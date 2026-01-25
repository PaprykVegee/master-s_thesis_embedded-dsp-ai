//
// Created by patryk on 27.12.25.
//

#include "fullpip.h"

FullPip::FullPip(int winSize, int overlap, std::vector<float> coff_filter, dsp::WinType winType) {
    this->winSize = winSize;
    this->overlap = overlap;
    this->coff_filter = coff_filter;
    this->winType = winType;
}

std::vector<float> FullPip::processCPU(std::vector<float> input, bool trash) {

    dsp::STFT stft(this->winSize, this->overlap, this->winType);
    dsp::FirFilter fir(this->coff_filter);
    int n_bins = winSize / 2 + 1; // H
    int in_w = input.size() / (n_bins * 3);


    std::vector<float> signal_filter = fir.processCPU(input);
    std::vector<float> stft_cpu = stft.processCPU(signal_filter);
    std::vector<float> stft_cpu_norm = dsp::MinMaxNormCPU(stft_cpu, 1.0f);

    if (!trash)
        return stft_cpu_norm;

    std::vector<float> thresh_cpu_stft = dsp::thresholdCPU(stft_cpu_norm, 0.5f);
    std::vector<float> stft_transpose = TransposeCPU(thresh_cpu_stft, n_bins, in_w);
    std::vector<float> stft_res = ResizeBilinear_CPU_CHW(stft_transpose, n_bins, in_w, 3, 256, 256);

    return stft_res;
}
