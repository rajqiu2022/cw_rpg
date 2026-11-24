extends "res://scripts/field/field_walkable_controller.gd"

# Loaded only after autoload initialization, never preloaded from the CLI SceneTree.
var definition: SceneScript
var on_preview_exit: Callable
var pointer_dispatch_count := 0


func _ready() -> void:
	_init_ui_canvas_layers()
	_init_field_ui_styles()
	_init_formal_hud()
	_apply_formal_hud_mode()
	_disable_gameplay_button_focus(self)
	apply_preview(definition)


func apply_preview(scene: SceneScript, spawn: Variant = null) -> void:
	_current_scene = scene
	_setup_scene(scene, spawn)
	# No scene-enter event, quest callbacks, on-enter dialog or Router travel.
	for zone: ExitZone in _exit_nodes:
		for connection in zone.exit_triggered.get_connections():
			zone.exit_triggered.disconnect(connection["callable"])
		for connection in zone.exit_action_triggered.get_connections():
			zone.exit_action_triggered.disconnect(connection["callable"])
		var anchor := zone.position / _world_size
		zone.exit_triggered.connect(func(target: String, target_spawn: Vector2):
			on_preview_exit.call_deferred(target, target_spawn, anchor))


func _open_system_menu() -> void:
	_show_toast("开发预览不提供存档；正式工程与玩家存档保持不变。")


func _open_save_slot_panel() -> void:
	_open_system_menu()


func _toggle_inventory_panel() -> void:
	_open_system_menu()


func _toggle_equipment_panel() -> void:
	_open_system_menu()


func _toggle_skill_panel() -> void:
	_open_system_menu()


func _toggle_quest_log_panel() -> void:
	_open_system_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().call("restore_preview_state")
			get_tree().quit()
		elif event.keycode in [KEY_F5, KEY_M, KEY_C, KEY_K, KEY_J, KEY_I, KEY_F12]:
			_open_system_menu()
		else:
			# Player owns Space/interact and movement; do not consume those.
			return
		get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.device < 0:
		get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		pointer_dispatch_count += 1
		var handled := _dispatch_pointer_interaction(event.position)
		if handled:
			get_viewport().set_input_as_handled()
