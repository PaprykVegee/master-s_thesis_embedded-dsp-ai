//
// Created by patryk on 25.12.25.
//
#include "tests.h"
#include <cuda_runtime.h>
#include "iostream"

bool test_win_applyer() {
    Signal signal("../data/sum_sin_signal.txt");
    std::vector<float> originalSignal = signal.getSignal();

    // CPU
    std::vector<float> expectedSignal = dsp::apply_window_cpu(originalSignal, 256, 128);

    // GPU -> CPU
    float* d_signal = nullptr;
    cudaMalloc(&d_signal, originalSignal.size()*sizeof(float));
    cudaMemcpy(d_signal, originalSignal.data(), originalSignal.size()*sizeof(float), cudaMemcpyHostToDevice);

    float* actual_signal_ptr = dsp::apply_window_gpu(
        d_signal,
        originalSignal.size(),
        256,
        128,
        dsp::WinType::Hann,
        false                 // false = zwracamy CPU
    );

    std::vector<float> actualSignal;
    actualSignal.assign(actual_signal_ptr, actual_signal_ptr + expectedSignal.size());

    // porównanie
    const float eps = 1e-4f;
    bool success = true;

    for (size_t i = 0; i < expectedSignal.size(); ++i) {
        float a = expectedSignal[i];
        float b = actualSignal[i];

        if (std::fabs(a - b) > eps) {
            std::cout << "Mismatch at index " << i
                      << " | expected: " << a
                      << " | actual: " << b
                      << " | diff: " << std::fabs(a - b)
                      << std::endl;
            success = false;
        }
    }

    if (success) {
        std::cout << "TEST PASSED: GPU and CPU values match within tolerance " << eps << std::endl;
    } else {
        std::cout << "TEST FAILED: Some values differ beyond tolerance " << eps << std::endl;
    }

    return success;
}
