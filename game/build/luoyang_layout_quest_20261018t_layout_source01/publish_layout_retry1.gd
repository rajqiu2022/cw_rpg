extends SceneTree
## ROOT-only finite publication from exact, already-published native artifacts.
## Does not call C.prepare/resolve or replay the historical art-maker pipeline.
const T=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const D=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const DG=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const G=preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const AUTHOR="res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry1.json"
const MIGRATION="res://build/luoyang_layout_quest_20261018t_layout_source01/source_migration_geometry_v1.json"
const PRIOR_REG="res://data/maps/luoyang_assembled_interiors_20261016g/registry_spacing_dependency_v3.json"
const PRIOR_REG_SHA="959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5"
const OLD_ROOT="res://data/maps/luoyang_precomputed_bundle_20261018r3/"
const ROOT="res://data/maps/luoyang_layout_bundle_20261018t_retry1/"
const ROOM_REUSE_REPORT="res://build/luoyang_layout_quest_publication_20261018t/42808/result.json"
const ROOM_REUSE_SHA="835d49fc1766de927de3c40017540903d79799fe48ab9af069301a68b9132663"
const ROOM_REGISTRY_SHA="a65ef4db492d00868568bf77be3efdda9665262bcdf3c78995dcdbe95a125e7c"
const ROOM_ROOT="res://data/maps/luoyang_layout_rooms_20261018t/"
const IDS=["ch4_s0_luoyang_gate","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s1_luoyang_yamen"]
const LIMIT_MS=60000
const GEOMETRY_ONLY_FLAG="--luoyang-t-geometry-only"
var _started: int=0
var _error: String=""
var _sources: Dictionary={}
var _rows: Dictionary={}
var _author: Dictionary={}
var _author_sha: String=""
var _migration: Dictionary={}
var _generated: Dictionary={}
var _geometry_only: bool=false
func _initialize() -> void: call_deferred("_run")
func require(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message; push_error("[Layout t] "+message)
	return ok
func read_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func track(path: String,pin: String="") -> bool:
	if _sources.has(path): return require(pin.is_empty() or _sources[path]==pin,"Conflicting exact source pin "+path)
	if not require(path.begins_with("res://") and ".." not in path and FileAccess.file_exists(path),"Source absent/unsafe "+path): return false
	var actual: String=FileAccess.get_sha256(path)
	if not require(B._hash(actual) and (pin.is_empty() or actual==pin) and (not _sources.has(path) or _sources[path]==actual),"Exact source changed "+path): return false
	_sources[path]=actual; return true
func write_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true
func write_native(path: String,value: Dictionary) -> bool:
	if not B._plain(value) or FileAccess.file_exists(path): return false
	var bytes: PackedByteArray=var_to_bytes(value); var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(bytes); file.close()
	var reread: Variant=bytes_to_var(FileAccess.get_file_as_bytes(path))
	return reread is Dictionary and B.equal(value,reread)
func write_text(path: String,value: String) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(value.trim_suffix("\n")+"\n"); file.close(); return true
func migrate(old: Dictionary) -> Dictionary:
	var current: Dictionary=old.duplicate(true)
	for path: String in old:
		var delta: Dictionary=_migration.get("source_delta",{}).get(path,{})
		if not delta.is_empty() and not _geometry_only:
			if not require(delta.size()==2 and delta.get("old_sha256")==old[path] and B._hash(delta.get("new_sha256")),"Unapproved prior/current delta "+path): return {}
			current[path]=delta.new_sha256
		if not track(path,current[path]): return {}
	return current
func parent(id: String) -> Dictionary:
	var manifest_path: String=OLD_ROOT+id+"/manifest.json"
	var expected: Dictionary=load("res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd").entries().get(id,{})
	if not require(expected.get("manifest_path")==manifest_path and track(manifest_path,expected.get("manifest_sha256","")),"Immutable parent index identity "+id): return {}
	var manifest: Dictionary=read_json(manifest_path)
	if not require(manifest.get("publication_full_source_finalized")==true and manifest.get("scene_id")==id,"Immutable parent not finalized "+id): return {}
	var legacy: Dictionary=migrate(manifest.get("legacy_source_sha256",{}))
	if legacy.is_empty(): return {}
	for path: String in manifest.artifacts:
		if not track(path,manifest.artifacts[path]): return {}
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(OLD_ROOT+id+"/packet.bin"))
	var scene:=ResourceLoader.load(OLD_ROOT+id+"/scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(OLD_ROOT+id+"/layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not require(packet is Dictionary and B._plain(packet) and scene!=null and layout!=null,"Native parent malformed "+id): return {}
	scene.map_layout=layout
	if not require(B.equal(B.storage(scene),packet.scene_storage) and B.equal(B.storage(layout),packet.layout_storage) and B.bytes_sha(packet.walk_bytes)==packet.mask_sha,"Whole parent storage/NAV differs "+id): return {}
	return {"manifest":manifest,"manifest_path":manifest_path,"manifest_sha256":expected.manifest_sha256,"packet":packet,"scene":scene,"legacy":legacy}
func district_projection(id: String) -> Dictionary:
	var config: Dictionary=D.binding(); var author: Dictionary=D.author(config)
	if author.is_empty() or not D.cpu_proof_valid(config,author): return {}
	return T.district_projection(DG.project(author,StringName(id)),StringName(id),_author)
func crowd_routes(id: String,projected: Dictionary) -> Array:
	var paths: Array=[]
	for person: Dictionary in projected.spec.get("crowd",[]):
		var foot: Vector2=T.v(person.foot_px); var distance: float=float(person.get("distance_px",0))
		paths.append({"id":"district:"+String(person.id),"npc":true,"points_px":[T.xy(foot-Vector2(distance,0)),T.xy(foot+Vector2(distance,0))]})
	for raw: Variant in projected.spec.get("protected_feet",[]): paths.append({"id":"district:protected","points_px":[raw,raw]})
	paths.append_array(projected.spec.get("required_routes",[])); paths.append_array(projected.spec.get("protected_routes",[]))
	return paths
func publish_city(id: String) -> bool:
	var p: Dictionary=parent(id)
	if p.is_empty(): return false
	var old: Dictionary=p.packet; var data: Dictionary=old.duplicate(true)
	var scene: SceneScript=p.scene
	var dir: String=ROOT+id+"/"
	if not require(not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir)==OK,"Fresh city artifact directory required "+id): return false
	var audit: Dictionary={"passed":true,"basis":"UNCHANGED_PARENT_NATIVE_ARTIFACT_EXPLICIT_SOURCE_SUCCESSION","not_new_geometry":true}
	if _author.districts.has(id):
		var record: Dictionary=T.compose(old.record,StringName(id),_author,dir+"walk.png")
		if not require(not record.is_empty(),"Pure exact record transform refused "+id): return false
		var raw_path: String=String(old.record.raw_walk_path)
		if not track(raw_path): return false
		var raw: Image=Image.load_from_file(raw_path)
		var mask: Image=T.c().raster_walk(raw,record.objects)
		if not require(mask!=null,"Original raw-support minus NEW solids raster "+id): return false
		var projection: Dictionary=district_projection(id)
		if not require(not projection.is_empty(),"Original District projection proof "+id): return false
		audit=T.audit(record,mask,_author,DG.delta_solids(projection),crowd_routes(id,projection))
		if not require(audit.get("passed")==true,"Combined original/new routes or anchors refused "+JSON.stringify(audit)): return false
		if not require(mask.save_png(dir+"walk.png")==OK,"NEW mask write "+id): return false
		var readback: Image=Image.load_from_file(dir+"walk.png")
		if readback!=null: readback.convert(Image.FORMAT_RGBA8)
		if not require(readback!=null and mask.get_data()==readback.get_data(),"Full NEW mask RGBA readback "+id): return false
		scene=T.materialize(p.scene,record,_author,_author_sha)
		if not require(scene!=null,"Full render/physical/door materialize "+id): return false
		if id=="ch4_s3_luoyang_market":
			var alpha: Dictionary=alpha_clearance(scene,_author.districts[id])
			if not require(alpha.get("passed")==true,"Five real alpha building footprints "+JSON.stringify(alpha)): return false
			audit["alpha_clearance"]=alpha
		data.record=record; data.solids=T.c().object_solids(record.objects)
		data.walk_bytes=mask.get_data(); data.mask_sha=B.bytes_sha(data.walk_bytes)
		data["geometry_basis"]=T.BASIS
		data["t_parent_record"]=old.record.duplicate(true)
		data["t_parent_scene_storage"]=old.scene_storage.duplicate(true)
		data["t_parent_layout_storage"]=old.layout_storage.duplicate(true)
	data["geometry_basis"]=T.BASIS if _author.districts.has(id) else "UNCHANGED_PARENT_NATIVE_ARTIFACT_EXPLICIT_SOURCE_SUCCESSION"
	data.scene_storage=B.storage(scene); data.layout_storage=B.storage(scene.map_layout)
	if not require(B._plain(data),"No unsafe Objects in native successor packet "+id): return false
	var layout_path: String=dir+"layout.res"; var scene_path: String=dir+"scene.res"
	if not require(ResourceSaver.save(scene.map_layout,layout_path)==OK,"Save layout "+id): return false
	scene.map_layout=ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not require(scene.map_layout!=null and ResourceSaver.save(scene,scene_path)==OK,"Save Scene "+id): return false
	var loaded:=ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not require(loaded!=null and B.equal(B.storage(loaded),data.scene_storage) and B.equal(B.storage(loaded.map_layout),data.layout_storage),"Complete native all-storage readback "+id): return false
	if not require(write_native(dir+"packet.bin",data),"Safe typed native roundtrip "+id): return false
	var artifacts: Dictionary={}
	for suffix: String in ["scene.res","layout.res","packet.bin"]: artifacts[dir+suffix]=FileAccess.get_sha256(dir+suffix)
	# Entire immutable prior manifest, including its real singular first/final
	# fields and all s migrations, is retained, not reconstructed from null keys.
	if not require(not p.manifest.get("publication_source_first",{}).is_empty() and B.equal(p.manifest.publication_source_first,p.manifest.publication_source_final),"Complete immutable prior publication first/final "+id): return false
	var manifest: Dictionary={"kind":B.KIND,"scene_id":id,"status":"CPU_PUBLISHED_IMPORT_AND_RUNTIME_PENDING","publication_full_source_finalized":true,"geometry_proof_basis":T.BASIS if _author.districts.has(id) else "UNCHANGED_PARENT_NATIVE_ARTIFACT_EXPLICIT_SOURCE_SUCCESSION","parent_publication":{"path":p.manifest_path,"sha256":p.manifest_sha256,"complete_immutable_manifest":p.manifest.duplicate(true)},"legacy_source_sha256":{},"artifacts":artifacts,"mask_sha256":data.mask_sha,"layout_proof":audit,"author_path":AUTHOR,"author_sha256":_author_sha,"source_migration":_migration.duplicate(true),"formal_enabled":false,"native_physics_not_run":true,"import_pending":_author.districts.has(id)}
	_rows[id]={"manifest_path":dir+"manifest.json","pending_manifest":manifest,"geometry":audit}
	if _author.districts.has(id): _generated[dir+"walk.png"]=FileAccess.get_sha256(dir+"walk.png")
	return true
