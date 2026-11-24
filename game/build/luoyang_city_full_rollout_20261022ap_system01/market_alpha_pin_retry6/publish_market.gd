extends SceneTree
## Root-only single-Market actual-art successor; no old suite replay.
const READY=true
const AP=preload("res://build/luoyang_city_full_rollout_20261022ap_system01/market_alpha_pin_retry6/market_transform.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const DG=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const D=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const T=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd")
const RETURNS=preload("res://build/luoyang_city_full_rollout_20261022ap_system01/five_room_returns.gd")
const OUT="res://build/luoyang_city_full_rollout_20261022ap_system01/market_alpha_pin_retry6/publication/"
const WALK="res://build/luoyang_city_full_rollout_20261022ap_system01/publication_assets/market_walk.png"
const LIMIT_MS=60000
var sources: Dictionary={}
var error: String=""
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AP "+label)
	return ok
func track(path: String,pin: String="") -> bool:
	if sources.has(path): return need(pin.is_empty() or sources[path]==pin,"SOURCE_FIRST_PIN:"+path)
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
	var solids: Array[PackedVector2Array]=AP.c().object_solids(record.objects);solids.append_array(DG.delta_solids(projection))
	var forced: Dictionary={}
	for route: Dictionary in spec.route_replacements+spec.additional_routes: forced[route.id]=true
	var paths: Array=record.routes.duplicate(true);var inherited: int=0;var checked: int=0;var failures: Array=[];var details: Array=[]
	for kind: String in ["npcs","interactions","portals"]:
		for slot: Dictionary in record.gameplay_slots.get(kind,[]):
			var point: Variant=slot.get("stand_px",slot.get("foot_px"))
			if point!=null: paths.append({"id":kind+":"+String(slot.get("source_id","")),"npc":kind=="npcs","points_px":[point,point]})
			if slot.has("passage_path_px"): paths.append({"id":"passage:"+String(slot.get("source_id","")),"points_px":slot.passage_path_px,"ao_added_route":slot.has("ao_original_slot")})
	for person: Dictionary in projection.spec.crowd:
		var p: Vector2=AP.v(person.foot_px);var distance: float=float(person.distance_px)
		paths.append({"id":"district:"+person.id,"npc":true,"points_px":[p-Vector2(distance,0),p+Vector2(distance,0)]})
	for p: Variant in projection.spec.protected_feet: paths.append({"id":"protected_district","points_px":[p,p]})
	for p: Variant in spec.protected_task_feet_px: paths.append({"id":"protected_task","points_px":[p,p]})
	for i: int in 2:
		var move: Dictionary=spec.room_moves[i];var p: Vector2=AP.v(move.return_foot_px);var threshold: Vector2=AP.v(spec.new_objects[i].world_foot_px)
		paths.append({"id":"real_threshold_return_plus10_and24:"+move.scene_id,"points_px":[threshold,p,p+Vector2(0,10),p+Vector2(0,24)],"ao_added_route":true})
	# The already-proved AN lane is not moved; only recheck if its body intersects this local delta.
	paths.append({"id":"AN_lane_2610_1860_keep","points_px":[Vector2(2610,1860),Vector2(2610,1884)]})
	for row: Dictionary in paths:
		var force: bool=forced.has(row.id) or row.get("ao_added_route",false);var local_count: int=0
		for segment: int in range(row.points_px.size()-1):
			var first: Vector2=AP.v(row.points_px[segment]);var last: Vector2=AP.v(row.points_px[segment+1]);var n: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for i: int in range(n+1):
				var foot: Vector2=first.lerp(last,float(i)/n);var npc: bool=row.get("npc",false)
				if not force and not point_near(foot,changed,npc): inherited+=1;continue
				checked+=1;local_count+=1
				if not AP.c()._safe_body_cpu(foot,mask,solids) or not T.seventeen(foot,mask) or (npc and not DG._npc_clear(foot,mask,solids)): failures.append({"route":row.id,"segment":segment,"sample":i,"foot":foot})
		if local_count>0: details.append({"id":row.id,"checked_samples":local_count,"entire_new_or_changed_route":force})
	return {"passed":failures.is_empty(),"checked_samples":checked,"unchanged_parent_samples_inherited_not_retested":inherited,"route_results":details,"failures":failures,"full87517":true,"npc1085":true,"max_step_px":4,"all_old_routes_retested":false}
