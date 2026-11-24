extends RefCounted
## NEW upper-wall geometry + street candidate; final captures are PENDING.
## Original local coordinate VERSION3 and all normal gameplay remain unchanged.
## Mechanically preserves the original normal-gameplay interfaces/migration/875.
## No DRY_RUN dispatcher, no reward/save or formal adoption writes.
## Source-frozen candidates only; independent actual Field/visual approval is separate.
const VERSION := 3
const ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v3/"
const DETAIL_CHECKER := preload("res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd")
const DETAIL_BUILDER := "res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd"
const DETAIL_SURFACE := "res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd"
const DETAIL_ADAPTER := "res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd"
const LEGACY_ROOT := "res://data/maps/luoyang_v3_legacy/"
const SIZE := Vector2(3072, 2048)
const BODY_SIZE := Vector2(34, 24)
const ROOF_BUILDER := "res://scripts/dev/build_luoyang_modular_v3_roof_revision.gd"
const GREY_TILE_BUILDER := "res://scripts/dev/build_luoyang_modular_v3_grey_tile_roof_revision.gd"
const ROOF_TRIAL := "res://scripts/dev/preview_luoyang_v3_wall_tile_cap.gd"
const MATERIAL_BUILDER := "res://scripts/dev/build_luoyang_modular_v3.gd"
const CAPTURE_SCRIPT_SHAS := {
	DETAIL_BUILDER: "0d9607cd3723349a3fce0ecb4f29b35cd0c344ce5f60fe47df4d5039e4dbd676",
	DETAIL_SURFACE: "88e224c9998d3c6cc3bbe0be4571c99188cf4d096813eef2b8ee688a22edf102",
	DETAIL_ADAPTER: "531bfcee9eababe944fd366904355fab57a74b47104eaba2598c6224f3d69f2c",
	"res://scripts/dev/build_luoyang_modular_v3_street_detail_capture_proposal.gd": "be5f9fdbfb463c32b97d80a2f4fca95284199f64759c0bb63adda5244a679630",
	"res://scripts/dev/build_luoyang_modular_v3_street_detail_proposal.gd": "fed19382beb77e9bec1d147dedb70bea548041718b2be372624033b229b1ae11",
	"res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd": "5f6a3f901645bdaed5e8a544c617375e2e2e02f5f2730b42d43895cf129c4dfa",
	"res://scripts/dev/luoyang_modular_v3_source.gd": "3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5",
	"res://scripts/dev/luoyang_modular_v3_surface.gd": "76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52",
	MATERIAL_BUILDER: "3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30",
	ROOF_BUILDER: "9cca9ac63a4a059cc5ac87478ab6ae17ce0c661b1c3d453271da505ea1ca3439",
	GREY_TILE_BUILDER: "9ff930bc7be4f5ee8f7c39c364a01416cf87fc47f073ec3f6edf17ff35dc1e7f",
	ROOF_TRIAL: "88c8f173d97ad8bfb58aff8ede95ab1b4b045840693989fac939a542b594c387",
}
const MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate": "PENDING",
	"ch4_s1_luoyang_yamen": "PENDING",
	"ch4_s2_canal_docks": "PENDING",
	"ch4_s3_luoyang_market": "PENDING",
}
const LEGACY_SHAS := {
	"ch4_s0_luoyang_gate": {"scene": "b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1", "layout": "1d5cca7d70b14032f116964533cc33b9a1b7937beb85c829a4148dfa5c79cc82"},
	"ch4_s1_luoyang_yamen": {"scene": "7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01", "layout": "658d7038a28f63aa84c701f604bd04405dcff3a8df6bacc7c533557e2e73ab63"},
	"ch4_s2_canal_docks": {"scene": "81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5", "layout": "0cc4afd6ec4583b62a9979e79ea88076e2b573f4fa91fb82dd424fa8dfc8c4a3"},
	"ch4_s3_luoyang_market": {"scene": "5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab", "layout": "d99c58dc2ad2e8b1bfbcbc1ac69e7a9aa08e2ac7cfffc773d4b5708f6825b60c"},
}
const LAYOUT_ARRAYS := ["walkable_regions", "walkable_mask_tiles", "tiles", "travel_routes", "visual_objects", "occluders", "actor_fade_zones", "blockers", "interactions", "portals", "walkable_probes", "blocked_probes", "seam_crossing_probes"]
static var _records: Dictionary = {}
static var _masks: Dictionary = {}
static var _solids: Dictionary = {}
static var _errors: Array[String] = []

static func owns_id(id: StringName) -> bool:
	return LEGACY_SHAS.has(String(id))

static func layout_path(id: StringName) -> String:
	return "res://data/maps/%s_layout_v3.tres" % id

static func candidate_path(id: StringName) -> String:
	return "res://data/scenes/luoyang_v3_candidates/%s.tres" % id

static func is_v3(scene: SceneScript) -> bool:
	return scene != null and owns_id(scene.scene_id) and scene.map_layout != null and scene.map_layout.schema_version == VERSION and (scene.map_layout.resource_path == layout_path(scene.scene_id) or (scene.get_meta("luoyang_layered_revision", 0) == VERSION and scene.get_meta("city_manifest_sha", "") == MANIFEST_SHAS[String(scene.scene_id)] and _hash(MANIFEST_SHAS[String(scene.scene_id)])))

static func resolve_scene(scene: SceneScript) -> SceneScript:
	if scene == null or not owns_id(scene.scene_id): return scene
	if is_v3(scene): return scene if runtime_fidelity(scene) else null
	if "--luoyang-v3-candidate" in OS.get_cmdline_user_args(): return materialize(scene.scene_id)
	return scene

static func errors() -> Array[String]:
	return _errors.duplicate()

static func _fail(message: String) -> bool:
	_errors.append(message)
	return false

