#include <cuda_runtime.h>
#include "utils.h"

#include <device_functions.h>
#include <float.h>

__device__ static float atomicMin_float(float* address, float val) {
    int* address_as_i = (int*)address;
    int old = *address_as_i, assumed;
    do {
        assumed = old;
        old = atomicCAS(address_as_i, assumed,
            __float_as_int(fminf(__int_as_float(assumed), val)));
    } while (assumed != old);
    return __int_as_float(old);
}

__device__ static float atomicMax_float(float* address, float val) {
    int* address_as_i = (int*)address;
    int old = *address_as_i, assumed;
    do {
        assumed = old;
        old = atomicCAS(address_as_i, assumed,
            __float_as_int(fmaxf(__int_as_float(assumed), val)));
    } while (assumed != old);
    return __int_as_float(old);
}

__global__ void MinMaxKernel(const float* data, float* g_min, float* g_max, int N) {
    extern __shared__ float s_mem[];
    float* s_min = s_mem;
    float* s_max = &s_mem[blockDim.x];

    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    float val_min = FLT_MAX;
    float val_max = -FLT_MAX;

    if (idx < N) {
        val_min = data[idx];
        val_max = data[idx];
    }

    s_min[tid] = val_min;
    s_max[tid] = val_max;
    __syncthreads();

    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            s_min[tid] = fminf(s_min[tid], s_min[tid + s]);
            s_max[tid] = fmaxf(s_max[tid], s_max[tid + s]);
        }
        __syncthreads();
    }

    if (tid == 0) {
        atomicMin_float(g_min, s_min[0]);
        atomicMax_float(g_max, s_max[0]);
    }
}


void findMinMaxGPU(float* d_data, float* d_min_out, float* d_max_out, int N) {
    if (N <= 0) return;

    float h_init_min = FLT_MAX;
    float h_init_max = -FLT_MAX;

    cudaMemcpy(d_min_out, &h_init_min, sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_max_out, &h_init_max, sizeof(float), cudaMemcpyHostToDevice);

    int threads = 256;
    int blocks = (N + threads - 1) / threads;

    size_t sharedMemSize = 2 * threads * sizeof(float);

    MinMaxKernel<<<blocks, threads, sharedMemSize>>>(d_data, d_min_out, d_max_out, N);
}

void cudaWarmup() {
    cudaFree(0);
}