extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Yamen-only B continuation after exact metadata successor promotion.
## Prior B86968 remains whole FAIL; three city maps are reused evidence, not rerun.
## Both indexes stay false. No A/geometry/Field/GPU execution.
const ADMISSION_READY := true
const ADMISSION_CONTRACT := "res://tests/fixtures/luoyang_t_yamen_collector_continuation_20261019u.json"
const ADMISSION_SHA := "b238464122f1891cf22bbe0779a1e8ad2f6dbf63309b76ba2ec6fcc3532fca46"
const ADMISSION_MS := 60000
const C := preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const B := preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const B_INDEX := "res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const R_INDEX := "res://scripts/city/luoyang_layout_room_index_20261018t.gd"
const CITY_IDS := ["ch4_s1_luoyang_yamen"]
var admission: Dictionary={}
var actual_A: Dictionary={}
var migration: Dictionary={}

func _same_keys(left: Dictionary,right: Dictionary) -> bool:
	if left.size()!=right.size(): return false
	for path: String in left:
		if not right.has(path): return false
	return true

func _map_diff(actual: Dictionary,expected: Dictionary) -> Dictionary:
	var missing: Array[String]=[];var extra: Array[String]=[];var changed: Array[Dictionary]=[]
	for path: String in expected:
		if not actual.has(path): missing.append(path)
		elif typeof(actual[path])!=typeof(expected[path]) or not C._equal_value(actual[path],expected[path]): changed.append({"path":path,"actual":actual[path],"expected":expected[path]})
	for path: String in actual:
		if not expected.has(path): extra.append(path)
	return {"missing":missing,"extra":extra,"changed":changed}

func _observed(path: String,expected: String) -> bool:
	# Test-only unique-path observation cache, never replaces runtime first/final.
	# finish() hashes every unique actual source again, including both indexes.
	if source_before.has(path): return check(source_before[path].sha256==expected,"Shared source has same exact approved value "+path)
	return track(path,expected)

