# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\ondevice_ai_project\verilogHDL_TIL\vitis\apb_gpio\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\ondevice_ai_project\verilogHDL_TIL\vitis\apb_gpio\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {apb_gpio}\
-hw {D:\ondevice_ai_project\verilogHDL_TIL\software\apb_gpio\design_1_wrapper.xsa}\
-proc {microblaze_0} -os {standalone} -fsbl-target {psu_cortexa53_0} -out {D:/ondevice_ai_project/verilogHDL_TIL/vitis}

platform write
platform generate -domains 
platform active {apb_gpio}
platform generate
platform config -updatehw {D:/ondevice_ai_project/verilogHDL_TIL/software/apb_gpio/design_1_wrapper.xsa}
platform generate -domains 
platform config -updatehw {D:/ondevice_ai_project/verilogHDL_TIL/software/apb_gpio/design_1_wrapper.xsa}
platform generate -domains 
platform active {apb_gpio}
