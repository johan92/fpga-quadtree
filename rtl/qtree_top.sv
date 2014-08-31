module qtree_top
#
( 
  parameter STAGES       = 5,
  parameter D_WIDTH      = 16,
  parameter D_CNT        = 4,
  parameter NEXT_A_WIDTH = ( STAGES + 1 )*2 + $clog2( D_CNT )
)
(
  input                                 clk_i,
  input                                 rst_i,

  qstage_ctrl_if                        stages_ctrl_if,
  qstage_ctrl_if                        match_ctrl_if,

  input                                 lookup_en_i,
  input              [D_WIDTH-1:0]      lookup_data_i,
  
  output                                lookup_done_o,
  output                                lookup_match_o,
  output [NEXT_A_WIDTH-1:0]             lookup_addr_o,
  output [D_WIDTH-1:0]                  lookup_data_o

);

genvar g;

generate
  for( g = 0; g < STAGES; g++ )
    begin : tr
      localparam _A_WIDTH      = ( g == 0 ) ? ( 1 ) : ( g * 2        );
      localparam _NEXT_A_WIDTH = ( g == 0 ) ? ( 2 ) : ( _A_WIDTH + 2 );

      logic                     lookup_en_w;
      logic [_A_WIDTH-1:0]      lookup_addr_w;
      logic [D_WIDTH-1:0]       lookup_data_w;

      logic                     next_lookup_en_w;
      logic [_NEXT_A_WIDTH-1:0] next_lookup_addr_w;
      logic [D_WIDTH-1:0]       next_lookup_data_w;
      

      if( g == 0 )
        begin
          assign lookup_en_w   = lookup_en_i;
          assign lookup_addr_w = '0;
          assign lookup_data_w = lookup_data_i;
        end
      else
        begin
          assign lookup_en_w   = tr[g-1].next_lookup_en_w; 
          assign lookup_addr_w = tr[g-1].next_lookup_addr_w; 
          assign lookup_data_w = tr[g-1].next_lookup_data_w; 
        end
      
      qstage
      #( 
        .A_WIDTH                                ( _A_WIDTH                    ),
        .NEXT_A_WIDTH                           ( _NEXT_A_WIDTH               ),
        .D_WIDTH                                ( D_WIDTH                     )
      ) qs (

        .clk_i                                  ( clk_i                       ),
        .rst_i                                  ( rst_i                       ),

        .ctrl_if                                ( stages_ctrl_if.mport[g].app ),
          
        .lookup_en_i                            ( lookup_en_w                 ),
        .lookup_addr_i                          ( lookup_addr_w               ),
        .lookup_data_i                          ( lookup_data_w               ),
          
        .lookup_en_o                            ( next_lookup_en_w            ),
        .lookup_addr_o                          ( next_lookup_addr_w          ),
        .lookup_data_o                          ( next_lookup_data_w          )

      );
    end

endgenerate

qtree_match
#( 
   .A_WIDTH                               ( ( STAGES + 1 ) * 2 ),
   .NEXT_A_WIDTH                          ( NEXT_A_WIDTH       ), 

   .D_WIDTH                               ( D_WIDTH            ),

   .D_CNT                                 ( D_CNT              )
) qm (
  .clk_i                                  ( clk_i              ),
  .rst_i                                  ( rst_i              ),

  .ctrl_if                                ( match_ctrl_if      ),

  .lookup_en_i                            ( lookup_en_i        ),
  .lookup_addr_i                          ( lookup_addr_i      ),
  .lookup_data_i                          ( lookup_data_i      ),

  .lookup_done_o                          ( lookup_done_o      ),
  .lookup_match_o                         ( lookup_match_o     ),
  .lookup_addr_o                          ( lookup_addr_o      ),
  .lookup_data_o                          ( lookup_data_o      )

);

endmodule
