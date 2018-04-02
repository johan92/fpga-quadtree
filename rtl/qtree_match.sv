`include "defs.vh"

module qtree_match #( 
   parameter IN_ADDR_WIDTH  = 4,
   parameter OUT_ADDR_WIDTH = 6, 

   parameter DATA_WIDTH     = 16,

   parameter D_CNT          = 4
) (
  input                         clk_i,
  input                         rst_i,

  qstage_ctrl_if                ctrl_if,

  input  [IN_ADDR_WIDTH  - 1:0] lookup_addr_i,
  input  [DATA_WIDTH     - 1:0] lookup_data_i,
  input                         lookup_valid_i,

  output                        lookup_match_o,
  output [OUT_ADDR_WIDTH - 1:0] lookup_addr_o,
  output [DATA_WIDTH     - 1:0] lookup_data_o,
  output                        lookup_valid_o

);

localparam DELAY = 3;

logic [DELAY-1:0]                 lookup_valid_d;
logic [DELAY-1:0][ADDR_WIDTH-1:0] lookup_addr_d;
logic [DELAY-1:0][DATA_WIDTH-1:0] lookup_data_d;

genvar g;

generate
  for( g = 0; g < DELAY; g++ ) begin : g_delay
    if( g == 0 ) begin

      always_comb begin
        lookup_addr_d  [0] = lookup_addr_i;
        lookup_data_d  [0] = lookup_data_i;
        lookup_valid_d [0] = lookup_valid_i;
      end

    end else begin

      always_ff @( posedge clk_i or posedge rst_i )
        if( rst_i ) begin
          lookup_addr_d  [g] <= 'x;
          lookup_data_d  [g] <= 'x;
          lookup_valid_d [g] <= 1'b0;
        end else begin
          lookup_addr_d  [g] <= lookup_addr_d  [g - 1];
          lookup_data_d  [g] <= lookup_data_d  [g - 1];
          lookup_valid_d [g] <= lookup_valid_d [g - 1];
        end

    end
  end
endgenerate

match_ram_data_t          rd_data_w    [D_CNT-1:0];
logic                     match        [D_CNT-1:0];
logic                     got_match_w;
logic                     got_match;
logic [$clog2(D_CNT)-1:0] match_num_w;
logic [$clog2(D_CNT)-1:0] match_num;

genvar g;
generate
  for( g = 0; g < D_CNT; g++ )
    begin : mr
      simple_ram #( 
        .DATA_WIDTH        ( $bits(match_ram_data_t)                ), 
        .ADDR_WIDTH        ( IN_ADDR_WIDTH                          )
      ) tr_ram (

        .clk               ( clk_i                                  ),

        .write_addr        ( ctrl_if.wr_addr[IN_ADDR_WIDTH-1:0]     ),
        .data              ( ctrl_if.wr_data                        ),
        .we                ( ctrl_if.wr_en && ctrl_if.mport[g].sel  ),

        .read_addr         ( lookup_addr_i                          ),
        .q                 ( rd_data_w[g]                           )
      );

      assign match[g] = ( rd_data_w[g].value == lookup_data_d1 ) && rd_data_w[g].en;
    end
endgenerate

always_comb
  begin
    match_num_w = '0;
    got_match_w = 1'b0;

    for( int i = 0; i < D_CNT; i++ )
      begin
        if( match[i] )
          begin
            match_num_w = i;
            got_match_w = 1'b1;
          end
      end
  end

always_ff @( posedge clk_i )
  begin
    match_num <= match_num_w;
    got_match <= got_match_w;
  end

assign lookup_valid_o =   lookup_en_d2;
assign lookup_match_o =   got_match; 
assign lookup_addr_o  = { lookup_addr_d2, match_num };
assign lookup_data_o  =   lookup_data_d2;

endmodule
