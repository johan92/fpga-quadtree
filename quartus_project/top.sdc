create_clock -name {clock} -period 10.000 -waveform { 0.000 5.000 } [get_ports {clk_i}]

derive_clock_uncertainty
