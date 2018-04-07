module qtree_level #(
  parameter ADDR_WIDTH     = 4,
  parameter KEY_WIDTH      = 16,
  parameter DATA_WIDTH     = 16,
  parameter BYPASS_WIDTH   = 1,
  
  parameter RAM_ADDR_WIDTH = 1,

  parameter RAM_OUT_REG_ENABLE    = 0,
  parameter STAGE0_OUT_REG_ENABLE = 0,
  parameter STAGE1_OUT_REG_ENABLE = 0,
  
  // internal parameter 
  parameter RAM_DATA_WIDTH = KEY_WIDTH * 3
) (
  input                            clk_i,
  input                            rst_i,

  input     [RAM_DATA_WIDTH - 1:0] mm_ram_data_i,
  input     [RAM_ADDR_WIDTH - 1:0] mm_ram_addr_i,
  input                            mm_ram_write_i,
  
  input     [DATA_WIDTH     - 1:0] in_data_i,
  input     [BYPASS_WIDTH   - 1:0] in_bypass_i,
  input                            in_valid_i,
  
  output    [DATA_WIDTH     - 1:0] out_data_o,
  output    [BYPASS_WIDTH   - 1:0] out_bypass_o,
  output                           out_valid_o

);

`include "defs.vh"

typedef struct packed {
  level_data_t              in_data;

  logic                     le_l;
  logic                     le_m;
  logic                     le_r;

  logic [1:0]               next_addr_postfix;
  
  logic [BYPASS_WIDTH-1:0]  bypass;
} level_pipe_data_t;

level_data_t             in_data;

level_pipe_data_t        stage0_in;
logic                    stage0_in_valid;

level_pipe_data_t        stage0_out; 
logic                    stage0_out_valid;

level_pipe_data_t        stage1_in;
logic                    stage1_in_valid;

level_pipe_data_t        stage1_out; 
logic                    stage1_out_valid;

level_pipe_data_t        stage2_in; 
logic                    stage2_in_valid;

assign in_data = in_data_i; 

//  --------------------------------------------------------------------------- 
//  STAGE 0: Reading from RAM
//  ---------------------------------------------------------------------------
level_ram_data_t     ram_read_data;
level_pipe_data_t    stage0_ram_out;
logic                 stage0_ram_out_valid;

always_comb begin
  stage0_in = 'x;
  stage0_in_valid = in_valid_i;

  stage0_in.in_data = in_data;
  stage0_in.bypass  = in_bypass_i;
end

simple_ram_with_delay #( 
  .DATA_WIDTH       ( RAM_DATA_WIDTH                              ), 
  .ADDR_WIDTH       ( RAM_ADDR_WIDTH                              ),
  .BYPASS_WIDTH     ( $bits(stage_0_in)                           ),
  .OUT_REG_ENABLE   ( RAM_OUT_REG_ENABLE                          )
) ram (
  .clk_i            ( clk_i                                       ),
  .rst_i            ( rst_i                                       ),

  .wr_addr_i        ( mm_ram_addr_i                               ),
  .wr_data_i        ( mm_ram_data_i                               ),
  .wr_enable_i      ( mm_ram_write_i                              ),

  .in_read_addr_i   ( stage0_in.in_data.addr[RAM_ADDR_WIDTH-1:0]  ),
  .in_bypass_i      ( stage0_in                                   ),
  .in_valid_i       ( stage0_in_valid                             ),

  .out_read_data_o  ( ram_read_data                               ),
  .out_bypass_o     ( stage0_ram_out                              ),
  .out_valid_o      ( stage0_ram_out_valid                        )
);

always_comb begin
  stage0_out       = stage0_ram_out;
  stage0_out_valid = stage0_ram_out_valid;

  stage0_out.le_l  = (stage0_out.in_data.lookup_value <= ram_read_data.l);
  stage0_out.le_m  = (stage0_out.in_data.lookup_value <= ram_read_data.m);
  stage0_out.le_r  = (stage0_out.in_data.lookup_value <= ram_read_data.r);
end

delay #(
  .DATA_WIDTH   ( $bits(stage0_out)        ),
  .ENABLE       ( STAGE0_OUT_REG_ENABLE    )
) delay_stage0 (
  .clk_i        ( clk_i                    ),
  .rst_i        ( rst_i                    ),

  .in_data_i    ( stage0_out               ),
  .in_valid_i   ( stage0_out_valid         ),

  .out_data_o   ( stage1_in                ),
  .out_valid_o  ( stage1_in_valid          )

);

//  --------------------------------------------------------------------------- 
//  STAGE 1: Next addr postfix calculation 
//  ---------------------------------------------------------------------------

always_comb begin
  stage1_out       = stage1_in;
  stage1_out_valid = stage1_in_valid;

  casex( { stage1_out.le_l, stage1_out.le_m, stage1_out.le_r } )
      3'b01x:  stage1_out.next_addr_postfix = 'd1;
      3'b001:  stage1_out.next_addr_postfix = 'd2;
      3'b000:  stage1_out.next_addr_postfix = 'd3;
      default: stage1_out.next_addr_postfix = 'd0;
  endcase
end

delay #(
  .DATA_WIDTH   ( $bits(stage1_out)        ),
  .ENABLE       ( STAGE1_OUT_REG_ENABLE    )
) delay_stage1 (
  .clk_i        ( clk_i                    ),
  .rst_i        ( rst_i                    ),

  .in_data_i    ( stage1_out               ),
  .in_valid_i   ( stage1_out_valid         ),

  .out_data_o   ( stage2_in                ),
  .out_valid_o  ( stage2_in_valid          )

);

//  --------------------------------------------------------------------------- 
//  STAGE 2: Output "calculations"
//  ---------------------------------------------------------------------------
level_data_t             out_data;
logic                    out_valid;
logic [BYPASS_WIDTH-1:0] out_bypass;
always_comb begin
  out_data   = 'x;

  out_valid  = stage2_in_valid;
  out_bypass = stage2_in.bypass;

  out_data.lookup_value = stage2_in.in_data.lookup_value;
  out_data.addr         = ( RAM_ADDR_WIDTH == 1 ) ? (                        stage2_in.next_addr_postfix   ):
                                                    ( { stage2.in_data.addr, stage2_in.next_addr_postfix } );
end

assign out_data_o   = out_data;
assign out_valid_o  = out_valid;
assign out_bypass_o = out_bypass;

// synthesis translate_off
initial begin
  if( RAM_DATA_WIDTH != $bits(level_ram_data_t) ) begin
    $error( "Data width mismatch RAM_DATA_WIDTH = %d $bits(level_ram_data_t) = %d",
                                 RAM_DATA_WIDTH,     $bits(level_ram_data_t) );
    $stop();                               
  end
end
// synthesis translate_on

endmodule
