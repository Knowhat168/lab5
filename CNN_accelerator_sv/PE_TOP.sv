`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/14 22:22:13
// Design Name: 
// Module Name: PE_TOP
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


module PE_TOP(
    input logic clk,
    input logic rst,
    input logic start,
    input logic finish,
    input logic signed [3:0] f_in,
    input logic valid_in_f,
    input logic [63:0] ifmap_1,
    input logic [63:0] ifmap_2,
    input logic [63:0] ifmap_3,
    input logic [63:0] ifmap_4,
    input logic [7:0] count_PE,
    output logic signed [7:0] Psum_1,
    output logic signed [7:0] Psum_2,
    output logic signed [7:0] Psum_3,
    output logic signed [7:0] Psum_4,
    output logic start_acc
    );
    
    logic signed [3:0] weight [0:15];
    logic [3:0] weight_count;
    logic [1:0] sum_count;
    logic [5:0] column;
    logic signed [7:0] add1;
    logic signed [7:0] add2;
    logic signed [7:0] add3;
    logic signed [7:0] add4;
    int i;
    logic running;
    
    
    always_comb begin
        add1 = ifmap_1 [63 - sum_count - column] ? {{4{weight[sum_count][3]}} , weight[sum_count]} : 8'sd0;
        add2 = ifmap_2 [63 - sum_count - column] ? {{4{weight[sum_count + 4][3]}} , weight[sum_count + 4]} : 8'sd0;
        add3 = ifmap_3 [63 - sum_count - column] ? {{4{weight[sum_count + 8][3]}} , weight[sum_count + 8]} : 8'sd0;
        add4 = ifmap_4 [63 - sum_count - column] ? {{4{weight[sum_count + 12][3]}} , weight[sum_count + 12]} : 8'sd0;
    end
    
    assign sum_count = count_PE[1:0];
    assign column    = count_PE[7:2];
    
    
    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
        running <= '0;
        Psum_1 <= '0;
        Psum_2 <= '0;
        Psum_3 <= '0;
        Psum_4 <= '0;
        start_acc <= '0;
        weight_count <= '0;
        for (i = 0 ; i < 16 ; i = i + 1) weight[i] <= 4'sd0;
        end else begin
            start_acc <= '0;
            if (valid_in_f) begin
                weight [weight_count] <= f_in;
                if (weight_count == 4'd15)begin
                    weight_count <= 4'b0;
                end else begin
                    weight_count <= weight_count + 1'b1;
                end
            end
        
            if (finish) begin
                running <= 1'b0;
            end

            else if (start) begin
                running <= 1'b1;

                Psum_1 <= 8'sd0;
                Psum_2 <= 8'sd0;
                Psum_3 <= 8'sd0;
                Psum_4 <= 8'sd0;
            end
        
            else if (running) begin
                case (sum_count)
                    2'b00: begin
                        Psum_1 <= add1;
                        Psum_2 <= add2;
                        Psum_3 <= add3;
                        Psum_4 <= add4;
                    end
                    2'b01: begin
                        Psum_1 <= add1 + Psum_1;
                        Psum_2 <= add2 + Psum_2;
                        Psum_3 <= add3 + Psum_3;
                        Psum_4 <= add4 + Psum_4;
                    end
                    2'b10: begin
                        Psum_1 <= add1 + Psum_1;
                        Psum_2 <= add2 + Psum_2;
                        Psum_3 <= add3 + Psum_3;
                        Psum_4 <= add4 + Psum_4;
                    end
                    2'b11: begin
                        Psum_1 <= add1 + Psum_1;
                        Psum_2 <= add2 + Psum_2;
                        Psum_3 <= add3 + Psum_3;
                        Psum_4 <= add4 + Psum_4;
                        start_acc <= 1;
                    end
                    default : begin
                        Psum_1 <= '0;
                        Psum_2 <= '0;
                        Psum_3 <= '0;
                        Psum_4 <= '0;
                    end
                endcase
            end
        end
    end
    
endmodule
