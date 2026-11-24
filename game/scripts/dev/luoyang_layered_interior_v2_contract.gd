extends RefCounted
## Isolated mechanism trial, NOT a production city replacement or art approval.
const ROOT := "res://art/maps/luoyang_modular_v2/"
const MANIFEST_PATH := ROOT + "art_contract.json"
const MANIFEST_SHA := "948702c260994754a75c3d113848fc419a34e6c3a15e25a5bf7268500178867b"
const LAB_ID := &"luoyang_layered_interior_v2"
const SIZE := Vector2(3072, 2048)
const BODY_SIZE := Vector2(34, 24)
const ANCHOR_IDS := ["entry", "south_market", "inn", "shop", "bounty_board"]
const NPC_FEET := {"luoyang_gate_sergeant": Vector2(1700, 1780), "spar_luoyang_patrol": Vector2(1070, 1170), "luoyang_armorer": Vector2(2370, 1080)}
const LAYOUT_ARRAY_FIELDS := ["walkable_regions", "walkable_mask_tiles", "tiles", "travel_routes", "visual_objects", "occluders", "actor_fade_zones", "blockers", "interactions", "portals", "walkable_probes", "blocked_probes", "seam_crossing_probes"]
const SCENE_ARRAY_FIELDS := ["hotspots", "scene_objects", "exits", "trigger_zones", "collision_rects", "animated_props", "encounter_enemy_ids", "encounter_groups", "npcs"]
const CANONICAL := {
	"ch4_s0_luoyang_gate": "b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"ch4_s1_luoyang_yamen": "7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"ch4_s3_luoyang_market": "5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"ch4_s2_canal_docks": "81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5",
}
var manifest: Dictionary = {}
var errors: Array[String] = []
var canonical_before: Dictionary = {}
var materialization_diagnostics: Array[Dictionary] = []
var _walk: Image
var _solids: Array[PackedVector2Array] = []
var object_ids: Dictionary = {}
var blocking_ids: Dictionary = {}
var anchors: Dictionary = {}
var gate_foot := Vector2(INF, INF)
var inner_foot := Vector2(INF, INF)

