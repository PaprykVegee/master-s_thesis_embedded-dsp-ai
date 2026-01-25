#include <cuda_runtime.h>
#include "utils.h"

#include <device_functions.h>
#include <float.h>
#include <cuda_fp16.h>

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

__global__ void resize_chw_kernel(
    const float* __restrict__ src,
    float* __restrict__ dst,
    int C, int H_in, int W_in,
    int H_out, int W_out
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int z = blockIdx.z;

    if (x >= W_out || y >= H_out || z >= C) return;
    if (W_out == 1 || H_out == 1) return;

    float x_ratio = (float)(W_in - 1) / (W_out - 1);
    float y_ratio = (float)(H_in - 1) / (H_out - 1);

    float x_src = x_ratio * x;
    float y_src = y_ratio * y;

    int x_l = (int)x_src;
    int y_l = (int)y_src;
    int x_h = min(x_l + 1, W_in - 1);
    int y_h = min(y_l + 1, H_in - 1);

    float x_w = x_src - x_l;
    float y_w = y_src - y_l;

    int in_base  = z * H_in * W_in;
    int out_base = z * H_out * W_out;

    float a  = src[in_base + y_l * W_in + x_l];
    float b  = src[in_base + y_l * W_in + x_h];
    float c0 = src[in_base + y_h * W_in + x_l];
    float d  = src[in_base + y_h * W_in + x_h];

    dst[out_base + y * W_out + x] =
        a  * (1 - x_w) * (1 - y_w) +
        b  * x_w       * (1 - y_w) +
        c0 * (1 - x_w) * y_w +
        d  * x_w       * y_w;
}

float* ResizeBilinear_chw_GPU(
    float* src,
    int h_in, int w_in,
    int h_out, int w_out,
    int c_num,
    bool return_gpu
) {
    float* d_output;
    // POPRAWKA 1: Rozmiar wyjściowy (H_out * W_out * C)
    size_t out_size = sizeof(float) * h_out * w_out * c_num;
    cudaMalloc((void**)&d_output, out_size);

    dim3 block(16, 16, 1);
    dim3 grid(
        (w_out + block.x - 1) / block.x,
        (h_out + block.y - 1) / block.y,
        c_num
    );

    // POPRAWKA 2: Grid i Block we właściwych miejscach
    resize_chw_kernel<<<grid, block>>>(src, d_output, c_num, h_in, w_in, h_out, w_out);

    // Sprawdzenie błędów kernela (opcjonalnie, ale zalecane)
    cudaDeviceSynchronize();

    if (return_gpu)
        return d_output;

    float* h_output = new float[h_out * w_out * c_num];
    cudaMemcpy(h_output, d_output, out_size, cudaMemcpyDeviceToHost);

    cudaFree(d_output);
    return h_output;
}

__global__ void TransposeKernel(const float* src, float* dst, int H, int W, int C) {
    int w = blockIdx.x * blockDim.x + threadIdx.x;
    int h = blockIdx.y * blockDim.y + threadIdx.y;
    int c = blockIdx.z; // Indeks kanału

    if (w < W && h < H) {
        int src_idx = c * (W * H) + w * H + h;

        int dst_idx = c * (H * W) + h * W + w;

        dst[dst_idx] = src[src_idx];
    }
}

float* TransposeGPU(float* src, int num_rows, int num_cols, bool return_gpu) {
    int H = num_rows;
    int W = num_cols;
    int C = 3;

    float* d_dst;
    size_t size = C * H * W * sizeof(float);

    cudaError_t err = cudaMalloc(&d_dst, size);
    if (err != cudaSuccess) return nullptr;

    dim3 threads(16, 16, 1);
    dim3 blocks((W + threads.x - 1) / threads.x,
                (H + threads.y - 1) / threads.y,
                C);

    TransposeKernel<<<blocks, threads>>>(src, d_dst, H, W, C);

    cudaDeviceSynchronize();

    if (return_gpu)
        return d_dst;

    float* h_dst = new float[H * W * C];

    cudaMemcpy(h_dst, src, size, cudaMemcpyHostToDevice);

    return h_dst;
}


void cudaWarmup() {
    cudaFree(0);
}
