extends SceneTree
## Root-only exact deletion of one NEW gallery/four posts, not city re-publication.
const READY: bool=true
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/isolated_ROOT_READY02/input_ROOT_READY.json"
const INPUT_SHA: String="2c3162e10d18ab002bf5b26d61a0e6bbd0735c487d661b507c298d572b77f126"
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/isolated_ROOT_READY02/publish_delta_ROOT_READY.gd"
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
func physical(path: String) -> String:
	return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
const ID: String="finish_i_docks_weighing_gallery"
const SCENE: String="ch4_s2_canal_docks"
const SIZE: Vector2=Vector2(3072,2048)
var checks: int=0
var errors: Array[String]=[]
var began: int=0
var spec: Dictionary={}
var first: Dictionary={}
var saves: Dictionary={}
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("DOCKS_RETIRE_FAIL ",label)
	return ok
func hash_bytes(raw: PackedByteArray) -> String:
	var h: HashingContext=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(raw);return h.finish().hex_encode()
func same(a: Variant,b: Variant) -> bool:
	return var_to_bytes(a)==var_to_bytes(b)
func vec(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
func points(raw: Variant) -> PackedVector2Array:
	var out: PackedVector2Array=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return out
	for item: Variant in raw: out.append(vec(item))
	return out
func facts(paths: Array) -> Dictionary:
	var out: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(physical(path)): out[path]={"exists":false};continue
		var file: FileAccess=FileAccess.open(physical(path),FileAccess.READ)
		out[path]={"exists":true,"sha256":FileAccess.get_sha256(physical(path)),"bytes":file.get_length(),"mtime_seconds":FileAccess.get_modified_time(physical(path))};file.close()
	return out
func json_pin(pin: Dictionary) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(pin.path)))
	return value if value is Dictionary else {}
func image_pin(pin: Dictionary) -> Image:
	var image: Image=Image.load_from_file(physical(pin.path))
	if image==null or image.get_size()!=Vector2i(3072,2048) or image.has_mipmaps(): return null
	if image.get_format()==Image.FORMAT_RGB8: image.convert(Image.FORMAT_RGBA8)
	return image if image.get_format()==Image.FORMAT_RGBA8 and hash_bytes(image.get_data())==pin.RGBA_sha256 else null
func unique_index(rows: Array,id: String) -> int:
	var result: int=-1
	for index: int in range(rows.size()):
		if String(rows[index].get("id",""))!=id: continue
		if result!=-1: return -2
		result=index
	return result
func domain_bytes(raw: PackedByteArray,box: Array) -> PackedByteArray:
	var out: PackedByteArray=PackedByteArray()
	for y: int in range(int(box[1]),int(box[3])+1): out.append_array(raw.slice((y*3072+int(box[0]))*4,(y*3072+int(box[2])+1)*4))
	return out
func save_bytes(path: String,raw: PackedByteArray) -> Dictionary:
	if not check(not FileAccess.file_exists(physical(path)),"NEW_COMPONENT_ONLY:"+path): return {}
	var file: FileAccess=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(file!=null,"CREATE_COMPONENT:"+path): return {}
	file.store_buffer(raw);file.close()
	return {"path":path,"sha256":hash_bytes(raw),"bytes":raw.size()}
func fail() -> void:
	finish({})
