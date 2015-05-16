module gnome_sort_engine #( 
  parameter AWIDTH = 5, 
  parameter DWIDTH = 8 
)
(
  input clk_i,
  input rst_i,
  
  // sync reset before accepting new data
  input srst_i,

  // strob to start sorting
  input run_i,

  input               wr_req_i,
  input  [DWIDTH-1:0] wr_data_i,

  input               rd_req_i,
  output [DWIDTH-1:0] rd_data_o,
  output              rd_last_word_o,

  output logic        done_o

);
logic [AWIDTH:0]   array_size;

logic [DWIDTH-1:0] wr_data_a;
logic [DWIDTH-1:0] rd_data_a;
logic [AWIDTH-1:0] addr_a;
logic              wr_en_a;

logic [DWIDTH-1:0] wr_data_b;
logic [DWIDTH-1:0] rd_data_b;
logic [AWIDTH-1:0] addr_b;
logic              wr_en_b;

logic [AWIDTH:0]   i;
logic [AWIDTH:0]   i_m1;
logic [AWIDTH:0]   j;

logic [AWIDTH:0]   next_i;
logic [AWIDTH:0]   next_j;

logic              need_swap;
logic              in_sorting;

logic [AWIDTH-1:0] rd_ptr;

typedef enum int unsigned { IDLE, 
                            READ,
                            CALC,
                            SWAP, 
                            WRITE } tick_t;
tick_t tick, next_tick;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    array_size <= '0;
  else
    if( srst_i )
      array_size <= '0;
    else
      if( wr_req_i )
        array_size <= array_size + 1'd1;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    in_sorting <= 1'b0;
  else
    if( run_i )
      in_sorting <= 1'b1;
    else
      if( done_o ) //FIXME: one tick earlier
        in_sorting <= 1'b0;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    rd_ptr <= '0;
  else
    if( run_i )
      rd_ptr <= '0;
    else
      if( rd_req_i )
        rd_ptr <= rd_ptr + 1'd1;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      i    <= '0;
      i_m1 <= '0;
      j    <= '0;
    end
  else
    if( run_i )
      begin
        i    <= 'd1;
        i_m1 <= 'd0;
        j    <= 'd2;
      end
    else
      if( next_tick == READ )
        begin
          i    <= next_i;
          i_m1 <= next_i - 1'd1;
          j    <= next_j;
        end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    tick <= IDLE;
  else
    if( srst_i )
      tick <= IDLE;
    else
      tick <= next_tick;

always_comb
  begin
    next_tick = tick;

    case( tick )
      IDLE:
        begin
          if( run_i )
            next_tick = READ;
        end
      READ:
        begin
          if( i >= array_size )
            next_tick = IDLE;
          else
            next_tick = CALC;
        end
      CALC:
        begin
          if( need_swap )
            next_tick = SWAP; 
          else
            next_tick = READ;
        end
      SWAP:
        begin
          next_tick = READ;
        end
      default:
        begin
          next_tick = IDLE;
        end
    endcase
  end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    done_o <= 1'b0;
  else
    if( srst_i )
      done_o <= 1'b0;
    else
      if( in_sorting && ( next_tick != tick ) && ( next_tick == IDLE ) )
        done_o <= 1'b1;

assign need_swap = ( rd_data_a < rd_data_b ); 

always_comb begin
  next_i = i;
  next_j = j;

  if( !need_swap ) begin
    next_i = next_j;
    next_j = next_j + 1'd1;
  end else begin
    next_i = i_m1;

    if( i_m1 == 'd0 ) begin
      next_i = next_j;
      next_j = next_j + 1'd1;
    end
  end
end


// for port A
always_comb
  begin
    wr_en_a   = wr_req_i;
    addr_a    = array_size;
    wr_data_a = wr_data_i;

    if( in_sorting )
      begin
        wr_en_a   = ( tick == SWAP );
        addr_a    = i; 
        wr_data_a = rd_data_b;
      end

    if( rd_req_i )
      begin
        addr_a = rd_ptr;
      end
  end

always_comb
  begin
    wr_en_b   = 1'b0;
    addr_b    = '0;
    wr_data_b = '0;

    if( in_sorting )
      begin
        wr_en_b   = ( tick == SWAP );
        addr_b    = i - 1'd1; 
        wr_data_b = rd_data_a;
      end
  end

assign rd_data_o = rd_data_a;

// FIXME  
assign rd_last_word_o = ( rd_ptr == array_size );

true_dual_port_ram_single_clock #(
  .DATA_WIDTH                             ( DWIDTH            ), 
  .ADDR_WIDTH                             ( AWIDTH            ),
  .REGISTER_OUT                           ( 0                 )
) dpram (
  .clk                                    ( clk_i             ),

  .addr_a                                 ( addr_a            ),
  .data_a                                 ( wr_data_a         ),
  .we_a                                   ( wr_en_a           ),
  .q_a                                    ( rd_data_a         ),

  .addr_b                                 ( addr_b            ),
  .data_b                                 ( wr_data_b         ),
  .we_b                                   ( wr_en_b           ),
  .q_b                                    ( rd_data_b         )
);

endmodule
