typedef struct packed {
  mm_addr_level_t  addr;
  level_ram_data_t data;
} level_ram_mm_cmd_t;

typedef struct packed {
  mm_addr_match_t  addr;
  match_ram_data_t data;
} match_ram_mm_cmd_t;

typedef struct packed {
  logic [KEY_WIDTH-1:0] l;
  logic [KEY_WIDTH-1:0] r;
} segment_t;

function automatic string level_ram_mm_cmd2str(input level_ram_mm_cmd_t _d);
  string s = "";

  $sformat( s, "%s addr.level = %d",      s, _d.addr.level_num  );
  $sformat( s, "%s addr.ram_addr = %d",   s, _d.addr.ram_addr   );
  $sformat( s, "%s data.l = %d",          s, _d.data.l          );
  $sformat( s, "%s data.m = %d",          s, _d.data.m          );
  $sformat( s, "%s data.r = %d",          s, _d.data.r          );

  return s;
endfunction

function automatic string match_ram_mm_cmd2str(input match_ram_mm_cmd_t _d);
  string s = "";

  $sformat( "%s addr.ram_addr = %d", s, _d.addr.ram_addr );
  $sformat( "%s addr.cell_num = %d", s, _d.addr.cell_num );
  $sformat( "%s data.l = %d",        s, _d.data.l        );
  $sformat( "%s data.r = %d",        s, _d.data.r        );

  return s;
endfunction

function automatic string segment2str(input segment_t _d);
  string s = "";
  
  $sformat(s, "%s l = %d", s, _d.l);
  $sformat(s, "%s r = %d", s, _d.r);

  return s;
endfunction

class MatchRamData;
  
  match_ram_mm_cmd_t cmds[$];

  function new();
    cmds = {};  
  endfunction
  
  function void load(input string fname);
    integer fd;
    integer code;
    
    match_ram_mm_cmd_t _cmd;

    fd = $fopen( fname, "r" );
    
    while( 1 )
      begin
        code = $fscanf( fd, "%d %d %d %d %d ", _cmd.addr.ram_addr, 
                                               _cmd.addr.cell_num, 
                                               _cmd.data.l, 
                                               _cmd.data.m, 
                                               _cmd.data.r );

        if( code <= 0 )
          begin
            return;
          end

        $display( "%t: %m: %s", $time(), match_ram_mm_cmd2str(_cmd));
        cmds.push_back(_cmd);
      end
    
  endfunction

endclass

class LevelRamData;

  level_ram_mm_cmd_t cmds[$];

  function new();
    cmds = {};  
  endfunction
  
  function void load(input string fname);
    integer fd;
    integer code;
    
    level_ram_mm_cmd_t _cmd;

    fd = $fopen( fname, "r" );
    
    while( 1 )
      begin
        code = $fscanf( fd, "%d %d %d %d ", _cmd.addr.level_num, 
                                            _cmd.addr.ram_addr, 
                                            _cmd.data.l, 
                                            _cmd.data.r );

        if( code <= 0 )
          begin
            return;
          end

        $display( "%t: %m: %s", $time(), level_ram_mm_cmd2str(_cmd));
        cmds.push_back(_cmd);
      end
    
  endfunction

endclass

class Segments;
  
  segment_t q[$];

  function new();
    q = {};
  endfunction 

  function void load(input string fname);
    integer fd;
    integer code;
    
    segment_t _s;

    fd = $fopen( fname, "r" );
    
    while( 1 )
      begin
        code = $fscanf( fd, "%d %d ", _s.l, _s.r );

        if( code <= 0 )
          begin
            return;
          end

        $display( "%t: %m: %s", $time(), segment2str(_s));

        q.push_back(_s)
      end

  endfunction

  function int search(input [KEY_WIDTH-1:0] value);
    foreach(q[i]) begin
      if(q[i].l >= value && q[i].r <= value) begin
        return i;
      end
    end

    return -1;
  endfunction

endclass
