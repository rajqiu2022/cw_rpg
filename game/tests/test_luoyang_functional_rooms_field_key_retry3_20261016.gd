extends "res://tests/test_luoyang_tasks_resident_field_key_retry2_20261016.gd"
## NEW retry3: only typed oracle-clone blockers and exact native/source counts; old failures preserved.
## ROOT-only candidate key: two real matched doors; disabled warehouse probe only.
const ROOM_SOURCE_READY := true
const ROOM_PARENT_SHA := "9c970b9a9b5cfc9ee417c5007ce447bbff4c35912b692f4e70e4c1f4a4b37137"
const ROOMS = preload("res://scripts/city/luoyang_functional_interiors_20261016.gd")
const ROOM_HELPER_SHA := "8c240e2e9dea961e2573813a1b127d1a8e88b7dad0e812033ea675481eafe611"
const ROOM_REGISTRY_SHA := "da704adefa51d4c523e92eea9faae6e1d0a257dc3fc0b4789427300503709eba"
const ROOM_CPU_RESULT := "res://build/luoyang_five_functional_rooms_cpu_20261016/65824_1682/result.json"
const ROOM_CPU_SHA := "cd7da081d4ca80a85e3bf60c3fb8392d4fde12c8129a264372f960a69402d9c6"
const ROOM_CPU_SCRIPT := "res://tests/test_luoyang_five_functional_rooms_cpu_retry3_20261016.gd"
const ROOM_CPU_SCRIPT_SHA := "8e3c9ff2f5c4dcdb24bacbd512ecec597731ca9d5325f6f5e2e79461a3696283"
const ROOM_HOOK_PINS := {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"887a9d060cc7a1d57af9c2ab7f62af4d7b6cacd8937c69e5baa609fefeeedd29",
	"res://scripts/autoload/scene_router.gd":"1877df7c4544275e66241552cee63e00f69d84a4c38bf5166976a4e401b2c1e1",
	"res://scripts/field/field_walkable_controller.gd":"b472320b3af47a904f3f43254219bbd5330e98f94f9ba886b1a9474018a9c356",
	"res://scripts/city/luoyang_resident_field_20261016.gd":"cd5d3485d7f639b447010df9e88cc6347242a2a2fe491a873fa2e46d6ff55b86"
}
const ROOM_OLD_PINS := {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":["0d107ce386760c8569aa2ab0e34ad8c1d3f8a9389954db1a9134f6604aade943","3b591067c28ad118de5f6d32e4bcf8d3cad7a1f091169f495590fdf3e6733a98"],
	"res://scripts/autoload/scene_router.gd":["843bf7afeaaf321d8931db689a846254ba30ce0a868c5b8eb5446be9ff7ad73e"],
	"res://scripts/field/field_walkable_controller.gd":["132f4e6b303280e515b757a51f05caf82fb0f0fb1202baa1233df3adb63a4f5b","71b54611d29c0b08ca1cb688b33b33346a293f744bc84e603b89eb8c527986be"],
	"res://scripts/city/luoyang_resident_field_20261016.gd":["b49b3674197df795ff1fa0c1b1a3d5d7b9e7977ae08ad6799c857d074ed6eabf"]
}
const ROOM_CASES := [
	{"type":"smithy","id":"luoyang_market_shop_interior_20261015","setup":Vector2(2320,940),"stand":Vector2(2320,884),"door":Vector2(2320,874)},
	{"type":"cloth_shop","id":"luoyang_market_north_market_front_interior_20261015","setup":Vector2(1536,720),"stand":Vector2(1536,664),"door":Vector2(1536,654)}
]
var functional_inside := false
var functional_spec: Dictionary = {}
var functional_trips: Array[Dictionary] = []
var production_proofs: Dictionary = {}
var production_finalized: Dictionary = {}
var warehouse_probe: Dictionary = {}

func _track_source(path: String,expected: String) -> bool:
	if ROOM_HOOK_PINS.has(path) and expected in ROOM_OLD_PINS[path]: expected=ROOM_HOOK_PINS[path]
	return super._track_source(path,expected)

