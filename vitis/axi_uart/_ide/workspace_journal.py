# 2026-06-24T22:19:17.990289300
import vitis

client = vitis.create_client()
client.set_workspace(path="axi_uart")

# 2026-06-24T22:19:17.990289300
import vitis

client = vitis.create_client()
client.set_workspace(path="axi_uart")

platform = client.create_platform_component(name = "my_i2c_platform",hw_design = "$COMPONENT_LOCATION/../../../software/20260624_axi_i2c/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="my_i2c_app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="my_i2c_app_component")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()

