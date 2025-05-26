module CommonDataBus #(
   parameter ISSUER          = 4
  ,parameter LISTENER        = 4
  ,parameter ROB_ENTRY       = 4
  ,parameter ARCH_ENTRY      = 32
  ,parameter DATA_WIDTH      = 32
  ,parameter ISSUER_PRIOR    = {2'd0, 2'd1, 2'd2, 2'd3}
  ,parameter ISSUER_ARCH_REG = {1'd0, 1'd0, 1'd0, 1'd1}
  //-----------------------
  ,parameter ROB_ENTRY_LOG2  = $clog2(ROB_ENTRY)
  ,parameter ARCH_ENTRY_LOG2 = $clog2(ARCH_ENTRY)
  ,parameter ISSUER_LOG2     = $clog2(ISSUER)
)(
  // Excution to Reorder Bufffer
   output                                 rob_write 
  ,output [           ROB_ENTRY_LOG2-1:0] rob_id
  ,output [               DATA_WIDTH-1:0] rob_data
  // Reorder Buffer to Arch. Register
  ,output                                 arch_reg_write
  ,output [          ARCH_ENTRY_LOG2-1:0] arch_reg_id
  ,output [               DATA_WIDTH-1:0] arch_reg_data
  // Issuer
  ,output [  ISSUER                 -1:0] cdb_isr_grant
  , input [  ISSUER                 -1:0] cdb_isr_request
  , input [( ISSUER*     DATA_WIDTH)-1:0] cdb_isr_data
  , input [( ISSUER* ROB_ENTRY_LOG2)-1:0] cdb_isr_id
  , input [( ISSUER*ARCH_ENTRY_LOG2)-1:0] cdb_isr_arch_id
  // Listener
  ,output [ LISTENER                -1:0] cdb_lsn_hit
  ,output [(LISTENER*    DATA_WIDTH)-1:0] cdb_lsn_data
  , input [ LISTENER                -1:0] cdb_lsn_request
  , input [(LISTENER*ROB_ENTRY_LOG2)-1:0] cdb_lsn_id
  //
  , input                                  CLK
  , input                                  RSTN
);

wire [ISSUER_LOG2-1:0] cdb_isr_grant_usr;

Parameterized_RR_Arbiter#(
  .USER(ISSUER)
) i0_RoundRobin (
  .grant      ( cdb_isr_grant     ),
  .grant_user ( cdb_isr_grant_usr ),
  .request    ( cdb_isr_request   ),
  .priority_  ( ISSUER_PRIOR      ),
  .CLK        ( CLK               ),
  .RSTN       ( RSTN              ) 
);

//===============================================
// EXE Unit to ROB
//===============================================
assign rob_write = ~ISSUER_ARCH_REG[cdb_isr_grant_usr] & 
                    cdb_isr_request[cdb_isr_grant_usr] & 
                    cdb_isr_grant  [cdb_isr_grant_usr];

assign rob_id    = cdb_isr_id  [cdb_isr_grant_usr*ROB_ENTRY_LOG2+:ROB_ENTRY_LOG2];
assign rob_data  = cdb_isr_data[cdb_isr_grant_usr*    DATA_WIDTH+:    DATA_WIDTH];

//===============================================
// ROB to ARCH REG
//===============================================
assign arch_reg_write = ISSUER_ARCH_REG[cdb_isr_grant_usr] & 
                        cdb_isr_request[cdb_isr_grant_usr] & 
                        cdb_isr_grant  [cdb_isr_grant_usr];

assign arch_reg_id    = cdb_isr_id  [cdb_isr_grant_usr*ROB_ENTRY_LOG2+:ROB_ENTRY_LOG2];
assign arch_reg_data  = cdb_isr_data[cdb_isr_grant_usr*    DATA_WIDTH+:    DATA_WIDTH];

//===============================================
// 
//===============================================
genvar g;
generate
  begin : LISTENER_MATCH
    for (g=0; g<LISTENER; g=g+1)
      begin : LISTENER_HIT_DATA
        assign cdb_lsn_hit[g] = (cdb_lsn_id[ROB_ENTRY_LOG2*                g+:ROB_ENTRY_LOG2] == 
                                 cdb_isr_id[ROB_ENTRY_LOG2*cdb_isr_grant_usr+:ROB_ENTRY_LOG2]) & cdb_lsn_request[g];

        assign cdb_lsn_data[DATA_WIDTH*                g+:DATA_WIDTH] = cdb_lsn_hit[g] ? 
               cdb_isr_data[DATA_WIDTH*cdb_isr_grant_usr+:DATA_WIDTH] : 'd0;
      end
  end
endgenerate

endmodule