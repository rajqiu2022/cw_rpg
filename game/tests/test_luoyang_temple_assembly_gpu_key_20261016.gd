extends "res://tests/test_luoyang_temple_assembly_cpu_key_20261016.gd"
## One temple only. CPU223 covers full13 routes/data; this owns actual7 stations/2 exits.
const INPUT=preload("res://tests/helpers/v15_input_driver.gd")
const CPU_RESULT="res://build/luoyang_temple_assembly_cpu_20261016/23196_1614/result.json"
const CPU_SHA="e3e3acab429bb87929c0cb830bc3c1c67738545b2520371939ee18cedbae620f"
const BASE_SHA="43f22bbe62052f9b89ceb6b9b2af258e044b6d898393a7c1d8b5aae85fe5511a"
const LIMIT_MS=90000
const ARRIVAL_MS=45000
var field: Node
var driver: RefCounted
var captures: Array[Dictionary]=[]
var output: String
var native_queries:=0
func actual_clear(foot: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not geometry.clear(foot): return false
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var world:=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.exclude=[player.get_rid()]; query.collision_mask=1; query.collide_with_areas=false
	native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func segment(a: Vector2,b: Vector2) -> Dictionary:
	# Reuse CPU independent continuous/round875/17 geometry, not production clearance.
	return geometry.segment(a,b)
func wait_arrival() -> bool:
	var until:=mini(deadline,Time.get_ticks_msec()+ARRIVAL_MS)
	while Time.get_ticks_msec()<until:
		await process_frame
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_temple_assembly_state"): continue
		var state: Dictionary=current_scene.call("get_temple_assembly_state")
		if not String(state.get("error","")).is_empty(): return check(false,"Temple setup refused",state)
		var player:=current_scene.get("_player") as CharacterBody2D
		if player==null or not player.is_inside_tree() or not bool(player.get("can_move")) or not state.get("finalized",false): continue
		var definition:=current_scene.get("_current_scene") as SceneScript
		if not A.is_scene(definition): continue
		var screen: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
		if panel!=null and panel.is_visible_in_tree(): continue
		field=current_scene; child=definition
		if not check(Vector2(field.get("_world_size"))==WORLD and child.actor_positions_are_feet,"Actual1920x1280/sourcefeet cover, no legacy42"): return false
		if not check(state.source_first==state.source_final and state.source_count>0 and not state.worker_active and state.scope=="TEMPLE_OWN_FIELD_NOT_C_CITY_RECEIPT","Actual temple owner first/final, not C receipt",state): return false
		for path: String in state.source_first:
			if not check(before.has(path) and before[path].sha256==state.source_first[path],"Actual owner source matches pre-entry "+path): return false
		rows.append({"kind":"ACTUAL_FIELD_SOURCE_OWNER","state":state})
		return check(actual_clear(player.position),"Actual birth continuous34x24/round875/17 and nativePhysics")
	return check(false,"Fixed45s actual finalized ready deadline")
func walk(points: Array) -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var path:=PackedVector2Array([player.position])
	for point: Array in points: path.append(Vector2(point[0],point[1])*1.25)
	var result: Dictionary=await driver.follow(field,path,actual_clear,segment)
	rows.append({"kind":"NORMAL_INPUT_COMPLETE_PATH","result":result})
	return check(result.ok,"Normal INPUT path all observed feet fullgeometry/nativePhysics",result)
func capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var path:=output.path_join(label+".png")
	var image:=root.get_texture().get_image()
	if not check(image!=null and image.save_png(path)==OK,"Actual GPU capture "+label): return false
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"label":label})
	return true
func foot_frame() -> Dictionary:
	var player:=field.get("_player") as CharacterBody2D
	var sprite:=player.get("sprite") as Sprite2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var world:=field.get("world_container") as Node2D
	var image:=sprite.texture.get_image()
	if image.is_compressed() and image.decompress()!=OK: return {"ok":false}
	var cell:=Vector2i(image.get_width()/sprite.hframes,image.get_height()/sprite.vframes)
	var frame:=image.get_region(Rect2i(sprite.frame_coords*cell,cell))
	var used:=frame.get_used_rect()
	if not check(not sprite.region_enabled and used.has_area(),"Actual frame bounds, no atlas-region substitution"): return {"ok":false}
	var last:=used.end.y-1
	var local:=sprite.get_rect().position+Vector2(float(used.position.x)+.5,float(last)+.5)
	var visible:=world.to_local(sprite.to_global(local))
	var center:=world.to_local(shape.global_position)
	var depth: float=player.call("get_depth_sort_y")
	var ok: bool=(shape.shape as RectangleShape2D).size==Vector2(34,24) and shape.position==Vector2.ZERO and center.distance_to(player.position)<.03 and absf(depth-player.global_position.y)<.03 and absf(visible.y-player.position.y)<=12.0
	return {"ok":ok,"frame":sprite.frame,"texture_id":sprite.texture.get_instance_id(),"alpha_delta_y":visible.y-player.position.y,"foot":player.position,"collider_center":center,"depth":depth,"native_size":(shape.shape as RectangleShape2D).size}
