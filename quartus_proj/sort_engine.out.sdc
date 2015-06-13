## Generated SDC file "sort_engine.out.sdc"

## Copyright (C) 1991-2014 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus II License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 14.1.0 Build 186 12/03/2014 SJ Full Version"

## DATE    "Sat May 16 18:02:38 2015"

##
## DEVICE  "5CEBA2F17C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk_i} -period 8.000 -waveform { 0.000 4.000 } [get_ports {clk_i}]
#create_clock -name {clk_i} -period 7.500 -waveform { 0.000 3.250 } [get_ports {clk_i}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}] -hold 0.060  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

