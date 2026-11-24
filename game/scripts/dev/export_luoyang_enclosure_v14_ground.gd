extends "res://scripts/dev/build_luoyang_modular_v3.gd"
## NEW native ground capture. Frozen support/paving/materials stay unchanged;
## remove only explicitly replaced old casters. Never paint shadows away.
const CITY = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ZONE = preload("res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd")
const DOMAIN = preload("res://scripts/dev/luoyang_ground_v14_serialized_domain.gd")
var ground_sources: Dictionary = {}
var ground_outputs: Dictionary = {}
var ground_dir := ""
var ground_region := ""
var ground_plan: Dictionary = {}
var ground_base: Dictionary = {}
var ground_casters: Array[MeshInstance3D] = []
var caster_records: Array[Dictionary] = []
var removed_casters: Array[String] = []
var new_native_casters: Array[String] = []
var zone_surface: ZONE

func _initialize() -> void: call_deferred("_ground_run")
func _ground_run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): await _ground_finish("Public checkpoint suspension unavailable"); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true: await _ground_finish("Checkpoint suspension not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args(); var tag := ""; var plan_sha := ""
	for arg: String in args:
		if arg.begins_with("--region="): ground_region = arg.trim_prefix("--region=")
		if arg.begins_with("--ground-run-tag="): tag = arg.trim_prefix("--ground-run-tag=")
		if arg.begins_with("--expected-plan-sha="): plan_sha = arg.trim_prefix("--expected-plan-sha=").to_lower()
	if not "--capture-luoyang-enclosure-v14-ground" in args or "--activate" in args or DisplayServer.get_name() == "headless" or not CITY.owns_id(StringName(ground_region)) or not tag.is_valid_identifier() or not CITY._hash(plan_sha): await _ground_finish("Explicit unique GPU ground capture and exact actual plan SHA required"); return
	ground_dir = CITY.ROOT + ground_region + "/ground_v14/" + tag + "/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ground_dir)): await _ground_finish("Existing ground evidence preserved"); return
	var base_path: String = CITY.base_manifest_path(StringName(ground_region))
	var plan_path: String = CITY.ROOT + ground_region + "/export_plan.json"
	if not _ground_track(base_path,CITY.base_manifest_sha(StringName(ground_region))) or not _ground_track(plan_path,plan_sha): await _ground_finish(error); return
	var base_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(base_path)); var plan_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not base_raw is Dictionary or not plan_raw is Dictionary: await _ground_finish("Frozen base/plan malformed"); return
	ground_base = base_raw; ground_plan = plan_raw
	if ground_plan.get("canonical_scene_id") != ground_region or ground_plan.get("base_manifest_sha256") != CITY.base_manifest_sha(StringName(ground_region)) or not ground_plan.get("remove_object_ids") is Array or not ground_plan.get("objects") is Array: await _ground_finish("Exact ground plan/base identity differs"); return
	for path: String in ground_base.asset_sha256:
		if not _ground_track(path,String(ground_base.asset_sha256[path])): await _ground_finish(error); return
	for path: String in ground_plan.source_catalog:
		if not _ground_track(path,String(ground_plan.source_catalog[path])): await _ground_finish(error); return
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_ground_v14_serialized_domain.gd","res://scripts/dev/build_luoyang_modular_v3.gd","res://scripts/dev/luoyang_modular_v3_surface.gd","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"]:
		if not _ground_track(path): await _ground_finish(error); return
	zone_surface = ZONE.new()
	var normalized: Dictionary = DOMAIN.snapshot(ground_base)
	if normalized.has("error"): await _ground_finish(String(normalized.error)); return
	if not zone_surface.configure(normalized.value) or not zone_surface.load_sources(): await _ground_finish(zone_surface.error); return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ground_dir)) != OK: await _ground_finish("Independent ground output directory failed"); return
	if not await _ground_capture(): await _ground_finish(error); return
	for path: String in ground_sources:
		if FileAccess.get_sha256(path) != ground_sources[path]: await _ground_finish("Source changed during actual ground capture: " + path); return
	var catalog: Dictionary = ground_sources.duplicate()
	# Consumer later freezes this ground manifest; no consumer-manifest SHA cycle.
	var consumer_path := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
	var executed_consumer: String = catalog[consumer_path]; catalog.erase(consumer_path)
	for path: String in ground_outputs: catalog[path] = ground_outputs[path]
	var record := {"schema_version":1,"status":"NATIVE_GROUND_GPU_CAPTURE_REQUIRES_VISUAL_FIELD_REVIEW","canonical_scene_id":ground_region,"base_manifest_path":CITY.base_manifest_path(StringName(ground_region)),"base_manifest_sha256":CITY.base_manifest_sha(StringName(ground_region)),"export_plan_path":CITY.ROOT+ground_region+"/export_plan.json","export_plan_sha256":FileAccess.get_sha256(CITY.ROOT+ground_region+"/export_plan.json"),"ground_path":ground_dir+"floor.png","asset_sha256":catalog,"executed_consumer_sha256_before_ground_freeze":executed_consumer,"requested_remove_object_ids":ground_plan.remove_object_ids,"removed_old_caster_ids":removed_casters,"added_native_caster_ids":new_native_casters,"retained_or_new_casters":caster_records,"capture_camera":ground_base.capture_camera,"actual_on_off_repeat_exact":true,"original_support_paving_material_arrays_unchanged":true,"original_vertex_contact_dirt_unchanged":true,"png_wall_proxy_casters":false,"navigation_or_height_changed":false,"production_approved":false,"visual_approved":false,"field_approved":false}
	if not _json(ground_dir+"ground_capture.json",record): await _ground_finish(error); return
	print("LUOYANG_V14_NATIVE_GROUND_ONLY " + ground_dir + "ground_capture.json SHA=" + FileAccess.get_sha256(ground_dir+"ground_capture.json"))
	await _ground_finish("")