func prepare() -> bool:
	errors.clear()
	manifest.clear()
	object_ids.clear()
	blocking_ids.clear()
	anchors.clear()
	_walk = null
	gate_foot = Vector2(INF, INF)
	inner_foot = Vector2(INF, INF)
	if MANIFEST_SHA.length() != 64:
		return _fail("V2 final art manifest has not been frozen; preview NOT_READY")
	if not "--luoyang-layered-v2-preview" in OS.get_cmdline_user_args():
		return _fail("Explicit --luoyang-layered-v2-preview required")
	if FileAccess.get_sha256(MANIFEST_PATH).to_lower() != MANIFEST_SHA:
		return _fail("Frozen art manifest is missing or changed")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary: return _fail("Invalid art JSON")
	manifest = parsed
	if int(manifest.get("schema_version", 0)) != 1 or String(manifest.get("scene_id", "")) != String(LAB_ID):
		return _fail("Wrong art identity/schema")
	if String(manifest.get("status", "")) != "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA":
		return _fail("Art is not the frozen mechanism candidate")
	if vec(manifest.get("logical_size_px", [])) != SIZE:
		return _fail("Canvas size mismatch")
	if String(manifest.get("pixel_sampling", "")) != "round_world_pixel" or float(manifest.get("physical_navigation_margin_px", -1)) != 0:
		return _fail("Sampling/margin contract mismatch")
	if vec(manifest.get("ordinary_actor_body_px", [])) != BODY_SIZE or float(manifest.get("ordinary_actor_visual_scale", 0)) != .91:
		return _fail("Ordinary actor contract mismatch")
	var catalog: Variant = manifest.get("asset_sha256", null)
	if not catalog is Dictionary or catalog.is_empty(): return _fail("Missing asset SHA graph")
	for path: String in catalog:
		if not path.begins_with("res://") or FileAccess.get_sha256(path).to_lower() != String(catalog[path]).to_lower():
			return _fail("Asset bytes mismatch: " + path)
	for role: String in manifest.get("capture_graph", {}):
		var binding: Dictionary = manifest.capture_graph[role]
		if not catalog.has(String(binding.get("path", ""))) or String(catalog[binding.path]).to_lower() != String(binding.get("sha256", "")).to_lower():
			return _fail("Capture graph not catalog-bound: " + role)
	for path: String in manifest.get("source_graph", {}):
		if not catalog.has(path) or String(catalog[path]).to_lower() != String(manifest.source_graph[path]).to_lower(): return _fail("Source graph not catalog-bound: " + path)
	for key: String in ["ground_path", "land_path", "raw_walk_path", "walk_path"]:
		var path: String = String(manifest.get(key, ""))
		if not path.begins_with(ROOT) or not catalog.has(path): return _fail("Unbound canvas: " + key)
		var image: Image = Image.load_from_file(path)
		if image == null or image.get_size() != Vector2i(SIZE): return _fail("Canvas missing/wrong dimensions: " + key)
		if not ResourceLoader.exists(path): return _fail("Canvas import missing: " + path)
		if key == "walk_path":
			_walk = image
			_walk.convert(Image.FORMAT_RGBA8)
			var texture: Texture2D = load(path) as Texture2D
			if texture == null: return _fail("Walk texture unavailable")
			var decoded: Image = texture.get_image()
			if decoded == null: return _fail("Walk import decode unavailable")
			if decoded.is_compressed() and decoded.decompress() != OK: return _fail("Walk import decompress failed")
			decoded.convert(Image.FORMAT_RGBA8)
			if decoded.get_size() != _walk.get_size() or decoded.get_data() != _walk.get_data(): return _fail("Imported navigation differs from actual PNG")
	_solids.clear()
	var objects: Array = manifest.get("objects", [])
	if objects.is_empty(): return _fail("Empty independent entity declaration")
	var ids: Dictionary = {}
	for object: Dictionary in objects:
		var id: String = String(object.get("id", ""))
		var texture_path: String = String(object.get("texture", ""))
		if id.is_empty() or ids.has(id) or not texture_path.begins_with(ROOT) or not catalog.has(texture_path): return _fail("Invalid entity identity: " + id)
		ids[id] = true
		var source: String = String(object.get("source", ""))
		if not catalog.has(source) or String(catalog[source]).to_lower() != String(object.get("source_sha256", "")).to_lower(): return _fail("Entity source not bound: " + id)
		var original: Image = Image.load_from_file(source)
		if original == null or original.get_size() != Vector2i(vec(object.get("source_size_px", []))): return _fail("Entity source dimensions: " + id)
		if not ResourceLoader.exists(texture_path): return _fail("Entity import missing: " + id)
		var foot: Vector2 = vec(object.get("world_foot_px", []))
		var render_size: Vector2 = vec(object.get("render_size_px", []))
		var uv: Vector2 = vec(object.get("foot_uv", []))
		if not finite_point(foot) or not finite_point(uv) or not finite_point(render_size) or render_size.x <= 0 or render_size.y <= 0 or uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1: return _fail("Entity foot/render geometry: " + id)
		if not Rect2(Vector2.ZERO, SIZE).has_point(foot): return _fail("Entity foot outside canvas: " + id)
		if float(object.get("depth_foot_y", -1)) != foot.y: return _fail("Entity depth is not its physical foot: " + id)
		if typeof(object.get("blocking", null)) != TYPE_BOOL: return _fail("Missing typed blocking declaration: " + id)
		var raw_solids: Variant = object.get("solid_polygons_px", null)
		if not raw_solids is Array: return _fail("Missing solid polygon declaration: " + id)
		var box_size: Vector2 = vec(object.get("collision_size_px", []))
		var physical_center: Vector2 = vec(object.get("physical_center_px", []))
		if not finite_point(box_size) or not finite_point(physical_center) or box_size.x < 0 or box_size.y < 0 or (box_size.x == 0) != (box_size.y == 0): return _fail("Invalid physical rectangle: " + id)
		var has_box: bool = box_size.x > 0 and box_size.y > 0
		var has_polygon: bool = not raw_solids.is_empty()
		if bool(object.blocking) != (has_box or has_polygon): return _fail("Blocking/geometry mismatch: " + id)
		if has_box and has_polygon: return _fail("Double solid/rectangle collision: " + id)
		if bool(object.blocking): blocking_ids[id] = true
		for raw: Array in object.get("solid_polygons_px", []):
			var polygon: PackedVector2Array = polygon_from(raw)
			if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return _fail("Invalid real solid polygon: " + id)
			for point: Vector2 in polygon:
				if not finite_point(point) or not Rect2(Vector2.ZERO, SIZE).has_point(point): return _fail("Solid outside canvas: " + id)
			_solids.append(polygon)
		if box_size.x > 0 and box_size.y > 0:
			var physical_rect := Rect2(physical_center - box_size * .5, box_size)
			if physical_rect.position.x < 0 or physical_rect.position.y < 0 or physical_rect.end.x >= SIZE.x or physical_rect.end.y >= SIZE.y: return _fail("Physical rectangle outside canvas: " + id)
			_solids.append(rect_polygon(Rect2(vec(object.physical_center_px) - box_size * .5, box_size)))
		if id == "south_gate": gate_foot = foot
	object_ids = ids.duplicate(true)
	for id: String in ["south_gate", "inn", "shop", "notice_pavilion"]:
		if not ids.has(id): return _fail("Missing semantic interaction entity: " + id)
	var authored_anchors: Variant = manifest.get("interaction_anchors", null)
	if not authored_anchors is Array or authored_anchors.size() != ANCHOR_IDS.size(): return _fail("Exact five interaction anchors required")
	for anchor: Dictionary in authored_anchors:
		var id: String = String(anchor.get("id", ""))
		var point: Vector2 = vec(anchor.get("point_px", []))
		if id not in ANCHOR_IDS or anchors.has(id) or String(anchor.get("action_mode", "")) != "DRY_RUN_ONLY" or not finite_point(point): return _fail("Invalid dry-run semantic anchor: " + id)
		anchors[id] = point
	if vec(manifest.get("entry_foot_px", [])) != anchors.entry or vec(manifest.get("return_foot_px", [])) != anchors.entry: return _fail("Trial entry/return anchor mismatch")
	var routes: Variant = manifest.get("routes", null)
	if not routes is Array: return _fail("Missing authored public routes")
	var gate_route_found := false
	for route: Dictionary in routes:
		if String(route.get("id", "")) != "gate_to_market": continue
		if gate_route_found: return _fail("Duplicate gate approach route")
		gate_route_found = true
		var points: Variant = route.get("points_px", null)
		if not points is Array: return _fail("Invalid gate route points")
		for index in range(points.size() - 1):
			if vec(points[index]) == gate_foot: inner_foot = vec(points[index + 1])
	if not gate_route_found or not finite_point(inner_foot) or inner_foot == gate_foot: return _fail("Gate checkpoint is not bound to its real route")
	for scene_id: String in CANONICAL:
		var path: String = "res://data/scenes/%s.tres" % scene_id
		if FileAccess.get_sha256(path).to_lower() != CANONICAL[scene_id]: return _fail("Canonical scene changed: " + scene_id)
		var scene: SceneScript = load(path) as SceneScript
		if scene == null or scene.map_layout == null: return _fail("Canonical resource missing: " + scene_id)
		canonical_before[scene_id] = storage_snapshot(scene)
	for point: Vector2 in [vec(manifest.get("entry_foot_px", [])), vec(manifest.get("return_foot_px", [])), gate_foot, inner_foot]:
		if not safe_body(point): return _fail("Unsafe authored trial anchor: " + str(point))
	var required_stands: Array = anchors.values() + NPC_FEET.values()
	for point: Vector2 in required_stands:
		if not safe_body(point): return _fail("Unsafe entity/NPC anchor: " + str(point))
	return errors.is_empty()

