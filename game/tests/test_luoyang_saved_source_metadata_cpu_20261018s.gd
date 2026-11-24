extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
##30s metadata/strict raw-SHA admission only. No C.prepare/Field/geometry/GPU.
const CPU_BASE="res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
const CPU_BASE_SHA="001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102"
const CORE="res://tests/fixtures/luoyang_saved_source_core_20261018s.json"
const CORE_SHA="f1fa923d3b094b9bf0e455bd11fea357455c87231170ee7fd22c9957039a3d25"
const CONTRACT="res://tests/fixtures/luoyang_saved_source_contract_20261018s.json"
const CONTRACT_SHA="8568c9c73b16612324e5a32ad8c6f287c393ef7d36a10d74d0a93152a9ac967a"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const FIELD_OLD="3462d7a036d4dab2cf28e497b7fd33b2bbd710687a7c383f9fe5708bf82f722c"
const FIELD_NEW="34081bd719470b53aa4b418e1772d7a11c2a6fe0573d735537ce8d58338a19b9"
const TEMPLE="res://scripts/city/luoyang_temple_assembly_20261016.gd"
const TEMPLE_OLD="d1c408f5e210a0aa0a42bf3d7f9578b7234731f7c913763756f14d26e093df40"
const TEMPLE_NEW="5d934e3167f9e4e8011583a48df9daacb9d066d08bd9d2b4d0f93659dd8ef5eb"
const TEMPLE_PRIOR_BIND="res://data/maps/luoyang_temple_assembly_20261016/binding_precomputed_world_v13.json"
const INDEX="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const BUNDLE_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
var bundle: Variant
var contract: Dictionary={}

func _initialize() -> void:
	budget_ms=30000;atom_name="S_SAVED_SOURCE_METADATA_ONLY_30S"
	super._initialize()

