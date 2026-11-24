extends RefCounted
## NEW, build-only geometry transform. No SceneTree, Physics, publication, save,
## current collector, canonical write, source-approval mutation or image export.
## Parent native data must be supplied from the exact frozen17536 artifacts.
const ID="v13_market_west_plot_wall"
const SOLID_ID="v13_market_west_plot_wall_poly_0"
const SIZE=Vector2i(3072,2048)
const DOMAIN=Rect2i(35,1408,111,13) # Original inclusive polygon raster envelope.
const WALL_TEXTURE="res://build/luoyang_city_full_rollout_20261022ap_system01/market_layout_successor2/west_wall_retained_panel.tres"
const NEW_WALK="res://build/luoyang_city_full_rollout_20261022ap_system01/market_wall_retirement_epoch01/future_publication/walk.png"
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const PARENT_RGBA_SHA="d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e"
static func b() -> Variant: return load(B_PATH)
static func fail(error: String,detail: Variant=null) -> Dictionary: return {"ok":false,"error":error,"detail":detail}
static func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if not raw is Array or raw.size()!=2: return Vector2(INF,INF)
	for scalar: Variant in raw:
		if typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)): return Vector2(INF,INF)
	return Vector2(raw[0],raw[1])
static func expected_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(35,1408),Vector2(145,1408),Vector2(145,1420),Vector2(35,1420)])
static func poly(raw: Variant) -> PackedVector2Array:
	if raw is PackedVector2Array: return raw.duplicate()
	var result:=PackedVector2Array()
	if not raw is Array: return result
	for point: Variant in raw:
		var value: Vector2=v(point)
		if not value.is_finite(): return PackedVector2Array()
		result.append(value)
	return result
static func wall_record_matches(row: Dictionary) -> bool:
	if row.get("id")!=ID or row.get("texture")!=WALL_TEXTURE or row.get("source")!=WALL_TEXTURE: return false
	if v(row.get("source_size_px",[]))!=Vector2(110,123) or v(row.get("render_size_px",[]))!=Vector2(110,123) or v(row.get("world_foot_px",[]))!=Vector2(90,1420) or v(row.get("physical_center_px",[]))!=Vector2(90,1414): return false
	if v(row.get("collision_size_px",[]))!=Vector2.ZERO or row.get("blocking")!=true or row.get("ghost_occlusion")!=true or row.get("sort_by_feet")!=true or row.get("walk_support")!=false: return false
	var polys: Variant=row.get("solid_polygons_px")
	if not polys is Array or polys.size()!=1: return false
	return b().equal(poly(polys[0]),expected_polygon())

static func remove_record(parent: Dictionary) -> Dictionary:
	if parent.get("canonical_scene_id")!="ch4_s3_luoyang_market" or not parent.get("objects") is Array or parent.objects.size()!=24: return fail("EXACT_PARENT_MARKET_24_NATIVE")
	var child: Dictionary=parent.duplicate(true)
	var index: int=-1
	for i: int in child.objects.size():
		var row: Dictionary=child.objects[i]
		if row.get("id")!=ID: continue
		if index>=0 or not wall_record_matches(row): return fail("EXACT_ONE_FROZEN_WALL_RECORD")
		index=i
	if index<0: return fail("WALL_RECORD_ABSENT")
	var removed: Dictionary=child.objects[index].duplicate(true)
	child.objects.remove_at(index)
	var original_walk: Variant=child.get("walk_path")
	child.walk_path=NEW_WALK
	var inverse: Dictionary=child.duplicate(true)
	inverse.objects.insert(index,removed.duplicate(true));inverse.walk_path=original_walk
	if child.objects.size()!=23 or not b().equal(inverse,parent): return fail("WHOLE_RECORD_INVERSE")
	return {"ok":true,"record":child,"removed":removed,"ordinal":index,"parent_native_count":24,"child_native_count":23,"all_other_record_fields_unchanged":true,"whole_inverse":true}

