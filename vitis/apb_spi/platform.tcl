# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\ondevice_ai_project\verilogHDL_TIL\vitis\apb_spi\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\ondevice_ai_project\verilogHDL_TIL\vitis\apb_spi\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {apb_spi}\
-hw {D:\ondevice_ai_project\verilogHDL_TIL\software\20260613_apb_spi_master_slave\design_1_wrapper.xsa}\
-proc {microblaze_0} -os {standalone} -fsbl-target {psu_cortexa53_0} -out {D:/ondevice_ai_project/verilogHDL_TIL/vitis}

platform write
platform generate -domains 
platform active {apb_spi}
