`timescale 1ns / 1ps

module id_ex_reg (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    input wire [31:0] pc_in,
    input wire [31:0] rdata1_in,
    input wire [31:0] rdata2_in,
    input wire [31:0] imm_in,
    input wire [4:0] rs_in,
    input wire [4:0] rt_in,
    input wire [4:0] rd_in,
    input wire [4:0] wreg_in,
    input wire [5:0] op_in,
    input wire [5:0] func_in,
    input wire regw_in,
    input wire memr_in,
    input wire memw_in,
    input wire [1:0] mem2reg_in,
    input wire [1:0] aluop_in,
    input wire alusrc_in,
    input wire branch_in,
    input wire jump_in,
    input wire regdst_in,
    input wire link_in,
    input wire sign_ext_in,
    output reg [31:0] pc_out,
    output reg [31:0] rdata1_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] imm_out,
    output reg [4:0] rs_out,
    output reg [4:0] rt_out,
    output reg [4:0] rd_out,
    output reg [4:0] wreg_out,
    output reg [5:0] op_out,
    output reg [5:0] func_out,
    output reg regw_out,
    output reg memr_out,
    output reg memw_out,
    output reg [1:0] mem2reg_out,
    output reg [1:0] aluop_out,
    output reg alusrc_out,
    output reg branch_out,
    output reg jump_out,
    output reg regdst_out,
    output reg link_out,
    output reg sign_ext_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 32'b0;
            rdata1_out <= 32'b0;
            rdata2_out <= 32'b0;
            imm_out <= 32'b0;
            rs_out <= 5'b0;
            rt_out <= 5'b0;
            rd_out <= 5'b0;
            wreg_out <= 5'b0;
            op_out <= 6'b0;
            func_out <= 6'b0;
            regw_out <= 1'b0;
            memr_out <= 1'b0;
            memw_out <= 1'b0;
            mem2reg_out <= 2'b00;
            aluop_out <= 2'b00;
            alusrc_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
            regdst_out <= 1'b0;
            link_out <= 1'b0;
            sign_ext_out <= 1'b1;
        end else if (flush) begin
            // flush时清空（用于分支跳转后的清除）
            pc_out <= 32'b0;
            rdata1_out <= 32'b0;
            rdata2_out <= 32'b0;
            imm_out <= 32'b0;
            rs_out <= 5'b0;
            rt_out <= 5'b0;
            rd_out <= 5'b0;
            wreg_out <= 5'b0;
            op_out <= 6'b0;
            func_out <= 6'b0;
            regw_out <= 1'b0;
            memr_out <= 1'b0;
            memw_out <= 1'b0;
            mem2reg_out <= 2'b00;
            aluop_out <= 2'b00;
            alusrc_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
            regdst_out <= 1'b0;
            link_out <= 1'b0;
            sign_ext_out <= 1'b1;
        end else if (!stall) begin
            pc_out <= pc_in;
            rdata1_out <= rdata1_in;
            rdata2_out <= rdata2_in;
            imm_out <= imm_in;
            rs_out <= rs_in;
            rt_out <= rt_in;
            rd_out <= rd_in;
            wreg_out <= wreg_in;
            op_out <= op_in;
            func_out <= func_in;
            regw_out <= regw_in;
            memr_out <= memr_in;
            memw_out <= memw_in;
            mem2reg_out <= mem2reg_in;
            aluop_out <= aluop_in;
            alusrc_out <= alusrc_in;
            branch_out <= branch_in;
            jump_out <= jump_in;
            regdst_out <= regdst_in;
            link_out <= link_in;
            sign_ext_out <= sign_ext_in;
        end
    end

endmodule