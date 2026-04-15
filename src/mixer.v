module mixer (
    input  wire clk,
    input  signed [31:0] a0,
    input  signed [31:0] a1,
    input  [15:0] b,
    output reg signed [31:0] y
);

    // We need 48 bits to hold 32-bit * 16-bit
    reg signed [48:0] full_product;
    reg signed [32:0] sum;
    

    always @(posedge clk) begin
        sum <= (a0 >>> 1) + (a1 >>> 1);

        // Use $signed(b) to ensure the multiplier treats the whole operation 
        // as a signed math problem.
        full_product <= sum * $signed({1'b0, b}); 
        
        // Scale back down (divide by 65536)
        y <= full_product[47:16];
    end
endmodule