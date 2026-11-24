extends "res://tests/test_luoyang_three_exterior_doors_cpu_20261016g.gd"
## NOTREADY. ROOT-only three real Space trips; no parent CPU run, no long city travel.
const DOORS_READY=true
const WHOLE_MS=180000
const ARRIVAL_MS=60000
const RETURN_MS=2000
const M=preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const INPUT=preload("res://tests/helpers/v15_input_driver.gd")
var field: Node
var scene: SceneScript
var independent: RefCounted
var driver: RefCounted
var active_mask: Image
var door_rows: Array[Dictionary]=[]
var pictures: Array[Dictionary]=[]
var native_queries:=0
var folder: String
func _precheck_actual() -> bool:
	if not check(DOORS_READY,"NOTREADY until ROOT approves three-door atomic scope and actual prerequisites"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary real GUI clock/no candidate flags"): return false
	var pins: Dictionary={M.SELF:"9e8e02af2b20938ebe9b4ab7000a3fba6a2eab22abb756c15442689410da64d3",M.REGISTRY_PATH:"725551952029cfabc92d5d875484a2b09e37fa64a451c3410351036cfa13d144",CONTRACT:CONTRACT_SHA,RAW_PATH:RAW_SHA,"res://tests/test_luoyang_three_exterior_doors_cpu_20261016g.gd":"91c09043fc1ad85fb392909ed3b6235ddf064dee3bea943365c91cd88fdb5b89","res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd":"a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","res://scripts/field/field_walkable_controller.gd":"638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839","res://scripts/autoload/scene_router.gd":"1082a842eb283a7eba339f9589bbcb0a5803d934c79f60d9e7a7f0413069bd92","res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d","res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"26e2e263426719878cd6e7853878d25277e25483cbb495bb3df44116efc6b5b8","res://scripts/city/luoyang_resident_field_20261016.gd":"f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	package=M.catalogue()
	if not check(M.FORMAL_ENABLED and package.get("rooms",{}).size()==11,"Default new-room catalogue, not candidate fallback"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	for source: Dictionary in contract.combined_navigation_sources.values():
		if source.has("path") and not track(source.path,source.sha256): return false
	author=JSON.parse_string(FileAccess.get_file_as_string(contract.combined_navigation_sources.district_author.path))
	return check(contract.doors.size()==3,"Exactly three source-measured new bays, no other doors")
func _wait_actual(id: StringName,arrival_ms: int) -> bool:
	var until: int=mini(deadline,Time.get_ticks_msec()+arrival_ms)
	while Time.get_ticks_msec()<until:
		await process_frame
		var request: Dictionary=root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id")==String(id) and request.get("phase")=="FAILED": return check(false,"Matching actual public request failed",request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("failed",false): return check(false,"Actual Field setup failed",state)
		var candidate:=current_scene.get("_current_scene") as SceneScript
		var player:=current_scene.get("_player") as CharacterBody2D
		if candidate==null or candidate.scene_id!=id or player==null or not player.is_inside_tree() or not bool(player.get("can_move")) or not state.get("complete",false): continue
		var loading: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=loading.get("root") as Control if is_instance_valid(loading) else null
		if panel!=null and panel.is_visible_in_tree(): continue
		if String(id).begins_with("ch4_s"):
			var proof: Dictionary=C.resident_receipt(candidate)
			if not proof.get("sources_finalized",false): continue
			if not check(not proof.get("sources",{}).is_empty(),"Actual complete city owner finalized source proof"): return false
			for path: String in source_before:
				if proof.sources.has(path) and not check(proof.sources[path]==source_before[path].sha256,"Actual city source proof equals precheck "+path): return false
			records.append({"kind":"CITY_FINAL_SOURCE_PROOF","scene_id":id,"proof":proof.duplicate(true)})
		else:
			if not check(M.is_room(candidate) and M._scene_sessions.get(candidate.get_instance_id(),{}).get("setup_source_finalized")==true,"Actual room per-row source/storage finalized, not C city proxy"): return false
		field=current_scene;scene=candidate;return true
	return check(false,"Actual arrival includes finalsource/Loadinghidden/canmove within fixed limit",{"target":id,"limit_ms":arrival_ms})
func _native(foot: Vector2) -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var world:=field.get("world_container") as Node2D
	if not check(shape.position==Vector2.ZERO and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==Vector2(34,24),"Actual feet-native34x24, no child offset"): return false
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position;query.exclude=[player.get_rid()];query.collision_mask=1;query.collide_with_areas=false
	native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func _clear_actual(foot: Vector2) -> bool:
	return Time.get_ticks_msec()<deadline and is_instance_valid(field) and current_scene==field and independent!=null and independent.clear(foot) and (active_mask==null or _mask_clear(active_mask,foot)) and _native(foot)
func _segment_actual(a: Vector2,b: Vector2) -> Dictionary:
	var count: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for i: int in range(count+1):
		var point: Vector2=a.lerp(b,float(i)/count)
		if Time.get_ticks_msec()>=deadline or not independent.clear(point) or (active_mask!=null and not _mask_clear(active_mask,point)): return {"clear":false,"sample":i,"foot":point,"raw":independent.last}
	return {"clear":true,"samples":count+1,"full87517":true,"continuous34x24":true,"step_world_le4":true}
func _input(points: PackedVector2Array,label: String) -> bool:
	var result: Dictionary=await driver.follow(field,points,_clear_actual,_segment_actual)
	records.append({"kind":"NORMAL_INPUT","label":label,"result":result})
	return check(result.get("ok")==true,"Actual short INPUT full87517/nativePhysics "+label,result)
func _overlap(target: String,expected: Vector2) -> bool:
	await driver.completed_actor_stage()
	var found: Array[Node2D]=[]
	var player:=field.get("_player") as CharacterBody2D
	for zone: Node2D in field.get("_exit_nodes"):
		if String(zone.get("target_scene_id"))==target and zone.position==expected: found.append(zone)
	if not check(found.size()==1,"One actual exact native portal target/position"): return false
	var zone: Node2D=found[0]
	var shape:=zone.get_node("CollisionShape2D") as CollisionShape2D
	records.append({"kind":"ACTUAL_PORTAL_OVERLAP","target":target,"position":zone.position,"size":(shape.shape as RectangleShape2D).size,"player":player.position,"overlap":zone.overlaps_body(player),"in_range":zone.get("_in_range"),"target_uv":zone.get("target_spawn_pos")})
	return check(zone.overlaps_body(player) and zone.get("_in_range")==true and zone.get("is_locked")==false and zone.get("auto_trigger")==false and _clear_actual(player.position),"Native Area overlap+unlocked and safe body before genuine Space")
func _bind_city(door: Dictionary) -> bool:
	var context: Dictionary=_context(door)
	if context.is_empty(): return false
	independent=context.oracle;active_mask=context.mask
	return check(scene.actor_positions_are_feet and field.get("_world_size")==WORLD and _clear_actual(field.get("_player").position),"Independent source-bound parent plus additive bases/native city feet")
func _bind_inside(row: Dictionary) -> bool:
	var data: Dictionary=M.author_for_id(scene.scene_id)
	if not check(scene.resource_path==row.scene_path and scene.map_layout.resource_path==row.layout_path and scene.actor_positions_are_feet,"Space reached exact new room Scene/layout/feet"): return false
	var solids: Array=[]
	for base: Dictionary in data.geometry.furniture_bases:
		if base.get("blocking",false): solids.append({"id":base.id,"kind":base.kind,"points_px":base.ground_polygon_px})
	independent=RAW.new();active_mask=null
	var world: Vector2=field.get("_world_size")
	return check(world==Vector2(1920,1280) and independent.configure(data.geometry.floor_regions_px,solids,Vector2(1536,1024),world,data.geometry.foot_forbidden_regions_px) and field.get("_player").position==_v(data.geometry.spawn_foot_px)*(world/Vector2(1536,1024)) and _clear_actual(field.get("_player").position),"Actual room spawn independent floor/base/foot-only columns/full87517/nativePhysics")
func _trip_door(door: Dictionary) -> bool:
	var row: Dictionary=package.rooms[door.room_id]
	var points:=PackedVector2Array()
	for point: Array in door.approach_route_px: points.append(_v(point))
	var router: Node=root.get_node("SceneRouter");var setup: int=Time.get_ticks_usec()
	var accepted: bool=router.call("go_field_smart",StringName(door.city_id),points[0]/WORLD,"",-1,3)
	if not check(accepted,"Public current-version3 near-door setup, explicitly NOT travel") or not await _wait_actual(StringName(door.city_id),ARRIVAL_MS) or not _bind_city(door): return false
	records.append({"kind":"PUBLIC_SETUP_ONLY","city":door.city_id,"elapsed_usec":Time.get_ticks_usec()-setup,"travel_credit":false})
	if not check(field.get("_player").position.distance_to(points[0])<.03,"Legal public initial foot, no private teleport") or not await _input(points,"exterior_"+door.portal_id): return false
	# UV -> native world uses precisely the same operation as Field, not a source-pixel roundtrip.
	var native_door: Vector2=(_v(door.return_foot_px)/WORLD)*WORLD
	if not await _overlap(door.room_id,native_door): return false
	var entered_foot: Vector2=field.get("_player").position
	var expected_remembered: Vector2=(entered_foot/WORLD)*WORLD
	if not check(entered_foot.distance_to(native_door)<=.3,"Actual normal INPUT reached source-bound door axis within original INPUT tolerance"): return false
	var exterior: WeakRef=weakref(field);var original_player: WeakRef=weakref(field.get("_player"));var original_scene_id: int=scene.get_instance_id()
	var entered: int=Time.get_ticks_usec();await driver.key(KEY_SPACE)
	if not await _wait_actual(StringName(door.room_id),ARRIVAL_MS) or not _bind_inside(row): return false
	await RenderingServer.frame_post_draw
	var path: String=folder.path_join(row.type_id+"_entered_by_Space.png")
	var image: Image=root.get_texture().get_image()
	if not check(image!=null and image.save_png(path)==OK,"One real doorway-entered room screenshot"): return false
	pictures.append({"room":door.room_id,"path":path,"sha256":FileAccess.get_sha256(path)})
	var data: Dictionary=M.author_for_id(scene.scene_id);var indoor:=PackedVector2Array()
	for route: Dictionary in data.geometry.required_routes:
		if route.id=="spawn_to_exit":
			for point: Array in route.points_px: indoor.append(_v(point)*Vector2(1.25,1.25))
	if not check(indoor.size()>=2,"Pinned spawn-to-exit route exists") or not await _input(indoor,"indoor_spawn_to_exit"): return false
	var exit: Dictionary=scene.map_layout.portals[0];var native_exit: Vector2=exit.pos*(field.get("_world_size") as Vector2)
	if not await _overlap(door.city_id,native_exit): return false
	var returning: int=Time.get_ticks_usec();await driver.key(KEY_SPACE)
	if not await _wait_actual(StringName(door.city_id),RETURN_MS) or not _bind_city(door): return false
	var elapsed: int=Time.get_ticks_usec()-returning
	var foot: Vector2=field.get("_player").position
	if not check(elapsed<RETURN_MS*1000 and field==exterior.get_ref() and field.get("_player")==original_player.get_ref() and scene.get_instance_id()==original_scene_id and foot==expected_remembered and _clear_actual(foot),"Exact corresponding remembered entry foot/native UV, same Field/Player/Scene, hidden+operable <2000ms",{"elapsed_usec":elapsed,"actual_foot":foot,"expected":expected_remembered,"door_axis":native_door,"entry_foot":entered_foot}): return false
	door_rows.append({"room":door.room_id,"city":door.city_id,"entry_usec":returning-entered,"return_usec":elapsed,"foot":foot,"actual_Space_both_directions":true,"same_resident_Field":true})
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_three_doors_actual_20261018q/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=_precheck_actual()
	if complete:
		driver=INPUT.new();driver.configure(self)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
		for door: Dictionary in contract.doors:
			if not await _trip_door(door): complete=false;break
	if driver!=null: driver.release();driver=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;var weak: WeakRef=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
		await process_frame;await process_frame
		if not check(weak.get_ref()==null,"Own final Field actually tree-exited"): complete=false
	contexts.clear();independent=null;active_mask=null
	records.append({"kind":"THREE_DOOR_SCOPE","doors":door_rows,"captures":pictures,"native_queries":native_queries,"whole_ms":WHOLE_MS,"arrival_ms":ARRIVAL_MS,"return_ms":RETURN_MS,"public_setups_are_not_travel":true,"ten_room_component_suite_retested":false})
	complete=check(door_rows.size()==3 and pictures.size()==3,"Three distinct actual Space entries/precise returns, independent outcomes") and complete
	finish(folder,began,complete,"THREE_NEW_EXTERIOR_DOORS_REAL_SPACE_PHYSICS_AND_EXACT_RETURNS_ONLY")

