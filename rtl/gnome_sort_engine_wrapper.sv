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
    run_sort <= pkt_i.val && pkt_i.eop;

logic              rd_req;  
logic              rd_req_d1;  
logic              rd_last_word_w;
logic              done_w;
logic [DWIDTH-1:0] rd_data_w;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_i.busy <= 1'b0;
  else
    if( pkt_i.eop && pkt_i.val )
      pkt_i.busy <= 1'b1;
    else
      if( pkt_o.eop && pkt_o.val )
        pkt_i.busy <= 1'b0;

logic sort_engine_srst;

assign sort_engine_srst = pkt_o.eop && pkt_o.val;

gnome_sort_engine #( 
  .AWIDTH                                 ( AWIDTH            ), 
  .DWIDTH                                 ( DWIDTH            ) 
) gse (
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),
    
  .srst_i                                 ( sort_engine_srst  ), 

  .run_i                                  ( run_sort          ),

  .wr_req_i                               ( pkt_i.val         ),
  .wr_data_i                              ( pkt_i.data        ),

  .rd_req_i                               ( rd_req            ), 
  .rd_data_o                              ( rd_data_w         ),
  .rd_last_word_o                         ( rd_last_word_w    ),

  .done_o                                 ( done_w            )

);

assign rd_req = done_w && ( !rd_last_word_w );

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    rd_req_d1 <= 1'b0;
  else
    rd_req_d1 <= rd_req;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      pkt_o.sop <= 1'b0;
      pkt_o.val <= 1'b0;
    end
  else
    begin
      if( rd_req && !rd_req_d1 )
        begin
          pkt_o.sop <= 1'b1;
          pkt_o.val <= 1'b1;
        end

      if( pkt_o.sop )
        pkt_o.sop <= 1'b0;

      if( rd_last_word_w )
        pkt_o.val <= 1'b0;
    end

assign pkt_o.eop  = rd_last_word_w;
assign pkt_o.data = rd_data_w;

endmodule
