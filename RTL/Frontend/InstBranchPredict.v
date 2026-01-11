module InstBranchPredict #(
     parameter ADDR_WIDTH = 32
    ,parameter BHT_DEPTH  = 16
    ,parameter BHT_WIDTH  = 4
    ,parameter BTB_DEPTH  = 1023
    ,parameter BTB_WIDTH  = 10 
    ,parameter TAG_WIDTH  = 22 // BTB tag widht
    ,parameter RAS_DEPTH  = 4
    ,parameter RAS_WIDTH  = 2
)(  
     output wire                  bp_taken
    ,output wire [ADDR_WIDTH-1:0] bp_pc
    // From inst_fetch
    , input wire                  inst_valid
    , input wire [ADDR_WIDTH-1:0] inst_pc
    // From Pre-Decoder
    , input wire                  pdec_branch
    , input wire                  pdec_jal
    , input wire                  pdec_jalr
    , input wire                  pdec_ret 
    , input wire                  pdec_call
    , input wire [ADDR_WIDTH-1:0] pdec_pc
    // From BPU
    , input wire                  bpu_valid
    , input wire                  bpu_flush
    , input wire [ADDR_WIDTH-1:0] bpu_target
    , input wire                  bpu_taken
    , input wire                  bpu_call
    , input wire                  bpu_ret
    , input wire [ADDR_WIDTH-1:0] bpu_pc
    // 
    , input wire                  CLK
    , input wire                  RSTN
);

integer i;

parameter [1:0] STRONGLY_TAKEN     = 2'b11;
parameter [1:0] WEAKLY_TAKEN       = 2'b10;
parameter [1:0] WEAKLY_NOT_TAKEN   = 2'b01;
parameter [1:0] STRONGLY_NOT_TAKEN = 2'b00;

//===============================================
// Branch History Table (BHT)
//===============================================
reg  [BHT_WIDTH-1:0] bht_queue;
reg  [BHT_WIDTH-1:0] bht_queue_spec; // speculative queue
reg  [          1:0] bht_counter [BHT_DEPTH-1:0]; // 2-bit saturate counter

// Counter index : gshare
wire [BHT_WIDTH-1:0] bht_bpu_idx = bht_queue      ^ bpu_pc [BTB_WIDTH+:BHT_WIDTH];
wire [BHT_WIDTH-1:0] bht_pc_idx  = bht_queue_spec ^ inst_pc[BTB_WIDTH+:BHT_WIDTH];

// Speculative taken
wire pc_taken;
wire pc_n_taken;

always @(posedge CLK or negedge RSTN)
  begin : BHT_QUEUE;
    if (~RSTN)
      bht_queue <= 'd0;
    else if (bpu_valid)
      bht_queue <= {bht_queue[BHT_WIDTH-2:0], bpu_taken};
  end

always @(posedge CLK or negedge RSTN)
  begin : BHT_QUEUE_SPEC;
    if (~RSTN)
      bht_queue_spec <= 'd0;
    else if (bpu_flush) // flush the speculative queue if misprediction.
      bht_queue_spec <= {bht_queue[BHT_WIDTH-2:0], bpu_taken};
    else if (pc_taken || pc_n_taken)
      bht_queue_spec <= {bht_queue_spec[BHT_WIDTH-2:0], pc_taken};
  end

always @(posedge CLK or negedge RSTN)
  begin : BHT_COUNTER;
    if (~RSTN)
      begin
        for (i=0; i<BHT_DEPTH; i=i+1)
          bht_counter[i] <= STRONGLY_TAKEN; 
      end
    else if (bpu_valid)
      begin
        case (bht_counter[bht_bpu_idx])
          STRONGLY_TAKEN : 
            if (~bpu_taken) 
              bht_counter[bht_bpu_idx] <= WEAKLY_TAKEN;

          WEAKLY_TAKEN : 
            if (~bpu_taken) 
              bht_counter[bht_bpu_idx] <= STRONGLY_NOT_TAKEN;
            else            
              bht_counter[bht_bpu_idx] <= STRONGLY_TAKEN;

          WEAKLY_NOT_TAKEN : 
            if (bpu_taken) 
              bht_counter[bht_bpu_idx] <= STRONGLY_TAKEN;
            else            
              bht_counter[bht_bpu_idx] <= STRONGLY_NOT_TAKEN;

          STRONGLY_NOT_TAKEN : 
            if (bpu_taken) 
              bht_counter[bht_bpu_idx] <= WEAKLY_NOT_TAKEN;
        endcase
      end
  end

