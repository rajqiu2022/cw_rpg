extends RefCounted
## NEW independent V8 candidate API; coordinate VERSION15 and frozen V14 remain unchanged.
## No production alias, approval or activation is written by this contract.
## Static methods/state are independent: a const subclass cannot rebind lexical paths.
const VERSION := 15
const SIZE := Vector2(12288, 8192)
const TILE_SIZE := Vector2i(1536, 1024)
const CANDIDATE_ID := &"world_map_jianghu_v15"
const CANDIDATE_PATH := "res://data/scenes/world_map_jianghu_v15.tres"
const LAYOUT_PATH := "res://data/maps/world_map_jianghu_layout_v15.tres"
const STREAM_PATH := "res://data/background_sets/world_map_jianghu_v15_streamed.tres"
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v8_source.json"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v8/art_contract.json"
const ROOT := "res://art/maps/world_map_v15_complete_v8/"
const EVIDENCE_GATE_PATH := "res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd"
const EVIDENCE_GATE_SHA := "54b8a25581d1680db23ca2c6c292bef60f5749dc53690cb435a2a85680c006ef"
const EVIDENCE_GATE = preload("res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd")
const CAPTURE_PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const V14 = preload("res://scripts/world/world_map_v14_contract.gd")
const PORTAL_IDS = V14.PORTAL_IDS
const VISUAL_MARGIN_PX := Vector2(18.432, 12.288)
const NAV_TILE_CACHE_LIMIT := 12
static var _layout: WalkableMapLayout
static var _blockers: Array[Rect2] = []
static var _solid_polygons: Array[PackedVector2Array] = []
static var _solid_bounds: Array[Rect2] = []
static var _geometry_valid := false
static var _tiles: Dictionary = {}
static var _tile_lru: Array[Vector2i] = []
static var _foot_offsets := PackedVector2Array()
static var _migration_debug: Dictionary = {}
static var _bound_candidate_layout: WalkableMapLayout
static var _bound_candidate_scene: SceneScript

static func read_json(path: String) -> Dictionary:
	return V14.read_json(path)

static func candidate_evidence_error() -> String:
	# Explicit complete publication preflight. It is not called on every foot
	# sample and never replaces independent normal Field/Physics/input QA.
	if FileAccess.get_sha256(EVIDENCE_GATE_PATH).to_lower() != EVIDENCE_GATE_SHA: return "Pinned V8 publication gate changed; explicit root rebind required"
	if EVIDENCE_GATE.SOURCE_PATH != SOURCE_PATH or EVIDENCE_GATE.MANIFEST_PATH != MANIFEST_PATH or EVIDENCE_GATE.PROTOCOL != CAPTURE_PROTOCOL: return "V8 gate source/protocol identity differs"
	return EVIDENCE_GATE.validate(read_json(SOURCE_PATH), read_json(MANIFEST_PATH))