func _fail(message: String) -> bool:
	errors.append(message)
	return false

func vec(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func finite_point(point: Vector2) -> bool:
	return is_finite(point.x) and is_finite(point.y)

func polygon_from(raw: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Variant in raw: result.append(vec(point))
	return result

func rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])

func safe_body(point: Vector2) -> bool:
	# Native one-world-pixel coordinates, no normalized (size-1) remapping.
	# Entire ordinary 34x24 physics body, not just the world-travel shoe ellipse.
	if _walk == null or not finite_point(point): return false
	var rect := Rect2(point - BODY_SIZE * .5, BODY_SIZE)
	if rect.position.x < 0 or rect.position.y < 0 or rect.end.x >= SIZE.x or rect.end.y >= SIZE.y: return false
	for y in range(roundi(rect.position.y), roundi(rect.end.y) + 1):
		for x in range(roundi(rect.position.x), roundi(rect.end.x) + 1):
			var pixel: Color = _walk.get_pixel(x, y)
			if pixel.a < .5 or pixel.r < .5: return false
	var body_polygon: PackedVector2Array = rect_polygon(rect)
	for solid: PackedVector2Array in _solids:
		if not Geometry2D.intersect_polygons(body_polygon, solid).is_empty(): return false
	return true

func independent_copy(original: Resource) -> Resource:
	var copy: Resource = original.duplicate(true)
	for property: Dictionary in original.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or property.name == "script": continue
		var value: Variant = original.get(property.name)
		if value is Array or value is Dictionary: copy.set(property.name, value.duplicate(true))
	if original is SceneScript and original.map_layout != null:
		copy.set("map_layout", independent_copy(original.map_layout))
	return copy

