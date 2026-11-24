extends "res://tests/test_luoyang_public_async_loading_key_retry2_20261015.gd"
## ROOT-only GPU key. No production writes, candidate flags or all-city replay.
## First public birth is setup, two real inn roundtrips; one extra entry only
## proves NEW_GAME_RESET frees an actually occupied single resident slot.
const RESIDENT_PARENT_SHA := "e2d8bd7bb803863bb6c2b1ed5b5e8464fa54ae916cda07e6d04d011e0ad8f88c"
const RESIDENT_PINS := {
	"res://scripts/autoload/scene_router.gd":"843bf7afeaaf321d8931db689a846254ba30ce0a868c5b8eb5446be9ff7ad73e",
	"res://scripts/autoload/loading_manager.gd":"d3dff3a613707774e38c1888cd8d9eae3611f6f35be1e7c96a7b4234e7578c17",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"3b591067c28ad118de5f6d32e4bcf8d3cad7a1f091169f495590fdf3e6733a98",
	"res://scripts/field/field_walkable_controller.gd":"71b54611d29c0b08ca1cb688b33b33346a293f744bc84e603b89eb8c527986be",
	"res://scripts/city/luoyang_resident_field_20261016.gd":"b49b3674197df795ff1fa0c1b1a3d5d7b9e7977ae08ad6799c857d074ed6eabf"
}
const RESIDENT_STAND := Vector2(735,894)
const PAPER_QUEST := &"q_ch4_side_02_luoyang_paper"
const PAPER_FLAG := &"luoyang_paper_started"
const RETURN_LIMIT_MS := 2000.0
var resident_trips: Array[Dictionary] = []
var resident_cancel: Dictionary = {}
var resident_release: Dictionary = {}
var resident_source_activity: Array[Dictionary] = []
var watch_resident_jobs := false
var retained: Node
var retained_identity: Dictionary = {}
var retained_nav: Dictionary = {}
var retained_connections := 0
var retained_mode := 0
var retained_validations := 0
var resident_initial_scene: SceneScript
var isolated_quest_expected: Dictionary = {}
var resident_input_count := 0

func _resident_expected(path: String,old_sha: String) -> String:
	if RESIDENT_PINS.has(path): return String(RESIDENT_PINS[path])
	return FORMAL_RUNTIME_SHA if path==REVISION_PATH else old_sha

func _precheck_revision() -> bool:
	# Exactly five authorized source paths, never a general current-hash waiver.
	if not _track_source("res://tests/test_luoyang_public_async_loading_key_retry2_20261015.gd",RESIDENT_PARENT_SHA): return false
	for path: String in RESIDENT_PINS:
		if not _track_source(path,RESIDENT_PINS[path]): return false
	for path: String in LIVE_ROOM_IMPORT_PINS:
		if not _track_source(path,LIVE_ROOM_IMPORT_PINS[path]): return false
	if not _track_source("res://tests/test_luoyang_revision_formal_boot_key_20261015.gd",FORMAL_PARENT_SHA): return false
	if not _track_source(FROZEN_PARENT_PATH,FROZEN_PARENT_SHA) or not _track_source(FALSE_RUNTIME_BACKUP,FALSE_RUNTIME_SHA) or not _track_source(REVISION_PATH,FORMAL_RUNTIME_SHA): return false
	var false_text:=FileAccess.get_file_as_string(FALSE_RUNTIME_BACKUP)
	var old_literal:="const FORMAL_ENABLED := false"
	if not _check(false_text.count(old_literal)==1 and false_text.replace(old_literal,"const FORMAL_ENABLED := true")==FileAccess.get_file_as_string(REVISION_PATH),"Unchanged exact ROOT formal runtime bool provenance"): return false
	for path: String in RUNTIME_PINS:
		if not _track_source(path,_resident_expected(path,String(RUNTIME_PINS[path]))): return false
	for path: String in UTILITY_PINS:
		if not _track_source(path,UTILITY_PINS[path]): return false
	for atom: Dictionary in ACCEPTED_ATOMS:
		if not _track_source(atom.path,atom.sha): return false
		var evidence: Variant=JSON.parse_string(FileAccess.get_file_as_string(atom.path))
		if not _check(evidence is Dictionary and evidence.get("scope")==atom.scope and evidence.get("complete")==true and evidence.get("failures")==0 and evidence.get("source_before") is Dictionary,"Exact completed source geometry atom "+atom.scope): return false
		for path: String in evidence.source_before:
			if not _track_source(path,_resident_expected(path,String(evidence.source_before[path].sha256))): return false
	revision=load(REVISION_PATH) as Script
	if not _check(revision!=null and revision.get_script_constant_map().get("FORMAL_ENABLED")==true,"Ordinary default formal runtime unchanged"): return false
	var publication: Dictionary=PUBLICATIONS[MARKET_ID]
	if not _track_source(publication.result,publication.sha) or not _track_source(publication.manifest,publication.manifest_sha): return false
	proof=JSON.parse_string(FileAccess.get_file_as_string(publication.result))
	published=JSON.parse_string(FileAccess.get_file_as_string(publication.manifest))
	for path: String in revision.call("source_paths"):
		if not source_before.has(path): source_before[path]=_file(path)
		_check(source_before[path].exists,"Complete default runtime source exists "+path)
	for path: String in ["res://scripts/autoload/quest_manager.gd","res://data/quests/q_ch4_side_02_luoyang_paper.tres"]:
		source_before[path]=_file(path)
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	return failures==0

