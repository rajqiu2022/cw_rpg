extends "res://tests/test_world_map_v14_production_20261002.gd"

## LIMITED diagnostic, not a station waiver or FULL credit. Producer runs it.
## Recompute actual terminal Rect2 values instead of parsing rounded log text.
const TERMINAL_MAIN_SHA := "a867438d1fa6b4a4082a31e3f08f20bf4eaf16cba1d659bf8a16eba1d6e8fbd7"
const TERMINAL_HELPER_SHA := "08366bb486074aff11d740e26913921f9e2ca512e85b8cbc94330cc1f9bfbb15"
const TERMINAL_CASES := [["native_ridge_face_west_volume_talus_left", false], ["native_tree_081", true]]

func _initialize() -> void:
	call_deferred("_run_terminal_diagnostic")

func _original_linear_upper(region: Rect2, prop: Sprite2D, image: Image, inverse: Transform2D) -> Dictionary:
	# Independent clipped four-corner extrema of original RGBA interpolation.
	# Same .01 WORLD guard; no nearest approximation, integral image or helper.
	var prop_inverse := (inverse * prop.global_transform).affine_inverse()
	var local := Rect2()
	var first := true
	var grown := region.grow(.01)
	for p: Vector2 in [grown.position, Vector2(grown.end.x, grown.position.y), grown.end, Vector2(grown.position.x, grown.end.y)]:
		var mapped := prop_inverse * p
		if first: local = Rect2(mapped, Vector2.ZERO); first = false
		else: local = local.expand(mapped)
	var render := prop.get_rect()
	var low := local.position.max(render.position)
	var high := local.end.min(render.end)
	if high.x < low.x or high.y < low.y: return {"upper": 0., "texel_span": Vector2.ZERO, "corner_queries": 0}
	var uv_low := (low - render.position) / render.size
	var uv_high := (high - render.position) / render.size
	if prop.flip_h:
		var swap := uv_low.x
		uv_low.x = 1. - uv_high.x
		uv_high.x = 1. - swap
	if prop.flip_v:
		var swap := uv_low.y
		uv_low.y = 1. - uv_high.y
		uv_high.y = 1. - swap
	var frame := _sprite_frame(prop, image)
	var a := Vector2(frame.position) + uv_low * Vector2(frame.size) - Vector2(.5, .5)
	var b := Vector2(frame.position) + uv_high * Vector2(frame.size) - Vector2(.5, .5)
	var maximum := 0.
	var queries := 0
	for y in range(floori(a.y), floori(b.y) + 1):
		for x in range(floori(a.x), floori(b.x) + 1):
			var lo := a.max(Vector2(x, y))
			var hi := b.min(Vector2(x + 1, y + 1))
			if hi.x < lo.x or hi.y < lo.y: continue
			var alphas: Array[float] = []
			for offset: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i.ONE]:
				alphas.append(image.get_pixel(clampi(x + offset.x, 0, image.get_width() - 1), clampi(y + offset.y, 0, image.get_height() - 1)).a)
			for p: Vector2 in [lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y)]:
				var t := p - Vector2(x, y)
				var value := lerpf(lerpf(alphas[0], alphas[1], t.x), lerpf(alphas[2], alphas[3], t.x), t.y) * prop.modulate.a * prop.self_modulate.a
				maximum = maxf(maximum, value)
				queries += 1
	return {"upper": maximum, "texel_span": b - a, "corner_queries": queries, "strict_below_with_existing_guard": maximum + .000001 < .12}

func _terminal_original_pixel_bounds(prop: Sprite2D, box: Rect2) -> Dictionary:
	var player: Node2D = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	var actor_image := _read_image(actor.texture.resource_path)
	var prop_image := _read_image(prop.texture.resource_path)
	var frame := _sprite_frame(actor, actor_image)
	var inverse := (field.get("world_container") as Node2D).global_transform.affine_inverse()
	var actor_transform := inverse * actor.global_transform
	var actor_rect := actor.get_rect()
	var pixels := 0
	var possible_pixels := 0
	var maximum := 0.
	var worst: Dictionary = {}
	var rows: Array[Dictionary] = []
	for y in frame.size.y:
		var start := -1
		var row_maximum := 0.
		var row_a := Vector2.ZERO
		var row_b := Vector2.ZERO
		for x in range(frame.size.x + 1):
			var strong := x < frame.size.x and actor_image.get_pixel(frame.position.x + x, frame.position.y + y).a > .12
			if strong:
				var uv := Vector2((float(x) + .5) / frame.size.x, (float(y) + .5) / frame.size.y)
				if actor.flip_h: uv.x = 1. - uv.x
				if actor.flip_v: uv.y = 1. - uv.y
				var offset := actor_transform * (actor_rect.position + uv * actor_rect.size) - player.position
				var pixel_region := Rect2(box.position + offset, box.size)
				var upper := _original_linear_upper(pixel_region, prop, prop_image, inverse)
				pixels += 1
				if float(upper.upper) + .000001 >= .12: possible_pixels += 1
				row_maximum = maxf(row_maximum, float(upper.upper))
				if float(upper.upper) > maximum:
					maximum = float(upper.upper)
					worst = {"actor_source_pixel": Vector2i(x, y), "offset": offset, "world_region": pixel_region, "bound": upper}
				if start < 0: start = x; row_a = offset
				row_b = offset
			elif start >= 0:
				var region := Rect2(box.position + row_a.min(row_b), box.size + row_a.max(row_b) - row_a.min(row_b))
				var upper := _original_linear_upper(region, prop, prop_image, inverse)
				if float(upper.upper) + .000001 >= .12:
					rows.append({"source_y": y, "source_x_range": [start, x - 1], "row_region": region, "row_bound": upper, "maximum_actual_pixel_upper": row_maximum, "all_actual_pixels_strictly_below": row_maximum + .000001 < .12})
				start = -1
				row_maximum = 0.
	return {"actor_source_path": actor.texture.resource_path, "actor_source_sha256": FileAccess.get_sha256(actor.texture.resource_path), "prop_source_path": prop.texture.resource_path, "prop_source_sha256": FileAccess.get_sha256(prop.texture.resource_path), "actual_frame": frame, "actor_transform": actor_transform, "prop_transform": inverse * prop.global_transform, "terminal": box, "strong_actor_pixels": pixels, "possible_actual_pixel_count": possible_pixels, "maximum_actual_pixel_upper": maximum, "worst_actual_pixel": worst, "possible_row_run_bounds": rows, "numerical_world_guard": .01, "numerical_alpha_guard": .000001, "threshold": .12, "classification": "DIAGNOSTIC_ONLY_NO_DENIED_NO_FULL_CREDIT"}

