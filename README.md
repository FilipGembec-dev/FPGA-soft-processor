# FPGA-soft-processor


A soft processor designed for use with a Digilent Arty A7 100t FPGA dev board coded in Verilog

This project demonstrates the use of Xilinx Vivado and Verilog HDL for designing and synthesizing a working soft processor model,
for writing Hello world on a 16x2 LCD display from a Xilinx Artix7 FPGA.

A digilent Arty A7 100t was used for conducting the hardware test.

The whole Verilog code is written in the main.v file and the machine code is stored on the rom.mem file

The project is usable in the Vivado 2020 version and is configured to reprogram the flash memory on the board. The code can be synthesised for a different board.

