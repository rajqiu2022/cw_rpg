extends SceneTree
## ROOT-only, two-domain120s CPU publisher; all outputs NEW and non-runtime.
const A=preload("res://scripts/city/luoyang_harbour_life_author_retry3_20261016.gd")
const G=preload("res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd")
const CROWD=preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
const LIMIT_MS=120000
const OUT="res://build/luoyang_harbour_life_publication_20261016/"
var _started: int=0
var _output: String=""
var _error: String=""
var _sources: Dictionary={}
var _rows: Array=[]
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message; push_error("[HarbourLife] "+message)
	return ok
func _budget() -> bool: return _require(Time.get_ticks_msec()-_started<LIMIT_MS,"Original finite120s publication budget")
func _track(path: String,pin: String="") -> bool:
	if not _require(path.begins_with("res://") and ".." not in path and FileAccess.file_exists(path),"Missing source "+path): return false
	var sha:=FileAccess.get_sha256(path)
	if not _require(sha.length()==64 and (pin.is_empty() or sha==pin) and (not _sources.has(path) or _sources[path]==sha),"Source changed "+path): return false
	_sources[path]=sha; return true
func _write(path: String,data: Dictionary) -> bool:
	if not _require(path.begins_with(_output) and not FileAccess.file_exists(path),"Existing/outside publication refused"): return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true)); file.close(); return true
