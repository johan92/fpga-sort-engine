interface sort_engine_if #( 
  parameter DWIDTH = 8 
)
( 
  input clk 
);
  
logic              sop;
logic              eop;
logic [DWIDTH-1:0] data;
logic              val;
logic              busy;

modport master( 
  output sop,
         eop,
         data,
         val,
  input  busy
);

modport slave(
  input  sop,
         eop,
         data,
         val,
  output busy

);

endinterface
