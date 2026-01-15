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