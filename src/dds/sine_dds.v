module sine_dds(
    input clk,
    input rst,
    input tick,
    input [31:0] phase_inc,
    input [31:0] mod_phase_inc,
    output wire [31:0] value
);

    wire signed [31:0] final_sample_out;

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
            mod_phase_acc <= 0;
        end
        else begin
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

    wire signed [31:0] mod_signal = mod_sample_out >>> 23;

    sine_lookup carrier_inst(
        .clk(clk),
        .rst(rst),
        .addr(sample_num + $signed(mod_signal)),
        .value(sample_out)
    );

    assign value = sample_out;

endmodule