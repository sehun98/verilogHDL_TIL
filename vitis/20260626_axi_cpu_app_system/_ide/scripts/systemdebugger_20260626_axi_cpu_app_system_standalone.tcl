# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\ondevice_ai_project\verilogHDL_TIL\vitis\20260626_axi_cpu_app_system\_ide\scripts\systemdebugger_20260626_axi_cpu_app_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\ondevice_ai_project\verilogHDL_TIL\vitis\20260626_axi_cpu_app_system\_ide\scripts\systemdebugger_20260626_axi_cpu_app_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183BEA215A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183BEA215A-0362d093-0"}
fpga -file D:/ondevice_ai_project/verilogHDL_TIL/vitis/20260626_axi_cpu_app/_ide/bitstream/axi_cpu_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/ondevice_ai_project/verilogHDL_TIL/vitis/20260626_axi_cpu/export/20260626_axi_cpu/hw/axi_cpu_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/ondevice_ai_project/verilogHDL_TIL/vitis/20260626_axi_cpu_app/Debug/20260626_axi_cpu_app.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
