extends SceneTree
## Root-only one NPC source-row successor. Never republishes NAV or modifies a mask.
const READY: bool=true
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/docks_loading08_local01_NOTREADY/ROOT_READY01/input_ROOT_READY.json"
const INPUT_SHA: String="cf6a4e14f20341afea24e3e4f76136dbfed0cbb34d50778c35f55b44eefc0982"
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/docks_loading08_local01_NOTREADY/ROOT_READY01/publish_loading_delta_ROOT_READY.gd"
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
const ID: String="harbour_life_docks_loading_attendant"
const SCENE: String="ch4_s2_canal_docks"
const SIZE: Vector2=Vector2(3072,2048)
var spec: Dictionary={}
var checks: int=0
var errors: Array[String]=[]
var began: int=0
var first: Dictionary={}
var saves: Dictionary={}
var mask_queries: int=0
var body_tests: int=0
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("LOADING08_FAIL ",label)
	return ok
func sha(raw: PackedByteArray) -> String:
	var hash: HashingContext=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(raw);return hash.finish().hex_encode()
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func vec(raw: Array) -> Vector2: return Vector2(float(raw[0]),float(raw[1]))
func facts(paths: Array) -> Dictionary:
	var out: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(physical(path)): out[path]={"exists":false};continue
		var file: FileAccess=FileAccess.open(physical(path),FileAccess.READ)
		out[path]={"exists":true,"sha256":FileAccess.get_sha256(physical(path)),"bytes":file.get_length(),"mtime_seconds":FileAccess.get_modified_time(physical(path))};file.close()
	return out
func json_file(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)))
	return value if value is Dictionary else {}
func write_new(path: String,bytes: PackedByteArray) -> Dictionary:
	if not check(not FileAccess.file_exists(physical(path)),"ABSENT_OUTPUT:"+path): return {}
	var file: FileAccess=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(file!=null,"NEW_OUTPUT:"+path): return {}
	file.store_buffer(bytes);file.close();return {"path":path,"sha256":sha(bytes),"bytes":bytes.size()}
func rectangle(foot: Vector2,half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot-half,foot+Vector2(half.x,-half.y),foot+half,foot+Vector2(-half.x,half.y)])
func cross(a: Vector2,b: Vector2,c: Vector2) -> float:
	return (float(b.x)-a.x)*(float(c.y)-a.y)-(float(b.y)-a.y)*(float(c.x)-a.x)
func on_segment(a: Vector2,b: Vector2,p: Vector2) -> bool:
	return cross(a,b,p)==0.0 and p.x>=minf(a.x,b.x) and p.x<=maxf(a.x,b.x) and p.y>=minf(a.y,b.y) and p.y<=maxf(a.y,b.y)
func touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	return (cross(a,b,c)*cross(a,b,d)<0.0 and cross(c,d,a)*cross(c,d,b)<0.0) or on_segment(a,b,c) or on_segment(a,b,d) or on_segment(c,d,a) or on_segment(c,d,b)
func safe_body(foot: Vector2,half: Vector2,mask: Image,solids: Array) -> bool:
	body_tests+=1
	if not foot.is_finite() or foot.x<half.x or foot.y<half.y or foot.x+half.x>=SIZE.x or foot.y+half.y>=SIZE.y: return false
	var body: PackedVector2Array=rectangle(foot,half)
	for poly: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(body,poly).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,poly): return false
		for point: Vector2 in poly:
			if point.x>=foot.x-half.x and point.x<=foot.x+half.x and point.y>=foot.y-half.y and point.y<=foot.y+half.y: return false
		for edge: int in range(body.size()):
			for other: int in range(poly.size()):
				if touch(body[edge],body[(edge+1)%body.size()],poly[other],poly[(other+1)%poly.size()]): return false
	for y: int in range(floori(foot.y-half.y),ceili(foot.y+half.y)+1):
		for x: int in range(floori(foot.x-half.x),ceili(foot.x+half.x)+1):
			mask_queries+=1
			var color: Color=mask.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	return true
