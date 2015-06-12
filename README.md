fpga-sort-engine
================

Just some engines that sort unsigned data unsigned.
Writing on Verilog (SystemVerilog).

At input and output uses Avalon-ST (Streaming) interface.

gnome\_sort\_engine\_wrapper - realization on Gnome Sort.

sort\_engine\_with\_merge - uses N engines in parallel, and merge tree at output ( to reduce proccessing time ).
