`timescale 1ns / 1ps
`include "GLOBAL.v"

module CPU(
    input   clk,
    input   rst,
    output  halt
);
    reg  [31:0] IR;
    wire [5:0]  opcode = IR[31:26];
    wire [4:0]  rs     = IR[25:21];
    wire [4:0]  rt     = IR[20:16];
    wire [4:0]  rd     = IR[15:11];
    wire [4:0]  shamt  = IR[10:6];
    wire [5:0]  funct  = IR[5:0];
    wire [15:0] immi   = IR[15:0];
    wire [25:0] immj   = IR[25:0];

    wire [31:0] ext_imm = (opcode == `OP_ANDI || opcode == `OP_ORI || opcode == `OP_XORI)
                          ? {16'b0, immi}
                          : {{16{immi[15]}}, immi};

    reg [31:0] PC;
    reg [31:0] MDR;
    reg [31:0] A, B;
    reg [31:0] ALUOut;

    wire        PCWrite, PCWriteCond, IorD;
    wire        MemRead, MemWrite, IRWrite;
    wire [1:0]  MemtoReg, PCSource, RegDst;
    wire [3:0]  ALUOp;
    wire        ALUSrcA;
    wire [1:0]  ALUSrcB;
    wire        RegWrite;

    wire [31:0] rd_data1, rd_data2;
    wire [4:0]  wr_addr;
    wire [31:0] wr_data;

    wire [31:0] operand1, operand2, alu_result;

    wire [31:0] mem_addr, mem_read_data;

    // registered to avoid delta-cycle glitch on S_MEM_WRITE→S_IF transition
    reg halt_reg;
    always @(posedge clk) begin
        if (rst) halt_reg <= 1'b0;
        else if (IRWrite) halt_reg <= (mem_read_data == 32'b0);
    end
    assign halt = halt_reg;

    assign mem_addr = IorD ? ALUOut : PC;

    assign operand1 = ALUSrcA ? A : PC;
    assign operand2 = (ALUSrcB == 2'b00) ? B                     :
                      (ALUSrcB == 2'b01) ? 32'd4                  :
                      (ALUSrcB == 2'b10) ? ext_imm                :
                                           {ext_imm[29:0], 2'b00};

    wire [31:0] jump_addr = {PC[31:28], immj, 2'b00};
    wire [31:0] pc_next   = (PCSource == 2'b00) ? alu_result :
                            (PCSource == 2'b01) ? ALUOut     :
                            (PCSource == 2'b10) ? jump_addr  :
                                                  A;

    wire pc_en = PCWrite | (PCWriteCond & alu_result[0]);

    assign wr_addr = (RegDst == 2'b01) ? rd    :
                     (RegDst == 2'b11) ? 5'd31 :
                                         rt;
    assign wr_data = (MemtoReg == 2'b01) ? MDR :
                     (MemtoReg == 2'b10) ? PC  :
                                           ALUOut;

    always @(posedge clk) begin
        if (rst) begin
            PC     <= 32'b0;
            IR     <= 32'b0;
            MDR    <= 32'b0;
            A      <= 32'b0;
            B      <= 32'b0;
            ALUOut <= 32'b0;
        end else begin
            if (pc_en)   PC <= pc_next;
            if (IRWrite) IR <= mem_read_data;
            MDR    <= mem_read_data;
            A      <= rd_data1;
            B      <= rd_data2;
            ALUOut <= alu_result;
        end
    end

    CTRL ctrl (
        .clk(clk),          .rst(rst),
        .opcode(opcode),    .funct(funct),
        .PCWrite(PCWrite),  .PCWriteCond(PCWriteCond),
        .IorD(IorD),        .MemRead(MemRead),   .MemWrite(MemWrite),
        .IRWrite(IRWrite),  .MemtoReg(MemtoReg), .PCSource(PCSource),
        .ALUOp(ALUOp),      .ALUSrcA(ALUSrcA),   .ALUSrcB(ALUSrcB),
        .RegWrite(RegWrite),.RegDst(RegDst)
    );

    RF rf (
        .clk(clk),      .rst(rst),
        .rd_addr1(rs),  .rd_addr2(rt),
        .rd_data1(rd_data1), .rd_data2(rd_data2),
        .RegWrite(RegWrite), .wr_addr(wr_addr), .wr_data(wr_data)
    );

    MEM mem (
        .clk(clk),          .rst(rst),
        .mem_addr(mem_addr),
        .MemWrite(MemWrite),
        .mem_write_data(B),
        .mem_read_data(mem_read_data)
    );

    ALU alu (
        .operand1(operand1), .operand2(operand2),
        .shamt(shamt),       .funct(ALUOp),
        .alu_result(alu_result)
    );

endmodule
