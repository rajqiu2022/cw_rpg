extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## One explicit near-door inspection and real Space/INPUT roundtrip, not default travel.
const FIXTURE_READY=false
const FIXTURE="PENDING_ROOT33_HALL_FIXTURE"
const FIXTURE_SHA="PENDING_ROOT33_HALL_FIXTURE_SHA"
const CITY=&"ch4_s1_luoyang_yamen"
const ROOM=&"luoyang_yamen_official_hall_20261018t"
const WHOLE_MS=60000
const ENTRY_MS=20000
const ROOM_MS=20000
const RETURN_MS=10000
const INPUT_DRIVER=preload("res://tests/helpers/v15_input_driver.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const G=preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
var fixture: Dictionary={}
var driver: RefCounted
var field: Node
var scene: SceneScript
var armed_id: StringName=&""
var leg: String=""
var trigger_usec: int=0
var first_draw: Dictionary={}
var first_ready: Dictionary={}
var exterior: WeakRef
var exterior_player: WeakRef
var exterior_scene: WeakRef
var exterior_layout: WeakRef
var exterior_ids: Dictionary={}
var parked_generation: int=-1
var actual_physics_queries: int=0
var actual_mask_samples: int=0

func _v(a: Variant) -> Vector2:
	return a if a is Vector2 else Vector2(a[0],a[1])

func _clock() -> Dictionary:
	return {"usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames()}

func precheck() -> bool:
	if not check(FIXTURE_READY,"Only independently frozen hall scope") or not track(FIXTURE,FIXTURE_SHA): return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(parsed is Dictionary and parsed.get("ready")==true,"Frozen current hall fixture"): return false
	fixture=parsed
	if not check(fixture.whole_ms==WHOLE_MS and fixture.entry_ms==ENTRY_MS and fixture.room_ms==ROOM_MS and fixture.return_ms==RETURN_MS and fixture.max_pictures==0,"Prior60s whole/20s entry/20s room/<10s return, no extension"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Ordinary GUI without candidate arguments"): return false
	if not check(fixture.expected_city_sources.size()==1239 and fixture.expected_G_global_sources.size()==557 and fixture.hall_row.source_sha256.size()==247,"Separate city1239/globalG557/historicalhall247 domains"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	for table: Dictionary in [fixture.expected_city_sources,fixture.expected_G_global_sources]:
		for path: String in table:
			if not check(fixture.source_sha256.get(path)==table[path],"Protect every independent complete source leaf"): return false
	return true

func _loading_hidden() -> bool:
	var lm: Node=root.get_node("LoadingManager")
	var screen: Node=lm.get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	return lm.get("_external_active")!=true and lm.get("_transition_active")!=true and (panel==null or not panel.is_visible_in_tree())

func _observe_ready() -> void:
	if armed_id==&"" or not first_ready.is_empty() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if current==null or current.scene_id!=armed_id or player==null or not player.can_process() or player.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	if state.get("complete")==true and state.get("failed",false)!=true:
		first_ready=_clock();first_ready["elapsed_usec"]=int(first_ready.usec)-trigger_usec

func _draw() -> void:
	if armed_id==&"" or not first_draw.is_empty() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if current==null or current.scene_id!=armed_id or player==null or not player.can_process() or player.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	if state.get("complete")!=true or state.get("failed",false)==true or not _loading_hidden(): return
	if armed_id==CITY and (C._resident_ready.get("scene")!=current or C._resident_ready.get("sources_finalized")!=true): return
	if armed_id==ROOM:
		var session: Dictionary=G._sessions.get(current.get_instance_id(),{})
		if session.get("finalized")!=true: return
	# First hidden+operable rendered frame: no source copies, SHA or deep checks yet.
	first_draw=_clock()
	first_draw.merge({"elapsed_usec":int(first_draw.usec)-trigger_usec,"leg":leg,"Field":current_scene.get_instance_id(),"Player":player.get_instance_id(),"Scene":current.get_instance_id(),"layout":current.map_layout.get_instance_id(),"foot":player.position,"loading_hidden_inactive":true,"can_move":true})

func _arm(id: StringName,label: String) -> void:
	armed_id=id;leg=label;trigger_usec=Time.get_ticks_usec();first_draw={};first_ready={}

func _arrive(limit_ms: int) -> bool:
	var until: int=mini(deadline,int(trigger_usec/1000)+limit_ms)
	while Time.get_ticks_msec()<until:
		_observe_ready()
		var public_state: Dictionary=root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if public_state.get("scene_id")==String(armed_id) and public_state.get("phase")=="FAILED":
			records.append({"kind":"HALL_PUBLIC_FAILURE","leg":leg,"public":public_state,"C_errors":C.errors()})
			return check(false,"Matching public failure, no success arrival time")
		if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
			var state: Dictionary=current_scene.call("get_field_loading_state")
			if state.get("scene_id")==String(armed_id) and state.get("failed")==true:
				records.append({"kind":"HALL_FIELD_FAILURE","leg":leg,"loading":state,"public":public_state})
				return check(false,"Matching Field failed before hidden operable draw")
		if not first_draw.is_empty():
			field=current_scene;scene=field.get("_current_scene") as SceneScript
			records.append({"kind":"HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY","leg":leg,"ready":first_ready.duplicate(),"draw":first_draw.duplicate()})
			armed_id=&""
			return check(int(first_draw.elapsed_usec)<limit_ms*1000,"Fixed arrival limit includes hidden operable rendered frame "+leg)
		await process_frame
	records.append({"kind":"HALL_ARRIVAL_TIMEOUT","leg":leg,"limit_ms":limit_ms,"ready":first_ready,"draw":first_draw,"lease":root.get_node("SceneRouter").call("get_resident_city_state")})
	armed_id=&""
	return check(false,"Original per-leg and whole budget, no added time "+leg)

func _clear(foot: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not is_instance_valid(field) or field!=current_scene or not foot.is_finite(): return false
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D if player!=null else null
	if shape==null or shape.disabled or shape.position!=Vector2.ZERO or not shape.shape is RectangleShape2D or shape.shape.size!=Vector2(34,24): return false
	var size: Vector2=field.get("_world_size")
	if foot.x<17 or foot.y<12 or foot.x>size.x-17 or foot.y>size.y-12: return false
	# The already-loaded native mask only:17 local samples, not a new875 route test.
	var mask: Image=field.get("_walkable_mask_image") as Image
	if mask!=null:
		var offsets: Array[Vector2]=[Vector2.ZERO,Vector2(-17,-12),Vector2(17,-12),Vector2(17,12),Vector2(-17,12),Vector2(-17,0),Vector2(17,0),Vector2(0,-12),Vector2(0,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6),Vector2(-8,-12),Vector2(8,-12),Vector2(-8,12),Vector2(8,12)]
		for offset: Vector2 in offsets:
			var pixel: Vector2i=Vector2i(foot.round()+offset);actual_mask_samples+=1
			if pixel.x<0 or pixel.y<0 or pixel.x>=mask.get_width() or pixel.y>=mask.get_height() or mask.get_pixelv(pixel)!=Color.WHITE: return false
	var world: Node2D=field.get("world_container") as Node2D
	if world==null: return false
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.exclude=[player.get_rid()];query.collision_mask=player.collision_mask;query.collide_with_areas=false
	actual_physics_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,16).is_empty()

func _walk(points: Array,label: String) -> bool:
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	if not check(player.position.distance_to(_v(points[0]))<=.3 and _clear(player.position),"Fixed native initial foot and full original34x24 clearance "+label): return false
	for index: int in range(1,points.size()):
		var result: Dictionary=await driver.drive(field,_v(points[index]),_clear)
		records.append({"kind":"HALL_REAL_INPUT","label":label,"result":result,"body":"ORIGINAL34x24_NATIVE_PHYSICS","mask":"LOADED_ACTUAL17_WHEN_PRESENT_NOT_NEW_GEOMETRY"})
		if not check(result.get("ok")==true and _clear(player.position),"Real INPUT fixed endpoint .3px, never teleport "+label,result): return false
	return true

func _zone(target: StringName,foot: Vector2,spawn: Vector2) -> bool:
	await driver.completed_actor_stage()
	var found: Array[Area2D]=[]
	for node: Node in field.get("_exit_nodes"):
		if node is Area2D and node.get("target_scene_id")==String(target) and node.position==foot: found.append(node)
	if not check(found.size()==1,"One exact authored native target and door foot"): return false
	var zone: Area2D=found[0]
	var collider: CollisionShape2D=zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var good: bool=zone.is_inside_tree() and zone.monitoring and zone.get("is_locked")==false and zone.get("auto_trigger")==false and zone.get("target_spawn_pos")==spawn and collider!=null and not collider.disabled and zone.overlaps_body(field.get("_player")) and zone.get("_in_range")==true
	records.append({"kind":"HALL_ACTUAL_NATIVE_ZONE","target":String(target),"zone_id":zone.get_instance_id(),"position":zone.position,"target_spawn":zone.get("target_spawn_pos"),"enabled_overlap_inrange":good,"actual_player_foot":field.get("_player").position})
	return check(good and _clear(field.get("_player").position),"Enabled exact-target native Area and actual full-body overlap before Space")

func _city_owner(initial: bool) -> bool:
	var natural: Dictionary=C._resident_ready
	if not check(natural.get("scene")==scene and natural.get("id")==CITY and natural.get("sources_finalized")==true and int(natural.get("token",0))>0 and natural.get("proof_kind")=="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1","Natural same exterior finalized C owner, no validator call"): return false
	var sources: Dictionary=natural.get("sources",{})
	if not check(sources==fixture.expected_city_sources and sources.size()==1239,"Full independent1239 C sources, no collector fill"): return false
	if not check(scene.resource_path==fixture.city_scene_path and scene.map_layout.resource_path==fixture.city_layout_path and scene.actor_positions_are_feet,"Exact current source-bound exterior Scene/layout"): return false
	records.append({"kind":"HALL_NATURAL_CITY_SOURCE_OWNER_AFTER_DRAW","initial":initial,"source_count":sources.size(),"sources":sources.duplicate(),"token":natural.token,"new_fresh_validation_claim":initial,"warm_return_reuses_original_finalized_proof":not initial})
	return _clear(field.get("_player").position)

func _room_owner() -> bool:
	var session: Dictionary=G._sessions.get(scene.get_instance_id(),{})
	var config: Dictionary=G._config
	var row: Dictionary=config.get("rooms",{}).get(String(ROOM),{})
	if not check(session.get("finalized")==true and session.get("scene") is WeakRef and session.get("layout") is WeakRef,"Field-created naturally finalized G session"): return false
	if not check(session.scene.get_ref()==scene and session.layout.get_ref()==scene.map_layout and row==fixture.hall_row and session.get("author")==fixture.hall_author,"Natural exact Scene/layout/author/247 historical registry row"): return false
	if not check(scene.resource_path==row.scene_path and scene.map_layout.resource_path==row.layout_path and scene.actor_positions_are_feet and scene.display_name==fixture.room_display_name,"Exact native hall paths and feet, not another room"): return false
	var protected: int=0
	for path: String in fixture.expected_G_global_sources:
		if not check(source_before.get(path,{}).get("sha256")==fixture.expected_G_global_sources[path],"Complete independent globalG source protected before load"): return false
		protected+=1
	records.append({"kind":"HALL_NATURAL_G_SESSION_AND_SEPARATE_GUARD","session_finalized":true,"Scene":scene.get_instance_id(),"layout":scene.map_layout.get_instance_id(),"session_author_exact":true,"native_paths_exact":true,"historical_row_count":row.source_sha256.size(),"global_independent_guard_count":protected,"session_has_no_full_source_receipt":true,"global_guard_not_G_FIRSTFINAL_or_collector_result":true,"historical_DT_successor":fixture.historical_DT_successor})
	return check(protected==557 and _clear(field.get("_player").position),"All557 guarded independently; original34x24 actual body clear")

func _keep_exterior() -> void:
	exterior=weakref(field);exterior_player=weakref(field.get("_player"));exterior_scene=weakref(scene);exterior_layout=weakref(scene.map_layout)
	exterior_ids={"Field":field.get_instance_id(),"Player":field.get("_player").get_instance_id(),"Scene":scene.get_instance_id(),"layout":scene.map_layout.get_instance_id()}

func _parked() -> bool:
	var lease: Dictionary=root.get_node("SceneRouter").call("get_resident_city_state")
	var retained: Node=exterior.get_ref() as Node
	var same: bool=retained!=null and retained.get_instance_id()==exterior_ids.Field and not retained.is_inside_tree() and exterior_player.get_ref()!=null and exterior_scene.get_ref()!=null and exterior_layout.get_ref()!=null and retained.get("_player")==exterior_player.get_ref() and retained.get("_current_scene")==exterior_scene.get_ref() and (exterior_scene.get_ref() as SceneScript).map_layout==exterior_layout.get_ref()
	records.append({"kind":"HALL_REAL_PARKED_LEASE","lease":lease,"retained_alive_detached_identity":same,"saved_ids":exterior_ids})
	parked_generation=int(lease.get("generation",-1))
	return check(same and lease.get("occupied")==true and lease.get("parked")==true and lease.get("phase")=="PARKED" and lease.get("excursion_kind")=="room" and lease.get("room")==String(ROOM) and lease.get("field_id")==exterior_ids.Field and parked_generation>0 and int(lease.get("estimated_bytes",0))>0 and int(lease.estimated_bytes)<=536870912 and int(lease.get("limit_bytes",0))==536870912,"Original living exterior PARKED within512MiB; refusal is failure")

func _returned() -> bool:
	var lease: Dictionary=root.get_node("SceneRouter").call("get_resident_city_state")
	var ret: Dictionary=lease.get("return",{})
	var same: bool=field==exterior.get_ref() and field.get("_player")==exterior_player.get_ref() and scene==exterior_scene.get_ref() and scene.map_layout==exterior_layout.get_ref()
	records.append({"kind":"HALL_REAL_RESUMED_LEASE","lease":lease,"same_original_Field_Player_Scene_layout":same,"actual_return_foot":field.get("_player").position,"expected_author_foot":_v(fixture.author_return_world),"saved_ids":exterior_ids,"hidden_operable_draw":first_draw})
	if not check(same and lease.get("phase")=="RESUMED" and lease.get("occupied")==false and lease.get("parked")==false and ret.get("hit")==true and ret.get("phase")=="READY" and ret.get("active")==false and ret.get("excursion_kind")=="room" and ret.get("final_live_identity")==true and ret.get("field_id")==exterior_ids.Field and int(ret.get("lease_generation",-1))==parked_generation and String(ret.get("miss_reason","")).is_empty(),"Actual same live exterior return hit READY/resumed with original lease generation"): return false
	if not check(ret.get("source_fresh_sha")==false and ret.get("source_basis")=="SAME_LIVE_OBJECTS_AND_EDITOR_METADATA" and ret.get("total_ms_excludes_loading_hide")==true,"Room lease metadata/live-identity credit, not new fresh SHA"): return false
	return check(int(first_draw.elapsed_usec)<10000000 and field.get("_player").position==_v(fixture.author_return_world) and _clear(field.get("_player").position),"Hidden operable warm return<10s and exact authored1536,660, not actual departure-foot equality")

func exercise_cpu() -> bool:
	_arm(CITY,"EXPLICIT_NEAR_DOOR_NOT_DEFAULT_TRAVEL")
	if not check(root.get_node("SceneRouter").call("go_field_smart",CITY,_v(fixture.setup_uv),"",-1,3),"One public near1536,716 setup, not default/world travel") or not await _arrive(ENTRY_MS): return false
	if not _city_owner(true): return false
	_keep_exterior()
	if not await _walk(fixture.street_input,"street716to660") or not await _zone(ROOM,_v(fixture.enter_zone_world),_v(fixture.room_spawn_uv)): return false
	records.append({"kind":"HALL_BEFORE_ENTER","actual_departure_foot":field.get("_player").position,"fixed_author_return":_v(fixture.author_return_world),"lease":root.get_node("SceneRouter").call("get_resident_city_state")})
	_arm(ROOM,"REAL_SPACE_HALL_ENTRY");await driver.key(KEY_SPACE)
	if not await _arrive(ROOM_MS) or not _room_owner() or not _parked(): return false
	if not await _walk(fixture.room_input,"room1050to1142.5") or not await _zone(CITY,_v(fixture.exit_zone_world),_v(fixture.author_return_uv)): return false
	records.append({"kind":"HALL_BEFORE_REAL_RETURN_SPACE","actual_room_departure_foot":field.get("_player").position,"lease":root.get_node("SceneRouter").call("get_resident_city_state")})
	_arm(CITY,"REAL_SPACE_SAME_EXTERIOR_WARM_RETURN");await driver.key(KEY_SPACE)
	if not await _arrive(RETURN_MS) or not _returned() or not _city_owner(false): return false
	records.append({"kind":"HALL_FINITE_ROUNDTRIP_COMPLETE","native_full_body_queries":actual_physics_queries,"actual_mask17_samples":actual_mask_samples,"pictures":0,"geometry_republication_or_full_routes":0,"collector_calls":0,"no_default_world_fulltravel_claim":true})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck():
		driver=INPUT_DRIVER.new();driver.configure(self);RenderingServer.frame_post_draw.connect(_draw)
		complete=await exercise_cpu()
	armed_id=&""
	if driver!=null: driver.release();driver=null
	if RenderingServer.frame_post_draw.is_connected(_draw): RenderingServer.frame_post_draw.disconnect(_draw)
	finish("PENDING_ROOT33_HALL_OUTPUT/%d_%d"%[OS.get_process_id(),began],began,complete,"ONE_EXPLICIT_NEAR_YAMEN_REAL_HALL_IN_OUT_SAME_RESIDENT_60s_0PICTURE_NO_COLLECTOR_OR_GEOMETRY")
