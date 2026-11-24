extends SceneTree
## NEW Root-only 24e bounded Market overlay publication. Never runs Field/C.prepare.
const READY=true
const INPUT="res://build/luoyang_city_blocks_20261024e_system01/publication_input04_ROOT_READY.json"
const INPUT_SHA="c48a6d9a1eb00bc3cf49d5b68676cefec39ef560d376bc9a6c217867650db34d"
const LIMIT_MS=60000
var begun: int=0
var errors: Array[String]=[]
var report: Dictionary={"passed":false,"native4_written":0,"Field":0,"Physics":0,"collector":0,"formal_writes":0}
var checks: int=0
var config: Dictionary={}
var helper: Variant
func _initialize() -> void: begun=Time.get_ticks_msec();call_deferred("run")
func check(value: bool,label: String) -> bool:
	checks+=1
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
func domain_raster(rows: Array,closed: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows:
		var area: Rect2=row.area
		# Conservative original paint bbox, not a new point-in-polygon convention.
		if floori(area.position.x)<=int(closed[2]) and ceili(area.end.x)>=int(closed[0]) and floori(area.position.y)<=int(closed[3]) and ceili(area.end.y)>=int(closed[1]): result.append(row)
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

func image(path: String) -> Image:
	var value:=Image.load_from_file(path)
	if value==null or value.is_empty(): return null
	if value.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return null
	if value.get_format()==Image.FORMAT_RGB8: value.convert(Image.FORMAT_RGBA8)
	return value
func native_rows(record: Dictionary) -> Array:
	var result: Array=[]
	for object: Dictionary in record.objects:
		var polygons: Variant=object.get("solid_polygons_px",[])
		if not polygons is Array: return []
		for raw: Variant in polygons:
			var shape: PackedVector2Array=helper.poly(raw)
			if shape.size()<3: return []
			result.append({"kind":"POLYGON","points_px":shape})
		var size:=v(object.get("collision_size_px",[0,0]))
		if size.x>0 and size.y>0:
			var low: Vector2=v(object.physical_center_px)-size*.5
			var high: Vector2=low+size
			result.append({"kind":"PARENT_EXACT_CLOSED_RECT","points_px":PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])})
	return result
func pixel_delta(parent: Image,raw: Image,old: Array,next: Array,domains: Array,prior: Dictionary) -> Dictionary:
	var before: PackedByteArray=parent.get_data();var after: PackedByteArray=before.duplicate()
	var positions:=PackedInt32Array();var old_rgba:=PackedByteArray();var visited: int=0
	var old_raster:=prepare_raster(old);var new_raster:=prepare_raster(next)
	for rect: Rect2i in domains:
		var closed: Array=[rect.position.x,rect.position.y,rect.end.x-1,rect.end.y-1]
		var old_local:=domain_raster(old_raster,closed);var new_local:=domain_raster(new_raster,closed)
		for y: int in range(rect.position.y,rect.end.y):
			if Time.get_ticks_msec()-begun>=LIMIT_MS: return {"ok":false,"error":"60S_LIMIT"}
			for x: int in range(rect.position.x,rect.end.x):
				visited+=1
				if visited>int(config.pixel_visit_limit): return {"ok":false,"error":"FINITE_DOMAIN_LIMIT"}
				var point:=Vector2(x,y);var base: Color=raw.get_pixel(x,y)
				var expected: Color=Color.BLACK if raster_blocked(point,old_local) else base
				if parent.get_pixel(x,y)!=expected: return {"ok":false,"error":"OLD_LOCAL_RAW_NATIVE_DIFF","xy":[x,y]}
				var desired: Color=Color.BLACK if raster_blocked(point,new_local) else base
				if desired==expected: continue
				var offset: int=(y*3072+x)*4
				positions.append(y*3072+x)
				for channel: int in range(4): old_rgba.append(before[offset+channel])
				var rgba: int=desired.to_rgba32()
				after[offset]=(rgba>>24)&255;after[offset+1]=(rgba>>16)&255;after[offset+2]=(rgba>>8)&255;after[offset+3]=rgba&255
	var child_sha: String=sha(after)
	if not check(child_sha==prior.get("expected_child_RGBA_sha256") and sha(before)==prior.get("parent_RGBA_sha256") and positions.size()==int(prior.get("changed_pixels",-1)) and visited==int(prior.get("union_visited_pixels",-1)),"INDEPENDENT_PRIOR_EXACT"): return {}
	var inverse: PackedByteArray=after.duplicate()
	for index: int in range(positions.size()):
		for channel: int in range(4): inverse[positions[index]*4+channel]=old_rgba[index*4+channel]
	if not check(inverse==before,"FULL_RGBA_OUTSIDE_DELTA_INVERSE"): return {}
	return {"ok":true,"image":Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,after),"inverse":{"encoding":"PACKED_POSITIONS_RGBA8_V1","positions":positions,"old_RGBA8":old_rgba},"changed_pixels":positions.size(),"visited_pixels":visited,"child_RGBA_sha256":child_sha,"parent_RGBA_sha256":sha(before)}