func _resident_state() -> Dictionary:
	return root.get_node("SceneRouter").call("get_resident_city_state")

func _transition_busy(manager: Node) -> bool:
	return bool((_resident_state().get("return",{}) as Dictionary).get("active",false)) or super._transition_busy(manager)

func _resident_frame() -> void:
	if not watch_resident_jobs: return
	var state: Dictionary=C.transition_validation_state()
	if state.get("source_worker_active",false) or state.get("base_cpu_worker_active",false) or state.get("navigation_worker_active",false) or state.get("revision_worker_active",false) or C._live_module_task>=0 or C._live_module_job!=null:
		resident_source_activity.append({"frame":Engine.get_process_frames(),"state":state})

func _hidden_operable() -> bool:
	var manager: Node=root.get_node("LoadingManager")
	var screen: Node=manager.get("_screen") as Node
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	var player: Node=field.get("_player") as Node if is_instance_valid(field) else null
	return not _transition_busy(manager) and (panel==null or not panel.is_visible_in_tree()) and is_instance_valid(player) and player.is_inside_tree() and bool(player.get("can_move")) and field.process_mode!=Node.PROCESS_MODE_DISABLED

func _wait_hidden_operable() -> bool:
	var until:=mini(deadline,Time.get_ticks_msec()+60000)
	while Time.get_ticks_msec()<until:
		await process_frame
		if _hidden_operable(): return true
	return _check(false,"Actual Loading hidden and native player operable within arrival60/shared180")

func _identity(node: Node) -> Dictionary:
	var player: Node=node.get("_player") as Node
	var image: Image=node.get("_walkable_mask_image") as Image
	var guard: RefCounted=node.get("_city3_motion_guard") as RefCounted
	var world: Node=node.get("world_container") as Node
	var canvas: CanvasLayer=node.get("_hud_canvas_layer") as CanvasLayer
	var background: Node=node.get("_world_background") as Node
	return {"Field":node.get_instance_id(),"Player":player.get_instance_id() if is_instance_valid(player) else 0,"world":world.get_instance_id() if is_instance_valid(world) else 0,"HUD_canvas":canvas.get_instance_id() if is_instance_valid(canvas) else 0,"Field_canvas_item":(node as CanvasItem).get_canvas_item().get_id(),"background":background.get_instance_id() if is_instance_valid(background) else 0,"mask":image.get_instance_id() if image!=null else 0,"guard":guard.get_instance_id() if guard!=null else 0}

func _singleton_connection_count(node: Node) -> int:
	var count:=0
	for emitter: Node in root.get_children():
		if emitter==node: continue
		for definition: Dictionary in emitter.get_signal_list():
			for connection: Dictionary in emitter.get_signal_connection_list(StringName(definition.name)):
				var callback: Callable=connection.callable
				var target: Object=callback.get_object()
				if target is Node and (target==node or node.is_ancestor_of(target as Node)): count+=1
	return count

