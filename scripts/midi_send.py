import rtmidi
import time

midi_out = rtmidi.MidiOut()
ports = midi_out.get_ports()
print("Available MIDI ports:", ports)

# Open your UM-1 interface
port_index = ports.index('UM-1:UM-1 MIDI 1 24:0')
midi_out.open_port(port_index)

# Send middle C, velocity 64, channel 1
midi_out.send_message([0x90, 60, 64])
time.sleep(0.5)

# Send Note Off
midi_out.send_message([0x80, 60, 0])

midi_out.close_port()