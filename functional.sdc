
set_units -time ns
create_clock -name clk -period 30 -waveform {0 15} [get_ports {clk}]
