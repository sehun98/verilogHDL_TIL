############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
############################################################
open_project vitis_microblaze
open_solution "solution1" -flow_target vivado
set_part {xc7a12ticsg325-1L}
create_clock -period 10 -name default
#source "./vitis_microblaze/solution1/directives.tcl"
#csim_design
csynth_design
#cosim_design
export_design -format ip_catalog
