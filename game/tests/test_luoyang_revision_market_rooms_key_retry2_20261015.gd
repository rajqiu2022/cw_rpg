extends "res://tests/test_world_luoyang_gate_normal_roundtrip_retry2_20261014.gd"
## Two-room candidate key only. ROOT launches; setup is never travel/perf credit.
const REVISION_PATH := "res://scripts/city/luoyang_city_revision_runtime_20261015.gd"
const REVISION_FLAG := "--luoyang-city-revision-runtime-candidate-20261015"
const MARKET_ID := "ch4_s3_luoyang_market"
const DOCKS_ID := "ch4_s2_canal_docks"
const INN_ID := "luoyang_market_inn_interior_20261015"
const SMALL_ID := "luoyang_market_market_northwest_rear_frontage_interior_20261015"
const SOURCE_FROZEN := true
const RUNTIME_PINS: Dictionary = {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"79f77ebc0af0b4f76e412f5795a03d56ec6e68702641aec2586b6267c9832238",
	"res://scripts/autoload/scene_router.gd":"0517db2a2e08039291aac70072ac35a55a20d988e87ad7214d1d6c220a795802",
	"res://scripts/field/field_walkable_controller.gd":"b5d2b5131ea23ee3c3b96d56757fc14a691dbe097eb6111eff81f94769cc4164",
	"res://scripts/autoload/loading_manager.gd":"7cf318d9e1fa79ad7df867daa5142048be1f429bc4296f64eed40e679ee712db",
	"res://scripts/city/luoyang_city_revision_runtime_20261015.gd":"da8faf3d85a4e7bb91ca74f05a1a630873be5f274d3fd7e12b8e2cb11d528a7e",
	"res://art/maps/luoyang_city_revision_runtime_20261015/bindings.json":"aa2cc1e741598a9dfc38e2c065e90c892a2795c1eb54456c745426e3a7782dac"
}
const UTILITY_PINS := {
	"res://tests/test_world_luoyang_gate_normal_roundtrip_retry2_20261014.gd":"a7fce73af15d31c171e9bba8f8e34772204830637fbea87c29395f6b40b497b8",
	"res://tests/test_luoyang_gate_fortification_field_key_20261013.gd":"64be58e1f0e1fccdece808a91d81b82e9e5dc41a71e746caae95d35ec7cb249b",
	"res://tests/test_luoyang_four_city_key_smoke_20261012.gd":"65508b636a699dad0cdd73543aea02a06b9730979666191d570e5fe13cab0ba5",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb"
}
const PUBLICATIONS := {
	MARKET_ID:{"result":"res://build/luoyang_city_revision_publication_retry2_20261015/71716_1657076/result.json","sha":"1e802c567cb0fbef145a93b384d6f31152d598397a7e4e67ac9948705efbc6f1","manifest":"res://art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/candidate_manifest.json","manifest_sha":"e103039fcf1d332fbb9cebe289cee88bcdb82c4c5fc28274e3737be489dc62f3"},
	DOCKS_ID:{"result":"res://build/luoyang_city_revision_publication_20261015/108740_1671746/result.json","sha":"c81e2243f4dd54e45c006226d5cd24b978c131a585c3baa103481ddc1aeda642","manifest":"res://art/maps/luoyang_city_revision_v1_20261015/ch4_s2_canal_docks/candidate_manifest.json","manifest_sha":"fae2b99d98499fc255c9c5607b9811fd29d6b539a2969cec0937884f29f02451"}
}
var revision: Script
var published: Dictionary = {}
var proof: Dictionary = {}
var candidate_scene: SceneScript
var inside_room := false
var revision_tags: Array[Dictionary] = []
var room_receipts: Array[Dictionary] = []
var phase_name := "precheck"
var frame_last_usec := 0
var max_gap_usec := 0

func _atom() -> String: return "market_rooms"
func _budget_ms() -> int: return 240000
func _city_id() -> String: return MARKET_ID

func _track_source(path: String,expected: String) -> bool:
	if not source_before.has(path): source_before[path]=_file(path)
	return _check(source_before[path].exists and source_before[path].sha256==expected,"Exact frozen key source "+path)

