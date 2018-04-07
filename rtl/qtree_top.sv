module qtree_top #( 
  parameter LEVEL_CNT      = 5,
  parameter LEVEL_WIDTH    = $clog2(LEVEL_CNT),
  parameter KEY_WIDTH      = 16,
  parameter MATCH_CELL_CNT = 4,
  parameter MATCH_CELL_CNT_WIDTH = -1,
  
  parameter ADDR_WIDTH     = -1, 

  parameter BYPASS_WIDTH   = 1,
  
  parameter MM_ADDR_WIDTH  = 8,
  parameter MM_DATA_WIDTH  = 128

) (
  input                            clk_i,
  input                            rst_i,
  
  input     [MM_ADDR_WIDTH - 1:0]  mm_ctrl_addr_i,
  input     [MM_DATA_WIDTH - 1:0]  mm_ctrl_data_i,
  input                            mm_ctrl_write_i,

  input     [KEY_WIDTH-1:0]        lookup_data_i,
  input     [BYPASS_WIDTH-1:0]     lookup_bypass_i,
  input                            lookup_valid_i,
  
  output                           lookup_valid_o,
  output                           lookup_match_o,
  output    [BYPASS_WIDTH-1:0]     lookup_bypass_o,
  output    [ADDR_WIDTH  -1:0]     lookup_addr_o

);

`include "func_defs.vh"

localparam LAST_STAGE_ADDR_WIDTH = get_level_ram_width(LEVEL_CNT-1); 

`include "mm_defs.vh"
`include "defs.vh"

localparam LEVEL_DATA_WIDTH = $bits(level_data_t);  

logic [0:LEVEL_CNT-1][LEVEL_DATA_WIDTH-1:0] level_in_data_w;
logic [0:LEVEL_CNT-1][BYPASS_WIDTH-1:0]     level_in_bypass_w;
logic [0:LEVEL_CNT-1]                       level_in_valid_w;

logic [0:LEVEL_CNT-1][LEVEL_DATA_WIDTH-1:0] level_out_data_w;
logic [0:LEVEL_CNT-1][BYPASS_WIDTH-1:0]     level_out_bypass_w;
logic [0:LEVEL_CNT-1]                       level_out_valid_w;

mm_addr_level_t mm_addr_level;
mm_addr_match_t mm_addr_match;

logic is_mm_addr_level;
logic is_mm_addr_match;

assign is_mm_addr_level = (mm_ctrl_addr_i[MM_ADDR_WIDTH-1] == 1'b0);
assign is_mm_addr_match = (mm_ctrl_addr_i[MM_ADDR_WIDTH-1] == 1'b1);

assign mm_addr_level = mm_ctrl_addr_i[$bits(mm_addr_level)-1:0];
assign mm_addr_match = mm_ctrl_addr_i[$bits(mm_addr_match)-1:0];

genvar g;

generate
  for( g = 0; g < LEVEL_CNT; g++ )
    begin : g_levels
      localparam _RAM_ADDR_WIDTH = ( g == 0 ) ? ( 1 ) : ( g * 2 );

      if( g == 0 ) begin : g_first_stage
        level_data_t _level_data;
        
        always_comb begin
          _level_data = 'x;
          _level_data.addr = '0;
          _level_data.lookup_value = lookup_data_i;
        end
        
        assign level_in_data_w   [g] = _level_data; 
        assign level_in_bypass_w [g] = lookup_bypass_i; 
        assign level_in_valid_w  [g] = lookup_valid_i;

      end else begin : other_stages
        assign level_in_data_w   [g] = level_out_data_w  [g-1]; 
        assign level_in_bypass_w [g] = level_out_bypass_w[g-1]; 
        assign level_in_valid_w  [g] = level_out_valid_w [g-1];
      end

      logic _mm_write;

      assign _mm_write = mm_ctrl_write_i && (is_mm_addr_level) && (g == mm_addr_level.level_num);
      
      qtree_level #( 
        .ADDR_WIDTH             ( OUT_ADDR_WIDTH    ),  
        .KEY_WIDTH              ( KEY_WIDTH         ),  
        .DATA_WIDTH             ( LEVEL_DATA_WIDTH  ),  
        .BYPASS_WIDTH           ( BYPASS_WIDTH      ),  
                                     
        .RAM_ADDR_WIDTH         ( _RAM_ADDR_WIDTH   ),  
                                     
        .RAM_OUT_REG_ENABLE     ( 0                 ),  
        .STAGE0_OUT_REG_ENABLE  ( 0                 ),  
        .STAGE1_OUT_REG_ENABLE  ( 0                 )   
      ) level (

        .clk_i                  ( clk_i                  ),
        .rst_i                  ( rst_i                  ),

        .mm_ram_data_i          ( mm_ctrl_data_i         ),
        .mm_ram_addr_i          ( mm_addr_level.ram_addr ),
        .mm_ram_write_i         ( _mm_write              ),
          
        .in_data_i              ( level_in_data_w    [g] ),
        .in_bypass_i            ( level_in_bypass_w  [g] ),
        .in_valid_i             ( level_in_valid_w   [g] ),
          
        .out_data_o             ( level_out_data_w   [g] ),
        .out_bypass_o           ( level_out_bypass_w [g] ),
        .out_valid_o            ( level_out_valid_w  [g] )

      );
    end

endgenerate

logic ram_match_write;

assign ram_match_write = is_mm_addr_match && mm_ctrl_write_i;

qtree_match #( 
  .ADDR_WIDTH                            ( ADDR_WIDTH              ), 
                                                                    
  .IN_DATA_WIDTH                         ( IN_DATA_WIDTH           ),
  .KEY_WIDTH                             ( KEY_WIDTH               ),
                                                                    
  .BYPASS_WIDTH                          ( BYPASS_WIDTH            ),
                                                                    
  .RAM_DATA_WIDTH                        ( RAM_DATA_WIDTH          ),
  .RAM_ADDR_WIDTH                        ( RAM_ADDR_WIDTH          ),
                                                                
  .MATCH_CELL_CNT                        ( MATCH_CELL_CNT          ),
  .MATCH_CELL_CNT_WIDTH                  ( MATCH_CELL_CNT_WIDTH    ),
                                                                
  .RAM_OUT_REG_ENABLE                    ( RAM_OUT_REG_ENABLE      ),
  .STAGE0_OUT_REG_ENABLE                 ( STAGE0_OUT_REG_ENABLE   ),
  .STAGE1_OUT_REG_ENABLE                 ( STAGE1_OUT_REG_ENABLE   )

) match (
  .clk_i                                 ( clk_i                   ),
  .rst_i                                 ( rst_i                   ),

  .ram_data_i                            ( mm_ctrl_data_i          ),
  .ram_addr_i                            ( mm_addr_match.ram_addr  ),
  .ram_cell_i                            ( mm_addr_match.cell_num  ),
  .ram_write_i                           ( ram_match_write         ),

  .lookup_addr_i                         ( lookup_addr_i           ),
  .lookup_data_i                         ( lookup_data_i           ),
  .lookup_valid_i                        ( lookup_valid_i          ),

  .lookup_done_o                         ( lookup_done_o           ),
  .lookup_match_o                        ( lookup_match_o          ),
  .lookup_addr_o                         ( lookup_addr_o           ),
  .lookup_data_o                         ( lookup_data_o           )

);

endmodule
