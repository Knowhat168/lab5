`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/13 23:19:52
// Design Name: 
// Module Name: RELU_v1
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


module RELU_v1(
    input logic [3:0] ofmap_in,
    input logic valid_ofmap,
    output logic [3:0] ofmap_relu
    );
    
    always_comb begin
        if (valid_ofmap && ofmap_in[3] ) begin
            ofmap_relu = 4'b0;
        end else begin
            ofmap_relu = ofmap_in;
        end
    end
    
endmodule
