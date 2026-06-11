# 2026-06-10T19:56:25.168955900
import vitis

client = vitis.create_client()
client.set_workspace(path="apb_gpio")

platform = client.create_platform_component(name = "apb_gpio",hw_design = "$COMPONENT_LOCATION/../design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../apb_gpio/export/apb_gpio/apb_gpio.xpfm",domain = "standalone_microblaze_0")

client.delete_component(name="app_component")

client.delete_component(name="componentName")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../apb_gpio/export/apb_gpio/apb_gpio.xpfm",domain = "standalone_microblaze_0")

platform = client.get_component(name="apb_gpio")
status = platform.update_desc(desc="")

domain = platform.get_domain(name="standalone_microblaze_0")

status = domain.regenerate()

status = platform.build()

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

