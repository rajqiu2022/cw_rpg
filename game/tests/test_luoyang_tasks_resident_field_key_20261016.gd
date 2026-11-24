extends "res://tests/test_luoyang_resident_field_key_retry2_20261016.gd"
## Only two city public setups, one clean inn trip and local native task checks.
## Original proven Scene/navigation remain separate from render-only task state.
const TASKS = preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
const TASK_PARENT_SHA := "307d7e6fca3cc4936453d48ec6f79de4f1e2839b8326c86acd372f6557e47c77"
const TASK_C_SHA := "0d107ce386760c8569aa2ab0e34ad8c1d3f8a9389954db1a9134f6604aade943"
const TASK_FIELD_SHA := "132f4e6b303280e515b757a51f05caf82fb0f0fb1202baa1233df3adb63a4f5b"
const TASK_HELPER_SHA := "27944bbb516bce10fad01b02efd714f1ce63029adcdaf83e701445962d34e13c"
const TASK_SPEC_SHA := "9e654f67be48a8da93232e0f2b66e109cdd769577fb53545f72f81885e90a3bb"
const TASK_IMPORT_PINS := {
	"res://art/characters/npc_zhuwei_merchant_idle_down_25d_4f_v3_runtime.png.import":"9fda7773357491b5ac1deba0724d1662733dfe41b63e0caceecea746c45c3bd4",
	"res://.godot/imported/npc_zhuwei_merchant_idle_down_25d_4f_v3_runtime.png-33c6d428abe09479c4ab453f6f22ab84.ctex":"802b5a16f255986eb98f645718ce307c0156676a52f3e6f91155c4830dd74366",
	"res://art/characters/portraits/generic/portrait_generic_older_man_v1.png.import":"797208885f59107d9e4aefbe7f8dbb434c73dba6616273ae4b4af1a4172dceea",
	"res://.godot/imported/portrait_generic_older_man_v1.png-0e6e98ee8462cb92ca318bad21e93849.ctex":"061551874aece8b35da4f26ec4cbc2a435d6e36b0a3424d79e9cbb7d402cc176"
}
const PHASE1_PATH := "res://build/luoyang_resident_field_key_20261016/101784_2649064/result.json"
const PHASE1_SHA := "321adb5b6fad3f2c4028943ec8029345c5771163078be13a77bb6b4c445a691d"
var task_city := MARKET_ID
var task_spec: Dictionary = {}
var task_sources: Dictionary = {}
var task_source_proof: Dictionary = {}
var task_source_finalized := false
var task_dialogs: Array[Dictionary] = []
var task_completed := false

func _city_id() -> String: return task_city

func _track_source(path: String,expected: String) -> bool:
	# Precisely two authorized post-phase1 changes, not arbitrary SHA folding.
	if path=="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd" and expected==RESIDENT_PINS[path]: expected=TASK_C_SHA
	elif path=="res://scripts/field/field_walkable_controller.gd" and expected==RESIDENT_PINS[path]: expected=TASK_FIELD_SHA
	return super._track_source(path,expected)

func _precheck_revision() -> bool:
	if not _track_source("res://tests/test_luoyang_resident_field_key_retry2_20261016.gd",TASK_PARENT_SHA) or not super._precheck_revision(): return false
	if not _track_source("res://scripts/city/luoyang_city_tasks_20261016.gd",TASK_HELPER_SHA) or not _track_source(TASKS.SPEC_PATH,TASK_SPEC_SHA): return false
	task_spec=JSON.parse_string(FileAccess.get_file_as_string(TASKS.SPEC_PATH))
	task_sources=TASKS.source_paths()
	if not _check(task_sources.size()==35 and task_spec.get("source_pins",{}).size()==33,"Exact35 task source leaves, not all quest-chain replay"): return false
	for path: String in task_spec.source_pins:
		if not _track_source(path,task_spec.source_pins[path]): return false
	for path: String in TASK_IMPORT_PINS:
		if not _track_source(path,TASK_IMPORT_PINS[path]): return false
	for path: String in [String(task_spec.market.artisan.sprite_path),String(task_spec.market.artisan.portrait_path)]:
		var config:=ConfigFile.new()
		var import_path:=path+".import"
		if not _check(config.load(import_path)==OK and config.get_value("deps","source_file","")==path and source_before.has(String(config.get_value("remap","path",""))),"Actual task texture native import/deps/remap closed "+path): return false
	if not _track_source(PHASE1_PATH,PHASE1_SHA): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PHASE1_PATH))
	if not _check(prior.get("complete")==true and prior.get("checks")==1765 and prior.get("failures")==0,"Exact accepted phase1 resident proof, never original offset FAIL"): return false
	for path: String in prior.source_before:
		if not _track_source(path,String(prior.source_before[path].sha256)): return false
	return failures==0

