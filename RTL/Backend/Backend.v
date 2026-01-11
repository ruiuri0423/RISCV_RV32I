module Backend #(
   parameter ID_WIDTH        = 4 
  ,parameter ADDR_WIDTH      = 32
  ,parameter LEN_WIDTH       = 8
  ,parameter SIZE_WIDTH      = 4
  ,parameter BURST_WIDTH     = 2
  ,parameter LOCK_WIDTH      = 1
  ,parameter CACHE_WIDTH     = 4
  ,parameter PROT_WIDTH      = 3
  ,parameter QOS_WIDTH       = 4
  ,parameter REGION_WIDTH    = 4
  ,parameter USER_WIDTH      = 32
  ,parameter DATA_WIDTH      = 32
  ,parameter STRB_WIDTH      = 4
  ,parameter RESP_WIDTH      = 2
  //-----------------------
  ,parameter ROB_ENTRY       = 4
  ,parameter ARCH_ENTRY      = 32
  ,parameter ISSUE_Q_WIDTH   = 123
  ,parameter QUERY_PORT      = 2
  ,parameter ISSUER          = 4
  ,parameter LISTENER        = 4
  ,parameter ISSUER_PRIOR    = {2'd0, 2'd1, 2'd2, 2'd3}
  ,parameter ISSUER_ARCH_REG = {1'd0, 1'd0, 1'd0, 1'd1}
  //-----------------------
  ,parameter ARCH_ENTRY_LOG2 = $clog2(ARCH_ENTRY)
  ,parameter ROB_ENTRY_LOG2  = $clog2( ROB_ENTRY)
  ,parameter FUNCTION_TYPES  = $clog2( 4)
  ,parameter OPERATOR_TYPES  = $clog2(10)
  ,parameter OPERAND_TYPES   = $clog2( 4)
)(
  // AW Channel
    input                     m_axi_awready  
  ,output                     m_axi_awvalid  
  ,output [   ADDR_WIDTH-1:0] m_axi_awaddr   
  ,output [   PROT_WIDTH-1:0] m_axi_awprot   
  ,output [     ID_WIDTH-1:0] m_axi_awid    
  ,output [    LEN_WIDTH-1:0] m_axi_awlen   
  ,output [   SIZE_WIDTH-1:0] m_axi_awsize  
  ,output [  BURST_WIDTH-1:0] m_axi_awburst 
  ,output [   LOCK_WIDTH-1:0] m_axi_awlock  
  ,output [  CACHE_WIDTH-1:0] m_axi_awcache 
  ,output [    QOS_WIDTH-1:0] m_axi_awqos   
  ,output [ REGION_WIDTH-1:0] m_axi_awregion
  ,output [   USER_WIDTH-1:0] m_axi_awuser
  // W Channel
  , input                     m_axi_wready
  ,output                     m_axi_wvalid
  ,output [   DATA_WIDTH-1:0] m_axi_wdata
  ,output [   STRB_WIDTH-1:0] m_axi_wstrb
  ,output                     m_axi_wlast
  ,output [   USER_WIDTH-1:0] m_axi_wuser    
  // B Channel
  ,output                     m_axi_bready
  , input                     m_axi_bvalid
  , input [   RESP_WIDTH-1:0] m_axi_bresp
  , input [     ID_WIDTH-1:0] m_axi_bid
  , input [   USER_WIDTH-1:0] m_axi_buser
  // AR Channel
  , input                     m_axi_arready
  ,output                     m_axi_arvalid  
  ,output [   ADDR_WIDTH-1:0] m_axi_araddr
  ,output [   PROT_WIDTH-1:0] m_axi_arprot
  ,output [     ID_WIDTH-1:0] m_axi_arid    
  ,output [    LEN_WIDTH-1:0] m_axi_arlen   
  ,output [   SIZE_WIDTH-1:0] m_axi_arsize  
  ,output [  BURST_WIDTH-1:0] m_axi_arburst 
  ,output [   LOCK_WIDTH-1:0] m_axi_arlock  
  ,output [  CACHE_WIDTH-1:0] m_axi_arcache 
  ,output [    QOS_WIDTH-1:0] m_axi_arqos   
  ,output [ REGION_WIDTH-1:0] m_axi_arregion
  ,output [   USER_WIDTH-1:0] m_axi_aruser   
  // R Channel
  ,output                     m_axi_rready
  , input                     m_axi_rvalid
  , input [   DATA_WIDTH-1:0] m_axi_rdata
  , input [   RESP_WIDTH-1:0] m_axi_rresp
  , input [     ID_WIDTH-1:0] m_axi_rid  
  , input                     m_axi_rlast
  , input [   USER_WIDTH-1:0] m_axi_ruser
  // BPU
  ,output                     bpu_valid  
  ,output                     bpu_flush
  ,output [   ADDR_WIDTH-1:0] bpu_target
  ,output                     bpu_taken
  ,output                     bpu_call
  ,output                     bpu_ret
  ,output [   ADDR_WIDTH-1:0] bpu_pc
  // Issue Queue
  ,output                     issue_q_ren
  , input                     issue_q_rok
  , input [ISSUE_Q_WIDTH-1:0] issue_q_rdata
  //
  , input                     CLK
  , input                     RSTN
);

