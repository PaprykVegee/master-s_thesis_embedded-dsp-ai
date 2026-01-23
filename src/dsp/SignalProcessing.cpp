//
// Created by patryk on 25.12.25.
//

#include "SignalProcessing.h"


void dsp::fft(cf* a, int winSize, bool invert)
{
    int n = winSize;

    // Bit-reversal permutation
    for (int i = 1, j = 0; i < n; i++) {
        int bit = n >> 1;
        for (; j & bit; bit >>= 1)
            j ^= bit;
        j ^= bit;
        if (i < j)
            std::swap(a[i], a[j]);
    }

    // FFT
    for (int len = 2; len <= n; len <<= 1) {
        double ang = 2 * M_PI / len * (invert ? -1 : 1);
        cf wlen(std::cos(ang), std::sin(ang));

        for (int i = 0; i < n; i += len) {
            cf w(1, 0);
            for (int j = 0; j < len / 2; j++) {
                cf u = a[i + j];
                cf v = a[i + j + len / 2] * w;
                a[i + j] = u + v;
                a[i + j + len / 2] = u - v;
                w *= wlen;
            }
        }
    }

    // Normalizacja przy IFFT
    if (invert) {
        for (int i = 0; i < n; i++)
            a[i] /= n;
    }
}

void dsp::rfft(float* data, int n)
{
    std::vector<cf> a(n);
    for (int i = 0; i < n; i++)
        a[i] = cf(data[i], 0.0);

    fft(a.data(), n, false);

    for (int i = 0; i < n / 2; i++) {
        data[i] = std::abs(a[i]);
    }
}


void dsp::hannWindow(float* data, int winSize) {
    const float pi = M_PI;

    for (int i = 0; i < winSize; i++) {
        data[i] = 0.5 * (1.0 - std::cos(2 * pi * i / (winSize - 1)));
    }
}

void dsp::hammingWindow(float* data, int winSize) {
    const float pi = M_PI;

    for (int i = 0; i < winSize; i++) {
        data[i] = 0.54 - 0.46*std::cos(2 * pi * i / (winSize - 1));
    }
}

dsp::FirFilter::FirFilter(std::vector<float> filter_coefficients)
{
    this->filter_coefficients = filter_coefficients;
}

std::vector<float> dsp::FirFilter::processCPU(std::vector<float> signal) {
    int N = signal.size();
    int K = filter_coefficients.size();
    std::vector<float> y(N, 0.0);
    for (int i = 0; i < N; i++) {
        double sum = 0;
        for (int j = 0; j < K; j++) {
            if (i - j >= 0) {
                sum += signal[i - j] * filter_coefficients[j];
            }
        }
        y[i] = sum;
    }
    return y;
}

std::vector<float> dsp::apply_window_cpu(std::vector<float> signal, int winSize, int overlap, WinType winType) {
    float* window = new float[winSize];

    if (winType == WinType::Hamming)
        dsp::hammingWindow(window, winSize);
    else
        dsp::hannWindow(window, winSize);

    unsigned int hop = winSize - overlap;
    unsigned int N = (signal.size() - winSize)/hop + 1;

    std::vector<float> windowed(N*winSize, 0.0);

    for (int i = 0; i < N; i++) {
        int start = i * hop;
        for (int j = 0; j < winSize; j++) {
            windowed[i*winSize + j] = signal[start + j]*window[j];
        }
    }

    delete[] window;
    return windowed;
}

dsp::STFT::STFT(int winSize, int overlap, WinType winType) {
    this->winSize = winSize;
    this->overlap = overlap;
    this->winType = winType;
}

std::vector<float> dsp::STFT::processCPU(std::vector<float> signal) {
    std::vector<float> win_signal = dsp::apply_window_cpu(signal, winSize, overlap, winType);

    int num_rows = win_signal.size() / winSize;
    int fft_cols = winSize / 2 + 1;

    std::vector<float> processed_data;
    processed_data.reserve(num_rows * fft_cols);

    for (int row = 0; row < num_rows; row++) {
        float* framePtr = win_signal.data() + (row * winSize);

        dsp::rfft(framePtr, winSize);

        processed_data.insert(processed_data.end(), framePtr, framePtr + fft_cols);
    }

    return processed_data;
}


std::vector<float> dsp::MinMaxNormCPU(std::vector<float> signal, float norm_val) {
    std::vector<float> process_signal;
    process_signal.reserve(signal.size());

    float min_val, max_val;

    findMinMaxCPU(signal, &min_val, &max_val);

    for (int i = 0; i < signal.size(); i++) {
        process_signal.push_back(norm_val*(signal[i] - min_val)/(max_val - min_val));
    }

    return process_signal;
}

std::vector<float> dsp::thresholdCPU(std::vector<float> signal, float threshold_val) {
    std::vector<float> threshold_signal(signal.size()); // <-- resize, gotowy do zapisu

    for (size_t i = 0; i < signal.size(); i++) {
        threshold_signal[i] = (signal[i] > threshold_val) ? 1.0f : 0.0f;
    }

    return threshold_signal;
}