func _ground_capture() -> bool:
	view = _viewport(SOURCE.SIZE*SSAA,false)
	var world: Node3D = _world(view,false)
	var graph: Dictionary = ground_base.capture_graph
	var support: Mesh = ResourceLoader.load(String(graph.native_support_mesh.path),"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	var paving_mesh: ArrayMesh = ResourceLoader.load(String(graph.paving_mesh.path),"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var paving_material: ShaderMaterial = ResourceLoader.load(String(graph.paving_material.path),"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if support == null or paving_mesh == null or paving_material == null: error = "Original native support/paving/material missing"; return false
	_ground_instance(world,support,zone_surface.shoulder(),Vector3.ZERO)
	_ground_instance(world,paving_mesh,paving_material,Vector3.ZERO)
	if ground_region == "ch4_s2_canal_docks":
		var bed: Mesh = ResourceLoader.load(String(graph.canal_bed_mesh.path),"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		var water: Mesh = ResourceLoader.load(String(graph.water_plane.path),"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		var quay: Mesh = ResourceLoader.load(String(graph.quay_wall_mesh.path),"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		if bed == null or water == null or quay == null: error = "Original frozen canal meshes missing"; return false
		_ground_instance(world,bed,SURFACE.plain(Color(.20,.215,.19)),Vector3.ZERO)
		_ground_instance(world,water,zone_surface.canal_water(),SOURCE.point3(Vector2((2230.+SOURCE.SIZE.x)*.5,1024),-.025))
		_ground_instance(world,quay,SURFACE.plain(Color(.31,.325,.315)),Vector3.ZERO)
	# Keep the old inn/shop low visual floor contact strips exactly; these are
	# not generated-building casters, and old vertex14px dirt is also retained.
	for object: Dictionary in ground_base.objects:
		if String(object.id) in ["inn","shop"]:
			for polygon: Array in object.solid_polygons_px:
				var left := INF; var right := -INF; var front := -INF
				for p: Array in polygon: left = minf(left,p[0]); right = maxf(right,p[0]); front = maxf(front,p[1])
				for limits: Array in [[left,float(object.world_foot_px[0])-55.],[float(object.world_foot_px[0])+55.,right]]:
					var width: float = float(limits[1])-float(limits[0])
					if width > 20.: _box(Vector3(width/SOURCE.PPM,.016,.15),SOURCE.point3(Vector2((float(limits[0])+float(limits[1]))*.5,front+2.),.004),SURFACE.plain(Color(.30,.32,.325)),world)
	var camera: Camera3D = _camera(world,SOURCE.SIZE,Vector3.ZERO)
	if not CITY._equal_value(DOMAIN.stored(_camera_data(camera,view.size,SOURCE.SIZE)),ground_base.capture_camera): error = "Fixed original6144-to3072 camera/light recipe changed"; return false
	for object: Dictionary in ground_base.objects:
		if not object.has("native_transform"): continue
		if String(object.id) in ground_plan.remove_object_ids: removed_casters.append(String(object.id)); continue
		var meta_path: String = String(object.get("metadata_path",""))
		if not ground_sources.has(meta_path): error = "Unbound old native caster metadata"; return false
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if not raw is Dictionary or not ground_sources.has(String(raw.get("native_mesh_path",""))): error = "Unbound actual old caster mesh"; return false
		var mesh: Mesh = ResourceLoader.load(String(raw.native_mesh_path),"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		var pose: Dictionary = object.native_transform
		var cols: Array = pose.basis_columns
		var basis := Basis(_ground_v3(cols[0]),_ground_v3(cols[1]),_ground_v3(cols[2]))
		if mesh == null: error = "Original actual caster mesh missing"; return false
		_ground_caster(world,String(object.id),mesh,Transform3D(basis,_ground_v3(pose.origin)),String(raw.native_mesh_path),false)
	for authored: Dictionary in ground_plan.objects:
		if authored.get("source_kind") != "actual_native_gpu_capture": continue
		var native: Dictionary = authored.original_native_record
		var mesh_path: String = String(native.native_mesh_path)
		if not ground_sources.has(mesh_path) or native.draw_transform.basis_columns != [[1.,0.,0.],[0.,1.,0.],[0.,0.,1.]] or native.draw_transform.origin_m != [0.,0.,0.] or native.local_ground_anchor_m != [0.,0.,0.]: error = "New native caster must preserve actual395 identity/G0 anchor"; return false
		var mesh: Mesh = ResourceLoader.load(mesh_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		if mesh == null: error = "Actual395 saved native caster missing"; return false
		_ground_caster(world,String(authored.id),mesh,Transform3D(Basis.IDENTITY,SOURCE.point3(CITY._vec(authored.world_foot_px))),mesh_path,true)
	await _sync()
	var off: Image = _read(view); await _sync(); var off_repeat: Image = _read(view)
	for caster: MeshInstance3D in ground_casters: caster.visible = true; caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	await _sync()
	var on: Image = _read(view); await _sync(); var on_repeat: Image = _read(view)
	if off.get_data() != off_repeat.get_data() or on.get_data() != on_repeat.get_data(): error = "Actual shadow on/off native repeat differs"; return false
	for pair: Array in [["ground_off_raw.png",off],["ground_off_raw_repeat.png",off_repeat],["ground_on_raw.png",on],["ground_on_raw_repeat.png",on_repeat]]:
		var image: Image = pair[1]; var path: String = ground_dir+String(pair[0])
		if image.save_png(path) != OK: error = "Actual ground raw PNG write failed"; return false
		ground_outputs[path] = FileAccess.get_sha256(path)
	var logical: Image = on.duplicate() as Image
	logical.resize(SOURCE.SIZE.x,SOURCE.SIZE.y,Image.INTERPOLATE_LANCZOS)
	if logical.save_png(ground_dir+"floor.png") != OK: error = "Actual ground logical PNG write failed"; return false
	ground_outputs[ground_dir+"floor.png"] = FileAccess.get_sha256(ground_dir+"floor.png")
	return true

func _ground_instance(world: Node3D, mesh: Mesh, material: Material, origin: Vector3) -> void:
	var node := MeshInstance3D.new(); node.mesh = mesh; node.material_override = material; node.position = origin
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(node)
func _ground_caster(world: Node3D, id: String, mesh: Mesh, pose: Transform3D, path: String, added: bool) -> void:
	var node := MeshInstance3D.new(); node.mesh = mesh; node.transform = pose; node.visible = false
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(node); ground_casters.append(node)
	if added: new_native_casters.append(id)
	caster_records.append({"id":id,"native_mesh_path":path,"native_mesh_sha256":ground_sources[path],"basis_columns":[_v3(pose.basis.x),_v3(pose.basis.y),_v3(pose.basis.z)],"origin_m":_v3(pose.origin),"actual_saved_mesh_only":true,"added395":added})
func _ground_v3(raw: Array) -> Vector3: return Vector3(raw[0],raw[1],raw[2])
func _ground_track(path: String, expected: String = "") -> bool:
	var sha: String = FileAccess.get_sha256(path)
	if not CITY._hash(sha) or (not expected.is_empty() and sha != expected): error = "Missing/changed frozen ground source: " + path; return false
	ground_sources[path] = sha; return true
func _ground_finish(reason: String) -> void:
	if not reason.is_empty(): push_error(reason)
	if view != null: view.queue_free(); view = null
	ground_casters.clear()
	if zone_surface != null: zone_surface.release(); zone_surface = null
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true: reason = "Checkpoint suspension lost; " + reason; push_error(reason)
	for i in range(4): await process_frame
	quit(0 if reason.is_empty() else 1)
