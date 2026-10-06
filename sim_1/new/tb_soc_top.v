`timescale 1ns / 1ps
// ============================================================================
// soc_top 测试平台 - BaseRAM/ExtRAM/UART 完整测试
// 修复版 - 修复内存地址映射和调试输出
// ============================================================================
module soc_top_tb;

    // ---------------- 时钟和复位 ----------------
    reg clk = 1'b0;
    reg reset = 1'b1;
    always #10 clk = ~clk;          // 50MHz

    // ---------------- 连接 soc_top ----------------
    wire [19:0] bram_addr;
    wire [31:0] bram_data;
    wire bram_ce_n, bram_oe_n, bram_we_n;
    wire [3:0] bram_be_n;

    wire [19:0] eram_addr;
    wire [31:0] eram_data;
    wire eram_ce_n, eram_oe_n, eram_we_n;
    wire [3:0] eram_be_n;

    wire uart_tx;
    reg uart_rx = 1'b1;

    soc_top dut (
        .clk(clk),
        .reset(reset),
        .bram_addr(bram_addr),
        .bram_data(bram_data),
        .bram_ce_n(bram_ce_n),
        .bram_oe_n(bram_oe_n),
        .bram_we_n(bram_we_n),
        .bram_be_n(bram_be_n),
        .eram_addr(eram_addr),
        .eram_data(eram_data),
        .eram_ce_n(eram_ce_n),
        .eram_oe_n(eram_oe_n),
        .eram_we_n(eram_we_n),
        .eram_be_n(eram_be_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // ==================== BaseRAM 模型 ====================
    reg [31:0] bram_mem [0:1048575];
    integer bram_idx;

    // BaseRAM 读操作
    assign bram_data = (!bram_ce_n && !bram_oe_n && bram_we_n) ? bram_mem[bram_addr] : 32'bz;

    // BaseRAM 写操作
    always @(posedge clk) begin
        if (!bram_ce_n && !bram_we_n) begin
            if (!bram_be_n[0]) bram_mem[bram_addr][7:0]   <= bram_data[7:0];
            if (!bram_be_n[1]) bram_mem[bram_addr][15:8]  <= bram_data[15:8];
            if (!bram_be_n[2]) bram_mem[bram_addr][23:16] <= bram_data[23:16];
            if (!bram_be_n[3]) bram_mem[bram_addr][31:24] <= bram_data[31:24];
            
            // 调试：打印写操作
            $display("Time=%0t BRAM Write: addr=0x%05h data=0x%08h be=0x%01h", 
                     $time, bram_addr, bram_data, ~bram_be_n);
        end
    end

    // ==================== ExtRAM 模型 ====================
    reg [31:0] eram_mem [0:1048575];
    integer eram_idx;

    // ExtRAM 读操作
    assign eram_data = (!eram_ce_n && !eram_oe_n && eram_we_n) ? eram_mem[eram_addr] : 32'bz;

    // ExtRAM 写操作
    always @(posedge clk) begin
        if (!eram_ce_n && !eram_we_n) begin
            if (!eram_be_n[0]) eram_mem[eram_addr][7:0]   <= eram_data[7:0];
            if (!eram_be_n[1]) eram_mem[eram_addr][15:8]  <= eram_data[15:8];
            if (!eram_be_n[2]) eram_mem[eram_addr][23:16] <= eram_data[23:16];
            if (!eram_be_n[3]) eram_mem[eram_addr][31:24] <= eram_data[31:24];
            
            // 调试：打印写操作
            $display("Time=%0t ERAM Write: addr=0x%05h data=0x%08h be=0x%01h", 
                     $time, eram_addr, eram_data, ~eram_be_n);
        end
    end

    // ==================== UART 发送任务 ====================
    // 9600 baud @ 50MHz: 5200 个时钟周期
    task uart_send_byte(input [7:0] byte);
        integer j;
        begin
            uart_rx = 1'b1;
            #104000;  // 5200 * 20ns = 104us
            uart_rx = 1'b0;                       // 起始位
            #104000;
            for (j = 0; j < 8; j = j + 1) begin
                uart_rx = byte[j];                // LSB 优先
                #104000;
            end
            uart_rx = 1'b1;                       // 停止位
            #104000;
            $display("Time=%0t UART Send: 0x%02h '%c'", $time, byte, byte);
        end
    endtask

    // ==================== UART 接收监视 ====================
    reg [7:0] tx_byte;
    reg tx_done = 1'b0;
    reg tx_err = 1'b0;
    reg uart_rxing = 1'b0;

    always @(posedge clk) begin
        if (!tx_done && !uart_rxing && uart_tx == 1'b0) begin
            // 检测到起始位
            uart_rxing = 1'b1;
            // 等待 1.5 个位周期
            repeat (7800) @(posedge clk);
            tx_byte[0] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[1] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[2] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[3] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[4] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[5] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[6] = uart_tx;
            repeat (5200) @(posedge clk); tx_byte[7] = uart_tx;
            repeat (5200) @(posedge clk);
            if (uart_tx !== 1'b1) tx_err = 1'b1;
            tx_done = 1'b1;
            uart_rxing = 1'b0;
            $display("Time=%0t UART Recv: 0x%02h '%c'", $time, tx_byte, tx_byte);
        end
    end

    // ==================== 初始化内存 ====================
    task init_mem();
        integer k;
        begin
            // 初始化所有内存为0
            for (k = 0; k < 1048576; k = k + 1) begin
                bram_mem[k] = 32'h00000000;
                eram_mem[k] = 32'h00000000;
            end
            
            $display("Memory initialized");
            
            // ===== 主程序 @ BaseRAM 偏移 0 (CPU看到 0x80000000) =====
            // 注意：bram_mem的索引就是地址（word地址）
            bram_mem[0]  = 32'h0C040000;   // jal 0x80100000
            bram_mem[1]  = 32'h00000000;   // nop (延迟槽)
            bram_mem[2]  = 32'h3C0A8040;   // lui $t2, 0x8040
            bram_mem[3]  = 32'hAD420000;   // sw $v0, 0($t2)
            bram_mem[4]  = 32'hAD480004;   // sw $t0, 4($t2)
            bram_mem[5]  = 32'hAD490008;   // sw $t1, 8($t2)
            bram_mem[6]  = 32'h3C0ABFD0;   // lui $t2, 0xbfd0
            bram_mem[7]  = 32'h340B0042;   // ori $t3, $0, 'B'
            bram_mem[8]  = 32'h8D4C03FC;   // lw $t4, 0x3fc($t2)
            bram_mem[9]  = 32'h318D0001;   // andi $t5, $t4, 1
            bram_mem[10] = 32'h11A0FFFD;   // beq $t5, $0, -3
            bram_mem[11] = 32'h00000000;   // nop
            bram_mem[12] = 32'hAD4B03F8;   // sw $t3, 0x3f8($t2)
            bram_mem[13] = 32'h00000000;   // nop
            bram_mem[14] = 32'h8D4C03FC;   // lw $t4, 0x3fc($t2)
            bram_mem[15] = 32'h318D0002;   // andi $t5, $t4, 2
            bram_mem[16] = 32'h11A0FFFD;   // beq $t5, $0, -3
            bram_mem[17] = 32'h00000000;   // nop
            bram_mem[18] = 32'h8D4E03F8;   // lw $t6, 0x3f8($t2)
            bram_mem[19] = 32'h00000000;   // nop
            bram_mem[20] = 32'h3C0F8040;   // lui $t7, 0x8040
            bram_mem[21] = 32'hADEE000C;   // sw $t6, 12($t7)
            bram_mem[22] = 32'h0800005C;   // j 0x80000170 (无限循环)
            bram_mem[23] = 32'h00000000;   // nop

            // ===== 子程序 @ BaseRAM 偏移 0x100000 =====
            // CPU看到 0x80100000，对应地址 0x100000/4 = 0x40000
            bram_mem[32'h40000] = 32'h34020005;  // ori $v0, $0, 5
            bram_mem[32'h40001] = 32'h01084026;  // xor $t0, $t0, $t0
            bram_mem[32'h40002] = 32'h01294826;  // xor $t1, $t1, $t1
            bram_mem[32'h40003] = 32'h01284821;  // loop: addu $t1, $t1, $t0
            bram_mem[32'h40004] = 32'h25080001;  // addiu $t0, $t0, 1
            bram_mem[32'h40005] = 32'h1448FFFD;  // bne $v0, $t0, loop
            bram_mem[32'h40006] = 32'h00000000;  // nop (延迟槽)
            bram_mem[32'h40007] = 32'h03E00008;  // jr $ra
            bram_mem[32'h40008] = 32'h00000000;  // nop (延迟槽)
            
            $display("Program loaded at 0x80000000 and 0x80100000");
        end
    endtask

    // ==================== PC监视器 ====================
    reg [31:0] last_pc = 32'b0;
    integer inst_count = 0;
    
    always @(posedge clk) begin
        if (!reset && dut.cpu.pc !== last_pc && dut.cpu.pc !== 32'b0) begin
            last_pc = dut.cpu.pc;
            inst_count = inst_count + 1;
            if (inst_count % 100 == 0) begin
                $display("Time=%0t PC=0x%08h Inst=0x%08h", 
                         $time, dut.cpu.pc, dut.cpu.id_inst);
            end
        end
    end

    // ==================== 测试主流程 ====================
    initial begin
        $display("========================================");
        $display("Starting Simulation");
        $display("========================================");
        
        // 初始化内存
        init_mem();
        
        // 释放复位
        reset = 1'b1;
        #200;
        reset = 1'b0;
        $display("Time=%0t Reset Released", $time);
        
        // 等待 CPU 执行并发送 'B'
        #1500000;
        
        // CPU 应该已经在等待接收，发送 'Z'
        uart_send_byte(8'h5A);
        
        // 等待 CPU 处理接收并存入 ExtRAM
        #1500000;
        
        // ===== 验证结果 =====
        $display("========================================");
        $display("Verifying Results");
        $display("========================================");
        
        // 读取 ExtRAM 内容
        $display("ExtRAM[0x80400000] = 0x%08h", eram_mem[0]);
        $display("ExtRAM[0x80400004] = 0x%08h", eram_mem[1]);
        $display("ExtRAM[0x80400008] = 0x%08h", eram_mem[2]);
        $display("ExtRAM[0x8040000C] = 0x%08h", eram_mem[3]);
        
        // 检查结果
        if (eram_mem[0] == 32'h00000005 &&
            eram_mem[1] == 32'h00000005 &&
            eram_mem[2] == 32'h0000000A &&  // 1+2+3+4+5 = 15
            eram_mem[3] == 32'h0000005A &&
            tx_done && !tx_err) begin
            $display("========================================");
            $display("TEST PASSED!");
            $display("  v0 = %0d (expected 5)", eram_mem[0]);
            $display("  t0 = %0d (expected 5)", eram_mem[1]);
            $display("  t1 = %0d (expected 10)", eram_mem[2]);
            $display("  UART RX = 0x%02h (expected 0x5A)", eram_mem[3]);
            $display("  Instructions executed: %0d", inst_count);
            $display("========================================");
        end else begin
            $display("========================================");
            $display("TEST FAILED");
            $display("  ExtRAM[0x80400000] = 0x%08h (expected 0x00000005)", eram_mem[0]);
            $display("  ExtRAM[0x80400004] = 0x%08h (expected 0x00000005)", eram_mem[1]);
            $display("  ExtRAM[0x80400008] = 0x%08h (expected 0x0000000A)", eram_mem[2]);
            $display("  ExtRAM[0x8040000C] = 0x%08h (expected 0x0000005A)", eram_mem[3]);
            $display("  TX Done: %0d, TX Error: %0d", tx_done, tx_err);
            $display("  Instructions executed: %0d", inst_count);
            $display("========================================");
        end
        
        $finish;
    end

    // ==================== 超时保护 ====================
    initial begin
        #100000000;  // 100ms 超时
        $display("========================================");
        $display("TIMEOUT - Simulation stopped after 100ms");
        $display("ExtRAM[0x80400000] = 0x%08h", eram_mem[0]);
        $display("ExtRAM[0x80400004] = 0x%08h", eram_mem[1]);
        $display("ExtRAM[0x80400008] = 0x%08h", eram_mem[2]);
        $display("ExtRAM[0x8040000C] = 0x%08h", eram_mem[3]);
        $display("Instructions executed: %0d", inst_count);
        $display("========================================");
        $finish;
    end

    // ==================== VCD 波形输出 ====================
    initial begin
        $dumpfile("soc_top_tb.vcd");
        $dumpvars(0, soc_top_tb);
    end

endmodule