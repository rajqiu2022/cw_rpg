extends SceneTree
## ROOT-only, one Market native publication. No C.prepare, room geometry or city loop.
const READY=false
const AF=preload("res://build/luoyang_market_frontage_20261020af_system01/frontage_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const D=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const DG=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const T=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd")
const RETURNS=preload("res://build/luoyang_market_frontage_20261020af_system01/room_returns_candidate.gd")
const LIMIT_MS=60000
const REPORT_ROOT="res://build/luoyang_market_frontage_20261020af_system01/publication/"
const WALK_CANDIDATE="res://build/luoyang_market_frontage_20261020af_system01/publication_assets/walk_candidate.png"
var sources: Dictionary={}
var error: String=""
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AF "+label)
	return ok
func track(path: String,pin: String="") -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and actual.length()==64 and (pin.is_empty() or actual==pin) and (not sources.has(path) or sources[path]==actual),"EXACT_SOURCE:"+path): return false
	sources[path]=actual;return true
func json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func write_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func alpha(scene: SceneScript) -> Dictionary:
	var ids: Array=["inn","north_market_front","shop","market_west_ward_frontage"]+AF.NEW_IDS
	var boxes: Dictionary={}
	for id: String in ids:
		var row: Dictionary=AF.find(scene.map_layout.visual_objects,id)
		if row.is_empty() or not track(String(row.get("texture",""))): return {"passed":false,"error":"ALPHA_ROW"}
		var image: Image=Image.load_from_file(String(row.texture))
		if image==null: return {"passed":false,"error":"ALPHA_IMAGE"}
		image.convert(Image.FORMAT_RGBA8)
		var used: Rect2i=image.get_used_rect()
		if not used.has_area(): return {"passed":false,"error":"EMPTY_ALPHA"}
		var render: Vector2=AF.v(row.render_size_px);var origin: Vector2=AF.v(row.pos)*AF.SIZE
		if row.get("centered",true): origin-=render*.5
		var box:=Rect2(origin+Vector2(used.position)*render/Vector2(image.get_size()),Vector2(used.size)*render/Vector2(image.get_size()))
		if not Rect2(Vector2.ZERO,AF.SIZE).encloses(box): return {"passed":false,"error":"ALPHA_OUTSIDE","id":id}
		boxes[id]=box
	for id: String in AF.NEW_IDS:
		for other: String in boxes:
			if id==other: continue
			if (boxes[id] as Rect2).intersects(boxes[other],true): return {"passed":false,"error":"ALPHA_OVERLAP","pair":[id,other]}
	var gap0: float=boxes[AF.NEW_IDS[1]].position.x-boxes[AF.NEW_IDS[0]].end.x
	var gap1: float=boxes[AF.NEW_IDS[2]].position.x-boxes[AF.NEW_IDS[1]].end.x
	return {"passed":gap0>=80.0 and gap1>=80.0,"gaps_px":[gap0,gap1],"boxes_native":var_to_str(boxes),"alpha_greater_than":0,"not_Field_or_art_credit":true}
