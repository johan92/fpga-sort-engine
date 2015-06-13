class SortScoreboard #( type T );
  
  mailbox #( T ) drv2scb;
  mailbox #( T ) mon2scb;

  function new( input mailbox #( T ) drv2scb, input mailbox #( T ) mon2scb );
    this.mon2scb = mon2scb;
    this.drv2scb = drv2scb;
  endfunction
  
  task run( );
    T to_dut;
    T from_dut;

    forever
      begin
        mon2scb.get( from_dut );
        drv2scb.get( to_dut   );
        
        // do sorting here
        to_dut.sort();
        
        check( to_dut, from_dut );
      end
  endtask

  function check( input T _ref, from_dut );
    if( from_dut.is_equal( _ref ) == 1'b0 )
      begin
        $error( "Transactions didn't match!" );
        $display("    DUT REF");
        for( int i = 0; i < from_dut.payload.size(); i++ )
          begin
            $display("%3d: %02h %02h", i, from_dut.payload[i], _ref.payload[i] );
          end
        $stop();
      end
    else
      begin
        $info( "Transations match!" );
      end
  endfunction

endclass
