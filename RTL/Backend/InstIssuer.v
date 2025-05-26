module InstIssuer #(
   parameter ROB_ENTRY      = 4
  ,parameter ARCH_ENTRY     = 32
  ,parameter DATA_WIDTH     = 32
  //-----------------------
  ,parameter ARCH_ENTRY_LOG2 = $clog2(ARCH_ENTRY)
  ,parameter ROB_ENTRY_LOG2  = $clog2( ROB_ENTRY)
  ,parameter FUNCTION_TYPES  = $clog2( 4)
  ,parameter OPERATOR_TYPES  = $clog2(10)
  ,parameter OPERAND_TYPES   = $clog2( 4)
  //-----------------------
  ,parameter FUNCTION_BASE = 0
  ,parameter OPERATOR_BASE = FUNCTION_BASE + FUNCTION_TYPES
  ,parameter OPERAND_BASE  = OPERATOR_BASE + OPERATOR_TYPES
  ,parameter IMM_BASE      = OPERAND_BASE  + OPERAND_TYPES
  ,parameter RS1_BASE      = IMM_BASE      + DATA_WIDTH
  ,parameter RS2_BASE      = RS1_BASE      + ARCH_ENTRY_LOG2
  ,parameter RD_BASE       = RS2_BASE      + ARCH_ENTRY_LOG2
  ,parameter RD_WEN_BASE   = RD_BASE       + ARCH_ENTRY_LOG2
  ,parameter TAKEN_BASE    = RD_WEN_BASE   + 1
  ,parameter NXT_PC_BASE   = TAKEN_BASE    + 1
  ,parameter CUR_PC_BASE   = NXT_PC_BASE   + DATA_WIDTH
)(
  // Issue Instruction
   output                       isr_valid
  ,output [FUNCTION_TYPES -1:0] isr_function
  ,output [OPERATOR_TYPES -1:0] isr_operator
  ,output [OPERAND_TYPES  -1:0] isr_oprand
  ,output [DATA_WIDTH     -1:0] isr_imm
  ,output [1              -1:0] isr_taken
  ,output [DATA_WIDTH     -1:0] isr_nxt_pc
  ,output [DATA_WIDTH     -1:0] isr_cur_pc
  ,output [DATA_WIDTH     -1:0] isr_rs1_data
  ,output [DATA_WIDTH     -1:0] isr_rs2_data
  ,output [ROB_ENTRY_LOG2 -1:0] isr_rs1_depend
  ,output [ROB_ENTRY_LOG2 -1:0] isr_rs2_depend
  ,output [ROB_ENTRY_LOG2 -1:0] isr_rob_entry
  // Register Alias Table: RS1
  ,output                       rat_query_request_rs1
  ,output [ARCH_ENTRY_LOG2-1:0] rat_query_arch_id_rs1
  , input                       rat_result_busy_rs1
  , input [ROB_ENTRY_LOG2 -1:0] rat_result_alias_rs1
  // Register Alias Table: RS2
  ,output                       rat_query_request_rs2
  ,output [ARCH_ENTRY_LOG2-1:0] rat_query_arch_id_rs2
  , input                       rat_result_busy_rs2
  , input [ROB_ENTRY_LOG2 -1:0] rat_result_alias_rs2
  // Reorder Buffer
  ,output                       rob_request
  ,output [ARCH_ENTRY_LOG2-1:0] rob_arch_id
  , input                       rob_grant
  , input [ ROB_ENTRY_LOG2-1:0] rob_alias_id
  // Common Data Bus
  ,output                       cdb_lsn_request
  ,output [ ROB_ENTRY_LOG2-1:0] cdb_lsn_id
  , input [     DATA_WIDTH-1:0] cdb_lsn_data
  , input                       cdb_lsn_hit
  // Issue Queue
  ,output    issue_q_ren
  , input    issue_q_rok
  , input [] issue_q_rdata
  // Function Unit
  , input    alu_wok
  , input    lsu_wok
  , input    bpu_wok
  , input    csr_wok
  //
  , input    CLK
  , input    RSTN
);

// Parameters (Begin)
// Function Unit (FU)
parameter [FUNCTION_TYPES-1:0] ALU = 'd0;
parameter [FUNCTION_TYPES-1:0] LSU = 'd1;
parameter [FUNCTION_TYPES-1:0] BPU = 'd2;
parameter [FUNCTION_TYPES-1:0] CSR = 'd3;
// Parameters (End)