func run_publication() -> Dictionary:
	if not need(READY and OS.get_cmdline_user_args().is_empty(),"AF_PENDING_OR_FLAGS"): return {}
	var spec: Dictionary=AF.author()
	if not need(not spec.is_empty(),"AF_AUTHOR_PENDING_OR_CHANGED"): return {}
	for path: String in [AF.AUTHOR,"res://build/luoyang_market_frontage_20261020af_system01/frontage_candidate.gd","res://build/luoyang_market_frontage_20261020af_system01/room_returns_candidate.gd",get_script().resource_path]:
		if not track(path): return {}
	for path: String in spec.source_sha256:
		if not track(path,String(spec.source_sha256[path])): return {}
	for pair: Array in [[spec.parent_packet_path,spec.parent_packet_sha256],[spec.parent_scene_path,spec.parent_scene_sha256],[spec.parent_layout_path,spec.parent_layout_sha256],[spec.district_t_author_path,spec.district_t_author_sha256]]:
		if not track(String(pair[0]),String(pair[1])): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	var scene:=ResourceLoader.load(spec.parent_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(spec.parent_layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(parent is Dictionary and B._plain(parent) and scene!=null and layout!=null,"PARENT_NATIVE"): return {}
	scene.map_layout=layout
	if not need(B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(layout),parent.layout_storage),"WHOLE_PARENT_STORAGE"): return {}
	var dir: String=AF.ROOT+String(AF.ID)+"/"
	if not need(not DirAccess.dir_exists_absolute(dir),"NEW_AF_ROOT_REQUIRED"): return {}
	var record: Dictionary=AF.compose(parent.record,spec,dir+"walk.png")
	if not need(not record.is_empty(),"EXACT_24_TO_26_COMPOSE"): return {}
	var raw_path: String=String(record.raw_walk_path)
	if not track(raw_path): return {}
	var raw: Image=Image.load_from_file(raw_path)
	var mask: Image=AF.c().raster_walk(raw,record.objects)
	if not need(mask!=null,"EXACT_RAW_MINUS_NEW_SOLIDS"): return {}
	var district_config: Dictionary=D.binding();var district_author: Dictionary=D.author(district_config)
	var old_t: Dictionary=json(spec.district_t_author_path)
	var projection: Dictionary=T.district_projection(DG.project(district_author,AF.ID),AF.ID,old_t)
	if not need(not projection.is_empty() and D.cpu_proof_valid(district_config,district_author),"DISTRICT_UNCHANGED_PROJECTION"): return {}
	var audit_author: Dictionary=old_t.duplicate(true)
	for move: Dictionary in audit_author.room_moves:
		for changed: Dictionary in spec.room_moves:
			if move.scene_id==changed.scene_id: move.return_foot_px=changed.return_foot_px.duplicate()
	var crowd: Array=[]
	for person: Dictionary in projection.spec.crowd:
		var foot: Vector2=AF.v(person.foot_px);var distance: float=float(person.distance_px)
		crowd.append({"id":"district:"+String(person.id),"npc":true,"points_px":[[foot.x-distance,foot.y],[foot.x+distance,foot.y]]})
	for point: Variant in projection.spec.protected_feet: crowd.append({"id":"district:protected","points_px":[point,point]})
	crowd.append_array(projection.spec.get("required_routes",[]));crowd.append_array(projection.spec.get("protected_routes",[]))
	var audit: Dictionary=T.audit(record,mask,audit_author,DG.delta_solids(projection),crowd,projection)
	if not need(audit.get("passed")==true,"ALL_GAMEPLAY_ROUTES_CROWD_87517"): return {"audit":audit}
	var result_scene: SceneScript=AF.materialize(scene,record,spec,FileAccess.get_sha256(AF.AUTHOR))
	if not need(result_scene!=null,"COMPLETE_NATIVE_MATERIALIZE"): return {}
	var alpha_result: Dictionary=alpha(result_scene)
	if not need(alpha_result.get("passed")==true,"ACTUAL_ALPHA_AND_80PX_GAPS"): return {"alpha":alpha_result}
	var data: Dictionary=parent.duplicate(true)
	data.geometry_basis=AF.BASIS;data.record=record;data.solids=AF.c().object_solids(record.objects);data.walk_bytes=mask.get_data();data.mask_sha=B.bytes_sha(data.walk_bytes)
	data.af_parent_record=parent.record.duplicate(true);data.af_parent_packet_sha256=spec.parent_packet_sha256;data.af_author_sha256=FileAccess.get_sha256(AF.AUTHOR)
	data.scene_storage=B.storage(result_scene);data.layout_storage=B.storage(result_scene.map_layout)
	if not need(AF.packet_inverse(data,parent,spec),"WHOLE_TYPED_PACKET_INVERSE"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(dir)==OK and not FileAccess.file_exists(WALK_CANDIDATE) and DirAccess.make_dir_recursive_absolute(WALK_CANDIDATE.get_base_dir())==OK,"NEW_OUTPUT_DIRECTORY"): return {}
	if not need(mask.save_png(WALK_CANDIDATE)==OK,"NEW_WALK_BUILD_CANDIDATE_WRITE"): return {}
	var readback: Image=Image.load_from_file(WALK_CANDIDATE)
	if readback!=null: readback.convert(Image.FORMAT_RGBA8)
	if not need(readback!=null and readback.get_data()==mask.get_data(),"WALK_FULL_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(result_scene.map_layout,dir+"layout.res")==OK,"NEW_LAYOUT_SAVE"): return {}
	result_scene.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(result_scene.map_layout!=null and ResourceSaver.save(result_scene,dir+"scene.res")==OK,"NEW_SCENE_SAVE"): return {}
	var reread:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(reread!=null and B.equal(B.storage(reread),data.scene_storage) and B.equal(B.storage(reread.map_layout),data.layout_storage),"NATIVE_WHOLE_READBACK"): return {}
	var packet:=FileAccess.open(dir+"packet.bin",FileAccess.WRITE)
	if not need(packet!=null and B._plain(data),"SAFE_TYPED_PACKET_WRITE"): return {}
	packet.store_buffer(var_to_bytes(data));packet.close()
	if not need(B.equal(bytes_to_var(FileAccess.get_file_as_bytes(dir+"packet.bin")),data),"TYPED_PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[dir+name]=FileAccess.get_sha256(dir+name)
	return {"published":true,"artifact_sha256":artifacts,"walk_candidate":{"path":WALK_CANDIDATE,"sha256":FileAccess.get_sha256(WALK_CANDIDATE),"rgba_sha256":data.mask_sha,"size":[3072,2048],"future_canonical_path":dir+"walk.png","canonical_png_import_ctex_not_promoted":true},"geometry":audit,"alpha":alpha_result,"parent_count":24,"child_count":26,"district_render_count":38,"not_Field_or_formal_credit":true}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	began=Time.get_ticks_msec()
	var result: Dictionary=run_publication()
	if error.is_empty() and result.get("published")==true:
		var returns: Dictionary=RETURNS.publish(AF.author(),Callable(self,"track"))
		result["room_returns"]=returns
		need(returns.get("ok")==true,"THREE_ROOM_RETURN_ONLY_SUCCESSOR:"+String(returns.get("error","")))
	var final_sources: Dictionary={}
	for path: String in sources:
		final_sources[path]=FileAccess.get_sha256(path)
		need(final_sources[path]==sources[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED_60S_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published")==true,"error":error,"source_first":sources,"source_final":final_sources,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"scope":"ONLY_AF_MARKET_NATIVE_CANDIDATE_NOT_RUNTIME_OR_ROOM_GEOMETRY"},true)
	var path: String=REPORT_ROOT+str(OS.get_process_id())+"/result.json"
	var written: bool=write_json(path,result)
	print(JSON.stringify({"passed":written and result.passed,"path":path,"error":error}))
	quit(0 if written and result.passed else 1)

