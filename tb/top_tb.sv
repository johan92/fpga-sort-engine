module top_tb;

logic clk;
logic rst;

localparam AWIDTH = 6;
localparam DWIDTH = 8;

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) pkt_i ( clk );

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) pkt_o ( clk );

typedef enum { 
               RANDOM,
               INCREASING,
               DECREASING,
               CONSTANT
             } sort_trans_t;

typedef bit[DWIDTH-1:0] trans_data_t[$];

clocking cb @( posedge clk );
endclocking

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
    rst <= 1'b1;
    @( negedge clk );
    rst <= 1'b0;
  end
/*
gnome_sort_engine_wrapper #( 
  .AWIDTH                                 ( AWIDTH         ),
  .DWIDTH                                 ( DWIDTH         )
) gsewp (
  .clk_i                                  ( clk            ),
  .rst_i                                  ( rst            ),

  .pkt_i                                  ( pkt_i          ),
  .pkt_o                                  ( pkt_o          )
);
*/

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
    pkt_o.ready <= 1'b0;

    forever
      begin
        @cb;
        pkt_o.ready <= 1'b1; //$urandom() % 2;
      end

  end

bit [DWIDTH-1:0] prev_out_data;

always_ff @( posedge clk )
  // clear after each output transation 
  if( pkt_o.eop && pkt_o.val )
    prev_out_data <= '0;
  else
    if( pkt_o.val && pkt_o.ready )
      prev_out_data <= pkt_o.data;

initial
  begin
    forever
      begin
        @cb;
        // checks that new data in transaction
        // not smaller than previous
        if( pkt_o.val && pkt_o.ready )
          assert( prev_out_data <= pkt_o.data );
      end
  end

initial
  begin
    pkt_i.sop  = '0;
    pkt_i.eop  = '0;
    pkt_i.data = '0;
    pkt_i.val  = '0;
  end

task send_transaction( trans_data_t data );
  wait( pkt_i.ready == 1'b1 )
  
  for( int i = 0; i < data.size(); i++ ) begin
    pkt_i.val  <= 1'b1;
    pkt_i.data <= data[i];
    pkt_i.sop  <= ( i == ( 0               ) ); 
    pkt_i.eop  <= ( i == ( data.size() - 1 ) );
    @( posedge pkt_i.clk );
   end

   pkt_i.sop <= 1'b0;
   pkt_i.val <= 1'b0;
   pkt_i.eop <= 1'b0;
   @( posedge pkt_i.clk );
endtask

function trans_data_t gen_transaction( int size, sort_trans_t trans_type );
  trans_data_t res;
  res = {};
  
  for( int i = 0; i < size; i++ ) begin

    case( trans_type )
      RANDOM: 
        begin
          res.push_back( $urandom() );
        end

      INCREASING:
        begin
          res.push_back( i );
        end

      DECREASING:
        begin
          res.push_back( size - i - 1 );
        end

      CONSTANT:
        begin
          if( i == 0 ) begin
            res.push_back( $urandom() );
          end else begin
            res.push_back( res[0] );
          end
        end
    endcase

  end
    
  return res;

endfunction

mailbox #( trans_data_t ) in_fifo;
mailbox #( trans_data_t ) in_fifo_ref;

task create_transaction( int size, sort_trans_t trans_type );
  trans_data_t trans;
  
  trans = gen_transaction( size, trans_type );
  
  assert( trans.size() == size );

  in_fifo.put( trans );
  
  trans.sort();
  in_fifo_ref.put( trans );
endtask

task transaction_monitor( output trans_data_t trans );
  trans = {};

  // $display("transaction_monitor: started");

  forever
    begin
      // FIXME: dirty hack
      @( negedge clk );
      
      // $display("%t: val = %d ready = %d eop = %d", $time(), pkt_o.val, pkt_o.ready, pkt_o.eop );

      if( pkt_o.val && pkt_o.ready )
        begin
          trans.push_back( pkt_o.data );
          $display("pushed: %h", pkt_o.data );
        end 

      if( pkt_o.val && pkt_o.ready && pkt_o.eop )
        break;
    end

  // $display("transaction_monitor: ended");
endtask

task transaction_checker( );
  trans_data_t ref_trans;
  trans_data_t out_trans;

  forever
    begin
      transaction_monitor( out_trans );
      in_fifo_ref.get( ref_trans );

      if( out_trans != ref_trans )
        begin
          $error( "Transactions didn't match!" );
          $display("    DUT REF");
          for( int i = 0; i < out_trans.size(); i++ )
            begin
              $display("%3d: %02h %02h", i, out_trans[i], ref_trans[i] );
            end
          $stop();
        end
      else
        begin
          $info( "Transcations match!" );
        end
    end
endtask

initial
  begin
    transaction_checker( );
  end

initial
  begin
    in_fifo     = new( );
    in_fifo_ref = new( );

    create_transaction( 15, RANDOM );
    create_transaction( 1, RANDOM );
    create_transaction( 2, RANDOM );
    create_transaction( 4, RANDOM );
    create_transaction( 4, DECREASING );

    create_transaction( 5, RANDOM );

    create_transaction( 2**AWIDTH-1, RANDOM );

    create_transaction( 2**AWIDTH, RANDOM );
    create_transaction( 2**AWIDTH, INCREASING );
    create_transaction( 2**AWIDTH, RANDOM );
    create_transaction( 2**AWIDTH, DECREASING );
    create_transaction( 2**AWIDTH, CONSTANT );

    for( int i = 0; i < 100; i++ )
      begin
        create_transaction( $urandom_range( 1, 2**AWIDTH ), RANDOM );
      end
  end

trans_data_t trans_to_dut;

initial
  begin
    @cb;
    forever
      begin
        @cb;
        if( in_fifo.num() > 0 ) 
          begin
            in_fifo.get( trans_to_dut ); 
            send_transaction( trans_to_dut );
          end
      end
  end
endmodule