func paths(author: Dictionary,prior: Dictionary,scene: SceneScript) -> Array:
	var result: Array=author.route_plan.duplicate(true)
	for row: Dictionary in result: row["new_route"]=true
	for npc: Dictionary in scene.npcs:
		var id: String=String(npc.get("npc_id",""));var foot: Vector2=v(npc.get("pos"))*Vector2(3072,2048)
		for change: Dictionary in author.npc_migrations:
			if id==change.id:
				if not check(foot==v(change.old_foot_px),"FROZEN_NATIVE_NPC_OLD:"+id): return []
				foot=v(change.foot_px)
		result.append({"id":"native_npc:"+id,"npc":true,"points_px":[foot,foot]})
	for npc: Dictionary in prior.runtime_district.crowd:
		var foot:=v(npc.foot_px);var distance: float=float(npc.distance_px)
		for change: Dictionary in author.npc_migrations:
			if npc.id==change.id:
				if not check(foot==v(change.old_foot_px) and (not change.has("distance_px") or distance==float(change.distance_px)),"FROZEN_CROWD_OLD_FOOT_AND_UNCHANGED_DISTANCE:"+String(npc.id)): return []
				foot=v(change.foot_px)
		result.append({"id":"crowd:"+String(npc.id),"npc":true,"points_px":[foot-Vector2(distance,0),foot+Vector2(distance,0)]})
	# Existing AP task projection is a frozen source statement, not a synthetic actor.
	result.append({"id":"paper_task_artisan_kept","npc":true,"points_px":[[880,1340],[880,1340]]})
	for room: Dictionary in author.room_migrations:
		result.append({"id":"room_return:"+String(room.room_id),"points_px":[room.return_foot_px,room.return_foot_px]})
	return result
func audit(author: Dictionary,prior: Dictionary,scene: SceneScript,mask: Image,solids: Array) -> Dictionary:
	var count: int=0;var rows: Array=[]
	var selected:=paths(author,prior,scene)
	if selected.is_empty() or not errors.is_empty(): return {}
	for path: Dictionary in selected:
		for ordinal: int in range(path.points_px.size()-1):
			var from:=v(path.points_px[ordinal]);var to:=v(path.points_px[ordinal+1]);var half:=Vector2(17,15 if path.get("npc",false) else 12)
			var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(steps+1):
				if Time.get_ticks_msec()-begun>=LIMIT_MS: return {"ok":false,"error":"60S_LIMIT"}
				var foot: Vector2=from.lerp(to,float(step)/steps)
				if not safe(foot,mask,solids,half): return {"ok":false,"error":"BODY_MASK_OR_SOLID","id":path.id,"segment":ordinal,"foot":[foot.x,foot.y]}
				count+=1
			rows.append({"id":path.id,"segment":ordinal,"samples":steps+1,"npc":path.get("npc",false)})
	return {"ok":true,"samples":count,"selected":rows,"new_layout_routes_only_not_old_whole_geometry_replay":true,"full875_or_NPC1085_plus17":true}
