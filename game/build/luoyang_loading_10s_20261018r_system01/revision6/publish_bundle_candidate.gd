extends SceneTree
## ROOT-only GUI compiler. No Field/NPC/Player or gameplay state transitions.
## Helper and C must be source-frozen/deployed before this compile. Generated
## bootstrap code is a new authority leaf, not a circular authoring input pin.
const CITY="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const HELPER="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const INDEX="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const SELF="res://build/luoyang_loading_10s_20261018r_system01/revision6/publish_bundle_candidate.gd"
const LIMIT_MS=180000
var _failure: String=""
var _rows: Array=[]
var _started: int=0
var _folder: String=""
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	call_deferred("_run")
func _require(ok: bool,message: String) -> bool:
	if not ok and _failure.is_empty(): _failure=message
	return ok
func _write_new(path: String,bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path): return _require(false,"Refuse overwrite: "+path)
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return _require(false,"Write refused: "+path)
	file.store_buffer(bytes); file.close()
	return true
func _facts(paths: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths: result[path]=FileAccess.get_sha256(path)
	return result
func _save_resource(resource: Resource,path: String) -> bool:
	return _require(not FileAccess.file_exists(path),"Refuse resource overwrite: "+path) and _require(ResourceSaver.save(resource,path)==OK,"Binary resource save refused: "+path)
func _serialization_preflight(helper: Variant) -> bool:
	# Catch any native dictionary/Vector2/typed-array roundtrip issue before
	# spending complete cold validations on the four cities. Preserve this evidence.
	var sample:=WalkableMapLayout.new()
	sample.visual_objects.assign([{"id":"native_roundtrip","physical_center_px":[1742.3499755859375],"collision_size_px":[20.400001525878906,15.300000190734863],"native":Vector2(20.400001525878906,15.300000190734863)}])
	sample.portals.assign([{"target_pos":Vector2(.921484375,.626953125)}])
	sample.set_meta("packed",PackedByteArray([0,17,128,255]))
	var path: String=_folder+"/native_preflight.res"
	if not _save_resource(sample,path): return false
	var readback:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(readback!=null and helper.equal(helper.storage(sample),helper.storage(readback)),"Binary native all-storage preflight differs"): return false
	# The actual Yamen external DialogScript/typed DialogNodes must serialize
	# safely before spending any of the four complete authoring pipelines.
	var yamen:=ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(yamen!=null and yamen.on_enter_dialog!=null,"Actual Yamen dialog preflight missing"): return false
	var snapshot: Dictionary=helper.storage(yamen)
	if not _require(helper._plain(snapshot),"Actual Yamen Resource graph is not safe plain storage"): return false
	var native_bytes: PackedByteArray=var_to_bytes(snapshot)
	if not _require(helper.equal(snapshot,bytes_to_var(native_bytes)),"Actual Yamen safe storage native domain differs"): return false
	var yamen_path: String=_folder+"/actual_yamen_preflight.res"
	if not _save_resource(yamen,yamen_path): return false
	var yamen_back:=ResourceLoader.load(yamen_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	return _require(yamen_back!=null and helper.equal(snapshot,helper.storage(yamen_back)),"Actual Yamen Dialog Resource graph binary readback differs")
func _compile(city: Variant,helper: Variant,id: StringName) -> Dictionary:
	var loading: Node=root.get_node("LoadingManager")
	var token: int=loading.call("begin_field_preparation","编译洛阳运行资源")
	if not _require(token>0,"Compiler Loading owner unavailable"): return {}
	var raw:=ResourceLoader.load("res://data/scenes/%s.tres"%String(id),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(raw!=null,"Compiler exact canonical input unavailable"): return {}
	var prepared: SceneScript=await city.resolve_scene_for_live_transition(raw,token)
	if not _require(prepared!=null,"Original complete pipeline rejected: "+str(city.errors())): return {}
	if not _require(await city.finalize_live_transition_sources(token,id),"Original complete full-source finalization rejected"): return {}
	var proof: Dictionary=city._transition_validation
	if not _require(proof.get("token")==token and proof.get("id")==id and proof.get("scene")==prepared and proof.get("source_scene")==raw and proof.get("sources_finalized")==true and not proof.has("proof_kind"),"Compiler did not execute the original authoring path"): return {}
	var closure: Dictionary=city._transition_sources(raw,false)
	if not _require(closure.size()==proof.sources.size() and not closure.has(helper.INDEX) and proof.sources.has(HELPER) and proof.sources.has(CITY),"Compiler legacy closure / new bootstrap separation differs"): return {}
	var mask: Image=city._masks.get(String(id))
	var record: Dictionary=city._records.get(String(id),{})
	var solids: Array=city._solids.get(String(id),[])
	if not _require(mask!=null and mask.get_size()==helper.SIZE and mask.get_format()==Image.FORMAT_RGBA8 and city._equal_value(record,proof.record) and city._equal_value(solids,proof.solids) and helper.bytes_sha(mask.get_data())==proof.mask_sha,"Original final Scene/record/mask/solids receipt differs"): return {}
	var payload: Dictionary={"kind":helper.KIND,"scene_id":String(id),"record":record.duplicate(true),"solids":solids.duplicate(true),"walk_bytes":mask.get_data(),"mask_sha":proof.mask_sha,"size":helper.SIZE,"scene_storage":helper.storage(prepared),"layout_storage":helper.storage(prepared.map_layout),"input_storage":helper.storage(raw),"input_layout_storage":helper.storage(raw.map_layout),"scene_script":prepared.get_script().resource_path,"layout_script":prepared.map_layout.get_script().resource_path}
	if not _require(helper._plain(payload),"Native payload unexpectedly contains Object/Resource"): return {}
	var output: String=helper.ROOT+String(id)
	if not _require(DirAccess.make_dir_recursive_absolute(output)==OK,"Compiler output mkdir refused"): return {}
	var layout_copy:=prepared.map_layout.duplicate(true) as WalkableMapLayout
	if not _save_resource(layout_copy,output+"/layout.res"): return {}
	var actual_layout:=ResourceLoader.load(output+"/layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(actual_layout!=null and helper.equal(payload.layout_storage,helper.storage(actual_layout)),"Published binary layout all-storage differs"): return {}
	var scene_copy:=prepared.duplicate(true) as SceneScript
	scene_copy.map_layout=actual_layout
	if not _save_resource(scene_copy,output+"/scene.res"): return {}
	var actual_scene:=ResourceLoader.load(output+"/scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _require(actual_scene!=null and helper.equal(payload.scene_storage,helper.storage(actual_scene)) and actual_scene.map_layout!=null and helper.equal(payload.layout_storage,helper.storage(actual_scene.map_layout)),"Published binary Scene/layout all-storage differs"): return {}
	var bytes: PackedByteArray=var_to_bytes(payload)
	if not _require(bytes.size()<=helper.MAX_PACKET_BYTES,"Native packet exceeds fixed runtime bound") or not _write_new(output+"/packet.bin",bytes): return {}
	var packet_back: Variant=bytes_to_var(FileAccess.get_file_as_bytes(output+"/packet.bin"))
	if not _require(helper.equal(payload,packet_back) and var_to_bytes(packet_back)==bytes,"Published native packet full readback / exact binary domain differs"): return {}
	# These are the actual complete first/final sources of this compiler run,
	# not a copy of old artifact proofs or a claim of runtime geometry execution.
	var source_after: Dictionary=await city._live_source_hashes(raw,token)
	if not _require(city._live_source_token==token and city._equal_value(source_after,proof.sources),"Complete compiler source map changed while saving artifacts"): return {}
	var artifacts: Dictionary={}
	for suffix: String in ["scene.res","layout.res","packet.bin"]: artifacts[output+"/"+suffix]=FileAccess.get_sha256(output+"/"+suffix)
	var manifest: Dictionary={"kind":helper.KIND,"scene_id":String(id),"publication_full_source_finalized":true,"geometry_proof_basis":"FULL_ORIGINAL_PIPELINE_AT_PUBLICATION_NOT_RERUN_AT_RUNTIME","legacy_source_sha256":proof.sources.duplicate(true),"publication_source_first":proof.sources.duplicate(true),"publication_source_final":source_after,"artifacts":artifacts,"mask_sha256":proof.mask_sha,"compiler_path":SELF,"compiler_sha256":FileAccess.get_sha256(SELF),"canonical_source_path":raw.resource_path,"canonical_source_sha256":proof.sources.get(raw.resource_path),"all_storage_binary_native_roundtrip":true,"no_Field_or_dynamic_task_snapshot":true,"body_px":[34,24]}
	if not _write_new(output+"/manifest.json",JSON.stringify(manifest,"\t",true,true).to_utf8_buffer()): return {}
	var entry: Dictionary={"manifest_path":output+"/manifest.json","manifest_sha256":FileAccess.get_sha256(output+"/manifest.json")}
	_rows.append({"scene_id":String(id),"legacy_source_count":proof.sources.size(),"entry":entry,"artifacts":artifacts,"mask_sha256":proof.mask_sha,"full_original_pipeline":true,"same_complete_source_first_final":true,"all_native_storage_exact":true})
	city.end_transition_validation(token)
	city.clear_resident_receipt()
	await loading.call("finish_field_preparation",token)
	return entry
func _run() -> void:
	_started=Time.get_ticks_msec()
	_folder="res://build/luoyang_runtime_bundle_publication_20261018r/%d_%d"%[OS.get_process_id(),_started]
	DirAccess.make_dir_recursive_absolute(_folder)
	var helper: Variant=load(HELPER)
	var city: Variant=load(CITY)
	var entry_map: Dictionary={}
	_require(DisplayServer.get_name()!="headless","Use ROOT GUI renderer for original material/image checks")
	_require(helper is GDScript and city is GDScript,"Frozen implementation scripts must be deployed before compiling")
	if _failure.is_empty():
		_require(helper.forced_authoring() and not helper.FORMAL_ENABLED and not helper.requested(&"ch4_s0_luoyang_gate"),"Explicit force-authoring and formalfalse required")
		_require(not FileAccess.file_exists(INDEX),"Bootstrap index must be absent before one-shot compilation")
	if _failure.is_empty() and _serialization_preflight(helper):
		for id: StringName in helper.IDS:
			var entry: Dictionary=await _compile(city,helper,id)
			if entry.is_empty(): break
			entry_map[String(id)]=entry
			if not _require(Time.get_ticks_msec()-_started<LIMIT_MS,"Original compiler180s finite limit"): break
	if _failure.is_empty() and _require(entry_map.size()==4,"Exactly Gate, Market, Docks and Yamen must be fully compiled"):
		var code: String="extends RefCounted\n## ROOT-reviewed generated manifest authority; separate from legacy input closure.\nconst FORMAL_ENABLED=false\nconst ENTRIES="+JSON.stringify(entry_map,"\t",true,true)+"\nstatic func entries() -> Dictionary: return ENTRIES.duplicate(true)\nstatic func formal_enabled() -> bool: return FORMAL_ENABLED\n"
		_write_new(INDEX,code.to_utf8_buffer())
	var result: Dictionary={"passed":_failure.is_empty(),"error":_failure,"rows":_rows,"elapsed_ms":Time.get_ticks_msec()-_started,"compiler_sha256":FileAccess.get_sha256(SELF),"implementation_sources":_facts({CITY:true,HELPER:true}),"bootstrap_path":INDEX,"bootstrap_sha256":FileAccess.get_sha256(INDEX) if FileAccess.file_exists(INDEX) else "ABSENT","scope":"PUBLICATION_ONLY_ORIGINAL_FULL_PIPELINE_FOUR_CITIES_NOT_RUNTIME_OR_PERFORMANCE_ACCEPTANCE"}
	# Failure must still produce a complete nonzero report, independently of _failure.
	_write_new(_folder+"/result.json",JSON.stringify(result,"\t",true,true).to_utf8_buffer())
	print(JSON.stringify({"passed":result.passed,"error":_failure,"rows":_rows.size(),"result":_folder+"/result.json"}))
	quit(0 if _failure.is_empty() else 1)
