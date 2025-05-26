module InstPreDecoder #(
   parameter ADDR_WIDTH = 32
)(
  // output
   output wire                  pdec_branch
  ,output wire                  pdec_jal
  ,output wire                  pdec_jalr
  ,output reg                   pdec_call
  ,output reg                   pdec_ret
  ,output wire [ADDR_WIDTH-1:0] pdec_pc
  // input
  , input wire                  inst_valid
  , input wire [ADDR_WIDTH-1:0] inst_pc
  , input wire [ADDR_WIDTH-1:0] inst
);

wire [ 6:0] opcode = inst_valid & inst[ 6: 0];
wire [ 4:0] rd     = inst_valid & inst[11: 7];
wire [ 4:0] rs1    = inst_valid & inst[19:15];

reg  [ADDR_WIDTH-1:0] pdec_imm;

// Branch / Direct Jump Extract
assign pdec_branch = opcode == `INST_BRANCH;
assign pdec_jal    = opcode == `INST_JAL   ;
assign pdec_jalr   = opcode == `INST_JALR  ;
assign pdec_pc     = pdec_imm + inst_pc;

always @(*)
  begin
    pdec_imm = 'd0;
    case(1'b1)
      pdec_branch : pdec_imm = `B_TYPE_IMM(inst);
      pdec_jal    : pdec_imm = `J_TYPE_IMM(inst);
      pdec_jalr   : pdec_imm = `I_TYPE_IMM(inst);
    endcase
  end

always @(*)
  begin
    pdec_call = 'd0;
    pdec_ret  = 'd0;
    case(1'b1)
      pdec_jal  :  
        begin
          pdec_call = (rd == 5'd1) || (rd == 5'd5);
        end
      pdec_jalr :  
        begin
          pdec_ret  = (((rd != 5'd1) && (rd != 5'd5)) && ((rs1 == 5'd1) || (rs1 == 5'd5)));
        end
    endcase
  end

endmodule