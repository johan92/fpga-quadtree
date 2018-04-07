create_clock -name {clock} -period 6.000 -waveform { 0.000 3.000 } [get_ports {clk_i}]

derive_clock_uncertainty
