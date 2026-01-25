//
// Created by patryk on 25.12.25.
//

#include <vector>
#include <cmath>
#include <iostream>

#ifndef UTILS_H
#define UTILS_H


void findMinMaxGPU(float* d_data, float* d_min_out, float* d_max_out, int N);
void findMinMaxCPU(std::vector<float> data, float* min, float* max);

std::vector<float> ResizeBilinear_CPU_CHW(const std::vector<float>& src, int H_in, int W_in, int C, int H_out, int W_out);
float* ResizeBilinear_chw_GPU(float* src, int h_in, int w_in, int h_out, int w_out, int c_num, bool return_gpu = true);

std::vector<float> TransposeCPU(std::vector<float> src, int num_rows, int num_cols);
float* TransposeGPU(float* src, int num_rows, int num_cols, bool return_gpu = true);

void cudaWarmup();


#endif //UTILS_H
