extends SceneTree

var failures := 0


func _initialize() -> void:
	await process_frame
	var scene := load("res://scenes/ui/character_panel.tscn") as PackedScene
	_check(scene != null, "character panel scene loads")
	if scene == null:
		quit(1)
		return
	# Keep the test script independent from CharacterPanel's compile-time class;
	# the scene is instantiated only after project autoloads are available.
	var panel := scene.instantiate()
	root.add_child(panel)
	await process_frame
	panel.call("open")
	await process_frame
	var action := panel.get("_inventory_action_button") as Button
	var drop := panel.get("_inventory_drop_button") as Button
	_check(action != null and drop != null, "inventory action buttons are created")
	if action != null and drop != null:
		_check(action.size == Vector2(92, 52) and drop.size == Vector2(92, 52), "both action buttons use the enlarged 92x52 touch target")
		_check(action.position == Vector2(8, 216) and drop.position == Vector2(106, 216), "buttons keep an explicit gap and remain inside the detail card")
		_check(action.position.y + action.size.y <= 280.0 and drop.position.x + drop.size.x <= 206.0, "buttons cannot overflow the 206x280 detail card")
		_check(action.get_theme_font_size("font_size") == 17 and drop.get_theme_font_size("font_size") == 17, "action text uses readable 17px type")
		_check(action.get_theme_constant("outline_size") >= 2, "action text owns a dark clarity outline")
		var normal := action.get_theme_stylebox("normal") as StyleBoxTexture
		_check(normal != null and normal.content_margin_left <= 8.0 and normal.content_margin_right <= 8.0, "button art leaves enough horizontal room for labels")
	var source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
	_check('"队友占用"' in source and '"不可操作"' in source, "long disabled labels use compact wording")
	panel.queue_free()
	await process_frame
	print("[CharacterInventoryActionButtons20260902] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