func _native_paper_count() -> int:
	var count:=0
	for npc: Node in field.get("_npc_nodes"):
		if String(npc.get("npc_id"))=="luoyang_paper_scholar" and (npc as CanvasItem).is_visible_in_tree(): count+=1
	return count

func _negative_receipts() -> bool:
	var actual: Dictionary=C.resident_receipt(candidate_scene)
	if not _check(not actual.is_empty() and C.resident_matches(actual.duplicate(true),candidate_scene),"Real finalized receipt accepts exact value clone"): return false
	var source_path: String=String(actual.sources.keys()[0])
	var sha_forged: Dictionary=actual.duplicate(true)
	sha_forged.sources[source_path]="0".repeat(64) if actual.sources[source_path]!="0".repeat(64) else "1".repeat(64)
	_check(not C.resident_matches(sha_forged,candidate_scene),"Clone-only fake per-path SHA rejected by trusted finalized proof")
	var stamp_forged: Dictionary=actual.duplicate(true)
	stamp_forged.stamps[source_path].length=int(stamp_forged.stamps[source_path].length)+1
	_check(not C.resident_matches(stamp_forged,candidate_scene),"Clone-only fake source length stamp rejected")
	var stamp_time: Dictionary=actual.duplicate(true)
	stamp_time.stamps[source_path].mtime_seconds=int(stamp_time.stamps[source_path].mtime_seconds)+1
	_check(not C.resident_matches(stamp_time,candidate_scene),"Clone-only fake source mtime stamp rejected")
	var changed: SceneScript=candidate_scene.duplicate(true) as SceneScript
	changed.set_meta("city_frontage_revision_runtime_status","QA_CLONE_NOT_TRUSTED")
	var changed_receipt: Dictionary=actual.duplicate(true)
	changed_receipt.scene=changed
	_check(not C.resident_matches(changed_receipt,changed),"Cloned scene with modified metadata cannot replace trusted source identity")
	_check(C.resident_matches(actual,candidate_scene),"Negative clones never mutate actual Scene/proof/source")
	rows.append({"kind":"RESIDENT_CLONE_NEGATIVES","changed_only_clones":true,"path":source_path,"source_count":actual.sources.size(),"mtime_precision":"SECONDS_NOT_FORGED_TIMESTAMP_PROOF","disk_metadata_changed":false})
	return failures==0

func _retain_before_entry() -> bool:
	retained=field; retained_identity=_identity(retained); retained_nav=_nav_snapshot()
	retained_connections=_singleton_connection_count(retained); retained_mode=retained.process_mode
	retained_validations=C._transition_full_validations; resident_initial_scene=candidate_scene
	return _check(retained_connections>0 and _clear(RESIDENT_STAND) and not C.resident_receipt(candidate_scene).is_empty(),"Source-ready exterior native identities and real global signal connections captured before park")

func _parked_assert(label: String) -> bool:
	if not _check(is_instance_valid(retained),"Retained exterior remains allocated "+label): return false
	var old_player: CharacterBody2D=retained.get("_player") as CharacterBody2D
	var state:=_resident_state()
	var body_space: RID=PhysicsServer2D.body_get_space(old_player.get_rid())
	var old_canvas: CanvasLayer=retained.get("_hud_canvas_layer") as CanvasLayer
	var connections:=_singleton_connection_count(retained)
	rows.append({"kind":"PARKED_EXTERIOR_ISOLATION","label":label,"resident":state,"identity":_identity(retained),"outside_tree":not retained.is_inside_tree(),"body_space_valid":body_space.is_valid(),"global_connections":connections,"prior_connections":retained_connections,"original_HUD_inside":old_canvas.is_inside_tree(),"old_player_can_move":old_player.get("can_move")})
	return _check(current_scene==field and current_scene!=retained and not retained.is_inside_tree() and retained.get_parent()==null and not old_player.is_inside_tree() and not old_canvas.is_inside_tree() and not body_space.is_valid() and connections==0 and retained.get("_resident_parked")==true and old_player.get("can_move")==false and state.get("occupied")==true and state.get("parked")==true and int(state.get("field_id",0))==retained.get_instance_id() and _identity(retained)==retained_identity and _nav_equal(retained_nav),"Original exterior detached from tree/Physics/canvas/global signals with unchanged retained identities/nav "+label)

