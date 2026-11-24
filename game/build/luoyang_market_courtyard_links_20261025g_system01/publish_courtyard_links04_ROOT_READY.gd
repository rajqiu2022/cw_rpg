extends SceneTree
## Root-only finite25g CPU publisher. No Field, collector, packet or native resource loading.
const READY = true
const INPUT = "res://build/luoyang_market_courtyard_links_20261025g_system01/publication_input04_ROOT_READY.json"
const INPUT_SHA = "8cd235acf0f9aa5c9dae18f637abe67cce56016d09ac09c82333b60b68b3246f"
const LIMIT_MS = 60000
var begun: int = 0
var checks: int = 0
var errors: Array[String] = []
var config: Dictionary = {}
var helper: Variant
var report: Dictionary = {"passed":false,"Field":0,"Physics":0,"collector":0,"packet_decodes":0,"native4_writes":0,"formal_writes":0}
func _initialize() -> void:
	begun=Time.get_ticks_msec()
	call_deferred("run")
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

func write_bytes(path: String,value: PackedByteArray) -> bool:
	if FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		return false
	file.store_buffer(value)
	file.close()
	return true

func source_facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in config.source_pins:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=String(config.source_pins[path]).to_lower():
			return {}
		result[path]=FileAccess.get_sha256(path).to_lower()
	return result

func swept_affected(from: Vector2,to: Vector2,half: Vector2,domains: Array) -> bool:
	var low: Vector2 = from.min(to)-half
	var high: Vector2 = from.max(to)+half
	for rect: Rect2i in domains:
		if Rect2(low,high-low).intersects(Rect2(rect),true):
			return true
	return false


func npc_lane_clear(foot: Vector2,half: Vector2,seed: Dictionary) -> bool:
	var low: Vector2 = foot-half
	var high: Vector2 = foot+half
	for npc: Dictionary in seed.protected_8_npc_source_seed.rows:
		var center: Vector2 = v(npc.origin)
		var distance: float = float(npc.patrol_distance) if npc.movement_mode=="patrol" else 0.0
		var npc_low: Vector2 = center-Vector2(17+distance,15)
		var npc_high: Vector2 = center+Vector2(17+distance,15)
		if low.x<=npc_high.x and high.x>=npc_low.x and low.y<=npc_high.y and high.y>=npc_low.y:
			return false
	return true

