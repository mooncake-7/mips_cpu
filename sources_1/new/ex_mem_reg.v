`timescale 1ns / 1ps

module ex_mem_reg (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire [31:0] alu_out_in,
    input wire [31:0] rdata2_in,
    input wire [4:0] wreg_in,
    input wire regw_in,
    input wire memr_in,
    input wire memw_in,
    input wire [1:0] mem2reg_in,
    input wire link_in,
    input wire [31:0] pc_plus8_in,
    input wire [5:0] op_in,        // 用于LB/SB判断
    output reg [31:0] alu_out,
    output reg [31:0] rdata2_out,
    output reg [4:0] wreg_out,
    output reg regw_out,
    output reg memr_out,
    output reg memw_out,
    output reg [1:0] mem2reg_out,
    output reg link_out,
    output reg [31:0] pc_plus8_out,
    output reg [5:0] op_out        
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_out <= 32'b0;
            rdata2_out <= 32'b0;
            wreg_out <= 5'b0;
            regw_out <= 1'b0;
            memr_out <= 1'b0;
            memw_out <= 1'b0;
            mem2reg_out <= 2'b00;
            link_out <= 1'b0;
            pc_plus8_out <= 32'b0;
            op_out <= 6'b0;
        end else begin
            alu_out <= alu_out_in;
            rdata2_out <= rdata2_in;
            //regw_in=0 时清零 wreg_out
            if (regw_in) begin
                wreg_out <= wreg_in;
                regw_out <= 1'b1;
            end else begin
                wreg_out <= 5'b0;
                regw_out <= 1'b0;
            end
            memr_out <= memr_in;
            memw_out <= memw_in;
            mem2reg_out <= mem2reg_in;
            link_out <= link_in;
            pc_plus8_out <= pc_plus8_in;
            op_out <= op_in;
        end
    end

endmodule