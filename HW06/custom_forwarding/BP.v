`timescale 1ns / 1ps
`include "GLOBAL.v"

module BP(
    input         clk,
    input         rst,

    input  [31:0] pc,
    output        predict_taken,
    output [31:0] predict_pc,

    input         update,
    input  [31:0] update_pc,
    input         update_is_jump,
    input         update_is_branch,
    input         update_taken,
    input  [31:0] update_target
);
    reg [23:0] btb_tag    [0:63];
    reg [31:0] btb_target [0:63];
    reg [1:0]  btb_type   [0:63]; // entry type
    reg [1:0]  pht        [0:255];

    wire [5:0]  idx = pc[7:2];
    wire [23:0] tag = pc[31:8];
    wire [7:0]  pht_idx = pc[9:2];
    wire        btb_hit = (btb_type[idx] != 2'b00) && (btb_tag[idx] == tag);
    wire        is_jump_entry = (btb_type[idx] == 2'b01);
    wire        is_branch_entry = (btb_type[idx] == 2'b10);
    wire        pht_taken = pht[pht_idx][1];

    assign predict_taken = btb_hit && (is_jump_entry || (is_branch_entry && pht_taken));
    assign predict_pc = predict_taken ? btb_target[idx] : (pc + 4);

    integer i;
    wire [5:0]  update_idx = update_pc[7:2];
    wire [7:0]  update_pht_idx = update_pc[9:2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1) begin
                btb_tag[i]    <= 24'b0;
                btb_target[i] <= 32'b0;
                btb_type[i]   <= 2'b00;
            end
            for (i = 0; i < 256; i = i + 1) begin
                pht[i] <= 2'b01;
            end
        end else if (update) begin
            btb_tag[update_idx]    <= update_pc[31:8];
            btb_target[update_idx] <= update_target;
            btb_type[update_idx]   <= update_is_jump ? 2'b01 :
                                      update_is_branch ? 2'b10 : 2'b00;

            if (update_is_branch) begin
                if (update_taken && (pht[update_pht_idx] != 2'b11))
                    pht[update_pht_idx] <= pht[update_pht_idx] + 2'b01;
                else if (!update_taken && (pht[update_pht_idx] != 2'b00))
                    pht[update_pht_idx] <= pht[update_pht_idx] - 2'b01;
            end
        end
    end
endmodule
