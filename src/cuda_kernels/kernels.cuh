#include "cuda_runtime.h"
#include "cufft.h"

#ifndef KERNELS_H
#define KERNELS_H

__global__
void firKernel(
    const float* d_signal,
    float* d_output,
    const float* d_coeffs,
    int signal_length,
    int order);

__global__
void applyWindow(
    const float* signal,
    float* d_output,
    const float* window,
    const int signal_size,
    const int window_size,
    const int overlap);

__global__
void computeMagnitude(
    cufftComplex* d_fft,
    float* d_mag,
    int N);

__global__
void normSignal(
    float* d_input,
    float* d_output,
    float d_min,
    float d_max,
    float norm_val,
    int N);

__global__
void threshold_kernel(
    float* d_input,
    float* d_output,
    int N,
    float trashold);

__global__ 
void standardScaler_kernel(
    float* d_input,
    float* d_output,
    int N,
    float mean,
    float std);
#endif