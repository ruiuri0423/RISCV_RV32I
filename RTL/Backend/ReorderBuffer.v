module ReorderBuffer #(
   parameter ROB_ENTRY   = 4
  ,parameter ARCH_ENTRY  = 32
  ,parameter DATA_WIDTH  = 32
  //-----------------------
  ,parameter STATE_WIDTH     = 2
  ,parameter ROB_ENTRY_LOG2  = $clog2( ROB_ENTRY)
  ,parameter ARCH_ENTRY_LOG2 = $clog2(ARCH_ENTRY)
)( 
  // Reorder Buffer -> Arch. Register(to CDB)
   output [ARCH_ENTRY_LOG2-1:0] cdb_isr_arch_id    
  ,output [ ROB_ENTRY_LOG2-1:0] cdb_isr_id
  ,output [     DATA_WIDTH-1:0] cdb_isr_data           
  ,output                       cdb_isr_request
  , input                       cdb_isr_grant
  // Reorder Buffer -> Register Alias Table
  ,output                       rat_register_remove
  ,output                       rat_register_request
  ,output [ARCH_ENTRY_LOG2-1:0] rat_register_arch_id
  ,output [ ROB_ENTRY_LOG2-1:0] rat_register_alias
  // Reorder Buffer <-> Issuer
  ,output                       rob_grant
  ,output [ ROB_ENTRY_LOG2-1:0] rob_alias_id
  , input                       rob_request
  , input [ARCH_ENTRY_LOG2-1:0] rob_arch_id
  // Execution(from CDB) -> Reorder Buffer
  , input                       rob_write 
  , input [ ROB_ENTRY_LOG2-1:0] rob_id
  , input [     DATA_WIDTH-1:0] rob_data
  //
  , input    CLK
  , input    RSTN
);

parameter ISSUED    = 0;
parameter EXECUTED  = 1;
parameter WROTE     = 2;
parameter COMMITTED = 3;

reg                        rob_busy        [ROB_ENTRY-1:0];
reg  [    STATE_WIDTH-1:0] rob_state       [ROB_ENTRY-1:0];
reg  [     DATA_WIDTH-1:0] rob_value       [ROB_ENTRY-1:0];
reg  [ARCH_ENTRY_LOG2-1:0] rob_destination [ROB_ENTRY-1:0];
reg                        rob_exception   [ROB_ENTRY-1:0];

wire                       rob_request_accept;
wire                       rob_cdb_isr_accept;

wire                       rob_head_executed;
wire                       rob_head_wrote;
wire [ARCH_ENTRY_LOG2-1:0] rob_head_destination;
wire [     DATA_WIDTH-1:0] rob_head_data;

wire                       rob_tail_busy;
wire [ARCH_ENTRY_LOG2-1:0] rob_tail_destination;

wire                       rob_pointer_head_max;
wire                       rob_pointer_head_inc;
wire [ ROB_ENTRY_LOG2-1:0] rob_pointer_head_nxt;
reg  [ ROB_ENTRY_LOG2-1:0] rob_pointer_head;

wire                       rob_pointer_tail_max;
wire                       rob_pointer_tail_inc;
wire [ ROB_ENTRY_LOG2-1:0] rob_pointer_tail_nxt;
reg  [ ROB_ENTRY_LOG2-1:0] rob_pointer_tail;

//===============================================
// Reorder Buffer Control 
//===============================================
//-----------------------------------------------
// ROB <-> Issuer
assign rob_grant    = ~rob_tail_busy;
assign rob_alias_id = rob_pointer_tail;

//-----------------------------------------------
// ROB -> CDB
assign cdb_isr_id      = rob_pointer_head;
assign cdb_isr_arch_id = rob_head_destination;
assign cdb_isr_data    = rob_head_data;
assign cdb_isr_request = rob_head_executed;

//-----------------------------------------------
// ROB -> CDB
assign rat_register_remove  = rob_cdb_isr_accept;
assign rat_register_request = rob_request_accept;
assign rat_register_arch_id = rob_tail_destination;
assign rat_register_alias   = rob_pointer_tail; 

