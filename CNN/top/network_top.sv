module network_top (
    input  logic         clk,
    input  logic         rst,
    input  logic         start_in,
    input  logic  [3:0]  f_in,
    input  logic         valid_in_f,
    input  logic  [3:0]  k_FC1_in,
    input  logic         valid_k_FC1_in,
    input  logic  [3:0]  k_FC2_in,
    input  logic         valid_k_FC2_in,
    output logic         out,
    output logic         valid_output
);

    // ------------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------------
    logic        valid_ofmap;
    logic [3:0]  ofmap_RELU;
    logic [3:0]  pooling_out;
    logic        valid_pooling;

    // ------------------------------------------------------------------
    // Instantiations
    // ------------------------------------------------------------------

    // Convolution stage
    conv_top CONV_TOP_inst (
        .clk         (clk),
        .rst         (rst),
        .start_in    (start_in),
        .f_in        (f_in),
        .valid_in_f  (valid_in_f),
        .ofmap       (ofmap_RELU),
        .valid_ofmap (valid_ofmap)
    );

    // Pooling stage
    Pooling_TOP Pooling_inst (
        .clk           (clk),
        .rst           (rst),
        .ofmap_RELU    (ofmap_RELU),
        .valid_data    (valid_ofmap),
        .pooling_out   (pooling_out),
        .valid_pooling (valid_pooling)
    );

    // Fully-connected stage
    FC_TOP FC_inst (
        .clk           (clk),
        .rst           (rst),
        .kernel_FC1_in (k_FC1_in),
        .valid_FC1_in  (valid_k_FC1_in),
        .kernel_FC2_in (k_FC2_in),
        .valid_FC2_in  (valid_k_FC2_in),
        .pooling       (pooling_out),
        .valid_pooling (valid_pooling),
        .fc_output     (out),
        .valid_output  (valid_output)
    );

endmodule
