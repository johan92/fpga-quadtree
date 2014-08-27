module qtree_top
#
( 
  parameter STAGES  = 5,
  parameter D_WIDTH = 16
)
(
  input                                 clk_i,
  input                                 rst_i,

  input                                 lookup_en_i,
  input              [D_WIDTH-1:0]      lookup_data_i,

);

genvar g;

generate
  for( g = 0; g < STAGES; g++ )
    begin : tr
      localparam _A_WIDTH      = ( g == 0 ) ? ( 1 ) : ( g * 2        );
      localparam _NEXT_A_WIDTH = ( g == 0 ) ? ( 2 ) : ( _A_WIDTH + 2 );

      logic                     lookup_en_w;
      logic [_A_WIDTH-1:0]      lookup_addr_w;
      logic [_D_WIDTH-1:0]      lookup_data_w;

      logic                     next_lookup_en_w;
      logic [_NEXT_A_WIDTH-1:0] next_lookup_addr_w;
      logic [_D_WIDTH-1:0]      next_lookup_data_w;
      
      always_comb
        begin
          if( g == 0 )
            begin
              lookup_en_w   = lookup_en_i;
              lookup_addr_w = '0;
              lookup_data_w = lookup_data_i;
            end
          else
            begin
              lookup_en_w   = tr[g-1].next_lookup_en_w; 
              lookup_addr_w = tr[g-1].next_lookup_addr_w; 
              lookup_data_w = tr[g-1].next_lookup_data_w; 
            end
        end

      qstage
      #( 
        .A_WIDTH                                ( _A_WIDTH               ),
        .NEXT_A_WIDTH                           ( _NEXT_A_WIDTH          ),
        .D_WIDTH                                ( D_WIDTH                )
      ) qs (

        .clk_i                                  ( clk_i                  ),
        .rst_i                                  ( rst_i                  ),

        .ctrl_if                                ( ctrl_if                ),
          
        .lookup_en_i                            ( lookup_en_w            ),
        .lookup_addr_i                          ( lookup_addr_w          ),
        .lookup_data_i                          ( lookup_data_w          ),
          
        .lookup_en_o                            ( next_lookup_en_w       ),
        .lookup_addr_o                          ( next_lookup_addr_w     ),
        .lookup_data_o                          ( next_lookup_data_w     )

      );
    end

endgenerate


endmodule
