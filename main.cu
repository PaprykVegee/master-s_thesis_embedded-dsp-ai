#include <iostream>
#include <vector>
#include <chrono>
#include "src/fullpip.h"
#include "src/utils/utils.h"
#include "src/structures/Signal.h"
#include "src/ML_clf/trt_clf.cuh"   // <-- nowa klasa
#include <fstream>
#include <algorithm>
#include <cuda_fp16.h>

#define WINDOW_SIZE 256
#define OVERLAP 128

extern void cudaWarmup();  // z utils

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <path_to_input_file>" << std::endl;
        return 1;
    }

    std::string input_file = argv[1];
    cudaWarmup();

    Signal signal(input_file);
    std::vector<float> signal0 = signal.getSignal();
    std::vector<float> signal1 = signal.getSignal();
    std::vector<float> signal2 = signal.getSignal();

    int winSize = WINDOW_SIZE;
    int hop = WINDOW_SIZE - OVERLAP;
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


    std::vector<float> fir_coeff = { -6.22306784141e-19, -0.000249723820228, -0.000121886379326, 0.000464301744213, 0.00115329587664, 0.00137619729156, 0.000826175708606, -0.00018539928305, -0.000887119191123, -0.000724385588735, 1.16209280889e-18, 0.000232259287887, -0.000856223045941, -0.00282889457298, -0.00401109670854, -0.0028761033194, 0.000327463122424, 0.00339402216342, 0.00398356005532, 0.00198159278452, 1.37722713301e-18, 0.00106044261687, 0.00530260604237, 0.00901769219938, 0.00756980795757, -9.24125574449e-18, -0.00912747450726, -0.0131166015332, -0.00931248743632, -0.00225166139203, -2.36136063588e-18, -0.00618723209277, -0.0151427955119, -0.0157596478541, -0.00186454117781, 0.0201706776504, 0.0348237871258, 0.0305769843119, 0.0115956550036, -0.00396918020027, 3.15754136444e-18, 0.0202076854621, 0.032084810013, 0.00879807319235, -0.0522062713656, -0.118100180901, -0.138390565063, -0.0818487506754, 0.034853027968, 0.151102544576, 0.199550844241, 0.151102544576, 0.034853027968, -0.0818487506754, -0.138390565063, -0.118100180901, -0.0522062713656, 0.00879807319235, 0.032084810013, 0.0202076854621, 3.15754136444e-18, -0.00396918020027, 0.0115956550036, 0.0305769843119, 0.0348237871258, 0.0201706776504, -0.00186454117781, -0.0157596478541, -0.0151427955119, -0.00618723209277, -2.36136063588e-18, -0.00225166139203, -0.00931248743632, -0.0131166015332, -0.00912747450726, -9.24125574449e-18, 0.00756980795757, 0.00901769219938, 0.00530260604237, 0.00106044261687, 1.37722713301e-18, 0.00198159278452, 0.00398356005532, 0.00339402216342, 0.000327463122424, -0.0028761033194, -0.00401109670854, -0.00282889457298, -0.000856223045941, 0.000232259287887, 1.16209280889e-18, -0.000724385588735, -0.000887119191123, -0.00018539928305, 0.000826175708606, 0.00137619729156, 0.00115329587664, 0.000464301744213, -0.000121886379326, -0.000249723820228, -6.22306784141e-19 };
    FullPip full_pip(winSize, OVERLAP, fir_coeff);

    // 🔹 Pomiar CPU
    auto start_cpu = std::chrono::high_resolution_clock::now();
    std::vector<float> stft_cpu = full_pip.processCPU(batched_signal);
    auto end_cpu = std::chrono::high_resolution_clock::now();

    // 🔹 Pomiar GPU
    auto start_gpu = std::chrono::high_resolution_clock::now();
    float* stft_gpu_raw = full_pip.processGPU(batched_signal, true);
    cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        std::cerr << "CUDA ERROR after processGPU: "
                  << cudaGetErrorString(err) << std::endl;
        return 1;
    }
    auto end_gpu = std::chrono::high_resolution_clock::now();

    std::cout << "CPU time: "
              << std::chrono::duration<double, std::milli>(end_cpu - start_cpu).count()
              << " ms" << std::endl;

    std::cout << "GPU time: "
              << std::chrono::duration<double, std::milli>(end_gpu - start_gpu).count()
              << " ms" << std::endl;

    try {
        std::cout << "=== TensorRT timing start ===" << std::endl;

        // 🔹 Pomiar konstruktora TRTClassifier
        auto trt_ctor_start = std::chrono::high_resolution_clock::now();
        TRTClassifier classifier("../nn_model/resnet18_fp16.trt", 0);
        auto trt_ctor_end = std::chrono::high_resolution_clock::now();

        std::cout << "TRT constructor time: "
                  << std::chrono::duration<double, std::milli>(trt_ctor_end - trt_ctor_start).count()
                  << " ms" << std::endl;

        // 🔹 Pomiar predict() z synchronizacją CUDA
        for (int j = 0; j<4; j++){
            auto trt_pred_start = std::chrono::high_resolution_clock::now();
            std::vector<float> output = classifier.predict(stft_gpu_raw);
            cudaDeviceSynchronize();
            auto trt_pred_end = std::chrono::high_resolution_clock::now();

            std::cout << "TRT predict() time: "
                    << std::chrono::duration<double, std::milli>(trt_pred_end - trt_pred_start).count()
                    << " ms" << std::endl;

            // 🔹 Wyświetlenie pierwszych 10 wyników
            std::cout << "First 10 output elements:" << std::endl;
            for (int i = 0; i < std::min(10, (int)output.size()); ++i)
                std::cout << output[i] << " ";
            std::cout << std::endl;

            std::cout << "=== TensorRT timing end ===" << std::endl;
        }
        } catch (const std::exception& e) {
            std::cout << "TRT ERROR ❌: " << e.what() << std::endl;
            return 1;
        }

    cudaFree(stft_gpu_raw);
    return 0;
}
