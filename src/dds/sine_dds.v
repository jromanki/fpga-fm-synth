module sine_dds(
    input clk,
    input rst,
    input tick,
    input [31:0] phase_inc,
    output wire [31:0] value
);

    reg [11:0] sample_num;
    reg [31:0] phase_acc;

    wire [31:0] sample_out;

    always @ (posedge clk) begin

        if (rst) begin
            phase_acc <= 0;
            sample_num <= 0;
        end
        else begin
            phase_acc <= phase_acc + phase_inc;

            if (tick) begin    
                sample_num <= phase_acc[31:20];
            end
        end
    end

    sine_lookup sine_lookup(
        .clk(clk),
        .rst(rst),
        .addr(sample_num),
        .value(sample_out)
    );

    assign value = sample_out;

endmodule