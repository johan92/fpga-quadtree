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

//  --------------------------------------------------------------------------- 
//  ST BFM 
//  ---------------------------------------------------------------------------

localparam ST_BFM_DATA_WIDTH = 32;

logic [ST_BFM_DATA_WIDTH-1:0] st_bfm_data;
logic                         st_bfm_valid;
logic                         st_bfm_ready;

altera_avalon_st_source_bfm #( 
  .ST_SYMBOL_W          ( 1                  ),
  
  .ST_NUMSYMBOLS        ( ST_BFM_DATA_WIDTH  ),

  .ST_CHANNEL_W         ( 0                  ), 
  .ST_ERROR_W           ( 0                  ), 
  .ST_EMPTY_W           ( 0                  ), 
 
  .ST_READY_LATENCY     ( 0                  ), 
  .ST_MAX_CHANNELS      ( 1                  ), 
  .USE_PACKET           ( 0                  ), 
  .USE_CHANNEL          ( 0                  ), 
  .USE_ERROR            ( 0                  ), 
  .USE_READY            ( 1                  ), 
  .USE_VALID            ( 1                  ), 
  .USE_EMPTY            ( 0                  ), 

  .ST_BEATSPERCYCLE     ( 1                  ) 
) st_bfm (
  .clk                  ( clk                ),
  .reset                ( rst                ),
  
  .src_data             ( st_bfm_data        ),
  .src_valid            ( st_bfm_valid       ),
  .src_channel          (                    ),
  .src_startofpacket    (                    ),
  .src_endofpacket      (                    ),
  .src_error            (                    ),
  .src_empty            (                    ),
  .src_ready            ( st_bfm_ready       )
);

assign st_bfm_ready = 1'b1;

task automatic st_bfm_send( logic [31:0] _data );
   while( st_bfm.get_transaction_queue_size() > 0 ) begin
     @( st_bfm.signal_src_driving_transaction );
   end

   while( st_bfm.get_response_queue_size() ) begin
     st_bfm.pop_response();
   end

   st_bfm.set_transaction_data( _data );
   st_bfm.push_transaction();
endtask

qtree_top #( 
  .STAGES                                 ( `STAGES_CNT ),
  .D_WIDTH                                ( `D_WIDTH    ),
  .D_CNT                                  ( `D_CNT      )
) dut (
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
