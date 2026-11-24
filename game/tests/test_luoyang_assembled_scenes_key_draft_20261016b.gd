extends SceneTree
## NEW thin key, not an extension of the 4300/1673 legacy proof chain.
## ROOT only: two public setups, one assembled-room trip; data not frozen yet.
const SOURCE_READY := false
const INPUT = preload("res://tests/helpers/v15_input_driver.gd")
const RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const ASSEMBLY = preload("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SOURCE_PINS := {
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb"
}
## These fields must come from the final reviewed NEW author, not old room hints.
const PLAN := {
	"market":{"id":"ch4_s3_luoyang_market","size":Vector2(3072,2048),"setup_foot":Vector2(INF,INF),"portal_foot":Vector2(INF,INF),"approach":PackedVector2Array(),"portal_id":"enter_shop_room"},
	"room":{"id":"luoyang_market_shop_interior_20261015","size":Vector2(INF,INF),"front":Vector2(INF,INF),"behind":Vector2(INF,INF),"side":Vector2(INF,INF),"routes":[],"impact_direction":Vector2.ZERO,"impact_target":Vector2(INF,INF),"return_approach":PackedVector2Array()},
	"yamen":{"id":"ch4_s1_luoyang_yamen","size":Vector2(3072,2048),"setup_foot":Vector2(INF,INF),"portal_foot":Vector2(INF,INF),"approach":PackedVector2Array(),"portal_id":"to_south_market"}
}
const SHARED_MS := 120000
const ARRIVAL_MS := 60000
const RETURN_MS := 2000.0
var deadline := 0
var checks := 0
var failures := 0
var output := ""
var driver: RefCounted
var field: Node
var scene: SceneScript
var oracle: RefCounted
var exact_solids: Array[PackedVector2Array]=[]
var source_before: Dictionary={}
var players_before: Dictionary={}
var rows: Array[Dictionary]=[]
var captures: Array[Dictionary]=[]
var sources_observed: Dictionary={}
var initialized := false

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok: failures+=1; printerr("ASSEMBLED_KEY_FAIL ",label," ",detail)
	return ok
func _fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime_seconds":0}
	var file:=FileAccess.open(path,FileAccess.READ)
	var length:=file.get_length(); file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":length,"mtime_seconds":FileAccess.get_modified_time(path)}
func _players() -> Dictionary:
	var result: Dictionary={}
	for index: int in range(5):
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path:="user://save_"+str(index)+suffix
			result[path]=_fact(path)
	return result
func _precheck() -> bool:
	if not _check(SOURCE_READY,"Draft cannot run before actual assets/author/runtime freeze"): return false
	# Final source list will be the exact reviewed dependency closure of this
	# assembly and two exterior data sets. Do not traverse old GPU result chains.
	for path: String in SOURCE_PINS:
		var fact:=_fact(path)
		if not _check(fact.exists and fact.sha256==SOURCE_PINS[path],"Exact assembly input "+path): return false
		source_before[path]=fact
	source_before[get_script().resource_path]=_fact(get_script().resource_path)
	return _check(not ASSEMBLY.author().is_empty() and ASSEMBLY.enabled(),"Final assembled author admits real assets")

func _busy() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var loading: Node=root.get_node("LoadingManager")
	var public_state: Dictionary=router.call("get_public_city_preparation_state")
	var resident: Dictionary=router.call("get_resident_city_state")
	if bool(loading.get("_transition_active")) or public_state.get("active",false) or (resident.get("return",{}) as Dictionary).get("active",false): return true
	var validation: Dictionary=C.transition_validation_state()
	for key: String in ["source_worker_active","base_cpu_worker_active","navigation_worker_active","revision_worker_active","module_worker_active"]:
		if validation.get(key,false): return true
	return C._live_module_task>=0 or C._live_module_job!=null or C._live_revision_task>=0 or C._live_revision_job!=null
