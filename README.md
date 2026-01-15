# Design and Implementation of a Machine Learning Algorithm for Stress Analysis in Mining Anchors on an Embedded System

## Project Overview

This repository contains the master’s thesis project focused on the **design and implementation of a machine learning algorithm for stress analysis in mining anchors**.  
The main goal is to implement the algorithm and AI pipeline on **embedded platforms**, targeting resource-constrained devices:

- **NVIDIA Jetson Nano** (embedded GPU)
- **Kria KV260** (FPGA)

The project combines **signal processing, feature extraction, and deep learning classification** for mining anchor measurement signals, and aims to deploy the full pipeline efficiently on these embedded devices.

This project is a continuation of the engineering thesis available at:  
[Engineering Thesis – Time Signal Classification](https://github.com/PaprykVegee/engineering-thesis---time-signal-classification)

---

## Summary of Engineering Thesis

The engineering thesis focused on applying **machine learning to monitor the state of mining anchors**, enabling precise stress monitoring and increasing safety in mines.  

Self-Excited Acoustic Vibrations (SAS), based on positive feedback, allowed monitoring of vibration frequencies and detection of anchor damage, providing data on their stability.  

Data from the "Wieliczka" and "Ziemowit" mines were processed using **band-pass filtering**, **Z-score normalization**, and **Short-Time Fourier Transform (STFT)** analysis to generate **RGB spectrograms** as input data for the machine learning model.  

The model was based on a **Vision Transformer (ViT) architecture**, using **Multi-Head Attention** to analyze global dependencies in the spectrogram images. Training was performed using **CrossEntropyLoss** and the **AdamW optimizer**, achieving high classification accuracy. Results were validated on "Wieliczka" test data and "Ziemowit" validation data, demonstrating the effectiveness of transformer-based methods for industrial applications and enabling fast, precise monitoring of mining anchor conditions.

---

## Repository Structure

The `main` branch contains the **overview and documentation** of the project.  
All concrete implementations and experiments are organized in separate branches:

| Branch | Contents |
|--------|----------|
| `cuda-implementation` | Full pipeline implemented on **CUDA**, including signal processing, feature extraction, and deep neural network. |
| `fpga-implementation` | FPGA implementation for **Kria KV260**, including source files, synthesis scripts, and hardware description files (HDL/HLS). |
| `net_prep` | Pipeline for **training and testing the neural network**, including model preparation, training scripts, and evaluation under **XAI (explainable AI)** scenarios. |

> Each branch contains its own `README.md` with detailed instructions and dependencies specific to that implementation.

---

## Goals

1. **Design and implement a machine learning pipeline** for stress analysis of mining anchors.  
2. **Deploy the pipeline on embedded devices** (Jetson Nano and Kria KV260) efficiently.  
3. **Prepare and train neural network models**, including feature extraction and classification.  
4. **Enable explainable AI (XAI) testing** for model evaluation and interpretation.  

---
