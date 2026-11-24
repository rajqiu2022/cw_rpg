extends SceneTree
## Read-only preview of actual exported independent PNGs plus retained V5.
## No actors, collisions, interaction simulation, publication or formal credit.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ID := &"ch4_s1_luoyang_yamen"
const OUTPUT_ROOT := "res://build/luoyang_enclosure_v11_export_preview/"
var _inputs: Dictionary = {}
var _outputs: Dictionary = {}
var _output := ""
var _objects: Array = []
var _ground := ""
var _error := ""
var _views: Dictionary = {}

func _initialize() -> void: call_deferred("_start")
func _start() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): _finish("Public checkpoint guard unavailable"); return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true: _finish("Public checkpoint guard not acknowledged"); return
	var tag := ""; var patch_sha := ""
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
		if arg.begins_with("--expected-patch-sha="): patch_sha = arg.trim_prefix("--expected-patch-sha=").to_lower()
	var regex := RegEx.new()
	if not "--preview-luoyang-enclosure-v11-export" in args or DisplayServer.get_name() == "headless" or not C._hash(patch_sha) or regex.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or regex.search(tag) == null: _finish("Explicit GPU preview, frozen actual patch SHA and unique safe tag required"); return
	_output = OUTPUT_ROOT + tag + "/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output)): _finish("Refusing old GPU evidence overwrite"); return
	var patch_path: String = C.ROOT + String(ID) + "/art_patch.json"
	if not _track(patch_path, patch_sha) or not _track(C.base_manifest_path(ID), C.base_manifest_sha(ID)): _finish(_error); return
	var patch_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(patch_path))
	var base_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(C.base_manifest_path(ID)))
	if not patch_raw is Dictionary or not base_raw is Dictionary: _finish("Malformed actual patch/base"); return
	var patch: Dictionary = patch_raw; var baseline: Dictionary = base_raw
	if patch.get("canonical_scene_id") != String(ID) or patch.get("status") != "GPU_EXPORTED_REQUIRES_FIELD_VISUAL_QA" or patch.get("base_manifest_sha256") != C.base_manifest_sha(ID) or not patch.get("asset_sha256") is Dictionary or not patch.get("remove_object_ids") is Array or not patch.get("objects") is Array: _finish("Actual patch identity/schema mismatch"); return
	for path: String in patch.asset_sha256:
		if not _track(path, String(patch.asset_sha256[path])): _finish(_error); return
	for path: String in baseline.asset_sha256:
		if not _track(path, String(baseline.asset_sha256[path])): _finish(_error); return
	for path: String in [get_script().resource_path, "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"]:
		if not _track(path): _finish(_error); return
	var removed: Dictionary = {}
	for oid: String in patch.remove_object_ids: removed[oid] = false
	for object: Dictionary in baseline.objects:
		if removed.has(String(object.id)): removed[String(object.id)] = true
		else: _objects.append(object)
	for oid: String in removed:
		if not removed[oid]: _finish("Removed object not present in actual baseline"); return
	_objects.append_array(patch.objects)
	_objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.depth_foot_y) < float(b.depth_foot_y))
	_ground = String(baseline.ground_path)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output)) != OK: _finish("Unique preview output directory creation failed"); return
	for spec: Dictionary in [{"name": "full_courtyard", "rect": Rect2i(0, 0, 3072, 2048)}, {"name": "west_join_opening_corner", "rect": Rect2i(780, 300, 650, 1480)}, {"name": "east_join_opening_corner", "rect": Rect2i(1700, 300, 650, 1480)}, {"name": "front_gate", "rect": Rect2i(820, 1280, 1430, 620)}, {"name": "north_hall_joins", "rect": Rect2i(780, 180, 1580, 870)}]:
		if not await _capture(String(spec.name), spec.rect): _finish(_error); return
	_finish("")

func _capture(name: String, rect: Rect2i) -> bool:
	var viewport := SubViewport.new()
	viewport.size = rect.size; viewport.transparent_bg = false; viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.msaa_2d = Viewport.MSAA_DISABLED
	root.add_child(viewport)
	var layer := Node2D.new(); viewport.add_child(layer)
	var ground: Image = Image.load_from_file(_ground)
	if ground == null: viewport.queue_free(); _error = "Retained actual ground image unreadable"; return false
	var background := Sprite2D.new(); background.texture = ImageTexture.create_from_image(ground)
	background.centered = false; background.position = -Vector2(rect.position); background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.add_child(background)
	var geometry: Array[Dictionary] = []
	for object: Dictionary in _objects:
		var image: Image = Image.load_from_file(String(object.texture))
		if image == null: viewport.queue_free(); _error = "Actual independent object PNG unreadable"; return false
		var sprite := Sprite2D.new(); sprite.texture = ImageTexture.create_from_image(image)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; sprite.centered = false
		var render: Vector2 = C._vec(object.render_size_px)
		var origin: Vector2 = C._vec(object.world_foot_px) - C._vec(object.foot_uv) * render
		sprite.position = origin - Vector2(rect.position); sprite.scale = render / Vector2(image.get_size())
		layer.add_child(sprite)
		geometry.append({"id": String(object.id), "actual_sprite_origin_px": [origin.x, origin.y], "authored_foot_px": object.world_foot_px, "actual_render_size_px": [render.x, render.y], "depth_foot_y": object.depth_foot_y})
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	var first: Image = viewport.get_texture().get_image()
	await process_frame; await RenderingServer.frame_post_draw
	var repeat: Image = viewport.get_texture().get_image()
	if first == null or repeat == null or first.get_data() != repeat.get_data() or first.get_size() != rect.size: viewport.queue_free(); _error = "Actual full-preview GPU readback/repeat failed"; return false
	var path: String = _output + name + ".png"
	if first.save_png(path) != OK: viewport.queue_free(); _error = "Actual preview PNG write failed"; return false
	_outputs[path] = FileAccess.get_sha256(path)
	_views[name] = {"logical_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "actual_canvas": [viewport.size.x, viewport.size.y], "actual_png_sha256": _outputs[path], "repeat_byte_exact": true, "object_count": _objects.size(), "geometry": geometry}
	viewport.queue_free(); await process_frame
	return true

func _track(path: String, expected: String = "") -> bool:
	var current: String = FileAccess.get_sha256(path)
	if not C._hash(current) or (not expected.is_empty() and current != expected): _error = "Missing/changed preview source: " + path; return false
	_inputs[path] = current; return true

func _finish(error: String) -> void:
	var changes: Array[String] = []
	for path: String in _inputs:
		if FileAccess.get_sha256(path) != _inputs[path]: changes.append(path)
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("is_checkpoint_saves_suspended") or bridge.call("is_checkpoint_saves_suspended") != true: error = "Checkpoint guard unavailable/lost; " + error
	if not changes.is_empty(): error = "Actual preview sources changed; " + error
	if not _output.is_empty() and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output)):
		var report := {"status": "PREVIEW_ONLY_NOT_ADOPTED" if error.is_empty() else "PREVIEW_FAILED", "reason": error, "scope": "Actual exported independent Sprites plus retained V5 ground/objects; no Field/Physics/actors/input/audio/formal credit", "sources_first_sha256": _inputs, "source_changes": changes, "outputs_sha256": _outputs, "views": _views, "visual_approved": false, "production_approved": false}
		var file: FileAccess = FileAccess.open(_output + "result.json", FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report, "\t", false)); file.close()
	if not error.is_empty(): push_error(error)
	quit(0 if error.is_empty() else 1)