func _bind_revision() -> bool:
	if String(candidate_scene.scene_id)!=DOCKS_ID: return super._bind_revision()
	if oracle!=null: oracle.call("release"); oracle=null
	mask=null; polygons.clear(); inside_room=false
	var p: Dictionary=PUBLICATIONS[DOCKS_ID]
	if not _track_source(p.result,p.sha) or not _track_source(p.manifest,p.manifest_sha): return false
	published=JSON.parse_string(FileAccess.get_file_as_string(p.manifest))
	var record: Dictionary=(C._records.get(DOCKS_ID,{}) as Dictionary).duplicate(true)
	if not _check(bool(revision.call("bound",candidate_scene)) and not record.is_empty() and record.get("city_revision_binding_sha")==RUNTIME_PINS["res://art/maps/luoyang_city_revision_runtime_20261015/bindings.json"] and record.get("city_revision_manifest_sha")==p.manifest_sha and candidate_scene.get_meta("city_frontage_revision_manifest_sha","")==p.manifest_sha and candidate_scene.get_meta("city_frontage_revision_runtime_status","")=="ROOT_APPROVED_DEFAULT_REVISION" and C._equal_value(record.objects,published.objects) and C._equal_value(record.gameplay_slots,published.gameplay_slots) and C._equal_value(record.routes,published.routes) and record.ground_path==published.ground_path and record.walk_path==published.walk_path,"Actual default Docks source/manifest record, geometry/slots/routes unchanged by task render projection"): return false
	var declarations: Array[Dictionary]=[]
	for object: Dictionary in published.objects:
		var shapes: Array[PackedVector2Array]=[]
		var extent:=C._vec(object.collision_size_px)
		if extent.x>0 and extent.y>0:
			var rect:=Rect2(C._vec(object.physical_center_px)-extent*.5,extent)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for raw: Array in object.solid_polygons_px:
			var polygon:=PackedVector2Array()
			for pair: Array in raw: polygon.append(C._vec(pair))
			shapes.append(polygon)
		for shape: PackedVector2Array in shapes: polygons.append(shape)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
	var owned: Resource=candidate_scene.map_layout.duplicate(true)
	owned.set("visual_objects",declarations)
	oracle=SIMPLE_RAW.new()
	mask=Image.load_from_file(published.walk_path)
	return _check(bool(oracle.call("configure",owned,"round_world_pixel",0.0)) and mask!=null and mask.get_size()==Vector2i(3072,2048) and candidate_scene.map_layout.walkable_mask_path==published.walk_path,"Docks independent original full875/17 solid source oracle, not presentation-filtered NAV")

func _task_source_frame() -> void:
	if task_city!=DOCKS_ID or C._transition_validation.is_empty() or C._transition_validation.get("id")!=StringName(DOCKS_ID): return
	if task_source_proof.is_empty(): task_source_proof=(C._transition_validation.get("sources",{}) as Dictionary).duplicate(true)
	if C.transition_validation_state().get("sources_finalized",false): task_source_finalized=true

func _task_npc(id: String,dialog: String="") -> NPCNode:
	var found: Array[NPCNode]=[]
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id==id: found.append(npc)
	if not _check(found.size()==1 and found[0].is_inside_tree() and found[0].is_visible_in_tree() and found[0].sprite!=null and found[0].sprite.texture!=null and (dialog.is_empty() or found[0].dialog_id==TASKS.PREFIX+dialog),"One real visible native NPC/dialog "+id+"/"+dialog): return null
	return found[0]

func _projection_source(scene: SceneScript,storage: Dictionary) -> bool:
	var receipt: Dictionary=field.call("get_city_task_projection_state")
	rows.append({"kind":"TASK_NATIVE_PROJECTION_SOURCE","scene_id":scene.scene_id,"scene_instance":scene.get_instance_id(),"receipt":receipt,"native_npc_count_not_definition_count":(field.get("_npc_nodes") as Array).size()})
	return _check(field.get("_current_scene")==scene and candidate_scene==scene and C._equal_value(C._transition_storage(scene),storage) and receipt.get("render_applied")==true and receipt.get("original_scene_identity")==scene.get_instance_id() and receipt.get("spec_sha256")==TASK_SPEC_SHA and receipt.get("source_resource_unmodified")==true and receipt.get("navigation_modified")==false,"Task projection uses unchanged original proven _current_scene/storage; receipt is not self-granted geometry credit")