// Issue Instruction
wire                       isr_valid;
wire [FUNCTION_TYPES -1:0] isr_function;
wire [OPERATOR_TYPES -1:0] isr_operator;
wire [OPERAND_TYPES  -1:0] isr_oprand;
wire [DATA_WIDTH     -1:0] isr_imm;
wire [1              -1:0] isr_taken;
wire [DATA_WIDTH     -1:0] isr_nxt_pc;
wire [DATA_WIDTH     -1:0] isr_cur_pc;
wire [DATA_WIDTH     -1:0] isr_rs1_data;
wire [DATA_WIDTH     -1:0] isr_rs2_data;
wire [ROB_ENTRY_LOG2 -1:0] isr_rs1_alias;
wire [ROB_ENTRY_LOG2 -1:0] isr_rs2_alias;
wire [ROB_ENTRY_LOG2 -1:0] isr_rob_entry;
// Register Alias Table: RS1
wire                       rat_query_request_rs1;
wire [ARCH_ENTRY_LOG2-1:0] rat_query_arch_id_rs1;
wire                       rat_result_busy_rs1;
wire [ROB_ENTRY_LOG2 -1:0] rat_result_alias_rs1;
// Register Alias Table: RS2
wire                       rat_query_request_rs2;
wire [ARCH_ENTRY_LOG2-1:0] rat_query_arch_id_rs2;
wire                       rat_result_busy_rs2;
wire [ROB_ENTRY_LOG2 -1:0] rat_result_alias_rs2;
// Reorder Buffer -> Register Alias Table
wire                       rat_register_remove;
wire                       rat_register_request;
wire [ARCH_ENTRY_LOG2-1:0] rat_register_arch_id;
wire [ ROB_ENTRY_LOG2-1:0] rat_register_alias;
// Reorder Buffer
wire                       rob_request;
wire [ARCH_ENTRY_LOG2-1:0] rob_arch_id;
wire                       rob_grant;
wire [ ROB_ENTRY_LOG2-1:0] rob_alias_id;
// Execution(from CDB) -> Reorder Buffer
wire                       rob_write; 
wire [ ROB_ENTRY_LOG2-1:0] rob_id;
wire [     DATA_WIDTH-1:0] rob_data;
// Common Data Bus: RS1/Fetch
wire                       cdb_lsn_request_rs1_fetch;
wire [ ROB_ENTRY_LOG2-1:0] cdb_lsn_id_rs1_fetch;
wire [     DATA_WIDTH-1:0] cdb_lsn_data_rs1_fetch;
wire                       cdb_lsn_hit_rs1_fetch;
// Common Data Bus: RS2/Fetch
wire                       cdb_lsn_request_rs2_fetch;
wire [ ROB_ENTRY_LOG2-1:0] cdb_lsn_id_rs2_fetch;
wire [     DATA_WIDTH-1:0] cdb_lsn_data_rs2_fetch;
wire                       cdb_lsn_hit_rs2_fetch;
// Common Data Bus: RS1/Issue
wire                       cdb_lsn_request_rs1_issue;
wire [ ROB_ENTRY_LOG2-1:0] cdb_lsn_id_rs1_issue;
wire [     DATA_WIDTH-1:0] cdb_lsn_data_rs1_issue;
wire                       cdb_lsn_hit_rs1_issue;
// Common Data Bus: RS2/Issue
wire                       cdb_lsn_request_rs2_issue;
wire [ ROB_ENTRY_LOG2-1:0] cdb_lsn_id_rs2_issue;
wire [     DATA_WIDTH-1:0] cdb_lsn_data_rs2_issue;
wire                       cdb_lsn_hit_rs2_issue;
// Reorder Buffer -> Arch. Register(to CDB)
wire [ARCH_ENTRY_LOG2-1:0] cdb_isr_arch_id_rob;
wire [ ROB_ENTRY_LOG2-1:0] cdb_isr_id_rob;
wire [     DATA_WIDTH-1:0] cdb_isr_data_rob;           
wire                       cdb_isr_request_rob;
wire                       cdb_isr_grant_rob;
// Arch. Register: RS1
wire [ARCH_ENTRY_LOG2-1:0] arch_reg_rs1;
wire                       arch_reg_ren_rs1;
wire [     DATA_WIDTH-1:0] arch_reg_data_rs1;
// Arch. Register: RS2
wire [ARCH_ENTRY_LOG2-1:0] arch_reg_rs2;
wire                       arch_reg_ren_rs2;
wire [     DATA_WIDTH-1:0] arch_reg_data_rs2;
// Reorder Buffer to Arch. Register
wire                       arch_reg_write;
wire [ARCH_ENTRY_LOG2-1:0] arch_reg_id;
wire [     DATA_WIDTH-1:0] arch_reg_data;
// Function Unit
wire                       alu_wok;
wire                       lsu_wok;
wire                       bpu_wok;
wire                       csr_wok;

