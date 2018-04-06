proc do_compile {} { 
  exec rm -rf work/
  
  vlib work
  
  set INC_DIR "+incdir+"
  set INC_DIR "$INC_DIR+./"
  set INC_DIR "$INC_DIR+../rtl/"

  vlog -sv altera/verbosity_pkg.sv
  vlog -sv altera/avalon_utilities_pkg.sv
  vlog -sv altera/altera_avalon_st_source_bfm.sv
  
  vlog -sv ${INC_DIR} ../rtl/delay.sv
  vlog -sv ${INC_DIR} ../rtl/qtree_level.sv
  vlog -sv ${INC_DIR} ../rtl/qtree_match.sv
  vlog -sv ${INC_DIR} ../rtl/qtree_top.sv
  vlog -sv ${INC_DIR} ../rtl/simple_ram.v
  vlog -sv ${INC_DIR} ../rtl/simple_ram_with_delay.sv
  vlog -sv ${INC_DIR} top_tb.sv 

}

proc start_sim {} {
  vsim -novopt top_tb 

  add wave -r -hex sim:/top_tb/dut/*

  run -all 
}

proc run_test {} {
  do_compile
  start_sim
}

proc help {} {
  echo "help                - show this message"
  echo "do_compile          - compile all"
  echo "start_sim           - start simulation"
  echo "run_test            - do_compile & start_sim"
}

help
