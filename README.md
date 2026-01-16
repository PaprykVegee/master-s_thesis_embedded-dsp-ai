# Jetson CUDA Implementation – Signal Processing and Classification Pipeline

## Overview

This branch contains the **implementation of the signal processing and machine learning algorithm on CPU and GPU (CUDA)**, targeting **embedded GPU platforms such as NVIDIA Jetson Nano**.

The implementation includes:
- a complete **DSP processing pipeline**,
- **GPU-accelerated computation** using CUDA,
- **CPU reference implementation** for comparison,
- and **tests and validation routines**.

---

## Algorithm Pipeline

The implemented algorithm follows the processing pipeline shown below:

1. **Input data loading**  
   Measurement signals are loaded from input files.

2. **FIR filtering**  
   Signals are filtered using a **Finite Impulse Response (FIR) filter** to isolate the frequency band of interest.

3. **Time windowing**  
   The filtered signal is divided into fixed-length **time windows**.

4. **Overlapping windows**  
   Consecutive windows are generated with a defined **overlap** to preserve temporal continuity.

5. **Fast Fourier Transform (FFT)**  
   FFT is applied to each window to transform the signal into the frequency domain.

6. **Normalization**  
   Frequency-domain data is normalized to improve numerical stability and robustness.

7. **Thresholding**  
   A thresholding stage is applied to suppress noise and irrelevant components.

8. **Neural network classification**  
   The processed features are passed to a **neural network model** for classification.

---

## Implementation Details

- **CPU implementation**  
  Used as a reference version and for debugging and validation.

- **CUDA implementation**  
  Computationally intensive stages (filtering, FFT, normalization, and preprocessing) are accelerated using **CUDA kernels**.

- **Target platform**  
  - NVIDIA Jetson Nano  
  - CUDA-enabled GPUs


## Implementation Details

- **CPU implementation**  
  Used as a reference and for validation.

- **CUDA implementation**  
  Performance-critical stages are accelerated using **CUDA**.

- **Target platform**  
  - NVIDIA Jetson Nano  
  - CUDA-capable GPUs

---
