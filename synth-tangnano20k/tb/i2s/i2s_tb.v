`timescale 1ns/1ns

module i2s_tb;
    reg clk;
    reg rst;
    reg [32:0] din_l;
    reg [32:0] din_r;

    wire bck;
    wire lrck;
    wire data;
    wire sync_tick;

    i2s_transmit uut (
        .clk(clk),
        .rst(rst),
        .din_l(din_l),
        .din_r(din_r),

        .bck(bck),
        .lrck(lrck),
        .data(data),
        .sync_tick(sync_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        din_l = 32'b11111111111111110000000000000000;
        din_r = 32'b10101010101010101010101010101010;

        $dumpfile("build/i2s_test.vcd");
        $dumpvars(0, i2s_tb);

        #20 rst = 0;
        #100000 $finish;
    end
endmodule                                                                                       