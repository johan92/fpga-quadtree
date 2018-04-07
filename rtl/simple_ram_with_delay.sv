module simple_ram_with_delay #(
  parameter DATA_WIDTH     = 8, 
  parameter ADDR_WIDTH     = 6,
  parameter BYPASS_WIDTH   = 1,
  parameter OUT_REG_ENABLE = 0
) (
  input                          clk_i,
  input                          rst_i,

  input  [DATA_WIDTH   - 1:0]    wr_data_i,
  input  [ADDR_WIDTH   - 1:0]    wr_addr_i,
  input                          wr_enable_i,
  
  input  [ADDR_WIDTH   - 1:0]    in_read_addr_i,
  input  [BYPASS_WIDTH - 1:0]    in_bypass_i,
  input                          in_valid_i,

  output [DATA_WIDTH   - 1:0]    out_read_data_o,
  output [BYPASS_WIDTH - 1:0]    out_bypass_o,
  output                         out_valid_o
);

logic [DATA_WIDTH-1:0] read_data_w;

logic [BYPASS_WIDTH-1:0] in_bypass_d1;
logic                    in_valid_d1;

simple_ram #(
  .DATA_WIDTH      ( DATA_WIDTH        ),
  .ADDR_WIDTH      ( ADDR_WIDTH        )
) ram (
  .clk             ( clk               ),
   
  .data            ( wr_data_i         ),
  .write_addr      ( wr_addr_i         ),
  .we              ( wr_enable_i       ),
    
  .read_addr       ( in_read_addr_i    ),
  .q               ( read_data_w       )
);

delay #(
  .DATA_WIDTH   ( BYPASS_WIDTH      ),
  .ENABLE       ( 1                 )
) delay_d1 (
  .clk_i        ( clk_i             ),
  .rst_i        ( rst_i             ),

  .in_data_i    ( in_bypass_i       ),
  .in_valid_i   ( in_valid_i        ),

  .out_data_o   ( in_bypass_d1      ),
  .out_valid_o  ( in_valid_d1       )

);

delay #(
  .DATA_WIDTH   ( DATA_WIDTH + BYPASS_WIDTH            ),
  .ENABLE       ( OUT_REG_ENABLE                       )
) delay_out (
  .clk_i        ( clk_i                                ),
  .rst_i        ( rst_i                                ),

  .in_data_i    ( { read_data_w,     in_bypass_d1 }    ),
  .in_valid_i   ( in_valid_d1                          ),

  .out_data_o   ( { out_read_data_o, out_bypass_o }    ),
  .out_valid_o  ( out_valid_o                          )

);

endmodule
