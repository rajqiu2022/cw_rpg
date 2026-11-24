extends SceneTree
## Independent QA implementation, prepared only. Root alone may authorize a mechanical READY copy.
## No System helper loads, no publisher artifacts, no ResourceLoader, no native writes.
const ROOT_READY=false
const SELF="res://build/luoyang_city_revision_20261024e_docks_qa01/independent_prior_NOTREADY.gd"
const INPUT="res://build/luoyang_city_revision_20261024e_docks_qa01/input_NOTREADY.json"
const INPUT_SHA="a90840fe1c73f72dceee9f017592bd7d5a5b217160715cfa8606be8f442d89dd"
const OUT="res://build/luoyang_city_revision_20261024e_docks_qa01/runs/"
const SCENE="ch4_s2_canal_docks"
const IDS=["north_canal_warehouse","harbour_rope_shop","harbour_quay_supply_shop"]
var began: int=0
var failures: Array[String]=[]
var checks: int=0
var cfg: Dictionary={}
var first: Dictionary={}
var result: Dictionary={"ready":false,"passed":false,"expected_child_RGBA_sha256":"UNKNOWN","changed_pixels":null,"union_visited_pixels":null,"domains":[],"packet_decode_count":0,"raw_PNG_decode_count":0,"Field":0,"collector":0,"formal_writes":0,"native_resource_writes":0}

func _initialize() -> void:
	began=Time.get_ticks_msec()
	call_deferred("run")
func require(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label)
	return ok
func in_time() -> bool:
	return Time.get_ticks_msec()-began<60000
