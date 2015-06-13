vlib work

# compiling verilog files
# in my dir is no verilog files, so I commented this line

#vlog *.v

# compiling systemerilog files
vlog sort_tb_pkg.sv
vlog top_tb_3.sv
vlog ../rtl/*.sv
vlog ../rtl/*.v

# t_tb is name for your testbench module
vsim -novopt top_tb_advanced

#adding all waveforms in hex view
add wave -r -hex *

# running simulation for 1000 nanoseconds
# you can change for run -all for infinity simulation :-)
run 30000ns
