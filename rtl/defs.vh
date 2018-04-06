typedef struct packed {
  logic [7:0]  port_num;
  logic [31:0] pkt_num;
} bypass_data_t;

typedef struct packed {
  logic [KEY_WIDTH-1:0] l;
  logic [KEY_WIDTH-1:0] m;
  logic [KEY_WIDTH-1:0] r;
} level_ram_data_t;

typedef struct packed {
  logic [ADDR_WIDTH-1:0] addr;
  logic [KEY_WIDTH-1:0]  lookup_value;
} level_data_t;

typedef struct packed {
  logic [KEY_WIDTH-1:0] l;
  logic [KEY_WIDTH-1:0] r;
} match_ram_data_t;