func _precheck_revision() -> bool:
	if not _check(SOURCE_FROZEN and not RUNTIME_PINS.is_empty(),"SYSTEM final source freeze required, draft may not run"): return false
	for path: String in RUNTIME_PINS: _track_source(path,RUNTIME_PINS[path])
	for path: String in UTILITY_PINS: _track_source(path,UTILITY_PINS[path])
	revision=load(REVISION_PATH) as Script
	if not _check(revision!=null,"Frozen runtime adapter script"): return false
	var publication: Dictionary=PUBLICATIONS[_city_id()]
	if not _track_source(publication.result,publication.sha) or not _track_source(publication.manifest,publication.manifest_sha): return false
	proof=JSON.parse_string(FileAccess.get_file_as_string(publication.result))
	published=JSON.parse_string(FileAccess.get_file_as_string(publication.manifest))
	if not _check(proof.get("passed")==true and published.get("full_original_C_first")==true and published.get("Field_Physics_visual_QA")=="PENDING","Exact approved publication proof, not original-source CPU replay"): return false
	for path: String in proof.source_first:
		# Only explicitly frozen production hook sources may differ from the old
		# publication. All other complete original import/pixel sources stay exact.
		var expected: String=RUNTIME_PINS.get(path,proof.source_first[path])
		if not _track_source(path,expected): return false
		if expected!=proof.source_first[path]: rows.append({"kind":"EXPLICIT_FROZEN_HOOK_DELTA","path":path,"publication_sha":proof.source_first[path],"current_authorized_sha":expected})
	for path: String in revision.call("source_paths"):
		if not source_before.has(path): source_before[path]=_file(path)
		_check(source_before[path].exists,"Actual runtime closed source exists "+path)
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	return failures==0

func _frame_gap() -> void:
	var now:=Time.get_ticks_usec()
	if frame_last_usec>0: max_gap_usec=maxi(max_gap_usec,now-frame_last_usec)
	frame_last_usec=now

func _transition_busy(manager: Node) -> bool:
	return C._live_revision_task>=0 or C._live_revision_job!=null or C._live_module_task>=0 or C._live_module_job!=null or super._transition_busy(manager)

func _wait_revision(id: String) -> bool:
	var ok: bool=await super._wait_field(id)
	if not ok: return false
	candidate_scene=field.get("_current_scene") as SceneScript
	if not _check(candidate_scene!=null and String(candidate_scene.scene_id)==id,"Actual target SceneScript identity "+id): return false
	return _bind_revision()

func _bind_revision() -> bool:
	if oracle!=null: oracle.call("release"); oracle=null
	mask=null; polygons.clear()
	inside_room=String(candidate_scene.scene_id) not in [MARKET_ID,DOCKS_ID]
	oracle=SIMPLE_RAW.new()
	if inside_room:
		var expected_path: String=String(revision.call("room_path",candidate_scene.scene_id))
		var shape: CollisionShape2D=(field.get("_player") as Node).get_node("CollisionShape2D")
		return _check(candidate_scene.resource_path==expected_path and not candidate_scene.actor_positions_are_feet and shape.shape is RectangleShape2D and shape.position==Vector2(0,42) and (shape.shape as RectangleShape2D).size==Vector2(34,24) and bool(oracle.call("configure",candidate_scene.map_layout)),"Exact independent room template with legacy body-center/42px collision anchor")
	if not _check(bool(revision.call("bound",candidate_scene)) and C._records.has(String(candidate_scene.scene_id)),"Actual revised city bound, prepared record exists before read"): return false
	var record: Dictionary=C.effective_author_record(candidate_scene.scene_id)
	var expected_slots: Dictionary=published.gameplay_slots.duplicate(true)
	if String(candidate_scene.scene_id)==MARKET_ID:
		var disabled: Array=(expected_slots.portals as Array).filter(func(row: Dictionary)->bool:return row.get("source_id")=="enter_southwest_market_front_room")
		if not _check(disabled.size()==1,"Exact published SW pillar door explicit removal domain"): return false
		expected_slots.portals.erase(disabled[0])
		var disabled_receipt: Array=record.get("city_revision_disabled_portals",[])
		_check(candidate_scene.map_layout.portals.size()==12 and disabled_receipt.size()==1 and disabled_receipt[0].id=="enter_southwest_market_front_room" and disabled_receipt[0].building_id=="southwest_market_front" and disabled_receipt[0].reason=="SOURCE_ANCHOR_IS_SOLID_CENTRAL_POST_NOT_DOOR","Only12 runtime Market portals and exact sole SW disabled receipt; old13/9door publication not runtime credit")
	if not _check(record.get("city_revision_manifest_sha")==PUBLICATIONS[_city_id()].manifest_sha and C._equal_value(record.objects,published.objects) and C._equal_value(record.gameplay_slots,expected_slots) and C._equal_value(record.routes,published.routes),"Actual revision record exact published geometry/gameplay/routes plus sole disabled SW door"): return false
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
	var configured: bool=bool(oracle.call("configure",owned,"round_world_pixel",0.0))
	mask=Image.load_from_file(published.walk_path)
	return _check(configured and mask!=null and mask.get_size()==Vector2i(3072,2048) and candidate_scene.map_layout.walkable_mask_path==published.walk_path,"Actual candidate raw navigation+source solids, no old mask substitution")

