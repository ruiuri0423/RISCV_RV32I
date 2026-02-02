`define AXI_WRITE
`define AXI_READ
`define AXI_LITE

module AxiMasterWrapper #(
   parameter     ID_WIDTH = 4 
  ,parameter   ADDR_WIDTH = 32
  ,parameter    LEN_WIDTH = 8
  ,parameter   SIZE_WIDTH = 4
  ,parameter  BURST_WIDTH = 2
  ,parameter   LOCK_WIDTH = 1
  ,parameter  CACHE_WIDTH = 4
  ,parameter   PROT_WIDTH = 3
  ,parameter    QOS_WIDTH = 4
  ,parameter REGION_WIDTH = 4
  ,parameter   USER_WIDTH = 32
  ,parameter   DATA_WIDTH = 32 
  ,parameter   STRB_WIDTH = 4
  ,parameter   RESP_WIDTH = 2
)(
    input                    aclk
  , input                    aresetn
`ifdef AXI_WRITE
  // AW Channel
  , input                    m_axi_awready  
  ,output                    m_axi_awvalid  
  ,output [  ADDR_WIDTH-1:0] m_axi_awaddr   
  ,output [  PROT_WIDTH-1:0] m_axi_awprot   
  `ifndef AXI_LITE 
    ,output [    ID_WIDTH-1:0] m_axi_awid    
    ,output [   LEN_WIDTH-1:0] m_axi_awlen   
    ,output [  SIZE_WIDTH-1:0] m_axi_awsize  
    ,output [ BURST_WIDTH-1:0] m_axi_awburst 
    ,output [  LOCK_WIDTH-1:0] m_axi_awlock  
    ,output [ CACHE_WIDTH-1:0] m_axi_awcache 
    ,output [   QOS_WIDTH-1:0] m_axi_awqos   
    ,output [REGION_WIDTH-1:0] m_axi_awregion
    ,output [  USER_WIDTH-1:0] m_axi_awuser
  `endif
  // W Chan   DATA_WIDTHnel
  , input                    m_axi_wready
  ,output                    m_axi_wvalid
  ,output [  DATA_WIDTH-1:0] m_axi_wdata
  ,output [  STRB_WIDTH-1:0] m_axi_wstrb
  `ifndef AXI_LITE 
    ,output                    m_axi_wlast
    ,output [  USER_WIDTH-1:0] m_axi_wuser    
  `endif
  // B Channel
  ,output                    m_axi_bready
  , input                    m_axi_bvalid
  , input [  RESP_WIDTH-1:0] m_axi_bresp
  `ifndef AXI_LITE 
    , input [    ID_WIDTH-1:0] m_axi_bid
    , input [  USER_WIDTH-1:0] m_axi_buser
  `endif
`endif
`ifdef AXI_READ
  // AR Channel
  , input                    m_axi_arready
  ,output                    m_axi_arvalid  
  ,output [  ADDR_WIDTH-1:0] m_axi_araddr
  ,output [  PROT_WIDTH-1:0] m_axi_arprot
  `ifndef AXI_LITE 
    ,output [    ID_WIDTH-1:0] m_axi_arid    
    ,output [   LEN_WIDTH-1:0] m_axi_arlen   
    ,output [  SIZE_WIDTH-1:0] m_axi_arsize  
    ,output [ BURST_WIDTH-1:0] m_axi_arburst 
    ,output [  LOCK_WIDTH-1:0] m_axi_arlock  
    ,output [ CACHE_WIDTH-1:0] m_axi_arcache 
    ,output [   QOS_WIDTH-1:0] m_axi_arqos   
    ,output [REGION_WIDTH-1:0] m_axi_arregion
    ,output [  USER_WIDTH-1:0] m_axi_aruser   
  `endif
  // R Channel
  ,output                    m_axi_rready
  , input                    m_axi_rvalid
  , input [  DATA_WIDTH-1:0] m_axi_rdata
  , input [  RESP_WIDTH-1:0] m_axi_rresp
  `ifndef AXI_LITE 
    , input [    ID_WIDTH-1:0] m_axi_rid  
    , input                    m_axi_rlast
    , input [  USER_WIDTH-1:0] m_axi_ruser
  `endif
