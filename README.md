# FPGA Embedded DSP + AI Pipeline – KV260 Vision AI Implementation

## Overview

This branch contains the implementation of a **real-time signal processing and classification pipeline** on FPGA, targeting the **Xilinx KV260 Vision AI Kit**.  

The implementation includes:

- Real-time DSP processing pipeline in FPGA PL (Programmable Logic),
- Immediate spectrogram computation (STFT) from ADC samples,
- DMA-based transfer of spectrogram columns to PS (ARM processor),
- Neural network classification in FPGA,
- Data structuring in PS across multiple measurements.

The pipeline has been **tested on the KV260 Vision AI platform**.

---

## Algorithm Pipeline

The implemented algorithm follows the processing pipeline shown below:

1. **Signal acquisition**  
   - Analog signals enter the system through the ADC.  
   - **50,000 samples** are collected **per measurement**, processed immediately in real-time.

2. **IIR Filtering**  
   - Incoming signals are filtered in FPGA PL using an **IIR filter** as soon as they arrive.

3. **Real-time Spectrogram (STFT) computation**  
   - Spectrogram columns are calculated on-the-fly from filtered samples in PL.  
   - Columns are streamed via DMA directly to PS (ARM processor) without buffering.  
   - The process is repeated for **three measurements**.

4. **Data structuring in PS**  
   - Spectrogram columns from multiple measurements are organized per channel.  
   - The final data structure has the shape `(height, width, 3)`.

5. **Resizing (bilinear interpolation)**  
   - Structured data is sent back to PL for **bilinear resizing** before neural network input.

6. **Neural network classification**  
   - Preprocessed spectrograms are fed to an FPGA-based neural network for classification.

---

## Implementation Details

### PL (FPGA) Implementation
- Performs **real-time filtering**, **STFT/spectrogram computation**, and **resizing**.  
- Uses DMA for high-speed column-wise transfer to PS.  
- Implements bilinear interpolation before passing data to neural network.

### PS (ARM) Implementation
- Receives spectrogram columns via DMA.  
- Organizes data across channels and measurements.  
- Minimal preprocessing before sending data back to PL for resizing and classification.

### Target Platform
- **Xilinx KV260 Vision AI Kit**  
- ARM Cortex-A53 processor (PS)  
- Programmable Logic (PL) for real-time DSP and AI acceleration  

---

## Usage
1. Connect the analog signal source to the ADC.  
2. Start the FPGA pipeline.  
3. The system automatically:
   - Processes ADC samples in real-time
   - Filters the signal
   - Computes STFT/spectrogram columns
   - Transfers columns to PS
   - Resizes data in PL
   - Performs neural network classification  
4. Classification results can be read from PS or output interface.

---