// Dispatch Buffer
wire [FUNCTION_TYPES -1:0] disp_function_nxt;
wire [OPERATOR_TYPES -1:0] disp_operator_nxt;
wire [OPERAND_TYPES  -1:0] disp_oprand_nxt;
wire [DATA_WIDTH     -1:0] disp_imm_nxt;
wire [ARCH_ENTRY_LOG2-1:0] disp_rs1_nxt;
wire [ARCH_ENTRY_LOG2-1:0] disp_rs2_nxt;
wire [ARCH_ENTRY_LOG2-1:0] disp_rd_nxt;
wire [1              -1:0] disp_rd_wen_nxt;
wire [1              -1:0] disp_taken_nxt;
wire [DATA_WIDTH     -1:0] disp_nxt_pc_nxt;
wire [DATA_WIDTH     -1:0] disp_cur_pc_nxt;

reg  [FUNCTION_TYPES -1:0] disp_function;
reg  [OPERATOR_TYPES -1:0] disp_operator;
reg  [OPERAND_TYPES  -1:0] disp_oprand;
reg  [DATA_WIDTH     -1:0] disp_imm;
reg  [ARCH_ENTRY_LOG2-1:0] disp_rs1;
reg  [ARCH_ENTRY_LOG2-1:0] disp_rs2;
reg  [ARCH_ENTRY_LOG2-1:0] disp_rd;
reg  [1              -1:0] disp_rd_wen;
reg  [1              -1:0] disp_taken;
reg  [DATA_WIDTH     -1:0] disp_nxt_pc;
reg  [DATA_WIDTH     -1:0] disp_cur_pc;

wire                       disp_to_alu;
wire                       disp_to_lsu;
wire                       disp_to_bpu;
wire                       disp_to_csr;
wire                       disp_hsk;

wire                       disp_fetch;
wire                       disp_issue;

reg                        disp_rem;
wire                       disp_rok;
wire                       disp_wok;

reg [] disp_rs1_data;   // From register file
reg [] disp_rs2_data;   // From register file
reg [] disp_rs1_depend; // Address by RAT
reg [] disp_rs2_depend; // Address by RAT
reg [] disp_rob_entry;  // Allocated in ROB

wire                       rat_busy_rs1;
wire                       rat_busy_rs2;

wire                       rob_accept;
reg                        rob_request_ext;

// Iussuer Work Flow
// (T + 0)
// 1. Fetch instruction from issue queue.
// 2. Check the RAT if the source register is addressed.
//    -> True : Return the dependency (ROB entry). 
// 3. Fetch source register data from register file.
// 4. Checking the entry is available in ROB.
//    -> True  : Return the allocated entry.
//    -> False : Stall the pipeline.
// (T + 1)
// If the dispatching data is prepared, issuing the 
// instruction to the corresponding function unit.

