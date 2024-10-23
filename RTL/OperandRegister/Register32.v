module Register32(
   output reg [31:0] x31
  ,output reg [31:0] x30
  ,output reg [31:0] x29
  ,output reg [31:0] x28
  ,output reg [31:0] x27
  ,output reg [31:0] x26
  ,output reg [31:0] x25
  ,output reg [31:0] x24
  ,output reg [31:0] x23
  ,output reg [31:0] x22
  ,output reg [31:0] x21
  ,output reg [31:0] x20
  ,output reg [31:0] x19
  ,output reg [31:0] x18
  ,output reg [31:0] x17
  ,output reg [31:0] x16
  ,output reg [31:0] x15
  ,output reg [31:0] x14
  ,output reg [31:0] x13
  ,output reg [31:0] x12
  ,output reg [31:0] x11
  ,output reg [31:0] x10
  ,output reg [31:0] x09
  ,output reg [31:0] x08
  ,output reg [31:0] x07
  ,output reg [31:0] x06
  ,output reg [31:0] x05
  ,output reg [31:0] x04
  ,output reg [31:0] x03
  ,output reg [31:0] x02
  ,output reg [31:0] x01
  ,output reg [31:0] x00
  , input            x31_wen
  , input            x30_wen
  , input            x29_wen
  , input            x28_wen
  , input            x27_wen
  , input            x26_wen
  , input            x25_wen
  , input            x24_wen
  , input            x23_wen
  , input            x22_wen
  , input            x21_wen
  , input            x20_wen
  , input            x19_wen
  , input            x18_wen
  , input            x17_wen
  , input            x16_wen
  , input            x15_wen
  , input            x14_wen
  , input            x13_wen
  , input            x12_wen
  , input            x11_wen
  , input            x10_wen
  , input            x09_wen
  , input            x08_wen
  , input            x07_wen
  , input            x06_wen
  , input            x05_wen
  , input            x04_wen
  , input            x03_wen
  , input            x02_wen
  , input            x01_wen
  , input     [31:0] x_wdata
  , input            CLK
  , input            RSTN
);

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x00 <= 'd0;
    else
      x00 <= 'd0;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x01 <= 'd0;
    else if (w01_en)
      x01 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x02 <= 'd0;
    else if (w02_en)
      x02 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x03 <= 'd0;
    else if (w03_en)
      x03 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x04 <= 'd0;
    else if (w04_en)
      x04 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x05 <= 'd0;
    else if (w05_en)
      x05 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x06 <= 'd0;
    else if (w06_en)
      x06 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x07 <= 'd0;
    else if (w07_en)
      x07 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x08 <= 'd0;
    else if (w08_en)
      x08 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x09 <= 'd0;
    else if (w09_en)
      x09 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x10 <= 'd0;
    else if (w10_en)
      x10 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x11 <= 'd0;
    else if (w11_en)
      x11 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x12 <= 'd0;
    else if (w12_en)
      x12 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x13 <= 'd0;
    else if (w13_en)
      x13 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x14 <= 'd0;
    else if (w14_en)
      x14 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x15 <= 'd0;
    else if (w15_en)
      x15 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x16 <= 'd0;
    else if (w16_en)
      x16 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x17 <= 'd0;
    else if (w17_en)
      x17 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x18 <= 'd0;
    else if (w18_en)
      x18 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x19 <= 'd0;
    else if (w19_en)
      x19 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x20 <= 'd0;
    else if (w20_en)
      x20 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x21 <= 'd0;
    else if (w21_en)
      x21 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x22 <= 'd0;
    else if (w22_en)
      x22 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x23 <= 'd0;
    else if (w23_en)
      x23 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x24 <= 'd0;
    else if (w24_en)
      x24 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x25 <= 'd0;
    else if (w25_en)
      x25 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x26 <= 'd0;
    else if (w26_en)
      x26 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x27 <= 'd0;
    else if (w27_en)
      x27 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x28 <= 'd0;
    else if (w28_en)
      x28 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x29 <= 'd0;
    else if (w29_en)
      x29 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x30 <= 'd0;
    else if (w30_en)
      x30 <= x_data;
  end

always @(posedge CLK or negedge RSTN)
  begin
    if (~RSTN)
      x31 <= 'd0;
    else if (w31_en)
      x31 <= x_data;
  end

endmodule