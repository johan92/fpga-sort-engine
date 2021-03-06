module top #( 
  parameter AWIDTH = 10,
  parameter DWIDTH = 32
)
( 
  input               clk_i,
  input               rst_i,

  input  [DWIDTH-1:0] data_i,
  input               sop_i,
  input               eop_i,
  input               val_i,
  output              ready_o,

  output [DWIDTH-1:0] data_o,
  output              sop_o,
  output              eop_o,
  output              val_o,
  input               ready_i

);

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) pkt_in ( clk_i );

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) pkt_out ( clk_i );

// trigger for Fmax testing
always_ff @( posedge clk_i )
  begin
    pkt_in.data <= data_i; 
    pkt_in.sop  <= sop_i;
    pkt_in.eop  <= eop_i;
    pkt_in.val  <= val_i;
    ready_o     <= pkt_in.ready;
  end

always_ff @( posedge clk_i )
  begin
    data_o <= pkt_out.data;
    sop_o  <= pkt_out.sop; 
    eop_o  <= pkt_out.eop; 
    val_o  <= pkt_out.val;
    pkt_out.ready <= ready_i;
  end

/*
gnome_sort_engine_wrapper #( 
  .AWIDTH                                 ( AWIDTH            ),
  .DWIDTH                                 ( DWIDTH            )
) gsewp (
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),

  .pkt_i                                  ( pkt_in            ),
  .pkt_o                                  ( pkt_out           )
);
*/

sort_engine_with_merge #( 
  .AWIDTH     ( AWIDTH ),
  .DWIDTH     ( DWIDTH ),

  .ENGINE_CNT ( 4      )
) sewm (
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),

  .pkt_i                                  ( pkt_in            ),
  .pkt_o                                  ( pkt_out           )

);

endmodule
