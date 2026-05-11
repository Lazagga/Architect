`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
    input           clk,
    input           rst,
    input [5:0]     opcode,
    input [5:0]     funct,

    output reg      PCWrite,
    output reg      PCWriteCond,
    output reg      IorD,
    output reg      MemRead,
    output reg      MemWrite,
    output reg      IRWrite,
    output reg [1:0] MemtoReg,
    output reg [1:0] PCSource,
    output reg [3:0] ALUOp,
    output reg      ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg      RegWrite,
    output reg [1:0] RegDst
);
    reg [2:0] state;

    always @(posedge clk) begin
        if (rst)
            state <= `IF;
        else begin
            case (state)
                `IF: state <= `ID;
                `ID: state <= `EX;
                `EX: begin
                    case (opcode)
                        `OP_LW, `OP_SW: state <= `MEM;
                        `OP_BEQ, `OP_BNE: state <= `IF;
                        `OP_J, `OP_JAL: state <= `IF;
                        `OP_RTYPE: begin
                            if (funct == `FUNCT_JR) state <= `IF;
                            else state <= `WB;
                        end
                        default: state <= `WB;
                    endcase
                end
                `MEM: state <= (opcode == `OP_LW) ? `WB : `IF;
                `WB:  state <= `IF;
                default: state <= `IF;
            endcase
        end
    end

    always @(*) begin
        PCWrite = 0;
        PCWriteCond = 0;
        IorD = 0;
        MemRead = 0;
        MemWrite = 0;
        IRWrite = 0;
        MemtoReg = 2'b00;
        PCSource = 2'b00;
        ALUOp = `ALU_ADDU;
        ALUSrcA = 0;
        ALUSrcB = 2'b00;
        RegWrite = 0;
        RegDst = 2'b00;

        case (state)
            `IF: begin
                IRWrite = 1;
                MemRead = 1;
                ALUSrcA = 0;
                ALUSrcB = 2'b01;
                ALUOp = `ALU_ADDU;
                PCWrite = 1;
                PCSource = 2'b00;
            end
            `ID: begin
                ALUSrcA = 0;
                ALUSrcB = 2'b11;
                ALUOp = `ALU_ADDU;
            end
            `EX: begin
                case (opcode)
                    `OP_LW, `OP_SW: begin
                        ALUSrcA = 1;
                        ALUSrcB = 2'b10;
                        ALUOp = `ALU_ADDU;
                    end
                    `OP_BEQ, `OP_BNE: begin
                        ALUSrcA = 1;
                        ALUSrcB = 2'b00;
                        ALUOp = (opcode == `OP_BEQ) ? `ALU_EQ : `ALU_NEQ;
                        PCWriteCond = 1;
                        PCSource = 2'b01;
                    end
                    `OP_J: begin
                        PCWrite = 1;
                        PCSource = 2'b10;
                    end
                    `OP_JAL: begin
                        PCWrite = 1;
                        PCSource = 2'b10;
                        RegWrite = 1;
                        RegDst = 2'b11;
                        MemtoReg = 2'b10;
                    end
                    `OP_RTYPE: begin
                        if (funct == `FUNCT_JR) begin
                            PCWrite = 1;
                            PCSource = 2'b11;
                        end else begin
                            ALUSrcA = 1;
                            ALUSrcB = 2'b00;
                            case (funct)
                                `FUNCT_SLL: ALUOp = `ALU_SLL;
                                `FUNCT_SRL: ALUOp = `ALU_SRL;
                                `FUNCT_SRA: ALUOp = `ALU_SRA;
                                `FUNCT_ADDU: ALUOp = `ALU_ADDU;
                                `FUNCT_SUBU: ALUOp = `ALU_SUBU;
                                `FUNCT_AND: ALUOp = `ALU_AND;
                                `FUNCT_OR: ALUOp = `ALU_OR;
                                `FUNCT_XOR: ALUOp = `ALU_XOR;
                                `FUNCT_NOR: ALUOp = `ALU_NOR;
                                `FUNCT_SLT: ALUOp = `ALU_SLT;
                                `FUNCT_SLTU: ALUOp = `ALU_SLTU;
                                default: ALUOp = `ALU_ADDU;
                            endcase
                        end
                    end
                    default: begin
                        ALUSrcA = 1;
                        ALUSrcB = 2'b10;
                        case (opcode)
                            `OP_ADDIU: ALUOp = `ALU_ADDU;
                            `OP_SLTI: ALUOp = `ALU_SLT;
                            `OP_SLTIU: ALUOp = `ALU_SLTU;
                            `OP_ANDI: ALUOp = `ALU_AND;
                            `OP_ORI: ALUOp = `ALU_OR;
                            `OP_XORI: ALUOp = `ALU_XOR;
                            `OP_LUI: ALUOp = `ALU_LUI;
                            default: ALUOp = `ALU_ADDU;
                        endcase
                    end
                endcase
            end
            `MEM: begin
                IorD = 1;
                if (opcode == `OP_LW) MemRead  = 1;
                else MemWrite = 1;
            end
            `WB: begin
                RegWrite = 1;
                case (opcode)
                    `OP_LW: begin
                        RegDst = 2'b00;
                        MemtoReg = 2'b01;
                    end
                    `OP_RTYPE: begin
                        RegDst = 2'b01;
                        MemtoReg = 2'b00;
                    end
                    default: begin
                        RegDst = 2'b00;
                        MemtoReg = 2'b00;
                    end
                endcase
            end
        endcase
    end
endmodule
