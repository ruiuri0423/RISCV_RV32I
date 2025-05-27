module Frontend #(
   parameter DATA_WIDTH     = 32
  ,parameter ADDR_WIDTH     = 32
  ,parameter PROT_WIDTH     = 3
  ,parameter RESP_WIDTH     = 4
  ,parameter BHT_DEPTH      = 16
  ,parameter BHT_WIDTH      = 4 
  ,parameter BTB_DEPTH      = 16
  ,parameter BTB_WIDTH      = 4
  ,parameter TAG_WIDTH      = 10
  ,parameter RAS_DEPTH      = 4
  ,parameter RAS_WIDTH      = 2
  ,parameter INST_Q_WIDTH   = 97 // 32 + 32 + 32 + 1
  ,parameter INST_Q_DEPTH   = 2
  ,parameter OPCODE_WIDTH   = 7
  ,parameter FUNCT7_WIDTH   = 7
  ,parameter FUNCT3_WIDTH   = 3
  ,parameter RS1_WIDTH      = 5
  ,parameter RS2_WIDTH      = 5
  ,parameter RD_WIDTH       = 5
  ,parameter FUNCTION_TYPES = $clog2( 4)
  ,parameter OPERATOR_TYPES = $clog2(10)
  ,parameter OPERAND_TYPES  = $clog2( 4)
  ,parameter ISSUE_Q_WIDTH  = 123 // 2 + 2 + 4 + 32 + 5 + 5 + 5 + 1 + 32 + 32 + 1
  ,parameter ISSUE_Q_DEPTH  = 2
)(
  // AR Channel (AXI4-Lite)
    input                     m_axi_arready
  ,output                     m_axi_arvalid  
  ,output [   ADDR_WIDTH-1:0] m_axi_araddr
  ,output [   PROT_WIDTH-1:0] m_axi_arprot
  //  R Channel (AXI4-Lite)
  ,output                     m_axi_rready
  , input                     m_axi_rvalid
  , input [   DATA_WIDTH-1:0] m_axi_rdata
  , input [   RESP_WIDTH-1:0] m_axi_rresp
  // Issue Queue
  ,output                     issue_q_ren
  , input [ISSUE_Q_WIDTH-1:0] issue_q_rdata
  , input                     issue_q_rok
  // BPU
  , input                     bpu_valid  
  , input                     bpu_flush
  , input [   ADDR_WIDTH-1:0] bpu_target
  , input                     bpu_taken
  , input                     bpu_call
  , input                     bpu_ret
  , input [   ADDR_WIDTH-1:0] bpu_pc
  //
  , input [   ADDR_WIDTH-1:0] BOOT_ADDR
  , input                     CLK
  , input                     RSTN
);

// Instruction Queue
wire                     inst_q_wen;
wire [ INST_Q_WIDTH-1:0] inst_q_wdata;
wire                     inst_q_wok;
wire                     inst_q_ren;
wire [ INST_Q_WIDTH-1:0] inst_q_rdata;
wire                     inst_q_rok;
wire                     inst_q_flush;

// Instruction Decoder
wire                     inst_q_taken;
wire [   ADDR_WIDTH-1:0] inst_q_nxt_pc;
wire [   ADDR_WIDTH-1:0] inst_q_cur_pc;
wire [   DATA_WIDTH-1:0] inst_q_inst;

// Issue Queue
wire                     issue_q_wen;
wire [ISSUE_Q_WIDTH-1:0] issue_q_wdata;
wire                     issue_q_wok;
wire                     issue_q_flush;

//===============================================
// Instruction Fetch
//===============================================
InstFetch_ #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .ADDR_WIDTH   ( ADDR_WIDTH   ),
  .PROT_WIDTH   ( PROT_WIDTH   ),
  .RESP_WIDTH   ( RESP_WIDTH   ),
  .BHT_DEPTH    ( BHT_DEPTH    ),
  .BHT_WIDTH    ( BHT_WIDTH    ),
  .BTB_DEPTH    ( BTB_DEPTH    ),
  .BTB_WIDTH    ( BTB_WIDTH    ),
  .TAG_WIDTH    ( TAG_WIDTH    ),
  .RAS_DEPTH    ( RAS_DEPTH    ),
  .RAS_WIDTH    ( RAS_WIDTH    ), 
  .INST_Q_WIDTH ( INST_Q_WIDTH )
) i0_inst_fetch (
  // AR Channel (AXI4-Lite)
  .m_axi_arready ( m_axi_arready ),
  .m_axi_arvalid ( m_axi_arvalid ),  
  .m_axi_araddr  ( m_axi_araddr  ),
  .m_axi_arprot  ( m_axi_arprot  ),
  //  R Channel (AXI4-Lite)
  .m_axi_rready  ( m_axi_rready  ),
  .m_axi_rvalid  ( m_axi_rvalid  ),
  .m_axi_rdata   ( m_axi_rdata   ),
  .m_axi_rresp   ( m_axi_rresp   ),
  // Instruction Queue
  .inst_q_wen    ( inst_q_wen    ),
  .inst_q_wdata  ( inst_q_wdata  ),
  .inst_q_wok    ( inst_q_wok    ),
  // BPU
  .bpu_valid     ( bpu_valid     ),
  .bpu_flush     ( bpu_flush     ),
  .bpu_target    ( bpu_target    ),
  .bpu_taken     ( bpu_taken     ),
  .bpu_call      ( bpu_call      ),
  .bpu_ret       ( bpu_ret       ),
  .bpu_pc        ( bpu_pc        ),
  //
  .BOOT_ADDR     ( BOOT_ADDR     ),
  .CLK           ( CLK           ),
  .RSTN          ( RSTN          )
);

