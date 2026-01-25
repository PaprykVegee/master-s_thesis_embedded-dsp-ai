//
// Created by patryk on 25.12.25.
//

#include "tests.h"
#include <cuda_runtime.h>
#include "iostream"

bool test_stft() {
    Signal signal("../data/sum_sin_signal.txt");
    std::vector<float> originalSignal = signal.getSignal();

    int winSize = 512;
    int overlap = 256;
    dsp::STFT stft(winSize, overlap, dsp::WinType::Hann);

    std::vector<float> stft_cpu = stft.processCPU(originalSignal);
    std::vector<float> stft_cpu_norm = dsp::MinMaxNormCPU(stft_cpu, 1.0f);
    std::vector<float> thresh_cpu_stft = dsp::thresholdCPU(stft_cpu_norm, 0.2f);

    float* d_signal = nullptr;
    cudaMalloc(&d_signal, originalSignal.size() * sizeof(float));
    cudaMemcpy(d_signal, originalSignal.data(), originalSignal.size() * sizeof(float),
               cudaMemcpyHostToDevice);
    float* d_stft = stft.processGPU(d_signal, originalSignal.size(), true);

    size_t stft_elements_count = stft_cpu.size();

    float* d_stft_norm = dsp::MinMaxNormGPU(d_stft, stft_elements_count, 1.0f, true);

    float* h_thresh_gpu_stft = dsp::thresholdGPU(d_stft_norm, stft_elements_count, 0.2f, false);

    std::vector<float> gpuSignal(h_thresh_gpu_stft, h_thresh_gpu_stft + stft_elements_count);

    // TEST COMPARISON
    const float eps = 1e-8f;
    bool success = true;

    for (size_t i = 0; i < thresh_cpu_stft.size(); ++i) {
        float a = thresh_cpu_stft[i];
        float b = gpuSignal[i];

        if (std::fabs(a - b) > eps) {
            std::cout << "Mismatch at index " << i
                      << " | expected: " << a
                      << " | actual: " << b
                      << " | diff: " << std::fabs(a - b) << "\n";
            success = false;
            if (i > 10) break;
        }
    }

    // SAVE OUTPUTS FOR INSPECTION
    signal.setSignal(thresh_cpu_stft);
    signal.writeSignal("/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/spectogram_cpu.txt");

    signal.setSignal(gpuSignal);
    signal.writeSignal("/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/spectogram_gpu.txt");

    // CLEANUP MEMORY
    cudaFree(d_signal);
    cudaFree(d_stft);
    cudaFree(d_stft_norm);

    free(h_thresh_gpu_stft); // host pointer

    // RESULT LOG
    if (success)
        std::cout << "TEST PASSED: GPU and CPU values match within tolerance " << eps << std::endl;
    else
        std::cout << "TEST FAILED: Some values differ beyond tolerance " << eps << std::endl;

    return success;
}