func precheck() -> bool:
	if not check(ADMISSION_READY,"Exact A81048 and independent runtime-source contract frozen"): return false
	if not track(ADMISSION_CONTRACT,ADMISSION_SHA): return false
	admission=JSON.parse_string(FileAccess.get_file_as_string(ADMISSION_CONTRACT))
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not check(args.size()==admission.allowed_args.size() and not B.forced_authoring(),"B is real runtime branch in a NEW process, never authoring collector or index adapter"): return false
	for i: int in args.size():
		if not check(args[i]==admission.allowed_args[i],"Exact frozen B-stage flags"): return false
	for path: String in admission.core_source_sha256:
		if not _observed(path,admission.core_source_sha256[path]): return false
	if not _observed(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	if not check(admission.whole_ms==ADMISSION_MS and admission.cities.size()==1,"Original60s/Yamen-only metadata continuation, no native geometry rerun"): return false
	for id: String in CITY_IDS:
		if not check(admission.cities.has(id),"Exact unique city identity "+id): return false
	var index: Variant=load(B_INDEX)
	var room_index: Variant=load(R_INDEX)
	if not check(index is GDScript and room_index is GDScript and index.resource_path==B_INDEX and room_index.resource_path==R_INDEX and index.formal_enabled()==false and room_index.formal_enabled()==false,"ROOT-promoted canonical indexes are actually disabled, no process-local substitution"): return false
	if not check(index.entries().size()==4 and admission.index_sha256==FileAccess.get_sha256(B_INDEX) and admission.room_index_sha256==FileAccess.get_sha256(R_INDEX),"Whole generated index identity equals fixed A outputs"): return false
	if not _observed(admission.generated_bundle_index_path,admission.index_sha256) or not _observed(admission.generated_room_index_path,admission.room_index_sha256): return false
	if not check(FileAccess.get_file_as_bytes(B_INDEX)==FileAccess.get_file_as_bytes(admission.generated_bundle_index_path) and FileAccess.get_file_as_bytes(R_INDEX)==FileAccess.get_file_as_bytes(admission.generated_room_index_path),"Two canonical promoted indexes byteexact A outputs, not rewritten adapters"): return false
	if not _observed(admission.finalizer_result_path,admission.finalizer_result_sha256): return false
	actual_A=JSON.parse_string(FileAccess.get_file_as_string(admission.finalizer_result_path))
	migration=JSON.parse_string(FileAccess.get_file_as_string(admission.migration_path))
	if not check(C._equal_value(actual_A.source_first,actual_A.source_final),"Actual A full input first/final remains separate from runtime maps"): return false
	for id: String in CITY_IDS:
		var row: Dictionary=admission.cities[id]
		row.runtime_legacy_expected=actual_A.runtime_closures[id].duplicate(true)
		row.runtime_authority_expected=actual_A.runtime_authorities[id].duplicate(true)
		for path: String in admission.continuation.added_legacy_source_sha256:
			if not check(not row.runtime_legacy_expected.has(path) and actual_A.source_first.get(path)==admission.continuation.added_legacy_source_sha256[path] and actual_A.source_final.get(path)==admission.continuation.added_legacy_source_sha256[path],"Both missing import leaves already fully observed in actual A "+path): return false
			row.runtime_legacy_expected[path]=admission.continuation.added_legacy_source_sha256[path]
		var expected: Dictionary=row.runtime_legacy_expected.duplicate(true)
		expected.merge(row.runtime_authority_expected)
		expected.merge(actual_A.rows[id])
		expected[B_INDEX]=admission.index_sha256;expected[row.manifest_path]=row.manifest_sha256
		row.complete_expected_sources=expected
		if not check(row.runtime_legacy_expected.size()==int(row.A_runtime_legacy_count)+2 and row.runtime_authority_expected.size()==int(row.A_runtime_authority_count),"Frozen actual A per-city maps, not runtime-derived expectations "+id): return false
	return _continuation_inverse()


func _continuation_inverse() -> bool:
	var extra: Dictionary=admission.continuation
	var id: String=String(CITY_IDS[0])
	var old_manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(extra.prior_manifest_path))
	var current: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(admission.cities[id].manifest_path))
	var restored: Dictionary=current.duplicate(true)
	var declaration: Dictionary=restored.get("runtime_closure_successor",{})
	if not check(declaration.get("prior_manifest_sha256")==extra.prior_manifest_sha256 and declaration.get("publication_report_sha256")==admission.finalizer_result_sha256 and declaration.get("original_admission_failure_sha256")==extra.prior_result_sha256 and C._equal_value(declaration.get("added_legacy_source_sha256"),extra.added_legacy_source_sha256) and declaration.get("geometry_recomputed")==false,"Exact successor declaration, not runtime-current admission"): return false
	restored.erase("runtime_closure_successor")
	for path: String in extra.added_legacy_source_sha256:
		if not check(restored.legacy_source_sha256.get(path)==extra.added_legacy_source_sha256[path],"Exact added SHA"): return false
		restored.legacy_source_sha256.erase(path)
	if not check(C._equal_value(restored,old_manifest),"Entire successor inverse equals original A manifest, including all historical proof/artifacts"): return false
	if not check(FileAccess.get_file_as_string(B_INDEX)==FileAccess.get_file_as_string(extra.prior_index_path).replace(String(extra.prior_manifest_sha256),String(admission.cities[id].manifest_sha256)),"Index bytes only Yamen manifest SHA replaced; false and other3 rows unchanged"): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(extra.prior_result_path))
	if not check(prior.get("complete")==false and int(prior.get("failures"))==2,"Original B86968 whole FAIL is retained, never rewritten as PASS"): return false
	for reused: String in extra.reuse_ids:
		var rows: Array[Dictionary]=[]
		for row: Dictionary in prior.records:
			if row.get("kind")=="T_FRESH_PROCESS_RUNTIME_COLLECTOR_ADMISSION" and row.get("scene_id")==reused: rows.append(row)
		if not check(rows.size()==1 and C._equal_value(rows[0].complete_actual_sources,rows[0].complete_expected_sources),"Reuse original exact full admission component "+reused): return false
		var original: Dictionary=rows[0].complete_actual_sources
		if not check(original.get(B_INDEX)==extra.prior_index_sha256,"Reused evidence is explicitly prior index, not false claim of new execution"): return false
		records.append({"kind":"REUSED_PRIOR_COMPONENT_NOT_RERUN","id":reused,"prior_report":extra.prior_result_path,"prior_report_sha256":extra.prior_result_sha256,"original_full_sources":original,"only_bootstrap_index_authorized_old":extra.prior_index_sha256,"only_bootstrap_index_authorized_new":admission.index_sha256,"current_cold_Geometry_Field_GPU_credit":false})
	return true