func storage_snapshot(resource: Resource) -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in resource.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or property.name == "script": continue
		result[property.name] = snapshot_value(resource.get(property.name))
	return result

func snapshot_value(value: Variant) -> Variant:
	if value is Resource: return storage_snapshot(value)
	if value is Array:
		var array: Array = []
		for item: Variant in value: array.append(snapshot_value(item))
		return array
	if value is Dictionary:
		var dict: Dictionary = {}
		for key: Variant in value: dict[key] = snapshot_value(value[key])
		return dict
	return value

func canonical_unchanged() -> bool:
	for scene_id: String in canonical_before:
		var original: Resource = load("res://data/scenes/%s.tres" % scene_id)
		if storage_snapshot(original) != canonical_before[scene_id]: return false
		if FileAccess.get_sha256("res://data/scenes/%s.tres" % scene_id).to_lower() != CANONICAL[scene_id]: return false
	return true

func make_scene() -> SceneScript:
	if _walk == null or not errors.is_empty(): return null
	var gate: SceneScript = load("res://data/scenes/ch4_s0_luoyang_gate.tres") as SceneScript
	var market: SceneScript = load("res://data/scenes/ch4_s3_luoyang_market.tres") as SceneScript
	var scene: SceneScript = independent_copy(gate) as SceneScript
	if scene == null or scene.map_layout == null or is_same(scene.map_layout, gate.map_layout):
		_fail("Candidate must own an independent external layout")
		return null
	materialization_diagnostics.clear()
	if not clear_isolated_typed_arrays(gate, scene, SCENE_ARRAY_FIELDS): return null
	if not clear_isolated_typed_arrays(gate.map_layout, scene.map_layout, LAYOUT_ARRAY_FIELDS): return null
	scene.scene_id = LAB_ID
	scene.display_name = "洛阳南门—南市 · 分层 v2 机制试样（不保存）"
	scene.background_path = String(manifest.ground_path)
	scene.streamed_background = null
	scene.bgm_path = ""
	scene.ambience_path = ""
	scene.on_enter_dialog = null
	scene.on_enter_once_flag = &""
	scene.on_enter_require_flag = &""
	scene.actor_positions_are_feet = true
	scene.player_visual_scale = .91
	scene.npc_visual_scale = 1
	scene.player_spawn = vec(manifest.entry_foot_px) / SIZE
	scene.camera_zoom = 1.05
	scene.is_settlement = true
	scene.encounter_step_distance = 0
	scene.encounter_chance = 0
	var layout: WalkableMapLayout = scene.map_layout
	layout.design_size = Vector2i(SIZE)
	layout.display_at_native_size = true
	layout.fill_viewport = false
	layout.walkable_mask_path = String(manifest.walk_path)
	layout.visual_objects = runtime_objects()
	layout.portals = [
		{"id": "entry", "pos": vec(manifest.entry_foot_px) / SIZE, "size": Vector2(64, 40) / SIZE,
		"action": "lab_identity:entry", "label": "外部世界动作 · 只记录", "show_destination_label": true},
		{"id": "enter_luoyang", "pos": gate_foot / SIZE, "size": Vector2(64, 40) / SIZE,
		"target_scene": String(LAB_ID), "target_pos": inner_foot / SIZE, "label": "门槛检查 · 仅本地试样", "show_destination_label": true},
		{"id": "lab_return", "pos": inner_foot / SIZE, "size": Vector2(64, 40) / SIZE,
		"target_scene": String(LAB_ID), "target_pos": gate_foot / SIZE, "label": "返回试样门前", "show_destination_label": true},
		{"id": "south_market", "pos": anchors.south_market / SIZE, "size": Vector2(64, 40) / SIZE,
		"action": "lab_identity:south_market", "label": "府衙动作身份 · 只记录", "show_destination_label": true},
	]
	# Off the public route and >118px from both gate and entry checkpoints;
	# the normal NPC-first Space dispatch must not steal a doorway interaction.
	append_npc(scene, gate, "luoyang_gate_sergeant", NPC_FEET.luoyang_gate_sergeant)
	append_npc(scene, market, "spar_luoyang_patrol", NPC_FEET.spar_luoyang_patrol)
	append_npc(scene, market, "luoyang_armorer", NPC_FEET.luoyang_armorer)
	scene.set_meta("lab_contract", MANIFEST_PATH)
	scene.set_meta("lab_only", true)
	if not materialization_valid(scene): return null
	if not canonical_unchanged():
		_fail("Candidate materialization mutated canonical STORAGE")
		return null
	return scene

