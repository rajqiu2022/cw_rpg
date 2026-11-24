extends SceneTree
## ROOT-only finite candidate publisher. No canonical writes or runtime hook.
const R = preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
const C = R.C
const OUTPUT_ROOT := "res://build/luoyang_city_revision_publication_retry2_20261015/"
const MAP_ROOT := "res://data/maps/luoyang_city_revision_candidates_retry2_20261015/"
const SCENE_ROOT := "res://data/scenes/luoyang_city_revision_candidates_retry2_20261015/"
var _error:=""
var _inputs: Dictionary={}
var _rows: Array[Dictionary]=[]
var _output:=""
var _started:=0

func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,message: String) -> bool:
	if not ok: _error=message; push_error("[CityRevisionCandidate] "+message)
	return ok
func _track(path: String,expected: String="") -> bool:
	if not _require(FileAccess.file_exists(path),"Missing exact source "+path): return false
	var sha:=FileAccess.get_sha256(path)
	if not _require(sha.length()==64 and (expected.is_empty() or sha.to_lower()==expected.to_lower()),"Changed exact source "+path): return false
	if not _require(not _inputs.has(path) or _inputs[path]==sha,"Conflicting source identity "+path): return false
	_inputs[path]=sha; return true
func _write(path: String,value: Dictionary) -> bool:
	if not _require(not FileAccess.file_exists(path),"Refuse overwrite "+path): return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true

func _seventeen(point: Vector2,image: Image,solids: Array[PackedVector2Array]) -> bool:
	var offsets:=PackedVector2Array([Vector2.ZERO])
	for i in 16: offsets.append(Vector2(cos(TAU*i/16.0)*10,sin(TAU*i/16.0)*6))
	for offset: Vector2 in offsets:
		var foot:=point+offset
		var pixel:=Vector2i(roundi(foot.x),roundi(foot.y))
		if pixel.x<0 or pixel.y<0 or pixel.x>=image.get_width() or pixel.y>=image.get_height(): return false
		var color:=image.get_pixelv(pixel)
		if color.r<.5 or color.a<.5: return false
		for polygon: PackedVector2Array in solids:
			if Geometry2D.is_point_in_polygon(foot,polygon): return false
	return true

func _routes_proof(record: Dictionary,mask: Image,solids: Array[PackedVector2Array]) -> Dictionary:
	var samples:=0; var routes: Array[Dictionary]=[]
	for route: Dictionary in record.routes:
		var count:=0
		for index in range(route.points_px.size()-1):
			var a:=C._vec(route.points_px[index]); var b:=C._vec(route.points_px[index+1])
			var steps:=maxi(1,ceili(a.distance_to(b)/4.0))
			for step in range(steps+1):
				var foot:=a.lerp(b,float(step)/float(steps))
				if not C._safe_body_cpu(foot,mask,solids) or not _seventeen(foot,mask,solids): return {"passed":false,"route":route.id,"foot_px":[foot.x,foot.y],"failure":"Exact875+17 original4px route rejected"}
				count+=1; samples+=1
		routes.append({"id":route.id,"samples":count,"full875_and17":true})
	return {"passed":true,"samples":samples,"routes":routes,"max_step_px":4.0,"Physics_not_run":true}

