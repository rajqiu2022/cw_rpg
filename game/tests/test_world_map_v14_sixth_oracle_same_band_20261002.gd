extends "res://tests/test_world_map_v14_production_20261002.gd"

## Bounded genuine Field diagnostic, never full-map or visual acceptance.
## Producer must freeze this source and its base test before authorizing run.
## No renderer/import/GPU, fabricated props, altered NPC shape or user saves.
var focused_evidence: Array = []
var focused_source_images: Dictionary = {}
var focused_actor_pixels: Dictionary = {}

func _bounded_original_alpha_hits(prop: Sprite2D) -> int:
	# Search acceleration reads original source alpha only. Final accepted
	# stations are rechecked by the independent full current-frame main oracle.
	var player: Node2D = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	for sprite: Sprite2D in [actor, prop]:
		var key := sprite.texture.get_instance_id()
		if not focused_source_images.has(key):
			var image := sprite.texture.get_image()
			if image.is_compressed(): image.decompress()
			focused_source_images[key] = image
	var source: Image = focused_source_images[actor.texture.get_instance_id()]
	var target: Image = focused_source_images[prop.texture.get_instance_id()]
	var frame := _sprite_frame(actor, source)
	var actor_key := "%d:%s" % [actor.texture.get_instance_id(), frame]
	if not focused_actor_pixels.has(actor_key):
		var points := PackedVector2Array()
		for y in frame.size.y:
			for x in frame.size.x:
				if source.get_pixelv(frame.position + Vector2i(x, y)).a > .12: points.append(Vector2(x + .5, y + .5) / Vector2(frame.size))
		focused_actor_pixels[actor_key] = points
	var points: PackedVector2Array = focused_actor_pixels[actor_key]
	var count := 0
	for uv: Vector2 in points:
		if actor.flip_h: uv.x = 1.0 - uv.x
		if actor.flip_v: uv.y = 1.0 - uv.y
		var local := prop.to_local(actor.to_global(actor.get_rect().position + uv * actor.get_rect().size))
		if prop.get_rect().has_point(local) and _prop_sample_alpha(prop, target, (local - prop.get_rect().position) / prop.get_rect().size) > .12: count += 1
	return count

func _load_actual_geometry_only() -> bool:
	var geometry := _json(ART_DIR + "geometry.json")
	var mesh := load(String(geometry.get("terrain_mesh_path", ""))) as ArrayMesh
	if mesh == null or mesh.get_surface_count() != 1: return false
	_check(FileAccess.get_sha256(String(geometry.get("terrain_mesh_path"))).to_lower() == String(geometry.get("terrain_mesh_sha256", "")).to_lower(), "bounded fixture uses exact saved iteration7 terrain mesh, not a live draft or archived sixth")
	var arrays := mesh.surface_get_arrays(0)
	terrain_vertices = arrays[Mesh.ARRAY_VERTEX]
	terrain_uvs = arrays[Mesh.ARRAY_TEX_UV]
	terrain_indices = arrays[Mesh.ARRAY_INDEX]
	var shape := _point(geometry.get("height_grid_shape"))
	terrain_cols = int(shape.x) - 1
	terrain_rows = int(shape.y) - 1
	return terrain_cols > 0 and terrain_rows > 0 and terrain_indices.size() == terrain_cols * terrain_rows * 6

func _sixth_camera_checks() -> void:
	var offset := _vec3(manifest.get("camera", {}).get("position"))
	_check(offset.distance_to(_vec3(source_contract.get("camera", {}).get("position"))) < .0001, "full-capture manifest and source contract agree on actual camera offset")
	var count := 0
	for d: Dictionary in source_contract.get("objects", []):
		var metadata_path := String(d.get("native_metadata", ""))
		if metadata_path.is_empty(): metadata_path = String(d.get("metadata_path", ""))
		if metadata_path.is_empty() and String(d.get("id", "")).begins_with("native_") and String(d.get("id")) != "native_cast_shadow": metadata_path = ART_DIR + "entities/" + String(d.id) + ".json"
		if metadata_path.is_empty() or not FileAccess.file_exists(metadata_path): continue
		var meta := _json(metadata_path)
		var camera: Dictionary = meta.get("sourcebody_camera", {})
		var ground := _vec3(meta.get("ground_m"))
		_check(_vec3(camera.get("position")).distance_to(ground + offset) < .0001 and _vec3(camera.get("look_at")).distance_to(ground) < .0001, "bounded actual body camera uses manifest offset, independently of obsolete36 hardcode: " + String(meta.get("id")))
		count += 1
	_check(count == int(manifest.get("native_model_count", -1)), "every captured native body camera checked, not a fixed47 assumption")