func _normal_inn_entry(label: String) -> bool:
	if not _overlap_target(INN_ID): return false
	var started:=Time.get_ticks_usec()
	await driver.call("key",KEY_SPACE); resident_input_count+=1
	if not await _wait_revision(INN_ID) or not await _wait_hidden_operable(): return false
	transitions.append({"kind":"REAL_SPACE_INN_ENTRY","label":label,"total_ms":(Time.get_ticks_usec()-started)/1000.0,"no_router_shortcut":true,"arrival_limit_ms":60000})
	return _check(candidate_scene.map_layout.get_meta("home_template_id","")=="inn_hall" and _clear((field.get("_player") as Node2D).position),"Actual original inn template full875/17/Physics "+label) and _parked_assert(label)

func _approach_room_exit(label: String) -> bool:
	var exit: Dictionary=candidate_scene.map_layout.portals[0]
	var target: Vector2=exit.pos*(field.get("_world_size") as Vector2)-Vector2(0,36)
	return await _way(PackedVector2Array([(field.get("_player") as Node2D).position,target]),label) and _overlap_target(MARKET_ID)

func _cancel_return_once() -> bool:
	# Deliberately white-box PUBLIC API cancellation, not a claimed Space trip.
	var router: Node=root.get_node("SceneRouter")
	var room: Node=field
	var player: Node2D=field.get("_player") as Node2D
	var origin:=player.position
	var exit: Dictionary=candidate_scene.map_layout.portals[0]
	# This existing public method returns void: acceptance is the real QUEUED
	# state, not a fabricated boolean return contract.
	router.call("go_field_from_portal",StringName(MARKET_ID),exit.target_pos,origin/(field.get("_world_size") as Vector2),"")
	var before: Dictionary=_resident_state()
	var queued: Dictionary=before.get("return",{})
	var token:=int(queued.get("token",0))
	var accepted: bool=queued.get("active")==true and queued.get("phase")=="QUEUED" and token>0
	var started:=Time.get_ticks_usec()
	var cancelled: bool=bool(router.call("cancel_public_city_preparation",token))
	var cancel_usec:=Time.get_ticks_usec()-started
	if not await _wait_hidden_operable(): return false
	await process_frame; await process_frame
	var after:=_resident_state()
	resident_cancel={"whitebox_public_API_not_input_trip":true,"accepted":accepted,"queued":queued,"cancelled":cancelled,"cancel_usec":cancel_usec,"after":after,"same_room":current_scene==room,"same_Player":room.get("_player")==player,"origin":player.position,"token":token}
	rows.append({"kind":"RESIDENT_RETURN_PREPARE_CANCEL","receipt":resident_cancel})
	return _check(accepted and token>0 and queued.get("phase")=="QUEUED" and cancelled and (after.get("return",{}) as Dictionary).get("phase")=="CANCELLED" and current_scene==room and room.get("_player")==player and player.position==origin and _clear(origin) and C._transition_full_validations==retained_validations,"Immediate public prepare cancel preserves current room and parked source; no cold validation") and _parked_assert("after_cancel")

