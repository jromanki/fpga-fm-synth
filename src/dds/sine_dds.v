// module sine_lookup(
//     input clk,
//     input rst,
//     input load_tick,
//     input [31:0] phase_inc,
//     output wire [31:0] value
// );

//     sine_dds sine_dds(
//         .clk(sys_clk),
//         .rst(btn),
//         .addr(sample_cnt),
//         .value(sample)
//     );

//     reg phase_acc[31:0]


//     always @ (posedge clk) begin

//         if (btn) begin
//             phase_acc <= 0;
//         end
//         else begin
//             if (tick) begin
//                 data_l <= sample;
//                 data_r <= sample;
//                 sample_cnt <= sample_cnt + 1;
//             end
//         end
//     end

// endmodule