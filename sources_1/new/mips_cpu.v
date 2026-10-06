`timescale 1ns / 1ps

module mips_cpu (
    input wire clk,
    input wire reset,
    output wire [31:0] inst_addr,
    input wire [31:0] inst_data,
    output wire inst_en,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire [31:0] data_rdata,
    output wire data_wen,
    output wire data_ren,
    output wire [3:0] data_be,
    input wire mem_busy
);

    //IF
    reg [31:0] pc;
    wire [31:0] pc_plus4;
    wire stall;
    wire flush_ifid;

    reg redirect_pending;
    reg [31:0] redirect_pending_target;
    wire branch_taken;
    wire jr_target;
    wire [31:0] jump_target;
    wire [31:0] branch_target;
    wire [31:0] jr_addr;
    wire redirect_req;
    wire [31:0] redirect_target_comb;

    //  ID 
    wire [31:0] id_pc, id_inst;
    wire [5:0] id_op;
    wire [4:0] id_rs, id_rt, id_rd;
    wire [15:0] id_imm;
    wire [31:0] id_imm_ext;
    wire [4:0] id_wreg;
    wire id_regw, id_memr, id_memw;
    wire [1:0] id_mem2reg, id_aluop;
    wire id_alusrc, id_branch, id_jump;
    wire id_regdst, id_link, id_sign_ext;
    wire [31:0] id_rdata1, id_rdata2;
    reg [31:0] id_rdata1_final, id_rdata2_final;

    //  EX 
    wire [31:0] ex_pc, ex_rdata1, ex_rdata2, ex_imm;
    wire [4:0] ex_rs, ex_rt, ex_rd, ex_wreg;
    wire [5:0] ex_op, ex_func;
    wire ex_regw, ex_memr, ex_memw;
    wire [1:0] ex_mem2reg, ex_aluop;
    wire ex_alusrc, ex_branch, ex_jump;
    wire ex_regdst, ex_link, ex_sign_ext;
    wire [31:0] ex_pc_plus8;
    wire [4:0] aluc;
    wire [31:0] alu_result;
    wire alu_zero;
    wire [31:0] alu_a_input, alu_b_input;

    // MEM 
    wire [31:0] mem_alu, mem_rdata2;
    wire [4:0] mem_wreg;
    wire mem_regw, mem_memr, mem_memw;
    wire [1:0] mem_mem2reg;
    wire mem_link;
    wire [31:0] mem_pc_plus8;
    wire [5:0] mem_op;

    //  WB 
    wire [31:0] wb_alu, wb_mem;
    wire [4:0] wb_wreg;
    wire wb_regw;
    wire [1:0] wb_mem2reg;
    wire [31:0] wb_wdata;
    wire wb_link;
    wire [31:0] wb_pc_plus8;
    reg [31:0] forward_a, forward_b;
    reg [1:0] forward_a_sel, forward_b_sel;

   
    // load-use
    wire load_use_hazard;
    assign load_use_hazard =
        ex_memr && ex_regw && (ex_wreg != 5'b0) &&
        ((ex_wreg == id_rs && id_rs != 5'b0) ||
         (ex_wreg == id_rt && id_rt != 5'b0)) &&
        (id_inst != 32'b0);

    assign stall = load_use_hazard || mem_busy;
    wire [31:0] imm_extended;
    assign imm_extended = ex_sign_ext ? {{16{ex_imm[15]}}, ex_imm[15:0]}
                                      : {16'b0, ex_imm[15:0]};

    assign jump_target = {ex_pc[31:28], ex_imm[25:0], 2'b00};
    assign branch_target = ex_pc + 4 + (imm_extended << 2);

    wire bgtz_cond;
    assign bgtz_cond = (ex_op == 6'b000111) && ($signed(forward_a) > 32'sd0);

    assign branch_taken = ex_branch &&
        ((ex_op == 6'b000100 && alu_zero) ||   // BEQ
         (ex_op == 6'b000101 && !alu_zero) ||  // BNE
         bgtz_cond);                           // BGTZ

    assign jr_target = (ex_op == 6'b000000) && (ex_func == 6'b001000);
    assign jr_addr = forward_a;

    assign redirect_req = branch_taken || jr_target || ex_jump;
    assign redirect_target_comb = branch_taken ? branch_target :
                                  (jr_target  ? jr_addr : jump_target);


    assign pc_plus4 = pc + 4;
    assign inst_en = ~stall;
    assign inst_addr = pc;

    assign flush_ifid = !stall && (redirect_req || redirect_pending);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h80000000;
            redirect_pending <= 1'b0;
            redirect_pending_target <= 32'b0;
        end else if (stall) begin

            if (redirect_req) begin
                redirect_pending <= 1'b1;
                redirect_pending_target <= redirect_target_comb;
            end
        end else if (redirect_pending) begin

            pc <= redirect_pending_target;
            redirect_pending <= 1'b0;
        end else if (redirect_req) begin

            pc <= redirect_target_comb;
        end else begin
            pc <= pc_plus4;
        end
    end


    always @(*) begin
        forward_a_sel = 2'b00;
        if (mem_regw && !mem_memr && (mem_wreg != 5'b0) &&
            (mem_wreg == ex_rs) && (ex_rs != 5'b0)) begin
            forward_a_sel = mem_link ? 2'b11 : 2'b10;  // JAL 
        end else if (wb_regw && (wb_wreg != 5'b0) &&
                     (wb_wreg == ex_rs) && (ex_rs != 5'b0)) begin
            forward_a_sel = 2'b01;   // WB 
        end
    end

    always @(*) begin
        forward_b_sel = 2'b00;
        if (mem_regw && !mem_memr && (mem_wreg != 5'b0) &&
            (mem_wreg == ex_rt) && (ex_rt != 5'b0)) begin
            forward_b_sel = mem_link ? 2'b11 : 2'b10;
        end else if (wb_regw && (wb_wreg != 5'b0) &&
                     (wb_wreg == ex_rt) && (ex_rt != 5'b0)) begin
            forward_b_sel = 2'b01;
        end
    end

    always @(*) begin
        case (forward_a_sel)
            2'b10: forward_a = mem_alu;
            2'b01: forward_a = wb_wdata;
            2'b11: forward_a = mem_pc_plus8;
            default: forward_a = ex_rdata1;
        endcase
    end

    always @(*) begin
        case (forward_b_sel)
            2'b10: forward_b = mem_alu;
            2'b01: forward_b = wb_wdata;
            2'b11: forward_b = mem_pc_plus8;
            default: forward_b = ex_rdata2;
        endcase
    end

    // IF/ID 
    if_id_reg if_id (
        .clk(clk), .reset(reset),
        .stall(stall), .flush(flush_ifid),
        .pc_in(pc), .inst_in(inst_data),
        .pc_out(id_pc), .inst_out(id_inst)
    );

    // ID 
    assign id_op = id_inst[31:26];
    assign id_rs = id_inst[25:21];
    assign id_rt = id_inst[20:16];
    assign id_rd = id_inst[15:11];
    assign id_imm = id_inst[15:0];


    assign id_imm_ext =
        (id_op == 6'b001111) ? {id_imm, 16'b0} :
        (id_op == 6'b000010 || id_op == 6'b000011) ? {6'b0, id_inst[25:0]} :
        ((id_op == 6'b000000) &&
         (id_inst[5:0] == 6'b000000 || id_inst[5:0] == 6'b000010)) ? {27'b0, id_inst[10:6]} :
        (id_op == 6'b001101 || id_op == 6'b001100 || id_op == 6'b001110) ? {16'b0, id_imm} :
        {{16{id_imm[15]}}, id_imm};

    assign id_wreg = (id_op == 6'b000011) ? 5'd31 : (id_regdst ? id_rd : id_rt);

    ctrl_unit ctrl (
        .opcode(id_op),
        .func(id_inst[5:0]),
        .regw(id_regw), .memr(id_memr), .memw(id_memw),
        .mem2reg(id_mem2reg), .aluop(id_aluop),
        .alusrc(id_alusrc), .branch(id_branch), .jump(id_jump),
        .regdst(id_regdst), .link(id_link), .sign_ext(id_sign_ext)
    );

    regfile rf (
        .clk(clk),
        .reset(reset),
        .regw(wb_regw),
        .r1(id_rs),
        .r2(id_rt),
        .wreg(wb_wreg),
        .wdata(wb_wdata),
        .rdata1(id_rdata1),
        .rdata2(id_rdata2)
    );

    always @(*) begin
        id_rdata1_final = id_rdata1;
        id_rdata2_final = id_rdata2;

        if (mem_regw && (mem_wreg != 5'b0) && (mem_wreg == id_rs) && (id_rs != 5'b0)) begin
            id_rdata1_final = mem_memr ? data_rdata : (mem_link ? mem_pc_plus8 : mem_alu);
        end
        if (mem_regw && (mem_wreg != 5'b0) && (mem_wreg == id_rt) && (id_rt != 5'b0)) begin
            id_rdata2_final = mem_memr ? data_rdata : (mem_link ? mem_pc_plus8 : mem_alu);
        end

        if (wb_regw && (wb_wreg != 5'b0) && (wb_wreg == id_rs) && (id_rs != 5'b0)) begin
            id_rdata1_final = wb_wdata;
        end
        if (wb_regw && (wb_wreg != 5'b0) && (wb_wreg == id_rt) && (id_rt != 5'b0)) begin
            id_rdata2_final = wb_wdata;
        end
    end

    //  ID/EX 
    id_ex_reg id_ex (
        .clk(clk), .reset(reset),
        .stall(1'b0), .flush(stall),
        .pc_in(id_pc),
        .rdata1_in(id_rdata1_final),
        .rdata2_in(id_rdata2_final),
        .imm_in(id_imm_ext),
        .rs_in(id_rs), .rt_in(id_rt), .rd_in(id_rd),
        .wreg_in(id_wreg),
        .op_in(id_op), .func_in(id_inst[5:0]),
        .regw_in(id_regw), .memr_in(id_memr), .memw_in(id_memw),
        .mem2reg_in(id_mem2reg), .aluop_in(id_aluop),
        .alusrc_in(id_alusrc), .branch_in(id_branch), .jump_in(id_jump),
        .regdst_in(id_regdst), .link_in(id_link), .sign_ext_in(id_sign_ext),
        .pc_out(ex_pc),
        .rdata1_out(ex_rdata1), .rdata2_out(ex_rdata2),
        .imm_out(ex_imm),
        .rs_out(ex_rs), .rt_out(ex_rt), .rd_out(ex_rd),
        .wreg_out(ex_wreg),
        .op_out(ex_op), .func_out(ex_func),
        .regw_out(ex_regw), .memr_out(ex_memr), .memw_out(ex_memw),
        .mem2reg_out(ex_mem2reg), .aluop_out(ex_aluop),
        .alusrc_out(ex_alusrc), .branch_out(ex_branch), .jump_out(ex_jump),
        .regdst_out(ex_regdst), .link_out(ex_link), .sign_ext_out(ex_sign_ext)
    );

    // EX 
    assign ex_pc_plus8 = ex_pc + 8;

    alu_ctrl aluctrl (
        .aluop(ex_aluop),
        .func(ex_func),
        .opcode(ex_op),
        .aluc(aluc)
    );

    wire is_shift = (ex_op == 6'b000000) &&
                    ((ex_func == 6'b000000) || (ex_func == 6'b000010));
    assign alu_a_input = is_shift ? {27'b0, ex_imm[4:0]} : forward_a;
    assign alu_b_input = is_shift ? forward_b : (ex_alusrc ? ex_imm : forward_b);

    alu alu_inst (
        .a(alu_a_input),
        .b(alu_b_input),
        .aluc(aluc),
        .result(alu_result),
        .zero(alu_zero)
    );

    // EX/MEM 
    ex_mem_reg ex_mem (
        .clk(clk), .reset(reset), .stall(1'b0),
        .alu_out_in(alu_result),
        .rdata2_in(forward_b),
        .wreg_in(ex_wreg),
        .regw_in(ex_regw), .memr_in(ex_memr), .memw_in(ex_memw),
        .mem2reg_in(ex_mem2reg),
        .link_in(ex_link),
        .pc_plus8_in(ex_pc_plus8),
        .op_in(ex_op),
        .alu_out(mem_alu),
        .rdata2_out(mem_rdata2),
        .wreg_out(mem_wreg),
        .regw_out(mem_regw), .memr_out(mem_memr), .memw_out(mem_memw),
        .mem2reg_out(mem_mem2reg),
        .link_out(mem_link),
        .pc_plus8_out(mem_pc_plus8),
        .op_out(mem_op)
    );

    //  MEM 
    wire [1:0] addr_low;
    wire is_lb, is_sb;

    assign addr_low = mem_alu[1:0];
    assign is_lb = (mem_op == 6'b100000);
    assign is_sb = (mem_op == 6'b101000);

    assign data_be = (is_sb || is_lb) ? (4'b0001 << addr_low) : 4'b1111;

    assign data_addr = mem_alu;
    assign data_wdata = mem_rdata2;
    assign data_wen = mem_memw;
    assign data_ren = mem_memr;

    //  MEM/WB 
    mem_wb_reg mem_wb (
        .clk(clk), .reset(reset),
        .alu_in(mem_alu),
        .mem_in(data_rdata),
        .wreg_in(mem_wreg),
        .regw_in(mem_regw),
        .mem2reg_in(mem_mem2reg),
        .link_in(mem_link),
        .pc_plus8_in(mem_pc_plus8),
        .alu_out(wb_alu),
        .mem_out(wb_mem),
        .wreg_out(wb_wreg),
        .regw_out(wb_regw),
        .mem2reg_out(wb_mem2reg),
        .wb_wdata_out(wb_wdata),
        .link_out(wb_link),
        .pc_plus8_out(wb_pc_plus8)
    );

endmodule
