//
// Created by patryk on 25.12.25.
//

#include <vector>

#ifndef UTILS_H
#define UTILS_H


void findMinMaxGPU(float* d_data, float* d_min_out, float* d_max_out, int N);
void findMinMaxCPU(std::vector<float> data, float* min, float* max);

void cudaWarmup();


#endif //UTILS_H