func _preserved_prior(id: String,expected: Dictionary) -> bool:
	var row: Dictionary=admission.cities[id]
	if not _observed(row.prior_manifest_path,row.prior_manifest_sha256): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.prior_manifest_path))
	var changed: Array[Dictionary]=[]
	for path: String in prior.legacy_source_sha256:
		var old: String=prior.legacy_source_sha256[path];var next: String=old
		if migration.source_delta.has(path):
			var delta: Dictionary=migration.source_delta[path]
			if not check(old in delta.historical_sha256,"Exact previously approved source hash before migration "+path): return false
			next=delta.new_sha256
			changed.append({"path":path,"old":old,"new":next})
		if not check(expected.get(path)==next,"Every original necessary runtime leaf is retained with only explicit delta "+id+":"+path): return false
	records.append({"kind":"INDEPENDENT_PRIOR_LEGACY_PRESERVATION","id":id,"prior_manifest":row.prior_manifest_path,"prior_count":prior.legacy_source_sha256.size(),"explicit_changes":changed})
	return true

func _expected(id: String) -> Dictionary:
	var row: Dictionary=admission.cities[id]
	if not _observed(row.manifest_path,row.manifest_sha256): return {}
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.manifest_path))
	if not check(manifest.scene_id==id and manifest.get("publication_full_source_finalized")==true and manifest.get("runtime_collector_admission_pending")==true and manifest.get("publication_inputs_are_not_runtime_union")==true,"A data-only output is NOT prior B/runtime acceptance "+id): return {}
	if not check(C._equal_value(manifest.legacy_source_sha256,row.runtime_legacy_expected) and C._equal_value(manifest.runtime_authority_sha256,row.runtime_authority_expected),"Independently frozen execution/authority sets, not historical1479 input union "+id): return {}
	if not check(C._equal_value(manifest.publication_source_first,manifest.publication_source_final),"Publication history retains its own first/final map "+id): return {}
	var expected: Dictionary=manifest.legacy_source_sha256.duplicate(true)
	# Acyclic authority: neither index nor the manifest can hash itself; three
	# native artifacts and room authorities are independent completed outputs.
	if not check(not expected.has(B_INDEX) and not expected.has(row.manifest_path) and not manifest.runtime_authority_sha256.has(B_INDEX) and not manifest.runtime_authority_sha256.has(row.manifest_path),"No source-map index/manifest self-hash cycle "+id): return {}
	for path: String in manifest.runtime_authority_sha256:
		if not check(not expected.has(path),"Legacy/authority namespaces are disjoint "+path): return {}
		expected[path]=manifest.runtime_authority_sha256[path]
	for path: String in manifest.artifacts:
		if expected.has(path):
			if not check(expected[path]==manifest.artifacts[path],"Repeated native artifact authority has one exact SHA"): return {}
		expected[path]=manifest.artifacts[path]
	expected[B_INDEX]=admission.index_sha256;expected[row.manifest_path]=row.manifest_sha256
	if not check(C._equal_value(expected,row.complete_expected_sources),"Final complete source map exactly equals independent QA contract "+id): return {}
	for path: String in row.publication_only_paths:
		if not check(manifest.publication_source_first.has(path) and not expected.has(path),"Compiler-only history is preserved but not imposed as runtime execution source "+path): return {}
	if not _preserved_prior(id,expected): return {}
	return expected

