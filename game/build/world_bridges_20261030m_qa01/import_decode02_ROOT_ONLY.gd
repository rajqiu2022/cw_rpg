extends "res://build/world_bridges_20261030m_qa01/import_decode_ROOT_ONLY.gd"
## Size/RGBA residual; original 61/1 report and original script remain untouched.
const FIRST := "res://build/world_bridges_20261030m_qa01/import_decode_actual/133416/result.json"
const FIRST_SHA := "d26d7c7387347e4f6afde99d11d61554bd1bbf71d8d10b818b9c6eb700a30405"
const FIXTURE_SHA := "011f8aa74c2d5668755f36337ad97bf8b48355a70d5982ff4f27fd2d6ba61198"

func _run() -> void:
	directory="res://build/world_bridges_20261030m_qa01/import_decode02_actual/"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	if not need(suspended and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"EARLIEST_CHECKPOINT_SUSPEND_NEW_OWNED_PROCESS"):finish();return
	if not need(FileAccess.get_sha256(FIRST)==FIRST_SHA and FileAccess.get_sha256(FIXTURE)==FIXTURE_SHA,"EXACT_FIRST_FAIL_AND_FROZEN_INPUT_FIXTURE"):finish();return
	var first: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIRST))
	if not need(first.get("passed")==false and int(first.get("checks",0))==61 and first.get("errors",[]).size()==1 and String(first.errors[0])=="ACTUAL_NATIVE_PNG_TEXTURE_IMAGE_SIZE:bridge_00","ONLY_SIZE_RESIDUAL_FIRST_FAIL_RETAINED"):finish();return
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	pins=raw.pins;sources_first=facts()
	var same: bool=sources_first.size()==first.first_sources.size()
	for path: String in pins:
		var before: Dictionary=first.first_sources.get(path,{})
		same=same and String(sources_first[path].sha256)==String(before.get("sha256","")) and int(sources_first[path].bytes)==int(before.get("bytes",-1)) and int(sources_first[path].mtime_seconds)==int(before.get("mtime_seconds",-1))
	if not need(same,"FIRST61_PREFIX_INPUT_SHAS_BYTES_MTIME_STILL_EXACT_INHERIT_NOT_RETEST_PARAMS00"):finish();return
	records.append({"inherited_first_result":FIRST,"sha256":FIRST_SHA,"checks":first.checks,"first_errors_retained":first.errors,"bridge00_import23params_mip0_success_inherited":true,"no_world_or_save_created":true})
	for row: Dictionary in raw.textures:
		if not one_texture(row):finish();return
	for path: String in raw.parse_scripts:
		var script: Script=ResourceLoader.load(path,"Script",ResourceLoader.CACHE_MODE_REUSE) as Script
		if not need(script!=null and script.can_instantiate(),"REMAINING_SCRIPT_LOAD_CAN_INSTANTIATE_ONLY_NOT_NEW:"+path):finish();return
		records.append({"parsed_script":path,"sha256":FileAccess.get_sha256(path),"instance_created":false})
	finish()

func one_texture(row: Dictionary) -> bool:
	var path: String=String(row.path)
	var texture: Texture2D=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	var source:=Image.new();var loaded: Error=source.load(path)
	var decoded: Image=texture.get_image() if texture!=null else null
	var expected: Array=row.size
	var observed: Dictionary={"id":row.id,"phase":"actual_native_size_before_assertion","expected_json":expected,"expected_component_types":[],"texture_width":texture.get_width() if texture!=null else -1,"texture_height":texture.get_height() if texture!=null else -1,"source_width":source.get_width(),"source_height":source.get_height(),"decoded_width":decoded.get_width() if decoded!=null else -1,"decoded_height":decoded.get_height() if decoded!=null else -1,"source_load_error":int(loaded),"integer_component_comparison_no_array_equality":true}
	for value: Variant in expected:observed.expected_component_types.append(type_string(typeof(value)))
	records.append(observed)
	var valid_expected: bool=expected.size()==2
	for value: Variant in expected:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT]:valid_expected=false;continue
		var number: float=float(value)
		valid_expected=valid_expected and is_finite(number) and number>0 and number<=32768 and number==floor(number)
	if not need(valid_expected and loaded==OK and texture!=null and decoded!=null,"VALID_INTEGER_JSON_NATIVE_SIZE_AND_REAL_LOAD:"+String(row.id)):return false
	var width: int=int(expected[0]);var height: int=int(expected[1])
	if not need(texture.get_width()==width and texture.get_height()==height and source.get_width()==width and source.get_height()==height and decoded.get_width()==width and decoded.get_height()==height,"ACTUAL_INTEGER_DIMENSIONS_ALL_THREE_COMPONENTWISE:"+String(row.id)):return false
	var config:=ConfigFile.new();var config_ok: bool=config.load(path+".import")==OK
	var actual_params: Dictionary={}
	if config_ok:
		for key: String in config.get_section_keys("params"):actual_params[key]=config.get_value("params",key)
	# Only bridge00 reached these assertions in first61. Other four were not run.
	if String(row.id)!="bridge_00":
		var params_ok: bool=config_ok and actual_params.size()==PARAMS.size()
		for key: String in PARAMS:params_ok=params_ok and actual_params.get(key)==PARAMS[key]
		params_ok=params_ok and String(config.get_value("remap","path",""))==String(row.compiled_path) and String(config.get_value("deps","source_file",""))==path
		if not need(params_ok,"REMAINING_UNRUN_IMPORT_PARAMS_AND_URI_COMPACT:"+String(row.id)):return false
	var mipmap_count: int=decoded.get_mipmap_count()
	if String(row.id)!="bridge_00":
		if not need(mipmap_count==0 and not decoded.has_mipmaps() and not source.has_mipmaps(),"REMAINING_UNRUN_MIP0:"+String(row.id)):return false
	decoded.convert(Image.FORMAT_RGBA8);source.convert(Image.FORMAT_RGBA8)
	var source_bytes: PackedByteArray=source.get_data();var decoded_bytes: PackedByteArray=decoded.get_data()
	var full_exact: bool=source_bytes==decoded_bytes
	var source_rgba: String=rgba_sha(source_bytes);var imported_rgba: String=rgba_sha(decoded_bytes)
	records.append({"id":row.id,"resource":{"path":path,"sha256":FileAccess.get_sha256(path),"import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":row.compiled_path,"compiled_sha256":FileAccess.get_sha256(String(row.compiled_path)),"size":[width,height],"full_RGBA_exact":full_exact,"mipmap_count":mipmap_count},"source_RGBA8_sha256":source_rgba,"imported_RGBA8_sha256":imported_rgba,"RGBA8_bytes":source_bytes.size(),"actual_import_params":actual_params,"source_version":row.version,"texture_resource_path":texture.resource_path,"bridge00_import_param_assertions_inherited_only":String(row.id)=="bridge_00"})
	return need(source_bytes.size()==width*height*4 and full_exact and source_rgba==String(row.rgba_sha256),"EVERY_RGBA8_BYTE_IMPORTED_SOURCE_AND_ART_HASH_EXACT:"+String(row.id))
