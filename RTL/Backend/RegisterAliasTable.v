module RegisterAliasTable #(
   parameter QUERY_PORT = 2
  ,parameter ARCH_ENTRY = 32 
  ,parameter ROB_ENTRY  = 4
  //-----------------------
  ,parameter ARCH_ENTRY_LOG2 = $clog2(ARCH_ENTRY)
  ,parameter ROB_ENTRY_LOG2  = $clog2( ROB_ENTRY)
)(
  // Query Port
   output [(QUERY_PORT                )-1:0] rat_result_busy
  ,output [(QUERY_PORT*ROB_ENTRY_LOG2 )-1:0] rat_result_alias
  , input [(QUERY_PORT                )-1:0] rat_query_request
  , input [(QUERY_PORT*ARCH_ENTRY_LOG2)-1:0] rat_query_arch_id
  // Register Port
  , input                                    rat_register_remove
  , input                                    rat_register_request
  , input [             ARCH_ENTRY_LOG2-1:0] rat_register_arch_id
  , input [             ROB_ENTRY_LOG2 -1:0] rat_register_alias
  //
  , input                                    CLK
  , input                                    RSTN
);

reg [               1:0] rat_busy  [ARCH_ENTRY-1:0];
reg [ROB_ENTRY_LOG2-1:0] rat_alias [ARCH_ENTRY-1:0];

integer i;
genvar g;

//===============================================
// Query
//===============================================
generate
  begin : RAT_QUERY
    for (g=0; g<QUERY_PORT; g=g+1)
      begin : UNROLLED_QUERY
        assign rat_result_busy [g] = rat_query_request & (rat_busy[rat_query_arch_id[ARCH_ENTRY_LOG2*g+:ARCH_ENTRY_LOG2]]);
        assign rat_result_alias[ROB_ENTRY_LOG2*g+:ROB_ENTRY_LOG2] = rat_alias[rat_query_arch_id[ARCH_ENTRY_LOG2*g+:ARCH_ENTRY_LOG2]];
      end
  end
endgenerate

//===============================================
// Registry
//===============================================
always @(posedge CLK or negedge RSTN)
  begin : RAT_BUSY
    for (i=0; i<ARCH_ENTRY; i=i+1)
      begin : UNROLLED_BUSY
        if (~RSTN)
          rat_busy[i] <= 1'b0;
        else if (i == rat_register_arch_id)
          rat_busy[i] <= rat_register_request ? 1'b1 : rat_register_remove ? 1'b0 : rat_busy[i];
      end
  end

always @(posedge CLK or negedge RSTN)
  begin : RAT_ALIAS
    for (i=0; i<ARCH_ENTRY; i=i+1)
      begin : UNROLLED_ALIAS
        if (~RSTN)
          rat_alias[i] <= 1'b0;
        else if (i == rat_register_arch_id)
          rat_alias[i] <= rat_register_request ? rat_register_alias : rat_alias[i];
      end
  end

endmodule