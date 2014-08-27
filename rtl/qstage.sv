`include "defs.vh"

module qstage
#( 
  parameter A_WIDTH      = 4,

  parameter NEXT_A_WIDTH = 6, 

  parameter D_WIDTH      = 16
)
(
  input                                 clk_i,
  input                                 rst_i,

  qstage_ctrl_if.app                    ctrl_if,
  
  input                                 lookup_en_i,
  input              [A_WIDTH-1:0]      lookup_addr_i,
  input              [D_WIDTH-1:0]      lookup_data_i,
  
  output                                lookup_en_o,
  output             [NEXT_A_WIDTH-1:0] lookup_addr_o,
  output             [D_WIDTH-1:0]      lookup_data_o

);

ram_data_t          rd_data_w;

logic               lookup_en_d1;
logic               lookup_en_d2;

logic [A_WIDTH-1:0] lookup_addr_d1;
logic [A_WIDTH-1:0] lookup_addr_d2;

logic [D_WIDTH-1:0] lookup_data_d1;
logic [D_WIDTH-1:0] lookup_data_d2;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i  )
    begin
      lookup_en_d1   <= '0;
      lookup_addr_d1 <= '0;
      lookup_data_d1 <= '0;

      lookup_en_d2   <= '0;
      lookup_addr_d2 <= '0;
      lookup_data_d2 <= '0;
    end
  else
    begin
      lookup_en_d1   <= lookup_en_i;
      lookup_addr_d1 <= lookup_addr_i;
      lookup_data_d1 <= lookup_data_i;
      
      lookup_en_d2   <= lookup_en_d1;   
      lookup_addr_d2 <= lookup_addr_d1; 
      lookup_data_d2 <= lookup_data_d1; 
    end


simple_ram
#( 
  .DATA_WIDTH                             ( $bits(ram_data_t) ), 
  .ADDR_WIDTH                             ( A_WIDTH           )
) tr_ram(

  .clk                                    ( clk_i             ),

  .write_addr                             ( ctrl_if.wr_addr   ),
  .data                                   ( ctrl_if.wr_data   ),
  .we                                     ( ctrl_if.wr_en     ),

  .read_addr                              ( lookup_addr_i     ),
  .q                                      ( rd_data_w         )
);

// less or equal values l, m, r
logic le_l;
logic le_m;
logic le_r;

assign le_l = ( lookup_data_d1 <= rd_data_w.l );
assign le_m = ( lookup_data_d1 <= rd_data_w.m );
assign le_r = ( lookup_data_d1 <= rd_data_w.r );

//TODO: rename hdr
logic [1:0] next_addr_hdr;

always_ff @( posedge clk_i )
  begin
    casex( { le_l, le_m, le_r } ):
      3'b01x:  next_addr_hdr <= 'd1;
      3'b001:  next_addr_hdr <= 'd2;
      3'b000:  next_addr_hdr <= 'd3;
      default: next_addr_hdr <= 'd0;
    endcase
  end

assign lookup_addr_o = ( A_WIDTH == 1 ) ? (                   next_addr_hdr   ):
                                          ( { lookup_addr_d2, next_addr_hdr } );

assign lookup_en_o   = lookup_en_d2;
assign lookup_data_o = lookup_data_d2;

endmodule