func clear_isolated_typed_arrays(original: Resource, copy: Resource, names: Array) -> bool:
	# Object.set(property, []) supplies an untyped Array to typed exports and
	# cannot be assumed to have replaced them. Keep each copied Array's type,
	# first prove it is not the source instance, then mutate that copy in place.
	for name: String in names:
		var source_value: Variant = original.get(name)
		var candidate_value: Variant = copy.get(name)
		if not source_value is Array or not candidate_value is Array:
			return _fail("Expected exported Array: " + name)
		if is_same(source_value, candidate_value):
			return _fail("Refusing to clear shared source Array: " + name)
		var entry: Dictionary = {"resource_class": original.get_class(), "property": name, "before_count": candidate_value.size(), "typed": candidate_value.is_typed(), "typed_builtin": candidate_value.get_typed_builtin(), "source_alias": false}
		candidate_value.clear()
		entry.after_count = candidate_value.size()
		materialization_diagnostics.append(entry)
		if not candidate_value.is_empty() or not copy.get(name).is_empty():
			return _fail("Copied typed Array did not clear: " + name)
	return true

func materialization_valid(scene: SceneScript) -> bool:
	if scene == null or scene.scene_id != LAB_ID or scene.map_layout == null:
		return _fail("Invalid candidate scene/layout identity")
	if scene.background_path != String(manifest.get("ground_path", "")) or scene.map_layout.walkable_mask_path != String(manifest.get("walk_path", "")):
		return _fail("Candidate background/nav binding mismatch")
	for name: String in SCENE_ARRAY_FIELDS:
		var value: Variant = scene.get(name)
		if name != "npcs" and (not value is Array or not value.is_empty()): return _fail("Inherited scene Array is not empty: " + name)
	for name: String in LAYOUT_ARRAY_FIELDS:
		var value: Variant = scene.map_layout.get(name)
		if name not in ["visual_objects", "portals"] and (not value is Array or not value.is_empty()): return _fail("Inherited layout Array is not empty: " + name)
	if scene.map_layout.visual_objects.size() != object_ids.size() or scene.map_layout.portals.size() != 4 or scene.npcs.size() != NPC_FEET.size():
		return _fail("Candidate entity/portal/NPC cardinality mismatch")
	var seen: Dictionary = {}
	for object: Dictionary in scene.map_layout.visual_objects:
		var id: String = String(object.get("id", ""))
		if not object_ids.has(id) or seen.has(id): return _fail("Candidate visual ID mismatch: " + id)
		seen[id] = true
	if scene.streamed_background != null or scene.on_enter_dialog != null or not scene.is_settlement:
		return _fail("Candidate retains production enter/stream/encounter behaviour")
	return true

