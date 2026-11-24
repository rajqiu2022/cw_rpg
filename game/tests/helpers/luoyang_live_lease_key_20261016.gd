extends "res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd"
## Thin lifecycle utility only; never calls inherited district _run/precheck/exercise.
const LEASE=preload("res://scripts/city/luoyang_resident_field_20261016.gd")
const WORLD_RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const ROOM_RAW=preload("res://tests/helpers/v15_field_raw_oracle.gd")
const NEW_PINS={
	"res://scripts/autoload/scene_router.gd":"1082a842eb283a7eba339f9589bbcb0a5803d934c79f60d9e7a7f0413069bd92",
	"res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db",
	"res://scripts/city/luoyang_resident_field_20261016.gd":"20086323c7aca3bb3efe51b77cdad393ec5e4ccdacdf98856eaca4beccd22624",
	"res://scripts/field/field_walkable_controller.gd":"50b35b21520b2d10d24e2582b4de4440178252df9f29f79e013146ac3c8e62c2"}
const BASELINE="res://build/luoyang_city_life_gpu_20261016f/gate/98036_2491/result.json"
const BASELINE_SHA="8db8a945f41f2d7233f45ca381331cbafd42353575d4e72e403b8b7dce5e5e88"
const WORLD_ID="world_map_jianghu"
var world_oracle: RefCounted
var room_oracle: RefCounted
var retained_field: Node
var retained_static: Dictionary={}
var retained_navigation: Dictionary={}
var observed_jobs:=0

