//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2025-12-04 20:22:10
create_clock -name clk -period 20 -waveform {0 10} [get_ports {clk}]
