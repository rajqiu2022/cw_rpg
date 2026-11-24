extends SceneTree
## NEW independent V8 whole candidate publisher; coordinate VERSION15 is unchanged.
## This file never activates formal bytes and never accepts pilot evidence.
## Stable VERSION15 staging identities only; runtime art-root integration still
## needs a separately approved change and FULL current-source Field verification.
const CONTRACT = preload("res://scripts/world/world_map_v15_complete_v8_candidate_contract.gd")
const EVIDENCE_GATE = preload("res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd")
const CANDIDATE_ID := &"world_map_jianghu_v15"
const CANDIDATE_PATH := "res://data/scenes/world_map_jianghu_v15.tres"
const LAYOUT_PATH := "res://data/maps/world_map_jianghu_layout_v15.tres"
const STREAM_PATH := "res://data/background_sets/world_map_jianghu_v15_streamed.tres"
const BASELINE_PATH := "res://data/scenes/world_map_jianghu_v14.tres"
const FROZEN_V14_COORDINATE_SHA := {
	"res://data/scenes/world_map_jianghu_v14.tres":"6922d310f952056c556141d6690dc35079880e212e5646700222eaf92b1103a8",
	"res://data/maps/world_map_jianghu_layout_v14.tres":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b",
	"res://data/background_sets/world_map_jianghu_v14_streamed.tres":"e933d6e6b5e6bbad569831bd6ca3f9bd785cb9df3b8e12e4c205f551d7d6c67d",
}
const VECTOR_KEYS := ["pos", "size", "target_pos", "marker_offset", "collision_size", "collision_offset", "render_size_px", "scale", "interaction_size", "interaction_offset", "prompt_offset", "walkability_margin_px"]
const POLYGON_KEYS := ["interaction_polygon_px", "passage_polygon_px", "passage_path_px"]

func _initialize() -> void:
	_publish.call_deferred()

