#include "tests.h"

bool test_resize() {
    float epsilon = 1e-3f;
    bool success = true;

    Signal signal("../data/spectrogram_gpu.txt");
    std::vector<float> originalSignal = signal.getSignal();

    int in_h = 129;
    int in_c = 3;
    int in_w = originalSignal.size() / (in_h * in_c);

    float* d_signal;
    size_t signal_size = originalSignal.size() * sizeof(float);
    cudaMalloc((void**)&d_signal, signal_size);
    cudaMemcpy(d_signal, originalSignal.data(), signal_size, cudaMemcpyHostToDevice);

    float* d_transposed = TransposeGPU(d_signal, in_h, in_w, true);
    float* d_gpu_resized = ResizeBilinear_chw_GPU(d_transposed, in_h, in_w, 256, 256, in_c, true);

    size_t out_elements = in_c * 256 * 256;
    std::vector<float> h_gpu_result(out_elements);
    cudaMemcpy(h_gpu_result.data(), d_gpu_resized, out_elements * sizeof(float), cudaMemcpyDeviceToHost);

    std::vector<float> cpu_transpose = TransposeCPU(originalSignal, in_h, in_w);
    std::vector<float> cpu_img = ResizeBilinear_CPU_CHW(cpu_transpose, in_h, in_w, in_c, 256, 256);

    for (size_t i = 0; i < cpu_img.size(); i++) {
        if (std::fabs(cpu_img[i] - h_gpu_result[i]) > epsilon) {
            success = false;
            std::cout << "Mismatch at " << i << ": CPU=" << cpu_img[i] << ", GPU=" << h_gpu_result[i] << std::endl;
            break;
        }
    }

    if (success) std::cout << "TEST PASSED!" << std::endl;

    signal.setSignal(h_gpu_result);
    signal.writeSignal("../data/resize_spec.txt");

    cudaFree(d_signal);
    cudaFree(d_transposed);
    cudaFree(d_gpu_resized);

    return success;
}