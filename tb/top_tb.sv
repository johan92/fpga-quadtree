`include "../rtl/defs.vh"

module top_tb;

logic clk;
logic rst;

initial
  begin
    clk = 1'b0;
    forever 
      begin
        #5.0ns clk = ~clk;
      end
  end

initial
  begin
    rst = 1'b0;
    #2.0ns 
    rst = 1'b1;
    #5.0ns
    rst = 1'b0;
  end


function int read_tree( input string fname );
  integer fd;
  integer code;
  
  int stage;
  int addr;
  ram_data_t data;

  fd = $fopen( fname, "r" );
  
  while( 1 )
    begin
      code = $fscanf( fd, "%d %d %d %d %d ", stage, addr, data.l, data.m, data.r );

      if( code <= 0 )
        begin
          return 0;
        end

      $display("%d %d %d %d %d", stage, addr, data.l, data.m, data.r );
    end
  
endfunction

initial
  begin
    read_tree("tree");
  end


qstage_ctrl_if 
#
(
  .A_WIDTH             ( 8           ),
  .D_TYPE              ( ram_data_t  ),
  .PARTS_CNT           ( `STAGES_CNT )
) stages_ctrl_if (

  .clk_i ( clk )

);

qstage_ctrl_if 
#
(
  .A_WIDTH             ( 8                 ),
  .D_TYPE              ( match_ram_data_t  ),
  .PARTS_CNT           ( `D_CNT            )
) match_ctrl_if (

  .clk_i ( clk )

);

qtree_top
#
( 
  .STAGES                                 ( `STAGES_CNT ),
  .D_WIDTH                                ( `D_WIDTH    ),
  .D_CNT                                  ( `D_CNT      )
) qt (
  .clk_i                                  ( clk               ),
  .rst_i                                  ( rst               ),

  .stages_ctrl_if                         ( stages_ctrl_if    ),
  .match_ctrl_if                          ( match_ctrl_if     ),

  .lookup_en_i                            ( lookup_en_i       ),
  .lookup_data_i                          ( lookup_data_i     ),
    
  .lookup_done_o                          ( lookup_done_o     ),
  .lookup_match_o                         ( lookup_match_o    ),
  .lookup_addr_o                          ( lookup_addr_o     ),
  .lookup_data_o                          ( lookup_data_o     )

);


endmodule
