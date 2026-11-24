extends SceneTree
## Root-only finite CPU publisher. This template is deliberately not executable.
## Never invokes C.prepare/resolve/collectors/raster_walk, Physics or Field.
const READY=true
const INPUT="res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/input_READY.json"
const INPUT_SHA="3739600a91f13531b633d215b04b92caa1eec70d8922727663868c0393afd5f7"
const OUT="res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/"
const SIZE=Vector2i(3072,2048)
const BASIS="FINITE_WALL_RETIREMENT_AND_YAMEN_WAITING_CLUSTER_EPOCH02_BUILD_ONLY"
const LIMIT_MS=60000
var pins: Dictionary={}
var config: Dictionary={}
var api: Variant
var wall: Variant
var clerk: Variant
var dg: Variant
var failure: String=""
var began: int=0
var checks: int=0

func _initialize() -> void: call_deferred("_run")
func require(ok: bool,label: String) -> bool:
	checks+=1
	if not ok and failure.is_empty(): failure=label;push_error("FINITE_TWO_DOMAIN:"+label)
	return ok
func track(path: String,pin: String="") -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not require(path.begins_with("res://") and ".." not in path and actual.length()==64 and (pin.is_empty() or actual==pin) and (not pins.has(path) or pins[path]==actual),"SOURCE_PIN:"+path): return false
	pins[path]=actual;return true
func read_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if not raw is Array or raw.size()!=2: return Vector2(INF,INF)
	for scalar: Variant in raw:
		if typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)): return Vector2(INF,INF)
	return Vector2(raw[0],raw[1])
func polygon(raw: Variant) -> PackedVector2Array:
	var output:=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return output
	for point: Variant in raw:
		var p: Vector2=v(point)
		if not p.is_finite(): return PackedVector2Array()
		output.append(p)
	return output
func bounds(poly: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in poly: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
func raster_domain(poly: PackedVector2Array) -> Rect2i:
	var b: Rect2=bounds(poly)
	return Rect2i(Vector2i(floori(b.position.x),floori(b.position.y)),Vector2i(ceili(b.end.x)+1,ceili(b.end.y)+1)-Vector2i(floori(b.position.x),floori(b.position.y)))
func closed_box_hit(a: Rect2,b: Rect2) -> bool:
	return a.position.x<=b.end.x and a.end.x>=b.position.x and a.position.y<=b.end.y and a.end.y>=b.position.y
func native_solids(record: Dictionary) -> Array[PackedVector2Array]:
	return wall.native_solids(record.objects)
func fixture_solids(spec: Dictionary,native_only: bool=false) -> Array[PackedVector2Array]:
	var output: Array[PackedVector2Array]=[]
	for row: Dictionary in spec.raw_geometry.solids:
		if native_only and row.kind=="ADDITIVE_NATIVE_BASE": continue
		output.append(polygon(row.points_px))
	return output
func load_mask(path: String) -> Image:
	var image: Image=Image.load_from_file(path)
	if image!=null: image.convert(Image.FORMAT_RGBA8)
	return image
func exact_polygon_multiset(actual: Array[PackedVector2Array],expected: Array[PackedVector2Array]) -> bool:
	# Independent source oracle order need not equal original object ordinal.
	# Every complete typed polygon must match exactly, once; no epsilon/reorder
	# inside a polygon, no count loss, no current-data expected reconstruction.
	if actual.size()!=expected.size(): return false
	var used: Array[bool]=[]
	for index: int in expected.size(): used.append(false)
	for poly: PackedVector2Array in actual:
		var match_index: int=-1
		for index: int in expected.size():
			if not used[index] and api.equal(poly,expected[index]): match_index=index;break
		if match_index<0: return false
		used[match_index]=true
	return true
func parent_native(spec: Dictionary) -> Dictionary:
	var data: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.packet_path))
	var scene:=ResourceLoader.load(spec.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var image: Image=load_mask(spec.walk_path)
	if not require(data is Dictionary and api._plain(data) and scene!=null and scene.map_layout!=null and image!=null,"FROZEN_PARENT_NATIVE:"+spec.scene_id): return {}
	if not require(data.record.canonical_scene_id==spec.scene_id and data.record.objects.size()==24 and scene.map_layout.visual_objects.size()==24,"EXACT_PARENT_24_NATIVE:"+spec.scene_id): return {}
	if not require(api.equal(api.storage(scene),data.scene_storage) and api.equal(api.storage(scene.map_layout),data.layout_storage),"WHOLE_PARENT_STORAGE:"+spec.scene_id): return {}
	if not require(image.get_size()==SIZE and image.get_data()==data.walk_bytes and api.bytes_sha(data.walk_bytes)==spec.mask_rgba_sha256 and data.mask_sha==spec.mask_rgba_sha256,"PARENT_PNG_PACKET_RGBA:"+spec.scene_id): return {}
	var expected_native: Array[PackedVector2Array]=fixture_solids(spec,true)
	if not require(api.equal(native_solids(data.record),data.solids) and exact_polygon_multiset(data.solids,expected_native),"INDEPENDENT_NATIVE_SOLIDS_IN_FIXED_COMBINED_ORACLE:"+spec.scene_id): return {}
	if not require(api.equal(api.storage(scene.map_layout),api.storage(ResourceLoader.load(spec.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE))),"EXACT_PARENT_LAYOUT_ARTIFACT:"+spec.scene_id): return {}
	if not require(data.record.raw_walk_path==spec.raw_walk_path,"EXACT_PARENT_RAW_PATH:"+spec.scene_id): return {}
	return {"packet":data,"scene":scene,"mask":image}
func safe_body(foot: Vector2,mask: Image,solids: Array[PackedVector2Array],npc: bool=false) -> bool:
	var half:=Vector2(17,15 if npc else 12)
	if not foot.is_finite() or foot.x-half.x<0 or foot.y-half.y<0 or roundi(foot.x+half.x)>=SIZE.x or roundi(foot.y+half.y)>=SIZE.y: return false
	var r:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
	# Original DG closed-boundary + rounded-hull1085 rules, never an epsilon.
	if not dg.safe_foot(solids,foot,half) or (npc and not dg._npc_clear(foot,mask,solids)): return false
	for solid: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(body,solid).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,solid): return false
	for y: int in range(roundi(r.position.y),roundi(r.end.y)+1):
		for x: int in range(roundi(r.position.x),roundi(r.end.x)+1):
			var color: Color=mask.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	# Exact original seventeen mask probes, additional to every875/1085pixel.
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var point:=Vector2i((foot+offset).round())
		var color: Color=mask.get_pixelv(point)
		if color.r<.5 or color.a<.5: return false
	return true
