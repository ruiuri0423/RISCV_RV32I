`include "../Decoder/DefineType.v"

module InstDecoder #(
   parameter DATA_WIDTH     = 32
  ,parameter ADDR_WIDTH     = 32
  ,parameter OPCODE_WIDTH   = 7
  ,parameter FUNCT7_WIDTH   = 7
  ,parameter FUNCT3_WIDTH   = 3
  ,parameter RS1_WIDTH      = 5
  ,parameter RS2_WIDTH      = 5
  ,parameter RD_WIDTH       = 5
  ,parameter FUNCTION_TYPES = $clog2( 4)
  ,parameter OPERATOR_TYPES = $clog2(10)
  ,parameter OPERAND_TYPES  = $clog2( 4)
  ,parameter ISSUE_Q_WIDTH  = 123
)(
  // output
   output wire                      inst_q_ren
  ,output wire                      issue_q_wen
  ,output wire [ ISSUE_Q_WIDTH-1:0] issue_q_wdata
  // input
  , input wire                      inst_q_rok
  , input wire                      inst_q_taken
  , input wire [    ADDR_WIDTH-1:0] inst_q_nxt_pc
  , input wire [    ADDR_WIDTH-1:0] inst_q_cur_pc
  , input wire [    DATA_WIDTH-1:0] inst_q_inst
  , input wire                      issue_q_wok
);

// Parameters (Begin)
// Function Unit (FU)
parameter [FUNCTION_TYPES-1:0] ALU = 'd0;
parameter [FUNCTION_TYPES-1:0] LSU = 'd1;
parameter [FUNCTION_TYPES-1:0] BPU = 'd2;
parameter [FUNCTION_TYPES-1:0] CSR = 'd3;
// Operater
// ALU
parameter [OPERATOR_TYPES-1:0] ADD    = 'd0;
parameter [OPERATOR_TYPES-1:0] SUB    = 'd1;
parameter [OPERATOR_TYPES-1:0] LT     = 'd2;
parameter [OPERATOR_TYPES-1:0] LTU    = 'd3;
parameter [OPERATOR_TYPES-1:0] AND    = 'd4;
parameter [OPERATOR_TYPES-1:0] OR     = 'd5;
parameter [OPERATOR_TYPES-1:0] XOR    = 'd6;
parameter [OPERATOR_TYPES-1:0] SLL    = 'd7;
parameter [OPERATOR_TYPES-1:0] SRL    = 'd8;
parameter [OPERATOR_TYPES-1:0] SRA    = 'd9;
// LSU
parameter [OPERATOR_TYPES-1:0] LOAD   = 'd0;
parameter [OPERATOR_TYPES-1:0] LOADU  = 'd1;
parameter [OPERATOR_TYPES-1:0] STORE  = 'd2;
// BPU
parameter [OPERATOR_TYPES-1:0] BEQ    = 'd0;
parameter [OPERATOR_TYPES-1:0] BNEQ   = 'd1;
parameter [OPERATOR_TYPES-1:0] BLT    = 'd2;
parameter [OPERATOR_TYPES-1:0] BLTU   = 'd3;
parameter [OPERATOR_TYPES-1:0] BGE    = 'd4;
parameter [OPERATOR_TYPES-1:0] BGEU   = 'd5;
parameter [OPERATOR_TYPES-1:0] UCJP   = 'd6; // unconditional jump
// CSR
parameter [OPERATOR_TYPES-1:0] CSRADD = 'd0;
parameter [OPERATOR_TYPES-1:0] CSRSET = 'd1;
parameter [OPERATOR_TYPES-1:0] CSRCLR = 'd2;
// Parameters (End)

wire [OPCODE_WIDTH-1:0] opcode = inst_q_inst[ 0+:OPCODE_WIDTH];
wire [FUNCT7_WIDTH-1:0] funct7 = inst_q_inst[25+:FUNCT7_WIDTH];
wire [FUNCT3_WIDTH-1:0] funct3 = inst_q_inst[12+:FUNCT3_WIDTH];

wire is_OP       = opcode == `INST_OP      ;    
wire is_OP_IMM   = opcode == `INST_OP_IMM  ;
wire is_LUI      = opcode == `INST_LUI     ;
wire is_AUIPC    = opcode == `INST_AUIPC   ;
wire is_JAL      = opcode == `INST_JAL     ;
wire is_JALR     = opcode == `INST_JALR    ;
wire is_BRANCH   = opcode == `INST_BRANCH  ;
wire is_LOAD     = opcode == `INST_LOAD    ;
wire is_STORE    = opcode == `INST_STORE   ;
wire is_MISC_MEM = opcode == `INST_MISC_MEM;
wire is_SYSTEM   = opcode == `INST_SYSTEM  ;

