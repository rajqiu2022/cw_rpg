extends "res://tests/test_world_map_v14_production_20261002.gd"

## GPU visual attachments ONLY. This is not FULL world acceptance and cannot
## grant production approval. The inherited normal NPC regression owns every
## spawn/texture/scale/body/patrol step; this observer only reads live nodes.
signal supplemental_observer_finished

var _supplement_observing := false
var _supplement_observer_done := false
var _supplement_observations := 0
var _supplement_images: Dictionary = {}
var _supplement_cases: Dictionary = {}
var _supplement_rows: Array[Dictionary] = []

func _run() -> void:
	qa_scope = "SUPPLEMENTAL_NORMAL_NPC_VISUAL"
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	phase_output = OUTPUT_DIR + "supplemental_normal_npc_gpu_%d/" % Time.get_ticks_usec()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique supplementary visual output directory")
	player_saves_before = _actual_player_saves()
	_check(DisplayServer.get_name() != "headless", "normal NPC visual supplement refuses headless; actual GPU pictures required")
	_check("--qa-gpu-approved" in OS.get_cmdline_user_args(), "supplement requires serialized producer GPU approval")
	if failed > 0:
		_finish()
		return
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	var status := String(manifest.get("status", ""))
	var ready: bool = status in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "PRODUCTION_APPROVED"] and String(source_contract.get("status", "")) == "ART_ASSETS_READY" and ResourceLoader.exists(active_path)
	_check(ready, "completed published candidate required for supplementary NPC Field initialization")
	if not ready or not _asset_binding_checks():
		_finish()
		return
	schema_ready = true
	_prepare_isolated_slots()
	_fixture_new_game()
	if not await _open_world(world.player_spawn):
		_finish()
		return
	_collect_runtime()
	var player: Node2D = field.get("_player")
	var original_player_foot := player.position
	player = null
	print("[WorldV14Supplement] SUPPLEMENTAL_NORMAL_NPC_VISUAL; inherited natural regression, NOT FULL")
	_supplement_observing = true
	_observe_normal_npc_draws()
	await _normal_patrol_same_band_regression()
	_supplement_observing = false
	if not _supplement_observer_done:
		await supplemental_observer_finished
	_check(_supplement_images.has("patrol_front") and _supplement_images.has("patrol_behind"), "supplement has actual GPU pictures of overlapping current alpha on BOTH real-foot sides")
	_check(await _place_fixture(original_player_foot), "supplement restores isolated Player original legal feet after inherited NPC cleanup")
	_checked_alpha_json(phase_output + "supplementary_normal_npc_visual.json", {
		"coverage": "SUPPLEMENTAL_NORMAL_NPC_VISUAL", "is_full_acceptance": false,
		"production_approval_granted": false, "regression_method": "inherited _normal_patrol_same_band_regression unchanged",
		"observer_stage": "RenderingServer.frame_post_draw; immediate synchronous current-node/image reads",
		"natural_observations": _supplement_observations, "pictures": _supplement_images,
		"records": _supplement_rows, "original_player_foot_px": [original_player_foot.x, original_player_foot.y],
		"visual_verdict": "REQUIRES_INDEPENDENT_IMAGE_REVIEW", "npc_teleport_or_freeze": false,
	})
	_write_supplement_cases()
	_finish() # Inherited owned-slot/navigation/audio/cursor/save-SHA cleanup.

func _write_supplement_cases() -> void:
	var path := phase_output + "supplemental_normal_npc_cases.json"
	var record := {"scope": qa_scope, "is_full_acceptance": false, "cases": _supplement_cases}
	var serialized := JSON.stringify(record, "\t")
	var expected: Variant = JSON.parse_string(serialized)
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null and expected is Dictionary, "open isolated supplementary cases JSON")
	if file == null: return
	file.store_string(serialized)
	file.flush()
	var write_error := file.get_error()
	file.close()
	file = null
	var bytes := FileAccess.get_file_as_bytes(path)
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	_check(write_error == OK and bytes == serialized.to_utf8_buffer() and parsed is Dictionary and _domain_equal(parsed, expected), "supplementary cases JSON exact bytes/parsed readback")

func _supplement_node_record(npc: NPCNode) -> Dictionary:
	var sprite: Sprite2D = npc.sprite
	var image := sprite.texture.get_image()
	if image.is_compressed(): image.decompress()
	var frame := _sprite_frame(sprite, image)
	var polygon := _normal_npc_actual_body_polygon(npc)
	var body_points: Array = []
	for point: Vector2 in polygon:
		body_points.append([point.x, point.y])
	var screen_rect := Rect2()
	var first := true
	var render := sprite.get_rect()
	for corner: Vector2 in [render.position, render.position + Vector2(render.size.x, 0), render.end, render.position + Vector2(0, render.size.y)]:
		var screen := sprite.get_global_transform_with_canvas() * corner
		if first:
			screen_rect = Rect2(screen, Vector2.ZERO)
			first = false
		else:
			screen_rect = screen_rect.expand(screen)
	return {
		"id": String(npc.npc_id), "position_world_px": [npc.position.x, npc.position.y],
		"global_position_px": [npc.global_position.x, npc.global_position.y], "actual_foot_global_y": npc.get_depth_sort_y(),
		"z_index": npc.z_index, "effective_z": _effective_z(sprite), "sibling_index": npc.get_index(),
		"parent_instance_id": npc.get_parent().get_instance_id(), "frame": sprite.frame,
		"frame_coords": [sprite.frame_coords.x, sprite.frame_coords.y],
		"source_frame_rect": [frame.position.x, frame.position.y, frame.size.x, frame.size.y],
		"source_texture_path": sprite.texture.resource_path, "source_texture_sha256": FileAccess.get_sha256(sprite.texture.resource_path),
		"sprite_scale": [sprite.scale.x, sprite.scale.y], "node_scale": [npc.scale.x, npc.scale.y],
		"screen_rect": [screen_rect.position.x, screen_rect.position.y, screen_rect.size.x, screen_rect.size.y],
		"actual_rectangle_body_global_vertices": body_points,
	}