func collect_paths(record: Dictionary,district: Dictionary) -> Array:
	var paths: Array=record.routes.duplicate(true)
	for key: String in ["entry_foot_px","return_foot_px"]:
		if record.has(key): paths.append({"id":key,"points_px":[record[key],record[key]]})
	for kind: String in ["npcs","interactions","portals"]:
		for row: Dictionary in record.get("gameplay_slots",{}).get(kind,[]):
			for key: String in ["stand_px","foot_px","arrival_foot_px"]:
				if row.has(key): paths.append({"id":kind+":"+String(row.get("source_id",""))+":"+key,"points_px":[row[key],row[key]],"npc":kind=="npcs"})
			if row.has("passage_path_px"): paths.append({"id":"passage:"+String(row.get("source_id","")),"points_px":row.passage_path_px.duplicate(true)})
	for person: Dictionary in district.crowd:
		var foot: Vector2=v(person.foot_px);var distance: float=float(person.distance_px)
		paths.append({"id":"district:"+String(person.id),"points_px":[foot-Vector2(distance,0),foot+Vector2(distance,0)],"npc":true,"real_original_npc_lane":true})
	for index: int in district.protected_feet.size():
		var foot: Variant=district.protected_feet[index]
		paths.append({"id":"protected_district:"+str(index),"points_px":[foot,foot]})
	return paths