func _artisan_ground() -> bool:
	var npc:=_task_npc("luoyang_paper_artisan_20261016","artisan_daily")
	if npc==null: return false
	var foot:=Vector2(1320,1290)
	var approach:=Vector2(1240,1290)
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var world: Node2D=field.get("world_container") as Node2D
	var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
	var own_body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
	if not _check(own_body!=null and npc.position.distance_to(foot)<.03,"Actual artisan foot1320,1290 and its native blocking body exist"): return false
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.collision_mask=player.collision_mask; query.collide_with_areas=false
	query.exclude=[player.get_rid(),own_body.get_rid()]
	var ground: bool=player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
	var evidence: Dictionary={"kind":"ARTISAN_NATIVE_GROUND_AND_APPROACH","native_npc":npc.get_instance_id(),"native_foot":npc.position,"foot":foot,"approach":approach,"C_full875_foot":C.safe_body(StringName(MARKET_ID),foot),"raw875_foot":_body_raw(foot),"raw17_foot":oracle.call("clear",foot),"Physics_ground_excludes_only_Player_and_artisan_self_body":ground,"approach_original_clear87517Physics":_clear(approach),"remote_native_space_query_not_player_walk_claim":true}
	rows.append(evidence)
	return _check(evidence.C_full875_foot and evidence.raw875_foot and evidence.raw17_foot and ground and evidence.approach_original_clear87517Physics,"Artisan original C875/17/native Physics ground excluding its own body only; approach has no NPC exclusion")

func _task_refresh(id: String) -> bool:
	await process_frame; await physics_frame
	return await _wait_revision(id) and await _wait_hidden_operable()

func _market_key() -> bool:
	if not await _public_enter(Vector2(735,920),"PUBLIC_INITIAL") or not await _wait_hidden_operable(): return false
	active_tag=""
	var scene: SceneScript=candidate_scene
	var storage: Dictionary=C._transition_storage(scene)
	if not _projection_source(scene,storage) or _task_npc("luoyang_paper_scholar","paper_offer")==null or not _artisan_ground(): return false
	if not await _way(PackedVector2Array([Vector2(735,920),RESIDENT_STAND]),"task_hook_real_inn_final56px") or not _retain_before_entry(): return false
	watch_resident_jobs=true
	if not await _normal_inn_entry("single_clean_trip_with_task_projection") or not await _approach_room_exit("task_hook_actual_inn_indoor_INPUT") or not await _normal_resident_return(false): return false
	watch_resident_jobs=false
	var gs: Node=root.get_node("GameState")
	var qm: Node=root.get_node("QuestManager")
	# Explicit isolated memory setup only. Actual offer/choice is separately
	# bound by the207 pure-state proof, and Docks below uses real native input.
	var accepted: bool=bool(qm.call("accept",TASKS.PAPER))
	gs.call("set_flag",&"luoyang_paper_started",true)
	if not await _task_refresh(MARKET_ID): return false
	rows.append({"kind":"MARKET_ACCEPTED_MEMORY_STATE_SETUP_NOT_NPC_SPACE","accepted":accepted,"quest":TASKS.PAPER,"flags":(gs.get("flags") as Dictionary).duplicate(true),"native_projection":field.call("get_city_task_projection_state")})
	if not _check(accepted and int(qm.call("get_status",StringName(TASKS.PAPER)))==1 and _task_npc("luoyang_paper_scholar","paper_progress")!=null and _task_npc("luoyang_paper_artisan_20261016","paper_hint")!=null,"Paper accepted phase retains scholar and artisan with live progress/hint, not source hide-flag disappearance"): return false
	if not _projection_source(scene,storage): return false
	captures.append(await _capture_gate("market_task_projection_after_clean_return_and_accept"))
	return true

