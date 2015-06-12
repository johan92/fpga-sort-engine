module sort_engine_with_merge #( 
  parameter AWIDTH     = 5,
  parameter DWIDTH     = 8,

  // should be power of 2 
  parameter ENGINE_CNT = 2
)
(
  input                  clk_i,
  input                  rst_i,

  sort_engine_if.slave   pkt_i,
  sort_engine_if.master  pkt_o

);
localparam ENGINE_AWIDTH = AWIDTH - $clog2( ENGINE_CNT );

logic run_sort;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    run_sort <= 1'b0;
  else
    run_sort <= pkt_i.val && pkt_i.eop && pkt_i.ready;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_i.ready <= 1'b1;
  else
    if( pkt_i.eop && pkt_i.val && pkt_i.ready )
      pkt_i.ready <= 1'b0;
    else
      if( pkt_o.eop && pkt_o.val && pkt_o.ready )
        pkt_i.ready <= 1'b1;

logic sort_engine_srst;

assign sort_engine_srst = pkt_o.eop && pkt_o.val && pkt_o.ready;

logic [ENGINE_CNT-1:0] balancer;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    balancer <= 'd1;
  else
    if( sort_engine_srst )
      balancer <= 'd1;
    else
      if( pkt_i.val && pkt_i.ready )
        begin
          if( balancer[ENGINE_CNT-1] )
            balancer <= 'd1;
          else
            balancer <= { balancer[ENGINE_CNT-2:0], 1'b0 };
        end

// se for sort_engine        
logic [ENGINE_CNT-1:0]             se_wr_req;
logic [ENGINE_CNT-1:0]             was_se_wr_req;

logic [ENGINE_CNT-1:0]             se_ready_w;
logic [ENGINE_CNT-1:0][DWIDTH-1:0] se_data_w;
logic [ENGINE_CNT-1:0]             se_valid_w;


always_comb
  begin
    for( int i = 0; i < ENGINE_CNT; i++ )
      begin
        se_wr_req[i] = pkt_i.val && pkt_i.ready && balancer[i];
      end
  end

// masks flag, that got at least one write request to engine
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    was_se_wr_req <= '0;
  else
    if( sort_engine_srst )
      was_se_wr_req <= '0;
    else
      was_se_wr_req <= was_se_wr_req | se_wr_req;

genvar g, z;
generate
  for( g = 0; g < ENGINE_CNT; g++ )
    begin : g_eng

      gnome_sort_engine #( 
        .AWIDTH                                 ( ENGINE_AWIDTH                ), 
        .DWIDTH                                 ( DWIDTH                       ) 
      ) gse (
        .clk_i                                  ( clk_i                        ),
        .rst_i                                  ( rst_i                        ),
          
        .srst_i                                 ( sort_engine_srst             ), 

        .run_i                                  ( run_sort && was_se_wr_req[g] ),

        .wr_req_i                               ( se_wr_req[g]                 ),
        .wr_data_i                              ( pkt_i.data                   ),

        .out_ready_i                            ( se_ready_w[g]   ),
        .out_data_o                             ( se_data_w[g]    ),
        .out_valid_o                            ( se_valid_w[g]   ),
        .out_sop_o                              (                 ),
        .out_eop_o                              (                 )

      );
      
    end
endgenerate

logic next_all_se_done;
logic      all_se_done;