func write_bytes(path: String,value: PackedByteArray) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(value);file.close();return true
func run() -> void:
	config=json_file(INPUT)
	if not check(READY and FileAccess.get_sha256(INPUT)==INPUT_SHA and config.get("ready")==true and config.get("independent_prior_ready")==true,"ROOT_FROZEN_READY"): finish();return
	var first: Dictionary={INPUT:INPUT_SHA}
	for path: String in config.source_pins:
		var actual: String=FileAccess.get_sha256(path)
		if not check(actual==config.source_pins[path],"SOURCE_FIRST:"+path): finish();return
		first[path]=actual
	var author:=json_file(config.author_path);var prior_author:=json_file(config.parent_author_path)
	helper=load(config.helper_path)
	var runtime: Variant=load(config.parent_runtime_path);var dg: Variant=load(config.DG_path)
	if not check(helper is GDScript and helper.can_instantiate() and helper.resource_path==config.helper_path and runtime is GDScript and runtime.can_instantiate() and runtime.resource_path==config.parent_runtime_path and dg is GDScript and dg.can_instantiate() and dg.resource_path==config.DG_path,"PINNED_PARSEABLE_PURE_APIS"): finish();return
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(config.packet_path))
	var scene:=ResourceLoader.load(config.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(config.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not check(packet is Dictionary and scene!=null and layout!=null and packet.record.canonical_scene_id==author.scene_id and scene.scene_id==StringName(author.scene_id) and scene.map_layout.visual_objects.size()==25 and var_to_bytes(scene.map_layout.visual_objects)==var_to_bytes(layout.visual_objects),"FROZEN_NATIVE25_SCENE_LAYOUT"): finish();return
	var entries: Dictionary=runtime._entries(prior_author.runtime_district,prior_author.district_assets)
	var canonical_parent: Array=dg.apply_render(scene.map_layout.visual_objects,entries)
	var reconstructed_parent: Array=helper.district_parent(scene.map_layout.visual_objects,prior_author)
	if not check(canonical_parent.size()==37 and var_to_bytes(canonical_parent)==var_to_bytes(reconstructed_parent),"FULL_PARENT37_EQUALS_FROZEN_CANONICAL_ENTRIES_DG_PROJECTION"): finish();return
	var projection: Dictionary=helper.project(author,canonical_parent)
	if not check(projection.get("ok",false) and projection.render.size()==43 and var_to_bytes(helper.restore(projection))==var_to_bytes(canonical_parent),"FULL_PARENT37_CHILD43_INVERSE"): finish();return
	var old_native:=native_rows(packet.record);var solids: Array=helper.primitives(projection.render)
	if not check(not old_native.is_empty() and not solids.is_empty() and same_multiset(packet.solids,old_native),"EXACT_PARENT_NATIVE_PRIMITIVE_MULTISET"): finish();return
	var parent:=image(config.walk_path);var raw:=image(config.raw_walk_path)
	if not check(parent!=null and raw!=null and parent.get_size()==Vector2i(3072,2048) and raw.get_size()==parent.get_size() and sha(parent.get_data())==author.parent.walk_RGBA_sha256 and packet.walk_bytes==parent.get_data(),"WHOLE_PARENT_MASK_PACKET_RGBA"): finish();return
	var domains: Array=helper.domains(projection)
	var prior:=json_file(config.independent_prior.path)
	if not check(FileAccess.get_sha256(config.independent_prior.path)==config.independent_prior.sha256 and prior.get("ready")==true,"INDEPENDENT_PRIOR_FROZEN"): finish();return
	first[config.independent_prior.path]=config.independent_prior.sha256
	var delta:=pixel_delta(parent,raw,old_native,solids,domains,prior)
	if not check(delta.get("ok",false),"SOURCE_NATIVE_MASK_DELTA"): report.delta=delta;finish();return
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		if not check(final[path]==first[path],"SOURCE_FINAL:"+path): finish();return
	var out: String=String(config.output_prefix)+str(OS.get_process_id())+"/"
	if not check(not DirAccess.dir_exists_absolute(out) and DirAccess.make_dir_recursive_absolute(out)==OK,"NEW_OUTPUT_ONLY"): finish();return
	if not check(delta.image.save_png(out+"walk_overlay.png")==OK,"NEW_MASK_ONLY"): finish();return
	var inverse_bytes: PackedByteArray=var_to_bytes(delta.inverse)
	if not check(write_bytes(out+"pixel_inverse.bin",inverse_bytes) and write_bytes(out+"render_projection.bin",var_to_bytes(projection)) and write_bytes(out+"geometry.bin",var_to_bytes(solids)),"PACKED_FINITE_PROOFS"): finish();return
	# Regenerated bytes only: publication03 already proved this exact parent,
	# projection/inverse and independent RGBA. Save before route audit so any
	# residual route failure cannot discard those successful immutable bytes.
	var component: Dictionary={"status":"MARKET24E_FIXED_COMPONENTS_NOT_RUNTIME","author_path":config.author_path,"author_sha256":first[config.author_path],"walk_path":out+"walk_overlay.png","walk_sha256":FileAccess.get_sha256(out+"walk_overlay.png"),"walk_RGBA_sha256":delta.child_RGBA_sha256,"changed_pixels":delta.changed_pixels,"visited_pixels":delta.visited_pixels,"render_projection":{"path":out+"render_projection.bin","sha256":FileAccess.get_sha256(out+"render_projection.bin")},"geometry":{"path":out+"geometry.bin","sha256":FileAccess.get_sha256(out+"geometry.bin")},"source_first":first,"source_final_before_route":final,"Field_ART_sourceclosure_pending":true}
	if not check(write_bytes(out+"components_FIXED_NOT_RUNTIME.json",JSON.stringify(component,"\\t",true,true).to_utf8_buffer()),"FINITE_COMPONENT_CHECKPOINT"): finish();return
	var routes:=audit(author,prior_author,scene,delta.image,solids)
	if not check(routes.get("ok",false),"FINITE_NEW_LAYOUT_BODY_MASK_ROUTES"): report.geometry=routes;report.output=out;report.successful_components_saved=true;finish();return
	for path: String in first:
		if not check(FileAccess.get_sha256(path)==first[path],"SOURCE_AFTER_ROUTE:"+path): finish();return
	var header: Dictionary={"status":"MARKET24E_BLOCK_OVERLAY_BUILD_ONLY","ready":false,"runtime_ready":false,"author_path":config.author_path,"author_sha256":first[config.author_path],"parent_native4_unchanged":author.parent.artifacts,"combined_visuals_before":37,"combined_visuals_after":43,"walk_path":out+"walk_overlay.png","walk_sha256":FileAccess.get_sha256(out+"walk_overlay.png"),"walk_RGBA_sha256":delta.child_RGBA_sha256,"changed_pixels":delta.changed_pixels,"visited_pixels":delta.visited_pixels,"domains":domains,"pixel_inverse":{"path":out+"pixel_inverse.bin","sha256":sha(inverse_bytes)},"render_projection":{"path":out+"render_projection.bin","sha256":FileAccess.get_sha256(out+"render_projection.bin")},"geometry":{"path":out+"geometry.bin","sha256":FileAccess.get_sha256(out+"geometry.bin")},"full_render_inverse":true,"full_RGBA_inverse":true,"route_proof":routes,"source_first":first,"source_final":final,"Field_Physics_ART_pending":true}
	if not check(write_bytes(out+"overlay_header_NOTREADY.json",JSON.stringify(header,"\t",true,true).to_utf8_buffer()),"SMALL_HEADER_NOT_PIXEL_JSON"): finish();return
	report.passed=true;report.output=out;report.header_sha256=FileAccess.get_sha256(out+"overlay_header_NOTREADY.json");report.geometry=routes
	finish()
func finish() -> void:
	report.errors=errors;report.checks=checks;report.elapsed_ms=Time.get_ticks_msec()-begun
	print(JSON.stringify(report));quit(0 if report.passed else 1)
