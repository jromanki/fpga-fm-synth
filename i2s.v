module i2s_transmit # (
    parameter integer DATA_WIDTH = 32,
    parameter integer FS = (192 / 2)
    )(
    input clk,
    input rst,
    input [31:0] din_l,
    input [31:0] din_r,

    output bck,
    output sck,
    output lrck,
    output data,
    output sync_tick
    );

    reg [31:0] shift_l, shift_r;
    reg [7:0] counter;
    reg [2:0] bck_cnt;
    reg lr_word;
    reg out_state;
    reg right_done;
    reg last_right_done;

    always @ (posedge clk) begin
        if (rst) begin
            counter <= 0;
            lr_word <= 0;
            shift_l <= 32'b0;
            shift_r <= 32'b0;
            out_state <= 0;
            right_done <= 0;
        end
        else begin
            if (counter < FS - 1) begin
                if (counter < DATA_WIDTH) begin
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

                    right_done <= 0;
                end
                else begin
                    // after completing right word transfer signalize
                    if (lr_word && (counter == DATA_WIDTH+1)) begin
                        right_done <= 1;
                    end
                    else begin
                        right_done <= 0;
                    end

                    // keep data line low
                    out_state <= 0;
                end

                // increment counter
                counter <= counter + 1;
            end
            else begin
                // load new samples
                if (lr_word) begin
                    shift_l <= din_l;
                    shift_r <= din_r;
                end

                // change left-right word
                lr_word <= ~lr_word;

                // reset counter   
                counter <= 0;
            end
        end
    end

    assign sck = clk;
    assign bck = clk;
    assign lrck = lr_word;
    assign data = out_state;
    assign sync_tick = right_done;

endmodule