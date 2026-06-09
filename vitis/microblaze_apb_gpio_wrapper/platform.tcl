# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\ondevice_ai_project\verilogHDL_TIL\vitis\microblaze_apb_gpio_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\ondevice_ai_project\verilogHDL_TIL\vitis\microblaze_apb_gpio_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {microblaze_apb_gpio_wrapper}\
-hw {D:\ondevice_ai_project\verilogHDL_TIL\software\20260605_gpio\microblaze_apb_gpio_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {D:/ondevice_ai_project/verilogHDL_TIL/vitis}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {microblaze_apb_gpio_wrapper}
platform generate -quick
