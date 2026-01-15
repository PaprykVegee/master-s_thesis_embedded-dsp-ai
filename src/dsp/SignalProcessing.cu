#include "SignalProcessing.h"
#include "../cuda_kernels/kernels.cuh"

float* dsp::FirFilter::processGPU(std::vector<float> signal, bool returnGPU) {
    float* d_signal = nullptr;
    float* d_out = nullptr;
    float* d_coeffs = nullptr;

    cudaMalloc(&d_signal, signal.size() * sizeof(float));
    cudaMalloc(&d_out, signal.size() * sizeof(float));
    cudaMalloc(&d_coeffs, filter_coefficients.size() * sizeof(float));

    cudaMemcpy(d_signal, signal.data(), signal.size() * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_coeffs, filter_coefficients.data(), filter_coefficients.size() * sizeof(float), cudaMemcpyHostToDevice);

    int block = 256;
    int grid = (signal.size() + block - 1) / block;
    size_t sharedMem = (block + filter_coefficients.size() - 1) * sizeof(float);

    firKernel<<<grid, block, sharedMem>>>(
        d_signal,
        d_out,
        d_coeffs,
        signal.size(),
        filter_coefficients.size()
    );

    cudaDeviceSynchronize(); // czekamy aż kernel się zakończy

    if (returnGPU) {
        cudaFree(d_signal);
        cudaFree(d_coeffs);
        return d_out; // pamięć GPU pozostaje do zwolnienia przez użytkownika
    } else {
        float* h_out = new float[signal.size()];
        cudaMemcpy(h_out, d_out, signal.size() * sizeof(float), cudaMemcpyDeviceToHost);

        cudaFree(d_signal);
        cudaFree(d_out);
        cudaFree(d_coeffs);

        return h_out;
    }
}

float* dsp::apply_window_gpu(float* signal, int signal_lenght, int winSize, int overlap,
                             dsp::WinType winType, bool returnGPU) {

    float* h_window = new float[winSize];
    if (winType == dsp::WinType::Hamming)
        dsp::hammingWindow(h_window, winSize);
    else
        dsp::hannWindow(h_window, winSize);

    float* d_window = nullptr;
    cudaMalloc(&d_window, winSize * sizeof(float));
    cudaMemcpy(d_window, h_window, winSize * sizeof(float), cudaMemcpyHostToDevice);
    delete[] h_window;

    unsigned int hop = winSize - overlap;
    unsigned int N = (signal_lenght - winSize)/hop + 1;

    float* d_out = nullptr;
    cudaMalloc(&d_out, N*winSize*sizeof(float));

    size_t blockSize = 256;
    size_t sharedMemSize = winSize * sizeof(float);
    applyWindow<<<N, blockSize, sharedMemSize>>>(signal, d_out, d_window, signal_lenght, winSize, overlap);
    cudaDeviceSynchronize();

    // --- return ---
    if (returnGPU) {
        cudaFree(d_window);
        return d_out;
    } else {
        float* h_out = new float[N*winSize];
        cudaMemcpy(h_out, d_out, N*winSize*sizeof(float), cudaMemcpyDeviceToHost);
        cudaFree(d_out);
        cudaFree(d_window);
        return h_out;
    }
}

float* dsp::STFT::processGPU(float* d_signal, int signal_lenght, bool returnGPU) {
    // 1. Obliczenia wymiarów
    size_t hop = winSize - overlap;
    size_t rows = (signal_lenght - winSize) / hop + 1;
    size_t fftCols = winSize / 2 + 1; // Standard dla R2C
    size_t totalFFTElements = rows * fftCols;

    // 2. Alokacja pamięci
    cufftComplex* d_fft;
    float* d_magnitude;
    cudaMalloc(&d_fft, sizeof(cufftComplex) * totalFFTElements);
    cudaMalloc(&d_magnitude, sizeof(float) * totalFFTElements);

    float* d_windows = dsp::apply_window_gpu(d_signal, signal_lenght, winSize, overlap, winType, true);

    cufftHandle plan;
    int n[1] = { (int)winSize };

    cufftResult res = cufftPlanMany(
        &plan,
        1,           // ranga (1D FFT)
        n,           // rozmiar transformaty
        NULL, 1, (int)winSize, // inembed, istride, idist
        NULL, 1, (int)fftCols, // onembed, ostride, odist
        CUFFT_R2C,
        (int)rows    // liczba ramek
    );

    if (res != CUFFT_SUCCESS) return nullptr;

    cufftExecR2C(plan, (cufftReal*)d_windows, d_fft);

    int threads = 256;
    int blocks = (totalFFTElements + threads - 1) / threads;
    computeMagnitude<<<blocks, threads>>>(d_fft, d_magnitude, totalFFTElements);

    cudaDeviceSynchronize();

    // 7. Sprzątanie
    cufftDestroy(plan);
    cudaFree(d_windows);
    cudaFree(d_fft);

    if (returnGPU) {
        return d_magnitude;
    } else {
        float* h_out = new float[totalFFTElements];
        cudaMemcpy(h_out, d_magnitude, totalFFTElements * sizeof(float), cudaMemcpyDeviceToHost);
        cudaFree(d_magnitude);
        return h_out;
    }
}

float* dsp::MinMaxNormGPU(float* signal, int signal_length, float norm_val, bool returnGPU) {
    // signal powinien być już na GPU

    float* d_min;
    float* d_max;
    cudaMalloc((void**)&d_min, sizeof(float));
    cudaMalloc((void**)&d_max, sizeof(float));

    findMinMaxGPU(signal, d_min, d_max, signal_length);

    float h_min, h_max;
    cudaMemcpy(&h_min, d_min, sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(&h_max, d_max, sizeof(float), cudaMemcpyDeviceToHost);

    if (h_max == h_min) {
        float* d_out;
        cudaMalloc(&d_out, signal_length * sizeof(float));
        cudaMemset(d_out, 0, signal_length * sizeof(float));
        return d_out;
    }

    float* d_out;
    cudaMalloc(&d_out, signal_length * sizeof(float));

    int threads = 256;
    int blocks = (signal_length + threads - 1) / threads;

    normSignal<<<blocks, threads>>>(signal, d_out, h_min, h_max, norm_val, signal_length);
    cudaDeviceSynchronize();

    if (returnGPU) {
        return d_out;
    }

    float* h_out = (float*)malloc(signal_length * sizeof(float));
    cudaMemcpy(h_out, d_out, signal_length*sizeof(float), cudaMemcpyDeviceToHost);

    cudaFree(d_out);
    return h_out;
}

float* dsp::thresholdGPU(float* d_input, int signal_lenght, float threshold_val, bool returnGPU) {
    // sygnał jest na GPU -> parametr to d_input

    float* d_output;
    cudaMalloc((void**)&d_output, sizeof(float) * signal_lenght);

    int threads = 256;
    int blocks = (signal_lenght + threads - 1) / threads;

    threshold_kernel<<<blocks, threads>>>(d_input, d_output, signal_lenght, threshold_val);

    if (returnGPU)
        return d_output;
    else {
        float* h_output = new float[signal_lenght];
        cudaMemcpy(h_output, d_output, signal_lenght * sizeof(float), cudaMemcpyDeviceToHost);
        cudaFree(d_output);
        return h_output;
    }
}
