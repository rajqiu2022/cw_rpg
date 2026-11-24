extends RefCounted
## Independent, source-pinned wall visual only. No mutable compiled owner data.
const HOME := "res://build/luoyang_quality_20261101b_decor01/"
const BINDING := HOME + "decor_binding.json"
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const ROOM := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const SHELL := "res://art/modules/luoyang_assembled_interiors_20261016g/shell_inn_hall_v1.png"
const SHELL_SHA := "930e994cb144573ee3eccb47c23b5a5f8e3dd539c0e973535f43020d519e84fb"
const PNG := "res://art/modules/luoyang_quality_20261101b/salon_wall_v1.png"
const RUG := "res://art/modules/luoyang_quality_20261101b/salon_rug_v1.png"
const RUG_FLOOR := Rect2(480, 590, 400, 200)
const META := "quality_20261101b_decor"
const NODE_NAME := "Quality20261101bWallDecor"
const IDS := ["yihongyuan27n_matron", "yihongyuan27n_waiter", "yihongyuan27n_merchant", "yihongyuan27n_scholar", "yihongyuan27n_elder_guest", "yihongyuan27n_woman_guest"]
const SAFE_BAYS := {
	"SaloonCentralWallHanging": Rect2(666, 260, 208, 110),
	"SaloonWestWallHanging": Rect2(450, 260, 176, 110),
	"SaloonEastWallHanging": Rect2(916, 260, 178, 110)
}

static func source_paths() -> Array[String]:
	var paths: Array[String] = [HOME + "live_decor_view.gd", BINDING, PNG, PNG + ".import", RUG, RUG + ".import", SHELL, SHELL + ".import", "res://.godot/imported/shell_inn_hall_v1.png-f07613623732c8b9ea1925a84ac810da.ctex"]
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDING))
	if value is Dictionary:
		var gpu: String = String(value.get("media", {}).get("gpu_path", ""))
		if not gpu.is_empty(): paths.append(gpu)
		var rug_gpu: String = String(value.get("floor_rug", {}).get("media", {}).get("gpu_path", ""))
		if not rug_gpu.is_empty(): paths.append(rug_gpu)
	return paths

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "applied": false, "error": reason}

static func _point(value: Variant) -> Vector2:
	if not value is Array or value.size() != 2: return Vector2(INF, INF)
	return Vector2(float(value[0]), float(value[1]))

static func _rect(value: Variant) -> Rect2:
	if not value is Array or value.size() != 2: return Rect2()
	return Rect2(_point(value[0]), _point(value[1]))

static func _media(media: Dictionary, expected_path: String) -> Dictionary:
	var gpu: String = String(media.get("gpu_path", ""))
	if media.get("path") != expected_path or not gpu.begins_with("res://.godot/imported/" + expected_path.get_file() + "-") or not gpu.ends_with(".ctex"):
		return _fail("DECOR_EXACT_RUNTIME_MEDIA:" + expected_path)
	var pins: Dictionary = media.get("source_sha256", {})
	if pins.size() != 3: return _fail("DECOR_THREE_EXACT_MEDIA_PINS:" + expected_path)
	for path: String in [expected_path, expected_path + ".import", gpu]:
		if String(pins.get(path, "")).length() != 64 or FileAccess.get_sha256(path) != pins[path]: return _fail("DECOR_MEDIA_SOURCE_CHANGED:" + path)
	var import_config := ConfigFile.new()
	if import_config.load(expected_path + ".import") != OK or import_config.get_value("remap", "path", "") != gpu:
		return _fail("DECOR_GPU_IS_ACTUAL_IMPORT_TARGET:" + expected_path)
	var texture: Texture2D = load(expected_path) as Texture2D
	var content: Rect2 = _rect(media.get("content_rect_px"))
	if texture == null or texture.get_size() != _point(media.get("size_px")) or content.size.x <= 0 or content.size.y <= 0:
		return _fail("DECOR_NATIVE_DIMENSIONS:" + expected_path)
	var image: Image = texture.get_image()
	if image == null or Rect2(image.get_used_rect()) != content: return _fail("DECOR_GPU_SAME_CONTENT_BOUNDS:" + expected_path)
	return {"ok": true, "texture": texture, "content": content, "pins": pins}