func route_delta_audit(parent_record: Dictionary,record: Dictionary,district: Dictionary,spec: Dictionary,mask: Image,solids: Array[PackedVector2Array],domains: Array[Rect2],changed_segments: Dictionary,new_paths: Array,all_six_lanes: bool=false) -> Dictionary:
	var paths: Array=collect_paths(record,district);paths.append_array(new_paths.duplicate(true))
	var new_ids: Dictionary={}
	for row: Dictionary in new_paths: new_ids[row.id]=true
	var failures: Array=[];var rows: Array=[];var checked: int=0;var inherited: int=0;var complete_lanes: int=0
	for path: Dictionary in paths:
		var npc: bool=path.get("npc",false)
		var forced: bool=new_ids.has(path.id) or (all_six_lanes and path.get("real_original_npc_lane",false))
		if all_six_lanes and path.get("real_original_npc_lane",false): complete_lanes+=1
		for segment: int in range(path.points_px.size()-1):
			var a: Vector2=v(path.points_px[segment]);var z: Vector2=v(path.points_px[segment+1])
			if not a.is_finite() or not z.is_finite(): return {"passed":false,"error":"NONFINITE_ROUTE"}
			var full: bool=forced or segment in changed_segments.get(path.id,[])
			var selected: bool=full
			var sweep:=Rect2(a.min(z),a.max(z)-a.min(z)).grow_individual(17,15,17,15)
			for domain: Rect2 in domains:
				if closed_box_hit(sweep,domain): selected=true
			if not selected: inherited+=1;continue
			var count: int=0;var steps: int=maxi(1,ceili(a.distance_to(z)/4.0))
			for index: int in range(steps+1):
				var foot: Vector2=a.lerp(z,float(index)/steps)
				var local: bool=full
				if not full:
					var body:=Rect2(foot-Vector2(17,15 if npc else 12),Vector2(34,30 if npc else 24))
					for domain: Rect2 in domains:
						if closed_box_hit(body,domain): local=true
				if not local: continue
				checked+=1;count+=1
				if not safe_body(foot,mask,solids,npc): failures.append({"id":path.id,"segment":segment,"sample":index,"foot":foot,"npc":npc})
			rows.append({"id":path.id,"segment":segment,"samples":count,"entire_changed_or_new_segment":full,"npc_full1085":npc})
	return {"passed":failures.is_empty() and (not all_six_lanes or complete_lanes==6),"checked_samples":checked,"failures":failures,"segments":rows,"unaffected_segments_inherited_not_replayed":inherited,"complete_real_NPC_lanes":complete_lanes,"max_step_px":4,"body_px":[34,24],"full875_plus17":true,"all_old_routes_replayed":false}
func yamen_route_detour(parent: Dictionary,proof: Dictionary) -> Dictionary:
	var result: Dictionary=parent.duplicate(true);var found: Dictionary={};var changed: Dictionary={}
	for original: Dictionary in proof.original_route_dictionaries:
		var index: int=-1
		for i: int in result.routes.size():
			if result.routes[i].id==original.id:
				if index!=-1: return {}
				index=i
		if index<0 or not api.equal(result.routes[index],original): return {}
		found[original.id]=index
	for delta: Dictionary in proof.exact_four_ordinal_changes:
		var route_index: int=int(found[delta.route_id]);var ordinal: int=int(delta.point_ordinal)
		if not api.equal(result.routes[route_index].points_px[ordinal],delta.before): return {}
		result.routes[route_index].points_px[ordinal]=delta.after.duplicate()
		if not changed.has(delta.route_id): changed[delta.route_id]=[]
		for segment: int in [ordinal-1,ordinal]:
			if segment>=0 and segment<result.routes[route_index].points_px.size()-1 and segment not in changed[delta.route_id]: changed[delta.route_id].append(segment)
	var inverse: Dictionary=result.duplicate(true)
	for delta: Dictionary in proof.exact_four_ordinal_changes: inverse.routes[found[delta.route_id]].points_px[int(delta.point_ordinal)]=delta.before.duplicate()
	return {"record":result,"changed_segments":changed,"whole_inverse":true} if api.equal(inverse,parent) else {}
func add_prop(asset: Dictionary,placement: Dictionary) -> Dictionary:
	var size: Vector2=v(asset.source_size_px);var anchor: Vector2=v(asset.source_ground_anchor_px);var foot: Vector2=v(placement.foot_px);var scale_value: float=float(placement.uniform_scale)
	if size!=Vector2(1536,1024) or scale_value!=.12 or not foot.is_finite(): return {}
	var polys: Array=[]
	for source_poly: Variant in asset.source_ground_solid_polygons_px:
		var points: Array=[]
		for point: Vector2 in polygon(source_poly): points.append(foot+(point-anchor)*scale_value)
		if points.size()<3 or Geometry2D.triangulate_polygon(polygon(points)).is_empty(): return {}
		polys.append(points)
	return {"id":placement.id,"prototype":"","nature":"existing_full_canvas_yamen_low_prop","role":"yamen_low_prop","texture":asset.texture,"source":asset.texture,"source_sha256":asset.media_three_leaves[0].sha256,"source_size_px":[1536,1024],"render_size_px":size*scale_value,"foot_uv":anchor/size,"world_foot_px":foot,"physical_center_px":foot,"collision_size_px":Vector2.ZERO,"solid_polygons_px":polys,"blocking":true,"sort_by_feet":true,"depth_foot_y":foot.y,"walk_support":false,"ghost_occlusion":false,"height_behavior":"LOW_OPAQUE_ACTOR_LOCAL_GHOST","requires_exact_future_Yamen_consumer":true}
