typedef struct packed {
  logic [KEY_WIDTH-1:0] l;
  logic [KEY_WIDTH-1:0] r;
} segment_t;

function automatic string segment2str(input segment_t _d);
  string s = "";
  
  $sformat(s, "%s l = %d", s, _d.l);
  $sformat(s, "%s r = %d", s, _d.r);

  return s;
endfunction

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

        q.push_back(_s);
      end

  endfunction

  function int search(input [KEY_WIDTH-1:0] value);
    foreach(q[i]) begin
      if((q[i].l <= value) && (value <= q[i].r)) begin
        return i;
      end
    end

    return -1;
  endfunction

endclass
