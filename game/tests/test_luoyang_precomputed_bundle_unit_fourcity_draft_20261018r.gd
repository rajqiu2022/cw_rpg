extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Four-city PUBLICATION compatibility; still only Gate/Market helper units.
## Original BDCE draft preserved. ROOT supplies remaining actual product pins.
## Does not prepare C/Field, rerun geometry, or rehash both legacy corpora.
const BUNDLE_UNIT_READY=false
const BUNDLE_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const BUNDLE_SHA="5e1e08d81f059448a0468687b9bfa78e9ab83bf2c09e09895b98a9160e7f0e49"
const INDEX_PATH="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const INDEX_SHA="PENDING_GENERATED_INDEX_SHA"
const PUBLICATION_PATH="PENDING_ACTUAL_PUBLICATION_RESULT_PATH"
const PUBLICATION_SHA="PENDING_ACTUAL_PUBLICATION_RESULT_SHA"
const UNIT_BASE="res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
const UNIT_BASE_SHA="a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895"
const EXPECTED_MANIFESTS={} # Exact two actual {id:{path,sha256}}, not inference.
const UNIT_IDS=[&"ch4_s0_luoyang_gate",&"ch4_s3_luoyang_market"]
var bundle_api: Variant
var children_started: int=0
var children_joined: int=0

func precheck() -> bool:
	if not check(BUNDLE_UNIT_READY and EXPECTED_MANIFESTS.size()==2,"NOTREADY until actual two-city publication and all exact pins supplied"): return false
	if not track(UNIT_BASE,UNIT_BASE_SHA) or not track(BUNDLE_PATH,BUNDLE_SHA) or not track(INDEX_PATH,INDEX_SHA) or not track(PUBLICATION_PATH,PUBLICATION_SHA): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	bundle_api=load(BUNDLE_PATH) as GDScript
	if not check(bundle_api!=null and bundle_api.resource_path==BUNDLE_PATH and OS.get_cmdline_user_args()==PackedStringArray([bundle_api.FLAG]),"Actual canonical helper, only exact bundle candidate flag"): return false
	var publication: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PUBLICATION_PATH))
	if not check(publication.get("passed")==true and publication.get("rows",[]).size()==4,"Actual successful original FOUR-city publication, not two-city runtime evidence relabelled"): return false
	var expected_ids: Array[String]=["ch4_s0_luoyang_gate","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s1_luoyang_yamen"]
	var actual_ids: Array[String]=[]
	for row: Dictionary in publication.rows:
		var id: String=String(row.get("scene_id",""))
		if not check(id in expected_ids and not id in actual_ids,"Four publication IDs complete and unique",id): return false
		actual_ids.append(id)
	expected_ids.sort();actual_ids.sort()
	return check(actual_ids==expected_ids,"Exact four published cities; UNIT_IDS remain only two representatives")

func _source_contract(id: StringName) -> Dictionary:
	var expected: Dictionary=EXPECTED_MANIFESTS.get(String(id),{})
	if not check(expected.size()==2 and track(expected.path,expected.sha256),"Exact generated authority manifest "+String(id)): return {}
	var manifest: Dictionary=bundle_api.manifest(id)
	if not check(not manifest.is_empty() and manifest.kind==bundle_api.KIND and manifest.scene_id==String(id) and bundle_api.equal(manifest.legacy_source_sha256,manifest.publication_source_first) and bundle_api.equal(manifest.legacy_source_sha256,manifest.publication_source_final),"Unchanged actual legacy full-source publication first/final, separate from new output leaves"): return {}
	var sources: Dictionary=manifest.legacy_source_sha256.duplicate(true)
	var outputs: Dictionary=bundle_api.source_paths(id)
	if not check(outputs.size()==6 and outputs.has(BUNDLE_PATH) and outputs.has(INDEX_PATH) and outputs.has(expected.path) and sources.get(BUNDLE_PATH)==BUNDLE_SHA,"SELF remains legacy; exactly five NEW index/manifest/three-artifact leaves"): return {}
	for path: String in outputs:
		if path==BUNDLE_PATH: continue
		if not check(not sources.has(path),"No output/legacy source-cycle or overwritten legacy field "+path): return {}
		var sha: String=INDEX_SHA if path==INDEX_PATH else (String(expected.sha256) if path==expected.path else String(manifest.artifacts.get(path,"")))
		if not track(path,sha): return {}
		sources[path]=sha
	if not check(not bundle_api.describe(id,sources).is_empty(),"Exact full source map contract accepted without repeat2.9GB legacy hashing"): return {}
	return {"sources":sources,"manifest":manifest}

