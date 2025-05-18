module InstFetch_ #(
   parameter DATA_WIDTH   = 32
  ,parameter ADDR_WIDTH   = 32
  ,parameter PROT_WIDTH   = 3
  ,parameter RESP_WIDTH   = 4
  ,parameter BHT_DEPTH    = 16
  ,parameter BHT_WIDTH    = 4 
  ,parameter BTB_DEPTH    = 16
  ,parameter BTB_WIDTH    = 4
  ,parameter TAG_WIDTH    = 10
  ,parameter RAS_DEPTH    = 4
  ,parameter RAS_WIDTH    = 2
  ,parameter INST_Q_WIDTH = 97
)(
  // AR Channel (AXI4-Lite)
    input                    m_axi_arready
  ,output                    m_axi_arvalid  
  ,output [  ADDR_WIDTH-1:0] m_axi_araddr
  ,output [  PROT_WIDTH-1:0] m_axi_arprot
  //  R Channel (AXI4-Lite)
  ,output                    m_axi_rready
  , input                    m_axi_rvalid
  , input [  DATA_WIDTH-1:0] m_axi_rdata
  , input [  RESP_WIDTH-1:0] m_axi_rresp
  // Instruction Queue
  // <<
  ,output                    inst_q_wen
  ,output [INST_Q_WIDTH-1:0] inst_q_wdata
  // >>
  , input                    inst_q_wok
  // BPU
  // >>
  , input                    bpu_valid  
  , input                    bpu_flush
  , input [  ADDR_WIDTH-1:0] bpu_target
  , input                    bpu_taken
  , input                    bpu_call
  , input                    bpu_ret
  , input [  ADDR_WIDTH-1:0] bpu_pc
  //
  , input [  ADDR_WIDTH-1:0] BOOT_ADDR
  , input                    CLK
  , input                    RSTN
);

parameter OKAY   = 0;
parameter EXOKAY = 1;
parameter SLVERR = 2; 
parameter DECERR = 3;
// AXI handshaking
wire                  m_axi_arhsk;
wire                  m_axi_rhsk;
wire                  m_axi_rerr;
// Instruction info. reserve and control.
wire                  req_trig;
reg                   req_flag;
reg                   req_sent;
reg  [ADDR_WIDTH-1:0] req_pc;
reg                   req_pc_taken;
reg                   req_boot;
// From PC Gen.
wire [ADDR_WIDTH-1:0] pc_out;
wire                  pc_taken;
//
wire                  inst_valid;
wire                  inst_taken;
wire [ADDR_WIDTH-1:0] inst_nxt_pc;
wire [ADDR_WIDTH-1:0] inst_cur_pc;
wire [DATA_WIDTH-1:0] inst;

//===============================================
// Instruction Fetch
//===============================================
//----------------------------
// Output to Bus Interface
//----------------------------
assign m_axi_arvalid = ~req_sent | m_axi_rhsk | m_axi_rerr;
assign m_axi_araddr  =   req_boot ? BOOT_ADDR :
                       m_axi_rerr ?    req_pc : 
                       m_axi_rhsk ?    pc_out :
                         req_trig ?    pc_out :
                                       req_pc ;
assign m_axi_arprot  = 'd0;

assign m_axi_rready  = inst_q_wok;

assign m_axi_arhsk   = m_axi_arvalid & m_axi_arready;
assign m_axi_rhsk    = m_axi_rvalid & m_axi_rready & (m_axi_rresp == OKAY);
assign m_axi_rerr    = m_axi_rvalid & m_axi_rready & (m_axi_rresp != OKAY);

//----------------------------
// Output to Instruction Queue.
//----------------------------
assign inst_q_wen    = inst_valid;    
assign inst_q_wdata  = {              
/* inst. taken/spec. */   inst_taken
/* inst. nxt. pc     */  ,inst_nxt_pc
/* inst. cur. pc     */  ,inst_cur_pc
/* inst.             */  ,inst
                       };             

//----------------------------
// Instruction Fetch Results.
//----------------------------
assign inst_valid    = m_axi_rhsk; 
assign inst_taken    = req_pc_taken;
assign inst_cur_pc   = req_pc;     
assign inst_nxt_pc   = pc_out;
assign inst          = m_axi_rdata;

assign req_trig      = ~req_flag & m_axi_arvalid;

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      req_boot <= 'd1;
    else if (m_axi_arhsk)
      req_boot <= 'd0;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      req_sent <= 'd0;
    else if (m_axi_arhsk)
      req_sent <= 'd1;
    else if (m_axi_rhsk | m_axi_rerr)
      req_sent <= 'd0;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      req_flag <= 'd0;
    else
      req_flag <= m_axi_arvalid;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        req_pc       <= 'd0;
        req_pc_taken <= 'd0;
      end
    else if (req_trig | m_axi_rhsk)
      begin
        req_pc       <= m_axi_araddr;
        req_pc_taken <= pc_taken; 
      end
  end

//===============================================
// Program Counter Generate
//===============================================
InstPcGen #(
  .ADDR_WIDTH ( ADDR_WIDTH  ),
  .BHT_DEPTH  ( BHT_DEPTH   ),
  .BHT_WIDTH  ( BHT_WIDTH   ),
  .BTB_DEPTH  ( BTB_DEPTH   ),
  .BTB_WIDTH  ( BTB_WIDTH   ),
  .TAG_WIDTH  ( TAG_WIDTH   ),
  .RAS_DEPTH  ( RAS_DEPTH   ),
  .RAS_WIDTH  ( RAS_WIDTH   ) 
) i0_Inst_Pc_Gen (            
  .pc_out     ( pc_out      ),
  .pc_taken   ( pc_taken    ),
  // Instruction fetch
  .inst_valid ( inst_valid  ),
  .inst_pc    ( inst_cur_pc ),
  .inst       ( inst        ),
  // BPU
  .bpu_valid  ( bpu_valid   ),
  .bpu_flush  ( bpu_flush   ),
  .bpu_target ( bpu_target  ),
  .bpu_taken  ( bpu_taken   ),
  .bpu_call   ( bpu_call    ),
  .bpu_ret    ( bpu_ret     ),
  .bpu_pc     ( bpu_pc      ),
  //
  .BOOT_ADDR  ( BOOT_ADDR   ),
  .CLK        ( CLK         ),
  .RSTN       ( RSTN        ) 
);

endmodule