func _precheck_revision() -> bool:
	if not _check(ROOM_SOURCE_READY,"Explicit frozen CPU approval required") or not _track_source("res://tests/test_luoyang_tasks_resident_field_key_retry2_20261016.gd",ROOM_PARENT_SHA): return false
	if not super._precheck_revision(): return false
	if not _track_source(ROOMS.SELF_PATH,ROOM_HELPER_SHA) or not _track_source(ROOMS.REGISTRY_PATH,ROOM_REGISTRY_SHA) or not _track_source(ROOM_CPU_RESULT,ROOM_CPU_SHA) or not _track_source(ROOM_CPU_SCRIPT,ROOM_CPU_SCRIPT_SHA): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOM_CPU_RESULT))
	if not _check(prior.get("complete")==true and prior.get("passed")==true and prior.get("failures")==0 and prior.get("rooms",[]).size()==5 and prior.get("engine_physics_tested")==false,"Exact independent five-room CPU/import/storage proof, no Physics credit"): return false
	for path: String in prior.source_before:
		if not _track_source(path,String(prior.source_before[path].sha256)): return false
	for path: String in ROOM_HOOK_PINS:
		if not _track_source(path,ROOM_HOOK_PINS[path]): return false
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOMS.REGISTRY_PATH))
	for path: String in registry.source_sha256:
		if not _track_source(path,registry.source_sha256[path]): return false
	return _check(ROOMS.enabled() and not ROOMS.FORMAL_ENABLED and registry.rooms.size()==5 and registry.rooms.luoyang_canal_warehouse_interior_20261016.door_enabled==false,"Only two approved candidate doors; warehouse stays disabled")

func _room_source_frame() -> void:
	var state: Dictionary=C._transition_validation
	if state.is_empty(): return
	var id:=String(state.get("id",""))
	if id not in [MARKET_ID,DOCKS_ID]: return
	if not production_proofs.has(id) and not (state.get("sources",{}) as Dictionary).is_empty(): production_proofs[id]=(state.sources as Dictionary).duplicate(true)
	if C.transition_validation_state().get("sources_finalized",false): production_finalized[id]=true

func _bind_revision() -> bool:
	functional_inside=candidate_scene.get_meta("functional_interior_revision","")==ROOMS.META
	if not functional_inside: return super._bind_revision()
	if oracle!=null: oracle.call("release"); oracle=null
	mask=null; polygons.clear(); inside_room=true
	var item: Dictionary=ROOMS.row(candidate_scene.scene_id)
	var shape: CollisionShape2D=(field.get("_player") as Node).get_node("CollisionShape2D")
	var actual_world: Vector2=field.get("_world_size")
	if not _check(ROOMS.matches(candidate_scene,candidate_scene.scene_id) and item.door_enabled and candidate_scene.map_layout.design_size==Vector2i(1536,1024) and candidate_scene.map_layout.fill_viewport and actual_world==Vector2(1920,1280) and shape.shape is RectangleShape2D and shape.position==Vector2(0,42) and (shape.shape as RectangleShape2D).size==Vector2(34,24),"Actual source-bound room/cover and unchanged native34x24/+42"): return false
	functional_spec=JSON.parse_string(FileAccess.get_file_as_string(item.author_path))
	var source: Resource=candidate_scene.map_layout
	var clone: Resource=source.duplicate(true)
	var source_count: int=(source.get("blockers") as Array).size()
	var empty_blockers: Array[Dictionary]=[]
	clone.set("design_size",Vector2i(actual_world)); clone.set("blockers",empty_blockers)
	var declarations: Array[Dictionary]=[]
	for base: Dictionary in functional_spec.furniture_bases:
		var poly:=PackedVector2Array()
		for pair: Array in base.ground_polygon_px: poly.append(Vector2(pair[0],pair[1])*actual_world/Vector2(1536,1024))
		declarations.append({"id":base.id,"solid_polygons_px":[poly]}); polygons.append(poly)
	clone.set("visual_objects",declarations)
	oracle=SIMPLE_RAW.new()
	var configured: bool=bool(oracle.call("configure",clone,"normalized_image_round",0.0))
	rows.append({"kind":"INDEPENDENT_ROOM_ORACLE_CONFIGURATION","accepted":configured,"errors":oracle.get("errors"),"clone_blockers_count":(clone.get("blockers") as Array).size(),"source_blockers_count":(source.get("blockers") as Array).size(),"source_count_before":source_count,"floor_count":(oracle.get("regions") as Array).size(),"solid_count":(oracle.get("solids") as Array).size()})
	if not _check(configured and (clone.get("blockers") as Array).is_empty() and (source.get("blockers") as Array).size()==source_count and source_count==functional_spec.furniture_bases.size() and (oracle.get("regions") as Array).size()==functional_spec.floor_regions_px.size() and (oracle.get("solids") as Array).size()==functional_spec.furniture_bases.size(),"Independent exact source floor/polygons projected to actual cover; typed clone clears only duplicate blockers and source counts stay exact"): return false
	var bodies: Array=field.get("_collision_bodies")
	if not _check(bodies.size()==functional_spec.furniture_bases.size(),"All actual native furniture bodies exist"): return false
	for index: int in bodies.size():
		var body: StaticBody2D=bodies[index] as StaticBody2D
		var poly_node:=body.get_child(0) as CollisionPolygon2D
		var authored: PackedVector2Array=source.blockers[index].ground_polygon
		var expected:=PackedVector2Array()
		for point: Vector2 in authored: expected.append(point*actual_world)
		if not _check(body.is_inside_tree() and body.position==Vector2.ZERO and body.collision_layer==1 and poly_node!=null and not poly_node.disabled and poly_node.polygon==expected and body.name=="Furniture_"+String(source.blockers[index].id),"Actual CollisionPolygon exact native position/vertices "+String(body.name)): return false
	return true