func _operable() -> bool:
	if not is_instance_valid(field) or field!=current_scene or _busy(): return false
	var loading: Node=root.get_node("LoadingManager")
	var screen: Node=loading.get("_screen") as Node
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	var player: Node=field.get("_player") as Node
	return (panel==null or not panel.is_visible_in_tree()) and is_instance_valid(player) and player.is_inside_tree() and bool(player.get("can_move")) and not bool(field.get("_scene_rebuilding"))
func _wait(id: String) -> bool:
	var end:=mini(deadline,Time.get_ticks_msec()+ARRIVAL_MS)
	while Time.get_ticks_msec()<end:
		await process_frame
		if _busy() or not is_instance_valid(current_scene): continue
		var definition:=current_scene.get("_current_scene") as SceneScript
		if definition==null or String(definition.scene_id)!=id: continue
		field=current_scene; scene=definition
		if not _operable(): continue
		await driver.call("completed_actor_stage")
		if _operable() and field.get("_current_scene")==scene: return _bind_geometry()
	return _check(false,"Bounded arrival/hidden Loading/operable "+id,{"public":root.get_node("SceneRouter").call("get_public_city_preparation_state"),"C":C.transition_validation_state(),"current_scene":String(current_scene.name) if is_instance_valid(current_scene) else "NONE","errors":C.errors()})

func _bind_geometry() -> bool:
	# Deliberately fail closed until the SYSTEM's NEW exterior/room manifest
	# schema is frozen. The final narrow binder must check that actual scene,
	# layout, props and native Physics correspond to those exact author inputs.
	# This is not a fallback to old source/old proof, and is never a ready pass.
	return _check(false,"PENDING: reviewed new exact source/scene/geometry binder")
func _physical(point: Vector2) -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var world:=field.get("world_container") as Node2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(point)-player.global_position
	query.exclude=[player.get_rid()]; query.collision_mask=player.collision_mask; query.collide_with_areas=false
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func _clear(point: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or oracle==null or not bool(oracle.call("clear",point)): return false
	for y: int in range(roundi(point.y)-12,roundi(point.y)+13):
		for x: int in range(roundi(point.x)-17,roundi(point.x)+18):
			var sample:=Vector2(x,y)
			if not bool((oracle.call("pixel_evidence",sample) as Dictionary).get("clear",false)): return false
			for poly: PackedVector2Array in exact_solids:
				if Geometry2D.is_point_in_polygon(sample,poly): return false
	return _physical(point)
func _segment(a: Vector2,b: Vector2) -> Dictionary:
	var count:=maxi(1,ceili(a.distance_to(b)/4.0))
	for index: int in range(count+1):
		if not _clear(a.lerp(b,float(index)/count)): return {"clear":false,"index":index}
	return {"clear":true,"centers":count+1,"max_world_step_px":a.distance_to(b)/count}
func _way(points: PackedVector2Array,label: String) -> bool:
	var receipt: Dictionary=await driver.call("follow",field,points,_clear,_segment)
	rows.append({"kind":"NORMAL_INPUT","label":label,"receipt":receipt})
	return _check(receipt.get("ok")==true,label,receipt)
func _foot_frame(label: String) -> Dictionary:
	var player:=field.get("_player") as CharacterBody2D
	var sprite:=player.get("sprite") as Sprite2D
	var world:=field.get("world_container") as Node2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var image:=sprite.texture.get_image()
	var cell:=Vector2i(sprite.texture.get_width()/sprite.hframes,sprite.texture.get_height()/sprite.vframes)
	var bounds:=image.get_region(Rect2i(sprite.frame_coords*cell,cell)).get_used_rect()
	var local_y: float=float(bounds.end.y)-.5-(float(cell.y)*.5 if sprite.centered else 0.0)+sprite.offset.y
	var alpha_foot:=world.to_local(sprite.to_global(Vector2(0,local_y)))
	var collider:=world.to_local(shape.global_position)
	var row: Dictionary={"kind":"SAME_FRAME_PLAYER_FEET","label":label,"frame":Engine.get_process_frames(),"animation_frame":sprite.frame,"actor_world":player.position,"collider_world":collider,"nominal_depth_world_y":world.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y")))).y,"alpha_lowest_pixel_center_world":alpha_foot,"alpha_bounds":bounds,"sprite_position":sprite.position,"sprite_scale":sprite.scale,"body_size":(shape.shape as RectangleShape2D).size,"collision_offset":shape.position}
	rows.append(row)
	_check(scene.actor_positions_are_feet and shape.position==Vector2.ZERO and (shape.shape as RectangleShape2D).size==Vector2(34,24) and collider.distance_to(player.position)<.03 and absf(float(row.nominal_depth_world_y)-player.position.y)<.03,"True feet contract; no residual legacy38px mismatch "+label,row)
	return row
func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=output.path_join(label+".png")
	if _check(image.save_png(path)==OK,"Actual new-scene GPU capture "+label): captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"size":image.get_size()})
