module InstPcGen #(
   parameter ADDR_WIDTH = 32
  ,parameter BHT_DEPTH  = 16  
  ,parameter BHT_WIDTH  = 4   
  ,parameter BTB_DEPTH  = 1023
  ,parameter BTB_WIDTH  = 10   
  ,parameter TAG_WIDTH  = 22  
  ,parameter RAS_DEPTH  = 4   
  ,parameter RAS_WIDTH  = 2   
)(
   output wire [ADDR_WIDTH-1:0] pc_out
  ,output wire                  pc_taken
  // Instruction fetch
  , input wire                  inst_valid
  , input wire [ADDR_WIDTH-1:0] inst_pc
  , input wire [ADDR_WIDTH-1:0] inst
  // BPU
  , input wire                  bpu_valid
  , input wire                  bpu_flush
  , input wire [ADDR_WIDTH-1:0] bpu_target
  , input wire                  bpu_taken
  , input wire                  bpu_call
  , input wire                  bpu_ret
  , input wire [ADDR_WIDTH-1:0] bpu_pc
  //
  , input wire [ADDR_WIDTH-1:0] BOOT_ADDR
  , input wire                  CLK
  , input wire                  RSTN
);

wire                  pdec_branch;
wire                  pdec_jal;
wire                  pdec_jalr;
wire                  pdec_call;
wire                  pdec_ret;
wire [ADDR_WIDTH-1:0] pdec_pc;

wire                  bp_taken;
wire [ADDR_WIDTH-1:0] bp_pc;

reg  [ADDR_WIDTH-1:0] pc_inc_4;

//===============================================
// Pre-Decoder
//===============================================
InstPreDecoder #(
  .ADDR_WIDTH ( ADDR_WIDTH )
) i0_inst_pre_decoder (
  // output
  .pdec_branch ( pdec_branch ),
  .pdec_jal    ( pdec_jal    ),
  .pdec_jalr   ( pdec_jalr   ),
  .pdec_call   ( pdec_call   ),
  .pdec_ret    ( pdec_ret    ),
  .pdec_pc     ( pdec_pc     ),
  // input
  .inst_valid  ( inst_valid  ),
  .inst_pc     ( inst_pc     ),
  .inst        ( inst        )
);

//===============================================
// Branch Prediction
//===============================================
InstBranchPredict #(
  .ADDR_WIDTH ( ADDR_WIDTH ),
  .BHT_DEPTH  ( BHT_DEPTH  ),
  .BHT_WIDTH  ( BHT_WIDTH  ),
  .BTB_DEPTH  ( BTB_DEPTH  ),
  .BTB_WIDTH  ( BTB_WIDTH  ), 
  .TAG_WIDTH  ( TAG_WIDTH  ),
  .RAS_DEPTH  ( RAS_DEPTH  ),
  .RAS_WIDTH  ( RAS_WIDTH  ) 
) i1_inst_branch_predict (  
  .bp_taken   ( bp_taken   ),
  .bp_pc      ( bp_pc      ),
  // From inst_fetch
  .inst_valid ( inst_valid ),
  .inst_pc    ( inst_pc    ),
  // From Pre-Decoder
  .pdec_branch( pdec_branch),
  .pdec_jal   ( pdec_jal   ),
  .pdec_jalr  ( pdec_jalr  ),
  .pdec_ret   ( pdec_ret   ),
  .pdec_call  ( pdec_call  ),
  .pdec_pc    ( pdec_pc    ),
  // From BPU
  .bpu_valid  ( bpu_valid  ),
  .bpu_flush  ( bpu_flush  ),
  .bpu_target ( bpu_target ),
  .bpu_taken  ( bpu_taken  ),
  .bpu_call   ( bpu_call   ),
  .bpu_ret    ( bpu_ret    ),
  .bpu_pc     ( bpu_pc     ),
  // 
  .CLK        ( CLK        ),
  .RSTN       ( RSTN       )
);

//===============================================
// Program Counter Generate
//===============================================
assign pc_out   = bp_taken ? bp_pc : pc_inc_4;
assign pc_taken = bp_taken;

always @(posedge CLK or negedge RSTN)
  begin 
    if (~RSTN)
      pc_inc_4 <= BOOT_ADDR + 'd4;
    else if (inst_valid)
      pc_inc_4 <= pc_out + 'd4;
  end

endmodule