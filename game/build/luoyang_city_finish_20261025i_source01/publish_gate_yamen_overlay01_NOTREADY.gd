extends SceneTree
# ROOT-only CPU publication; no Field, original packet decode, Scene or import.
const READY: bool=false
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/gate_yamen_publication_input01_NOTREADY.json"
const INPUT_SHA: String="PENDING_INPUT_FREEZE"
var config: Dictionary={}
var checks: int=0
var errors: Array=[]
var first: Dictionary={}
var started: int=0
var out: String=""

func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label)
	return ok
func digest(bytes: PackedByteArray) -> String:
	var c: HashingContext=HashingContext.new();c.start(HashingContext.HASH_SHA256);c.update(bytes)
	return c.finish().hex_encode()
func json_file(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func write_bytes(path: String,bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path): return false
	var stream: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if stream==null: return false
	stream.store_buffer(bytes);stream.close()
	return true
func finish(rows: Dictionary) -> void:
	var final: Dictionary={}
	for path: String in first: final[path]=FileAccess.get_sha256(path)
	check(final==first,"EXACT_SOURCE_FIRST_FINAL")
	var result: Dictionary={"status":"SOURCE_ONLY_TWO_NEW_LOCAL_DOMAIN_COMPONENTS_NOT_RUNTIME","complete":errors.is_empty(),"checks":checks,"failures":errors.size(),"errors":errors.duplicate(true),"elapsed_ms":Time.get_ticks_msec()-started,"source_first":first,"source_final":final,"scenes":rows,"packet_decodes":0,"old_route_replays":0,"Field_calls":0,"import_calls":0}
	if not out.is_empty(): write_bytes(out+"/result.json",(JSON.stringify(result,"\t")+"\n").to_utf8_buffer())
	print(JSON.stringify(result));quit(0 if errors.is_empty() else 1)
func image(path: String) -> Image:
	var result: Image=Image.load_from_file(path)
	if result==null or result.get_size()!=Vector2i(3072,2048) or result.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return null
	if result.get_format()==Image.FORMAT_RGB8: result.convert(Image.FORMAT_RGBA8)
	return result
func polygon_bounds(points: PackedVector2Array) -> Rect2:
	var lo: Vector2=Vector2(INF,INF);var hi: Vector2=Vector2(-INF,-INF)
	for p: Vector2 in points: lo=lo.min(p);hi=hi.max(p)
	return Rect2(lo,hi-lo)
func active_for_domain(rows: Array,rect: Array) -> Array:
	var result: Array=[]
	var domain: Rect2=Rect2(float(rect[0]),float(rect[1]),float(rect[2])-float(rect[0])+1.0,float(rect[3])-float(rect[1])+1.0)
	for row: Dictionary in rows:
		var bounds: Rect2=polygon_bounds(row.points_px)
		if bounds.intersects(domain,true): result.append({"kind":row.kind,"points_px":row.points_px,"bounds":bounds})
	return result
func blocked(point: Vector2,active: Array) -> bool:
	if point.x<24 or point.y<24 or point.x>=3048 or point.y>=2024: return true
	for row: Dictionary in active:
		var area: Rect2=row.bounds
		if row.kind=="EXACT_EXISTING_CLOSED_RECT":
			# Original native half-open integer rectangle raster, not polygon-edge inclusive.
			if point.x>=ceili(area.position.x) and point.x<ceili(area.end.x) and point.y>=ceili(area.position.y) and point.y<ceili(area.end.y): return true
		elif point.x>=area.position.x and point.x<=area.end.x and point.y>=area.position.y and point.y<=area.end.y:
			if Geometry2D.is_point_in_polygon(point,row.points_px): return true
	return false
func local_pixels(parent: Image,raw: Image,primitives: Array,domains: Array,budget: int) -> Dictionary:
	var before: PackedByteArray=parent.get_data();var after: PackedByteArray=before.duplicate();var support: PackedByteArray=raw.get_data()
	var changed: PackedInt32Array=PackedInt32Array();var inverse: PackedByteArray=PackedByteArray();var visited: int=0
	for rect: Array in domains:
		var active: Array=active_for_domain(primitives,rect)
		for y: int in range(int(rect[1]),int(rect[3])+1):
			if Time.get_ticks_msec()-started>int(config.whole_budget_ms): return {}
			for x: int in range(int(rect[0]),int(rect[2])+1):
				visited+=1
				if visited>budget: return {}
				var offset: int=(y*3072+x)*4
				var next: PackedByteArray=PackedByteArray([0,0,0,255]) if blocked(Vector2(x,y),active) else support.slice(offset,offset+4)
				if before.slice(offset,offset+4)!=next:
					changed.append(offset);inverse.append_array(before.slice(offset,offset+4))
					after[offset]=next[0];after[offset+1]=next[1];after[offset+2]=next[2];after[offset+3]=next[3]
	var restored: PackedByteArray=after.duplicate()
	for i: int in range(changed.size()):
		for channel: int in range(4): restored[changed[i]+channel]=inverse[i*4+channel]
	if restored!=before: return {}
	return {"rgba":after,"changed_pixels":changed.size(),"visited":visited,"pixel_inverse":{"offsets":changed,"RGBA":inverse},"outside_and_inverse_whole_exact":true}
func run() -> void:
	started=Time.get_ticks_msec()
	if not check(READY and FileAccess.get_sha256(INPUT)==INPUT_SHA,"ROOT_READY_EXACT_INPUT"): finish({});return
	config=json_file(INPUT)
	if not check(config.get("ready")==true and config.get("independent_prior") is Dictionary,"FIXED_INDEPENDENT_PRIOR_REQUIRED"): finish({});return
	for path: String in config.sources:
		var actual: String=FileAccess.get_sha256(path)
		if not check(actual==String(config.sources[path]),"SOURCE:"+path): finish({});return
		first[path]=actual
	var compiler: Variant=load(String(config.compiler_path))
	if not check(compiler is GDScript and compiler.can_instantiate(),"PURE_PROJECTOR_LOAD"): finish({});return
	var author: Dictionary=json_file(String(config.author_path));var library: Dictionary=json_file(String(config.library_path))
	var seed: Variant=bytes_to_var(FileAccess.get_file_as_bytes(String(config.parent_seed_path)))
	if not check(seed is Dictionary,"OLD_PARENT_SOURCE_SEED_ONLY"): finish({});return
	var prior: Dictionary=json_file(String(config.independent_prior.path))
	var prior_rows: Variant=bytes_to_var(FileAccess.get_file_as_bytes(String(config.independent_prior.expected_primitives_path)))
	if not check(prior.get("passed")==true and prior_rows is Dictionary,"INDEPENDENT_PRIOR_TYPED_EXPECTATIONS"): finish({});return
	out=String(config.output_root)+"/"+str(OS.get_process_id())
	if not check(not DirAccess.dir_exists_absolute(out) and DirAccess.make_dir_recursive_absolute(out)==OK,"NEW_OUTPUT_ROOT_ONLY"): finish({});return
	var outputs: Dictionary={}
	for spec: Dictionary in author.scenes:
		var id: String=String(spec.scene_id)
		var projected: Dictionary=compiler.derive(id,author,library,seed)
		if not check(projected.get("ok")==true,"STRICT_PARENT_AND_NEW_RENDER_GROUND:"+id): finish(outputs);return
		var rows: Array=[]
		for row: Dictionary in spec.new_all_primitive_rows_source_model:
			rows.append({"id":String(row.id),"owner_id":String(row.owner_id),"kind":String(row.kind),"points_px":compiler.poly(row.points_px)})
		if not check(prior_rows.has(id) and var_to_bytes(rows)==var_to_bytes(prior_rows[id]),"FULL_INDEPENDENT_NEW_PRIMITIVE_BITS:"+id): finish(outputs);return
		var wanted: Dictionary=prior.scenes[id]
		if not check(spec.local_closed_integer_domains_xyxy==wanted.closed_domains_xyxy,"EXACT_CLOSED_DOMAINS:"+id): finish(outputs);return
		var parent: Image=image(String(spec.parent_mask_source.path));var raw: Image=image(String(spec.raw_support_source.path))
		if not check(parent!=null and raw!=null and digest(parent.get_data())==String(wanted.parent_RGBA_sha256),"FIXED_EFFECTIVE_PARENT_MASK:"+id): finish(outputs);return
		var delta: Dictionary=local_pixels(parent,raw,rows,spec.local_closed_integer_domains_xyxy,int(spec.local_domain_max_visited_pixels))
		if not check(not delta.is_empty(),"FINITE_LOCAL_RASTER_AND_WHOLE_INVERSE:"+id): finish(outputs);return
		if not check(digest(delta.rgba)==String(wanted.expected_child_RGBA_sha256) and int(delta.changed_pixels)==int(wanted.changed_pixels) and int(delta.visited)==int(wanted.union_visited_pixels),"INDEPENDENT_PIXEL_PRIOR:"+id): finish(outputs);return
		var prefix: String=out+"/"+id
		if not check(DirAccess.make_dir_recursive_absolute(prefix)==OK,"NEW_COMPONENT_DIRECTORY"): finish(outputs);return
		var mask: Image=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,delta.rgba)
		if not check(mask.save_png(prefix+"/walk_overlay.png")==OK,"SAVE_NEW_MASK"): finish(outputs);return
		for artifact: String in ["render_projection","geometry","pixel_inverse"]:
			var value: Variant=projected.render_objects if artifact=="render_projection" else (rows if artifact=="geometry" else delta.pixel_inverse)
			if not check(write_bytes(prefix+"/"+artifact+".bin",var_to_bytes(value)),"SAVE_COMPONENT:"+artifact): finish(outputs);return
		outputs[id]={"prefix":prefix,"render_count":projected.render_objects.size(),"ground_count":rows.size(),"RGBA_sha256":digest(delta.rgba),"changed_pixels":delta.changed_pixels,"union_visited_pixels":delta.visited,"mask_consumer_layer":"Gate old native28 outside domains; full new47 inside; existing DG retained separately until final effective-ground lease replaces, never double-add. Yamen old effective40 to new42."}
	finish(outputs)
