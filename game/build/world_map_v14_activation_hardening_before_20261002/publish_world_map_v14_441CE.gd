extends SceneTree
## System publisher. Capture assets first; candidate publication does not activate.
const CONTRACT = preload("res://scripts/world/world_map_v14_contract.gd")
const OFFICIAL := "res://data/scenes/world_map_jianghu.tres"
const VECTOR_KEYS := ["pos", "size", "target_pos", "marker_offset", "collision_size", "collision_offset", "render_size_px", "ground_shadow_size_px", "scale", "interaction_size", "interaction_offset", "prompt_offset"]
const SYSTEM_PATHS := ["world/world_map_v14_contract", "world/v14_modular_overlap", "dev/publish_world_map_v14", "autoload/scene_router", "autoload/save_manager", "field/field_walkable_controller", "field/player", "field/npc_node", "ui/world_map_panel", "ui/result_victory", "ui/result_defeat", "battle/battle_controller"]
const NATIVE_SOURCE_MODELS := [
	"res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf",
	"res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf",
	"res://art/external/polyhaven/pine_sapling_small/pine_sapling_small_1k.gltf",
	"res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf",
	"res://art/external/polyhaven/coastal_cliff_01/coastal_cliff_01_1k.gltf",
	"res://art/external/polyhaven/world_native_v14_ninth/rock_face_01/rock_face_01_1k.gltf"]
const PBR_SOURCE_DIRECTORIES := [
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01",
	"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass",
	"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04",
	"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03",
	"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock",
	"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground"]
const REPOSITORY_EVIDENCE_PATHS := [
	"scripts/fetch_world_v14_sixth_pbr.ps1",
	"scripts/fetch_world_v14_eighth_pbr.ps1",
	"scripts/fetch_world_v14_ninth_pbr.ps1",
	"docs/licensed-world-assets-polyhaven-20260929.md",
	"assets/raw/external/polyhaven/README.md",
	"assets/raw/external/polyhaven/rock_face_01/rock_face_01_1k.gltf",
	"assets/raw/external/polyhaven/rock_face_01/rock_face_01.bin",
	"assets/raw/external/polyhaven/rock_face_01/textures/rock_face_01_arm_1k.jpg",
	"assets/raw/external/polyhaven/rock_face_01/textures/rock_face_01_diff_1k.jpg",
	"assets/raw/external/polyhaven/rock_face_01/textures/rock_face_01_nor_gl_1k.jpg"]

