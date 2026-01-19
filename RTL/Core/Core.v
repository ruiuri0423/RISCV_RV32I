module Core #(
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
  ,parameter BHT_DEPTH       = 16
  ,parameter BHT_WIDTH       = 4 
  ,parameter BTB_DEPTH       = 16
  ,parameter BTB_WIDTH       = 4
  ,parameter TAG_WIDTH       = 10
  ,parameter RAS_DEPTH       = 4
  ,parameter RAS_WIDTH       = 2
  ,parameter INST_Q_WIDTH    = 97 // 32 + 32 + 32 + 1
  ,parameter INST_Q_DEPTH    = 2
  ,parameter OPCODE_WIDTH    = 7
  ,parameter FUNCT7_WIDTH    = 7
  ,parameter FUNCT3_WIDTH    = 3
  ,parameter RS1_WIDTH       = 5
  ,parameter RS2_WIDTH       = 5
  ,parameter RD_WIDTH        = 5
  ,parameter FUNCTION_TYPES  = $clog2( 4)
  ,parameter OPERATOR_TYPES  = $clog2(10)
  ,parameter OPERAND_TYPES   = $clog2( 4)
  ,parameter ISSUE_Q_WIDTH   = 123 // 2 + 2 + 4 + 32 + 5 + 5 + 5 + 1 + 32 + 32 + 1
  ,parameter ISSUE_Q_DEPTH   = 2
  ,parameter ROB_ENTRY       = 4
  ,parameter ARCH_ENTRY      = 32
  ,parameter QUERY_PORT      = 2
  ,parameter ISSUER          = 4
  ,parameter LISTENER        = 4
  ,parameter ISSUER_PRIOR    = {2'd0, 2'd1, 2'd2, 2'd3}
  ,parameter ISSUER_ARCH_REG = {1'd0, 1'd0, 1'd0, 1'd1}
)(
  // AR Channel (AXI4-Lite)
    input                     m_axi_arready_fe
  ,output                     m_axi_arvalid_fe  
  ,output [   ADDR_WIDTH-1:0] m_axi_araddr_fe
  ,output [   PROT_WIDTH-1:0] m_axi_arprot_fe
  //  R Channel (AXI4-Lite)
  , input                     m_axi_rvalid_fe
  , input [   DATA_WIDTH-1:0] m_axi_rdata_fe
  , input [   RESP_WIDTH-1:0] m_axi_rresp_fe
  ,output                     m_axi_rready_fe
  // AW Channel
  , input                     m_axi_awready_be  
  ,output                     m_axi_awvalid_be  
  ,output [   ADDR_WIDTH-1:0] m_axi_awaddr_be   
  ,output [   PROT_WIDTH-1:0] m_axi_awprot_be   
  ,output [     ID_WIDTH-1:0] m_axi_awid_be    
  ,output [    LEN_WIDTH-1:0] m_axi_awlen_be   
  ,output [   SIZE_WIDTH-1:0] m_axi_awsize_be  
  ,output [  BURST_WIDTH-1:0] m_axi_awburst_be 
  ,output [   LOCK_WIDTH-1:0] m_axi_awlock_be  
  ,output [  CACHE_WIDTH-1:0] m_axi_awcache_be 
  ,output [    QOS_WIDTH-1:0] m_axi_awqos_be   
  ,output [ REGION_WIDTH-1:0] m_axi_awregion_be
  ,output [   USER_WIDTH-1:0] m_axi_awuser_be
  // W Channel                
  , input                     m_axi_wready_be
  ,output                     m_axi_wvalid_be
  ,output [   DATA_WIDTH-1:0] m_axi_wdata_be
  ,output [   STRB_WIDTH-1:0] m_axi_wstrb_be
  ,output                     m_axi_wlast_be
  ,output [   USER_WIDTH-1:0] m_axi_wuser_be    
  // B Channel                
  , input                     m_axi_bvalid_be
  , input [   RESP_WIDTH-1:0] m_axi_bresp_be
  , input [     ID_WIDTH-1:0] m_axi_bid_be
  , input [   USER_WIDTH-1:0] m_axi_buser_be
  ,output                     m_axi_bready_be
  // AR Channel               
  , input                     m_axi_arready_be
  ,output                     m_axi_arvalid_be  
  ,output [   ADDR_WIDTH-1:0] m_axi_araddr_be
  ,output [   PROT_WIDTH-1:0] m_axi_arprot_be
  ,output [     ID_WIDTH-1:0] m_axi_arid_be    
  ,output [    LEN_WIDTH-1:0] m_axi_arlen_be   
  ,output [   SIZE_WIDTH-1:0] m_axi_arsize_be  
  ,output [  BURST_WIDTH-1:0] m_axi_arburst_be 
  ,output [   LOCK_WIDTH-1:0] m_axi_arlock_be  
  ,output [  CACHE_WIDTH-1:0] m_axi_arcache_be 
  ,output [    QOS_WIDTH-1:0] m_axi_arqos_be   
  ,output [ REGION_WIDTH-1:0] m_axi_arregion_be
  ,output [   USER_WIDTH-1:0] m_axi_aruser_be   
  // R Channel                
  , input                     m_axi_rvalid_be
  , input [   DATA_WIDTH-1:0] m_axi_rdata_be
  , input [   RESP_WIDTH-1:0] m_axi_rresp_be
  , input [     ID_WIDTH-1:0] m_axi_rid_be  
  , input                     m_axi_rlast_be
  , input [   USER_WIDTH-1:0] m_axi_ruser_be
  ,output                     m_axi_rready_be
  //
  , input [   ADDR_WIDTH-1:0] BOOT_ADDR
  , input                     CLK
  , input                     RSTN
);