func _body_raw(p: Vector2) -> bool:
	if not inside_room: return super._body_raw(p)
	# Legacy room navigation samples the actor origin. Independently also check
	# its real native foot collider, whose center is origin+(0,42), full875.
	var center:=p+Vector2(0,42)
	for y: int in range(roundi(center.y)-12,roundi(center.y)+13):
		for x: int in range(roundi(center.x)-17,roundi(center.x)+18):
			if not bool((oracle.call("pixel_evidence",Vector2(x,y)) as Dictionary).get("clear",false)): return false
	return true

func _clear(p: Vector2) -> bool:
	return Time.get_ticks_msec()<deadline and oracle!=null and _body_raw(p) and bool(oracle.call("clear",p)) and _physical(p)

func _state(label: String) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	return {"label":label,"scene_id":candidate_scene.scene_id,"scene_path":candidate_scene.resource_path,"Field_id":field.get_instance_id(),"Player_id":player.get_instance_id(),"origin":player.position,"physical_ground_center":player.position+(Vector2(0,42) if inside_room else Vector2.ZERO),"legacy_body_center_room":inside_room,"full875":_body_raw(player.position),"raw17":oracle.call("foot_evidence",player.position),"Physics":_physical(player.position),"frame":Engine.get_process_frames()}

func _way(points: PackedVector2Array,label: String) -> bool:
	var actual: Dictionary=await driver.call("follow",field,points,_clear,_segment)
	rows.append({"kind":"NORMAL_INPUT","label":label,"points":points,"receipt":actual,"actual":_state(label)})
	return _check(actual.get("ok")==true,"Normal INPUT complete source-safe path "+label)

func _public_setup(foot: Vector2) -> bool:
	phase_name="PUBLIC_SETUP_ONLY_CURRENT_VERSION3"
	var started:=Time.get_ticks_msec(); frame_last_usec=Time.get_ticks_usec(); max_gap_usec=0
	_observe(_city_id(),"before_public_current_version3_setup",started)
	var accepted: bool=bool(root.get_node("SceneRouter").call("go_field_smart",StringName(_city_id()),foot/C.SIZE,"",-1,C.VERSION))
	var sync_ms:=Time.get_ticks_msec()-started
	_observe(_city_id(),"after_public_setup_return_"+str(accepted),started)
	if not _check(accepted,"Explicit version3 public city setup; not travel") or not await _wait_revision(_city_id()): return false
	var row:=_state("PUBLIC_SETUP_ONLY")
	row.synchronous_call_ms=sync_ms; row.total_ms=Time.get_ticks_msec()-started; row.max_gap_usec=max_gap_usec; row.travel_or_performance_credit=false
	rows.append(row)
	return _check((field.get("_player") as Node2D).position.distance_to(foot)<.03 and _clear((field.get("_player") as Node2D).position),"Exact initial public setup original current coordinate and physical body")

func _space_revision(target: String,label: String) -> bool:
	phase_name=label
	var started:=Time.get_ticks_msec(); frame_last_usec=Time.get_ticks_usec(); max_gap_usec=0
	await driver.call("key",KEY_SPACE)
	var input_ms:=Time.get_ticks_msec()-started
	var ok: bool=await _wait_revision(target)
	transitions.append({"kind":"REAL_SPACE","target":target,"label":label,"input_call_ms":input_ms,"total_ms":Time.get_ticks_msec()-started,"max_gap_usec":max_gap_usec,"no_router_shortcut":true})
	return ok

