extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	var router := root.get_node_or_null("SceneRouter")
	_check(game_state != null and router != null, "required autoloads must exist")
	if game_state == null or router == null:
		quit(1)
		return
	game_state.call("set_flag", &"entered_zhuwei_village", true)
	router.set("_field_payload", {
		"scene_id": &"ch1_s2_qingfeng",
		"player_spawn": Vector2(0.24, 0.72),
	})
	router.set("_current_field_id", &"ch1_s2_qingfeng")
	var field_scene := load("res://scenes/field_walkable.tscn") as PackedScene
	_check(field_scene != null, "walkable field scene loads")
	if field_scene == null:
		quit(1)
		return
	var field := field_scene.instantiate()
	root.add_child(field)
	for _frame in range(12):
		await process_frame

	var escorts: Array[NPCNode] = []
	var world_size := field.get("_world_size") as Vector2
	for node: Node in get_nodes_in_group("npc"):
		if node is NPCNode and String((node as NPCNode).npc_id) in ["patrol_scout", "patrol_scout_partner"]:
			escorts.append(node as NPCNode)
	_check(escorts.size() == 2, "two escort guards must be instantiated at every story stage")
	for escort: NPCNode in escorts:
		_check(escort.visible and escort.sprite != null and escort.sprite.texture != null, "%s must own a visible sprite" % escort.npc_id)
		_check(escort.dialog_id != "", "%s must remain interactable" % escort.npc_id)
		var normalized_position := Vector2(escort.position.x / world_size.x, escort.position.y / world_size.y)
		_check(normalized_position.x > 0.35 and normalized_position.x < 0.52, "%s must not be pulled to the map origin" % escort.npc_id)
		_check(normalized_position.y > 0.45 and normalized_position.y < 0.60, "%s must remain on the main-street patrol lane" % escort.npc_id)

	var player := field.get("_player") as Player
	_check(player != null, "player must exist for baked-roof fade test")
	if player != null:
		field.call("_update_dynamic_occluders", Vector2(0.29, 0.78), true)
		_check(is_equal_approx(player.sprite.modulate.a, 0.44), "player fades inside the baked southwest roof")
		var ghost := player.get_node_or_null("BuildingOverlapGhost") as Sprite2D
		_check(ghost != null and not ghost.visible, "baked roof fade creates no duplicate foreground ghost")
		field.call("_update_dynamic_occluders", Vector2(0.54, 0.62), true)
		_check(is_equal_approx(player.sprite.modulate.a, 1.0), "player restores opacity in the central square")

	field.queue_free()
	await process_frame
	print("[Ch1ZhuweiRuntimeNPCsAndFade] failed=%d" % failures.size())
	for failure in failures:
		push_error("[Ch1ZhuweiRuntimeNPCsAndFade] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