func _normal_resident_return(dirty: bool) -> bool:
	if not _overlap_target(MARKET_ID): return false
	var old_room: WeakRef=weakref(field)
	var started:=Time.get_ticks_usec()
	await driver.call("key",KEY_SPACE); resident_input_count+=1
	if not await _wait_revision(MARKET_ID) or not await _wait_hidden_operable(): return false
	# End-to-end includes real Input, source checks, attaching/rebuilding,
	# independent binder, native safety checks and Loading completely hidden.
	var hidden_operable_ms: float=(Time.get_ticks_usec()-started)/1000.0
	var actual_identity:=_identity(field)
	var resident:=_resident_state()
	var state:=_state("DIRTY_LIVE_RETURN" if dirty else "CLEAN_RESIDENT_RETURN")
	var same_identity: bool=actual_identity==retained_identity
	var record: Dictionary={"kind":"REAL_SPACE_RESIDENT_RETURN","dirty":dirty,"end_to_end_hidden_operable_ms":hidden_operable_ms,"limit_ms":RETURN_LIMIT_MS,"router_receipt":resident.get("return",{}),"identity_before":retained_identity.duplicate(true),"identity_after":actual_identity,"original_full_validation_count":retained_validations,"actual_full_validation_count":C._transition_full_validations,"cold_source_jobs_observed":resident_source_activity.size(),"old_room_released":old_room.get_ref()==null,"state":state,"Loading_hidden_and_operable":_hidden_operable(),"actual_remembered_return_foot":RESIDENT_STAND,"authored_marker_foot":Vector2(735,854)}
	resident_trips.append(record); transitions.append(record)
	if not _check(hidden_operable_ms<RETURN_LIMIT_MS and current_scene==retained and field==retained and field.get("_current_scene")==resident_initial_scene and (field.get("_player") as Node2D).position.distance_to(RESIDENT_STAND)<.03 and _clear(RESIDENT_STAND) and field.process_mode==retained_mode and field.get("_resident_parked")==false and resident.get("occupied")==false and (resident.get("return",{}) as Dictionary).get("phase")=="READY" and old_room.get_ref()==null and _nav_equal(retained_nav) and C._transition_full_validations==retained_validations and resident_source_activity.is_empty(),"Real Space returns same exterior under2000ms INCLUDING hidden Loading/operability and precise40px remembered foot; no cold rebuild"): return false
	if not dirty:
		if not _check(same_identity and _singleton_connection_count(field)==retained_connections,"Clean return keeps exact Field/Player/world/HUD/canvas/mask/guard identities and restores global signals"): return false
	else:
		var quests: Node=root.get_node("QuestManager")
		if not _check(actual_identity.Field==retained_identity.Field and root.get_node("GameState").call("get_flag",PAPER_FLAG)==true and C._equal_value(quests.call("to_dict"),isolated_quest_expected) and _native_paper_count()==0 and int(quests.call("get_status",PAPER_QUEST))==1,"Dirty room flag and real quest remain live; same exterior refreshes hidden scholar instead of restoring stale snapshot"): return false
	# Separate actual normal input proves the newly operable state, no teleport.
	return await _way(PackedVector2Array([RESIDENT_STAND,RESIDENT_STAND+Vector2(16,0),RESIDENT_STAND]),"normal_INPUT_after_"+("dirty" if dirty else "clean")+"_resident_return")

func _newgame_occupied_release() -> bool:
	if not _retain_before_entry() or not await _normal_inn_entry("release_only_third_entry_no_roundtrip"): return false
	var old: WeakRef=weakref(retained)
	var room: Node=field
	var router: Node=root.get_node("SceneRouter")
	var before:=_resident_state()
	retained=null; resident_initial_scene=null
	router.call("reset_for_new_game")
	await process_frame; await physics_frame
	var after:=_resident_state()
	resident_release={"before":before,"after":after,"old_exterior_released":old.get_ref()==null,"current_room_preserved":current_scene==room,"extra_entry_only_not_third_roundtrip":true}
	rows.append({"kind":"ACTUAL_NEW_GAME_SINGLE_SLOT_RELEASE","receipt":resident_release})
	return _check(before.get("occupied")==true and after.get("occupied")==false and after.get("phase")=="RELEASED" and after.get("reason")=="NEW_GAME_RESET" and old.get_ref()==null and current_scene==room and C._resident_ready.is_empty(),"Actual new-game reset frees occupied retained exterior and receipt, leaves no second resident slot")