func _body_raw(origin: Vector2) -> bool:
	if not functional_inside: return super._body_raw(origin)
	var foot:=origin+Vector2(0,42)
	for y: int in range(roundi(foot.y)-12,roundi(foot.y)+13):
		for x: int in range(roundi(foot.x)-17,roundi(foot.x)+18):
			var point:=Vector2(x,y)
			if not bool((oracle.call("pixel_evidence",point) as Dictionary).get("clear",false)): return false
			for polygon: PackedVector2Array in polygons:
				if Geometry2D.is_point_in_polygon(point,polygon): return false
	return true

func _clear(origin: Vector2) -> bool:
	if not functional_inside: return super._clear(origin)
	return Time.get_ticks_msec()<deadline and oracle!=null and _body_raw(origin) and bool(oracle.call("clear",origin+Vector2(0,42))) and _physical(origin) and ROOMS.safe_origin(field.get("_functional_room_geometry"),origin,field.get("_world_size"),false)

func _proof_closed(id: String) -> bool:
	if not _check(production_finalized.get(id,false) and production_proofs.has(id),"Actual production full source first/final complete "+id): return false
	for path: String in production_proofs[id]:
		if not _check(source_before.has(path) and source_before[path].sha256==production_proofs[id][path],"Actual full source closure equals frozen inputs "+path): return false
	return true

func _setup_city(id: String,foot: Vector2,label: String) -> bool:
	task_city=id
	production_proofs.erase(id); production_finalized.erase(id)
	var started:=Time.get_ticks_usec()
	var accepted: bool=bool(root.get_node("SceneRouter").call("go_field_smart",StringName(id),foot/C.SIZE,"",-1,C.VERSION))
	var sync_ms: float=(Time.get_ticks_usec()-started)/1000.0
	if not _check(accepted,"Current-version3 public near-door setup accepted, not travel") or not await _wait_revision(id) or not await _wait_hidden_operable() or not _proof_closed(id): return false
	rows.append({"kind":"PUBLIC_NEAR_DOOR_SETUP_NOT_TRAVEL","label":label,"scene_id":id,"sync_ms":sync_ms,"ready_ms":(Time.get_ticks_usec()-started)/1000.0,"actual_foot":(field.get("_player") as Node2D).position})
	return _check((field.get("_player") as Node2D).position.distance_to(foot)<.03 and _clear(foot),"Actual source875/17/Physics safe setup foot "+label)