InstIssuer #(
  .ROB_ENTRY     ( ROB_ENTRY     ),
  .ARCH_ENTRY    ( ARCH_ENTRY    ),
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ISSUE_Q_WIDTH ( ISSUE_Q_WIDTH )
) i0_inst_issuer (
  // Issue Instruction
  .isr_valid                 ( isr_valid                 ),
  .isr_function              ( isr_function              ),
  .isr_operator              ( isr_operator              ),
  .isr_oprand                ( isr_oprand                ),
  .isr_imm                   ( isr_imm                   ),
  .isr_taken                 ( isr_taken                 ),
  .isr_nxt_pc                ( isr_nxt_pc                ),
  .isr_cur_pc                ( isr_cur_pc                ),
  .isr_rs1_data              ( isr_rs1_data              ),
  .isr_rs2_data              ( isr_rs2_data              ),
  .isr_rs1_alias             ( isr_rs1_alias             ),
  .isr_rs2_alias             ( isr_rs2_alias             ),
  .isr_rob_entry             ( isr_rob_entry             ),
  // Register Alias Table: RS1
  .rat_query_request_rs1     ( rat_query_request_rs1     ),
  .rat_query_arch_id_rs1     ( rat_query_arch_id_rs1     ),
  .rat_result_busy_rs1       ( rat_result_busy_rs1       ),
  .rat_result_alias_rs1      ( rat_result_alias_rs1      ),
  // Register Alias Table: RS2
  .rat_query_request_rs2     ( rat_query_request_rs2     ),
  .rat_query_arch_id_rs2     ( rat_query_arch_id_rs2     ),
  .rat_result_busy_rs2       ( rat_result_busy_rs2       ),
  .rat_result_alias_rs2      ( rat_result_alias_rs2      ),
  // Reorder Buffer         
  .rob_request               ( rob_request               ),
  .rob_arch_id               ( rob_arch_id               ),
  .rob_grant                 ( rob_grant                 ),
  .rob_alias_id              ( rob_alias_id              ),
  // Common Data Bus: RS1/Fetch
  .cdb_lsn_request_rs1_fetch ( cdb_lsn_request_rs1_fetch ),
  .cdb_lsn_id_rs1_fetch      ( cdb_lsn_id_rs1_fetch      ),
  .cdb_lsn_data_rs1_fetch    ( cdb_lsn_data_rs1_fetch    ),
  .cdb_lsn_hit_rs1_fetch     ( cdb_lsn_hit_rs1_fetch     ),
  // Common Data Bus: RS2/Fetch
  .cdb_lsn_request_rs2_fetch ( cdb_lsn_request_rs2_fetch ),
  .cdb_lsn_id_rs2_fetch      ( cdb_lsn_id_rs2_fetch      ),
  .cdb_lsn_data_rs2_fetch    ( cdb_lsn_data_rs2_fetch    ),
  .cdb_lsn_hit_rs2_fetch     ( cdb_lsn_hit_rs2_fetch     ),
  // Common Data Bus: RS1/Issue
  .cdb_lsn_request_rs1_issue ( cdb_lsn_request_rs1_issue ),
  .cdb_lsn_id_rs1_issue      ( cdb_lsn_id_rs1_issue      ),
  .cdb_lsn_data_rs1_issue    ( cdb_lsn_data_rs1_issue    ),
  .cdb_lsn_hit_rs1_issue     ( cdb_lsn_hit_rs1_issue     ),
  // Common Data Bus: RS2/Issue
  .cdb_lsn_request_rs2_issue ( cdb_lsn_request_rs2_issue ),
  .cdb_lsn_id_rs2_issue      ( cdb_lsn_id_rs2_issue      ),
  .cdb_lsn_data_rs2_issue    ( cdb_lsn_data_rs2_issue    ),
  .cdb_lsn_hit_rs2_issue     ( cdb_lsn_hit_rs2_issue     ),
  // Arch. Register: RS1
  .arch_reg_rs1              ( arch_reg_rs1              ),
  .arch_reg_ren_rs1          ( arch_reg_ren_rs1          ),
  .arch_reg_data_rs1         ( arch_reg_data_rs1         ),
  // Arch. Register: RS2
  .arch_reg_rs2              ( arch_reg_rs2              ),
  .arch_reg_ren_rs2          ( arch_reg_ren_rs2          ),
  .arch_reg_data_rs2         ( arch_reg_data_rs2         ),
  // Issue Queue
  .issue_q_ren               ( issue_q_ren               ),
  .issue_q_rok               ( issue_q_rok               ),
  .issue_q_rdata             ( issue_q_rdata             ),
  // Function Unit
  .alu_wok                   ( alu_wok                   ),
  .lsu_wok                   ( lsu_wok                   ),
  .bpu_wok                   ( bpu_wok                   ),
  .csr_wok                   ( csr_wok                   ),
  //
  .CLK                       ( CLK                       ),
  .RSTN                      ( RSTN                      )
);

