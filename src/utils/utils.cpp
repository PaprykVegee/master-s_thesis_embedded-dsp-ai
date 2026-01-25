//
// Created by patryk on 25.12.25.
//

#include "utils.h"


void findMinMaxCPU(std::vector<float> data, float* min, float* max) {
    if (data.empty()) {
        if (min) *min = 0.0f;
        if (max) *max = 0.0f;
        return;
    }

    float currentMin = data[0];
    float currentMax = data[0];

    for (size_t i = 1; i < data.size(); ++i) {
        if (data[i] < currentMin) {
            currentMin = data[i];
        }
        if (data[i] > currentMax) {
            currentMax = data[i];
        }
    }

    if (min) *min = currentMin;
    if (max) *max = currentMax;
}

std::vector<float> ResizeBilinear_CPU_CHW(const std::vector<float>& src,
                                          int H_in, int W_in, int C, int H_out, int W_out) {

    std::vector<float> out_src(C * H_out * W_out);

    float x_ratio = float(W_in - 1) / (W_out - 1);
    float y_ratio = float(H_in - 1) / (H_out - 1);

    for (int c = 0; c < C; c++) {
        for (int y = 0; y < H_out; y++) {
            for (int x = 0; x < W_out; x++) {
                int x_l = static_cast<int>(floor(x_ratio * x));
                int y_l = static_cast<int>(floor(y_ratio * y));
                int x_h = static_cast<int>(ceil(x_ratio * x));
                int y_h = static_cast<int>(ceil(y_ratio * y));

                float x_weight = (x_ratio * x) - x_l;
                float y_weight = (y_ratio * y) - y_l;

                float a = src[c*H_in*W_in + y_l*W_in + x_l];
                float b = src[c*H_in*W_in + y_l*W_in + x_h];
                float c_ = src[c*H_in*W_in + y_h*W_in + x_l];
                float d = src[c*H_in*W_in + y_h*W_in + x_h];

                float pixel = a * (1 - x_weight) * (1 - y_weight)
                            + b * x_weight * (1 - y_weight)
                            + c_ * (1 - x_weight) * y_weight
                            + d * x_weight * y_weight;

                out_src[c*H_out*W_out + y*W_out + x] = pixel;
            }
        }
    }

    return out_src;
}

std::vector<float> TransposeCPU(const std::vector<float> src, int H, int W) {
    int C = 3; // Liczba kanałów

    // Sprawdzenie, czy wektor wejściowy faktycznie ma tyle danych, ile myślisz
    if (src.size() < (size_t)C * H * W) {
        std::cerr << "TransposeCPU Error: src size (" << src.size()
                  << ") is smaller than expected (" << C * H * W << ")" << std::endl;
        return src; // Zwróć oryginał, żeby uniknąć crasha
    }

    std::vector<float> dst(C * H * W);

    for (int c = 0; c < C; ++c) {
        for (int w = 0; w < W; ++w) {
            for (int h = 0; h < H; ++h) {
                // Układ CWH (wejście): [kanał][szerokość][wysokość]
                size_t src_idx = (size_t)c * W * H + (size_t)w * H + h;

                // Układ CHW (wyjście): [kanał][wysokość][szerokość]
                size_t dst_idx = (size_t)c * H * W + (size_t)h * W + w;

                dst[dst_idx] = src[src_idx];
            }
        }
    }
    return dst;
}