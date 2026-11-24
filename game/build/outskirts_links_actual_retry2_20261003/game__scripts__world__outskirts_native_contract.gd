extends RefCounted
## Three independent local fields, not a world-map coordinate/version contract.
const SIZE := Vector2(1536, 1024)
const ROOT := "res://art/maps/world_map_v15_outskirts/"
const ADOPTION := "res://data/config/outskirts_native_adoption.json"
const ENTRIES := {
	"bamboo": {"scene": &"openworld_v15_bamboo_outskirts", "source": &"linxi_village_scrollmap", "source_pos": Vector2(.55, .53), "return_label": "返回林西南坊", "item": &"herb_bundle"},
	"forest": {"scene": &"openworld_v15_forest_outskirts", "source": &"openworld_xiangzhou_mine_valley", "source_pos": Vector2(.80, .62), "return_label": "返回襄州矿谷", "item": &"timber_bundle"},
	"marsh": {"scene": &"openworld_v15_marsh_outskirts", "source": &"openworld_jinling_reed_marsh", "source_pos": Vector2(.72, .58), "return_label": "返回江南芦荡", "item": &"cloth_roll"},
}
static var _contracts: Dictionary = {}
static var _images: Dictionary = {}

static func biome_for(scene_id: StringName) -> String:
	for biome: String in ENTRIES:
		if ENTRIES[biome].scene == scene_id: return biome
	return ""

static func is_native(scene: SceneScript) -> bool:
	return scene != null and not biome_for(scene.scene_id).is_empty()

static func clear_cache() -> void:
	_contracts.clear()
	_images.clear()

static func _v(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

static func contract_path(biome: String) -> String:
	return ROOT + biome + "/art_contract.json"

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func _enabled(biome: String) -> bool:
	if OS.get_cmdline_user_args().has("--outskirts-candidate-preview"): return true
	var adopted := _read(ADOPTION)
	if adopted.get("status", "") != "APPROVED_LOCAL_FIELDS": return false
	var bindings: Dictionary = adopted.get("contract_sha256", {})
	for required: String in ENTRIES:
		var expected := String(bindings.get(required, ""))
		if expected.length() != 64 or FileAccess.get_sha256(contract_path(required)).to_lower() != expected.to_lower(): return false
	return true

static func authoring_contract(biome: String) -> Dictionary:
	if not ENTRIES.has(biome) or not _enabled(biome): return {}
	if _contracts.has(biome): return _contracts[biome]
	var data := _read(contract_path(biome))
	if int(data.get("schema_version", 0)) != 1 or String(data.get("scene_id", "")) != String(ENTRIES[biome].scene): return {}
	if _v(data.get("logical_size_px", [])) != SIZE: return {}
	if data.get("pixel_sampling", "") != "round_world_pixel" or float(data.get("physical_navigation_margin_px", -1)) != 0: return {}
	if data.get("status", "") not in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "APPROVED_LOCAL_FIELD"]: return {}
	var hashes: Dictionary = data.get("asset_sha256", {})
	if hashes.is_empty(): return {}
	for asset: String in hashes:
		var expected := String(hashes[asset])
		if not asset.begins_with("res://") or expected.length() != 64 or not FileAccess.file_exists(asset) or FileAccess.get_sha256(asset).to_lower() != expected.to_lower(): return {}
	for filename: String in ["terrain_height.rf", "terrain_mesh.res"]:
		if not hashes.has(ROOT + biome + "/" + filename): return {}
	var graph: Dictionary = data.get("capture_graph", {})
	for role: String in ["height_rf", "terrain_mesh", "source_script", "builder_script", "surface_script", "vegetation_script", "camera_contract"]:
		var node: Dictionary = graph.get(role, {})
		var path := String(node.get("path", ""))
		if not hashes.has(path) or String(node.get("sha256", "")).to_lower() != String(hashes[path]).to_lower(): return {}
	var sources: Dictionary = data.get("source_graph", {})
	for role: String in ["source_script", "builder_script", "surface_script", "vegetation_script"]:
		var path := String(graph[role].path)
		if not sources.has(path) or String(sources[path]).to_lower() != String(hashes[path]).to_lower(): return {}
	if String(graph.height_rf.path) != ROOT + biome + "/terrain_height.rf" or String(graph.terrain_mesh.path) != ROOT + biome + "/terrain_mesh.res" or String(graph.camera_contract.path) != ROOT + biome + "/capture_camera.json": return {}
	for anchor: String in ["return_foot_px", "discovery_foot_px"]:
		var point := _v(data.get(anchor, []))
		if not point.is_finite() or point.x < 0 or point.y < 0 or point.x >= SIZE.x or point.y >= SIZE.y: return {}
	for filename: String in ["ground.png", "land.png", "raw_walk.png", "walk.png"]:
		var path := ROOT + biome + "/" + filename
		if not _verified_asset(path, hashes): return {}
		var image := Image.load_from_file(path)
		if image == null or Vector2(image.get_size()) != SIZE: return {}
	var objects: Array = data.get("objects", [])
	if objects.is_empty(): return {}
	var discovery_found := false
	for object: Dictionary in objects:
		var texture := String(object.get("texture", ""))
		if not texture.begins_with(ROOT + biome + "/entities/") or not _verified_asset(texture, hashes): return {}
		if not _valid_object(object): return {}
		if object.get("id", "") == "discovery_cache": discovery_found = true
	if not discovery_found: return {}
	var post: Dictionary = data.get("source_entry_object", {})
	if not _valid_object(post) or not _verified_asset(String(post.get("texture", "")), hashes): return {}
	_contracts[biome] = data
	return data

