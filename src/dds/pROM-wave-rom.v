`default_nettype none

module wave_rom(
    input wire clk,
    input wire reset,
    input wire [9:0] ad,
    output wire [31:0] data
);

    reg [31:0] rom [0:1023];
    reg [31:0] data_r;
    assign data = data_r;

    always @(posedge clk) begin
        data_r <= rom[ad];
    end

    initial begin
        $readmemh("src/dds/wave-rom.hex", rom);
    end

endmodule