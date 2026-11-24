extends SceneTree
## Root-only three existing payloads: two portal positions and two incoming contracts.
const READY: bool=true
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/Temple_visible_arrival_local02_ROOT_READY/input_ROOT_READY.json"
const INPUT_SHA: String="da9d124eb078260c223d99ae73200c3b49fce76bc8fe7bd1db405dc7f26aaffe"
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/Temple_visible_arrival_local02_ROOT_READY/check_visible_arrival_ROOT_READY.gd"
const ROOT: String="F:/Code/RPG_GAME/game/"
const SOURCE_SIZE: Vector2=Vector2(1536,1024)
const WORLD_SIZE: Vector2=Vector2(1920,1280)
var cfg: Dictionary={}
var errors: Array[String]=[]
var checks: int=0
var began: int=0
var first: Dictionary={}
var save_first: Dictionary={}
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func hash_bytes(raw: PackedByteArray) -> String:
	var ctx: HashingContext=HashingContext.new();ctx.start(HashingContext.HASH_SHA256);ctx.update(raw);return ctx.finish().hex_encode()
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func v(raw: Array) -> Vector2: return Vector2(float(raw[0]),float(raw[1]))
func check(ok: bool,tag: String) -> bool:
	checks+=1
	if not ok: errors.append(tag);printerr("VISIBLE_TEMPLE_FAIL ",tag)
	return ok
func facts(paths: Array) -> Dictionary:
	var out: Dictionary={}
	for path: String in paths:
		var file_path: String=physical(path)
		if not FileAccess.file_exists(file_path): out[path]={"exists":false};continue
		var file: FileAccess=FileAccess.open(file_path,FileAccess.READ)
		out[path]={"exists":true,"sha256":FileAccess.get_sha256(file_path),"bytes":file.get_length(),"mtime_seconds":FileAccess.get_modified_time(file_path)};file.close()
	return out
func read_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)))
	return value if value is Dictionary else {}
func new_file(path: String,raw: PackedByteArray) -> Dictionary:
	if not check(not FileAccess.file_exists(physical(path)),"NEW_ONLY:"+path): return {}
	var file: FileAccess=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(file!=null,"CREATE_NEW:"+path): return {}
	file.store_buffer(raw);file.close();return {"path":path,"sha256":hash_bytes(raw),"bytes":raw.size()}
func finish(components: Dictionary) -> void:
	var last: Dictionary=facts(first.keys());var save_last: Dictionary=facts(cfg.get("save_absolute_paths",[]))
	check(first==last,"ALL_FIXED_SOURCE_FIRST_FINAL");check(save_first==save_last,"SAVE15_SHA_BYTES_SECONDS_SAME")
	check(Time.get_ticks_msec()-began<20000,"BOUNDED20S")
	var report: Dictionary={"status":"ROOT_TWO_VISIBLE_TEMPLE_PORTALS_THREE_PAYLOAD_TYPED_INVERSE_NOT_FIELD_PASS","passed":errors.is_empty() and not components.is_empty(),"checks":checks,"errors":errors.duplicate(),"components":components,"source_first":first,"source_final":last,"save_first":save_first,"save_final":save_last,"elapsed_ms":Time.get_ticks_msec()-began,"old25_solids_recompiled":false,"new_swept_legs_only":true,"mask_import_raster_or_PNG_loads":0,"Scene_Field_ResourceLoader_calls":0,"old87517_replay":false,"actual_Field_pass":false,"canonical_writes":0,"exactticks_guard":"Root outer exactticks guard, native internal facts seconds only"}
	if not cfg.is_empty():
		var output: String=String(cfg.output_root)+str(OS.get_process_id())+"/"
		DirAccess.make_dir_recursive_absolute(physical(output));new_file(output+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("VISIBLE_TEMPLE_RESULT ",output+"result.json")
	quit(0 if report.passed else 1)
func unique_index(rows: Array,id: String) -> int:
	var found: int=-1
	for i: int in range(rows.size()):
		if String(rows[i].get("id",""))!=id: continue
		if found!=-1: return -2
		found=i
	return found
func rectangle(center: Vector2,half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center-half,center+Vector2(half.x,-half.y),center+half,center+Vector2(-half.x,half.y)])
func swept(a: Vector2,b: Vector2) -> PackedVector2Array:
	var corners: PackedVector2Array=rectangle(a,Vector2(17,12));corners.append_array(rectangle(b,Vector2(17,12)))
	return Geometry2D.convex_hull(corners)
