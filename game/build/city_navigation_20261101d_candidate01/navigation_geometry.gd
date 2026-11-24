extends RefCounted
## Read-only geometry. Uses original immutable bins/masks, never a new NAV oracle.
const SELF := "res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd"
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Pair = preload("res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd")
const MANIFEST := "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const FINISH_BIND := "res://build/scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json"
const FINISH_RUNTIME := "res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/finish8_runtime_READY.gd"
const ADVENTURE := "adventure_luoyang_riverside_route"
const ADVENTURE_SCENE := "res://data/scenes/adventure_luoyang_riverside_route.tres"
const ADVENTURE_LAYOUT := "res://data/maps/adventure_20261030k/luoyang_riverside_layout.tres"
static var _regions: Dictionary = {}
static var _legacy: Dictionary = {}
static var _masks: Dictionary = {}
static var _adventure_scene: SceneScript
static var _loaded := false

static func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func media_paths(path: String) -> Array[String]:
	var paths: Array[String] = [path]
	if not FileAccess.file_exists(path + ".import"): return paths
	paths.append(path + ".import")
	var settings := ConfigFile.new()
	if settings.load(path + ".import") != OK: return paths
	for key: String in settings.get_section_keys("remap"):
		if key.begins_with("path"):
			var gpu: String = String(settings.get_value("remap", key))
			if not paths.has(gpu): paths.append(gpu)
	return paths