func append_npc(scene: SceneScript, original: SceneScript, id: String, point: Vector2) -> void:
	for source: Dictionary in original.npcs:
		if String(source.get("npc_id", "")) != id: continue
		var npc: Dictionary = source.duplicate(true)
		npc.pos = point / SIZE
		npc.lab_source_scene_id = String(original.scene_id)
		npc.lab_source_id = id
		scene.npcs.append(npc)
		return

func runtime_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for authored: Dictionary in manifest.objects:
		var foot: Vector2 = vec(authored.world_foot_px)
		var size: Vector2 = vec(authored.render_size_px)
		var center: Vector2 = foot + (Vector2(.5, .5) - vec(authored.foot_uv)) * size
		var object: Dictionary = authored.duplicate(true)
		object.pos = center / SIZE
		object.render_size_px = size
		object.centered = true
		object.sort_by_feet = true
		object.depth_sort_foot_y = foot.y / SIZE.y
		# Physics created by the isolated subclass, never the v15-world branch.
		object.erase("collision_size")
		object.solid_polygons_px = []
		var id: String = String(authored.id)
		var anchor: Vector2 = Vector2.ZERO
		if id == "south_gate": anchor = gate_foot
		if id == "inn": anchor = anchors.inn
		if id == "shop": anchor = anchors.shop
		if id == "notice_pavilion": anchor = anchors.bounty_board
		if anchor != Vector2.ZERO:
			object.interaction_action = "lab_identity:" + id
			object.interaction_offset = (anchor - center) / SIZE
			object.interaction_size = Vector2(80, 48) / SIZE
		result.append(object)
	return result

func action_bindings(id: String) -> Array[Dictionary]:
	# Explicit identities from canonical resources; the art's pending tokens are
	# never interpreted as gameplay actions. Gates are evaluated, not overridden.
	if id in ["south_gate", "enter_luoyang"]:
		return [{"source_scene_id": "ch4_s0_luoyang_gate", "source_id": "enter_luoyang", "action": "scene:ch4_s1_luoyang_yamen", "original_target_pos": Vector2(.5, .73)}]
	if id == "lab_return": return [{"source_scene_id": String(LAB_ID), "source_id": id, "action": "lab:return_checkpoint"}]
	if id == "entry": return [{"source_scene_id": "ch4_s0_luoyang_gate", "source_id": "return_world", "action": "world_map"}]
	if id == "south_market": return [{"source_scene_id": "ch4_s3_luoyang_market", "source_id": "to_yamen_square", "action": "scene:ch4_s1_luoyang_yamen", "original_target_pos": Vector2(.15, .59)}]
	if id == "shop": return [{"source_scene_id": "ch4_s3_luoyang_market", "source_id": "luoyang_armorer", "action": "shop:luoyang_armory"}]
	if id == "notice_pavilion":
		return [{"source_scene_id": "ch4_s0_luoyang_gate", "source_id": "luoyang_wanted_board", "action": "dialog:ch4_case_clue", "require_flag": "chapter4_started", "hide_flag": "luoyang_case_found_clue"},
		{"source_scene_id": "ch4_s0_luoyang_gate", "source_id": "luoyang_repeatable_bounty_board", "action": "bounty_board:luoyang", "require_flag": "luoyang_case_found_clue"}]
	if id == "inn": return [{"source_scene_id": String(LAB_ID), "source_id": id, "action": "lab:inspect_inn", "canonical_action_exists": false}]
	return []
