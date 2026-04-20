module top #(
    /* Num of click cycles per L/R toggle. */
    parameter integer DIV = 100,
    /* Num of voices (also needs changes in mixer module) */
    parameter integer VOICE_NUM = 4
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

    /* Main regs/wires */
    wire sys_clk;
    wire [31:0] final_sample;
    reg [31:0] data_l;
    reg [31:0] data_r;
    reg [15:0] master_volume_mult;
    reg sync_tick_last;
    reg dac_ready;
    reg [21:0] led_timer [5:0];
    reg led_on [5:0];

    reg [31:0] sys_spi_data;
    reg [4:0] sys_spi_target_osc;
    reg [2:0] sys_spi_msg_type;
    wire sys_spi_ready;
    reg note_msg_ready;

    /* SPI wires/regs */
    wire sys_lrck;
    wire sys_dout;
    wire sys_sync_tick;
    wire sys_bck;

    /* Per voice regs */
    reg [2:0]   osc_mod_freq_mult_setting;
    reg [7:0]   osc_mod_depth;
    reg [31:0]  sys_phase_inc [VOICE_NUM-1:0];
    reg [15:0]  osc_vol_mult [VOICE_NUM-1:0];
    wire [31:0] sample [VOICE_NUM-1:0];

    /* for loops for code clarity */
    integer i;

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
            sync_tick_last <= 0;
            dac_ready <= 0;
            
            osc_mod_freq_mult_setting <= 3'b000;
            osc_mod_depth <= 7'b0000000;
            master_volume_mult <= 16'hFFFF;

            /* clear led regs */
            for (i = 0; i < 6; i = i + 1) begin
                led_timer[i] <= 0;
                led_on[i] <= 0;
            end

            /* clear per-voice setting regs */
            for (i = 0; i < VOICE_NUM-1; i = i + 1) begin
                sys_phase_inc[i] <= 0;
                osc_vol_mult[i] <= 16'hFFFF;
            end

            
        end
        else begin
            if (note_msg_ready) begin
                /* If new spi message came */

                if (sys_spi_msg_type == 3'b001) begin
                    /* if note on message */
                    
                    /* assign phase incrementation to get correct freq */
                    sys_phase_inc[sys_spi_target_osc] <= sys_spi_data;

                    /* turn on the note sound output */
                    osc_vol_mult[sys_spi_target_osc] <= 16'hFFFF;

                    /* signalize with led */
                    if (sys_spi_target_osc < 6) begin
                        led_timer[sys_spi_target_osc] <= 22'h3FFFFF;
                        led_on[sys_spi_target_osc] <= 1;
                    end
                end

                if (sys_spi_msg_type == 3'b000) begin
                    /* note off message */

                    /* turn off the note sound output */
                    osc_vol_mult[sys_spi_target_osc] <= 16'h0000;

                    /* signalize with led */
                    if (sys_spi_target_osc < 6) begin
                        led_timer[sys_spi_target_osc] <= 22'h3FFFFF;
                        led_on[sys_spi_target_osc] <= 1;
                    end
                end

                if (sys_spi_msg_type == 3'b111) begin
                    /* volume change message */
                    master_volume_mult <= sys_spi_data[15:0];
                    led_timer[0] <= 22'h3FFFFF;
                    led_on[0] <= 1;
                end

                if (sys_spi_msg_type == 3'b010) begin
                    /* change modulation depth message */
                    osc_mod_depth <= sys_spi_data[6:0];
                    led_timer[0] <= 22'h3FFFFF;
                    led_on[0] <= 1;
                end

                if (sys_spi_msg_type == 3'b011) begin
                    /* change modulation frequency multiplier depth message */
                    osc_mod_freq_mult_setting <= sys_spi_data[2:0];
                    led_timer[0] <= 22'h3FFFFF;
                    led_on[0] <= 1;
                end
            end
            else if (btn2) begin
                /* test mode */
                sys_phase_inc[1] <= 9544;
            end

            /* if both words have been transmitted dac_ready = 1
                for 1 sys_clk cycle */
            if (dac_ready) begin
                data_l <= final_sample;
                data_r <= final_sample;
            end

            /* blink leds for a short time if led_on was set */ 
            for (i = 0; i < 6; i = i + 1) begin
                if (led_timer[i] > 0) begin
                    led_timer[i] <= led_timer[i] - 1;
                    led_on[i] <= 1;
                end
                else begin
                    led_on[i] <= 0;
                end
            end

        end
    end


    /* PLL 49.5 Mhz */
    pll pll (
        .clock_in(ext_clk),
        .clock_out(sys_clk),
        .locked()
    );

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


    /* Voice instances */

    voice voice0 (
        .clk(sys_clk),
        .rst(btn),
        .tick(sys_sync_tick),
        .phase_inc(sys_phase_inc[0]),
        .mod_freq_mult_setting(osc_mod_freq_mult_setting),
        .mod_depth(osc_mod_depth),
        .volume_mult(osc_vol_mult[0]),
        .value(sample[0])
    );

    voice voice1 (
        .clk(sys_clk),
        .rst(btn),
        .tick(sys_sync_tick),
        .phase_inc(sys_phase_inc[1]),
        .mod_freq_mult_setting(osc_mod_freq_mult_setting),
        .mod_depth(osc_mod_depth),
        .volume_mult(osc_vol_mult[1]),
        .value(sample[1])
    );

    voice voice2 (
        .clk(sys_clk),
        .rst(btn),
        .tick(sys_sync_tick),
        .phase_inc(sys_phase_inc[2]),
        .mod_freq_mult_setting(osc_mod_freq_mult_setting),
        .mod_depth(osc_mod_depth),
        .volume_mult(osc_vol_mult[2]),
        .value(sample[2])
    );

    voice voice3 (
        .clk(sys_clk),
        .rst(btn),
        .tick(sys_sync_tick),
        .phase_inc(sys_phase_inc[3]),
        .mod_freq_mult_setting(osc_mod_freq_mult_setting),
        .mod_depth(osc_mod_depth),
        .volume_mult(osc_vol_mult[3]),
        .value(sample[3])
    );

    // voice voice4 (
    //     .clk(sys_clk),
    //     .rst(btn),
    //     .tick(sys_sync_tick),
    //     .phase_inc(sys_phase_inc[4]),
    //     .mod_freq_mult_setting(osc_mod_freq_mult_setting),
    //     .mod_depth(osc_mod_depth),
    //     .volume_mult(osc_vol_mult[4]),
    //     .value(sample[4])
    // );

    // voice voice5 (
    //     .clk(sys_clk),
    //     .rst(btn),
    //     .tick(sys_sync_tick),
    //     .phase_inc(sys_phase_inc[5]),
    //     .mod_freq_mult_setting(osc_mod_freq_mult_setting),
    //     .mod_depth(osc_mod_depth),
    //     .volume_mult(osc_vol_mult[5]),
    //     .value(sample[5])
    // );

    // voice voice6 (
    //     .clk(sys_clk),
    //     .rst(btn),
    //     .tick(sys_sync_tick),
    //     .phase_inc(sys_phase_inc[6]),
    //     .mod_freq_mult_setting(osc_mod_freq_mult_setting),
    //     .mod_depth(osc_mod_depth),
    //     .volume_mult(osc_vol_mult[6]),
    //     .value(sample[6])
    // );

    // voice voice7 (
    //     .clk(sys_clk),
    //     .rst(btn),
    //     .tick(sys_sync_tick),
    //     .phase_inc(sys_phase_inc[7]),
    //     .mod_freq_mult_setting(osc_mod_freq_mult_setting),
    //     .mod_depth(osc_mod_depth),
    //     .volume_mult(osc_vol_mult[7]),
    //     .value(sample[7])
    // );

    mixer master_mixer (
        .clk(sys_clk),
        .a0(sample[0]),
        .a1(sample[1]),
        .a2(sample[2]),
        .a3(sample[3]),
        .b(master_volume_mult),
        .y(final_sample)
    );

    // mixer master_mixer (
    //     .clk(sys_clk),
    //     .a0(sample[0]),
    //     .a1(sample[1]),
    //     .a2(sample[2]),
    //     .a3(sample[3]),
    //     .a4(sample[4]),
    //     .a5(sample[5]),
    //     .a6(sample[6]),
    //     .a7(sample[7]),
    //     .b(master_volume_mult),
    //     .y(final_sample)
    // );

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

    assign sck = sys_clk;
    assign bck = sys_bck;
    assign lrck = sys_lrck;
    assign dout = sys_dout;

    assign led[0] = ~led_on[0];
    assign led[1] = ~led_on[1];
    assign led[2] = ~led_on[2];
    assign led[3] = ~led_on[3];
    assign led[4] = ~led_on[4];
    assign led[5] = ~led_on[5];

    assign test_1 = note_msg_ready;

endmodule