func _visible_arrow(foot: Vector2,label: String) -> bool:
	var matches: Array[Node]=[]
	for node: Node2D in field.get("_exit_nodes"):
		if node.position.distance_to(foot)<.03: matches.append(node)
	if not _check(matches.size()==1,"One actual configured portal node "+label): return false
	var zone: Node=matches[0]
	var marker: Sprite2D=zone.get("marker_visual") as Sprite2D
	var point: Vector2=marker.get_global_transform_with_canvas().origin if marker!=null else Vector2(INF,INF)
	rows.append({"kind":"ACTUAL_ARROW","label":label,"source_foot":foot,"native_position":(zone as Node2D).position,"target":zone.get("target_scene_id"),"action":zone.get("action"),"in_range":zone.get("_in_range"),"viewport_point":point})
	return _check(marker!=null and marker.texture!=null and marker.is_visible_in_tree() and root.get_visible_rect().has_point(point) and bool(zone.get("_in_range")) and not bool(zone.get("is_locked")),"Actual visible on-screen available arrow "+label)

func _overlap_target(target: String) -> bool:
	var matches:=0
	for node: Node in field.get("_exit_nodes"):
		if String(node.get("target_scene_id"))==target and bool(node.get("_in_range")) and not bool(node.get("is_locked")): matches+=1
	return _check(matches==1,"One actual source portal overlap "+target)

func _fade(id: String,behind: bool,label: String) -> bool:
	var player: Node2D=field.get("_player") as Node2D
	var held: Node=field
	var until:=mini(deadline,Time.get_ticks_msec()+250)
	while Time.get_ticks_msec()<until: await process_frame
	var sprite:=field.find_child("SceneObject_"+id,true,false) as Sprite2D
	var state: Dictionary=field.call("get_city_building_fade_debug")
	var found: Array=(state.get("buildings",[]) as Array).filter(func(row: Dictionary)->bool:return row.get("id")==id)
	if not _check(current_scene==held and field.get("_player")==player and sprite!=null and found.size()==1 and _clear(player.position),"Same actual frame actor/prop/source clearance "+label): return false
	var record: Dictionary=found[0]
	var expected: float=.55 if behind else 1.0
	rows.append({"kind":"ACTUAL_NATIVE_FADE","label":label,"object_id":id,"sprite_id":sprite.get_instance_id(),"state":_state(label),"record":record,"native":sprite.self_modulate})
	return _check(record.hit==behind and absf(float(record.factor)-expected)<.000001 and absf(sprite.self_modulate.a-expected)<.000001 and sprite.modulate.a==1.0,"Native behind55/front1 "+label)

func _room_trip(id: String,door: Vector2) -> bool:
	if not _overlap_target(id) or not await _space_revision(id,"ENTER_ROOM_"+id): return false
	var template: String=String(candidate_scene.map_layout.get_meta("home_template_id",""))
	_check(template==("inn_hall" if id==INN_ID else "small_home"),"Two genuinely different indoor templates, not bookshop substitution")
	captures.append(await _capture_gate("inside_"+id))
	var exit: Dictionary=candidate_scene.map_layout.portals[0]
	var target: Vector2=exit.pos*Vector2(candidate_scene.map_layout.design_size)-Vector2(0,36)
	var player: Node2D=field.get("_player") as Node2D
	if not await _way(PackedVector2Array([player.position,target]),"ordinary_indoor_walk_to_actual_exit_overlap") or not _overlap_target(MARKET_ID): return false
	if not await _space_revision(MARKET_ID,"RETURN_ROOM_"+id): return false
	var receipt:=_state("EXACT_ROOM_RETURN_"+id)
	room_receipts.append(receipt)
	return _check((field.get("_player") as Node2D).position.distance_to(door)<.03 and _clear(door),"Actual Space returns original corresponding city door foot "+id)

