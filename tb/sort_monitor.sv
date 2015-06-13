class SortMonitor #( type T );

  mailbox #( T ) mon2scb;
  
  virtual sort_engine_if __if;

  function new( input mailbox #( T ) mon2scb, virtual sort_engine_if _out_if );
    this.mon2scb = mon2scb;
    this.__if    = _out_if;
  endfunction

  task run( );
    fork
      receiver_thread(   );
      ready_thread( 1 );
    join
  endtask
  
  task receiver_thread( );
    T tr;

    forever 
      begin
        recieve_data( tr );
        mon2scb.put( tr );
      end

  endtask

  task ready_thread( bit ready_is_rand );

    forever
      begin
        @( posedge __if.clk );
        __if.ready <= ( ready_is_rand ) ? ( $urandom() % 2 ) : ( 1'b1 );
      end

  endtask 

  task recieve_data( output T tr );
    tr = new();
    
    forever
      begin
        //FIXME: dirty hack
        @( negedge __if.clk ); 
        if( __if.val && __if.ready )
          begin
            tr.payload.push_back( __if.data );
            //$display("pushed: %h", __if.data );
          end 

        if( __if.val && __if.ready && __if.eop )
          break;
      end

  endtask

endclass
