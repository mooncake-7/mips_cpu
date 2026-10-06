`timescale 1ns / 1ps

module ctrl_unit (
    input wire [5:0] opcode,
    input wire [5:0] func,
    output reg regw,
    output reg memr,
    output reg memw,
    output reg [1:0] mem2reg,
    output reg [1:0] aluop,
    output reg alusrc,
    output reg branch,
    output reg jump,
    output reg regdst,
    output reg link,
    output reg sign_ext
);
    always @(*) begin
        regw = 1'b0;
        memr = 1'b0;
        memw = 1'b0;
        mem2reg = 2'b00;
        aluop = 2'b00;
        alusrc = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        regdst = 1'b0;
        link = 1'b0;
        sign_ext = 1'b1;
        
        case (opcode)
            6'b001101: begin // ORI
                regw = 1'b1;
                aluop = 2'b10;
                alusrc = 1'b1;
                mem2reg = 2'b00;
                sign_ext = 1'b0;
            end
            6'b001100: begin // ANDI
                regw = 1'b1;
                aluop = 2'b10;
                alusrc = 1'b1;
                mem2reg = 2'b00;
                sign_ext = 1'b0;
            end
            6'b001110: begin // XORI
                regw = 1'b1;
                aluop = 2'b10;
                alusrc = 1'b1;
                mem2reg = 2'b00;
                sign_ext = 1'b0;
            end
            6'b001111: begin // LUI
                regw = 1'b1;
                aluop = 2'b10;
                alusrc = 1'b1;
                mem2reg = 2'b10;
            end
            6'b000000: begin // R-type
                case (func)
                    6'b100001, 6'b100101, 6'b100100, 6'b100110: begin
                        regw = 1'b1;
                        aluop = 2'b10;
                        alusrc = 1'b0;
                        mem2reg = 2'b00;
                        regdst = 1'b1;
                    end
                    6'b000000, 6'b000010: begin // SLL, SRL
                        regw = 1'b1;
                        aluop = 2'b10;
                        alusrc = 1'b0;
                        mem2reg = 2'b00;
                        regdst = 1'b1;
                    end
                    6'b011000: begin // MUL 
                        regw = 1'b1;
                        aluop = 2'b10;
                        alusrc = 1'b0;
                        mem2reg = 2'b00;
                        regdst = 1'b1;
                    end
                    6'b001000: begin // JR
                        jump = 1'b1;
                        regw = 1'b0;
                    end
                    default: begin
                        regw = 1'b0;
                    end
                endcase
            end
            6'b000101: begin // BNE
                branch = 1'b1;
                aluop = 2'b01;
                alusrc = 1'b0;
                regw = 1'b0;
                mem2reg = 2'b00;
            end
            6'b000100: begin // BEQ
                branch = 1'b1;
                aluop = 2'b01;
                alusrc = 1'b0;
                regw = 1'b0;
                mem2reg = 2'b00;
            end
            6'b011100: begin 
                case (func)
                    6'b000010: begin // MUL rd, rs, rt
                        regw = 1'b1;
                        aluop = 2'b10;
                        alusrc = 1'b0;
                        mem2reg = 2'b00;
                        regdst = 1'b1;
                    end
                    default: begin
                        regw = 1'b0;
                    end
                endcase
            end
            6'b000111: begin // BGTZ
                branch = 1'b1;
                aluop = 2'b10;  // 使用ALU的OR操作
                alusrc = 1'b0;
                regw = 1'b0;
                mem2reg = 2'b00;
            end
            6'b001001: begin // ADDIU
                regw = 1'b1;
                aluop = 2'b00;
                alusrc = 1'b1;
                mem2reg = 2'b00;
            end
            6'b000010: begin // J
                jump = 1'b1;
                regw = 1'b0;
                mem2reg = 2'b00;
            end
            6'b000011: begin // JAL
                jump = 1'b1;
                regw = 1'b1;
                link = 1'b1;
                mem2reg = 2'b11;
            end
            6'b100011: begin // LW
                regw = 1'b1;
                memr = 1'b1;
                mem2reg = 2'b01;
                aluop = 2'b00;
                alusrc = 1'b1;
            end
            6'b101011: begin // SW
                memw = 1'b1;
                aluop = 2'b00;
                alusrc = 1'b1;
                regw = 1'b0;
                mem2reg = 2'b00;
            end
            6'b100000: begin // LB
                regw = 1'b1;
                memr = 1'b1;
                mem2reg = 2'b01;
                aluop = 2'b00;
                alusrc = 1'b1;
            end
            6'b101000: begin // SB
                memw = 1'b1;
                aluop = 2'b00;
                alusrc = 1'b1;
                regw = 1'b0;
                mem2reg = 2'b00;
            end
            default: begin
                regw = 1'b0;
                memr = 1'b0;
                memw = 1'b0;
                mem2reg = 2'b00;
                aluop = 2'b00;
                alusrc = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                regdst = 1'b0;
                link = 1'b0;
                sign_ext = 1'b1;
            end
        endcase
    end
endmodule