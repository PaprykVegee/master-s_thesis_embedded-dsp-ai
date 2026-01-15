import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import firwin, lfilter

FS = 50000  # częstotliwość próbkowania

# Wczytanie sygnałów
filtred_signal_cpu = np.loadtxt(r"/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/filterd_signal_cpu.txt")
filtred_signal_gpu = np.loadtxt(r"/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/filterd_signal_gpu.txt")
orginal_signal = np.loadtxt(r"/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/sum_sin_signal.txt")

# Parametry filtra FIR
N = 60           # rząd filtra
cutoff = 300     # częstotliwość odcięcia w Hz
nyq = FS / 2     # częstotliwość Nyquista

# Projektowanie filtra FIR
fir_coeff = firwin(N + 1, cutoff / nyq)

# Wyświetlenie współczynników w konsoli
print("Współczynniki filtra FIR (N=60, fc=300Hz):")
print(', '.join(map(str, fir_coeff)))

# Filtracja sygnału oryginalnego
sig_fir = lfilter(fir_coeff, 1.0, orginal_signal)

# Oś czasu
t = np.arange(len(orginal_signal)) / FS

# Tworzenie subplotów: 3 wiersze, 1 kolumna
fig, axs = plt.subplots(3, 1, figsize=(12, 12))

# Górny subplot: wszystkie sygnały
axs[0].plot(t, orginal_signal, label='Sygnał oryginalny')
axs[0].plot(t, filtred_signal_cpu, label='Sygnał filtrowany CPU')
axs[0].plot(t, sig_fir, label='Sygnał FIR (N=60, fc=300Hz)')
axs[0].set_xlabel('Czas [s]')
axs[0].set_ylabel('Amplituda')
axs[0].set_title('Porównanie sygnałów')
axs[0].legend()
axs[0].grid(True)

# Środkowy subplot: sygnał filtrowany CPU
axs[1].plot(t, filtred_signal_cpu, color='orange', label='Sygnał filtrowany CPU')
axs[1].plot(t, filtred_signal_gpu, color='orange', label='Sygnał filtrowany GPU')
axs[1].set_xlabel('Czas [s]')
axs[1].set_ylabel('Amplituda')
axs[1].set_title('Sygnał filtrowany CPU')
axs[1].legend()
axs[1].grid(True)

# Dolny subplot: sygnał po filtrze FIR
axs[2].plot(t, sig_fir, color='green', label='Sygnał FIR (N=60, fc=300Hz)')
axs[2].set_xlabel('Czas [s]')
axs[2].set_ylabel('Amplituda')
axs[2].set_title('Sygnał po filtrze FIR')
axs[2].legend()
axs[2].grid(True)

plt.tight_layout()
plt.show()