func ghost_frame(id: String,expected: bool) -> Dictionary:
	var player:=field.get("_player") as CharacterBody2D
	var sprite:=player.get("sprite") as Sprite2D
	var ghost:=player.get("_overlap_ghost") as Sprite2D
	var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
	var result: Dictionary={"expected":expected,"visible":ghost.visible,"logical_pixels":debug.get("pixels",0),"prop_hits":debug.get("prop_hits",{})}
	var base_ok: bool=sprite.modulate.a==1.0 and sprite.self_modulate.a==1.0 and ghost.get_parent()==player and not ghost.is_in_group("player") and not ghost.is_in_group("npc")
	if not expected:
		result.ok=base_ok and not ghost.visible and not debug.get("active",false); return result
	var texture:=debug.get("mask_texture") as Texture2D
	var cpu:=debug.get("mask_image") as Image
	var material:=ghost.material as ShaderMaterial
	if texture==null or cpu==null or material==null: result.ok=false; return result
	var actual:=texture.get_image()
	var visible_pixels:=0
	var data:=actual.get_data()
	for i: int in range(3,data.size(),4):
		if data[i]>0: visible_pixels+=1
	result.mask_nonzero=visible_pixels
	result.mask_bytes_exact=actual.get_size()==cpu.get_size() and actual.get_format()==cpu.get_format() and data==cpu.get_data()
	result.ok=base_ok and ghost.visible and debug.get("active",false) and debug.get("pixels",0)>0 and debug.get("prop_hits",{}).get(id,0)>0 and visible_pixels>0 and result.mask_bytes_exact and material.get_shader_parameter("frame_mask")==texture and absf(float(material.get_shader_parameter("ghost_alpha"))-.46)<.000001 and ghost.texture==sprite.texture and ghost.frame==sprite.frame and ghost.hframes==sprite.hframes and ghost.vframes==sprite.vframes and ghost.position==sprite.position and ghost.scale==sprite.scale and ghost.flip_h==sprite.flip_h and ghost.flip_v==sprite.flip_v
	return result
func station(index: int) -> bool:
	var spec: Dictionary=author.validation_stations[index]
	await create_timer(.35).timeout
	var player:=field.get("_player") as CharacterBody2D
	var prop: Sprite2D
	for object: Node in field.get("_scene_object_nodes"):
		if String(object.name)=="SceneObject_"+String(spec.prop_id): prop=object as Sprite2D
	if not check(prop!=null and player.position.distance_to(Vector2(spec.foot_px[0],spec.foot_px[1])*1.25)<=.3 and actual_clear(player.position),"Exact authored station and nativebody "+String(spec.id)): return false
	var fade: Dictionary=field.call("get_city_building_fade_debug")
	if not check(fade.get("scope")=="EXACT_TEMPLE_COMPONENTS_NOT_CITY" and "temple_low_altar" not in fade.get("fade_ids",[]),"Only explicit tall props eligible, original alpha tails unchanged"): return false
	var frames: Dictionary={}
	var until:=mini(deadline,Time.get_ticks_msec()+3500)
	var needed:=4 if index<4 else 1
	while frames.size()<needed and Time.get_ticks_msec()<until:
		await driver.completed_actor_stage()
		await RenderingServer.frame_post_draw
		var foot:=foot_frame()
		if not check(foot.get("ok",false) and absf(prop.self_modulate.a-float(spec.expected_prop_alpha))<.01,"Actual same-frame alphafoot<=12/native34x24/propalpha "+String(spec.id),foot): return false
		var ghost: Dictionary={}
		if spec.has("expected_ghost"):
			ghost=ghost_frame(spec.prop_id,spec.expected_ghost)
			if not check(ghost.get("ok",false),"Current actor-only mask/ghost exact "+String(spec.id),ghost): return false
		var prop_before: bool=prop.z_index<player.z_index or (prop.z_index==player.z_index and prop.get_parent()==player.get_parent() and prop.get_index()<player.get_index())
		if index<4 and not check(prop_before==(index!=1),"Actual native prop-before-actor front/tie; behind prop after actor"): return false
		frames[str(foot.texture_id)+":"+str(foot.frame)]={"foot":foot,"ghost":ghost,"prop_alpha":prop.self_modulate.a,"prop_before_actor":prop_before}
	rows.append({"kind":"ACTUAL_STATION","id":spec.id,"natural_frames":frames})
	return check(frames.size()==needed,"Four naturally animated low station frames / one tall station frame") and await capture(spec.id)
