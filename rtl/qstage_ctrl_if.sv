`include "defs.vh"

interface qstage_ctrl_if( input clk_i );
  parameter A_WIDTH         = 4;
  parameter type D_TYPE     = int;
  parameter PARTS_CNT       = 4;
  parameter PARTS_CNT_WIDTH = $clog2( PARTS_CNT );

  logic [A_WIDTH-1:0]         wr_addr;
  logic                       wr_en;
  D_TYPE                      wr_data;
  logic [PARTS_CNT_WIDTH-1:0] wr_sel;


  modport csr(
    output wr_addr,
           wr_en,
           wr_sel,
           wr_data
  );
 
/*
Idea from dxp at:
  http://electronix.ru/forum/index.php?s=&showtopic=117095&view=findpost&p=1213836
*/

genvar g;
generate
  for( g = 0; g < PARTS_CNT; g++ )
    begin : mport
      logic sel;
      assign sel = ( g == wr_sel );

      modport app
      (
        input  .wr_addr  (  wr_addr        ),
        input  .wr_data  (  wr_data        ),
        input  .wr_en    (  wr_en && sel   )
      );

    end
endgenerate

endinterface

