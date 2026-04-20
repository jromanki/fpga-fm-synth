module mixer (
    input  wire clk,
    input  signed [31:0] a0,
    input  signed [31:0] a1,
    input  signed [31:0] a2,
    input  signed [31:0] a3,
    input  [15:0] b,
    output reg signed [31:0] y
);

    // We need 48 bits to hold 32-bit * 16-bit
    reg signed [49:0] full_product;
    reg signed [33:0] sum;
    

    always @(posedge clk) begin
        sum <= a0 + a1 + a2 + a3;

        // Use $signed(b) to ensure the multiplier treats the whole operation 
        // as a signed math problem.
        full_product <= sum * $signed({1'b0, b}); 
        
        // Scale back down (divide by 65536)
        y <= full_product[49:18];
    end
endmodule