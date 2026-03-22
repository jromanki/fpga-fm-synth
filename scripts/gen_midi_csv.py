import re
import csv

# This scripts cleans out table taken out from wikipedia
# https://en.wikipedia.org/wiki/Piano_key_frequencies

PATH = 'scripts/midi_freqs'

header = ["Key num", "MIDI mesg", "Frequency", "Note name"]
notes = []

with open(PATH, 'r') as f:
    for line in f:
        line = line.strip()

        space_sep = line.split()

        freq = re.search(r"\b\d+\.\d+\b", line).group()
        notes.append([space_sep[0], space_sep[1], freq, space_sep[2]])

with open('scripts/midi.csv', 'w') as f:
    writer = csv.writer(f, delimiter=' ')
    writer.writerow(header)
    for row in notes:
        writer.writerow(row)
