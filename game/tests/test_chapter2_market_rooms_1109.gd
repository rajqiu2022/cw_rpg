extends "res://tests/test_inner_courts_modular_1108.gd"

const MARKET := &"ch2_s1_zhuwei_market"
const INN := &"ch2_s1_market_inn"
const DOJO := &"ch2_s1_market_training_hall"
const EDGE := &"ch2_s2_forest_edge"
const AMBUSH := &"ch2_s3_forest_ambush"
const SIZE := Vector2(1920,1280)

func _done() -> void:
	print("CH2_MARKET_ROOMS_RESULT ",_checks,"/",_failed)
	quit(0 if _failed==0 else 1)

func _near_market_door(field: Node, target: StringName) -> bool:
	var zone := _portal(field,target)
	if zone==null: return false
	var world:=field.get("world_container") as Node2D
	var point:=world.to_local(zone.global_position)
	return await _outside_approach(field,target,point)

func _room_contract(field: Node, id: StringName) -> bool:
	var actual := field.get("_current_scene") as SceneScript
	var original := load("res://data/maps/%s_layout_v1.tres"%id) as WalkableMapLayout
	var layout := actual.map_layout
	_expect(actual.background_path.is_empty() and Vector2(field.get("_world_size"))==SIZE,"original logical extent with modular backdrop")
	_expect(layout.resource_path.ends_with("_layout_v2.tres") and layout.visual_objects.size()>=10,"new modular room "+String(id))
	_expect(layout.portals==original.portals and layout.walkable_regions==original.walkable_regions and layout.schema_version==original.schema_version,"original boundaries, door identity and version")
	_expect(_feet(field).distance_to(Vector2(.5,.72)*SIZE)<1.0,"original room entrance feet")
	_expect(field.get("_npc_nodes").size()==3,"all three original characters")
	for probe: Dictionary in original.walkable_probes:
		var sample: Vector2=probe.pos
		if probe.id in ["spar_left","spar_right"]: sample.y+=.06
		_expect(bool(field.call("_spawn_has_foot_clearance",actual,sample)),"reachable "+String(probe.id))
	var open: Vector2=Vector2(.56,.57) if id==INN else Vector2(.50,.68)
	_expect(bool(field.call("_spawn_has_foot_clearance",actual,open)),"room central path")
	var furniture: Vector2=Vector2(.28,.562) if id==INN else Vector2(.187,.553)
	_expect(not bool(field.call("_spawn_has_foot_clearance",actual,furniture)),"solid furniture footing")
	return true

func _innkeeper(field: Node) -> void:
	var keeper: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="zhuwei_innkeeper_ch2": keeper=npc
	if not _expect(keeper!=null,"original innkeeper"): return
	var actual := field.get("_current_scene") as SceneScript
	var uv:=Vector2(.220,.524)
	_expect(bool(field.call("_spawn_has_foot_clearance",actual,uv)),"innkeeper side approach is physically clear")
	await _place(field,uv)
	_expect(keeper.try_interact(),"innkeeper in interaction range")
	var dialog:=root.get_node("DialogPlayer")
	for i in range(45):
		if dialog.call("is_playing"):break
		await process_frame
	var active:=dialog.get("_current_script") as DialogScript
	_expect(active!=null and active.dialog_id==&"ch2_missing_disciple_offer","original missing-disciple dialogue opens")
	if active!=null:
		dialog.call("_end_dialog")
		await process_frame
		await process_frame

func _forest_contract(field: Node,id: StringName,uv: Vector2) -> void:
	var scene:=field.get("_current_scene") as SceneScript
	var original:=load("res://data/maps/%s_layout_v1.tres"%id) as WalkableMapLayout
	_expect(scene.scene_id==id and scene.background_path.is_empty() and scene.map_layout.visual_objects.size()>=20 and Vector2(field.get("_world_size"))==SIZE,"new outdoor layout "+String(id))
	_expect(scene.map_layout.walkable_regions==original.walkable_regions and scene.map_layout.schema_version==original.schema_version,"original walkable envelope "+String(id))
	_expect(_feet(field).distance_to(uv*SIZE)<1.0,"original outbound foot "+String(id)+": "+str(_feet(field)))
	for sample: Dictionary in original.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance",scene,sample.pos)),"original open route "+String(sample.id))
	for sample: Dictionary in original.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance",scene,sample.pos)),"original blocked edge "+String(sample.id))

func _take_field_door(field: Node,id: StringName,uv: Vector2) -> Node:
	var gate:=_portal(field,id)
	if id==AMBUSH and is_instance_valid(gate):
		await _place(field,Vector2(.607,uv.y))
		var move:=InputEventKey.new()
		move.keycode=KEY_D
		move.physical_keycode=KEY_D
		move.pressed=true
		Input.parse_input_event(move)
		for i in range(66):
			await physics_frame
			if bool(gate.get("_in_range")):break
		move=move.duplicate()
		move.pressed=false
		Input.parse_input_event(move)
		await process_frame
	else:await _place(field,uv)
	gate=_portal(field,id)
	var diagnostics: Array=[]
	for zone: ExitZone in field.get("_exit_nodes"):
		diagnostics.append([zone.destination_name,zone.target_scene_id,zone.is_locked,zone.get("_in_range"),zone.position])
	if not _expect(is_instance_valid(gate) and not gate.is_locked and bool(gate.get("_in_range")),"actual exit to "+String(id)+" foot="+str(_feet(field))+" doors="+str(diagnostics)):return null
	print("CH2_FOREST_INPUT Space ",id)
	await _press_space()
	return await _ready_field(id)

