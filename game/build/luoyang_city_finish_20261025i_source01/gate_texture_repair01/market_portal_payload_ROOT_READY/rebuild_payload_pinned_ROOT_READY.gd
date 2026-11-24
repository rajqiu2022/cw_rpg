extends SceneTree
## Root-only one published Market portal row transport. No resources/Scene/PNG/raster/collector.
const READY: bool=true
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
const INPUT: String="F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_source01/gate_texture_repair01/market_portal_payload_ROOT_READY/input_ROOT_READY.json"
const INPUT_SHA: String="6715011f264d8e62b9a8296707193bb6d943a4e0a57996e818023e047f3ccbef"
var checks: int=0
var errors: Array=[]
var first: Dictionary={}
var began: int=0
var output: String=""
func hash_bytes(raw: PackedByteArray) -> String:
	var h: HashingContext=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(raw);return h.finish().hex_encode()
func physical(path: String) -> String:
	return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func check(ok: bool,clause: String) -> bool:
	checks+=1
	if not ok: errors.append(clause)
	return ok
func pinned(pin: Dictionary) -> PackedByteArray:
	var path: String=String(pin.path);var raw: PackedByteArray=FileAccess.get_file_as_bytes(physical(path))
	if not check(hash_bytes(raw)==String(pin.sha256),"FIXED_SOURCE_SHA:"+path): return PackedByteArray()
	first[path]=String(pin.sha256);return raw
func json_pin(pin: Dictionary) -> Dictionary:
	var raw: PackedByteArray=pinned(pin);var value: Variant=JSON.parse_string(raw.get_string_from_utf8())
	return value if value is Dictionary else {}
func save_new(path: String,raw: PackedByteArray) -> Dictionary:
	if not check(not FileAccess.file_exists(physical(path)),"ONLY_ABSENT_NEW_OUTPUT:"+path): return {}
	var file: FileAccess=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(file!=null,"NEW_OUTPUT_OPEN"): return {}
	file.store_buffer(raw);file.close()
	if not check(FileAccess.get_file_as_bytes(physical(path))==raw,"OUTPUT_WHOLE_BYTE_READBACK"): return {}
	return {"path":path,"sha256":hash_bytes(raw),"bytes":raw.size()}
func finish(extra: Dictionary={}) -> void:
	var final: Dictionary={}
	for path: String in first: final[path]=FileAccess.get_sha256(physical(path))
	check(final==first,"FIXED_SOURCE_FIRST_FINAL_SAME")
	var report: Dictionary={"status":"ROOT_ONLY_ONE_MARKET_POST24E_PORTAL_PAYLOAD_SUCCESSOR","passed":errors.is_empty(),"checks":checks,"errors":errors.duplicate(true),"elapsed_ms":(Time.get_ticks_usec()-began)/1000.0,"source_first":first,"source_final":final,"Scene_loads":0,"PNG_decodes":0,"raster_calls":0,"geometry_recomputed":false,"collector_calls":0,"canonical_writes":0,"actual_Field_pass":false}
	for key: String in extra: report[key]=extra[key]
	if output!="": save_new(output+"/result.json",(JSON.stringify(report,"  ",true,true)+"\n").to_utf8_buffer())
	print(JSON.stringify(report));quit(0 if errors.is_empty()else 1)
func _initialize() -> void:
	began=Time.get_ticks_usec();call_deferred("run")
