`timescale 1ns / 1ps
 
module alu_ctrl (
    input wire [1:0] aluop,
    input wire [5:0] func,
    input wire [5:0] opcode,
    output reg [4:0] aluc  // 扩展为5位
);
    always @(*) begin
        case (aluop)
            2'b00: aluc = 5'b00010;  // LW, SW, ADDIU: 加法
            2'b01: aluc = 5'b00110;  // BEQ, BNE: 减法
            2'b10: begin
                case (opcode)
                    6'b001101: aluc = 5'b00101;  // ORI: 或
                    6'b001111: aluc = 5'b00001;  // LUI: 直接输出
                    6'b001100: aluc = 5'b00100;  // ANDI: 与
                    6'b001110: aluc = 5'b00111;  // XORI: 异或
                    6'b000000: begin
                        case (func)
                            6'b100001: aluc = 5'b00010;  // ADDU: 加法
                            6'b100101: aluc = 5'b00101;  // OR: 或
                            6'b100100: aluc = 5'b00100;  // AND: 与
                            6'b100110: aluc = 5'b00111;  // XOR: 异或
                            6'b000000: aluc = 5'b01000;  // SLL: 左移
                            6'b000010: aluc = 5'b01001;  // SRL: 右移
                            6'b011000: aluc = 5'b01100;  // MUL
                            6'b001000: aluc = 5'b00110;  // JR: 减法
                            default: aluc = 5'b00010;
                        endcase
                    end
                    6'b011100: begin
                        case (func)
                            6'b000010: aluc = 5'b01100;  // MUL
                            default: aluc = 5'b00010;
                        endcase
                    end
                    6'b000101: aluc = 5'b00110;  // BNE: 减法
                    6'b000100: aluc = 5'b00110;  // BEQ: 减法
                    6'b000111: aluc = 5'b01010;  // BGTZ: 比较
                    6'b000010: aluc = 5'b00010;  // J: 加法
                    6'b000011: aluc = 5'b01011;  // JAL: 加法(PC+8)
                    6'b001001: aluc = 5'b00010;  // ADDIU: 加法
                    6'b100000: aluc = 5'b00010;  // LB: 加法
                    6'b101000: aluc = 5'b00010;  // SB: 加法
                    default: aluc = 5'b00010;
                endcase
            end
            default: aluc = 5'b00000;
        endcase
    end
endmodule