#ifndef TRT_CLF_H
#define TRT_CLF_H

#include <string>
#include <vector>
#include <cuda_runtime.h>
#include <NvInfer.h>
#include <cuda_fp16.h>

class TRTClassifier {
public:
    explicit TRTClassifier(const std::string& engine_path, int device_id = 0);
    ~TRTClassifier();

    // Predict na podstawie wskaźnika do danych float na GPU (kształt: [1,3,224,224])
    std::vector<float> predict(float* gpu_input_float, cudaStream_t stream = 0);

private:
    class Logger : public nvinfer1::ILogger {
        void log(Severity severity, const char* msg) noexcept override;
    } logger_;

    nvinfer1::IRuntime* runtime_ = nullptr;
    nvinfer1::ICudaEngine* engine_ = nullptr;
    nvinfer1::IExecutionContext* context_ = nullptr;

    void* bindings_[2] = {nullptr, nullptr};
    __half* input_half_ = nullptr;
    __half* output_half_ = nullptr;
    int output_size_ = 0;

    static std::vector<char> loadEngine(const std::string& path);
    void checkCuda(cudaError_t err, const char* msg);
};

#endif // TRT_CLF_H