wire r_type_inst = is_OP                                    ;
wire i_type_inst = is_OP_IMM | is_JALR | is_LOAD | is_SYSTEM;
wire s_type_inst = is_STORE                                 ;
wire b_type_inst = is_BRANCH                                ;
wire u_type_inst = is_LUI | is_AUIPC                        ;
wire j_type_inst = is_JAL                                   ;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// To ALU                                                           
//////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                    // FU_-RS1-RS2-IMM-PC_-RD_-OP_
wire add_en    = is_OP     & (funct3 == `FUNCT_ADD  ) & ~funct7[5]; // ALU- O - O - X - X - O -ADD
wire sub_en    = is_OP     & (funct3 == `FUNCT_SUB  ) &  funct7[5]; // ALU- O - O - X - X - O -SUB
wire slt_en    = is_OP     & (funct3 == `FUNCT_SLT  );              // ALU- O - O - X - X - O -LT
wire sltu_en   = is_OP     & (funct3 == `FUNCT_SLTU );              // ALU- O - O - X - X - O -LTU
wire and_en    = is_OP     & (funct3 == `FUNCT_AND  );              // ALU- O - O - X - X - O -AND
wire or_en     = is_OP     & (funct3 == `FUNCT_OR   );              // ALU- O - O - X - X - O -OR
wire xor_en    = is_OP     & (funct3 == `FUNCT_XOR  );              // ALU- O - O - X - X - O -XOR
wire sll_en    = is_OP     & (funct3 == `FUNCT_SLL  );              // ALU- O - O - X - X - O -SLL
wire srl_en    = is_OP     & (funct3 == `FUNCT_SRL  ) & ~funct7[5]; // ALU- O - O - X - X - O -SRL
wire sra_en    = is_OP     & (funct3 == `FUNCT_SRA  ) &  funct7[5]; // ALU- O - O - X - X - O -SRA
wire addi_en   = is_OP_IMM & (funct3 == `FUNCT_ADDI );              // ALU- O - X - O - X - O -ADD
wire slti_en   = is_OP_IMM & (funct3 == `FUNCT_SLTI );              // ALU- O - X - O - X - O -LT
wire sltiu_en  = is_OP_IMM & (funct3 == `FUNCT_SLTIU);              // ALU- O - X - O - X - O -LTU
wire andi_en   = is_OP_IMM & (funct3 == `FUNCT_ANDI );              // ALU- O - X - O - X - O -AND
wire ori_en    = is_OP_IMM & (funct3 == `FUNCT_ORI  );              // ALU- O - X - O - X - O -OR
wire xori_en   = is_OP_IMM & (funct3 == `FUNCT_XORI );              // ALU- O - X - O - X - O -XOR
wire slli_en   = is_OP_IMM & (funct3 == `FUNCT_SLLI );              // ALU- O - X - O - X - O -SLL
wire srli_en   = is_OP_IMM & (funct3 == `FUNCT_SRLI ) & ~funct7[5]; // ALU- O - X - O - X - O -SRL
wire srai_en   = is_OP_IMM & (funct3 == `FUNCT_SRAI ) &  funct7[5]; // ALU- O - X - O - X - O -SRA
wire lui_en    = is_LUI;                                            // ALU- X - X - O - X - O -ADD
wire auipc_en  = is_AUIPC;                                          // ALU- X - X - O - O - O -ADD
// To LSU      
wire lb_en     = is_LOAD   & (funct3 == `FUNCT_LB   );              // LSU- O - X - O - X - O -LOAD
wire lh_en     = is_LOAD   & (funct3 == `FUNCT_LH   );              // LSU- O - X - O - X - O -LOAD
wire lw_en     = is_LOAD   & (funct3 == `FUNCT_LW   );              // LSU- O - X - O - X - O -LOAD
wire lbu_en    = is_LOAD   & (funct3 == `FUNCT_LBU  );              // LSU- O - X - O - X - O -LOAD
wire lhu_en    = is_LOAD   & (funct3 == `FUNCT_LHU  );              // LSU- O - X - O - X - O -LOAD
wire sb_en     = is_STORE  & (funct3 == `FUNCT_SB   );              // LSU- O - O - O - X - X -STORE
wire sh_en     = is_STORE  & (funct3 == `FUNCT_SH   );              // LSU- O - O - O - X - X -STORE
wire sw_en     = is_STORE  & (funct3 == `FUNCT_SW   );              // LSU- O - O - O - X - X -STORE
// To BPU      
wire jal_en    = is_JAL;                                            // BPU- X - X - O - O - O -ADD/ADD
wire jalr_en   = is_JALR   & (funct3 == `FUNCT_JALR );              // BPU- O - X - O - X - O -ADD/ADD
wire beq_en    = is_BRANCH & (funct3 == `FUNCT_BEQ  );              // BPU- O - O - O - O - X -ADD/EQ
wire bne_en    = is_BRANCH & (funct3 == `FUNCT_BNE  );              // BPU- O - O - O - O - X -ADD/NEQ
wire blt_en    = is_BRANCH & (funct3 == `FUNCT_BLT  );              // BPU- O - O - O - O - X -ADD/LT
wire bltu_en   = is_BRANCH & (funct3 == `FUNCT_BLTU );              // BPU- O - O - O - O - X -ADD/LTU
wire bge_en    = is_BRANCH & (funct3 == `FUNCT_BGE  );              // BPU- O - O - O - O - X -ADD/GE
wire bgeu_en   = is_BRANCH & (funct3 == `FUNCT_BGEU );              // BPU- O - O - O - O - X -ADD/GEU
// To CSR
wire csrrw_en  = is_SYSTEM & (funct3 == `FUNCT_CSRRW );             // CSR-RS1- X -CSA- X - ? -ADD
wire csrrs_en  = is_SYSTEM & (funct3 == `FUNCT_CSRRS );             // CSR-RS1- X -CSA- X - O -OR
wire csrrc_en  = is_SYSTEM & (funct3 == `FUNCT_CSRRC );             // CSR-RS1- X -CSA- X - O -AND
wire csrrwi_en = is_SYSTEM & (funct3 == `FUNCT_CSRRWI);             // CSR-IMM- X -CSA- X - ? -ADD
wire csrrsi_en = is_SYSTEM & (funct3 == `FUNCT_CSRRSI);             // CSR-IMM- X -CSA- X - O -OR
wire csrrci_en = is_SYSTEM & (funct3 == `FUNCT_CSRRCI);             // CSR-IMM- X -CSA- X - O -AND
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// output 
reg  [FUNCTION_TYPES-1:0] dec_function;
reg  [OPERATOR_TYPES-1:0] dec_operator;
reg  [ OPERAND_TYPES-1:0] dec_oprand;
wire [    DATA_WIDTH-1:0] dec_imm;
wire [     RS1_WIDTH-1:0] dec_rs1;
wire [     RS2_WIDTH-1:0] dec_rs2;
wire [      RD_WIDTH-1:0] dec_rd;
wire                      dec_rd_wen;
wire                      dec_taken;
wire [    ADDR_WIDTH-1:0] dec_nxt_pc;
wire [    ADDR_WIDTH-1:0] dec_cur_pc;

