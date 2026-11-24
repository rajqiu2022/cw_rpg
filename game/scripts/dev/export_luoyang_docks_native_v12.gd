extends "res://scripts/dev/build_luoyang_modular_v3.gd"
## NEW native source capture only. Inherited camera/environment/alpha sampler
## are frozen utilities; never call the original publisher/run/finish.
const AUTHOR = preload("res://scripts/dev/luoyang_docks_native_structures_v12_preview.gd")
const AUTHOR_PATH := "res://scripts/dev/luoyang_docks_native_structures_v12_preview.gd"
const AUTHOR_SHA := "845b0683567c6156967d25293096f791a6f8744e206ce61e59834e6f5ebe44e4"
const FROZEN_CAPTURE := "res://scripts/dev/build_luoyang_modular_v3.gd"
const FROZEN_CAPTURE_SHA := "3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30"
const FROZEN_SOURCE_SHA := "3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5"
const FROZEN_SURFACE_SHA := "76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52"
const NATIVE_ROOT := "res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/native_v12/"
var native_author: AUTHOR
var native_dir := ""
var native_sources: Dictionary = {}
var native_outputs: Dictionary = {}
var native_records: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_native_run")
func _native_run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): await _native_finish("Public checkpoint suspension unavailable"); return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true: await _native_finish("Checkpoint suspension not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--native-run-tag="): tag = arg.trim_prefix("--native-run-tag=")
	if not "--capture-luoyang-docks-native-v12" in args or "--activate" in args or "--publish-candidate" in args or tag.is_empty() or not tag.is_valid_identifier(): await _native_finish("Explicit unique native capture only"); return
	if DisplayServer.get_name() == "headless": await _native_finish("Native art requires actual GPU"); return
	native_dir = NATIVE_ROOT + tag + "/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(native_dir)): await _native_finish("Existing capture preserved; choose NEW run tag"); return
	native_sources = {AUTHOR_PATH: AUTHOR_SHA, FROZEN_CAPTURE: FROZEN_CAPTURE_SHA, "res://scripts/dev/luoyang_modular_v3_source.gd": FROZEN_SOURCE_SHA, "res://scripts/dev/luoyang_modular_v3_surface.gd": FROZEN_SURFACE_SHA, AUTHOR.BOX_SOURCE: AUTHOR.BOX_SHA, get_script().resource_path: FileAccess.get_sha256(get_script().resource_path)}
	if not _native_sources_same(): await _native_finish("Frozen native capture inputs changed"); return
	native_author = AUTHOR.new()
	if not native_author.prepare(): await _native_finish(native_author.error); return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(native_dir)) != OK: await _native_finish("Independent native directory failed"); return
	for spec: Dictionary in native_author.author_native_specs():
		if not await _native_capture(spec): await _native_finish(error); return
	if not _native_sources_same(): await _native_finish("Sources changed during actual GPU capture"); return
	var report := {"schema_version": 1, "status": "NATIVE_GPU_CAPTURE_REQUIRES_VISUAL_FIELD_REVIEW", "canonical_scene_id": "ch4_s2_canal_docks", "source_catalog": native_sources, "asset_sha256": native_outputs, "objects": native_records, "existing_cargo_records": native_author.existing_cargo_records(), "source_bitmap_modified": false, "original_geometry_used_without_reauthoring": true, "alpha_bbox_is_not_physical_anchor": true, "production_approved": false, "visual_approved": false, "field_approved": false}
	if not _json(native_dir + "native_capture.json", report): await _native_finish(error); return
	print("LUOYANG_DOCKS_NATIVE_V12_GPU_ONLY " + native_dir + "native_capture.json SHA=" + FileAccess.get_sha256(native_dir + "native_capture.json"))
	await _native_finish("")