func _docks_setup() -> bool:
	task_city=DOCKS_ID
	var router: Node=root.get_node("SceneRouter")
	var started:=Time.get_ticks_usec()
	var accepted: bool=bool(router.call("go_field_smart",StringName(DOCKS_ID),Vector2(1740,1370)/C.SIZE,"",-1,C.VERSION))
	var sync_ms: float=(Time.get_ticks_usec()-started)/1000.0
	if not _check(accepted,"Docks public current-v3 near-chief setup accepted, not city travel") or not await _wait_revision(DOCKS_ID) or not await _wait_hidden_operable(): return false
	if not _check(task_source_finalized and not task_source_proof.is_empty(),"Docks actual production first/final source closure completed"): return false
	for path: String in task_source_proof:
		_check(source_before.has(path) and source_before[path].sha256==task_source_proof[path],"Docks complete closed source equals frozen input "+path)
	rows.append({"kind":"DOCKS_PUBLIC_SETUP_NOT_TRAVEL","sync_ms":sync_ms,"ready_ms":(Time.get_ticks_usec()-started)/1000.0,"foot":(field.get("_player") as Node2D).position,"actual_source_count":task_source_proof.size(),"sources_finalized":task_source_finalized})
	return _check((field.get("_player") as Node2D).position.distance_to(Vector2(1740,1370))<.03 and _clear(Vector2(1740,1370)),"Actual near-chief public foot full875/17/Physics") and await _way(PackedVector2Array([Vector2(1740,1370),Vector2(1740,1354)]),"Docks_normal_INPUT16px_before_native_Space")

func _native_chief_offer(accept: bool) -> bool:
	var npc:=_task_npc("canal_work_chief","canal_offer")
	if npc==null or not _check(bool(npc.get("_in_range")),"Actual chief native interaction area overlap"): return false
	await driver.call("key",KEY_SPACE)
	var dp: Node=root.get_node("DialogPlayer")
	var end:=mini(deadline,Time.get_ticks_msec()+5000)
	while Time.get_ticks_msec()<end and not bool(dp.call("is_playing")): await process_frame
	var script: DialogScript=dp.get("_current_script") as DialogScript
	if not _check(bool(dp.call("is_playing")) and script!=null and script.dialog_id==&"ch4_city_tasks_20261016_canal_offer","Real native chief Space opens exact NEW task offer"): return false
	for step in range(4):
		if dp.get("_pending_side_offer_id")==StringName(TASKS.CANAL): break
		await driver.call("key",KEY_SPACE)
	var box: Node=dp.get("_box") as Node
	if not _check(dp.get("_pending_side_offer_id")==StringName(TASKS.CANAL) and (box.get("_choice_rects") as Array).size()==2,"Actual DialogBox has two real side-quest choices"): return false
	await driver.call("key",KEY_1 if accept else KEY_2)
	for step in range(6):
		if not bool(dp.call("is_playing")): break
		await driver.call("key",KEY_SPACE)
	if not _check(not bool(dp.call("is_playing")),"Normal input finishes offer without private advance/choose"): return false
	if not await _task_refresh(DOCKS_ID): return false
	var status:=int(root.get_node("QuestManager").call("get_status",StringName(TASKS.CANAL)))
	var flag: bool=bool(root.get_node("GameState").call("get_flag",&"canal_grudge_started"))
	var row: Dictionary={"kind":"NATIVE_SPACE_DIALOGBOX_REAL_CHOICE","accepted":accept,"actual_quest_status":status,"started_flag":flag,"input":"KEY_1" if accept else "KEY_2","dialog":script.dialog_id,"projection":field.call("get_city_task_projection_state")}
	task_dialogs.append(row); rows.append(row)
	return _check(status==(1 if accept else 0) and flag==accept and _task_npc("canal_work_chief","canal_progress" if accept else "canal_offer")!=null and _task_npc("canal_old_soldier","canal_witness" if accept else "hanjia_offer")!=null,"Reject/accept keeps real chief+old soldier in correct stage")

