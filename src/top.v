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
    reg [31:0] sys_mod_phase_inc;
    reg [15:0] master_volume_mult;
    reg [2:0] osc1_mod_freq_mult_setting;

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

        if (btn | auto_rst) begin
            sample_cnt <= 0;
            sync_tick_last <= 0;
            dac_ready <= 0;
            sys_phase_inc <= 0;
            sys_mod_phase_inc <= 0;
            led_on <= 0;
            led_timer <= 0;
            master_volume_mult <= 16'hFFFF;
            osc1_vol_mult <= 16'hFFFF;
            osc1_mod_depth <= 7'b0000000;
        end
        else begin
            if (note_msg_ready) begin
                if (sys_spi_msg_type == 3'b001) begin
                    /* note on message */
                    
                    /* assign phase incrementation to get correct freq */
                    sys_phase_inc <= sys_spi_data;

                    /* turn on the note sound output */
                    osc1_vol_mult <= 16'hFFFF;

                    /* signalize with led */
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end

                if (sys_spi_msg_type == 3'b000) begin
                    /* note off message */
                    sys_phase_inc <= 0;

                    /* turn off the note sound output */
                    osc1_vol_mult <= 16'h0000;
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end

                if (sys_spi_msg_type == 3'b111) begin
                    /* volume change message */
                    master_volume_mult <= sys_spi_data[15:0];
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end

                if (sys_spi_msg_type == 3'b010) begin
                    /* change modulation depth message */
                    osc1_mod_depth <= sys_spi_data[6:0];
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end

                if (sys_spi_msg_type == 3'b011) begin
                    /* change modulation frequency multiplier depth message */
                    osc1_mod_freq_mult_setting <= sys_spi_data[2:0];
                    led_timer <= 22'h3FFFFF;
                    led_on <= 1;
                end
            end
            else if (btn2) begin
                /* test mode */
                sys_phase_inc <= 9544;
            end

            /* assign chosen modulator freq */
            case(osc1_mod_freq_mult_setting)

                /* x1/2 of the frequency */
                3'b000 : begin
                    sys_mod_phase_inc <= sys_phase_inc >> 1;
                end

                /* x1 of the frequency */
                3'b001 : begin
                    sys_mod_phase_inc <= sys_phase_inc;
                end

                /* x3/2 of the frequency */
                3'b010 : begin
                    sys_mod_phase_inc <= sys_phase_inc + (sys_phase_inc >> 1);
                end

                /* x2 of the frequency */
                3'b011 : begin
                    sys_mod_phase_inc <= sys_phase_inc << 1;
                end
                
                /* x3 of the frequency */
                3'b100 : begin
                    sys_mod_phase_inc <= sys_phase_inc + (sys_phase_inc << 1);
                end

                default : begin
                    sys_mod_phase_inc <= sys_phase_inc;
                end
            endcase


            /* if both words have been transmitted dac_ready = 1
                for 1 sys_clk cycle */
            if (dac_ready) begin
                // data_l <= sample;
                // data_r <= sample;
                data_l <= final_sample;
                data_r <= final_sample;
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
    wire [31:0] final_sample;
    reg [15:0] osc1_vol_mult;
    reg [7:0] osc1_mod_depth;

    voice voice1 (
        .clk(sys_clk),
        .rst(btn),
        .tick(sys_sync_tick),
        .phase_inc(sys_phase_inc),
        .mod_phase_inc(sys_mod_phase_inc),
        .mod_depth(osc1_mod_depth),
        .volume_mult(osc1_vol_mult),
        .value(sample)
    );

    s32_x_u16_mult volume_mult_inst (
        .clk(sys_clk),
        .a(sample),
        .b(master_volume_mult),
        .y(final_sample)
    );

    reg [31:0] sys_spi_data;
    reg [4:0] sys_spi_target_osc;
    reg [2:0] sys_spi_msg_type;
    wire sys_spi_ready;
    reg note_msg_ready;

    spi_parser spi_parser (
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
