module s32_x_u16_mult (
    input  wire clk,
    input  signed [31:0] a, // DECLARE AS SIGNED
    input  [15:0] b,        // Volume is usually unsigned (0 to Max)
    output reg signed [31:0] y
);

    // We need 48 bits to hold 32-bit * 16-bit
    reg signed [47:0] full_product;

    always @(posedge clk) begin
        // Use $signed(b) to ensure the multiplier treats the whole operation 
        // as a signed math problem.
        full_product <= a * $signed({1'b0, b}); 
        
        // Scale back down (divide by 65536)
        y <= full_product[47:16];
    end
endmodule