func _native_capture(spec: Dictionary) -> bool:
	var mesh: ArrayMesh = native_author.call(String(spec.method)) as ArrayMesh
	if mesh == null or not native_author.error.is_empty(): error = native_author.error; return false
	var counts: Dictionary = native_author.component_counts.duplicate(true)
	var bounds: Dictionary = _bounds(mesh, Basis.IDENTITY)
	if bounds.is_empty(): return false
	# Explicit authored origin, not inferred lowest/front vertices or alpha bottom.
	var anchor := Vector3(spec.local_ground_anchor_m[0], spec.local_ground_anchor_m[1], spec.local_ground_anchor_m[2])
	if not anchor.is_finite(): error = "Native semantic anchor invalid"; return false
	view = _viewport(Vector2i(1536,1536), true)
	var world: Node3D = _world(view, true)
	var body := MeshInstance3D.new()
	body.mesh = mesh; body.transform = Transform3D.IDENTITY
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera: Camera3D = _camera(world, Vector2i(768,768), Vector3(0,1.6,0))
	await _sync()
	var raw: Image = _read(view)
	await _sync()
	var repeat: Image = _read(view)
	if raw.get_size() != Vector2i(1536,1536) or raw.get_data() != repeat.get_data(): error = "Actual native readback repeat differs"; return false
	var logical: Image = _alpha_resize(raw, Vector2i(768,768))
	var used: Rect2i = logical.get_used_rect()
	var projected: Vector2 = camera.unproject_position(body.to_global(anchor)) / SSAA
	if used.size == Vector2i.ZERO or not Rect2i(4,4,760,760).encloses(used) or not Rect2(4,4,760,760).has_point(projected): error = "Native body/anchor empty or clipped"; return false
	var anchor_rect := Rect2i(Vector2i(floori(projected.x),floori(projected.y)),Vector2i.ONE)
	var crop: Rect2i = used.merge(anchor_rect).grow(4)
	var image: Image = logical.get_region(crop)
	var foot: Vector2 = projected - Vector2(crop.position)
	var prefix: String = native_dir + String(spec.id)
	var mesh_path: String = prefix + ".res"
	for pair: Array in [[prefix + "_raw.png",raw],[prefix + "_raw_repeat.png",repeat],[prefix + ".png",image]]:
		var output: Image = pair[1]
		if output.save_png(pair[0]) != OK: error = "Actual native PNG write failed"; return false
		native_outputs[pair[0]] = FileAccess.get_sha256(pair[0])
	if ResourceSaver.save(mesh,mesh_path) != OK: error = "Native mesh save failed"; return false
	native_outputs[mesh_path] = FileAccess.get_sha256(mesh_path)
	var saved_mesh: ArrayMesh = ResourceLoader.load(mesh_path,"ArrayMesh",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if saved_mesh == null or _geometry_array_evidence(saved_mesh) != _geometry_array_evidence(mesh): error = "Actual saved native draw arrays changed"; return false
	var record: Dictionary = spec.duplicate(true)
	record.merge({"texture": prefix + ".png", "source_sha256": native_outputs[prefix + ".png"], "source_size_px": [image.get_width(),image.get_height()], "render_size_px": [image.get_width(),image.get_height()], "foot_uv": [foot.x/image.get_width(),foot.y/image.get_height()], "world_origin_px": [float(spec.world_foot_px[0])-foot.x,float(spec.world_foot_px[1])-foot.y], "depth_foot_y": spec.world_foot_px[1], "raw_camera": _camera_data(camera,view.size,Vector2i(768,768)), "local_ground_anchor_m": _v3(anchor), "projected_semantic_anchor_px": [projected.x,projected.y], "crop_rect_px": [crop.position.x,crop.position.y,crop.size.x,crop.size.y], "actual_alpha_bounds_px": [used.position.x,used.position.y,used.size.x,used.size.y], "used_bounds_m": {"minimum": _v3(bounds.minimum),"maximum": _v3(bounds.maximum)}, "actual_used_vertices": bounds.actual_used_vertices, "geometry_array_evidence": _geometry_array_evidence(mesh), "component_counts": counts, "native_mesh_path": mesh_path, "draw_transform": {"basis_columns": [_v3(body.basis.x),_v3(body.basis.y),_v3(body.basis.z)],"origin_m": _v3(body.position)}, "repeat_byte_exact": true, "crop_includes_authored_anchor": true, "alpha_resampling_algorithm": "RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1", "material_provenance": "Project original procedural timber/canvas/iron authoring, not a CC0 scan or imported native asset", "collision_size_px": [0,0]},true)
	if not _json(prefix + ".json",record): return false
	native_outputs[prefix + ".json"] = FileAccess.get_sha256(prefix + ".json")
	native_records.append(record)
	view.queue_free(); view = null
	await _sync()
	return true

func _native_sources_same() -> bool:
	for path: String in native_sources:
		if FileAccess.get_sha256(path) != native_sources[path]: return false
	return true
func _native_finish(failure: String) -> void:
	if not failure.is_empty(): push_error(failure)
	if view != null: view.queue_free(); view = null
	if native_author != null: native_author.release(); native_author = null
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		failure = "Checkpoint suspension lost before quit"; push_error(failure)
	for i in range(4): await process_frame
	quit(0 if failure.is_empty() else 1)
