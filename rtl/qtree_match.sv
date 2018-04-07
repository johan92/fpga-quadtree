module qtree_match #( 
   parameter ADDR_WIDTH       = -1,

   parameter IN_DATA_WIDTH    = -1,
   parameter KEY_WIDTH        = -1,

   parameter BYPASS_WIDTH     = -1,

   parameter RAM_DATA_WIDTH   = -1,
   parameter RAM_ADDR_WIDTH   = -1,

   parameter MATCH_CELL_CNT   = -1,
   parameter MATCH_CELL_CNT_WIDTH = $clog2(MATCH_CELL_CNT),
  
   parameter RAM_OUT_REG_ENABLE    = 0,
   parameter STAGE0_OUT_REG_ENABLE = 0,
   parameter STAGE1_OUT_REG_ENABLE = 0

) (
  input                               clk_i,
  input                               rst_i,
  
  input  [RAM_DATA_WIDTH       - 1:0] ram_data_i,
  input  [RAM_ADDR_WIDTH       - 1:0] ram_addr_i,
  input  [MATCH_CELL_CNT_WIDTH - 1:0] ram_cell_i,
  input                               ram_write_i,
  
  input  [IN_DATA_WIDTH  - 1:0]       in_data_i,
  input  [BYPASS_WIDTH   - 1:0]       in_bypass_i,
  input                               in_valid_i,

  output                              lookup_match_o,
  output [ADDR_WIDTH     - 1:0]       lookup_addr_o,
  output [BYPASS_WIDTH   - 1:0]       lookup_bypass_o,
  output                              lookup_valid_o

);

`include "defs.vh"

typedef struct packed {
  level_data_t                      in_data;

  logic [MATCH_CELL_CNT-1:0]        match_mask;

  logic [MATCH_CELL_CNT_WIDTH-1:0]  match_num;
  logic                             got_match;
  
  logic [BYPASS_WIDTH-1:0]          bypass;
} match_pipe_data_t;

match_ram_data_t          rd_data_w    [MATCH_CELL_CNT-1:0];

level_data_t              in_data;

match_pipe_data_t         stage0_in;
logic                     stage0_in_valid;

match_pipe_data_t         stage0_out;
logic                     stage0_out_valid;

match_pipe_data_t         stage1_in;
logic                     stage1_in_valid;

match_pipe_data_t         stage1_out;
logic                     stage1_out_valid;

assign in_data = in_data_i;

//  --------------------------------------------------------------------------- 
//  STAGE 0: Reading from RAM
//  ---------------------------------------------------------------------------
match_ram_data_t      ram_read_data       [MATCH_CELL_CNT-1:0];
match_pipe_data_t     stage0_ram_out      [MATCH_CELL_CNT-1:0];
logic                 stage0_ram_out_valid[MATCH_CELL_CNT-1:0];

always_comb begin
  stage0_in = 'x;
  stage0_in_valid = in_valid_i;

  stage0_in.in_data = in_data;
  stage0_in.bypass  = in_bypass_i;
end


genvar g;
generate
  for( g = 0; g < MATCH_CELL_CNT; g++ )
    begin : mr
      logic _ram_write_w;
      assign _ram_write_w = ram_write_i && (g == ram_cell_i);

      simple_ram_with_delay #( 
        .DATA_WIDTH       ( RAM_DATA_WIDTH                              ), 
        .ADDR_WIDTH       ( RAM_ADDR_WIDTH                              ),
        .BYPASS_WIDTH     ( $bits(stage_0_in)                           ),
        .OUT_REG_ENABLE   ( RAM_OUT_REG_ENABLE                          )
      ) ram (
        .clk_i            ( clk_i                                       ),
        .rst_i            ( rst_i                                       ),

        .wr_addr_i        ( ram_addr_i                                  ),
        .wr_data_i        ( ram_data_i                                  ),
        .wr_enable_i      ( _ram_write_w                                ),

        .in_read_addr_i   ( stage0_in.in_data.addr[RAM_ADDR_WIDTH-1:0]  ),
        .in_bypass_i      ( stage0_in                                   ),
        .in_valid_i       ( stage0_in_valid                             ),

        .out_read_data_o  ( ram_read_data[g]                            ),
        .out_bypass_o     ( stage0_ram_out[g]                           ),
        .out_valid_o      ( stage0_ram_out_valid[g]                     )
      );

    end
endgenerate

always_comb begin
  stage0_out       = stage0_ram_out[0];
  stage0_out_valid = stage0_ram_out_valid[0];

  for( int i = 0; i < MATCH_CELL_CNT; i++ ) begin
    stage0_out.match_mask[i]  = 1'b1;
    stage0_out.match_mask[i] &= ram_read_data[i].l <= stage0_ram_out[0].in_data.lookup_value;
    stage0_out.match_mask[i] &= ram_read_data[i].r >= stage0_ram_out[0].in_data.lookup_value;
  end
end

delay #(
  .DATA_WIDTH   ( $bits(stage0_out)        ),
  .ENABLE       ( STAGE0_OUT_REG_ENABLE    )
) delay_stage0 (
  .clk_i        ( clk_i                    ),
  .rst_i        ( rst_i                    ),

  .in_data_i    ( stage0_out               ),
  .in_valid_i   ( stage0_out_valid         ),

  .out_data_o   ( stage1_in                ),
  .out_valid_o  ( stage1_in_valid          )

);

//  --------------------------------------------------------------------------- 
//  STAGE 1: Match Num Calculation 
//  ---------------------------------------------------------------------------
logic [MATCH_CELL_CNT_WIDTH-1:0] match_num_w;
logic                            got_match_w;

always_comb
  begin
    match_num_w = '0;
    got_match_w = 1'b0;

    for( int i = 0; i < MATCH_CELL_CNT; i++ )
      begin
        if( stage1_out.match_mask[i] )
          begin
            match_num_w = i;
            got_match_w = 1'b1;
          end
      end
  end

always_comb begin
  stage1_out = stage1_in;
  stage1_out_valid = stage1_in_valid;

  stage1_out.match_num  = match_num_w;
  stage1_out.got_match  = got_match_w; 
end

delay #(
  .DATA_WIDTH   ( $bits(stage1_out)        ),
  .ENABLE       ( STAGE1_OUT_REG_ENABLE    )
) delay_stage1 (
  .clk_i        ( clk_i                    ),
  .rst_i        ( rst_i                    ),

  .in_data_i    ( stage1_out               ),
  .in_valid_i   ( stage1_out_valid         ),

  .out_data_o   ( stage2_in                ),
  .out_valid_o  ( stage2_in_valid          )

);

//  --------------------------------------------------------------------------- 
//  STAGE 2: Output Calculations
//  ---------------------------------------------------------------------------

assign lookup_valid_o = 'x; 
assign lookup_match_o = 'x;
assign lookup_addr_o  = 'x; // TODO

endmodule