func finish(components: Dictionary) -> void:
	var last: Dictionary=facts(first.keys());var save_last: Dictionary=facts(spec.get("save_absolute_paths",[]))
	check(first==last,"FIXED_SOURCE_FIRST_FINAL_SAME");check(saves==save_last,"FIFTEEN_SAVE_BYTES_SHA_MTIME_SECONDS_SAME")
	check(Time.get_ticks_msec()-began<20000,"FINITE_LOCAL20S")
	var report: Dictionary={"status":"ROOT_LOCAL_LOADING_NPC08_COMPONENTS_NOT_RUNTIME","passed":errors.is_empty() and not components.is_empty(),"checks":checks,"errors":errors.duplicate(),"elapsed_ms":Time.get_ticks_msec()-began,"components":components,"source_first":first,"source_final":last,"save_first":saves,"save_final":save_last,"body_tests":body_tests,"mask_pixel_queries":mask_queries,"mask_writes":0,"geometry_recompile_calls":0,"old87517_or_city_routes_replayed":0,"Scene_Field_packet_ResourceLoader_calls":0,"canonical_writes":0,"actual_Field_pass":false,"independent_QA_credit":false,"exact_ticks_protection":"Root external pre/post guard; Godot facts here deliberately claim seconds only"}
	var output: String=String(spec.get("output_root",""))+str(OS.get_process_id())+"/"
	if output.begins_with("res://build/luoyang_city_finish_20261025i_source01/docks_loading08_local01_NOTREADY/"):
		DirAccess.make_dir_recursive_absolute(physical(output));write_new(output+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("LOADING08_RESULT ",output+"result.json")
	quit(0 if report.passed else 1)
func run() -> void:
	began=Time.get_ticks_msec()
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_FIXED_INPUT"): quit(2);return
	spec=json_file(INPUT)
	if not check(spec.get("ready")==true and spec.get("root_run_authorized")==true and spec.get("scene_id")==SCENE,"EXACT_ROOT_SCOPE"): quit(2);return
	var paths: Array=spec.sources.keys();paths.append(INPUT);paths.append(SELF);first=facts(paths);saves=facts(spec.save_absolute_paths)
	for path: String in spec.sources:
		if not check(first[path].get("sha256")==spec.sources[path],"FIXED_SOURCE:"+path): finish({});return
	if not check(saves.size()==15,"EXACT_FIFTEEN_SAVE_FACTS"): finish({});return
	var parent_author: Dictionary=json_file(spec.parent_author.path);var author: Dictionary=json_file(spec.author.path)
	var old_move: Dictionary=parent_author.scenes[3].npc_migrations[1];var new_move: Dictionary=author.scenes[3].npc_migrations[1]
	var old_route: Dictionary=parent_author.scenes[3].new_source_routes[1];var new_route: Dictionary=author.scenes[3].new_source_routes[1]
	if not check(old_move.npc_id==ID and new_move.npc_id==ID and old_move.new_source_origin_px==[2060.0,1840.0] and new_move.new_source_origin_px==[1940.0,1840.0] and new_move.new_dynamic_NPC_guard_domain_xyxy==[1916.0,1816.0,1964.0,1904.0] and new_route.points_px==[[1430.0,1910.0],[1940.0,1910.0],[1940.0,1888.0]],"EXACT_SOURCE08_FOOT_DOMAIN_ROUTE"): finish({});return
	var parent_bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(spec.parent_payload.path))
	var raw: Variant=bytes_to_var(parent_bytes)
	if not check(raw is Dictionary and var_to_bytes(raw)==parent_bytes and raw.scene_id==SCENE,"FIXED_PARENT_NATIVE_TYPED_ROUNDTRIP"): finish({});return
	var parent: Dictionary=raw;var child: Dictionary=parent.duplicate(true);var index: int=-1
	for i: int in range(parent.npc_migrations.size()):
		if parent.npc_migrations[i].get("npc_id")==ID:
			if not check(index==-1,"UNIQUE_LOADING_MIGRATION"): finish({});return
			index=i
	if not check(index>=0 and same(parent.npc_migrations[index],old_move),"WHOLE_PARENT_MIGRATION_EXACT_SOURCE07"): finish({});return
	child.npc_migrations[index]=new_move.duplicate(true)
	var restored: Dictionary=child.duplicate(true);restored.npc_migrations[index]=parent.npc_migrations[index].duplicate(true)
	if not check(same(restored,parent) and var_to_bytes(restored)==parent_bytes,"FULL_TYPED_AND_BYTE_PAYLOAD_INVERSE"): finish({});return
	for key: Variant in parent:
		if key!="npc_migrations" and not check(same(parent[key],child[key]),"UNCHANGED_PAYLOAD_FIELD:"+String(key)): finish({});return
	if not check(parent.effective_navigation.size()==43 and parent.effective_solids.size()==39 and same(parent.portal_before,child.portal_before) and same(parent.portal_after,child.portal_after) and same(parent.new_route_contracts,child.new_route_contracts),"ALL43_NAV39_SOLID_REAL_PORTAL2140_UNCHANGED"): finish({});return
	var mask: Image=Image.load_from_file(physical(spec.mask.path))
	if not check(mask!=null and mask.get_size()==Vector2i(3072,2048) and not mask.has_mipmaps(),"FIXED_LOCAL_MASK_SIZE"): finish({});return
	mask.convert(Image.FORMAT_RGBA8)
	if not check(sha(mask.get_data())==spec.mask.RGBA_sha256,"INHERITED_FULL_MASK_RGBA"): finish({});return
	var npc_foot: Vector2=Vector2(1940,1840);var npc_half: Vector2=Vector2(22.4,28.8)*.5
	if not check(safe_body(npc_foot,npc_half,mask,parent.effective_solids),"NEW_LOADING_NPC22_4x28_8_MASK_ALL39_INCLUDING_ORIGINAL_OFFICE"): finish({});return
	var samples: int=0
	for segment: int in range(new_route.points_px.size()-1):
		var from: Vector2=vec(new_route.points_px[segment]);var to: Vector2=vec(new_route.points_px[segment+1]);var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
		for step: int in range(steps+1):
			var foot: Vector2=from.lerp(to,float(step)/float(steps));samples+=1
			if not check(safe_body(foot,Vector2(17,12),mask,parent.effective_solids),"PACKING_PLAYER34x24:"+str(segment)+":"+str(step)): finish({});return
			if not check(absf(foot.x-npc_foot.x)>17.0+npc_half.x or absf(foot.y-npc_foot.y)>12.0+npc_half.y,"PACKING_REAL_NPC_BODY_SEPARATION:"+str(segment)+":"+str(step)): finish({});return
	# Exact whole doorway rectangle, conservatively expanded by Player half-body.
	if not check(2075.0-npc_foot.x>118.0 and 2075.0-npc_foot.x>80.0+17.0 and npc_foot.distance_to(Vector2(2140,1840))==200.0 and vec(new_route.points_px[-1]).distance_to(npc_foot)==48.0,"WHOLE_DOORWAY_NPC_FALLBACK_AREA_AND_48PX_APPROACH"): finish({});return
	var output: String=String(spec.output_root)+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(physical(output))
	var payload_pin: Dictionary=write_new(output+"payload.bin",var_to_bytes(child))
	var inverse_pin: Dictionary=write_new(output+"migration_inverse.bin",var_to_bytes({"index":index,"before":parent.npc_migrations[index],"after":child.npc_migrations[index],"parent_payload_sha256":spec.parent_payload.sha256}))
	finish({"payload":payload_pin,"migration_inverse":inverse_pin,"npc_migrations_var_sha256":sha(var_to_bytes(child.npc_migrations)),"only_changed_payload_key":"npc_migrations","changed_NPC_id":ID,"new_foot_px":npc_foot,"route_samples":samples,"original_mask_NAV_solids_portal_contract_inherited_unchanged":true,"no_new_mask_or_import_needed":true,"original_public_Space_still_requires_actual_Field_validation":true})
