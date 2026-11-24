extends SceneTree
## Independent native PIP oracle. No candidate helper/publisher/packet/Resource calls.
const READY=false
const FIXTURE="PENDING_FIXTURE_PATH"
const FIXTURE_SHA="PENDING_FIXTURE_SHA"
const SIZE=Vector2i(3072,2048)
var checks: int=0
var errors: Array[String]=[]
var began: int=0
var deadline: int=0
var diagnostics: Array=[]
var images: int=0
var cfg: Dictionary={}

func _initialize() -> void:
	began=Time.get_ticks_msec();deadline=began+60000;call_deferred("run")
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("INDEPENDENT24E_PRIOR_FAIL ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()
func read_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"exists":true,"unreadable":true}
	var count:=file.get_length();file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":count,"mtime":FileAccess.get_modified_time(path)}
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths: result[path]=fact(path)
	return result
func v(pair: Array) -> Vector2: return Vector2(pair[0],pair[1])
func poly(raw: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Array in raw: result.append(v(point))
	return result
func pair_bits(value: Vector2) -> String: return PackedFloat32Array([value.x,value.y]).to_byte_array().hex_encode()
func source_polys(asset: Dictionary,place: Dictionary) -> Array:
	var result: Array=[]
	var anchor:=v(asset.source_ground_anchor_px);var foot:=v(place.foot_px);var scale_value: float=float(place.scale)
	for raw: Array in asset.ground_solid_polygons_px:
		var shape:=PackedVector2Array()
		for point: Vector2 in poly(raw): shape.append(foot+(point-anchor)*scale_value)
		result.append(shape)
	return result
func decode_rows(raw: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in raw:
		var shapes: Array=[]
		for shape: Array in row.polygons: shapes.append(poly(shape))
		result.append({"id":row.id,"foot":v(row.foot),"center":v(row.center),"size":v(row["size"]),"polygons":shapes})
	return result
func index_of(rows: Array,id: String) -> int:
	var result: int=-1
	for i: int in range(rows.size()):
		if rows[i].id==id:
			if result>=0: return -1
			result=i
	return result
func exact_model(rows: Array,expected: Array,label: String) -> bool:
	if not check(rows.size()==expected.size(),label+":count"): return false
	for i: int in range(rows.size()):
		var row: Dictionary=rows[i];var fixed: Dictionary=expected[i]
		if not check(row.id==fixed.id and row.polygons.size()==fixed.polygon_bits.size(),label+":id/shape:"+str(i)): return false
		for part: String in ["foot","center","size"]:
			if not check(row[part].is_finite() and pair_bits(row[part])==fixed[part+"_bits"],label+":"+row.id+":"+part): return false
		for j: int in range(row.polygons.size()):
			var shape: PackedVector2Array=row.polygons[j];var bits: Array=fixed.polygon_bits[j]
			if not check(shape.size()==bits.size(),label+":vertexcount:"+row.id): return false
			for k: int in range(shape.size()):
				if not check(shape[k].is_finite() and pair_bits(shape[k])==bits[k],label+":vertex:"+row.id+":"+str(j)+":"+str(k)): return false
	return true
func derive_before(native25: Array,parent: Dictionary) -> Array:
	var result: Array=native25.duplicate(true)
	for place: Dictionary in parent.runtime_district.placements:
		var shapes:=source_polys(parent.district_assets[place.asset_id],place)
		if not String(place.get("replaces","")).is_empty():
			var at:=index_of(result,place.id)
			if not check(at>=0,"DG exact replacement id"): return []
			result[at].polygons.append_array(shapes)
		else:
			if not check(index_of(result,place.id)<0,"DG additions unique id"): return []
			result.append({"id":place.id,"foot":v(place.foot_px),"center":v(place.foot_px),"size":Vector2.ZERO,"polygons":shapes})
	return result
func derive_after(before: Array,author: Dictionary) -> Array:
	var result: Array=before.duplicate(true)
	for group: String in ["building_changes","wall_changes","native_prop_moves","district_moves"]:
		for change: Dictionary in author[group]:
			var at:=index_of(result,change.id)
			if not check(at>=0 and result[at].foot==v(change.old_foot_px),"Exact source old foot:"+change.id): return []
			var row: Dictionary=result[at];var delta:=v(change.foot_px)-v(change.old_foot_px)
			row.foot=v(change.foot_px);row.center=row.center+delta
			var moved: Array=[]
			for shape: PackedVector2Array in row.polygons:
				var next:=PackedVector2Array()
				for point: Vector2 in shape: next.append(point+delta)
				moved.append(next)
			row.polygons=moved
			if group=="wall_changes" or change.get("rebuild_source_plinths",false): row.polygons=source_polys(author.assets[change.asset_id],change)
	for place: Dictionary in author.new_components:
		if not check(index_of(result,place.id)<0,"NEW exact unique id"): return []
		result.append({"id":place.id,"foot":v(place.foot_px),"center":v(place.foot_px),"size":Vector2.ZERO,"polygons":source_polys(author.assets[place.asset_id],place)})
	return result
func bbox(shape: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in shape: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
func row_boxes(row: Dictionary) -> Array:
	var result: Array=[]
	for shape: PackedVector2Array in row.polygons:
		var box:=bbox(shape)
		result.append(Rect2i(floori(box.position.x)-1,floori(box.position.y)-1,ceili(box.end.x)-floori(box.position.x)+3,ceili(box.end.y)-floori(box.position.y)+3))
	if row["size"].x>0 and row["size"].y>0:
		var low: Vector2=row.center-row["size"]*.5;var high: Vector2=low+row["size"]
		result.append(Rect2i(floori(low.x)-1,floori(low.y)-1,ceili(high.x)-floori(low.x)+3,ceili(high.y)-floori(low.y)+3))
	return result
func derive_domains(before: Array,after: Array,model: Dictionary) -> Array:
	var raw: Array=[]
	for rows: Array in [before,after]:
		for id: String in model.changed_ids:
			var at:=index_of(rows,id)
			if not check(at>=0,"Domain changed id exists"): return []
			raw.append_array(row_boxes(rows[at]))
	for id: String in model.added_ids: raw.append_array(row_boxes(after[index_of(after,id)]))
	if not check(raw.size()==model.raw_half_open_domains.size(),"Every old/new polygon AND nonzero rectangle closure"): return []
	for i: int in range(raw.size()):
		var r: Rect2i=raw[i];var e: Array=model.raw_half_open_domains[i]
		if not check([r.position.x,r.position.y,r.end.x,r.end.y]==e,"Unmerged exact f32-domain:"+str(i)): return []
	var merged: Array=[]
	for r: Rect2i in raw:
		var current:=r.intersection(Rect2i(0,0,3072,2048));var again: bool=true
		while again:
			again=false
			for i: int in range(merged.size()):
				if current.intersects(merged[i],true): current=current.merge(merged[i]);merged.remove_at(i);again=true;break
		merged.append(current)
	if not check(merged.size()==model.merged_half_open_domains.size(),"Exact merged closure count"): return []
	for i: int in range(merged.size()):
		var r: Rect2i=merged[i];var e: Array=model.merged_half_open_domains[i]
		if not check([r.position.x,r.position.y,r.end.x,r.end.y]==e,"Exact merged closure:"+str(i)): return []
	return merged
func raster(rows: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows:
		for shape: PackedVector2Array in row.polygons: result.append({"shape":shape,"area":bbox(shape),"rect":false})
		if row["size"].x>0 and row["size"].y>0:
			var low: Vector2=row.center-row["size"]*.5
			result.append({"area":Rect2(low,row["size"]),"rect":true})
	return result
func local_raster(all_rows: Array,domain: Rect2i) -> Array:
	var result: Array=[]
	for row: Dictionary in all_rows:
		var box: Rect2=row.area
		if floori(box.position.x)<=domain.end.x-1 and ceili(box.end.x)>=domain.position.x and floori(box.position.y)<=domain.end.y-1 and ceili(box.end.y)>=domain.position.y: result.append(row)
	return result
func blocked(point: Vector2,rows: Array) -> bool:
	if point.x<24 or point.y<24 or point.x>=3048 or point.y>=2024: return true
	for row: Dictionary in rows:
		var box: Rect2=row.area
		if row.rect:
			if point.x>=ceili(box.position.x) and point.x<ceili(box.end.x) and point.y>=ceili(box.position.y) and point.y<ceili(box.end.y): return true
		elif point.x>=floori(box.position.x) and point.x<=ceili(box.end.x) and point.y>=floori(box.position.y) and point.y<=ceili(box.end.y) and Geometry2D.is_point_in_polygon(point,row.shape): return true
	return false
func image(path: String) -> Image:
	var result:=Image.load_from_file(path);images+=1
	if result==null or result.is_empty() or result.has_mipmaps(): return null
	if result.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return null
	if result.get_format()!=Image.FORMAT_RGBA8: result.convert(Image.FORMAT_RGBA8)
	return result
func pixel_prior(model: Dictionary,before: Array,after: Array,domains: Array) -> Dictionary:
	var parent:=image(cfg.parent_walk_path);var raw:=image(cfg.raw_walk_path)
	if not check(parent!=null and raw!=null and parent.get_size()==SIZE and raw.get_size()==SIZE,"Exactly two original-size masks/mip0"): return {}
	var original:=parent.get_data();var rawbytes:=raw.get_data();var child:=original.duplicate()
	if not check(sha(original)==cfg.parent_RGBA_sha256,"Fixed2042 whole parentRGBA"): return {}
	var old_raster:=raster(before);var new_raster:=raster(after)
	var changed:=PackedInt32Array();var visited: int=0;var old_diff: int=0;var first_diff: Array=[]
	for domain: Rect2i in domains:
		var local_old:=local_raster(old_raster,domain);var local_new:=local_raster(new_raster,domain)
		for y: int in range(domain.position.y,domain.end.y):
			if Time.get_ticks_msec()>=deadline: errors.append("FINITE_60S_LIMIT");return {}
			for x: int in range(domain.position.x,domain.end.x):
				visited+=1
				var offset: int=(y*3072+x)*4;var point:=Vector2(x,y)
				var old_black:=blocked(point,local_old);var new_black:=blocked(point,local_new);var matches: bool=true;var differs: bool=false
				for channel: int in range(4):
					var black: int=255 if channel==3 else 0
					var expected: int=black if old_black else int(rawbytes[offset+channel])
					var desired: int=black if new_black else int(rawbytes[offset+channel])
					matches=matches and expected==original[offset+channel];differs=differs or desired!=original[offset+channel];child[offset+channel]=desired
				if not matches:
					old_diff+=1
					if first_diff.size()<12: first_diff.append({"xy":[x,y],"old_blocked":old_black,"actual":Array(original.slice(offset,offset+4)),"raw":Array(rawbytes.slice(offset,offset+4))})
				if differs: changed.append(y*3072+x)
	diagnostics.append({"old_local_diff":old_diff,"old_first12_diff":first_diff,"visited":visited,"changed":changed.size()})
	if not check(old_diff==0 and visited==int(model.union_visited_pixels),"Every bounded parent pixel matches raw + fixed native25, exact union"): return {}
	var inverse:=child.duplicate()
	for index: int in changed:
		for channel: int in range(4): inverse[index*4+channel]=original[index*4+channel]
	if not check(inverse==original,"CompleteRGBA exact inverse/outside local domains untouched"): return {}
	return {"ready":true,"status":"INDEPENDENT24E_NATIVE_LOCAL_PIXEL_PRIOR_NOT_RUNTIME_OR_ART","parent_RGBA_sha256":sha(original),"expected_child_RGBA_sha256":sha(child),"changed_pixels":changed.size(),"union_visited_pixels":visited,"merged_domain_count":domains.size(),"full_RGBA_inverse":true,"local_parent_differences":0,"native_before":25,"combined_after":43,"Field_Physics_ART_pass":false}
func run() -> void:
	if not check(READY and FileAccess.get_sha256(FIXTURE)==FIXTURE_SHA,"Root frozen single CPU oracle only"): quit(2);return
	cfg=read_json(FIXTURE)
	if not check(cfg.get("ready")==true and int(cfg.whole_ms)==60000 and root.get_children().is_empty(),"No-autoload hardfalse fixture/60s"): quit(2);return
	var first: Dictionary={};var saved_first:=facts(cfg.save_paths)
	for path: String in cfg.source_sha256:
		first[path]=fact(path)
		if not check(first[path].get("sha256")==cfg.source_sha256[path],"Fixed source first:"+path): finish({},first,saved_first);return
	var model:=read_json(cfg.model_path);var author:=read_json(cfg.author_path);var parent_author:=read_json(cfg.parent_author_path)
	var native:=decode_rows(model.native25)
	if not exact_model(native,model.native25,"InheritedF484_native25"): finish({},first,saved_first);return
	var before:=derive_before(native,parent_author);var after:=derive_after(before,author)
	if not exact_model(before,model.before37,"Independent37") or not exact_model(after,model.after43,"Independent43"): finish({},first,saved_first);return
	var domains:=derive_domains(before,after,model)
	if domains.is_empty() or not errors.is_empty(): finish({},first,saved_first);return
	# Parent raster is native25 ONLY. DG contributes to the new effective mask;
	# old native4 remains immutable and DG physical guard was formerly separate.
	var prior:=pixel_prior(model,native,after,domains)
	finish(prior,first,saved_first)
func finish(prior: Dictionary,first: Dictionary,saved_first: Dictionary) -> void:
	var final:=facts(first.keys());var saved_final:=facts(cfg.save_paths)
	check(first==final,"Exact fixed sources first/final unchanged")
	check(saved_first==saved_final,"Current fifteen saves first/final unchanged")
	var passed: bool=not prior.is_empty() and errors.is_empty() and Time.get_ticks_msec()<deadline
	var output: String=cfg.output_path
	if FileAccess.file_exists(output): printerr("RESULT_ALREADY_EXISTS");quit(2);return
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null: quit(2);return
	file.store_string(JSON.stringify({"passed":passed,"complete":passed,"checks":checks,"failures":errors.size(),"errors":errors,"prior":prior,"diagnostics":diagnostics,"elapsed_ms":Time.get_ticks_msec()-began,"source_first":first,"source_final":final,"save_first":saved_first,"save_final":saved_final,"PNG_decodes":images,"packet_decodes":0,"PNG_outputs":0,"Scene_Resource_Field_Physics_collector_publisher_calls":0},"\t",true,true));file.close()
	print("INDEPENDENT24E_PRIOR_RESULT ",output);quit(0 if passed else 1)
