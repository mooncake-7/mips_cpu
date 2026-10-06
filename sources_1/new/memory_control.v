`timescale 1ns / 1ps

module mem_ctrl (
    input wire clk,
    input wire reset,
    input wire [31:0] inst_addr,
    output reg [31:0] inst_data,
    input wire inst_en,
    input wire [31:0] data_addr,
    input wire [31:0] data_wdata,
    output reg [31:0] data_rdata,
    input wire data_wen,
    input wire data_ren,
    input wire [3:0] data_be,

    // 串口
    input wire uart_rx,
    output reg uart_tx,

    // 忙信号
    output wire mem_busy,

    // BaseRAM 接口
    output reg [19:0] bram_addr,
    inout wire [31:0] bram_data,
    output reg bram_we,
    output reg bram_oe,
    output reg [3:0] bram_be,
    output reg bram_ce,

    // ExtRAM 接口
    output reg [19:0] eram_addr,
    inout wire [31:0] eram_data,
    output reg eram_we,
    output reg eram_oe,
    output reg [3:0] eram_be,
    output reg eram_ce
);

    parameter [15:0] UART_DIV16 = 16'd325;
    localparam [15:0] UART_BIT_PERIOD = UART_DIV16 * 16'd16;

    // 地址译码 
    wire inst_in_bram_raw = (inst_addr >= 32'h80000000) && (inst_addr < 32'h80400000);
    wire inst_in_bram = inst_en && inst_in_bram_raw;
    wire data_in_bram = (data_wen || data_ren) &&
                        (data_addr >= 32'h80000000) && (data_addr < 32'h80400000);
    wire data_in_eram = (data_wen || data_ren) &&
                        (data_addr >= 32'h80400000) && (data_addr < 32'h80800000);
    
    // UART地址检测
    wire uart_tx_addr = (data_addr & 32'hFFFFFFFC) == 32'hBFD003F8;
    wire uart_rx_addr = (data_addr & 32'hFFFFFFFC) == 32'hBFD003F8;
    wire uart_status_addr = (data_addr & 32'hFFFFFFFC) == 32'hBFD003FC;

    // 只有当数据访问和指令取指都访问BRAM时，且数据访问有效时，才stall
    wire data_access = data_wen || data_ren;
    assign mem_busy = inst_in_bram_raw && data_in_bram && data_access;

    //  UART 发送 (8N1)
    reg tx_state;
    reg [15:0] tx_cnt;
    reg [3:0] tx_bit;
    reg [7:0] tx_shift;
    reg tx_busy;

    // 检测发送写操作（边沿检测）
    reg tx_write_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_write_prev <= 1'b0;
        end else begin
            tx_write_prev <= data_wen && uart_tx_addr && !tx_busy;
        end
    end
    wire tx_write = data_wen && uart_tx_addr && !tx_busy && !tx_write_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_state <= 1'b0;
            uart_tx <= 1'b1;
            tx_cnt <= 16'b0;
            tx_bit <= 4'b0;
            tx_shift <= 8'b0;
            tx_busy <= 1'b0;
        end else begin
            case (tx_state)
                1'b0: begin
                    uart_tx <= 1'b1;
                    tx_cnt <= 16'b0;
                    tx_bit <= 4'b0;
                    if (tx_write) begin
                        tx_state <= 1'b1;
                        tx_busy <= 1'b1;
                        tx_shift <= data_wdata[7:0];
                        uart_tx <= 1'b0;
                    end
                end
                1'b1: begin
                    if (tx_cnt >= UART_BIT_PERIOD - 1) begin
                        tx_cnt <= 16'b0;
                        if (tx_bit == 4'd9) begin
                            tx_state <= 1'b0;
                            tx_busy <= 1'b0;
                            uart_tx <= 1'b1;
                        end else begin
                            tx_bit <= tx_bit + 1'b1;
                            case (tx_bit)
                                4'd0: uart_tx <= tx_shift[0];
                                4'd1: uart_tx <= tx_shift[1];
                                4'd2: uart_tx <= tx_shift[2];
                                4'd3: uart_tx <= tx_shift[3];
                                4'd4: uart_tx <= tx_shift[4];
                                4'd5: uart_tx <= tx_shift[5];
                                4'd6: uart_tx <= tx_shift[6];
                                4'd7: uart_tx <= tx_shift[7];
                                4'd8: uart_tx <= 1'b1;
                                default: uart_tx <= 1'b1;
                            endcase
                        end
                    end else begin
                        tx_cnt <= tx_cnt + 1'b1;
                    end
                end
            endcase
        end
    end
    //  UART (16x) 

    reg [2:0] rx_state;
    reg [15:0] rx_cnt;
    reg [3:0] rx_bit;
    reg [7:0] rx_shift;
    reg rx_done;
    reg [7:0] rx_data_reg;
    reg rx_ready;

    wire rx_read = data_ren && uart_rx_addr;

    localparam [15:0] RX_HALF_BIT = (UART_DIV16 << 3) - 1;   
    localparam [15:0] RX_FULL_BIT = (UART_DIV16 << 4) - 1;   

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_state <= 3'b000;
            rx_cnt <= 16'b0;
            rx_bit <= 4'b0;
            rx_shift <= 8'b0;
            rx_done <= 1'b0;
            rx_data_reg <= 8'b0;
            rx_ready <= 1'b0;
        end else begin
            rx_done <= 1'b0;
            case (rx_state)
                3'b000: begin
                    rx_cnt <= 16'b0;
                    if (~uart_rx) rx_state <= 3'b001;   
                end
                3'b001: begin
                    if (rx_cnt >= RX_HALF_BIT) begin
                        rx_cnt <= 16'b0;
                        if (~uart_rx) begin
                            rx_state <= 3'b010;
                            rx_bit <= 4'b0;
                        end else begin
                            rx_state <= 3'b000;         
                        end
                    end else begin
                        rx_cnt <= rx_cnt + 1'b1;
                    end
                end
                3'b010: begin                   
                    if (rx_cnt >= RX_FULL_BIT) begin
                        rx_cnt <= 16'b0;
                        rx_shift <= {uart_rx, rx_shift[7:1]};
                        if (rx_bit == 4'd7) begin
                            rx_state <= 3'b011;
                        end else begin
                            rx_bit <= rx_bit + 1'b1;
                        end
                    end else begin
                        rx_cnt <= rx_cnt + 1'b1;
                    end
                end
                3'b011: begin                  
                    if (rx_cnt >= RX_FULL_BIT) begin
                        rx_cnt <= 16'b0;
                        rx_state <= 3'b000;
                        rx_done <= 1'b1;
                        if (uart_rx) begin
                            rx_data_reg <= rx_shift;
                            rx_ready <= 1'b1;
                        end
                    end else begin
                        rx_cnt <= rx_cnt + 1'b1;
                    end
                end
            endcase

            if (rx_read) begin
                rx_ready <= 1'b0;
            end
        end
    end
    reg [31:0] bram_out;
    reg [31:0] eram_out;

    assign bram_data = bram_we ? bram_out : 32'bz;
    assign eram_data = eram_we ? eram_out : 32'bz;

    // 组合逻辑：读写控制 
    always @(*) begin
        bram_ce = 1'b0;  bram_we = 1'b0;  bram_oe = 1'b0;
        bram_be = 4'b0000; bram_addr = 20'b0; bram_out = 32'b0;

        eram_ce = 1'b0;  eram_we = 1'b0;  eram_oe = 1'b0;
        eram_be = 4'b0000; eram_addr = 20'b0; eram_out = 32'b0;

        inst_data = 32'b0;
        data_rdata = 32'b0;

        // 指令取指 (BaseRAM) 
        if (inst_in_bram) begin
            bram_addr = (inst_addr - 32'h80000000) >> 2;
            bram_ce = 1'b1;
            bram_oe = 1'b1;
            bram_be = 4'b1111;
            inst_data = bram_data;
        end

        //数据写操作
        if (data_wen) begin
            if (uart_tx_addr) begin
                // 串口发送，由UART发送器处理
            end else if (data_in_bram) begin
                bram_addr = (data_addr - 32'h80000000) >> 2;
                bram_ce = 1'b1;
                bram_we = 1'b1;
                bram_be = data_be;
                case (data_be)
                    4'b0001: bram_out = {24'b0, data_wdata[7:0]};
                    4'b0010: bram_out = {16'b0, data_wdata[7:0], 8'b0};
                    4'b0100: bram_out = {8'b0, data_wdata[7:0], 16'b0};
                    4'b1000: bram_out = {data_wdata[7:0], 24'b0};
                    default: bram_out = data_wdata;
                endcase
            end else if (data_in_eram) begin
                eram_addr = (data_addr - 32'h80400000) >> 2;
                eram_ce = 1'b1;
                eram_we = 1'b1;
                eram_be = data_be;
                case (data_be)
                    4'b0001: eram_out = {24'b0, data_wdata[7:0]};
                    4'b0010: eram_out = {16'b0, data_wdata[7:0], 8'b0};
                    4'b0100: eram_out = {8'b0, data_wdata[7:0], 16'b0};
                    4'b1000: eram_out = {data_wdata[7:0], 24'b0};
                    default: eram_out = data_wdata;
                endcase
            end
        end

        // 数据读操作 
        if (data_ren) begin
            if (uart_rx_addr) begin
                data_rdata = {24'b0, rx_data_reg};
            end else if (uart_status_addr) begin
                data_rdata = {30'b0, rx_ready, ~tx_busy};
            end else if (data_in_bram) begin
                bram_addr = (data_addr - 32'h80000000) >> 2;
                bram_ce = 1'b1;
                bram_oe = 1'b1;
                bram_be = 4'b1111;
                case (data_be)
                    4'b0001: data_rdata = {{24{bram_data[7]}},  bram_data[7:0]};
                    4'b0010: data_rdata = {{24{bram_data[15]}}, bram_data[15:8]};
                    4'b0100: data_rdata = {{24{bram_data[23]}}, bram_data[23:16]};
                    4'b1000: data_rdata = {{24{bram_data[31]}}, bram_data[31:24]};
                    default: data_rdata = bram_data;
                endcase
            end else if (data_in_eram) begin
                eram_addr = (data_addr - 32'h80400000) >> 2;
                eram_ce = 1'b1;
                eram_oe = 1'b1;
                eram_be = 4'b1111;
                case (data_be)
                    4'b0001: data_rdata = {{24{eram_data[7]}},  eram_data[7:0]};
                    4'b0010: data_rdata = {{24{eram_data[15]}}, eram_data[15:8]};
                    4'b0100: data_rdata = {{24{eram_data[23]}}, eram_data[23:16]};
                    4'b1000: data_rdata = {{24{eram_data[31]}}, eram_data[31:24]};
                    default: data_rdata = eram_data;
                endcase
            end
        end
    end

endmodule