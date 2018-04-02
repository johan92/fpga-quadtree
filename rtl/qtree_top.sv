module qtree_top #( 
  parameter STAGES         = 5,
  parameter DATA_WIDTH     = 16,
  parameter D_CNT          = 4,
  parameter OUT_ADDR_WIDTH = ( STAGES + 1 )*2 + $clog2( D_CNT )
) (
  input                                   clk_i,
  input                                   rst_i,

  qstage_ctrl_if                          stages_ctrl_if,
  qstage_ctrl_if                          match_ctrl_if,

  input                                   lookup_valid_i,
  input              [DATA_WIDTH-1:0]     lookup_data_i,
  
  output                                  lookup_valid_o,
  output                                  lookup_match_o,
  output             [OUT_ADDR_WIDTH-1:0] lookup_addr_o,
  output             [DATA_WIDTH    -1:0] lookup_data_o

);

genvar g;

generate
  for( g = 0; g < STAGES; g++ )
    begin : tr
      localparam _IN_ADDR_WIDTH      = ( g == 0 ) ? ( 1 ) : ( g * 2        );
      localparam _NEXT_ADDR_WIDTH = ( g == 0 ) ? ( 2 ) : ( _A_WIDTH + 2 );

      logic                        _lookup_valid_w;
      logic [_ADDR_WIDTH-1:0]      _lookup_addr_w;
      logic [DATA_WIDTH-1:0]       _lookup_data_w;

      logic                        _next_lookup_valid_w;
      logic [_NEXT_ADDR_WIDTH-1:0] _next_lookup_addr_w;
      logic [DATA_WIDTH-1:0]       _next_lookup_data_w;

      if( g == 0 ) begin
        assign _lookup_addr_w  = '0;
        assign _lookup_data_w  = lookup_data_i;
        assign _lookup_valid_w = lookup_valid_i;
      end else begin
        assign _lookup_addr_w  = tr[g-1]._next_lookup_addr_w; 
        assign _lookup_data_w  = tr[g-1]._next_lookup_data_w; 
        assign _lookup_valid_w = tr[g-1]._next_lookup_valid_w; 
      end
      
      qstage #( 
        .IN_ADDR_WIDTH        ( _ADDR_WIDTH                 ),
        .OUT_ADDR_WIDTH       ( _NEXT_ADDR_WIDTH            ),
        .DATA_WIDTH           ( DATA_WIDTH                  )
      ) qs (

        .clk_i                ( clk_i                       ),
        .rst_i                ( rst_i                       ),

        .ctrl_if              ( stages_ctrl_if.mport[g].app ),
          
        .lookup_addr_i        ( _lookup_addr_w              ),
        .lookup_data_i        ( _lookup_data_w              ),
        .lookup_valid_i       ( _lookup_valid_w             ),
          
        .lookup_addr_o        ( _next_lookup_addr_w         ),
        .lookup_data_o        ( _next_lookup_data_w         ),
        .lookup_valid_o       ( _next_lookup_valid_w        )

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