func run() -> void:
	began=Time.get_ticks_msec()
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_INPUT"): quit(2);return
	cfg=read_json(INPUT)
	if not check(cfg.get("ready")==true and cfg.get("root_run_authorized")==true,"ROOT_EXPLICIT_PERMISSION"): quit(2);return
	var paths: Array=cfg.sources.keys();paths.append(INPUT);paths.append(SELF);first=facts(paths);save_first=facts(cfg.save_absolute_paths)
	for path: String in cfg.sources:
		if not check(first[path].get("sha256")==cfg.sources[path],"FIXED_SOURCE:"+path): finish({});return
	if not check(save_first.size()==15,"SAVE15_DOMAIN"): finish({});return
	var source_author: Dictionary=read_json(cfg.author.path)
	if not check(source_author.finish_i_effective_portal_local_migrations.size()==2 and cfg.pairs.size()==2,"ROOT_EXACT_TWO_PORTAL_SOURCE_MIGRATIONS"): finish({});return
	for source_migration: Dictionary in source_author.finish_i_effective_portal_local_migrations:
		var source_matches: int=0
		for fixed_pair: Dictionary in cfg.pairs:
			if source_migration.id==fixed_pair.temple_portal_id and v(source_migration.new_local_source_foot_px)==v(fixed_pair.new_source_foot): source_matches+=1
		if not check(source_matches==1,"FIXED_SOURCE_AUTHOR_PAIR_BINDING:"+String(source_migration.id)): finish({});return
	var parents: Dictionary={};var children: Dictionary={};var parent_raws: Dictionary={}
	for scene_id: String in cfg.payloads:
		var pin: Dictionary=cfg.payloads[scene_id];var raw: PackedByteArray=FileAccess.get_file_as_bytes(physical(pin.path));var data: Variant=bytes_to_var(raw)
		if not check(data is Dictionary and var_to_bytes(data)==raw,"WHOLE_TYPED_PARENT:"+scene_id): finish({});return
		parents[scene_id]=data;children[scene_id]=data.duplicate(true);parent_raws[scene_id]=raw
	var temple: Dictionary=parents["ch4_s4_ancient_temple"]
	if not check(temple.effective_solids.size()==25 and temple.effective_walkable_polygons.size()==1,"INHERITED_ORIGINAL25_ONE_FLOOR_NO_RECOMPILE"): finish({});return
	var mapping: Array=[]
	for spec: Dictionary in cfg.pairs:
		var old_uv: Vector2=v(spec.old_source_foot)/SOURCE_SIZE;var next_uv: Vector2=v(spec.new_source_foot)/SOURCE_SIZE;var next_foot: Vector2=next_uv*WORLD_SIZE
		var temple_child: Dictionary=children["ch4_s4_ancient_temple"]
		var portal_index: int=unique_index(temple_child.portal_after,String(spec.temple_portal_id))
		if not check(portal_index>=0,"UNIQUE_TEMPLE_PORTAL:"+String(spec.temple_portal_id)): finish({});return
		var old_row: Dictionary=temple.portal_after[portal_index];var next_row: Dictionary=old_row.duplicate(true)
		if not check(old_row.pos==old_uv,"EXACT_OLD_SOURCE_FOOT:"+String(spec.temple_portal_id)): finish({});return
		next_row.pos=next_uv;temple_child.portal_after[portal_index]=next_row
		var source: Dictionary=parents[String(spec.incoming_scene)];var source_child: Dictionary=children[String(spec.incoming_scene)]
		var source_index: int=unique_index(source.portal_after,String(spec.incoming_portal_id))
		if not check(source_index>=0 and source.new_route_contracts.size()==1,"ONE_EXACT_INCOMING_CONTRACT:"+String(spec.incoming_scene)): finish({});return
		var source_old_row: Dictionary=source.portal_after[source_index];var source_new_row: Dictionary=source_old_row.duplicate(true)
		var contract: Dictionary=source.new_route_contracts[0];var next_contract: Dictionary=contract.duplicate(true)
		if not check(source_old_row.target_pos==old_uv and contract.expected_normalized==old_uv and contract.source_target_pos==old_uv and contract.target_foot_px==old_uv*WORLD_SIZE and same(contract.source_portal_row,source_old_row) and contract.source_foot_px==v(spec.incoming_actual_source_foot) and contract.kind=="TEMPLE_DEFERRED_ORIGINAL_PREPARE","ENTIRE_OLD_INCOMING_TERMINAL_CONTRACT:"+String(spec.incoming_scene)): finish({});return
		source_new_row.target_pos=next_uv;source_child.portal_after[source_index]=source_new_row
		next_contract.expected_normalized=next_uv;next_contract.source_target_pos=next_uv;next_contract.target_foot_px=next_foot;next_contract.source_portal_row=source_new_row.duplicate(true);source_child.new_route_contracts[0]=next_contract
		var restore_row: Dictionary=source_new_row.duplicate(true);restore_row.target_pos=source_old_row.target_pos
		check(same(restore_row,source_old_row),"SOURCE_PORTAL_ENTIRE_ROW_EXCEPT_TARGET_IDENTICAL:"+String(spec.incoming_scene))
		var restore_contract: Dictionary=next_contract.duplicate(true)
		for key: String in ["expected_normalized","source_target_pos","target_foot_px","source_portal_row"]: restore_contract[key]=contract[key]
		check(same(restore_contract,contract),"CONTRACT_OTHER_KEYS_INCLUDING2140_AND_KIND_UNCHANGED:"+String(spec.incoming_scene))
		var body: PackedVector2Array=rectangle(next_foot,Vector2(17,12))
		check(next_foot.y==1157.5 and next_foot.y+12<1180 and next_foot.y-140>100,"BODY_AND140_CORE_VISIBLE_ORIGINAL_STATIC_VIEW:"+String(spec.temple_portal_id))
		# Existing ExitZone source: offset(0,-40), clamp to world.y-130, max bob5.
		var anchor: Vector2=Vector2(clampf(next_foot.x,120,1770),clampf(next_foot.y-40,120,1150))
		var label_min: Vector2=anchor+Vector2(-140,28);var label_max: Vector2=label_min+Vector2(200,30)
		check(label_min.x>=0 and label_max.x<=1920 and label_min.y-3>100 and label_max.y+3<1180,"ORIGINAL_PROMPT_DECLARED200x30_PLUS_OUTLINE3_ANCHORED_VISIBLE:"+String(spec.temple_portal_id))
		var arrow_half: Vector2=Vector2(300,375)*.092*.5
		check(anchor.y-arrow_half.y-5>100 and anchor.y+arrow_half.y+5<1180,"ORIGINAL_COMPLETE_ARROW_CANVAS_WITH_MAX_SCALE_AND_BOB_VISIBLE:"+String(spec.temple_portal_id))
		mapping.append({"portal":spec.temple_portal_id,"old_source_foot":v(spec.old_source_foot),"new_source_foot":v(spec.new_source_foot),"normalized":next_uv,"world_foot":next_foot,"full_body":body,"world_arrow_anchor":anchor,"world_prompt_control_box":[label_min,label_max],"prompt_outline_bottom_margin":1180-label_max.y-3,"original_hotspot_storage_unchanged_layout_portals_take_precedence":true})
	var route_results: Array=[]
	for route: Dictionary in cfg.routes:
		var errors_before: int=errors.size();var points: PackedVector2Array=[]
		for point: Array in route.source_points: points.append((v(point)/SOURCE_SIZE)*WORLD_SIZE)
		for leg: int in range(points.size()-1):
			var sweep: PackedVector2Array=swept(points[leg],points[leg+1])
			check(Geometry2D.clip_polygons(sweep,temple.effective_walkable_polygons[0]).is_empty(),"NEW_LEG_FULL_BODY_IN_INHERITED_FLOOR:"+String(route.id)+":"+str(leg))
			for solid_index: int in range(temple.effective_solids.size()): check(Geometry2D.intersect_polygons(sweep,temple.effective_solids[solid_index]).is_empty(),"NEW_LEG_VS_FIXED25_SOLID:"+String(route.id)+":"+str(leg)+":"+str(solid_index))
			for npc: Dictionary in cfg.original_two_monks:
				var npc_world: Vector2=(v(npc.source_foot)/SOURCE_SIZE)*WORLD_SIZE
				check(Geometry2D.intersect_polygons(sweep,rectangle(npc_world,Vector2(17,15))).is_empty(),"NEW_LEG_VS_UNMOVED_MONK34x30:"+String(route.id)+":"+str(leg)+":"+String(npc.id))
		route_results.append({"id":route.id,"passed":errors.size()==errors_before,"world_points":points})
	var inverse: Dictionary={}
	for scene_id: String in parents:
		var parent: Dictionary=parents[scene_id];var child: Dictionary=children[scene_id];var restored: Dictionary=child.duplicate(true)
		restored.portal_after=parent.portal_after.duplicate(true);restored.new_route_contracts=parent.new_route_contracts.duplicate(true)
		check(var_to_bytes(restored)==parent_raws[scene_id],"WHOLE_TYPED_BYTE_THREE_PAYLOAD_INVERSE:"+scene_id)
		for key: Variant in parent:
			if key not in ["portal_after","new_route_contracts"]: check(same(parent[key],child[key]),"ALL_OTHER_PAYLOAD_KEYS_IDENTICAL:"+scene_id+":"+String(key))
		inverse[scene_id]={"parent":cfg.payloads[scene_id],"portal_after_before":parent.portal_after,"new_route_contracts_before":parent.new_route_contracts,"whole_typed_byte_inverse":var_to_bytes(restored)==parent_raws[scene_id]}
	if not errors.is_empty(): finish({"mapping":mapping,"new_routes":route_results,"no_child_emitted":true});return
	var output: String=String(cfg.output_root)+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(physical(output));var artifacts: Dictionary={}
	for scene_id: String in children:
		var scene_dir: String=output+scene_id+"/";DirAccess.make_dir_recursive_absolute(physical(scene_dir));artifacts[scene_id]=new_file(scene_dir+"payload.bin",var_to_bytes(children[scene_id]))
	var inverse_pin: Dictionary=new_file(output+"three_payload_portal_contract_whole_inverse.bin",var_to_bytes(inverse))
	finish({"payloads":artifacts,"whole_inverse":inverse_pin,"mapping":mapping,"new_routes":route_results,"all_masks_geometry_NPCs_camera_original_storage_unchanged":true,"prompt_box_not_font_glyph_GPU_credit":true})
