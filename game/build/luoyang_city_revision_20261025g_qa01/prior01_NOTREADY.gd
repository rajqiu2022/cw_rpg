extends SceneTree
## Independent source-donor projection and bounded PIP oracle. Never loads System pure/publisher.
const READY25G=false
const INPUT25G="PENDING_ROOT_FROZEN_INPUT"
const INPUT_SHA25G="PENDING_ROOT_FROZEN_SHA"
const MAP_SIZE=Vector2i(3072,2048)
const CHANGED25G=["market_e_court_side_0","market_e_court_side_1","market_e_court_side_2","market_e_court_side_3","market_b_book_rear_wall_e","goods_stall","medicine_stall"]
const ADDED25G=["market_g_cloth_gallery","market_g_medicine_gallery"]
var checks: int=0
var errors: Array[String]=[]
var began: int=0
var deadline: int=0
var cfg: Dictionary={}
var first: Dictionary={}
var report: Dictionary={"ready":false,"engine_Field_Physics_collector_calls":0,"System_pure_or_publisher_calls":0,"packet_decodes":0,"PNG_outputs":0,"PNG_decodes":0,"binary_decodes":0}

func _initialize() -> void:
	began=Time.get_ticks_msec();deadline=began+60000;call_deferred("run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label)
	return ok
func digest(raw: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(raw);return h.finish().hex_encode()
func read_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
func poly(raw: Variant) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for vertex: Variant in raw: out.append(v(vertex))
	return out
func bounds(points: PackedVector2Array) -> Rect2:
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for point: Vector2 in points: lo=lo.min(point);hi=hi.max(point)
	return Rect2(lo,hi-lo)
func primitive(id: String,points: PackedVector2Array,rect: bool=false) -> Dictionary:
	return {"id":id,"points":points,"rect":rect,"area":bounds(points)}
func affine(raw: Variant,anchor: Vector2,foot: Vector2,scale_value: float) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for point: Vector2 in poly(raw): out.append(foot+(point-anchor)*scale_value)
	return out
func rect_points(raw: Array) -> PackedVector2Array:
	var lo:=Vector2(float(raw[0]),float(raw[1]));var hi:=lo+Vector2(float(raw[2]),float(raw[3]))
	return PackedVector2Array([lo,Vector2(hi.x,lo.y),hi,Vector2(lo.x,hi.y)])
func asset_primitives(id: String,asset: Dictionary,foot: Vector2,scale_value: float) -> Array:
	var result: Array=[];var anchor: Vector2=v(asset.source_ground_anchor_px)
	for source: Variant in asset.get("ground_solid_polygons_px",[]): result.append(primitive(id,affine(source,anchor,foot,scale_value)))
	for source: Array in asset.get("ground_solid_rects_xywh_px",[]): result.append(primitive(id,affine(rect_points(source),anchor,foot,scale_value)))
	return result
func old_model(rows: Array) -> Array:
	var out: Array=[]
	for row: Dictionary in rows:
		if not need(row.get("points_px") is PackedVector2Array and row.kind in ["POLYGON","PARENT_EXACT_CLOSED_RECT"] and not String(row.owner_id).is_empty(),"FIXED_PARENT_PRIMITIVE_SCHEMA"): return []
		out.append(primitive(String(row.owner_id),row.points_px,row.kind=="PARENT_EXACT_CLOSED_RECT"))
	return out
func independently_project(old: Array,author: Dictionary,parent_author: Dictionary,cloth_donor: Dictionary,herb_donor: Dictionary,corridor_donor: Dictionary) -> Array:
	# Source fields are checked against independent immutable donors before any projection.
	if not need(author.assets.vertical_wall==parent_author.assets.vertical_wall and author.assets.low_wall==parent_author.assets.low_wall,"UNCHANGED_WALL_SOURCE_DONORS"): return []
	var cloth: Dictionary=cloth_donor.assets.cloth_rack
	if not need(author.assets.cloth_rack.texture==cloth.texture and v(author.assets.cloth_rack.source_ground_anchor_px)==v(cloth.ground_anchor) and var_to_bytes(poly(author.assets.cloth_rack.ground_solid_polygons_px[0]))==var_to_bytes(poly(cloth.solid_polygons[0])),"C2AA_CLOTH_SOURCE_ANCHOR_POLYGON"): return []
	var herbs: Array=[]
	for row: Dictionary in herb_donor.furniture:
		if row.id=="herbal_shop_medicine_worktable_2": herbs.append(row)
	if not need(herbs.size()==1 and author.assets.medicine_table.texture==herbs[0].texture and v(author.assets.medicine_table.source_ground_anchor_px)==v(herbs[0].source_ground_anchor_px) and var_to_bytes(poly(author.assets.medicine_table.ground_solid_polygons_px[0]))==var_to_bytes(poly(herbs[0].source_ground_solid_polygons_px[0])),"705F_MEDICINE_SOURCE_ANCHOR_POLYGON"): return []
	var corridors: Array=[]
	for row: Dictionary in corridor_donor.assets:
		if row.id=="corridor": corridors.append(row)
	if not need(corridors.size()==1,"UNIQUE_C210_CORRIDOR_DONOR"): return []
	var corridor: Dictionary=corridors[0]
	var historical_texture: String=String(corridor.texture).replace("res://",String(cfg.game_root)+"/")
	if not need(v(author.assets.corridor.source_ground_anchor_px)==v(corridor.ground_anchor) and author.assets.corridor.source_sha256=="a335bb05e3155a1933314525824b90eba098bbd878f1f85d1db60889a549388d" and FileAccess.get_sha256(historical_texture)==author.assets.corridor.source_sha256,"C210_CORRIDOR_ANCHOR_AND_SAME_BYTES_APPROVED_FORMAL_COPY"): return []
	# Four column footprints are copied from the source contract, not current render output.
	var columns: Array=[[584,766,124,40],[1039,766,116,40],[1465,766,119,40],[1904,766,124,40]]
	for i: int in range(4):
		if not need(var_to_bytes(rect_points(author.assets.corridor.ground_solid_rects_xywh_px[i]))==var_to_bytes(rect_points(columns[i])) and var_to_bytes(rect_points(corridor.solid_rects_px[i]))==var_to_bytes(rect_points(columns[i])),"EXACT_C210_COLUMN:"+str(i)): return []
	var out: Array=[];var found: Dictionary={}
	for row: Dictionary in old:
		if row.id in CHANGED25G: found[row.id]=true
		else: out.append(row.duplicate(true))
	if not need(found.size()==7 and author.changes.size()==7 and author.additions.size()==2,"ONLY_SEVEN_OLD_IDS_TWO_ADDITIONS"): return []
	var ids: Array=CHANGED25G.duplicate();ids.append_array(ADDED25G)
	var feet: Array=[Vector2(1390,1372),Vector2(2050,1372),Vector2(2340,1372),Vector2(2938,1372),Vector2(2829,1372),Vector2(1735,1308),Vector2(2685,1308),Vector2(1720,1372),Vector2(2660,1372)]
	var factors: Array=[.65,.65,.65,.65,218.0/630.0,.12,.16,.36,.36]
	var asset_ids: Array=["vertical_wall","vertical_wall","vertical_wall","vertical_wall","low_wall","cloth_rack","medicine_table","corridor","corridor"]
	var places: Array=author.changes.duplicate();places.append_array(author.additions)
	for i: int in range(9):
		var place: Dictionary=places[i]
		if not need(place.id==ids[i] and place.asset_id==asset_ids[i] and v(place.foot_px)==feet[i] and float(place.scale)==float(factors[i]),"INDEPENDENT_NINE_ROOT_EXPRESSIONS:"+str(i)): return []
		out.append_array(asset_primitives(ids[i],author.assets[asset_ids[i]],feet[i],float(factors[i])))
	var left: float=(Vector2(1720,1372)+(Vector2(1155,766)-Vector2(1307,807))*.36).x
	var right: float=(Vector2(1720,1372)+(Vector2(1465,766)-Vector2(1307,807))*.36).x
	var opening: float=right-left;var height: float=(Vector2(0,357)*.36).y
	report["gallery_clearance"]={"source_center_width":310,"design_nominal_width":111.6,"native_f32_world_left":left,"native_f32_world_right":right,"native_f32_width":opening,"source_clear_height":357,"design_nominal_height":128.52,"native_f32_height":height,"old_low_wall_gate_width":120,"not_claimed_gallery_width120":true}
	if not need(opening>=96 and height>114.8,"CENTRAL_COLUMN_OPENING_GE96_AND_INHERITED_ADULT114_8_HEIGHT"): return []
	return out

func domains(old: Array,child: Array) -> Array:
	var boxes: Array=[]
	for rows: Array in [old,child]:
		for row: Dictionary in rows:
			if row.id not in CHANGED25G and row.id not in ADDED25G: continue
			var box: Rect2=row.area
			boxes.append(Rect2i(floori(box.position.x)-1,floori(box.position.y)-1,ceili(box.end.x)-floori(box.position.x)+3,ceili(box.end.y)-floori(box.position.y)+3))
	var merged: Array=[]
	for box: Rect2i in boxes:
		var current:=box.intersection(Rect2i(Vector2i.ZERO,MAP_SIZE));var again: bool=true
		while again:
			again=false
			for i: int in range(merged.size()):
				var other: Rect2i=merged[i]
				if current.position.x<=other.end.x and other.position.x<=current.end.x and current.position.y<=other.end.y and other.position.y<=current.end.y:
					current=current.merge(other);merged.remove_at(i);again=true;break
		merged.append(current)
	var visits: int=0
	for box: Rect2i in merged: visits+=box.size.x*box.size.y
	report["half_open_domains"]=[]
	for box: Rect2i in merged: report.half_open_domains.append([box.position.x,box.position.y,box.end.x,box.end.y])
	report["union_visited_pixels"]=visits
	if not need(visits>0 and visits<=500000,"LOCAL_UNION_LIMIT500K_NOT_WHOLE_MAP"): return []
	return merged
func local_rows(rows: Array,domain: Rect2i) -> Array:
	var out: Array=[]
	for row: Dictionary in rows:
		var box: Rect2=row.area
		if floori(box.position.x)<domain.end.x and ceili(box.end.x)>=domain.position.x and floori(box.position.y)<domain.end.y and ceili(box.end.y)>=domain.position.y: out.append(row)
	return out
func occupied(point: Vector2,rows: Array) -> bool:
	if point.x<24 or point.y<24 or point.x>=3048 or point.y>=2024: return true
	for row: Dictionary in rows:
		var box: Rect2=row.area
		if row.rect:
			if point.x>=ceili(box.position.x) and point.x<ceili(box.end.x) and point.y>=ceili(box.position.y) and point.y<ceili(box.end.y): return true
		elif point.x>=floori(box.position.x) and point.x<=ceili(box.end.x) and point.y>=floori(box.position.y) and point.y<=ceili(box.end.y) and Geometry2D.is_point_in_polygon(point,row.points): return true
	return false
func image(path: String) -> Image:
	var out:=Image.load_from_file(path);report.PNG_decodes+=1
	if out==null or out.get_size()!=MAP_SIZE or out.has_mipmaps() or out.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return null
	if out.get_format()!=Image.FORMAT_RGBA8: out.convert(Image.FORMAT_RGBA8)
	return out
func prior(old: Array,child: Array,areas: Array) -> Dictionary:
	var parent: Image=image(cfg.parent_walk);var raw: Image=image(cfg.raw_walk)
	if not need(parent!=null and raw!=null,"TWO_EXISTING_MASK_SUPPORT_PNG_ONLY"): return {}
	var original: PackedByteArray=parent.get_data();var support: PackedByteArray=raw.get_data();var next: PackedByteArray=original.duplicate()
	if not need(digest(original)=="b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06","FIXED_B6D6_PARENT_RGBA"): return {}
	var changed:=PackedInt32Array();var visited: int=0
	for area: Rect2i in areas:
		var before: Array=local_rows(old,area);var after: Array=local_rows(child,area)
		for y: int in range(area.position.y,area.end.y):
			if Time.get_ticks_msec()>=deadline: need(false,"WHOLE60S_NO_EXTENSION");return {}
			for x: int in range(area.position.x,area.end.x):
				visited+=1;var offset: int=(y*3072+x)*4;var was: bool=occupied(Vector2(x,y),before);var now: bool=occupied(Vector2(x,y),after);var different: bool=false
				for c: int in range(4):
					var black: int=255 if c==3 else 0
					var expected: int=black if was else support[offset+c]
					if original[offset+c]!=expected:
						report["first_old_mismatch"]=[x,y,c,original[offset+c],expected];need(false,"PARENT_LOCAL_RGBA_DIFFERS_SOURCE");return {}
					var desired: int=black if now else support[offset+c];next[offset+c]=desired;different=different or desired!=original[offset+c]
				if different: changed.append(y*3072+x)
	var inverse: PackedByteArray=next.duplicate()
	for index: int in changed:
		for c: int in range(4): inverse[index*4+c]=original[index*4+c]
	if not need(inverse==original and visited==int(report.union_visited_pixels),"WHOLE_RGBA_INVERSE_OUTSIDE_DOMAINS_IDENTICAL"): return {}
	return {"image":Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,next),"sha256":digest(next),"changed":changed.size(),"visited":visited,"inverse_sha256":digest(inverse)}

func closed_segment(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	if Geometry2D.segment_intersects_segment(a,b,c,d)!=null: return true
	for point: Vector2 in [a,b]:
		if (d-c).cross(point-c)==0 and point.x>=minf(c.x,d.x) and point.x<=maxf(c.x,d.x) and point.y>=minf(c.y,d.y) and point.y<=maxf(c.y,d.y): return true
	for point: Vector2 in [c,d]:
		if (b-a).cross(point-a)==0 and point.x>=minf(a.x,b.x) and point.x<=maxf(a.x,b.x) and point.y>=minf(a.y,b.y) and point.y<=maxf(a.y,b.y): return true
	return false
func body_safe(foot: Vector2,size: Vector2,rows: Array,mask: Image) -> bool:
	var area:=Rect2(foot-size*.5,size)
	var body:=PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
	for row: Dictionary in rows:
		var box: Rect2=row.area
		if area.position.x>box.end.x or area.end.x<box.position.x or area.position.y>box.end.y or area.end.y<box.position.y: continue
		var shape: PackedVector2Array=row.points
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,shape): return false
		for point: Vector2 in shape:
			if point.x>=area.position.x and point.x<=area.end.x and point.y>=area.position.y and point.y<=area.end.y: return false
		for i: int in range(4):
			for j: int in range(shape.size()):
				if closed_segment(body[i],body[(i+1)%4],shape[j],shape[(j+1)%shape.size()]): return false
	for y: int in range(roundi(area.position.y),roundi(area.end.y)+1):
		for x: int in range(roundi(area.position.x),roundi(area.end.x)+1):
			var color: Color=mask.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	for fraction: Vector2 in [Vector2(-.5,-.5),Vector2(0,-.5),Vector2(.5,-.5),Vector2(-.5,0),Vector2.ZERO,Vector2(.5,0),Vector2(-.5,.5),Vector2(0,.5),Vector2(.5,.5),Vector2(-.25,-.5),Vector2(.25,-.5),Vector2(-.25,.5),Vector2(.25,.5),Vector2(-.5,-.25),Vector2(-.5,.25),Vector2(.5,-.25),Vector2(.5,.25)]:
		var color: Color=mask.get_pixelv(Vector2i((foot+fraction*size).round()))
		if color.r<.5 or color.a<.5: return false
	return true
func npc_safe(foot: Vector2,size: Vector2,actors: Array) -> bool:
	var lo: Vector2=foot-size*.5;var hi: Vector2=lo+size
	for actor: Dictionary in actors:
		var origin: Vector2=v(actor.origin);var travel: float=float(actor.patrol_distance) if actor.movement_mode=="patrol" else 0.0
		# Conservative superset of the unchanged patrol axis; no phase pause or guessed live position.
		var npc_lo: Vector2=origin-Vector2(17+travel,15+travel);var npc_hi: Vector2=origin+Vector2(17+travel,15+travel)
		if lo.x<=npc_hi.x and hi.x>=npc_lo.x and lo.y<=npc_hi.y and hi.y>=npc_lo.y: return false
	return true
func short_routes(author: Dictionary,rows: Array,mask: Image,actors: Array) -> bool:
	var count: int=0
	for route: Dictionary in author.local_routes:
		var a: Vector2=v(route.points_px[0]);var b: Vector2=v(route.points_px[1]);var steps: int=ceili(a.distance_to(b)/4.0)
		if not need(a.y==1384 and steps>0 and steps<=11,"FOUR_EXPLICIT_NEW1384_SHORT_ROUTE_STARTS"): return false
		for step: int in range(steps+1):
			var foot: Vector2=a.lerp(b,float(step)/float(steps));count+=1
			if not need(body_safe(foot,Vector2(34,24),rows,mask) and body_safe(foot,Vector2(34,30),rows,mask) and npc_safe(foot,Vector2(34,24),actors) and npc_safe(foot,Vector2(34,30),actors),"AFFECTED_SHORT_BODY_AND_UNCHANGED_NPC:"+String(route.id)+":"+str(step)): return false
	for foot: Vector2 in [Vector2(1720,1364),Vector2(2660,1364)]:
		if not need(body_safe(foot,Vector2(34,24)*1.35,rows,mask) and npc_safe(foot,Vector2(34,24)*1.35,actors),"NEW_ONLY_CONSERVATIVE135_CENTER_PROBE_NOT_OLD_CONTRACT"): return false
	for foot: Vector2 in [Vector2(1720,1396),Vector2(2660,1396),Vector2(1735,1396),Vector2(2685,1396)]:
		if not need(not npc_safe(foot,Vector2(34,24),actors),"ORIGINAL1396_BUYER_BODY_NEGATIVE_CONTROL"): return false
	var negative_columns: int=0
	for row: Dictionary in rows:
		if row.id in ADDED25G:
			if not need(not body_safe(row.area.get_center(),Vector2(34,24),rows,mask),"COLUMN_FOOT_BODY_NEGATIVE_CONTROL"): return false
			negative_columns+=1
	report["short_route_samples"]=count;report["NEW_only135_center_probes"]=2;report["135_not_inherited_old_contract"]=true;report["NPC_original1396_negative_controls"]=4;report["column_negative_controls"]=negative_columns;report["body_sizes"]=[[34,24],[34,30]];report["mask_body_grid_counts"]=[875,1085];report["additional_boundary_probes_per_body"]=17
	return true
func finish() -> void:
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path);need(final[path]==first[path],"FIXED_SOURCE_FINAL:"+path)
	report["source_first"]=first;report["source_final"]=final;report["checks"]=checks;report["errors"]=errors;report["failures"]=errors.size();report["elapsed_ms"]=Time.get_ticks_msec()-began
	report["ready"]=report.get("ready",false) and errors.is_empty() and Time.get_ticks_msec()<deadline
	if not cfg.is_empty():
		var path: String=cfg.output_prefix+str(OS.get_process_id())+"/prior.json"
		if not FileAccess.file_exists(path) and DirAccess.make_dir_recursive_absolute(path.get_base_dir())==OK:
			var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true,true));file.close();print("INDEPENDENT25G_PRIOR ",path)
	quit(0 if report.ready else 1)