func _setup(item: Dictionary) -> bool:
	var started:=Time.get_ticks_usec()
	var accepted: bool=bool(root.get_node("SceneRouter").call("go_field_smart",StringName(item.id),item.setup_foot/item.size,"",-1,3))
	var call_ms: float=(Time.get_ticks_usec()-started)/1000.0
	if not _check(accepted,"Public current-v3 near-door setup, not travel") or not await _wait(item.id): return false
	rows.append({"kind":"PUBLIC_SETUP_NOT_TRAVEL","id":item.id,"call_ms":call_ms,"ready_ms":(Time.get_ticks_usec()-started)/1000.0})
	return _clear(item.setup_foot)
func _portal(item: Dictionary) -> bool:
	# Final implementation binds exactly one live zone/target/availability to
	# the frozen NEW authored door. No old coordinates or synthetic activation.
	return _check(false,"PENDING: exact new portal zone/foot/arrow binding "+String(item.portal_id))
func _assembled_trip() -> bool:
	# Final body: real Space -> true-foot spawn -> normal front/behind/side
	# route, four naturally observed alpha frames, native prop depth/fade,
	# actual brief input against the base (not follow's invalid-plan refusal),
	# real Space -> exact remembered city foot, Loading hidden/can_move<2000ms.
	return _check(false,"PENDING: new assets' reviewed three stands/contact/exit path")
func _exercise() -> bool:
	if not await _setup(PLAN.market): return false
	await _capture("new_market_overview")
	if not await _way(PLAN.market.approach,"market_final_short_INPUT") or not _portal(PLAN.market) or not await _assembled_trip(): return false
	if not await _setup(PLAN.yamen): return false
	await _capture("new_yamen_overview")
	if not await _way(PLAN.yamen.approach,"yamen_final_short_INPUT") or not _portal(PLAN.yamen): return false
	return await _way(PackedVector2Array([PLAN.yamen.portal_foot,PLAN.yamen.portal_foot+Vector2(16,0)]),"yamen_final_normal16px")
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+SHARED_MS
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_assembled_scenes_key_20261016b/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Actual normal-clock GPU engine")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		initialized=true
		complete=await _exercise()
	if initialized: root.get_node("SceneRouter").call("reset_for_new_game")
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	if is_instance_valid(field): field=null
	if initialized and is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if initialized: await process_frame; await process_frame
	var source_after: Dictionary={}
	for path: String in source_before: source_after[path]=_fact(path)
	var players_after:=_players()
	_check(source_after==source_before and players_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Exact new closure/15 saves held; no player restoration or source mutation")
	_check(complete and Time.get_ticks_msec()<deadline,"Fixed120s/two-public-setups/one-room scope complete")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"NEW_ASSEMBLY_TWO_EXTERIORS_ONE_ROOM_THIN_KEY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"return_limit_ms":RETURN_MS,"records":rows,"captures":captures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"source_ready":SOURCE_READY,"no_old_inn_cloth_quest_or_all_city_replay":true},"\t")); file.close()
	print("ASSEMBLED_THIN_KEY=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