func _bounded_pose_reuse_checks() -> void:
	# Three actual source families, not all instance geometry/capture acceptance.
	# The complete suite independently checks every exported instance chain.
	var families: Dictionary = {}
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not id.begins_with("native_") or id == "native_cast_shadow": continue
		var meta := _json(ART_DIR + "entities/" + id + ".json")
		var evidence: Dictionary = meta.get("pose_reuse_evidence", {})
		if String(evidence.get("mode", "")) != "translation_equivalent_same_pose_rgba_reuse": continue
		var family := String(meta.get("source", ""))
		if families.has(family): continue
		var prototype_id := String(evidence.get("prototype_id", ""))
		var prototype := _json(ART_DIR + "entities/" + prototype_id + ".json")
		var prototype_body := _read_image(ART_DIR + "entities/" + prototype_id + "_sourcebody.png")
		var prototype_repeat := _read_image(ART_DIR + "entities/" + prototype_id + "_sourcebody_repeat.png")
		var prototype_crop := _read_image(ART_DIR + "entities/" + prototype_id + ".png")
		var body := _read_image(ART_DIR + "entities/" + id + "_sourcebody.png")
		var repeat := _read_image(ART_DIR + "entities/" + id + "_sourcebody_repeat.png")
		var crop := _read_image(ART_DIR + "entities/" + id + ".png")
		if prototype_body == null or prototype_repeat == null or prototype_crop == null or body == null or repeat == null or crop == null: continue
		_check(prototype_body.get_size() == prototype_repeat.get_size() and prototype_body.get_format() == Image.FORMAT_RGBA8 and prototype_body.get_data() == prototype_repeat.get_data() and prototype_body.get_pixel(0, 0).a == 0 and prototype_body.get_used_rect().has_area(), "bounded original fresh capture is actual localized transparent/repeat RGBA: " + prototype_id)
		_check(_native_pose_capture_checks(prototype, prototype_body, prototype_repeat, prototype_crop) == "fresh", "bounded chain has a genuine fresh prototype: " + prototype_id)
		_check(_native_pose_capture_checks(meta, body, repeat, crop) == "reused", "bounded chain verifies exact translated original-alpha replica: " + id)
		families[family] = true
		focused_evidence.append({"pose_family":family,"fresh_prototype":prototype_id,"translation_replica":id,"translation_m":evidence.get("translation_m"),"not_all_instance_geometry_acceptance":true})
		if families.size() == 3: break
	_check(families.size() == 3, "bounded three independent source-family fresh/replica chains verified; no claim of86 fresh GPU captures")

func _same_band_station(d: Dictionary, prop: Sprite2D) -> Dictionary:
	var player: Node2D = field.get("_player")
	var container: Node2D = field.get("world_container")
	var bounds := _alpha_bounds_world_local(prop)
	var base := float(d.depth_sort_foot_y) * WORLD_SIZE.y
	for delta: float in [1.0, .5, .25]:
		for x in range(maxi(10, floori(bounds.position.x) - 24), mini(int(WORLD_SIZE.x) - 10, ceili(bounds.end.x) + 24), 4):
			for facing: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
				_set_idle(facing)
				var local_visual_offset := container.to_local(Vector2(player.global_position.x, float(player.call("get_depth_sort_y")))).y - player.position.y
				var before := Vector2(x, base - delta - local_visual_offset)
				var after := Vector2(x, base + delta - local_visual_offset)
				if not _planner_clear(before) or not _planner_clear(after): continue
				var minimum_hits := 2147483647
				var same_band := true
				for point: Vector2 in [before, after]:
					player.position = point
					player.call("refresh_depth_sort")
					minimum_hits = mini(minimum_hits, _bounded_original_alpha_hits(prop))
					same_band = same_band and player.z_index == prop.z_index
				if same_band and minimum_hits >= 100:
					return {"before": before, "after": after, "facing": facing, "hits": minimum_hits, "delta": delta}
	print("[SameBandBoundedSearch] id=%s alpha_bounds=%s source_base=%.9f no_pair_with_fullfoot_physics_sameband_and_100_currentframe_hits; no claim of continuous-domain absence" % [d.id, bounds, base])
	return {}