func _initialize() -> void:
	var source := CONTRACT.read_json(CONTRACT.SOURCE_PATH)
	var manifest := CONTRACT.read_json(CONTRACT.MANIFEST_PATH)
	var completed_checks := {"schema": _exact_number(source.get("schema_version"), 14), "size": _world_size_ok(source.get("world_size")), "source_status": source.get("status") == "ART_ASSETS_READY", "manifest_version": manifest.get("version") == "world_v14", "manifest_status": manifest.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "PRODUCTION_APPROVED"]}
	if "--diagnose-source" in OS.get_cmdline_user_args():
		for key: String in ["schema_version", "world_size", "status"]:
			var value: Variant = source.get(key)
			print("SOURCE %s type=%d value=%s" % [key, typeof(value), str(value)])
			if value is Array:
				for component: Variant in value: print("  component type=%d value=%s" % [typeof(component), str(component)])
		for key: String in ["version", "status"]: print("MANIFEST %s type=%d value=%s" % [key, typeof(manifest.get(key)), str(manifest.get(key))])
		print("COMPLETED_CHECKS ", completed_checks, " old_array_equality=", source.get("world_size") == [4608, 3072])
		quit(0)
		return
	if false in completed_checks.values():
		_fail("Art capture is not a completed candidate"); return
	if "--activate" in OS.get_cmdline_user_args():
		_activate()
		return
	for name in ["visual", "land", "walk", "overview"]:
		if not _image_ok("res://art/maps/world_map_v14/%s.png" % name, Vector2i(4608, 3072)):
			_fail("Missing/wrong production image " + name); return
	var old: SceneScript
	if FileAccess.file_exists(CONTRACT.LEGACY_PATH):
		if FileAccess.get_sha256(CONTRACT.LEGACY_PATH).to_lower() != CONTRACT.LEGACY_SHA:
			_fail("Legacy evidence bytes changed"); return
		old = load(CONTRACT.LEGACY_PATH) as SceneScript
	else:
		if FileAccess.get_sha256(OFFICIAL).to_lower() != CONTRACT.LEGACY_SHA:
			_fail("Canonical source is not frozen v12"); return
		var input := FileAccess.open(OFFICIAL, FileAccess.READ)
		var output := FileAccess.open(CONTRACT.LEGACY_PATH, FileAccess.WRITE)
		if input == null or output == null: _fail("Legacy byte copy could not open files"); return
		output.store_buffer(input.get_buffer(input.get_length()))
		output.close()
		if FileAccess.get_sha256(CONTRACT.LEGACY_PATH).to_lower() != CONTRACT.LEGACY_SHA:
			_fail("Legacy byte copy did not preserve SHA"); return
		old = load(CONTRACT.LEGACY_PATH) as SceneScript
	if old == null: _fail("Missing legacy SceneScript"); return
	var layout := WalkableMapLayout.new()
	layout.schema_version = 14
	layout.design_size = Vector2i(4608, 3072)
	layout.display_at_native_size = true
	layout.fill_viewport = false
	layout.walkable_mask_path = String(source["walk_path"])
	var ids: Array[String] = []
	for raw: Dictionary in source.get("portals", []):
		var portal := _runtime_dictionary(raw)
		var id := String(portal.get("id", ""))
		if not id in CONTRACT.PORTAL_IDS or id in ids: _fail("Invalid/duplicate portal " + id); return
		var matches := false
		var gameplay: Dictionary = {}
		for legacy: Dictionary in old.map_layout.portals:
			if String(legacy["id"]) == id:
				matches = portal.get("target_scene") == legacy.get("target_scene") and portal.get("target_pos") == legacy.get("target_pos")
				gameplay = legacy.duplicate(true)
		if not matches: _fail("Changed gameplay portal " + id); return
		# Art authors geometry and label placement. Preserve any production travel
		# mode, story gate, action and marker semantics not present in staging.
		gameplay.merge(portal, true)
		ids.append(id)
		layout.portals.append(gameplay)
	if ids.size() != 16: _fail("Exactly 16 portals required"); return
	var object_ids: Array[String] = []
	for raw: Dictionary in source.get("objects", []):
		var object := _runtime_dictionary(raw)
		var id := String(object.get("id", ""))
		var texture := String(object.get("texture", ""))
		if id.is_empty() or id in object_ids or not texture.begins_with("res://art/maps/world_map_v14/") or not FileAccess.file_exists(texture):
			_fail("Invalid production entity " + id); return
		object_ids.append(id)
		layout.visual_objects.append(object)
	# Keep source route geometry available to runtime QA. It is already drawn
	# by the shared terrain, and Field explicitly skips its duplicate overlay.
	for route: Dictionary in source.get("routes", []):
		var points := PackedVector2Array()
		for p: Array in route.get("points_px", []):
			points.append(Vector2(float(p[0]), float(p[1])) / CONTRACT.SIZE)
		layout.travel_routes.append({"id": String(route["id"]), "points": points, "width_px": float(route["width_px"]), "baked_into_terrain": true})
	var stream := StreamedBackgroundSet.new()
	stream.logical_size = layout.design_size
	stream.mobile_preview_path = String(source.get("overview_path", "res://art/maps/world_map_v14/overview.png"))
	stream.desktop_preview_path = stream.mobile_preview_path
	stream.load_padding = 160
	stream.retain_padding = 448
	for row in 3:
		for col in 3:
			var path := "res://art/maps/world_map_v14/chunks/r%dc%d_visual.png" % [row, col]
			if not _image_ok(path, Vector2i(1536, 1024)): _fail("Invalid chunk " + path); return
			stream.mobile_chunks.append({"path": path, "logical_rect": Rect2(col * 1536, row * 1024, 1536, 1024), "draw_position": Vector2(col * 1536, row * 1024), "draw_scale": 1.0})
	# Give the in-memory layout its final identity for validation, but don't
	# publish partially validated resources over a previous candidate.
	layout.take_over_path(CONTRACT.LAYOUT_PATH)
	stream.take_over_path(CONTRACT.STREAM_PATH)
	var scene := old.duplicate(true) as SceneScript
	scene.scene_id = CONTRACT.CANDIDATE_ID
	scene.map_layout = layout
	scene.streamed_background = stream
	scene.background_path = String(source["visual_path"])
	scene.player_spawn = Vector2(float(source.player_spawn_px[0]), float(source.player_spawn_px[1])) / CONTRACT.SIZE
	if not CONTRACT.safe_foot(scene, scene.player_spawn): _fail("Authored default lacks full-foot clearance"); return
	for portal: Dictionary in scene.map_layout.portals:
		if not CONTRACT.safe_foot(scene, portal.pos): _fail("Unsafe authored portal " + String(portal.id)); return
	if ResourceSaver.save(layout, CONTRACT.LAYOUT_PATH) != OK or ResourceSaver.save(stream, CONTRACT.STREAM_PATH) != OK:
		_fail("Resource publication failed"); return
	if ResourceSaver.save(scene, CONTRACT.CANDIDATE_PATH) != OK: _fail("Candidate save failed"); return
	var published := ResourceLoader.load(CONTRACT.CANDIDATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if published == null or published.map_layout == null or published.streamed_background == null or published.map_layout.resource_path != CONTRACT.LAYOUT_PATH or published.streamed_background.resource_path != CONTRACT.STREAM_PATH:
		_fail("Published scene did not retain external layout/stream identities"); return
	print("WORLD_V14_RESOURCE_BINDINGS scene=%s layout=%s stream=%s" % [published.resource_path, published.map_layout.resource_path, published.streamed_background.resource_path])
	print("WORLD_V14_CANDIDATE_PUBLISHED_NOT_ACTIVATED")
	quit(0)

func _exact_number(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

func _world_size_ok(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _exact_number(value[0], 4608) and _exact_number(value[1], 3072)

func _activate() -> void:
	# Do not re-publish/re-serialize the independently tested candidate here:
	# acceptance binds its actual bytes, not a reconstructed approximation.
	var manifest := CONTRACT.read_json(CONTRACT.MANIFEST_PATH)
	if not _production_manifest_ok(manifest):
		_fail("Activation requires production-approved manifest with explicit visual + production booleans"); return
	var approval := CONTRACT.read_json("res://data/maps/world_map_v14_acceptance.json")
	if approval.get("version") != 14 or typeof(approval.get("technical_approved")) != TYPE_BOOL or typeof(approval.get("visual_approved")) != TYPE_BOOL or not bool(approval.get("technical_approved", false)) or not bool(approval.get("visual_approved", false)) or not _same_hashes(approval.get("asset_sha256", {}), _asset_hashes()):
		_fail("Activation requires current independent visual + technical acceptance"); return
	if FileAccess.get_sha256(CONTRACT.LEGACY_PATH).to_lower() != CONTRACT.LEGACY_SHA:
		_fail("Legacy recovery evidence changed"); return
	var tested := load(CONTRACT.CANDIDATE_PATH) as SceneScript
	if not CONTRACT.is_v14(tested) or tested.scene_id != CONTRACT.CANDIDATE_ID:
		_fail("Missing production candidate"); return
	var scene := tested.duplicate() as SceneScript
	scene.scene_id = &"world_map_jianghu"
	if ResourceSaver.save(scene, OFFICIAL) != OK: _fail("Activation failed"); return
	print("WORLD_V14_ACTIVATED")
	quit(0)

func _production_manifest_ok(manifest: Dictionary) -> bool:
	return manifest.get("version") == "world_v14" and manifest.get("status") == "PRODUCTION_APPROVED" and typeof(manifest.get("visual_approved")) == TYPE_BOOL and typeof(manifest.get("production_approved")) == TYPE_BOOL and manifest.get("visual_approved") == true and manifest.get("production_approved") == true

func _runtime_dictionary(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	for key: String in VECTOR_KEYS:
		if result.has(key) and result[key] is Array and result[key].size() == 2:
			result[key] = Vector2(float(result[key][0]), float(result[key][1]))
	return result

func _image_ok(path: String, size: Vector2i) -> bool:
	var image := Image.load_from_file(path) if FileAccess.file_exists(path) else null
	return image != null and image.get_size() == size

func _asset_hashes() -> Dictionary:
	var paths: Array[String] = [CONTRACT.SOURCE_PATH, CONTRACT.MANIFEST_PATH, CONTRACT.LAYOUT_PATH, CONTRACT.STREAM_PATH, CONTRACT.CANDIDATE_PATH, CONTRACT.LEGACY_PATH,
		"res://data/maps/openworld_bailu_ferry_layout.tres",
		"res://data/maps/openworld_bailu_ferry_layout_before_v14_return_fix_20261002.tres"]
	for system_path: String in SYSTEM_PATHS:
		paths.append("res://scripts/%s.gd" % system_path)
	paths.append("res://scripts/dev/build_world_map_native_full_v14.gd")
	paths.append("res://scripts/dev/build_world_map_native_full_v14_sixth_draft.gd")
	paths.append("res://scripts/dev/world_map_v14_sixth_native_surface.gd")
	paths.append("res://scripts/dev/build_world_map_native_full_v14_seventh_draft.gd")
	paths.append("res://scripts/dev/world_map_v14_seventh_native_surface.gd")
	paths.append("res://scripts/dev/build_world_map_native_full_v14_eighth_draft.gd")
	paths.append("res://scripts/dev/world_map_v14_eighth_native_surface.gd")
	paths.append("res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd")
	paths.append("res://scripts/dev/world_map_v14_ninth_native_surface.gd")
	paths.append("res://art/external/polyhaven/pine_sapling_small/SOURCE.json")
	paths.append("res://art/external/polyhaven/tree_small_02/SOURCE.json")
	paths.append("res://art/external/polyhaven/world_native_v14_ninth/rock_face_01/SOURCE.json")
	var native_source_graph_valid := true
	for model_path: String in NATIVE_SOURCE_MODELS:
		paths.append(model_path)
		if not _append_native_dependencies(model_path, paths): native_source_graph_valid = false
	for directory: String in PBR_SOURCE_DIRECTORIES:
		paths.append(directory + "/SOURCE.json")
		for channel: String in ["diff", "nor_gl", "arm"]:
			paths.append("%s/%s_%s_2k.jpg" % [directory, directory.get_file(), channel])
	# Bind both runtime art and technical source evidence. Source/manifest are
	# already explicit above, so recursive JSON discovery must not duplicate them.
	_collect_art_paths("res://art/maps/world_map_v14", paths)
	paths.sort()
	var result: Dictionary = {}
	for path: String in paths: result[path] = FileAccess.get_sha256(path).to_lower()
	# Fixed repo:// keys are machine-independent; only these exact trusted
	# relative paths are resolved outside the game project, never a manifest URI.
	var repository_root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	for relative_path: String in REPOSITORY_EVIDENCE_PATHS:
		result["repo://" + relative_path] = FileAccess.get_sha256(repository_root.path_join(relative_path)).to_lower()
	# Missing/malformed sources cannot disappear from the approval keyset or
	# approve themselves by matching two empty hashes.
	if not native_source_graph_valid: result["evidence://native-source-graph-invalid"] = ""
	return result

func _append_native_dependencies(model_path: String, paths: Array[String]) -> bool:
	var raw := CONTRACT.read_json(model_path)
	if not raw.get("buffers") is Array or not raw.get("images") is Array or raw["buffers"].is_empty() or raw["images"].is_empty(): return false
	for key: String in ["buffers", "images"]:
		for item: Variant in raw[key]:
			if not item is Dictionary or not item.get("uri") is String: return false
			var uri: String = item["uri"]
			# Embedded bytes already belong to the main glTF hash. External URIs
			# must stay in this registered model directory; never fetch a URL.
			if uri.begins_with("data:"): continue
			if uri.is_empty() or uri.is_absolute_path() or uri.contains(":") or uri.split("/").has("..") or uri.contains("\\"): return false
			var path := model_path.get_base_dir().path_join(uri)
			if not paths.has(path): paths.append(path)
	return true

func _collect_art_paths(folder: String, paths: Array[String]) -> void:
	for filename in DirAccess.get_files_at(folder):
		if filename.get_extension().to_lower() in ["png", "json", "rf", "rgf", "res", "gdshader"]:
			var path := folder + "/" + filename
			if not paths.has(path): paths.append(path)
	for child in DirAccess.get_directories_at(folder):
		_collect_art_paths(folder + "/" + child, paths)

func _same_hashes(raw: Variant, current: Dictionary) -> bool:
	if not raw is Dictionary or raw.size() != current.size(): return false
	for path: String in current:
		if String(current[path]).length() != 64: return false
		if String(raw.get(path, "")).to_lower() != current[path]: return false
	return true

func _fail(reason: String) -> void:
	push_error("[WorldV14Publisher] " + reason)
	quit(1)
