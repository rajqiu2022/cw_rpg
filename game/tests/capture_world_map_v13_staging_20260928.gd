extends SceneTree

## Captures the nine tiles, all gateway landings, and both sides of every
## internal seam. Keep this separate from the assertions so visual review is
## still required for style, perspective, object depth, and pasted edges.

const STAGING_SCENE := "res://data/scenes/world_map_jianghu_v13_staging.tres"
const OUTPUT_DIR := "res://screenshots/world_map_v13_staging_qa"
const WORLD_SIZE := Vector2(4608, 3072)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[PENDING] runtime screenshots require a rendering display; rerun without --headless")
		quit(0)
		return
	if not ResourceLoader.exists(STAGING_SCENE):
		print("[PENDING] v13 staging scene not yet present; no screenshots captured")
		quit(0)
		return
	var scene := load(STAGING_SCENE) as SceneScript
	if scene == null or scene.map_layout == null:
		push_error("[FAIL] v13 staging scene/layout does not load")
		quit(1)
		return
	if scene.map_layout.walkable_mask_tiles.size() != 9:
		print("[PENDING] staging has %d/9 navigation tiles; runtime screenshots deferred" % scene.map_layout.walkable_mask_tiles.size())
		quit(0)
		return
	for entry in scene.map_layout.walkable_mask_tiles:
		if not ResourceLoader.exists(String(entry.get("path", ""))):
			print("[PENDING] navigation tile not imported: " + String(entry.get("path", "")))
			quit(0)
			return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"world_map_jianghu_v13_staging", scene.player_spawn)
	for tick in range(160):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
			break
	var field := current_scene
	if field == null or not field.has_method("_is_inside_walkable_screen"):
		push_error("[FAIL] v13 staging Field did not load")
		quit(1)
		return
	var player: Player = field.get("_player")
	if player == null:
		push_error("[FAIL] v13 staging player did not load")
		quit(1)
		return
	var failures := 0
	for row in range(3):
		for col in range(3):
			var focus := Vector2((float(col) + 0.5) / 3.0, (float(row) + 0.5) / 3.0)
			failures += await _capture_at(field, player, focus, "tile_r%dc%d" % [row, col], false)
	for raw in scene.map_layout.portals:
		if not raw is Dictionary:
			continue
		var portal: Dictionary = raw
		var focus: Vector2 = portal.get("pos", Vector2.ZERO)
		failures += await _capture_at(field, player, focus, "gateway_" + String(portal.get("id", "unknown")), true)
	for col in [1, 2]:
		for row in range(3):
			var focus := Vector2(float(col) / 3.0, (float(row) + 0.5) / 3.0)
			failures += await _capture_at(field, player, focus, "vertical_seam_c%d_r%d" % [col, row], false)
	for row in [1, 2]:
		for col in range(3):
			var focus := Vector2((float(col) + 0.5) / 3.0, float(row) / 3.0)
			failures += await _capture_at(field, player, focus, "horizontal_seam_r%d_c%d" % [row, col], false)
	var surveyed_seams := 0
	for raw in scene.map_layout.seam_crossing_probes:
		var probe: Dictionary = raw
		var start: Vector2 = probe.get("from_pos", Vector2.ZERO)
		var finish: Vector2 = probe.get("to_pos", Vector2.ZERO)
		var focus := (start + finish) * 0.5
		failures += await _capture_at(field, player, focus, "surveyed_seam_" + String(probe.get("id", "unknown")), true)
		surveyed_seams += 1
	var blocked_seams := [
		{"id": "snowline_north_forbidden", "pos": Vector2(0.333333, 0.050)},
		{"id": "mist_ridge_north_forbidden", "pos": Vector2(0.666667, 0.105)},
		{"id": "jiangnan_bridge_west_water_forbidden", "pos": Vector2(0.480, 0.666667)},
		{"id": "jiangnan_bridge_east_water_forbidden", "pos": Vector2(0.515, 0.666667)},
	]
	for probe in blocked_seams:
		failures += await _capture_at(field, player, probe["pos"], "forbidden_seam_" + String(probe["id"]), false)
	var bridge_shots := 0
	for raw in scene.map_layout.visual_objects:
		var object: Dictionary = raw
		var id := String(object.get("id", ""))
		if id == "north_south_stone_bridge" or id == "east_west_stone_bridge":
			failures += await _capture_at(field, player, object.get("pos", Vector2.ZERO), "bridge_full_" + id, false)
			bridge_shots += 1
	for raw in scene.map_layout.walkable_probes:
		var probe: Dictionary = raw
		var id := String(probe.get("id", ""))
		if id.begins_with("bridge_") and id.ends_with("_approach"):
			failures += await _capture_at(field, player, probe.get("pos", Vector2.ZERO), "bridge_foot_" + id, true)
			bridge_shots += 1
	for raw in scene.map_layout.blocked_probes:
		var probe: Dictionary = raw
		var id := String(probe.get("id", ""))
		if id.begins_with("bridge_") and id.ends_with("_water"):
			failures += await _capture_at(field, player, probe.get("pos", Vector2.ZERO), "bridge_water_" + id, false)
			bridge_shots += 1
	print("[WorldMapV13StagingCapture] screenshots=%d failed=%d output=%s" % [9 + scene.map_layout.portals.size() + 12 + surveyed_seams + blocked_seams.size() + bridge_shots, failures, ProjectSettings.globalize_path(OUTPUT_DIR)])
	field.queue_free()
	for frame in range(5):
		await process_frame
	quit(1 if failures > 0 else 0)


func _capture_at(field: Node, player: Player, normalized: Vector2, name: String, show_player: bool) -> int:
	player.position = normalized * WORLD_SIZE
	player.modulate.a = 1.0 if show_player else 0.0
	field.call("_snap_camera_to_player")
	await create_timer(0.40).timeout
	for frame in range(4):
		await process_frame
	var path := OUTPUT_DIR.path_join(name + ".png")
	var frame_texture := root.get_texture()
	if frame_texture == null:
		push_error("[FAIL] rendering viewport has no frame texture: " + name)
		return 1
	var frame_image := frame_texture.get_image()
	if frame_image == null:
		push_error("[FAIL] rendering viewport has no frame image: " + name)
		return 1
	var error := frame_image.save_png(path)
	if error != OK:
		push_error("[FAIL] screenshot could not be saved: " + path)
		return 1
	print("[CAPTURE] " + ProjectSettings.globalize_path(path))
	return 0
