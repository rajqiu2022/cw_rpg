extends "res://tests/test_luoyang_revision_formal_boot_key_20261015.gd"
## ROOT-only actual key: exact Router source/schema frozen; no other production delta.
## Public true means accepted, never ready. go_chapter remains outside this scope.
const PUBLIC_SOURCE_READY := true
const PUBLIC_ROUTER_PATH := "res://scripts/autoload/scene_router.gd"
const PUBLIC_ROUTER_SHA := "da99d43f6ecee2ced0ceaebfb0468bfc21b35a5a6235d2f3c0b965b02dd007a0"
const FORMAL_PARENT_SHA := "63b3d4dee6bb106cced555df5dbd7eeee830a409a3240f3c85de48600d677406"
const PUBLIC_CALL_LIMIT_MS := 1500
const FIRST_OPAQUE_LIMIT_MS := 1500
const LIVE_ROOM_IMPORT_PINS := {
	"res://art/backgrounds/bg_interior_inn_hall_v1.png.import":"6c7d69b8436f6b72316afb509ff075158d3c8f57436e5433595d673954d8cc19",
	"res://.godot/imported/bg_interior_inn_hall_v1.png-22f02238b18ce3a40b9dd31e0d23acba.ctex":"039cb5f62a7e1bdd1a6dc4309653bbb01bfdbeec4e4c97f5538713e67a0b8405",
	"res://art/backgrounds/bg_linxi_farmer_cottage_25d_v2.png.import":"a71f2598fe825517ddc0efcb5f6389f98fd32aa111ea15004fc911cbd53711aa",
	"res://.godot/imported/bg_linxi_farmer_cottage_25d_v2.png-9f1b63c833780d1e31dde15d39be8314.ctex":"826ee6bdc28bbb81474b4c635fc90174fa574ddd55e1a39ad017bbd647874b68",
	"res://art/backgrounds/bg_linxi_scholar_house_25d_v2.png.import":"1b8c922bc5563e9507d828c71218bfd55389ca6b6672b5b51ea20ce66d36c585",
	"res://.godot/imported/bg_linxi_scholar_house_25d_v2.png-8f3983466a548b24e3c72bc87a2928e7.ctex":"04bf9f9456baa14f7cbb81b2c025ac9a612998ffae3e28c4fcb100643cac4430"
}
var active_tag := ""
var entry_stats: Dictionary = {}
var stage_samples: Array[Dictionary] = []
var last_stage_signature := ""
var public_token := 0
var cancelled_token := 0
var cancelled_receipt: Dictionary = {}
var last_source_receipt: Dictionary = {}

func _precheck_revision() -> bool:
	for path: String in LIVE_ROOM_IMPORT_PINS:
		if not _track_source(path,LIVE_ROOM_IMPORT_PINS[path]): return false
	if not _check(PUBLIC_SOURCE_READY and PUBLIC_ROUTER_SHA.length()==64,"Exact Router schema and source freeze required"): return false
	if not _track_source("res://tests/test_luoyang_revision_formal_boot_key_20261015.gd",FORMAL_PARENT_SHA): return false
	if not _track_source(FROZEN_PARENT_PATH,FROZEN_PARENT_SHA) or not _track_source(FALSE_RUNTIME_BACKUP,FALSE_RUNTIME_SHA) or not _track_source(REVISION_PATH,FORMAL_RUNTIME_SHA): return false
	var false_text:=FileAccess.get_file_as_string(FALSE_RUNTIME_BACKUP)
	var true_text:=FileAccess.get_file_as_string(REVISION_PATH)
	var old_literal:="const FORMAL_ENABLED := false"
	if not _check(false_text.count(old_literal)==1 and false_text.replace(old_literal,"const FORMAL_ENABLED := true")==true_text,"Only exact ROOT-authorized FORMAL_ENABLED false-to-true byte-text edit"): return false
	for path: String in RUNTIME_PINS:
		if not _track_source(path,PUBLIC_ROUTER_SHA if path==PUBLIC_ROUTER_PATH else (FORMAL_RUNTIME_SHA if path==REVISION_PATH else String(RUNTIME_PINS[path]))): return false
	for path: String in UTILITY_PINS:
		if not _track_source(path,UTILITY_PINS[path]): return false
	for atom: Dictionary in ACCEPTED_ATOMS:
		if not _track_source(atom.path,atom.sha): return false
		var evidence: Variant=JSON.parse_string(FileAccess.get_file_as_string(atom.path))
		if not _check(evidence is Dictionary and evidence.get("scope")==atom.scope and evidence.get("complete")==true and evidence.get("failures")==0 and evidence.get("source_before") is Dictionary,"Exact completed candidate atom, never old failed evidence "+atom.scope): return false
		for path: String in evidence.source_before:
			var expected: String=PUBLIC_ROUTER_SHA if path==PUBLIC_ROUTER_PATH else (FORMAL_RUNTIME_SHA if path==REVISION_PATH else String(evidence.source_before[path].sha256))
			if not _track_source(path,expected): return false
	revision=load(REVISION_PATH) as Script
	if not _check(revision!=null and revision.get_script_constant_map().get("FORMAL_ENABLED")==true,"Actual frozen adapter default formal enabled"): return false
	var publication: Dictionary=PUBLICATIONS[MARKET_ID]
	if not _track_source(publication.result,publication.sha) or not _track_source(publication.manifest,publication.manifest_sha): return false
	proof=JSON.parse_string(FileAccess.get_file_as_string(publication.result))
	published=JSON.parse_string(FileAccess.get_file_as_string(publication.manifest))
	for path: String in revision.call("source_paths"):
		if not source_before.has(path): source_before[path]=_file(path)
		_check(source_before[path].exists,"Actual default runtime closed source exists "+path)
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	return failures==0


