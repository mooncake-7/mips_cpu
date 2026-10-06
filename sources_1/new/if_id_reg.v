`timescale 1ns / 1ps

module if_id_reg (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    input wire [31:0] pc_in,
    input wire [31:0] inst_in,
    output reg [31:0] pc_out,
    output reg [31:0] inst_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 32'b0;
            inst_out <= 32'b0;
        end else if (flush) begin
            // flush时清空（分支跳转时，清除分支指令本身)
            pc_out <= 32'b0;
            inst_out <= 32'b0;
        end else if (!stall) begin
            pc_out <= pc_in;
            inst_out <= inst_in;
        end
    end
endmodule