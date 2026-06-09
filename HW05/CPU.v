`timescale 1ns / 1ps
`include "GLOBAL.v"

module CPU(
    input  clk,
    input  rst,
    output halt
);

// IF
reg  [31:0] PC;
wire [31:0] if_inst;

// IF/ID
reg [31:0] if_id_pc4;
reg [31:0] if_id_inst;
reg        if_id_is_halt;

// ID
wire [5:0]  id_opcode = if_id_inst[31:26];
wire [4:0]  id_rs     = if_id_inst[25:21];
wire [4:0]  id_rt     = if_id_inst[20:16];
wire [4:0]  id_rd     = if_id_inst[15:11];
wire [4:0]  id_shamt  = if_id_inst[10:6];
wire [5:0]  id_funct  = if_id_inst[5:0];
wire [15:0] id_immi   = if_id_inst[15:0];
wire [25:0] id_immj   = if_id_inst[25:0];

wire [31:0] id_ext_imm =
    (id_opcode == `OP_ANDI || id_opcode == `OP_ORI || id_opcode == `OP_XORI)
    ? {16'b0, id_immi} : {{16{id_immi[15]}}, id_immi};

wire [31:0] id_rd1, id_rd2;

wire        id_ALUSrcA, id_MemRead, id_MemWrite;
wire        id_Branch,  id_BranchNE, id_RegWrite;
wire [1:0]  id_ALUSrcB, id_RegDst, id_MemtoReg;
wire [3:0]  id_ALUOp;
wire        id_Jump, id_Jal, id_Jr;

// Jump/JR targets resolved in ID
wire [31:0] id_jump_tgt = {if_id_pc4[31:28], id_immj, 2'b00};
wire [31:0] id_jr_tgt   = id_rd1;

wire stall;
wire id_jump_taken = id_Jump || (id_Jr && !stall);

// ID/EX
reg [31:0] id_ex_pc4;
reg [31:0] id_ex_rd1, id_ex_rd2;
reg [31:0] id_ex_ext;
reg [4:0]  id_ex_rs, id_ex_rt, id_ex_rd, id_ex_shamt;
reg        id_ex_ALUSrcA;
reg [1:0]  id_ex_ALUSrcB;
reg [3:0]  id_ex_ALUOp;
reg [1:0]  id_ex_RegDst;
reg        id_ex_MemRead,  id_ex_MemWrite;
reg        id_ex_Branch,   id_ex_BranchNE;
reg [1:0]  id_ex_MemtoReg;
reg        id_ex_RegWrite;
reg        id_ex_is_halt;

// EX
wire [4:0]  ex_wr_reg =
    (id_ex_RegDst == 2'b01) ? id_ex_rd :
    (id_ex_RegDst == 2'b11) ? 5'd31    : id_ex_rt;

wire [31:0] ex_op1 = id_ex_ALUSrcA ? id_ex_rd1 : id_ex_pc4;
wire [31:0] ex_op2 = (id_ex_ALUSrcB == 2'b00) ? id_ex_rd2 : id_ex_ext;
wire [31:0] ex_alu_result;

wire [31:0] ex_branch_tgt  = id_ex_pc4 + {id_ex_ext[29:0], 2'b00};
wire        ex_branch_taken = (id_ex_Branch || id_ex_BranchNE) && ex_alu_result[0];

// EX/MEM
reg [31:0] ex_mem_alu_result;
reg [31:0] ex_mem_rd2;
reg [4:0]  ex_mem_wr_reg;
reg        ex_mem_MemRead, ex_mem_MemWrite;
reg [1:0]  ex_mem_MemtoReg;
reg        ex_mem_RegWrite;
reg [31:0] ex_mem_pc4;
reg        ex_mem_is_halt;

// MEM
wire [31:0] mem_rd_data;

// MEM/WB
reg [31:0] mem_wb_alu_result;
reg [31:0] mem_wb_mem_data;
reg [4:0]  mem_wb_wr_reg;
reg [1:0]  mem_wb_MemtoReg;
reg        mem_wb_RegWrite;
reg [31:0] mem_wb_pc4;
reg        mem_wb_is_halt;

// WB
wire [31:0] wb_wr_data =
    (mem_wb_MemtoReg == 2'b01) ? mem_wb_mem_data :
    (mem_wb_MemtoReg == 2'b10) ? mem_wb_pc4      : mem_wb_alu_result;

assign halt = mem_wb_is_halt;

// Flush control
wire if_flush = ex_branch_taken || id_jump_taken;
wire id_flush = ex_branch_taken;

CTRL ctrl (
    .opcode(id_opcode), .funct(id_funct),
    .ALUSrcA(id_ALUSrcA), .ALUSrcB(id_ALUSrcB),
    .ALUOp(id_ALUOp),     .RegDst(id_RegDst),
    .MemRead(id_MemRead), .MemWrite(id_MemWrite),
    .Branch(id_Branch),   .BranchNE(id_BranchNE),
    .MemtoReg(id_MemtoReg), .RegWrite(id_RegWrite),
    .Jump(id_Jump),       .Jal(id_Jal), .Jr(id_Jr)
);

RF rf (
    .clk(clk),             .rst(rst),
    .rd_addr1(id_rs),      .rd_addr2(id_rt),
    .rd_data1(id_rd1),     .rd_data2(id_rd2),
    .RegWrite(mem_wb_RegWrite),
    .wr_addr(mem_wb_wr_reg),
    .wr_data(wb_wr_data)
);

MEM mem (
    .clk(clk),             .rst(rst),
    .inst_addr(PC),        .inst(if_inst),
    .mem_addr(ex_mem_alu_result),
    .MemWrite(ex_mem_MemWrite),
    .mem_write_data(ex_mem_rd2),
    .mem_read_data(mem_rd_data)
);

ALU alu (
    .operand1(ex_op1),    .operand2(ex_op2),
    .shamt(id_ex_shamt),  .funct(id_ex_ALUOp),
    .alu_result(ex_alu_result)
);

HAZARD hazard (
    .id_ex_RegWrite(id_ex_RegWrite),
    .id_ex_wr_reg(ex_wr_reg),
    .ex_mem_RegWrite(ex_mem_RegWrite),
    .ex_mem_wr_reg(ex_mem_wr_reg),
    .if_id_rs(id_rs),
    .if_id_rt(id_rt),
    .stall(stall)
);

// PC
always @(posedge clk) begin
    if (rst)
        PC <= 32'b0;
    else if (ex_branch_taken)
        PC <= ex_branch_tgt;
    else if (!stall) begin
        if      (id_Jump) PC <= id_jump_tgt;
        else if (id_Jr)   PC <= id_jr_tgt;
        else              PC <= PC + 4;
    end
end

// IF/ID
always @(posedge clk) begin
    if (rst || if_flush) begin
        if_id_pc4     <= 32'b0;
        if_id_inst    <= 32'b0;
        if_id_is_halt <= 1'b0;
    end else if (!stall) begin
        if_id_pc4     <= PC + 4;
        if_id_inst    <= if_inst;
        if_id_is_halt <= (if_inst == 32'b0);
    end
end

// ID/EX
always @(posedge clk) begin
    if (rst || id_flush || stall) begin
        id_ex_pc4      <= 32'b0;
        id_ex_rd1      <= 32'b0;
        id_ex_rd2      <= 32'b0;
        id_ex_ext      <= 32'b0;
        id_ex_rs       <= 5'b0;
        id_ex_rt       <= 5'b0;
        id_ex_rd       <= 5'b0;
        id_ex_shamt    <= 5'b0;
        id_ex_ALUSrcA  <= 1'b0;
        id_ex_ALUSrcB  <= 2'b0;
        id_ex_ALUOp    <= 4'b0;
        id_ex_RegDst   <= 2'b0;
        id_ex_MemRead  <= 1'b0;
        id_ex_MemWrite <= 1'b0;
        id_ex_Branch   <= 1'b0;
        id_ex_BranchNE <= 1'b0;
        id_ex_MemtoReg <= 2'b0;
        id_ex_RegWrite <= 1'b0;
        id_ex_is_halt  <= 1'b0;
    end else begin
        id_ex_pc4      <= if_id_pc4;
        id_ex_rd1      <= id_rd1;
        id_ex_rd2      <= id_rd2;
        id_ex_ext      <= id_ext_imm;
        id_ex_rs       <= id_rs;
        id_ex_rt       <= id_rt;
        id_ex_rd       <= id_rd;
        id_ex_shamt    <= id_shamt;
        id_ex_ALUSrcA  <= id_ALUSrcA;
        id_ex_ALUSrcB  <= id_ALUSrcB;
        id_ex_ALUOp    <= id_ALUOp;
        id_ex_RegDst   <= id_RegDst;
        id_ex_MemRead  <= id_MemRead;
        id_ex_MemWrite <= id_MemWrite;
        id_ex_Branch   <= id_Branch;
        id_ex_BranchNE <= id_BranchNE;
        id_ex_MemtoReg <= id_MemtoReg;
        id_ex_RegWrite <= id_RegWrite;
        id_ex_is_halt  <= if_id_is_halt;
    end
end

// EX/MEM
always @(posedge clk) begin
    if (rst) begin
        ex_mem_alu_result <= 32'b0;
        ex_mem_rd2        <= 32'b0;
        ex_mem_wr_reg     <= 5'b0;
        ex_mem_MemRead    <= 1'b0;
        ex_mem_MemWrite   <= 1'b0;
        ex_mem_MemtoReg   <= 2'b0;
        ex_mem_RegWrite   <= 1'b0;
        ex_mem_pc4        <= 32'b0;
        ex_mem_is_halt    <= 1'b0;
    end else begin
        ex_mem_alu_result <= ex_alu_result;
        ex_mem_rd2        <= id_ex_rd2;
        ex_mem_wr_reg     <= ex_wr_reg;
        ex_mem_MemRead    <= id_ex_MemRead;
        ex_mem_MemWrite   <= id_ex_MemWrite;
        ex_mem_MemtoReg   <= id_ex_MemtoReg;
        ex_mem_RegWrite   <= id_ex_RegWrite;
        ex_mem_pc4        <= id_ex_pc4;
        ex_mem_is_halt    <= id_ex_is_halt;
    end
end

// MEM/WB
always @(posedge clk) begin
    if (rst) begin
        mem_wb_alu_result <= 32'b0;
        mem_wb_mem_data   <= 32'b0;
        mem_wb_wr_reg     <= 5'b0;
        mem_wb_MemtoReg   <= 2'b0;
        mem_wb_RegWrite   <= 1'b0;
        mem_wb_pc4        <= 32'b0;
        mem_wb_is_halt    <= 1'b0;
    end else begin
        mem_wb_alu_result <= ex_mem_alu_result;
        mem_wb_mem_data   <= mem_rd_data;
        mem_wb_wr_reg     <= ex_mem_wr_reg;
        mem_wb_MemtoReg   <= ex_mem_MemtoReg;
        mem_wb_RegWrite   <= ex_mem_RegWrite;
        mem_wb_pc4        <= ex_mem_pc4;
        mem_wb_is_halt    <= ex_mem_is_halt;
    end
end

endmodule