func _bind_revision() -> bool:
	if candidate_scene.scene_id==StringName(MARKET_ID): return super._bind_revision()
	if not _check(candidate_scene.scene_id==StringName(INN_ID),"This key permits only one inn template, not other rooms"): return false
	if oracle!=null: oracle.call("release"); oracle=null
	mask=null; polygons.clear()
	inside_room=String(candidate_scene.scene_id) not in [MARKET_ID,DOCKS_ID]
	oracle=SIMPLE_RAW.new()
	if inside_room:
		var expected_path: String=String(revision.call("room_path",candidate_scene.scene_id))
		var shape: CollisionShape2D=(field.get("_player") as Node).get_node("CollisionShape2D")
		if not _check(candidate_scene.resource_path==expected_path and not candidate_scene.actor_positions_are_feet and shape.shape is RectangleShape2D and shape.position==Vector2(0,42) and (shape.shape as RectangleShape2D).size==Vector2(34,24),"Exact independent room template with legacy body-center/42px collision anchor"): return false
		var layout: Resource=candidate_scene.map_layout
		var png: FileAccess=FileAccess.open(candidate_scene.background_path,FileAccess.READ)
		if not _check(png!=null and png.get_length()>=24,"Original background PNG header available"): return false
		var header: PackedByteArray=png.get_buffer(24); png.close()
		var source_size:=Vector2((int(header[16])<<24)|(int(header[17])<<16)|(int(header[18])<<8)|int(header[19]),(int(header[20])<<24)|(int(header[21])<<16)|(int(header[22])<<8)|int(header[23]))
		var viewport_size: Vector2=(field as Control).get_viewport_rect().size
		var scale: float=maxf(maxf(viewport_size.x,float(layout.get("design_size").x))/source_size.x,viewport_size.y/source_size.y)
		var projected_size: Vector2=source_size*scale
		var actual_size: Vector2=field.get("_world_size")
		if not _check(header.slice(0,8)==PackedByteArray([137,80,78,71,13,10,26,10]) and source_size==Vector2(1536,1024) and layout.get("design_size")==Vector2i(1536,1024) and layout.get("display_at_native_size")==true and layout.get("fill_viewport")==true and candidate_scene.streamed_background==null and actual_size==projected_size and actual_size==Vector2(1920,1280),"Independent PNG/cover rule agrees with actual room world size, not design-domain substitution"): return false
		var room_layout: Resource=layout.duplicate(true)
		room_layout.set("design_size",Vector2i(projected_size))
		if not _check(C._equal_value(room_layout.get("blockers"),layout.get("blockers")) and C._equal_value(room_layout.get("walkable_regions"),layout.get("walkable_regions")) and C._equal_value(room_layout.get("visual_objects"),layout.get("visual_objects")),"Only oracle design canvas projected; normalized furniture/regions remain exact"): return false
		rows.append({"kind":"INDEPENDENT_ROOM_COVER_PROJECTION","source_png":candidate_scene.background_path,"source_size":source_size,"viewport_size":viewport_size,"scale":scale,"actual_world_size":actual_size,"native_body_size":(shape.shape as RectangleShape2D).size,"native_offset":shape.position,"body_not_scaled":true})
		return _check(bool(oracle.call("configure",room_layout)),"Independent room oracle uses actual cover canvas with original normalized sources")
	return false