func audit(author: Dictionary,seed: Dictionary,mask: Image,geometry: Array,domains: Array) -> Dictionary:
	var samples: int = 0
	var inherited: int = 0
	var rows: Array = author.local_routes.duplicate(true)
	for row: Dictionary in rows:
		row["new_route"]=true
	for row: Dictionary in seed.protected_route_centerlines:
		rows.append(row.duplicate(true))
	for npc: Dictionary in seed.protected_8_npc_source_seed.rows:
		var foot: Vector2 = v(npc.origin)
		var distance: float = float(npc.patrol_distance) if npc.movement_mode=="patrol" else 0.0
		rows.append({"id":"NPC:"+String(npc.npc_id),"points_px":[foot-Vector2(distance,0),foot+Vector2(distance,0)],"npc":true})
	var audit_rows: Array = []
	for row: Dictionary in rows:
		var points: Array = row.points_px
		var half := Vector2(17,15) if row.get("npc",false) else Vector2(17,12)
		for index: int in range(points.size()-1):
			var from: Vector2 = v(points[index])
			var to: Vector2 = v(points[index+1])
			if not row.get("new_route",false) and not swept_affected(from,to,half,domains):
				inherited+=1
				continue
			var count: int = maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(count+1):
				var foot: Vector2 = from.lerp(to,float(step)/count)
				if not check(safe(foot,mask,geometry,half) and (not row.get("new_route",false) or npc_lane_clear(foot,half,seed)),"LOCAL_FULL_BODY:"+String(row.id)+":"+str(index)+":"+str(step)):
					report["failed_foot_px"]=[foot.x,foot.y]
					return {}
				samples+=1
			audit_rows.append({"id":row.id,"segment":index,"samples":count+1,"half_body_px":[half.x,half.y]})
	# Existing city player and NPC body contracts both pass each gallery center.
	for x: float in [1720.0,2660.0]:
		for half: Vector2 in [Vector2(17,12),Vector2(17,15),Vector2(22.95,16.2),Vector2(22.95,20.25)]:
			for y: int in range(1340,1385,4):
				if not check(safe(Vector2(x,y),mask,geometry,half) and npc_lane_clear(Vector2(x,y),half,seed),"GALLERY_CLEAR_BOTH_BODIES"):
					return {}
				samples+=1
	# NEW Root conservative1.35 margin probes, not an inherited production body claim.
	for route: Dictionary in author.local_routes:
		var from: Vector2 = v(route.points_px[0])
		var to: Vector2 = v(route.points_px[1])
		var count: int = maxi(1,ceili(from.distance_to(to)/4.0))
		for half: Vector2 in [Vector2(22.95,16.2),Vector2(22.95,20.25)]:
			for step: int in range(count+1):
				var foot: Vector2 = from.lerp(to,float(step)/count)
				if not check(safe(foot,mask,geometry,half) and npc_lane_clear(foot,half,seed),"NEW_CONSERVATIVE135_SHORT_ROUTE:"+String(route.id)):
					return {}
				samples+=1
	for old_x: float in [1720.0,2660.0]:
		if not check(not npc_lane_clear(Vector2(old_x,1396),Vector2(17,12),seed),"REJECT_OLD_NPC_OVERLAPPING_ROUTE_START1396"):
			return {}
	# New bases remain real solids; no roof-wide rectangle or alpha-derived nav.
	var negative: int = 0
	for owner: String in helper.ADD_IDS:
		for primitive: Dictionary in geometry:
			if primitive.owner_id!=owner:
				continue
			var shape: PackedVector2Array = polygon(primitive.points_px)
			var center := Vector2.ZERO
			for point: Vector2 in shape:
				center+=point
			center/=shape.size()
			if not check(not safe(center,mask,geometry),"FOUR_GALLERY_BASE_NEGATIVE:"+owner):
				return {}
			negative+=1
	return {"ok":true,"samples":samples,"inherited_unaffected_segments":inherited,"rows":audit_rows,"negative_bases":negative,"conservative135_scope":"NEW two-gallery/new-short-route margin probes only; no production body change or inherited-contract claim"}

func finish() -> void:
	report["checks"]=checks
	report["errors"]=errors
	report["elapsed_ms"]=Time.get_ticks_msec()-begun
	var output: String = String(config.get("output_prefix","res://build/luoyang_market_courtyard_links_20261025g_system01/publication01/"))+"reports/"+str(OS.get_process_id())+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	write_bytes(output+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer())
	print(JSON.stringify(report))
	quit(0 if report.passed and errors.is_empty() else 1)