`endif
  // USER
`ifdef AXI_WRITE
  ,output                    u_wr_ren
  ,output                    u_wr_gnt
  , input                    u_wr_rok
  , input                    u_wr_req
  , input [   LEN_WIDTH-1:0] u_wr_len
  , input [  ADDR_WIDTH-1:0] u_wr_addr
  , input [  DATA_WIDTH-1:0] u_wr_data
  , input [  STRB_WIDTH-1:0] u_wr_strb
`endif
`ifdef AXI_READ
  ,output [  DATA_WIDTH-1:0] u_rd_data
  ,output                    u_rd_wen
  ,output                    u_rd_gnt
  , input                    u_rd_wok
  , input                    u_rd_req
  , input [   LEN_WIDTH-1:0] u_rd_len
  , input [  ADDR_WIDTH-1:0] u_rd_addr
`endif
);


`ifdef AXI_WRITE
  //===============================================
  // AW Channel
  //===============================================
  assign u_wr_gnt       = m_axi_awready;
  assign m_axi_awvalid  = u_wr_req;
  assign m_axi_awaddr   = u_wr_req ? u_wr_addr : 'd0;
  assign m_axi_awprot   = u_wr_req ?       'd0 : 'd0;
  `ifndef AXI_LITE
    assign m_axi_awid     = 'd0;
    assign m_axi_awlen    = u_wr_req ?    m_axi_awlen : 'd0;
    assign m_axi_awsize   = u_wr_req ? (DATA_WIDTH/8) : 'd0;
    assign m_axi_awburst  = 'd1; // INCR;
    assign m_axi_awlock   = 'd0; // Atomic
    assign m_axi_awcache  = 'd0; // Device Non-bufferable
    assign m_axi_awqos    = 'd0;
    assign m_axi_awregion = 'd0;
    assign m_axi_awuser   = 'd0;
  `endif

  //===============================================
  // W Channel
  //===============================================
  wire [LEN_WIDTH-1:0] wr_len_cnt_nxt;
  reg  [LEN_WIDTH-1:0] wr_len_cnt;

  assign wr_len_cnt_nxt = u_wr_req ? u_wr_len - (m_axi_wvalid & m_axi_wready) :
                         (|wr_len_cnt & m_axi_wvalid & m_axi_wready) ? wr_len_cnt - 'd1 : wr_len_cnt;

  always @(posedge aclk or negedge aresetn)
    begin
      if (~aresetn)
        wr_len_cnt <= 'd0;
      else
        wr_len_cnt <= wr_len_cnt_nxt;
    end

  assign m_axi_wvalid = u_wr_req | (|wr_len_cnt);
  assign m_axi_wdata  = u_wr_data;
  assign m_axi_wstrb  = u_wr_strb;
  `ifndef AXI_LITE 
    assign m_axi_wlast = wr_len_cnt == 'd1;
    assign m_axi_wuser = 'd0;
  `endif

  assign u_wr_ren = m_axi_wvalid & m_axi_wready;

  //===============================================
  // B Channel
  //===============================================
  assign m_axi_bready = 'd1;
`endif

`ifdef AXI_READ
  //===============================================
  // AR Channel
  //===============================================
  assign u_rd_gnt       = m_axi_arready;
  assign m_axi_arvalid  = u_rd_req;
  assign m_axi_araddr   = u_rd_req ? u_rd_addr : 'd0;
  assign m_axi_arprot   = u_rd_req ?       'd0 : 'd0;
  `ifndef AXI_LITE
    assign m_axi_arid     = 'd0;
    assign m_axi_arlen    = u_rd_req ?    m_axi_arlen : 'd0;
    assign m_axi_arsize   = u_rd_req ? (DATA_WIDTH/8) : 'd0;
    assign m_axi_arburst  = 'd1; // INCR;
    assign m_axi_arlock   = 'd0; // Atomic
    assign m_axi_arcache  = 'd0; // Device Non-bufferable
    assign m_axi_arqos    = 'd0;
    assign m_axi_arregion = 'd0;
    assign m_axi_aruser   = 'd0;
  `endif

  //===============================================
  // R Channel
  //===============================================
  assign u_rd_data    = m_axi_rdata;
  assign u_rd_wen     = m_axi_rready & m_axi_rvalid;
  assign m_axi_rready = u_rd_wok;

`endif

endmodule