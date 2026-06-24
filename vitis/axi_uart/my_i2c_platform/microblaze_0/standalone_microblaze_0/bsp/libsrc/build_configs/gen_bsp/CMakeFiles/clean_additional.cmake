# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "D:\\Project\\verilogHDL_TIL\\vitis\\axi_uart\\my_i2c_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\sleep.h"
  "D:\\Project\\verilogHDL_TIL\\vitis\\axi_uart\\my_i2c_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xiltimer.h"
  "D:\\Project\\verilogHDL_TIL\\vitis\\axi_uart\\my_i2c_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\include\\xtimer_config.h"
  "D:\\Project\\verilogHDL_TIL\\vitis\\axi_uart\\my_i2c_platform\\microblaze_0\\standalone_microblaze_0\\bsp\\lib\\libxiltimer.a"
  )
endif()
