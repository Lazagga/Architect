`timescale 1ns / 1ps

module HAZARD(
    input        id_ex_MemRead,
    input        id_ex_RegWrite,
    input  [4:0] id_ex_wr_reg,

    input        ex_mem_MemRead,
    input  [4:0] ex_mem_wr_reg,

    input  [4:0] if_id_rs,
    input  [4:0] if_id_rt,
    input        if_id_uses_rs,
    input        if_id_uses_rt,
    input        if_id_is_jr,

    output       stall
);
    wire load_use_rs = id_ex_MemRead && (id_ex_wr_reg != 5'b0) &&
                       if_id_uses_rs && (id_ex_wr_reg == if_id_rs);
    wire load_use_rt = id_ex_MemRead && (id_ex_wr_reg != 5'b0) &&
                       if_id_uses_rt && (id_ex_wr_reg == if_id_rt);

    // JR hazard
    wire jr_ex_rs = if_id_is_jr && id_ex_RegWrite && (id_ex_wr_reg != 5'b0) &&
                    (id_ex_wr_reg == if_id_rs);
    wire jr_mem_load_rs = if_id_is_jr && ex_mem_MemRead && (ex_mem_wr_reg != 5'b0) &&
                          (ex_mem_wr_reg == if_id_rs);

    assign stall = load_use_rs || load_use_rt || jr_ex_rs || jr_mem_load_rs;
endmodule
