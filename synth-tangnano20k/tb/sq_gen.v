module sq_gen (
    input clk,
    input rst
    );

    wire sync_tick;

    i2s_mock i2s_mock (
        .clk(clk),
        .rst(rst),
        .sync_tick(sync_tick)
    );

    reg sync_tick_delayed;
    reg [7:0] sample_cnt;
    reg [31:0] l_data;
    reg [31:0] r_data;

    always @ (posedge clk) begin
        if (rst) begin
            sample_cnt <= 0;
            l_data <= 32'h0000_0000;
            r_data <= 32'h0000_0000;
            sync_tick_delayed <= 0;
        end
        else begin
            // 1-cycle delayed
            sync_tick_delayed <= sync_tick;
            // rising edge detection
            if (sync_tick && !sync_tick_delayed) begin
                if (sample_cnt < 10 - 1) begin
                    sample_cnt <= sample_cnt + 1;
                end
                else begin
                    // every few sync_ticks flip all bits
                    l_data <= l_data ^ 32'hFFFF_FFFF;
                    r_data <= r_data ^ 32'hFFFF_FFFF;
                    sample_cnt <= 0;
                end
            end
        end
    end
endmodule