static func source_paths() -> Array[String]:
	var paths: Array[String] = [SELF, MANIFEST, FINISH_BIND, FINISH_RUNTIME, Pair.MAIN_FIELD, Pair.REGION_FIELD,
		"res://scripts/autoload/scene_router.gd", "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd",
		"res://build/luoyang_regions_20261027d_source01/region_entry.gd", "res://build/luoyang_regions_20261027d_source01/region_compiler.gd",
		"res://build/luoyang_regions_20261027d_source01/legacy_alias.gd", "res://build/luoyang_regions_20261027d_source01/region_session.gd",
		"res://scripts/field/exit_zone.gd", "res://scenes/exit_zone.tscn", ADVENTURE_SCENE, ADVENTURE_LAYOUT,
		"res://scripts/adventure/adventure_runtime.gd", "res://build/adventure_world_20261031f_system01/world_links.gd",
		"res://data/maps/adventure_20261030k/luoyang_adventure_config.json"]
	var manifest: Dictionary = _json(MANIFEST)
	for id: String in ["luoyang_civic_market_region_27d", "luoyang_estate_region_27d", "luoyang_temple_region_27d"]:
		var binding: Dictionary = manifest.get("compiled_bindings", {}).get(id, {})
		paths.append(String(binding.get("path", "")))
	var finish: Dictionary = _json(FINISH_BIND)
	for id: String in ["ch4_s0_luoyang_gate", "ch4_s2_canal_docks", "luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]:
		var binding: Dictionary = finish.get("scenes", {}).get(id, {})
		paths.append(String(binding.get("payload", {}).get("path", "")))
		if binding.get("mask", {}).get("kind") == "IMPORTED_RGBA8":
			paths.append_array(media_paths(String(binding.mask.path)))
	paths.append_array(media_paths("res://data/maps/adventure_20261030k/luoyang_walk.svg"))
	return paths

static func load_fixed() -> bool:
	if _loaded: return true
	_regions.clear(); _legacy.clear(); _masks.clear()
	var manifest: Dictionary = _json(MANIFEST)
	var finish: Dictionary = _json(FINISH_BIND)
	if manifest.is_empty() or finish.is_empty(): return false
	for id: String in ["luoyang_civic_market_region_27d", "luoyang_estate_region_27d", "luoyang_temple_region_27d"]:
		var row: Dictionary = manifest.compiled_bindings[id]
		if FileAccess.get_sha256(row.path) != row.sha256: return false
		var value: Variant = bytes_to_var(FileAccess.get_file_as_bytes(row.path))
		if not value is Dictionary or value.get("ok") != true or value.get("id") != id: return false
		_regions[id] = value
	for id: String in ["ch4_s0_luoyang_gate", "ch4_s2_canal_docks", "luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]:
		var row: Dictionary = finish.scenes[id]
		if FileAccess.get_sha256(row.payload.path) != row.payload.sha256: return false
		var value: Variant = bytes_to_var(FileAccess.get_file_as_bytes(row.payload.path))
		if not value is Dictionary or value.get("scene_id") != id: return false
		_legacy[id] = value
		if row.mask.kind == "IMPORTED_RGBA8":
			var texture: Texture2D = load(row.mask.path) as Texture2D
			var image: Image = texture.get_image() if texture != null else null
			if image == null: return false
			image.convert(Image.FORMAT_RGBA8)
			var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(image.get_data())
			if hash.finish().hex_encode() != row.mask.RGBA_sha256: return false
			_masks[id] = image
	_adventure_scene = load(ADVENTURE_SCENE) as SceneScript
	_loaded = _adventure_scene != null and _adventure_scene.map_layout != null
	return _loaded

static func size_for(id: String) -> Vector2:
	if _regions.has(id): return _regions[id].size
	if _legacy.has(id): return _legacy[id].world_size_px
	return Vector2(4096,3072) if id == ADVENTURE else Vector2.ZERO

static func region_for(id: String) -> Dictionary:
	return _regions.get(id, {})

static func _cross(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (float(b.x)-a.x)*(float(c.y)-a.y)-(float(b.y)-a.y)*(float(c.x)-a.x)

static func _on(a: Vector2,b: Vector2,p: Vector2) -> bool:
	return _cross(a,b,p)==0.0 and p.x>=minf(a.x,b.x) and p.x<=maxf(a.x,b.x) and p.y>=minf(a.y,b.y) and p.y<=maxf(a.y,b.y)

static func _touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	return (_cross(a,b,c)*_cross(a,b,d)<0 and _cross(c,d,a)*_cross(c,d,b)<0) or _on(a,b,c) or _on(a,b,d) or _on(c,d,a) or _on(c,d,b)

static func safe_static(id: String, foot: Vector2) -> bool:
	if not foot.is_finite(): return false
	if _regions.has(id):
		return Core.safe_body(_regions[id], foot, Vector2(17,12)) and Core.npc_route_clear(_regions[id], foot, foot, Vector2(17,12))
	var size: Vector2 = size_for(id)
	var rect := Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not Rect2(Vector2.ZERO,size).encloses(rect): return false
	var body := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var solids: Array = []
	if _legacy.has(id):
		var payload: Dictionary = _legacy[id]
		solids = payload.effective_solids
		if not _masks.has(id):
			var supported := false
			for floor: PackedVector2Array in payload.effective_walkable_polygons:
				var all_inside := true
				for p: Vector2 in body:
					if not Geometry2D.is_point_in_polygon(p,floor): all_inside=false; break
				if all_inside: supported=true; break
			if not supported: return false
	elif id == ADVENTURE:
		# Original native layout remains the oracle; no generated NAV substitute.
		var layout: WalkableMapLayout = _adventure_scene.map_layout
		for blocker: Dictionary in layout.blockers:
			var center: Vector2 = blocker.pos * size
			var extent: Vector2 = blocker.size * size
			var area := Rect2(center-extent*.5,extent)
			if area.intersects(rect,true): return false
		for p: Vector2 in body:
			var supported := false
			for floor: PackedVector2Array in layout.walkable_regions:
				if Geometry2D.is_point_in_polygon(p/size,floor): supported=true; break
			if not supported: return false
	else: return false
	for polygon: PackedVector2Array in solids:
		if polygon.size() > 0:
			var low: Vector2 = polygon[0]
			var high: Vector2 = low
			var finite := low.is_finite()
			for point: Vector2 in polygon:
				finite = finite and point.is_finite()
				low = low.min(point); high = high.max(point)
			# STRICT separation only; touching and non-finite input keep the original narrow phase.
			if finite and (high.x < rect.position.x or low.x > rect.end.x or high.y < rect.position.y or low.y > rect.end.y): continue
		if not Geometry2D.intersect_polygons(body,polygon).is_empty(): return false
		for p: Vector2 in body:
			if Geometry2D.is_point_in_polygon(p,polygon): return false
		for p: Vector2 in polygon:
			if rect.has_point(p): return false
		for i: int in range(4):
			for j: int in range(polygon.size()):
				if _touch(body[i],body[(i+1)%4],polygon[j],polygon[(j+1)%polygon.size()]): return false
	if _masks.has(id):
		var mask: Image = _masks[id]
		for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
			for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
				var pixel: Color = mask.get_pixel(x,y)
				if pixel.r<.5 or pixel.a<.5: return false
	return true

static func safe_segment(id: String, a: Vector2, b: Vector2) -> bool:
	var steps: int = maxi(1,ceili(a.distance_to(b)))
	for i: int in range(steps+1):
		if not safe_static(id,a.lerp(b,float(i)/steps)): return false
	return not _regions.has(id) or Core.npc_route_clear(_regions[id],a,b,Vector2(17,12))

static func live(field: Node, deep: bool = false) -> bool:
	if not is_instance_valid(field) or field.get_tree().current_scene != field or field.get_script() == null: return false
	if field.get_script().resource_path not in [Pair.MAIN_FIELD,Pair.REGION_FIELD]: return false
	if field.get("_field_loading_complete") != true or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") == true: return false
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null: return false
	if field.get_script().resource_path == Pair.REGION_FIELD:
		var owner: RefCounted = field.get("_region_owner") as RefCounted
		if owner == null or owner.get("_phase") != "LIVE" or not owner.call("matches",field,scene): return false
		return not deep or owner.call("revalidate_boundary",field,scene,field.get("_region"))
	if String(scene.scene_id) == ADVENTURE: return scene.map_layout.resource_path == ADVENTURE_LAYOUT
	var finish: RefCounted = field.get("_finish25i") as RefCounted
	if finish == null or finish.call("state").get("finalized") != true: return false
	return not deep or finish.call("revalidate_boundary")

static func physics_clear(field: Node, foot: Vector2) -> bool:
	var actor: Player = field.get("_player") as Player
	var world: Node2D = field.get("world_container") as Node2D
	if actor == null or world == null: return false
	var shape: CollisionShape2D = actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or shape.shape == null or shape.disabled: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape; query.transform = shape.global_transform
	query.transform.origin += world.to_global(foot)-actor.global_position
	query.collision_mask=actor.collision_mask; query.exclude=[actor.get_rid()]
	query.collide_with_areas=false; query.collide_with_bodies=true; query.margin=0.0
	return actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
