extends "res://build/menu_buttons_20261109/verify.gd"

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var system := load("res://scenes/ui/system_menu.tscn").instantiate() as Control
	root.add_child(system)
	system.open()
	await process_frame
	expect(system.visible,"official system scene opens")
	for button: Button in [system.settings_btn,system.save_btn,system.load_btn]:
		expect(painted(button,"system"),"matching four art states "+button.name)
		expect(button.size.y > 52.0,"larger readable button "+button.name)
	await shot("07_system_final")
	await click(system.save_btn)
	var slots: Control=system.get("_slot_panel")
	expect(slots.visible and slots.get("_mode")==0 and system.save_btn.button_pressed,"save mode via actual click")
	await click(system.load_btn)
	expect(slots.visible and slots.get("_mode")==1 and system.load_btn.button_pressed,"load mode via actual click")
	await shot("08_load_final")
	await click(system.settings_btn)
	expect(system.settings_page.visible and not slots.visible and system.settings_btn.button_pressed,"settings returns via actual click")
	await click(system.get_node("%CloseBtn"))
	expect(not system.visible,"close still works")
	system.queue_free()
	await process_frame
	finish()

