module DecorderTop(
   output wire        dec_funct_vld
  ,output wire        dec_type_vld
  ,output reg         rs1_ren
  ,output reg         rs2_ren
  ,output reg         rd_wen
//,output wire [ 5:0] inst_type
  ,output wire [31:0] imm
  ,output wire [ 6:0] funct7
  ,output wire [ 4:0] rs2   
  ,output wire [ 4:0] rs1   
  ,output wire [ 2:0] funct3
  ,output wire [ 4:0] rd    
  ,output wire [ 6:0] opcode
// R_TYPE
  ,output wire        add_en
  ,output wire        slt_en
  ,output wire        sltu_en
  ,output wire        and_en
  ,output wire        or_en
  ,output wire        xor_en
  ,output wire        sll_en
  ,output wire        srl_en
  ,output wire        sub_en
  ,output wire        sra_en
// I_TYPE 
  ,output wire        addi_en
  ,output wire        slti_en
  ,output wire        sltiu_en
  ,output wire        andi_en
  ,output wire        ori_en
  ,output wire        xori_en
  ,output wire        slli_en
  ,output wire        srli_en
  ,output wire        srai_en
  ,output wire        jalr_en
  ,output wire        load_en
  ,output wire        lb_en
  ,output wire        lh_en
  ,output wire        lw_en
  ,output wire        lbu_en
  ,output wire        lhu_en
  ,output wire        nop_en
// S_TYPE
  ,output wire        sb_en
  ,output wire        sh_en
  ,output wire        sw_en
// B_TYPE
  ,output wire        beq_en
  ,output wire        bne_en
  ,output wire        blt_en
  ,output wire        bltu_en
  ,output wire        bge_en
  ,output wire        bgeu_en
// U_TYPE
  ,output wire        lui_en
  ,output wire        auipc_en
// J_TYPE
  ,output wire        jal_en 
// from Instruction Fetch
  , input reg  [31:0] inst
  , input             dec_en
  , input             CLK
  , input             RSNT
);

wire        is_OP;
wire        is_OP_IMM;
wire        is_LUI;
wire        is_AUIPC;
wire        is_JAL;
wire        is_JALR;
wire        is_BRANCH;
wire        is_LOAD;
wire        is_STORE;
wire        is_MISC_MEM;
wire        is_SYSTEM;
wire [ 2:0] funct3_p;
wire [ 6:0] funct7_p;

TypeDecoder i0_TypeDecoder(
  .dec_type_vld ( dec_type_vld ),
  .rs1_ren      ( rs1_ren      ),
  .rs2_ren      ( rs2_ren      ),
  .rd_wen       ( rd_wen       ),
//.inst_type    ( inst_type    ),
  .imm          ( imm          ),
  .funct7       ( funct7       ),
  .funct7_p     ( funct7_p     ),
  .rs2          ( rs2          ),
  .rs1          ( rs1          ),
  .funct3       ( funct3       ),
  .funct3_p     ( funct3_p     ),
  .rd           ( rd           ),
  .opcode       ( opcode       ),
  .is_OP        ( is_OP        ),
  .is_OP_IMM    ( is_OP_IMM    ),
  .is_LUI       ( is_LUI       ),
  .is_AUIPC     ( is_AUIPC     ),
  .is_JAL       ( is_JAL       ),
  .is_JALR      ( is_JALR      ),
  .is_BRANCH    ( is_BRANCH    ),
  .is_LOAD      ( is_LOAD      ),
  .is_STORE     ( is_STORE     ),
  .is_MISC_MEM  ( is_MISC_MEM  ),
  .is_SYSTEM    ( is_SYSTEM    ),
  .inst         ( inst         ),
  .dec_en       ( dec_en       ),
  .CLK          ( CLK          ),
  .RSTN         ( RSTN         )
);

FunctionDecoeder i1_FunctionDecorder(
  .dec_funct_vld ( dec_funct_vld ),
  .add_en        ( add_en        ),
  .slt_en        ( slt_en        ),
  .sltu_en       ( sltu_en       ),
  .and_en        ( and_en        ),
  .or_en         ( or_en         ),
  .xor_en        ( xor_en        ),
  .sll_en        ( sll_en        ),
  .srl_en        ( srl_en        ),
  .sub_en        ( sub_en        ),
  .sra_en        ( sra_en        ),
  .addi_en       ( addi_en       ),
  .slti_en       ( slti_en       ),
  .sltiu_en      ( sltiu_en      ),
  .andi_en       ( andi_en       ),
  .ori_en        ( ori_en        ),
  .xori_en       ( xori_en       ),
  .slli_en       ( slli_en       ),
  .srli_en       ( srli_en       ),
  .srai_en       ( srai_en       ),
  .jalr_en       ( jalr_en       ),
  .load_en       ( load_en       ),
  .lb_en         ( lb_en         ),
  .lh_en         ( lh_en         ),
  .lw_en         ( lw_en         ),
  .lbu_en        ( lbu_en        ),
  .lhu_en        ( lhu_en        ),
  .nop_en        ( nop_en        ),
  .sb_en         ( sb_en         ),
  .sh_en         ( sh_en         ),
  .sw_en         ( sw_en         ),
  .beq_en        ( beq_en        ),
  .bne_en        ( bne_en        ),
  .blt_en        ( blt_en        ),
  .bltu_en       ( bltu_en       ),
  .bge_en        ( bge_en        ),
  .bgeu_en       ( bgeu_en       ),
  .lui_en        ( lui_en        ),
  .auipc_en      ( auipc_en      ),
  .jal_en        ( jal_en        ),
  .funct3        ( funct3_p      ),
  .funct7        ( funct7_p      ),
  .is_OP         ( is_OP         ),
  .is_OP_IMM     ( is_OP_IMM     ),
  .is_LUI        ( is_LUI        ),
  .is_AUIPC      ( is_AUIPC      ),
  .is_JAL        ( is_JAL        ),
  .is_JALR       ( is_JALR       ),
  .is_BRANCH     ( is_BRANCH     ),
  .is_LOAD       ( is_LOAD       ),
  .is_STORE      ( is_STORE      ),
  .is_MISC_MEM   ( is_MISC_MEM   ),
  .is_SYSTEM     ( is_SYSTEM     ),
  .dec_en        ( dec_en        ),
  .CLK           ( CLK           ),
  .RSNT          ( RSNT          )
);

endmodule