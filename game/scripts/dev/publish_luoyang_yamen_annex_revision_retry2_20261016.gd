extends SceneTree
## ROOT-only one-domain CPU publication. Original complete parent chain first.
const A=preload("res://scripts/city/luoyang_yamen_annex_revision_20261016.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_assembled_serialized_20261016b.gd")
const LIMIT_MS=90000
var _started: int=0
var _output: String=""
var _error: String=""
var _sources: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func _require(value: bool,message: String) -> bool:
	if not value and _error.is_empty(): _error=message; push_error("[AnnexRevision] "+message)
	return value
func _write(path: String,value: Dictionary) -> bool:
	if not path.begins_with(_output) or FileAccess.file_exists(path): return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true
func _publish() -> Dictionary:
	var token: int=OS.get_process_id()*10+1
	var raw:=ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(raw!=null,"Canonical Yamen missing"): return {}
	var parent: SceneScript=await C.resolve_scene_for_live_transition(raw,token)
	if not _require(parent!=null and A.OLD.bound(parent),"Complete assembled parent refused "+str(C.errors())): return {}
	if not _require(await C.finalize_live_transition_sources(token,A.ID),"Parent final source closure refused"): return {}
	_sources=C._transition_validation.sources.duplicate(true)
	_sources[A.SELF]=FileAccess.get_sha256(A.SELF)
	_sources[A.PARENT]=A.PARENT_SHA
	var self_path: String="res://scripts/dev/publish_luoyang_yamen_annex_revision_retry2_20261016.gd"
	_sources[self_path]=FileAccess.get_sha256(self_path)
	var original: Dictionary=C._records[String(A.ID)].duplicate(true)
	var record: Dictionary=A.compose(original)
	if not _require(not record.is_empty(),"Exact two-object composition refused"): return {}
	var raw_image:=Image.load_from_file(String(record.raw_walk_path))
	if not _require(raw_image!=null and raw_image.get_size()==Vector2i(3072,2048),"Original RAW support missing"): return {}
	var mask: Image=C.raster_walk(raw_image,record.objects)
	var solids: Array[PackedVector2Array]=C.object_solids(record.objects)
	if not _require(mask!=null,"Exact raw-minus-solids raster refused"): return {}
	var routes: Dictionary=A.routes_audit(record,mask,solids)
	if not routes.get("passed",false):
		_write(_output+"geometry_failure.json",{"record":record,"routes":routes})
		_require(false,"Original/new lane routes refused "+JSON.stringify(routes)); return {}
	if not _require(C._all_gameplay_safe_cpu(record,mask,solids,Callable()),"Original full87517 gameplay anchors refused"): return {}
	var walk: String=_output+"walk.png"
	if not _require(not FileAccess.file_exists(walk) and mask.save_png(walk)==OK,"NEW navigation write refused"): return {}
	var reread:=Image.load_from_file(walk)
	reread.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	if not _require(reread.get_data()==mask.get_data(),"Full navigation RGBA differs"): return {}
	record.walk_path=walk
	var scene: SceneScript=A.apply_scene(parent,record,walk)
	if not _require(scene!=null,"Native parent24 clone refused"): return {}
	if not _require(A.geometry_matches(parent,scene,record),"Two moved native polygons must exactly equal new record; other22 unchanged"): return {}
	var layout_path: String=_output+"layout.tres"
	var scene_path: String=_output+"scene.tres"
	if not _require(not FileAccess.file_exists(layout_path) and ResourceSaver.save(scene.map_layout,layout_path)==OK,"NEW layout save failed"): return {}
	scene.map_layout=ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(not FileAccess.file_exists(scene_path) and ResourceSaver.save(scene,scene_path)==OK,"NEW Scene save failed"): return {}
	var loaded:=ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(loaded!=null and SERIAL.equal(scene,loaded),"Complete native/TRES Scene differs"):
		_storage_failure(parent,record,scene,loaded,scene_path,"saved_vs_reload"); return {}
	# Independent fresh materialization vs saved resource, not only save/reload.
	var fresh:=A.apply_scene(parent,record,walk)
	if not _require(fresh!=null and SERIAL.equal(fresh,loaded),"Fresh complete Scene/TRES differs"):
		_storage_failure(parent,record,fresh,loaded,scene_path,"fresh_vs_saved"); return {}
	if not _require(C._equal_value(parent.npcs,scene.npcs) and C._equal_value(parent.map_layout.portals,scene.map_layout.portals) and C._equal_value(parent.map_layout.interactions,scene.map_layout.interactions),"Any task/NPC/portal changed"): return {}
	var row: Dictionary={"status":"YAMEN_TWO_ANNEX_CPU_NOT_IMPORTED_NOT_FORMAL","scene_id":String(A.ID),"author_sha256":FileAccess.get_sha256(A.SELF),"parent_manifest_path":A.PARENT,"parent_manifest_sha256":A.PARENT_SHA,"parent_record":original,"record":record,"walk_path":walk,"walk_sha256":FileAccess.get_sha256(walk),"layout_path":layout_path,"layout_sha256":FileAccess.get_sha256(layout_path),"scene_path":scene_path,"scene_sha256":FileAccess.get_sha256(scene_path),"routes":routes,"old_objects":24,"new_objects":24,"changed_ids":A.MOVES.keys(),"task_portal_npc_unchanged":true,"physics_not_run":true}
	if not _write(_output+"manifest.json",row): return {}
	C.end_transition_validation(token)
	return {"manifest_path":_output+"manifest.json","manifest_sha256":FileAccess.get_sha256(_output+"manifest.json"),"routes":routes}
func _storage_failure(parent: SceneScript,record: Dictionary,left: SceneScript,right: SceneScript,scene_path: String,stage: String) -> void:
	_write(_output+"storage_failure.json",{"stage":stage,"scene_path":scene_path,"parent_scene_path":parent.resource_path,"parent_record":C._records[String(A.ID)].duplicate(true),"record":record,"left_storage":C._transition_storage(left),"left_layout":C._transition_storage(left.map_layout) if left!=null else {},"right_storage":C._transition_storage(right),"right_layout":C._transition_storage(right.map_layout) if right!=null else {}})
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec()
	_output="res://build/luoyang_yamen_annex_publication_20261016/"+str(OS.get_process_id())+"_"+str(_started)+"/"
	var directory_error: Error=DirAccess.make_dir_recursive_absolute(_output)
	if directory_error!=OK: _require(false,"NEW output directory creation failed")
	var row: Dictionary=await _publish() if directory_error==OK else {}
	var ok: bool=not row.is_empty()
	for path: String in _sources:
		if not _require(FileAccess.get_sha256(path)==_sources[path],"Source changed "+path): ok=false
	if not _require(Time.get_ticks_msec()-_started<LIMIT_MS,"Finite90s publication deadline"): ok=false
	var report: Dictionary={"passed":ok,"error":_error,"row":row,"sources":_sources,"elapsed_ms":Time.get_ticks_msec()-_started,"limit_ms":LIMIT_MS,"no_formal_activation":true,"no_user_save_writes":true}
	if not _write(_output+"result.json",report): ok=false
	print(JSON.stringify({"passed":ok,"error":_error,"output":_output})); quit(0 if ok else 1)