func _public_state() -> Dictionary:
	var router: Node=root.get_node("SceneRouter")
	return router.call("get_public_city_preparation_state") if router.has_method("get_public_city_preparation_state") else {}

func _transition_busy(manager: Node) -> bool:
	return bool(_public_state().get("active",false)) or super._transition_busy(manager)

func _loading_values() -> Dictionary:
	var manager: Node=root.get_node("LoadingManager")
	var screen: Node=manager.get("_screen") as Node
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	var bar: ProgressBar=screen.get("progress_bar") as ProgressBar if is_instance_valid(screen) else null
	var stage: Label=screen.get("stage_label") as Label if is_instance_valid(screen) else null
	return {"opaque":panel!=null and panel.is_visible_in_tree() and panel.modulate.a==1.0,"progress":bar.value if bar!=null else -1.0,"stage":stage.text if stage!=null else "NO_SCREEN","external":manager.get("_external_active"),"transition":manager.get("_transition_active")}

func _begin_tag(label: String) -> void:
	active_tag=label; last_stage_signature=""
	var now:=Time.get_ticks_usec()
	entry_stats[label]={"started_usec":now,"last_frame_usec":now,"frames":0,"max_gap_usec":0,"first_opaque_usec":0,"first_opaque_frame":-1,"first_source_worker_usec":0,"first_source_worker_frame":-1,"opaque_worker_frames":0,"distinct_progress":{},"public_call_ms":-1,"public_token":0,"finalized_sources":false,"source_hashes":{}}

func _observe_loading_frame() -> void:
	if active_tag.is_empty() or not entry_stats.has(active_tag): return
	var now:=Time.get_ticks_usec()
	var stats: Dictionary=entry_stats[active_tag]
	stats.frames+=1; stats.max_gap_usec=maxi(stats.max_gap_usec,now-int(stats.last_frame_usec)); stats.last_frame_usec=now
	var loading:=_loading_values()
	var state: Dictionary=C.transition_validation_state()
	var phase: String="source" if state.get("source_worker_active",false) else ("base_cpu" if state.get("base_cpu_worker_active",false) else ("navigation" if state.get("navigation_worker_active",false) else ("revision_cpu" if state.get("revision_worker_active",false) else ("base_main" if state.get("BASE_live_active",false) else "other"))))
	if state.get("source_worker_active",false):
		if int(stats.first_source_worker_usec)==0:
			stats.first_source_worker_usec=now; stats.first_source_worker_frame=Engine.get_process_frames()
		if loading.opaque: stats.opaque_worker_frames+=1
	stats.distinct_progress[str(roundi(float(loading.progress)))]=true
	# Only already joined, main-owned source proof; never read an active job packet.
	if not C._transition_validation.is_empty() and C._transition_validation.get("id")==StringName(MARKET_ID):
		if stats.source_hashes.is_empty(): stats.source_hashes=C._transition_validation.get("sources",{}).duplicate(true)
		if state.get("sources_finalized",false): stats.finalized_sources=true
	if not state.get("live_phase_msec",{}).is_empty(): last_source_receipt=state.duplicate(true)
	var signature:=active_tag+"/"+phase+"/"+String(loading.stage)+"/"+str(roundi(float(loading.progress)))
	if signature!=last_stage_signature:
		stage_samples.append({"tag":active_tag,"elapsed_usec":now-int(stats.started_usec),"frame":Engine.get_process_frames(),"phase":phase,"loading":loading,"C_state":state,"public":_public_state()})
		last_stage_signature=signature

func _observe_post_draw() -> void:
	if active_tag.is_empty() or not entry_stats.has(active_tag): return
	var stats: Dictionary=entry_stats[active_tag]
	if int(stats.first_opaque_usec)>0 or not bool(_loading_values().opaque): return
	stats.first_opaque_usec=Time.get_ticks_usec(); stats.first_opaque_frame=Engine.get_process_frames()
	stats.first_draw_C_state=C.transition_validation_state()
	if active_tag=="PUBLIC_INITIAL":
		var image: Image=root.get_texture().get_image()
		var path:=output+"first_actual_opaque_loading.png"
		var ok: bool=image!=null and not image.is_empty() and image.save_png(path)==OK
		_check(ok,"First actual opaque Loading GPU readback")
		captures.append({"path":path,"sha256":FileAccess.get_sha256(path) if ok else "","size":image.get_size() if ok else Vector2i.ZERO,"tag":active_tag,"post_draw_usec":stats.first_opaque_usec,"frame":stats.first_opaque_frame,"snapshot":_loading_values()})

