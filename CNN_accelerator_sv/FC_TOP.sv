`timescale 1ns / 1ps

// Two-process FC implementation: all decisions and arithmetic are combinational.
module FC_TOP (
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] k_FC1_in,
    input  logic       valid_k_FC1_in,
    input  logic [3:0] k_FC2_in,
    input  logic       valid_k_FC2_in,
    input  logic [3:0] pooling,
    input  logic       valid_pooling,
    output logic       fc_output,
    output logic       valid_output
);

    typedef enum logic [2:0] {LOAD, FC1, FC1_FLUSH, FC2_MULT, FC2_SUM, DONE} state_t;

    state_t state, state_next;

    logic signed [3:0] k_FC1 [0:47];
    logic signed [3:0] k_FC1_next [0:47];
    logic signed [3:0] k_FC2 [0:2];
    logic signed [3:0] k_FC2_next [0:2];
    logic        [3:0] pooling_input [0:15];
    logic        [3:0] pooling_input_next [0:15];

    logic [5:0] count_kc1, count_kc1_next;
    logic [1:0] count_kc2, count_kc2_next;
    logic [3:0] count_pooling, count_pooling_next;
    logic [3:0] FC1_index, FC1_index_next;

    logic FC1_loaded, FC1_loaded_next;
    logic FC2_loaded, FC2_loaded_next;
    logic pooling_loaded, pooling_loaded_next;

    logic signed [11:0] FC1_sum_0, FC1_sum_0_next;
    logic signed [11:0] FC1_sum_1, FC1_sum_1_next;
    logic signed [11:0] FC1_sum_2, FC1_sum_2_next;
    logic signed [11:0] FC1_product_0, FC1_product_0_next;
    logic signed [11:0] FC1_product_1, FC1_product_1_next;
    logic signed [11:0] FC1_product_2, FC1_product_2_next;
    logic FC1_product_valid, FC1_product_valid_next;
    logic signed [15:0] FC2_product_0, FC2_product_0_next;
    logic signed [15:0] FC2_product_1, FC2_product_1_next;
    logic signed [15:0] FC2_product_2, FC2_product_2_next;
    logic signed [15:0] FC2_score;

    logic fc_output_next;
    logic valid_output_next;

    localparam logic signed [11:0] FC1_BIAS_0 = -12'sd12;
    localparam logic signed [11:0] FC1_BIAS_1 =  12'sd20;
    localparam logic signed [11:0] FC1_BIAS_2 =  12'sd24;
    localparam logic signed [15:0] FC2_BIAS   =  16'sd6;

    function automatic logic signed [11:0] pool_product (
        input logic        [3:0] value,
        input logic signed [3:0] weight
    );
        logic signed [4:0] signed_value;
        begin
            signed_value = $signed({1'b0, value});
            pool_product = signed_value * weight;
        end
    endfunction

    function automatic logic signed [15:0] FC2_product (
        input logic signed [11:0] value,
        input logic signed  [3:0] weight
    );
        logic signed [11:0] relu_value;
        begin
            relu_value = value[11] ? 12'sd0 : value;
            FC2_product = relu_value * weight;
        end
    endfunction

    always_comb begin
        integer i;

        state_next          = state;
        count_kc1_next      = count_kc1;
        count_kc2_next      = count_kc2;
        count_pooling_next  = count_pooling;
        FC1_index_next      = FC1_index;
        FC1_loaded_next     = FC1_loaded;
        FC2_loaded_next     = FC2_loaded;
        pooling_loaded_next = pooling_loaded;
        FC1_sum_0_next      = FC1_sum_0;
        FC1_sum_1_next      = FC1_sum_1;
        FC1_sum_2_next      = FC1_sum_2;
        FC1_product_0_next  = FC1_product_0;
        FC1_product_1_next  = FC1_product_1;
        FC1_product_2_next  = FC1_product_2;
        FC1_product_valid_next = FC1_product_valid;
        FC2_product_0_next  = FC2_product_0;
        FC2_product_1_next  = FC2_product_1;
        FC2_product_2_next  = FC2_product_2;
        fc_output_next      = fc_output;
        valid_output_next   = 1'b0;
        FC2_score           = 16'sd0;

        for (i = 0; i < 48; i = i + 1)
            k_FC1_next[i] = k_FC1[i];

        for (i = 0; i < 3; i = i + 1)
            k_FC2_next[i] = k_FC2[i];

        for (i = 0; i < 16; i = i + 1)
            pooling_input_next[i] = pooling_input[i];

        case (state)
            LOAD: begin
                if (!rst && valid_k_FC1_in && !FC1_loaded) begin
                    k_FC1_next[count_kc1] = $signed(k_FC1_in);
                    if (count_kc1 == 6'd47)
                        FC1_loaded_next = 1'b1;
                    else
                        count_kc1_next = count_kc1 + 1'b1;
                end

                if (!rst && valid_k_FC2_in && !FC2_loaded) begin
                    k_FC2_next[count_kc2] = $signed(k_FC2_in);
                    if (count_kc2 == 2'd2)
                        FC2_loaded_next = 1'b1;
                    else
                        count_kc2_next = count_kc2 + 1'b1;
                end

                if (!rst && valid_pooling && !pooling_loaded) begin
                    pooling_input_next[count_pooling] = pooling;
                    if (count_pooling == 4'd15)
                        pooling_loaded_next = 1'b1;
                    else
                        count_pooling_next = count_pooling + 1'b1;
                end

                if (FC1_loaded && FC2_loaded && pooling_loaded) begin
                    FC1_sum_0_next = FC1_BIAS_0;
                    FC1_sum_1_next = FC1_BIAS_1;
                    FC1_sum_2_next = FC1_BIAS_2;
                    FC1_index_next = 4'd0;
                    FC1_product_valid_next = 1'b0;
                    state_next = FC1;
                end
            end

            FC1: begin
                if (FC1_product_valid) begin
                    FC1_sum_0_next = FC1_sum_0 + FC1_product_0;
                    FC1_sum_1_next = FC1_sum_1 + FC1_product_1;
                    FC1_sum_2_next = FC1_sum_2 + FC1_product_2;
                end

                FC1_product_0_next = pool_product(
                    pooling_input[FC1_index], k_FC1[FC1_index]);
                FC1_product_1_next = pool_product(
                    pooling_input[FC1_index], k_FC1[16 + FC1_index]);
                FC1_product_2_next = pool_product(
                    pooling_input[FC1_index], k_FC1[32 + FC1_index]);
                FC1_product_valid_next = 1'b1;

                if (FC1_index == 4'd15)
                    state_next = FC1_FLUSH;
                else
                    FC1_index_next = FC1_index + 1'b1;
            end

            FC1_FLUSH: begin
                FC1_sum_0_next = FC1_sum_0 + FC1_product_0;
                FC1_sum_1_next = FC1_sum_1 + FC1_product_1;
                FC1_sum_2_next = FC1_sum_2 + FC1_product_2;
                FC1_product_valid_next = 1'b0;
                state_next = FC2_MULT;
            end

            FC2_MULT: begin
                FC2_product_0_next = FC2_product(FC1_sum_0, k_FC2[0]);
                FC2_product_1_next = FC2_product(FC1_sum_1, k_FC2[1]);
                FC2_product_2_next = FC2_product(FC1_sum_2, k_FC2[2]);
                state_next = FC2_SUM;
            end

            FC2_SUM: begin
                FC2_score = FC2_product_0 + FC2_product_1 +
                            FC2_product_2 + FC2_BIAS;
                fc_output_next = (FC2_score > 16'sd0);
                valid_output_next = 1'b1;
                state_next = DONE;
            end

            DONE: begin
                count_pooling_next = 4'd0;
                pooling_loaded_next = 1'b0;
                FC1_sum_0_next = 12'sd0;
                FC1_sum_1_next = 12'sd0;
                FC1_sum_2_next = 12'sd0;
                FC1_product_0_next = 12'sd0;
                FC1_product_1_next = 12'sd0;
                FC1_product_2_next = 12'sd0;
                FC1_product_valid_next = 1'b0;
                FC2_product_0_next = 16'sd0;
                FC2_product_1_next = 16'sd0;
                FC2_product_2_next = 16'sd0;
                FC1_index_next = 4'd0;
                state_next = LOAD;
            end

            default: begin
                state_next = LOAD;
            end
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= LOAD;
            count_kc1      <= 6'd0;
            count_kc2      <= 2'd0;
            count_pooling  <= 4'd0;
            FC1_index      <= 4'd0;
            FC1_loaded     <= 1'b0;
            FC2_loaded     <= 1'b0;
            pooling_loaded <= 1'b0;
            FC1_sum_0      <= 12'sd0;
            FC1_sum_1      <= 12'sd0;
            FC1_sum_2      <= 12'sd0;
            FC1_product_0  <= 12'sd0;
            FC1_product_1  <= 12'sd0;
            FC1_product_2  <= 12'sd0;
            FC1_product_valid <= 1'b0;
            FC2_product_0  <= 16'sd0;
            FC2_product_1  <= 16'sd0;
            FC2_product_2  <= 16'sd0;
            fc_output      <= 1'b0;
            valid_output   <= 1'b0;
        end
        else begin
            state          <= state_next;
            count_kc1      <= count_kc1_next;
            count_kc2      <= count_kc2_next;
            count_pooling  <= count_pooling_next;
            FC1_index      <= FC1_index_next;
            FC1_loaded     <= FC1_loaded_next;
            FC2_loaded     <= FC2_loaded_next;
            pooling_loaded <= pooling_loaded_next;
            FC1_sum_0      <= FC1_sum_0_next;
            FC1_sum_1      <= FC1_sum_1_next;
            FC1_sum_2      <= FC1_sum_2_next;
            FC1_product_0  <= FC1_product_0_next;
            FC1_product_1  <= FC1_product_1_next;
            FC1_product_2  <= FC1_product_2_next;
            FC1_product_valid <= FC1_product_valid_next;
            FC2_product_0  <= FC2_product_0_next;
            FC2_product_1  <= FC2_product_1_next;
            FC2_product_2  <= FC2_product_2_next;
            fc_output      <= fc_output_next;
            valid_output   <= valid_output_next;
        end
    end

    always_ff @(posedge clk) begin
        integer i;

        for (i = 0; i < 48; i = i + 1)
            k_FC1[i] <= k_FC1_next[i];

        for (i = 0; i < 3; i = i + 1)
            k_FC2[i] <= k_FC2_next[i];

        for (i = 0; i < 16; i = i + 1)
            pooling_input[i] <= pooling_input_next[i];
    end

endmodule
