# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\ondevice_ai_project\verilogHDL_TIL\vitis\apb_fnd\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\ondevice_ai_project\verilogHDL_TIL\vitis\apb_fnd\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {apb_fnd}\
-hw {D:\ondevice_ai_project\verilogHDL_TIL\software\20260611_apb_fnd\design_1_wrapper.xsa}\
-proc {microblaze_0} -os {standalone} -fsbl-target {psu_cortexa53_0} -out {D:/ondevice_ai_project/verilogHDL_TIL/vitis}

platform write
platform generate -domains 
platform active {apb_fnd}
platform generate