func _exercise_revision() -> void:
	if not await _public_setup(Vector2(735,920)): return
	if not await _way(PackedVector2Array([Vector2(735,920),Vector2(735,854)]),"inn_short_final_approach") or not await _fade("inn",false,"inn_front_door_not_faded"): return
	captures.append(await _capture_gate("inn_front_door"))
	if not await _room_trip(INN_ID,Vector2(735,854)): return
	if not await _way(PackedVector2Array([Vector2(735,854),Vector2(735,920),Vector2(1000,1060),Vector2(220,1060),Vector2(220,590),Vector2(620,590)]),"published_NW_route_no_old_y550_tree_crossing"): return
	if not await _fade("inn",true,"inn_rear") or not await _fade("market_northwest_rear_frontage",false,"NW_front_distinct_object"): return
	captures.append(await _capture_gate("inn_rear_NW_front_same_frame"))
	if not await _way(PackedVector2Array([Vector2(620,590),Vector2(620,524)]),"NW_small_home_short_final_approach") or not await _room_trip(SMALL_ID,Vector2(620,524)): return
	if not await _way(PackedVector2Array([Vector2(620,524),Vector2(620,590)]),"post_return_same_Field_inn_rear") or not await _fade("inn",true,"same_Field_inn_rear_before_restore"): return
	var sprite: Node=field.find_child("SceneObject_inn",true,false)
	var held_id: int=sprite.get_instance_id()
	if not await _way(PackedVector2Array([Vector2(620,590),Vector2(220,590),Vector2(220,1060),Vector2(1000,1060),Vector2(735,920),Vector2(735,854)]),"same_Field_original_routes_back_to_inn_front") or not await _fade("inn",false,"same_Field_inn_front_restored"): return
	_check(field.find_child("SceneObject_inn",true,false).get_instance_id()==held_id,"Same prop instance55-to1, no reload illusion")
	captures.append(await _capture_gate("inn_front_restored"))
	if not await _way(PackedVector2Array([Vector2(735,854),Vector2(735,920),Vector2(1000,1060),Vector2(1180,1380),Vector2(1180,1510),Vector2(650,1510),Vector2(650,1464)]),"published_wall_tree_front_street_open"): return
	captures.append(await _capture_gate("wall_tree_front_street_open"))
	rows.append(_state("BEFORE_NEW_NORTH_PORTAL_VISIT"))
	var north: Array=(candidate_scene.map_layout.portals as Array).filter(func(row: Dictionary)->bool:return row.get("id")=="to_yamen_square")
	_check(north.size()==1 and north[0].arrival_foot_px==Vector2(2090,160) and north[0].pos*C.SIZE==Vector2(2090,160),"New north street exit exact configuration")
	if not await _way(PackedVector2Array([Vector2(650,1464),Vector2(650,1510),Vector2(1180,1510),Vector2(1180,1380),Vector2(1000,1060),Vector2(1536,1060),Vector2(1536,770),Vector2(1850,680),Vector2(2090,680),Vector2(2090,160)]),"published_north_street_approach_no_portal_activation") or not _visible_arrow(Vector2(2090,160),"north_yamen_gate"): return
	captures.append(await _capture_gate("north_yamen_gate_visible"))

func _run() -> void:
	var started:=Time.get_ticks_msec(); deadline=started+_budget_ms()
	output="res://build/luoyang_revision_"+_atom()+"_key_20261015/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique bounded candidate key output")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoints held before first await")
	_check(REVISION_FLAG in OS.get_cmdline_user_args() and ("--luoyang-revision-"+_atom()+"-key") in OS.get_cmdline_user_args(),"Explicit atomic candidate flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Installed actual GPU engine ordinary clock")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_frame_gap)
		await _exercise_revision()
	if process_frame.is_connected(_frame_gap): process_frame.disconnect(_frame_gap)
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Independent mask sources unchanged"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	_check(_sources()==source_before and _players()==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Complete sources/15save/slot/checkpoint guard unchanged")
	_check(Time.get_ticks_msec()<deadline,"Atomic shared deadline retained")
	if _atom()=="market_rooms": _check(transitions.size()==4 and room_receipts.size()==2 and captures.size()==7,"Both distinct rooms actual Space roundtrips and all seven finite state screenshots complete")
	else: _check(transitions.is_empty() and room_receipts.is_empty() and captures.size()==3,"One Docks setup, ferry display and actual foreman interaction only")
	var result: Dictionary={"scope":"LIMITED_CANDIDATE_"+_atom().to_upper(),"complete":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"budget_ms":_budget_ms(),"arrival_ms":60000,"records":rows,"transitions":transitions,"room_returns":room_receipts,"arrival_observations":observations,"captures":captures,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"initial_public_setup_is_not_travel_or_performance_credit":true,"publication_complete_geometry_proof_reused_not_replayed":true,"formal_activated":false,"whole_city_or_old_Gate_tested":false,"ROOT_outer_exactticks_and_stderr_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_REVISION_ATOMIC_KEY="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
