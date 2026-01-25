#include "fullpip.h"

float* FullPip::processGPU(std::vector<float> input, bool return_gpu, bool trash)
{
    dsp::FirFilter fir(coff_filter);
    dsp::STFT stft(winSize, overlap, winType);

    int n_bins = winSize / 2 + 1; // H
    unsigned int hop = winSize - overlap;
    int in_w = input.size() / (n_bins * 3);


    int numWindows = (input.size() / 3 - winSize) / hop + 1;
    size_t channelSize = (size_t)numWindows * n_bins;
    size_t totalElements = 3 * channelSize;

    float* d_signal_filter = fir.processGPU(input, true);
    float* d_fft_mag       = stft.processGPU(d_signal_filter, input.size(), true);
    float* d_norm_fft_mag  = dsp::MinMaxNormGPU(d_fft_mag, totalElements, 1.0f, true);

    float* d_processed = nullptr;
    if (trash) {
        d_processed = dsp::thresholdGPU(d_norm_fft_mag, totalElements, 0.5f, true);
    } else {
        d_processed = d_norm_fft_mag;
    }

    float* d_transposed = TransposeGPU(d_processed, n_bins, in_w, true);

    float* d_output = ResizeBilinear_chw_GPU(d_transposed, n_bins, in_w, 256, 256, 3, true);

    cudaFree(d_signal_filter);
    cudaFree(d_fft_mag);
    cudaFree(d_norm_fft_mag);
    if (trash) cudaFree(d_processed);
    cudaFree(d_transposed); // Zwalniamy po zrobieniu Resize

    if (return_gpu) {
        return d_output;
    }

    size_t outSize = 3 * 256 * 256;
    float* h_out = new float[outSize];
    cudaMemcpy(h_out, d_output, outSize * sizeof(float), cudaMemcpyDeviceToHost);

    cudaFree(d_output);
    return h_out;
}