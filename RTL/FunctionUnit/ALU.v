module ALU #(
   parameter ROB_ENTRY      = 4
  ,parameter DATA_WIDTH     = 32
  ,parameter RSV_Q_WIDTH    = 
  ,parameter OPERATOR_TYPES = $clog2(10)
)(
  // Common Data Bus
  ,output                       cdb_isr_request
  ,output [     DATA_WIDTH-1:0] cdb_isr_data
  ,output [ ROB_ENTRY_LOG2-1:0] cdb_isr_id
  , input                       cdb_isr_grant
  // Issuer / Reservation Station
  ,output                       sync_q_ren
  , input                       sync_q_rok
  , input [    RSV_Q_WIDTH-1:0] sync_q_rdata
  //
  , input                       CLK
  , input                       RSTN
);


//===============================================
// ALU Control
//===============================================
//---
//
// T+0: Data is fetched from sync. queue.
// T+1: Data is available to write to the ROB 
//      through the common data bus. 
//---
//
// Stall Condtion:
//   CDB request is contention with another issuer.
//
//===============================================
wire                     sync_q_hsk;
wire                     cdb_isr_hsk;

reg                      alu_cdb_request;
reg [    DATA_WIDTH-1:0] alu_cdb_data;
reg [ROB_ENTRY_LOG2-1:0] alu_cdb_id;


always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      alu_cdb_request <= 'd0;
    else if (cdb_isr_hsk)
      alu_cdb_request <= 'd0;
    else if (sync_q_hsk)
      alu_cdb_request <= 'd1;
  end

assign sync_q_hsk = sync_q_ren & sync_q_rok;
assign sync_q_ren = sync_q_rok & (cdb_isr_hsk | ~alu_cdb_request);

assign cdb_isr_hsk     = cdb_isr_request & cdb_isr_grant;
assign cdb_isr_request = alu_cdb_request;
assign cdb_isr_data    = alu_cdb_data;
assign cdb_isr_id      = alu_cdb_id;

//===============================================
// ALU Data
//===============================================
// Parameters (Begin)
// Operater
// ALU
parameter [OPERATOR_TYPES-1:0] ADD    = 'd0;
parameter [OPERATOR_TYPES-1:0] SUB    = 'd1;
parameter [OPERATOR_TYPES-1:0] LT     = 'd2;
parameter [OPERATOR_TYPES-1:0] LTU    = 'd3;
parameter [OPERATOR_TYPES-1:0] AND    = 'd4;
parameter [OPERATOR_TYPES-1:0] OR     = 'd5;
parameter [OPERATOR_TYPES-1:0] XOR    = 'd6;
parameter [OPERATOR_TYPES-1:0] SLL    = 'd7;
parameter [OPERATOR_TYPES-1:0] SRL    = 'd8;
parameter [OPERATOR_TYPES-1:0] SRA    = 'd9;
// Parameters (End)

// Data connection (Begin)
wire [OPERATOR_TYPES-1:0] alu_operation = sync_q_rdata[];
wire [    DATA_WIDTH-1:0] alu_operand_1 = sync_q_rdata[];
wire [    DATA_WIDTH-1:0] alu_operand_2 = sync_q_rdata[];
wire [    DATA_WIDTH-1:0] alu_result    = sync_q_rdata[];
wire [ROB_ENTRY_LOG2-1:0] alu_rob_entry = sync_q_rdata[];
// Data connection (End)

wire is_ADD = alu_operation == ADD;    
wire is_SUB = alu_operation == SUB;    
wire is_LT  = alu_operation == LT;     
wire is_LTU = alu_operation == LTU;    
wire is_AND = alu_operation == AND;    
wire is_OR  = alu_operation == OR;     
wire is_XOR = alu_operation == XOR;    
wire is_SLL = alu_operation == SLL;    
wire is_SRL = alu_operation == SRL;    
wire is_SRA = alu_operation == SRA;    

assign alu_result = 
  is_ADD ? ADD(alu_operand_1, alu_operand_2) :
  is_SUB ? SUB(alu_operand_1, alu_operand_2) :
  is_AND ? AND(alu_operand_1, alu_operand_2) :
  is_OR  ? OR (alu_operand_1, alu_operand_2) :
  is_XOR ? XOR(alu_operand_1, alu_operand_2) :
  is_SLL ? SLL(alu_operand_1, alu_operand_2) :
  is_SRL ? SRL(alu_operand_1, alu_operand_2) :
  is_SRA ? SRA(alu_operand_1, alu_operand_2) :
  is_LT  ? LT (alu_operand_1, alu_operand_2) :
  is_LTU ? LTU(alu_operand_1, alu_operand_2) : 'd0;

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      begin
        alu_cdb_data <= 'd0;
        alu_cdb_id   <= 'd0;
      end
    else if (sync_q_hsk)
      begin
        alu_cdb_data <= alu_result;
        alu_cdb_id   <= alu_rob_entry;
      end
  end

endmodule