`timescale 1ns / 1ps

module mem_wb_reg (
    input wire clk,
    input wire reset,
    input wire [31:0] alu_in,
    input wire [31:0] mem_in,
    input wire [4:0] wreg_in,
    input wire regw_in,
    input wire [1:0] mem2reg_in,
    input wire link_in,
    input wire [31:0] pc_plus8_in,
    output reg [31:0] alu_out,
    output reg [31:0] mem_out,
    output reg [4:0] wreg_out,
    output reg regw_out,
    output reg [1:0] mem2reg_out,
    output reg [31:0] wb_wdata_out,
    output reg link_out,
    output reg [31:0] pc_plus8_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_out <= 32'b0;
            mem_out <= 32'b0;
            wreg_out <= 5'b0;
            regw_out <= 1'b0;
            mem2reg_out <= 2'b00;
            wb_wdata_out <= 32'b0;
            link_out <= 1'b0;
            pc_plus8_out <= 32'b0;
        end else begin
            alu_out <= alu_in;
            mem_out <= mem_in;
            // regw_in=0 Ê±ÇåÁã wreg_out
            if (regw_in) begin
                wreg_out <= wreg_in;
            end else begin
                wreg_out <= 5'b0;
            end
            regw_out <= regw_in;
            mem2reg_out <= mem2reg_in;
            link_out <= link_in;
            pc_plus8_out <= pc_plus8_in;
            
            case (mem2reg_in)
                2'b00: wb_wdata_out <= alu_in;
                2'b01: wb_wdata_out <= mem_in;
                2'b10: wb_wdata_out <= alu_in;
                2'b11: wb_wdata_out <= pc_plus8_in;
                default: wb_wdata_out <= alu_in;
            endcase
        end
    end
endmodule