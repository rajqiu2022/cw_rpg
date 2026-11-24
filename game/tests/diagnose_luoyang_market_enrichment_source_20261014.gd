extends "res://tests/test_luoyang_market_enrichment_key_retry2_20261014.gd"
## Read-only source diagnosis. No Field, prepare/materialize/router or adoption.
## Saved refusal is evidence, never changed into production/geometry PASS.
const PRIOR_KEY_PATH := "res://tests/test_luoyang_market_enrichment_key_retry2_20261014.gd"
const PRIOR_KEY_SHA := "3b044ad20054256c27ae373477ae251e800c14e4a5eac43cf4e289cfade7e463"
var differences: Array[Dictionary] = []

func _compare(a: Variant, b: Variant, location: String, depth: int = 0) -> void:
	if differences.size() >= 50 or depth > 24: return
	if typeof(a) != typeof(b): differences.append({"path":location,"kind":"TYPE","a_type":typeof(a),"b_type":typeof(b),"a":_values(a),"b":_values(b)}); return
	if a is Dictionary:
		for key: Variant in a:
			if not b.has(key): differences.append({"path":location+"/"+String(key),"kind":"MISSING_KEY"})
			else: _compare(a[key],b[key],location+"/"+String(key),depth+1)
		for key: Variant in b:
			if not a.has(key): differences.append({"path":location+"/"+String(key),"kind":"EXTRA_KEY"})
	elif a is Array:
		if a.size() != b.size(): differences.append({"path":location,"kind":"ARRAY_COUNT","a":a.size(),"b":b.size()})
		for index: int in mini(a.size(),b.size()): _compare(a[index],b[index],location+"/"+str(index),depth+1)
	elif a != b:
		differences.append({"path":location,"kind":"VALUE","a_type":typeof(a),"b_type":typeof(b),"a":_values(a),"b":_values(b)})

