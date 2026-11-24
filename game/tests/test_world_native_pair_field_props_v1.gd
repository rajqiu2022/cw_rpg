extends SceneTree

# Runtime-only Field integration of the two-region visual FAIL candidate.
# Build candidate images and run editor import before this test; do not ship them.
const PROP_CONTRACT := preload("res://scripts/dev/world_native_pair_prop_contract_v1.gd")

var failures := 0


func _prop_contract() -> GDScript:
	return PROP_CONTRACT


func _expected_prop_count() -> int:
	return 4


func _ground_path() -> String:
	return "res://build/world_native_pair_shared_v3_visual.png"


func _walk_path() -> String:
	return "res://build/world_native_pair_shared_v3_walk.png"


func _output_prefix() -> String:
	return "res://build/world_native_pair_field_props_v3_"


func _screenshot_placements() -> Array[Dictionary]:
	return [{"name": "behind", "foot": Vector2(1175, 673)}, {"name": "front", "foot": Vector2(1175, 817)}]


func _runtime_checks(_field: Node, _player: Player) -> void:
	pass


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("[FAIL] " + label)


func _run() -> void:
	if not ResourceLoader.exists(_ground_path()) or not ResourceLoader.exists(_walk_path()):
		push_error("Build and import the isolated terrain/walk images before running this test")
		quit(1)
		return
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"world_map_jianghu_v13_staging")
	for tick in range(120):
		await process_frame
		if current_scene != null and current_scene.has_method("_setup_scene"):
			break
	var field := current_scene
	if field == null or not field.has_method("_setup_scene"):
		push_error("Could not start the real walkable Field controller")
		quit(1)
		return
	var layout := WalkableMapLayout.new()
	var contract := _prop_contract()
	var world_size: Vector2 = contract.WORLD_SIZE
	layout.design_size = Vector2i(world_size)
	layout.display_at_native_size = true
	layout.walkable_mask_path = _walk_path()
	layout.visual_objects = contract.scene_objects()
	var scene := SceneScript.new()
	scene.scene_id = &"world_native_pair_field_prop_lab"
	scene.display_name = "双区分层物件隔离验收"
	scene.background_path = _ground_path()
	scene.is_walkable = true
	scene.actor_positions_are_feet = true
	scene.map_layout = layout
	scene.player_spawn = Vector2(1275, 835) / world_size
	scene.player_visual_scale = 0.754
	scene.camera_zoom = 1.25
	field.call("_setup_scene", scene)
	for tick in range(12):
		await process_frame
	var player := field.get("_player") as Player
	_check(player != null, "real Field Player is present")
	if player == null:
		quit(1)
		return
	_check(field.get("_world_size") == world_size, "runtime world size matches terrain and mask")
	var objects: Array = field.get("_scene_object_nodes")
	var collision_bodies: Array = field.get("_collision_bodies")
	_check(objects.size() == _expected_prop_count() * 2, "independent visual props and contact shadows are registered")
	_check(collision_bodies.size() >= _expected_prop_count(), "independent static foot blockers are registered")
	for prop in contract.props():
		var foot: Vector2 = prop["foot"]
		var footprint: Vector2 = prop["footprint"]
		_check(not bool(field.call("_is_inside_walkable_screen", foot)), "%s foot is physically blocked" % prop["id"])
		for side in [-1.0, 1.0]:
			var flank := foot + Vector2(side * (footprint.x * 0.5 + 24.0), 0.0)
			_check(bool(field.call("_is_inside_walkable_screen", flank)), "%s side path stays open (%s)" % [prop["id"], str(side)])
		var visual: Sprite2D = null
		for node in objects:
			if node is Sprite2D and node.name == "SceneObject_" + String(prop["id"]):
				visual = node
				break
		_check(visual != null, "%s visual exists" % prop["id"])
		if visual == null:
			continue
		player.position = foot + Vector2(0, -72)
		player.refresh_depth_sort()
		_check(player.z_index < visual.z_index, "%s covers actor standing behind" % prop["id"])
		player.position = foot + Vector2(0, 72)
		player.refresh_depth_sort()
		_check(player.z_index > visual.z_index, "actor standing in front covers %s" % prop["id"])
	_runtime_checks(field, player)
	if DisplayServer.get_name() != "headless":
		for placement in _screenshot_placements():
			player.position = placement["foot"]
			player.refresh_depth_sort()
			field.call("_snap_camera_to_player")
			for tick in range(8):
				await process_frame
			var image := root.get_texture().get_image()
			_check(image != null and image.save_png(_output_prefix() + String(placement["name"]) + ".png") == OK, "runtime %s screenshot saves" % placement["name"])
	print("[WorldNativePairFieldProps] checks complete; failures=%d; v12/v13 staging unchanged" % failures)
	quit(1 if failures > 0 else 0)
