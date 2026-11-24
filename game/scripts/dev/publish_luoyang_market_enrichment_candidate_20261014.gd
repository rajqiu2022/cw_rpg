extends SceneTree
## Root-owned one publication. Writes ONLY new market candidate artifacts.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const MARKET = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
var _error := ""

func _initialize() -> void: call_deferred("_run")

func _publish() -> bool:
	if not "--publish-luoyang-market-enrichment-v1" in OS.get_cmdline_user_args() or MARKET.FLAG in OS.get_cmdline_user_args(): _error = "Explicit publisher only; no candidate flag while publishing"; return false
	for path: String in [MARKET.MANIFEST_PATH,MARKET.SCENE_PATH,MARKET.LAYOUT_PATH,MARKET.ROOT+"walk.png"]:
		if FileAccess.file_exists(path): _error = "Refuse overwrite: "+path; return false
	var config := MARKET.author()
	if config.is_empty(): _error = "Exact market author/source changed"; return false
	var old_scene := C.materialize(MARKET.ID)
	if old_scene == null: _error = "Original complete enclosure rejected: "+str(C.errors()); return false
	var original: Dictionary = C._records[String(MARKET.ID)].duplicate(true)
	var record := MARKET.compose(original,config)
	if record.is_empty() or record.objects.size() != 26: _error = "Exact original16 plus new10 composition rejected"; return false
	for object: Dictionary in record.objects:
		if not C._object_solids_valid(object): _error = "Invalid footprint: "+str(object.id); return false
	var raw := Image.load_from_file(original.raw_walk_path)
	var mask := C.raster_walk(raw,record.objects)
	if mask == null or not C._all_gameplay_safe_cpu(record,mask,C.object_solids(record.objects),Callable()): _error = "Original 875body/4px routes/gameplay blocked"; return false
	for directory: String in [MARKET.ROOT,MARKET.SCENE_PATH.get_base_dir(),MARKET.LAYOUT_PATH.get_base_dir()]:
		if DirAccess.make_dir_recursive_absolute(directory) != OK: _error = "Candidate directory creation failed"; return false
	if mask.save_png(record.walk_path) != OK: _error = "Cannot save independent walk"; return false
	var readback := Image.load_from_file(record.walk_path)
	if readback == null: _error = "Walk readback missing"; return false
	readback.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	if readback.get_data() != mask.get_data(): _error = "Walk saved pixels changed"; return false
	var catalog: Dictionary = config.source_sha256.duplicate(true)
	for path: String in [record.walk_path,original.walk_path,original.ground_path,original.raw_walk_path,"res://scripts/city/luoyang_market_enrichment_fade_20261014.gd"]: catalog[path] = FileAccess.get_sha256(path)
	for object: Dictionary in record.objects: catalog[object.texture] = FileAccess.get_sha256(object.texture)
	for path: Variant in catalog:
		if not MARKET._source(path,catalog[path]): _error = "Changed market source "+str(path); return false
	var manifest := {"schema_version":1,"scene_id":String(MARKET.ID),"status":"PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA","author_path":MARKET.AUTHOR_PATH,"author_sha256":MARKET.AUTHOR_SHA,"asset_sha256":catalog,"objects":record.objects,"gameplay_slots":original.gameplay_slots,"routes":original.routes,"entry_foot_px":original.entry_foot_px,"return_foot_px":original.return_foot_px,"ground_path":original.ground_path,"walk_path":record.walk_path,"add_ids":MARKET.ADD_IDS,"building_ids":MARKET.NEW_BUILDINGS,"added_npcs":0,"added_portals":0,"formal_activated":false,"real_field_qa":"PENDING"}
	var file := FileAccess.open(MARKET.MANIFEST_PATH,FileAccess.WRITE)
	if file == null: _error = "Cannot write candidate manifest"; return false
	file.store_string(JSON.stringify(manifest,"\t",true,true)); file.close()
	var sha := FileAccess.get_sha256(MARKET.MANIFEST_PATH)
	var scene: SceneScript = C.BASE._independent_copy(old_scene)
	scene.map_layout.visual_objects.clear()
	for authored: Dictionary in record.objects:
		var entry := authored.duplicate(true)
		var foot := C._vec(authored.world_foot_px); var render := C._vec(authored.render_size_px)
		entry.pos = (foot+(Vector2(.5,.5)-C._vec(authored.foot_uv))*render)/C.SIZE
		entry.render_size_px = render; entry.centered = true; entry.sort_by_feet = authored.get("role","") != "ground_overlay"
		if not entry.sort_by_feet: entry.z_index = -2; entry.ghost_occlusion = false
		entry.depth_sort_foot_y = foot.y/C.SIZE.y
		entry.city_v3_solid_polygons_px = authored.solid_polygons_px.duplicate(true); entry.erase("solid_polygons_px")
		scene.map_layout.visual_objects.append(entry)
	scene.map_layout.walkable_mask_path = record.walk_path
	scene.set_meta(MARKET.META,sha)
	if not C.semantic_fidelity(scene) or ResourceSaver.save(scene.map_layout,MARKET.LAYOUT_PATH) != OK: _error = "Candidate spatial/semantic save failed"; return false
	var expected: SceneScript = C.BASE._independent_copy(scene)
	scene.map_layout = ResourceLoader.load(MARKET.LAYOUT_PATH,"",ResourceLoader.CACHE_MODE_IGNORE)
	if scene.map_layout == null or ResourceSaver.save(scene,MARKET.SCENE_PATH) != OK: _error = "Candidate scene save failed"; return false
	var saved := ResourceLoader.load(MARKET.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if saved == null or not C._runtime_matches_expected(saved,expected): _error = "Candidate serialized spatial fidelity rejected: "+str(C.errors()); return false
	for path: String in catalog:
		if FileAccess.get_sha256(path) != catalog[path]: _error = "Publisher final source changed"; return false
	print("MARKET_ENRICHMENT_CANDIDATE_PUBLISHED "+JSON.stringify({"manifest_path":MARKET.MANIFEST_PATH,"manifest_sha256":sha,"scene_path":MARKET.SCENE_PATH,"scene_sha256":FileAccess.get_sha256(MARKET.SCENE_PATH),"layout_path":MARKET.LAYOUT_PATH,"layout_sha256":FileAccess.get_sha256(MARKET.LAYOUT_PATH),"objects":26,"additions":10,"new_buildings":4,"walk_sha256":FileAccess.get_sha256(record.walk_path),"scope":"SOURCE_ASSEMBLED_NOT_FIELD_OR_FORMAL"}))
	return true

func _run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): push_error("Market publisher checkpoint API unavailable"); quit(1); return
	var previous: bool = bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true: bridge.call("set_checkpoint_saves_suspended",previous); push_error("Market publisher checkpoint suspension refused"); quit(1); return
	var ok := _publish()
	bridge.call("set_checkpoint_saves_suspended",previous)
	if bridge.call("is_checkpoint_saves_suspended") != previous: ok = false; _error = "Checkpoint state restore refused"
	if not ok: push_error("Market publisher: "+_error)
	quit(0 if ok else 1)
