extends SceneTree
## Small GPU UV-to-independent-Sprite exporter. Not production Polygon2D.
## Root supplies and freezes a measured plan; no atlas bbox is a physical foot.
## Existing outputs refuse overwrite. Formal resource writing is not supported.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
var _error := ""
var _region := "ch4_s1_luoyang_yamen"
var _checkpoint_suspended := false
var _sources: Dictionary = {}
var _exported: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_export")

func _export() -> void:
	# Public guard before the first await, held through process exit.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): _finish("Checkpoint suspension API unavailable"); return
	bridge.call("set_checkpoint_saves_suspended", true)
	var suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	_checkpoint_suspended = suspended is bool and suspended
	if not _checkpoint_suspended: _finish("Checkpoint suspension not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not "--export-luoyang-enclosure-v11" in args or "--activate" in args: _finish("Explicit export only; formal activation forbidden"); return
	for arg: String in args:
		if arg.begins_with("--region="): _region = arg.trim_prefix("--region=")
	if not C.owns_id(StringName(_region)) or not C._hash(C.EXPORT_PLAN_SHAS.get(_region)): _finish("Approved measured V11 plan is PENDING"); return
	var prefix: String = C.ROOT + _region + "/"
	var plan_path: String = prefix + "export_plan.json"
	if FileAccess.get_sha256(plan_path) != C.EXPORT_PLAN_SHAS[_region]: _finish("Measured authoring plan changed"); return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not raw is Dictionary: _finish("Malformed measured authoring plan"); return
	var plan: Dictionary = raw
	if plan.get("canonical_scene_id") != _region or plan.get("status") != "ROOT_APPROVED_AUTHORING_REQUIRES_GPU_FIELD_VISUAL" or plan.get("base_manifest_path") != C.base_manifest_path(StringName(_region)) or plan.get("base_manifest_sha256") != C.base_manifest_sha(StringName(_region)) or not plan.get("objects") is Array or plan.objects.is_empty() or not plan.get("remove_object_ids") is Array or not plan.get("source_catalog") is Dictionary: _finish("Plan identity/explicit object-removal/source declarations invalid"); return
	if not C.BASE.prepare(StringName(_region)): _finish("Frozen V5 base not intact: " + "; ".join(C.BASE.errors())); return
	if FileAccess.file_exists(prefix + "art_patch.json") or FileAccess.file_exists(prefix + "walk.png"): _finish("Existing V11 outputs must be preserved; root must choose NEW output revision"); return
	var baseline_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(C.base_manifest_path(StringName(_region))))
	if not baseline_raw is Dictionary: _finish("Validated base author record unreadable"); return
	var baseline: Dictionary = baseline_raw
	var objects: Array = []
	var removed: Dictionary = {}
	for oid: Variant in plan.remove_object_ids:
		if not oid is String or removed.has(oid): _finish("Invalid exact removed identity"); return
		removed[oid] = false
	var ids: Dictionary = {}
	for object: Dictionary in baseline.objects:
		if removed.has(String(object.id)): removed[String(object.id)] = true
		else: objects.append(object); ids[String(object.id)] = true
	for oid: String in removed:
		if not removed[oid]: _finish("Removal not an actual old independent object: " + oid); return
	_sources[plan_path] = FileAccess.get_sha256(plan_path)
	_sources[C.base_manifest_path(StringName(_region))] = C.base_manifest_sha(StringName(_region))
	for path: String in baseline.asset_sha256: _sources[path] = baseline.asset_sha256[path]
	for path: String in [get_script().resource_path, "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"]: _sources[path] = FileAccess.get_sha256(path)
	for path: Variant in plan.source_catalog:
		if not path is String or not path.begins_with("res://") or ".." in path or not C._hash(plan.source_catalog[path]) or FileAccess.get_sha256(path) != plan.source_catalog[path]: _finish("Frozen atlas source changed: " + str(path)); return
		_sources[path] = plan.source_catalog[path]
	for author: Variant in plan.objects:
		if not author is Dictionary or not author.get("id") is String or String(author.id).is_empty() or ids.has(String(author.id)) or not author.get("pieces") is Array or author.pieces.is_empty() or not C.BASE._in_domain(C._vec(author.get("world_foot_px"))) or not C._object_solids_valid(author): _finish("Invalid separate Y-piece/ground-foot/solid authoring"); return
		var texture_path: String = prefix + "entities/" + String(author.id) + ".png"
		if not String(author.id).is_valid_filename() or FileAccess.file_exists(texture_path): _finish("Invalid ID or pre-existing independent PNG"); return
		ids[String(author.id)] = true
		var crop: Rect2i = _crop(author, plan.source_catalog)
		if crop.size.x <= 0: _finish(_error); return
		var result: Dictionary = await _capture(author, crop, texture_path)
		if result.is_empty(): _finish(_error); return
		objects.append(result); _exported.append(result)
	var support: Image = Image.load_from_file(String(baseline.raw_walk_path))
	var walk: Image = C.raster_walk(support, objects)
	if walk == null or walk.save_png(prefix + "walk.png") != OK: _finish("New retained-plus-replaced-solid raster write failed"); return
	var catalog: Dictionary = _sources.duplicate()
	# The consumer's final patch SHA is filled only after this manifest exists;
	# retaining that pre-freeze consumer in a current-byte catalog would create
	# an impossible SHA cycle. Observe it through export exit, keep its historical
	# execution SHA below, and let root freeze the final consumer independently.
	catalog.erase("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	for object: Dictionary in _exported: catalog[object.texture] = FileAccess.get_sha256(object.texture)
	catalog[prefix + "walk.png"] = FileAccess.get_sha256(prefix + "walk.png")
	for path: String in _sources:
		if FileAccess.get_sha256(path) != _sources[path]: _finish("Source changed during actual GPU export: " + path); return
	var patch := {"schema_version": 1, "canonical_scene_id": _region, "status": "GPU_EXPORTED_REQUIRES_FIELD_VISUAL_QA", "base_manifest_path": C.base_manifest_path(StringName(_region)), "base_manifest_sha256": C.base_manifest_sha(StringName(_region)), "export_plan_path": plan_path, "export_plan_sha256": C.EXPORT_PLAN_SHAS[_region], "remove_object_ids": plan.remove_object_ids, "source_catalog": plan.source_catalog, "objects": _exported, "walk_path": prefix + "walk.png", "asset_sha256": catalog, "production_approved": false, "field_approved": false, "visual_approved": false, "executed_consumer_sha256_before_final_patch_freeze": _sources["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"], "capture_kind": "GPU_CANVAS_UV_EXPORT_NOT_NEW_IMAGE_GENERATION", "navigation_recipe": "Frozen raw native dry support, retained and NEW measured solids; original 24px guard; no old final walk reuse"}
	if not _json(prefix + "art_patch.json", patch): _finish("Patch manifest write failed"); return
	print("LUOYANG_V11_GPU_EXPORTED_NOT_FIELD_VISUAL_OR_FORMAL_APPROVED " + _region)
	_finish("")

func _crop(author: Dictionary, catalog: Dictionary) -> Rect2i:
	var minimum: Vector2 = C._vec(author.world_foot_px)
	var maximum: Vector2 = minimum
	for piece: Variant in author.pieces:
		if not piece is Dictionary or not catalog.has(piece.get("source")) or not C._vec(piece.get("origin_px")).is_finite() or not typeof(piece.get("scale")) in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(piece.scale)) or float(piece.scale) <= 0 or float(piece.scale) > 10:
			_error = "Invalid frozen source/transform piece"; return Rect2i()
		var image: Image = Image.load_from_file(String(piece.source))
		var uv: PackedVector2Array = C._polygon(piece.get("uv_polygon_px"))
		if image == null or uv.size() < 3 or Geometry2D.triangulate_polygon(uv).is_empty(): _error = "Actual source polygon cannot triangulate"; return Rect2i()
		for point: Vector2 in uv:
			if not point.is_finite() or point.x < 0 or point.y < 0 or point.x > image.get_width() or point.y > image.get_height(): _error = "UV outside actual retained source"; return Rect2i()
			var world: Vector2 = C._vec(piece.origin_px) + point * float(piece.scale)
			minimum = minimum.min(world); maximum = maximum.max(world)
	var origin := Vector2i(floori(minimum.x) - 4, floori(minimum.y) - 4)
	var end := Vector2i(ceili(maximum.x) + 5, ceili(maximum.y) + 5)
	var result := Rect2i(origin, end - origin)
	if result.size.x <= 0 or result.size.y <= 0 or result.size.x > 4096 or result.size.y > 4096: _error = "Invalid bounded native Sprite export canvas"; return Rect2i()
	return result