func _run_strong_prop(region: String) -> bool:
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not id.begins_with("native_tree_") or not runtime_props.has(id): continue
		var base := float(d.get("depth_sort_foot_y", 0)) * WORLD_SIZE.y
		if (base > 2048) != (region == "south"): continue
		var prop: Sprite2D = runtime_props[id]
		var station := _same_band_station(d, prop)
		if station.is_empty(): continue
		var player: Node2D = field.get("_player")
		_check(await _place_fixture(station.before), "legal same-band starting fixture: " + id)
		_set_idle(station.facing)
		await process_frame
		_check(_planner_clear(player.position) and player.z_index == prop.z_index and float(player.call("get_depth_sort_y")) < field.get("world_container").to_global(Vector2(0, base)).y and _actual_actor_alpha_intersection(prop) >= 100 and _depth_order(player, prop, false), "same-band behind has genuine strong current-frame alpha and correct actual sibling order: " + id)
		var behind := await _ghost_mask_check("same-band strong behind: " + id)
		_check(int(behind.pixels) >= 100, "same-band actual ghost preserves strong original-alpha union: " + id)
		_check(await _drive_to(station.after), "normal Player input crosses real footline without body/nav collision: " + id)
		_set_idle(station.facing)
		await process_frame
		_check(_planner_clear(player.position) and player.z_index == prop.z_index and float(player.call("get_depth_sort_y")) > field.get("world_container").to_global(Vector2(0, base)).y and _actual_actor_alpha_intersection(prop) >= 100 and _depth_order(player, prop, true), "same-band front remains strong alpha but player actually draws ahead: " + id)
		var front := await _ghost_mask_check("same-band strong front: " + id)
		_check(not front.debug.get("prop_hits", {}).has(id), "front does not acquire this prop's false ghost even within identical z band: " + id)
		focused_evidence.append({"region":region,"id":id,"station":station,"actual_front":player.position,"actor_z":player.z_index,"prop_z":prop.z_index,"front_hits":_actual_actor_alpha_intersection(prop),"behind_union":behind.pixels,"front_union":front.pixels})
		return true
	return false

