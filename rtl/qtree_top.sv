module qtree_top #( 
  // main "global" defines
  parameter LEVEL_CNT            = 5,
  parameter KEY_WIDTH            = 16,
  parameter MATCH_CELL_CNT       = 4,
  parameter BYPASS_WIDTH         = 1,
  
  // other defines. recalculated from global
  parameter LEVEL_WIDTH          = -1,
  parameter MATCH_CELL_CNT_WIDTH = -1,
  
  parameter ADDR_WIDTH           = -1, 
  
  parameter MM_ADDR_WIDTH        = -1,
  parameter MM_DATA_WIDTH        = -1,

  parameter LEVEL_RAM_DATA_WIDTH = -1,
  parameter MATCH_RAM_DATA_WIDTH = -1,
  parameter MATCH_RAM_ADDR_WIDTH = -1,
  
  // regs enable
  parameter LEVEL_RAM_OUT_REG_ENABLE    = 0, 
  parameter LEVEL_STAGE0_OUT_REG_ENABLE = 0,
  parameter LEVEL_STAGE1_OUT_REG_ENABLE = 0,
  
  parameter MATCH_RAM_OUT_REG_ENABLE    = 0, 
  parameter MATCH_STAGE0_OUT_REG_ENABLE = 0,
  parameter MATCH_STAGE1_OUT_REG_ENABLE = 0

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
        .ADDR_WIDTH             ( ADDR_WIDTH             ),  
        .KEY_WIDTH              ( KEY_WIDTH              ),  
        .DATA_WIDTH             ( LEVEL_DATA_WIDTH       ),  
        .BYPASS_WIDTH           ( BYPASS_WIDTH           ),  
                                     
        .RAM_ADDR_WIDTH         ( _RAM_ADDR_WIDTH        ), 
        .RAM_DATA_WIDTH         ( LEVEL_RAM_DATA_WIDTH   ),
                                     
        .RAM_OUT_REG_ENABLE     ( LEVEL_RAM_OUT_REG_ENABLE    ), 
        .STAGE0_OUT_REG_ENABLE  ( LEVEL_STAGE0_OUT_REG_ENABLE ),  
        .STAGE1_OUT_REG_ENABLE  ( LEVEL_STAGE1_OUT_REG_ENABLE )   
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
                                                                    
  .IN_DATA_WIDTH                         ( LEVEL_DATA_WIDTH        ),
  .KEY_WIDTH                             ( KEY_WIDTH               ),
                                                                    
  .BYPASS_WIDTH                          ( BYPASS_WIDTH            ),
                                                                    
  .RAM_DATA_WIDTH                        ( MATCH_RAM_DATA_WIDTH    ),
  .RAM_ADDR_WIDTH                        ( MATCH_RAM_ADDR_WIDTH    ),
                                                                
  .MATCH_CELL_CNT                        ( MATCH_CELL_CNT          ),
  .MATCH_CELL_CNT_WIDTH                  ( MATCH_CELL_CNT_WIDTH    ),
                                                                
  .RAM_OUT_REG_ENABLE                    ( MATCH_RAM_OUT_REG_ENABLE    ),
  .STAGE0_OUT_REG_ENABLE                 ( MATCH_STAGE0_OUT_REG_ENABLE ),
  .STAGE1_OUT_REG_ENABLE                 ( MATCH_STAGE1_OUT_REG_ENABLE )

) match (
  .clk_i                                 ( clk_i                   ),
  .rst_i                                 ( rst_i                   ),

  .ram_data_i                            ( mm_ctrl_data_i          ),
  .ram_addr_i                            ( mm_addr_match.ram_addr  ),
  .ram_cell_i                            ( mm_addr_match.cell_num  ),
  .ram_write_i                           ( ram_match_write         ),

  .in_data_i                             ( level_out_data_w   [LEVEL_CNT-1] ),
  .in_bypass_i                           ( level_out_bypass_w [LEVEL_CNT-1] ),
  .in_valid_i                            ( level_out_valid_w  [LEVEL_CNT-1] ),

  .lookup_match_o                        ( lookup_match_o                   ),
  .lookup_addr_o                         ( lookup_addr_o                    ),
  .lookup_bypass_o                       ( lookup_bypass_o                  ),
  .lookup_valid_o                        ( lookup_valid_o                   )

);

// synthesis translate_off
function automatic display_parameters();
  $display("%t: %m: LEVEL_CNT            = %d", $time(), LEVEL_CNT             ); 
  $display("%t: %m: KEY_WIDTH            = %d", $time(), KEY_WIDTH             );
  $display("%t: %m: MATCH_CELL_CNT       = %d", $time(), MATCH_CELL_CNT        );
  $display("%t: %m: BYPASS_WIDTH         = %d", $time(), BYPASS_WIDTH          );
  $display("%t: %m: LEVEL_WIDTH          = %d", $time(), LEVEL_WIDTH           );
  $display("%t: %m: MATCH_CELL_CNT_WIDTH = %d", $time(), MATCH_CELL_CNT_WIDTH  );
  $display("%t: %m: ADDR_WIDTH           = %d", $time(), ADDR_WIDTH            );
  $display("%t: %m: MM_ADDR_WIDTH        = %d", $time(), MM_ADDR_WIDTH         );
  $display("%t: %m: MM_DATA_WIDTH        = %d", $time(), MM_DATA_WIDTH         );
  $display("%t: %m: LEVEL_RAM_DATA_WIDTH = %d", $time(), LEVEL_RAM_DATA_WIDTH  );
  $display("%t: %m: MATCH_RAM_DATA_WIDTH = %d", $time(), MATCH_RAM_DATA_WIDTH  );
  $display("%t: %m: MATCH_RAM_ADDR_WIDTH = %d", $time(), MATCH_RAM_ADDR_WIDTH  );
endfunction

initial begin
  display_parameters();
end
// synthesis translate_on

//  --------------------------------------------------------------------------- 
//  RefModel/SelfChecker
//  ---------------------------------------------------------------------------

// synthesis translate_off

`include "segments.sv"
`include "qtree_ref_model.sv"

dut_in_t  checker_dut_in;
logic     checker_dut_in_valid;

dut_out_t checker_dut_out;
logic     checker_dut_out_valid;

always_comb begin
  checker_dut_in.data    = lookup_data_i; 
  checker_dut_in.bypass  = lookup_bypass_i;
  checker_dut_in_valid   = lookup_valid_i;

  checker_dut_out.match  = lookup_match_o;
  checker_dut_out.addr   = lookup_addr_o;
  checker_dut_out.bypass = lookup_bypass_o;
  checker_dut_out_valid  = lookup_valid_o;
end

QTreeRefModel ref_model;
bit           use_ref_model;

initial begin
  ref_model = new();
end

always_ff @( posedge clk_i ) begin
  if(use_ref_model) begin

    if(checker_dut_in_valid) begin
      ref_model.put_dut_in(checker_dut_in);
    end

    if(checker_dut_out_valid) begin
      ref_model.put_dut_out(checker_dut_out);
    end

  end
end

initial begin
  wait(use_ref_model);

  ref_model.thread_check();
end

// synthesis translate_on

endmodule
