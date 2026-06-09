`timescale 1ns / 1ps

module HAZARD(
    // Instruction in EX stage (from ID/EX register)
    input        id_ex_RegWrite,
    input  [4:0] id_ex_wr_reg,

    // Instruction in MEM stage (from EX/MEM register)
    input        ex_mem_RegWrite,
    input  [4:0] ex_mem_wr_reg,

    // Instruction in ID stage (from IF/ID register)
    input  [4:0] if_id_rs,
    input  [4:0] if_id_rt,

    output       stall
);
    wire ex_hazard_rs  = id_ex_RegWrite  && (id_ex_wr_reg  != 5'b0) && (id_ex_wr_reg  == if_id_rs);
    wire ex_hazard_rt  = id_ex_RegWrite  && (id_ex_wr_reg  != 5'b0) && (id_ex_wr_reg  == if_id_rt);
    wire mem_hazard_rs = ex_mem_RegWrite && (ex_mem_wr_reg != 5'b0) && (ex_mem_wr_reg == if_id_rs);
    wire mem_hazard_rt = ex_mem_RegWrite && (ex_mem_wr_reg != 5'b0) && (ex_mem_wr_reg == if_id_rt);

    assign stall = ex_hazard_rs || ex_hazard_rt || mem_hazard_rs || mem_hazard_rt;
endmodule
