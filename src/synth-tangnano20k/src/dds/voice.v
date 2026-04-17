module voice(
    input clk,
    input rst,
    input tick,
    input [31:0] phase_inc,
    input [2:0] mod_freq_mult_setting,
    input [6:0] mod_depth,
    input [15:0] volume_mult,
    output wire [31:0] value
);
    wire signed [31:0] final_sample_out;

    reg [31:0] mod_phase_inc;
    reg [11:0] sample_num;
    reg [31:0] phase_acc;
    wire signed [31:0] sample_out;

    reg [11:0] mod_sample_num;
    reg [31:0] mod_phase_acc;
    wire signed [31:0] mod_sample_out;

    always @ (posedge clk) begin

        if (rst) begin
            phase_acc <= 0;
            sample_num <= 0;
            mod_sample_num <= 0;
            mod_phase_acc <= 0;
        end
        else begin
            
            /* assign chosen modulator freq */
            case(mod_freq_mult_setting)

                /* x1/2 of the frequency */
                3'b000 : begin
                    mod_phase_inc <= phase_inc >> 1;
                end

                /* x1 of the frequency */
                3'b001 : begin
                    mod_phase_inc <= phase_inc;
                end

                /* x3/2 of the frequency */
                3'b010 : begin
                    mod_phase_inc <= phase_inc + (phase_inc >> 1);
                end

                /* x2 of the frequency */
                3'b011 : begin
                    mod_phase_inc <= phase_inc << 1;
                end
                
                /* x3 of the frequency */
                3'b100 : begin
                    mod_phase_inc <= phase_inc + (phase_inc << 1);
                end

                default : begin
                    mod_phase_inc <= phase_inc;
                end
            endcase

            phase_acc <= phase_acc + phase_inc;
            mod_phase_acc <= mod_phase_acc + mod_phase_inc;

            if (tick) begin    
                sample_num <= phase_acc[31:20];
                mod_sample_num <= mod_phase_acc[31:20];
            end
        end
    end

    /* reduce to serial single instance in the future */
    sine_lookup mod_inst(
        .clk(clk),
        .rst(rst),
        .addr(mod_sample_num),
        .value(mod_sample_out)
    );

    wire signed [38:0] mod_signal = (mod_sample_out * $signed({1'b0, mod_depth})) >>> 26;

    sine_lookup carrier_inst(
        .clk(clk),
        .rst(rst),
        .addr(sample_num + $signed(mod_signal)),
        .value(sample_out)
    );

    amp amp(
        .clk(clk),
        .sample(sample_out),
        .volume(volume_mult),
        .sample_out(final_sample_out)
    );

    assign value = final_sample_out;

endmodule