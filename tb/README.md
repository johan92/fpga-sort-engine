fpga-sort-engine-tb
===================

So, this is dir for testbench files.

### top\_tb

First dummy implementation, all tasks in one big file.

### top\_tb\_advanced 
Second implementation, with driver, monitor, etc
Inspired by SystemVerilog for Verification (Chris Spear).

Includes:
  * sort\_driver
  * sort\_environment
  * sort\_generator
  * sort\_monitor
  * sort\_scoreboard
  * sort\_tb\_pkg

### Run
To run:
```
vsim -do make.do
```

In script you can select testbench in line:
```
vsim -novopt top_tb_advanced
```