func _run_joined(job: RefCounted) -> bool:
	var thread:=Thread.new()
	if not check(thread.start(Callable(job,"run"))==OK,"Start actual packet reader child"): return false
	children_started+=1
	while thread.is_alive() and Time.get_ticks_msec()<deadline: await process_frame
	if thread.is_alive(): job.request_cancel()
	thread.wait_to_finish();children_joined+=1
	return check(Time.get_ticks_msec()<deadline,"Fixed30s includes read/cancel/alljoin, no extension")

func _source_negatives(id: StringName,sources: Dictionary) -> bool:
	var legacy_key: String=String(bundle_api.manifest(id).legacy_source_sha256.keys()[0])
	var changed: Dictionary=sources.duplicate(true);changed.erase(legacy_key)
	if not check(bundle_api.describe(id,changed).is_empty(),"Missing genuine legacy leaf rejected"): return false
	changed=sources.duplicate(true);changed["res://QA_memory_only_extra_leaf"]="0".repeat(64)
	if not check(bundle_api.describe(id,changed).is_empty(),"Extra undeclared source leaf rejected"): return false
	changed=sources.duplicate(true);changed[legacy_key]="0".repeat(64)
	if not check(bundle_api.describe(id,changed).is_empty(),"Changed current legacy SHA rejected without disk fallback"): return false
	return check(bundle_api.describe(&"QA_wrong_city",sources).is_empty(),"Wrong city/authority rejected")

func _packet_negatives(raw: SceneScript,id: StringName,data: Dictionary,sources: Dictionary) -> bool:
	var changed: Dictionary=data.duplicate(true);changed.size=Vector2(3072,2048)
	if not check(bundle_api.materialize(raw,id,changed,sources)==null,"Vector2 replacing native Vector2i rejected, no numeric-domain normalization"): return false
	changed=data.duplicate(true);changed.record.canonical_scene_id="QA_memory_only_wrong_id"
	if not check(bundle_api.materialize(raw,id,changed,sources)==null,"Record identity edit rejected by full native packet binding"): return false
	changed=data.duplicate(true)
	var mask: PackedByteArray=changed.walk_bytes.duplicate();mask[0]=mask[0]^1;changed.walk_bytes=mask
	if not check(bundle_api.materialize(raw,id,changed,sources)==null,"One complete NAV RGBA byte change rejected"): return false
	changed=data.duplicate(true)
	var solids: Array=changed.solids
	if not check(not solids.is_empty() and solids[0] is PackedVector2Array and not solids[0].is_empty(),"Actual typed native polygon fixture exists"): return false
	var polygon: PackedVector2Array=solids[0].duplicate();polygon[0]+=Vector2(1,0);solids[0]=polygon;changed.solids=solids
	if not check(bundle_api.materialize(raw,id,changed,sources)==null,"One native solid vertex change rejected, no body reduction"): return false
	changed=data.duplicate(true);changed.erase("layout_storage")
	return check(bundle_api.materialize(raw,id,changed,sources)==null and bundle_api.materialize(raw,&"QA_wrong_city",data,sources)==null,"Missing complete native storage or wrong city rejected")

