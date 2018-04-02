// Quartus II Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module simple_ram #(
  parameter DATA_WIDTH = 8, 
  parameter ADDR_WIDTH = 6,
  parameter OUT_REG_EN = 0
) (
  input                     clk,
 
  input  [(DATA_WIDTH-1):0] data,
  input  [(ADDR_WIDTH-1):0] write_addr,
  input                     we,
  
  input  [(ADDR_WIDTH-1):0] read_addr, 
  output [(DATA_WIDTH-1):0] q
);

  // Declare the RAM variable
  reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
  reg [DATA_WIDTH-1:0] read_data;
  reg [DATA_WIDTH-1:0] read_data_d1;

  always @ (posedge clk) begin
    // Write
    if (we)
      ram[write_addr] <= data;

    // Read (if read_addr == write_addr, return OLD data).  To return
    // NEW data, use = (blocking write) rather than <= (non-blocking write)
    // in the write assignment.   NOTE: NEW data may require extra bypass
    // logic around the RAM.
    read_data <= ram[read_addr];
  end

  always @ (posedge clk) begin
    read_data_d1 <= read_data;
  end

  assign q = (OUT_REG_EN) ? (read_data_d1):
                            (read_data   );

endmodule
