`timescale 1ns / 1ps

module Pooling_TOP (
    input  logic       clk,
    input  logic       rst,
    input  logic       valid_ofmap,
    input  logic [3:0] ofmap_RELU,

    output logic [3:0] pooling_out,
    output logic       valid_pooling
);

    // 当前输入坐标：0～60
    logic [5:0] row;
    logic [5:0] column;

    // 当前15×15窗口内部的坐标：0～14
    logic [3:0] pool_row;
    logic [3:0] pool_col;

    // 当前列所属窗口，采用one-hot编码
    // 第60列（从0开始计数）时为0000，忽略该列
    logic [3:0] zone_sel;

    // 同一时刻只需要保存横向4个窗口的最大值
    logic [3:0] poolvalue [0:3];
    logic [3:0] next_max  [0:3];

    logic       inside_pool_area;
    logic       zone_end;
    logic [3:0] selected_max;

    assign inside_pool_area =
        (row != 6'd60) && (column != 6'd60);

    assign zone_end =
        (pool_row == 4'd14) &&
        (pool_col == 4'd14);

    // 4路并行比较，避免先动态读取数组再比较
    generate
        for (genvar g = 0; g < 4; g = g + 1) begin : GEN_POOL
            assign next_max[g] =
                (ofmap_RELU > poolvalue[g])
                ? ofmap_RELU
                : poolvalue[g];

            always_ff @(posedge clk or posedge rst) begin
                if (rst) begin
                    poolvalue[g] <= 4'd0;
                end
                else if (valid_ofmap &&
                         inside_pool_area &&
                         zone_sel[g]) begin
                    if (zone_end)
                        poolvalue[g] <= 4'd0;
                    else
                        poolvalue[g] <= next_max[g];
                end
            end
        end
    endgenerate

    // one-hot选择，输出包含当前输入像素的最大值
    assign selected_max =
        (next_max[0] & {4{zone_sel[0]}}) |
        (next_max[1] & {4{zone_sel[1]}}) |
        (next_max[2] & {4{zone_sel[2]}}) |
        (next_max[3] & {4{zone_sel[3]}});

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            row           <= 6'd0;
            column        <= 6'd0;
            pool_row      <= 4'd0;
            pool_col      <= 4'd0;
            zone_sel      <= 4'b0001;

            pooling_out   <= 4'd0;
            valid_pooling <= 1'b0;
        end
        else begin
            valid_pooling <= 1'b0;

            if (valid_ofmap) begin

                // 当前窗口最后一个像素到达时输出
                if (inside_pool_area && zone_end) begin
                    pooling_out   <= selected_max;
                    valid_pooling <= 1'b1;
                end

                // 一行共61个像素
                if (column == 6'd60) begin
                    column   <= 6'd0;
                    pool_col <= 4'd0;
                    zone_sel <= 4'b0001;

                    // 一帧共61行
                    if (row == 6'd60) begin
                        row      <= 6'd0;
                        pool_row <= 4'd0;
                    end
                    else begin
                        row <= row + 6'd1;

                        if (pool_row == 4'd14)
                            pool_row <= 4'd0;
                        else
                            pool_row <= pool_row + 4'd1;
                    end
                end
                else begin
                    column <= column + 6'd1;

                    if (pool_col == 4'd14) begin
                        pool_col <= 4'd0;
                        zone_sel <= {zone_sel[2:0], 1'b0};
                    end
                    else begin
                        pool_col <= pool_col + 4'd1;
                    end
                end
            end
        end
    end

endmodule