func digest(data: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()
func read_json(path: String) -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
func point(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
func array_point(p: Vector2) -> Array:
	return [float(p.x),float(p.y)]
func shape(raw: Variant) -> PackedVector2Array:
	var points:=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return points
	for value: Variant in raw:
		var p: Vector2=point(value)
		if not p.is_finite(): return PackedVector2Array()
		points.append(p)
	return points
func only(rows: Array,id: String) -> Dictionary:
	var matches: Array=[]
	for row: Dictionary in rows:
		if String(row.get("id",""))==id: matches.append(row)
	return matches[0] if matches.size()==1 else {}
func same_shape_lists(left: Array,right: Array) -> bool:
	if left.size()!=right.size(): return false
	for index: int in range(left.size()):
		if var_to_bytes(shape(left[index]))!=var_to_bytes(shape(right[index])): return false
	return true
func affine_polys(polys: Array,origin: Vector2,destination: Vector2,factor: float) -> Array:
	var transformed: Array=[]
	for poly: Variant in polys:
		var p: PackedVector2Array=shape(poly)
		if p.size()<3: return []
		var row: Array=[]
		for vertex: Vector2 in p: row.append(array_point(destination+(vertex-origin)*factor))
		transformed.append(row)
	return transformed

func independently_project(parent: Dictionary,docks: Dictionary,market: Dictionary) -> Dictionary:
	# These expressions are fixed from source donors and the Root handoff, not author output.
	var donor_ids: Array=["north_canal_warehouse","shop","shop"]
	var donor_sources: Array=[docks,market,market]
	var source_feet: Array=[Vector2(870,580),Vector2(2320,850),Vector2(2320,850)]
	var old_feet: Array=[Vector2(870,580),Vector2(720,1420),Vector2(1930,530)]
	var new_feet: Array=[Vector2(754,580),Vector2(600,1510),Vector2(1860,640)]
	var old_ratios: Array=[1.0,0.85,0.8]
	var new_ratios: Array=[1.0,145.0/312.0/0.5,145.0/312.0/0.5]
	var child: Dictionary=parent.duplicate(true)
	var undo: Array=[]
	for i: int in range(3):
		var donor: Dictionary=only(donor_sources[i].get("objects",[]),donor_ids[i])
		var old: Dictionary=only(parent.objects,IDS[i])
		var replacement: Dictionary=only(child.objects,IDS[i])
		if not require(not donor.is_empty() and not old.is_empty() and not replacement.is_empty(),"UNIQUE_DONOR_AND_NATIVE:"+IDS[i]): return {}
		var before: Array=affine_polys(donor.get("solid_polygons_px",[]),source_feet[i],old_feet[i],float(old_ratios[i]))
		var after: Array=affine_polys(donor.get("solid_polygons_px",[]),source_feet[i],new_feet[i],float(new_ratios[i]))
		if not require(point(donor.world_foot_px)==source_feet[i] and point(old.world_foot_px)==old_feet[i] and point(old.physical_center_px)==old_feet[i] and point(old.collision_size_px)==Vector2.ZERO and old.texture==donor.texture and old.source_sha256==donor.source_sha256 and point(old.render_size_px)==point(donor.render_size_px)*float(old_ratios[i]) and before.size()==1 and after.size()==1 and same_shape_lists(old.solid_polygons_px,before),"INDEPENDENT_OLD_DONOR_EXPRESSION:"+IDS[i]): return {}
		undo.append(old.duplicate(true))
		replacement.world_foot_px=array_point(new_feet[i])
		replacement.physical_center_px=array_point(new_feet[i])
		replacement.render_size_px=array_point(point(donor.render_size_px)*float(new_ratios[i]))
		replacement.depth_foot_y=float(new_feet[i].y)
		replacement.solid_polygons_px=after
		if replacement.has("world_origin_px"):
			replacement.world_origin_px=array_point(new_feet[i]+(point(donor.get("world_origin_px"))-source_feet[i])*float(new_ratios[i]))
		if replacement.has("harbour_transform"):
			if not require(point(replacement.harbour_transform.get("foot"))==old_feet[i] and float(replacement.harbour_transform.get("ratio"))==float(old_ratios[i]),"OLD_TRANSFORM:"+IDS[i]): return {}
			replacement.harbour_transform.foot=array_point(new_feet[i])
			replacement.harbour_transform.ratio=float(new_ratios[i])
	var restored: Dictionary=child.duplicate(true)
	for i: int in range(restored.objects.size()):
		for row: Dictionary in undo:
			if restored.objects[i].id==row.id: restored.objects[i]=row.duplicate(true)
	if not require(var_to_bytes(restored)==var_to_bytes(parent),"COMPLETE_PARENT_RECORD_TYPED_AND_PACKED_INVERSE"): return {}
	return {"child":child,"original_rows":undo,"restored":restored}

func district_rows(author: Dictionary) -> Array:
	var placements: Array=author.get("districts",{}).get(SCENE,{}).get("placements",[])
	var rows: Array=[]
	var seen: Dictionary={}
	if not require(placements.size()==10,"DG_SOURCE_TEN"): return []
	for placement: Dictionary in placements:
		if not require(not seen.has(placement.id) and not placement.has("replaces"),"DG_ADDITIONS_NOT_REPLACEMENTS"): return []
		seen[placement.id]=true
		var asset: Dictionary=author.get("assets",{}).get(placement.asset_id,{})
		var solids: Array=affine_polys(asset.get("ground_solid_polygons_px",[]),point(asset.get("source_ground_anchor_px")),point(placement.foot_px),float(placement.scale))
		if not require(not solids.is_empty() and float(placement.scale)>0,"DG_SOURCE_AFFINE"): return []
		rows.append({"id":placement.id,"solid_polygons_px":solids,"collision_size_px":[0,0]})
	return rows

func primitives(rows: Array) -> Array:
	var all: Array=[]
	for row: Dictionary in rows:
		for raw: Variant in row.get("solid_polygons_px",[]):
			var p: PackedVector2Array=shape(raw)
			if p.size()<3: return []
			var low:=Vector2(INF,INF)
			var high:=Vector2(-INF,-INF)
			for vertex: Vector2 in p:
				low=low.min(vertex)
				high=high.max(vertex)
			all.append({"polygon":p,"lo":low,"hi":high,"box":false})
		var extent: Vector2=point(row.get("collision_size_px",[0,0]))
		if extent.x>0:
			var rect_low: Vector2=point(row.get("physical_center_px"))-extent*.5
			var rect_high: Vector2=rect_low+extent
			all.append({"polygon":PackedVector2Array([rect_low,Vector2(rect_high.x,rect_low.y),rect_high,Vector2(rect_low.x,rect_high.y)]),"lo":rect_low,"hi":rect_high,"box":true})
	return all
func packet_multiset_equal(packet: Array,derived: Array) -> bool:
	var counts: Dictionary={}
	for raw: Variant in packet:
		var key: String=var_to_bytes(shape(raw)).hex_encode()
		counts[key]=int(counts.get(key,0))+1
	for item: Dictionary in derived:
		var derived_key: String=var_to_bytes(item.polygon).hex_encode()
		if int(counts.get(derived_key,0))<=0: return false
		counts[derived_key]=int(counts[derived_key])-1
	for counted_key: String in counts:
		if int(counts[counted_key])!=0: return false
	return packet.size()==derived.size()

func closed_domains(old: Array,next: Array) -> Array:
	var changed_rows: Array=old.duplicate(true)
	for id: String in IDS: changed_rows.append(only(next,id))
	var boxes: Array=[]
	for item: Dictionary in primitives(changed_rows):
		boxes.append([floori(item.lo.x),floori(item.lo.y),ceili(item.hi.x),ceili(item.hi.y)])
	# Iterative pair-union independent of source helper's Rect2i implementation.
	var retry: bool=true
	while retry:
		retry=false
		for i: int in range(boxes.size()):
			if retry: break
			for j: int in range(i+1,boxes.size()):
				var a: Array=boxes[i]
				var b: Array=boxes[j]
				if int(a[0])<=int(b[2])+1 and int(b[0])<=int(a[2])+1 and int(a[1])<=int(b[3])+1 and int(b[1])<=int(a[3])+1:
					boxes[i]=[mini(a[0],b[0]),mini(a[1],b[1]),maxi(a[2],b[2]),maxi(a[3],b[3])]
					boxes.remove_at(j)
					retry=true
					break
	boxes.sort_custom(func(a: Array,b: Array) -> bool: return a[1]<b[1] if a[1]!=b[1] else a[0]<b[0])
	var total: int=0
	for box: Array in boxes:
		if not require(box[0]>=0 and box[1]>=0 and box[2]<3072 and box[3]<2048,"CLOSED_DOMAIN_INSIDE_MAP"): return []
		total+=(int(box[2])-int(box[0])+1)*(int(box[3])-int(box[1])+1)
	if not require(total>0 and total<=500000,"MAXIMUM_UNIQUE_DOMAIN_PIXELS"): return []
	return boxes

func occupancy(domain: Array,all: Array) -> PackedByteArray:
	var width: int=int(domain[2])-int(domain[0])+1
	var height: int=int(domain[3])-int(domain[1])+1
	var occupied:=PackedByteArray()
	occupied.resize(width*height)
	occupied.fill(0)
	for item: Dictionary in all:
		# Exact original C loops: polygon floor-low..ceil-high inclusive; box ceil-low..ceil-high exclusive.
		var x0: int=maxi(domain[0],ceili(item.lo.x) if item.box else floori(item.lo.x))
		var y0: int=maxi(domain[1],ceili(item.lo.y) if item.box else floori(item.lo.y))
		var x1: int=mini(int(domain[2])+1,ceili(item.hi.x)+(0 if item.box else 1))
		var y1: int=mini(int(domain[3])+1,ceili(item.hi.y)+(0 if item.box else 1))
		for y: int in range(y0,y1):
			if not in_time(): return PackedByteArray()
			for x: int in range(x0,x1):
				if item.box or Geometry2D.is_point_in_polygon(Vector2(x,y),item.polygon): occupied[(y-int(domain[1]))*width+x-int(domain[0])]=1
	# Original C's fixed 24-pixel map border.
	for y: int in range(domain[1],int(domain[3])+1):
		for x: int in range(domain[0],int(domain[2])+1):
			if x<24 or y<24 or x>=3048 or y>=2024: occupied[(y-int(domain[1]))*width+x-int(domain[0])]=1
	return occupied

func local_prior(parent: PackedByteArray,raw: PackedByteArray,old: Array,next: Array,domains: Array) -> Dictionary:
	var child: PackedByteArray=parent.duplicate()
	var changed:=PackedInt32Array()
	var prior_bytes:=PackedByteArray()
	var visited: int=0
	for domain: Array in domains:
		var width: int=int(domain[2])-int(domain[0])+1
		var old_bits: PackedByteArray=occupancy(domain,old)
		var next_bits: PackedByteArray=occupancy(domain,next)
		if not require(not old_bits.is_empty() and not next_bits.is_empty(),"BOUNDED_RASTER_COMPLETED"): return {}
		for y: int in range(domain[1],int(domain[3])+1):
			if not require(in_time(),"60_SECOND_BUDGET"): return {}
			for x: int in range(domain[0],int(domain[2])+1):
				var local: int=(y-int(domain[1]))*width+x-int(domain[0])
				var pixel: int=y*3072+x
				var offset: int=pixel*4
				visited+=1
				var different: bool=false
				for channel: int in range(4):
					var old_expected: int=(255 if channel==3 else 0) if old_bits[local]==1 else raw[offset+channel]
					if parent[offset+channel]!=old_expected:
						result["first_old_mismatch"]=[x,y,channel,parent[offset+channel],old_expected]
						require(false,"OLD_NATIVE29_LOCAL_RGBA_DOES_NOT_MATCH_SOURCE")
						return {}
					var desired: int=(255 if channel==3 else 0) if next_bits[local]==1 else raw[offset+channel]
					child[offset+channel]=desired
					different=different or desired!=parent[offset+channel]
				if different:
					changed.append(pixel)
					for channel: int in range(4): prior_bytes.append(parent[offset+channel])
	var inverse: PackedByteArray=child.duplicate()
	for index: int in range(changed.size()):
		for channel: int in range(4): inverse[changed[index]*4+channel]=prior_bytes[index*4+channel]
	if not require(inverse==parent,"COMPLETE_RGBA_PACKED_INVERSE_AND_OUTSIDE_UNTOUCHED"): return {}
	return {"child":child,"indices":changed,"old_RGBA8":prior_bytes,"visited":visited,"child_sha":digest(child),"inverse_sha":digest(inverse)}

func save_new(path: String,bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(bytes)
	file.close()
	return true
func finish() -> void:
	result["source_first"]=first
	result["source_final"]={}
	for path: String in first:
		result.source_final[path]=FileAccess.get_sha256(path)
		require(result.source_final[path]==first[path],"WHOLE_SOURCE_FINAL:"+path)
	if result.get("passed",false): require(in_time(),"FINAL_60_SECOND_BUDGET")
	result["checks"]=checks
	result["failures"]=failures
	result["elapsed_ms"]=Time.get_ticks_msec()-began
	result["passed"]=result.get("passed",false) and failures.is_empty()
	result["ready"]=result.passed
	var folder: String=OUT+str(OS.get_process_id())+"/"
	if not DirAccess.dir_exists_absolute(folder) and DirAccess.make_dir_recursive_absolute(folder)==OK:
		save_new(folder+"prior.json",(JSON.stringify(result,"\t")+"\n").to_utf8_buffer())
	print(JSON.stringify({"ready":result.ready,"prior":folder+"prior.json","failures":failures,"elapsed_ms":result.elapsed_ms}))
	quit(0 if result.ready else 1)
func run() -> void:
	if not require(ROOT_READY,"ROOT_ONLY_FROZEN_READY_COPY"): finish();return
	if not require(FileAccess.get_sha256(INPUT)==INPUT_SHA,"EXTERNAL_INPUT_PIN"): finish();return
	cfg=read_json(INPUT)
	first[INPUT]=INPUT_SHA
	first[SELF]=FileAccess.get_sha256(SELF)
	for path: String in cfg.pins:
		if not require(FileAccess.get_sha256(path)==cfg.pins[path],"SOURCE_FIRST:"+path): finish();return
		first[path]=cfg.pins[path]
	var decoded: Variant=bytes_to_var(FileAccess.get_file_as_bytes(cfg.packet))
	result.packet_decode_count=1
	if not require(decoded is Dictionary and decoded.get("record") is Dictionary and decoded.record.get("canonical_scene_id")==SCENE and decoded.record.get("objects",[]).size()==29 and decoded.get("walk_bytes") is PackedByteArray and decoded.get("solids") is Array,"PACKET_NATIVE29_SHAPE"): finish();return
	var parent: Dictionary=decoded.record
	var projection: Dictionary=independently_project(parent,read_json(cfg.docks),read_json(cfg.market))
	if projection.is_empty(): finish();return
	var old_native: Array=primitives(parent.objects)
	var additions: Array=district_rows(read_json(cfg.district))
	if not require(additions.size()==10 and packet_multiset_equal(decoded.solids,old_native),"OLD_NATIVE_PACKET_SOLID_MULTISET_AND_SOURCE_DG10"): finish();return
	var next_rows: Array=projection.child.objects.duplicate(true)
	next_rows.append_array(additions)
	var next_primitives: Array=primitives(next_rows)
	if not require(next_rows.size()==39 and not next_primitives.is_empty(),"NEW_NATIVE29_PLUS_SOURCE_DG10"): finish();return
	var parent_rgba: PackedByteArray=decoded.walk_bytes
	if not require(parent_rgba.size()==3072*2048*4 and digest(parent_rgba)==cfg.parent_RGBA_sha256,"FROZEN_PARENT_COMPLETE_RGBA_PIN"): finish();return
	var raw: Image=Image.load_from_file(cfg.raw)
	result.raw_PNG_decode_count=1
	if not require(raw!=null and raw.get_size()==Vector2i(3072,2048) and raw.get_format() in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8],"ONE_RAW_SUPPORT_DECODE"): finish();return
	if raw.get_format()!=Image.FORMAT_RGBA8: raw.convert(Image.FORMAT_RGBA8)
	var domains: Array=closed_domains(projection.original_rows,projection.child.objects)
	if domains.is_empty(): finish();return
	var prior: Dictionary=local_prior(parent_rgba,raw.get_data(),old_native,next_primitives,domains)
	if prior.is_empty(): finish();return
	for path: String in first:
		if not require(FileAccess.get_sha256(path)==first[path],"SOURCE_FINAL:"+path): finish();return
	if not require(in_time(),"TOTAL_60_SECOND_BUDGET"): finish();return
	var proof: Dictionary={"child_record":projection.child,"original_rows":projection.original_rows,"restored_record":projection.restored,"positions":prior.indices,"old_RGBA8":prior.old_RGBA8,"parent_RGBA_sha256":digest(parent_rgba),"child_RGBA_sha256":prior.child_sha,"restored_RGBA_sha256":prior.inverse_sha,"domains":domains}
	var folder: String=OUT+str(OS.get_process_id())+"_proof/"
	if not require(not DirAccess.dir_exists_absolute(folder) and DirAccess.make_dir_recursive_absolute(folder)==OK and save_new(folder+"typed_and_packed_inverse.bin",var_to_bytes(proof)),"EXCLUSIVE_QA_PROOF_ONLY"): finish();return
	result["passed"]=true
	result["author_sha256"]=cfg.pins[cfg.author]
	result["parent_RGBA_sha256"]=digest(parent_rgba)
	result["expected_child_RGBA_sha256"]=prior.child_sha
	result["changed_pixels"]=prior.indices.size()
	result["union_visited_pixels"]=prior.visited
	result["visited_pixels"]=prior.visited
	result["domains"]=domains
	result["closed_domains"]=domains
	result["parent_record_complete_typed_and_packed_inverse"]=true
	result["complete_RGBA_inverse"]=true
	result["outside_domains_untouched"]=true
	result["parent_mask_includes_DG"]=false
	result["child_local_mask_includes_DG"]=true
	result["inverse_artifact"]={"path":folder+"typed_and_packed_inverse.bin","sha256":FileAccess.get_sha256(folder+"typed_and_packed_inverse.bin")}
	finish()