static func legacy_scene(id: StringName) -> SceneScript:
	if not owns_id(id): return null
	var path := LEGACY_ROOT + String(id) + "_scene.tres"
	var old_layout := LEGACY_ROOT + String(id) + "_layout.tres"
	if FileAccess.get_sha256(path).to_lower() != LEGACY_SHAS[String(id)].scene or FileAccess.get_sha256(old_layout).to_lower() != LEGACY_SHAS[String(id)].layout: return null
	var scene: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout: WalkableMapLayout = ResourceLoader.load(old_layout, "", ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if scene == null or layout == null: return null
	# The byte-exact scene still names its old external canonical layout. After
	# cutover that path may be replaced: bind the separately frozen backup instead.
	# Never mutate either loader result, even when an external resource is cached.
	var copy: SceneScript = _independent_copy(scene) as SceneScript
	if copy == null: return null
	copy.map_layout = _independent_copy(layout) as WalkableMapLayout
	return copy

static func prepare(id: StringName) -> bool:
	_errors.clear()
	if FileAccess.get_sha256("res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd").to_lower() != "21aafe707136e0176a815a67bd2b07b9e74ce5568539ee691a5553a1398f1fd6": return _fail("Exact independent geometry/material checker changed; refreeze required")
	_records.erase(String(id))
	_masks.erase(String(id))
	_solids.erase(String(id))
	if not owns_id(id): return _fail("Unknown Luoyang region")
	if not _hash(MANIFEST_SHAS[String(id)]): return _fail("Luoyang v3 art NOT_READY; no formal/candidate materialization")
	var path := ROOT + String(id) + "/art_contract.json"
	if FileAccess.get_sha256(path).to_lower() != MANIFEST_SHAS[String(id)]: return _fail("Frozen city manifest missing/changed")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary: return _fail("Malformed city manifest")
	var record: Dictionary = raw
	if record.get("canonical_scene_id") != String(id) or not _num(record.get("schema_version"), 1) or _vec(record.get("logical_size_px")) != SIZE: return _fail("City identity/canvas mismatch")
	if record.get("status") != "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA" or record.get("pixel_sampling") != "round_world_pixel" or not _num(record.get("physical_navigation_margin_px"), 0): return _fail("Unready/native pixel contract mismatch")
	if _vec(record.get("ordinary_actor_body_px")) != BODY_SIZE or not _num(record.get("ordinary_actor_visual_scale"), .91): return _fail("Ordinary city actor contract mismatch")
	var catalog: Variant = record.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty(): return _fail("Missing city asset catalog")
	for asset: Variant in catalog:
		if not asset is String or not String(asset).begins_with("res://") or ".." in String(asset) or not _hash(catalog[asset]) or FileAccess.get_sha256(asset).to_lower() != String(catalog[asset]).to_lower(): return _fail("Changed city asset: " + str(asset))
	for role: String in ["source_graph", "capture_graph"]:
		var graph: Variant = record.get(role)
		if not graph is Dictionary or graph.is_empty(): return _fail("Missing city " + role)
		for key: Variant in graph:
			if role == "capture_graph" and not graph[key] is Dictionary: return _fail("Malformed city capture graph role")
			var asset: String = String(key) if role == "source_graph" else String(graph[key].get("path", ""))
			var sha: Variant = graph[key] if role == "source_graph" else graph[key].get("sha256")
			if not catalog.has(asset) or not _hash(sha) or String(sha).to_lower() != String(catalog[asset]).to_lower(): return _fail("Unbound city source/capture graph")
	var capture_error: String = _capture_graph_error(record, catalog, id)
	if not capture_error.is_empty(): return _fail(capture_error)
	for key: String in ["ground_path", "land_path", "raw_walk_path", "walk_path"]:
		var asset: String = String(record.get(key, ""))
		if not asset.begins_with(ROOT + String(id) + "/") or not catalog.has(asset): return _fail("Unbound city canvas " + key)
		var image: Image = Image.load_from_file(asset)
		if image == null or image.get_size() != Vector2i(SIZE) or not ResourceLoader.exists(asset): return _fail("Missing city canvas/import " + key)
		if key == "walk_path":
			image.convert(Image.FORMAT_RGBA8)
			var texture: Texture2D = ResourceLoader.load(asset, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
			var decoded: Image = texture.get_image() if texture != null else null
			if decoded == null or (decoded.is_compressed() and decoded.decompress() != OK): return _fail("Undecodable imported city navigation")
			decoded.convert(Image.FORMAT_RGBA8)
			if decoded.get_size() != image.get_size() or decoded.get_data().slice(0, 3072 * 2048 * 4) != image.get_data(): return _fail("Imported city walk differs from actual PNG")
			_masks[String(id)] = image
	var objects: Variant = record.get("objects")
	if not objects is Array or objects.is_empty(): return _fail("No independent city props")
	var object_ids: Dictionary = {}
	var region_solids: Array[PackedVector2Array] = []
	for object: Variant in objects:
		if not object is Dictionary: return _fail("Malformed city prop")
		var oid: String = String(object.get("id", ""))
		var texture_path: String = String(object.get("texture", ""))
		var source_path: String = String(object.get("source", ""))
		var runtime_path_allowed: bool = texture_path.begins_with(ROOT + String(id) + "/") or texture_path.begins_with(ROOT + "source/")
		if oid.is_empty() or object_ids.has(oid) or not runtime_path_allowed or not catalog.has(texture_path) or not catalog.has(source_path) or String(object.get("source_sha256", "")).to_lower() != String(catalog[source_path]).to_lower(): return _fail("Unbound/duplicate city prop " + oid)
		object_ids[oid] = true
		var source: Image = Image.load_from_file(source_path)
		if source == null or Vector2(source.get_size()) != _vec(object.get("source_size_px")) or not ResourceLoader.exists(texture_path): return _fail("Invalid real prop source dimensions/import " + oid)
		var provenance_error: String = _reuse_error(object, catalog)
		if not provenance_error.is_empty(): return _fail(provenance_error)
		var foot: Vector2 = _vec(object.get("world_foot_px"))
		var render: Vector2 = _vec(object.get("render_size_px"))
		var uv: Vector2 = _vec(object.get("foot_uv"))
		if not _in_domain(foot) or not render.is_finite() or render.x <= 0 or render.y <= 0 or not uv.is_finite() or uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1 or not _num(object.get("depth_foot_y"), foot.y): return _fail("Invalid prop foot/render/depth " + oid)
		var polys: Variant = object.get("solid_polygons_px")
		var size: Vector2 = _vec(object.get("collision_size_px"))
		var center: Vector2 = _vec(object.get("physical_center_px"))
		if not polys is Array or not size.is_finite() or not center.is_finite() or size.x < 0 or size.y < 0 or (size.x == 0) != (size.y == 0) or typeof(object.get("blocking")) != TYPE_BOOL: return _fail("Invalid prop physical declaration " + oid)
		var has_rect: bool = size.x > 0
		if (has_rect and not polys.is_empty()) or bool(object.blocking) != (has_rect or not polys.is_empty()): return _fail("Double/missing city solid " + oid)
		var role_error: String = _object_role_error(id, object)
		if not role_error.is_empty(): return _fail(role_error)
		for raw_polygon: Variant in polys:
			var polygon: PackedVector2Array = _polygon(raw_polygon)
			if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return _fail("Malformed measured city solid " + oid)
			for point: Vector2 in polygon:
				if not _in_domain(point): return _fail("City solid outside canvas " + oid)
			region_solids.append(polygon)
		if has_rect:
			var rect := Rect2(center - size * .5, size)
			if not _in_domain(rect.position) or not _in_domain(rect.end): return _fail("City rectangle outside canvas " + oid)
			region_solids.append(_rect_polygon(rect))
	_solids[String(id)] = region_solids
	var original: SceneScript = legacy_scene(id)
	if original == null: return _fail("Immutable legacy city evidence missing")
	var slots: Variant = record.get("gameplay_slots")
	if not slots is Dictionary: return _fail("Missing full gameplay source slots")
	for kind: String in ["npcs", "interactions", "portals"]:
		var authored: Variant = slots.get(kind)
		var originals: Array = original.npcs if kind == "npcs" else original.map_layout.get(kind)
		if not authored is Array or authored.size() != originals.size(): return _fail("Incomplete original city " + kind)
		var required: Dictionary = {}
		for entry: Dictionary in originals: required[String(entry.get("npc_id" if kind == "npcs" else "id", ""))] = true
		var seen: Dictionary = {}
		for slot: Variant in authored:
			if not slot is Dictionary: return _fail("Malformed gameplay slot")
			var sid: String = String(slot.get("source_id", ""))
			if not required.has(sid) or seen.has(sid): return _fail("Unknown/duplicate original gameplay identity " + sid)
			seen[sid] = true
			var stand: Vector2 = _vec(slot.get("stand_px" if kind == "interactions" else "foot_px"))
			if not safe_body(id, stand): return _fail("Unsafe full ordinary-body gameplay stand " + sid)
			if kind == "interactions" and not object_ids.has(String(slot.get("object_id", ""))): return _fail("Interaction has no actual visible entity " + sid)
			if kind != "npcs":
				var approach: PackedVector2Array = _polygon(slot.get("interaction_polygon_px"))
				if approach.size() < 3 or Geometry2D.triangulate_polygon(approach).is_empty() or not Geometry2D.is_point_in_polygon(stand, approach): return _fail("Unbound/invalid native interaction approach " + sid)
				for point: Vector2 in approach:
					if not _in_domain(point): return _fail("Interaction polygon outside city " + sid)
			if kind == "portals" and not safe_body(id, _vec(slot.get("arrival_foot_px"))): return _fail("Unsafe portal arrival " + sid)
			if kind == "npcs" and slot.has("patrol_path_px"):
				if not slot.patrol_path_px is Array: return _fail("Malformed native patrol path " + sid)
				for point: Variant in slot.patrol_path_px:
					if not safe_body(id, _vec(point)): return _fail("Unsafe authored patrol point " + sid)
	if not safe_body(id, _vec(record.get("entry_foot_px"))) or not safe_body(id, _vec(record.get("return_foot_px"))): return _fail("Unsafe city default/return")
	_records[String(id)] = record
	return true

static func safe_body(id: StringName, point_px: Vector2) -> bool:
	if not _masks.has(String(id)) or not point_px.is_finite(): return false
	var image: Image = _masks[String(id)]
	var rect := Rect2(point_px - BODY_SIZE * .5, BODY_SIZE)
	if not _in_domain(rect.position) or not _in_domain(rect.end): return false
	# Native round_world_pixel sampling includes both rounded rectangle ends.
	# A finite geometric endpoint just below canvas may round beyond last pixel.
	if roundi(rect.position.x) < 0 or roundi(rect.position.y) < 0 or roundi(rect.end.x) >= image.get_width() or roundi(rect.end.y) >= image.get_height(): return false
	for y in range(roundi(rect.position.y), roundi(rect.end.y) + 1):
		for x in range(roundi(rect.position.x), roundi(rect.end.x) + 1):
			var color: Color = image.get_pixel(x, y)
			if color.a < .5 or color.r < .5: return false
	for solid: PackedVector2Array in _solids.get(String(id), []):
		if not Geometry2D.intersect_polygons(_rect_polygon(rect), solid).is_empty(): return false
	return true

static func gameplay_identity(id: StringName) -> Dictionary:
	var source: SceneScript = legacy_scene(id)
	if source == null: return {}
	return {"npcs": source.npcs.duplicate(true), "interactions": source.map_layout.interactions.duplicate(true), "portals": source.map_layout.portals.duplicate(true), "on_enter_dialog": source.on_enter_dialog, "on_enter_require_flag": source.on_enter_require_flag, "on_enter_once_flag": source.on_enter_once_flag, "bgm_path": source.bgm_path}

static func materialize(id: StringName) -> SceneScript:
	if not prepare(id): return null
	var original: SceneScript = legacy_scene(id)
	var scene: SceneScript = _independent_copy(original) as SceneScript
	if scene == null or scene.map_layout == null or is_same(scene.map_layout, original.map_layout): return null
	for name: String in LAYOUT_ARRAYS:
		var source_array: Variant = original.map_layout.get(name)
		var target_array: Variant = scene.map_layout.get(name)
		if not source_array is Array or not target_array is Array or is_same(source_array, target_array): _fail("Shared typed layout Array " + name); return null
		target_array.clear()
		if not scene.map_layout.get(name).is_empty(): _fail("Typed layout Array clear failed " + name); return null
	var record: Dictionary = _records[String(id)]
	# Old baked geometry and water/mist positions cannot survive replacement.
	# They have no actions; any future authored legacy semantic geometry fails.
	for name: String in ["scene_objects", "collision_rects", "animated_props", "exits", "trigger_zones"]:
		var spatial: Array = scene.get(name)
		for entry: Dictionary in spatial:
			if entry.has("action") or entry.has("interaction_action") or entry.has("target_scene"): _fail("Unmapped legacy semantic geometry " + name); return null
		spatial.clear()
	scene.background_path = String(record.ground_path)
	scene.streamed_background = null
	scene.player_visual_scale = .91
	scene.actor_positions_are_feet = true
	scene.player_spawn = _vec(record.entry_foot_px) / SIZE
	scene.map_layout.schema_version = VERSION
	scene.map_layout.design_size = Vector2i(SIZE)
	scene.map_layout.display_at_native_size = true
	scene.map_layout.walkable_mask_path = String(record.walk_path)
	# All non-spatial scene fields, dialogue, NPC identity/actions and progression
	# remain original. No dev HUD/input/event/action override enters production.
	for npc: Dictionary in scene.npcs:
		var slot: Dictionary = _slot(record.gameplay_slots.npcs, String(npc.npc_id))
		npc.pos = _vec(slot.foot_px) / SIZE
		if slot.has("patrol_path_px"):
			var path := PackedVector2Array()
			for point: Variant in slot.patrol_path_px: path.append(_vec(point) / SIZE)
			npc.patrol_path = path
	for source: Dictionary in original.map_layout.interactions:
		var slot: Dictionary = _slot(record.gameplay_slots.interactions, String(source.id))
		var entry: Dictionary = source.duplicate(true)
		entry.pos = _vec(slot.stand_px) / SIZE
		entry.visual_object_id = String(slot.object_id)
		entry.city_v3_interaction_polygon_px = _polygon(slot.interaction_polygon_px)
		entry.visual_baked = true # Actual independent authored sprite supplies it.
		entry.clickable = true
		scene.map_layout.interactions.append(entry)
	for source: Dictionary in original.map_layout.portals:
		var slot: Dictionary = _slot(record.gameplay_slots.portals, String(source.id))
		var entry: Dictionary = source.duplicate(true)
		entry.pos = _vec(slot.foot_px) / SIZE
		entry.arrival_foot_px = _vec(slot.arrival_foot_px)
		entry.interaction_polygon_px = _polygon(slot.interaction_polygon_px)
		entry.passage_path_px = slot.get("passage_path_px", []).duplicate(true)
		scene.map_layout.portals.append(entry)
	for authored: Dictionary in record.objects:
		var entry: Dictionary = authored.duplicate(true)
		var foot: Vector2 = _vec(authored.world_foot_px)
		var render: Vector2 = _vec(authored.render_size_px)
		entry.pos = (foot + (Vector2(.5, .5) - _vec(authored.foot_uv)) * render) / SIZE
		entry.render_size_px = render
		entry.centered = true
		entry.sort_by_feet = authored.get("role", "") != "ground_overlay"
		if not entry.sort_by_feet: entry.z_index = -2; entry.ghost_occlusion = false
		entry.depth_sort_foot_y = foot.y / SIZE.y
		entry.city_v3_solid_polygons_px = authored.solid_polygons_px.duplicate(true)
		entry.erase("solid_polygons_px") # Scoped ordinary Field creates physics.
		scene.map_layout.visual_objects.append(entry)
	scene.set_meta("luoyang_layered_revision", VERSION)
	scene.set_meta("city_manifest_sha", MANIFEST_SHAS[String(id)])
	return scene if semantic_fidelity(scene) else null

static func semantic_fidelity(scene: SceneScript) -> bool:
	var original: SceneScript = legacy_scene(scene.scene_id) if scene != null else null
	if original == null or scene.map_layout == null: return _fail("Cannot compare original city gameplay")
	var spatial_fields := ["map_layout", "background_path", "streamed_background", "player_spawn", "player_visual_scale", "actor_positions_are_feet", "scene_objects", "collision_rects", "animated_props", "exits", "trigger_zones", "npcs", "resource_path", "resource_name", "resource_local_to_scene", "metadata/luoyang_layered_revision", "metadata/city_manifest_sha"]
	for property: Dictionary in original.get_property_list():
		var name: String = String(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name == "script" or name in spatial_fields: continue
		if not _equal_value(original.get(name), scene.get(name)): return _fail("Changed original scene gameplay field " + name)
	for kind: String in ["npcs", "interactions", "portals"]:
		var before: Array = original.npcs if kind == "npcs" else original.map_layout.get(kind)
		var after: Array = scene.npcs if kind == "npcs" else scene.map_layout.get(kind)
		if before.size() != after.size(): return _fail("Changed original gameplay count " + kind)
		var allowed := ["pos", "patrol_path"] if kind == "npcs" else (["pos", "visual_object_id", "city_v3_interaction_polygon_px", "visual_baked", "clickable"] if kind == "interactions" else ["pos", "arrival_foot_px", "interaction_polygon_px", "passage_path_px"])
		for i in before.size():
			var expected: Dictionary = before[i].duplicate(true)
			var actual: Dictionary = after[i].duplicate(true)
			for key: String in allowed: expected.erase(key); actual.erase(key)
			if not _equal_value(expected, actual): return _fail("Changed original action/gate/identity " + kind + "/" + str(i))
	return true

static func runtime_fidelity(scene: SceneScript) -> bool:
	# Serialized candidate/formal layouts must bind the current manifest too;
	# semantic equality alone cannot admit changed prop positions or collisions.
	var expected: SceneScript = materialize(scene.scene_id) if scene != null else null
	if expected == null or not semantic_fidelity(scene): return false
	for name: String in ["background_path", "streamed_background", "player_spawn", "player_visual_scale", "actor_positions_are_feet", "npcs", "animated_props", "scene_objects", "collision_rects", "exits", "trigger_zones"]:
		if not _equal_value(expected.get(name), scene.get(name)): return _fail("Serialized city does not bind native spatial field " + name)
	for property: Dictionary in expected.map_layout.get_property_list():
		var name: String = String(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name in ["script", "resource_path", "resource_name", "resource_local_to_scene"]: continue
		if not _equal_value(expected.map_layout.get(name), scene.map_layout.get(name)): return _fail("Serialized city does not bind native layout field " + name)
	return true

static func _equal_value(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Resource: return b is Resource and a.resource_path == b.resource_path and a.get_script() == b.get_script()
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _equal_value(a[i], b[i]): return false
		return true
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal_value(a[key], b[key]): return false
		return true
	return a == b

static func versions_supported(data: Dictionary, target_versions: Dictionary) -> bool:
	var versions: Variant = data.get("local_layout_versions", {})
	if not versions is Dictionary: return _fail("Malformed local layout versions")
	for id: Variant in versions:
		# Godot JSON decodes numerical values as floats. Accept exactly 1/3,
		# never int-truncate 1.5/NaN/strings into a supported coordinate version.
		if not id is String or not owns_id(StringName(id)) or not (_num(versions[id], 1) or _num(versions[id], VERSION)): return _fail("Unknown local city coordinate version")
		if int(versions[id]) == VERSION and int(target_versions.get(id, 1)) != VERSION: return _fail("City v3 downgrade unsupported; restore the approved city layout first")
	return true

static func prepare_navigation(data: Dictionary, fallback: StringName, target_versions: Dictionary) -> Dictionary:
	# Pure local resolution. Caller commits this exact result after SaveManager
	# completes its unrelated state application; no Router/global state here.
	_errors.clear()
	if not versions_supported(data, target_versions): return {}
	var result: Dictionary = data.duplicate(true)
	var versions: Dictionary = data.get("local_layout_versions", {}).duplicate(true)
	var traces: Array[Dictionary] = []
	for id: String in target_versions:
		if not owns_id(StringName(id)) or not (_num(target_versions[id], 1) or _num(target_versions[id], VERSION)): _fail("Invalid target local layout version"); return {}
		if int(target_versions[id]) == VERSION and not prepare(StringName(id)): return {}
	var current := StringName(data.get("current_field", fallback))
	result.current_field = String(current)
	if owns_id(current) and int(target_versions.get(String(current), 1)) == VERSION:
		var current_version: int = int(versions.get(String(current), 1))
		var legacy: SceneScript = legacy_scene(current) if current_version == 1 else null
		var default_spawn: Vector2 = legacy.player_spawn if legacy != null else _vec(_records[String(current)].entry_foot_px) / SIZE
		var migrated: Dictionary = migrate_spawn_report(current, _vec(data.get("current_field_spawn", default_spawn)), current_version)
		if migrated.is_empty(): return {}
		result.current_field_spawn = [migrated.spawn.x, migrated.spawn.y]
		traces.append(migrated)
	var returns: Variant = data.get("portal_return_spawns", {})
	if not returns is Dictionary: _fail("Malformed paired local return coordinates"); return {}
	var repaired: Dictionary = returns.duplicate(true)
	for key: Variant in returns:
		var parts: PackedStringArray = String(key).split("->")
		if parts.size() != 2: continue
		var target := StringName(parts[1])
		if not owns_id(target) or int(target_versions.get(String(target), 1)) != VERSION: continue
		var migrated: Dictionary = migrate_spawn_report(target, _vec(returns[key]), int(versions.get(String(target), 1)), StringName(parts[0]))
		if migrated.is_empty(): return {}
		repaired[key] = [migrated.spawn.x, migrated.spawn.y]
		traces.append(migrated)
	result.portal_return_spawns = repaired
	for id: String in target_versions: versions[id] = int(target_versions[id])
	result.local_layout_versions = versions
	result.local_migration_trace = traces
	return result

static func repair_spawn(id: StringName, normalized: Vector2) -> Variant:
	if not normalized.is_finite() or normalized.x < 0 or normalized.y < 0 or normalized.x > 1 or normalized.y > 1: return null
	var point: Vector2 = normalized * SIZE
	if safe_body(id, point): return normalized
	# Strict bounded local repair only; new v3 invalid points never teleport to
	# another district, a global white pixel, or a convenient portal.
	for radius in range(4, 197, 4):
		for index in 32:
			var probe: Vector2 = point + Vector2.from_angle(TAU * index / 32.0) * radius
			if safe_body(id, probe): return probe / SIZE
	return null

static func migrate_spawn_report(id: StringName, normalized: Vector2, source_version: int, source_scene: StringName = &"") -> Dictionary:
	if source_version not in [1, VERSION] or not normalized.is_finite() or normalized.x < 0 or normalized.y < 0 or normalized.x > 1 or normalized.y > 1: _fail("Invalid city source coordinates/version"); return {}
	if not _records.has(String(id)) and not prepare(id): return {}
	if source_version == VERSION:
		var repaired: Variant = repair_spawn(id, normalized)
		return {"scene_id": String(id), "spawn": repaired, "source_version": VERSION, "target_version": VERSION, "reason": "same_version_local_clearance"} if repaired is Vector2 else {}
	var original: SceneScript = legacy_scene(id)
	if original == null: _fail("Missing legacy city origin"); return {}
	var record: Dictionary = _records[String(id)]
	var anchors: Array[Dictionary] = []
	for portal: Dictionary in original.map_layout.portals:
		var slot: Dictionary = _slot(record.gameplay_slots.portals, String(portal.id))
		anchors.append({"id": String(portal.id), "old": portal.pos, "new": _vec(slot.arrival_foot_px) / SIZE, "target": String(portal.get("target_scene", ""))})
	if anchors.is_empty(): _fail("No same-district semantic city anchors"); return {}
	var closest: Dictionary = anchors[0]
	var nearest := INF
	for anchor: Dictionary in anchors:
		var distance: float = ((normalized - anchor.old) * Vector2(original.map_layout.design_size)).length_squared()
		if distance < nearest: closest = anchor; nearest = distance
	# Exact authored target_pos/default arrivals are mapped by actual incoming
	# route, not the old art's potentially still-white roof coordinate.
	if source_scene != &"":
		if String(source_scene) in ["world_map_jianghu", "world_map_jianghu_staging", "world_map_jianghu_v14", "world_map_jianghu_v15"]:
			var entry: Vector2 = _vec(record.entry_foot_px) / SIZE
			return {"scene_id": String(id), "spawn": entry, "source_version": source_version, "target_version": VERSION, "reason": "authored_world_city_entry"} if safe_body(id, entry * SIZE) else {}
		for anchor: Dictionary in anchors:
			if anchor.target == String(source_scene): closest = anchor; nearest = 0; break
	var mapped: Vector2 = closest.new
	var reason := "same_district_portal_anchor"
	if nearest > 200.0 * 200.0:
		var semantic_anchors: Array[Dictionary] = anchors.duplicate(true)
		for npc: Dictionary in original.npcs:
			var slot: Dictionary = _slot(record.gameplay_slots.npcs, String(npc.npc_id))
			semantic_anchors.append({"old": npc.pos, "new": _vec(slot.foot_px) / SIZE})
		for interaction: Dictionary in original.map_layout.interactions:
			var slot: Dictionary = _slot(record.gameplay_slots.interactions, String(interaction.id))
			semantic_anchors.append({"old": interaction.pos, "new": _vec(slot.stand_px) / SIZE})
		var displacement := Vector2.ZERO
		var total := 0.0
		for anchor: Dictionary in semantic_anchors:
			var weight: float = 1.0 / maxf(.000001, normalized.distance_squared_to(anchor.old))
			displacement += (anchor.new - anchor.old) * weight
			total += weight
		mapped = normalized + displacement / total
		reason = "same_district_semantic_interpolation"
	var repaired: Variant = repair_spawn(id, mapped)
	if not repaired is Vector2 and reason == "same_district_semantic_interpolation":
		# Preserve a free point's local road relation before considering a portal:
		# only actual authored roads within the same bounded 196px neighbourhood.
		var road_point: Variant = _local_route_projection(id, mapped * SIZE)
		if road_point is Vector2:
			repaired = road_point / SIZE
			reason = "same_district_local_authored_road_projection"
	if not repaired is Vector2:
		# Explicit old-only semantic fallback, preserving same-region relation.
		# Never relax native mask/body clearance or select arbitrary free ground.
		repaired = closest.new if safe_body(id, closest.new * SIZE) else null
		reason = "same_district_author_anchor_fallback"
	if not repaired is Vector2: _fail("No safe same-district migration anchor"); return {}
	return {"scene_id": String(id), "spawn": repaired, "source_version": source_version, "target_version": VERSION, "reason": reason, "anchor_id": closest.id}

static func _local_route_projection(id: StringName, point: Vector2) -> Variant:
	var best: Variant = null
	var nearest := 196.0 * 196.0
	for route: Variant in _records[String(id)].get("routes", []):
		if not route is Dictionary or not route.get("points_px") is Array: continue
		var points: Array = route.points_px
		for i in range(points.size() - 1):
			var a: Vector2 = _vec(points[i])
			var b: Vector2 = _vec(points[i + 1])
			if not a.is_finite() or not b.is_finite(): continue
			var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(point, a, b)
			var distance: float = point.distance_squared_to(candidate)
			if distance < nearest and safe_body(id, candidate): best = candidate; nearest = distance
	return best

static func _slot(slots: Array, id: String) -> Dictionary:
	for slot: Dictionary in slots:
		if String(slot.source_id) == id: return slot
	return {}

static func _capture_graph_error(record: Dictionary, catalog: Dictionary, id: StringName) -> String:
	var prefix: String = ROOT + String(id) + "/"
	var required := {
		"source_script": "res://scripts/dev/luoyang_modular_v3_source.gd",
		"builder_script": "res://scripts/dev/build_luoyang_modular_v3.gd",
		"surface_script": DETAIL_SURFACE,
		"material_adapter_script": DETAIL_ADAPTER,
		"camera_contract": prefix + "capture_camera.json",
		"height_rf": prefix + "terrain_height.rf",
		"native_support_mesh": prefix + "support_plane.res",
		"paving_mesh": prefix + "paving_mesh.res",
		"paving_material": prefix + "paving_material.res",
	}
	var graph: Variant = record.get("capture_graph")
	var sources: Variant = record.get("source_graph")
	if not graph is Dictionary or not sources is Dictionary: return "Missing native city executed graph"
	var builder: Variant = graph.get("builder_script")
	if not builder is Dictionary or builder.get("path") != DETAIL_BUILDER: return "Unsupported exact city capture builder"
	var roof_revision: bool = builder.path != MATERIAL_BUILDER
	required.builder_script = builder.path
	for role: String in required:
		var node: Variant = graph.get(role)
		var path: String = required[role]
		if not node is Dictionary or node.get("path") != path or not catalog.has(path) or not _hash(node.get("sha256")) or String(node.sha256).to_lower() != String(catalog[path]).to_lower(): return "Unbound actual native city role " + role
		if role in ["source_script", "builder_script", "surface_script", "material_adapter_script"] and String(sources.get(path, "")).to_lower() != String(catalog[path]).to_lower(): return "Executed city script absent from actual source graph"
		if CAPTURE_SCRIPT_SHAS.has(path) and not _capture_script_bound(path, sources, catalog): return "City executed script differs from frozen revision " + role
	# This NEW executor does not emit the old parent_surface_script capture role.
	# Retain every frozen ancestor as an actual source/catalog dependency instead;
	# never mislabel a historical authoring script as the current material instance.
	for path: String in ["res://scripts/dev/luoyang_modular_v3_surface.gd", "res://scripts/dev/build_luoyang_modular_v3_street_detail_capture_proposal.gd", "res://scripts/dev/build_luoyang_modular_v3_street_detail_proposal.gd", "res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"]:
		if not _capture_script_bound(path, sources, catalog): return "Frozen wall/street ancestor absent or changed: " + path
	if roof_revision:
		for path: String in [MATERIAL_BUILDER, ROOF_TRIAL, ROOF_BUILDER, GREY_TILE_BUILDER]:
			if not _capture_script_bound(path, sources, catalog): return "Roof base/trial source is not the frozen actual capture source"
		if builder.path == GREY_TILE_BUILDER and not _capture_script_bound(ROOF_BUILDER, sources, catalog): return "Grey tile capture lost frozen raised-roof parent source"
	var roof_error: String = DETAIL_CHECKER.validate(record, catalog, id)
	if not roof_error.is_empty(): return roof_error
	var visual: Variant = record.get("capture_camera")
	var authority: Variant = record.get("authority_camera")
	if not _native_camera_matches(visual, Vector2(6144, 4096), 2) or not _native_camera_matches(authority, SIZE, 1): return "City visual/authority camera canvas or transform mismatch"
	if not _equal_value(visual, JSON.parse_string(FileAccess.get_file_as_string(prefix + "capture_camera.json"))) or not _equal_value(authority, JSON.parse_string(FileAccess.get_file_as_string(prefix + "authority_camera.json"))) or not catalog.has(prefix + "authority_camera.json"): return "Actual retained city camera metadata differs"
	for name: String in ["ground_on_raw.png", "ground_on_raw_repeat.png", "ground_off_raw.png", "ground_off_raw_repeat.png"]:
		if not catalog.has(prefix + name) or not _png_size(prefix + name, Vector2i(6144, 4096)): return "Native city raw capture missing/wrong exact canvas"
	for kind: String in ["on", "off"]:
		if catalog[prefix + "ground_" + kind + "_raw.png"] != catalog[prefix + "ground_" + kind + "_raw_repeat.png"]: return "Native city raw capture not byte-exact repeat"
	var height: Variant = record.get("height_grid")
	var file: FileAccess = FileAccess.open(prefix + "terrain_height.rf", FileAccess.READ)
	if not height is Dictionary or _vec(height.get("size")) != Vector2(385, 257) or not _num(height.get("step_px"), 8) or file == null or file.get_length() != 385 * 257 * 4: return "City RF lattice not current native source"
	return ""

static func _capture_script_bound(path: String, sources: Dictionary, catalog: Dictionary) -> bool:
	var expected: String = CAPTURE_SCRIPT_SHAS[path]
	return catalog.get(path) == expected and sources.get(path) == expected and FileAccess.get_sha256(path) == expected

static func _roof_objects_error(record: Dictionary, catalog: Dictionary, prefix: String, executed_builder: String) -> String:
	var roof_revision: bool = executed_builder != MATERIAL_BUILDER
	var objects: Variant = record.get("objects")
	if not objects is Array: return "City roof validation requires actual object list"
	var checked: Dictionary = {}
	for object: Variant in objects:
		if not object is Dictionary: return "Malformed actual city roof object"
		var kind: Variant = object.get("prototype", "")
		for wall_kind: String in ["wall_horizontal", "wall_vertical"]:
			if object.get("texture") == prefix + "entities/native_" + wall_kind + ".png" and kind != wall_kind: return "Native city wall cannot hide its prototype identity"
		if kind not in ["wall_horizontal", "wall_vertical"]: continue
		var stem: String = prefix + "entities/native_" + String(kind)
		var metadata_path: String = stem + ".json"
		if object.get("metadata_path") != metadata_path or not catalog.has(metadata_path): return "City wall metadata is not its exact regional prototype"
		var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if not metadata is Dictionary or metadata.get("kind") != kind: return "Malformed retained native wall metadata"
		if not roof_revision:
			if metadata.has("roof_geometry_revision"): return "Raised roof cannot claim the old material-only builder"
			continue
		if object.get("original_licensed_source") != executed_builder or object.get("texture") != stem + ".png" or object.get("source") != stem + ".png" or _vec(object.get("source_size_px")) != _vec(metadata.get("source_size_px")) or _vec(object.get("render_size_px")) != _vec(metadata.get("render_size_px")) or _vec(object.get("foot_uv")) != _vec(metadata.get("foot_uv")): return "Raised roof instance lost actual PNG/canvas/foot binding"
		if not checked.has(metadata_path):
			var error: String = _roof_prototype_error(metadata, catalog, stem, executed_builder)
			if not error.is_empty(): return error
			checked[metadata_path] = true
	return ""

static func _roof_prototype_error(metadata: Dictionary, catalog: Dictionary, stem: String, executed_builder: String) -> String:
	for pair: Array in [["texture", ".png"], ["metadata_path", ".json"], ["native_mesh_path", ".res"], ["sourcebody_raw", "_raw.png"], ["sourcebody_raw_repeat", "_raw_repeat.png"]]:
		var path: String = stem + String(pair[1])
		if metadata.get(pair[0]) != path or not catalog.has(path) or FileAccess.get_sha256(path) != catalog[path]: return "Roof native body/render evidence not current catalog bytes"
	var size: Vector2 = _vec(metadata.get("source_size_px"))
	var crop: Variant = metadata.get("crop_rect_px")
	var camera: Variant = metadata.get("raw_camera")
	if not size.is_finite() or size != _vec(metadata.get("render_size_px")) or not _png_size(stem + ".png", Vector2i(size)) or not crop is Array or crop.size() != 4 or not _num(crop[2], size.x) or not _num(crop[3], size.y): return "Roof actual cropped render canvas mismatch"
	if not typeof(crop[0]) in [TYPE_INT, TYPE_FLOAT] or not typeof(crop[1]) in [TYPE_INT, TYPE_FLOAT] or not _num(crop[0], floor(float(crop[0]))) or not _num(crop[1], floor(float(crop[1]))) or float(crop[0]) < 0 or float(crop[1]) < 0 or float(crop[0]) + size.x > 768 or float(crop[1]) + size.y > 768 or metadata.get("alpha_resampling_algorithm") != "RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1": return "Roof exact native crop/resampling identity differs"
	var basis: Variant = metadata.get("draw_basis_columns")
	if not basis is Array or basis.size() != 3 or _roof_v3(basis[0]) != Vector3.RIGHT or _roof_v3(basis[1]) != Vector3.UP or _roof_v3(basis[2]) != Vector3.BACK or not _num(metadata.get("scale"), 1) or not _num(metadata.get("source_min_vertex_ground_delta_m"), 0): return "Roof body/support basis differs"
	if not camera is Dictionary or _vec(camera.get("raw_canvas_px")) != Vector2(1536, 1536) or _vec(camera.get("logical_canvas_px")) != Vector2(768, 768) or not _num(camera.get("raw_to_logical_factor"), 2) or not _num(camera.get("msaa"), 0) or not _num(camera.get("projection"), Camera3D.PROJECTION_ORTHOGONAL) or not _num(camera.get("orthographic_size_m"), 12): return "Roof raw capture camera is not actual native prototype camera"
	if not _png_size(stem + "_raw.png", Vector2i(1536, 1536)) or not _png_size(stem + "_raw_repeat.png", Vector2i(1536, 1536)) or catalog[stem + "_raw.png"] != catalog[stem + "_raw_repeat.png"] or metadata.get("repeat_byte_exact") != true or metadata.get("sourcebody_and_ground_caster_same_mesh_material_basis_support") != true: return "Roof actual native repeat/body/caster mismatch"
	var revision: Variant = metadata.get("roof_geometry_revision")
	if not revision is Dictionary or revision.get("algorithm_identity") != "ROOT097_CLOCKWISE_RAISED_TILE_CAP_V1" or revision.get("new_geometry_not_material_only") != true or revision.get("production_approved") != false: return "Unknown raised roof geometry revision"
	for pair: Array in [["base_builder", MATERIAL_BUILDER], ["trial_builder", ROOF_TRIAL]]:
		var node: Variant = revision.get(pair[0])
		if not node is Dictionary or node.get("path") != pair[1] or node.get("sha256") != CAPTURE_SCRIPT_SHAS[pair[1]]: return "Roof revision base/trial binding differs"
	if not _num(revision.get("original_surface_count"), 53) or not _num(revision.get("actual_surface_count"), 54) or not _num(revision.get("new_surface_count"), 1) or revision.get("prepared_and_captured_all_arrays_byte_exact") != true or revision.get("prepared_and_captured_actual_bounds_byte_exact") != true: return "Roof captured/prepared geometry identity missing"
	var mesh: ArrayMesh = ResourceLoader.load(stem + ".res", "ArrayMesh", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if mesh == null or mesh.get_surface_count() != 54: return "Roof actual stored native mesh unavailable/wrong surface count"
	var render_error: String = _roof_render_error(metadata.get("masonry_material_evidence"), mesh, catalog)
	if not render_error.is_empty(): return render_error
	var original_bounds: Dictionary = _roof_mesh_bounds(mesh, 53)
	var actual_bounds: Dictionary = _roof_mesh_bounds(mesh, 54)
	if original_bounds.is_empty() or actual_bounds.is_empty(): return "Roof native mesh contains invalid actual vertices/indices"
	if original_bounds.support != actual_bounds.support or original_bounds.support_count != actual_bounds.support_count or original_bounds.minimum.y != actual_bounds.minimum.y: return "Raised roof changed original actual ground support"
	for key: String in ["pre_capture_original_comparison", "captured_original_comparison"]:
		var comparison_error: String = _roof_comparison_error(revision.get(key), mesh, original_bounds, actual_bounds)
		if not comparison_error.is_empty(): return comparison_error
	var bounds: Variant = metadata.get("used_bounds_m")
	if not bounds is Dictionary or _roof_v3(bounds.get("minimum")) != actual_bounds.minimum or _roof_v3(bounds.get("maximum")) != actual_bounds.maximum or _roof_v3(metadata.get("support_m")) != actual_bounds.support or not _num(metadata.get("actual_used_vertices"), actual_bounds.actual_used_vertices): return "Roof retained render/support bounds differ from actual mesh"
	var cap_error: String = _roof_cap_error(revision.get("actual_new_surface"), mesh)
	if not cap_error.is_empty(): return cap_error
	if executed_builder == GREY_TILE_BUILDER: return _grey_tile_error(metadata, mesh, stem)
	return "Grey tile material cannot claim the original raised-roof builder" if metadata.has("roof_cap_material_revision") else ""

static func _grey_tile_error(metadata: Dictionary, mesh: ArrayMesh, stem: String) -> String:
	var revision: Variant = metadata.get("roof_cap_material_revision")
	var identity := "PROJECT_NATIVE_WEATHERED_GREY_CLAY_TILE_CAP_MATERIAL_V1"
	if not revision is Dictionary or revision.get("algorithm_identity") != identity or revision.get("scope") != "MATERIAL_ONLY_RELATIVE_TO_FROZEN_ROOT100_RAISED_CAP_GEOMETRY" or not _num(revision.get("surface_index"), 53) or revision.get("production_approved") != false: return "Grey tile material-only revision identity differs"
	var changed: Variant = revision.get("changed_surfaces")
	if not changed is Array or changed.size() != 1 or not _num(changed[0], 53): return "Grey tile material changed more than the final raised-cap surface"
	for pair: Array in [["parent_builder", ROOF_BUILDER], ["executed_builder", GREY_TILE_BUILDER]]:
		var node: Variant = revision.get(pair[0])
		if not node is Dictionary or node.get("path") != pair[1] or node.get("sha256") != CAPTURE_SCRIPT_SHAS[pair[1]]: return "Grey tile frozen parent/executor evidence differs"
	for key: String in ["all_original_wall_materials_unchanged", "layout_collision_ground_navigation_unchanged", "actual_sampler_objects_equal_registered_textures"]:
		if revision.get(key) != true: return "Grey tile original wall/support/sampler invariant missing " + key
	for key: String in ["pre_capture_geometry", "actual_capture_geometry"]:
		var geometry: Variant = revision.get(key)
		if not geometry is Dictionary or not _num(geometry.get("surface_count"), 54) or not _num(geometry.get("slots_checked"), 54 * Mesh.ARRAY_MAX): return "Grey tile all-surface geometry comparison incomplete"
		for flag: String in ["passed", "all_surface_arrays_primitive_byte_exact", "actual_bounds_support_byte_exact", "all_original_wall_material_code_parameters_exact"]:
			if geometry.get(flag) != true: return "Grey tile altered frozen geometry/support/original materials " + flag
		var error: String = _roof_cap_error(geometry.get("unchanged_raised_cap_surface"), mesh)
		if not error.is_empty(): return error
	var material: ShaderMaterial = mesh.surface_get_material(53) as ShaderMaterial
	if material == null or material.shader == null: return "Grey tile actual saved cap shader missing"
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(material.shader.code.to_utf8_buffer())
	if revision.get("actual_shader_code_sha256") != context.finish().hex_encode(): return "Grey tile actual saved shader code differs"
	var horizontal: bool = metadata.get("kind") == "wall_horizontal"
	var expected := {"native_grey_tile_cap_identity": 1.0, "horizontal_axis": 1.0 if horizontal else 0.0, "cap_half_span_m": .575 if horizontal else .650, "tile_pitch_m": .15625, "course_pitch_m": .20, "masonry_profile": 1.0 if stem.begins_with(ROOT + "ch4_s1_luoyang_yamen/") else 0.0}
	var parameters: Variant = revision.get("actual_shader_parameters")
	if not parameters is Dictionary: return "Grey tile actual physical parameter evidence missing"
	for key: String in expected:
		if not _num(parameters.get(key), expected[key]) or not _num(material.get_shader_parameter(key), expected[key]): return "Grey tile actual saved physical parameter differs " + key
	if _roof_v3(parameters.get("masonry_tint")) != Vector3(.99, .99, .97) or material.get_shader_parameter("masonry_tint") != Vector3(.99, .99, .97): return "Grey tile actual saved cap tint differs"
	var materials: Variant = metadata.get("masonry_material_evidence")
	if not materials is Array or materials.size() != 54 or not materials[53] is Dictionary or materials[53].get("profile") != identity or materials[53].get("surface_role") != "raised_roof_cap_not_wall_masonry" or materials[53].get("shader_code_sha256") != revision.get("actual_shader_code_sha256"): return "Grey tile final material cannot masquerade as wall masonry"
	return ""

static func _roof_render_error(value: Variant, mesh: ArrayMesh, catalog: Dictionary) -> String:
	if not value is Array or value.size() != mesh.get_surface_count(): return "Roof actual masonry material evidence incomplete"
	var checked: Dictionary = {}
	for index in mesh.get_surface_count():
		var evidence: Variant = value[index]
		var material: ShaderMaterial = mesh.surface_get_material(index) as ShaderMaterial
		if not evidence is Dictionary or material == null or material.shader == null or not _num(evidence.get("surface_index"), index) or evidence.get("actual_sampler_objects_equal_registered_textures") != true: return "Roof actual saved material identity missing"
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256); context.update(material.shader.code.to_utf8_buffer())
		if evidence.get("shader_code_sha256") != context.finish().hex_encode() or not _num(evidence.get("actual_profile_uniform"), float(material.get_shader_parameter("masonry_profile"))) or _roof_v3(evidence.get("actual_tint")) != material.get_shader_parameter("masonry_tint"): return "Roof actual saved masonry shader/profile differs"
		var samplers: Variant = evidence.get("samplers")
		if not samplers is Dictionary: return "Roof actual saved sampler evidence missing"
		for channel: String in ["original_stone", "registered_normal", "registered_arm"]:
			var sampler: Variant = samplers.get(channel)
			var texture: Texture2D = material.get_shader_parameter(channel) as Texture2D
			if not sampler is Dictionary or texture == null: return "Roof actual saved masonry sampler differs"
			var original_path := String(sampler.get("path", ""))
			if not catalog.has(original_path) or sampler.get("sha256") != catalog[original_path] or FileAccess.get_sha256(original_path) != catalog[original_path]: return "Roof actual saved masonry sampler bytes changed"
			# The capture surface constructs ImageTextures from exact decoded
			# originals with generated mipmaps. ResourceSaver embeds these in the
			# mesh; their resource_path is NOT the original PNG/JPG pathname.
			# Validate the stored sampler's actual complete pixels/mips instead.
			var key := original_path + "|" + str(texture.get_instance_id())
			if not checked.has(key):
				var original := Image.load_from_file(original_path)
				var stored := texture.get_image()
				if original == null or stored == null or original.generate_mipmaps() != OK: return "Roof saved sampler original/mipmap decode failed"
				if stored.get_size() != original.get_size() or stored.get_format() != original.get_format() or stored.has_mipmaps() != original.has_mipmaps() or stored.get_mipmap_count() != original.get_mipmap_count() or stored.get_data() != original.get_data(): return "Roof actual saved sampler pixels/mipmaps differ from registered original"
				checked[key] = true
	return ""

static func _roof_comparison_error(value: Variant, mesh: ArrayMesh, old_bounds: Dictionary, actual_bounds: Dictionary) -> String:
	if not value is Dictionary or value.get("passed") != true or value.get("all_original_surface_slots_byte_exact") != true or value.get("support_exact") != true or not _num(value.get("surfaces_checked"), 53): return "Roof original geometry/support comparison incomplete"
	if not _roof_bound_matches(value.get("original_bounds"), old_bounds) or not _roof_bound_matches(value.get("actual_bounds"), actual_bounds): return "Roof original/captured actual bounds evidence differs"
	var surfaces: Variant = value.get("original_surfaces")
	if not surfaces is Array or surfaces.size() != 53: return "Roof original surface evidence incomplete"
	for index in 53:
		var surface: Variant = surfaces[index]
		var arrays: Array = mesh.surface_get_arrays(index)
		if not surface is Dictionary or not _num(surface.get("surface_index"), index) or not _num(surface.get("primitive_type"), mesh.surface_get_primitive_type(index)) or surface.get("primitive_exact") != true or not _num(surface.get("original_slot_count"), arrays.size()) or not _num(surface.get("actual_slot_count"), arrays.size()): return "Roof original surface identity differs"
		var slots: Variant = surface.get("slots")
		if not slots is Array or slots.size() != arrays.size(): return "Roof original array slot evidence incomplete"
		for slot in arrays.size():
			var entry: Variant = slots[slot]
			var actual_sha: String = _roof_variant_sha(arrays[slot])
			if not entry is Dictionary or not _num(entry.get("slot"), slot) or entry.get("byte_exact") != true or entry.get("original_sha256") != actual_sha or entry.get("actual_sha256") != actual_sha or not _num(entry.get("original_variant_type"), typeof(arrays[slot])) or not _num(entry.get("actual_variant_type"), typeof(arrays[slot])): return "Roof altered an original native surface array"
	return ""

static func _roof_cap_error(value: Variant, mesh: ArrayMesh) -> String:
	if not value is Dictionary: return "Missing actual new tile surface evidence"
	var expected := {"surface_index": 53, "primitive_type": Mesh.PRIMITIVE_TRIANGLES, "vertex_count": 192, "normal_count": 192, "index_count": 0, "actual_draw_vertex_count": 192, "triangle_count": 64, "clockwise_up_faces": 64, "degenerate_faces": 0}
	for key: String in expected:
		if not _num(value.get(key), expected[key]): return "Raised tile surface statistics differ " + key
	if mesh.surface_get_primitive_type(53) != Mesh.PRIMITIVE_TRIANGLES: return "Raised roof stored primitive is not triangles"
	var arrays: Array = mesh.surface_get_arrays(53)
	if not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array: return "Raised roof stored vertex/normal arrays missing"
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if vertices.size() != 192 or normals.size() != 192 or (arrays[Mesh.ARRAY_INDEX] != null and (not arrays[Mesh.ARRAY_INDEX] is PackedInt32Array or not arrays[Mesh.ARRAY_INDEX].is_empty())) or value.get("normal_sha256") != _roof_variant_sha(normals): return "Raised roof actual vertex/normal/index geometry differs"
	var min_y: float = INF
	var max_y: float = -INF
	for normal: Vector3 in normals:
		if not normal.is_finite() or normal.y <= 0: return "Raised roof has invalid/downward normal"
		min_y = minf(min_y, normal.y); max_y = maxf(max_y, normal.y)
	# Serialized JSON doubles must recover the exact stored float32 vector values.
	if _roof_v3([0, value.get("actual_normal_y_min"), 0]).y != min_y or _roof_v3([0, value.get("actual_normal_y_max"), 0]).y != max_y: return "Raised roof retained actual normal extrema differ"
	for offset in range(0, 192, 3):
		var cross: Vector3 = (vertices[offset + 1] - vertices[offset]).cross(vertices[offset + 2] - vertices[offset])
		if cross.length_squared() == 0 or cross.y >= 0: return "Raised roof stored triangle is degenerate/not clockwise-up"
	var slots: Variant = value.get("all_actual_surface_array_slots")
	if not slots is Array or slots.size() != arrays.size(): return "Raised roof new array slot evidence incomplete"
	for slot in arrays.size():
		var entry: Variant = slots[slot]
		if not entry is Dictionary or not _num(entry.get("slot"), slot) or not _num(entry.get("variant_type"), typeof(arrays[slot])) or entry.get("sha256") != _roof_variant_sha(arrays[slot]): return "Raised roof actual new native surface differs"
	return ""

static func _roof_mesh_bounds(mesh: ArrayMesh, count: int) -> Dictionary:
	var points := PackedVector3Array()
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for surface in count:
		var arrays: Array = mesh.surface_get_arrays(surface)
		if not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array: return {}
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices = arrays[Mesh.ARRAY_INDEX]
		elif arrays[Mesh.ARRAY_INDEX] != null: return {}
		if indices.is_empty():
			for index in vertices.size(): indices.append(index)
		var used: Dictionary = {}
		for index in indices:
			if index < 0 or index >= vertices.size(): return {}
			if used.has(index): continue
			used[index] = true
			var point: Vector3 = vertices[index]
			if not point.is_finite(): return {}
			points.append(point); minimum = minimum.min(point); maximum = maximum.max(point)
	if points.is_empty(): return {}
	var sum_x: float = 0
	var front: float = -INF
	var support_count: int = 0
	for point: Vector3 in points:
		if point.y <= minimum.y + (maximum.y - minimum.y) * .02:
			sum_x += point.x; front = maxf(front, point.z); support_count += 1
	if support_count == 0: return {}
	return {"minimum": minimum, "maximum": maximum, "support": Vector3(sum_x / support_count, minimum.y, front), "support_count": support_count, "actual_used_vertices": points.size()}

static func _roof_bound_matches(value: Variant, actual: Dictionary) -> bool:
	return value is Dictionary and value.get("valid") == true and _roof_v3(value.get("minimum_m")) == actual.minimum and _roof_v3(value.get("maximum_m")) == actual.maximum and _roof_v3(value.get("support_m")) == actual.support and _num(value.get("support_count"), actual.support_count) and _num(value.get("actual_used_vertices"), actual.actual_used_vertices)

static func _roof_v3(value: Variant) -> Vector3:
	if not value is Array or value.size() != 3: return Vector3(INF, INF, INF)
	for component: Variant in value:
		if not typeof(component) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)): return Vector3(INF, INF, INF)
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

static func _roof_variant_sha(value: Variant) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(value))
	return context.finish().hex_encode()

static func _native_camera_matches(camera: Variant, raw_size: Vector2, factor: float) -> bool:
	if not camera is Dictionary or not _num(camera.get("projection"), Camera3D.PROJECTION_ORTHOGONAL) or _vec(camera.get("raw_canvas_px")) != raw_size or _vec(camera.get("logical_canvas_px")) != SIZE or not _num(camera.get("raw_to_logical_factor"), factor): return false
	if not _num(camera.get("logical_pixels_per_world_m_x"), 64) or not _num(camera.get("logical_pixels_per_world_m_ground_z"), 32) or _vec(camera.get("physical_world_size_m")) != Vector2(48, 64) or not _num(camera.get("camera_elevation_degrees"), 30) or not _num(camera.get("msaa"), 0): return false
	for value: Variant in [camera.get("position_m"), camera.get("basis_columns")]:
		if not value is Array or value.size() != 3: return false
		for component: Variant in value:
			if component is Array:
				if component.size() != 3: return false
				for number: Variant in component:
					if not typeof(number) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(number)): return false
			elif not typeof(component) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)): return false
	return true

