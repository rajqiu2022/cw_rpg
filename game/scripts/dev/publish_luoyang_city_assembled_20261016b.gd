extends SceneTree
## ROOT-only bounded CPU candidate publisher. New output directory only. This
## executes the parent complete live chain, then the explicit NEW layout; it
## neither activates runtime nor changes old files/Scene/mask/import/proofs.
const A=preload("res://scripts/city/luoyang_city_assembled_20261016b.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const LIMIT_MS:=120000
const OUT:="res://build/luoyang_city_assembled_publication_20261016b/"
var _started:=0
var _output:=""
var _error:=""
var _sources: Dictionary={}
var _rows: Array=[]
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message; push_error("[AssembledCityCandidate] "+message)
	return ok
func _budget() -> bool: return _require(Time.get_ticks_msec()-_started<LIMIT_MS,"Finite120s publication budget")
func _track(path: String,pin: String="") -> bool:
	if not _require(path.begins_with("res://") and not ".." in path and FileAccess.file_exists(path),"Missing bounded source "+path): return false
	var sha:=FileAccess.get_sha256(path)
	if not _require(sha.length()==64 and (pin.is_empty() or sha==pin) and (not _sources.has(path) or _sources[path]==sha),"Source changed "+path): return false
	_sources[path]=sha; return true
func _write(path: String,value: Dictionary) -> bool:
	if not _require(not FileAccess.file_exists(path) and path.begins_with(_output),"Refuse existing/outside output "+path): return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true
func _seventeen(p: Vector2,mask: Image) -> bool:
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var point:=Vector2i((p+offset).round())
		if point.x<0 or point.y<0 or point.x>=mask.get_width() or point.y>=mask.get_height(): return false
		var color:=mask.get_pixelv(point)
		if color.a<.5 or color.r<.5: return false
	return true
func _routes(record: Dictionary,mask: Image,solids: Array[PackedVector2Array]) -> Dictionary:
	var count:=0
	for route: Dictionary in record.routes:
		for index: int in range(route.points_px.size()-1):
			var from:=C._vec(route.points_px[index]); var to:=C._vec(route.points_px[index+1])
			var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(steps+1):
				var point:=from.lerp(to,float(step)/steps)
				if not C._safe_body_cpu(point,mask,solids) or not _seventeen(point,mask): return {"passed":false,"route":route.id,"foot_px":[point.x,point.y],"samples_before_failure":count}
				count+=1
			if not _budget(): return {"passed":false,"budget":true}
	return {"passed":true,"samples":count,"full875_and17":true,"max_step_world_px":4}
func _publish(spec: Dictionary,donors: Dictionary,token: int) -> bool:
	if not _budget(): return false
	var id:=StringName(spec.scene_id)
	var raw:=ResourceLoader.load("res://data/scenes/"+String(id)+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(raw!=null,"Parent canonical source missing"): return false
	var parent: SceneScript=await C.resolve_scene_for_live_transition(raw,token)
	if not _require(parent!=null and C.is_v3(parent),"Complete original parent chain rejected "+str(C.errors())): return false
	if not _require(await C.finalize_live_transition_sources(token,id),"Parent final complete source closure rejected"): return false
	var proof: Dictionary=C.transition_validation_state()
	# _transition_validation is the actual same-token, finalized success receipt;
	# no second effective_author_record() call that re-prepares the whole city.
	var actual_sources: Dictionary=C._transition_validation.get("sources",{})
	for path: String in actual_sources:
		if not _sources.has(path): _sources[path]=actual_sources[path]
		elif not _require(_sources[path]==actual_sources[path],"Parent source conflict "+path): return false
	var original: Dictionary=C._records.get(String(id),{}).duplicate(true)
	var record:=A.compose(original,spec,donors)
	if not _require(not record.is_empty(),"NEW explicit layout transform refused "+String(id)): return false
	for object: Dictionary in record.objects:
		if not _require(C._object_solids_valid(object),"Invalid transformed solid "+String(object.id)): return false
		var texture_path:=String(object.texture)
		var texture_pin: String=_sources.get(texture_path,String(object.get("source_sha256","")))
		if not _require(texture_pin.length()==64,"Donor texture lacks fixed source identity "+texture_path) or not _track(texture_path,texture_pin): return false
	var source:=Image.load_from_file(String(original.raw_walk_path))
	if not _require(source!=null and source.get_size()==Vector2i(3072,2048),"Original RAW support missing (never cooked walk)"): return false
	var mask:=C.raster_walk(source,record.objects)
	var solids:=C.object_solids(record.objects)
	if not _require(mask!=null,"New exact raw-minus-solids raster failed"): return false
	var route_proof:=_routes(record,mask,solids)
	if not _require(route_proof.get("passed")==true,"NEW route rejected "+JSON.stringify(route_proof)): return false
	if not _require(C._all_gameplay_safe_cpu(record,mask,solids,Callable()),"Original exact door/task/NPC feet blocked by NEW layout"): return false
	if not _budget(): return false
	var directory:=_output+String(id)+"/"
	if DirAccess.make_dir_recursive_absolute(directory)!=OK: return false
	var walk:=directory+"walk.png"
	if not _require(not FileAccess.file_exists(walk) and mask.save_png(walk)==OK,"New walk PNG save failed"): return false
	var reread:=Image.load_from_file(walk)
	if not _require(reread!=null,"New PNG readback missing"): return false
	reread.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	if not _require(reread.get_size()==mask.get_size() and reread.get_data()==mask.get_data(),"New navigation full RGBA readback differs"): return false
	record.walk_path=walk
	var scene:=A.apply_scene(parent,record,walk)
	if not _require(scene!=null,"New complete Scene materialization refused"): return false
	var layout_path:=directory+"layout.tres"; var scene_path:=directory+"scene.tres"
	var relocated: Array=[]
	for move: Dictionary in spec.get("portal_moves",[]):
		var old_room:=ResourceLoader.load(move.old_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var room:=A.derive_return_room(old_room,move)
		if not _require(room!=null,"Old full room proof/new return delta refused "+String(move.room_id)): return false
		var room_layout_path:=directory+String(move.building_id)+"_room_layout.tres"
		var room_scene_path:=directory+String(move.building_id)+"_room.tres"
		if not _require(not FileAccess.file_exists(room_layout_path) and not FileAccess.file_exists(room_scene_path),"Refuse relocated room overwrite"): return false
		if not _require(ResourceSaver.save(room.map_layout,room_layout_path)==OK,"Relocated layout save failed"): return false
		room.map_layout=ResourceLoader.load(room_layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if not _require(ResourceSaver.save(room,room_scene_path)==OK,"Relocated room save failed"): return false
		var room_read:=ResourceLoader.load(room_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not _require(room_read!=null and load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd").serialized_equal(room_read,room),"Relocated room full storage readback differs"): return false
		relocated.append({"room_id":move.room_id,"building_id":move.building_id,"city_id":String(id),"return_foot_px":move.foot_px,"scene_path":room_scene_path,"scene_sha256":FileAccess.get_sha256(room_scene_path),"layout_path":room_layout_path,"layout_sha256":FileAccess.get_sha256(room_layout_path),"old_scene_path":move.old_scene_path,"old_layout_path":move.old_layout_path})
	if not _require(not FileAccess.file_exists(layout_path) and not FileAccess.file_exists(scene_path),"Refuse candidate resource overwrite"): return false
	if not _require(ResourceSaver.save(scene.map_layout,layout_path)==OK,"Candidate layout save failed"): return false
	scene.map_layout=ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(ResourceSaver.save(scene,scene_path)==OK,"Candidate Scene save failed"): return false
	var loaded:=ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(loaded!=null and load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd").serialized_equal(loaded,scene),"Candidate full serialized storage readback differs"): return false
	var manifest: Dictionary={"status":"NEW_LAYOUT_CPU_PUBLISHED_NOT_IMPORTED_NOT_RUNTIME_NOT_FORMAL","scene_id":String(id),"author_path":A.AUTHOR_PATH,"author_sha256":A.AUTHOR_SHA,"parent_receipt":proof,"parent_identity":spec.parent_identity,"record":record,"walk_path":walk,"walk_sha256":FileAccess.get_sha256(walk),"scene_path":scene_path,"scene_sha256":FileAccess.get_sha256(scene_path),"layout_path":layout_path,"layout_sha256":FileAccess.get_sha256(layout_path),"relocated_rooms":relocated,"route_proof":route_proof,"gameplay_delta_only_declared_portals":record.gameplay_slots.npcs==original.gameplay_slots.npcs and record.gameplay_slots.interactions==original.gameplay_slots.interactions,"native_physics_not_run":true}
	if not _write(directory+"manifest.json",manifest): return false
	_rows.append({"scene_id":String(id),"manifest":directory+"manifest.json","manifest_sha256":FileAccess.get_sha256(directory+"manifest.json"),"route_proof":route_proof,"old_objects":original.objects.size(),"new_objects":record.objects.size()})
	C.end_transition_validation(token)
	return true
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec(); _output=OUT+str(OS.get_process_id())+"_"+str(_started)+"/"
	var data:=A.author()
	var ok:=_require(not data.is_empty(),"NEW author/source pins refused")
	if ok: ok=_track(A.AUTHOR_PATH,A.AUTHOR_SHA) and _track("res://scripts/city/luoyang_city_assembled_20261016b.gd") and _track("res://scripts/dev/publish_luoyang_city_assembled_20261016b.gd")
	var donors: Dictionary={}
	if ok:
		for path: String in data.source_sha256:
			if not _track(path,data.source_sha256[path]): ok=false; break
			if path.ends_with(".json"):
				var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
				if value is Dictionary: donors[path]=value
	if ok:
		for index: int in data.scenes.size():
			if not await _publish(data.scenes[index],donors,OS.get_process_id()*10+index+1): ok=false; break
	if ok:
		for path: String in _sources:
			if not _require(FileAccess.get_sha256(path)==_sources[path],"Final source changed "+path): ok=false; break
	if ok: ok=_budget()
	var result: Dictionary={"passed":ok,"error":_error,"rows":_rows,"sources":_sources,"limit_ms":LIMIT_MS,"elapsed_ms":Time.get_ticks_msec()-_started,"not_formal":true,"no_runtime_hook":true,"no_user_data_writes":true}
	if not _write(_output+"result.json",result): ok=false
	print(JSON.stringify({"passed":ok,"error":_error,"rows":_rows.size(),"output":_output,"elapsed_ms":Time.get_ticks_msec()-_started}))
	quit(0 if ok else 1)
