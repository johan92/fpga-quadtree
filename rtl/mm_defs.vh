typedef struct packed {
  logic [LEVEL_WIDTH-1:0]          level_num;
  logic [MATCH_RAM_ADDR_WIDTH-1:0] ram_addr;
} mm_addr_level_t;

typedef struct packed {
  logic [MATCH_RAM_ADDR_WIDTH-1:0] ram_addr;
  logic [MATCH_CELL_CNT_WIDTH-1:0] cell_num;
} mm_addr_match_t;
