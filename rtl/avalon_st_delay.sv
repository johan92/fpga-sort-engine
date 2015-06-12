module avalon_st_delay #(
  parameter DWIDTH = 8
)(
  input                     clk_i,
  input                     rst_i,

  input  logic [DWIDTH-1:0] in_data_i,
  input  logic              in_valid_i,
  output logic              in_ready_o,

  output logic [DWIDTH-1:0] out_data_o,
  output logic              out_valid_o,
  input  logic              out_ready_i

);

assign in_ready_o = ( !out_valid_o ) || out_ready_i;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      out_data_o  <= '0;
      out_valid_o <= 1'b0;
    end
  else
    if( in_ready_o )
      begin
        out_data_o  <= in_data_i;
        out_valid_o <= in_valid_i;
      end

endmodule
