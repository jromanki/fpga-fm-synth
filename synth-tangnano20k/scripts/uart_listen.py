import serial

ser = serial.Serial('/dev/ttyUSB0', 31250)
ignored = [0]

while True:
    data = ser.read(1)
    byte = data[0]
    if byte not in ignored:
        print(f"{byte:08b}")  # 8-bit binary, no 0b prefix