func run() -> void:
	if not need(READY25G and FileAccess.get_sha256(INPUT25G)==INPUT_SHA25G,"ROOT_FROZEN_READY_INPUT_ONLY"): finish();return
	cfg=read_json(INPUT25G);first[INPUT25G]=INPUT_SHA25G
	if not need(cfg.ready==true and cfg.whole_ms==60000 and root.get_children().is_empty(),"ISOLATED_NO_AUTOLOAD60S"): finish();return
	for path: String in cfg.pins:
		first[path]=FileAccess.get_sha256(path)
		if not need(first[path]==cfg.pins[path],"FIXED_SOURCE_FIRST:"+path): finish();return
	var raw: Variant=bytes_to_var(FileAccess.get_file_as_bytes(cfg.parent_geometry));report.binary_decodes=1
	if not need(raw is Array,"FIXED05C6_GEOMETRY_ARRAY"): finish();return
	var old: Array=old_model(raw);var author: Dictionary=read_json(cfg.author)
	var child: Array=independently_project(old,author,read_json(cfg.parent_author),read_json(cfg.cloth_donor),read_json(cfg.herb_donor),read_json(cfg.corridor_donor))
	if child.is_empty(): finish();return
	var areas: Array=domains(old,child)
	if areas.is_empty(): finish();return
	var pixel: Dictionary=prior(old,child,areas)
	if pixel.is_empty(): finish();return
	var actors: Array=read_json(cfg.NPC_seed).expected_npc_positions
	if not short_routes(author,child,pixel.image,actors): finish();return
	report["parent_RGBA_sha256"]="b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06";report["expected_child_RGBA_sha256"]=pixel.sha256;report["changed_pixels"]=pixel.changed;report["union_visited_pixels"]=pixel.visited;report["full_RGBA_inverse"]=true;report["outside_domains_unchanged"]=true;report["author_sha256"]=cfg.pins[cfg.author];report["ready"]=true
	finish()
