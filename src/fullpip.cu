#include "fullpip.h"

float* FullPip::processGPU(std::vector<float> input, bool return_gpu)
{

    dsp::FirFilter fir(coff_filter);
    dsp::STFT stft(winSize, overlap, winType);

    unsigned int hop = winSize - overlap;
    int numWindows = (input.size() - winSize) / hop + 1;
    size_t outputSize = numWindows * (winSize / 2 + 1);

    // 1. Processing
    float* d_signal_filter = fir.processGPU(input, true);
    float* d_fft_mag       = stft.processGPU(d_signal_filter, input.size(), true);
    float* d_norm_fft_mag  = dsp::MinMaxNormGPU(d_fft_mag, outputSize, 1.0f, true);

    // opcjonalnie
    // float* d_threshold = dsp::thresholdGPU(d_norm_fft_mag, outputSize, 0.2f, true);

    // 2. cleanup
    cudaFree(d_signal_filter);
    cudaFree(d_fft_mag);

    if (return_gpu) {
        return d_norm_fft_mag; // caller MUSI cudaFree
    }

    // 3. GPU → CPU
    float* h_out = new float[outputSize];
    cudaMemcpy(h_out, d_norm_fft_mag,
               outputSize * sizeof(float),
               cudaMemcpyDeviceToHost);

    cudaFree(d_norm_fft_mag);
    return h_out;  // CPU pointer
}
