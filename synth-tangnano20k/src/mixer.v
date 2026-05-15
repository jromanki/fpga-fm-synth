module mixer (
    input  wire clk,
    // 8 wejść dla 8 głosów polifonii
    input  signed [31:0] a0,
    input  signed [31:0] a1,
    input  signed [31:0] a2,
    input  signed [31:0] a3,
    input  signed [31:0] a4,
    input  signed [31:0] a5,
    input  signed [31:0] a6,
    input  signed [31:0] a7,
    input  [15:0] b,
    output reg signed [31:0] y
);

    // Suma 8 sygnałów 32-bitowych potrzebuje 3 dodatkowych bitów (32 + 3 = 35)
    // 2^3 = 8, więc 35 bitów gwarantuje brak overflow przy sumowaniu.
    reg signed [34:0] sum;
    
    // 35 bitów * 17 bitów ($signed({1'b0, b})) = 52 bity
    reg signed [51:0] full_product;

    always @(posedge clk) begin
        // Krok 1: Sumowanie wszystkich głosów
        sum <= a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7;

        // Krok 2: Mnożenie przez głośność (Master Volume)
        full_product <= sum * $signed({1'b0, b}); 
        
        // Krok 3: Skalowanie (przesunięcie bitowe)
        // b to 16-bitowa wartość, więc dzielimy przez 2^16 (>>> 16)
        // Jeśli chcesz zachować ten sam poziom wyjściowy co wcześniej:
        y <= full_product[47:16]; 
    end
endmodule