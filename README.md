fpga-sort-engine
================

Just some engines that sort unsigned data.
Writing on Verilog (SystemVerilog).

At input and output uses Avalon-ST (Streaming) interface.

Numbers for resources and Fmax was acheived with Speed optimizations in Quartus.

### gnome\_sort\_engine\_wrapper 
Gnome Sort realization.

For AWIDTH = 10, DWIDTH = 32: <br>
Altera Cyclone V 5CBA2F17C8: 136 MHz, 207 ALM

### sort\_engine\_with\_merge 
Uses N gnome sort engines in parallel, and merge tree at output (to reduce proccessing time).

For AWIDTH = 10, DWIDTH = 32, ENGINE\_CNT = 2: <br>
Altera Cyclone V 5CBA2F17C8: 131 MHz, 442 ALM

For AWIDTH = 10, DWIDTH = 32, ENGINE\_CNT = 4: <br>
Altera Cyclone V 5CBA2F17C8: 125 MHz, 862 ALM