func _npc_cases() -> void:
	# Candidate has no authored NPCs. Exercise its NORMAL production spawning
	# service with a temporary real NPCNode+existing sprite+unchanged collider.
	# No QA depth metadata assignment: failure exposes production defaults.
	var player: Node2D = field.get("_player")
	var container: Node2D = field.get("world_container")
	var fixture_center := Vector2(INF, INF)
	for route: Dictionary in source_contract.get("routes", []):
		for value: Variant in route.get("points_px", []):
			var point := _point(value)
			if point.y < 2160 or point.y > 2980: continue
			# Select a legal ordinary world position near the middle of an actual
			# 8px global depth band. Do not fake NPC depth metadata or turn a
			# band-boundary pair into a same-band claim.
			var global_anchor := container.to_global(point)
			point = container.to_local(Vector2(global_anchor.x, floor(global_anchor.y / 8.0) * 8.0 + 4.0))
			if _planner_clear(point) and _planner_clear(point + Vector2(64, 0)) and _planner_clear(point + Vector2(-64, 0)):
				fixture_center = point; break
		if fixture_center.is_finite(): break
	_check(fixture_center.is_finite(), "normal southern NPC fixture has independent complete-foot natural route space")
	if not fixture_center.is_finite(): return
	var entries: Array = []
	for i in 2:
		entries.append({"npc_id":"qa_same_band_real_npc_%d" % i,"npc_name":"QA隔离角色","sprite_path":"res://art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png","pos":(fixture_center + Vector2(i * 64, 0)) / WORLD_SIZE,"scale":.65,"movement_mode":"idle"})
	field.call("_spawn_npcs", entries)
	await physics_frame
	await process_frame
	var npcs: Array[NPCNode] = []
	for child: Node in field.get("_actor_layer").get_children():
		if child is NPCNode and String(child.npc_id).begins_with("qa_same_band_real_npc_"): npcs.append(child)
	_check(npcs.size() == 2, "two genuine NPCNode fixtures created through normal Field service")
	if npcs.size() != 2: return
	for npc: NPCNode in npcs:
		_check(int(npc.get_meta("depth_band_max", -1)) == 512 and npc.z_index > 255 and npc.get("_body_collider") is StaticBody2D, "normal v14 southern NPC gets real512 metadata/actual foot collider, never QA-forced: " + npc.npc_id)
	_check(npcs[0].get_depth_sort_y() == npcs[1].get_depth_sort_y() and npcs[0].z_index == npcs[1].z_index and npcs[0].get_index() < npcs[1].get_index(), "identical real NPC foot ties use stable registration order, not random reorder")
	var npc := npcs[0]
	var sprite := npc.sprite
	var base_global := npc.get_depth_sort_y()
	var base := container.to_local(Vector2(npc.global_position.x, base_global)).y
	var found := false
	for separation in range(24, 89, 2):
		for sign in [-1, 1]:
			_set_idle(Vector2.RIGHT if sign < 0 else Vector2.LEFT)
			var player_offset := container.to_local(Vector2(player.global_position.x, float(player.call("get_depth_sort_y")))).y - player.position.y
			var before := Vector2(npc.position.x + sign * separation, base - .5 - player_offset)
			var after := Vector2(before.x, base + .5 - player_offset)
			if not _planner_clear(before) or not _planner_clear(after): continue
			player.position = before
			player.call("refresh_depth_sort")
			if player.z_index != npc.z_index or _actual_actor_alpha_intersection(sprite) <= 0: continue
			player.position = after
			player.call("refresh_depth_sort")
			if player.z_index != npc.z_index or _actual_actor_alpha_intersection(sprite) <= 0: continue
			_check(await _place_fixture(before), "NPC same-band player stand is fullfoot/normal-body clear")
			await process_frame
			_check(float(player.call("get_depth_sort_y")) < npc.get_depth_sort_y() and player.get_index() < npc.get_index(), "actual southern NPC and player same-band behind uses exact visual-foot order")
			_check(await _drive_to(after), "normal Player input crosses NPC footline without entering real collider")
			await process_frame
			_check(_planner_clear(player.position) and player.z_index == npc.z_index and float(player.call("get_depth_sort_y")) > npc.get_depth_sort_y() and player.get_index() > npc.get_index(), "actual southern NPC and player same-band front order updates after real movement")
			focused_evidence.append({"npc":npc.npc_id,"before":before,"after":player.position,"npc_foot":npc.get_depth_sort_y(),"actor_foot":player.call("get_depth_sort_y"),"alpha_hits":_actual_actor_alpha_intersection(sprite),"band":npc.z_index})
			found = true; break
		if found: break
	_check(found, "at least one real-body-clear same-band NPC/current-frame alpha case exists, no fake NPC replacement")
	for node: NPCNode in npcs: node.queue_free()
	await physics_frame

func _run() -> void:
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	qa_scope = "BOUNDED_CAPTURE_ITERATION7_ORACLES_SAME_BAND_NOT_FULL_MAP_NOT_VISUAL"
	phase_output = OUTPUT_DIR + "seventh_oracle_same_band_" + str(int(Time.get_unix_time_from_system())) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output))
	player_saves_before = _actual_player_saves()
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	world = load(active_path) as SceneScript
	_check(DisplayServer.get_name() == "headless" and world != null and int(manifest.get("capture_iteration", -1)) == 7 and not bool(manifest.get("current_outputs_not_ready", true)), "producer-approved bounded headless fixture requires completed iteration7 candidate")
	if failed > 0 or not _load_actual_geometry_only(): _finish(); return
	for name: String in ["land", "walk"]: native_images[name] = _read_image(ART_DIR + name + ".png")
	_structure_saved_mesh_checks()
	_sixth_camera_checks()
	_bounded_pose_reuse_checks()
	_fixture_new_game()
	if not await _open_world(world.player_spawn): _finish(); return
	_collect_runtime()
	await _structure_and_negative_checks()
	_check(await _run_strong_prop("north"), "genuine north strong-alpha same-band mechanism case exists")
	_check(await _run_strong_prop("south"), "genuine south strong-alpha same-band mechanism case exists")
	await _npc_cases()
	_check(_actual_player_saves() == player_saves_before, "bounded fixtures never write any actual player save")
	var evidence_file := FileAccess.open(phase_output + "evidence.json", FileAccess.WRITE)
	if evidence_file != null: evidence_file.store_string(JSON.stringify({"scope":qa_scope,"capture_iteration":int(manifest.get("capture_iteration", -1)),"cases":focused_evidence,"main_source_sha256":FileAccess.get_sha256("res://tests/test_world_map_v14_production_20261002.gd"),"fixture_source_sha256":FileAccess.get_sha256(get_script().resource_path)}, "\t"))
	_finish()
