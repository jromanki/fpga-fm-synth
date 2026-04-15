module mixer (
    input  wire clk,
    input  signed [31:0] a0,
    input  signed [31:0] a1,
    input  [15:0] b,
    output reg signed [31:0] y
);

    // We need 48 bits to hold 32-bit * 16-bit
    reg signed [48:0] full_product;

    wire signed [32:0] sum;
    assign sum = {a0[31], a0} + {a1[31], a1};

    always @(posedge clk) begin

        // Use $signed(b) to ensure the multiplier treats the whole operation 
        // as a signed math problem.
        full_product <= sum * $signed({1'b0, b}); 
        
        // Scale back down (divide by 65536)
        y <= full_product[48:16];
    end
endmodule