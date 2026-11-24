extends SceneTree
## Root-only finite Market content publication. No Scene/Field/Router or old geometry rebuild.
const READY: bool=false
const INPUT: String="res://build/luoyang_market_workcourts_20261026b_system01/input_NOTREADY.json"
const INPUT_SHA: String="881dd25c4af04d8d889f4fcd9eb390de2d7a00e301a2f0e94b675c67687028ab"
const PREFIX: String="res://build/luoyang_market_workcourts_20261026b_system01/"
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
const SIZE: Vector2=Vector2(3072,2048)
var errors: Array[String]=[]
var checks: int=0
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("MARKET_LAYOUT ",label)
	return ok
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func vec(a: Array) -> Vector2: return Vector2(float(a[0]),float(a[1]))
func sha(a: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(a);return h.finish().hex_encode()
func read_json(path: String) -> Dictionary:
	var a: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)));return a if a is Dictionary else {}
func write_new(path: String,bytes: PackedByteArray) -> Dictionary:
	if not check(path.begins_with(PREFIX) and not FileAccess.file_exists(physical(path)),"NEW_BUILD_OUTPUT:"+path): return {}
	var f:=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(f!=null,"OUTPUT_OPEN"): return {}
	f.store_buffer(bytes);f.close();return {"path":path,"sha256":sha(bytes),"bytes":bytes.size()}
func body(foot: Vector2,half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot-half,foot+Vector2(half.x,-half.y),foot+half,foot+Vector2(-half.x,half.y)])
func clear(foot: Vector2,half: Vector2,mask: Image,solids: Array) -> bool:
	if foot.x<half.x or foot.y<half.y or foot.x+half.x>=SIZE.x or foot.y+half.y>=SIZE.y: return false
	for poly: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(body(foot,half),poly).is_empty(): return false
	for y: int in range(floori(foot.y-half.y),ceili(foot.y+half.y)+1):
		for x: int in range(floori(foot.x-half.x),ceili(foot.x+half.x)+1):
			if mask.get_pixel(x,y).r<0.5: return false
	return true