func exercise_cpu() -> bool:
	await process_frame
	var finalizer: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(admission.finalizer_result_path))
	if not check(finalizer.get("passed")==true and finalizer.get("geometry_not_recomputed")==true and finalizer.get("formal_enabled")==false and finalizer.get("runtime_collector_admission_pending")==true,"A only finalized data/indexes; it does not award B credit"): return false
	for id: String in CITY_IDS:
		var expected: Dictionary=_expected(id)
		if expected.is_empty(): return false
		var raw: SceneScript=ResourceLoader.load("res://data/scenes/"+id+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not check(raw!=null and raw.scene_id==StringName(id) and not B.requested(StringName(id)),"Real canonical input; runtime remains disabled while collector is complete "+id): return false
		var paths: Dictionary=C._transition_sources(raw,false)
		var membership: Dictionary=_map_diff(paths,expected)
		# Values are booleans in the non-hashing C collector. Only compare keys
		# here; then hash every ACTUAL key independently and compare full maps.
		records.append({"kind":"ACTUAL_COLLECTOR_MEMBERSHIP","id":id,"missing":membership.missing,"extra":membership.extra,"actual_count":paths.size(),"expected_count":expected.size()})
		if not check(not paths.is_empty() and _same_keys(paths,expected),"Actual C runtime collector complete keyset, no known-subset count pass "+id): return false
		var actual: Dictionary={}
		for path: String in paths:
			if not check(Time.get_ticks_msec()<deadline,"Original60s B admission budget") or not _observed(path,expected[path]): return false
			actual[path]=source_before[path].sha256
		if not check(C._equal_value(actual,expected),"Actual collector FULL independently read SHA map equals expected "+id,_map_diff(actual,expected)): return false
		if not check(not B.describe(StringName(id),actual).is_empty(),"Actual canonical helper accepts exactly this complete map "+id): return false
		# In-memory metadata refusal only. No real source/index/file mutation.
		var bad: Dictionary=actual.duplicate(true)
		var first: String=String(expected.keys()[0]);bad.erase(first)
		if not check(B.describe(StringName(id),bad).is_empty(),"One missing execution leaf refused "+id): return false
		bad=actual.duplicate(true);bad["res://qa_not_an_authorized_runtime_source"]=String(expected[first])
		if not check(B.describe(StringName(id),bad).is_empty(),"One extra execution leaf refused "+id): return false
		bad=actual.duplicate(true);bad[first]="0000000000000000000000000000000000000000000000000000000000000000"
		if not check(B.describe(StringName(id),bad).is_empty(),"One incorrect execution SHA refused "+id): return false
		records.append({"kind":"T_FRESH_PROCESS_RUNTIME_COLLECTOR_ADMISSION","scene_id":id,"complete_actual_sources":actual,"complete_expected_sources":expected,"canonical_C_path":String((load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd") as GDScript).get("resource_path")),"canonical_bundle_path":String((load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd") as GDScript).get("resource_path")),"disabled_index_path":B_INDEX,"index_adapter_used":false,"geometry_or_Field_or_GPU_credit":false})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+ADMISSION_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck(): complete=await exercise_cpu()
	finish("res://build/luoyang_t_yamen_collector_continuation_20261019u/%d_%d"%[OS.get_process_id(),began],began,complete,"T_YAMEN_ONLY_B_CONTINUATION_PRIOR_THREE_CITY_COMPONENTS_REUSED")