func alpha(scene: SceneScript,projection: Dictionary,spec: Dictionary) -> Dictionary:
	var entries: Array=DG.apply_render(scene.map_layout.visual_objects,projection)
	if entries.size()!=36: return {"passed":false,"error":"EXACT_NATIVE24_PLUS_DG12"}
	var boxes: Dictionary={}
	for row: Dictionary in entries:
		if not spec.source_sha256.has(row.texture) or not track(row.texture,spec.source_sha256[row.texture]): return {"passed":false,"error":"PINNED_ACTUAL_ALPHA_SOURCE","id":row.id,"path":row.texture,"declared_sha256":spec.source_sha256.get(row.texture,"ABSENT")}
		var im: Image
		if String(row.texture).ends_with(".tres"):
			var native_texture: Texture2D=ResourceLoader.load(row.texture) as Texture2D
			im=native_texture.get_image() if native_texture!=null else null
		else: im=Image.load_from_file(row.texture)
		if im==null: return {"passed":false,"error":"ACTUAL_ALPHA_IMAGE"}
		var used: Rect2i=im.get_used_rect();var render: Vector2=AP.v(row.render_size_px);var origin: Vector2=AP.v(row.pos)*AP.SIZE
		if row.get("centered",true): origin-=render*.5
		var box:=Rect2(origin+Vector2(used.position)*render/Vector2(im.get_size()),Vector2(used.size)*render/Vector2(im.get_size()))
		if not used.has_area() or not Rect2(Vector2.ZERO,AP.SIZE).encloses(box) or boxes.has(row.id): return {"passed":false,"error":"ACTUAL_ALPHA_DOMAIN"}
		boxes[row.id]=box
	for id: String in AP.NEW_IDS+AP.MOVED_NATIVE_IDS+AP.MOVED_DISTRICT_IDS:
		for other: String in boxes:
			if id!=other and boxes[id].intersects(boxes[other],true): return {"passed":false,"error":"A_GREATER_THAN_ZERO_PROP_OVERLAP","pair":[id,other]}
	var gap: float=boxes[AP.NEW_IDS[1]].position.x-boxes[AP.NEW_IDS[0]].end.x
	return {"passed":gap>96.0,"full_alpha_gap":gap,"required_strictly_greater_than":96,"boxes":var_to_str(boxes),"all36_props_measured":true}
func asset_facts(spec: Dictionary) -> Dictionary:
	var rows: Array=[]
	for i: int in 2:
		var key: String="pawn" if i==0 else "tailor"
		var asset: Dictionary=spec.assets[key]
		if not track(asset.texture,asset.source_sha256): return {"passed":false,"error":"SOURCE_SHA"}
		var image: Image=Image.load_from_file(asset.texture)
		if image==null or Vector2(image.get_size())!=AP.v(asset.source_size_px): return {"passed":false,"error":"SOURCE_SIZE"}
		var used: Rect2i=image.get_used_rect()
		if used!=Rect2i(asset.alpha_rect_px[0],asset.alpha_rect_px[1],asset.alpha_rect_px[2],asset.alpha_rect_px[3]): return {"passed":false,"error":"COMPLETE_A1"}
		var scale_value: float=float(asset.scale)
		if float(asset.door_lower_px)*scale_value<120: return {"passed":false,"error":"ADULT_DOOR"}
		rows.append({"asset":key,"complete_A1":used,"uniform_scale":scale_value,"adult_door":float(asset.door_lower_px)*scale_value,"source_base_jambs":asset.solid_rects.duplicate(true)})
	return {"passed":true,"rows":rows}
