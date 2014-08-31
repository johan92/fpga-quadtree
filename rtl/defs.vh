`define D_WIDTH    8
`define STAGES_CNT 3
`define D_CNT      4

typedef struct packed{
  logic [`D_WIDTH-1:0] l;
  logic [`D_WIDTH-1:0] m;
  logic [`D_WIDTH-1:0] r;
} ram_data_t;

typedef struct packed{
  logic [`D_WIDTH-1:0] value;
  logic                en;
} match_ram_data_t;
