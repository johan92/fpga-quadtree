`include "defs.vh"

interface qstage_ctrl_if( input clk_i );
  parameter A_WIDTH = 4;

  logic [A_WIDTH-1:0] wr_addr;
  logic               wr_en;
  ram_data_t          wr_data;

  modport app(
    input wr_addr,
          wr_en,
          wr_data
  );

  modport csr(
    output wr_addr,
           wr_en,
           wr_data
  );


endinterface

