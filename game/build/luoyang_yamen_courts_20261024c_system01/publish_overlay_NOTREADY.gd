extends SceneTree
## Root-only finite two-domain navigation overlay; never writes native artifacts.
const READY=false
const INPUT="res://build/luoyang_yamen_courts_20261024c_system01/input_NOTREADY.json"
const LIMIT_MS=15000
var begun: int=0
var errors: Array[String]=[]
var report: Dictionary={"passed":false,"native_artifacts_written":0,"collector_calls":0,"Field_instances":0,"geometry_full_replay":false}
func _initialize() -> void:
	begun=Time.get_ticks_msec();call_deferred("run")
func check(value: bool,label: String) -> bool:
	if not value: errors.append(label)
	return value
func sha(bytes: PackedByteArray) -> String:
	var hashing:=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(bytes);return hashing.finish().hex_encode()
func json_file(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else Vector2(raw[0],raw[1])
func polygon(raw: Variant) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in raw: result.append(v(point))
	return result
func bounds(points: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in points: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
func prepare_raster(rows: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows:
		var shape:=polygon(row.points_px)
		result.append({"shape":shape,"area":bounds(shape),"rect":String(row.kind)=="PARENT_EXACT_CLOSED_RECT"})
	return result
func raster_blocked(point: Vector2,rows: Array) -> bool:
	if point.x<24 or point.y<24 or point.x>=3048 or point.y>=2024: return true
	for row: Dictionary in rows:
		var shape: PackedVector2Array=row.shape;var area: Rect2=row.area
		if row.rect:
			# Original C raster is ceil-low / ceil-high-exclusive, not closed-body geometry.
			if point.x>=ceili(area.position.x) and point.x<ceili(area.end.x) and point.y>=ceili(area.position.y) and point.y<ceili(area.end.y): return true
		elif point.x>=floori(area.position.x) and point.x<=ceili(area.end.x) and point.y>=floori(area.position.y) and point.y<=ceili(area.end.y) and Geometry2D.is_point_in_polygon(point,shape): return true
	return false
func same_multiset(native: Array,expected: Array) -> bool:
	if native.size()!=expected.size(): return false
	var used: Dictionary={}
	for row: Dictionary in expected:
		var found: int=-1;var target: PackedByteArray=var_to_bytes(polygon(row.points_px))
		for index: int in range(native.size()):
			if not used.has(index) and var_to_bytes(polygon(native[index]))==target: found=index;break
		if found<0: return false
		used[found]=true
	return true
func cross(a: Vector2,b: Vector2,p: Vector2) -> float: return (float(b.x)-a.x)*(float(p.y)-a.y)-(float(b.y)-a.y)*(float(p.x)-a.x)
func on(a: Vector2,b: Vector2,p: Vector2) -> bool: return cross(a,b,p)==0.0 and p.x>=minf(a.x,b.x) and p.x<=maxf(a.x,b.x) and p.y>=minf(a.y,b.y) and p.y<=maxf(a.y,b.y)
func touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	return cross(a,b,c)*cross(a,b,d)<0.0 and cross(c,d,a)*cross(c,d,b)<0.0 or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)
func safe(foot: Vector2,mask: Image,solids: Array,half: Vector2=Vector2(17,12)) -> bool:
	if not foot.is_finite() or foot.x<half.x or foot.y<half.y or roundi(foot.x+half.x)>=3072 or roundi(foot.y+half.y)>=2048: return false
	var area:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
	for row: Dictionary in solids:
		var shape:=polygon(row.points_px)
		if not bounds(shape).intersects(area,true): continue
		if not Geometry2D.intersect_polygons(body,shape).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,shape): return false
		for point: Vector2 in shape:
			if point.x>=area.position.x and point.x<=area.end.x and point.y>=area.position.y and point.y<=area.end.y: return false
		for i: int in range(body.size()):
			for j: int in range(shape.size()):
				if touch(body[i],body[(i+1)%body.size()],shape[j],shape[(j+1)%shape.size()]): return false
	for y: int in range(roundi(area.position.y),roundi(area.end.y)+1):
		for x: int in range(roundi(area.position.x),roundi(area.end.x)+1):
			var color:=mask.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var color:=mask.get_pixelv(Vector2i((foot+offset).round()))
		if color.r<.5 or color.a<.5: return false
	return true
func selected_paths(record: Dictionary,author: Dictionary) -> Array:
	var paths: Array=record.routes.duplicate(true)
	for kind: String in ["interactions","npcs","portals"]:
		for slot: Dictionary in record.get("gameplay_slots",{}).get(kind,[]):
			for key: String in ["foot_px","stand_px","arrival_foot_px"]:
				if slot.has(key): paths.append({"id":kind+":"+String(slot.get("source_id",""))+":"+key,"points_px":[slot[key],slot[key]],"npc":kind=="npcs"})
			if slot.has("passage_path_px"): paths.append({"id":"passage:"+String(slot.source_id),"points_px":slot.passage_path_px})
	for person: Dictionary in author.preserved.all_original_npcs:
		var foot:=v(person.foot_px);var distance: float=float(person.get("distance_px",0))
		paths.append({"id":"source_npc:"+String(person.get("id",person.get("source_id",""))),"points_px":[foot-Vector2(distance,0),foot+Vector2(distance,0)],"npc":true})
	for row: Dictionary in author.proposed_short_routes:
		var extra: Dictionary=row.duplicate(true);extra["new_route"]=true;paths.append(extra)
	return paths
func route_audit(record: Dictionary,author: Dictionary,mask: Image,solids: Array) -> Dictionary:
	var rows: Array=[];var inherited: Array=[];var samples: int=0
	for path: Dictionary in selected_paths(record,author):
		for ordinal: int in range(path.points_px.size()-1):
			var from:=v(path.points_px[ordinal]);var to:=v(path.points_px[ordinal+1]);var half:=Vector2(17,15 if path.get("npc",false) else 12)
			var sweep:=Rect2(from.min(to)-half,(from-to).abs()+half*2);var affected: bool=path.get("new_route",false)
			for domain: Dictionary in author.local_mask_domains:
				var c: Array=domain.closed
				affected=affected or sweep.intersects(Rect2(c[0],c[1],c[2]-c[0]+1,c[3]-c[1]+1),true)
			if not affected: inherited.append({"id":path.id,"segment":ordinal});continue
			var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(steps+1):
				if Time.get_ticks_msec()-begun>LIMIT_MS: return {"ok":false,"error":"FINITE_TIME_LIMIT"}
				var foot:=from.lerp(to,float(step)/steps)
				if not safe(foot,mask,solids,half): return {"ok":false,"error":"BODY_MASK_OR_SOLID","id":path.id,"segment":ordinal,"foot":[foot.x,foot.y]}
				samples+=1
			rows.append({"id":path.id,"segment":ordinal,"samples":steps+1,"whole_selected_segment":true,"npc":path.get("npc",false)})
	for foot: Array in author.negative_body_centres:
		if safe(v(foot),mask,solids): return {"ok":false,"error":"NEW_BASE_NEGATIVE_DID_NOT_REJECT"}
	return {"ok":true,"samples":samples,"selected":rows,"unaffected_inherited":inherited,"body":[34,24],"NPC_body":[34,30],"full875_and17":true,"max_step":4}
func save_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func run() -> void:
	var input:=json_file(INPUT)
	if not check(READY and input.get("ready")==true and input.get("independent_prior_ready")==true,"NOT_AUTHORIZED_NOTREADY"): finish();return
	var first: Dictionary={}
	first[INPUT]=FileAccess.get_sha256(INPUT)
	for path: String in input.source_pins:
		var actual: String=FileAccess.get_sha256(path)
		if not check(actual==input.source_pins[path],"FIXED_SOURCE_FIRST:"+path): finish();return
		first[path]=actual
	var author:=json_file(input.author_path);var helper: Variant=load(input.helper_path)
	var geometry: Dictionary=helper.derive(author)
	if not check(geometry.get("ok",false),"SOURCE_GEOMETRY42_TO40"): finish();return
	var prior:=json_file(input.independent_prior.path)
	if not check(FileAccess.get_sha256(input.independent_prior.path)==input.independent_prior.sha256 and prior.get("ready")==true,"INDEPENDENT_PRIOR"): finish();return
	first[input.independent_prior.path]=input.independent_prior.sha256
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(input.parent_packet))
	if not check(packet is Dictionary and packet.get("record") is Dictionary and packet.record.get("canonical_scene_id")==author.scene_id and same_multiset(packet.solids,geometry.native_before),"ORIGINAL_NATIVE32_EXACT_SOURCE_MULTISET"): finish();return
	var parent:=Image.load_from_file(input.parent_walk);var raw:=Image.load_from_file(input.raw_walk)
	if not check(parent!=null and raw!=null and parent.get_size()==Vector2i(3072,2048) and raw.get_size()==parent.get_size() and parent.get_format()==Image.FORMAT_RGBA8 and raw.get_format()==Image.FORMAT_RGBA8 and sha(parent.get_data())==author.parent_native.walk_RGBA_sha256,"FROZEN_FULL_PARENT_RGBA8"): finish();return
	var old_raster:=prepare_raster(geometry.native_before);var new_raster:=prepare_raster(geometry.combined)
	var child: Image=parent.duplicate() as Image;var changes: Array=[];var visited: int=0
	for domain: Dictionary in author.local_mask_domains:
		var c: Array=domain.closed
		for y: int in range(int(c[1]),int(c[3])+1):
			if not check(Time.get_ticks_msec()-begun<LIMIT_MS,"FINITE_TIME_LIMIT"): finish();return
			for x: int in range(int(c[0]),int(c[2])+1):
				visited+=1;var point:=Vector2(x,y);var source:=raw.get_pixel(x,y)
				var expected: Color=Color.BLACK if raster_blocked(point,old_raster) else source
				if not check(parent.get_pixel(x,y)==expected,"OLD_LOCAL_RAW_NATIVE_EXACT:"+str(point)): finish();return
				var desired: Color=Color.BLACK if raster_blocked(point,new_raster) else source
				if desired!=parent.get_pixel(x,y):
					changes.append({"xy":[x,y],"old":parent.get_pixel(x,y).to_rgba32(),"new":desired.to_rgba32()});child.set_pixel(x,y,desired)
	var child_sha:=sha(child.get_data())
	if not check(child_sha==prior.expected_child_RGBA_sha256 and changes.size()==int(prior.changed_pixels) and visited==int(prior.union_visited_pixels),"INDEPENDENT_EXPECTATION_EXACT"): finish();return
	var inverse: Image=child.duplicate() as Image
	for change: Dictionary in changes: inverse.set_pixel(change.xy[0],change.xy[1],Color.hex(int(change.old)))
	if not check(inverse.get_data()==parent.get_data(),"FULL_RGBA_INVERSE_OUTSIDE_DOMAINS_EXACT"): finish();return
	var audit:=route_audit(packet.record,author,child,geometry.combined)
	if not check(audit.get("ok",false),"ONLY_NEW_AND_AFFECTED_PATHS"): report.geometry=audit;finish();return
	for witness: Vector2 in [Vector2(590,1080),Vector2(2664,1160)]:
		if not check(not safe(witness,parent,author.original_combined_geometry) and safe(witness,child,geometry.combined),"OLD_ANNEX_BASE_RESTORED_BODY:"+str(witness)): finish();return
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		if not check(final[path]==first[path],"FIXED_SOURCE_FINAL:"+path): finish();return
	var out: String=String(input.output_prefix)+str(OS.get_process_id())+"/"
	if not check(not DirAccess.dir_exists_absolute(out) and DirAccess.make_dir_recursive_absolute(out)==OK,"NEW_OUTPUT_ABSENT"): finish();return
	var walk: String=out+"walk_overlay.png"
	if not check(child.save_png(walk)==OK,"ONLY_NEW_MASK_WRITE"): finish();return
	var back:=Image.load_from_file(walk)
	if not check(back!=null and back.get_data()==child.get_data(),"NEW_MASK_FULL_RGBA_READBACK"): finish();return
	var manifest: Dictionary={"status":"YAMEN_GROUND_OVERLAY_BUILD_NATIVE4_UNCHANGED_RUNTIME_PENDING","ready":false,"consumer_ready":false,"imported":false,"author_path":input.author_path,"author_sha256":first[input.author_path],"parent_native":author.parent_native,"walk_path":walk,"walk_file_sha256":FileAccess.get_sha256(walk),"walk_RGBA_sha256":child_sha,"geometry_before42_after40":geometry,"domains":author.local_mask_domains,"changed_pixels":changes.size(),"visited_pixels":visited,"mask_inverse":changes,"full_RGBA_inverse":true,"geometry":audit,"source_first":first,"source_final":final,"original_native_artifacts_unchanged":true,"Field_Physics_ART_pending":true}
	if not check(save_json(out+"overlay_manifest_NOTREADY.json",manifest),"NEW_OVERLAY_MANIFEST"): finish();return
	report.passed=true;report.manifest_path=out+"overlay_manifest_NOTREADY.json";report.manifest_sha256=FileAccess.get_sha256(report.manifest_path);report.walk_path=walk;report.walk_RGBA_sha256=child_sha;report.changed_pixels=changes.size();report.visited_pixels=visited;report.geometry=audit
	finish()
func finish() -> void:
	report.errors=errors;report.elapsed_ms=Time.get_ticks_msec()-begun
	print(JSON.stringify(report));quit(0 if report.passed else 1)