// Issue Queue
wire                     issue_q_ren;
wire                     issue_q_rok;
wire [ISSUE_Q_WIDTH-1:0] issue_q_rdata;
// BPU
wire                     bpu_valid;
wire                     bpu_flush;
wire [   ADDR_WIDTH-1:0] bpu_target;
wire                     bpu_taken;
wire                     bpu_call;
wire                     bpu_ret;
wire [   ADDR_WIDTH-1:0] bpu_pc;

Frontend #(
  .DATA_WIDTH     ( DATA_WIDTH     ),
  .ADDR_WIDTH     ( ADDR_WIDTH     ),
  .PROT_WIDTH     ( PROT_WIDTH     ),
  .RESP_WIDTH     ( RESP_WIDTH     ),
  .BHT_DEPTH      ( BHT_DEPTH      ),
  .BHT_WIDTH      ( BHT_WIDTH      ),
  .BTB_DEPTH      ( BTB_DEPTH      ),
  .BTB_WIDTH      ( BTB_WIDTH      ),
  .TAG_WIDTH      ( TAG_WIDTH      ),
  .RAS_DEPTH      ( RAS_DEPTH      ),
  .RAS_WIDTH      ( RAS_WIDTH      ),
  .INST_Q_WIDTH   ( INST_Q_WIDTH   ),
  .INST_Q_DEPTH   ( INST_Q_DEPTH   ),
  .OPCODE_WIDTH   ( OPCODE_WIDTH   ),
  .FUNCT7_WIDTH   ( FUNCT7_WIDTH   ),
  .FUNCT3_WIDTH   ( FUNCT3_WIDTH   ),
  .RS1_WIDTH      ( RS1_WIDTH      ),
  .RS2_WIDTH      ( RS2_WIDTH      ),
  .RD_WIDTH       ( RD_WIDTH       ),
  .FUNCTION_TYPES ( FUNCTION_TYPES ),
  .OPERATOR_TYPES ( OPERATOR_TYPES ),
  .OPERAND_TYPES  ( OPERAND_TYPES  ),
  .ISSUE_Q_WIDTH  ( ISSUE_Q_WIDTH  ),
  .ISSUE_Q_DEPTH  ( ISSUE_Q_DEPTH  ) 
) i0_frontend (
  // AR Channel (AXI4-Lite)
  .m_axi_arready ( m_axi_arready_fe ),
  .m_axi_arvalid ( m_axi_arvalid_fe ),  
  .m_axi_araddr  ( m_axi_araddr_fe  ),
  .m_axi_arprot  ( m_axi_arprot_fe  ),
  //  R Channel (AXI4-Lite)
  .m_axi_rready  ( m_axi_rready_fe  ),
  .m_axi_rvalid  ( m_axi_rvalid_fe  ),
  .m_axi_rdata   ( m_axi_rdata_fe   ),
  .m_axi_rresp   ( m_axi_rresp_fe   ),
  // Issue Queue
  .issue_q_ren   ( issue_q_ren      ),
  .issue_q_rdata ( issue_q_rdata    ),
  .issue_q_rok   ( issue_q_rok      ),
  // BPU                            
  .bpu_valid     ( bpu_valid        ),
  .bpu_flush     ( bpu_flush        ),
  .bpu_target    ( bpu_target       ),
  .bpu_taken     ( bpu_taken        ),
  .bpu_call      ( bpu_call         ),
  .bpu_ret       ( bpu_ret          ),
  .bpu_pc        ( bpu_pc           ),
  //                                
  .BOOT_ADDR     ( BOOT_ADDR        ),
  .CLK           ( CLK              ),
  .RSTN          ( RSTN             )
);

