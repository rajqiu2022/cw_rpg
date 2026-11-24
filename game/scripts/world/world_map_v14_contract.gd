extends RefCounted
## Production coordinate contract. Art owns pixels; this layer never paints nav.
const VERSION := 14
const SIZE := Vector2(4608, 3072)
const CANDIDATE_ID := &"world_map_jianghu_v14"
const CANDIDATE_PATH := "res://data/scenes/world_map_jianghu_v14.tres"
const LAYOUT_PATH := "res://data/maps/world_map_jianghu_layout_v14.tres"
const STREAM_PATH := "res://data/background_sets/world_map_jianghu_v14_streamed.tres"
const LEGACY_PATH := "res://data/maps/world_map_jianghu_legacy_v12_scene.tres"
const LEGACY_SHA := "09fa89449b1792063e66ad488aa2f60671aa00da2193e5c68acb861df14d71d5"
const SOURCE_PATH := "res://art/maps/world_map_v14/source_contract.json"
const MANIFEST_PATH := "res://art/maps/world_map_v14/manifest.json"
const PORTAL_IDS := ["yanmen_pass", "huashan", "wudang", "gufeng", "lingyue", "bianzhou", "luoyang", "xiangzhou", "jinling", "east_sea_port", "bailu_ferry", "lieyun_valley", "mingwu", "linxi_village", "zhuwei_village", "qinghe_town"]
static var _mask: Image
static var _mask_path := ""
static var _layout: WalkableMapLayout
static var _blockers: Array[Rect2] = []
static var _foot_offsets: PackedVector2Array = PackedVector2Array()

static func read_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value if value is Dictionary else {}

static func is_v14(scene: SceneScript) -> bool:
	return scene != null and scene.map_layout != null and scene.map_layout.schema_version == VERSION and scene.map_layout.resource_path == LAYOUT_PATH

static func formal_version() -> int:
	return VERSION if is_v14(load("res://data/scenes/world_map_jianghu.tres") as SceneScript) else 12

static func source_scene(version: int) -> SceneScript:
	if version == 13:
		return load("res://data/scenes/world_map_jianghu_v13_staging.tres") as SceneScript
	if version == VERSION:
		return load(CANDIDATE_PATH) as SceneScript
	# Never read the mutable canonical resource as old coordinate evidence.
	return load(LEGACY_PATH) as SceneScript if ResourceLoader.exists(LEGACY_PATH) else null

static func safe_foot(scene: SceneScript, point: Vector2) -> bool:
	if not is_v14(scene) or not point.is_finite(): return false
	var path: String = scene.map_layout.walkable_mask_path
	if path != _mask_path or _mask == null:
		var texture := load(path) as Texture2D if ResourceLoader.exists(path) else null
		_mask = texture.get_image() if texture != null else null
		if _mask == null and FileAccess.file_exists(path):
			_mask = Image.load_from_file(path) # Publisher before editor import only.
		if _mask != null and _mask.is_compressed(): _mask.decompress()
		_mask_path = path
	if _mask == null or _mask.get_size() != Vector2i(SIZE): return false
	if _layout != scene.map_layout:
		_layout = scene.map_layout
		_blockers.clear()
		for d: Dictionary in _layout.visual_objects:
			if d.has("collision_size"):
				var center: Vector2 = d.get("pos", Vector2.ZERO) + d.get("collision_offset", Vector2.ZERO)
				var extent: Vector2 = d["collision_size"]
				_blockers.append(Rect2(center - extent * .5, extent).grow(.004))
		for d: Dictionary in _layout.blockers:
			var extent: Vector2 = d.get("size", Vector2.ZERO)
			_blockers.append(Rect2(d.get("pos", Vector2.ZERO) - extent * .5, extent).grow(maxf(0, float(d.get("walkability_margin", .014)))))
	if _foot_offsets.is_empty():
		for i in range(16): _foot_offsets.append(Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6) / SIZE)
		_foot_offsets.append(Vector2.ZERO)
	var samples := PackedVector2Array()
	var minimum := point
	var maximum := point
	for offset: Vector2 in _foot_offsets:
		var p := point + offset
		samples.append(p)
		minimum = minimum.min(p)
		maximum = maximum.max(p)
		if p.x < 0 or p.y < 0 or p.x >= 1 or p.y >= 1: return false
		var sample := _mask.get_pixel(int(round(p.x * (SIZE.x - 1))), int(round(p.y * (SIZE.y - 1))))
		if sample.a < .5 or maxf(sample.r, maxf(sample.g, sample.b)) < .5: return false
	# Inclusive broad phase uses the actual float32 sample extrema, not a
	# theoretical ellipse box that could round past a boundary. Equality stays
	# a candidate; Rect2.has_point alone decides its original end-edge semantics.
	for rect: Rect2 in _blockers:
		if rect.position.x > maximum.x or rect.position.y > maximum.y or rect.end.x < minimum.x or rect.end.y < minimum.y: continue
		for p: Vector2 in samples:
			if rect.has_point(p): return false
	return true

static func repair_spawn(scene: SceneScript, point: Vector2) -> Variant:
	if safe_foot(scene, point): return point
	var origin := (point if point.is_finite() else scene.player_spawn).clamp(Vector2.ZERO, Vector2.ONE) * SIZE
	# Entry-only bounded fine search, then global nearest coarse safe land and
	# local refinement. Never fall back to an unchecked roof or water point.
	for radius in range(4, 197, 4):
		var count := maxi(16, int(ceil(TAU * radius / 6.0)))
		for j in count:
			var p := (origin + Vector2.from_angle(TAU * j / count) * radius) / SIZE
			if safe_foot(scene, p): return p
	var best: Variant = null
	var distance := INF
	for y in range(16, int(SIZE.y), 16):
		for x in range(16, int(SIZE.x), 16):
			var pixel := Vector2(x, y)
			var d := pixel.distance_squared_to(origin)
			if d < distance and safe_foot(scene, pixel / SIZE):
				best = pixel
				distance = d
	if best == null: return null
	var coarse: Vector2 = best
	for y in range(int(coarse.y) - 16, int(coarse.y) + 17, 2):
		for x in range(int(coarse.x) - 16, int(coarse.x) + 17, 2):
			var pixel := Vector2(x, y)
			var d := pixel.distance_squared_to(origin)
			if d < distance and safe_foot(scene, pixel / SIZE):
				best = pixel
				distance = d
	return (best as Vector2) / SIZE

static func migrate_spawn(point: Vector2, from_version: int, target: SceneScript) -> Variant:
	if from_version == VERSION: return repair_spawn(target, point)
	var old := source_scene(from_version)
	if old == null or old.map_layout == null: return repair_spawn(target, target.player_spawn)
	var old_size := Vector2(old.map_layout.design_size)
	var anchors: Array[Dictionary] = []
	for a: Dictionary in old.map_layout.portals:
		for b: Dictionary in target.map_layout.portals:
			if String(a.get("id")) == String(b.get("id")):
				var old_pos: Vector2 = a["pos"]
				var new_pos: Vector2 = b["pos"]
				var d := ((point - old_pos) * old_size).length()
				if d <= 64: return repair_spawn(target, new_pos)
				anchors.append({"distance": d, "delta": new_pos - old_pos})
	anchors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	var delta := Vector2.ZERO
	var weights := 0.0
	for i in mini(4, anchors.size()):
		var weight := 1.0 / maxf(1.0, float(anchors[i].distance) * float(anchors[i].distance))
		delta += (anchors[i].delta as Vector2) * weight
		weights += weight
	var mapped := point + delta / weights if weights > 0 else point
	return repair_spawn(target, mapped)
