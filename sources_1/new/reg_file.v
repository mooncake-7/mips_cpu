`timescale 1ns / 1ps

module regfile (
    input wire clk,
    input wire reset,
    input wire regw,
    input wire [4:0] r1,
    input wire [4:0] r2,
    input wire [4:0] wreg,
    input wire [31:0] wdata,
    output reg [31:0] rdata1,
    output reg [31:0] rdata2
);
    reg [31:0] regs [0:31];
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (regw && (wreg != 5'b0)) begin
            regs[wreg] <= wdata;
        end
    end
    
    always @(*) begin
        // ¶ÁºóĞ´×ª·¢
        if (regw && (wreg != 5'b0) && (wreg == r1) && (r1 != 5'b0)) begin
            rdata1 = wdata;
        end else begin
            rdata1 = (r1 == 5'b0) ? 32'b0 : regs[r1];
        end
        
        if (regw && (wreg != 5'b0) && (wreg == r2) && (r2 != 5'b0)) begin
            rdata2 = wdata;
        end else begin
            rdata2 = (r2 == 5'b0) ? 32'b0 : regs[r2];
        end
    end
endmodule