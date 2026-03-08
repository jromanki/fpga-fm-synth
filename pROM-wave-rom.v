`default_nettype none
module wave_rom(
	input wire clk,
	input wire reset,
	input wire [8:0] ad,
	output wire [31:0] data
);

	wire gnd, vcc;
	assign gnd = 1'b0;
	assign vcc = 1'b1;

	wire [31:0] data_w;

	pROM rom(
		.AD({ad[8:0], gnd, gnd, gnd, gnd, gnd}),
		.DO(data_w),
		.CLK(clk),
		.OCE(vcc),
		.CE(vcc),
		.RESET(reset)
	);
	defparam rom.READ_MODE = 1'b1;
	defparam rom.BIT_WIDTH = 32;
	defparam rom.RESET_MODE = "SYNC";

	`include "wave-rom.vh"

	assign data = data_w;

endmodule
