module top #(
    // Num of click cycle per led toggle.
    parameter integer DIV = 100
) (
    input       ext_clk,
    input       btn,
    input       btn2,

    input       scl,
	input       mosi,
	input       cs,

    output      sck,
    output      bck,
    output      lrck,
    output      dout,

    output      [5:0] led,

    output      test_1
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
    reg [31:0] sys_phase_inc;

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

    wire sys_note_reset;

    reg sync_tick_last;
    reg dac_ready;
    reg [11:0] sample_cnt;

    reg [21:0] led_timer;
    reg led_on;

    /* simple power on reset */
    reg [15:0] por_counter = 0;
    wire auto_rst = !por_counter[15];
    always @(posedge sys_clk) begin
        if (auto_rst) begin
            por_counter <= por_counter + 1;
        end
    end

    always @ (posedge sys_clk) begin

        /* make dac_ready detect rising edge of sync_tick */
        sync_tick_last <= sys_sync_tick;
        dac_ready <= (sys_sync_tick && !sync_tick_last);
        note_msg_ready <= sys_spi_ready;

        if (btn) begin
            sample_cnt <= 0;
            sync_tick_last <= 0;
            dac_ready <= 0;
            sys_phase_inc <= 0;
            led_on <= 0;
            led_timer <= 0;
        end
        else begin
            if (note_msg_ready) begin
                if (sys_spi_msg_type == 3'b001) begin
                    /* note on message */
                    sys_phase_inc <= sys_spi_data;
                    sys_note_reset <= 0;
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end

                if (sys_spi_msg_type == 3'b000) begin
                    /* note off message */
                    sys_phase_inc <= 0;
                    sys_note_reset <= 1;
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end
            end
            else if (btn2) begin
                /* test mode */
                sys_phase_inc <= 9544;
            end


            /* if both words have been transmitted dac_ready = 1
                for 1 sys_clk cycle */
            if (dac_ready) begin
                data_l <= sample;
                data_r <= sample;
            end

            if (led_timer > 0) begin
                led_timer <= led_timer - 1;
                led_on <= 1;
            end
            else begin
                led_on <= 0;
            end
        end
    end

    wire [31:0] sample;

    sine_dds sine_dds(
        .clk(sys_clk),
        .rst(btn | sys_note_reset),
        .tick(sys_sync_tick),
        .phase_inc(sys_phase_inc),
        .mod_phase_inc(sys_phase_inc),
        .value(sample)
    );

    reg [31:0] sys_spi_data;
    reg [4:0] sys_spi_target_osc;
    reg [2:0] sys_spi_msg_type;
    wire sys_spi_ready;
    reg note_msg_ready;

    spi_parser spi_parser(
        .clk(sys_clk),
        .rst(btn | auto_rst),
        .scl(scl),
        .mosi(mosi),
        .cs(cs),
        .data_ready(sys_spi_ready),
        .data_out(sys_spi_data),
        .target_osc_out(sys_spi_target_osc),
        .msg_type_out(sys_spi_msg_type)
    );

    assign sck = sys_clk;
    assign bck = sys_bck;
    assign lrck = sys_lrck;
    assign dout = sys_dout;

    assign led[0] = ~led_on;
    assign led[5:1] = 5'b11111;

    assign test_1 = note_msg_ready;

endmodule
