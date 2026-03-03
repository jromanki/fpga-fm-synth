module top #(
    // Num of click cycle per led toggle.
    parameter integer DIV = 100
) (
    input       ext_clk,
    input       btn,
    output      bck,
    output      lrck,
    output      dout
);

    `define MAX_VAL 32'h7FFFFFFF
    `define MIN_VAL 32'h80000000
    // `define MAX_VAL 32'hFFFFFFFF
    // `define MIN_VAL 32'h00000000
    // `define MAX_VAL 32'b11111111_11111111_11111111_11111111
    // `define MIN_VAL 32'b00000000_00000000_00000000_00000000

    // ---- PLL, 27Mhz -> 180Mhz
    //
    // Generated using the commands:
    //   apio raw -- gowin_pll -d "GW2A-18 C8/I7" -i 27 -o 180 -f pll.v
    //   apio format pll.v
    //
    wire sys_clk;

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

    reg sync_tick_reg;
    reg sync_tick_delayed;
    reg [7:0] sample_cnt;

    always @ (posedge sys_clk) begin
        if (btn) begin
            sample_cnt <= 0;
            data_l <= `MIN_VAL;
            data_r <= `MIN_VAL;
            sync_tick_delayed <= 0;
            sync_tick_reg <= 0;
            
        end
        else begin
            // if both words transmitted
            if (sys_sync_tick) begin
                if (sample_cnt < 100 - 1) begin
                    sample_cnt <= sample_cnt + 1;
                end
                else begin
                    // every few sync_ticks flip all bits
                    if (data_l == `MIN_VAL) begin
                        data_l <= `MAX_VAL;
                        data_r <= `MAX_VAL;
                    end
                    else begin
                        data_l <= `MIN_VAL;
                        data_r <= `MIN_VAL;
                    end
                    
                    sample_cnt <= 0;
                end
            end
        end
    end

    assign bck = sys_bck;
    assign lrck = sys_lrck;
    assign dout = sys_dout;

endmodule
