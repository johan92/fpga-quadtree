module top(
  clk_i,
  rst_i,

  mm_ctrl_addr_i,
  mm_ctrl_data_i,
  mm_ctrl_write_i,

  lookup_data_i,
  lookup_bypass_i,
  lookup_valid_i,
  
  lookup_valid_o,
  lookup_match_o,
  lookup_bypass_o,
  lookup_addr_o
);

// main "global" quad tree defines
localparam LEVEL_CNT      = 5;
localparam KEY_WIDTH      = 16;
localparam MATCH_CELL_CNT = 4;
localparam BYPASS_WIDTH   = 1;

`include "func_defs.vh"
`include "ram_defs.vh"

// other defines, recalculated from "global"
localparam ADDR_WIDTH           = get_ADDR_WIDTH          ( LEVEL_CNT, MATCH_CELL_CNT );

localparam LEVEL_WIDTH          = get_LEVEL_WIDTH         ( LEVEL_CNT      );
localparam MATCH_CELL_CNT_WIDTH = get_MATCH_CELL_CNT_WIDTH( MATCH_CELL_CNT );

localparam LEVEL_RAM_DATA_WIDTH = $bits(level_ram_data_t);
localparam MATCH_RAM_DATA_WIDTH = $bits(match_ram_data_t);
localparam MATCH_RAM_ADDR_WIDTH = get_MATCH_RAM_ADDR_WIDTH( LEVEL_CNT );

`include "mm_defs.vh"

localparam MM_ADDR_WIDTH = get_MM_ADDR_WIDTH( $bits(mm_addr_level_t), $bits(mm_addr_match_t) );
localparam MM_DATA_WIDTH = get_MM_DATA_WIDTH( LEVEL_RAM_DATA_WIDTH, MATCH_RAM_DATA_WIDTH     );


input                            clk_i;
input                            rst_i;

input     [MM_ADDR_WIDTH - 1:0]  mm_ctrl_addr_i;
input     [MM_DATA_WIDTH - 1:0]  mm_ctrl_data_i;
input                            mm_ctrl_write_i;

input     [KEY_WIDTH-1:0]        lookup_data_i;
input     [BYPASS_WIDTH-1:0]     lookup_bypass_i;
input                            lookup_valid_i;

output                           lookup_valid_o;
output                           lookup_match_o;
output    [BYPASS_WIDTH-1:0]     lookup_bypass_o;
output    [ADDR_WIDTH  -1:0]     lookup_addr_o;

qtree_top #( 
  .LEVEL_CNT                              ( LEVEL_CNT             ), 
  .KEY_WIDTH                              ( KEY_WIDTH             ),
  .MATCH_CELL_CNT                         ( MATCH_CELL_CNT        ),
  .BYPASS_WIDTH                           ( BYPASS_WIDTH          ),
                                                                
  .LEVEL_WIDTH                            ( LEVEL_WIDTH           ),
  .MATCH_CELL_CNT_WIDTH                   ( MATCH_CELL_CNT_WIDTH  ),
  .ADDR_WIDTH                             ( ADDR_WIDTH            ),
  .MM_ADDR_WIDTH                          ( MM_ADDR_WIDTH         ),
  .MM_DATA_WIDTH                          ( MM_DATA_WIDTH         ),
  .LEVEL_RAM_DATA_WIDTH                   ( LEVEL_RAM_DATA_WIDTH  ),
  .MATCH_RAM_DATA_WIDTH                   ( MATCH_RAM_DATA_WIDTH  ),
  .MATCH_RAM_ADDR_WIDTH                   ( MATCH_RAM_ADDR_WIDTH  )
) qtree (
  .clk_i                                  ( clk_i                 ),
  .rst_i                                  ( rst_i                 ),
  
  .mm_ctrl_addr_i                         ( mm_ctrl_addr_i        ),
  .mm_ctrl_data_i                         ( mm_ctrl_data_i        ),
  .mm_ctrl_write_i                        ( mm_ctrl_write_i       ),

  .lookup_data_i                          ( lookup_data_i         ),
  .lookup_bypass_i                        ( lookup_bypass_i       ),
  .lookup_valid_i                         ( lookup_valid_i        ),
    
  .lookup_valid_o                         ( lookup_valid_o        ),
  .lookup_match_o                         ( lookup_match_o        ),
  .lookup_bypass_o                        ( lookup_bypass_o       ),
  .lookup_addr_o                          ( lookup_addr_o         )

);

endmodule
