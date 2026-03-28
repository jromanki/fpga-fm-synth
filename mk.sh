#!/bin/sh

set -e 

SRC_FILES="src/pll.v \
src/top.v \
src/i2s.v \
src/spi_parser.v \
src/dds/pROM-wave-rom.v \
src/dds/sine_dds.v \
src/dds/sine-lookup.v \
src/spi/neg_edge_det.v \
src/spi/pos_edge_det.v \
src/spi/spi_module.v"

OUT_DIR=build
SERIAL_NUM=2025012315

yosys -p "read_verilog $SRC_FILES; synth_gowin -json $OUT_DIR/top-synth.json -family gw2a"
#yosys  -p "read_verilog pll.v pROM-wave-rom.v sine-lookup.v top.v i2s.v; synth_gowin -vout top-synth.vg -setundef"
nextpnr-himbaechel -v --debug --json $OUT_DIR/top-synth.json --write $OUT_DIR/top.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=pinout.cst &> /dev/null
gowin_pack -d GW2A-18C -o $OUT_DIR/top.fs $OUT_DIR/top.json &> /dev/null
# openFPGALoader --ftdi-serial $SERIAL_NUM -f $OUT_DIR/top.fs
openFPGALoader --ftdi-serial $SERIAL_NUM $OUT_DIR/top.fs