func _docks_gates() -> bool:
	var box: Sprite2D=field.find_child("SceneObject_canal_feud_chest",true,false) as Sprite2D
	var mud: Node=field.find_child("SceneObject_warehouse_mud_trace",true,false)
	var wrong_areas:=0
	for area: Area2D in field.get("_trigger_areas"):
		var data: Dictionary=area.get_meta("trigger_data",{})
		if String(data.get("id","")) in ["canal_feud_chest","canal_warehouse_mud"] or String(data.get("visual_object_id","")) in ["canal_feud_chest","warehouse_mud_trace"]: wrong_areas+=1
	var dp: Node=root.get_node("DialogPlayer")
	var gs: Node=root.get_node("GameState")
	var qm: Node=root.get_node("QuestManager")
	var before: Dictionary={"flags":(gs.get("flags") as Dictionary).duplicate(true),"quests":qm.call("to_dict"),"gold":gs.get("gold")}
	var stale_denied: bool=not TASKS.authorize_dialog(TASKS.PREFIX+"canal_offer",before.flags,qm.get("states")) and not TASKS.authorize_dialog(TASKS.PREFIX+"canal_evidence",before.flags,qm.get("states"))
	field.call("_resolve_field_action","dialog:"+TASKS.PREFIX+"canal_evidence")
	field.call("_resolve_field_action","dialog:"+TASKS.PREFIX+"canal_offer")
	await process_frame
	var after: Dictionary={"flags":(gs.get("flags") as Dictionary).duplicate(true),"quests":qm.call("to_dict"),"gold":gs.get("gold")}
	rows.append({"kind":"ACTUAL_CARGO_MUD_AND_STALE_ACTION_GATES","cargo_visible":box!=null and box.is_visible_in_tree(),"mud_visual_absent":mud==null,"wrong_task_areas":wrong_areas,"stale_authorization_denied":stale_denied,"state_unchanged":C._equal_value(before,after),"whitebox_negative_action_only":true})
	return _check(box!=null and box.is_visible_in_tree() and (box.material==null or not box.material is ShaderMaterial or (box.material as ShaderMaterial).shader==null or (box.material as ShaderMaterial).shader.resource_path!="res://shaders/interaction_outline.gdshader") and mud==null and wrong_areas==0 and stale_denied and not dp.call("is_playing") and C._equal_value(before,after) and not bool(gs.call("get_flag",&"canal_grudge_route_heard")),"Real ordinary cargo no quest highlight/action, mud hidden before testimony and stale actions refused with no effects")

func _exercise_task_key() -> void:
	if not await _market_key() or not await _docks_setup(): return
	var scene: SceneScript=candidate_scene
	var storage: Dictionary=C._transition_storage(scene)
	if not _projection_source(scene,storage) or not await _native_chief_offer(false) or not await _native_chief_offer(true): return
	if not _projection_source(scene,storage) or not await _docks_gates(): return
	captures.append(await _capture_gate("docks_chief_retained_offer_accepted_mud_hidden"))
	task_completed=true

func _run() -> void:
	var started:=Time.get_ticks_msec(); deadline=started+180000
	output="res://build/luoyang_tasks_resident_field_key_20261016/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique finite final task/resident output")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoint held before first await")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-tasks-resident-field-key" in args and not REVISION_FLAG in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args,"Ordinary default task/resident runtime, no candidate flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual normal GPU engine")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_observe_loading_frame); process_frame.connect(_resident_frame); process_frame.connect(_task_source_frame)
		RenderingServer.frame_post_draw.connect(_observe_post_draw)
		await _exercise_task_key()
	watch_resident_jobs=false; active_tag=""
	for callback: Callable in [_observe_loading_frame,_resident_frame,_task_source_frame]:
		if process_frame.is_connected(callback): process_frame.disconnect(callback)
	if RenderingServer.frame_post_draw.is_connected(_observe_post_draw): RenderingServer.frame_post_draw.disconnect(_observe_post_draw)
	root.get_node("SceneRouter").call("reset_for_new_game")
	retained=null; resident_initial_scene=null; retained_nav.clear()
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Independent source navigation unchanged"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	var source_after:=_sources(); var players_after:=_players()
	_check(source_after==source_before and players_after==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Full inherited+task35+imports/15save/slot/checkpoint exact unchanged")
	_check(Time.get_ticks_msec()<deadline and task_completed and resident_trips.size()==1 and task_dialogs.size()==2 and captures.size()==3,"Fixed180/arrival60 key complete: one inn return, two native chief choices and three GPU captures")
	var result: Dictionary={"scope":"DEFAULT_TASK_PROJECTION_MARKET_DOCKS_ONE_RESIDENT_RETURN_ONLY","complete":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"budget_ms":180000,"arrival_ms":60000,"return_hidden_operable_limit_ms":RETURN_LIMIT_MS,"records":rows,"resident_trips":resident_trips,"actual_chief_choices":task_dialogs,"captures":captures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"source5_phase1_reused":PHASE1_PATH,"task35_source_paths":task_sources.keys(),"entry_stats":entry_stats,"Docks_production_sources_finalized":task_source_finalized,"all_city_travel_full_quest_chain_art_or_audio_credit":false,"ROOT_outer_exactticks_complete_stderr_and_natural_exit_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_TASKS_RESIDENT_FIELD_KEY="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
