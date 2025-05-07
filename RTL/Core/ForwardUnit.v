module ForwardUnit (
      input [ 4:0] dec_rs2
    , input [ 4:0] dec_rs1

    , input        lsu_mem_en
    , input [ 3:0] lsu_mem_wen
    , input        lsu_mem_rvld
    , input [ 4:0] alu_rd
    , input        alu_rd_wen
    , input [31:0] alu_out
    , input [ 4:0] wb_rd       // lsu -> wb is combo.
    , input        wb_rd_wen   // lsu -> wb is combo.
    , input [31:0] wb_rd_data  // lsu -> wb is combo.
    
    ,output        nop_insert
    ,output [ 0:0] rs1_forward
    ,output [31:0] rs1_forward_data
    ,output [ 0:0] rs2_forward
    ,output [31:0] rs2_forward_data

    , input        CLK
    , input        RSTN
);

reg nop_insert_hold;

assign rs1_forward = (alu_rd == dec_rs1 && alu_rd_wen) | 
                     ( wb_rd == dec_rs1 &&  wb_rd_wen);

assign rs2_forward = (alu_rd == dec_rs2 && alu_rd_wen) | 
                     ( wb_rd == dec_rs2 &&  wb_rd_wen) ;

assign rs1_forward_data = (alu_rd == dec_rs1 && alu_rd_wen) ? alu_out    :
                          ( wb_rd == dec_rs1 &&  wb_rd_wen) ? wb_rd_data : 'd0;

assign rs2_forward_data = (alu_rd == dec_rs2 && alu_rd_wen) ? alu_out    :
                          ( wb_rd == dec_rs2 &&  wb_rd_wen) ? wb_rd_data : 'd0; 

// Hazard if rd is read from memory
assign nop_insert = lsu_mem_en & (~&lsu_mem_wen) & 
                    ((alu_rd == dec_rs1 && alu_rd_wen)  | 
                     (alu_rd == dec_rs2 && alu_rd_wen)) | 
                    (nop_insert_hold & ~lsu_mem_rvld);

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      nop_insert_hold <= 'd0;
    else if (lsu_mem_rvld)
      nop_insert_hold <= 'd0;
    else if (nop_insert)
      nop_insert_hold <= 'd1;
  end

endmodule