func alpha_clearance(scene: SceneScript,spec: Dictionary) -> Dictionary:
	var boxes: Dictionary={}
	for id: String in spec.five_building_ids:
		var entry: Dictionary=T.find(scene.map_layout.visual_objects,id)
		var image: Image=Image.load_from_file(String(entry.get("texture","")))
		if image==null or not track(String(entry.texture)): return {"passed":false,"error":"ACTUAL_PNG_ABSENT","id":id}
		image.convert(Image.FORMAT_RGBA8)
		var size: Vector2i=image.get_size(); var bytes: PackedByteArray=image.get_data()
		var low:=Vector2i(size.x,size.y); var high:=Vector2i(-1,-1)
		for y: int in size.y:
			for x: int in size.x:
				if bytes[(y*size.x+x)*4+3]==0: continue
				low=Vector2i(mini(low.x,x),mini(low.y,y)); high=Vector2i(maxi(high.x,x),maxi(high.y,y))
		if high.x<low.x: return {"passed":false,"error":"EMPTY_ALPHA","id":id}
		var render: Vector2=T.v(entry.render_size_px); var origin: Vector2=T.v(entry.pos)*T.SIZE
		if entry.get("centered",true): origin-=render*.5
		var box:=Rect2(origin+Vector2(low)*render/Vector2(size),Vector2(high-low+Vector2i.ONE)*render/Vector2(size))
		if box.position.x<0 or box.position.y<0 or box.end.x>T.SIZE.x or box.end.y>T.SIZE.y: return {"passed":false,"error":"VISIBLE_ALPHA_OUTSIDE_MAP","id":id,"actual_rect":var_to_str(box)}
		boxes[id]=box
	var first: Rect2=boxes.inn; var middle: Rect2=boxes.north_market_front; var last: Rect2=boxes.shop
	var gaps: Array=[float(middle.position.x-first.end.x),float(last.position.x-middle.end.x)]
	if float(gaps[0])<float(spec.minimum_north_alpha_gap_px) or float(gaps[1])<float(spec.minimum_north_alpha_gap_px): return {"passed":false,"error":"ACTUAL_ALPHA_GAP","gaps_px":gaps,"boxes":var_to_str(boxes)}
	var ids: Array=boxes.keys()
	for i: int in ids.size():
		for j: int in range(i+1,ids.size()):
			var a: String=ids[i]; var b: String=ids[j]; var rect: Rect2=boxes[a]
			if rect.intersects(boxes[b],true): return {"passed":false,"error":"BUILDING_ALPHA_AABB_OVERLAP","pair":[a,b]}
	var guest_rects: Array=[]
	for path: String in ["res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png","res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"]:
		if not track(path): return {"passed":false,"error":"GUEST_SPRITE_SOURCE"}
		var image: Image=Image.load_from_file(path)
		if image==null or image.get_height()!=160 or image.get_width()%160!=0: return {"passed":false,"error":"GUEST_NATIVE_CELL"}
		var first_frame_bounds: Rect2i=image.get_region(Rect2i(0,0,160,160)).get_used_rect()
		if first_frame_bounds.size.y<=0: return {"passed":false,"error":"GUEST_EMPTY_ALPHA"}
		var scale: float=140.0/float(first_frame_bounds.size.y) # exact NPCNode calibrated policy
		for frame: int in image.get_width()/160:
			var used: Rect2i=image.get_region(Rect2i(frame*160,0,160,160)).get_used_rect()
			for flipped: bool in [false,true]:
				var left: float=float(used.position.x-80) if not flipped else float(80-used.end.x)
				var bounds:=Rect2(Vector2(1140-70+left*scale,1810+(used.position.y-first_frame_bounds.end.y)*scale),Vector2(140+used.size.x*scale,used.size.y*scale))
				for id: String in boxes:
					if bounds.intersects(boxes[id],true): return {"passed":false,"error":"GUEST_FULL_LANE_VISIBLE_ALPHA_UNDER_ROOF","texture":path,"frame":frame,"building_id":id}
				guest_rects.append(var_to_str(bounds))
	return {"passed":true,"north_gaps_px":gaps,"actual_alpha_greater_than":0,"boxes_native":var_to_str(boxes),"all_visible_alpha_in_map":true,"scale_unchanged":true,"guest_all_idle_walk_frames_both_flips_lane_visible_rects":guest_rects,"guest_new_lane_px":[[1070,1810],[1210,1810]],"guest_nativebody_unchanged":true}
