function automatic int get_level_ram_width(int level_num);
  return (level_num == 0) ? (1) : (level_num * 2);
endfunction

function automatic int get_segment_idx_width(int level_cnt, int d_cnt);
  int last_level_out_addr_width;
  int d_cnt_log2;

  last_level_out_addr_width = get_level_ram_width(level_cnt + 1);
  d_cnt_log2 = (d_cnt == 1) ? ( 1 ) : ( $clog2(d_cnt) );

  return last_level_out_addr_width + d_cnt_log2;

endfunction

function automatic int get_level_mm_ctrl_width(int level_cnt);
  int last_level_ram_addr_width;
  int level_cnt_clog2;

  last_level_ram_addr_width = get_level_ram_width(level_cnt);

  level_cnt_clog2 = (level_cnt == 1) ? (1) : ($clog2(level_cnt));

  return last_level_ram_addr_width + level_cnt_clog2;

endfunction

function automatic int get_qtree_mm_ctrl_width(int level_cnt, int d_cnt);
endfunction
