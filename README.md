fpga-sort-engine
================

Just some engines that sort unsigned data.
Writing on Verilog (SystemVerilog).

At input and output uses Avalon-ST (Streaming) interface.

### gnome\_sort\_engine\_wrapper 
Realization on Gnome Sort.

For AWIDTH = 10, DWIDTH = 32: <br>
Altera Cyclone V 5CBA2F17C8: 136 MHz, 207 ALM

### sort\_engine\_with\_merge 
Uses N engines in parallel, and merge tree at output ( to reduce proccessing time ).

For AWIDTH = 10, DWIDTH = 32, ENGINE\_CNT = 2: <br>
Altera Cyclone V 5CBA2F17C8: 93 MHz, 428 ALM
