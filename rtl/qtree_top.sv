module qtree_top #( 
  parameter STAGES_CNT     = 5,
  parameter KEY_WIDTH      = 16,
  parameter D_CNT          = 4,
  parameter BYPASS_WIDTH   = 1,
  parameter OUT_ADDR_WIDTH = ( STAGES + 1 )*2 + $clog2( D_CNT )
) (
  input                                   clk_i,
  input                                   rst_i,

  input              [KEY_WIDTH-1:0]      lookup_data_i,
  input              [BYPASS_WIDTH-1:0]   lookup_bypass_i,
  input                                   lookup_valid_i,
  
  output                                  lookup_valid_o,
  output                                  lookup_match_o,
  output             [BYPASS_WIDTH-1:0]   lookup_bypass_o,
  output             [OUT_ADDR_WIDTH-1:0] lookup_addr_o,
  output             [KEY_WIDTH    -1:0]  lookup_data_o

);

`include "defs.vh"

localparam QSTAGE_DATA_WIDTH = $bits(qstage_data_t);  

logic [0:STAGES_CNT-1][QSTAGE_DATA_WIDTH-1:0] qstage_in_data_w;
logic [0:STAGES_CNT-1][BYPASS_WIDTH-1:0]      qstage_in_bypass_w;
logic [0:STAGES_CNT-1]                        qstage_in_valid_w;

logic [0:STAGES_CNT-1][QSTAGE_DATA_WIDTH-1:0] qstage_out_data_w;
logic [0:STAGES_CNT-1][BYPASS_WIDTH-1:0]      qstage_out_bypass_w;
logic [0:STAGES_CNT-1]                        qstage_out_valid_w;

genvar g;

generate
  for( g = 0; g < STAGES; g++ )
    begin : tr
      localparam _IN_ADDR_WIDTH = ( g == 0 ) ? ( 1 ) : ( g * 2        );

      if( g == 0 ) begin : g_first_stage
        qstage_data_t _qstage_data;
        
        always_comb begin
          _qstage_data = 'x;
          _qstage_data.addr = '0;
          _qstage_data.lookup_value = lookup_data_i;
        end
        
        assign qstage_in_data_w   [g] = _qstage_data; 
        assign qstage_in_bypass_w [g] = lookup_bypass_i; 
        assign qstage_in_valid_w  [g] = lookup_valid_i;

      end else begin : other_stages
        assign qstage_in_data_w   [g] = qstage_out_data_w  [g-1]; 
        assign qstage_in_bypass_w [g] = qstage_out_bypass_w[g-1]; 
        assign qstage_in_valid_w  [g] = qstage_out_valid_w [g-1];
      end
      
      qstage #( 
        .ADDR_WIDTH             ( OUT_ADDR_WIDTH    ),  
        .KEY_WIDTH              ( KEY_WIDTH         ),  
        .DATA_WIDTH             ( QSTAGE_DATA_WIDTH ),  
        .BYPASS_WIDTH           ( BYPASS_WIDTH      ),  
                                     
        .RAM_ADDR_WIDTH         ( _IN_ADDR_WIDTH    ),  
                                     
        .RAM_OUT_REG_ENABLE     ( 0                 ),  
        .STAGE0_OUT_REG_ENABLE  ( 0                 ),  
        .STAGE1_OUT_REG_ENABLE  ( 0                 )   
      ) qs (

        .clk_i                  ( clk_i                   ),
        .rst_i                  ( rst_i                   ),

        .mm_ram_data_i          ( mm_ram_data_i           ),
        .mm_ram_addr_i          ( mm_ram_addr_i           ),
        .mm_ram_write_i         ( mm_ram_write_i          ),
          
        .in_data_i              ( qstage_in_data_w    [g] ),
        .in_bypass_i            ( qstage_in_bypass_w  [g] ),
        .in_valid_i             ( qstage_in_valid_w   [g] ),
          
        .out_data_o             ( qstage_out_data_w   [g] ),
        .out_bypass_o           ( qstage_out_bypass_w [g] ),
        .out_valid_o            ( qstage_out_valid_w  [g] )

      );
    end

endgenerate

qtree_match #( 
  .IN_ADDR_WIDTH                         ( IN_ADDR_WIDTH      ),
  .OUT_ADDR_WIDTH                        ( OUT_ADDR_WIDTH     ), 
  .DATA_WIDTH                            ( DATA_WIDTH         ),
  .D_CNT                                 ( D_CNT              )
) qm (
  .clk_i                                 ( clk_i              ),
  .rst_i                                 ( rst_i              ),

  .ctrl_if                               ( match_ctrl_if      ),

  .lookup_valid_i                        ( lookup_valid_i     ),
  .lookup_addr_i                         ( lookup_addr_i      ),
  .lookup_data_i                         ( lookup_data_i      ),

  .lookup_done_o                         ( lookup_done_o      ),
  .lookup_match_o                        ( lookup_match_o     ),
  .lookup_addr_o                         ( lookup_addr_o      ),
  .lookup_data_o                         ( lookup_data_o      )

);

endmodule
