extends "res://tests/test_luoyang_market_enrichment_formal_boot_retry3_20261014.gd"
## NEW short formal boot. Reuse the exact passed candidate source/geometry receipt;
## actual canonical/public entry/26 nodes/full875/full17/Physics still run unchanged.
## No RAW ground reload, composition replay, budget increase or production edit.
const REUSE_RESULT_PATH := "res://build/joint_world_luoyang_20261003_qa/market_enrichment_key_6148_2436839/result.json"
const REUSE_RESULT_SHA := "2677e298cf678e3edf9e9d11246c15f2d344b977b4b27c8364a00d221a3b86c6"
const REUSE_OUTER_PATH := "res://build/luoyang_market_enrich_20261014_root01/v2_sources_after_key.json"
const REUSE_OUTER_SHA := "7cd8d9944e3e4c12281fa1aafab20b286a8f10808e8cd4d6d6774f3351d04aa9"
const FORMAL_PARENT_PATH := "res://tests/test_luoyang_market_enrichment_formal_boot_retry3_20261014.gd"
const FORMAL_PARENT_SHA := "c2afaf1f9c32012cb721cfbba714c14caffbe2bac552163deeb2d52ebb7fcffc"
const ORIGINAL_CANONICAL_SHA := "3d4d7fb941845c9220b27adf726160704cb9e3e2713ac4f58322c2e90f3e2660"

func _source_market() -> bool:
	for path: String in [REUSE_RESULT_PATH,REUSE_OUTER_PATH,FORMAL_PARENT_PATH]: source_before[path] = _file(path)
	if not _check(source_before[REUSE_RESULT_PATH].sha256 == REUSE_RESULT_SHA and source_before[REUSE_OUTER_PATH].sha256 == REUSE_OUTER_SHA and source_before[FORMAL_PARENT_PATH].sha256 == FORMAL_PARENT_SHA,"exact previously passed candidate plus root outer receipt and inherited formal driver"): return false
	var proof: Variant = JSON.parse_string(FileAccess.get_file_as_string(REUSE_RESULT_PATH))
	if not _check(proof is Dictionary and proof.get("complete") == true and proof.get("checks") == 138.0 and proof.get("failures") == 0.0 and proof.get("scope") == "MARKET_26_SOURCE_SPAWN_MAIN_STREET_NEW_SOLID_FADE_SPACE_NOT_SIX" and proof.get("source_before") is Dictionary and proof.get("source_after") is Dictionary and proof.source_before == proof.source_after and proof.get("records",[]).size() == 8 and proof.get("gallery",[]).size() == 2 and proof.get("fade",[]).size() == 2 and proof.get("arrivals",[]).size() == 3,"exact completed candidate source/geometry/real input receipt, not failure reuse"): return false
	for path: String in proof.source_after:
		if not source_before.has(path): source_before[path] = _file(path)
		var now: Dictionary = source_before[path]
		var previous: Dictionary = proof.source_after[path]
		if path == CANONICAL_MARKET_PATH:
			if not _check(previous.sha256 == ORIGINAL_CANONICAL_SHA and now.sha256 == ADOPTED_SCENE_SHA and now.sha256 == source_before[MARKET.SCENE_PATH].sha256,"only exact authorized old canonical to candidate-byte adoption differs"): return false
		elif not _check(now == previous,"same passed candidate source fact "+path): return false
	market_manifest = MARKET.runtime_manifest()
	if not _check(not market_manifest.is_empty() and source_before[MARKET.MANIFEST_PATH].sha256 == MARKET.MANIFEST_SHA and market_manifest.get("status") == "PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA" and market_manifest.get("author_sha256") == MARKET.AUTHOR_SHA and market_manifest.get("objects",[]).size() == 26 and market_manifest.get("routes",[]).size() == 7,"same frozen publication, no artistic/formal status rewrite"): return false
	market_record = {"objects":market_manifest.objects.duplicate(true),"gameplay_slots":market_manifest.gameplay_slots.duplicate(true),"routes":market_manifest.routes.duplicate(true),"ground_path":market_manifest.ground_path,"walk_path":market_manifest.walk_path}
	var scene: SceneScript = ResourceLoader.load(CANONICAL_MARKET_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _check(scene != null and MARKET.bound(scene) and scene.npcs.size() == 8 and scene.map_layout.portals.size() == 4 and scene.map_layout.interactions.size() == 4,"actual adopted original eight NPC/four portal/four interaction definitions"): return false
	for npc: Dictionary in scene.npcs: expected_npc_ids.append(String(npc.npc_id))
	var previous_source: Dictionary = proof.records[0]
	if not _check(previous_source.get("kind") == "SOURCE_BOUND" and previous_source.get("manifest_sha") == MARKET.MANIFEST_SHA and previous_source.get("author_sha") == MARKET.AUTHOR_SHA and previous_source.get("objects") == 26.0 and previous_source.get("routes") == 7.0 and previous_source.get("add_ids") == MARKET.ADD_IDS and previous_source.get("NPC_definition_ids") == expected_npc_ids,"same exact source/gameplay identities as completed candidate"): return false
	rows.append({"kind":"SOURCE_BOUND","objects":26,"add_ids":MARKET.ADD_IDS,"NPC_definition_ids":expected_npc_ids,"NPC_live_count_credit":false,"portals":4,"interactions":4,"routes":7,"manifest_sha":MARKET.MANIFEST_SHA,"author_sha":MARKET.AUTHOR_SHA,"source_geometry_reused":true,"composition_reexecuted":false,"RAW_ground_reloaded":false,"reused_result_path":REUSE_RESULT_PATH,"reused_result_sha":REUSE_RESULT_SHA,"root_outer_path":REUSE_OUTER_PATH,"root_outer_sha":REUSE_OUTER_SHA,"root_outer_current_exactticks_required":true,"credit":"PASSED_CANDIDATE_SOURCE_GEOMETRY_REUSED_CURRENT_FORMAL_BIRTH_STILL_REQUIRED"})
	return failures == 0
