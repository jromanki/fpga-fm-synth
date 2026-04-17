import csv

CLK_FREQ = 49.5 * 10**6
BIT_DEPTH = 32

def get_phase_inc(freq: float):
    return round(((freq * 2**BIT_DEPTH) / CLK_FREQ) / 2)

def main():
    phase_inc_arr = []

    with open('scripts/midi.csv', 'r') as f:
        # Skip first row (header)
        rows = list(csv.reader(f, delimiter=' '))[1::]
        table_len = len(rows) - 1
        first_midi_num = int(rows[-1][1])
        rows = rows[::-1]
        
        # pad array with zeros for non existing notes
        for i in range(first_midi_num):
            phase_inc_arr.append(0)
        
        for i, row in enumerate(rows):
            freq = float(row[2])
            phase_inc = get_phase_inc(freq)
            phase_inc_arr.append(phase_inc)
    

    c_array = "uint32_t midi_to_phase_inc_arr[] = { " + ", ".join(f"{n}" for n in phase_inc_arr) + " };"
    print(c_array)
    print(f"A note (110 Hz) phase inc = {phase_inc_arr[45+12]}")

if __name__ == '__main__':
    main()