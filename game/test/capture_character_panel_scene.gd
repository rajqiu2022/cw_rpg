extends Node


func _ready() -> void:
	GameState.reset_for_new_game()
	Inventory.reset_for_new_game()
	GameState.add_companion(&"tang_xingzhou")
	GameState.add_companion(&"shen_qinghe")
	Inventory.add_item(&"wooden_staff", 1)
	Inventory.add_item(&"linxi_iron_sword", 1)
	Inventory.add_item(&"cloth_armor", 1)
	var panel := (load("res://scenes/ui/character_panel.tscn") as PackedScene).instantiate() as CharacterPanel
	add_child(panel)
	# Mirror the former Field-side anchor reset; open() must still center itself.
	panel.anchors_preset = Control.PRESET_TOP_LEFT
	panel.open()
	var requested_character := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("character="):
			requested_character = argument.trim_prefix("character=")
	if not requested_character.is_empty():
		panel.call("_select_character", StringName(requested_character))
	await get_tree().process_frame
	await get_tree().process_frame
	var capture_confirmation := "confirm=precious" in OS.get_cmdline_user_args()
	var capture_drop := "confirm=drop" in OS.get_cmdline_user_args()
	if capture_confirmation:
		panel.call("_show_precious_use_confirmation", load("res://data/items/linxi_jiu.tres") as Item)
		await get_tree().process_frame
	elif capture_drop:
		panel.call("_on_inventory_drop_pressed")
		await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	DirAccess.make_dir_recursive_absolute("screenshots")
	var prefix := "character_precious_confirm" if capture_confirmation else ("character_drop_confirm" if capture_drop else ("character_%s" % requested_character if not requested_character.is_empty() else "character_party"))
	var path := "screenshots/%s_%d.png" % [prefix, int(Time.get_unix_time_from_system())]
	get_viewport().get_texture().get_image().save_png(path)
	print("[CaptureCharacterPanel] saved=", path)
	get_tree().quit()
