vlib work

# compiling files
vlog sort_tb_pkg.sv
vlog top_tb.sv
vlog top_tb_advanced.sv
vlog ../rtl/*.sv
vlog ../rtl/*.v

# insert name of testbench module
vsim -novopt top_tb_advanced

# adding all waveforms in hex view
add wave -r -hex *

# running simulation for some time
# you can change for run -all for infinity simulation :-)
run 30000ns
