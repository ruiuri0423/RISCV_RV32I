//`define AXI_WRITE
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
  , input                    arestn
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
);



endmodule