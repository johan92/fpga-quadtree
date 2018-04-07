typedef struct packed {
  mm_addr_level_t  addr;
  level_ram_data_t data;
} level_ram_mm_cmd_t;

typedef struct packed {
  mm_addr_match_t  addr;
  match_ram_data_t data;
} match_ram_mm_cmd_t;

typedef logic [KEY_WIDTH-1:0] lookup_data_t;

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

  $sformat( s, "%s addr.ram_addr = %d", s, _d.addr.ram_addr );
  $sformat( s, "%s addr.cell_num = %d", s, _d.addr.cell_num );
  $sformat( s, "%s data.l = %d",        s, _d.data.l        );
  $sformat( s, "%s data.r = %d",        s, _d.data.r        );

  return s;
endfunction

function automatic string lookup_data2str(input lookup_data_t _d);
  string s = "";

  $sformat(s, "%s %d", s, _d);

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
        code = $fscanf( fd, "%d %d %d %d ", _cmd.addr.ram_addr, 
                                            _cmd.addr.cell_num, 
                                            _cmd.data.l, 
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
        code = $fscanf( fd, "%d %d %d %d %d ", _cmd.addr.level_num, 
                                            _cmd.addr.ram_addr, 
                                            _cmd.data.l, 
                                            _cmd.data.m,
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

class LookupData;

  lookup_data_t q[$];
  
  function new();
    q = {};
  endfunction

  function void load(input string fname);
    integer fd;
    integer code;

    lookup_data_t _d;

    fd = $fopen( fname, "r" );

    while( 1 ) begin
        code = $fscanf( fd, "%d ", _d );

        if( code <= 0 )
          begin
            return;
          end

        $display( "%t: %m: %s", $time(), lookup_data2str(_d));

        q.push_back(_d);
    end
  endfunction
endclass
