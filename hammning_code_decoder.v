`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2023 09:31:55
// Design Name: 
// Module Name: hammning_code_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hamming_decoder (
    input [6:0] code_in,
    output [3:0] data_out,
    output error
);

// Decoder
reg [3:0] data;
wire p1, p2, p3;
assign p1 = code_in[0] ^ code_in[1] ^ code_in[3] ^ code_in[4] ^ code_in[6];
assign p2 = code_in[0] ^ code_in[2] ^ code_in[3] ^ code_in[5] ^ code_in[6];
assign p3 = code_in[1] ^ code_in[2] ^ code_in[3] ^ code_in[6];
assign error = p1 | p2 | p3;
always @ (*) begin
    if (error) begin
        data[0] = ~code_in[1] & ~code_in[2] & code_in[4] & ~code_in[5];
        data[1] = ~code_in[1] & code_in[2] & ~code_in[3] & ~code_in[4] & code_in[6];
        data[2] = code_in[1] & ~code_in[2] & ~code_in[3] & ~code_in[5] & code_in[6];
        data[3] = code_in[2] & ~code_in[4] & ~code_in[5] & code_in[6];
    end else begin
        data[0] = code_in[1];
        data[1] = code_in[2];
        data[2] = code_in[4];
        data[3] = code_in[5];
    end
end
assign data_out = data;

endmodule
