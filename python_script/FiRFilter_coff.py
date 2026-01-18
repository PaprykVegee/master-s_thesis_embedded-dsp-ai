import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, freqz, firwin

# Parametry
fs = 50000
lowcut = 3000
highcut = 8000
numtaps = 101

nyq = fs / 2
low = lowcut / nyq
high = highcut / nyq

fir_coeff = firwin(numtaps, [low, high], pass_zero=False)
w_fir, h_fir = freqz(fir_coeff, worN=8000, fs=fs)

b_iir, a_iir = butter(N=5, Wn=[low, high], btype='band')
w_iir, h_iir = freqz(b_iir, a_iir, worN=8000, fs=fs)

result = ", ".join(str(x) for x in fir_coeff)

print(result)

plt.figure(figsize=(10,6))
plt.plot(w_fir, 20 * np.log10(np.abs(h_fir)), label='FIR bandpass', linewidth=2)
plt.plot(w_iir, 20 * np.log10(np.abs(h_iir)), label='Butterworth 4. rzędu', linewidth=2, linestyle='--')
plt.title('Charakterystyka Bodego filtrów bandpass')
plt.xlabel('Częstotliwość [Hz]')
plt.ylabel('Wzmocnienie [dB]')
plt.grid(True)
plt.legend()
plt.show()