func finish(components: Dictionary) -> void:
	var paths: Array=first.keys();var last: Dictionary=facts(paths);var save_last: Dictionary=facts(spec.get("save_absolute_paths",[]))
	check(first==last,"ALL_FIXED_SOURCES_FIRST_FINAL_SAME");check(saves==save_last,"FIFTEEN_SAVES_UNCHANGED");check(Time.get_ticks_msec()-began<20000,"WHOLE_LOCAL_COMPONENT20S")
	var report: Dictionary={"status":"ROOT_LOCAL_DOCKS_GALLERY_RETIREMENT_COMPONENTS_NOT_RUNTIME","passed":errors.is_empty() and not components.is_empty(),"complete":errors.is_empty() and not components.is_empty(),"checks":checks,"errors":errors.duplicate(),"elapsed_ms":Time.get_ticks_msec()-began,"components":components,"source_first":first,"source_final":last,"save_first":saves,"save_final":save_last,"inherited_full_publication":spec.get("inherited_whole_publication"),"new_geometry_recompile_calls":0,"old_routes_or87517_replay":0,"full_raster_replay_calls":0,"Scene_Field_packet_import_calls":0,"canonical_writes":0,"actual_Field_pass":false}
	var report_root: String=String(spec.get("output_root",""))+str(OS.get_process_id())+"/"
	if report_root.begins_with("res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/"):
		DirAccess.make_dir_recursive_absolute(physical(report_root));save_bytes(report_root+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("DOCKS_RETIRE_RESULT ",report_root+"result.json")
	quit(0 if report.passed else 1)
func run() -> void:
	began=Time.get_ticks_msec()
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_AND_FIXED_INPUT"): quit(2);return
	spec=json_pin({"path":INPUT})
	if not check(spec.get("ready")==true and spec.get("root_run_authorized")==true and spec.get("scene_id")==SCENE and spec.get("retire_id")==ID and int(spec.get("whole_budget_ms",0))==20000,"EXACT_LOCAL_ROOT_SCOPE"): quit(2);return
	var paths: Array=spec.sources.keys();paths.append(INPUT);paths.append(SELF);first=facts(paths);saves=facts(spec.save_absolute_paths)
	for path: String in spec.sources:
		if not check(first[path].get("sha256")==spec.sources[path],"FIXED_INPUT_SOURCE:"+path): fail();return
	if not check(saves.size()==15,"EXACT_FIFTEEN_SAVE_FACTS"): fail();return
	var old_bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(spec.parent_payload.path))
	var original: Variant=bytes_to_var(old_bytes)
	if not check(original is Dictionary and same(original,bytes_to_var(old_bytes)) and var_to_bytes(original)==old_bytes and original.scene_id==SCENE,"EXACT_FROZEN_PAYLOAD_TYPED_READBACK"): fail();return
	var old: Dictionary=original;var child: Dictionary=old.duplicate(true)
	var source_contract: Dictionary=json_pin(spec.source_contract);var oracle: Dictionary=json_pin(spec.local_oracle)
	var placement: Dictionary=source_contract.placement;var asset: Dictionary=source_contract.asset
	if not check(placement.id==ID and placement.asset_id=="open_gallery" and vec(placement.foot_px)==Vector2(1850,1780) and float(placement.scale)==.36 and asset.source_solid_rects_px.size()==4,"EXACT_RETIRED_SOURCE_INSTANCE"): fail();return
	var foot: Vector2=vec(placement.foot_px);var anchor: Vector2=vec(asset.source_ground_anchor_px);var ratio: float=float(placement.scale);var size: Vector2=vec(asset.source_size_px);var retired_shapes: Array=[]
	for rectangle: Array in asset.source_solid_rects_px:
		var raw_corners: Array=[Vector2(float(rectangle[0]),float(rectangle[1])),Vector2(float(rectangle[0])+float(rectangle[2]),float(rectangle[1])),Vector2(float(rectangle[0])+float(rectangle[2]),float(rectangle[1])+float(rectangle[3])),Vector2(float(rectangle[0]),float(rectangle[1])+float(rectangle[3]))]
		var shape: PackedVector2Array=PackedVector2Array()
		for corner: Vector2 in raw_corners: shape.append(foot+(corner-anchor)*ratio)
		retired_shapes.append(shape)
	for shape_index: int in range(4):
		if not check(same(retired_shapes[shape_index],points(placement.source_derived_new_ground_polygons_f32[shape_index])) and same(retired_shapes[shape_index],points(oracle.retired_named_rows[shape_index].points_px)),"EXACT_FOUR_SOURCE_AND_INHERITED_INDEPENDENT_PACKED_BITS:"+str(shape_index)): fail();return
	var expected_row: Dictionary={"id":ID,"texture":asset.texture,"pos":(foot+(size*0.5-anchor)*ratio)/SIZE,"render_size_px":size*ratio,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":retired_shapes,"blocking":true}
	var nav_index: int=unique_index(old.effective_navigation,ID);var add_index: int=unique_index(old.visual_additions,ID)
	if not check(nav_index>=0 and add_index>=0 and same(old.effective_navigation[nav_index],expected_row) and same(old.visual_additions[add_index],expected_row) and unique_index(old.parent_navigation,ID)==-1,"EXACT_ONLY_NEW_VISUAL_ROW"): fail();return
	var independent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(physical(spec.independent_geometry.path)))
	if not check(independent is Dictionary and independent.geometry.get(SCENE) is Dictionary,"INHERITED_QA_GEOMETRY_SCHEMA"): fail();return
	var table: Dictionary=independent.geometry[SCENE];var all_named: Array=table.old_retained.duplicate(true);all_named.append_array(table.new_appended)
	if not check(all_named.size()==old.effective_solids.size() and all_named.size()==43,"OLD43_FULL_ORDER_FROM_INHERITED_QA"): fail();return
	var solid_indices: Array=[]
	for solid_index: int in range(all_named.size()):
		if not check(same(old.effective_solids[solid_index],all_named[solid_index].points_px),"INHERITED_FULL_PACKED_ORDER:"+str(solid_index)): fail();return
		if String(all_named[solid_index].get("owner_id",""))==ID: solid_indices.append(solid_index)
	if not check(solid_indices.size()==4,"ONLY_FOUR_RETIRED_SOLID_ROWS"): fail();return
	child.effective_navigation.remove_at(nav_index);child.visual_additions.remove_at(add_index)
	for reverse_index: int in range(solid_indices.size()-1,-1,-1): child.effective_solids.remove_at(int(solid_indices[reverse_index]))
	if not check(old.new_route_contracts.size()==1 and old.new_route_contracts[0].source_portal_id=="canal_world_ferry" and old.new_route_contracts[0].source_foot_px==Vector2(340,1840) and old.new_route_contracts[0].source_portal_row.pos==Vector2(2140,1840)/SIZE and not old.new_route_contracts[0].source_portal_row.has("source_spawn_pos"),"FERRY_ORIGINAL_REAL_POS_NOT_MOVED_ONLY_OLD_CONTRACT_STALE"): fail();return
	child.new_route_contracts[0].source_foot_px=Vector2(2140,1840)
	var permitted: Array=["effective_navigation","visual_additions","effective_solids","new_route_contracts"]
	for key: Variant in old:
		if not permitted.has(key) and not check(same(old[key],child[key]),"OTHER_PAYLOAD_FIELD_BYTES_UNCHANGED:"+String(key)): fail();return
	var restored: Dictionary=child.duplicate(true);restored.effective_navigation.insert(nav_index,old.effective_navigation[nav_index]);restored.visual_additions.insert(add_index,old.visual_additions[add_index])
	for restored_index: int in solid_indices: restored.effective_solids.insert(restored_index,old.effective_solids[restored_index])
	restored.new_route_contracts[0].source_foot_px=old.new_route_contracts[0].source_foot_px
	if not check(var_to_bytes(restored)==old_bytes and child.effective_navigation.size()==43 and child.effective_solids.size()==39,"WHOLE_PAYLOAD_BYTE_INVERSE_AND_43NAV39SOLIDS"): fail();return
	var current_image: Image=image_pin(spec.parent_mask);var support_image: Image=image_pin(spec.support_mask)
	if not check(current_image!=null and support_image!=null,"FIXED_CURRENT_AND_ORIGINAL35_SUPPORT_RGBA"): fail();return
	var before: PackedByteArray=current_image.get_data();var after: PackedByteArray=before.duplicate();var support: PackedByteArray=support_image.get_data();var offsets: PackedInt32Array=PackedInt32Array();var prior_bytes: PackedByteArray=PackedByteArray();var visited: int=0
	for domain: Dictionary in oracle.closed_domains:
		var box: Array=domain.closed_xyxy
		if not check(domain_bytes(before,box)==String(domain.before_RGBA_hex).hex_decode(),"LOCAL_ORACLE_BEFORE_DOMAIN:"+str(box)): fail();return
		for retained: Dictionary in oracle.retained_new_named_rows:
			var retained_points: PackedVector2Array=points(retained.points_px);var low: Vector2=retained_points[0];var high: Vector2=low
			for retained_point: Vector2 in retained_points: low=low.min(retained_point);high=high.max(retained_point)
			if not check(high.x<float(box[0]) or low.x>float(box[2]) or high.y<float(box[1]) or low.y>float(box[3]),"RETAINED_NEW_BODY_OUTSIDE_RETIRED_POST_DOMAIN"): fail();return
		for y: int in range(int(box[1]),int(box[3])+1):
			for x: int in range(int(box[0]),int(box[2])+1):
				visited+=1;var offset: int=(y*3072+x)*4
				if before.slice(offset,offset+4)!=support.slice(offset,offset+4): offsets.append(offset);prior_bytes.append_array(before.slice(offset,offset+4))
				for channel: int in range(4): after[offset+channel]=support[offset+channel]
		if not check(domain_bytes(after,box)==String(domain.after_RGBA_hex).hex_decode(),"LOCAL_ORACLE_AFTER_DOMAIN:"+str(box)): fail();return
	var inverse_mask: PackedByteArray=after.duplicate()
	for inverse_index: int in range(offsets.size()):
		for channel: int in range(4): inverse_mask[offsets[inverse_index]+channel]=prior_bytes[inverse_index*4+channel]
	if not check(visited==2928 and offsets.size()==630 and inverse_mask==before,"ONLY_FOUR_DOMAINS_630_PIXELS_WHOLE_RGBA_INVERSE"): fail();return
	var fingerprints: Dictionary={}
	for key: Variant in child:
		if child[key] is Array or String(key)=="parent_blockers_ref": fingerprints[key]=hash_bytes(var_to_bytes(child[key]))
	var prefix: String=String(spec.output_root)+str(OS.get_process_id())+"/"
	if not check(not DirAccess.dir_exists_absolute(physical(prefix)) and prefix.begins_with("res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/"),"NEW_LOCAL_OUTPUT_DIRECTORY_ONLY"): fail();return
	DirAccess.make_dir_recursive_absolute(physical(prefix))
	var payload_pin: Dictionary=save_bytes(prefix+"payload.bin",var_to_bytes(child));var solids_pin: Dictionary=save_bytes(prefix+"effective_solids.bin",var_to_bytes(child.effective_solids))
	var inverse: Dictionary={"parent_payload_sha256":spec.parent_payload.sha256,"retired_nav_index":nav_index,"retired_add_index":add_index,"retired_row":old.effective_navigation[nav_index],"retired_solid_indices":solid_indices,"retired_shapes":retired_shapes,"old_route_source_foot":Vector2(340,1840),"mask_byte_offsets":offsets,"mask_old_RGBA":prior_bytes,"whole_payload_byte_inverse_verified":true,"whole_RGBA_inverse_verified":true}
	var inverse_pin: Dictionary=save_bytes(prefix+"retirement_inverse.bin",var_to_bytes(inverse));var output_image: Image=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,after);var mask_path: String=prefix+"walk_overlay.png"
	if not check(not FileAccess.file_exists(physical(mask_path)) and output_image.save_png(physical(mask_path))==OK,"NEW_MASK_FILE_ONLY"): fail();return
	var mask_pin: Dictionary={"path":mask_path,"sha256":FileAccess.get_sha256(physical(mask_path)),"RGBA_sha256":hash_bytes(after),"bytes":FileAccess.get_file_as_bytes(physical(mask_path)).size(),"kind":"RAW_RGBA8_PENDING_ISOLATED_IMPORT","size":[3072,2048]}
	finish({"payload":payload_pin,"geometry":solids_pin,"mask":mask_pin,"inverse":inverse_pin,"fingerprints":fingerprints,"retired_visual_ids":[ID],"retired_solid_count":4,"new_NAV_count":43,"new_solid_count":39,"mask_visited_pixels":visited,"mask_changed_pixels":offsets.size(),"closed_domains":source_contract.closed_domains,"portal_before_after_unchanged":true,"ferry_source_contract_only":[2140,1840],"unchanged_old_office_warehouse_doors_NPC_cargo_routes":true})
