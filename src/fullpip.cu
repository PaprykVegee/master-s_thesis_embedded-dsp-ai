#include "fullpip.h"

float* FullPip::processGPU(std::vector<float> input, bool return_gpu, bool trash)
{
    dsp::FirFilter fir(coff_filter);
    dsp::STFT stft(winSize, overlap, winType);

    unsigned int hop = winSize - overlap;
    int numWindows = (input.size() - winSize) / hop + 1;
    size_t outputSize = numWindows * (winSize / 2 + 1);

    // 1️⃣ Przetwarzanie
    float* d_signal_filter = fir.processGPU(input, true);
    float* d_fft_mag       = stft.processGPU(d_signal_filter, input.size(), true);
    float* d_norm_fft_mag  = dsp::MinMaxNormGPU(d_fft_mag, outputSize, 1.0f, true);

    // 2️⃣ Zdecyduj, co zwrócić
    float* d_output = nullptr;

    if (trash) {
        d_output = dsp::thresholdGPU(d_norm_fft_mag, outputSize, 0.5f, true);
    } else {
        // jeśli trash=false, zwracamy tylko znormalizowany spektrogram
        d_output = d_norm_fft_mag;
    }

    cudaFree(d_signal_filter);
    cudaFree(d_fft_mag);
    if (trash) {
        cudaFree(d_norm_fft_mag); // jeśli trash=true, d_output wskazuje na threshold, więc norm musimy zwolnić
    }

    if (return_gpu) {
        return d_output; // caller MUSI cudaFree!
    }

    // 5️⃣ GPU → CPU
    float* h_out = new float[outputSize];
    cudaMemcpy(h_out, d_output,
               outputSize * sizeof(float),
               cudaMemcpyDeviceToHost);

    cudaFree(d_output); // teraz zwalniamy GPU
    return h_out;       // CPU pointer
}
