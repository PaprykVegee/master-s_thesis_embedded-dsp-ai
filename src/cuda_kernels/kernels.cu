#include "kernels.cuh"

__global__ void firKernel(
    const float* d_signal,
    float* d_output,
    const float* d_coeffs,
    int signal_length,
    int order)
{
    extern __shared__ float s_signal[];

    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + tid;
    int s_idx = tid + order - 1;

    if (idx < signal_length) {
        s_signal[s_idx] = d_signal[idx];
    }

    if (tid < order - 1) {
        int halo_idx = idx - (order - 1);
        s_signal[tid] = (halo_idx >= 0) ? d_signal[halo_idx] : 0.0;
    }

    __syncthreads();

    // Liczenie FIR
    if (idx < signal_length) {
        float acc = 0.0;
        for (int i = 0; i < order; ++i) {
            acc += d_coeffs[i] * s_signal[s_idx - i];
        }
        d_output[idx] = acc;
    }
}

__global__ void applyWindow(
    const float* signal,
    float* d_output,
    const float* window,
    const int signal_size,
    const int window_size,
    const int overlap)
{
    int hop = window_size - overlap;
    int N = (signal_size - window_size) / hop + 1;

    int tid = threadIdx.x;
    int frame_idx = blockIdx.x;
    int block_size = blockDim.x;

    if (frame_idx >= N) return;

    extern __shared__ float s_signal[];

    int start_idx = frame_idx * hop;

    // ladowanie ramki
    for (int i = tid; i < window_size; i += block_size) {
        s_signal[i] = signal[start_idx + i] * window[i];
    }
    __syncthreads();

    // zapis do pamieci globalnej
    for (int i = tid; i < window_size; i += block_size) {
        d_output[frame_idx * window_size + i] = s_signal[i];
    }
}
__global__ void computeMagnitude(cufftComplex* d_fft, float* d_mag, int N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        float re = d_fft[idx].x;
        float im = d_fft[idx].y;

        d_mag[idx] = sqrtf(re * re + im * im);
    }
}

__global__ void normSignal(float* d_input, float* d_output, float d_min, float d_max, float norm_val, int N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < N) {
        d_output[idx] = norm_val*(d_input[idx] - d_min) / (d_max - d_min);
    }
}

__global__ void threshold_kernel(float* d_input, float* d_output, int N, float trashold) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        d_output[idx] = (d_input[idx] > trashold) ? 1.0f: 0.0f;
    }
}