func _public_request(foot: Vector2,label: String) -> bool:
	_begin_tag(label)
	var router: Node=root.get_node("SceneRouter")
	var before_field: Node=current_scene
	var started:=Time.get_ticks_usec()
	var accepted: bool=bool(router.call("go_field_smart",StringName(MARKET_ID),foot/C.SIZE,"",-1,C.VERSION))
	var elapsed: float=(Time.get_ticks_usec()-started)/1000.0
	var state:=_public_state()
	public_token=int(state.get("token",0))
	entry_stats[label].public_call_ms=elapsed; entry_stats[label].public_token=public_token
	rows.append({"kind":"PUBLIC_ACCEPTED_NOT_READY","tag":label,"call_ms":elapsed,"accepted":accepted,"state":state,"old_Field_id":before_field.get_instance_id() if is_instance_valid(before_field) else 0,"same_current_scene_at_return":current_scene==before_field})
	var schema_ok: bool=state.get("accepted")==true and state.get("phase")=="QUEUED" and state.get("bool_means")=="ACCEPTED_ENQUEUED_NOT_READY" and state.get("scene_id")==MARKET_ID and typeof(state.get("request_generation"))==TYPE_INT and int(state.request_generation)>0 and typeof(state.get("request_msec"))==TYPE_INT and typeof(state.get("request_frame"))==TYPE_INT and state.get("draw_checkpoint_frame")==0 and state.get("validation_started_msec")==0 and state.get("prepared_msec")==0 and state.get("finished_msec")==0 and state.get("error")==""
	return _check(accepted and schema_ok and elapsed<=PUBLIC_CALL_LIMIT_MS and bool(state.get("active",false)) and public_token>0 and current_scene==before_field,"Public returns accepted within1500ms with exact QUEUED/value-only contract, old Field not replaced before prepared handoff")

func _public_assert(label: String,completed: bool) -> bool:
	var stats: Dictionary=entry_stats[label]
	stats.total_ms=(Time.get_ticks_usec()-int(stats.started_usec))/1000.0
	var first_ms: float=(int(stats.first_opaque_usec)-int(stats.started_usec))/1000.0
	var draw_state: Dictionary=stats.get("first_draw_C_state",{})
	var timing_ok: bool=int(stats.first_opaque_usec)>0 and first_ms<=FIRST_OPAQUE_LIMIT_MS and int(stats.first_source_worker_usec)>int(stats.first_opaque_usec) and int(stats.first_source_worker_frame)>int(stats.first_opaque_frame) and draw_state.get("source_worker_active",false)==false and int(stats.opaque_worker_frames)>0
	_check(timing_ok,"Actual opaque post_draw within1500ms and before real source worker "+label)
	if completed:
		var public_state: Dictionary=_public_state()
		_check(public_state.get("active")==false and public_state.get("accepted")==true and public_state.get("phase")=="HANDED_OFF" and public_state.get("token")==stats.public_token and public_state.get("error")=="","Actual public accepted-to-handoff receipt; ready separately proven by native Field "+label)
		_check(stats.finalized_sources and not stats.source_hashes.is_empty(),"Actual complete source first/final SHA production proof retained "+label)
		for path: String in stats.source_hashes:
			_check(source_before.has(path) and source_before[path].sha256==stats.source_hashes[path],"Actual source hash equals frozen complete input "+path)
	rows.append({"kind":"PUBLIC_LOADING_TIMINGS","tag":label,"stats":stats.duplicate(true),"first_opaque_ms":first_ms,"all_frame_gaps_reported_not_smoothness_credit":true,"production_receipt":last_source_receipt.duplicate(true)})
	return failures==0

func _public_enter(foot: Vector2,label: String) -> bool:
	if not _public_request(foot,label): return false
	if not await _wait_revision(MARKET_ID): return false
	return _check((field.get("_player") as Node2D).position.distance_to(foot)<.03 and _clear(foot),"Actual accepted public target ready with original875/17/Physics "+label) and _public_assert(label,true)

