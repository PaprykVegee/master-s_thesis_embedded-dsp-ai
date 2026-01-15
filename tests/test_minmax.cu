#include "tests.h"

bool test_minmax() {
    Signal signal("/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/sum_sin_signal.txt");
    std::vector<float> originalSignal = signal.getSignal();
    float cpu_min, cpu_max;

    findMinMaxCPU(originalSignal, &cpu_min, &cpu_max);

    float *d_data, *d_min, *d_max;
    int N = originalSignal.size();

    cudaMalloc((void**)&d_data, N * sizeof(float));
    cudaMalloc((void**)&d_min, sizeof(float));
    cudaMalloc((void**)&d_max, sizeof(float));

    cudaMemcpy(d_data, originalSignal.data(), N * sizeof(float), cudaMemcpyHostToDevice);

    findMinMaxGPU(d_data, d_min, d_max, N);

    float h_gpu_min, h_gpu_max;
    cudaMemcpy(&h_gpu_min, d_min, sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(&h_gpu_max, d_max, sizeof(float), cudaMemcpyDeviceToHost);

    cudaFree(d_data);
    cudaFree(d_min);
    cudaFree(d_max);

    bool success = (cpu_min == h_gpu_min) && (cpu_max == h_gpu_max);

    if (success) {
        std::cout << "Test MinMax: PASSED (Min: " << cpu_min << ", Max: " << cpu_max << ")" << std::endl;
    } else {
        std::cout << "Test MinMax: FAILED!" << std::endl;
        std::cout << "CPU: [" << cpu_min << ", " << cpu_max << "]" << std::endl;
        std::cout << "GPU: [" << h_gpu_min << ", " << h_gpu_max << "]" << std::endl;
    }
    return success;
}
