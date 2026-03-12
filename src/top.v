module top #(
    // Num of click cycle per led toggle.
    parameter integer DIV = 100
) (
    input       ext_clk,
    input       btn,
    output      sck,
    output      bck,
    output      lrck,
    output      dout,

    output      test_1,
);

    `define MAX_VAL 32'h7FFFFFFF
    `define MIN_VAL 32'h80000000

    wire sys_clk;
    // ---- PLL, 27Mhz
    //
    // Generated using the commands:
    //   apio raw -- gowin_pll -d "GW2A-18 C8/I7" -i 27 -o 180 -f pll.v
    //   apio format pll.v
    //
    pll pll (
        .clock_in(ext_clk),
        .clock_out(sys_clk),
        .locked()
    );

    wire sys_lrck;
    wire sys_dout;
    wire sys_sync_tick;
    wire sys_bck;
    reg [31:0] data_l;
    reg [31:0] data_r;

    i2s_transmit i2s (
        .clk(sys_clk),
        .rst(btn),
        .din_l(data_l),
        .din_r(data_r),

        .bck(sys_bck),
        .lrck(sys_lrck),
        .data(sys_dout),
        .sync_tick(sys_sync_tick)
    );

    reg sync_tick_last;
    reg dac_ready;
    reg [11:0] sample_cnt;

    always @ (posedge sys_clk) begin

        /* make dac_ready detect rising edge of sync_tick */
        sync_tick_last <= sys_sync_tick;
        dac_ready <= (sys_sync_tick && !sync_tick_last);

        if (btn) begin
            sample_cnt <= 0;
            sync_tick_last <= 0;
            dac_ready <= 0;
        end
        else begin
            /* if both words have been transmitted dac_ready = 1
                for 1 sys_clk cycle */
            if (dac_ready) begin
                data_l <= sample;
                data_r <= sample;
                sample_cnt <= sample_cnt + 1;
            end
        end
    end

    wire [31:0] sample;

    sine_lookup sine_lookup(
        .clk(sys_clk),
        .rst(btn),
        .addr(sample_cnt),
        .value(sample)
    );

    assign sck = sys_clk;
    assign bck = sys_bck;
    assign lrck = sys_lrck;
    assign dout = sys_dout;

    // assign test_1 = dac_ready;

endmodule