//-----------------------------------------------
// ROB inside control
assign rob_request_accept = rob_request & rob_grant;
assign rob_cdb_isr_accept = cdb_isr_request & cdb_isr_grant;

assign rob_head_executed    = rob_state      [rob_pointer_head] == EXECUTED;
assign rob_head_wrote       = rob_state      [rob_pointer_head] == WROTE;
assign rob_head_data        = rob_value      [rob_pointer_head];
assign rob_head_destination = rob_destination[rob_pointer_head]; 

assign rob_tail_busy        = rob_busy       [rob_pointer_tail];
assign rob_tail_destination = rob_destination[rob_pointer_tail];

assign rob_pointer_head_inc = rob_head_wrote;
assign rob_pointer_head_max = rob_pointer_head == ROB_ENTRY;
assign rob_pointer_head_nxt = rob_pointer_head_inc ? 
                              rob_pointer_head_max ? 'd0 : rob_pointer_head + 1'b1 : 
                                                           rob_pointer_head        ;

assign rob_pointer_tail_inc = rob_request_accept;
assign rob_pointer_tail_max = rob_pointer_tail == ROB_ENTRY;
assign rob_pointer_tail_nxt = rob_pointer_tail_inc ? 
                              rob_pointer_tail_max ? 'd0 : rob_pointer_tail + 1'b1 : 
                                                           rob_pointer_tail        ;

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      rob_pointer_head <= 'd0;
    else
      rob_pointer_head <= rob_pointer_head_nxt;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      rob_pointer_tail <= 'd0;
    else 
      rob_pointer_tail <= rob_pointer_tail_nxt;
  end
//-----------------------------------------------
//===============================================
// Reorder Buffer 
//===============================================
integer i;

always @(posedge CLK or negedge RSTN)
  begin : ROB_BUSY
    if (~RSTN)
      for (i=0; i<ROB_ENTRY; i=i+1)
        rob_busy[i] <= 1'b0;
    // Explicitly prevent from race condition.         
    else if (rob_pointer_head != rob_pointer_tail)
      begin
        rob_busy[rob_pointer_tail] <= rob_pointer_tail_inc ? 1'b1 : rob_busy[rob_pointer_tail];
        rob_busy[rob_pointer_head] <= rob_pointer_head_inc ? 1'b0 : rob_busy[rob_pointer_head];
      end
    else
      begin
        rob_busy[rob_pointer_head] <= rob_pointer_head_inc ? 1'b0 :
                                      rob_pointer_tail_inc ? 1'b1 : rob_busy[rob_pointer_head];
      end
  end

always @(posedge CLK or negedge RSTN)
  for (i=0; i<ROB_ENTRY; i=i+1)
    begin : ROB_STATE
      if (~RSTN)
        rob_state[i] <= COMMITTED;
      else
        case (rob_state[i])
        ISSUED    : 
          begin
            if (rob_write & (rob_id == i))
              rob_state[i] <= EXECUTED;
            else 
              rob_state[i] <= ISSUED;
          end
        EXECUTED  : 
          begin
            if (rob_cdb_isr_accept & (rob_pointer_head == i))
              rob_state[i] <= WROTE;
            else
              rob_state[i] <= EXECUTED;
          end
        WROTE     : 
          begin
              rob_state[i] <= COMMITTED;
          end
        COMMITTED : 
          begin
            if (rob_request_accept & (rob_pointer_tail == i))
              rob_state[i] <= ISSUED;
            else
              rob_state[i] <= COMMITTED;
          end
        endcase
    end

always @(posedge CLK or negedge RSTN)
  for (i=0; i<ROB_ENTRY; i=i+1)
    begin
      if (~RSTN)
        rob_value[i] <= 'd0;
      else if (rob_write & (rob_id == i))
        rob_value[i] <= rob_data;
    end

always @(posedge CLK or negedge RSTN)
  for (i=0; i<ROB_ENTRY; i=i+1)
    begin
      if (~RSTN)
        rob_destination[i] <= 'd0;
      else if (rob_request_accept & (rob_pointer_tail == i))
        rob_destination[i] <= rob_arch_id;
    end

endmodule