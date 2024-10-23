module FunctionDecoeder (
   output reg dec_funct_vld
// R_TYPE
  ,output reg add_en
  ,output reg slt_en
  ,output reg sltu_en
  ,output reg and_en
  ,output reg or_en
  ,output reg xor_en
  ,output reg sll_en
  ,output reg srl_en
  ,output reg sub_en
  ,output reg sra_en
// I_TYPE 
  ,output reg addi_en
  ,output reg slti_en
  ,output reg sltiu_en
  ,output reg andi_en
  ,output reg ori_en
  ,output reg xori_en
  ,output reg slli_en
  ,output reg srli_en
  ,output reg srai_en
  ,output reg jalr_en
  ,output reg load_en
  ,output reg lb_en
  ,output reg lh_en
  ,output reg lw_en
  ,output reg lbu_en
  ,output reg lhu_en
  ,output reg nop_en
// S_TYPE
  ,output reg sb_en
  ,output reg sh_en
  ,output reg sw_en
// B_TYPE
  ,output reg beq_en
  ,output reg bne_en
  ,output reg blt_en
  ,output reg bltu_en
  ,output reg bge_en
  ,output reg bgeu_en
// U_TYPE
  ,output reg lui_en
  ,output reg auipc_en
// J_TYPE
  ,output reg jal_en 
// from TYPE_DECODER
  , input [2:0] funct3
  , input [6:0] funct7
  , input       is_OP    
  , input       is_OP_IMM
  , input       is_LUI
  , input       is_AUIPC
  , input       is_JAL
  , input       is_JALR
  , input       is_BRANCH
  , input       is_LOAD
  , input       is_STORE
  , input       is_MISC_MEM
  , input       is_SYSTEM
  , input       dec_en
  , input       CLK
  , input       RSNT
);

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        add_en  <= 'd0;
        slt_en  <= 'd0;
        sltu_en <= 'd0;
        and_en  <= 'd0;
        or_en   <= 'd0;
        xor_en  <= 'd0;
        sll_en  <= 'd0;
        srl_en  <= 'd0;
        sub_en  <= 'd0;
        sra_en  <= 'd0;
      end
    else
      begin
        add_en  <= dec_en & is_OP & (funct3 == `FUNCT_ADD ) & ~funct7_p[5];
        sub_en  <= dec_en & is_OP & (funct3 == `FUNCT_SUB ) &  funct7_p[5];
        slt_en  <= dec_en & is_OP & (funct3 == `FUNCT_SLT );
        sltu_en <= dec_en & is_OP & (funct3 == `FUNCT_SLTU);
        and_en  <= dec_en & is_OP & (funct3 == `FUNCT_AND );
        or_en   <= dec_en & is_OP & (funct3 == `FUNCT_OR  );
        xor_en  <= dec_en & is_OP & (funct3 == `FUNCT_XOR );
        sll_en  <= dec_en & is_OP & (funct3 == `FUNCT_SLL );
        srl_en  <= dec_en & is_OP & (funct3 == `FUNCT_SRL ) & ~funct7_p[5];
        sra_en  <= dec_en & is_OP & (funct3 == `FUNCT_SRA ) &  funct7_p[5];
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        addi_en  <= 'd0;
        slti_en  <= 'd0;
        sltiu_en <= 'd0;
        andi_en  <= 'd0;
        ori_en   <= 'd0;
        xori_en  <= 'd0;
        slli_en  <= 'd0;
        srli_en  <= 'd0;
        srai_en  <= 'd0;
        jalr_en  <= 'd0;
        load_en  <= 'd0;
        lb_en    <= 'd0;
        lh_en    <= 'd0;
        lw_en    <= 'd0;
        lbu_en   <= 'd0;
        lhu_en   <= 'd0;
        nop_en   <= 'd0;
      end
    else
      begin
        addi_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_ADDI );
        slti_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_SLTI );
        sltiu_en <= dec_en & is_OP_IMM & (funct3 == `FUNCT_SLTIU);
        andi_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_ANDI );
        ori_en   <= dec_en & is_OP_IMM & (funct3 == `FUNCT_ORI  );
        xori_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_XORI );
        slli_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_SLLI );
        srli_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_SRLI ) & ~funct7_p[5];
        srai_en  <= dec_en & is_OP_IMM & (funct3 == `FUNCT_SRAI ) &  funct7_p[5];
        jalr_en  <= dec_en & is_JALR   & (funct3 == `FUNCT_JALR );
        lb_en    <= dec_en & is_LOAD   & (funct3 == `FUNCT_LB   );
        lh_en    <= dec_en & is_LOAD   & (funct3 == `FUNCT_LH   );
        lw_en    <= dec_en & is_LOAD   & (funct3 == `FUNCT_LW   );
        lbu_en   <= dec_en & is_LOAD   & (funct3 == `FUNCT_LBU  );
        lhu_en   <= dec_en & is_LOAD   & (funct3 == `FUNCT_LHU  );
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        sb_en <= 'd0;
        sh_en <= 'd0;
        sw_en <= 'd0;
      end
    else
      begin
        sb_en <= dec_en & is_STORE & (funct3 == `FUNCT_SB);
        sh_en <= dec_en & is_STORE & (funct3 == `FUNCT_SH);
        sw_en <= dec_en & is_STORE & (funct3 == `FUNCT_SW);
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        beq_en   <= 'd0;
        bne_en   <= 'd0;
        blt_en   <= 'd0;
        bltu_en  <= 'd0;
        bge_en   <= 'd0;
        bgeu_en  <= 'd0;
        lui_en   <= 'd0;
        auipc_en <= 'd0;
        jal_en   <= 'd0;
      end
    else
      begin
        beq_en   <= dec_en & is_BRANCH & (funct3 == `FUNCT_BEQ );
        bne_en   <= dec_en & is_BRANCH & (funct3 == `FUNCT_BNE );
        blt_en   <= dec_en & is_BRANCH & (funct3 == `FUNCT_BLT );
        bltu_en  <= dec_en & is_BRANCH & (funct3 == `FUNCT_BLTU);
        bge_en   <= dec_en & is_BRANCH & (funct3 == `FUNCT_BGE );
        bgeu_en  <= dec_en & is_BRANCH & (funct3 == `FUNCT_BGEU);
        lui_en   <= dec_en & is_LUI;
        auipc_en <= dec_en & is_AUIPC;
        jal_en   <= dec_en & is_JAL;
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        lui_en   <= 'd0;
        auipc_en <= 'd0;
      end
    else
      begin
        lui_en   <= dec_en & is_LUI;
        auipc_en <= dec_en & is_AUIPC;
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      jal_en <= 'd0;
    else
      jal_en <= dec_en & is_JAL;
  end

always @(posedge CLK or negedge RSTN) 
  begin
    if (~RSTN)
      dec_funct_vld <= 'd0;
    else
      dec_funct_vld <= dec_en;
  end

endmodule