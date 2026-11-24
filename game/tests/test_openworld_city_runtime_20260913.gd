extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router := root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var bounties := root.get_node("BountyManager")
	state.reset_for_new_game()
	inventory.reset_for_new_game()
	bounties.reset_for_new_game()

	for scene_id: StringName in [
		&"openworld_bianzhou_city",
		&"openworld_xiangzhou_city",
		&"openworld_jinling_city",
		&"openworld_bianzhou_old_post",
		&"openworld_xiangzhou_mine_valley",
		&"openworld_jinling_reed_marsh",
	]:
		var scene_def := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		router.set("_current_field_id", scene_id)
		router.set("_current_field_spawn", scene_def.player_spawn)
		router.set("_field_payload", {"scene_id": scene_id, "player_spawn": scene_def.player_spawn})
		var packed := load("res://scenes/field_walkable.tscn") as PackedScene
		var current := packed.instantiate() if packed != null else null
		if current != null:
			root.add_child(current)
			for _frame in range(5):
				await process_frame
		_check(current != null, "%s creates a runtime scene" % scene_id)
		if current == null:
			continue
		_check(current.scene_file_path == "res://scenes/field_walkable.tscn", "%s uses the walkable field" % scene_id)
		var loaded_scene: Variant = current.get("_current_scene")
		_check(loaded_scene is SceneScript and loaded_scene.scene_id == scene_id, "%s binds its SceneScript" % scene_id)
		var actor: Variant = current.get("_player")
		_check(actor != null and is_instance_valid(actor), "%s creates the player actor" % scene_id)
		current.queue_free()
		await process_frame

	print("[OpenworldCityRuntime] checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[OpenworldCityRuntime] " + description)