func _one(id: StringName,token: int) -> bool:
	var contract: Dictionary=_source_contract(id)
	if contract.is_empty(): return false
	var sources: Dictionary=contract.sources
	if not _source_negatives(id,sources): return false
	var job: RefCounted=bundle_api.new()
	if not check(not job.configure(0,id,sources) and job.configure(token,id,sources) and not job.configure(token+1,id,sources),"Nonzero fresh token only; repeated configure rejected"): return false
	if not check(job.packet(token,id).is_empty(),"Packet unavailable before actual run/join"): return false
	if not await _run_joined(job): job.release();return false
	if not check(not job.mark_joined(token+1,id) and job.packet(token+1,id).is_empty() and not job.mark_joined(token,&"QA_wrong_city") and job.mark_joined(token,id),"Actual join then exact token+city ownership; wrong owner cannot publish"): job.release();return false
	var data: Dictionary=job.packet(token,id)
	if not check(not data.is_empty() and data.kind==bundle_api.KIND and data.scene_id==String(id) and data.size is Vector2i and data.size==Vector2i(3072,2048) and data.walk_bytes is PackedByteArray and data.solids is Array,"Single decoded native packet with exact identity/type domains"): job.release();return false
	var raw: SceneScript=ResourceLoader.load("res://data/scenes/%s.tres"%String(id),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var materialized: SceneScript=bundle_api.materialize(raw,id,data,sources)
	if not check(materialized!=null and bundle_api.equal(bundle_api.storage(raw),data.input_storage) and bundle_api.equal(bundle_api.storage(raw.map_layout),data.input_layout_storage) and bundle_api.equal(bundle_api.storage(materialized),data.scene_storage) and bundle_api.equal(bundle_api.storage(materialized.map_layout),data.layout_storage),"Whole canonical input and independently loaded Scene/Layout ALL storage match actual native packet"): job.release();return false
	var mask:=Image.load_from_file(String(data.record.walk_path))
	if not check(mask!=null and not mask.is_compressed() and mask.get_size()==Vector2i(3072,2048),"Actual original published NAV image native dimensions"): job.release();return false
	mask.convert(Image.FORMAT_RGBA8)
	if not check(mask.get_data()==data.walk_bytes and bundle_api.bytes_sha(data.walk_bytes)==contract.manifest.mask_sha256,"Full original mask RGBA equals packet, not a count or few pixel samples"): job.release();return false
	if not _packet_negatives(raw,id,data,sources): job.release();return false
	job.release()
	if not check(job.packet(token,id).is_empty(),"Release removes accessible packet ownership"): return false
	var cancelled: RefCounted=bundle_api.new()
	if not check(cancelled.configure(token+100,id,sources),"Separate real precancel reader configured"): return false
	cancelled.request_cancel()
	if not await _run_joined(cancelled): cancelled.release();return false
	if not check(not cancelled.mark_joined(token+100,id) and cancelled.packet(token+100,id).is_empty() and not cancelled.error().is_empty(),"Precancel child fully joined and never exposes partial packet"): cancelled.release();return false
	cancelled.release()
	records.append({"kind":"ACTUAL_NATIVE_BUNDLE_HELPER_CONTRACT","scene_id":String(id),"legacy_sources":contract.manifest.legacy_source_sha256.size(),"runtime_sources":sources.size(),"added_output_leaves":5,"native_packet_decode_jobs":1,"precancel_jobs":1,"all_native_storage_exact":true,"full_mask_RGBA":true,"source_contract_not_fresh_legacy_disk_rehash":true,"no_C_transition_commit_exercised":true})
	return true

func exercise_cpu() -> bool:
	for index: int in UNIT_IDS.size():
		if not await _one(UNIT_IDS[index],7001+index): return false
	return check(children_started==children_joined and children_started==4,"All actual reader children joined, no outstanding helper child")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+30000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck(): complete=await exercise_cpu()
	records.append({"kind":"SCOPE","whole_ms":30000,"children_started":children_started,"children_joined":children_joined,"no_Field_GPU_performance_or_runtime_fullgeometry_credit":true,"published_city_count":4,"unit_representative_count":2,"Docks_Yamen_unit_or_performance_credit":false,"publication_legacy_firstfinal_reused_not_rehashed":true,"own_code_artifact_firstlast_SHA_required":true,"C_runtime_fullfirstfinal_acceptance_is_separate":true})
	finish("res://build/luoyang_bundle_unit_20261018r/%d_%d"%[OS.get_process_id(),began],began,complete,"R_NATIVE_BUNDLE_HELPER_ONLY_NO_SOURCE_OR_SAVE_MUTATION")
