typedef struct packed {
  logic [KEY_WIDTH-1:0] l;
  logic [KEY_WIDTH-1:0] m;
  logic [KEY_WIDTH-1:0] r;
} level_ram_data_t;

typedef struct packed {
  logic [KEY_WIDTH-1:0] l;
  logic [KEY_WIDTH-1:0] r;
} match_ram_data_t;
