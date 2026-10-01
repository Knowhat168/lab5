`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/15 20:46:27
// Design Name: 
// Module Name: Pooling_TOP
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


module Pooling_TOP (
    input  logic       clk,
    input  logic       rst,
    input  logic       valid_ofmap,
    input  logic [3:0] ofmap_RELU,

    output logic [3:0] pooling_out,
    output logic       valid_pooling
);

    logic [11:0] count;
    logic [5:0]  row;
    logic [5:0]  column;

    logic [3:0] zonenum;

    logic [3:0] poolvalue [0:15];

    logic [3:0] updated_max;

    logic inside_pool_area;

    logic zonend;

    integer i;

    always_comb begin
        row    = count / 12'd61;
        column = count % 12'd61;

        zonenum = 4'd0;

        inside_pool_area =
            (row < 6'd60) &&
            (column < 6'd60);

        if (inside_pool_area) begin
            zonenum =
                ((row / 6'd15) << 2) +
                (column / 6'd15);
        end

        zonend =
            inside_pool_area &&
            ((row % 6'd15) == 6'd14) &&
            ((column % 6'd15) == 6'd14);

        if (ofmap_RELU > poolvalue[zonenum])
            updated_max = ofmap_RELU;
        else
            updated_max = poolvalue[zonenum];
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count         <= 12'd0;
            pooling_out   <= 4'd0;
            valid_pooling <= 1'b0;

            for (i = 0; i < 16; i = i + 1)
                poolvalue[i] <= 4'd0;
        end
        else begin
            
            valid_pooling <= 1'b0;

            if (valid_ofmap) begin
                if (inside_pool_area) begin
                    
                    if (zonend) begin
                        pooling_out   <= updated_max;
                        valid_pooling <= 1'b1;

                        // zero for next image
                        poolvalue[zonenum] <= 4'd0;
                    end
                    else begin
                        poolvalue[zonenum] <= updated_max;
                    end
                end

                /*
                 * 61×61 -> 3721 elements：
                 *
                 * count range: 0～3720。
                 */
                if (count == 12'd3720)
                    count <= 12'd0;
                else
                    count <= count + 1'b1;
            end
        end
    end

endmodule