Backend #(
  .ID_WIDTH        ( ID_WIDTH        ),
  .ADDR_WIDTH      ( ADDR_WIDTH      ),
  .LEN_WIDTH       ( LEN_WIDTH       ),
  .SIZE_WIDTH      ( SIZE_WIDTH      ),
  .BURST_WIDTH     ( BURST_WIDTH     ),
  .LOCK_WIDTH      ( LOCK_WIDTH      ),
  .CACHE_WIDTH     ( CACHE_WIDTH     ),
  .PROT_WIDTH      ( PROT_WIDTH      ),
  .QOS_WIDTH       ( QOS_WIDTH       ),
  .REGION_WIDTH    ( REGION_WIDTH    ),
  .USER_WIDTH      ( USER_WIDTH      ),
  .DATA_WIDTH      ( DATA_WIDTH      ),
  .STRB_WIDTH      ( STRB_WIDTH      ),
  .RESP_WIDTH      ( RESP_WIDTH      ),
  .ROB_ENTRY       ( ROB_ENTRY       ), 
  .ARCH_ENTRY      ( ARCH_ENTRY      ), 
  .ISSUE_Q_WIDTH   ( ISSUE_Q_WIDTH   ), 
  .QUERY_PORT      ( QUERY_PORT      ), 
  .ISSUER          ( ISSUER          ), 
  .LISTENER        ( LISTENER        ), 
  .ISSUER_PRIOR    ( ISSUER_PRIOR    ), 
  .ISSUER_ARCH_REG ( ISSUER_ARCH_REG ),
  .FUNCTION_TYPES  ( FUNCTION_TYPES  ),
  .OPERATOR_TYPES  ( OPERATOR_TYPES  ),
  .OPERAND_TYPES   ( OPERAND_TYPES   )
) i1_backend (
  // AW Channel
  .m_axi_awready  ( m_axi_awready_be  ),
  .m_axi_awvalid  ( m_axi_awvalid_be  ),
  .m_axi_awaddr   ( m_axi_awaddr_be   ),
  .m_axi_awprot   ( m_axi_awprot_be   ),
  .m_axi_awid     ( m_axi_awid_be     ),
  .m_axi_awlen    ( m_axi_awlen_be    ),
  .m_axi_awsize   ( m_axi_awsize_be   ),
  .m_axi_awburst  ( m_axi_awburst_be  ),
  .m_axi_awlock   ( m_axi_awlock_be   ),
  .m_axi_awcache  ( m_axi_awcache_be  ),
  .m_axi_awqos    ( m_axi_awqos_be    ),
  .m_axi_awregion ( m_axi_awregion_be ),
  .m_axi_awuser   ( m_axi_awuser_be   ),
  // W Channel
  .m_axi_wready   ( m_axi_wready_be   ),
  .m_axi_wvalid   ( m_axi_wvalid_be   ),
  .m_axi_wdata    ( m_axi_wdata_be    ),
  .m_axi_wstrb    ( m_axi_wstrb_be    ),
  .m_axi_wlast    ( m_axi_wlast_be    ),
  .m_axi_wuser    ( m_axi_wuser_be    ),
  // B Channel
  .m_axi_bready   ( m_axi_bready_be   ),
  .m_axi_bvalid   ( m_axi_bvalid_be   ),
  .m_axi_bresp    ( m_axi_bresp_be    ),
  .m_axi_bid      ( m_axi_bid_be      ),
  .m_axi_buser    ( m_axi_buser_be    ),
  // AR Channel
  .m_axi_arready  ( m_axi_arready_be  ),
  .m_axi_arvalid  ( m_axi_arvalid_be  ),
  .m_axi_araddr   ( m_axi_araddr_be   ),
  .m_axi_arprot   ( m_axi_arprot_be   ),
  .m_axi_arid     ( m_axi_arid_be     ),
  .m_axi_arlen    ( m_axi_arlen_be    ),
  .m_axi_arsize   ( m_axi_arsize_be   ),
  .m_axi_arburst  ( m_axi_arburst_be  ),
  .m_axi_arlock   ( m_axi_arlock_be   ),
  .m_axi_arcache  ( m_axi_arcache_be  ),
  .m_axi_arqos    ( m_axi_arqos_be    ),
  .m_axi_arregion ( m_axi_arregion_be ),
  .m_axi_aruser   ( m_axi_aruser_be   ),
  // R Channel
  .m_axi_rready   ( m_axi_rready_be   ),
  .m_axi_rvalid   ( m_axi_rvalid_be   ),
  .m_axi_rdata    ( m_axi_rdata_be    ),
  .m_axi_rresp    ( m_axi_rresp_be    ),
  .m_axi_rid      ( m_axi_rid_be      ),
  .m_axi_rlast    ( m_axi_rlast_be    ),
  .m_axi_ruser    ( m_axi_ruser_be    ),
  // BPU
  .bpu_valid      ( bpu_valid         ),
  .bpu_flush      ( bpu_flush         ),
  .bpu_target     ( bpu_target        ),
  .bpu_taken      ( bpu_taken         ),
  .bpu_call       ( bpu_call          ),
  .bpu_ret        ( bpu_ret           ),
  .bpu_pc         ( bpu_pc            ),
  // Issue Queue                      
  .issue_q_ren    ( issue_q_ren       ),
  .issue_q_rok    ( issue_q_rok       ),
  .issue_q_rdata  ( issue_q_rdata     ),
  //                                  
  .CLK            ( CLK               ),
  .RSTN           ( RSTN              )
);

endmodule
