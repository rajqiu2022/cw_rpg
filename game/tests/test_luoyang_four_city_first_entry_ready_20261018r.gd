extends "res://tests/test_luoyang_loading_baseline_ready_20261018r.gd"
## NOTREADY. Four different IDs first-loaded in ONE process, not SSD-cold.
## Public default setup only, NOT travel between districts or warm-return credit.
const FOUR_CITY_READY=true
const FOUR_CORE_PATH="res://tests/fixtures/luoyang_loading_candidate_final_core_20261018r.json"
const FOUR_CORE_SHA="f2070988417bc520526031c3bae56efb5f57031ef34c5fc36e4b2bf4a2ddb332"
const FOUR_BUNDLE_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const FOUR_KIND="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1"
const FOUR_FLAG="--luoyang-precomputed-bundle-20261018r"
const FOUR_INDEX_PATH="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const FOUR_INDEX_SHA="e03bddda7dea2ebc1b13e92f9dac5f1c4cc8b70ece18fa53cdf6ef5edf15abb5"
const FOUR_PUBLICATION_PATH="res://build/luoyang_runtime_bundle_publication_20261018r/112724_2528/result.json"
const FOUR_PUBLICATION_SHA="eecb06deaf16fe19d83ba55128b916fde47bd3f53f7a8f6cabfcd30f1ecd0a0b"
const FOUR_EXPECTATIONS={
	"ch4_s0_luoyang_gate": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s0_luoyang_gate/manifest.json",
		"manifest_sha256": "ed6c8fab99f3e99079d1b92ba383277188a72dcc105565014a5f24c7a980155e"
	},
	"ch4_s3_luoyang_market": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s3_luoyang_market/manifest.json",
		"manifest_sha256": "48c987285b1be911818201d45a692a9004fab31b9acf57c202170699f7b6adff"
	},
	"ch4_s2_canal_docks": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s2_canal_docks/manifest.json",
		"manifest_sha256": "d1634164dcf7ee908b1e91142cf4b1e58e36e5f469bdc43803a2fb59f43b2262"
	},
	"ch4_s1_luoyang_yamen": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s1_luoyang_yamen/manifest.json",
		"manifest_sha256": "966c888629953546b108de5fc1893b7537ee0b4b6d88b74a17575e458819e221"
	}
}
const FOUR_IDS=[&"ch4_s0_luoyang_gate",&"ch4_s3_luoyang_market",&"ch4_s2_canal_docks",&"ch4_s1_luoyang_yamen"]
var four_api: Variant
var seen_city_ids: Dictionary={}
var city_source_maps: Dictionary={}

func precheck() -> bool:
	if not check(FOUR_CITY_READY and FOUR_EXPECTATIONS.size()==4,"NOTREADY until all four native publications and exact current core frozen"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args()==PackedStringArray([FOUR_FLAG]),"Real GPU/native clock, sole bundle candidate flag"): return false
	if not track(FOUR_CORE_PATH,FOUR_CORE_SHA) or not track(FOUR_INDEX_PATH,FOUR_INDEX_SHA) or not track(FOUR_PUBLICATION_PATH,FOUR_PUBLICATION_SHA): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FOUR_CORE_PATH))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track("res://tests/test_luoyang_loading_baseline_ready_20261018r.gd","d2b7dece0bc4a53768394c817eeadf337e9f258c21fd75ade71dbcc073cca8c8") or not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	four_api=load(FOUR_BUNDLE_PATH)
	var publication: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FOUR_PUBLICATION_PATH))
	if not check(four_api!=null and publication.get("passed")==true and publication.get("rows",[]).size()==4,"Actual full four-city publication success; not partial two/three-row outputs"): return false
	var ids: Dictionary={}
	for row: Dictionary in publication.rows:
		var id: String=String(row.get("scene_id",""))
		if not check(StringName(id) in FOUR_IDS and not ids.has(id),"Exact four unique published IDs",id): return false
		ids[id]=true
	for id: StringName in FOUR_IDS:
		var expected: Dictionary=FOUR_EXPECTATIONS.get(String(id),{})
		if not check(ids.has(String(id)) and expected.size()==2 and expected.manifest_path==four_api.ROOT+String(id)+"/manifest.json","Four exact generated manifest authority paths",String(id)): return false
		if not track(expected.manifest_path,expected.manifest_sha256): return false
	package=R.binding();author=R.author(package)
	return check(not package.is_empty() and not author.is_empty(),"Current unchanged Field-owned district geometry definitions")