func _publish(id: StringName,token: int) -> bool:
	if not _budget(): return false
	var canonical:="res://data/scenes/"+String(id)+".tres"
	var raw:=ResourceLoader.load(canonical,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var parent: SceneScript=await C.resolve_scene_for_live_transition(raw,token)
	if not _require(parent!=null and C.is_v3(parent),"Original full parent refused "+str(C.errors())): return false
	if not _require(await C.finalize_live_transition_sources(token,id),"Original same-token complete final SHA refused"): return false
	for path: String in C._transition_validation.sources:
		if not _track(path,C._transition_validation.sources[path]): return false
	var original: Dictionary=C._records[String(id)].duplicate(true)
	var record:=A.compose(original,id)
	if not _require(not record.is_empty(),"NEW explicit composition refused "+String(id)): return false
	for object: Dictionary in record.objects:
		if not _require(C._object_solids_valid(object),"Invalid independent physical base "+String(object.id)): return false
		if not _track(String(object.texture),String(object.get("source_sha256",""))): return false
	var support:=Image.load_from_file(String(original.raw_walk_path))
	if not _require(support!=null and support.get_size()==Vector2i(C.SIZE),"Original raw support unavailable"): return false
	var mask:=C.raster_walk(support,record.objects); var solids:=C.object_solids(record.objects)
	if not _require(mask!=null,"Exact raw-minus-solids raster refused"): return false
	var audit:=G.audit(record,mask)
	var directory:=_output+String(id)+"/"
	if audit.get("passed")!=true or not C._all_gameplay_safe_cpu(record,mask,solids,Callable()):
		_write(directory+"geometry_failure.json",{"record":record,"parent":original,"audit":audit,"not_formal":true})
		return _require(false,"NEW complete route/gameplay/crowd body refused "+JSON.stringify(audit))
	if not _budget(): return false
	if DirAccess.make_dir_recursive_absolute(directory)!=OK: return false
	var walk:=directory+"walk.png"
	if not _require(not FileAccess.file_exists(walk) and mask.save_png(walk)==OK,"NEW navigation save refused"): return false
	var reread:=Image.load_from_file(walk)
	if not _require(reread!=null,"NEW navigation readback missing"): return false
	reread.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	if not _require(mask.get_size()==reread.get_size() and mask.get_data()==reread.get_data(),"Full navigation RGBA readback differs"): return false
	record.walk_path=walk
	var scene:=A.apply_scene(parent,record,walk)
	if not _require(scene!=null and C._equal_value(scene.npcs,parent.npcs) and C._equal_value(scene.map_layout.portals,parent.map_layout.portals) and C._equal_value(scene.map_layout.interactions,parent.map_layout.interactions),"Original NPC/task/portal values changed"): return false
	var layout_path:=directory+"layout.tres"; var scene_path:=directory+"scene.tres"
	if not _require(not FileAccess.file_exists(layout_path) and not FileAccess.file_exists(scene_path),"Refuse Scene/layout overwrite"): return false
	if not _require(ResourceSaver.save(scene.map_layout,layout_path)==OK,"NEW layout save failed"): return false
	scene.map_layout=ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(ResourceSaver.save(scene,scene_path)==OK,"NEW Scene save failed"): return false
	var loaded:=ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(loaded!=null and SERIAL.serialized_equal(loaded,scene),"Complete Scene/storage readback differs"): return false
	# Also test a fresh recomposition against saved text BEFORE any runtime GPU.
	var fresh:=A.apply_scene(parent,record,walk)
	if not SERIAL.serialized_equal(fresh,loaded):
		_write(directory+"storage_failure.json",{"parent_record":original,"record":record,"fresh_scene_storage":var_to_str(C._transition_storage(fresh)),"fresh_layout_storage":var_to_str(C._transition_storage(fresh.map_layout)),"read_scene_storage":var_to_str(C._transition_storage(loaded)),"read_layout_storage":var_to_str(C._transition_storage(loaded.map_layout))})
		return _require(false,"Fresh native complete Scene versus publication differs")
	var manifest: Dictionary={"status":"HARBOUR_CPU_CANDIDATE_NOT_IMPORTED_NOT_RUNTIME_NOT_FORMAL","scene_id":String(id),"author_sha256":A.author_sha(),"parent_canonical_path":canonical,"parent_canonical_sha256":FileAccess.get_sha256(canonical),"parent_record":original,"record":record,"parent_receipt":C.transition_validation_state(),"walk_path":walk,"walk_sha256":FileAccess.get_sha256(walk),"layout_path":layout_path,"layout_sha256":FileAccess.get_sha256(layout_path),"scene_path":scene_path,"scene_sha256":FileAccess.get_sha256(scene_path),"geometry_audit":audit,"crowd":CROWD.spec(id),"original_gameplay_unchanged":true,"native_physics_not_run":true}
	if not _write(directory+"manifest.json",manifest): return false
	# Verify the actual full-precision JSON writer domain, without mutating native
	# geometry or permitting any numerical tolerance, dropped field or missingkey.
	var wire: Variant=JSON.parse_string(JSON.stringify(record,"\t",true,true))
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(directory+"manifest.json"))
	if not _require(wire is Dictionary and saved is Dictionary and C._equal_value(wire,saved.record),"Exact original JSON writer-domain full record mismatch"): return false
	_rows.append({"scene_id":String(id),"manifest_path":directory+"manifest.json","manifest_sha256":FileAccess.get_sha256(directory+"manifest.json"),"old_objects":original.objects.size(),"new_objects":record.objects.size(),"audit":audit})
	C.end_transition_validation(token); return true
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec(); _output=OUT+str(OS.get_process_id())+"_"+str(_started)+"/"
	var ok:=_require(A.sources_valid(),"NEW author fixed source package refused")
	for path: String in [A.PATH,"res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd","res://scripts/dev/publish_luoyang_harbour_life_retry3_20261016.gd"]:
		if ok: ok=_track(path)
	for path: String in A.PINS:
		if ok: ok=_track(path,A.PINS[path])
	for path: String in CROWD.source_paths():
		if ok: ok=_track(path)
	if ok:
		for index: int in A.IDS.size():
			if not await _publish(A.IDS[index],OS.get_process_id()*10+index+1): ok=false; break
	if ok:
		for path: String in _sources:
			if not _require(FileAccess.get_sha256(path)==_sources[path],"Final source changed "+path): ok=false; break
	if ok: ok=_budget()
	var result: Dictionary={"passed":ok,"error":_error,"rows":_rows,"source_sha256":_sources,"limit_ms":LIMIT_MS,"elapsed_ms":Time.get_ticks_msec()-_started,"not_runtime":true,"not_formal":true,"no_player_writes":true}
	if not _write(_output+"result.json",result): ok=false
	print(JSON.stringify({"passed":ok,"error":_error,"output":_output,"rows":_rows.size()})); quit(0 if ok else 1)
