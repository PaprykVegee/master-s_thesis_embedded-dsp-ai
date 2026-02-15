#include "trt_clf.cuh"
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <cuda_fp16.h>

// Kernel do konwersji float -> half
__global__ void float2half_kernel(const float* in, __half* out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = __float2half(in[i]);
}

void TRTClassifier::Logger::log(Severity severity, const char* msg) noexcept {
    if (severity <= Severity::kWARNING)
        std::cout << "[TensorRT] " << msg << std::endl;
}

std::vector<char> TRTClassifier::loadEngine(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("Cannot open engine file: " + path);
    f.seekg(0, std::ios::end);
    size_t size = f.tellg();
    f.seekg(0, std::ios::beg);
    std::vector<char> data(size);
    f.read(data.data(), size);
    return data;
}

void TRTClassifier::checkCuda(cudaError_t err, const char* msg) {
    if (err != cudaSuccess) {
        std::cerr << "CUDA error (" << msg << "): " << cudaGetErrorString(err) << std::endl;
        throw std::runtime_error(msg);
    }
}

TRTClassifier::TRTClassifier(const std::string& engine_path, int device_id) {
    // Ustaw urządzenie i zainicjuj kontekst CUDA
    checkCuda(cudaSetDevice(device_id), "cudaSetDevice");
    checkCuda(cudaFree(0), "cudaFree(0) - context init");

    std::cout << "Loading TensorRT engine from: " << engine_path << std::endl;
    auto engineData = loadEngine(engine_path);
    std::cout << "Engine size: " << engineData.size() << " bytes" << std::endl;

    runtime_ = nvinfer1::createInferRuntime(logger_);
    if (!runtime_) throw std::runtime_error("Failed to create TensorRT runtime");

    engine_ = runtime_->deserializeCudaEngine(engineData.data(), engineData.size());
    if (!engine_) throw std::runtime_error("Failed to deserialize engine");

    int inputIndex  = engine_->getBindingIndex("input");
    int outputIndex = engine_->getBindingIndex("output");
    if (inputIndex < 0 || outputIndex < 0)
        throw std::runtime_error("Missing 'input' or 'output' binding in engine");

    context_ = engine_->createExecutionContext();
    if (!context_) throw std::runtime_error("Failed to create execution context");

    // Ustaw wymiary wejściowe (zakładamy [1,3,224,224])
    nvinfer1::Dims inputDims = engine_->getBindingDimensions(inputIndex);
    bool dynamic = false;
    for (int i = 0; i < inputDims.nbDims; ++i)
        if (inputDims.d[i] == -1) dynamic = true;
    if (dynamic) {
        nvinfer1::Dims4 fixedDims{1, 3, 224, 224};
        if (!context_->setBindingDimensions(inputIndex, fixedDims))
            throw std::runtime_error("Failed to set dynamic input dimensions");
        inputDims = fixedDims;
    }

    nvinfer1::Dims outDims = context_->getBindingDimensions(outputIndex);
    output_size_ = 1;
    for (int i = 0; i < outDims.nbDims; ++i)
        output_size_ *= outDims.d[i];

    // Alokuj bufory GPU
    int inputElems = 1 * 3 * 224 * 224;
    checkCuda(cudaMalloc(&input_half_, inputElems * sizeof(__half)), "cudaMalloc input_half_");
    checkCuda(cudaMalloc(&output_half_, output_size_ * sizeof(__half)), "cudaMalloc output_half_");

    bindings_[inputIndex]  = input_half_;
    bindings_[outputIndex] = output_half_;

    std::cout << "TensorRT engine loaded, output size: " << output_size_ << std::endl;
}

TRTClassifier::~TRTClassifier() {
    cudaFree(input_half_);
    cudaFree(output_half_);
    if (context_) context_->destroy();
    if (engine_) engine_->destroy();
    if (runtime_) runtime_->destroy();
}

std::vector<float> TRTClassifier::predict(float* gpu_input_float, cudaStream_t stream) {
    int inputElems = 1 * 3 * 224 * 224;
    int threads = 256;
    int blocks = (inputElems + threads - 1) / threads;
    float2half_kernel<<<blocks, threads, 0, stream>>>(gpu_input_float, input_half_, inputElems);
    checkCuda(cudaGetLastError(), "float2half_kernel launch");

    if (!context_->enqueueV2(bindings_, stream, nullptr))
        throw std::runtime_error("Inference enqueue failed");

    std::vector<__half> output_half_host(output_size_);
    checkCuda(cudaMemcpyAsync(output_half_host.data(), output_half_,
                              output_size_ * sizeof(__half), cudaMemcpyDeviceToHost, stream),
              "cudaMemcpyAsync output");
    checkCuda(cudaStreamSynchronize(stream), "cudaStreamSynchronize");

    std::vector<float> output_float(output_size_);
    for (int i = 0; i < output_size_; ++i)
        output_float[i] = __half2float(output_half_host[i]);

    return output_float;
}