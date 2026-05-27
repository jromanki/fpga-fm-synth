import csv

CLK_FREQ = 49.5 * 10**6
BIT_DEPTH = 32

def get_phase_inc(midi_note: int):
    return round(440/CLK_FREQ * 2**((midi_note - 69 + (12*BIT_DEPTH))/12))

def main():
    phase_inc_arr = []
    
    for i in range(128):
        phase_inc_arr.append(get_phase_inc(i))

    c_array = "uint32_t midi_to_phase_inc_arr[] = { " + ", ".join(f"{n}" for n in phase_inc_arr) + " };"
    print(c_array)
    print(f"A note (110 Hz) phase inc = {phase_inc_arr[45+12]}")

if __name__ == '__main__':
    main()