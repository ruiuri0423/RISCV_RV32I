module Parameterized_RR_Arbiter #(
   parameter USER      = 4
  ,parameter USER_LOG2 = $clog2(USER)
)(
   output [USER          -1:0] grant
  ,output [USER_LOG2     -1:0] grant_user
  , input [USER          -1:0] request
  , input [USER*USER_LOG2-1:0] priority_
  , input                      CLK
  , input                      RSTN
);
  
  integer i;
  genvar  g;

  reg  [USER*USER_LOG2-1:0] prior_set;
  wire [     USER_LOG2-1:0] current_user;
  wire [     USER_LOG2-1:0] shift_user;

  assign grant_user = current_user;
  
  generate
    begin : COMBO
      wire [USER_LOG2-1:0] mux_shift_user   [USER-1:0];
      wire [USER_LOG2-1:0] mux_current_user [USER-1:0];

      assign shift_user = mux_shift_user[0];
      assign mux_shift_user[USER-1] = 0;

      for (g=0; g<(USER-1); g=g+1)
        begin : SHIFT_MUX
          assign mux_shift_user[g] = request[prior_set[USER_LOG2*g+:USER_LOG2]] ? (g+1) : mux_shift_user[g+1];
        end

      assign current_user = mux_current_user[0];
      assign mux_current_user[USER-1] = request[prior_set[USER_LOG2*(USER-1)+:USER_LOG2]] ? prior_set[USER_LOG2*(USER-1)+:USER_LOG2] : 0;

      for (g=0; g<(USER-1); g=g+1)
        begin : CURRENT_MUX
          assign mux_current_user[g] = request[prior_set[USER_LOG2*g+:USER_LOG2]] ? prior_set[USER_LOG2*g+:USER_LOG2] : mux_current_user[g+1];
        end

      for (g=0; g<USER; g=g+1)
        begin : GRANT_LOGIC
          assign grant[g] = (g == current_user) & request[current_user];
        end
    end
  endgenerate

  always @(posedge CLK or negedge RSTN)
    begin
      if(~RSTN)
        prior_set <= priority_;
      else if (~|request)
	      prior_set <= priority_;
      else
        prior_set <= {prior_set, prior_set} >> (USER_LOG2 * shift_user);
    end

endmodule