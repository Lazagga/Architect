`timescale 1ns / 1ps

module FORWARD(
    input  [4:0] id_ex_rs,
    input  [4:0] id_ex_rt,

    input        ex_mem_RegWrite,
    input  [4:0] ex_mem_wr_reg,
    input        ex_mem_MemRead,

    input        mem_wb_RegWrite,
    input  [4:0] mem_wb_wr_reg,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;

        if (ex_mem_RegWrite && !ex_mem_MemRead &&
            (ex_mem_wr_reg != 5'b0) && (ex_mem_wr_reg == id_ex_rs)) begin
            forwardA = 2'b10;
        end else if (mem_wb_RegWrite &&
            (mem_wb_wr_reg != 5'b0) && (mem_wb_wr_reg == id_ex_rs)) begin
            forwardA = 2'b01;
        end

        if (ex_mem_RegWrite && !ex_mem_MemRead &&
            (ex_mem_wr_reg != 5'b0) && (ex_mem_wr_reg == id_ex_rt)) begin
            forwardB = 2'b10;
        end else if (mem_wb_RegWrite &&
            (mem_wb_wr_reg != 5'b0) && (mem_wb_wr_reg == id_ex_rt)) begin
            forwardB = 2'b01;
        end
    end
endmodule