func _actual_room_npcs() -> bool:
	var actual: Array=field.get("_npc_nodes")
	if not _check(actual.size()==functional_spec.npc_slots.size(),"Exact native new room NPC count"): return false
	for index: int in actual.size():
		var npc: NPCNode=actual[index] as NPCNode
		var source: Dictionary=functional_spec.npc_slots[index]
		var foot:=Vector2(source.foot_px[0],source.foot_px[1])*Vector2(1.25,1.25)
		var body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
		var shape:=body.get_child(0) as CollisionShape2D
		var world: Node2D=field.get("world_container") as Node2D
		if not _check(npc.is_visible_in_tree() and npc.position.distance_to(foot)<.03 and npc.get("_ground_anchored")==true and shape.shape is RectangleShape2D and world.to_local(shape.global_position).distance_to(foot)<.03,"Actual NPC grounded body center matches source foot (no Player42 shift)"): return false
		var texture:=npc.sprite.texture
		var expected_body:=Vector2(float(texture.get_width())/npc.sprite.hframes*.14,texture.get_height()*.18)*npc.sprite_scale
		if not _check((shape.shape as RectangleShape2D).size==expected_body,"NPC native footprint uses original sprite_scale, not visual calibration/cover"): return false
		var player: CharacterBody2D=field.get("_player") as CharacterBody2D
		var player_shape:=player.get_node("CollisionShape2D") as CollisionShape2D
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=player_shape.shape; query.transform=player_shape.global_transform
		query.transform.origin+=world.to_global(foot-Vector2(0,42))-player.global_position
		query.collision_mask=player.collision_mask; query.collide_with_areas=false
		query.exclude=[player.get_rid(),body.get_rid()]
		var own_ground: bool=player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
		var approach:=Vector2(source.approach_foot_px[0],source.approach_foot_px[1])*Vector2(1.25,1.25)-Vector2(0,42)
		if not _check(_body_raw(foot-Vector2(0,42)) and bool(oracle.call("clear",foot)) and own_ground and _clear(approach),"NPC original875/17/native Physics own ground excludes self only; approach excludes none"): return false
		var image:=texture.get_image()
		var cell_width:=texture.get_width()/npc.sprite.hframes
		var visible_frames: Array=[]
		for frame: int in npc.sprite.hframes:
			var bounds:=image.get_region(Rect2i(frame*cell_width,0,cell_width,texture.get_height())).get_used_rect()
			var visible_y: float=npc.sprite.position.y+(float(bounds.end.y)-texture.get_height()*.5)*npc.sprite.scale.y
			visible_frames.append({"frame":frame,"alpha_bounds":bounds,"visible_height_world_px":bounds.size.y*npc.sprite.scale.y,"visible_foot_offset_from_authored_world_px":visible_y})
		rows.append({"kind":"ACTUAL_NATIVE_ROOM_NPC_BODY_AND_ALPHA_FEET","npc":npc.npc_id,"foot":foot,"body_size":(shape.shape as RectangleShape2D).size,"body_center":world.to_local(shape.global_position),"ground_Physics_excludes_own_body_only":own_ground,"approach_full87517_Physics_no_exclusion":true,"frames":visible_frames,"no_invented_visual_zero_offset_tolerance":true})
	return true

func _run_room_trip(item: Dictionary) -> bool:
	if not await _setup_city(MARKET_ID,item.setup,"near_"+String(item.type)) or not await _way(PackedVector2Array([item.setup,item.stand]),"normal_final56px_"+String(item.type)) or not _overlap_target(item.id): return false
	retained=field; retained_identity=_identity(field); retained_nav=_nav_snapshot()
	retained_connections=_singleton_connection_count(field); retained_mode=field.process_mode
	retained_validations=C._transition_full_validations; resident_initial_scene=candidate_scene
	watch_resident_jobs=true
	var began:=Time.get_ticks_usec()
	await driver.call("key",KEY_SPACE)
	if not await _wait_revision(item.id) or not await _wait_hidden_operable() or not _parked_assert(String(item.type)) or not _actual_room_npcs(): return false
	var player: Node2D=field.get("_player") as Node2D
	var world: Vector2=field.get("_world_size")
	var spawn:=Vector2(functional_spec.spawn_foot_px[0],functional_spec.spawn_foot_px[1])*world/Vector2(1536,1024)-Vector2(0,42)
	if not _check(player.position.distance_to(spawn)<.03 and _clear(player.position),"Actual new sourcefeet spawn converts once and full875/17/Physics "+String(item.type)): return false
	captures.append(await _capture_gate("inside_"+String(item.type)))
	var exit_origin:=Vector2(768,885)*world/Vector2(1536,1024)-Vector2(0,42)
	if not await _way(PackedVector2Array([player.position,exit_origin]),"normal_new_room_sourcefloor_exit_"+String(item.type)) or not _overlap_target(MARKET_ID): return false
	var old_room: WeakRef=weakref(field)
	var return_started:=Time.get_ticks_usec()
	await driver.call("key",KEY_SPACE)
	if not await _wait_revision(MARKET_ID) or not await _wait_hidden_operable(): return false
	var returned_ms: float=(Time.get_ticks_usec()-return_started)/1000.0
	var receipt: Dictionary={"kind":"NORMAL_NEW_ROOM_TRIP_AND_FAST_RETURN","type":item.type,"source_room_id":item.id,"total_trip_ms":(Time.get_ticks_usec()-began)/1000.0,"return_hidden_operable_ms":returned_ms,"return_limit_ms":RETURN_LIMIT_MS,"remembered_foot":item.stand,"authored_marker":item.door,"actual_foot":(field.get("_player") as Node2D).position,"resident":_resident_state(),"source_jobs":resident_source_activity.duplicate(true)}
	functional_trips.append(receipt); rows.append(receipt)
	if not _check(returned_ms<RETURN_LIMIT_MS and field==retained and _identity(field)==retained_identity and candidate_scene==resident_initial_scene and _nav_equal(retained_nav) and (field.get("_player") as Node2D).position.distance_to(item.stand)<.03 and _clear(item.stand) and C._transition_full_validations==retained_validations and resident_source_activity.is_empty() and old_room.get_ref()==null and _singleton_connection_count(field)==retained_connections,"Normal Space under2000ms Loading-hidden/operable same-identity exact remembered-foot return "+String(item.type)): return false
	watch_resident_jobs=false
	captures.append(await _capture_gate("returned_"+String(item.type)))
	return await _way(PackedVector2Array([item.stand,item.stand+Vector2(16,0),item.stand]),"actual_normal_INPUT_after_fast_return_"+String(item.type))