func _exercise_resident() -> void:
	if not await _public_enter(Vector2(735,920),"PUBLIC_INITIAL") or not await _wait_hidden_operable(): return
	active_tag=""
	if not _check(_native_paper_count()==1,"Initial native scholar visible before dirty flag"): return
	if not await _way(PackedVector2Array([Vector2(735,920),RESIDENT_STAND]),"ordinary_final26px_40px_before_authored_door") or not await _fade("inn",false,"resident_front_alpha1"): return
	if not _negative_receipts() or not _retain_before_entry(): return
	watch_resident_jobs=true
	if not await _normal_inn_entry("trip1_clean"): return
	captures.append(await _capture_gate("first_actual_inn_exterior_detached"))
	if not await _approach_room_exit("trip1_real_indoor_INPUT") or not await _cancel_return_once() or not await _normal_resident_return(false): return
	if not _retain_before_entry() or not await _normal_inn_entry("trip2_dirty"): return
	var quests: Node=root.get_node("QuestManager")
	var state_before: Dictionary=quests.call("to_dict")
	var accepted: bool=bool(quests.call("accept",PAPER_QUEST))
	root.get_node("GameState").call("set_flag",PAPER_FLAG,true)
	isolated_quest_expected=quests.call("to_dict")
	rows.append({"kind":"ROOM_ISOLATED_MEMORY_DIRTY_STATE","quest":PAPER_QUEST,"quest_before":state_before,"quest_after":isolated_quest_expected,"accepted":accepted,"flag":PAPER_FLAG,"checkpoint_held":root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"disk_save_called":false})
	if not _check(accepted and not C._equal_value(state_before,isolated_quest_expected) and _singleton_connection_count(retained)==0,"Actual real quest acceptance/flag in isolated room memory while parked Field signals stay disconnected"): return
	if not await _approach_room_exit("trip2_real_indoor_INPUT") or not await _normal_resident_return(true): return
	captures.append(await _capture_gate("second_return_actual_live_flag_and_quest"))
	if not await _newgame_occupied_release(): return
	watch_resident_jobs=false

func _run() -> void:
	var started:=Time.get_ticks_msec(); deadline=started+180000
	output="res://build/luoyang_resident_field_key_20261016/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique resident finite key output")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoint suspended before any await")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-resident-field-key" in args and not REVISION_FLAG in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not "--luoyang-market-enrichment-candidate-20261014" in args,"Ordinary resident key, no candidate map selection")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual installed GPU engine normal clock")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_observe_loading_frame); process_frame.connect(_resident_frame)
		RenderingServer.frame_post_draw.connect(_observe_post_draw)
		await _exercise_resident()
	watch_resident_jobs=false; active_tag=""
	if process_frame.is_connected(_observe_loading_frame): process_frame.disconnect(_observe_loading_frame)
	if process_frame.is_connected(_resident_frame): process_frame.disconnect(_resident_frame)
	if RenderingServer.frame_post_draw.is_connected(_observe_post_draw): RenderingServer.frame_post_draw.disconnect(_observe_post_draw)
	var router: Node=root.get_node("SceneRouter")
	var pending: Dictionary=(_resident_state().get("return",{}) as Dictionary)
	if pending.get("active",false): router.call("cancel_public_city_preparation",int(pending.get("token",0)))
	var public_pending:=_public_state()
	if public_pending.get("active",false): router.call("cancel_public_city_preparation",int(public_pending.get("token",0)))
	# Always release a parked exterior even when an assertion failed early.
	router.call("reset_for_new_game")
	retained=null; resident_initial_scene=null
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Final independent original navigation sources stable"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	var source_after:=_sources()
	var players_after:=_players()
	_check(source_after==source_before and players_after==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"All inherited source closure/new helper/15save/slot/checkpoint exact unchanged")
	_check(Time.get_ticks_msec()<deadline and resident_trips.size()==2 and resident_input_count==5 and captures.size()==3 and not resident_cancel.is_empty() and not resident_release.is_empty() and resident_source_activity.is_empty(),"One shared180/arrival60: two real trips, one explicit prepare cancel, release-only entry and three GPU frames complete")
	var result: Dictionary={"scope":"ORDINARY_MARKET_RESIDENT_TWO_INN_TRIPS_CANCEL_DIRTY_NEWGAME_ONLY","complete":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"budget_ms":180000,"arrival_ms":60000,"return_hidden_operable_limit_ms":RETURN_LIMIT_MS,"records":rows,"transitions":transitions,"resident_trips":resident_trips,"resident_prepare_cancel":resident_cancel,"newgame_occupied_release":resident_release,"cold_source_activity_after_birth":resident_source_activity,"entry_stats":entry_stats,"stage_samples":stage_samples,"arrival_observations":observations,"captures":captures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"authorized_five_source_pins":RESIDENT_PINS,"return_clock_includes_Loading_hidden_and_operable":true,"first_public_is_setup_not_world_travel":true,"new_fifth_layer_tasks_or_all_city_or_all_loading_claim":false,"ROOT_outer_exactticks_and_complete_stderr_natural_exit_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_RESIDENT_FIELD_KEY="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
