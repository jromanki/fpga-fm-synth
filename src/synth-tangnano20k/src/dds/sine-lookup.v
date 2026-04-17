module sine_lookup(
    input clk,
    input rst,
    input [11:0] addr,
    output wire [31:0] value
);

    reg [9:0] lookup_addr;
    wire [31:0] prom_data;
    reg [31:0] full_data;
    reg sign_d1;
    reg sign_d2;

    always @(posedge clk) begin
        /* calculate ROM address (mirror symetry) */
        if (addr[10]) begin
            lookup_addr <= ~addr[9:0];
        end else begin
            lookup_addr <= addr[9:0];
        end

        /* delay */
        sign_d1 <= addr[11];
        sign_d2 <= sign_d1; 

        /* output data (invert symetry) */
        if (sign_d2) begin
            full_data <= -prom_data;
        end else begin
            full_data <= prom_data;
        end
    end

    wave_rom wave_rom(
        .clk(clk),
        .reset(rst),
        .ad(lookup_addr),
        .data(prom_data)
    );

    assign value = full_data;

endmodule
