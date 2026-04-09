# This script generates a 128 element uint16_t C array
# containing exponential curve with values of 0-65535.

# The array is meant to be used as a multiplier of the
# output sample value to provide smooth perceptual
# volume scaling

import numpy as np
import matplotlib.pyplot as plt

DEBUG = True

BITS = 16
MAX_VAL = 2**BITS - 1
MIN_DB = -60
MAX_DB = 0

x = np.arange(128)
db = MIN_DB + (x / 127) * (MAX_DB - MIN_DB)

# convert DB to linear
amp = 10 ** (db / 20)
y = amp * MAX_VAL

# Make encoder at zero position mute audio completly
y[0] = 0

# C array code ready to be copied onto a microcontroller
c_array = "uint16_t exp_volume_arr[] = { " + ", ".join(f"{int(np.round(n))}" for n in y) + " };"
print(c_array)

if DEBUG:
    # visualize curve
    plt.plot(x, y, "*-")
    plt.title("Exponential Volume Curve")
    plt.xlabel("Encoder value")
    plt.ylabel("Amplitude multiplier")
    plt.show()