func publication() -> Dictionary:
	if not need(READY and OS.get_cmdline_user_args().is_empty(),"PENDING_ACTUAL_ART_NOT_EXECUTABLE"): return {}
	if not track("res://build/luoyang_city_full_rollout_20261022ap_system01/market_navigation_retry5/room_relocations.json","2fc85298a8144efb585219609c514af40de512eea05b8b2bb3d264dcbd2c30dc"): return {}
	var spec: Dictionary=AP.author()
	if not need(not spec.is_empty(),"AUTHOR_PENDING_OR_CHANGED"): return {}
	var assets: Dictionary=asset_facts(spec)
	if not need(assets.get("passed",false),"ACTUAL_SOURCE_ALPHA_DOOR_AND_JAMBS"): return {"asset_measurements":assets}
	var execution: Dictionary=spec.cpu_execution_successor
	if not track(execution.receipt,execution.receipt_sha256): return {}
	var prior_release: Variant=JSON.parse_string(FileAccess.get_file_as_string(execution.receipt))
	if not need(prior_release is Dictionary and prior_release.get("targets") is Array and execution.rows.size()==2,"EXACT_AO_EXECUTION_SUCCESSOR_RECEIPT"): return {}
	var current_inputs: Dictionary={}
	for transition: Dictionary in execution.rows:
		if not need(transition.path in ["res://scripts/city/luoyang_district_life_20261016f.gd","res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"] and not current_inputs.has(transition.path) and spec.source_sha256.get(transition.path)==transition.historical_sha256,"CLOSED_TWO_HISTORICAL_INPUTS"): return {}
		if not track(transition.snapshot,transition.historical_sha256): return {}
		var matches: int=0
		for deployed: Dictionary in prior_release.targets:
			if deployed.get("target")==transition.path and deployed.get("old_sha256")==transition.historical_sha256 and deployed.get("candidate_sha256")==transition.current_sha256: matches+=1
		if not need(matches==1,"EXACT_AO_DEPLOYED_INPUT_EDGE:"+transition.path) or not track(transition.path,transition.current_sha256): return {}
		current_inputs[transition.path]=transition.current_sha256
	for p: String in spec.source_sha256:
		if current_inputs.has(p): continue
		if not track(p,spec.source_sha256[p]): return {}
	for pair: Array in [[spec.parent_packet_path,spec.parent_packet_sha256],[spec.parent_scene_path,spec.parent_scene_sha256],[spec.parent_layout_path,spec.parent_layout_sha256],[AP.AUTHOR,FileAccess.get_sha256(AP.AUTHOR)]]:
		if not track(pair[0],pair[1]): return {}
	if not track(spec.parent_geometry_report_path,spec.parent_geometry_report_sha256): return {}
	var prior_proof: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.parent_geometry_report_path))
	if not need(prior_proof is Dictionary and prior_proof.get("passed")==true and prior_proof.get("geometry",{}).get("passed")==true and prior_proof.geometry.get("full87517")==true,"IMMUTABLE_PARENT_COMPLETE_GEOMETRY_PROOF_FOR_INHERITANCE"): return {}
	for p: String in [get_script().resource_path,"res://build/luoyang_city_full_rollout_20261022ap_system01/market_alpha_pin_retry6/market_transform.gd","res://build/luoyang_city_full_rollout_20261022ap_system01/five_room_returns.gd"]:
		if not track(p): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	var scene:=ResourceLoader.load(spec.parent_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent is Dictionary and B._plain(parent) and scene!=null and scene.map_layout!=null and B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"COMPLETE_ORIGINAL_NATIVE_STORAGE"): return {}
	# Independently check the immutable native Scene portals, not just record slots.
	var native_counts: Array[int]=[0,0,0,0,0]
	for original_portal: Dictionary in scene.map_layout.portals:
		var room_index: int=AP.ROOM_IDS.find(String(original_portal.get("target_scene","")))
		if room_index>=0: native_counts[room_index]+=1
	if not need(native_counts==AP.NATIVE_COUNTS,"IMMUTABLE_PARENT_SCENE_FIVE_NATIVE_PORTAL_COUNTS"): return {"native_portal_counts":native_counts}
	var dir: String=AP.ROOT+String(AP.ID)+"/"
	if not need(not DirAccess.dir_exists_absolute(dir) and not FileAccess.file_exists(WALK),"NEW_OUTPUT_ONLY"): return {}
	var record: Dictionary=AP.compose(parent.record,spec,dir+"walk.png")
	if not need(not record.is_empty(),"EXACT_TWO_FOR_TWO_RECORD_WHOLE_INVERSE"): return {}
	if not track(record.raw_walk_path,spec.source_sha256.get(record.raw_walk_path,"MISSING_FIXED_RAW_PIN")): return {}
	var raw: Image=Image.load_from_file(record.raw_walk_path);var mask: Image=AP.c().raster_walk(raw,record.objects)
	if not need(mask!=null,"ONE_NEW_NATIVE_MASK_FROM_ORIGINAL_RAW"): return {}
	var changed: Array[Rect2]=[]
	for row: Dictionary in parent.record.objects:
		if String(row.id) in AP.OLD_IDS+AP.MOVED_NATIVE_IDS:
			for polygon: PackedVector2Array in AP.c().object_solids([row]): changed.append(bounds(polygon))
	for row: Dictionary in record.objects:
		if String(row.id) not in AP.NEW_IDS+AP.MOVED_NATIVE_IDS: continue
		for polygon: PackedVector2Array in AP.c().object_solids([row]): changed.append(bounds(polygon))
	var delta: Dictionary=mask_delta(parent.walk_bytes,mask.get_data(),changed)
	if not need(delta.get("passed",false),"EXACT_LOCAL_FULL_RGBA_MASK_INVERSE"): return {"mask_delta":delta}
	var config: Dictionary=D.binding();var data: Dictionary=D.author(config)
	var t: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.district_t_author_path))
	var original_projection: Dictionary=T.district_projection(DG.project(data,AP.ID),AP.ID,t)
	var projection: Dictionary=AP.project_district(original_projection,spec)
	if not need(not original_projection.is_empty() and not projection.is_empty(),"EXACT_THREE_DISTRICT_PROP_WHOLE_INVERSE"): return {}
	for move: Dictionary in spec.layout_successor.district_moves:
		for p: Dictionary in [AP.find(original_projection.additions,move.id),AP.find(projection.additions,move.id)]:
			for polygon: PackedVector2Array in DG.delta_solids({"additions":[p],"replacements":[]}): changed.append(bounds(polygon))
	if not need(not projection.is_empty() and D.cpu_proof_valid(config,data),"UNCHANGED_DISTRICT_AUTHOR_PROJECTION"): return {}
	var audit: Dictionary=route_audit(parent.record,record,mask,projection,changed,spec)
	if not need(audit.get("passed",false),"NEW_AND_AFFECTED_ONLY_BODY_NAV"): return {"geometry":audit}
	var child: SceneScript=AP.materialize(scene,record,spec)
	if not need(child!=null and AP.native_inverse(child,scene,spec),"NATIVE_ALL_STORAGE_WHOLE_INVERSE"): return {}
	var alpha_result: Dictionary=alpha(child,projection,spec)
	if not need(alpha_result.get("passed",false),"ACTUAL_36_ALPHA_AND_96_SIDE_ALLEY"): return {"alpha":alpha_result,"geometry":audit,"mask_delta":delta}
	var packet: Dictionary=parent.duplicate(true);packet.geometry_basis=AP.BASIS;packet.record=record;packet.solids=AP.c().object_solids(record.objects);packet.walk_bytes=mask.get_data();packet.mask_sha=B.bytes_sha(packet.walk_bytes);packet.scene_storage=B.storage(child);packet.layout_storage=B.storage(child.map_layout)
	packet["ap_parent_record"]=parent.record.duplicate(true);packet["ap_parent_packet_sha256"]=spec.parent_packet_sha256;packet["ap_author_sha256"]=FileAccess.get_sha256(AP.AUTHOR)
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=parent[key]
	for key: String in ["ap_parent_record","ap_parent_packet_sha256","ap_author_sha256"]: inverse.erase(key)
	if not need(B.equal(inverse,parent),"WHOLE_TYPED_PACKET_INVERSE"): return {}
	if not need(DirAccess.make_dir_recursive_absolute(dir)==OK and DirAccess.make_dir_recursive_absolute(WALK.get_base_dir())==OK and mask.save_png(WALK)==OK,"NEW_NATIVE_AND_BUILD_WALK_FOLDER"): return {}
	var check_mask: Image=Image.load_from_file(WALK)
	if check_mask!=null: check_mask.convert(Image.FORMAT_RGBA8)
	if not need(check_mask!=null and check_mask.get_data()==mask.get_data(),"MASK_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(child.map_layout,dir+"layout.res")==OK,"LAYOUT_WRITE"): return {}
	child.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(child.map_layout!=null and ResourceSaver.save(child,dir+"scene.res")==OK,"SCENE_WRITE"): return {}
	var readback:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),packet.scene_storage) and B.equal(B.storage(readback.map_layout),packet.layout_storage) and AP.native_inverse(readback,scene,spec),"NATIVE_READBACK_INVERSE"): return {}
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
		var return_spec: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://build/luoyang_city_full_rollout_20261022ap_system01/market_navigation_retry5/room_relocations.json"))
		var returns: Dictionary=RETURNS.publish(return_spec,Callable(self,"track"));result["five_room_returns"]=returns;need(returns.get("ok",false),"FIVE_ROOM_RETURN_ONLY_SUCCESSOR:"+String(returns.get("error","")))
	var final: Dictionary={}
	for p: String in sources: final[p]=FileAccess.get_sha256(p);need(final[p]==sources[p],"SOURCE_FINAL:"+p)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED_60_SECOND_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published",false),"error":error,"source_first":sources,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"scope":"AP_MARKET_PAWN_TAILOR_AND_FIVE_RETURN_ONLY_NATIVE_NOT_FIELD_NOT_FORMAL"},true)
	var path: String=OUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: quit(1);return
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null: quit(1);return
	f.store_string(JSON.stringify(result,"\t",true,true));f.close();print(JSON.stringify({"passed":result.passed,"path":path,"error":error}));quit(0 if result.passed else 1)