assign disp_function_nxt = issue_q_rdata[FUNCTION_BASE+:FUNCTION_TYPES ];
assign disp_operator_nxt = issue_q_rdata[OPERATOR_BASE+:OPERATOR_TYPES ];
assign disp_oprand_nxt   = issue_q_rdata[OPERAND_BASE +:OPERAND_TYPES  ];
assign disp_imm_nxt      = issue_q_rdata[IMM_BASE     +:DATA_WIDTH     ];
assign disp_rs1_nxt      = issue_q_rdata[RS1_BASE     +:ARCH_ENTRY_LOG2];
assign disp_rs2_nxt      = issue_q_rdata[RS2_BASE     +:ARCH_ENTRY_LOG2];
assign disp_rd_nxt       = issue_q_rdata[RD_BASE      +:ARCH_ENTRY_LOG2];
assign disp_rd_wen_nxt   = issue_q_rdata[RD_WEN_BASE  +:1              ];
assign disp_taken_nxt    = issue_q_rdata[TAKEN_BASE   +:1              ];
assign disp_nxt_pc_nxt   = issue_q_rdata[NXT_PC_BASE  +:DATA_WIDTH     ];
assign disp_cur_pc_nxt   = issue_q_rdata[CUR_PC_BASE  +:DATA_WIDTH     ];

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        disp_function <= 'd0;
        disp_operator <= 'd0;
        disp_oprand   <= 'd0;
        disp_imm      <= 'd0;
        disp_rs1      <= 'd0;
        disp_rs2      <= 'd0;
        disp_rd       <= 'd0;
        disp_rd_wen   <= 'd0;
        disp_taken    <= 'd0;
        disp_nxt_pc   <= 'd0;
        disp_cur_pc   <= 'd0;
      end
    else if (disp_fetch)
      begin
        disp_function <= disp_function_nxt;
        disp_operator <= disp_operator_nxt;
        disp_oprand   <= disp_oprand_nxt;
        disp_imm      <= disp_imm_nxt;
        disp_rs1      <= disp_rs1_nxt;
        disp_rs2      <= disp_rs2_nxt;
        disp_rd       <= disp_rd_nxt;
        disp_rd_wen   <= disp_rd_wen_nxt;
        disp_taken    <= disp_taken_nxt;
        disp_nxt_pc   <= disp_nxt_pc_nxt;
        disp_cur_pc   <= disp_cur_pc_nxt;
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        disp_rs1_data <= 'd0;    // From register file
        disp_rs2_data <= 'd0;    // From register file
      end
    else if ()
      begin
        disp_rs1_data <= ;    // From register file
        disp_rs2_data <= ;    // From register file
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        disp_rs1_depend <= 'd0;    // Address by RAT
        disp_rs2_depend <= 'd0;    // Address by RAT
      end
    else
      begin
        disp_rs1_depend <= rat_busy_rs1 ? rat_result_alias_rs1 : disp_rs1_depend;    // Address by RAT
        disp_rs2_depend <= rat_busy_rs2 ? rat_result_alias_rs2 : disp_rs2_depend;    // Address by RAT
      end
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        disp_rob_entry <= 'd0;    // Allocated in ROB
      end
    else if (rob_accept)
      begin
        disp_rob_entry <= rob_alias_id;    // Allocated in ROB
      end
  end

//-----------------------------------------------
// Issuer FIFO, depth = 1.
assign disp_to_alu = (disp_function_nxt == ALU) & alu_wok;  
assign disp_to_lsu = (disp_function_nxt == LSU) & lsu_wok;
assign disp_to_bpu = (disp_function_nxt == BPU) & bpu_wok; 
assign disp_to_csr = (disp_function_nxt == CSR) & csr_wok; 

assign disp_hsk = disp_rok & (disp_to_alu | disp_to_lsu | disp_to_bpu | disp_to_csr);

// Operation : Fetch then issue.
// Operation : Fetch then store.
//             -> issue from stored.
assign disp_fetch = issue_q_rok & disp_wok;
assign disp_issue = disp_hsk & disp_rok;

assign disp_wok =  disp_rem | disp_issue; 
assign disp_rok = ~disp_rem & rob_accept;

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      disp_rem <= 'd1;
    else
      disp_rem <= disp_fetch ? 'd0 : disp_issue ? 'd1 : disp_rem;
  end

//===============================================
// Instruction Fetching
//===============================================
assign issue_q_ren = disp_fetch;

//===============================================
// Register Alias Table Checks
//===============================================
assign rat_busy_rs1 = rat_query_request_rs1 & rat_result_busy_rs1;
assign rat_query_request_rs1 = disp_fetch;
assign rat_query_arch_id_rs1 = disp_rs1_nxt;

assign rat_busy_rs2 = rat_query_request_rs2 & rat_result_busy_rs2;
assign rat_query_request_rs2 = disp_fetch;
assign rat_query_arch_id_rs2 = disp_rs2_nxt;

//===============================================
// Reorder Buffer Checks
//===============================================
assign rob_accept  = rob_request & rob_grant;
assign rob_request = rob_request_ext | disp_fetch;
assign rob_arch_id = rob_request_ext ? disp_rd : disp_rd_nxt;

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      rob_request_ext <= 'd0;
    else
      rob_request_ext <= rob_accept ? 'd0 : disp_fetch ? 'd1 : rob_request_ext;
  end

//===============================================
// If hit the RAW, listen the common data bus. 
//===============================================
assign cdb_lsn_request = 
assign cdb_lsn_id      = 

//===============================================
// Instruction Issuing
//===============================================
assign isr_valid = 

endmodule