func _first_city(id: StringName) -> bool:
	var router: Node=root.get_node("SceneRouter")
	if not check(not seen_city_ids.has(String(id)),"First request for this city in this process, never reused to label warm as cold"): return false
	seen_city_ids[String(id)]=true
	var lease_before: Dictionary=router.call("get_resident_city_state")
	_arm_draw(String(id),"FOUR_CITY_FIRST_PUBLIC_DEFAULT_"+String(id))
	if not check(router.call("go_field_smart",id,null,"",-1,C.VERSION),"Normal public default spawn accepted "+String(id)) or not await _wait_once(String(id)): return false
	var measurement: Dictionary=first_draw.duplicate(true)
	# First timestamp is already immutable. Everything below is post-verification.
	var post_started: int=Time.get_ticks_usec()
	if not check(measurement.trusted_scene_same and measurement.trusted_id==String(id) and measurement.trusted_token>0 and measurement.trusted_sources_finalized and measurement.trusted_source_count>0,"First draw itself is native finalized same-city owner, not late QA backfill"): return false
	var proof: Dictionary=C.resident_receipt(scene)
	var config: Dictionary=four_api.describe(id,proof.get("sources",{}))
	var source_paths: Dictionary=C._transition_sources(proof.get("source_scene"),false) if not proof.is_empty() else {}
	if not check(not proof.is_empty() and not config.is_empty() and proof.get("proof_kind")==FOUR_KIND and proof.get("sources_finalized")==true and int(proof.token)==int(measurement.trusted_token) and source_paths.size()==proof.sources.size(),"Full runtime first/final source owner + exact native publication source contract; no runtime geometry-rerun claim"): return false
	for path: String in source_paths:
		if not check(proof.sources.has(path),"Complete actual collector path present "+path): return false
	for path: String in source_before:
		if proof.sources.has(path) and not check(proof.sources[path]==source_before[path].sha256,"Actual finalized source agrees with independent frozen core "+path): return false
	var lease_after: Dictionary=router.call("get_resident_city_state")
	if not check(lease_after.get("return",{}).get("hit",false)==false,"First different-city load was not resident warm hit",lease_after): return false
	city_source_maps[String(id)]=proof.sources.duplicate(true)
	var record_actual: Dictionary=C._records.get(String(id),{}).duplicate(true)
	oracle=RAW.new()
	var delta: Dictionary=oracle.compile_delta(author,author.districts[String(id)])
	if not check(not record_actual.is_empty() and oracle.configure_record(record_actual,C._masks[String(id)],delta),"Only actual spawn/short step independent combined oracle; not old full route replay"): return false
	var player: CharacterBody2D=field.get("_player")
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	if not check(String(scene.scene_id)==String(id) and scene.actor_positions_are_feet and Vector2(field.get("_world_size"))==Vector2(3072,2048) and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==Vector2(34,24) and shape.position==Vector2.ZERO and _clear(player.position),"Actual correct FieldScene/native34x24 child0/spawn full87517+Physics"): return false
	var step: PackedVector2Array=PackedVector2Array()
	for offset: Vector2 in [Vector2(16,0),Vector2(-16,0),Vector2(0,16),Vector2(0,-16)]:
		var route: PackedVector2Array=PackedVector2Array([player.position,player.position+offset])
		if oracle.path([route[0],route[1]],false,deadline).get("clear",false): step=route;break
	if not check(step.size()==2,"A finite legal16px cardinal INPUT test from actual default foot, no player teleport"): return false
	if not await _walk(step): return false
	records.append({"kind":"FOUR_CITY_FIRST_ENTRY_METRIC","scene_id":String(id),"first_draw":measurement,"user10s_target_met":int(measurement.elapsed_usec)<10000000,"post_verify_and_small_input_usec":Time.get_ticks_usec()-post_started,"lease_before":lease_before,"lease_after":lease_after,"proof_kind":proof.proof_kind,"complete_actual_source_map":proof.sources.duplicate(true),"collector_count":source_paths.size(),"no_new_independent_full_asset_SHA_loop":true,"process_first_per_ID_not_SSD_cold":true,"public_default_setup_not_between_city_travel":true,"actual_portal_count":field.get("_exit_nodes").size(),"actual_NPC_count":field.get("_npc_nodes").size()})
	return await _capture("first_public_default_"+String(id))

func _exercise() -> bool:
	for id: StringName in FOUR_IDS:
		if not await _first_city(id): return false
	return check(seen_city_ids.size()==4 and city_source_maps.size()==4,"Four independent per-ID first entry records in one bounded process")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+160000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_four_city_first_entry_20261018r/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		RenderingServer.frame_post_draw.connect(_r_draw)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
	draw_target=""
	if RenderingServer.frame_post_draw.is_connected(_r_draw): RenderingServer.frame_post_draw.disconnect(_r_draw)
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":160000,"per_arrival_ms":60000,"captures":captures,"native_queries":native_queries,"per_ID_first_entries":seen_city_ids.keys(),"same_R_firstdraw_instrument":true,"full_C_firstfinal_sources_preserved":true,"helper_publication_geometry_not_runtime_rebuild":true,"not_fresh_process_each_city_or_SSD_cold":true,"not_world_travel_warm_rooms_old_CPU_or_fullroutes":true})
	finish(folder,began,complete,"R_FOUR_CITY_FIRST_PUBLIC_ENTRY_LIGHT_METRICS_AND_CORRECTNESS")
