function automatic int get_level_ram_width(int level_num);
  return (level_num == 0) ? (1) : (level_num * 2);
endfunction

function automatic int get_level_out_addr_width(int level_num);
  return get_level_ram_width(level_num + 1);
endfunction

function automatic int get_LEVEL_WIDTH( int level_cnt );
  return (level_cnt == 1) ? ( 1 ) : ($clog2(level_cnt));
endfunction

function automatic int get_MATCH_CELL_CNT_WIDTH( int match_cell_cnt );
  return (match_cell_cnt == 1) ? ( 1 ) : ($clog2(match_cell_cnt));
endfunction

function automatic int get_MATCH_RAM_ADDR_WIDTH( int level_cnt );
  return get_level_out_addr_width(level_cnt);
endfunction

function automatic int get_ADDR_WIDTH( int level_cnt, int match_cell_cnt );
  return get_MATCH_RAM_ADDR_WIDTH(level_cnt) + get_MATCH_CELL_CNT_WIDTH(match_cell_cnt);
endfunction

function automatic int get_MM_ADDR_WIDTH( int addr_level_width, int addr_match_width );
  return (addr_level_width > addr_match_width) ? ( addr_level_width + 1 ):
                                                 ( addr_match_width + 1 );
endfunction

function automatic int get_MM_DATA_WIDTH( int level_ram_width, int match_ram_width );
  int max_width;
  max_width = (level_ram_width > match_ram_width ) ? (level_ram_width):
                                                     (match_ram_width);

  // we want MM_DATA_WIDTH to be power of two                                                   
  return 2**$clog2(max_width);
endfunction
