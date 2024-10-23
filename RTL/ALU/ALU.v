module ADD (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);
  
assign dout =  din1 + din2;

endmodule

//module SLT 
//module SLTU 

module AND (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

assign dout = din1 & din2;

endmodule

module OR (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

assign dout = din1 | din2;

endmodule

module XOR (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

assign dout = din1 ^ din2;

endmodule

module SLL (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

assign dout = din1 << din2[4:0];

endmodule

module SRL (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

assign dout = din1 >> din2[4:0];

endmodule

module SRA (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

wire [62:0] ext_din1 = {{31{din1[31]}}, din1};
wire [62:0] ext_shf1 = ext_din1 >> din2[4:0]; 

assign dout = ext_shf1[31:0];

endmodule

module SUB (
   output [31:0] dout
  , input [31:0] din1
  , input [31:0] din2
);

assign dout = din1 - din2;

endmodule

module PC_NXT (
   output [31:0] pc_o
  , input [31:0] pc_i
);

  assign dout = din1 + 3'd4; 

endmodule


module EQ (
   output        dout
  , input [31:0] din1
  , input [31:0] din2
);

  assign dout = din1 == din2;

endmodule

module NE (
   output        dout
  , input [31:0] din1
  , input [31:0] din2
);

  assign dout = din != din2;

endmodule

module LT (
   output        dout
  , input [31:0] din1
  , input [31:0] din2
);
  wire lt0  =  din1[31] & ~din2[31];
  wire lt1  =  din1[31] &  din2[31];
  wire lt2  = ~din1[31] & ~din2[31];
  wire lt3  =  din1     <  din2;

  assign dout = lt0 | (lt1 | lt2 & lt3);

endmodule

module LTU (
   output        dout
  , input [31:0] din1
  , input [31:0] din2
);

  assign dout = din1 <= din2;

endmodule

module GT (
   output        dout
  , input [31:0] din1
  , input [31:0] din2
);

  wire lt0  = ~din1[31] &  din2[31];
  wire lt1  =  din1[31] &  din2[31];
  wire lt2  = ~din1[31] & ~din2[31];
  wire lt3  =  din1     >  din2;

  assign dout = lt0 | (lt1 | lt2 & lt3);

endmodule

module GTU (
   output        dout
  , input [31:0] din1
  , input [31:0] din2
);

  assign dout = din1 >= din2;

endmodule

module ASSIGN (
   output [31:0] dout
  , input [31:0] din1
);

  assign dout = din1;

endmodule