static func _png_size(path: String, size: Vector2i) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 24 or file.get_buffer(8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]): return false
	file.big_endian = true
	return file.get_32() == 13 and file.get_buffer(4).get_string_from_ascii() == "IHDR" and file.get_32() == size.x and file.get_32() == size.y

static func _independent_copy(original: Resource) -> Resource:
	var copy: Resource = original.duplicate(true)
	for property: Dictionary in original.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or property.name == "script": continue
		var value: Variant = original.get(property.name)
		if value is Array or value is Dictionary: copy.set(property.name, value.duplicate(true))
	if original is SceneScript and original.map_layout != null: copy.set("map_layout", _independent_copy(original.map_layout))
	return copy

static func _vec(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

static func _polygon(value: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not value is Array: return result
	for point: Variant in value:
		var parsed: Vector2 = _vec(point)
		if not parsed.is_finite(): return PackedVector2Array()
		result.append(parsed)
	return result

static func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])

static func _in_domain(point: Vector2) -> bool:
	return point.is_finite() and point.x >= 0 and point.y >= 0 and point.x < SIZE.x and point.y < SIZE.y

static func _num(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

static func _object_role_error(id: StringName, object: Dictionary) -> String:
	var oid: String = String(object.get("id", ""))
	var role: Variant = object.get("role", "")
	if not role is String or role not in ["", "ground_overlay", "water_decoration"]: return "Unknown city object role " + oid
	if role == "ground_overlay":
		if typeof(object.get("blocking")) != TYPE_BOOL or typeof(object.get("ghost_occlusion")) != TYPE_BOOL or object.get("blocking") != false or object.get("ghost_occlusion") != false or not _num(object.get("z_index"), -2): return "Ground overlay cannot masquerade as solid/ghost actor " + oid
	elif role == "water_decoration":
		# This does not certify absence. Final joint approval additionally requires
		# the QA's bound continuous full actor-domain proof, never an empty search.
		for key: String in ["blocking", "ghost_occlusion", "walk_support", "interaction_required"]:
			if typeof(object.get(key)) != TYPE_BOOL or object[key] != false: return "Invalid nonwalkable water-decoration boolean " + oid
		if id != &"ch4_s2_canal_docks" or oid != "moored_canal_boat" or _vec(object.get("collision_size_px")) != Vector2.ZERO or not object.get("solid_polygons_px") is Array or not object.solid_polygons_px.is_empty(): return "Invalid nonwalkable water-decoration declaration " + oid
	elif object.has("ghost_occlusion") and (typeof(object.ghost_occlusion) != TYPE_BOOL or object.ghost_occlusion != true):
		return "Ordinary high city prop cannot disable precise ghost " + oid
	return ""

static func _reuse_error(object: Dictionary, catalog: Dictionary) -> String:
	if not object.has("original_source"): return ""
	var original: Variant = object.get("original_source")
	var source: Variant = object.get("source")
	var runtime: Variant = object.get("texture")
	var authoring: bool = object.get("nature") in ["generated_independent_architecture", "generated_independent_city_prop"] and original is String and original.begins_with("res://art/maps/luoyang_modular_v2/source/")
	var registry_path: String = "res://art/maps/luoyang_modular_v3/" + ("source/reused_architecture_authoring.json" if authoring else "source/reused_city_prop_provenance.json")
	# Absence selects the sole canonical registry, never a guessed alternate.
	# An explicit null, empty or different path still fails the same strict gate.
	var provenance: Variant = object.get("provenance_document", registry_path)
	for path: Variant in [original, source, runtime, provenance]:
		if not path is String or not path.begins_with("res://") or ".." in path or not catalog.has(path) or not _hash(catalog[path]) or FileAccess.get_sha256(path).to_lower() != String(catalog[path]).to_lower(): return "Unbound existing-original prop evidence " + String(object.get("id", ""))
	# Frozen v2 city props record source_sha256 without a redundant original SHA.
	# Only an absent key may use that exact bound value; explicit invalid values fail.
	var original_sha: Variant = object.get("original_source_sha256")
	if authoring and not object.has("original_source_sha256"): original_sha = object.get("source_sha256")
	if not _same_source_hash(object.get("source_sha256"), catalog[source]) or not _same_source_hash(original_sha, catalog[original]) or String(catalog[original]).to_lower() != String(catalog[source]).to_lower() or String(catalog[source]).to_lower() != String(catalog[runtime]).to_lower(): return "Existing-original source/copy/runtime bytes differ " + String(object.get("id", ""))
	if provenance != registry_path: return "Unexpected existing-original provenance registry"
	var registry: Variant = JSON.parse_string(FileAccess.get_file_as_string(provenance))
	if authoring: return _authoring_reuse_error(object, registry, catalog)
	if not registry is Dictionary or registry.get("status") != "PROJECT_EXISTING_ORIGINAL_REUSE_NOT_CC0" or registry.get("source_bytes_modified") != false or not registry.get("sources") is Array: return "Invalid existing-original provenance status"
	for entry: Variant in registry.sources:
		if entry is Dictionary and entry.get("path") == original and entry.get("copy") == source and _hash(entry.get("sha256")) and String(entry.sha256).to_lower() == String(catalog[original]).to_lower() and _vec(entry.get("size_px")) == _vec(object.get("source_size_px")): return ""
	return "Existing-original not registered against exact source/copy bytes"

static func _authoring_reuse_error(object: Dictionary, registry: Variant, catalog: Dictionary) -> String:
	# Frozen v2 authoring is a different, explicit schema from the tablet/chest
	# registry. It proves source geometry identity, NOT CC0 or new generation.
	const ORIGINAL_CONTRACT := "res://art/maps/luoyang_modular_v2/art_contract.json"
	const ORIGINAL_SHA := "948702c260994754a75c3d113848fc419a34e6c3a15e25a5bf7268500178867b"
	if not registry is Dictionary or not _num(registry.get("schema_version"), 1) or registry.get("status") != "FROZEN_AUTHORING_GEOMETRY_ONLY" or registry.get("frozen_original_contract_path") != ORIGINAL_CONTRACT or not _same_source_hash(registry.get("frozen_original_contract_sha256"), ORIGINAL_SHA) or FileAccess.get_sha256(ORIGINAL_CONTRACT).to_lower() != ORIGINAL_SHA or not registry.get("objects") is Array: return "Invalid frozen v2 source-authoring registry"
	var original: String = String(object.original_source)
	if not original.begins_with("res://art/maps/luoyang_modular_v2/source/") or object.source != "res://art/maps/luoyang_modular_v3/source/" + original.get_file() or not object.get("source_semantics") is Dictionary or object.source_semantics.is_empty(): return "Invalid frozen v2 original/copy/source semantics"
	for entry: Variant in registry.objects:
		if not entry is Dictionary or entry.get("texture") != original or entry.get("source") != original: continue
		if entry.get("nature") != object.get("nature") or not _same_source_hash(entry.get("source_sha256"), catalog[original]) or _vec(entry.get("source_size_px")) != _vec(object.get("source_size_px")) or not _equal_value(entry.get("source_semantics"), object.source_semantics): continue
		if not _png_size(original, Vector2i(_vec(object.source_size_px))): return "Frozen v2 original source dimensions changed"
		return ""
	return "Frozen v2 original/source semantics not registered against exact bytes"

static func _same_source_hash(value: Variant, expected: String) -> bool:
	return _hash(value) and String(value).to_lower() == expected.to_lower()

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true


