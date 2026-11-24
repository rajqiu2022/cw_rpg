extends RefCounted
## Root's one integrated QA calls this with the actual Gate Scene. No mutation.
static func audit(scene: SceneScript) -> Dictionary:
	var c: GDScript=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	var b: GDScript=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	if scene==null or scene.scene_id!=&"ch4_s0_luoyang_gate":return {"passed":false,"error":"EXACT_GATE_SCENE_REQUIRED"}
	var actual: Dictionary=c._transition_sources(scene)
	var config: Dictionary=b.manifest(scene.scene_id)
	if actual.is_empty() or config.is_empty():return {"passed":false,"error":"ACTUAL_COLLECTOR_OR_MANIFEST_EMPTY","actual_count":actual.size()}
	var expected: Dictionary=config.legacy_source_sha256.duplicate(true)
	expected.merge(config.runtime_authority_sha256);expected.merge(config.artifacts)
	for path: String in [b.INDEX,b.ESTATE_INDEX,b.AO_INDEX,b.AP_INDEX,b.AP_ENV_INDEX,b.AP_EXEC_INDEX,b.AP_QUARTER_INDEX]:expected[path]=FileAccess.get_sha256(path)
	var entry: Dictionary=b._entry(scene.scene_id)
	if entry.is_empty():return {"passed":false,"error":"ACTUAL_GATE_INDEX_ENTRY_EMPTY"}
	expected[entry.manifest_path]=entry.manifest_sha256
	var missing: Array[Dictionary]=[];var added: Array[Dictionary]=[];var stale: Array[Dictionary]=[]
	for path: String in expected:
		var origin: String="legacy_source_sha256" if config.legacy_source_sha256.has(path) else ("runtime_authority_sha256" if config.runtime_authority_sha256.has(path) else ("artifacts" if config.artifacts.has(path) else "actual_index_entry"))
		if not actual.has(path):missing.append({"path":path,"expected":expected[path],"expected_origin":origin});continue
		if actual[path]!=expected[path]:stale.append({"path":path,"expected":expected[path],"actual_collector":actual[path],"disk_sha256":FileAccess.get_sha256(path),"expected_origin":origin})
	for path: String in actual:
		if not expected.has(path):added.append({"path":path,"actual_collector":actual[path],"disk_sha256":FileAccess.get_sha256(path),"attribution":"C collector only; inspect finish8 required_sources / EX snapshot / World16 proof ownership; never auto-approve"})
	return {"passed":missing.is_empty() and added.is_empty() and stale.is_empty() and not b.describe(scene.scene_id,actual).is_empty(),"actual_count":actual.size(),"expected_count":expected.size(),"missing":missing,"added":added,"stale":stale,"actual_complete":actual,"expected_complete":expected,"Scene_instance":scene.get_instance_id(),"read_only":true}
