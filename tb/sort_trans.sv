`include "sort_defines.svh"

class sort_trans_t #( 
  parameter DWIDTH         = 8,
  // should be 2**AWIDTH of sort_engine
  parameter MAX_TRANS_SIZE = 64
);
  rand sort_trans_type_t _type;
  
  rand int size;

  bit [DWIDTH-1:0] payload [$];

  constraint size_c {
    size > 0;
    size <= MAX_TRANS_SIZE; 
  }
  
  function bit is_equal( input sort_trans_t b );
    // we can't rely on size, because it can be not initialized
    // (after monitor, for example)
    if( payload.size() != b.payload.size() )
      return 0;

    for( int i = 0; i < payload.size(); i++ )
      begin
        if( payload[i] != b.payload[i] )
          begin
            return 0;
          end
      end

    return 1;

  endfunction

  function void sort();
    payload.sort();
  endfunction

  function void print();
    $display("type = %s", _type.name() );
    $display("size = %d", size );
    for( int i = 0; i < size; i++ )
      begin
        $display("[%d] = %04h", i, payload[i] );
      end
  endfunction

  function void post_randomize();
    $display("%m: in post_randomize");
    
    payload = {};

    for( int i = 0; i < size; i++ )
      begin
        case( _type )
          RANDOM: 
            begin
              payload.push_back( $urandom() );
            end

          INCREASING:
            begin
              payload.push_back( i );
            end

          DECREASING:
            begin
              payload.push_back( size - i - 1 );
            end

          CONSTANT:
            begin
              if( i == 0 ) begin
                payload.push_back( $urandom() );
              end else begin
                payload.push_back( payload[0] );
              end
            end

          default:
            begin
              $error("Unknown: type = %s ", _type );
              $fatal();
            end

        endcase
      end

  endfunction

endclass