func run() -> void:
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_INPUT"): quit(2);return
	var spec: Dictionary=read_json(INPUT)
	if not check(spec.get("ready")==true and spec.get("scene_id")=="ch4_s3_luoyang_market","EXACT_MARKET_ONLY"): quit(2);return
	for path: String in spec.sources:
		if not check(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE:"+path): quit(2);return
	var author: Dictionary=read_json(spec.author.path)
	var parent_bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(spec.parent_payload.path))
	var value: Variant=bytes_to_var(parent_bytes)
	if not check(value is Dictionary and var_to_bytes(value)==parent_bytes and value.scene_id==spec.scene_id,"EXACT_TYPED_PARENT"): quit(2);return
	var parent: Dictionary=value;var child: Dictionary=parent.duplicate(true)
	var old_mask:=Image.load_from_file(physical(spec.mask.path))
	if not check(old_mask!=null and old_mask.get_size()==Vector2i(3072,2048) and not old_mask.has_mipmaps(),"OLD_MASK"): quit(2);return
	old_mask.convert(Image.FORMAT_RGBA8)
	if not check(sha(old_mask.get_data())==spec.mask.RGBA_sha256,"FIXED_MASK_RGBA"): quit(2);return
	var mask: Image=old_mask.duplicate()
	var appended: Array=[];var new_solids: Array=[];var changed: Dictionary={}
	for placement: Dictionary in author.placements:
		var asset: Dictionary=author.assets[placement.asset_id]
		var foot: Vector2=vec(placement.foot);var anchor: Vector2=vec(asset.source_anchor)
		var size: Vector2=vec(asset.source_size);var ratio: float=float(placement.uniform_scale)
		for old: Dictionary in child.effective_navigation:
			if not check(old.id!=placement.id,"UNIQUE_NEW_ID:"+String(placement.id)): quit(2);return
		var polys: Array=[]
		for raw: Array in asset.true_ground_polygons:
			var poly:=PackedVector2Array()
			for point: Array in raw: poly.append(foot+(vec(point)-anchor)*ratio)
			for old: PackedVector2Array in child.effective_solids:
				if not check(Geometry2D.intersect_polygons(poly,old).is_empty(),"TRUE_BASE_SEPARATE:"+String(placement.id)): quit(2);return
			polys.append(poly);new_solids.append(poly)
			var bounds:=Rect2(poly[0],Vector2.ZERO)
			for point: Vector2 in poly: bounds=bounds.expand(point)
			for y: int in range(floori(bounds.position.y),ceili(bounds.end.y)+1):
				for x: int in range(floori(bounds.position.x),ceili(bounds.end.x)+1):
					if not Geometry2D.is_point_in_polygon(Vector2(x,y),poly): continue
					var index: int=y*3072+x
					if not changed.has(index): changed[index]=old_mask.get_pixel(x,y)
					mask.set_pixel(x,y,Color(0,0,0,1))
		var row: Dictionary={"id":String(placement.id),"texture":String(asset.texture),"pos":(foot+(size*0.5-anchor)*ratio)/SIZE,"render_size_px":size*ratio,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":polys,"blocking":true,"district_life_fade":false}
		child.effective_navigation.append(row);child.visual_additions.append(row);child.effective_solids.append_array(polys);appended.append(row)
	# Only the declared new content suffix is reversible. All old bodies/tasks/portals remain exact.
	var inverse: Dictionary=child.duplicate(true)
	inverse.effective_navigation.resize(parent.effective_navigation.size());inverse.visual_additions.resize(parent.visual_additions.size());inverse.effective_solids.resize(parent.effective_solids.size())
	if not check(var_to_bytes(inverse)==parent_bytes,"WHOLE_PAYLOAD_INVERSE"): quit(2);return
	var restored: Image=mask.duplicate()
	for index: int in changed: restored.set_pixel(index%3072,floori(float(index)/3072.0),changed[index])
	if not check(sha(restored.get_data())==spec.mask.RGBA_sha256,"WHOLE_RGBA_INVERSE_ONLY_NEW_BASES"): quit(2);return
	# Four named old approaches only, no city/room/World regression replay.
	for route: Dictionary in author.routes:
		var ok: bool=true
		for i: int in range(1,route.points.size()):
			var a: Vector2=vec(route.points[i-1]);var b: Vector2=vec(route.points[i])
			var steps: int=maxi(1,ceili(a.distance_to(b)/8.0))
			for j: int in range(steps+1):
				if not clear(a.lerp(b,float(j)/steps),Vector2(17,12),mask,child.effective_solids): ok=false;break
			if not ok: break
		if not check(ok,"LOCAL34x24_APPROACH:"+String(route.id)): quit(2);return
	for path: String in spec.sources:
		if not check(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE_FINAL:"+path): quit(2);return
	var root: String=spec.output_root+str(OS.get_process_id())+"/"
	if not check(root.begins_with(PREFIX),"OUTPUT_SCOPE"): quit(2);return
	DirAccess.make_dir_recursive_absolute(physical(root))
	var payload: Dictionary=write_new(root+"payload.bin",var_to_bytes(child))
	var mask_path: String=root+"walk_overlay.png"
	if not check(not FileAccess.file_exists(physical(mask_path)) and mask.save_png(physical(mask_path))==OK,"NEW_MASK_PNG"): quit(2);return
	var fingerprints: Dictionary={}
	for key: String in child:
		if child[key] is Array or key=="parent_blockers_ref": fingerprints[key]=sha(var_to_bytes(child[key]))
	var report: Dictionary={"passed":errors.is_empty(),"checks":checks,"errors":errors,"status":"FINITE_MARKET_CONTENT_PUBLICATION_NOT_FIELD_OR_ART_PASS","parent_payload":spec.parent_payload,"payload":payload,"mask":{"path":mask_path,"sha256":FileAccess.get_sha256(physical(mask_path)),"RGBA_sha256":sha(mask.get_data()),"size":[3072,2048]},"fingerprints":fingerprints,"added_ids":appended.map(func(row: Dictionary) -> String: return row.id),"effective_navigation_count":child.effective_navigation.size(),"effective_solids_count":child.effective_solids.size(),"changed_domain_pixels":changed.size(),"whole_payload_inverse":true,"whole_RGBA_inverse":true,"old_city_routes_replayed":0,"Scene_Field_Router_calls":0,"actual_Field_pass":false}
	write_new(root+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("MARKET_LAYOUT_RESULT ",root+"result.json");quit(0 if errors.is_empty() else 1)
