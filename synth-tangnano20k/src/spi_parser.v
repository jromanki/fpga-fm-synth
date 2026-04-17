module spi_parser (
    input wire clk,
    input wire rst,

	input wire scl,
	input wire mosi,
	input wire cs,

    output wire data_ready,
    output reg [31:0] data_out,
    output reg [4:0] target_osc_out,
    output reg [2:0] msg_type_out
);


    /* synchronization of SPI inputs to FPGA clock domain using
		double flip flops */
    reg scl_d1, scl_d2;
    reg mosi_d1, mosi_d2;
    reg cs_d1, cs_d2;

    always @(posedge clk) begin
        scl_d1 <= scl;
        scl_d2 <= scl_d1;

        mosi_d1 <= mosi;
        mosi_d2 <= mosi_d1;

        cs_d1 <= cs;
        cs_d2 <= cs_d1;
    end

	/* SPI slave module */
    wire sys_processing;
	wire sys_is_ready;
	reg sys_spi_reset;
	wire [39:0] sys_recv_data;
	reg sys_data_ready;
	reg sys_data_ready_d1;

    spi_module #(
        .SPI_MASTER(1'b0),
        .SPI_WORD_LEN(40)
	) spi_slave (
        .master_clock(clk),
        .SCLK_IN(scl_d2),
        .SS_IN(cs_d2),
        .INPUT_SIGNAL(mosi_d2),
        .data_word_recv(sys_recv_data),
        .processing_word(sys_processing),
        .process_next_word(process_next_word),
        .do_reset(sys_spi_reset),
        .is_ready(sys_is_ready),
        // Unused ports
        .SCLK_OUT(), .SS_OUT(), .OUTPUT_SIGNAL(), .data_word_send(40'h0)
    );

    always @(posedge clk) begin
        if (rst) begin
            sys_spi_reset <= 1'b1;
            process_next_word <= 1'b0;
            sys_processing_d1 <= 1'b0;
            data_ready <= 1'b0;
            data_out <= 32'd0;
        end else begin
            sys_spi_reset <= 1'b0;

            /* processing_word edge detect */
            sys_processing_d1 <= sys_processing;

            /* rearming SPI module */
            if (!sys_processing && !process_next_word) begin
                process_next_word <= 1'b1; 
            end
            else if (sys_processing && process_next_word) begin
                process_next_word <= 1'b0;
            end

            /* word complete */
            if (sys_processing_d1 && !sys_processing) begin
                data_out <= sys_recv_data[31:0];
                target_osc_out <= sys_recv_data[36:32];
                msg_type_out <= sys_recv_data[39:37];
                data_ready <= 1'b1;
            end else begin
                data_ready <= 1'b0;
            end
        end
    end

endmodule