func render_entry(row: Dictionary) -> Dictionary:
	var output: Dictionary=row.duplicate(true);var size: Vector2=v(row.render_size_px);var foot: Vector2=v(row.world_foot_px)
	output.pos=(foot+(Vector2(.5,.5)-v(row.foot_uv))*size)/Vector2(SIZE);output.centered=true;output.depth_sort_foot_y=foot.y/SIZE.y
	output.city_v3_solid_polygons_px=row.solid_polygons_px.duplicate(true);output.erase("solid_polygons_px")
	return output
func add_only_local_mask(parent: Image,raw: Image,old_objects: Array,new_objects: Array,domains: Array[Rect2i]) -> Dictionary:
	var output: Image=parent.duplicate() as Image;var changes: Array=[];var visited: int=0
	var old_bytes: PackedByteArray=parent.get_data()
	for domain: Rect2i in domains:
		for y: int in range(domain.position.y,domain.end.y):
			for x: int in range(domain.position.x,domain.end.x):
				visited+=1;var point:=Vector2(x,y);var base: Color=raw.get_pixel(x,y)
				var expected: Color=Color.BLACK if wall.native_raster_blocked(point,old_objects) else base
				if parent.get_pixel(x,y)!=expected: return {"ok":false,"error":"LOCAL_PARENT_RAW_NATIVE_MISMATCH","point":point}
				var desired: Color=Color.BLACK if wall.native_raster_blocked(point,new_objects) else base
				if output.get_pixel(x,y)==desired: continue
				if desired!=Color.BLACK: return {"ok":false,"error":"ADD_ONLY_NATIVE_NONBLACK_DELTA"}
				changes.append({"x":x,"y":y,"old":output.get_pixel(x,y),"new":desired});output.set_pixel(x,y,desired)
	var inverse: PackedByteArray=output.get_data().duplicate()
	for row: Dictionary in changes:
		var offset: int=(int(row.y)*SIZE.x+int(row.x))*4
		for channel: int in 4: inverse[offset+channel]=old_bytes[offset+channel]
	if inverse!=old_bytes or changes.is_empty(): return {"ok":false,"error":"ADD_ONLY_WHOLE_RGBA_INVERSE"}
	return {"ok":true,"mask":output,"changed":changes,"visited_pixels":visited,"domains":domains,"full_RGBA_inverse":true,"outside_domains_byte_identical":true,"raw_plus_native_not_blind_black":true,"DG_not_baked_into_native_mask":true}
func child_scene(parent: SceneScript,record: Dictionary,visuals: Array) -> SceneScript:
	var child:=parent.duplicate(true) as SceneScript;child.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	child.map_layout.visual_objects.clear();child.map_layout.visual_objects.append_array(visuals.duplicate(true));child.map_layout.walkable_mask_path=record.walk_path
	return child
func scene_inverse(child: SceneScript,parent: SceneScript) -> bool:
	var inverse:=child.duplicate(true) as SceneScript;inverse.map_layout=child.map_layout.duplicate(true) as WalkableMapLayout
	inverse.map_layout.visual_objects.clear();inverse.map_layout.visual_objects.append_array(parent.map_layout.visual_objects.duplicate(true));inverse.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path
	return api.equal(api.storage(inverse),api.storage(parent)) and api.equal(api.storage(inverse.map_layout),api.storage(parent.map_layout))
