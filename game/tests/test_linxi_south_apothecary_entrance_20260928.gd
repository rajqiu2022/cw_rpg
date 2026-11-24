extends SceneTree

var checks := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[SouthApothecary] " + message)


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.get_node("GameState").reset_for_new_game()
	root.get_node("Inventory").reset_for_new_game()
	var router := root.get_node("SceneRouter")
	router.set("_field_payload", {"scene_id": &"linxi_village_scrollmap"})
	router.set("_current_field_id", &"linxi_village_scrollmap")
	var field: Node = load("res://scenes/field_walkable.tscn").instantiate()
	root.add_child(field)
	for i in range(12):
		await process_frame
	for i in range(3):
		await physics_frame

	var actor: Player = field.get("_player")
	var world: Node2D = field.get("world_container")
	var size: Vector2 = field.get("_screen_size")
	_check(field.call("_is_inside_walkable_screen", world.to_global(Vector2(0.650, 0.330) * size)), "doorstep is connected to the street")
	_check(not field.call("_is_inside_walkable_screen", world.to_global(Vector2(0.650, 0.240) * size)), "house interior remains blocked")
	var entrance: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id == "linxi_south_apothecary_home":
			entrance = candidate
	_check(entrance != null, "south apothecary entrance exists")
	if entrance == null:
		quit(1)
		return

	# Prevent a real scene change; verify the same physical Area2D and signal used
	# by gameplay, beginning from the street below the screenshot's red stair box.
	for connection: Dictionary in entrance.get_signal_connection_list("exit_triggered"):
		entrance.disconnect("exit_triggered", connection.callable)
	var triggered := [false]
	entrance.exit_triggered.connect(func(id: String, _pos: Vector2):
		if id == "linxi_south_apothecary_home":
			triggered[0] = true
	)
	actor.position = Vector2(0.650, 0.430) * size
	for i in range(3):
		await physics_frame
	_check(not entrance.get("_in_range"), "player begins outside the doorway")
	Input.action_press("move_up")
	for i in range(90):
		await physics_frame
	Input.action_release("move_up")
	for i in range(3):
		await physics_frame
	_check(entrance.get("_in_range"), "player can walk from street onto apothecary stairs and reach the entry area")
	_check(entrance.try_interact() and triggered[0], "entry interaction opens the intended room")
	var feet := world.to_local(actor.global_position) / size
	_check(feet.y < 0.350, "player feet cross the street-to-stair gap (y=%0.4f)" % feet.y)

	field.queue_free()
	await process_frame
	await root.get_node("AudioManager").stop_bgm(0.0)
	print("[SouthApothecary] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)