func _warehouse_disabled_probe() -> bool:
	if not await _setup_city(DOCKS_ID,Vector2(940,750),"warehouse_door_original_source_probe_only"): return false
	var points:=PackedVector2Array([Vector2(940,750),Vector2(754,750),Vector2(754,610)])
	var full_route:=true
	for index: int in range(points.size()-1): full_route=full_route and bool(_segment(points[index],points[index+1]).get("clear",false))
	var foot_safe:=_clear(Vector2(754,610))
	var disabled: bool=not ROOMS.known(&"luoyang_canal_warehouse_interior_20261016")
	warehouse_probe={"kind":"DISABLED_WAREHOUSE_REAL_ORIGINAL_DOOR_PROBE_ONLY","full_route87517Physics":full_route,"door_foot87517Physics":foot_safe,"door_still_disabled":disabled,"normal_route_walked":false,"not_entry_or_publisher_credit":true}
	if full_route and foot_safe:
		warehouse_probe.normal_route_walked=await _way(points,"native_INPUT_original_warehouse_door_probe_only")
		captures.append(await _capture_gate("disabled_warehouse_source_door_probe"))
	rows.append(warehouse_probe)
	# Unsafe is a reported refusal, never an excuse to open or relocate this door.
	return _check(disabled and (not full_route or not foot_safe or warehouse_probe.normal_route_walked),"Warehouse remains disabled; exact safe native approach or explicit refusal recorded")

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+180000
	output="res://build/luoyang_functional_rooms_field_key_20261016/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique own functional-room key output")
	_check("--luoyang-functional-room-field-key" in OS.get_cmdline_user_args() and ROOMS.FLAG in OS.get_cmdline_user_args() and not REVISION_FLAG in OS.get_cmdline_user_args(),"Explicit new room candidate only, no old map candidate flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual normal-clock installed GPU engine")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	var complete:=false
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_resident_frame); process_frame.connect(_room_source_frame)
		complete=true
		for item: Dictionary in ROOM_CASES:
			if not await _run_room_trip(item): complete=false; break
		if complete: complete=await _warehouse_disabled_probe()
	watch_resident_jobs=false
	for callback: Callable in [_resident_frame,_room_source_frame]:
		if process_frame.is_connected(callback): process_frame.disconnect(callback)
	root.get_node("SceneRouter").call("reset_for_new_game")
	retained=null; resident_initial_scene=null; retained_nav.clear()
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Final independent navigation source identity"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null; functional_spec.clear()
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	var source_after:=_sources(); var players_after:=_players()
	_check(source_after==source_before and players_after==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Full closed sources/15save/slot/checkpoint remain exact")
	_check(complete and Time.get_ticks_msec()<deadline and functional_trips.size()==2 and not warehouse_probe.is_empty(),"Shared180/arrival60/return2000 two native doors and disabled original warehouse probe complete")
	_save_evidence("result.json",{"scope":"TWO_MATCHED_FUNCTIONAL_ROOMS_NATIVE_TRIPS_AND_DISABLED_WAREHOUSE_PROBE_ONLY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":180000,"arrival_ms":60000,"return_limit_ms":RETURN_LIMIT_MS,"trips":functional_trips,"warehouse_probe":warehouse_probe,"records":rows,"captures":captures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"production_proofs":production_proofs,"production_finalized":production_finalized,"CPU_proof":ROOM_CPU_RESULT,"pawn_mansion_warehouse_room_native_or_all_city_credit":false,"ROOT_complete_stderr_exactticks_natural_exit_required":true})
	print("LUOYANG_FUNCTIONAL_ROOM_KEY=",output,"result.json checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