func _observe_normal_npc_draws() -> void:
	# Run concurrently with the ORIGINAL regression. No input, transforms,
	# sprite frames, process flags, patrol parameters, or actor sorting are set.
	while _supplement_observing and _supplement_observations < 512 and _supplement_images.size() < 2:
		await RenderingServer.frame_post_draw
		if not _supplement_observing or not is_instance_valid(field): break
		var layer := field.get("_actor_layer") as Node
		if not is_instance_valid(layer): continue
		var nodes: Dictionary = {}
		for child: Node in layer.get_children():
			if child is NPCNode and String(child.npc_id).begins_with("qa_v14_normal_patrol_"):
				nodes[String(child.npc_id)] = child
		if nodes.size() != 3: continue
		_supplement_observations += 1
		var idle := nodes.get("qa_v14_normal_patrol_0") as NPCNode
		var tie := nodes.get("qa_v14_normal_patrol_1") as NPCNode
		var patrol := nodes.get("qa_v14_normal_patrol_2") as NPCNode
		if idle == null or tie == null or patrol == null: continue
		var hits := _normal_npc_original_alpha_hits(patrol.sprite, idle.sprite)
		var delta: float = patrol.get_depth_sort_y() - idle.get_depth_sort_y()
		var same_band: bool = idle.z_index == patrol.z_index
		if hits <= 0 or absf(delta) <= .01 or not same_band: continue
		var label := "patrol_front" if delta > 0 else "patrol_behind"
		if _supplement_images.has(label): continue
		var correct: bool = patrol.get_index() > idle.get_index() if delta > 0 else patrol.get_index() < idle.get_index()
		var idle_body := _normal_npc_actual_body_polygon(idle)
		var patrol_body := _normal_npc_actual_body_polygon(patrol)
		var body_clear: bool = idle_body.size() == 4 and patrol_body.size() == 4 and Geometry2D.intersect_polygons(idle_body, patrol_body).is_empty()
		var full_foot_clear: bool = _foot_clear(patrol.position)
		var physical_clear: bool = idle.get("_body_collider") is StaticBody2D and patrol.get("_body_collider") is StaticBody2D and body_clear
		_check(correct and physical_clear and full_foot_clear, "post-draw actual overlapping normal NPC ordering/full17/unchanged Rectangle supports: " + label)
		if not correct or not physical_clear or not full_foot_clear: continue
		var actors: Array[Dictionary] = []
		for npc: NPCNode in [idle, tie, patrol]:
			actors.append(_supplement_node_record(npc))
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(1920, 1080))
		var all_in_picture := true
		for actor: Dictionary in actors:
			var screen_rect := _rect(actor.screen_rect)
			if not viewport_rect.encloses(screen_rect): all_in_picture = false
		# The inherited Player relocation uses natural camera following. Wait for
		# actual visible actors, never snap/freeze/move NPCs to manufacture a shot.
		if not all_in_picture: continue
		var screenshot := root.get_texture().get_image()
		var valid: bool = screenshot != null and screenshot.get_size() == Vector2i(1920, 1080)
		_check(valid, "supplement reads actual 1920x1080 completed GPU frame: " + label)
		if not valid: continue
		var path := phase_output + label + ".png"
		var saved: bool = screenshot.save_png(path) == OK
		_check(saved, "supplementary natural NPC picture saved: " + label)
		if not saved: continue
		captures += 1
		var record := {
			"relation": label, "png_path": path, "png_sha256": FileAccess.get_sha256(path),
			"renderer": DisplayServer.get_name(), "process_frame": Engine.get_process_frames(),
			"physics_frame": Engine.get_physics_frames(), "ticks_usec": Time.get_ticks_usec(),
			"stage": "frame_post_draw", "current_alpha_hits": hits, "source_alpha_threshold": .12,
			"actual_foot_delta_y": delta, "same_band": same_band, "correct_sibling_order": correct,
			"actual_rectangle_bodies_disjoint": body_clear, "all_three_actual_sprite_rects_in_picture": all_in_picture, "actors": actors,
			"full_foot_clear": full_foot_clear, "physical_clear": physical_clear,
			"no_fixture_mutation_by_observer": true,
		}
		_supplement_images[label] = record
		_supplement_cases[label] = {
			"image_path": path, "image_sha256": record.png_sha256,
			"relation": "front" if delta > 0 else "behind",
			"actor_id": String(patrol.npc_id), "npc_id": String(idle.npc_id),
			"actor_foot_y": patrol.get_depth_sort_y(), "npc_foot_y": idle.get_depth_sort_y(),
			"current_alpha_hits": hits, "current_frame": patrol.sprite.frame,
			"full_foot_clear": full_foot_clear, "physical_clear": physical_clear, "correct_order": correct,
			"source_record_json": phase_output + label + ".json", "observation_stage": "frame_post_draw",
			"process_frame": record.process_frame, "physics_frame": record.physics_frame,
		}
		_supplement_rows.append(record)
		_checked_alpha_json(phase_output + label + ".json", record)
	_supplement_observer_done = true
	supplemental_observer_finished.emit()