func _capture(author: Dictionary, crop: Rect2i, path: String) -> Dictionary:
	var view := SubViewport.new()
	view.size = crop.size; view.transparent_bg = true; view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.msaa_2d = Viewport.MSAA_DISABLED
	root.add_child(view)
	var layer := Node2D.new(); view.add_child(layer)
	for piece: Dictionary in author.pieces:
		var image: Image = Image.load_from_file(String(piece.source))
		var node := Polygon2D.new()
		node.texture = ImageTexture.create_from_image(image)
		node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		node.uv = C._polygon(piece.uv_polygon_px)
		var polygon := PackedVector2Array()
		for point: Vector2 in node.uv: polygon.append(C._vec(piece.origin_px) + point * float(piece.scale) - Vector2(crop.position))
		node.polygon = polygon; layer.add_child(node)
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	var first: Image = view.get_texture().get_image()
	await process_frame; await RenderingServer.frame_post_draw
	var repeat: Image = view.get_texture().get_image()
	if first == null or repeat == null or first.get_size() != crop.size or first.get_data() != repeat.get_data() or first.get_used_rect().size == Vector2i.ZERO:
		view.queue_free(); _error = "Actual transparent GPU readback/repeat/used pixels failed"; return {}
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK or first.save_png(path) != OK:
		view.queue_free(); _error = "Independent actual Sprite PNG write failed"; return {}
	view.queue_free(); await process_frame
	var foot: Vector2 = C._vec(author.world_foot_px)
	var uv: Vector2 = (foot - Vector2(crop.position)) / Vector2(crop.size)
	return {"id": String(author.id), "nature": "PROJECT_GENERATED_MODULE_GPU_UV_EXPORT_NOT_CC0", "texture": path, "source": path, "source_sha256": FileAccess.get_sha256(path), "source_size_px": [crop.size.x, crop.size.y], "render_size_px": [crop.size.x, crop.size.y], "world_origin_px": [crop.position.x, crop.position.y], "world_foot_px": author.world_foot_px, "depth_foot_y": foot.y, "foot_uv": [uv.x, uv.y], "solid_polygons_px": author.solid_polygons_px, "collision_size_px": author.collision_size_px, "physical_center_px": author.physical_center_px, "blocking": author.blocking, "ghost_occlusion": true, "authoring": author.duplicate(true), "actual_gpu": {"repeat_byte_exact": true, "used_rect_px": [first.get_used_rect().position.x, first.get_used_rect().position.y, first.get_used_rect().size.x, first.get_used_rect().size.y], "crop_includes_authored_ground_foot": true, "alpha_bbox_is_not_physical_foot": true}}

func _json(path: String, value: Variant) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t", false)); file.flush()
	var status: Error = file.get_error(); file.close()
	return status == OK

func _finish(error: String) -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if _checkpoint_suspended and (bridge == null or bridge.call("is_checkpoint_saves_suspended") != true): error = "Checkpoint suspension lost during GPU export; " + error
	if not error.is_empty(): push_error(error)
	# Do not resume automatic checkpoint while a quitting window loses focus.
	quit(0 if error.is_empty() else 1)