always_comb
  begin
    next_all_se_done = 1'b1;

    for( int i = 0; i < ENGINE_CNT; i++ )
      begin
        if( was_se_wr_req[i] && ( se_valid_w[i] == 1'b0 ) )
          next_all_se_done = 1'b0;
      end
  end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    all_se_done <= 1'b0;
  else
    if( run_sort ) 
      all_se_done <= 1'b0;
    else
      if( !all_se_done )
        all_se_done <= next_all_se_done;


localparam STAGES_CNT = $clog2( ENGINE_CNT ); 
      
logic [DWIDTH-1:0] last_stage_data;
logic              last_stage_val;
logic              last_stage_ready;

generate
  for( g = 0; g < STAGES_CNT; g++ )
    begin : g_stages
      localparam STAGE_IN_DATA_CNT  = ENGINE_CNT/2**g; 
      localparam STAGE_OUT_DATA_CNT = STAGE_IN_DATA_CNT/2;

      logic [STAGE_IN_DATA_CNT-1:0][DWIDTH-1:0]  _data_in_w;
      logic [STAGE_IN_DATA_CNT-1:0]              _data_in_val_w;
      logic [STAGE_IN_DATA_CNT-1:0]              _data_in_ready_w;
      
      logic [STAGE_OUT_DATA_CNT-1:0][DWIDTH-1:0] _data_out_w;
      logic [STAGE_OUT_DATA_CNT-1:0]             _data_out_val_w;
      logic [STAGE_OUT_DATA_CNT-1:0]             _data_out_ready_w;
      
      if( g == 0 )
        begin
          logic [STAGE_IN_DATA_CNT-1:0] _se_valid_masked;
          logic [STAGE_IN_DATA_CNT-1:0] _pre_se_ready_masked;

          assign _se_valid_masked = se_valid_w           & {{ENGINE_CNT}{all_se_done}};
          assign se_ready_w       = _pre_se_ready_masked & {{ENGINE_CNT}{all_se_done}};
          
          for( z = 0; z < STAGE_IN_DATA_CNT; z++ )
            begin : _pipe_data_d1
              avalon_st_delay #(
                .DWIDTH                                 ( DWIDTH                  )
              ) avalon_d1 (
                .clk_i                                  ( clk_i                   ),
                .rst_i                                  ( rst_i                   ),

                .in_data_i                              ( se_data_w[z]            ),
                .in_valid_i                             ( _se_valid_masked[z]     ),
                .in_ready_o                             ( _pre_se_ready_masked[z] ),

                .out_data_o                             ( _data_in_w[z]           ),
                .out_valid_o                            ( _data_in_val_w[z]       ),
                .out_ready_i                            ( _data_in_ready_w[z]     )
              );
            end
        end
      else
        begin
          assign _data_in_w                       = g_stages[g-1]._data_out_w; 
          assign _data_in_val_w                   = g_stages[g-1]._data_out_val_w;
          assign g_stages[g-1]._data_out_ready_w  = _data_in_ready_w;
        end

      sort_engine_merge_tree_stage #( 
        .DWIDTH                                 ( DWIDTH            ),
        .IN_DATA_CNT                            ( STAGE_IN_DATA_CNT )
      ) st_0 (
        .clk_i                                  ( clk_i             ),
        .rst_i                                  ( rst_i             ),
          
        .data_in_i                              ( _data_in_w        ),
        .data_in_val_i                          ( _data_in_val_w    ),
        .data_in_ready_o                        ( _data_in_ready_w  ),

        .data_out_o                             ( _data_out_w       ),
        .data_out_val_o                         ( _data_out_val_w   ),
        .data_out_ready_i                       ( _data_out_ready_w )

      );
    end
endgenerate

assign last_stage_data  = g_stages[STAGES_CNT-1]._data_out_w;
assign last_stage_val   = g_stages[STAGES_CNT-1]._data_out_val_w;
assign g_stages[STAGES_CNT-1]._data_out_ready_w = last_stage_ready; 

assign last_stage_ready = ( !pkt_o.val ) || pkt_o.ready;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      pkt_o.sop   <= 1'b0;
      pkt_o.val   <= 1'b0;
      pkt_o.data  <= '0;
    end
  else
    if( last_stage_ready ) 
      begin
        if( pkt_o.sop )
          pkt_o.sop <= 1'b0;
        else
          if( !pkt_o.val && last_stage_val )
            pkt_o.sop <= 1'b1;

        pkt_o.val   <= last_stage_val;
        pkt_o.data  <= last_stage_data;
      end

assign pkt_o.eop = pkt_o.val && !last_stage_val;

// synthesys translate_off

initial
  begin
    // checks, that ENGINE_CNT is power of 2
    // http://stackoverflow.com/questions/1053582/how-does-this-bitwise-operation-check-for-a-power-of-2
    // for example check 8 ( 4'b1000 ):
    // 1000 & 0111 = 0000 
    if( ( ENGINE_CNT & ( ENGINE_CNT - 1 ) ) != 0 )
      begin
        $display( "ENGINE_CNT = %0d is not power of 2!", ENGINE_CNT );
        $fatal();
      end

    if( ENGINE_AWIDTH <= 0 )
      begin
        $fatal( "Wrong ENGINE_AWIDTH = %0d parameter!", ENGINE_AWIDTH );
        $fatal();
      end
  end
// synthesys translate_on
endmodule
