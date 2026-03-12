`default_nettype none
module wave_rom(
	input wire clk,
	input wire reset,
	input wire [9:0] ad,
	output wire [31:0] data
);

	wire gnd, vcc;
	assign gnd = 1'b0;
	assign vcc = 1'b1;

	wire [31:0] data_w [1:0];
	assign data = data_w[ad[9]];

	pROM rom0(
		.AD({ad[8:0], gnd, gnd, gnd, gnd, gnd}),
		.DO(data_w[0]),
		.CLK(clk),
		.OCE(vcc),
		.CE(vcc),
		.RESET(reset)
	);
	defparam rom0.READ_MODE = 1'b0;
	defparam rom0.BIT_WIDTH = 32;
	defparam rom0.RESET_MODE = "SYNC";
	`include "wave-rom0.vh"

	pROM rom1(
		.AD({ad[8:0], gnd, gnd, gnd, gnd, gnd}),
		.DO(data_w[1]),
		.CLK(clk),
		.OCE(vcc),
		.CE(vcc),
		.RESET(reset)
	);
	defparam rom1.READ_MODE = 1'b0;
	defparam rom1.BIT_WIDTH = 32;
	defparam rom1.RESET_MODE = "SYNC";
	`include "wave-rom1.vh"

endmodule
