class SortGenerator #( type T );

  mailbox #( T ) gen2drv;

  function new( input mailbox #( T ) gen2drv );
    this.gen2drv = gen2drv;
  endfunction

  task run( input int n = 10 );
    T tr;

    repeat( n ) 
      begin
        tr = new( );
        tr.randomize( );
        gen2drv.put( tr ); // use tr.copy?
      end

  endtask

endclass
