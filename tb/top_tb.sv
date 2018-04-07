module top_tb;

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

`include "defs.vh"
`include "tb_defs.vh"

bit clk;
bit rst;
bit rst_done;

always #5ns clk = ~clk;

initial
  begin
    rst <= 1'b1;
    @(posedge clk);
    @(posedge clk);
    @(negedge clk);
    rst <= 1'b0;

    rst_done = 1'b1;
  end


Segments     segments;
LevelRamData level_ram_data;
MatchRamData match_ram_data;

initial
  begin
    segments       = new();
    level_ram_data = new();
    match_ram_data = new();

    segments.load      ("./test_cases/test_01_segments" );
    level_ram_data.load("./test_cases/test_01_level_ram");
    match_ram_data.load("./test_cases/test_01_match_ram");
  end

//  --------------------------------------------------------------------------- 
//  ST BFM 
//  ---------------------------------------------------------------------------

localparam ST_BFM_DATA_WIDTH = KEY_WIDTH;

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

//  --------------------------------------------------------------------------- 
//  MM 
//  ---------------------------------------------------------------------------

logic [MM_ADDR_WIDTH-1:0] mm_ctrl_addr;
logic [MM_DATA_WIDTH-1:0] mm_ctrl_data;
logic                     mm_ctrl_write;

task automatic ctrl_level_ram();
  @(posedge clk);

  foreach(level_ram_data.cmds[i]) begin
    mm_ctrl_addr <= level_ram_data.cmds[i].addr;
    mm_ctrl_addr[MM_ADDR_WIDTH-1] <= 1'b0;
    
    mm_ctrl_data  <= level_ram_data.cmds[i].data;
    mm_ctrl_write <= 1'b0;
    
    @(posedge clk);
    mm_ctrl_write <= 1'b1;
    
    @(posedge clk);
    mm_ctrl_write <= 1'b0;
  end
endtask

task automatic ctrl_match_ram();
  @(posedge clk);

  foreach(match_ram_data.cmds[i]) begin
    mm_ctrl_addr <= match_ram_data.cmds[i].addr;
    mm_ctrl_addr[MM_ADDR_WIDTH-1] <= 1'b1;
    
    mm_ctrl_data  <= match_ram_data.cmds[i].data;
    mm_ctrl_write <= 1'b0;
    
    @(posedge clk);
    mm_ctrl_write <= 1'b1;
    
    @(posedge clk);
    mm_ctrl_write <= 1'b0;
  end
endtask

initial begin
  wait(rst_done);

  ctrl_level_ram();
  ctrl_match_ram();
end

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
) dut (
  .clk_i                                  ( clk               ),
  .rst_i                                  ( rst               ),
  
  .mm_ctrl_addr_i                         ( mm_ctrl_addr      ),
  .mm_ctrl_data_i                         ( mm_ctrl_data      ),
  .mm_ctrl_write_i                        ( mm_ctrl_write     ),

  .lookup_data_i                          ( st_bfm_data       ),
  .lookup_bypass_i                        ( 1'b0              ),
  .lookup_valid_i                         ( st_bfm_valid      ),
    
  .lookup_valid_o                         (    ),
  .lookup_match_o                         (    ),
  .lookup_bypass_o                        (    ),
  .lookup_addr_o                          (    )

);


endmodule