static func _verified_asset(path: String, hashes: Dictionary) -> bool:
	var expected := String(hashes.get(path, ""))
	return expected.length() == 64 and FileAccess.file_exists(path) and ResourceLoader.exists(path) and FileAccess.get_sha256(path).to_lower() == expected.to_lower()

static func _valid_object(object: Dictionary) -> bool:
	var foot := _v(object.get("world_foot_px", []))
	var size := _v(object.get("render_size_px", []))
	var uv := _v(object.get("foot_uv", []))
	if not foot.is_finite() or not size.is_finite() or size.x <= 0 or size.y <= 0: return false
	if not uv.is_finite() or uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1: return false
	var path := String(object.get("texture", ""))
	var image := Image.load_from_file(path) if FileAccess.file_exists(path) else null
	if image == null or _v(object.get("source_size_px", [])) != Vector2(image.get_size()): return false
	if String(object.get("source_sha256", "")).to_lower() != FileAccess.get_sha256(path).to_lower(): return false
	if bool(object.get("blocking", false)):
		var physical := _v(object.get("physical_center_px", []))
		var collision := _v(object.get("collision_size_px", []))
		if not physical.is_finite() or not collision.is_finite() or collision.x <= 0 or collision.y <= 0: return false
	return true

static func _runtime_object(object: Dictionary, logical_size: Vector2) -> Dictionary:
	var foot := _v(object.world_foot_px)
	var size := _v(object.render_size_px)
	var uv := _v(object.foot_uv)
	var center := foot - (uv - Vector2(.5, .5)) * size
	var result := {"id": object.get("id", "prop"), "texture": object.texture, "pos": center / logical_size, "render_size_px": size, "centered": true, "sort_by_feet": true, "depth_sort_foot_y": foot.y / logical_size.y}
	if bool(object.get("blocking", false)):
		result["collision_size"] = _v(object.collision_size_px) / logical_size
		result["collision_offset"] = (_v(object.physical_center_px) - center) / logical_size
	return result

static func source_spawn_pos(scene: SceneScript, biome: String) -> Vector2:
	# Legacy local maps save an actor origin, whereas these waymarkers address
	# the actual visible feet. Read the normal canonical strip, not an estimated
	# screenshot offset. Every currently selected weapon uses this cell height.
	var foot: Vector2 = ENTRIES[biome].source_pos
	if scene.actor_positions_are_feet: return foot
	var path := Player.FIELD_VARIANT_ROOT + "/sword/lengguyun_sword_idle_down_25d_4f.png"
	var texture := load(path) as Texture2D if ResourceLoader.exists(path) else null
	if texture == null or scene.map_layout == null: return Vector2(INF, INF)
	var offset := float(texture.get_height()) * Player.VISUAL_SCALE * scene.player_visual_scale * .45
	return foot - Vector2(0, offset) / Vector2(scene.map_layout.design_size)

static func materialize(scene: SceneScript) -> SceneScript:
	if scene == null: return null
	var biome := biome_for(scene.scene_id)
	if biome.is_empty(): return _append_source_entry(scene)
	var data := authoring_contract(biome)
	if data.is_empty(): return null
	var result := scene.duplicate(true) as SceneScript
	var layout := result.map_layout
	if layout == null: return null
	layout.visual_objects.clear()
	for object: Dictionary in data.objects:
		var entry := _runtime_object(object, SIZE)
		if object.get("id", "") == "discovery_cache":
			entry["interaction_action"] = "dialog:outskirts_%s_discovery" % biome
			entry["interaction_label"] = "查看遗留物"
			entry["interaction_size"] = Vector2(72, 56) / SIZE
			entry["interaction_offset"] = (_v(data.discovery_foot_px) - _v(entry.pos) * SIZE) / SIZE
			entry["hide_flag"] = "outskirts_%s_material_found" % biome
		layout.visual_objects.append(entry)
	layout.walkable_probes.clear()
	layout.blocked_probes.clear()
	for kind: String in ["walkable_probes", "blocked_probes"]:
		for probe: Dictionary in data.get(kind, []):
			layout.get(kind).append({"id": probe.get("id", "probe"), "pos": _v(probe.get("point_px", [])) / SIZE})
	var return_foot := _v(data.get("return_foot_px", [])) / SIZE
	result.player_spawn = return_foot
	var source_scene := load("res://data/scenes/%s.tres" % ENTRIES[biome].source) as SceneScript
	if source_scene == null: return null
	var source_spawn := source_spawn_pos(source_scene, biome)
	if not source_spawn.is_finite(): return null
	layout.portals = [{"id": "return_to_source", "label": ENTRIES[biome].return_label, "pos": return_foot, "size": Vector2(64, 48) / SIZE, "target_scene": String(ENTRIES[biome].source), "target_pos": source_spawn, "show_destination_label": true}]
	if not safe_foot(result, return_foot) or not safe_foot(result, _v(data.get("discovery_foot_px", [])) / SIZE): return null
	return result