func _nav_snapshot() -> Dictionary:
	var id:=MARKET_ID
	var image: Image=C._masks.get(id) as Image
	return {"has_record":C._records.has(id),"record":C._records.get(id,{}).duplicate(true),"has_mask":C._masks.has(id),"image":image,"image_id":image.get_instance_id() if image!=null else 0,"mask_bytes":image.get_data() if image!=null else PackedByteArray(),"mask_size":image.get_size() if image!=null else Vector2i.ZERO,"mask_format":image.get_format() if image!=null else -1,"has_solids":C._solids.has(id),"solids":C._solids.get(id,[]).duplicate(true),"has_patch":C._using_patch.has(id),"patch":C._using_patch.get(id)}

func _nav_equal(prior: Dictionary) -> bool:
	var image: Image=C._masks.get(MARKET_ID) as Image
	return C._records.has(MARKET_ID)==prior.has_record and C._equal_value(C._records.get(MARKET_ID,{}),prior.record) and C._masks.has(MARKET_ID)==prior.has_mask and image!=null and image.get_instance_id()==prior.image_id and image.get_size()==prior.mask_size and image.get_format()==prior.mask_format and image.get_data()==prior.mask_bytes and C._solids.has(MARKET_ID)==prior.has_solids and C._equal_value(C._solids.get(MARKET_ID,[]),prior.solids) and C._using_patch.has(MARKET_ID)==prior.has_patch and C._equal_value(C._using_patch.get(MARKET_ID),prior.patch)

func _late_cancel_and_reenter() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var held: Node=field
	var player: Node2D=field.get("_player") as Node2D
	var foot:=player.position
	var process_mode_before: int=field.process_mode
	var navigation: Dictionary={"id":router.call("get_current_field_id"),"spawn":router.get("_current_field_spawn"),"payload":(router.get("_field_payload") as Dictionary).duplicate(true),"versions":(router.get("_local_layout_versions") as Dictionary).duplicate(true)}
	var prior_nav:=_nav_snapshot()
	if not _public_request(foot,"PUBLIC_CANCEL_LATE_CPU"): return false
	cancelled_token=public_token
	var limit:=mini(deadline,Time.get_ticks_msec()+60000)
	var late: Dictionary={}
	while Time.get_ticks_msec()<limit:
		await process_frame
		var state: Dictionary=C.transition_validation_state()
		if state.get("base_cpu_worker_active",false) or state.get("navigation_worker_active",false):
			late=state; break
		if not bool(_public_state().get("active",false)): break
	if not _check(not late.is_empty() and not C._records.has(MARKET_ID) and not C._masks.has(MARKET_ID) and not C._solids.has(MARKET_ID) and not C._using_patch.has(MARKET_ID),"Cancel observed real BASE CPU/navigation only after all four old nav entries erased"): return false
	var started:=Time.get_ticks_usec()
	var cancelled: bool=bool(router.call("cancel_public_city_preparation",cancelled_token))
	var cancel_usec:=Time.get_ticks_usec()-started
	while Time.get_ticks_msec()<limit and _transition_busy(root.get_node("LoadingManager")): await process_frame
	var jobs_idle: bool=C._live_source_task<0 and C._live_source_job==null and C._live_base_cpu_task<0 and C._live_base_cpu_job==null and C._live_navigation_task<0 and C._live_navigation_job==null and C._live_module_task<0 and C._live_module_job==null and C._live_revision_task<0 and C._live_revision_job==null
	var nav_ok: bool=_nav_equal(prior_nav)
	var router_ok: bool=router.call("get_current_field_id")==navigation.id and C._equal_value(router.get("_current_field_spawn"),navigation.spawn) and C._equal_value(router.get("_field_payload"),navigation.payload) and C._equal_value(router.get("_local_layout_versions"),navigation.versions)
	cancelled_receipt={"old_token":cancelled_token,"cancelled":cancelled,"cancel_usec":cancel_usec,"late_state":late,"after":_public_state(),"jobs_joined_idle":jobs_idle,"exact_four_nav_restored":nav_ok,"router_restored":router_ok,"same_Field":current_scene==held,"same_Player":held.get("_player")==player,"foot":player.position,"same_process_mode":held.process_mode==process_mode_before}
	rows.append({"kind":"LATE_CPU_CANCEL_ROLLBACK","receipt":cancelled_receipt})
	if not _check(cancelled and jobs_idle and nav_ok and router_ok and current_scene==held and field==held and held.get("_player")==player and held.process_mode==process_mode_before and player.position==foot and _clear(foot),"Late cancel restores exact old Field/player/foot/router/four nav and joined workers"): return false
	if not _public_assert("PUBLIC_CANCEL_LATE_CPU",false): return false
	active_tag=""
	if not await _way(PackedVector2Array([foot,foot+Vector2(0,16)]),"old_Field_normal_INPUT_after_late_cancel"): return false
	var next_foot:=player.position
	if not await _public_enter(next_foot,"PUBLIC_REENTRY_NEW_TOKEN"): return false
	if not _check(public_token>cancelled_token,"Reentry owns a fresh token after cancelled owner"): return false
	var fresh: Node=field
	var fresh_player: Node2D=field.get("_player") as Node2D
	var fresh_public_state: Dictionary=_public_state()
	var fresh_lm_token: int=int(root.get_node("LoadingManager").get("_external_token"))
	var old_cancel_again: bool=bool(router.call("cancel_public_city_preparation",cancelled_token))
	await process_frame; await process_frame
	return _check(not old_cancel_again and C._equal_value(_public_state(),fresh_public_state) and int(root.get_node("LoadingManager").get("_external_token"))==fresh_lm_token and current_scene==fresh and field.get("_player")==fresh_player and fresh_player.position==next_foot and not _transition_busy(root.get_node("LoadingManager")) and _clear(next_foot),"Old cancelled owner cannot cancel or mutate successor ready Field")

