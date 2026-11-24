extends SceneTree
## One fixed native packet readback, not geometry/Field/source collection.
const READY=true
const PACKET="res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/market/packet.bin"
const SHA="81e9f0a7cf7d006514ac4dccf00e8eefdd31bbef53f5c3a479b423c5ae0ad9a2"
const OUTPUT="res://build/luoyang_city_space_20261024b_source01/current_market_native_projection_ROOT_ACTUAL.json"

func _initialize() -> void: call_deferred("_run")
func plain(value: Variant,depth: int=0) -> Variant:
	if depth>=64: return {"unprojected_type":typeof(value),"depth_limit":true}
	if value is Dictionary:
		var out: Dictionary={}
		for key: Variant in value:
			if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME]: return {"unsupported_key_type":typeof(key)}
			out[String(key)]=plain(value[key],depth+1)
		return out
	if value is Array:
		var rows: Array=[]
		for item: Variant in value: rows.append(plain(item,depth+1))
		return rows
	if value is Vector2 or value is Vector2i: return {"native_type":typeof(value),"xy":[value.x,value.y]}
	if value is Rect2 or value is Rect2i: return {"native_type":typeof(value),"position":plain(value.position,depth+1),"size":plain(value.size,depth+1)}
	if value is PackedVector2Array:
		var points: Array=[]
		for point: Vector2 in value: points.append([point.x,point.y])
		return {"native_type":typeof(value),"points":points}
	if value is StringName: return {"native_type":TYPE_STRING_NAME,"text":String(value)}
	if typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]: return value
	return {"unprojected_type":typeof(value)}
func _run() -> void:
	if not READY: push_error("MARKET_READBACK_NOT_ROOT_FROZEN");quit(2);return
	if FileAccess.file_exists(OUTPUT): push_error("READBACK_OUTPUT_MUST_BE_NEW");quit(2);return
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(PACKET)
	var hash:=HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256)!=OK: quit(2);return
	hash.update(bytes)
	if hash.finish().hex_encode()!=SHA: push_error("FIXED_PACKET_SHA");quit(2);return
	var packet: Variant=bytes_to_var(bytes)
	if not packet is Dictionary or not packet.get("record") is Dictionary or packet.record.get("canonical_scene_id")!="ch4_s3_luoyang_market": push_error("FIXED_PACKET_MARKET_RECORD");quit(2);return
	var record: Dictionary=packet.record
	if not record.get("objects") is Array or record.objects.size()!=23: push_error("EXACT_CURRENT_NATIVE23");quit(2);return
	var selected: Dictionary={}
	for key: String in ["canonical_scene_id","objects","npc_stations","gameplay_slots","interaction_anchors","routes","entry_foot_px","return_foot_px","ordinary_actor_body_px","ordinary_actor_effective_height_px"]:
		if record.has(key): selected[key]=plain(record[key])
	var storage: Dictionary={}
	for kind: String in ["scene_storage","layout_storage"]:
		var raw: Variant=packet.get(kind)
		if not raw is Dictionary or not raw.get("fields") is Dictionary: push_error("WHOLE_STORAGE_WRAPPER_ABSENT");quit(2);return
		var fields: Dictionary={}
		for key: String in ["scene_id","player_spawn","npcs","portals","scene_objects","interactables","interaction_zones","design_size","visual_objects","walkable_mask_path","blockers"]:
			if raw.fields.has(key): fields[key]=plain(raw.fields[key])
		storage[kind]={"wrapper_schema":raw.get("schema"),"root_class":raw.get("root_class"),"root_script":raw.get("root_script"),"fields":fields}
	var report: Dictionary={"status":"CURRENT_FIXED_MARKET_NATIVE23_PROJECTION_ONLY","packet_path":PACKET,"packet_sha256":SHA,"packet_bytes":bytes.size(),"native_decode_count":1,"record":selected,"storage":storage,"no_walk_bytes_retained":true,"ResourceLoader_Image_Field_Physics_collector_calls":0,"no_geometry_checks_or_native_publication":true}
	var output:=FileAccess.open(OUTPUT,FileAccess.WRITE)
	if output==null: push_error("NEW_OUTPUT_OPEN");quit(2);return
	output.store_string(JSON.stringify(report,"\t",true,true));output.close()
	print("CURRENT_MARKET_NATIVE23_READBACK "+OUTPUT+" SHA "+FileAccess.get_sha256(OUTPUT));quit(0)
