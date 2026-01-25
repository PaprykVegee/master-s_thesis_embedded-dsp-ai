import matplotlib.pyplot as plt
import numpy as np

# --- 1. ORYGINAŁ (129 binów x 10545 ramek łącznie) ---
raw_gpu = np.loadtxt("../data/spectrogram_gpu.txt")
raw_resize = np.loadtxt("../data/resize_spec.txt")


fig, axes = plt.subplots(1, 2, figsize=(16, 7))

raw_gpu = raw_gpu.reshape(3, 3515, 129)#.transpose(0, 2, 1)
raw_resize = raw_resize.reshape(3, 256, 256)#.transpose(0, 2, 1)

axes[0].imshow(raw_gpu.transpose(1, 2, 0), aspect='auto', origin='lower')
axes[1].imshow(raw_resize.transpose(1, 2, 0), aspect='auto', origin='lower')
plt.show()