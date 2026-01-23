import numpy as np

filename = "/home/patryk/Desktop/MASTER_THIESIS/CUDA/data/input.txt"
fs = 50000
N = 300000
frequencies = [10, 50, 120, 1000, 2000, 3000, 10000]
amplitudes = [1000, 1, 1, 1, 1, 1, 1]
#amplitudes = [0,0, 0, 0, 0]

t = np.arange(N) / fs
signal = np.zeros(N)
for f, a in zip(frequencies, amplitudes):
    signal += a * np.sin(2 * np.pi * f * t)

noise = np.random.normal(0, 1, t.shape)
signal += noise

with open(filename, "w") as f:
    for s in signal:
        f.write(f"{s}\n")

print(f"Sygnał zapisany do {filename} ({N} próbek)")
