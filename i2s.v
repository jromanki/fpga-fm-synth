module i2s_transmit # (
    parameter integer DATA_WIDTH = 32,
    // parameter integer FS = (192 / 2)
    parameter integer FS = 192
    )(
    input clk,
    input rst,
    input [31:0] din_l,
    input [31:0] din_r,

    output bck,
    output lrck,
    output data,
    output sync_tick
    );

    reg [31:0] shift_l, shift_r;
    reg [7:0] clk_counter;
    reg [5:0] bit_counter;
    reg [2:0] div_3_counter;

    reg bck_clk;
    reg lr_word;
    reg lr_word_delayed;
    reg out_state;
    reg right_done;
    reg last_right_done;

    always @ (posedge clk) begin
        if (rst) begin
            clk_counter <= 0;
            bit_counter <= 0;
            div_3_counter <= 0;
            bck_clk <= 0;

            lr_word <= 0;
            shift_l <= 6'b0; // CHANGE TO 32
            shift_r <= 6'b0; // CHANGE TO 32
            out_state <= 0;
            right_done <= 0;
        end
        else begin
            if (clk_counter < FS - 1) begin
                lr_word_delayed <= lr_word;

                // load new samples
                if (lr_word && !lr_word_delayed) begin
                    shift_l <= din_l;
                    shift_r <= din_r;
                end

                // after completing right word transfer signalize
                if (lr_word && (clk_counter == (DATA_WIDTH * 2))) begin
                    right_done <= 1;
                end
                else begin
                    right_done <= 0;
                end

                if (div_3_counter < 2 - 1) begin
                    div_3_counter <= div_3_counter + 1;

                end
                else begin
                    if (bck_clk == 1) begin
                        if (bit_counter < DATA_WIDTH) begin
                            // shift out MSB
                            if (!lr_word) begin
                                // left word
                                out_state <= shift_l[31];
                                shift_l <= {shift_l[30:0], 1'b0};
                            end
                            else begin
                                // right word
                                out_state <= shift_r[31];
                                shift_r <= {shift_r[30:0], 1'b0};
                            end
                        end
                        else begin

                            // keep data line low
                            out_state <= 0;
                        end

                        bit_counter <= bit_counter + 1;
                    end

                    bck_clk <= ~bck_clk;

                    div_3_counter <= 0;
                end

                // increment counter
                clk_counter <= clk_counter + 1;
            end
            else begin

                // change left-right word
                lr_word <= ~lr_word;

                // oscillate bck every 4 clk periods
                bck_clk <= ~bck_clk;

                bit_counter <= 0;

                // reset counter
                div_3_counter <= 0;
                clk_counter <= 0;
            end
        end
    end

    assign bck = bck_clk;
    assign lrck = lr_word;
    assign data = out_state;
    assign sync_tick = right_done;

endmodule