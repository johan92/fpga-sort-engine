module top_tb;

logic clk;
logic rst;

localparam AWIDTH = 5;
localparam DWIDTH = 8;

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) data_in ( clk );

sort_engine_if #( 
  .DWIDTH ( DWIDTH ) 
) data_out ( clk );

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

gnome_sort_engine_wrapper #( 
  .AWIDTH                                 ( AWIDTH            ),
  .DWIDTH                                 ( DWIDTH            )
) gsewp (
  .clk_i                                  ( clk               ),
  .rst_i                                  ( rst               ),

  .pkt_i                                  ( data_in           ),
  .pkt_o                                  ( data_out          )
);

initial
  begin
    data_in.sop  = '0;
    data_in.eop  = '0;
    data_in.data = '0;
    data_in.val  = '0;
  end


task send_transaction( trans_data_t data );
  wait( data_in.busy == 0 )
  
  for( int i = 0; i < data.size(); i++ ) begin
    @( posedge data_in.clk );

    data_in.val  <= 1'b1;
    data_in.data <= data[i];
    data_in.sop <= ( i == ( 0               ) ); 
    data_in.eop <= ( i == ( data.size() - 1 ) );
   end

   @( posedge data_in.clk );
   data_in.sop <= 1'b0;
   data_in.val <= 1'b0;
   data_in.eop <= 1'b0;
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

trans_data_t new_trans;

initial
  begin
    in_fifo = new( );

    //new_trans = gen_transaction( 1, RANDOM );
    //in_fifo.put( new_trans );

    //new_trans = gen_transaction( 2, RANDOM );
    //in_fifo.put( new_trans );

    //new_trans = gen_transaction( 4, INCREASING );
    //in_fifo.put( new_trans );

    new_trans = gen_transaction( 5, RANDOM );
    in_fifo.put( new_trans );
  end

trans_data_t new_trans_2;

initial
  begin
    forever
      begin
        @cb;
        if( in_fifo.num() > 0 ) begin
          in_fifo.get( new_trans_2 ); 
          send_transaction( new_trans_2 );
        end
      end
  end

endmodule
