`include "defs.vh"

module qstage #( 
  parameter IN_ADDR_WIDTH  = 4,
  parameter OUT_ADDR_WIDTH = 6, 
  parameter DATA_WIDTH     = 16
) (
  input                                 clk_i,
  input                                 rst_i,

  qstage_ctrl_if                        ctrl_if,
  
  input                                 lookup_valid_i,
  input          [IN_ADDR_WIDTH - 1:0]  lookup_addr_i,
  input          [DATA_WIDTH    - 1:0]  lookup_data_i,
  
  output                                lookup_valid_o,
  output         [OUT_ADDR_WIDTH - 1:0] lookup_addr_o,
  output         [DATA_WIDTH     - 1:0] lookup_data_o

);

ram_data_t                rd_data_w;

logic                     lookup_valid_d1;
logic                     lookup_valid_d2;

logic [IN_ADDR_WIDTH-1:0] lookup_addr_d1;
logic [IN_ADDR_WIDTH-1:0] lookup_addr_d2;

logic [DATA_WIDTH-1:0]    lookup_data_d1;
logic [DATA_WIDTH-1:0]    lookup_data_d2;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i  )
    begin
      lookup_valid_d1  <= 1'b0;
      lookup_addr_d1   <= 'x;
      lookup_data_d1   <= 'x;

      lookup_valid_d2  <= 1'b0;
      lookup_addr_d2   <= 'x;
      lookup_data_d2   <= 'x;
    end
  else
    begin
      lookup_valid_d1  <= lookup_valid_i;
      lookup_addr_d1   <= lookup_addr_i;
      lookup_data_d1   <= lookup_data_i;
      
      lookup_valid_d2  <= lookup_valid_d1;   
      lookup_addr_d2   <= lookup_addr_d1; 
      lookup_data_d2   <= lookup_data_d1; 
    end


simple_ram #( 
  .DATA_WIDTH                             ( $bits(ram_data_t)                  ), 
  .ADDR_WIDTH                             ( IN_ADDR_WIDTH                      )
) tr_ram(
  .clk                                    ( clk_i                              ),

  .write_addr                             ( ctrl_if.wr_addr[IN_ADDR_WIDTH-1:0] ),
  .data                                   ( ctrl_if.wr_data                    ),
  .we                                     ( ctrl_if.wr_en                      ),

  .read_addr                              ( lookup_addr_i                      ),
  .q                                      ( rd_data_w                          )
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
    casex( { le_l, le_m, le_r } )
      3'b01x:  next_addr_hdr <= 'd1;
      3'b001:  next_addr_hdr <= 'd2;
      3'b000:  next_addr_hdr <= 'd3;
      default: next_addr_hdr <= 'd0;
    endcase
  end

assign lookup_addr_o = ( IN_ADDR_WIDTH == 1 ) ? (                   next_addr_hdr   ):
                                                ( { lookup_addr_d2, next_addr_hdr } );

assign lookup_valid_o = lookup_valid_d2;
assign lookup_data_o  = lookup_data_d2;

endmodule