func exit_ready(target: String,source_point: Array) -> bool:
	if not await walk([source_point]): return false
	await driver.completed_actor_stage()
	var player:=field.get("_player") as CharacterBody2D
	var layer:=field.get("_portal_layer") as Node
	for zone: Node in layer.get_children():
		if String(zone.get("target_scene_id"))!=target: continue
		var area:=zone as Area2D
		var predicate: bool=not bool(zone.get("is_locked")) and not bool(zone.get("auto_trigger")) and bool(zone.get("_in_range")) and area.get_overlapping_bodies().has(player)
		rows.append({"kind":"NATIVE_EXIT_ENTER_PREDICATE","target":target,"position":zone.position,"ready":predicate,"api":"ExitZone lacks can_enter; real Area overlap + in_range + unlocked, no activation"})
		return check(predicate and zone.position==Vector2(source_point[0],source_point[1])*1.25 and actual_clear(player.position),"Original exact exit available; no heavy city trip")
	return check(false,"Original exit missing "+target)
func exercise_gpu() -> bool:
	var start:=Time.get_ticks_msec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",A.ID,null,"",-1,-1)
	rows.append({"kind":"PUBLIC_ENTRY","accepted":accepted,"call_ms":Time.get_ticks_msec()-start})
	if not check(accepted,"Actual normal public temple route") or not await wait_arrival(): return false
	if not await walk([[768,700]]) or not await station(0): return false
	if not await walk([[900,700],[900,606],[768,606]]) or not await station(1): return false
	if not await walk([[900,606],[900,650]]) or not await station(2): return false
	if not await walk([[900,700],[768,700]]) or not await station(3): return false
	if not await walk([[900,700],[900,540],[768,540]]) or not await station(4): return false
	if not await walk([[1160,540],[1160,430],[768,430]]) or not await station(5): return false
	if not await walk([[768,400],[1210,400],[1250,350]]) or not await station(6): return false
	if not await walk([[1160,350],[1160,860],[337.92,860]]) or not await exit_ready("ch4_s2_canal_docks",[337.92,819.2]): return false
	if not await walk([[337.92,860],[153.6,860]]) or not await exit_ready("ch4_s3_luoyang_market",[153.6,819.2]): return false
	return check(is_instance_valid(field) and current_scene==field,"One real temple, no portal signal simulation")
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+LIMIT_MS
	output="res://build/luoyang_temple_assembly_gpu_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players=saves()
	var complete:=false
	if precheck() and track("res://tests/test_luoyang_temple_assembly_cpu_key_20261016.gd",BASE_SHA) and track(CPU_RESULT,CPU_SHA) and track("res://tests/helpers/v15_input_driver.gd","a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"):
		var cpu: Variant=JSON.parse_string(FileAccess.get_file_as_string(CPU_RESULT))
		if check(cpu is Dictionary and cpu.complete and cpu.failures==0,"Actual independent CPU223 success bound, no duplicated full1955 path pass"):
			driver=INPUT.new(); driver.configure(self)
			for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
			complete=await exercise_gpu()
			root.get_node("SceneRouter").call("reset_for_new_game")
			await process_frame; await process_frame
	if driver!=null: driver.release(); driver=null
	field=null; child=null; geometry=null
	rows.append({"kind":"GPU_SCOPE","shared_ms":LIMIT_MS,"arrival_ms":ARRIVAL_MS,"captures":captures,"native_queries":native_queries,"scope":"ONE_TEMPLE_7STATIONS_2EXIT_AVAILABILITY_NO_CITY_TRIP_NO_REWARD"})
	finish("luoyang_temple_assembly_gpu_20261016",began,complete)
