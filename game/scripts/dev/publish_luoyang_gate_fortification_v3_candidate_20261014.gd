extends SceneTree
## NEW A3/B3 publication. V1 publisher/manifest/captures remain immutable.
## One root-owned NEW candidate publication; never writes canonical resources.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const GATE = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const EXTRA_SOURCES := ["res://scripts/city/luoyang_gate_moat_runtime_20261013.gd","res://scripts/city/luoyang_gate_fortification_fade_20261013.gd"]
var _error := ""

func _initialize() -> void: call_deferred("_run")

func _png(path: String, image: Image) -> bool:
	if image == null or image.get_size() != Vector2i(3072,2048) or image.save_png(path) != OK: return false
	var readback := Image.load_from_file(path)
	if readback == null: return false
	readback.convert(Image.FORMAT_RGBA8); image.convert(Image.FORMAT_RGBA8)
	return readback.get_data() == image.get_data()

func _publish() -> bool:
	if not "--publish-luoyang-gate-fortification-v3" in OS.get_cmdline_user_args() or GATE.FLAG in OS.get_cmdline_user_args(): _error = "Explicit publisher only; no candidate selection while publishing"; return false
	for path: String in [GATE.MANIFEST_PATH,GATE.SCENE_PATH,GATE.LAYOUT_PATH,GATE.ROOT+"floor.png",GATE.ROOT+"walk.png"]:
		if FileAccess.file_exists(path): _error = "Refuse overwrite: "+path; return false
	var config := GATE.author(); var native := GATE.capture(config)
	if config.is_empty() or native.is_empty(): _error = "Exact author/native capture is pending or changed"; return false
	var source_scene := C.materialize(GATE.ID)
	if source_scene == null: _error = "Original complete V11 rejected: "+str(C.errors()); return false
	var old_record: Dictionary = C._records[String(GATE.ID)].duplicate(true)
	var record := GATE.compose(old_record,config,native)
	if record.is_empty(): _error = "Exact original object replacement set rejected"; return false
	for object: Dictionary in record.objects:
		if not C._object_solids_valid(object): _error = "Out-of-domain/new invalid footprint: "+str(object.get("id")); return false
	var raw := Image.load_from_file(old_record.raw_walk_path)
	var mask := C.raster_walk(raw,record.objects)
	if mask == null or not C._all_gameplay_safe_cpu(record,mask,C.object_solids(record.objects),Callable()): _error = "Original 875 body/4px routes/gameplay slots blocked"; return false
	var floor := Image.load_from_file(config.shadow_off_raw_path)
	if FileAccess.get_sha256(config.shadow_off_raw_path) != config.shadow_off_raw_sha256 or floor == null or floor.get_size() != Vector2i(6144,4096): _error = "Original OFF raw identity missing"; return false
	floor.resize(3072,2048,Image.INTERPOLATE_LANCZOS); floor.convert(Image.FORMAT_RGBA8)
	for directory: String in [GATE.ROOT,GATE.SCENE_PATH.get_base_dir(),GATE.LAYOUT_PATH.get_base_dir()]:
		if DirAccess.make_dir_recursive_absolute(directory) != OK: _error = "Candidate directory creation failed"; return false
	if not _png(record.ground_path,floor) or not _png(record.walk_path,mask): _error = "Exact logical floor/walk saved readback differs"; return false
	if not GATE.BASE._hash(config.get("expected_walk_sha256")) or FileAccess.get_sha256(record.walk_path) != config.expected_walk_sha256: _error = "A3/B3 navigation SHA differs from original Gate walk"; return false
	var catalog: Dictionary = config.source_sha256.duplicate(true)
	catalog[config.shadow_off_raw_path] = config.shadow_off_raw_sha256
	for kind: String in ["wall","tower"]:
		var capture_pin: Dictionary = config.native_captures[kind]
		catalog[capture_pin.path] = capture_pin.sha256
	for path: String in native.source_catalog.sha256_by_res_path: catalog[path] = native.source_catalog.sha256_by_res_path[path]
	for kind: String in ["wall","tower"]:
		catalog[native[kind].texture_path] = native[kind].texture_sha256
		catalog[native[kind].mesh_path] = native[kind].mesh_sha256
	for path: String in EXTRA_SOURCES + [record.ground_path,record.walk_path]: catalog[path] = FileAccess.get_sha256(path)
	for object: Dictionary in record.objects:
		var path: String = object.texture
		if not catalog.has(path): catalog[path] = FileAccess.get_sha256(path)
	for path: Variant in catalog:
		if not GATE._source(path,catalog[path]): _error = "Candidate source catalog changed: "+str(path); return false
	var manifest := {"schema_version":1,"scene_id":String(GATE.ID),"status":"PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA","author_path":GATE.AUTHOR_PATH,"author_sha256":GATE.AUTHOR_SHA,"native_captures":config.native_captures.duplicate(true),"expected_walk_sha256":config.expected_walk_sha256,"asset_sha256":catalog,"objects":record.objects,"gameplay_slots":record.gameplay_slots,"routes":record.routes,"entry_foot_px":record.entry_foot_px,"return_foot_px":record.return_foot_px,"ground_path":record.ground_path,"walk_path":record.walk_path,"background_derivation":{"source_raw":config.shadow_off_raw_path,"source_sha256":config.shadow_off_raw_sha256,"raw_size_px":[6144,4096],"logical_size_px":[3072,2048],"interpolation":"Image.INTERPOLATE_LANCZOS","new_caster_approval":false},"formal_activated":false,"real_field_qa":"PENDING"}
	var file := FileAccess.open(GATE.MANIFEST_PATH,FileAccess.WRITE)
	if file == null: _error = "Cannot write candidate manifest"; return false
	file.store_string(JSON.stringify(manifest,"\t",true,true)); file.close()
	var sha := FileAccess.get_sha256(GATE.MANIFEST_PATH)
	# Do not rewrite the contract's PENDING pin. Root reviews this actual artifact,
	# then SYSTEM binds that exact SHA before any real Field selection is allowed.
	var scene: SceneScript = C.BASE._independent_copy(source_scene)
	scene.map_layout.visual_objects.clear()
	for authored: Dictionary in record.objects:
		var entry := authored.duplicate(true)
		var foot := C._vec(authored.world_foot_px); var render := C._vec(authored.render_size_px)
		entry.pos = (foot+(Vector2(.5,.5)-C._vec(authored.foot_uv))*render)/C.SIZE
		entry.render_size_px = render; entry.centered = true; entry.sort_by_feet = authored.get("role","") != "ground_overlay"
		if not entry.sort_by_feet: entry.z_index = -2; entry.ghost_occlusion = false
		entry.depth_sort_foot_y = foot.y/C.SIZE.y
		entry.city_v3_solid_polygons_px = authored.solid_polygons_px.duplicate(true); entry.erase("solid_polygons_px")
		GATE.apply_entry(entry,authored); scene.map_layout.visual_objects.append(entry)
	scene.background_path = record.ground_path; scene.map_layout.walkable_mask_path = record.walk_path
	scene.set_meta(GATE.META,sha)
	if not C.semantic_fidelity(scene) or ResourceSaver.save(scene.map_layout,GATE.LAYOUT_PATH) != OK: _error = "Candidate layout/semantic save failed"; return false
	var expected: SceneScript = C.BASE._independent_copy(scene)
	scene.map_layout = ResourceLoader.load(GATE.LAYOUT_PATH,"",ResourceLoader.CACHE_MODE_IGNORE)
	if ResourceSaver.save(scene,GATE.SCENE_PATH) != OK: _error = "Candidate scene save failed"; return false
	var saved: SceneScript = ResourceLoader.load(GATE.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE)
	if not C._runtime_matches_expected(saved,expected): _error = "Candidate serialized full spatial fidelity rejected: "+str(C.errors()); return false
	for path: String in catalog:
		if FileAccess.get_sha256(path) != catalog[path]: _error = "Publisher final exact source changed"; return false
	print("GATE_FORTIFICATION_CANDIDATE_PUBLISHED "+JSON.stringify({"manifest_path":GATE.MANIFEST_PATH,"manifest_sha256":sha,"scene_path":GATE.SCENE_PATH,"scene_sha256":FileAccess.get_sha256(GATE.SCENE_PATH),"layout_path":GATE.LAYOUT_PATH,"layout_sha256":FileAccess.get_sha256(GATE.LAYOUT_PATH),"object_count":record.objects.size(),"walk_sha256":FileAccess.get_sha256(record.walk_path),"asset_revision":"A3_WALL_B3_TOWER_ACTUAL_FEET","scope":"SOURCE_ASSEMBLED_NOT_FIELD_OR_FORMAL","errors":[]}))
	return true

func _run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("Gate publisher: public checkpoint suspension unavailable"); quit(1); return
	var previous: bool = bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		bridge.call("set_checkpoint_saves_suspended",previous)
		push_error("Gate publisher: checkpoint suspension refused"); quit(1); return
	var ok := _publish()
	bridge.call("set_checkpoint_saves_suspended",previous)
	if bridge.call("is_checkpoint_saves_suspended") != previous: ok = false; _error = "Checkpoint state restore refused"
	if not ok: push_error("Gate publisher: "+_error)
	quit(0 if ok else 1)
