extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## One public near setup +24px realINPUT and ordinary camera image, no Space/room.
const FIXTURE_READY=false
const FIXTURE="PENDING_FROZEN_FIXTURE"
const FIXTURE_SHA="PENDING_FROZEN_FIXTURE_SHA"
const CITY=&"ch4_s3_luoyang_market"
const WHOLE_MS=60000
const ENTRY_MS=20000
const INPUT_DRIVER=preload("res://tests/helpers/v15_input_driver.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
var fixture: Dictionary={}
var driver: RefCounted
var field: Node
var scene: SceneScript
var armed: bool=false
var trigger_usec: int=0
var first_draw: Dictionary={}
var first_ready: Dictionary={}
var output: String=""
var actual_physics_queries: int=0
var actual_mask_samples: int=0

func _v(a: Variant) -> Vector2:
	return a if a is Vector2 else Vector2(a[0],a[1])

func _clock() -> Dictionary:
	return {"usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames()}

func precheck() -> bool:
	if not check(FIXTURE_READY,"Only frozen newMarket singleimage scope") or not track(FIXTURE,FIXTURE_SHA): return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(parsed is Dictionary and parsed.get("ready")==true,"Frozen current singleimage fixture"): return false
	fixture=parsed
	if not check(fixture.whole_ms==WHOLE_MS and fixture.entry_ms==ENTRY_MS and fixture.max_pictures==1 and fixture.expected_sources.size()==1700,"Fixed60s/20s/onepicture/Market1700 scope"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Ordinary GUI without candidate arguments"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	for path: String in fixture.expected_sources:
		if not check(fixture.source_sha256.get(path)==fixture.expected_sources[path],"Every independentMarket source protected"): return false
	return true

func _loading_hidden() -> bool:
	var lm: Node=root.get_node("LoadingManager")
	var screen: Node=lm.get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	return lm.get("_external_active")!=true and lm.get("_transition_active")!=true and (panel==null or not panel.is_visible_in_tree())

func _observe_ready() -> void:
	if not armed or not first_ready.is_empty() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if current==null or current.scene_id!=CITY or player==null or not player.can_process() or player.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	if state.get("complete")==true and state.get("failed",false)!=true:
		first_ready=_clock();first_ready["elapsed_usec"]=int(first_ready.usec)-trigger_usec

func _draw() -> void:
	if not armed or not first_draw.is_empty() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if current==null or current.scene_id!=CITY or player==null or not player.can_process() or player.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	if state.get("complete")!=true or state.get("failed",false)==true or not _loading_hidden(): return
	if C._resident_ready.get("scene")!=current or C._resident_ready.get("sources_finalized")!=true: return
	# Freeze first timestamp before source copies/deepchecks/image transfer.
	first_draw=_clock()
	first_draw.merge({"elapsed_usec":int(first_draw.usec)-trigger_usec,"Field":current_scene.get_instance_id(),"Player":player.get_instance_id(),"Scene":current.get_instance_id(),"layout":current.map_layout.get_instance_id(),"foot":player.position,"loading_hidden_inactive":true,"can_move":true})

func _arrive() -> bool:
	var until: int=mini(deadline,int(trigger_usec/1000)+ENTRY_MS)
	while Time.get_ticks_msec()<until:
		_observe_ready()
		var public_state: Dictionary=root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if public_state.get("scene_id")==String(CITY) and public_state.get("phase")=="FAILED":
			records.append({"kind":"MARKET_PUBLIC_FAILURE","public":public_state,"C_errors":C.errors()})
			return check(false,"Matching public failure, no arrival credit")
		if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
			var state: Dictionary=current_scene.call("get_field_loading_state")
			if state.get("scene_id")==String(CITY) and state.get("failed")==true:
				records.append({"kind":"MARKET_FIELD_FAILURE","loading":state})
				return check(false,"Matching Field failure before draw")
		if not first_draw.is_empty():
			field=current_scene;scene=field.get("_current_scene") as SceneScript;armed=false
			records.append({"kind":"MARKET_NEAR_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY","near_not_default_or_worldtravel":true,"ready":first_ready.duplicate(),"draw":first_draw.duplicate(),"under10s":int(first_draw.elapsed_usec)<10000000})
			return check(int(first_draw.elapsed_usec)<ENTRY_MS*1000,"Fixed20s hiddenoperable arrival cap, not10s promise")
		await process_frame
	armed=false
	return check(false,"Fixed entry/whole budget; no extra time")

func _clear(foot: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not is_instance_valid(field) or field!=current_scene or not foot.is_finite(): return false
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D if player!=null else null
	if shape==null or shape.disabled or shape.position!=Vector2.ZERO or not shape.shape is RectangleShape2D or shape.shape.size!=Vector2(34,24): return false
	var size: Vector2=field.get("_world_size")
	if foot.x<17 or foot.y<12 or foot.x>size.x-17 or foot.y>size.y-12: return false
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

func _city_owner() -> bool:
	var natural: Dictionary=C._resident_ready
	if not check(natural.get("scene")==scene and natural.get("id")==CITY and natural.get("sources_finalized")==true and int(natural.get("token",0))>0 and natural.get("proof_kind")=="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1","Natural finalized sameMarket owner, no validator call"): return false
	var sources: Dictionary=natural.get("sources",{})
	if not check(sources==fixture.expected_sources and sources.size()==1700,"Independent fullMarket1700, not observed expected fill"): return false
	if not check(scene.resource_path==fixture.scene_path and scene.map_layout.resource_path==fixture.layout_path and scene.actor_positions_are_feet,"Exact fixed nativeMarket Scene/layout"): return false
	records.append({"kind":"MARKET_NATURAL_FINAL1700_AFTER_DRAW","token":natural.token,"source_count":sources.size(),"sources":sources.duplicate()})
	return true

func _capture_one() -> bool:
	await driver.completed_actor_stage()
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	if not check(camera!=null and camera.enabled and root.get_camera_2d()==camera and camera.zoom==Vector2.ONE and root.get_visible_rect().size==Vector2(1920,1080),"Original normal1920x1080 camera zoom1, no private framing"): return false
	records.append({"kind":"MARKET_ORIGINAL_CAMERA_ONLY","camera_instance":camera.get_instance_id(),"position":camera.position,"screen_center":camera.get_screen_center_position(),"zoom":camera.zoom,"smoothing":camera.position_smoothing_enabled,"limits":[camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom],"viewport":root.get_visible_rect().size,"actual_player_foot":field.get("_player").position,"camera_or_player_position_writes":0})
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(1920,1080),"One actual full ordinary viewport image"): return false
	DirAccess.make_dir_recursive_absolute(output)
	var path: String=output.path_join("market_pawn_current_normal_camera.png")
	if not check(image.save_png(path)==OK,"Save exactly one actualPNG without editing"): return false
	records.append({"kind":"MARKET_ONE_CURRENT_ART_OBSERVATION","path":path,"sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()],"foot":field.get("_player").position,"not_ART_approval":true,"pictures":1})
	return true

func exercise_cpu() -> bool:
	armed=true;trigger_usec=Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",CITY,_v(fixture.setup_uv),"",-1,3),"One public near570,1928 setup, not defaultworldtravel") or not await _arrive(): return false
	if not _city_owner(): return false
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	if not check(player.position.distance_to(_v(fixture.input_world[0]))<=.3 and _clear(player.position),"Fixed authorednear initial34x24 actual clearance"): return false
	var result: Dictionary=await driver.drive(field,_v(fixture.input_world[1]),_clear)
	records.append({"kind":"MARKET_REAL_INPUT_24PX_ONLY","result":result,"no_Space_or_room_or_crossdistrict":true})
	if not check(result.get("ok")==true and _clear(player.position),"RealINPUT endpoint original.3px and nativebody, never reposition",result): return false
	if not await _capture_one(): return false
	return check(current_scene==field and field.get("_current_scene")==scene and player.position.distance_to(_v(fixture.input_world[1]))<=.3 and _loading_hidden() and _clear(player.position),"SameMarket after oneimage, no transition/no alteredbody")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WHOLE_MS
	output="PENDING_OUTPUT_ROOT/%d_%d"%[OS.get_process_id(),began]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck():
		driver=INPUT_DRIVER.new();driver.configure(self);RenderingServer.frame_post_draw.connect(_draw)
		complete=await exercise_cpu()
	armed=false
	if driver!=null: driver.release();driver=null
	if RenderingServer.frame_post_draw.is_connected(_draw): RenderingServer.frame_post_draw.disconnect(_draw)
	records.append({"kind":"MARKET_FINITE_OBSERVATION_COUNTS","actual_body_queries":actual_physics_queries,"already_loaded_mask_samples":actual_mask_samples,"Space_calls":0,"room_or_crossdistrict_trips":0,"collector_calls":0,"new_geometry":0})
	finish(output,began,complete,"ONE_MARKET_NEAR_PAWN_REAL24PX_INPUT_NORMAL_CAMERA_1PNG_60s_NO_SPACE_ROOM_COLLECTOR_GEOMETRY")
