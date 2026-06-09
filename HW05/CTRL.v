`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
    input  [5:0] opcode,
    input  [5:0] funct,

    output reg        ALUSrcA,
    output reg [1:0]  ALUSrcB,
    output reg [3:0]  ALUOp,
    output reg [1:0]  RegDst,

    output reg        MemRead,
    output reg        MemWrite,
    output reg        Branch,
    output reg        BranchNE,

    output reg [1:0]  MemtoReg,
    output reg        RegWrite,

    output reg        Jump,
    output reg        Jal,
    output reg        Jr
);
    always @(*) begin
        ALUSrcA  = 1'b0;
        ALUSrcB  = 2'b00;
        ALUOp    = `ALU_ADDU;
        RegDst   = 2'b00;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        BranchNE = 1'b0;
        MemtoReg = 2'b00;
        RegWrite = 1'b0;
        Jump     = 1'b0;
        Jal      = 1'b0;
        Jr       = 1'b0;

        case (opcode)
            `OP_RTYPE: begin
                if (funct == `FUNCT_JR) begin
                    Jr = 1'b1;
                end else begin
                    ALUSrcA  = 1'b1;
                    ALUSrcB  = 2'b00;
                    RegDst   = 2'b01;
                    RegWrite = 1'b1;
                    MemtoReg = 2'b00;
                    case (funct)
                        `FUNCT_SLL:  ALUOp = `ALU_SLL;
                        `FUNCT_SRL:  ALUOp = `ALU_SRL;
                        `FUNCT_SRA:  ALUOp = `ALU_SRA;
                        `FUNCT_ADDU: ALUOp = `ALU_ADDU;
                        `FUNCT_SUBU: ALUOp = `ALU_SUBU;
                        `FUNCT_AND:  ALUOp = `ALU_AND;
                        `FUNCT_OR:   ALUOp = `ALU_OR;
                        `FUNCT_XOR:  ALUOp = `ALU_XOR;
                        `FUNCT_NOR:  ALUOp = `ALU_NOR;
                        `FUNCT_SLT:  ALUOp = `ALU_SLT;
                        `FUNCT_SLTU: ALUOp = `ALU_SLTU;
                        default:     ALUOp = `ALU_ADDU;
                    endcase
                end
            end

            `OP_LW: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_ADDU;
                RegDst   = 2'b00;
                MemRead  = 1'b1;
                RegWrite = 1'b1;
                MemtoReg = 2'b01;
            end

            `OP_SW: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_ADDU;
                MemWrite = 1'b1;
            end

            `OP_BEQ: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b00;
                ALUOp    = `ALU_EQ;
                Branch   = 1'b1;
            end

            `OP_BNE: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b00;
                ALUOp    = `ALU_NEQ;
                BranchNE = 1'b1;
            end

            `OP_J: begin
                Jump = 1'b1;
            end

            `OP_JAL: begin
                Jump     = 1'b1;
                Jal      = 1'b1;
                RegDst   = 2'b11;
                RegWrite = 1'b1;
                MemtoReg = 2'b10;
            end

            `OP_ADDIU: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_ADDU;
                RegWrite = 1'b1;
            end

            `OP_SLTI: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_SLT;
                RegWrite = 1'b1;
            end

            `OP_SLTIU: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_SLTU;
                RegWrite = 1'b1;
            end

            `OP_ANDI: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_AND;
                RegWrite = 1'b1;
            end

            `OP_ORI: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_OR;
                RegWrite = 1'b1;
            end

            `OP_XORI: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_XOR;
                RegWrite = 1'b1;
            end

            `OP_LUI: begin
                ALUSrcA  = 1'b1;
                ALUSrcB  = 2'b10;
                ALUOp    = `ALU_LUI;
                RegWrite = 1'b1;
            end

            default: begin end
        endcase
    end
endmodule