func _exercise_public() -> void:
	if not await _public_enter(Vector2(735,920),"PUBLIC_INITIAL"): return
	active_tag=""
	if not await _way(PackedVector2Array([Vector2(735,920),Vector2(735,890)]),"public_original_normal30px") or not await _fade("inn",false,"public_inn_front_alpha1"): return
	if not await _way(PackedVector2Array([Vector2(735,890),Vector2(735,854)]),"normal_inn_final_approach") or not await _room_trip(INN_ID,Vector2(735,854)): return
	if not await _late_cancel_and_reenter(): return
	captures.append(await _capture_gate("final_public_new_token_Market"))

func _run() -> void:
	var started:=Time.get_ticks_msec(); deadline=started+240000
	output="res://build/luoyang_public_async_loading_key_20261015/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique public async key output")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoints held before first await")
	_check("--luoyang-public-async-loading-key" in OS.get_cmdline_user_args() and not REVISION_FLAG in OS.get_cmdline_user_args(),"Ordinary public key selection, no city revision candidate")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual GPU normal clock")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if _precheck_revision() and failures==0:
		var router: Node=root.get_node("SceneRouter")
		_check(router.has_method("get_public_city_preparation_state") and router.has_method("cancel_public_city_preparation"),"Frozen public state/cancel API exists")
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_observe_loading_frame); RenderingServer.frame_post_draw.connect(_observe_post_draw)
		if failures==0: await _exercise_public()
	if process_frame.is_connected(_observe_loading_frame): process_frame.disconnect(_observe_loading_frame)
	if RenderingServer.frame_post_draw.is_connected(_observe_post_draw): RenderingServer.frame_post_draw.disconnect(_observe_post_draw)
	var pending:=_public_state()
	if bool(pending.get("active",false)): root.get_node("SceneRouter").call("cancel_public_city_preparation",int(pending.get("token",0)))
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Independent actual source stable"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	_check(_sources()==source_before and _players()==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Complete917-origin sources/15save/slot/checkpoint guards unchanged")
	_check(Time.get_ticks_msec()<deadline and transitions.size()==2 and room_receipts.size()==1 and captures.size()==3 and not cancelled_receipt.is_empty(),"One shared240s/arrival60 key: one inn trip, late cancel/reentry and three actual GPU captures")
	var result: Dictionary={"scope":"PUBLIC_ASYNC_MARKET_INN_LATE_CANCEL_REENTRY_ONLY","complete":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"budget_ms":240000,"arrival_ms":60000,"public_call_limit_ms":PUBLIC_CALL_LIMIT_MS,"first_opaque_limit_ms":FIRST_OPAQUE_LIMIT_MS,"records":rows,"transitions":transitions,"room_returns":room_receipts,"entry_stats":entry_stats,"stage_samples":stage_samples,"arrival_observations":observations,"captures":captures,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"whole_city_or_go_chapter_or_all_loading_smoothness_credit":false,"ROOT_exactticks_natural_exit_complete_stderr_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_PUBLIC_ASYNC_KEY="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
