extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	if change_scene_to_file("res://scenes/main_menu.tscn") != OK:
		quit(1)
		return
	await scene_changed
	current_scene.btn_new_game.pressed.emit()
	var deadline := Time.get_ticks_msec() + 20000
	var field: Node
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var ancestor := get_first_node_in_group("player")
		while ancestor != null and not ancestor.has_method("_init_formal_hud"):
			ancestor = ancestor.get_parent()
		if ancestor != null and is_instance_valid(ancestor.get("_primary_hud")):
			field = ancestor
			break
	if field == null:
		printerr("HUD_QA: new game did not reach the walking scene")
		quit(1)
		return
	var hud: Control = field.get("_primary_hud")
	if hud == null or hud.get_script() == null or hud.get_script().resource_path != "res://scripts/ui/field_primary_hud.gd":
		printerr("HUD_QA: walking scene has no formal HUD script")
		quit(1)
		return
	for signal_name in [&"inventory_pressed", &"equipment_pressed", &"skill_pressed", &"quest_pressed", &"system_pressed"]:
		if not hud.has_signal(signal_name) or hud.get_signal_connection_list(signal_name).size() != 1:
			printerr("HUD_QA: missing HUD signal binding: ", signal_name)
			quit(1)
			return
	var inventory: Control = field.get("_inventory_panel")
	hud.get_node("BtnInventory").pressed.emit()
	if inventory == null or not inventory.visible:
		printerr("HUD_QA: inventory button did not open its panel")
		quit(1)
		return
	print("HUD_QA PASS: New Game -> ", root.get_node("SceneRouter").get_current_field_id(), ", five bindings, inventory opened")
	quit()
