module mixer (
    input  wire clk,
    input  signed [31:0] a0,
    input  signed [31:0] a1,
    input  signed [31:0] a2,
    input  signed [31:0] a3,
    input  signed [31:0] a4,
    input  signed [31:0] a5,
    input  signed [31:0] a6,
    input  signed [31:0] a7,
    input  signed [31:0] a8,
    input  signed [31:0] a9,
    input  [15:0] b,
    output reg signed [31:0] y
);

    // We need 48 bits to hold 32-bit * 16-bit
    reg signed [51:0] full_product;
    reg signed [35:0] sum;
    

    always @(posedge clk) begin
        sum <= a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9;

        // Use $signed(b) to ensure the multiplier treats the whole operation 
        // as a signed math problem.
        full_product <= sum * $signed({1'b0, b}); 
        
        // Scale back down
        y <= full_product[51:20];
    end
endmodule