func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func precheck() -> bool:
	if not check(OS.get_cmdline_user_args().is_empty(),"Metadata ordinary no flags; deployment must precede this key"): return false
	for pair: Array in [[CPU_BASE,CPU_BASE_SHA],[CORE,CORE_SHA],[CONTRACT,CONTRACT_SHA]]:
		if not track(pair[0],pair[1]): return false
	var core: Dictionary=_json(CORE)
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	contract=_json(CONTRACT)
	for row: Dictionary in contract.rows:
		if not track(row.candidate_path,row.sha256) or not track(row.prior_path,row.prior_sha256): return false
	for pair: Array in [[contract.temple_old_binding_path,contract.temple_old_binding_sha256],[contract.temple_candidate_binding_path,contract.temple_new_binding_sha256],[contract.temple_old_helper_path,contract.temple_old_helper_sha256],[contract.temple_candidate_helper_path,contract.temple_candidate_helper_sha256],[contract.old_index_path,contract.old_index_sha256],[contract.candidate_index_path,contract.candidate_index_sha256],[contract.field_snapshot_path,FIELD_NEW]]:
		if not track(pair[0],pair[1]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	bundle=load(BUNDLE_PATH)
	return check(bundle!=null,"Unchanged actual strict bundle implementation, not a QA replacement")

func _inverse(prior: Dictionary,current: Dictionary) -> bool:
	var restored: Dictionary=current.duplicate(true)
	var migration: Dictionary=restored.get("source_migration",{})
	if migration.is_empty() or migration.get("authority_path")!=contract.authority_path or migration.get("authority_sha256")!=contract.authority_sha256: return false
	if migration.get("original_publication_source_first_final_and_artifacts_unchanged")!=true: return false
	var expected_delta: Dictionary={FIELD:{"old":FIELD_OLD,"new":FIELD_NEW}}
	var extra: Dictionary={}
	if current.scene_id!="ch4_s0_luoyang_gate":
		expected_delta[TEMPLE]={"old":TEMPLE_OLD,"new":TEMPLE_NEW}
		extra[contract.temple_new_binding_path]=contract.temple_new_binding_sha256
	if not bundle.equal(migration.get("added_current_sources"),extra) or migration.get("source_delta",[]).size()!=expected_delta.size(): return false
	var seen: Dictionary={}
	for item: Dictionary in migration.source_delta:
		var path: String=item.path
		if seen.has(path) or not expected_delta.has(path) or item.old_sha256!=expected_delta[path].old or item.new_sha256!=expected_delta[path].new or restored.legacy_source_sha256.get(path)!=item.new_sha256: return false
		seen[path]=true;restored.legacy_source_sha256[path]=item.old_sha256
	for path: String in extra:
		if restored.legacy_source_sha256.get(path)!=extra[path] or prior.legacy_source_sha256.has(path): return false
		restored.legacy_source_sha256.erase(path)
	restored.erase("source_migration")
	return bundle.equal(prior,restored)

func _admission_negative(id: StringName,sources: Dictionary,path: String,hash: String,label: String) -> bool:
	var bad: Dictionary=sources.duplicate(true);bad[path]=hash
	return check(bundle.describe(id,bad).is_empty(),"Actual strict helper rejects "+label)

func exercise() -> bool:
	await process_frame # Match actual asynchronous finite-utility contract.
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(contract.field_snapshot_path)
	var old_bytes: PackedByteArray=bytes.duplicate();old_bytes.append(10)
	if not check(bytes.size()==217489 and bytes[-1]==10 and bytes[-2]!=10 and bundle.bytes_sha(bytes)==FIELD_NEW and bundle.bytes_sha(old_bytes)==FIELD_OLD,"Exact whole Field reverse: append one final0A reconstructs old published bytes, not normalized hashing"): return false
	var mutations: Dictionary={}
	var internal: PackedByteArray=bytes.duplicate();internal[100]=internal[100]^1;mutations.internal_one_byte=bundle.bytes_sha(internal)
	var absent_lf: PackedByteArray=bytes.duplicate();absent_lf.resize(absent_lf.size()-1);mutations.no_final_LF=bundle.bytes_sha(absent_lf)
	var three_lf: PackedByteArray=old_bytes.duplicate();three_lf.append(10);mutations.three_final_LF=bundle.bytes_sha(three_lf)
	var bom:=PackedByteArray([239,187,191]);bom.append_array(bytes);mutations.BOM_prefix=bundle.bytes_sha(bom)
	mutations.historical_two_LF_current_disallowed=FIELD_OLD
	for row: Dictionary in contract.rows:
		var prior: Dictionary=_json(row.prior_path);var current: Dictionary=_json(row.candidate_path)
		if not check(bundle.equal(current,_json(row.path)) and _inverse(prior,current),"Whole successor metadata exact inverse recovers full immutable prior "+row.id): return false
		var corrupt: Dictionary=current.duplicate(true);corrupt.publication_source_first[FIELD]=FIELD_NEW
		if not check(not _inverse(prior,corrupt),"Historical original publication first must remain old, not rewritten "+row.id): return false
		corrupt=current.duplicate(true);corrupt.artifacts[corrupt.artifacts.keys()[0]]="0".repeat(64)
		if not check(not _inverse(prior,corrupt),"Original artifact bytes/proof identity cannot migrate "+row.id): return false
		var sources: Dictionary=current.legacy_source_sha256.duplicate(true)
		for path: String in current.artifacts: sources[path]=current.artifacts[path]
		sources[INDEX]=contract.candidate_index_sha256;sources[row.path]=row.sha256
		if not check(not bundle.describe(StringName(row.id),sources).is_empty(),"Actual unchanged helper admits exact complete current raw map "+row.id): return false
		for label: String in mutations:
			if not _admission_negative(StringName(row.id),sources,FIELD,mutations[label],label+" "+row.id): return false
		var missing: Dictionary=sources.duplicate(true);missing.erase(FIELD)
		if not check(bundle.describe(StringName(row.id),missing).is_empty(),"Missing exact Field path cannot fallback to disk "+row.id): return false
		var extra: Dictionary=sources.duplicate(true);extra["res://not_authorized.gd"]=FIELD_NEW
		if not check(bundle.describe(StringName(row.id),extra).is_empty(),"Extra current source leaf cannot silently pass "+row.id): return false
		records.append({"kind":"S_EXACT_CURRENT_SOURCE_METADATA","id":row.id,"whole_inverse":true,"historical_first_final_and_artifacts_unchanged":true,"current_runtime_map_count":sources.size(),"authority_is_not_runtime_leaf":not sources.has(contract.authority_path),"old_Field_identity_not_dual_allowed":true})
	var old_binding: Dictionary=_json(contract.temple_old_binding_path)
	var new_binding: Dictionary=_json(contract.temple_new_binding_path)
	var restored: Dictionary=new_binding.duplicate(true)
	if not check(restored.source_sha256.get(FIELD)==FIELD_NEW and restored.source_sha256.get(TEMPLE_PRIOR_BIND)==contract.temple_old_binding_sha256,"Temple v14 current exact Field and immutable v13 source identity"): return false
	restored.erase("editor_save_authorized_dependency_revision");restored.source_sha256[FIELD]=FIELD_OLD;restored.source_sha256.erase(TEMPLE_PRIOR_BIND)
	if not check(bundle.equal(restored,old_binding),"Whole Temple binding inverse keeps all other storage/geometry/history exact"): return false
	var old_helper: String=FileAccess.get_file_as_string(contract.temple_old_helper_path)
	var expected_helper: String=old_helper.replace(TEMPLE_PRIOR_BIND,contract.temple_new_binding_path).replace(contract.temple_old_binding_sha256,contract.temple_new_binding_sha256)
	if not check(expected_helper==FileAccess.get_file_as_string(TEMPLE),"Temple helper whole text only two pinned binding constants changed"): return false
	var old_index: String=FileAccess.get_file_as_string(contract.old_index_path)
	for row: Dictionary in contract.rows: old_index=old_index.replace(row.prior_sha256,row.sha256)
	return check(old_index==FileAccess.get_file_as_string(INDEX),"Whole index text only three exact manifest hashes change; formaltrue/Yamen unchanged")