static func _candidate_binding_error(scene: SceneScript) -> String:
	# Positive identity is cached only for the same immutable Scene/layout pair,
	# matching the existing per-layout geometry cache. A new publication/pin
	# requires a fresh process; parent QA also snapshots every current byte.
	if _bound_candidate_scene == scene and _bound_candidate_layout == scene.map_layout: return ""
	if FileAccess.get_sha256(EVIDENCE_GATE_PATH).to_lower() != EVIDENCE_GATE_SHA: return "Pinned V8 gate changed"
	if EVIDENCE_GATE.SOURCE_PATH != SOURCE_PATH or EVIDENCE_GATE.MANIFEST_PATH != MANIFEST_PATH or EVIDENCE_GATE.ROOT != ROOT or EVIDENCE_GATE.PROTOCOL != CAPTURE_PROTOCOL: return "V8 source/protocol binding differs"
	var source_sha := String(EVIDENCE_GATE.FROZEN_SOURCE_SHA).to_lower()
	var manifest_sha := String(EVIDENCE_GATE.FROZEN_MANIFEST_SHA).to_lower()
	if source_sha.length() != 64 or manifest_sha.length() != 64 or not FileAccess.file_exists(SOURCE_PATH) or not FileAccess.file_exists(MANIFEST_PATH): return "V8 SOURCE/MANIFEST PENDING"
	if FileAccess.get_sha256(SOURCE_PATH).to_lower() != source_sha or FileAccess.get_sha256(MANIFEST_PATH).to_lower() != manifest_sha: return "V8 current source/manifest bytes differ"
	var source := read_json(SOURCE_PATH)
	var manifest := read_json(MANIFEST_PATH)
	if source.get("art_revision") != "complete_v8_coherent_whole" or manifest.get("art_revision") != "complete_v8_coherent_whole" or source.get("status") != "ART_ASSETS_READY" or manifest.get("status") != "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA": return "Incomplete V8 candidate source"
	var catalog: Variant = manifest.get("asset_sha256")
	if not catalog is Dictionary: return "Missing V8 review asset catalog"
	# Reuse the exact pinned gate's independent root review predicates. This is
	# an identity/review guard, not a second claim of complete capture validation.
	var review_error: String = EVIDENCE_GATE._review(source, manifest, catalog)
	if not review_error.is_empty(): return review_error
	if scene.streamed_background == null or scene.streamed_background.resource_path != STREAM_PATH or scene.streamed_background.logical_size != Vector2i(SIZE) or scene.background_path != String(source.get("overview_path", "")) or not scene.background_path.begins_with(ROOT): return "Candidate stream/overview is not V8"
	if scene.map_layout.walkable_mask_tiles.size() != 64 or scene.streamed_background.mobile_chunks.size() != 64: return "V8 candidate must retain all64 native chunks"
	var cells: Dictionary = {}
	for entry: Dictionary in scene.map_layout.walkable_mask_tiles:
		var rect: Variant = entry.get("logical_rect")
		if not rect is Rect2: return "Malformed V8 native nav rect"
		var col := int(rect.position.x) / TILE_SIZE.x
		var row := int(rect.position.y) / TILE_SIZE.y
		if col < 0 or col > 7 or row < 0 or row > 7 or rect != Rect2(Vector2(col * TILE_SIZE.x, row * TILE_SIZE.y), Vector2(TILE_SIZE)): return "Wrong V8 native nav domain"
		var id := "r%d_c%d" % [row, col]
		if cells.has(id) or entry.get("path") != ROOT + "chunks/" + id + "_walk.png": return "Old/duplicate V8 nav tile identity"
		cells[id] = true
	var visual_cells: Dictionary = {}
	for entry: Dictionary in scene.streamed_background.mobile_chunks:
		var rect: Variant = entry.get("logical_rect")
		if not rect is Rect2: return "Malformed V8 native visual rect"
		var col := int(rect.position.x) / TILE_SIZE.x
		var row := int(rect.position.y) / TILE_SIZE.y
		if col < 0 or col > 7 or row < 0 or row > 7 or rect != Rect2(Vector2(col * TILE_SIZE.x, row * TILE_SIZE.y), Vector2(TILE_SIZE)): return "Wrong V8 native visual domain"
		var id := "r%d_c%d" % [row, col]
		if visual_cells.has(id) or entry.get("path") != ROOT + "chunks/" + id + "_visual.png" or entry.get("draw_position") != rect.position or entry.get("draw_scale") != 1.0: return "Old/duplicate/scaled V8 visual tile identity"
		visual_cells[id] = true
	for entry: Dictionary in scene.map_layout.visual_objects:
		if not String(entry.get("texture", "")).begins_with(ROOT): return "Old independent entity identity"
	_bound_candidate_layout = scene.map_layout
	_bound_candidate_scene = scene
	return ""

static func is_v15(scene: SceneScript) -> bool:
	if scene == null or scene.map_layout == null or scene.map_layout.schema_version != VERSION or scene.map_layout.resource_path != LAYOUT_PATH or scene.map_layout.design_size != Vector2i(SIZE): return false
	return _candidate_binding_error(scene).is_empty()

static func formal_version() -> int:
	return VERSION if is_v15(load("res://data/scenes/world_map_jianghu.tres") as SceneScript) else V14.formal_version()

static func source_scene(version: int) -> SceneScript:
	if version == VERSION:
		var candidate := load(CANDIDATE_PATH) as SceneScript if ResourceLoader.exists(CANDIDATE_PATH) else null
		return candidate if is_v15(candidate) else null
	if version in [12, 13, 14]: return V14.source_scene(version)
	return null # Unknown coordinate spaces must not be mistaken for v12.