static func _append_source_entry(scene: SceneScript) -> SceneScript:
	for biome: String in ENTRIES:
		var entry: Dictionary = ENTRIES[biome]
		if scene.scene_id != entry.source: continue
		var data := authoring_contract(biome)
		if data.is_empty() or scene.map_layout == null: return scene
		var result := scene.duplicate(true) as SceneScript
		var source_size := Vector2(result.map_layout.design_size)
		var source_spawn := source_spawn_pos(result, biome)
		if not source_spawn.is_finite(): return scene
		var post: Dictionary = data.source_entry_object.duplicate(true)
		var old_foot := _v(post.world_foot_px)
		var foot := (entry.source_pos as Vector2) * source_size + Vector2(32, 0)
		post["world_foot_px"] = foot
		if bool(post.get("blocking", false)): post["physical_center_px"] = foot + _v(post.physical_center_px) - old_foot
		post["id"] = "outskirts_%s_routepost" % biome
		var runtime_post := _runtime_object(post, source_size)
		runtime_post["interaction_action"] = "outskirts_entry:" + biome
		runtime_post["interaction_size"] = Vector2(64, 48) / source_size
		runtime_post["interaction_offset"] = ((entry.source_pos as Vector2) - (runtime_post.pos as Vector2))
		result.map_layout.visual_objects.append(runtime_post)
		result.map_layout.portals.append({"id": "outskirts_%s_entrance" % biome, "label": "前往" + scene_title(biome), "destination_name": scene_title(biome), "pos": entry.source_pos, "source_foot_pos": entry.source_pos, "source_spawn_pos": source_spawn, "size": Vector2(64, 48) / source_size, "target_scene": String(entry.scene), "target_pos": _v(data.return_foot_px) / SIZE, "marker_offset": Vector2(0, 18) / source_size, "show_destination_label": true})
		return result
	return scene

static func scene_title(biome: String) -> String:
	return {"bamboo": "竹溪林", "forest": "襄州密林", "marsh": "金陵南泽"}.get(biome, "郊外")

static func _walk_image(scene: SceneScript) -> Image:
	var path := scene.map_layout.walkable_mask_path
	if not _images.has(path):
		if not ResourceLoader.exists(path): return null
		var texture := load(path) as Texture2D
		if texture == null: return null
		var image := texture.get_image()
		if image == null: return null
		if image.is_compressed(): image.decompress()
		if Vector2(image.get_size()) != SIZE: return null
		_images[path] = image
	return _images[path]

static func safe_foot(scene: SceneScript, position: Vector2) -> bool:
	if not is_native(scene) or scene.map_layout == null or not position.is_finite(): return false
	var image := _walk_image(scene)
	if image == null: return false
	for index in range(17):
		var offset := Vector2.ZERO if index == 0 else Vector2(cos(TAU * float(index - 1) / 16) * 10, sin(TAU * float(index - 1) / 16) * 6)
		var point := position * SIZE + offset
		if point.x < 0 or point.y < 0 or point.x >= SIZE.x or point.y >= SIZE.y: return false
		# Native camera canvas and nav PNG share literal logical pixel coordinates.
		var pixel := Vector2i(clampi(roundi(point.x), 0, int(SIZE.x) - 1), clampi(roundi(point.y), 0, int(SIZE.y) - 1))
		var sample := image.get_pixelv(pixel)
		if sample.a < .5 or maxf(sample.r, maxf(sample.g, sample.b)) < .5: return false
		for object: Dictionary in scene.map_layout.visual_objects:
			if not object.has("collision_size"): continue
			var center: Vector2 = (object.pos + object.collision_offset) * SIZE
			var size: Vector2 = object.collision_size * SIZE
			if Rect2(center - size * .5, size).has_point(point): return false
	return true

static func repair_spawn(scene: SceneScript, requested: Vector2) -> Variant:
	if safe_foot(scene, requested): return requested
	if not requested.is_finite(): return null
	for radius in range(4, 157, 4):
		var count := maxi(16, int(ceil(TAU * radius / 6)))
		for index in range(count):
			var point := requested + Vector2.from_angle(TAU * index / count) * radius / SIZE
			if safe_foot(scene, point): return point
	return null
