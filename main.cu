#include <iostream>
#include <vector>
#include <chrono>
#include "src/fullpip.h"
#include "src/utils/utils.h"
#include "src/structures/Signal.h"
#include <fstream>
#include <algorithm>
#include <NvInfer.h>
#include <cuda_fp16.h>

#define WINDOW_SIZE 256
#define OVERLAP 128

__global__ void float2half_kernel(const float* in, __half* out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = __float2half(in[i]);
}

class Logger : public nvinfer1::ILogger {
public:
    void log(Severity severity, const char* msg) noexcept override {
        if (severity <= Severity::kWARNING)
            std::cout << msg << std::endl;
    }
} logger;

std::vector<char> loadEngine(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    f.seekg(0, std::ios::end);
    size_t size = f.tellg();
    f.seekg(0, std::ios::beg);
    std::vector<char> data(size);
    f.read(data.data(), size);
    return data;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <path_to_input_file>" << std::endl;
        return 1;
    }

    std::string input_file = argv[1];
    cudaWarmup();	

    // Przygotowanie sygnału
    Signal signal(input_file);
    std::vector<float> signal0 = signal.getSignal();
    std::vector<float> signal1 = signal.getSignal();
    std::vector<float> signal2 = signal.getSignal();

    int winSize = WINDOW_SIZE;
    int hop = WINDOW_SIZE - OVERLAP;
    int n_bins = winSize / 2 + 1;

    size_t raw_max = std::max({signal0.size(), signal1.size(), signal2.size()});
    int n_frames_per_sig = (raw_max - winSize + hop - 1) / hop + 1;
    size_t safe_len = (n_frames_per_sig - 1) * hop + winSize;

    auto pad_signal = [&](std::vector<float>& s, size_t target_len) {
        if (s.size() < target_len) s.resize(target_len, 0.0f);
        else s.resize(target_len);
    };

    pad_signal(signal0, safe_len);
    pad_signal(signal1, safe_len);
    pad_signal(signal2, safe_len);

    std::vector<float> batched_signal;
    batched_signal.reserve(3 * safe_len);
    batched_signal.insert(batched_signal.end(), signal0.begin(), signal0.end());
    batched_signal.insert(batched_signal.end(), signal1.begin(), signal1.end());
    batched_signal.insert(batched_signal.end(), signal2.begin(), signal2.end());

    // FIR i FullPip
    std::vector<float> fir_coeff;
    fir_coeff.assign({-6.223067841408601e-19, -0.00024972382022756543, /* ... reszta współczynników ... */  -6.223067841408601e-19});

    FullPip full_pip(winSize, OVERLAP, fir_coeff);

    auto start_cpu = std::chrono::high_resolution_clock::now();
    std::vector<float> stft_cpu = full_pip.processCPU(batched_signal);
    auto end_cpu = std::chrono::high_resolution_clock::now();

    auto start_gpu = std::chrono::high_resolution_clock::now();
    float* stft_gpu_raw = full_pip.processGPU(batched_signal, true);
    auto end_gpu = std::chrono::high_resolution_clock::now();

    std::cout << "CPU time: " << std::chrono::duration<double, std::milli>(end_cpu - start_cpu).count() << " ms" << std::endl;
    std::cout << "GPU time: " << std::chrono::duration<double, std::milli>(end_gpu - start_gpu).count() << " ms" << std::endl;

    // TensorRT
    try {
        std::cout << "=== TensorRT inference debug start ===" << std::endl;
        auto engineData = loadEngine("../nn_model/resnet18_fp16.trt");
        std::cout << "Engine size: " << engineData.size() << " bytes" << std::endl;

        nvinfer1::IRuntime* runtime = nvinfer1::createInferRuntime(logger);
        nvinfer1::ICudaEngine* engine = runtime->deserializeCudaEngine(engineData.data(), engineData.size());
        nvinfer1::IExecutionContext* context = engine->createExecutionContext();

        int inputIndex  = engine->getBindingIndex("input");
        int outputIndex = engine->getBindingIndex("output");
        std::cout << "inputIndex=" << inputIndex << ", outputIndex=" << outputIndex << std::endl;

        // Ustawienie dynamicznych wymiarów na 1x3x224x224
        nvinfer1::Dims4 inputDims{1,3,224,224};
        if(!context->setBindingDimensions(inputIndex, inputDims))
            throw std::runtime_error("Failed to set dynamic input dimensions");

        nvinfer1::Dims outDims = context->getBindingDimensions(outputIndex);
        int outSize = 1;
        for(int i=0;i<outDims.nbDims;i++) outSize *= outDims.d[i];
        std::cout << "Output size: " << outSize << std::endl;

        // Konwersja danych STFT w GPU do FP16
        int totalElems = 3*224*224;
        __half* stft_fp16;
        cudaMalloc(&stft_fp16, totalElems * sizeof(__half));

        int threads = 256;
        int blocks  = (totalElems + threads - 1)/threads;
        float2half_kernel<<<blocks, threads>>>(stft_gpu_raw, stft_fp16, totalElems);
        cudaDeviceSynchronize();

        // Przygotowanie output
        __half* output_gpu;
        cudaMalloc(&output_gpu, outSize * sizeof(__half));

        void* bindings[2];
        bindings[inputIndex]  = stft_fp16;
        bindings[outputIndex] = output_gpu;

        cudaStream_t stream;
        cudaStreamCreate(&stream);

        if(!context->enqueueV2(bindings, stream, nullptr))
            throw std::runtime_error("Inference failed");

        cudaStreamSynchronize(stream);

        // Kopiowanie wyników do CPU
        std::vector<__half> output_host(outSize);
        cudaMemcpy(output_host.data(), output_gpu, outSize*sizeof(__half), cudaMemcpyDeviceToHost);

        std::vector<float> output_float(outSize);
        for(int i=0;i<outSize;i++) output_float[i] = __half2float(output_host[i]);

        std::cout << "First 10 output elements:" << std::endl;
        for(int i=0;i<std::min(10,outSize);i++) std::cout << output_float[i] << " ";
        std::cout << std::endl;

        // Zwolnienie pamięci
        cudaFree(stft_gpu_raw);   // pamięć zwolniona, bo processGPU zwraca GPU pointer
        cudaFree(stft_fp16);
        cudaFree(output_gpu);
        cudaStreamDestroy(stream);
        context->destroy();
        engine->destroy();
        runtime->destroy();

        std::cout << "=== TensorRT inference debug end ===" << std::endl;

    } catch(const std::exception& e){
        std::cout << "TRT ERROR ❌: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}