//===============================================
// Return Adress Stack (RAS)
//===============================================
reg  [ADDR_WIDTH:0] ras_stack      [RAS_DEPTH-1:0];
reg  [ADDR_WIDTH:0] ras_stack_spec [RAS_DEPTH-1:0]; // speculative queue
wire                pc_call; 
wire                pc_return;
wire                pdec_return;

always @(posedge CLK or negedge RSTN)
  begin : RAS_STACK
    if (~RSTN)
      for (i=0; i<RAS_DEPTH; i=i+1)
        ras_stack[i] <= 'd0;
    else if (bpu_valid)
      begin
        if (bpu_call & ~bpu_ret) // push
          begin
            ras_stack[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (bpu_pc + 3'd4);
            ras_stack[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1; // stack data is valid
            for (i=0; i<RAS_DEPTH-1; i=i+1)
              begin
                ras_stack[i] <= ras_stack[i+1];   
              end
          end
        else if (~bpu_call & bpu_ret) // pop
          begin
            ras_stack[0] <= 'd0;
            for (i=1; i<RAS_DEPTH; i=i+1)
              ras_stack[i] <= ras_stack[i-1];   
          end
        else if (bpu_call & bpu_ret) // pop then push
          begin
            ras_stack[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (bpu_pc + 3'd4);
            ras_stack[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1; // stack data is valid
          end
      end
  end

always @(posedge CLK or negedge RSTN)
  begin : RAS_STACK_SPEC
    if (~RSTN)
      for (i=0; i<RAS_DEPTH; i=i+1)
        ras_stack_spec[i] <= 'd0;
    else if (bpu_flush) // miss predict
      begin
        if (bpu_call & ~bpu_ret) // push
          begin
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (bpu_pc + 3'd4);
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1; // stack data is valid
            for (i=0; i<RAS_DEPTH-1; i=i+1)
              ras_stack_spec[i] <= ras_stack[i+1];   
          end
        else if (~bpu_call & bpu_ret) // pop
          begin
            ras_stack_spec[0] <= 'd0;
            for (i=1; i<RAS_DEPTH; i=i+1)
              ras_stack_spec[i] <= ras_stack[i-1];   
          end
        else if (bpu_call & bpu_ret) // pop then push
          begin
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (bpu_pc + 3'd4);
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1; // stack data is valid
            for (i=1; i<RAS_DEPTH; i=i+1)
              ras_stack_spec[i] <= ras_stack[i];   
          end
        else // not a call or return
          begin
            for (i=0; i<RAS_DEPTH; i=i+1)
              ras_stack_spec[i] <= ras_stack[i];   
          end
      end
    else if (inst_valid)// speculative
      begin
        if (pc_call & ~pc_return) // push
          begin
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (inst_pc + 3'd4);
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1;
            for (i=0; i<RAS_DEPTH-1; i=i+1)
              begin
                ras_stack_spec[i] <= ras_stack_spec[i+1];   
              end
          end
        else if (~pc_call & pc_return) // pop
          begin
            ras_stack_spec[0] <= 'd0;
            for (i=1; i<RAS_DEPTH; i=i+1)
              ras_stack_spec[i] <= ras_stack_spec[i-1];   
          end
        else if (pc_call & pc_return)
          begin
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (inst_pc + 3'd4);
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1;  
          end
        else if (pdec_call) // push, lower priority
          begin
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0] <= (inst_pc + 3'd4);
            ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH    ] <= 1'b1;
            for (i=0; i<RAS_DEPTH-1; i=i+1)
              begin
                ras_stack_spec[i] <= ras_stack_spec[i+1];   
              end
          end
        else if (pdec_return) // pop, lower priority
          begin
            ras_stack_spec[0] <= 'd0;
            for (i=1; i<RAS_DEPTH; i=i+1)
              ras_stack_spec[i] <= ras_stack_spec[i-1];   
          end
      end
  end

//===============================================
// Branch Target Buffer (BTB)
//===============================================
reg                  btb_valid  [BTB_DEPTH-1:0];
reg                  btb_call   [BTB_DEPTH-1:0];
reg                  btb_return [BTB_DEPTH-1:0];
reg [ TAG_WIDTH-1:0] btb_tag    [BTB_DEPTH-1:0];
reg [ADDR_WIDTH-1:0] btb_target [BTB_DEPTH-1:0];

assign tag_match   = btb_tag   [inst_pc[0+:BTB_WIDTH]] == inst_pc[BTB_WIDTH+:TAG_WIDTH]; 
assign tag_valid   = btb_valid [inst_pc[0+:BTB_WIDTH]] & tag_match;

assign pc_call     = btb_call  [inst_pc[0+:BTB_WIDTH]] & tag_valid;
assign pc_return   = btb_return[inst_pc[0+:BTB_WIDTH]] & tag_valid & ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH];
assign pdec_return = pdec_jalr & pdec_ret & ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH];
assign pdec_taken  = pdec_branch | pdec_jal | pdec_call;

assign pc_taken    =  (((bht_counter[bht_pc_idx][1] & tag_valid) | pc_call | pc_return) | pdec_taken | pdec_return) & inst_valid;
assign pc_n_taken  = ~(((bht_counter[bht_pc_idx][1] & tag_valid) | pc_call | pc_return) | pdec_taken | pdec_return) & inst_valid;

assign bp_taken    = pc_taken;
assign bp_pc       = pc_return   ? ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0]  : 
                     pc_taken    ? btb_target[inst_pc[0+:BTB_WIDTH]] :
                     pdec_return ? ras_stack_spec[RAS_DEPTH-1][ADDR_WIDTH-1:0]  :
                     pdec_taken  ? pdec_pc : 'd0;

always @(posedge CLK or negedge RSTN)
  begin : BTB_VALID
    if (~RSTN)
      for (i=0; i<BTB_DEPTH; i=i+1)
        btb_valid[i] <= 'd0;
    else if (bpu_valid)
        btb_valid[bpu_pc[0+:BTB_WIDTH]] <= 1'b1;
  end

always @(posedge CLK or negedge RSTN)
  begin : BTB_CALL
    if (~RSTN)
      for (i=0; i<BTB_DEPTH; i=i+1)
        btb_call[i] <= 'd0;
    else if (bpu_valid)
        btb_call[bpu_pc[0+:BTB_WIDTH]] <= bpu_call;
  end

always @(posedge CLK or negedge RSTN)
  begin : BTB_RETURN
    if (~RSTN)
      for (i=0; i<BTB_DEPTH; i=i+1)
        btb_return[i] <= 'd0;
    else if (bpu_valid)
        btb_return[bpu_pc[0+:BTB_WIDTH]] <= bpu_ret;
  end

always @(posedge CLK or negedge RSTN)
  begin : BTB_TAG
    if (~RSTN)
      for (i=0; i<BTB_DEPTH; i=i+1)
        btb_tag[i] <= 'd0;
    else if (bpu_valid)
        btb_tag[bpu_pc[0+:BTB_WIDTH]] <= bpu_pc[BTB_WIDTH+:TAG_WIDTH];
  end

always @(posedge CLK or negedge RSTN)
  begin : BTB_TARGET
    if (~RSTN)
      for (i=0; i<BTB_DEPTH; i=i+1)
        btb_target[i] <= 'd0;
    else if (bpu_valid)
        btb_target[bpu_pc[0+:BTB_WIDTH]] <= bpu_target;
  end

endmodule