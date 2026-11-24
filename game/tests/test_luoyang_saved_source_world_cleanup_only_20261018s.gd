extends "res://tests/test_luoyang_saved_source_gate_entry_ready_20261018s.gd"
## Independent cleanup-domain correction only. Prior34260 remains whole FAIL.
## No96px route/Space/Gate/capture/repeated entry; one actual world setup+exit.
const CLEANUP_BASE="res://tests/test_luoyang_saved_source_gate_entry_ready_20261018s.gd"
const CLEANUP_BASE_SHA="c0ffa73adeb5edb7216746aa6134170b0b365c75f56ddc7b254b98eb52c3e927"
const PARTIAL="res://build/luoyang_saved_source_gate_entry_20261018s/34260_2730/result.json"
const PARTIAL_SHA="21f2015d72685f7aca450acfeb04c68ea7bce014e890bef2ae726f1bd6152a03"
const CLEANUP_STREAM="res://scripts/world/world_v15_visible_stream_20261018r.gd"
var cleanup_stream_api: Variant

func precheck() -> bool:
	if not super.precheck(): return false
	if not track(CLEANUP_BASE,CLEANUP_BASE_SHA) or not track(PARTIAL,PARTIAL_SHA): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PARTIAL))
	if not check(prior.complete==false and prior.failures==2 and prior.checks==2177,"Preserve original34260 whole FAIL; no replacement result/backfill"): return false
	var exit_rows: Array=[]
	for row: Dictionary in prior.records:
		if row.get("kind")=="ACTUAL_OWN_FIELD_TREE_EXIT": exit_rows.append(row)
	if not check(exit_rows.size()==1 and exit_rows[0].tree_exited==true and exit_rows[0].field_gone==true and exit_rows[0].released_lease.is_empty(),"Original failure was district-release predicate on actual exited world with no district lease"): return false
	cleanup_stream_api=load(CLEANUP_STREAM)
	return check(cleanup_stream_api!=null,"Current source-pinned real world stream cleanup API")

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for item: Dictionary in definition.map_layout.portals:
		if item.get("target_scene")==GATE_ID: portals.append(item)
	if not check(portals.size()==1,"Only choose one original legal world setup, not activating portal"): return false
	_arm_draw(WORLD_ID,"S_CLEANUP_ONLY_WORLD_SETUP_NOT_TRAVEL_OR_PERFORMANCE")
	if not check(router.call("go_field_smart",StringName(WORLD_ID),portals[0].pos,"",15),"One actual ordinary public world setup") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	return check(field.get("_district_session")==null and is_instance_valid(field.get("_world_v15_stream")),"Actual world has stream owner and no district session; cannot require district release receipt")

func _leave_actual_field() -> bool:
	if not check(is_instance_valid(field) and String(scene.scene_id)==WORLD_ID and field.get("_district_session")==null,"World-specific real teardown domain, not a broad exemption"): return false
	var owned: Node=field
	var field_ref: WeakRef=weakref(owned)
	var stream_ref: WeakRef=weakref(owned.get("_world_v15_stream"))
	var observed: Dictionary={"tree_exited":false}
	owned.tree_exited.connect(func() -> void: observed.tree_exited=true,CONNECT_ONE_SHOT)
	owned.queue_free()
	await process_frame;await process_frame
	while cleanup_stream_api.drain_count()>0 and Time.get_ticks_msec()<deadline: await process_frame
	var released: bool=observed.tree_exited and field_ref.get_ref()==null and stream_ref.get_ref()==null and cleanup_stream_api.drain_count()==0
	records.append({"kind":"S_WORLD_CLEANUP_ONLY","tree_exited":observed.tree_exited,"Field_gone":field_ref.get_ref()==null,"stream_gone":stream_ref.get_ref()==null,"drain":cleanup_stream_api.drain_count(),"released":released,"world_district_session_was_null":true,"prior34260_whole_failure_unchanged":true,"no_repeated_route_or_entry_credit":true})
	field=null;scene=null
	return check(released,"Real owned world tree_exit releases actual stream and drains loader within original90s; no district receipt substitution")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_saved_source_world_cleanup_only_20261018s/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		RenderingServer.frame_post_draw.connect(_r_draw)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if complete and not await _leave_actual_field(): complete=false
	draw_target=""
	if RenderingServer.frame_post_draw.is_connected(_r_draw): RenderingServer.frame_post_draw.disconnect(_r_draw)
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	if is_instance_valid(field): field.queue_free()
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":90000,"arrival_ms":60000,"cleanup_only":true,"captures":captures,"native_queries":native_queries,"no_INPUT_Space_Gate_route_or_performance_credit":true})
	finish(folder,began,complete,"S_INDEPENDENT_WORLD_CLEANUP_ONLY_PRIOR34260_WHOLE_FAIL_PRESERVED")
