import sort_tb::*;

module top_tb_advanced;

bit clk;
bit rst;
bit rst_done;

localparam AWIDTH = 6;
localparam DWIDTH = 8;

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) pkt_i ( clk );

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) pkt_o ( clk );
  
typedef sort_trans_t #( .DWIDTH( DWIDTH ),  .MAX_TRANS_SIZE( 2**AWIDTH ) ) __sort_trans_t;

initial
  begin
    clk = 1'b0;
    forever
      begin
        #5ns clk = !clk;
      end
  end

initial
  begin
    rst      <= 1'b1;

    @( negedge clk );
    rst      <= 1'b0;
    rst_done <= 1'b1;
  end

sort_engine_with_merge #( 
  .AWIDTH                                 ( AWIDTH            ),
  .DWIDTH                                 ( DWIDTH            ),
  .ENGINE_CNT                             ( 4                 )
) seom (
  .clk_i                                  ( clk               ),
  .rst_i                                  ( rst               ),

  .pkt_i                                  ( pkt_i             ),
  .pkt_o                                  ( pkt_o             )
);

initial
  begin
    SortEnvironment #( __sort_trans_t ) env = new();
    env.build( pkt_i, pkt_o );
    
    wait( rst_done );
    @( posedge clk );
    @( posedge clk );
    
    // starting test
    env.run();
  end

endmodule
