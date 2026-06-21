# 2026-06-21T16:56:11.024706100
import vitis

client = vitis.create_client()
client.set_workspace(path="axi_uart")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../../software/20260620_axi_uart/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

client.delete_component(name="app_component")

client.delete_component(name="componentName")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

