extends "res://tests/test_luoyang_loading_baseline_ready_20261018r.gd"
## NOTREADY. One normal world96px/Space Gate arrival,32px INPUT and Space out.
## No warm retry/four-city/room/full-world visual suite.160s whole/60s arrival.
const SAVED_SOURCE_READY=true
const SAVED_CORE="res://tests/fixtures/luoyang_saved_source_core_20261018s.json"
const SAVED_CORE_SHA="f1fa923d3b094b9bf0e455bd11fea357455c87231170ee7fd22c9957039a3d25"
const SAVED_DELTA="res://tests/fixtures/luoyang_saved_source_delta_20261018s.json"
const SAVED_DELTA_SHA="6697e661f6200e2f3bf5ecf59d8b41de477aad18feaeeb87ff6014234e575ddc"
const SAVED_BASE_RESULT="res://build/luoyang_four_city_first_entry_formal_20261018r/111196_2763/result.json"
const SAVED_BASE_RESULT_SHA="733407cb5ce12a6959f4a082994fd7af81e40776f4f56d4c0e41c1db18a32956"
const SAVED_BASE_TOOL="res://tests/test_luoyang_loading_baseline_ready_20261018r.gd"
const SAVED_BASE_TOOL_SHA="d2b7dece0bc4a53768394c817eeadf337e9f258c21fd75ade71dbcc073cca8c8"
const SAVED_PROOF_KIND="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1"
var saved_expected: Dictionary={}

func precheck() -> bool:
	if not check(SAVED_SOURCE_READY,"NOTREADY until exact successor index/manifest/Temple/core and explicit delta frozen"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty() and LEASE.LIVE_WORLD_FORMAL_ENABLED,"Ordinary current source/native clock/no flags; not whitespace-canonicalization bypass"): return false
	for pair: Array in [[SAVED_CORE,SAVED_CORE_SHA],[SAVED_DELTA,SAVED_DELTA_SHA],[SAVED_BASE_RESULT,SAVED_BASE_RESULT_SHA],[SAVED_BASE_TOOL,SAVED_BASE_TOOL_SHA]]:
		if not track(pair[0],pair[1]): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVED_CORE))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVED_BASE_RESULT))
	var found: int=0
	for row: Dictionary in prior.records:
		if row.get("kind")=="FOUR_CITY_FIRST_ENTRY_METRIC" and row.get("scene_id")==GATE_ID:
			saved_expected=row.complete_actual_source_map.duplicate(true);found+=1
	if not check(prior.complete==true and prior.failures==0 and found==1 and not saved_expected.is_empty(),"Exact prior successful Gate whole source map, not fixed-count seed"): return false
	var delta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVED_DELTA))
	if not check(delta.get("changed") is Dictionary and not delta.changed.is_empty() and delta.get("added") is Dictionary and delta.get("removed") is Array and delta.removed.is_empty(),"Explicit old->new authority mapping, no deleted legacy leaves"): return false
	for path: String in delta.changed:
		var item: Dictionary=delta.changed[path]
		if not check(item.size()==2 and saved_expected.get(path)==item.old and String(item.new).length()==64,"Exact former authority value before single authorized replacement "+path): return false
		saved_expected[path]=item.new
	for path: String in delta.added:
		if not check(not saved_expected.has(path) and String(delta.added[path]).length()==64,"Only explicitly new source authority path "+path): return false
		saved_expected[path]=delta.added[path]
	package=R.binding();author=R.author(package)
	return check(not package.is_empty() and not author.is_empty(),"Current unchanged actual district source-bound geometry")

func _post_gate(warm: bool) -> bool:
	if not check(not warm,"No warm suite hidden in saved-source entry regression"): return false
	if not super._post_gate(false): return false
	var proof: Dictionary=C.resident_receipt(scene)
	if not check(proof.get("proof_kind")==SAVED_PROOF_KIND and C._equal_value(baseline_sources,saved_expected) and C._equal_value(proof.get("sources",{}),saved_expected),"Complete independently expected successor source map exact, not current-auto-accept or runtime geometry claim"): return false
	records.append({"kind":"S_EXPLICIT_COMPLETE_SOURCE_ADMISSION","expected_complete_map":saved_expected.duplicate(true),"actual_complete_map":baseline_sources.duplicate(true),"all_postverify_after_first_draw":true,"no_general_whitespace_normalization":true})
	return true

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for item: Dictionary in definition.map_layout.portals:
		if item.get("target_scene")==GATE_ID: portals.append(item)
	if not check(portals.size()==1,"Immutable original unique Gate world portal"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192)
	var setup: Vector2=entry+Vector2(0,96)
	_arm_draw(WORLD_ID,"S_LEGAL_NEAR_SETUP_NOT_WORLD_FIRST_PARSE_PERFORMANCE")
	if not check(router.call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15),"Normal public legal world setup, not direct city load") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID) or not await _space_to(GATE_ID,"S_REAL_WORLD96_SPACE_GATE_SAVED_SOURCE"): return false
	district="gate";scene_id=GATE_ID
	if not _bind_actual() or not check(GATE.bound(field.get("_harbour_gate_visual_scene")) and field.get("_player").position==Vector2(1536,1860),"Real formal Gate/immutable original arrival/native34x24/full87517"): return false
	if not await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860),Vector2(1536,1860)])) or not _zone("","world_map"): return false
	if not await _capture("saved_source_ordinary_Gate_after_real_Space_and32px"): return false
	if not await _space_to(WORLD_ID,"S_REAL_GATE_SPACE_WORLD_EXIT") or not _world_bind(): return false
	records.append({"kind":"S_ORDINARY_ENTRY_SCOPE","whole_ms":160000,"arrival_ms":60000,"actual_world96_and_city32_INPUT":true,"ordinary_no_flags":true,"one_Gate_image":true,"no_warm_fourcity_rooms_or_fullworld_visual_suite":true,"historical_publication_proof_not_rewritten":true})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+160000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_saved_source_gate_entry_20261018s/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
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
	records.append({"kind":"SCOPE","whole_ms":160000,"arrival_ms":60000,"captures":captures,"native_queries":native_queries,"expected_full_source_count":saved_expected.size(),"complete_expected_identity_and15save_preserved":true})
	finish(folder,began,complete,"S_ORDINARY_REAL_WORLD96_SPACE_GATE32_SPACE_WORLD_CURRENT_EXACT_SOURCE")
