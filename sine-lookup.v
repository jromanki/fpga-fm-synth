module sine_lookup(
    input clk,
    input rst,
    input [10:0] addr,
    output wire [31:0] value
);

    reg [8:0] lookup_addr;
    wire [31:0] prom_data;
    reg [31:0] full_data;

    reg addr10_delayed1; 
    reg addr10_delayed2;

    always @(posedge clk) begin
        if (addr[9]) begin
            lookup_addr <= ~addr[8:0];
        end
        else begin
            lookup_addr <= addr[8:0];
        end

        addr10_delayed1 <= addr[10];
        addr10_delayed2 <= addr10_delayed1;

        if (addr10_delayed2) begin
            full_data <= ~prom_data + 1;
        end
        else begin
            full_data <= prom_data;
        end
    end

    wave_rom wave(
        .clk(clk),
        .reset(rst),
        .ad(lookup_addr),
        .data(prom_data)
    );

    assign value = full_data;

endmodule
