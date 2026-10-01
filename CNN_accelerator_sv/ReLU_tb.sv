`timescale 1ns / 1ps

module tb_RELU_v1;

    logic [3:0] ofmap_in;
    logic       valid_ofmap;
    logic [3:0] ofmap_relu;

    RELU_v1 dut (
        .ofmap_in    (ofmap_in),
        .valid_ofmap (valid_ofmap),
        .ofmap_relu  (ofmap_relu)
    );

    task automatic check_relu (
        input logic       valid_value,
        input logic [3:0] input_value,
        input logic [3:0] expected
    );
        begin
            valid_ofmap = valid_value;
            ofmap_in    = input_value;
            #1;

            if (ofmap_relu !== expected)
                $fatal(
                    1,
                    "ReLU failed: valid=%b input=%b got=%b expected=%b",
                    valid_value,
                    input_value,
                    ofmap_relu,
                    expected
                );
        end
    endtask

    initial begin
        // 有效的正数
        check_relu(1'b1, 4'b0011, 4'b0011); // +3
        check_relu(1'b1, 4'b0111, 4'b0111); // +7

        // 有效的负数
        check_relu(1'b1, 4'b1111, 4'b0000); // -1
        check_relu(1'b1, 4'b1011, 4'b0000); // -5
        check_relu(1'b1, 4'b1000, 4'b0000); // -8

        // 按参考IP行为：无效时直接传递输入
        check_relu(1'b0, 4'b1011, 4'b1011);

        $display("PASS: ReLU tests completed.");
        $finish;
    end

endmodule