func save_json(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
func plain_mask_proof(delta: Dictionary,parent: Image,child: Image) -> Dictionary:
	var output: Dictionary=delta.duplicate(true);output.erase("mask")
	var before: PackedByteArray=parent.get_data();var after: PackedByteArray=child.get_data();var rows: Array=[]
	for change: Dictionary in delta.changed:
		var offset: int=(int(change.y)*SIZE.x+int(change.x))*4
		rows.append({"x":change.x,"y":change.y,"old_RGBA":[before[offset],before[offset+1],before[offset+2],before[offset+3]],"new_RGBA":[after[offset],after[offset+1],after[offset+2],after[offset+3]]})
	output.changed=rows;output.parent_rgba_sha256=api.bytes_sha(before);output.child_rgba_sha256=api.bytes_sha(after)
	return output
func write_domain(spec: Dictionary,parent: Dictionary,record: Dictionary,visuals: Array,mask: Image,proof: Dictionary) -> Dictionary:
	var directory: String=OUT+spec.domain_id+"/";var child: SceneScript=child_scene(parent.scene,record,visuals)
	if not require(scene_inverse(child,parent.scene),"WHOLE_NATIVE_SCENE_LAYOUT_INVERSE:"+spec.domain_id): return {}
	var packet: Dictionary=parent.packet.duplicate(true)
	for key: String in ["record","solids","walk_bytes","mask_sha","scene_storage","layout_storage","geometry_basis"]:
		match key:
			"record": packet[key]=record
			"solids": packet[key]=native_solids(record)
			"walk_bytes": packet[key]=mask.get_data()
			"mask_sha": packet[key]=api.bytes_sha(mask.get_data())
			"scene_storage": packet[key]=api.storage(child)
			"layout_storage": packet[key]=api.storage(child.map_layout)
			"geometry_basis": packet[key]=BASIS+":"+spec.domain_id
	packet["finite_delta_parent_packet_sha256"]=spec.packet_sha256;packet["finite_delta_input_sha256"]=INPUT_SHA;packet["finite_delta_domain_id"]=spec.domain_id
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in ["record","solids","walk_bytes","mask_sha","scene_storage","layout_storage","geometry_basis"]:
		if parent.packet.has(key): inverse[key]=parent.packet[key]
		else: inverse.erase(key)
	for key: String in ["finite_delta_parent_packet_sha256","finite_delta_input_sha256","finite_delta_domain_id"]: inverse.erase(key)
	if not require(api.equal(inverse,parent.packet) and api._plain(packet),"WHOLE_TYPED_PACKET_INVERSE:"+spec.domain_id): return {}
	if not require(not DirAccess.dir_exists_absolute(directory) and DirAccess.make_dir_recursive_absolute(directory)==OK,"ABSENT_NEW_DOMAIN_OUTPUT:"+spec.domain_id): return {}
	if not require(mask.save_png(directory+"walk.png")==OK,"NEW_BUILD_MASK_WRITE:"+spec.domain_id): return {}
	var readmask: Image=load_mask(directory+"walk.png")
	if not require(readmask!=null and readmask.get_data()==packet.walk_bytes,"FULL_MASK_READBACK:"+spec.domain_id): return {}
	if not require(ResourceSaver.save(child.map_layout,directory+"layout.res")==OK,"NEW_LAYOUT_WRITE:"+spec.domain_id): return {}
	child.map_layout=ResourceLoader.load(directory+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not require(child.map_layout!=null and ResourceSaver.save(child,directory+"scene.res")==OK,"NEW_SCENE_WRITE:"+spec.domain_id): return {}
	var back:=ResourceLoader.load(directory+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not require(back!=null and api.equal(api.storage(back),packet.scene_storage) and api.equal(api.storage(back.map_layout),packet.layout_storage) and scene_inverse(back,parent.scene),"WHOLE_NATIVE_READBACK:"+spec.domain_id): return {}
	var file:=FileAccess.open(directory+"packet.bin",FileAccess.WRITE)
	if not require(file!=null,"NEW_PACKET_FILE:"+spec.domain_id): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	if not require(api.equal(bytes_to_var(FileAccess.get_file_as_bytes(directory+"packet.bin")),packet),"WHOLE_PACKET_READBACK:"+spec.domain_id): return {}
	var artifacts: Dictionary={}
	for name: String in ["layout.res","scene.res","packet.bin","walk.png"]: artifacts[directory+name]=FileAccess.get_sha256(directory+name)
	var manifest: Dictionary={"kind":"FINITE_GEOMETRY_BUILD_CANDIDATE_NOT_RUNTIME_ADMISSION","formal_enabled":false,"scene_id":spec.scene_id,"geometry_basis":BASIS+":"+spec.domain_id,"artifacts":artifacts,"mask_sha256":packet.mask_sha,"parent_publication":{"path":spec.parent_manifest_path,"sha256":spec.parent_manifest_sha256,"complete_immutable_manifest":read_json(spec.parent_manifest_path)},"fixed_input":{"path":INPUT,"sha256":INPUT_SHA},"finite_geometry_proof":proof,"runtime_source_closure_pending":true,"native_physics_not_run":true,"outdoor_art_not_accepted":true,"source_first":pins.duplicate(true),"status":"LOCAL_GEOMETRY_ONLY_IMPORT_ADAPTER_METADATA_FIELD_ART_PENDING"}
	if not require(save_json(directory+"manifest_PENDING.json",manifest),"NEW_NON_ADMITTING_METADATA_WRITE:"+spec.domain_id): return {}
	return {"published":true,"artifacts":artifacts,"mask_rgba_sha256":packet.mask_sha,"native_visual_count":visuals.size(),"native_solid_count":packet.solids.size(),"combined_solid_count":spec.raw_geometry.solids.size()+(-1 if spec.domain_id=="market" else 3),"native_whole_inverse":true,"packet_whole_inverse":true,"finite_proof":proof,"future_metadata_path":directory+"manifest_PENDING.json","future_metadata_sha256":FileAccess.get_sha256(directory+"manifest_PENDING.json")}
func publish_market(spec: Dictionary) -> Dictionary:
	var parent: Dictionary=parent_native(spec)
	if parent.is_empty(): return {}
	var transformed: Dictionary=wall.remove_record(parent.packet.record);var visual: Dictionary=wall.remove_visuals(parent.scene.map_layout.visual_objects)
	if not require(transformed.get("ok",false) and visual.get("ok",false),"EXACT_MARKET_REMOVE_ONE_RECORD_VISUAL"): return {}
	var record: Dictionary=transformed.record;record.walk_path=OUT+"market/walk.png"
	var old: Dictionary=record.duplicate(true);old.objects.insert(transformed.ordinal,transformed.removed.duplicate(true));old.walk_path=parent.packet.record.walk_path
	if not require(api.equal(old,parent.packet.record),"WHOLE_MARKET_RECORD_WITH_NEW_BUILD_WALK_INVERSE"): return {}
	var raw: Image=load_mask(spec.raw_walk_path)
	var delta: Dictionary=wall.local_mask_delta(parent.mask,raw,parent.packet.record.objects,record.objects)
	if not require(delta.get("ok",false),"MARKET_ONLY_111_BY_13_RAW_DERIVED_MASK:"+String(delta.get("error",""))): return {"mask_delta":delta}
	var solids: Array[PackedVector2Array]=fixture_solids(spec);var target: PackedVector2Array=wall.expected_polygon();var removed: int=0
	for i: int in range(solids.size()-1,-1,-1):
		if api.equal(solids[i],target): solids.remove_at(i);removed+=1
	if not require(removed==1 and solids.size()==43,"MARKET_FIXED_RAW_ORACLE_44_TO43"): return {}
	var domains: Array[Rect2]=[Rect2(Vector2(wall.DOMAIN.position),Vector2(wall.DOMAIN.size))]
	var paths: Array=[{"id":"former_wall_crossing","points_px":[Vector2(90,1388),Vector2(90,1440)]},{"id":"former_wall_stand","points_px":[Vector2(90,1414),Vector2(90,1414)]}]
	if not require(not safe_body(Vector2(90,1414),parent.mask,fixture_solids(spec)),"FORMER_WALL_OLD_STAND_REJECTS"): return {}
	var audit: Dictionary=route_delta_audit(parent.packet.record,record,config.district_author.districts[spec.scene_id],spec,delta.mask,solids,domains,{},paths)
	if not require(audit.get("passed",false),"MARKET_NEW_AND_AFFECTED_87517_ONLY"): return {"geometry":audit}
	var proof: Dictionary={"geometry":audit,"mask_delta":plain_mask_proof(delta,parent.mask,delta.mask),"native24_to23":true,"DG12_unchanged":true,"combined_visual36_to35":true,"fixed_raw_solids44_to43":true,"removed_record":transformed.removed,"record_removed_ordinal":transformed.ordinal,"visual_removed_ordinal":visual.ordinal,"old_stand_rejected_new_stand_checked":true}
	return write_domain(spec,parent,record,visual.visuals,delta.mask,proof)
func publish_yamen(spec: Dictionary) -> Dictionary:
	var parent: Dictionary=parent_native(spec)
	if parent.is_empty(): return {}
	var route_proof: Dictionary=read_json(config.route_correction_path)
	var detour: Dictionary=yamen_route_detour(parent.packet.record,route_proof)
	if not require(not detour.is_empty(),"YAMEN_COMPLETE_REAL_PARENT_TWO_ROUTE_DICTIONARIES_AND_FOUR_ORDINALS"): return {}
	var proposal: Dictionary=read_json(config.yamen_proposal_path);var record: Dictionary=detour.record
	var visuals: Array=parent.scene.map_layout.visual_objects.duplicate(true);var new_props: Array=[];var domains: Array[Rect2i]=[];var near_domains: Array[Rect2]=[]
	for placement: Dictionary in proposal.placements:
		var asset: Dictionary={}
		for candidate: Dictionary in proposal.assets:
			if candidate.asset_id==placement.asset_id: asset=candidate
		var object: Dictionary=add_prop(asset,placement)
		if not require(not object.is_empty(),"EXACT_SOURCE_NATIVE_PROP:"+placement.id): return {}
		for old: Dictionary in record.objects:
			if not require(old.id!=object.id,"NEW_PROP_ID_ABSENT"): return {}
		new_props.append(object);record.objects.append(object);visuals.append(render_entry(object))
		for poly: Variant in object.solid_polygons_px:
			var domain: Rect2i=raster_domain(polygon(poly));domains.append(domain);near_domains.append(Rect2(Vector2(domain.position),Vector2(domain.size)))
	var expected_domains: Array=[]
	for row: Array in spec.local_mask_domains_px: expected_domains.append(Rect2i(row[0],row[1],row[2],row[3]))
	if not require(api.equal(domains,expected_domains) and record.objects.size()==27 and visuals.size()==27,"YAMEN_EXACT_THREE_LOCAL_DOMAINS_24_TO27_NATIVE"): return {}
	record.walk_path=OUT+"yamen/walk.png"
	var record_inverse: Dictionary=record.duplicate(true)
	for i: int in 3: record_inverse.objects.pop_back()
	record_inverse.routes=parent.packet.record.routes.duplicate(true);record_inverse.walk_path=parent.packet.record.walk_path
	if not require(api.equal(record_inverse,parent.packet.record),"YAMEN_RECORD_ONLY_3PROPS_4ROUTEPOINTS_NEW_WALK_INVERSE"): return {}
	var delta: Dictionary=add_only_local_mask(parent.mask,load_mask(spec.raw_walk_path),parent.packet.record.objects,record.objects,domains)
	if not require(delta.get("ok",false) and delta.get("visited_pixels")==7622,"YAMEN_ONLY7622_RAW_NATIVE_LOCAL_BLACKENING:"+String(delta.get("error",""))): return {"mask_delta":delta}
	var solids: Array[PackedVector2Array]=fixture_solids(spec);solids.append_array(wall.native_solids(new_props))
	if not require(solids.size()==42 and native_solids(record).size()==32,"YAMEN_NATIVE29_TO32_DG10_OLD39_TO42"): return {}
	var original_clerk_pair: Array=[]
	for row: Dictionary in config.district_author.districts[spec.scene_id].crowd:
		if row.id=="yamen_clerk": original_clerk_pair=row.foot_px.duplicate()
	var altered: Dictionary=clerk.apply_clerk_foot(config.district_author)
	if not require(not altered.is_empty() and api.equal(clerk.inverse_clerk_foot(altered,original_clerk_pair),config.district_author),"YAMEN_ONLY_CLERK_OVERLAY_WHOLE_AUTHOR_INVERSE"): return {}
	var district: Dictionary=altered.districts[spec.scene_id]
	if not require(api.equal(parent.packet.record.gameplay_slots.npcs,spec.source_native_npc_stations),"YAMEN_EXACT_THREE_NATIVE_SOURCE_NPC_ANCHORS"): return {}
	var finite_paths: Array=proposal.static_routes.duplicate(true)
	for row: Dictionary in spec.source_native_npc_stations:
		finite_paths.append({"id":"unchanged_native_source_npc_anchor:"+String(row.source_id),"npc":true,"points_px":[row.foot_px,row.foot_px],"source_foot_only_not_actor_spawn_or_visibility_claim":true})
	finite_paths.append({"id":"inherited_court_loop_segment5_y1135_horizontal_witness","points_px":[Vector2(300,1135),Vector2(1100,1135)],"unchanged_parent_segment":5})
	finite_paths.append({"id":"inherited_court_loop_segment6_y1135_vertical_witness","points_px":[Vector2(1100,1135),Vector2(1100,1080)],"unchanged_parent_segment":6})
	var audit: Dictionary=route_delta_audit(parent.packet.record,record,district,spec,delta.mask,solids,near_domains,detour.changed_segments,finite_paths,true)
	if not require(audit.get("passed",false),"YAMEN_NEW_AFFECTED_CHANGED_AND_ALL6_REAL_NPC_LANES_87517"): return {"geometry":audit}
	# Explicit near-tangent inherited west return: no epsilon relaxation.
	var near_gap: Dictionary={"id":"court_loop_inherited_y1135_north_bench_gap","unchanged_parent_segments":[5,6],"points":[[300,1135],[1100,1135],[1100,1080]],"north_bench_min_y":bounds(polygon(new_props[0].solid_polygons_px[0])).position.y,"body_bottom_at1135":1147,"gap_px":bounds(polygon(new_props[0].solid_polygons_px[0])).position.y-1147,"passed":audit.passed,"basis":"Two complete original segments checked in finite witness rows at max4px,34x24/full875+17; no epsilon/body shrink."}
	var alpha: Array=[]
	for asset: Dictionary in proposal.assets:
		var image: Image=Image.load_from_file(asset.texture)
		if not require(image!=null and image.get_size()==Vector2i(1536,1024),"EXACT_FULL_UNCROPPED_PROP_CANVAS"): return {}
		var used: Rect2i=image.get_used_rect();var expected: Array=asset.alpha_bbox_nonzero_xyxy
		if not require(used==Rect2i(expected[0],expected[1],expected[2]-expected[0],expected[3]-expected[1]),"FURNITURE_COMPLETE_A1_NO_CROP"): return {}
		alpha.append({"asset_id":asset.asset_id,"source_sha256":asset.media_three_leaves[0].sha256,"size":[1536,1024],"actual_A1":used,"strict_margin_pass":false,"outdoor_composite_art_pending":true,"source_unchanged":true})
	var overlay: Dictionary={"status":"BUILD_ONLY_EXACT_YAMEN_CLERK_FOOT_OVERLAY_NOT_GLOBAL_D98_AUTHOR_REPLACEMENT","parent_author":{"path":config.district_author_path,"sha256":config.source_pins[config.district_author_path]},"scene_id":spec.scene_id,"id":"yamen_clerk","before":[1260,1500],"after":[1130,1360],"old_spec":config.district_author.districts[spec.scene_id],"new_spec":district,"whole_author_inverse":true,"D98_8BCE_and_old10placements_unchanged":true,"future_Yamen_only_consumer_required":true}
	if not require(save_json(OUT+"yamen_clerk_overlay_PENDING.json",overlay),"NEW_YAMEN_ONLY_OVERLAY_PROOF_NOT_D98_WRITE"): return {}
	var proof: Dictionary={"geometry":audit,"mask_delta":plain_mask_proof(delta,parent.mask,delta.mask),"route_ordinal_correction":route_proof.exact_four_ordinal_changes,"changed_route_segments":detour.changed_segments,"whole_record_inverse":true,"whole_route_inverse":true,"near_tangent_inherited_segment":near_gap,"source_alpha":alpha,"clerk_overlay_path":OUT+"yamen_clerk_overlay_PENDING.json","clerk_overlay_sha256":FileAccess.get_sha256(OUT+"yamen_clerk_overlay_PENDING.json"),"native_visual24_to27":true,"native_solid29_to32":true,"DG10_old_solids_and_placements_unchanged":true,"combined_solids39_to42":true,"existing_native_ghost_rules_not_widened":true,"future_Yamen_low_prop_gate_and_actor_local_ghost_pending":true}
	return write_domain(spec,parent,record,visuals,delta.mask,proof)
func publication() -> Dictionary:
	if not require(READY and OS.get_cmdline_user_args().is_empty(),"ROOT_ONLY_READY_NO_ADDITIONAL_ARGS"): return {}
	if not track(INPUT,INPUT_SHA): return {}
	config=read_json(INPUT)
	if not require(config.get("status")=="FROZEN_FINITE_TWO_DOMAIN_ROOT_ONLY_INPUT" and not DirAccess.dir_exists_absolute(OUT),"FROZEN_INPUT_NEW_OUTPUT"): return {}
	for path: String in config.source_pins:
		if not track(path,config.source_pins[path]): return {}
	if not track(get_script().resource_path): return {}
	api=load(config.bundle_api_path);wall=load(config.wall_helper_path);clerk=load(config.clerk_helper_path);dg=load(config.geometry_api_path)
	if not require(api is GDScript and wall is GDScript and clerk is GDScript and dg is GDScript,"ONLY_PINNED_READONLY_HELPERS"): return {}
	config["district_author"]=read_json(config.district_author_path)
	var market: Dictionary=publish_market(config.market)
	if not require(market.get("published",false),"MARKET_FINITE_DOMAIN_PUBLISHED"): return {"market":market}
	var yamen: Dictionary=publish_yamen(config.yamen)
	if not require(yamen.get("published",false),"YAMEN_FINITE_DOMAIN_PUBLISHED"): return {"market":market,"yamen":yamen}
	return {"market":market,"yamen":yamen,"published":true}
func _run() -> void:
	began=Time.get_ticks_msec()
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null and platform.has_method("set_checkpoint_saves_suspended"): platform.call("set_checkpoint_saves_suspended",true)
	var result: Dictionary=publication();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);require(final[path]==pins[path],"SOURCE_FINAL:"+path)
	require(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED60S_FINITE_CPU_BUDGET")
	result.merge({"passed":failure.is_empty() and result.get("published",false),"error":failure,"checks":checks,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"source_first":pins,"source_final":final,"scope":"TWO_NEW_BUILD_ONLY_LOCAL_GEOMETRY_DOMAINS_NOT_RUNTIME_FIELD_ART","engine_geometry_full_raster_calls":0,"collector_calls":0,"physics_frames":0,"old_all_city_or_room_routes_replayed":false},true)
	var path: String=OUT+"runs/"+str(OS.get_process_id())+"_"+str(began)+"/result.json"
	if not save_json(path,result): print("FINITE_REPORT_WRITE_FAILED:"+path);quit(1);return
	print(JSON.stringify({"passed":result.passed,"error":failure,"result_path":path}));quit(0 if result.passed else 1)
