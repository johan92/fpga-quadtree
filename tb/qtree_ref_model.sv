typedef struct packed {
  logic [KEY_WIDTH-1:0]        data;
  logic [BYPASS_WIDTH-1:0]     bypass;
} dut_in_t;

typedef struct packed {
  logic                        match;
  logic [ADDR_WIDTH  -1:0]     addr;
  logic [BYPASS_WIDTH-1:0]     bypass;
} dut_out_t;

function automatic string dut_in2str(dut_in_t _d);
  string s = "";
  
  $sformat(s, "bypass = 0x%x data = %0d", _d.bypass, _d.data);

  return s;
endfunction

function automatic string dut_out2str(dut_out_t _d);
  string s = "";
  
  $sformat(s, "bypass = 0x%x addr = %0d match = 0x%x", _d.bypass, _d.addr, _d.match );

  return s;
endfunction

function automatic bit dut_out_eq(dut_out_t a, dut_out_t b);
  bit eq;

  eq = 1'b1;
  eq &= (a.bypass == b.bypass);
  eq &= (a.match  == b.match );

  if(a.match) begin
    eq &= (a.addr == b.addr);
  end

  return eq;
endfunction

class QTreeRefModel;
  
  Segments segments;
  
  mailbox #(dut_in_t)  mbx_dut_in;
  mailbox #(dut_out_t) mbx_dut_out;
  
  bit verbose;

  function new();
    segments = new();
    mbx_dut_in = new();
    mbx_dut_out = new();
    verbose = 1'b1;
  endfunction

  task put_dut_in(input dut_in_t _in);
    mbx_dut_in.put(_in);
  endtask

  task put_dut_out(input dut_out_t _out);
    mbx_dut_out.put(_out); 
  endtask
  
  function dut_out_t calc_ref_output(input dut_in_t _in);
    dut_out_t rez;
    int search_rez;
    
    search_rez = segments.search(_in.data);
    
    rez.match  = (search_rez >= 0);
    rez.addr   = search_rez;
    rez.bypass = _in.bypass;

    return rez;
  endfunction

  task thread_check();
    dut_in_t  _in;
    dut_out_t _dut_out;
    dut_out_t _ref_out;
    bit       ref_dut_eq;

    forever begin
      mbx_dut_in.get ( _in      );
      mbx_dut_out.get( _dut_out );
      _ref_out = calc_ref_output( _in );

      ref_dut_eq = dut_out_eq( _ref_out, _dut_out );
      
      if(ref_dut_eq == 1'b0 || verbose) begin
        $display( "%t: %m: IN: %s DUT: %s REF: %s", $time(), dut_in2str(_in),
                                                             dut_out2str(_dut_out),
                                                             dut_out2str(_ref_out) );
      end

      if(ref_dut_eq == 1'b0) begin
        $error("DUT and REF results mismatched");
        $stop();
      end
    end
  endtask

endclass