ReorderBuffer #(
  .ROB_ENTRY  ( ROB_ENTRY  ),
  .ARCH_ENTRY ( ARCH_ENTRY ),
  .DATA_WIDTH ( DATA_WIDTH ) 
) i1_reorder_buffer ( 
  // Reorder Buffer -> Arch. Register(to CDB)
  .cdb_isr_arch_id      ( cdb_isr_arch_id_rob  ),  
  .cdb_isr_id           ( cdb_isr_id_rob       ),
  .cdb_isr_data         ( cdb_isr_data_rob     ),      
  .cdb_isr_request      ( cdb_isr_request_rob  ),
  .cdb_isr_grant        ( cdb_isr_grant_rob    ),
  // Reorder Buffer -> Register Alias Table
  .rat_register_remove  ( rat_register_remove  ),
  .rat_register_request ( rat_register_request ),
  .rat_register_arch_id ( rat_register_arch_id ),
  .rat_register_alias   ( rat_register_alias   ),
  // Reorder Buffer <-> Issuer
  .rob_grant            ( rob_grant            ),
  .rob_alias_id         ( rob_alias_id         ),
  .rob_request          ( rob_request          ),
  .rob_arch_id          ( rob_arch_id          ),
  // Execution(from CDB) -> Reorder Buffer
  .rob_write            ( rob_write            ),
  .rob_id               ( rob_id               ),
  .rob_data             ( rob_data             ),
  //
  .CLK                  ( CLK                  ),
  .RSTN                 ( RSTN                 )
);

