# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\ondevice_ai_project\verilogHDL_TIL\vitis\20260626_axi_cpu\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\ondevice_ai_project\verilogHDL_TIL\vitis\20260626_axi_cpu\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {20260626_axi_cpu}\
-hw {D:\ondevice_ai_project\verilogHDL_TIL\software\20260626_axi_parallel\axi_cpu_wrapper.xsa}\
-proc {microblaze_0} -os {standalone} -fsbl-target {psu_cortexa53_0} -out {D:/ondevice_ai_project/verilogHDL_TIL/vitis}

platform write
platform generate -domains 
platform active {20260626_axi_cpu}
platform generate
platform config -updatehw {D:/ondevice_ai_project/verilogHDL_TIL/software/20260627_axi_cpu/axi_cpu_wrapper.xsa}
bsp reload
platform generate -domains 
