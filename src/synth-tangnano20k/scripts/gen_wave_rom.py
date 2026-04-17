import numpy as np
import matplotlib.pyplot as plt

DEBUG = False

FILENAME = "src/dds/wave-rom"
LINES = 128
BITS_IN_LINE = 256
BIT_DEPTH = 32
NUM_OF_FILES = 1

TOTAL_SAMPLE_NUM = int(LINES * (BITS_IN_LINE / BIT_DEPTH))

def gen_sine_samples(start, end):
    # generate np array wit 1/4 sine period
    t = np.linspace(start, end, TOTAL_SAMPLE_NUM, endpoint=False, dtype=np.float64)
    # t = np.linspace(0, np.pi/2, TOTAL_SAMPLE_NUM, endpoint=False, dtype=np.float64)
    samples = np.sin(t)
    return samples

def int_to_2s_comp_str(num):
    temp = ((1 << BIT_DEPTH) - 1) & num
    return f"{temp:0{BIT_DEPTH}b}"

def samples_float_to_2s_comp_str(samples):
    # Use the actual max positive value for 32-bit signed
    max_pos = np.float64((1 << (BIT_DEPTH - 1)) - 1)

    bin_samples = []
    for s in samples:
        # Proper rounding to the nearest 32-bit integer
        val = int(np.round(s * max_pos))
        bin_samples.append(int_to_2s_comp_str(val))
    
    return bin_samples

def addr_to_hex_str(addr: int):
    return f'{addr:0>2X}'

def bin_str_to_hex_str(num_str):
    hex_width = BIT_DEPTH // 4
    num_int = int(num_str, 2)
    hex_str = f"{num_int:0{hex_width}x}".upper()
    return hex_str


def create_lines(file_num, start, end):
    float_samples = gen_sine_samples(start, end)
    bin_samples = samples_float_to_2s_comp_str(float_samples)

    lines = ""
    lines += f"`ifndef _wave_vh{file_num}_\n`define _wave_vh{file_num}_\n"

    samples_in_line = BITS_IN_LINE // BIT_DEPTH
    sample_num = 0
    total_lines = []
    for line_num in range(LINES):
        line_data = []
        for line_sample_num in range(samples_in_line):
            sample = bin_samples[line_num * samples_in_line + line_sample_num]
            line_data.append(bin_str_to_hex_str(sample))

        total_lines.append(line_data)
        data_str = ''.join(reversed(line_data))


        lines += f"      defparam rom{file_num}.INIT_RAM_{addr_to_hex_str(line_num)} = 256'h{data_str};\n"
    print(total_lines)
    lines += "`endif"
    return lines

def main():
    for file_num in range(NUM_OF_FILES):
        with open(f"{FILENAME}{file_num}.vh", "w") as f:
            start = np.pi/(2 * NUM_OF_FILES) * file_num
            end = np.pi/(2 * NUM_OF_FILES) * (file_num + 1)

            lines = create_lines(file_num, start, end)
            f.write(lines)

if __name__ == "__main__":
    main()