func _locked_destination(field: Node,label: String) -> bool:
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.destination_name==label and zone.is_locked and zone.target_scene_id.is_empty():return true
	return false

func _forest(outside: Node) -> void:
	if not _expect(await _near_market_door(outside,EDGE),"original north path"):return
	print("CH2_FOREST_INPUT Space ",EDGE)
	await _press_space()
	var edge: Node=await _ready_field(EDGE)
	if edge==null:return
	_forest_contract(edge,EDGE,Vector2(.12,.72))
	var scene:=edge.get("_current_scene") as SceneScript
	_expect(scene.encounter_groups.size()==2 and is_equal_approx(scene.encounter_chance,.16),"unchanged forest encounters")
	_expect(_locked_destination(edge,"追踪林中血迹"),"ambush locked before hunter testimony")
	var hunter: NPCNode
	for npc: NPCNode in edge.get("_npc_nodes"):
		if npc.npc_id=="old_hunter_forest_edge":hunter=npc
	var hunter_uv:=Vector2(.442,.627)
	_expect(bool(edge.call("_spawn_has_foot_clearance",scene,hunter_uv)),"hunter approach clear")
	await _place(edge,hunter_uv)
	await _capture(edge,"north_forest")
	if not _expect(hunter!=null and hunter.try_interact(),"actual hunter interaction"):return
	var dialog:=root.get_node("DialogPlayer")
	for i in range(30):
		if dialog.call("is_playing"):break
		await process_frame
	var active:=dialog.get("_current_script") as DialogScript
	_expect(active!=null and active.dialog_id==&"ch2_forest_route","original trail testimony opens")
	for i in range(8):
		if not dialog.call("is_playing"):break
		dialog.call("advance")
		await process_frame
	_expect(bool(root.get_node("GameState").get("flags").get("forest_route_open",false)),"actual dialogue unlocks ambush")
	var deadline:=Time.get_ticks_msec()+12000
	while Time.get_ticks_msec()<deadline:
		edge=current_scene
		if is_instance_valid(edge) and not bool(edge.get("_scene_rebuilding")) and _portal(edge,AMBUSH)!=null:break
		await process_frame
	var ambush: Node=await _take_field_door(edge,AMBUSH,Vector2(.70,.46))
	if ambush==null:return
	_forest_contract(ambush,AMBUSH,Vector2(.12,.75))
	for point: Vector2 in [Vector2(.58,.44),Vector2(.52,.65),Vector2(.78,.32)]:
		_expect(bool(ambush.call("_spawn_has_foot_clearance",ambush.get("_current_scene"),point)),"original fight or quest point approachable "+str(point))
	await _place(ambush,Vector2(.55,.57))
	await _capture(ambush,"forest_ambush")
	edge=await _take_field_door(ambush,EDGE,Vector2(.10,.82))
	if edge==null:return
	_expect(_feet(edge).distance_to(Vector2(.70,.46)*SIZE)<1.0,"ambush reverse north trail anchor")
	outside=await _take_field_door(edge,MARKET,Vector2(.10,.82))
	if outside!=null:_expect(_feet(outside).distance_to(Vector2(3180,430))<1.0,"forest returns to market's north path")

func _run() -> void:
	if not _expect(_paused_checkpoints,"private saves"): _done(); return
	_router=root.get_node("SceneRouter")
	var flags: Dictionary=root.get_node("GameState").get("flags")
	flags["chapter1_complete"]=true
	flags["seen_ch2_zhuwei_intro"]=true
	flags["heard_about_missing_lingyue"]=true
	if not _expect(bool(_router.call("go_field_smart",MARKET,null,"",-1,1)),"formal morning market"): _done(); return
	var outside: Node=await _ready_field(MARKET)
	if outside==null: _done(); return
	for id: StringName in [INN,DOJO]:
		if not _expect(await _near_market_door(outside,id),"real market door "+String(id)): _done(); return
		print("CH2_MARKET_ROOMS_INPUT Space ",id)
		await _press_space()
		var field: Node=await _ready_field(id)
		if field==null: _done(); return
		_room_contract(field,id)
		await _capture(field,String(id))
		if id==INN: await _innkeeper(field)
		else:
			for row: Dictionary in (field.get("_current_scene") as SceneScript).npcs:
				_expect(String(row.get("interaction_action","")).begins_with("spar:"),"original spar action "+String(row.npc_id))
		field=await _ready_field(id)
		if field==null: _done();return
		outside=await _take_field_door(field,MARKET,Vector2(.5,.82 if id==INN else .83))
		if outside==null: _done(); return
		var target := Vector2(950,1838) if id==INN else Vector2(3143.501838235294,1698)
		_expect(_feet(outside).distance_to(target)<1.0,"exact morning market return "+String(id)+": "+str(_feet(outside)))
	await _forest(outside)
	_done()