func finish_manifests() -> bool:
	# Outputs are a separate, exact generated authority set. They are never
	# retroactively injected into the input publication source-first observation.
	for id: String in IDS:
		var row: Dictionary=_rows[id]; var manifest: Dictionary=row.pending_manifest
		manifest.legacy_source_sha256=_sources.duplicate(true)
		manifest["runtime_authority_sha256"]=_generated.duplicate(true)
		manifest["publication_source_first"]=_sources.duplicate(true)
		manifest["publication_source_final"]={}
		for path: String in _sources: manifest.publication_source_final[path]=FileAccess.get_sha256(path)
		if not require(B.equal(manifest.publication_source_first,manifest.publication_source_final),"Complete input source-first/final before successor manifest "+id): return false
		if not require(write_json(row.manifest_path,manifest),"Successor manifest write "+id): return false
		row["manifest_sha256"]=FileAccess.get_sha256(row.manifest_path); row.erase("pending_manifest")
	return true
func reuse_rooms() -> bool:
	if not require(_geometry_only,"Retry1 is geometry-only; runtime finalizer is a separate atom"): return false
	if not track(ROOM_REUSE_REPORT,ROOM_REUSE_SHA): return false
	var failed: Dictionary=read_json(ROOM_REUSE_REPORT)
	if not require(failed.get("passed")==false and String(failed.get("error","")).contains("room_eastward_approach") and B.equal(failed.get("source_first"),failed.get("source_final")),"Preserved failed CITY report with successful unchanged ROOM inputs"): return false
	var registry_path: String=ROOM_ROOT+"registry_geometry.json"
	if not track(registry_path,ROOM_REGISTRY_SHA): return false
	var registry: Dictionary=read_json(registry_path)
	if not require(registry.get("rooms",{}).size()==12 and registry.get("status")=="CPU_PUBLISHED_ROOM_SUCCESSORS_CANDIDATE","Exact complete twelve-room predecessor"): return false
	var generated: Dictionary=failed.get("generated_authority_sha256",{})
	if not require(generated.size()==49 and generated.get(registry_path)==ROOM_REGISTRY_SHA,"Exact twelve times four native artifacts plus registry"): return false
	for path: String in failed.source_first:
		if not track(path,failed.source_first[path]): return false
	for path: String in generated:
		if not require(path.begins_with(ROOM_ROOT),"Reuse is rooms-only, not failed CITY output"): return false
		if not require(FileAccess.get_sha256(path)==generated[path],"Existing room artifact changed "+path): return false
		_generated[path]=generated[path]
	var checked: int=0
	for id: String in registry.rooms:
		var row: Dictionary=registry.rooms[id]
		if not require(row.get("geometry",{}).get("passed")==true,"Existing room proof incomplete "+id): return false
		for source: String in row.source_sha256:
			if generated.has(source): continue
			if not track(source,row.source_sha256[source]): return false
		var a: Dictionary=read_json(row.author_path)
		for move: Dictionary in _author.room_moves:
			if move.scene_id==id and not require(T.v(a.room.return_foot_px)==T.v(move.return_foot_px) and a.room.building_id==move.building_id,"Retry may not alter existing room return/building "+id): return false
		if id==_author.official_hall.scene_id:
			if not require(a.room.city_id==_author.official_hall.city_id and T.v(a.room.return_foot_px)==T.v(_author.official_hall.return_foot_px),"Retry must retain independent hall identity"): return false
		var storage: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
		var scene:=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var layout:=ResourceLoader.load(row.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if not require(storage is Dictionary and B._plain(storage) and scene!=null and layout!=null,"Reused room native readback "+id): return false
		scene.map_layout=layout
		if not require(B.equal(B.storage(scene),storage.scene) and B.equal(B.storage(layout),storage.layout),"Reused room WHOLE storage "+id): return false
		checked+=1
	return require(checked==12,"All twelve exact rooms reused without geometry rerun")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec(); _author=read_json(AUTHOR); _migration=read_json(MIGRATION)
	_geometry_only=GEOMETRY_ONLY_FLAG in OS.get_cmdline_user_args()
	var ok: bool=require(not _author.is_empty() and (_migration.get("status")=="READY_EXACT_SOURCE_SUCCESSION" or (_geometry_only and _migration.get("status")=="SOURCE_READY_GEOMETRY_CANDIDATE")),"NEEDS_PUBLICATION: finish explicit source-owner freeze before ROOT execution")
	if ok:
		for path: String in [AUTHOR,MIGRATION,get_script().resource_path,"res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform.gd"]:
			if not track(path): ok=false; break
	_author_sha=FileAccess.get_sha256(AUTHOR)
	if ok:
		for path: String in _migration.get("new_source_paths",[]):
			if not track(path): ok=false; break
	if ok: ok=reuse_rooms()
	if ok:
		var selected_ids: Array=["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"] if _geometry_only else IDS
		for id: String in selected_ids:
			if not publish_city(id): ok=false; break
			if not require(Time.get_ticks_msec()-_started<LIMIT_MS,"Finite 60s publication budget"): ok=false; break
	if ok and not _geometry_only: ok=finish_manifests()
	var final_sources: Dictionary={}
	for path: String in _sources:
		final_sources[path]=FileAccess.get_sha256(path)
		if not require(final_sources[path]==_sources[path],"Final source changed "+path): ok=false
	var report: Dictionary={"passed":ok,"status":"CPU_GEOMETRY_SUCCESSOR_NOT_RUNTIME_NOT_FORMAL" if _geometry_only else "CPU_PUBLICATION_NOT_RUNTIME_NOT_FORMAL","error":_error,"rows":_rows,"source_first":_sources,"source_final":final_sources,"generated_authority_sha256":_generated,"candidate_source_contract":_migration,"elapsed_ms":Time.get_ticks_msec()-_started,"limit_ms":LIMIT_MS,"not_full_original_art_pipeline":true,"new_geometry_basis":T.BASIS}
	var out: String="res://build/luoyang_layout_quest_publication_20261018t/"+str(OS.get_process_id())+"/result.json"
	if not write_json(out,report): ok=false
	if ok and _geometry_only and not write_json(ROOT+"geometry_publication.json",report): ok=false
	print(JSON.stringify({"passed":ok,"error":_error,"output":out})); quit(0 if ok else 1)