func _publish() -> void:
	if "--activate" in OS.get_cmdline_user_args() or not "--publish-whole-v8-candidate" in OS.get_cmdline_user_args(): _fail("Explicit candidate publication required; activation belongs to independent producer acceptance"); return
	if CONTRACT.CANDIDATE_ID != CANDIDATE_ID or CONTRACT.CANDIDATE_PATH != CANDIDATE_PATH or CONTRACT.LAYOUT_PATH != LAYOUT_PATH or CONTRACT.STREAM_PATH != STREAM_PATH:
		_fail("Stable VERSION15 staging identities changed"); return
	for path: String in [CANDIDATE_PATH,LAYOUT_PATH,STREAM_PATH]:
		if FileAccess.file_exists(path): _fail("Stable staging target already exists; no overwrite without root byte-identity review"); return
	if FileAccess.get_sha256(CONTRACT.EVIDENCE_GATE_PATH).to_lower() != CONTRACT.EVIDENCE_GATE_SHA: _fail("Exact V8 gate changed; explicit root rebind required"); return
	if EVIDENCE_GATE.SOURCE_PATH != CONTRACT.SOURCE_PATH or EVIDENCE_GATE.MANIFEST_PATH != CONTRACT.MANIFEST_PATH or EVIDENCE_GATE.PROTOCOL != CONTRACT.CAPTURE_PROTOCOL: _fail("V8 gate/candidate contract identity differs"); return
	var source := CONTRACT.read_json(EVIDENCE_GATE.SOURCE_PATH)
	var manifest := CONTRACT.read_json(EVIDENCE_GATE.MANIFEST_PATH)
	if not _number(source.get("schema_version"), 15) or not _size(source.get("world_size"), CONTRACT.SIZE) or source.get("status") != "ART_ASSETS_READY":
		_fail("Incomplete v15 source contract"); return
	if manifest.get("version") != "world_v15" or not manifest.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "PRODUCTION_APPROVED"]:
		_fail("Incomplete v15 capture manifest"); return
	var evidence_error := EVIDENCE_GATE.validate(source, manifest)
	if not evidence_error.is_empty(): _fail(evidence_error); return
	var independent_review: Dictionary = CONTRACT.read_json(EVIDENCE_GATE.REVIEW)
	for path: String in FROZEN_V14_COORDINATE_SHA:
		if FileAccess.get_sha256(path).to_lower() != FROZEN_V14_COORDINATE_SHA[path]: _fail("Frozen v14 migration/gameplay bytes changed " + path); return
	var baseline := ResourceLoader.load(BASELINE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if baseline == null or not SceneRouter.WORLD_V14.is_v14(baseline): _fail("Frozen v14 coordinate/gameplay baseline unavailable"); return
	var layout := WalkableMapLayout.new()
	layout.schema_version = 15
	layout.design_size = Vector2i(CONTRACT.SIZE)
	layout.display_at_native_size = true
	var stream := StreamedBackgroundSet.new()
	stream.logical_size = layout.design_size
	stream.mobile_preview_path = String(source.get("overview_path", ""))
	stream.desktop_preview_path = stream.mobile_preview_path
	stream.load_padding = 160
	stream.retain_padding = 448
	if not stream.mobile_preview_path.begins_with("res://art/maps/world_map_v15_complete_v8/") or not FileAccess.file_exists(stream.mobile_preview_path): _fail("Missing v15 overview"); return
	for row in 8:
		for col in 8:
			var rect := Rect2(col * 1536, row * 1024, 1536, 1024)
			var prefix := "res://art/maps/world_map_v15_complete_v8/chunks/r%d_c%d_" % [row, col]
			var visual := prefix + "visual.png"
			var walk := prefix + "walk.png"
			if not _png_size(visual, CONTRACT.TILE_SIZE) or not _png_size(walk, CONTRACT.TILE_SIZE): _fail("Missing/wrong native tile " + prefix); return
			stream.mobile_chunks.append({"path": visual, "logical_rect": rect, "draw_position": rect.position, "draw_scale": 1.0})
			layout.walkable_mask_tiles.append({"path": walk, "logical_rect": rect})
	var ids: Array[String] = []
	for raw: Dictionary in source.get("portals", []):
		var portal := _runtime_dictionary(raw)
		var id := String(portal.get("id", ""))
		if id not in CONTRACT.PORTAL_IDS or id in ids: _fail("Invalid/duplicate portal " + id); return
		var original: Dictionary = {}
		for entry: Dictionary in baseline.map_layout.portals:
			if String(entry.id) == id: original = entry.duplicate(true); break
		if original.is_empty() or portal.get("target_scene") != original.get("target_scene") or portal.get("target_pos") != original.get("target_pos"):
			_fail("Changed gameplay destination " + id); return
		var door_review_error: String = EVIDENCE_GATE.door_review_error(raw, independent_review, manifest.asset_sha256)
		if not door_review_error.is_empty(): _fail(door_review_error); return
		if not _pair_finite(raw.get("source_doorstep_uv")) or not _pair_finite(raw.get("door_foot_px")):
			_fail("Unreviewed actual visible doorway " + id); return
		var foot := Vector2(float(raw.door_foot_px[0]), float(raw.door_foot_px[1]))
		if not portal.get("pos") is Vector2 or ((portal.pos as Vector2) * CONTRACT.SIZE).distance_to(foot) > .01:
			_fail("Door/portal/return anchor mismatch " + id); return
		var polygon: PackedVector2Array = portal.get("interaction_polygon_px", PackedVector2Array())
		if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty() or not Geometry2D.is_point_in_polygon(foot, polygon):
			_fail("Invalid visible doorway interaction polygon " + id); return
		original.merge(portal, true)
		layout.portals.append(original)
		ids.append(id)
	if ids.size() != 16: _fail("All sixteen gameplay entrances are required"); return
	var object_ids: Array[String] = []
	for raw: Dictionary in source.get("objects", []):
		var object := _runtime_dictionary(raw)
		var id := String(object.get("id", ""))
		var texture := String(object.get("texture", ""))
		if id.is_empty() or id in object_ids or not texture.begins_with("res://art/maps/world_map_v15_complete_v8/") or not FileAccess.file_exists(texture): _fail("Invalid independent entity " + id); return
		object_ids.append(id)
		layout.visual_objects.append(object)
	for raw: Dictionary in source.get("blockers", []): layout.blockers.append(_runtime_dictionary(raw))
	for route: Dictionary in source.get("routes", []):
		var points := PackedVector2Array()
		for pair: Array in route.get("points_px", []):
			if not _pair_finite(pair): _fail("Invalid route point"); return
			points.append(Vector2(float(pair[0]), float(pair[1])) / CONTRACT.SIZE)
		layout.travel_routes.append({"id": String(route.get("id", "")), "points": points, "width_px": float(route.get("width_px", 0)), "baked_into_terrain": true})
	layout.take_over_path(LAYOUT_PATH)
	stream.take_over_path(STREAM_PATH)
	var scene := baseline.duplicate(true) as SceneScript
	scene.scene_id = CANDIDATE_ID
	scene.map_layout = layout
	scene.streamed_background = stream
	# Only chunks render in Field; this preview is the low-memory fallback.
	scene.background_path = stream.mobile_preview_path
	var spawn_px: Vector2 = EVIDENCE_GATE.reviewed_spawn_px(source, independent_review)
	if not spawn_px.is_finite(): _fail("Missing/invalid independently authored spawn; explicit invalid source cannot fall back"); return
	scene.player_spawn = spawn_px / CONTRACT.SIZE
	# This is the candidate's full17/navigation/solid preflight, NOT actual
	# Physics2D Field input approval. Independent normal Field QA remains required.
	if not EVIDENCE_GATE.safe_source_foot(source, spawn_px): _fail("Unsafe full17 default spawn"); return
	for portal: Dictionary in layout.portals:
		if not EVIDENCE_GATE.safe_source_foot(source, portal.pos * CONTRACT.SIZE): _fail("Unsafe full17 doorway " + String(portal.id)); return
		if not _passage_safe(source, portal): _fail("Unsafe full17 continuous doorway passage " + String(portal.id)); return
	if ResourceSaver.save(layout, LAYOUT_PATH) != OK or ResourceSaver.save(stream, STREAM_PATH) != OK or ResourceSaver.save(scene, CANDIDATE_PATH) != OK:
		_fail("Candidate resource publication failed"); return
	var actual := ResourceLoader.load(CANDIDATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if actual == null or actual.scene_id != CANDIDATE_ID or actual.map_layout == null or actual.map_layout.resource_path != LAYOUT_PATH or actual.map_layout.design_size != Vector2i(CONTRACT.SIZE) or actual.map_layout.schema_version != 15 or actual.streamed_background == null or actual.streamed_background.resource_path != STREAM_PATH:
		_fail("Published candidate lost external layout/stream identities"); return
	print("WORLD_V15_WHOLE_V8_CANDIDATE_PUBLISHED_NOT_ACTIVATED")
	quit(0)

func _passage_safe(source: Dictionary, portal: Dictionary) -> bool:
	var path: PackedVector2Array = portal.get("passage_path_px", PackedVector2Array())
	var area: PackedVector2Array = portal.get("passage_polygon_px", PackedVector2Array())
	if path.size() < 2 or area.size() < 3: return false
	for i in range(path.size() - 1):
		var steps := maxi(1, ceili(path[i].distance_to(path[i + 1]) / 4.0))
		for j in range(steps + 1):
			var point := path[i].lerp(path[i + 1], float(j) / steps)
			if not Geometry2D.is_point_in_polygon(point, area) or not EVIDENCE_GATE.safe_source_foot(source, point): return false
	return true

func _runtime_dictionary(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	for key: String in VECTOR_KEYS:
		if result.has(key) and _pair_finite(result[key]): result[key] = Vector2(float(result[key][0]), float(result[key][1]))
	for key: String in POLYGON_KEYS:
		if not result.get(key) is Array: continue
		var polygon := PackedVector2Array()
		for point: Variant in result[key]:
			if not _pair_finite(point): return {}
			polygon.append(Vector2(float(point[0]), float(point[1])))
		result[key] = polygon
	if result.has("solid_polygons_px"):
		if not result.solid_polygons_px is Array: return {}
		var polygons: Array[PackedVector2Array] = []
		for raw_polygon: Variant in result.solid_polygons_px:
			if not raw_polygon is Array: return {}
			var polygon := PackedVector2Array()
			for point: Variant in raw_polygon:
				if not _pair_finite(point): return {}
				polygon.append(Vector2(float(point[0]), float(point[1])))
			polygons.append(polygon)
		result.solid_polygons_px = polygons
	return result

func _number(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

func _pair_finite(value: Variant) -> bool:
	return value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1]))

func _size(value: Variant, expected: Vector2) -> bool:
	return value is Array and value.size() == 2 and _number(value[0], expected.x) and _number(value[1], expected.y)

func _png_size(path: String, expected: Vector2i) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 24: return false
	var signature := file.get_buffer(8)
	if signature != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]): return false
	file.big_endian = true
	if file.get_32() != 13 or file.get_buffer(4).get_string_from_ascii() != "IHDR": return false
	return file.get_32() == expected.x and file.get_32() == expected.y

func _fail(reason: String) -> void:
	push_error("WorldV15 whole-v8 candidate refused: " + reason)
	quit(1)
