`timescale 1ns / 1ps
// Ö§³ÖLB/SB
module byte_enable_gen (
    input wire [31:0] addr,
    input wire [1:0] size,  // 0=byte, 1=half, 2=word
    input wire wen,         // 1=write, 0=read
    output reg [3:0] be
);
    always @(*) begin
        case (size)
            2'b00: begin  // Byte
                case (addr[1:0])
                    2'b00: be = 4'b0001;
                    2'b01: be = 4'b0010;
                    2'b10: be = 4'b0100;
                    2'b11: be = 4'b1000;
                endcase
            end
            2'b01: begin  // Half-word
                if (addr[1] == 0)
                    be = 4'b0011;
                else
                    be = 4'b1100;
            end
            2'b10: begin  // Word
                be = 4'b1111;
            end
            default: be = 4'b0000;
        endcase
    end
endmodule