extends SceneTree
## Root-only: retire one Garden addition/base; restore only its owned mask pixels.
const READY: bool=false
const INPUT: String="res://build/luoyang_garden_estate_exit_20261027c_system01/input_NOTREADY.json"
const INPUT_SHA: String="PENDING_ROOT_INPUT_SHA"
const PREFIX: String="res://build/luoyang_garden_estate_exit_20261027c_system01/"
const GAME: String="F:/Code/RPG_GAME/game/"
var checks: int=0
var errors: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME+path.trim_prefix("res://") if path.begins_with("res://") else path
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("GARDEN_ONE_WALL ",label)
	return ok
func sha(data: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(data);return h.finish().hex_encode()
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func json_file(path: String) -> Dictionary:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)))
	return data if data is Dictionary else {}
func write_new(path: String,data: PackedByteArray) -> Dictionary:
	if not need(path.begins_with(PREFIX) and not FileAccess.file_exists(physical(path)),"EXCLUSIVE_NEW_BUILD_OUTPUT"): return {}
	var f:=FileAccess.open(physical(path),FileAccess.WRITE)
	if not need(f!=null,"NEW_OUTPUT_OPEN"): return {}
	f.store_buffer(data);f.close();return {"path":path,"sha256":sha(data),"bytes":data.size()}
func blocked(point: Vector2,solids: Array) -> bool:
	for poly: PackedVector2Array in solids:
		if Geometry2D.is_point_in_polygon(point,poly): return true
	return false
func read_mask(row: Dictionary) -> Image:
	var image:=Image.load_from_file(physical(row.path))
	if not need(image!=null and image.get_size()==Vector2i(3072,2048) and not image.has_mipmaps(),"FIXED_MASK_SIZE"): return null
	image.convert(Image.FORMAT_RGBA8)
	return image if need(sha(image.get_data())==row.RGBA_sha256,"FIXED_RGBA_MASK") else null
func run() -> void:
	if not need(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_INPUT"): quit(2);return
	var spec: Dictionary=json_file(INPUT)
	if not need(spec.get("ready")==true,"ROOT_REVIEWED_ONE_WALL_ONLY"): quit(2);return
	for path: String in spec.sources:
		if not need(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE:"+path): quit(2);return
	var data: PackedByteArray=FileAccess.get_file_as_bytes(physical(spec.payload.path))
	var parent: Variant=bytes_to_var(data)
	if not need(parent is Dictionary and var_to_bytes(parent)==data and parent.scene_id=="luoyang_riverside_garden_20261022ap","EXACT_WHOLE_TYPED_GARDEN_PARENT"): quit(1);return
	var child: Dictionary=parent.duplicate(true)
	var row: Dictionary=parent.effective_navigation[60]
	var poly: PackedVector2Array=parent.effective_solids[20]
	var expected:=PackedVector2Array([Vector2(92.5,1454),Vector2(407.5,1454),Vector2(407.5,1460),Vector2(92.5,1460)])
	if not need(row.get("id")=="seven26c_garden_west_dry_outer_edge" and row.get("world_foot_px")==[250.0,1460.0] and same(row,parent.visual_additions[4]) and same(poly,expected) and same(row.city_v3_solid_polygons_px,[expected]),"EXACT_ART_RETIRED_ROW_AND_GROUND_AT_FIXED_INDICES"): quit(1);return
	child.effective_navigation.remove_at(60);child.visual_additions.remove_at(4);child.effective_solids.remove_at(20)
	var inverse: Dictionary=child.duplicate(true)
	inverse.effective_navigation.insert(60,row.duplicate(true));inverse.visual_additions.insert(4,parent.visual_additions[4].duplicate(true));inverse.effective_solids.insert(20,poly.duplicate())
	if not need(var_to_bytes(inverse)==data,"WHOLE_PAYLOAD_TYPED_INVERSE_REINSERT_ONLY_ONE"): quit(1);return
	var old: Image=read_mask(spec.old_mask);var support: Image=read_mask(spec.pre_seven_mask)
	if old==null or support==null: quit(1);return
	var mask: Image=old.duplicate();var changed: Dictionary={};var owned: int=0
	for y: int in range(1454,1461):
		for x: int in range(92,409):
			var point:=Vector2(x,y)
			if not Geometry2D.is_point_in_polygon(point,poly): continue
			owned+=1
			# Restore the frozen underlying support, never fill a rectangle white.
			# Every other currently retained solid still wins at this same pixel.
			var next: Color=Color.BLACK if blocked(point,child.effective_solids) else support.get_pixel(x,y)
			if next!=old.get_pixel(x,y): changed[y*3072+x]=old.get_pixel(x,y);mask.set_pixel(x,y,next)
	var restored: Image=mask.duplicate()
	for index: int in changed: restored.set_pixel(index%3072,floori(float(index)/3072.0),changed[index])
	if not need(same(restored.get_data(),old.get_data()),"WHOLE_RGBA_INVERSE_ONLY_RETIRED_OWNER_PIXELS"): quit(1);return
	for path: String in spec.sources:
		if not need(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE_FINAL:"+path): quit(1);return
	var folder: String=spec.output_root+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(physical(folder))
	var payload: Dictionary=write_new(folder+"payload.bin",var_to_bytes(child))
	var mask_path: String=folder+"walk_overlay.png"
	if not need(not FileAccess.file_exists(physical(mask_path)) and mask.save_png(physical(mask_path))==OK,"NEW_SINGLE_GARDEN_MASK"): quit(1);return
	var fingerprints: Dictionary={}
	for key: String in child:
		if child[key] is Array or key=="parent_blockers_ref": fingerprints[key]=sha(var_to_bytes(child[key]))
	var report: Dictionary={"passed":errors.is_empty(),"checks":checks,"errors":errors,"status":"ONE_ISOLATED_GARDEN_WALL_RETIRED_NOT_FIELD_OR_ROUTE_PASS","payload":payload,"mask":{"path":mask_path,"sha256":FileAccess.get_sha256(physical(mask_path)),"RGBA_sha256":sha(mask.get_data()),"size":[3072,2048]},"fingerprints":fingerprints,"retired_id":row.id,"effective_navigation_count":child.effective_navigation.size(),"effective_solids_count":child.effective_solids.size(),"owned_domain_pixels":owned,"changed_pixels":changed.size(),"whole_payload_inverse":true,"whole_RGBA_inverse":true,"source_first":spec.sources,"source_final":spec.sources,"Field_calls":0,"route_replay_calls":0,"collector_calls":0,"old_geometry_rebuilt":false}
	write_new(folder+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("GARDEN_ONE_WALL_RESULT ",folder+"result.json");quit(0 if errors.is_empty() else 1)