static func remove_visuals(parent: Array) -> Dictionary:
	if parent.size()!=24: return fail("EXACT_PARENT_24_NATIVE_VISUALS")
	var child: Array=parent.duplicate(true);var index: int=-1
	for i: int in child.size():
		var row: Dictionary=child[i]
		if row.get("id")!=ID: continue
		if index>=0 or row.get("texture")!=WALL_TEXTURE or v(row.get("render_size_px",[]))!=Vector2(110,123) or v(row.get("pos",[]))!=Vector2(90,1361.5)/Vector2(SIZE) or row.get("centered")!=true or row.get("sort_by_feet")!=true: return fail("EXACT_FROZEN_WALL_VISUAL")
		index=i
	if index<0: return fail("WALL_VISUAL_ABSENT")
	var removed: Dictionary=child[index].duplicate(true);child.remove_at(index)
	var inverse: Array=child.duplicate(true);inverse.insert(index,removed.duplicate(true))
	if child.size()!=23 or not b().equal(inverse,parent): return fail("WHOLE_VISUAL_ARRAY_INVERSE")
	return {"ok":true,"visuals":child,"removed":removed,"ordinal":index,"whole_inverse":true,"district_additions_not_touched":true}

static func native_solids(objects: Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for object: Dictionary in objects:
		for polygon: Variant in object.get("solid_polygons_px",[]): result.append(poly(polygon))
		var size: Vector2=v(object.get("collision_size_px",Vector2.ZERO))
		if size.x>0:
			var rect:=Rect2(v(object.physical_center_px)-size*.5,size)
			result.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	return result

static func native_raster_blocked(point: Vector2,objects: Array) -> bool:
	# Exact original C._raster_walk_cpu rules: integer-point polygons include
	# their Geometry2D boundary convention; rectangle pixels are ceil-half-open.
	if point.x<24 or point.y<24 or point.x>=SIZE.x-24 or point.y>=SIZE.y-24: return true
	for object: Dictionary in objects:
		for raw: Variant in object.get("solid_polygons_px",[]):
			if Geometry2D.is_point_in_polygon(point,poly(raw)): return true
		var size: Vector2=v(object.get("collision_size_px",Vector2.ZERO))
		if size.x>0:
			var area:=Rect2(v(object.physical_center_px)-size*.5,size)
			if point.x>=ceili(area.position.x) and point.x<ceili(area.end.x) and point.y>=ceili(area.position.y) and point.y<ceili(area.end.y): return true
	return false

static func local_mask_delta(parent: Image,raw_ground: Image,parent_objects: Array,child_objects: Array) -> Dictionary:
	if parent==null or raw_ground==null or parent.get_size()!=SIZE or raw_ground.get_size()!=SIZE or parent_objects.size()!=24 or child_objects.size()!=23: return fail("FROZEN_NATIVE_MASK_INPUTS")
	var parent_bytes: PackedByteArray=parent.get_data()
	if parent.get_format()!=Image.FORMAT_RGBA8 or raw_ground.get_format()!=Image.FORMAT_RGBA8 or parent_bytes.size()!=SIZE.x*SIZE.y*4: return fail("EXACT_RGBA8_NO_CONVERSION")
	if b().bytes_sha(parent_bytes)!=PARENT_RGBA_SHA: return fail("FROZEN_17536_PARENT_RGBA_SHA")
	var expected_child: Array=parent_objects.duplicate(true);var removed_count: int=0
	for index: int in range(expected_child.size()-1,-1,-1):
		if expected_child[index].get("id")==ID:
			if not wall_record_matches(expected_child[index]): return fail("EXACT_MASK_PARENT_WALL")
			expected_child.remove_at(index);removed_count+=1
	if removed_count!=1 or not b().equal(expected_child,child_objects): return fail("MASK_CHILD_REMOVES_ONLY_EXACT_WALL")
	var parent_solids: Array[PackedVector2Array]=native_solids(parent_objects)
	var child_solids: Array[PackedVector2Array]=native_solids(child_objects)
	if parent_solids.size()!=child_solids.size()+1: return fail("EXACT_ONE_NATIVE_SOLID_REMOVED")
	var changed: Array[Dictionary]=[];var output: Image=parent.duplicate() as Image
	var visited: int=0
	for y: int in range(DOMAIN.position.y,DOMAIN.end.y):
		for x: int in range(DOMAIN.position.x,DOMAIN.end.x):
			var point:=Vector2(x,y);visited+=1
			var raw: Color=raw_ground.get_pixel(x,y)
			var expected_parent: Color=Color.BLACK if native_raster_blocked(point,parent_objects) else raw
			if parent.get_pixel(x,y)!=expected_parent: return fail("LOCAL_PARENT_NOT_ORIGINAL_RAW_PLUS_NATIVE",point)
			var desired: Color=Color.BLACK if native_raster_blocked(point,child_objects) else raw
			if desired==parent.get_pixel(x,y): continue
			# Never blind-white: original ground may be blocked, nonwhite, or
			# retained by another exact native solid. All four channels restored.
			changed.append({"x":x,"y":y,"old":parent.get_pixel(x,y),"new":desired})
			output.set_pixel(x,y,desired)
	if visited!=1443 or changed.is_empty(): return fail("EXACT_111_BY_13_NONEMPTY_LOCAL_DELTA")
	var inverse: PackedByteArray=output.get_data().duplicate()
	for row: Dictionary in changed:
		var offset: int=(int(row.y)*SIZE.x+int(row.x))*4
		for channel: int in 4: inverse[offset+channel]=parent_bytes[offset+channel]
	if inverse!=parent_bytes: return fail("FULL_RGBA_BYTES_OUTSIDE_DELTA_CHANGED")
	return {"ok":true,"mask":output,"changed":changed,"visited_pixels":visited,"domain":DOMAIN,"blind_white":false,"full_RGBA_inverse":true,"outside_domain_byte_identical":true,"native_only_mask_semantics":true,"district_prefix_and_solids_unchanged":true}

static func affected_path_segments(record: Dictionary,district_paths: Array) -> Dictionary:
	var paths: Array=record.get("routes",[]).duplicate(true)
	for kind: String in ["npcs","interactions","portals"]:
		for slot: Dictionary in record.get("gameplay_slots",{}).get(kind,[]):
			var point: Variant=slot.get("stand_px",slot.get("foot_px"))
			if point!=null: paths.append({"id":kind+":"+String(slot.get("source_id","")),"points_px":[point,point]})
			if slot.has("passage_path_px"): paths.append({"id":"passage:"+String(slot.get("source_id","")),"points_px":slot.passage_path_px})
	paths.append_array(district_paths.duplicate(true))
	var affected: Array[Dictionary]=[];var inherited: Array[String]=[]
	# Only sample selection, not a new navigation acceptance or full route run.
	var body_domain:=Rect2(Vector2(DOMAIN.position)-Vector2(17,15),Vector2(DOMAIN.size)+Vector2(34,30))
	for path: Dictionary in paths:
		var local: Array[int]=[]
		for i: int in range(path.points_px.size()-1):
			var a: Vector2=v(path.points_px[i]);var z: Vector2=v(path.points_px[i+1])
			var low: Vector2=a.min(z);var high: Vector2=a.max(z)
			if low.x<=body_domain.end.x and high.x>=body_domain.position.x and low.y<=body_domain.end.y and high.y>=body_domain.position.y: local.append(i)
		if local.is_empty(): inherited.append(String(path.id))
		else: affected.append({"id":path.id,"segments":local})
	return {"ok":true,"affected":affected,"unchanged_paths_to_inherit":inherited,"selection_only_not_safe_body_proof":true}
