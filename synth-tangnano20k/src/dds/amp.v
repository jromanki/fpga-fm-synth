module amp (
    input wire clk,
    input signed [31:0] sample,
    input [15:0] volume,
    output reg signed [31:0] sample_out
);

    // We need 48 bits to hold 32-bit * 16-bit
    reg signed [47:0] full_product;

    always @(posedge clk) begin
        // Use $signed(b) to ensure the multiplier treats the whole operation 
        // as a signed math problem.
        full_product <= sample * $signed({1'b0, volume}); 
        
        // Scale back down (divide by 65536)
        sample_out <= full_product[47:16];
    end
endmodule