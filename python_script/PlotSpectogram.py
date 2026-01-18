import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import stft, firwin, filtfilt, lfilter

# 1️⃣ Wczytaj dane
data_cpu = np.loadtxt("../data/spectrogram_cpu.txt")
data_gpu = np.loadtxt("../data/spectrogram_gpu.txt")
ref_data = np.loadtxt("../data/test_data.txt")

# Parametry (muszą być zgodne z kodem C++)
fs = 50000
N = 512
hop = 256
n_bins_cpu = N // 2 + 1     # Twoja klasa STFTApplyer na CPU zwraca winSize / 2
n_bins_gpu = N // 2 + 1     # Klasa STFTApplyer na GPU (cuFFT D2Z) zwraca winSize / 2 + 1

print(data_cpu.shape, data_gpu.shape)

# 2️⃣ Zamień na macierze i oblicz dB
# CPU
n_cols_cpu = len(data_cpu) // n_bins_cpu
spectrogram_cpu = data_cpu.reshape((n_cols_cpu, n_bins_cpu)).T
spectrogram_cpu_db = 20 * np.log10(spectrogram_cpu + 1e-10)

# GPU
n_cols_gpu = len(data_gpu) // n_bins_gpu
spectrogram_gpu = data_gpu.reshape((n_cols_gpu, n_bins_gpu)).T
spectrogram_gpu_db = 20 * np.log10(spectrogram_gpu + 1e-10)

# 3️⃣ Filtracja sygnału referencyjnego FIR
lowcut = 3000    # dolna częstotliwość [Hz]
highcut = 8000   # górna częstotliwość [Hz]
numtaps = 101    # liczba współczynników FIR

# Normalizacja częstotliwości do Nyquista
nyq = fs / 2
low = lowcut / nyq
high = highcut / nyq

# Projekt filtra FIR (bandpass)
fir_coeff = firwin(numtaps, [low, high], pass_zero=False)

# Filtracja sygnału (filtfilt dla zerowej fazy)
ref_data_filtered = filtfilt(fir_coeff, [1.0], ref_data)

# 4️⃣ Oblicz STFT referencyjne (SciPy)
f, t, Zxx = stft(ref_data_filtered, fs=fs, nperseg=N, noverlap=N-hop)
spectrogram_ref_db = 20 * np.log10(np.abs(Zxx) + 1e-10)

# 5️⃣ Wyświetl trzy spektrogramy obok siebie
plt.figure(figsize=(18, 6))

# a) Spektrogram CPU
plt.subplot(1, 3, 1)
plt.imshow(spectrogram_cpu_db, aspect='auto', origin='lower', cmap='magma')
plt.colorbar(label='Amplitude [dB]')
plt.title('CPU Spectrogram')
plt.ylabel('Frequency bins')

# b) Spektrogram GPU
plt.subplot(1, 3, 2)
plt.imshow(spectrogram_gpu_db, aspect='auto', origin='lower', cmap='magma')
plt.colorbar(label='Amplitude [dB]')
plt.title('GPU Spectrogram (cuFFT)')
plt.xlabel('Time frames')

# c) Spektrogram referencyjny (SciPy + FIR)
plt.subplot(1, 3, 3)
plt.pcolormesh(t, f, spectrogram_ref_db, shading='gouraud', cmap='magma')
plt.colorbar(label='Amplitude [dB]')
plt.title('Reference Spectrogram (SciPy, FIR filtered)')
plt.ylabel('Frequency [Hz]')
plt.ylim(0, fs/2)

plt.tight_layout()
plt.show()