func run() -> void:
	if not check(READY,"ROOT_READY"): finish();return
	var ib: PackedByteArray=FileAccess.get_file_as_bytes(INPUT)
	if not check(hash_bytes(ib)==INPUT_SHA,"FIXED_INPUT_SHA"): finish();return
	var decoded: Variant=JSON.parse_string(ib.get_string_from_utf8())
	if not check(decoded is Dictionary and decoded.get("ready")==true,"INPUT_ROOT_READY"): finish();return
	var spec: Dictionary=decoded
	first[INPUT]=INPUT_SHA
	output=String(spec.output_prefix)+str(OS.get_process_id())
	if not check(not DirAccess.dir_exists_absolute(physical(output)),"NEW_UNIQUE_OUTPUT_DIRECTORY"): output="";finish();return
	if not check(DirAccess.make_dir_recursive_absolute(physical(output))==OK,"CREATE_NEW_OUTPUT_DIRECTORY"): output="";finish();return
	var old_bytes: PackedByteArray=pinned(spec.payload)
	var old_value: Variant=bytes_to_var(old_bytes)
	if not check(old_value is Dictionary and old_value.get("scene_id")=="ch4_s3_luoyang_market" and var_to_bytes(old_value)==old_bytes,"FIXED_MARKET_TYPED_PAYLOAD_FULL_BYTES"): finish();return
	var old: Dictionary=old_value
	var author: Dictionary=json_pin(spec.author)
	var runtime_bytes: PackedByteArray=pinned(spec.old_runtime)
	var source_expression: String="var foot: Vector2=_pure.v(row.foot_px);portal.pos=foot/SIZE"
	if not check(runtime_bytes.get_string_from_utf8().count(source_expression)==1,"FIXED_ORIGINAL_24E_PORTAL_SOURCE_EXPRESSION"): finish();return
	var move: Dictionary={};var count: int=0
	for row: Dictionary in author.get("external_portal_migrations",[]):
		if row.get("id")!="to_ancient_temple": continue
		move=row;count+=1
	if not check(count==1 and move.get("old_foot_px")==[1536.0,1860.0] and move.get("foot_px")==[1170.0,1600.0],"DE191_EXACT_ONE_AUTHORED_EXTERNAL_MIGRATION"): finish();return
	var size: Vector2=Vector2(3072,2048);var old_foot: Vector2=Vector2(move.old_foot_px[0],move.old_foot_px[1]);var foot: Vector2=Vector2(move.foot_px[0],move.foot_px[1]);var delta: Vector2=foot-old_foot
	if not check(old.portal_before is Array and old.portal_after is Array and old.portal_before.size()==1 and old.portal_after.size()==1 and old.new_route_contracts is Array and old.new_route_contracts.size()==1,"ONE_TARGET_PORTAL_AND_ONE_ROUTE_ONLY"): finish();return
	var prior: Dictionary=old.portal_before[0];var after: Dictionary=old.portal_after[0];var route: Dictionary=old.new_route_contracts[0]
	if not check(prior.get("id")=="to_ancient_temple" and after.get("id")==prior.id and prior.get("pos")==old_foot/size and prior.get("target_scene")=="ch4_s4_ancient_temple","OLD_FIXED_NATIVE_PORTAL_ROW"): finish();return
	var expected_old_after: Dictionary=prior.duplicate(true);expected_old_after.target_pos=Vector2(170,980)/Vector2(1536,1024)
	if not check(var_to_bytes(expected_old_after)==var_to_bytes(after),"OLD_AFTER_EXACTLY_PRIOR_PLUS_APPROVED_TEMPLE_TARGET_UV"): finish();return
	if not check(route.get("source_portal_id")==prior.id and route.get("source_scene_id")=="ch4_s3_luoyang_market" and route.get("target_scene_id")=="ch4_s4_ancient_temple" and route.get("source_foot_px")==foot and var_to_bytes(route.get("source_portal_row"))==var_to_bytes(after),"OLD_ROUTE_SOURCE_CONTRACT_EXACT_ID_FOOT_AND_AFTER_ROW"): finish();return
	var next_prior: Dictionary=prior.duplicate(true);next_prior.pos=foot/size
	if prior.has("interaction_polygon_px"):
		if not check(prior.interaction_polygon_px is PackedVector2Array,"ORIGINAL_POLYGON_PACKED_TYPE"): finish();return
		var points: PackedVector2Array=prior.interaction_polygon_px.duplicate()
		for index: int in range(points.size()): points[index]+=delta
		next_prior.interaction_polygon_px=points
	var next_after: Dictionary=next_prior.duplicate(true);next_after.target_pos=after.target_pos
	var next: Dictionary=old.duplicate(true);next.portal_before[0]=next_prior;next.portal_after[0]=next_after;next.new_route_contracts[0].source_portal_row=next_after.duplicate(true)
	var allowed: Array=["portal_before","portal_after","new_route_contracts"]
	for key: Variant in old:
		if key in allowed: continue
		if not check(var_to_bytes(old[key])==var_to_bytes(next[key]),"EVERY_OTHER_PAYLOAD_FIELD_TYPED_BYTES_UNCHANGED:"+String(key)): finish();return
	var next_route: Dictionary=next.new_route_contracts[0].duplicate(true);next_route.source_portal_row=route.source_portal_row.duplicate(true)
	if not check(var_to_bytes(next_route)==var_to_bytes(route),"EVERY_OTHER_ROUTE_SCALAR_TYPED_BYTES_UNCHANGED"): finish();return
	var back: Dictionary=next.duplicate(true);back.portal_before=old.portal_before.duplicate(true);back.portal_after=old.portal_after.duplicate(true);back.new_route_contracts=old.new_route_contracts.duplicate(true)
	if not check(var_to_bytes(back)==old_bytes,"FULL_PAYLOAD_WHOLE_TYPED_BYTE_INVERSE"): finish();return
	var bytes: PackedByteArray=var_to_bytes(next)
	if not check(var_to_bytes(bytes_to_var(bytes))==bytes,"NEW_TYPED_STORAGE_BYTE_ROUNDTRIP"): finish();return
	var fp: Dictionary={}
	for key: String in next:
		if next[key] is Array or key=="parent_blockers_ref": fp[key]=hash_bytes(var_to_bytes(next[key]))
	var payload_pin: Dictionary=save_new(output+"/payload.bin",bytes)
	var inverse: Dictionary={"old_sha256":hash_bytes(old_bytes),"new_sha256":hash_bytes(bytes),"whole_typed_byte_inverse":true,"only_changed_top_level_fields":allowed,"old_before":prior,"new_before":next_prior,"old_after":after,"new_after":next_after,"source_expression":"DE191 external_portal_migrations + original D296.portals lines195-205 (native Vector2 and Packed += delta in original point order)","geometry_mask_NAV_and_all_other_payload_keys_exact_unchanged":true}
	var ip: Dictionary=save_new(output+"/portal_source_inverse.bin",var_to_bytes(inverse))
	if not check((Time.get_ticks_usec()-began)<20000000,"TWENTY_SECOND_LIMIT"): finish();return
	finish({"payload":payload_pin,"inverse":ip,"fingerprints":fp,"source_domain":"one Market to_ancient_temple row and its exact repeated new_route_contracts.source_portal_row only","old_complete_publication_preserved":true})
