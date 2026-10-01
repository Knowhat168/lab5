`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/13 23:29:42
// Design Name: 
// Module Name: Acc
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


module Acc(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [7:0] Psum1,
    input logic [7:0] Psum2,
    input logic [7:0] Psum3,
    input logic [7:0] Psum4,
    output logic [3:0] ofmap,
    output logic valid_ofmap
    );
    logic signed [7:0] Psum1_ac;
    logic signed [7:0] Psum2_ac;
    logic signed [7:0] Psum3_ac;
    logic signed [7:0] Psum4_ac;
    logic signed [11:0] sum;
    logic start_delay;
    
    always_comb begin
        sum =
        $signed({{4{Psum1_ac[7]}}, Psum1_ac}) +
        $signed({{4{Psum2_ac[7]}}, Psum2_ac}) +
        $signed({{4{Psum3_ac[7]}}, Psum3_ac}) +
        $signed({{4{Psum4_ac[7]}}, Psum4_ac});
    end
    
    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
            Psum1_ac <= '0;
            Psum2_ac <= '0;
            Psum3_ac <= '0;
            Psum4_ac <= '0;
            start_delay <= '0;
            ofmap <= '0;
            valid_ofmap <= '0;
        end
        else begin
            start_delay <= start;
            Psum1_ac <= Psum1;
            Psum2_ac <= Psum2;
            Psum3_ac <= Psum3;
            Psum4_ac <= Psum4;
            if (start_delay) begin
                if (sum > 12'sd7) begin
                    ofmap <= 4'b0111;
                    valid_ofmap <= 1'b1;
                end else if (sum < -12'sd8) begin
                    ofmap <= 4'b1000;
                    valid_ofmap <= 1'b1;
                end else begin
                    ofmap <= sum[3:0];
                    valid_ofmap <= 1'b1;
                end
            end else begin
                valid_ofmap <= 1'b0;
            end
        end
    end
endmodule
