extends SceneTree
## ROOT-only finite delta publication. Does not prepare C or overwrite any NAV.
const R=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const G=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const BUDGET_MSEC=30000
const IMPORTS={"res://build/luoyang_district_life_import_20261016f_system01/result_111036.json":"a7a6ccc8d472874b5584d91f4e43be9b5913fa4b018c9241386dbb97c82cfef5","res://build/luoyang_district_stock_import_20261016f_system01/result_96136.json":"b65cc3fb878da835b419012b7b24c96a14c2714a5bc0f54f4bef857b9c93617d"}
const PARAMS={"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0}
var _started: int=0
var _output: String=""
var _error: String=""
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message
	return ok
func _cancel() -> bool: return Time.get_ticks_msec()-_started>BUDGET_MSEC
func _write(path: String,data: Dictionary) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return _require(false,"OUTPUT_WRITE:"+path)
	file.store_string(JSON.stringify(data,"\t",true,true)); file.close(); return true
func _sha_sources(paths: Dictionary) -> Dictionary:
	var out: Dictionary={}
	for path: String in paths:
		if _cancel() or not path.begins_with("res://") or ".." in path or not FileAccess.file_exists(path): return {}
		out[path]=FileAccess.get_sha256(path)
	return out
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"):
		push_error("CHECKPOINT_SUSPEND_API_UNAVAILABLE"); quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec()
	_output="res://build/luoyang_district_life_publication_20261016f/"+str(OS.get_process_id())+"_"+str(Time.get_ticks_msec())
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))!=OK: quit(1); return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(R.AUTHOR_PATH))
	var result: Dictionary={"passed":false,"error":"","rows":{},"budget_msec":BUDGET_MSEC,"scope":"NEW_DELTA_ONLY_NOT_FIELD_OR_FORMAL","output":_output}
	if not _require(data is Dictionary and data.get("status")=="READY_AUTHORED_DISTRICT_LIFE","AUTHOR_NOT_READY"): _finish(result); return
	var paths: Dictionary={R.AUTHOR_PATH:true,"res://scripts/city/luoyang_district_life_geometry_20261016f.gd":true,"res://scripts/city/luoyang_district_life_crowd_20261016f.gd":true,"res://scripts/city/luoyang_district_life_fade_20261016f.gd":true,"res://scripts/dev/publish_luoyang_district_life_retry1_20261016f.gd":true,"res://data/maps/luoyang_district_life_20261016f/component_source_author.json":true,"res://data/maps/luoyang_district_life_20261016f/import_copy_receipt.json":true}
	paths.merge(R.CROWD.source_paths())
	var proofs: Dictionary={}
	for report_path: String in IMPORTS:
		if not _require(FileAccess.get_sha256(report_path)==IMPORTS[report_path],"IMPORT_REPORT_SHA:"+report_path): _finish(result); return
		var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(report_path))
		if not _require(report is Dictionary and report.get("passed")==true and report.get("failures",[]).is_empty(),"IMPORT_NOT_PASSED"): _finish(result); return
		paths[report_path]=true
		paths[report_path.get_base_dir()+"/verify_import.gd"]=true
		for row: Dictionary in report.rows:
			if not _require(not proofs.has(row.texture) and row.get("full_rgba_exact")==true and row.get("params23")==true,"IMPORT_DUPLICATE_OR_RGBA"): _finish(result); return
			proofs[row.texture]=row
			for pair: Array in [[row.texture,row.source_sha256],[row.import_path,row.import_sha256],[row.compiled_path,row.compiled_sha256]]:
				if not _require(FileAccess.get_sha256(pair[0])==pair[1],"COPIED_IMPORT_LEAF_CHANGED:"+String(pair[0])): _finish(result); return
				paths[pair[0]]=true
			var config:=ConfigFile.new()
			if not _require(config.load(row.import_path)==OK and config.get_section_keys("params").size()==23,"IMPORT_CONFIG"): _finish(result); return
			for key: String in PARAMS:
				if not _require(config.get_value("params",key,null)==PARAMS[key],"IMPORT_PARAM:"+key): _finish(result); return
	var used_textures: Dictionary={}
	for asset: Dictionary in data.assets.values():
		if not _require(proofs.has(asset.texture) and not used_textures.has(asset.texture),"EXACT_TEXTURE_SET"): _finish(result); return
		used_textures[asset.texture]=true
		if String(asset.get("original_texture","")).begins_with("res://"): paths[asset.original_texture]=true
		if String(asset.get("original_source","")).begins_with("res://"): paths[asset.original_source]=true
	if not _require(proofs.size()==used_textures.size() and proofs.size()==6,"SIX_DISTINCT_TEXTURES"): _finish(result); return
	for id: String in data.districts:
		var spec: Dictionary=data.districts[id]
		for key: String in ["parent_manifest","parent_scene","parent_walk"]:
			if not _require(FileAccess.get_sha256(spec[key].path)==spec[key].sha256,"FIXED_PARENT_SHA:"+id+":"+key): _finish(result); return
			paths[spec[key].path]=true
		var parent_layout: String=String(spec.parent_scene.path).get_base_dir()+"/layout.tres"
		paths[parent_layout]=true
	# The original NPC native strips/imports are reused, not newly generated.
	for path: String in paths.keys():
		if not path.ends_with(".png"): continue
		var imported: String=path+".import"
		if not FileAccess.file_exists(imported): continue
		paths[imported]=true
		var cfg:=ConfigFile.new()
		if not _require(cfg.load(imported)==OK,"SOURCE_IMPORT_UNREADABLE"): _finish(result); return
		var compiled: String=String(cfg.get_value("remap","path",""))
		if not _require(compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex"),"SOURCE_IMPORT_REMAP"): _finish(result); return
		paths[compiled]=true
	var first:=_sha_sources(paths); result["source_first"]=first
	if not _require(first.size()==paths.size(),"SOURCE_FIRST"): _finish(result); return
	for id: StringName in R.IDS:
		var spec: Dictionary=data.districts[String(id)]
		var mask:=Image.load_from_file(spec.parent_walk.path)
		if mask!=null: mask.convert(Image.FORMAT_RGBA8)
		var audit:=G.audit(data,id,mask,_cancel)
		result.rows[String(id)]=audit
		if not _require(audit.get("passed")==true,"DISTRICT_GEOMETRY:"+String(id)+":"+JSON.stringify(audit)): _finish(result); return
		mask=null
	var last:=_sha_sources(paths); result["source_final"]=last
	if not _require(not _cancel() and G._c()._equal_value(first,last),"SOURCE_FINAL_OR_BUDGET"): _finish(result); return
	var proof_path: String=_output+"/geometry_proof.json"
	var proof: Dictionary={"passed":true,"status":"BOUNDED_CPU_NEW_DELTA_PROOF_NOT_RUNTIME","author_sha256":FileAccess.get_sha256(R.AUTHOR_PATH),"source_sha256":first,"rows":result.rows,"budget_msec":BUDGET_MSEC,"elapsed_msec":Time.get_ticks_msec()-_started,"old_nav_unchanged":true}
	if not _write(proof_path,proof): _finish(result); return
	var bound_sources: Dictionary=first.duplicate(true); bound_sources[proof_path]=FileAccess.get_sha256(proof_path)
	var binding_candidate: Dictionary={"status":"READY_SOURCE_BOUND_DISTRICT_LIFE","author_sha256":proof.author_sha256,"cpu_proof_path":proof_path,"cpu_proof_sha256":bound_sources[proof_path],"cpu_audit":result.rows,"texture_proofs":proofs,"source_sha256":bound_sources,"limitations":["CPU proof is not Field/Physics/visual acceptance.","No parent Scene/layout/record/NAV was edited."]}
	var candidate_path: String=_output+"/binding_candidate.json"
	if not _write(candidate_path,binding_candidate): _finish(result); return
	result["binding_candidate_path"]=candidate_path; result["binding_candidate_sha256"]=FileAccess.get_sha256(candidate_path)
	result["geometry_proof_path"]=proof_path; result["geometry_proof_sha256"]=bound_sources[proof_path]
	result.passed=true; _finish(result)
func _finish(result: Dictionary) -> void:
	result["elapsed_msec"]=Time.get_ticks_msec()-_started; result.error=_error
	if not _write(_output+"/result.json",result): result.passed=false
	print(JSON.stringify({"passed":result.passed,"error":_error,"result":_output+"/result.json","elapsed_msec":result.elapsed_msec}))
	quit(0 if result.passed else 1)
