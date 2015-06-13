class SortEnvironment #( type T );
  
  SortGenerator   #( T ) gen;
  SortDriver      #( T ) drv;
  SortMonitor     #( T ) mon;
  SortScoreboard  #( T ) scb;

  mailbox #( T ) gen2drv, drv2scb, mon2scb;
  
  function void build( virtual sort_engine_if _in_if, virtual sort_engine_if _out_if );
    gen2drv = new( );
    drv2scb = new( );
    mon2scb = new( );

    gen = new( gen2drv                   );
    drv = new( gen2drv, drv2scb, _in_if  );
    mon = new( mon2scb,          _out_if );
    scb = new( drv2scb, mon2scb          );
  endfunction 
  
  task run( );
    fork
      gen.run( 100 );
      drv.run( );
      mon.run( );
      scb.run( );
    join
  endtask 

endclass
