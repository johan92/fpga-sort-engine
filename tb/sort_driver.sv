class SortDriver #( type T );

  mailbox #( T ) gen2drv;
  mailbox #( T ) drv2scb;
  
  virtual sort_engine_if __if;

  function new( input mailbox #( T ) gen2drv, drv2scb, virtual sort_engine_if _in_if );
    this.gen2drv = gen2drv;
    this.drv2scb = drv2scb;
    this.__if    = _in_if;

    init_if( );
  endfunction
  
  task run( );
    T tr;
    
    forever
      begin
        gen2drv.get( tr );
        
        send_transaction( tr );
        
        drv2scb.put( tr );
      end

  endtask

  function init_if( );
    this.__if.val  <= '0;
    this.__if.data <= '0;
    this.__if.sop  <= '0;
    this.__if.eop  <= '0;
  endfunction
  
  task send_transaction( input T tr );
    wait( __if.ready == 1'b1 )
    
    for( int i = 0; i < tr.size; i++ ) 
      begin
       __if.val  <= 1'b1;
       __if.data <= tr.payload[i];
       __if.sop  <= ( i == ( 0           ) ); 
       __if.eop  <= ( i == ( tr.size - 1 ) );
       @( posedge __if.clk );
      end

    __if.sop <= 1'b0;
    __if.val <= 1'b0;
    __if.eop <= 1'b0;
    @( posedge __if.clk );

  endtask 

endclass
