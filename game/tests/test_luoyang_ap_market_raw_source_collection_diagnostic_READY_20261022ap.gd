extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Pure source diagnostic: no Router, Field, public request, resolve or geometry.
const DC=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const DB=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const DF="res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_groups_v5_author_anchors_READY.json"
const DF_SHA="56af9d883a163e6cd0646f6ef4b394e46fc2c29e10baf254fc5d0bc548ee618d"

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+30000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	var output: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/market_raw_source_diagnostic/%d_%d"%[OS.get_process_id(),began]
	var complete: bool=false
	if track(DF,DF_SHA) and check(OS.get_cmdline_user_args().is_empty(),"No candidate or request selector"):
		var fixed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DF))
		var spec: Dictionary={}
		for row: Dictionary in fixed.scenes:
			if row.id=="ch4_s3_luoyang_market": spec=row
		var pinned: bool=not spec.is_empty()
		for path: String in fixed.core_source_sha256:
			if not track(path,fixed.core_source_sha256[path]): pinned=false
		if pinned:
			var raw: SceneScript=ResourceLoader.load("res://data/scenes/ch4_s3_luoyang_market.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
			if check(raw!=null and raw.resource_path=="res://data/scenes/ch4_s3_luoyang_market.tres","Direct exact original raw resource, never resolved"):
				var actual_keys: Dictionary=DC._transition_sources(raw,false)
				var expected: Dictionary=spec.source_sha256
				var extra: Array[String]=[];var missing: Array[String]=[]
				var mismatch: Array[Dictionary]=[];var actual_hashes: Dictionary={}
				for path: String in actual_keys:
					actual_hashes[path]=FileAccess.get_sha256(path)
					if not expected.has(path): extra.append(path)
					elif actual_hashes[path]!=expected[path]: mismatch.append({"path":path,"actual":actual_hashes[path],"fixed_expected":expected[path]})
				for path: String in expected:
					if not actual_keys.has(path): missing.append(path)
				extra.sort();missing.sort()
				records.append({"kind":"AP_MARKET_RAW_SOURCE_COLLECTION_ONLY","raw_scene_path":raw.resource_path,"raw_layout_path":raw.map_layout.resource_path if raw.map_layout!=null else "","actual_collector_keys":actual_keys.keys(),"actual_source_hashes_DIAGNOSTIC_ONLY":actual_hashes,"actual_count":actual_keys.size(),"fixed_count":expected.size(),"extra":extra,"missing":missing,"mismatch":mismatch,"B_manifest_empty":DB.manifest(&"ch4_s3_luoyang_market").is_empty(),"B_describe_actual_hashed_collector_empty":DB.describe(&"ch4_s3_luoyang_market",actual_hashes).is_empty(),"B_describe_fixed_expected_empty":DB.describe(&"ch4_s3_luoyang_market",expected).is_empty(),"no_expected_backfill":true,"public_request_count":0,"resolve_count":0,"geometry_runs":0,"Field_created":false})
				complete=check(not actual_keys.is_empty(),"Collected only raw source facts; not admission/functional acceptance")
	finish(output,began,complete,"AP_PURE_RAW_SOURCE_DIAGNOSTIC_NO_PUBLIC_REQUEST_NO_GEOMETRY")
