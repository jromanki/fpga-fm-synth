import numpy as np
import matplotlib.pyplot as plt

DEBUG = False

FILENAME = "wave-rom.vh"
LINES = 64
BITS_IN_LINE = 256
BIT_DEPTH = 32

TOTAL_SAMPLE_NUM = int(LINES * (BITS_IN_LINE / BIT_DEPTH))

def gen_sine_samples():
    samples = np.zeros(TOTAL_SAMPLE_NUM, dtype=object)

    for sample_num in range(TOTAL_SAMPLE_NUM):
        samples[sample_num] = np.sin(np.pi / 2 * sample_num / TOTAL_SAMPLE_NUM)

    if DEBUG:
        xpoints = range(0, TOTAL_SAMPLE_NUM)
        ypoints = samples
        plt.plot(xpoints, ypoints, "*--")
        plt.show()

    return samples

def int_to_2s_comp_str(num):
    temp = ((1 << BIT_DEPTH) - 1) & num
    return f"{temp:0{BIT_DEPTH}b}"

def samples_float_to_2s_comp_str(samples):
    max_val = (2**(BIT_DEPTH - 1)) - 1

    for sample_num in range(TOTAL_SAMPLE_NUM):
        sample = samples[sample_num]
        sample = int(round(sample * max_val))
        sample = int_to_2s_comp_str(sample)
        samples[sample_num] = sample
    
    return samples

def addr_to_hex_str(addr: int):
    return f'{addr:0>2X}'

def bin_str_to_hex_str(num_str):
    hex_width = BIT_DEPTH // 4
    num_int = int(num_str, 2)
    hex_str = f"{num_int:0{hex_width}x}".upper()
    return hex_str


def create_lines():
    float_samples = gen_sine_samples()
    bin_samples = samples_float_to_2s_comp_str(float_samples)

    lines = ""
    lines += "`ifndef _wave_vh_\n`define _wave_vh_\n"

    samples_in_line = BITS_IN_LINE // BIT_DEPTH
    sample_num = 0
    for line_num in range(LINES):
        line_data = []
        for line_sample_num in range(samples_in_line):
            sample = bin_samples[line_num * samples_in_line + line_sample_num]
            line_data.append(bin_str_to_hex_str(sample))

        data_str = ''.join(line_data[::-1])

        lines += f"      defparam rom.INIT_RAM_{addr_to_hex_str(line_num)} = 256'h{data_str};\n"
    
    lines += "`endif"
    return lines

def main():
    with open(FILENAME, "w") as f:
        samples = gen_sine_samples()
        lines = create_lines()
        f.write(lines)

if __name__ == "__main__":
    main()