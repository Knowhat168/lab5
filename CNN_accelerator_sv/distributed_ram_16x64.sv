`timescale 1ns / 1ps

// Shared implementation used by all four image memories.
// The read port is asynchronous and the write port is synchronous,
// matching the Single Port distributed-memory configuration used by the lab.
module distributed_ram_16x64 #(
    parameter INIT_FILE = ""
) (
    input  logic        clk,
    input  logic [3:0]  a,
    input  logic [63:0] d,
    input  logic        we,
    output logic [63:0] spo
);

    (* ram_style = "distributed" *) logic [63:0] memory [0:15];

    integer index;
    initial begin
        // A defined default also makes a missing/short file obvious and repeatable.
        for (index = 0; index < 16; index = index + 1)
            memory[index] = 64'b0;

        if (INIT_FILE != "")
            $readmemb(INIT_FILE, memory);
    end

    // Synchronous write: data is stored only at the rising clock edge.
    always_ff @(posedge clk) begin
        if (we)
            memory[a] <= d;
    end

    // Asynchronous read: changing the address changes the output directly.
    always_comb begin
        spo = memory[a];
    end

endmodule
