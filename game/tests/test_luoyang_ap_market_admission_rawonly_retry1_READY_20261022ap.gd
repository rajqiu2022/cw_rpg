extends "res://tests/test_luoyang_city_full_rollout_bounded_groups_author_anchor_returns_READY_20261022ap.gd"
## Diagnostic only: one original public Market request, no geometry/doors/pictures.
## Expected maps remain fixed v5; observed hashes below are diagnosis, never admission.
const DIAG_B = preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const DIAG_Q = preload("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
const DIAG_G = preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")

func _key_delta_diag(observed: Dictionary, expected: Dictionary) -> Dictionary:
	var extra: Array[String]=[]
	var missing: Array[String]=[]
	var mismatch: Array[Dictionary]=[]
	for path: String in observed:
		if not expected.has(path): extra.append(path)
		elif observed[path] is String and observed[path]!=expected[path]: mismatch.append({"path":path,"observed":observed[path],"fixed_expected":expected[path]})
	for path: String in expected:
		if not observed.has(path): missing.append(path)
	extra.sort();missing.sort()
	return {"observed_count":observed.size(),"fixed_expected_count":expected.size(),"extra":extra,"missing":missing,"value_mismatch":mismatch,"diagnostic_only_no_expected_backfill":true}

func _diagnostic_ap() -> bool:
	var id: String="ch4_s3_luoyang_market"
	var router: Node=root.get_node("SceneRouter")
	var spec: Dictionary=ap_specs[id]
	_arm(id)
	var accepted: bool=router.call("go_field_smart",StringName(id),_v(spec.setup_uv),"",-1,3)
	var terminal: Dictionary={}
	var end: int=mini(deadline,Time.get_ticks_msec()+60000)
	while accepted and Time.get_ticks_msec()<end:
		var public: Dictionary=router.call("get_public_city_preparation_state")
		if public.get("scene_id")==id and public.get("phase")=="FAILED":
			terminal={"kind":"FAILED","public":public.duplicate(true),"C_errors":C.errors(),"transition":C.transition_validation_state(),"transition_keys":C._transition_validation.keys(),"transition_sources":C._transition_validation.get("sources",{}).duplicate(true)}
			break
		if not first_draw.is_empty():
			terminal={"kind":"OPERABLE_FIRST_DRAW","public":public.duplicate(true),"C_errors":C.errors(),"transition":C.transition_validation_state(),"first_draw":first_draw.duplicate(true),"transition_keys":C._transition_validation.keys(),"transition_sources":C._transition_validation.get("sources",{}).duplicate(true)}
			break
		await process_frame
	if terminal.is_empty(): terminal={"kind":"REJECTED_OR_TIMEOUT","accepted":accepted,"C_errors":C.errors(),"transition":C.transition_validation_state(),"public":router.call("get_public_city_preparation_state")}
	# Preserve original failure before any other API can refresh caches/errors.
	records.append({"kind":"AP_MARKET_ORIGINAL_REQUEST_DIAGNOSTIC","terminal":terminal})
	# Direct source read only. Router._load_field_scene_def could resolve again.
	var raw: SceneScript=ResourceLoader.load("res://data/scenes/ch4_s3_luoyang_market.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var collected: Dictionary=C._transition_sources(raw,false) if raw!=null else {}
	var manifest: Dictionary=DIAG_B.manifest(StringName(id))
	var header: Dictionary=DIAG_Q.source_header()
	var registry: Dictionary=DIAG_G.catalogue()
	var fixed_expected: Dictionary=spec.source_sha256
	var actual_hash_diffs: Array[Dictionary]=[]
	for path: String in fixed_expected:
		var observed_sha: String=FileAccess.get_sha256(path)
		if observed_sha!=fixed_expected[path]: actual_hash_diffs.append({"path":path,"observed_sha256":observed_sha,"fixed_expected_sha256":fixed_expected[path]})
	records.append({"kind":"AP_MARKET_READONLY_SOURCE_DIAGNOSTIC","raw_scene_path":raw.resource_path if raw!=null else "","B_entry":DIAG_B._entry(StringName(id)),"B_manifest_empty":manifest.is_empty(),"B_manifest_keys":manifest.keys(),"B_manifest_legacy_count":manifest.get("legacy_source_sha256",{}).size(),"B_manifest_runtime_count":manifest.get("runtime_authority_sha256",{}).size(),"B_manifest_artifact_count":manifest.get("artifacts",{}).size(),"B_ap_author_empty":DIAG_B._ap().author().is_empty(),"Q_header_empty":header.is_empty(),"Q_header_source_count":header.get("source_sha256",{}).size(),"G_registry_empty":registry.is_empty(),"G_registry_room_count":registry.get("rooms",{}).size(),"collector_vs_fixed":_key_delta_diag(collected,fixed_expected),"transition_vs_fixed":_key_delta_diag(terminal.get("transition_sources",{}),fixed_expected),"B_describe_collected_empty":DIAG_B.describe(StringName(id),collected).is_empty(),"B_describe_full_fixed_empty":DIAG_B.describe(StringName(id),fixed_expected).is_empty(),"fixed_source_disk_mismatch":actual_hash_diffs,"not_functional_or_geometry_acceptance":true})
	return check(accepted and not terminal.is_empty(),"Single original request diagnostic captured, not admission",terminal.kind)

func _run() -> void:
	var began: int=Time.get_ticks_msec()
	deadline=began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	output="res://build/luoyang_city_full_rollout_20261022ap_qa01/market_admission_diagnostic/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete: bool=false
	if precheck() and check(ap_group=="B","Diagnostic exact selector B only"):
		deadline=began+90000
		driver=INPUT.new();driver.configure(self)
		RenderingServer.frame_post_draw.connect(_draw)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		root.get_node("GameState").set("current_chapter",4)
		ap_state_before=_state_ap()
		complete=await _diagnostic_ap()
	target=""
	if RenderingServer.frame_post_draw.is_connected(_draw): RenderingServer.frame_post_draw.disconnect(_draw)
	if not await _cleanup(): complete=false
	if not ap_state_before.is_empty() and not check(C._equal_value(ap_state_before,_state_ap()),"Diagnostic does not mutate task/flag/reward state"): complete=false
	finish(output,began,complete,"AP_MARKET_SINGLE_PUBLIC_REQUEST_DIAGNOSTIC_NOT_ACCEPTANCE")
