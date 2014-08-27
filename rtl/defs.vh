`define D_WIDTH 8

typedef struct packed{
  logic [`D_WIDTH-1:0] l;
  logic [`D_WIDTH-1:0] m;
  logic [`D_WIDTH-1:0] r;
} ram_data_t;