//===============================================
// Instruction Queue
//===============================================
assign inst_q_flush = bpu_flush;

SyncQueue #(
  .WIDTH ( INST_Q_WIDTH ),
  .DEPTH ( INST_Q_DEPTH ) 
) i1_inst_queue (
  // output
  .sync_q_rok   ( inst_q_rok   ),
  .sync_q_wok   ( inst_q_wok   ),
  .sync_q_rdata ( inst_q_rdata ),
  // input
  .sync_q_ren   ( inst_q_ren   ),
  .sync_q_wen   ( inst_q_wen   ),
  .sync_q_wdata ( inst_q_wdata ),
  .sync_q_flush ( inst_q_flush ),
  //
  .CLK          ( CLK          ),
  .RSTN         ( RSTN         )
);

//===============================================
// Instruction Decoder
//===============================================
parameter INST_Q_INST_BASE   = 0;
parameter INST_Q_CUR_PC_BASE = INST_Q_INST_BASE   + DATA_WIDTH;
parameter INST_Q_NXT_PC_BASE = INST_Q_CUR_PC_BASE + ADDR_WIDTH;
parameter INST_Q_TAKEN_BASE  = INST_Q_NXT_PC_BASE + ADDR_WIDTH;

assign inst_q_taken  = inst_q_rdata[INST_Q_TAKEN_BASE +:         1];
assign inst_q_nxt_pc = inst_q_rdata[INST_Q_NXT_PC_BASE+:ADDR_WIDTH];
assign inst_q_cur_pc = inst_q_rdata[INST_Q_CUR_PC_BASE+:ADDR_WIDTH];
assign inst_q_inst   = inst_q_rdata[INST_Q_INST_BASE  +:DATA_WIDTH];

InstDecoder #(
  .DATA_WIDTH     ( DATA_WIDTH     ),
  .OPCODE_WIDTH   ( OPCODE_WIDTH   ),
  .FUNCT7_WIDTH   ( FUNCT7_WIDTH   ),
  .FUNCT3_WIDTH   ( FUNCT3_WIDTH   ),
  .RS1_WIDTH      ( RS1_WIDTH      ),
  .RS2_WIDTH      ( RS2_WIDTH      ),
  .RD_WIDTH       ( RD_WIDTH       ),
  .FUNCTION_TYPES ( FUNCTION_TYPES ),
  .OPERATOR_TYPES ( OPERATOR_TYPES ),
  .OPERAND_TYPES  ( OPERAND_TYPES  ),
  .ISSUE_Q_WIDTH  ( ISSUE_Q_WIDTH  )
) i2_inst_decoder (
  .issue_q_wen    ( issue_q_wen    ),
  .issue_q_wdata  ( issue_q_wdata  ),
  .inst_q_ren     ( inst_q_ren     ),
  .inst_q_rok     ( inst_q_rok     ),
  .inst_q_taken   ( inst_q_taken   ),
  .inst_q_nxt_pc  ( inst_q_nxt_pc  ),
  .inst_q_cur_pc  ( inst_q_cur_pc  ),
  .inst_q_inst    ( inst_q_inst    ),
  .issue_q_wok    ( issue_q_wok    )
);

//===============================================
// Issue Queue
//===============================================
//assign issue_q_ren
assign issue_q_flush = bpu_flush;

SyncQueue #(
  .WIDTH ( ISSUE_Q_WIDTH ),
  .DEPTH ( ISSUE_Q_DEPTH ) 
) i3_issue_queue (
  // output
  .sync_q_rok   ( issue_q_rok   ),
  .sync_q_wok   ( issue_q_wok   ),
  .sync_q_rdata ( issue_q_rdata ),
  // input
  .sync_q_ren   ( issue_q_ren   ),
  .sync_q_wen   ( issue_q_wen   ),
  .sync_q_wdata ( issue_q_wdata ),
  .sync_q_flush ( issue_q_flush ),
  //
  .CLK          ( CLK           ),
  .RSTN         ( RSTN          )
);

endmodule