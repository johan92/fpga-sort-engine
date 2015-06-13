module top_tb;

`include "sort_trans.sv"

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

typedef sort_trans_t #( .DWIDTH( DWIDTH ),  .MAX_TRANS_SIZE( 2**AWIDTH ) ) __sort_trans_t;

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
        //pkt_o.ready <= 1'b1; //$urandom() % 2;
        pkt_o.ready <= $urandom() % 2;
      end

  end

initial
  begin
    pkt_i.sop  = '0;
    pkt_i.eop  = '0;
    pkt_i.data = '0;
    pkt_i.val  = '0;
  end

// TODO: check ready for each tick!
task send_transaction( input __sort_trans_t data );
  wait( pkt_i.ready == 1'b1 )
  
  for( int i = 0; i < data.size; i++ ) begin
    pkt_i.val  <= 1'b1;
    pkt_i.data <= data.payload[i];
    pkt_i.sop  <= ( i == ( 0             ) ); 
    pkt_i.eop  <= ( i == ( data.size - 1 ) );
    @( posedge pkt_i.clk );
   end

   pkt_i.sop <= 1'b0;
   pkt_i.val <= 1'b0;
   pkt_i.eop <= 1'b0;
   @( posedge pkt_i.clk );
endtask

mailbox #( __sort_trans_t ) in_fifo;
mailbox #( __sort_trans_t ) in_fifo_ref;

task automatic create_transaction( input bit ultra_random = 1'b0, int _size, sort_trans_type_t _trans_type );
  
  __sort_trans_t trans = new();
  
  $display("create_transaction: %d, %d, %s", ultra_random, _size, _trans_type.name() );

  if( ultra_random == 1'b0 )
    begin
      trans.randomize() with {
         size == _size;
        _type == _trans_type;
      };
    end
  else
    begin
      trans.randomize();
    end
  
  trans.print(); 

  in_fifo.put( trans );
  
  trans.sort();
  in_fifo_ref.put( trans );
endtask

task transaction_monitor( output __sort_trans_t trans );
  trans = new();

  // $display("transaction_monitor: started");

  forever
    begin
      // FIXME: dirty hack
      @( negedge clk );
      
      // $display("%t: val = %d ready = %d eop = %d", $time(), pkt_o.val, pkt_o.ready, pkt_o.eop );

      if( pkt_o.val && pkt_o.ready )
        begin
          trans.payload.push_back( pkt_o.data );
          $display("pushed: %h", pkt_o.data );
        end 

      if( pkt_o.val && pkt_o.ready && pkt_o.eop )
        break;
    end

  // $display("transaction_monitor: ended");
endtask

task transaction_checker( );
  __sort_trans_t ref_trans = new ();
  __sort_trans_t out_trans = new ();

  forever
    begin
      transaction_monitor( out_trans );
      in_fifo_ref.get( ref_trans );

      if( out_trans.is_equal( ref_trans ) == 1'b0 )
        begin
          $error( "Transactions didn't match!" );
          $display("    DUT REF");
          for( int i = 0; i < out_trans.payload.size(); i++ )
            begin
              $display("%3d: %02h %02h", i, out_trans.payload[i], ref_trans.payload[i] );
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

    create_transaction( 0, 15, RANDOM );
    create_transaction( 0, 1, RANDOM );
    create_transaction( 0, 2, RANDOM );
    create_transaction( 0, 4, RANDOM );
    create_transaction( 0, 4, DECREASING );
    
    create_transaction( 0, 5, RANDOM );

    create_transaction( 0, 2**AWIDTH-1, RANDOM );

    create_transaction( 0, 2**AWIDTH, RANDOM );
    create_transaction( 0, 2**AWIDTH, INCREASING );
    create_transaction( 0, 2**AWIDTH, RANDOM );
    create_transaction( 0, 2**AWIDTH, DECREASING );
    create_transaction( 0, 2**AWIDTH, CONSTANT );

    for( int i = 0; i < 100; i++ )
      begin
        create_transaction( 1, 0, RANDOM );
      end
  end

__sort_trans_t trans_to_dut;

initial
  begin
    trans_to_dut = new();

    @cb;
    forever
      begin
        @cb;
        if( in_fifo.num() > 0 ) 
          begin
            in_fifo.get( trans_to_dut );
            $display("TRANS_TO_DUT size = %d", in_fifo.num() );
            trans_to_dut.print();
            send_transaction( trans_to_dut );
          end
      end
  end
endmodule
