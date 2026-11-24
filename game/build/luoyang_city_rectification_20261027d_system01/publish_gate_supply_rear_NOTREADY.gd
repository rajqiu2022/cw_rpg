extends SceneTree
## One Gate owner row gains one real rear slab; all other payload bytes retained.
const READY: bool=false
const INPUT="res://build/luoyang_city_rectification_20261027d_system01/gate_rear_input_NOTREADY.json"
const INPUT_SHA="PENDING_ROOT_REVIEWED_INPUT"
const PREFIX="res://build/luoyang_city_rectification_20261027d_system01/"
const GAME="F:/Code/RPG_GAME/game/"
const OWNER="finish_i_gate_east_supply"
var checks: int=0
var errors: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME+path.trim_prefix("res://") if path.begins_with("res://") else path
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("GATE_REAR ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes);return context.finish().hex_encode()
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func v(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(float(value[0]),float(value[1])) if value is Array and value.size()==2 else Vector2(INF,INF)
func poly(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array: return value.duplicate()
	var out:=PackedVector2Array()
	if value is Array:
		for point: Variant in value: out.append(v(point))
	return out
func write_new(path: String,data: PackedByteArray) -> Dictionary:
	if not need(path.begins_with(PREFIX) and not FileAccess.file_exists(physical(path)),"EXCLUSIVE_NEW_BUILD_OUTPUT"): return {}
	var file:=FileAccess.open(physical(path),FileAccess.WRITE)
	if not need(file!=null,"NEW_OUTPUT_OPEN"): return {}
	file.store_buffer(data);file.close();return {"path":path,"sha256":sha(data),"bytes":data.size()}
func primitives(rows: Array) -> Array:
	var out: Array=[]
	for row: Dictionary in rows:
		for points: Variant in row.get("city_v3_solid_polygons_px",[]): out.append(poly(points))
		var size: Vector2=v(row.get("collision_size_px",Vector2.ZERO))
		if size.x>0 and size.y>0:
			var center: Vector2=v(row.get("physical_center_px"));var low: Vector2=center-size*.5;var high: Vector2=low+size
			out.append(PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]))
	return out
func clear(foot: Vector2,half: Vector2,mask: Image,solids: Array) -> bool:
	if not Rect2(Vector2.ZERO,Vector2(mask.get_size())).encloses(Rect2(foot-half,half*2)): return false
	var box:=PackedVector2Array([foot-half,foot+Vector2(half.x,-half.y),foot+half,foot+Vector2(-half.x,half.y)])
	for polygon: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(box,polygon).is_empty(): return false
	for y: int in range(floori(foot.y-half.y),ceili(foot.y+half.y)+1):
		for x: int in range(floori(foot.x-half.x),ceili(foot.x+half.x)+1):
			if mask.get_pixel(x,y).r<.5: return false
	return true
func run() -> void:
	if not need(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_INPUT_PIN"): quit(2);return
	var input: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(INPUT)))
	if not need(input is Dictionary and input.get("ready")==true,"ROOT_REVIEWED_EXACT_GATE_OWNER"): quit(2);return
	for path: String in input.sources:
		if not need(FileAccess.get_sha256(physical(path))==input.sources[path],"SOURCE:"+path): quit(2);return
	var design: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(physical(input.spec.path)))
	var author: Dictionary=design.proposals[0]
	if not need(author.logical_id=="ch4_s0_luoyang_gate" and author.object_id==OWNER and author.foot==[2380.0,1300.0] and author.uniform_scale==.41,"ROOT_DESIGN_EXACT_GATE_ONLY"): quit(1);return
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(input.payload.path))
	var parent: Variant=bytes_to_var(bytes)
	if not need(parent is Dictionary and var_to_bytes(parent)==bytes and parent.scene_id=="ch4_s0_luoyang_gate" and parent.world_size_px==Vector2(3072,2048),"WHOLE_TYPED_GATE_PARENT"): quit(1);return
	var child: Dictionary=parent.duplicate(true);var owner_index: int=-1
	for i: int in parent.effective_navigation.size():
		if parent.effective_navigation[i].get("id")!=OWNER: continue
		if not need(owner_index==-1,"UNIQUE_TARGET_NAV_OWNER"): quit(1);return
		owner_index=i
	if not need(owner_index>=0,"TARGET_OWNER_EXISTS"): quit(1);return
	var before: Dictionary=parent.effective_navigation[owner_index];var front: Array=before.get("city_v3_solid_polygons_px",[])
	var old_polys: Array=[]
	for points: Variant in author.existing_front_ground_world: old_polys.append(poly(points))
	var front_points: Array=[]
	for points: Variant in front: front_points.append(poly(points))
	if not need(front.size()==2 and same(front_points,old_polys),"ORIGINAL_TWO_FRONT_PLINTHS_EXACT"): quit(1);return
	if not need(before.get("texture")=="res://art/modules/luoyang_estate_components_20261021am/wing.png" and before.get("world_foot_px")==[2380.0,1300.0] and before.get("render_size_px")==Vector2(2202,1289)*.41 and before.get("centered")==true and before.get("blocking")==true,"ORIGINAL_FACADE_TRANSFORM"): quit(1);return
	var added:=PackedVector2Array()
	for point: Variant in author.append_source_ground_polygon: added.append(v(author.foot)+(v(point)-v(author.source_anchor))*float(author.uniform_scale))
	if not need(added.size()==4 and not Geometry2D.triangulate_polygon(added).is_empty(),"NEW_REAR_GROUND_POLYGON"): quit(1);return
	for old: PackedVector2Array in parent.effective_solids:
		if not need(Geometry2D.intersect_polygons(added,old).is_empty(),"REAR_NO_POSITIVE_OLD_GROUND_OVERLAP"): quit(1);return
	var parent_solids: Array=primitives(parent.effective_navigation)
	if not need(same(parent_solids,parent.effective_solids),"PARENT_COMPLETE_NAVIGATION_SOLID_SEQUENCE"): quit(1);return
	var after: Dictionary=before.duplicate(true);after.city_v3_solid_polygons_px.append(added)
	child.effective_navigation[owner_index]=after
	var addition_index: int=-1
	for i: int in child.visual_additions.size():
		if child.visual_additions[i].get("id")!=OWNER: continue
		if not need(addition_index==-1 and same(child.visual_additions[i],before),"EXACT_ONE_VISUAL_ADDITION_PARENT"): quit(1);return
		addition_index=i;child.visual_additions[i]=after.duplicate(true)
	if not need(addition_index>=0,"SUPPLY_IS_EXISTING_ADDITION"): quit(1);return
	child.effective_solids=primitives(child.effective_navigation)
	var insert_index: int=0
	for i: int in owner_index+1: insert_index+=primitives([parent.effective_navigation[i]]).size()
	var expected_solids: Array=parent.effective_solids.duplicate(true);expected_solids.insert(insert_index,added)
	if not need(same(child.effective_solids,expected_solids),"ONE_INSERT_NO_OTHER_SOLID_CHANGE"): quit(1);return
	var inverse: Dictionary=child.duplicate(true);inverse.effective_navigation[owner_index]=before.duplicate(true);inverse.visual_additions[addition_index]=before.duplicate(true);inverse.effective_solids.remove_at(insert_index)
	if not need(var_to_bytes(inverse)==bytes,"WHOLE_PAYLOAD_INVERSE_ONLY_ONE_REAR_BASE"): quit(1);return
	var old_mask:=Image.load_from_file(physical(input.mask.path))
	if not need(old_mask!=null and old_mask.get_size()==Vector2i(3072,2048) and not old_mask.has_mipmaps(),"ORIGINAL_MASK_SIZE"): quit(1);return
	old_mask.convert(Image.FORMAT_RGBA8)
	if not need(sha(old_mask.get_data())==input.mask.RGBA_sha256,"ORIGINAL_FULL_RGBA"): quit(1);return
	var mask: Image=old_mask.duplicate();var changed: Dictionary={};var owned: int=0
	var bounds:=Rect2(added[0],Vector2.ZERO)
	for point: Vector2 in added: bounds=bounds.expand(point)
	for y: int in range(floori(bounds.position.y),ceili(bounds.end.y)+1):
		for x: int in range(floori(bounds.position.x),ceili(bounds.end.x)+1):
			if not Geometry2D.is_point_in_polygon(Vector2(x,y),added): continue
			owned+=1
			if mask.get_pixel(x,y)!=Color.BLACK: changed[y*3072+x]=mask.get_pixel(x,y);mask.set_pixel(x,y,Color.BLACK)
	var restored: Image=mask.duplicate()
	for index: int in changed: restored.set_pixel(index%3072,floori(float(index)/3072.0),changed[index])
	if not need(same(restored.get_data(),old_mask.get_data()),"WHOLE_RGBA_INVERSE_NEW_REAR_DOMAIN_ONLY"): quit(1);return
	for probe: Dictionary in input.preserved_clearance:
		if not need(clear(v(probe.foot),v(probe.half),mask,child.effective_solids),"PRESERVED_LOCAL_BODY:"+String(probe.id)): quit(1);return
	if not need(not clear(bounds.get_center(),Vector2(17,12),mask,child.effective_solids),"NEW_REAR_BODY_NEGATIVE"): quit(1);return
	for path: String in input.sources:
		if not need(FileAccess.get_sha256(physical(path))==input.sources[path],"SOURCE_FINAL:"+path): quit(1);return
	var folder: String=input.output_root+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(physical(folder))
	var payload: Dictionary=write_new(folder+"payload.bin",var_to_bytes(child));var mask_path: String=folder+"walk_overlay.png"
	if not need(not FileAccess.file_exists(physical(mask_path)) and mask.save_png(physical(mask_path))==OK,"EXCLUSIVE_NEW_GATE_MASK"): quit(1);return
	var fingerprints: Dictionary={}
	for key: String in child:
		if child[key] is Array or key=="parent_blockers_ref": fingerprints[key]=sha(var_to_bytes(child[key]))
	var report: Dictionary={"passed":errors.is_empty(),"checks":checks,"errors":errors,"status":"ONE_GATE_SUPPLY_REAR_GROUND_BUILD_NOT_FIELD_ACCEPTANCE","payload":payload,"mask":{"path":mask_path,"sha256":FileAccess.get_sha256(physical(mask_path)),"RGBA_sha256":sha(mask.get_data()),"size":[3072,2048]},"fingerprints":fingerprints,"owner_id":OWNER,"new_rear_polygon":added,"original_front_bases_retained":true,"owner_navigation_index":owner_index,"owner_visual_addition_index":addition_index,"new_solid_index":insert_index,"owned_pixels":owned,"changed_pixels":changed.size(),"navigation_count":child.effective_navigation.size(),"solid_count":child.effective_solids.size(),"whole_payload_inverse":true,"whole_RGBA_inverse":true,"NPC_portal_interaction_fields_unchanged":true,"source_first":input.sources,"source_final":input.sources,"Field_instances":0,"legacy_owner_prepare_calls":0,"old_geometry_reraster":false}
	write_new(folder+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("GATE_REAR_RESULT ",folder+"result.json");quit(0 if errors.is_empty() else 1)
