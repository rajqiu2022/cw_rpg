extends SceneTree
## Root-only single-Market actual-art successor; no old suite replay.
const READY=true
const AO=preload("res://build/luoyang_market_two_shops_20261021ao_system01/two_shops_READY.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const DG=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const D=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const T=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd")
const RETURNS=preload("res://build/luoyang_market_two_shops_20261021ao_system01/two_room_returns_READY.gd")
const OUT="res://build/luoyang_market_two_shops_20261021ao_system01/publication/"
const WALK="res://build/luoyang_market_two_shops_20261021ao_system01/publication_assets/walk_candidate.png"
const LIMIT_MS=60000
var sources: Dictionary={}
var error: String=""
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AO "+label)
	return ok
func track(path: String,pin: String="") -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and actual.length()==64 and (pin.is_empty() or pin==actual) and (not sources.has(path) or sources[path]==actual),"SOURCE:"+path): return false
	sources[path]=actual;return true
func bounds(polygon: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for p: Vector2 in polygon: low=low.min(p);high=high.max(p)
	return Rect2(low,high-low)
func point_near(foot: Vector2,changed: Array[Rect2],npc: bool=false) -> bool:
	var body:=Rect2(foot-Vector2(17,15 if npc else 12),Vector2(34,30 if npc else 24))
	for box: Rect2 in changed:
		if body.intersects(box,true): return true
	return false
func mask_delta(old: PackedByteArray,new: PackedByteArray,changed: Array[Rect2]) -> Dictionary:
	if old.size()!=3072*2048*4 or new.size()!=old.size(): return {"passed":false,"error":"FULL_RGBA_DIMENSIONS"}
	var count: int=0;var inverse: PackedByteArray=new.duplicate()
	for index: int in range(0,old.size(),4):
		if old[index]==new[index] and old[index+1]==new[index+1] and old[index+2]==new[index+2] and old[index+3]==new[index+3]: continue
		var p:=Vector2((index/4)%3072,(index/4)/3072);var local: bool=false
		for box: Rect2 in changed:
			if box.grow(1).has_point(p): local=true;break
		if not local: return {"passed":false,"error":"CHANGED_PIXEL_OUTSIDE_EXACT_OLD_NEW_RASTER_ENVELOPES","pixel":p}
		for channel: int in 4: inverse[index+channel]=old[index+channel]
		count+=1
	return {"passed":inverse==old,"changed_pixels":count,"full_RGBA_inverse":inverse==old,"only_declared_old_new_bounds":true,"bounds_are_locality_not_polygon_ownership":true}
func route_audit(parent: Dictionary,record: Dictionary,mask: Image,projection: Dictionary,changed: Array[Rect2],spec: Dictionary) -> Dictionary:
	var solids: Array[PackedVector2Array]=AO.c().object_solids(record.objects);solids.append_array(DG.delta_solids(projection))
	var paths: Array=record.routes.duplicate(true);var inherited: int=0;var checked: int=0;var failures: Array=[];var details: Array=[]
	for kind: String in ["npcs","interactions","portals"]:
		for slot: Dictionary in record.gameplay_slots.get(kind,[]):
			var point: Variant=slot.get("stand_px",slot.get("foot_px"))
			if point!=null: paths.append({"id":kind+":"+String(slot.get("source_id","")),"npc":kind=="npcs","points_px":[point,point]})
			if slot.has("passage_path_px"): paths.append({"id":"passage:"+String(slot.get("source_id","")),"points_px":slot.passage_path_px,"ao_added_route":slot.has("ao_original_slot")})
	for person: Dictionary in projection.spec.crowd:
		var p: Vector2=AO.v(person.foot_px);var distance: float=float(person.distance_px)
		paths.append({"id":"district:"+person.id,"npc":true,"points_px":[p-Vector2(distance,0),p+Vector2(distance,0)]})
	for p: Variant in projection.spec.protected_feet: paths.append({"id":"protected_district","points_px":[p,p]})
	for p: Variant in spec.protected_task_feet_px: paths.append({"id":"protected_task","points_px":[p,p]})
	for i: int in 2:
		var move: Dictionary=spec.room_moves[i];var p: Vector2=AO.v(move.return_foot_px);var threshold: Vector2=AO.v(spec.new_objects[i].world_foot_px)
		paths.append({"id":"real_threshold_return_plus10_and24:"+move.scene_id,"points_px":[threshold,p,p+Vector2(0,10),p+Vector2(0,24)],"ao_added_route":true})
	# The already-proved AN lane is not moved; only recheck if its body intersects this local delta.
	paths.append({"id":"AN_lane_2610_1860_keep","points_px":[Vector2(2610,1860),Vector2(2610,1884)]})
	for row: Dictionary in paths:
		var force: bool=row.get("ao_added_route",false) or row.has("ao_original_points_px");var local_count: int=0
		for segment: int in range(row.points_px.size()-1):
			var first: Vector2=AO.v(row.points_px[segment]);var last: Vector2=AO.v(row.points_px[segment+1]);var n: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for i: int in range(n+1):
				var foot: Vector2=first.lerp(last,float(i)/n);var npc: bool=row.get("npc",false)
				if not force and not point_near(foot,changed,npc): inherited+=1;continue
				checked+=1;local_count+=1
				if not AO.c()._safe_body_cpu(foot,mask,solids) or not T.seventeen(foot,mask) or (npc and not DG._npc_clear(foot,mask,solids)): failures.append({"route":row.id,"segment":segment,"sample":i,"foot":foot})
		if local_count>0: details.append({"id":row.id,"checked_samples":local_count,"entire_new_or_changed_route":force})
	return {"passed":failures.is_empty(),"checked_samples":checked,"unchanged_parent_samples_inherited_not_retested":inherited,"route_results":details,"failures":failures,"full87517":true,"npc1085":true,"max_step_px":4,"all_old_routes_retested":false}
func alpha(scene: SceneScript,projection: Dictionary,spec: Dictionary) -> Dictionary:
	var entries: Array=DG.apply_render(scene.map_layout.visual_objects,projection)
	if entries.size()!=36: return {"passed":false,"error":"EXACT_NATIVE24_PLUS_DG12"}
	var boxes: Dictionary={}
	for row: Dictionary in entries:
		if not spec.source_sha256.has(row.texture) or not track(row.texture,spec.source_sha256[row.texture]): return {"passed":false,"error":"PINNED_ACTUAL_ALPHA_SOURCE"}
		var im: Image=Image.load_from_file(row.texture)
		if im==null: return {"passed":false,"error":"ACTUAL_ALPHA_IMAGE"}
		var used: Rect2i=im.get_used_rect();var render: Vector2=AO.v(row.render_size_px);var origin: Vector2=AO.v(row.pos)*AO.SIZE
		if row.get("centered",true): origin-=render*.5
		var box:=Rect2(origin+Vector2(used.position)*render/Vector2(im.get_size()),Vector2(used.size)*render/Vector2(im.get_size()))
		if not used.has_area() or not Rect2(Vector2.ZERO,AO.SIZE).encloses(box) or boxes.has(row.id): return {"passed":false,"error":"ACTUAL_ALPHA_DOMAIN"}
		boxes[row.id]=box
	for id: String in AO.NEW_IDS:
		for other: String in boxes:
			if id!=other and boxes[id].intersects(boxes[other],true): return {"passed":false,"error":"A_GREATER_THAN_ZERO_PROP_OVERLAP","pair":[id,other]}
	var gap: float=boxes[AO.NEW_IDS[1]].position.x-boxes[AO.NEW_IDS[0]].end.x
	return {"passed":gap>96.0,"full_alpha_gap":gap,"required_strictly_greater_than":96,"boxes":var_to_str(boxes),"all36_props_measured":true}
func asset_facts(spec: Dictionary) -> Dictionary:
	var measured: Array=[]
	for i: int in 2:
		var key: String="apothecary" if i==0 else "study"
		var asset: Dictionary=spec.get("assets",{}).get(key,{})
		var row: Dictionary=spec.new_objects[i]
		if asset.get("status")!="ROOT_ART_SOURCE_MEASURED_READY" or asset.get("texture")!=row.texture or not asset.get("alpha_rect_px") is Array or asset.alpha_rect_px.size()!=4 or not asset.get("source_size_px") is Array or asset.source_size_px.size()!=2: return {"passed":false,"error":"ACTUAL_ASSET_MEASUREMENT_PENDING:"+key}
		for value: Variant in asset.alpha_rect_px+asset.source_size_px:
			if not (value is int or value is float) or float(value)!=floorf(float(value)): return {"passed":false,"error":"SOURCE_PIXEL_EXACT_INTEGER_DOMAIN"}
		if not track(asset.texture,asset.source_sha256): return {"passed":false,"error":"ASSET_SOURCE_SHA"}
		var image: Image=Image.load_from_file(asset.texture)
		if image==null or image.get_size()!=Vector2i(asset.source_size_px[0],asset.source_size_px[1]): return {"passed":false,"error":"SOURCE_CANVAS_SIZE"}
		var used: Rect2i=image.get_used_rect();var authored:=Rect2i(asset.alpha_rect_px[0],asset.alpha_rect_px[1],asset.alpha_rect_px[2],asset.alpha_rect_px[3])
		if used!=authored or not used.has_area(): return {"passed":false,"error":"COMPLETE_ACTUAL_A1_PIXEL_RECT"}
		var scale: float=float(asset.scale);var anchor: Vector2=AO.v(asset.source_ground_anchor_px)
		if not Rect2(Vector2.ZERO,Vector2(image.get_size())).has_point(anchor) or scale<=0 or not is_finite(scale) or AO.v(row.render_size_px)!=Vector2(image.get_size())*scale or AO.v(row.foot_uv)!=anchor/Vector2(image.get_size()): return {"passed":false,"error":"ACTUAL_UNIFORM_RENDER_AND_GROUND_ANCHOR"}
		var door: float=float(asset.conservative_door_height_source_px)*scale
		var width: float=float(used.size.x)*scale;var height: float=float(used.size.y)*scale
		if door<120.0 or (i==1 and (width>250.0 or height>268.0 or door<135.0 or width/door>1.85)): return {"passed":false,"error":"ACTUAL_ADULT_DOOR_AND_EXPLICIT_EXPANDED_STUDY_CAPS","asset":key,"width":width,"height":height,"door":door}
		if i==1 and (asset.get("design_successor")!="AO_EXPANDED_COMPLETE_A1_250x268_DOOR135_RATIO1_85" or asset.get("old_contract_pass_claimed",true)!=false): return {"passed":false,"error":"EXPLICIT_NEW_STUDY_DESIGN_NOT_OLD_FAILURE_RELABEL"}
		var derived: Array=[]
		for raw: Variant in asset.ground_solid_polygons_px:
			var polygon: Array=[]
			for p: Vector2 in AO.c()._polygon(raw): polygon.append(AO.v(row.world_foot_px)+(p-anchor)*scale)
			derived.append(polygon)
		if derived.is_empty() or not B.equal(AO.wire(derived),AO.wire(row.solid_polygons_px)): return {"passed":false,"error":"REAL_SOURCE_BASE_JAMBS_NOT_ESTIMATED_OR_DOOR_SPANNING"}
		measured.append({"asset":key,"complete_A1":used,"uniform_scale":scale,"conservative_world_door_height":door,"source_base_jambs_exactly_projected":true,"world_complete_width":width,"world_complete_height":height,"expanded_study_target_not_old_spec":i==1})
	return {"passed":true,"rows":measured,"not_generic_art_or_physics_credit":true}
func publication() -> Dictionary:
	if not need(READY and OS.get_cmdline_user_args().is_empty(),"PENDING_ACTUAL_ART_NOT_EXECUTABLE"): return {}
	var spec: Dictionary=AO.author()
	if not need(not spec.is_empty(),"AUTHOR_PENDING_OR_CHANGED"): return {}
	var assets: Dictionary=asset_facts(spec)
	if not need(assets.get("passed",false),"ACTUAL_SOURCE_ALPHA_DOOR_AND_JAMBS"): return {"asset_measurements":assets}
	for p: String in spec.source_sha256:
		if not track(p,spec.source_sha256[p]): return {}
	for pair: Array in [[spec.parent_packet_path,spec.parent_packet_sha256],[spec.parent_scene_path,spec.parent_scene_sha256],[spec.parent_layout_path,spec.parent_layout_sha256],[AO.AUTHOR,AO.AUTHOR_SHA]]:
		if not track(pair[0],pair[1]): return {}
	if not track(spec.parent_geometry_proof_manifest_path,spec.parent_geometry_proof_manifest_sha256): return {}
	var prior_proof: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.parent_geometry_proof_manifest_path))
	if not need(prior_proof is Dictionary and prior_proof.get("layout_proof",{}).get("passed")==true and prior_proof.layout_proof.get("full87517")==true,"IMMUTABLE_PARENT_COMPLETE_GEOMETRY_PROOF_FOR_INHERITANCE"): return {}
	for p: String in [get_script().resource_path,"res://build/luoyang_market_two_shops_20261021ao_system01/two_shops_READY.gd","res://build/luoyang_market_two_shops_20261021ao_system01/two_room_returns_READY.gd"]:
		if not track(p): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	var scene:=ResourceLoader.load(spec.parent_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent is Dictionary and B._plain(parent) and scene!=null and scene.map_layout!=null and B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"COMPLETE_ORIGINAL_NATIVE_STORAGE"): return {}
	var dir: String=AO.ROOT+String(AO.ID)+"/"
	if not need(not DirAccess.dir_exists_absolute(dir) and not FileAccess.file_exists(WALK),"NEW_OUTPUT_ONLY"): return {}
	var record: Dictionary=AO.compose(parent.record,spec,dir+"walk.png")
	if not need(not record.is_empty(),"EXACT_TWO_FOR_TWO_RECORD_WHOLE_INVERSE"): return {}
	if not track(record.raw_walk_path,spec.source_sha256.get(record.raw_walk_path,"MISSING_FIXED_RAW_PIN")): return {}
	var raw: Image=Image.load_from_file(record.raw_walk_path);var mask: Image=AO.c().raster_walk(raw,record.objects)
	if not need(mask!=null,"ONE_NEW_NATIVE_MASK_FROM_ORIGINAL_RAW"): return {}
	var changed: Array[Rect2]=[]
	for row: Dictionary in parent.record.objects:
		if String(row.id) in AO.OLD_IDS:
			for polygon: PackedVector2Array in AO.c().object_solids([row]): changed.append(bounds(polygon))
	for row: Dictionary in spec.new_objects:
		for polygon: PackedVector2Array in AO.c().object_solids([row]): changed.append(bounds(polygon))
	var delta: Dictionary=mask_delta(parent.walk_bytes,mask.get_data(),changed)
	if not need(delta.get("passed",false),"EXACT_LOCAL_FULL_RGBA_MASK_INVERSE"): return {"mask_delta":delta}
	var config: Dictionary=D.binding();var data: Dictionary=D.author(config)
	var t: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.district_t_author_path))
	var projection: Dictionary=T.district_projection(DG.project(data,AO.ID),AO.ID,t)
	if not need(not projection.is_empty() and D.cpu_proof_valid(config,data),"UNCHANGED_DISTRICT_AUTHOR_PROJECTION"): return {}
	var audit: Dictionary=route_audit(parent.record,record,mask,projection,changed,spec)
	if not need(audit.get("passed",false),"NEW_AND_AFFECTED_ONLY_BODY_NAV"): return {"geometry":audit}
	var child: SceneScript=AO.materialize(scene,record,spec)
	if not need(child!=null and AO.native_inverse(child,scene,spec),"NATIVE_ALL_STORAGE_WHOLE_INVERSE"): return {}
	var alpha_result: Dictionary=alpha(child,projection,spec)
	if not need(alpha_result.get("passed",false),"ACTUAL_36_ALPHA_AND_96_SIDE_ALLEY"): return {"alpha":alpha_result}
	var packet: Dictionary=parent.duplicate(true);packet.geometry_basis=AO.BASIS;packet.record=record;packet.solids=AO.c().object_solids(record.objects);packet.walk_bytes=mask.get_data();packet.mask_sha=B.bytes_sha(packet.walk_bytes);packet.scene_storage=B.storage(child);packet.layout_storage=B.storage(child.map_layout)
	packet["ao_parent_record"]=parent.record.duplicate(true);packet["ao_parent_packet_sha256"]=spec.parent_packet_sha256;packet["ao_author_sha256"]=AO.AUTHOR_SHA
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=parent[key]
	for key: String in ["ao_parent_record","ao_parent_packet_sha256","ao_author_sha256"]: inverse.erase(key)
	if not need(B.equal(inverse,parent),"WHOLE_TYPED_PACKET_INVERSE"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(dir)==OK and DirAccess.make_dir_recursive_absolute(WALK.get_base_dir())==OK and mask.save_png(WALK)==OK,"NEW_NATIVE_AND_BUILD_WALK_FOLDER"): return {}
	var check_mask: Image=Image.load_from_file(WALK)
	if check_mask!=null: check_mask.convert(Image.FORMAT_RGBA8)
	if not need(check_mask!=null and check_mask.get_data()==mask.get_data(),"MASK_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(child.map_layout,dir+"layout.res")==OK,"LAYOUT_WRITE"): return {}
	child.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(child.map_layout!=null and ResourceSaver.save(child,dir+"scene.res")==OK,"SCENE_WRITE"): return {}
	var readback:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),packet.scene_storage) and B.equal(B.storage(readback.map_layout),packet.layout_storage) and AO.native_inverse(readback,scene,spec),"NATIVE_READBACK_INVERSE"): return {}
	var f:=FileAccess.open(dir+"packet.bin",FileAccess.WRITE)
	if not need(f!=null and B._plain(packet),"PLAIN_PACKET_WRITE"): return {}
	f.store_buffer(var_to_bytes(packet));f.close()
	if not need(B.equal(bytes_to_var(FileAccess.get_file_as_bytes(dir+"packet.bin")),packet),"PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[dir+name]=FileAccess.get_sha256(dir+name)
	return {"published":true,"artifacts":artifacts,"walk_candidate":{"path":WALK,"sha256":FileAccess.get_sha256(WALK),"rgba_sha256":packet.mask_sha,"future_path":dir+"walk.png","not_promoted":true},"asset_measurements":assets,"geometry":audit,"mask_delta":delta,"alpha":alpha_result,"native_count":24,"district_count":36,"AN_native_portals_storage_untouched":true}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);began=Time.get_ticks_msec()
	var result: Dictionary=publication()
	if error.is_empty() and result.get("published",false):
		var returns: Dictionary=RETURNS.publish(AO.author(),Callable(self,"track"));result["two_room_returns"]=returns;need(returns.get("ok",false),"TWO_ROOM_RETURN_ONLY_SUCCESSOR:"+String(returns.get("error","")))
	var final: Dictionary={}
	for p: String in sources: final[p]=FileAccess.get_sha256(p);need(final[p]==sources[p],"SOURCE_FINAL:"+p)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED_60_SECOND_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published",false),"error":error,"source_first":sources,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"scope":"AO_ONLY_TWO_SHOPS_AND_TWO_RETURN_CHILDREN_NOT_FIELD_NOT_FORMAL"},true)
	var path: String=OUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: quit(1);return
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null: quit(1);return
	f.store_string(JSON.stringify(result,"\t",true,true));f.close();print(JSON.stringify({"passed":result.passed,"path":path,"error":error}));quit(0 if result.passed else 1)