static func _prepare(scene: SceneScript) -> void:
	if _layout == scene.map_layout: return
	_layout = scene.map_layout
	_tiles.clear()
	_tile_lru.clear()
	_blockers.clear()
	_solid_polygons.clear()
	_solid_bounds.clear()
	_geometry_valid = true
	for entry: Dictionary in _layout.visual_objects:
		if entry.has("solid_polygons_px"):
			var authored: Variant = entry.solid_polygons_px
			if not authored is Array or authored.is_empty():
				_geometry_valid = false
				continue
			for polygon: Variant in authored:
				if not polygon is PackedVector2Array or polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty():
					_geometry_valid = false
					continue
				var minimum: Vector2 = polygon[0]
				var maximum: Vector2 = polygon[0]
				for point: Vector2 in polygon:
					if not point.is_finite() or point.x < 0 or point.y < 0 or point.x >= SIZE.x or point.y >= SIZE.y: _geometry_valid = false
					minimum = minimum.min(point)
					maximum = maximum.max(point)
				_solid_polygons.append(polygon)
				_solid_bounds.append(Rect2(minimum, maximum - minimum))
			# An exact measured multi-polygon doorway cannot also be sealed by
			# the old conservative whole-compound rectangular blocker.
			continue
		if not entry.has("collision_size"): continue
		var center: Vector2 = (entry.get("pos", Vector2.ZERO) + entry.get("collision_offset", Vector2.ZERO)) * SIZE
		var extent: Vector2 = entry.collision_size * SIZE
		var margin: Vector2 = entry.get("walkability_margin_px", VISUAL_MARGIN_PX)
		_blockers.append(Rect2(center - extent * .5 - margin, extent + margin * 2))
	for entry: Dictionary in _layout.blockers:
		var extent: Vector2 = entry.get("size", Vector2.ZERO) * SIZE
		var center: Vector2 = entry.get("pos", Vector2.ZERO) * SIZE
		var margin: Vector2 = entry.get("walkability_margin_px", Vector2(64.512, 43.008))
		_blockers.append(Rect2(center - extent * .5 - margin, extent + margin * 2))
	if _foot_offsets.is_empty():
		for i in 16: _foot_offsets.append(Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6))
		_foot_offsets.append(Vector2.ZERO)

static func _pixel_clear(point: Vector2) -> bool:
	if not point.is_finite() or point.x < 0 or point.y < 0 or point.x >= SIZE.x or point.y >= SIZE.y: return false
	# One global rounded pixel coordinate: two sides of a chunk seam do not
	# independently rescale/round their local extents.
	var pixel := Vector2i(roundi(point.x), roundi(point.y))
	# Coordinates already address the native global canvas, not a normalized
	# inclusive extent. Reject rounding past the canvas instead of clamping it.
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= SIZE.x or pixel.y >= SIZE.y: return false
	var cell := Vector2i(pixel.x / TILE_SIZE.x, pixel.y / TILE_SIZE.y)
	if not _tile_lru.is_empty() and _tile_lru.back() != cell:
		_tile_lru.erase(cell)
		_tile_lru.append(cell)
	if not _tiles.has(cell):
		var expected := Rect2(Vector2(cell * TILE_SIZE), Vector2(TILE_SIZE))
		var image: Image
		for entry: Dictionary in _layout.walkable_mask_tiles:
			if entry.get("logical_rect", Rect2()) != expected: continue
			var path := String(entry.get("path", ""))
			var texture := load(path) as Texture2D if ResourceLoader.exists(path) else null
			image = texture.get_image() if texture != null else null
			if image == null and FileAccess.file_exists(path): image = Image.load_from_file(path) # Publisher before import only.
			if image != null and image.is_compressed(): image.decompress()
			# Nav must be actual binary RGB+alpha; do not discard alpha to save RAM.
			if image != null and image.get_size() != TILE_SIZE: image = null
			break
		if not cell in _tile_lru: _tile_lru.append(cell)
		while _tile_lru.size() > NAV_TILE_CACHE_LIMIT:
			_tiles.erase(_tile_lru.pop_front())
		_tiles[cell] = image # Cache missing tiles too: fail closed.
	var image: Image = _tiles[cell]
	if image == null: return false
	var local := pixel - cell * TILE_SIZE
	var sample := image.get_pixel(local.x, local.y)
	return sample.a >= .5 and maxf(sample.r, maxf(sample.g, sample.b)) >= .5