func run() -> void:
	if not check(READY and FileAccess.get_sha256(INPUT).to_lower()==INPUT_SHA.to_lower(),"ROOT_READY_AND_FIXED_INPUT"):
		finish()
		return
	config=json_file(INPUT)
	if not check(config.get("ready")==true and config.get("prior_ready")==true,"INDEPENDENT_PRIOR_READY"):
		finish()
		return
	var first: Dictionary = source_facts()
	if not check(not first.is_empty() and FileAccess.get_sha256(config.independent_prior.path).to_lower()==String(config.independent_prior.sha256).to_lower(),"FIXED_SOURCE_FIRST_AND_PRIOR"):
		finish()
		return
	helper=load(config.helper.path)
	if not check(helper is GDScript and helper.can_instantiate(),"PURE_SCRIPT_LOAD_AND_CAN_INSTANTIATE"):
		finish()
		return
	var author: Dictionary = json_file(config.author.path)
	var prior: Dictionary = json_file(config.independent_prior.path)
	var parent_projection: Variant = bytes_to_var(FileAccess.get_file_as_bytes(author.parent.render.path))
	var old_geometry: Variant = bytes_to_var(FileAccess.get_file_as_bytes(author.parent.geometry.path))
	if not check(parent_projection is Dictionary and parent_projection.get("ok")==true and parent_projection.get("render",[]).size()==43 and old_geometry is Array,"FIXED_ACTUAL43_COMPONENTS_NOT_SELF_SYNTHESIZED"):
		finish()
		return
	var parent43: Array = parent_projection.render
	var computed_old: Array = helper.primitives(parent43)
	if not check(not computed_old.is_empty() and var_to_bytes(computed_old)==var_to_bytes(old_geometry),"ACTUAL43_WHOLE_PRIMITIVE_STORAGE"):
		finish()
		return
	var projection: Dictionary = helper.project(author,parent43)
	if not check(projection.get("ok")==true and projection.render.size()==45 and var_to_bytes(helper.restore(projection))==var_to_bytes(parent43),"45_COMPLETE_PARENT43_TYPED_BYTE_INVERSE"):
		finish()
		return
	var geometry: Array = helper.primitives(projection.render)
	var domains: Array = helper.domains(projection)
	if not check(not geometry.is_empty() and not domains.is_empty(),"FINITE_NEW_PRIMITIVES_AND_DOMAINS"):
		finish()
		return
	var parent: Image = image(author.parent.walk.path)
	var raw: Image = image(config.raw_walk.path)
	if not check(parent!=null and raw!=null and parent.get_size()==Vector2i(3072,2048) and raw.get_size()==Vector2i(3072,2048) and sha(parent.get_data())==author.parent.walk.RGBA_sha256,"FIXED_PARENT_AND_RAW_RGBA"):
		finish()
		return
	var delta: Dictionary = pixel_delta(parent,raw,old_geometry,geometry,domains,prior)
	if not check(delta.get("ok")==true,"LOCAL_MASK_ALL_OLD_AND_NEW_PRIMITIVES_WITH_INVERSE"):
		report["delta_error"]=delta
		finish()
		return
	var seed: Dictionary = json_file(config.protected_seed.path)
	var finite: Dictionary = audit(author,seed,delta.image,geometry,domains)
	if not check(finite.get("ok")==true and finite.negative_bases==8,"ONLY_NEW_OR_AFFECTED_BODY_ROUTES_AND_EIGHT_BASES"):
		finish()
		return
	var final: Dictionary = source_facts()
	if not check(final==first and FileAccess.get_sha256(config.independent_prior.path).to_lower()==String(config.independent_prior.sha256).to_lower() and Time.get_ticks_msec()-begun<LIMIT_MS,"FIXED_SOURCE_FINAL_AND_60S"):
		finish()
		return
	var out: String = String(config.output_prefix)+"output/"+str(OS.get_process_id())+"/"
	if not check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(out)),"NEW_OUTPUT_ABSENT"):
		finish()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	if not check(delta.image.save_png(out+"walk_overlay.png")==OK and write_bytes(out+"projection.bin",var_to_bytes(projection)) and write_bytes(out+"geometry.bin",var_to_bytes(geometry)) and write_bytes(out+"pixel_inverse.bin",var_to_bytes(delta.inverse)) and write_bytes(out+"finite_proof.bin",var_to_bytes(finite)),"ONLY_NEW_LOCAL_OUTPUTS"):
		finish()
		return
	var artifacts: Dictionary = {}
	for name: String in ["walk_overlay.png","projection.bin","geometry.bin","pixel_inverse.bin","finite_proof.bin"]:
		artifacts[name]={"path":out+name,"sha256":FileAccess.get_sha256(out+name)}
	var closed: Array = []
	for area: Rect2i in domains:
		closed.append([area.position.x,area.position.y,area.end.x-1,area.end.y-1])
	var header: Dictionary = {"ready":false,"status":"25G_LOCAL_PUBLICATION_ART_FIELD_SOURCE_PENDING","scene_id":author.scene_id,"parent_count":43,"child_count":45,"author":config.author,"pure":config.helper,"artifacts":artifacts,"parent":author.parent,"walk_RGBA_sha256":delta.child_RGBA_sha256,"parent_RGBA_sha256":delta.parent_RGBA_sha256,"changed_pixels":delta.changed_pixels,"visited_pixels":delta.visited_pixels,"domains_closed":closed,"finite":finite,"source_first":first,"source_final":final,"sourceclosure_ready":false,"Field_ART_pending":true,"no_old_native_republish":true}
	if not check(write_bytes(out+"overlay_header_NOTREADY.json",(JSON.stringify(header,"\t")+"\n").to_utf8_buffer()),"SMALL_RUNTIME_HEADER_NO_PIXEL_JSON"):
		finish()
		return
	report.merge({"passed":true,"header":out+"overlay_header_NOTREADY.json","artifacts":artifacts,"changed_pixels":delta.changed_pixels,"visited_pixels":delta.visited_pixels,"domains_closed":closed,"finite":finite,"source_first":first,"source_final":final})
	finish()