func _run_terminal_diagnostic() -> void:
	qa_scope = "LIMITED_ACTUAL_ALPHA_TERMINAL_CAUSE_NOT_FULL_WORLD"
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	phase_output = OUTPUT_DIR + "alpha_terminal_cause_" + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique limited diagnostic output")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	_check(DisplayServer.get_name() == "headless", "producer serial headless diagnostic only")
	_check(FileAccess.get_sha256("res://tests/test_world_map_v14_production_20261002.gd") == TERMINAL_MAIN_SHA and FileAccess.get_sha256(ALPHA_INTERVAL_PATH) == TERMINAL_HELPER_SHA, "original failed main/helper exact source binding")
	if failed > 0 or not _asset_binding_checks(): _finish(); return
	_terrain_capture_geometry_checks()
	_structure_saved_mesh_checks()
	_raw_pixel_and_crop_checks()
	if not raw_walk_tiles_exact: _finish(); return
	schema_ready = true
	_prepare_isolated_slots()
	_fixture_new_game()
	if not await _open_world(world.player_spawn): _finish(); return
	_collect_runtime()
	var evidence: Array[Dictionary] = []
	for item: Array in TERMINAL_CASES:
		var id := String(item[0])
		var front := bool(item[1])
		var object: Dictionary = {}
		for entry: Dictionary in world.map_layout.visual_objects:
			if String(entry.get("id")) == id: object = entry; break
		_check(not object.is_empty() and runtime_props.has(id), "actual previously unresolved entity remains present: " + id)
		if object.is_empty() or not runtime_props.has(id): continue
		var prop: Sprite2D = runtime_props[id]
		var classification := _complete_alpha_station(object, prop, front)
		_check(classification.get("status") == "INCONCLUSIVE", "original unresolved classification reproduced, otherwise diagnostic must fail: " + id)
		var observed_terminals := 0
		for record: Dictionary in classification.get("records", []):
			var terminal: Dictionary = record.get("terminal_box", {})
			if typeof(terminal.get("box")) != TYPE_RECT2: continue
			var box: Rect2 = terminal.box
			var player: Node2D = field.get("_player")
			player.position = box.get_center()
			_set_idle(record.facing)
			await _completed_normal_actor_stage()
			var row := _terminal_original_pixel_bounds(prop, box)
			var collisions: Array[Dictionary] = _planning_collisions(player.position)
			var collision_ids: Array[String] = []
			for collision: Dictionary in collisions:
				var node := collision.get("collider") as Node
				collision_ids.append(String(node.get_path()) if is_instance_valid(node) else str(collision.get("collider_id")))
			row["id"] = id
			row["original_classification"] = classification.get("status")
			row["frame_identity"] = record.get("frame_identity", record.get("last_live_probe", {}).get("frame_identity", ""))
			row["relation"] = "front" if front else "behind"
			row["facing"] = record.facing
			row["terminal_depth"] = terminal.get("depth")
			row["original_reason"] = record.get("reason")
			row["original_last_live"] = record.get("last_live_probe")
			row["actual_collision_ids_always_queried"] = collision_ids
			row["actual_full17"] = _foot_clear(player.position)
			row["actual_relation"] = _candidate_actual_foot_relation(player, object, front)
			row["actual_center_hits"] = _actual_actor_alpha_intersection(prop)
			evidence.append(row)
			observed_terminals += 1
			print("[AlphaTerminalCause] id=%s facing=%s rows=%d pixels=%d possible=%d max=%s physics=%s" % [id, record.facing, row.possible_row_run_bounds.size(), row.strong_actor_pixels, row.possible_actual_pixel_count, row.maximum_actual_pixel_upper, collision_ids])
		_check(observed_terminals > 0, "each exact unresolved case retains an actual terminal observation: " + id)
	_checked_alpha_json(phase_output + "terminal_cause.json", {"terminals": evidence, "coverage": "actual failed terminal domains only; no station resolution or continuous absence claim"})
	_check(ghost_positive == 0 and ghost_south_positive == 0, "terminal observations grant zero FULL category credits")
	_finish()