func _publish_scene(spec: Dictionary,home: Dictionary) -> bool:
	if not _require(Time.get_ticks_msec()-_started<180000,"Finite180s candidate publication budget"): return false
	var id:=StringName(spec.scene_id)
	var canonical_path:="res://data/scenes/"+String(id)+".tres"
	if not _track(canonical_path) or not _track(spec.parent_manifest_path,spec.parent_manifest_sha256): return false
	var raw:=ResourceLoader.load(canonical_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(raw!=null and raw.map_layout!=null and _track(raw.map_layout.resource_path),"Exact original canonical scene/layout"): return false
	# Fully execute the current original enclosure and its Gate/Market third
	# layer. A prepared cache or source hash alone does not authorize a record.
	var original_scene: SceneScript=C.resolve_scene(raw)
	if not _require(original_scene!=null and C.is_v3(original_scene),"Original full city rejected: "+str(C.errors())): return false
	var original: Dictionary=C._records.get(String(id),{}).duplicate(true)
	if not _require(not original.is_empty(),"Original full city record unavailable"): return false
	var closure: Dictionary=C._transition_sources(raw)
	if not _require(not closure.is_empty(),"Original complete import/source closure unavailable"): return false
	for path: String in closure:
		if not _track(path,closure[path]): return false
	for path: String in original.asset_sha256:
		if not _track(path,original.asset_sha256[path]): return false
	var record:=R.compose(original,spec,home)
	if not _require(not record.is_empty(),"Explicit source-bound fourth-layer composition rejected "+String(id)): return false
	for object: Dictionary in record.objects:
		if not _require(C._object_solids_valid(object),"Explicit candidate solid invalid "+String(object.id)): return false
	if not _track(original.raw_walk_path): return false
	var raw_walk:=Image.load_from_file(original.raw_walk_path)
	var mask: Image=C.raster_walk(raw_walk,record.objects)
	var solids: Array[PackedVector2Array]=C.object_solids(record.objects)
	if not _require(mask!=null,"Original raw cannot form exact revised mask"): return false
	var route_proof:=_routes_proof(record,mask,solids)
	if not _require(route_proof.get("passed")==true,"875+17 route proof rejected: "+str(route_proof)): return false
	if not _require(C._all_gameplay_safe_cpu(record,mask,solids,Callable()),"Exact875 original+new gameplay/4px routes rejected "+String(id)): return false
	var arrival_receipts:=R.strict_arrival_receipts(spec)
	if not _require(arrival_receipts.size()==spec.fresh_arrival_overrides.size(),"Strict original-source fresh arrival mapping refused"): return false
	for arrival: Dictionary in arrival_receipts:
		var point:=C._vec(arrival.revised_foot_px)
		if not _require(C._safe_body_cpu(point,mask,solids) and _seventeen(point,mask,solids),"Revised fresh arrival lacks exact shoe clearance"): return false
	if id==&"ch4_s2_canal_docks":
		var ferry:=C._vec(R._find(record.gameplay_slots.portals,"source_id","canal_world_ferry").foot_px)
		var market:=C._vec(R._find(record.gameplay_slots.portals,"source_id","to_south_market").foot_px)
		if not _require(ferry.distance_to(market)>=500.0,"Independent Docks exits must separate500px"): return false
	var room_receipts: Array[Dictionary]=[]
	if spec.get("room_count",0)==9:
		for room: Dictionary in home.rooms:
			if not _track(room.scene_path) or not _track(room.layout_path): return false
			var inside:=ResourceLoader.load(room.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
			if not _require(inside!=null and inside.scene_id==StringName(room.scene_id) and inside.is_walkable and inside.npcs.is_empty() and inside.hotspots.is_empty() and inside.on_enter_dialog==null,"Independent room identity/content not clean"): return false
			var exit:=R._find(inside.map_layout.portals,"id",String(room.indoor_exit.portal_id))
			if not _require(not exit.is_empty() and exit.get("target_scene")==String(id) and exit.get("target_pos")==C._vec(room.return_foot_px)/C.SIZE,"Room exact corresponding city return foot differs"): return false
			var foot:=C._vec(room.return_foot_px)
			if not _require(C._safe_body_cpu(foot,mask,solids) and _seventeen(foot,mask,solids),"Independent main door875+17 clearance refused "+String(room.building_id)): return false
			room_receipts.append({"building_id":room.building_id,"room_id":room.scene_id,"scene_path":room.scene_path,"return_foot_px":room.return_foot_px,"full875_and17":true,"router_installed":false,"door_visual_Physics":"PENDING"})
	var scene:=R.apply_candidate(original_scene,record,spec,home)
	if not _require(scene!=null,"Explicit scene delta serialization preparation rejected"): return false
	var manifest_path:=R.ROOT+String(id)+"/candidate_manifest.json"
	var layout_path:=MAP_ROOT+String(id)+"_layout.tres"
	var scene_path:=SCENE_ROOT+String(id)+".tres"
	for path: String in [record.walk_path,manifest_path,layout_path,scene_path]:
		if not _require(not FileAccess.file_exists(path),"Refuse existing candidate output "+path): return false
	for directory: String in [record.walk_path.get_base_dir(),layout_path.get_base_dir(),scene_path.get_base_dir()]:
		if not _require(DirAccess.make_dir_recursive_absolute(directory)==OK,"New candidate directory creation refused"): return false
	if not _require(mask.save_png(record.walk_path)==OK,"New original-raw-derived raster save refused"): return false
	var saved_mask:=Image.load_from_file(record.walk_path)
	if not _require(saved_mask!=null,"New raster readback missing"): return false
	saved_mask.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	if not _require(saved_mask.get_data()==mask.get_data(),"New raster fullRGBA readback differs"): return false
	var manifest: Dictionary={"scene_id":String(id),"status":"PUBLISHED_FOURTH_LAYER_CANDIDATE_NOT_FORMAL_NOT_ROUTER_INSTALLED","author_path":R.AUTHOR_PATH,"author_sha256":R.AUTHOR_SHA,"parent_manifest_path":spec.parent_manifest_path,"parent_manifest_sha256":spec.parent_manifest_sha256,"objects":record.objects,"gameplay_slots":record.gameplay_slots,"routes":record.routes,"ground_path":record.ground_path,"walk_path":record.walk_path,"walk_sha256":FileAccess.get_sha256(record.walk_path),"raw_walk_path":original.raw_walk_path,"raw_walk_sha256":_inputs[original.raw_walk_path],"route_proof":route_proof,"strict_fresh_arrivals":arrival_receipts,"rooms":room_receipts,"full_original_C_first":true,"formal_activated":false,"C_Router_hook_installed":false,"Field_Physics_visual_QA":"PENDING"}
	if not _write(manifest_path,manifest): return false
	scene.set_meta(R.META,FileAccess.get_sha256(manifest_path))
	if not _require(ResourceSaver.save(scene.map_layout,layout_path)==OK,"New candidate layout save rejected"): return false
	var expected: SceneScript=C.BASE._independent_copy(scene)
	scene.map_layout=ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(ResourceSaver.save(scene,scene_path)==OK,"New candidate scene save rejected"): return false
	var saved:=ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(R.serialized_equal(saved,expected),"Full new candidate serialized storage differs"): return false
	_rows.append({"scene_id":String(id),"scene_path":scene_path,"scene_sha256":FileAccess.get_sha256(scene_path),"layout_path":layout_path,"layout_sha256":FileAccess.get_sha256(layout_path),"manifest_path":manifest_path,"manifest_sha256":FileAccess.get_sha256(manifest_path),"room_count":room_receipts.size(),"route_samples":route_proof.samples,"full_original_C_first":true,"runtime_installed":false})
	return true

func _run() -> void:
	_started=Time.get_ticks_msec()
	_output=OUTPUT_ROOT+"%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge:=root.get_node_or_null("PlatformBridge")
	if bridge==null: quit(1); return
	var prior: bool=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	var ok:=_require(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoint suspension acknowledgement required") and _require("--publish-luoyang-city-revision-retry2-20261015" in OS.get_cmdline_user_args() and not R.FLAG in OS.get_cmdline_user_args(),"Explicit publisher flag only, no runtime flag")
	var authoring:=R.author(); var home:=R.homes()
	ok=ok and _require(not authoring.is_empty() and not home.is_empty(),"Exact author/home sources rejected")
	if ok:
		for path: String in [get_script().resource_path,"res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd",R.AUTHOR_PATH,R.HOME_PATH]:
			if not _track(path): ok=false; break
	if ok:
		for path: String in authoring.source_sha256:
			if not _track(path,authoring.source_sha256[path]): ok=false; break
	if ok:
		var selected:=""
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--city="): selected=argument.trim_prefix("--city=")
		if not selected.is_empty() and selected not in ["ch4_s3_luoyang_market","ch4_s2_canal_docks"]: ok=false; _error="Unknown explicit city publication scope"
		for spec: Dictionary in (authoring.scenes if ok else []):
			if not selected.is_empty() and spec.scene_id!=selected: continue
			if not _publish_scene(spec,home): ok=false; break
	for path: String in _inputs:
		if FileAccess.get_sha256(path)!=_inputs[path]: ok=false; _error="Final original source changed "+path
	if Time.get_ticks_msec()-_started>=180000: ok=false; _error="Finite180s publication budget exceeded"
	var report: Dictionary={"passed":ok,"error":_error,"elapsed_ms":Time.get_ticks_msec()-_started,"source_first":_inputs,"rows":_rows,"formal_changed":false,"C_Router_Field_hook_installed":false,"runtime_Physics_QA":false}
	var saved:=_write(_output+"result.json",report)
	bridge.call("set_checkpoint_saves_suspended",prior)
	print("LUOYANG_CITY_REVISION_CANDIDATE_RESULT="+_output+"result.json passed="+str(ok and saved))
	quit(0 if ok and saved else 1)