RegisterAliasTable #(
  .QUERY_PORT ( QUERY_PORT ),
  .ARCH_ENTRY ( ARCH_ENTRY ),
  .ROB_ENTRY  ( ROB_ENTRY  ) 
) i2_register_alias_table (
  // Query Port
  .rat_result_busy      ({
    rat_result_busy_rs1,
    rat_result_busy_rs2
  }),
  .rat_result_alias     ({
    rat_result_alias_rs1,
    rat_result_alias_rs2
  }),
  .rat_query_request    ({
    rat_query_request_rs1,
    rat_query_request_rs2
  }),
  .rat_query_arch_id    ({
    rat_query_arch_id_rs1,
    rat_query_arch_id_rs2
  }),
  // Register Port
  .rat_register_remove  ( rat_register_remove  ),
  .rat_register_request ( rat_register_request ),
  .rat_register_arch_id ( rat_register_arch_id ),
  .rat_register_alias   ( rat_register_alias   ),
  //
  .CLK                  ( CLK                  ),
  .RSTN                 ( RSTN                 ) 
);

CommonDataBus #(
  .ISSUER          ( ISSUER          ),
  .LISTENER        ( LISTENER        ),
  .ROB_ENTRY       ( ROB_ENTRY       ),
  .ARCH_ENTRY      ( ARCH_ENTRY      ),
  .DATA_WIDTH      ( DATA_WIDTH      ),
  .ISSUER_PRIOR    ( ISSUER_PRIOR    ),
  .ISSUER_ARCH_REG ( ISSUER_ARCH_REG ) 
) i3_common_data_bus (
  // Excution to Reorder Bufffer
  .rob_write       ( rob_write       ),
  .rob_id          ( rob_id          ),
  .rob_data        ( rob_data        ),
  // Reorder Buffer to Arch. Register
  .arch_reg_write  ( arch_reg_write  ),
  .arch_reg_id     ( arch_reg_id     ),
  .arch_reg_data   ( arch_reg_data   ),
  // Issuer
  .cdb_isr_grant   ({
    cdb_isr_grant_rob
  }),
  .cdb_isr_request ({
    1'b0,
    1'b0,
    1'b0,
    cdb_isr_request_rob
  }),
  .cdb_isr_data    ({
    {DATA_WIDTH{1'b0}},
    {DATA_WIDTH{1'b0}},
    {DATA_WIDTH{1'b0}},
    cdb_isr_data_rob
  }),
  .cdb_isr_id      ({
    {ROB_ENTRY_LOG2{1'b0}},
    {ROB_ENTRY_LOG2{1'b0}},
    {ROB_ENTRY_LOG2{1'b0}},
    cdb_isr_id_rob
  }),
  .cdb_isr_arch_id ({
    {ARCH_ENTRY_LOG2{1'b0}},
    {ARCH_ENTRY_LOG2{1'b0}},
    {ARCH_ENTRY_LOG2{1'b0}},
    cdb_isr_arch_id_rob
  }),
  // Listener
  .cdb_lsn_hit     ({
    cdb_lsn_hit_rs1_fetch,
    cdb_lsn_hit_rs2_fetch,
    cdb_lsn_hit_rs1_issue,
    cdb_lsn_hit_rs2_issue
  }),
  .cdb_lsn_data    ({
    cdb_lsn_data_rs1_fetch,
    cdb_lsn_data_rs2_fetch,
    cdb_lsn_data_rs1_issue,
    cdb_lsn_data_rs2_issue
  }),
  .cdb_lsn_request ({
    cdb_lsn_request_rs1_fetch,
    cdb_lsn_request_rs2_fetch,
    cdb_lsn_request_rs1_issue,
    cdb_lsn_request_rs2_issue
  }),
  .cdb_lsn_id      ({
    cdb_lsn_id_rs1_fetch,
    cdb_lsn_id_rs2_fetch,
    cdb_lsn_id_rs1_issue,
    cdb_lsn_id_rs2_issue 
  }),
  //
  .CLK             ( CLK             ),
  .RSTN            ( RSTN            ) 
);

endmodule