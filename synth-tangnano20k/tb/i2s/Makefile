USER_MODULE = i2s.v
TESTBENCH   = i2s_tb.v
OUTPUT      = build/sim.out
WAVEFORM    = build/i2s_test.vcd

all: clean build run

build:
	mkdir -p build
	iverilog -o $(OUTPUT) $(USER_MODULE) $(TESTBENCH)

run:
	vvp $(OUTPUT)

wave: all
	@if [ -f view.gtkw ]; then \
		gtkwave $(WAVEFORM) view.gtkw; \
	else \
		gtkwave $(WAVEFORM); \
	fi

clean:
	rm -rf build