func precheck() -> bool:
	if not check(LEASE.LIVE_WORLD_FLAG in OS.get_cmdline_user_args() and not LEASE.LIVE_WORLD_FORMAL_ENABLED,"Exact live-lease candidate only; old city formal stays enabled"): return false
	if not track(BASELINE,BASELINE_SHA): return false
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	if not check(prior.complete and prior.failures==0,"Exact ordinary original district evidence"): return false
	for path: String in prior.source_before:
		if not track(path,String(NEW_PINS.get(path,prior.source_before[path].sha256))): return false
	for path: String in NEW_PINS:
		if not track(path,NEW_PINS[path]): return false
	if not track("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1"): return false
	package=R.binding(); author=R.author(package)
	if not check(R.FORMAL_ENABLED and R.cpu_proof_valid(package,author),"Original full combined geometry/import publication unchanged"): return false
	for path: String in [get_script().resource_path,"res://tests/helpers/luoyang_live_lease_key_20261016.gd","res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd","res://tests/helpers/v15_raw_world_oracle.gd","res://tests/helpers/v15_field_raw_oracle.gd"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true

func _hidden() -> bool:
	var manager: Node=root.get_node("LoadingManager")
	var screen: Node=manager.get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	return not bool(manager.get("_transition_active")) and not bool(manager.get("_external_active")) and (panel==null or not panel.is_visible_in_tree())

func _wait_target(id: String) -> bool:
	var end: int=mini(deadline,Time.get_ticks_msec()+60000)
	while Time.get_ticks_msec()<end:
		await process_frame
		var cs: Dictionary=C.transition_validation_state()
		if cs.get("source_worker_active",false) or cs.get("base_cpu_worker_active",false) or cs.get("navigation_worker_active",false): observed_jobs+=1
		var live: Node=current_scene
		if not is_instance_valid(live) or not live.has_method("get_field_loading_state"): continue
		var state: Dictionary=live.call("get_field_loading_state")
		var current: SceneScript=live.get("_current_scene") as SceneScript
		if current==null or String(current.scene_id)!=id: continue
		if state.get("failed",false): return check(false,"Actual Field readiness failed",state)
		var player: CharacterBody2D=live.get("_player") as CharacterBody2D
		if state.get("complete")!=true or player==null or not player.is_inside_tree() or not bool(player.get("can_move")) or not _hidden(): continue
		field=live; scene=current
		if C.owns_id(current.scene_id):
			var proof: Dictionary=C.resident_receipt(current)
			if not check(proof.get("sources_finalized",false) and not proof.get("sources",{}).is_empty(),"Actual finalized cold-origin proof still bound to live exterior"): return false
			records.append({"kind":"READY_SOURCE","id":id,"source_count":proof.sources.size(),"sources":proof.sources,"cold_origin_not_fresh_warm_sha":true})
		return true
	return check(false,"Fixed60s arrival or fixed whole deadline",{"id":id,"C":C.transition_validation_state(),"errors":C.errors(),"resident":root.get_node("SceneRouter").call("get_resident_city_state")})

func _bind_world() -> bool:
	world_oracle=WORLD_RAW.new()
	var shape: CollisionShape2D=(field.get("_player") as Node).get_node("CollisionShape2D")
	return check(scene.resource_path=="res://data/scenes/world_map_jianghu.tres" and shape.shape is CircleShape2D and (shape.shape as CircleShape2D).radius==5.0 and shape.position==Vector2.ZERO and world_oracle.configure(scene.map_layout),"Independent original world17 navigation/native travel radius5 unchanged",world_oracle.get("errors"))

func _bind_room() -> bool:
	var shape: CollisionShape2D=(field.get("_player") as Node).get_node("CollisionShape2D")
	var actual: Vector2=field.get("_world_size")
	if not check(not scene.actor_positions_are_feet and shape.position==Vector2(0,42) and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==Vector2(34,24) and actual==Vector2(1920,1280),"Original inn actual cover/legacy42/native34x24 not scaled"): return false
	var clone: Resource=scene.map_layout.duplicate(true)
	clone.set("design_size",Vector2i(actual))
	room_oracle=ROOM_RAW.new()
	return check(room_oracle.configure(clone),"Independent actual-cover inn source",room_oracle.errors)

func _bind_city(id: String) -> bool:
	district="gate" if id=="ch4_s0_luoyang_gate" else "market"
	scene_id=id
	return _bind_actual()

func _ground(origin: Vector2) -> bool:
	if String(scene.scene_id) in DISTRICTS.values(): return oracle.clear(origin)
	if String(scene.scene_id)==WORLD_ID: return world_oracle!=null and world_oracle.clear(origin)
	var raw: RefCounted=room_oracle
	if raw==null: return false
	var offset: float=float((field.get("_player") as Node).call("_visual_foot_offset"))
	var foot: Vector2=origin+Vector2(0,offset)
	if not raw.clear(foot): return false
	var body_rect:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	var body:=PackedVector2Array([body_rect.position,Vector2(body_rect.end.x,body_rect.position.y),body_rect.end,Vector2(body_rect.position.x,body_rect.end.y)])
	var contained:=false
	for region: PackedVector2Array in raw.get("regions"):
		var actual_region:=PackedVector2Array()
		for point: Vector2 in region: actual_region.append(point*Vector2(raw.get("size")))
		if Geometry2D.clip_polygons(body,actual_region).is_empty(): contained=true;break
	if not contained: return false
	for solid: Dictionary in raw.get("solids"):
		if solid.get("kind")=="exact_world_polygon":
			if not Geometry2D.intersect_polygons(body,solid.polygon).is_empty(): return false
		elif body_rect.intersects(solid.rect,true): return false
	var rounded: Vector2=foot.round()
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var point: Vector2=rounded+Vector2(x,y)
			if not raw.pixel_evidence(point).get("clear",false): return false
			var source_solids: Array=raw.get("solids")
			for solid: Dictionary in source_solids:
				var exact: bool=solid.get("shape",solid.get("kind",""))=="exact_world_polygon"
				if exact and Geometry2D.is_point_in_polygon(point,solid.polygon): return false
				if not exact:
					var rect: Rect2=solid.get("grown",solid.get("rect",Rect2()))
					if rect.has_point(point): return false
	return true

func _clear(origin: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not is_instance_valid(field) or current_scene!=field or not _ground(origin): return false
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node("CollisionShape2D")
	var world: Node2D=field.get("world_container")
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(origin)-player.global_position
	query.exclude=[player.get_rid()]; query.collision_mask=1; query.collide_with_areas=false
	native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _segment(a: Vector2,b: Vector2) -> Dictionary:
	if String(scene.scene_id) in DISTRICTS.values(): return oracle.path([a,b],false,deadline)
	if String(scene.scene_id)==WORLD_ID: return world_oracle.segment_evidence(a,b)
	var count: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for i: int in range(count+1):
		if not _ground(a.lerp(b,float(i)/count)): return {"clear":false,"index":i}
	return {"clear":true,"samples":count+1,"max_step_px":a.distance_to(b)/count}

func _zone(target: String,action: String="") -> bool:
	var matches: Array=[]
	for zone: Node in field.get("_exit_nodes"):
		if (not target.is_empty() and String(zone.get("target_scene_id"))==target) or (not action.is_empty() and String(zone.get("action"))==action): matches.append(zone)
	return check(matches.size()==1 and bool(matches[0].get("_in_range")) and not bool(matches[0].get("is_locked")),"Actual unique unlocked original portal overlap",{"target":target,"action":action})

func _space(id: String,label: String,warm: bool=false) -> bool:
	var began: int=Time.get_ticks_usec()
	var jobs_before: int=observed_jobs
	await driver.key(KEY_SPACE)
	if not await _wait_target(id): return false
	var elapsed: int=Time.get_ticks_usec()-began
	var lease: Dictionary=root.get_node("SceneRouter").call("get_resident_city_state")
	records.append({"kind":"REAL_SPACE_READY","label":label,"target":id,"until_Loading_hidden_canmove_final_live_identity_usec":elapsed,"warm":warm,"source_jobs_observations":observed_jobs-jobs_before,"lease":lease})
	if warm:
		var returned: Dictionary=lease.get("return",{})
		return check(elapsed<2000000 and returned.get("hit")==true and returned.get("final_live_identity")==true and returned.get("source_fresh_sha")==false and returned.get("source_basis")=="SAME_LIVE_OBJECTS_AND_EDITOR_METADATA" and observed_jobs==jobs_before,"Strict warm <2s to hidden+operable; live identity not fresh disk SHA",returned)
	return true

func _retain() -> bool:
	retained_field=field; retained_static=field.call("resident_static_identity")
	retained_navigation={"record":C._records.get(scene_id,{}).duplicate(true),"solids":C._solids.get(scene_id,[]).duplicate(true),"mask":C._masks.get(scene_id),"using":C._using_patch.get(scene_id),"id":scene_id}
	return check(not retained_static.is_empty() and _clear((field.get("_player") as Node2D).position),"Trusted current exterior native snapshot")

func _same_retained() -> bool:
	var id: String=retained_navigation.id
	return check(field==retained_field and field.call("resident_static_identity")==retained_static and C._masks.get(id)==retained_navigation.mask and C._equal_value(C._records.get(id),retained_navigation.record) and C._equal_value(C._solids.get(id),retained_navigation.solids) and C._using_patch.get(id)==retained_navigation.using,"Exact original live Field/static props/textures/native bodies/mask/nav retained")

func _lease_run(kind: String,budget: int) -> void:
	var began: int=Time.get_ticks_msec(); deadline=began+budget
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players_before=saves()
	folder="res://build/luoyang_live_city_lease_20261016g/"+kind+"/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new(); driver.configure(self)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame; await process_frame
	field=null;scene=null;oracle=null;world_oracle=null;room_oracle=null;retained_field=null;retained_static.clear();retained_navigation.clear()
	records.append({"kind":"SCOPE","name":kind,"shared_ms":budget,"arrival_ms":60000,"warm_limit_usec":2000000,"captures":captures,"native_queries":native_queries,"warm_fresh_disk_sha_claimed":false,"world_long_walk_claimed":false})
	finish(folder,began,complete,kind)
