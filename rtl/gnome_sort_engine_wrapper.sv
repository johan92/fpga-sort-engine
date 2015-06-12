module gnome_sort_engine_wrapper #( 
  parameter AWIDTH = 5,
  parameter DWIDTH = 8
)
(
  input                  clk_i,
  input                  rst_i,

  sort_engine_if.slave   pkt_i,
  sort_engine_if.master  pkt_o

);

logic run_sort;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    run_sort <= 1'b0;
  else
    run_sort <= pkt_i.val && pkt_i.eop && pkt_i.ready;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_i.ready <= 1'b1;
  else
    if( pkt_i.eop && pkt_i.val )
      pkt_i.ready <= 1'b0;
    else
      if( pkt_o.eop && pkt_o.val && pkt_o.ready ) 
        pkt_i.ready <= 1'b1;

logic sort_engine_srst;

assign sort_engine_srst = pkt_o.eop && pkt_o.val && pkt_o.ready;

gnome_sort_engine #( 
  .AWIDTH                                 ( AWIDTH            ), 
  .DWIDTH                                 ( DWIDTH            ) 
) gse (
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),
    
  .srst_i                                 ( sort_engine_srst  ), 

  .run_i                                  ( run_sort          ),

  .wr_req_i                               ( pkt_i.val && pkt_i.ready ),
  .wr_data_i                              ( pkt_i.data        ),

  .out_ready_i                            ( pkt_o.ready       ), 
  .out_data_o                             ( pkt_o.data        ),
  .out_valid_o                            ( pkt_o.val         ),
  .out_sop_o                              ( pkt_o.sop         ),
  .out_eop_o                              ( pkt_o.eop         )

);

endmodule
