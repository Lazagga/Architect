`timescale 1ns / 100ps

module adder (
    input clk,
    input rst,
    input [31:0] in,
    output [31:0] out
);
    reg [31:0] acc;

    assign out = in + acc;

    always @(posedge clk) begin
        if (rst) begin
            acc <= 0;
        end
        else begin
            acc <= out;
        end
    end
endmodule