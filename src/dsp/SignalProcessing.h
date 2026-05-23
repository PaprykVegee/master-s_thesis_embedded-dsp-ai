//
// Created by patryk on 25.12.25.
//

#include <complex>
#include <cmath>
#include <vector>
#include "../utils/utils.h"


using cf = std::complex<float>;

#ifndef SIGNALPROCESSING_H
#define SIGNALPROCESSING_H

namespace dsp
{
    void fft(cf* a, int winSize, bool invert);
    void rfft(float* data, int n);

    void hannWindow(float* data, int winSize);
    void hammingWindow(float* data, int winSize);

    // filtr FIR
    class FirFilter {
        public:
            FirFilter(std::vector<float> filter_coefficients);
            std::vector<float> processCPU(std::vector<float> signal);
            float* processGPU(std::vector<float> signal, bool returnGPU = true);
        private:
            std::vector<float> filter_coefficients;
    };

    enum class WinType
    {
        Hann,
        Hamming
        // etc
    };

    std::vector<float>  apply_window_cpu(std::vector<float> signal, int winSize, int overlap, WinType winType = WinType::Hann);
    float* apply_window_gpu(float* signal, int signal_lenght, int winSize, int overlap, WinType winType = WinType::Hann, bool returnGPU = true);

    class STFT {
        public:
            STFT(int winSize, int overlap, WinType winType = WinType::Hann);

            std::vector<float> processCPU(std::vector<float> signal);
            float* processGPU(float* signal, int signal_lenght,  bool returnGPU = true);
        private:
            int winSize;
            int overlap;
           // float* windows;
            WinType winType;
    };

    std::vector<float> MinMaxNormCPU(std::vector<float> signal, float norm_val);
    float* MinMaxNormGPU(float* signal, int signal_lenght, float norm_val, bool returnGPU = true);

    std::vector<float> thresholdCPU(std::vector<float> signal, float threshold_val);
    float* thresholdGPU(float* signal, int signal_lenght, float threshold_val, bool returnGPU = true);

    std::vector<float> StandardScalerCPU(std::vector<float> signal, float mean, float std);
    float* StandardScalerGPU(float* signal, int signal_lenght, float mean, float std, bool returnGPU = true);
}

#endif //SIGNALPROCESSING_H
