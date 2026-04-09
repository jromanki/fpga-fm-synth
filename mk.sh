#!/bin/sh

set -e 

SRC_FILES="src/pll.v \
src/top.v \
src/i2s.v \
src/spi_parser.v \
src/s32_x_u16_mult.v \
src/dds/pROM-wave-rom.v \
src/dds/voice.v \
src/dds/sine-lookup.v \
src/dds/amp.v \
src/spi/neg_edge_det.v \
src/spi/pos_edge_det.v \
src/spi/spi_module.v"

OUT_DIR=build
SERIAL_NUM=2025012315

yosys -p "read_verilog $SRC_FILES; synth_gowin -json $OUT_DIR/top-synth.json -family gw2a" > build/yosys-log.txt
nextpnr-himbaechel -v --debug --json $OUT_DIR/top-synth.json --write $OUT_DIR/top.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=pinout.cst > build/nextpnr-log.txt
gowin_pack -d GW2A-18C -o $OUT_DIR/top.fs $OUT_DIR/top.json
echo "build succesfull! see logs in build/"

openFPGALoader --ftdi-serial $SERIAL_NUM -f $OUT_DIR/top.fs
# openFPGALoader --ftdi-serial $SERIAL_NUM $OUT_DIR/top.fs
