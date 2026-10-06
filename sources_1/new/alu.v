`timescale 1ns / 1ps

module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [4:0] aluc,
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case (aluc)
            5'b00010: result = a + b;      // ADDU, ADDIU, LW, SW, LB, SB
            5'b00110: result = a - b;      // BEQ, BNE
            5'b00101: result = a | b;      // OR, ORI, BGTZ
            5'b00001: result = b;          // LUI
            5'b00100: result = a & b;      // AND, ANDI
            5'b00111: result = a ^ b;      // XOR, XORI
            5'b01000: result = b << a[4:0]; // SLL (b << shamt)
            5'b01001: result = b >> a[4:0]; // SRL (b >> shamt)
            5'b01010: result = a | b;      // BGTZ 
            5'b01011: result = a + b;      // JAL (PC+8)
            5'b01100: result = a * b;      // MUL 
            default: result = 32'b0;
        endcase
    end
    
    assign zero = (result == 32'b0);
endmodule