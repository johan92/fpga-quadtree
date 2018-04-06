module delay #(
  parameter DATA_WIDTH   = 32,
  parameter ENABLE       = 0
) (
  input                           clk_i,
  input                           rst_i,

  input  logic [DATA_WIDTH-1:0]   in_data_i,
  input  logic                    in_valid_i,

  output logic [DATA_WIDTH-1:0]   out_data_o,
  output logic                    out_valid_o

);

generate
  if(ENABLE == 0) begin : g_not_enable
    assign out_data_o  = in_data_i;
    assign out_valid_o = in_valid_i;
  end else begin : g_enable
    always_ff @(posedge clk_i or posedge rst_i)
      if( rst_i ) begin
        out_data_o  <= 'x;
        out_valid_o <= 1'b0;
      end else begin
        out_data_o  <= in_data_i;
        out_valid_o <= in_valid_i;
      end
  end
endgenerate

endmodule
