module sort_engine_merge_tree_stage #( 
  parameter DWIDTH      = 8,
  // should be power of 2 !
  parameter IN_DATA_CNT = 16,

  // internal parameter. do not change it!
  parameter OUT_DATA_CNT = IN_DATA_CNT/2 
) 
(
  input                                       clk_i,
  input                                       rst_i,
  
  input  logic [IN_DATA_CNT-1:0][DWIDTH-1:0]  data_in_i,
  input  logic [IN_DATA_CNT-1:0]              data_in_val_i,
  output logic [IN_DATA_CNT-1:0]              data_in_ready_o,


  output logic [OUT_DATA_CNT-1:0][DWIDTH-1:0] data_out_o,
  output logic [OUT_DATA_CNT-1:0]             data_out_val_o,
  input  logic [OUT_DATA_CNT-1:0]             data_out_ready_i

);


genvar g;
generate
  for( g = 0; g < OUT_DATA_CNT; g++ )
    begin : g_out
      localparam OFFSET = g * 2;
      logic              _in_ready;

      logic [DWIDTH-1:0] _l_data;
      logic [DWIDTH-1:0] _r_data;
      logic              _l_data_val;
      logic              _r_data_val;
      logic              _l_ready;
      logic              _r_ready;

      logic              _l_sel;
      logic              _l_lt_r;

      logic [DWIDTH-1:0] _next_data;
      logic              _next_data_val;
      
      assign _l_lt_r       = ( _l_data < _r_data ); 
      assign _next_data    = ( _l_sel ) ? ( _l_data ) : ( _r_data );

      assign _l_data     = data_in_i    [ OFFSET     ];
      assign _r_data     = data_in_i    [ OFFSET + 1 ];
      assign _l_data_val = data_in_val_i[ OFFSET     ];
      assign _r_data_val = data_in_val_i[ OFFSET + 1 ];

      assign data_in_ready_o[ OFFSET     ] = _l_ready;
      assign data_in_ready_o[ OFFSET + 1 ] = _r_ready;
      
      always_comb
        begin
          case( { _l_data_val, _r_data_val } )
            2'b00: { _next_data_val, _l_sel } = { 1'b0, 1'b1     }; 
            2'b01: { _next_data_val, _l_sel } = { 1'b1, 1'b0     }; 
            2'b10: { _next_data_val, _l_sel } = { 1'b1, 1'b1     }; 
            2'b11: { _next_data_val, _l_sel } = { 1'b1, _l_lt_r  }; 
          endcase
        end

      always_comb
        begin
          case( { _l_data_val, _r_data_val } )
            2'b00: { _l_ready, _r_ready } = { 1'b0, 1'b0       }; 
            2'b01: { _l_ready, _r_ready } = { 1'b0, 1'b1       }; 
            2'b10: { _l_ready, _r_ready } = { 1'b1, 1'b0       }; 
            2'b11: { _l_ready, _r_ready } = _l_lt_r ? ( 2'b10 ) : ( 2'b01 ); 
          endcase

          _l_ready = _l_ready && _in_ready;
          _r_ready = _r_ready && _in_ready;
        end

      assign _in_ready = ( !data_out_val_o[g] ) || data_out_ready_i[g];

      always_ff @( posedge clk_i or posedge rst_i )
        if( rst_i )
          begin
            data_out_o[g]     <= '0;
            data_out_val_o[g] <= '0;
          end
        else
          if( _in_ready )
            begin
              data_out_o[g]     <= _next_data;
              data_out_val_o[g] <= _next_data_val;
            end
    end
endgenerate

endmodule
