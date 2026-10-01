`timescale 1ns / 1ps

module dist_mem_gen_0 (
    input  logic        clk,
    input  logic [3:0]  a,
    input  logic [63:0] d,
    input  logic        we,
    output logic [63:0] spo
);

    distributed_ram_16x64 #(
        .INIT_FILE("MemInitData1.mem")
    ) memory_inst (
        .clk (clk),
        .a   (a),
        .d   (d),
        .we  (we),
        .spo (spo)
    );

endmodule