static func _leaf(id: String, texture: Texture2D, content: Rect2, visible: Rect2, ratio: float, depth: int) -> Polygon2D:
	# One complete native quad, identical to an uncentered uniformly-scaled
	# Sprite2D. Polygon2D lets the existing minimap clone this independent view.
	var leaf := Polygon2D.new()
	var size: Vector2 = texture.get_size()
	var quad := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	leaf.name = id
	leaf.texture = texture
	leaf.polygon = quad
	leaf.uv = quad.duplicate()
	leaf.scale = Vector2.ONE * ratio
	leaf.position = visible.position - content.position * ratio
	leaf.z_as_relative = false
	leaf.z_index = depth
	leaf.set_meta("decor_only_no_collision", true)
	return leaf

static func attach(field: Node) -> Dictionary:
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_script() == null or field.get_script().resource_path != FIELD:
		return _fail("DECOR_EXACT_REGION_FIELD")
	if field.get("_field_loading_complete") != true or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") == true:
		return _fail("DECOR_FIELD_NOT_READY")
	var region: Variant = field.get("_region")
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if not region is Dictionary or region.get("id") != ROOM or region.get("size") != Vector2(1536, 1024) or scene == null or String(scene.scene_id) != ROOM:
		return _fail("DECOR_EXACT_ROOM_AND_COORDINATES")
	if region.get("room_enclosure", {}).get("native_complete_shell") != SHELL or region.get("sources", {}).get(SHELL) != SHELL_SHA or FileAccess.get_sha256(SHELL) != SHELL_SHA:
		return _fail("DECOR_ORIGINAL_NATIVE_SHELL")
	var parent: Node2D = field.get("_visual_layer") as Node2D
	if parent == null or not parent.is_inside_tree() or parent.transform != Transform2D.IDENTITY:
		return _fail("DECOR_ORIGINAL_VISUAL_COORDINATES")
	if field.has_meta(META):
		if parent.get_node_or_null(NodePath(NODE_NAME)) == null: return _fail("DECOR_EXISTING_VIEW_MISSING")
		return {"ok": true, "applied": false, "already_attached": true, "receipt": field.get_meta(META).duplicate(true)}
	if parent.get_node_or_null(NodePath(NODE_NAME)) != null: return _fail("DECOR_FOREIGN_NAMED_VIEW")
	if not region.get("npcs") is Array or region.npcs.size() != 6: return _fail("DECOR_SIX_AUTHORED_NPCS")
	var actors: Variant = field.get("_region_actors")
	if not actors is Dictionary or actors.size() != 6: return _fail("DECOR_SIX_LIVE_NPCS")
	var identities: Dictionary = {}
	for row: Dictionary in region.npcs:
		var id: String = String(row.get("data", {}).get("npc_id", ""))
		var slot: String = LOGICAL + "/" + id
		if id not in IDS or identities.has(id) or row.get("logical_id") != LOGICAL or row.get("slot_key") != slot: return _fail("DECOR_AUTHORED_NPC_IDENTITY")
		var npc: NPCNode = actors.get(slot, {}).get("node") as NPCNode
		if not is_instance_valid(npc) or npc.npc_id != id or npc.get_meta("region27d_logical_id", "") != LOGICAL or npc.get_meta("region27d_slot_key", "") != slot:
			return _fail("DECOR_LIVE_NPC_METADATA")
		identities[id] = {"instance": npc.get_instance_id(), "transform": npc.transform}
	var spec: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDING))
	if not spec is Dictionary or spec.get("schema") != "YIHONG_WALL_VIEW_V1" or spec.get("sealed_by_root_after_media_import") != true or spec.get("room_id") != ROOM:
		return _fail("DECOR_ROOT_MEDIA_BINDING_NOT_SEALED")
	var wall: Dictionary = _media(spec.get("media", {}), PNG)
	if wall.get("ok") != true: return wall
	var texture: Texture2D = wall.texture as Texture2D
	var content: Rect2 = wall.content
	var pins: Dictionary = wall.pins.duplicate(true)
	if not spec.get("placements") is Array or spec.placements.size() != 3: return _fail("DECOR_THREE_DECLARED_BAYS")
	var group := Node2D.new()
	group.name = NODE_NAME
	var placed: Array[Dictionary] = []
	var seen: Dictionary = {}
	for placement: Dictionary in spec.placements:
		var id: String = String(placement.get("id", ""))
		var safe: Rect2 = _rect(placement.get("wall_safe_rect_px"))
		if not SAFE_BAYS.has(id) or seen.has(id) or safe != SAFE_BAYS[id]:
			group.free(); return _fail("DECOR_FIXED_BACK_WALL_BAYS")
		seen[id] = true
		if placement.get("enabled") != true: continue
		var maximum: Vector2 = _point(placement.get("maximum_content_size_px"))
		var center: Vector2 = _point(placement.get("content_center_px"))
		if not maximum.is_finite() or not center.is_finite() or maximum.x <= 0 or maximum.y <= 0:
			group.free(); return _fail("DECOR_FINITE_UNIFORM_PLACEMENT")
		var ratio: float = minf(1.0, minf(maximum.x / content.size.x, maximum.y / content.size.y))
		var visible := Rect2(center - content.size * ratio * 0.5, content.size * ratio)
		if not safe.encloses(visible):
			group.free(); return _fail("DECOR_STAYS_INSIDE_WALL_WITHOUT_BEAM_RAIL_ACTOR")
		var leaf: Polygon2D = _leaf(id, texture, content, visible, ratio, -990)
		group.add_child(leaf)
		placed.append({"id": id, "scale": ratio, "position": leaf.position, "content_rect": visible, "safe_wall_rect": safe, "z_index": -990, "complete_native_quad": true})
	if placed.is_empty(): group.free(); return _fail("DECOR_AT_LEAST_ONE_ENABLED_WALL_VIEW")
	var rug: Dictionary = spec.get("floor_rug", {})
	if rug.get("enabled") == true:
		if rug.get("id") != "SaloonPeonyFloorRug" or _rect(rug.get("floor_safe_rect_px")) != RUG_FLOOR:
			group.free(); return _fail("DECOR_RUG_EXACT_FLAT_FLOOR_ZONE")
		var rug_media: Dictionary = _media(rug.get("media", {}), RUG)
		if rug_media.get("ok") != true: group.free(); return rug_media
		var rug_content: Rect2 = rug_media.content
		var maximum: Vector2 = _point(rug.get("maximum_content_size_px"))
		var center: Vector2 = _point(rug.get("content_center_px"))
		if not maximum.is_finite() or not center.is_finite() or maximum.x <= 0 or maximum.y <= 0:
			group.free(); return _fail("DECOR_RUG_FINITE_PLACEMENT")
		var ratio: float = minf(1.0, minf(maximum.x / rug_content.size.x, maximum.y / rug_content.size.y))
		var visible := Rect2(center - rug_content.size * ratio * 0.5, rug_content.size * ratio)
		if not RUG_FLOOR.encloses(visible): group.free(); return _fail("DECOR_RUG_CLEAR_OF_DOOR_AND_TABLE_FEET")
		var leaf: Polygon2D = _leaf("SaloonPeonyFloorRug", rug_media.texture, rug_content, visible, ratio, -985)
		group.add_child(leaf)
		pins.merge(rug_media.pins, true)
		placed.append({"id": "SaloonPeonyFloorRug", "scale": ratio, "position": leaf.position, "content_rect": visible, "safe_floor_rect": RUG_FLOOR, "z_index": -985, "complete_native_quad": true, "flat_walkable_decor_only": true})
	var original: PackedByteArray = var_to_bytes(region)
	parent.add_child(group)
	if var_to_bytes(region) != original:
		group.free(); return _fail("DECOR_COMPILED_ROOM_CHANGED")
	var receipt: Dictionary = {"ok": true, "room_id": ROOM, "field_instance": field.get_instance_id(), "node_instance": group.get_instance_id(), "placements": placed, "media_sha256": pins.duplicate(true), "original_actor_identities": identities, "compiled_room_typed_identical": true, "physics_nodes_added": 0, "upper_floor_changed": false, "dialogue_changed": false, "new_pngs_created_by_helper": 0, "root_screenshot_acceptance_still_required": true}
	field.set_meta(META, receipt)
	return {"ok": true, "applied": true, "receipt": receipt.duplicate(true)}
