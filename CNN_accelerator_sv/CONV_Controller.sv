`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/15 10:45:54
// Design Name: 
// Module Name: CONV_Controller
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


module CONV_Controller(
        input logic clk,
        input logic rst,
        input logic start_in,
        output logic [63:0] data_1,
        output logic [63:0] data_2,
        output logic [63:0] data_3,
        output logic [63:0] data_4,
        output logic [3:0] address_1,
        output logic [3:0] address_2,
        output logic [3:0] address_3,
        output logic [3:0] address_4,
        output logic csn_1,
        output logic csn_2,
        output logic csn_3,
        output logic csn_4,
        output logic wen_1,
        output logic wen_2,
        output logic wen_3,
        output logic wen_4,
        output logic finish,
        output logic [1:0] count_def,
        output logic [7:0] count_PE
    );

    // Current output row of the valid 4x4 convolution (0 ... 60).
    // Four physical RAMs contain image rows in an interleaved layout:
    // RAM1: rows 0,4,8,...; RAM2: rows 1,5,9,... and so on.
    logic [5:0] row_count;
    logic       running;

    logic [3:0] base_address;

    always_comb begin
        // The memories are pre-initialized and are read-only during inference.
        data_1 = 64'd0;
        data_2 = 64'd0;
        data_3 = 64'd0;
        data_4 = 64'd0;

        wen_1 = 1'b0;
        wen_2 = 1'b0;
        wen_3 = 1'b0;
        wen_4 = 1'b0;

        csn_1 = 1'b0;
        csn_2 = 1'b0;
        csn_3 = 1'b0;
        csn_4 = 1'b0;

        // row_count / 4 selects the address within each 16-word RAM.
        base_address = row_count[5:2];
        count_def    = row_count[1:0];

        // Select the four consecutive image rows row_count ... row_count+3.
        // RAM_IP_TOP uses count_def to rotate these physical RAM outputs back
        // into logical order ifmap_1, ifmap_2, ifmap_3, ifmap_4.
        address_1 = base_address;
        address_2 = base_address;
        address_3 = base_address;
        address_4 = base_address;

        case (count_def)
            2'd1: begin
                address_1 = base_address + 1'b1;
            end

            2'd2: begin
                address_1 = base_address + 1'b1;
                address_2 = base_address + 1'b1;
            end

            2'd3: begin
                address_1 = base_address + 1'b1;
                address_2 = base_address + 1'b1;
                address_3 = base_address + 1'b1;
            end

            default: begin
                // For row_count mod 4 == 0, all four RAMs use base_address.
            end
        endcase
    end

    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
            count_PE <= 8'd0;
            row_count <= 6'd0;
            running   <= 1'b0;
            finish    <= 1'b0;
        end else begin
            // finish is a one-clock pulse.
            finish <= 1'b0;

            if (start_in) begin
                count_PE <= 8'd0;
                row_count <= 6'd0;
                running   <= 1'b1;
            end else if (running) begin
                if (count_PE == 8'd243) begin
                    count_PE <= 8'd0;

                    if (row_count == 6'd60) begin
                        // 61 rows x 61 columns have now been scheduled.
                        running <= 1'b0;
                        finish  <= 1'b1;
                    end else begin
                        row_count <= row_count + 1'b1;
                    end
                end else begin
                    count_PE <= count_PE + 1'b1;
                end
            end
        end
    end
endmodule