func _bytes_sha(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK: return "HASH_ERROR"
	return hash.finish().hex_encode()

func _import_probe(path: String, expected: Vector2i) -> Dictionary:
	var raw: Image = Image.load_from_file(path)
	var texture: Texture2D = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var decoded: Image = texture.get_image() if texture != null else null
	var result: Dictionary = {"path":path,"expected":expected,"source_sha":FileAccess.get_sha256(path),"raw_exists":raw != null,"texture_exists":texture != null,"import_exists":decoded != null,"same":false}
	if raw == null or decoded == null: return result
	result.raw_size = raw.get_size(); result.import_size = decoded.get_size()
	result.raw_format = raw.get_format(); result.import_format = decoded.get_format()
	result.compressed_before = decoded.is_compressed()
	if decoded.is_compressed():
		var error: Error = decoded.decompress()
		result.decompress_error = error
		if error != OK: return result
	raw.convert(Image.FORMAT_RGBA8); decoded.convert(Image.FORMAT_RGBA8)
	var a: PackedByteArray = raw.get_data()
	var b: PackedByteArray = decoded.get_data().slice(0,expected.x*expected.y*4)
	result.raw_bytes = a.size(); result.import_prefix_bytes = b.size()
	result.raw_rgba_sha = _bytes_sha(a); result.import_rgba_sha = _bytes_sha(b)
	result.same = raw.get_size() == expected and decoded.get_size() == expected and a == b
	if a != b:
		for index: int in mini(a.size(),b.size()):
			if a[index] != b[index]: result.first_byte_difference = {"index":index,"raw":a[index],"import":b[index]}; break
	return result

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"checkpoint held before source work")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	var started: int = Time.get_ticks_msec()
	deadline = started+60000
	output = "res://build/joint_world_luoyang_20261003_qa/market_source_diagnostic_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"new source-only evidence")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--diagnose-luoyang-market-enrichment-source" in args and not MARKET.FLAG in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args,"explicit source-only no candidate selection")
	_check(DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA,"actual GUI GPU/frozen engine/ordinary time")
	for path: String in MARKET_PINS:
		source_before[path] = _file(path)
		_check(MARKET_PINS[path].length() == 64 and source_before[path].sha256 == MARKET_PINS[path],"exact refused source unchanged "+path)
	for path: String in [PRIOR_KEY_PATH,get_script().resource_path]: source_before[path] = _file(path)
	_check(source_before[PRIOR_KEY_PATH].sha256 == PRIOR_KEY_SHA,"old refused driver immutable")
	for path: String in MARKET.source_paths(): source_before[path] = _file(path)
	var original: Dictionary = {}
	var config: Dictionary = {}
	var manifest: Dictionary = {}
	var composed: Dictionary = {}
	var packet: Dictionary = {}
	var components: Dictionary = {}
	var imports: Array[Dictionary] = []
	if failures == 0:
		var reader: RefCounted = RAW.new()
		original = reader.call("independent_record",StringName(MARKET_ID))
		reader.call("release"); reader = null
		config = MARKET.author(); manifest = MARKET.runtime_manifest()
		composed = MARKET.compose(original,config) if not original.is_empty() and not config.is_empty() else {}
		_save("original_raw_record.json",original)
		_save("composed_record.json",composed)
		_save("actual_manifest.json",manifest)
		components = {"original_nonempty":not original.is_empty(),"original_scene_id":original.get("canonical_scene_id"),"original_patch_sha":original.get("enclosure_patch_sha256"),"author_patch_sha":config.get("original_enclosure_manifest_sha"),"original_object_count":original.get("objects",[]).size(),"author_nonempty":not config.is_empty(),"manifest_nonempty":not manifest.is_empty(),"status":manifest.get("status"),"manifest_author_sha":manifest.get("author_sha256"),"expected_author_sha":MARKET.AUTHOR_SHA,"compose_nonempty":not composed.is_empty(),"objects_equal":MARKET.BASE._equal_value(composed.get("objects"),manifest.get("objects")),"gameplay_equal":MARKET.BASE._equal_value(original.get("gameplay_slots"),manifest.get("gameplay_slots")),"routes_equal":MARKET.BASE._equal_value(original.get("routes"),manifest.get("routes")),"floor_equal":original.get("ground_path") == manifest.get("ground_path"),"source_failures":[]}
		for path: Variant in manifest.get("asset_sha256",{}):
			if not MARKET._source(path,manifest.asset_sha256[path]): components.source_failures.append({"path":path,"expected":manifest.asset_sha256[path],"actual":FileAccess.get_sha256(path)})
		_compare(composed.get("objects"),manifest.get("objects"),"objects")
		_compare(original.get("gameplay_slots"),manifest.get("gameplay_slots"),"gameplay_slots")
		_compare(original.get("routes"),manifest.get("routes"),"routes")
		_save("comparison_components.json",{"components":components,"first_50_differences":differences})
		packet = MARKET.read_after_original(original)
		_save("actual_read_packet.json",packet)
		var seen: Dictionary = {}
		for object: Dictionary in composed.get("objects",[]):
			if not object.get("market_enrichment_object",false) or seen.has(object.texture): continue
			seen[object.texture] = true
			imports.append(_import_probe(String(object.texture),Vector2i(MARKET.BASE._vec(object.source_size_px))))
			_save("actual_imports.json",imports)
		imports.append(_import_probe(MARKET.ROOT+"walk.png",Vector2i(3072,2048)))
		_save("actual_imports.json",imports)
	_check(Time.get_ticks_msec() < deadline,"source diagnostic within shared60s, no Field")
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot and bridge.call("is_checkpoint_saves_suspended") == true,"read-only source/current15save/slot unchanged")
	var result: Dictionary = {"scope":"READ_ONLY_MARKET_REFUSAL_CAUSE_NOT_PRODUCTION_PASS","diagnostic_complete":failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"actual_packet_error":packet.get("error",""),"production_packet_accepted":not packet.is_empty() and not packet.has("error") and packet.get("record") is Dictionary,"components":components,"first_50_differences":differences,"actual_imports":imports,"Field_entered":false,"formal_approved":false,"audio_credit":false,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"exactticks_guard":"ROOT_OUTER_REQUIRED"}
	_save("result.json",result)
	print("MARKET_SOURCE_DIAGNOSTIC_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures)+" packet_error="+String(packet.get("error","")))
	quit(0 if failures == 0 else 1)
