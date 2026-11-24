extends SceneTree

var failures := 0
var checks := 0
var suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_suspend)
	for node in root.get_children():_suspend(node)
	_run.call_deferred()

func _suspend(node: Node) -> void:
	if node.name==&"PlatformBridge":
		node.call("set_checkpoint_saves_suspended",true)
		suspended=bool(node.call("is_checkpoint_saves_suspended"))

func _check(ok: bool, label: String) -> bool:
	checks+=1
	if not ok:
		failures+=1
		printerr("QINGFENG_INN_FAIL ",label)
	return ok

func _wait_for(id: String) -> Node:
	var until:=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<until:
		await process_frame
		if current_scene==null or not current_scene.has_method("get_field_loading_state"):continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("complete")==true and state.get("scene_id")==id and not bool(root.get_node("LoadingManager").get("_transition_active")):
			return current_scene
	_check(false,"wait for "+id)
	return null

func _door(field: Node,target: String) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.target_scene_id==target:return zone
	return null

func _key(code: int, down: bool) -> void:
	var e:=InputEventKey.new()
	e.keycode=code
	e.physical_keycode=code
	e.pressed=down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _walk(code: int,ticks: int) -> void:
	_key(code,true)
	for i in range(ticks):await physics_frame
	_key(code,false)
	await physics_frame
	await process_frame

func _finish() -> void:
	print("QINGFENG_INN_RESULT ",checks," / ",failures)
	quit(0 if failures==0 else 1)

func _run() -> void:
	if not _check(suspended,"checkpoint suspension"):
		_finish();return
	var router:=root.get_node("SceneRouter")
	root.get_node("GameState").get("flags")["entered_zhuwei_village"]=true
	if not _check(router.call("go_field_smart",&"ch1_s2_qingfeng",null,"",-1,-1)==true,"formal village entry"):
		_finish();return
	var outside:=await _wait_for("ch1_s2_qingfeng")
	if outside==null:
		_finish();return
	var entry:=_door(outside,"interior_inn_hall")
	if not _check(entry!=null and not entry.is_locked,"original inn entrance visible"):
		_finish();return
	# Only position setup is synthetic. Both scene changes are real Space input.
	var outside_actor: Player=outside.get("_player")
	outside_actor.global_position=entry.global_position+Vector2(0,24)
	var native: Node=outside.get("native_town")
	native.terrain.reset_actor(entry.get_meta("sect_floor"))
	await create_timer(.2).timeout
	print("QINGFENG_INN_DOOR ",entry.global_position," actor ",outside_actor.global_position," range ",entry.get("_in_range")," floor ",[entry.get_meta("sect_floor"),native.terrain.actor_level])
	if not _check(bool(entry.get("_in_range")),"village door foot in range"):
		_finish();return
	await _walk(KEY_SPACE,3)
	print("QINGFENG_INN_AFTER_SPACE ",router.call("get_current_field_id")," dialog ",root.get_node("DialogPlayer").call("is_playing"))
	var room:=await _wait_for("interior_inn_hall")
	if room==null:
		_finish();return
	var actor: Player=room.get("_player")
	var scene: SceneScript=room.get("_current_scene")
	var world: Node2D=room.get("world_container")
	_check(scene.map_layout.resource_path.ends_with("qingfeng_inn_20261108_runtime01/inn_layout.tres"),"runtime versioned inn layout")
	_check(actor.can_move and world.to_local(actor.global_position).distance_to(Vector2(768,604.16))<1.5,"original safe arrival")
	_check(room.get("_npc_nodes").size()==4 and scene.npcs.size()==4,"original four NPCs")
	var names: Array[String]=[]
	for prop: Sprite2D in room.get("_scene_object_nodes"):names.append(String(prop.name))
	for id in ["shell_main","shell_front_left","shell_front_right","shell_door_floor","service_counter","tea_wine_shelf","left_table","right_table","left_guest_bench","right_guest_bench"]:
		_check("SceneObject_"+id in names,"real prop "+id)
	_check(scene.map_layout.interactions[0].id=="inn_guest_register" and scene.map_layout.interactions[0].action=="dialog:interior_inn_guest_register","guest register identity and dialogue kept")
	for row: Dictionary in scene.map_layout.walkable_probes:
		_check(room.call("_spawn_has_foot_clearance",scene,row.pos)==true,"full clearance "+String(row.id))
	for row: Dictionary in scene.map_layout.blocked_probes:
		_check(room.call("_is_normalized_spawn_walkable",scene,row.pos)==false,"furniture block "+String(row.id))
	await RenderingServer.frame_post_draw
	var screenshot:=root.get_texture().get_image()
	_check(screenshot.save_png("user://qingfeng_inn_normal.png")==OK,"normal camera screenshot")
	var exit:=_door(room,"ch1_s2_qingfeng")
	if not _check(exit!=null and world.to_local(exit.global_position).distance_to(Vector2(768,814.08))<1.5,"original return doorway"):
		_finish();return
	await _walk(KEY_S,68)
	_check(world.to_local(actor.global_position).y>770.0 and bool(exit.get("_in_range")),"walk down central aisle into real exit range")
	await _walk(KEY_SPACE,3)
	outside=await _wait_for("ch1_s2_qingfeng")
	if outside!=null:
		_check((outside.get("_player") as Player).global_position.distance_to(Vector2(950,1838))<1.5,"returned to original village inn steps")
	_finish()
