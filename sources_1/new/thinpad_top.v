`timescale 1ns / 1ps

module thinpad_top (
    input wire clk,
    input wire reset,
    
    output wire [19:0] bram_addr,
    inout wire [31:0] bram_data,
    output wire bram_ce_n,
    output wire bram_oe_n,
    output wire bram_we_n,
    output wire [3:0] bram_be_n,
    
    output wire [19:0] eram_addr,
    inout wire [31:0] eram_data,
    output wire eram_ce_n,
    output wire eram_oe_n,
    output wire eram_we_n,
    output wire [3:0] eram_be_n,
    
    // ´®¿Ú
    input wire uart_rx,
    output wire uart_tx
);

    wire [31:0] inst_addr;
    wire [31:0] inst_data;
    wire inst_en;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    wire data_wen;
    wire data_ren;
    wire [3:0] data_be;
    wire mem_busy;
    
    wire [19:0] bram_addr_int;
    wire [31:0] bram_data_int;
    wire bram_we_int;
    wire bram_oe_int;
    wire [3:0] bram_be_int;
    wire bram_ce_int;
    
    wire [19:0] eram_addr_int;
    wire [31:0] eram_data_int;
    wire eram_we_int;
    wire eram_oe_int;
    wire [3:0] eram_be_int;
    wire eram_ce_int;
    
    wire [31:0] eram_data_internal;
    
    mips_cpu cpu (
        .clk(clk), .reset(reset),
        .inst_addr(inst_addr), .inst_data(inst_data), .inst_en(inst_en),
        .data_addr(data_addr), .data_wdata(data_wdata), .data_rdata(data_rdata),
        .data_wen(data_wen), .data_ren(data_ren), .data_be(data_be),
        .mem_busy(mem_busy)
    );
    
    mem_ctrl mem (
        .clk(clk), .reset(reset),
        .inst_addr(inst_addr), .inst_data(inst_data), .inst_en(inst_en),
        .data_addr(data_addr), .data_wdata(data_wdata), .data_rdata(data_rdata),
        .data_wen(data_wen), .data_ren(data_ren), .data_be(data_be),
        .uart_rx(uart_rx), .uart_tx(uart_tx),
        .mem_busy(mem_busy),
        .bram_addr(bram_addr_int), .bram_data(bram_data_int),
        .bram_we(bram_we_int), .bram_oe(bram_oe_int), .bram_be(bram_be_int),
        .bram_ce(bram_ce_int),
        .eram_addr(eram_addr_int), .eram_data(eram_data_internal),
        .eram_we(eram_we_int), .eram_oe(eram_oe_int), .eram_be(eram_be_int),
        .eram_ce(eram_ce_int)
    );
    
    // BaseRAM
    assign bram_addr = bram_addr_int;
    assign bram_ce_n = ~bram_ce_int;
    assign bram_oe_n = ~bram_oe_int;
    assign bram_we_n = ~bram_we_int;
    assign bram_be_n = ~bram_be_int;
    assign bram_data = bram_we_int ? bram_data_int : 32'bz;
    assign bram_data_int = bram_oe_int ? bram_data : 32'bz;
    
    // ExtRAM
    assign eram_addr = eram_addr_int;
    assign eram_ce_n = ~eram_ce_int;
    assign eram_oe_n = ~eram_oe_int;
    assign eram_we_n = ~eram_we_int;
    assign eram_be_n = ~eram_be_int;
    assign eram_data = eram_we_int ? eram_data_internal : 32'bz;
    assign eram_data_internal = eram_oe_int ? eram_data : 32'bz;

endmodule