extends SceneTree
## ROOT-only single-domain pure-data publication; no C.prepare/full-city replay.
const P=preload("res://scripts/city/luoyang_building_spacing_20261017p.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
const DISTRICT=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const LIMIT_MS: int=60000
const OUT: String="res://build/luoyang_spacing_publication_20261017p/"
var _output: String=""
var _started: int=0
var _error: String=""
var _sources: Dictionary={}
var _report: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message; push_error("[Spacing] "+message)
	return ok
func _budget() -> bool: return _require(Time.get_ticks_msec()-_started<LIMIT_MS,"Original finite60s publication budget")
func _track(path: String,pin: String="") -> bool:
	if not _require(path.begins_with("res://") and ".." not in path and FileAccess.file_exists(path),"Source absent "+path): return false
	var sha: String=FileAccess.get_sha256(path)
	if not _require(sha.length()==64 and (pin.is_empty() or sha==pin) and (not _sources.has(path) or _sources[path]==sha),"Source changed "+path): return false
	_sources[path]=sha; return true
func _write(path: String,value: Dictionary) -> bool:
	if not path.begins_with(_output) or FileAccess.file_exists(path): return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true
func _publish() -> bool:
	var data: Dictionary=P.author()
	if not _require(not data.is_empty(),"Exact source author unavailable"): return false
	for path: String in data.source_sha256:
		if not _track(path,data.source_sha256[path]): return false
	for path: String in [P.SELF,P.AUTHOR_PATH,get_script().resource_path,"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd","res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd","res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd","res://scripts/city/luoyang_district_life_geometry_20261016f.gd"]:
		if not _track(path): return false
	var district: Dictionary=DISTRICT.binding()
	if not _require(not district.is_empty(),"Original District binding unavailable"): return false
	for path: String in DISTRICT.source_paths():
		if not _track(path,String(district.source_sha256.get(path,""))): return false
	var manifest: Dictionary=P.parent_manifest()
	if not _require(not manifest.is_empty(),"Complete frozen Harbour publication refused"): return false
	var parent_record: Dictionary=manifest.record.duplicate(true)
	var parent:=ResourceLoader.load(data.parent_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var raw: Image=Image.load_from_file(data.raw_walk_path)
	var old_mask: Image=Image.load_from_file(data.parent_walk_path)
	if not _require(parent!=null and parent.map_layout!=null and raw!=null and old_mask!=null,"Original Scene/raw/walk missing"): return false
	var old_raster: Image=C.raster_walk(raw,parent_record.objects)
	old_mask.convert(Image.FORMAT_RGBA8)
	if not _require(old_raster!=null and old_raster.get_size()==old_mask.get_size() and old_raster.get_data()==old_mask.get_data(),"Original parent raw-minus-solids fullRGBA changed"): return false
	var walk_path: String=_output+"walk.png"
	var record: Dictionary=P.compose(parent_record,walk_path)
	if not _require(not record.is_empty(),"Exact unique remove-one composition refused"): return false
	for object: Dictionary in record.objects:
		if not _require(C._object_solids_valid(object),"Invalid retained physical base "+String(object.id)): return false
	var mask: Image=C.raster_walk(raw,record.objects)
	if not _require(mask!=null,"NEW raw-minus-solids raster refused"): return false
	var audit: Dictionary=P.geometry(record,mask,parent_record,old_mask)
	_report["geometry"]=audit
	if not _require(audit.get("passed")==true,"Full original geometry or restored base/route rejected: "+JSON.stringify(audit)): return false
	var combined: Dictionary=P.combined_geometry(record,mask)
	_report["combined_geometry"]=combined
	if not _require(combined.get("passed")==true,"Current District combined full-body rejected: "+JSON.stringify(combined)): return false
	if not _budget(): return false
	if not _require(not FileAccess.file_exists(walk_path) and mask.save_png(walk_path)==OK,"New navigation write refused"): return false
	var reread: Image=Image.load_from_file(walk_path)
	if not _require(reread!=null,"New navigation readback missing"): return false
	reread.convert(Image.FORMAT_RGBA8)
	if not _require(mask.get_data()==reread.get_data(),"New full navigation RGBA readback differs"): return false
	var scene: SceneScript=P.materialize(parent,record,walk_path)
	if not _require(scene!=null,"Complete reversible Scene remove-one storage rejected"): return false
	var layout_path: String=_output+"layout.tres"; var scene_path: String=_output+"scene.tres"
	if not _require(not FileAccess.file_exists(layout_path) and ResourceSaver.save(scene.map_layout,layout_path)==OK,"New layout save failed"): return false
	scene.map_layout=ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(not FileAccess.file_exists(scene_path) and ResourceSaver.save(scene,scene_path)==OK,"New Scene save failed"): return false
	var loaded:=ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var fresh: SceneScript=P.materialize(parent,record,walk_path)
	if loaded==null or fresh==null or not SERIAL.serialized_equal(fresh,loaded):
		_write(_output+"storage_failure.json",{"record":record,"parent_record":parent_record,"fresh_scene":var_to_str(C._transition_storage(fresh)),"fresh_layout":var_to_str(C._transition_storage(fresh.map_layout)) if fresh!=null else "null","loaded_scene":var_to_str(C._transition_storage(loaded)),"loaded_layout":var_to_str(C._transition_storage(loaded.map_layout)) if loaded!=null else "null"})
		return _require(false,"Complete fresh/published all-storage differs")
	var published: Dictionary={"status":"SPACING_REMOVE_ONE_CPU_NOT_IMPORTED_NOT_RUNTIME","scene_id":String(P.ID),"author_sha256":P.AUTHOR_SHA,"parent_manifest_path":data.parent_manifest_path,"parent_manifest_sha256":data.source_sha256[data.parent_manifest_path],"parent_record":parent_record,"record":record,"walk_path":walk_path,"walk_sha256":FileAccess.get_sha256(walk_path),"walk_rgba_sha256":C._transition_bytes_sha(mask.get_data()),"scene_path":scene_path,"scene_sha256":FileAccess.get_sha256(scene_path),"layout_path":layout_path,"layout_sha256":FileAccess.get_sha256(layout_path),"geometry":audit,"combined_geometry":combined,"source_sha256":_sources.duplicate(true),"scene_scope":"Frozen Harbour publication child; runtime additionally preserves current Office/Water metadata by reversible full-storage delta, not an identical published resource_path","unchanged_npcs_interactions_portals_routes":true,"native_physics_not_run":true,"import_pending":true,"formal_enabled":false}
	if not _require(_write(_output+"manifest.json",published),"Manifest write failed"): return false
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(_output+"manifest.json"))
	if not _require(saved is Dictionary and P.equal(saved.record,record),"Full original JSON writer-domain record differs"): return false
	_report.merge({"manifest_path":_output+"manifest.json","manifest_sha256":FileAccess.get_sha256(_output+"manifest.json"),"walk_path":walk_path,"walk_sha256":published.walk_sha256,"scene_sha256":published.scene_sha256,"layout_sha256":published.layout_sha256,"removed_id":P.REMOVED,"parent_count":28,"child_count":27})
	return true
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec(); _output=OUT+str(OS.get_process_id())+"_"+str(_started)+"/"
	var ok: bool=_require(DirAccess.make_dir_recursive_absolute(_output)==OK,"New output directory refused")
	if ok: ok=_publish()
	# Failure evidence is always writable even after the first failed assertion.
	for path: String in _sources:
		if not _require(FileAccess.get_sha256(path)==_sources[path],"Final source changed "+path): ok=false
	if ok: ok=_budget()
	_report.merge({"passed":ok,"error":_error,"source_sha256":_sources,"elapsed_ms":Time.get_ticks_msec()-_started,"limit_ms":LIMIT_MS,"not_runtime":true,"not_formal":true,"no_player_writes":true})
	if not _write(_output+"result.json",_report): ok=false
	print(JSON.stringify({"passed":ok,"error":_error,"output":_output})); quit(0 if ok else 1)