static func safe_foot(scene: SceneScript, point: Vector2) -> bool:
	if not is_v15(scene) or not point.is_finite(): return false
	_prepare(scene)
	if not _geometry_valid: return false
	var center := point * SIZE
	var samples := PackedVector2Array()
	var minimum := center
	var maximum := center
	for offset: Vector2 in _foot_offsets:
		var sample := center + offset
		if not _pixel_clear(sample): return false
		samples.append(sample)
		minimum = minimum.min(sample)
		maximum = maximum.max(sample)
	for rect: Rect2 in _blockers:
		if rect.position.x > maximum.x or rect.position.y > maximum.y or rect.end.x < minimum.x or rect.end.y < minimum.y: continue
		for sample: Vector2 in samples:
			if rect.has_point(sample): return false
	for index in _solid_polygons.size():
		var bounds: Rect2 = _solid_bounds[index]
		if bounds.position.x > maximum.x or bounds.position.y > maximum.y or bounds.end.x < minimum.x or bounds.end.y < minimum.y: continue
		for sample: Vector2 in samples:
			if Geometry2D.is_point_in_polygon(sample, _solid_polygons[index]): return false
	return true

static func repair_spawn(scene: SceneScript, point: Vector2) -> Variant:
	if safe_foot(scene, point): return point
	if not is_v15(scene): return null
	var origin := (point if point.is_finite() else scene.player_spawn).clamp(Vector2.ZERO, Vector2.ONE) * SIZE
	for radius in range(4, 197, 4):
		var count := maxi(16, ceili(TAU * radius / 6.0))
		for j in count:
			var probe := (origin + Vector2.from_angle(TAU * j / count) * radius) / SIZE
			if safe_foot(scene, probe): return probe
	# Bounded geographically local recovery. Never silently warp a failed entry
	# to a different city across this much larger world.
	return null

static func migrate_spawn(point: Vector2, from_version: int, target: SceneScript) -> Variant:
	_migration_debug = {"from_version": from_version, "reason": "rejected", "source_point": point}
	if not point.is_finite() or not is_v15(target): return null
	if from_version == VERSION:
		var result: Variant = repair_spawn(target, point)
		_migration_debug.reason = "current_space_local_repair" if result is Vector2 else "current_space_unrepairable"
		return result
	var old := source_scene(from_version)
	if old == null or old.map_layout == null: return null
	var old_size := Vector2(old.map_layout.design_size)
	var anchors: Array[Dictionary] = []
	for a: Dictionary in old.map_layout.portals:
		for b: Dictionary in target.map_layout.portals:
			if String(a.get("id")) != String(b.get("id")): continue
			var old_pos: Vector2 = a.pos
			var new_pos: Vector2 = b.pos
			var distance := ((point - old_pos) * old_size).length()
			if distance <= 64:
				_migration_debug.merge({"reason": "same_portal_id", "portal_id": String(a.id)}, true)
				return repair_spawn(target, new_pos)
			anchors.append({"distance": distance, "delta": new_pos - old_pos, "new_pos": new_pos, "portal_id": String(a.id)})
	anchors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	var delta := Vector2.ZERO
	var weights := 0.0
	for i in mini(4, anchors.size()):
		var weight := 1.0 / maxf(1, float(anchors[i].distance) * float(anchors[i].distance))
		delta += (anchors[i].delta as Vector2) * weight
		weights += weight
	if weights <= 0: return null
	var mapped := point + delta / weights
	var repaired: Variant = repair_spawn(target, mapped)
	if repaired is Vector2:
		_migration_debug.merge({"reason": "geographic_anchor_interpolation", "mapped_point": mapped}, true)
		return repaired
	# Changed geography may map a valid historic free-roam point into a river.
	# Use the nearest OLD geographic gateway's corresponding NEW safe doorway;
	# never an unchecked nearest-white point or an unrelated new map location.
	for anchor: Dictionary in anchors:
		var station: Vector2 = anchor.new_pos
		if safe_foot(target, station):
			_migration_debug.merge({"reason": "historic_free_roam_gateway_fallback", "portal_id": anchor.portal_id, "mapped_point": mapped, "destination_point": station}, true)
			print("[WorldV15Migration] source_version=%d reason=%s portal=%s" % [from_version, _migration_debug.reason, anchor.portal_id])
			return station
	return null

static func get_last_migration_debug() -> Dictionary:
	return _migration_debug.duplicate(true)

static func get_navigation_cache_debug() -> Dictionary:
	return {"tiles": _tiles.size(), "limit": NAV_TILE_CACHE_LIMIT, "lru": _tile_lru.duplicate()}