assign inst_q_ren    = issue_q_wok;
assign issue_q_wen   = inst_q_rok & inst_q_ren;
assign issue_q_wdata = {
                          dec_function
                         ,dec_operator
                         ,dec_oprand
                         ,dec_imm
                         ,dec_rs1
                         ,dec_rs2
                         ,dec_rd
                         ,dec_rd_wen
                         ,dec_taken
                         ,dec_nxt_pc
                         ,dec_cur_pc
                       };

always @(*)
  begin
    dec_function = 'd0;
    dec_operator = 'd0;
    dec_oprand   = 'd0;
    case(1'b1)
      add_en    : begin dec_function = ALU; dec_operator = ADD;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -ADD
      sub_en    : begin dec_function = ALU; dec_operator = SUB;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -SUB
      slt_en    : begin dec_function = ALU; dec_operator = LT ;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -LT
      sltu_en   : begin dec_function = ALU; dec_operator = LTU;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -LTU
      and_en    : begin dec_function = ALU; dec_operator = AND;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -AND
      or_en     : begin dec_function = ALU; dec_operator = OR ;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -OR
      xor_en    : begin dec_function = ALU; dec_operator = XOR;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -XOR
      sll_en    : begin dec_function = ALU; dec_operator = SLL;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -SLL
      srl_en    : begin dec_function = ALU; dec_operator = SRL;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -SRL
      sra_en    : begin dec_function = ALU; dec_operator = SRA;    dec_oprand = 4'b1100; end // ALU- O - O - X - X - O -SRA
      addi_en   : begin dec_function = ALU; dec_operator = ADD;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -ADD
      slti_en   : begin dec_function = ALU; dec_operator = LT ;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -LT
      sltiu_en  : begin dec_function = ALU; dec_operator = LTU;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -LTU
      andi_en   : begin dec_function = ALU; dec_operator = AND;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -AND
      ori_en    : begin dec_function = ALU; dec_operator = OR ;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -OR
      xori_en   : begin dec_function = ALU; dec_operator = XOR;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -XOR
      slli_en   : begin dec_function = ALU; dec_operator = SLL;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -SLL
      srli_en   : begin dec_function = ALU; dec_operator = SRL;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -SRL
      srai_en   : begin dec_function = ALU; dec_operator = SRA;    dec_oprand = 4'b1010; end // ALU- O - X - O - X - O -SRA
      lui_en    : begin dec_function = ALU; dec_operator = ADD;    dec_oprand = 4'b0010; end // ALU- X - X - O - X - O -ADD
      auipc_en  : begin dec_function = ALU; dec_operator = ADD;    dec_oprand = 4'b0011; end // ALU- X - X - O - O - O -ADD

      lb_en     : begin dec_function = LSU; dec_operator = LOAD ;  dec_oprand = 4'b1010; end // LSU- O - X - O - X - O -LOAD
      lh_en     : begin dec_function = LSU; dec_operator = LOAD ;  dec_oprand = 4'b1010; end // LSU- O - X - O - X - O -LOAD
      lw_en     : begin dec_function = LSU; dec_operator = LOAD ;  dec_oprand = 4'b1010; end // LSU- O - X - O - X - O -LOAD
      lbu_en    : begin dec_function = LSU; dec_operator = LOADU;  dec_oprand = 4'b1010; end // LSU- O - X - O - X - O -LOAD
      lhu_en    : begin dec_function = LSU; dec_operator = LOADU;  dec_oprand = 4'b1010; end // LSU- O - X - O - X - O -LOAD
      sb_en     : begin dec_function = LSU; dec_operator = STORE;  dec_oprand = 4'b1110; end // LSU- O - O - O - X - X -STORE
      sh_en     : begin dec_function = LSU; dec_operator = STORE;  dec_oprand = 4'b1110; end // LSU- O - O - O - X - X -STORE
      sw_en     : begin dec_function = LSU; dec_operator = STORE;  dec_oprand = 4'b1110; end // LSU- O - O - O - X - X -STORE

      jal_en    : begin dec_function = BPU; dec_operator = UCJP;   dec_oprand = 4'b0011; end // BPU- X - X - O - O - O -ADD/ADD
      jalr_en   : begin dec_function = BPU; dec_operator = UCJP;   dec_oprand = 4'b1010; end // BPU- O - X - O - X - O -ADD/ADD
      beq_en    : begin dec_function = BPU; dec_operator = BEQ ;   dec_oprand = 4'b1111; end // BPU- O - O - O - O - X -ADD/EQ
      bne_en    : begin dec_function = BPU; dec_operator = BNEQ;   dec_oprand = 4'b1111; end // BPU- O - O - O - O - X -ADD/NEQ
      blt_en    : begin dec_function = BPU; dec_operator = BLT ;   dec_oprand = 4'b1111; end // BPU- O - O - O - O - X -ADD/LT
      bltu_en   : begin dec_function = BPU; dec_operator = BLTU;   dec_oprand = 4'b1111; end // BPU- O - O - O - O - X -ADD/LTU
      bge_en    : begin dec_function = BPU; dec_operator = BGE ;   dec_oprand = 4'b1111; end // BPU- O - O - O - O - X -ADD/GE
      bgeu_en   : begin dec_function = BPU; dec_operator = BGEU;   dec_oprand = 4'b1111; end // BPU- O - O - O - O - X -ADD/GEU

      csrrw_en  : begin dec_function = CSR; dec_operator = CSRADD; dec_oprand = 4'b1010; end // CSR-RS1- X -CSA- X - ? -ADD
      csrrs_en  : begin dec_function = CSR; dec_operator = CSRSET; dec_oprand = 4'b1010; end // CSR-RS1- X -CSA- X - O -OR
      csrrc_en  : begin dec_function = CSR; dec_operator = CSRCLR; dec_oprand = 4'b1010; end // CSR-RS1- X -CSA- X - O -AND
      csrrwi_en : begin dec_function = CSR; dec_operator = CSRADD; dec_oprand = 4'b0010; end // CSR-IMM- X -CSA- X - ? -ADD
      csrrsi_en : begin dec_function = CSR; dec_operator = CSRSET; dec_oprand = 4'b0010; end // CSR-IMM- X -CSA- X - O -OR
      csrrci_en : begin dec_function = CSR; dec_operator = CSRCLR; dec_oprand = 4'b0010; end // CSR-IMM- X -CSA- X - O -AND
    endcase
  end

assign dec_imm = i_type_inst ? `I_TYPE_IMM(inst_q_inst) :
                 s_type_inst ? `S_TYPE_IMM(inst_q_inst) :
                 b_type_inst ? `B_TYPE_IMM(inst_q_inst) :
                 u_type_inst ? `U_TYPE_IMM(inst_q_inst) :
                 j_type_inst ? `J_TYPE_IMM(inst_q_inst) : 'd0;

assign dec_rs2 = inst_q_inst[20+:RS2_WIDTH];
assign dec_rs1 = inst_q_inst[15+:RS1_WIDTH];
assign dec_rd  = inst_q_inst[ 7+: RD_WIDTH];

assign dec_rd_wen = (r_type_inst | i_type_inst | u_type_inst | j_type_inst) & |dec_rd ;

assign dec_taken  = inst_q_taken;
assign dec_nxt_pc = inst_q_nxt_pc;
assign dec_cur_pc = inst_q_cur_pc;



endmodule