extends SceneTree
## ROOT-only main-project readback of the two NEW copied artifacts. No C/Field.
const PREPARED="res://build/luoyang_spacing_walk_import_20261018q_system01/prepared.json"
const PREPARED_SHA="4c86409c68c8a959778132a7e3fa2be827e50b0e1637d4378ada3ac764f8bb28"
const REPORT="res://build/luoyang_spacing_walk_import_20261018q_system01/result_101424.json"
const REPORT_SHA="7422f8f6fed56ae2b0eb979baebf8b771f12f1bade83a7d4595a69ec92a252d9"
var failures: Array=[]
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	call_deferred("_run")
func _require(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(bytes); return hash.finish().hex_encode()
func _run() -> void:
	var started: int=Time.get_ticks_msec()
	_require(FileAccess.get_sha256(PREPARED)==PREPARED_SHA,"prepared_exact")
	_require(FileAccess.get_sha256(REPORT)==REPORT_SHA,"actual_isolated_report_exact")
	var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREPARED))
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(REPORT))
	var row: Dictionary={}
	if prepared is Dictionary and report is Dictionary and report.get("passed")==true and report.get("rows",[]).size()==1:
		row=report.rows[0]
		_require(row.get("texture")==prepared.texture and row.get("full_rgba_exact")==true and row.get("params23")==true and row.get("no_mipmaps")==true,"isolated_proof_contract")
		for pair: Array in [[row.texture,row.source_sha256],[row.import_path,row.import_sha256],[row.compiled_path,row.compiled_sha256]]:
			_require(FileAccess.get_sha256(pair[0])==pair[1],"game_actual_file_sha:"+String(pair[0]))
		var config:=ConfigFile.new()
		if config.load(row.import_path)!=OK:
			failures.append("game_import_config")
		else:
			_require(config.get_section_keys("params").size()==23,"exact23params")
			for key: String in prepared.params23: _require(config.get_value("params",key,null)==prepared.params23[key],"game_param:"+key)
			_require(config.get_value("remap","path","")==row.compiled_path and config.get_value("deps","source_file","")==row.texture,"game_remap_source")
			var dest: Variant=config.get_value("deps","dest_files",null)
			_require((dest is Array or dest is PackedStringArray) and dest.size()==1 and String(dest[0])==row.compiled_path,"game_single_native_ctex")
		var raw: Image=Image.load_from_file(row.texture)
		var texture:=ResourceLoader.load(row.texture,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var direct:=CompressedTexture2D.new()
		var direct_error: int=direct.load(row.compiled_path)
		var imported: Image=texture.get_image() if texture!=null else null
		var native: Image=direct.get_image() if direct_error==OK else null
		if raw!=null and imported!=null and native!=null:
			raw.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8); native.convert(Image.FORMAT_RGBA8)
			_require(raw.get_size()==Vector2i(3072,2048) and imported.get_size()==raw.get_size() and native.get_size()==raw.get_size(),"game_native_dimensions")
			_require(raw.get_data()==imported.get_data() and raw.get_data()==native.get_data() and _sha(raw.get_data())==prepared.rgba_sha256,"game_all_RGBA_equal_CPU")
			_require(not raw.has_mipmaps() and not imported.has_mipmaps() and not native.has_mipmaps(),"game_all_native_no_mip")
		else: failures.append("game_native_texture_image_missing")
		texture=null; direct=null; raw=null; imported=null; native=null
	else: failures.append("prepared_or_actual_report_schema")
	_require(Time.get_ticks_msec()-started<30000,"original30s_budget")
	var result: Dictionary={"passed":failures.is_empty(),"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"script_sha256":FileAccess.get_sha256("res://build/luoyang_spacing_20261018q_source01/check_game_walk_readback.gd"),"isolated_report_sha256":REPORT_SHA,"row":row,"scope":"ACTUAL_GAME_NEW_WALK_READBACK_ONLY_NOT_FIELD_OR_PHYSICS"}
	var output: String="res://build/luoyang_spacing_20261018q_source01/game_readback_"+str(OS.get_process_id())+".json"
	if FileAccess.file_exists(output): quit(1); return
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(result,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":result.passed,"output":output,"failures":failures})); quit(0 if failures.is_empty() else 1)
