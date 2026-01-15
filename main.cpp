#include <iostream>
#include <vector>
#include <chrono>
#include "src/fullpip.h"
#include "src/utils/utils.h"
#include "src/structures/Signal.h"

int main() {
    // Warmup CUDA
    std::cout << "debug";
    cudaWarmup();
    std::cout << "debug";
    // Wczytanie sygnału
    Signal signal("/home/patryk/Desktop/MASTER_THIESIS/fpga_prep/test_data.txt");
    std::vector<float> originalSignal = signal.getSignal();
    std::cout << "debug";

    // FIR coefficients
    std::vector<float> fir_coeff = {
        0.0020395046501305893, 0.0021361459782720717, 0.002365577569209405,
        0.002731093451858461, 0.0032340860681839903, 0.0038739865880887893,
        0.004648234485304411, 0.00555227723719692, 0.0065796005309615236,
        0.007721788867696089, 0.008968615962520554, 0.010308163851541149,
        0.01172696914328666, 0.013210194401314497, 0.014741822223705599,
        0.016304869201378337, 0.017881616597192698, 0.019453854297612448,
        0.02100313435334998, 0.022511030249130433, 0.023959397928685764,
        0.02533063455148792, 0.0266079309736304, 0.02777551402663862,
        0.028818874813691702, 0.029724979450539285, 0.030482458945007087,
        0.03108177523011269, 0.03151536073623671, 0.03177772930144902,
        0.03186555666917236, 0.03177772930144902, 0.03151536073623671,
        0.03108177523011269, 0.030482458945007087, 0.029724979450539285,
        0.028818874813691702, 0.02777551402663863, 0.026607930973630404,
        0.02533063455148792, 0.023959397928685768, 0.022511030249130436,
        0.02100313435334998, 0.019453854297612455, 0.017881616597192704,
        0.016304869201378337, 0.014741822223705606, 0.013210194401314506,
        0.01172696914328666, 0.010308163851541152, 0.008968615962520564,
        0.007721788867696089, 0.006579600530961528, 0.0055522772371969275,
        0.004648234485304411, 0.003873986588088791, 0.0032340860681839916,
        0.002731093451858461, 0.002365577569209405, 0.0021361459782720717,
        0.0020395046501305893
    };

    // Inicjalizacja FullPip
    FullPip full_pip(512, 256, fir_coeff);

    // =======================
    // CPU TIMER
    // =======================
    auto start_cpu = std::chrono::high_resolution_clock::now();
    std::vector<float> stft_cpu = full_pip.processCPU(originalSignal);
    std::cout << "debug";
    auto end_cpu = std::chrono::high_resolution_clock::now();
    double cpu_time = std::chrono::duration<double, std::milli>(end_cpu - start_cpu).count();

    // signal.setSignal(stft_cpu);
    // signal.writeSignal("/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/spectrogram_cpu.txt");

    // =======================
    // GPU TIMER
    // =======================
    auto start_gpu = std::chrono::high_resolution_clock::now();
    float* stft_gpu = full_pip.processGPU(originalSignal, false);
    std::cout << "debug";
    auto end_gpu = std::chrono::high_resolution_clock::now();
    double gpu_time = std::chrono::duration<double, std::milli>(end_gpu - start_gpu).count();

    std::vector<float> stft_gpu_vec(stft_gpu, stft_gpu+stft_cpu.size());

    signal.setSignal(stft_cpu);
    signal.writeSignal("/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/spectrogram_cpu.txt");

    signal.setSignal(stft_gpu_vec);
    signal.writeSignal("/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/spectrogram_gpu.txt");

    // =======================
    // PRINT TIMES
    // =======================
    std::cout << "CPU processing time: " << cpu_time << " ms" << std::endl;
    std::cout << "GPU processing time: " << gpu_time << " ms" << std::endl;

    return 0;
}
