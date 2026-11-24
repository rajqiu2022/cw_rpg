extends "res://tests/test_chapter6_modular_maps_1109.gd"

const FERRY := &"ch7_s1_lieyun_valley_ferry"
const TEA_TOWN := &"ch7_s2_mingwu_tea_town"
const LIEYUN_OUTER := &"ch7_s3_lieyun_outpost_outer_ward"
const MINGWU_OUTER := &"ch7_s4_mingwu_manor_outer_court"
const LIEYUN_HALL := &"ch7_s5_lieyun_assembly_hall"
const MINGWU_INNER := &"ch7_s6_mingwu_inner_court"
const LIEYUN_ARCHIVE := &"ch7_s7_lieyun_resettlement_archive"
const MINGWU_ARCHIVE := &"ch7_s8_mingwu_permission_archive"
const OUTER_QUEST := &"q_ch7_main_03_outer_wards"
const SECT_FIELD := "res://build/sect_completion_20261030a_system01/sect_field.gd"

func _done() -> void:
	print("CH7_WARDS_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _native_gate(field: Node,target: StringName,foot: Vector2) -> Node:
	if not _expect(field.get_script().resource_path == SECT_FIELD, "official native parent " + String(target)): return null
	if not _expect(await _outside_approach(field,target,foot),"native door on the same elevation " + String(target)): return null
	print("CH7_NATIVE_INPUT Space ",target)
	await _press_space()
	return await _ready_field(target)

func _npc_talk(field: Node,uv: Vector2,id: StringName) -> bool:
	var scene := field.get("_current_scene") as SceneScript
	if not _expect(bool(field.call("_spawn_has_foot_clearance",scene,uv)),"walkable NPC approach " + String(id)): return false
	await _place(field,uv)
	print("CH7_NPC_INPUT Space ",id)
	await _press_space()
	var passed := await _drain(id)
	await process_frame
	await physics_frame
	return passed

func _locked_door(field: Node,target: StringName) -> bool:
	var scene := field.get("_current_scene") as SceneScript
	var authored := false
	for portal: Dictionary in scene.map_layout.portals:
		if StringName(portal.get("target_scene","")) == target and not String(portal.get("require_flag","")).is_empty():
			authored = true
	var zone := _portal(field,target)
	return authored and (not is_instance_valid(zone) or zone.is_locked)

func _run() -> void:
	if not _expect(_paused_checkpoints,"private checkpoint saves suspended"): _done(); return
	_router=root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	var flags: Dictionary=state.get("flags")
	var quests := root.get_node("QuestManager")
	flags["chapter6_complete"]=true
	flags["chapter7_investigation_unlocked"]=true
	flags["ch7_outer_routes_opened"]=true
	flags["ch7_route_first_lieyun"]=true
	flags["seen_ch7_lieyun_outer_intro"]=true
	flags["seen_ch7_mingwu_outer_intro"]=true
	quests.call("accept",OUTER_QUEST)
	if not _expect(bool(_router.call("go_field_smart",FERRY,null,"",-1,1)),"open official Lieyun exterior"): _done(); return
	var field: Node=await _ready_field(FERRY)
	if field==null: _done(); return
	field=await _native_gate(field,LIEYUN_OUTER,Vector2(3100,1160))
	if field==null: _done(); return
	_verify_layout(field,LIEYUN_OUTER)
	_expect(_feet(field).distance_to(Vector2(.5,.875)*SIZE)<2.0,"Lieyun arrivals use original entry path")
	_expect(_locked_door(field,LIEYUN_HALL),"Lieyun council locked initially")
	await _place(field,Vector2(.51,.58))
	await _capture(field,"ch7_lieyun_outer")
	if not await _talk(field,&"ch7_lieyun_quarantine_register",Vector2(.281,.414)): _done(); return
	_expect(bool(flags.get("ch7_lieyun_registry_checked",false)),"original quarantine register recorded")
	await process_frame
	field=await _ready_field(LIEYUN_OUTER)
	if field==null: _done(); return
	_expect(field.get("_npc_nodes").size()==1,"the original patrol appears after the register")
	_expect((field.get("_current_scene") as SceneScript).encounter_groups.size()==3,"Lieyun keeps all encounter groups")
	state.call("set_flag",&"ch7_lieyun_hardliners_defeated",true)
	field=await _ready_field(LIEYUN_OUTER)
	if field==null: _done(); return
	field=await _door(field,FERRY,Vector2(.5,.925))
	if field==null: _done(); return
	_expect(_feet(field).distance_to(Vector2(3100,1160))<2.0,"outer return exact Lieyun native gate")
	if not _expect(bool(_router.call("go_field_smart",TEA_TOWN,null,"",-1,1)),"open official Mingwu exterior"): _done(); return
	field=await _ready_field(TEA_TOWN)
	if field==null: _done(); return
	field=await _native_gate(field,MINGWU_OUTER,Vector2(4080,1350))
	if field==null: _done(); return
	_verify_layout(field,MINGWU_OUTER)
	_expect(_locked_door(field,MINGWU_INNER),"Mingwu inner court locked initially")
	_expect(_area_for_action(field,"dialog:ch7_mingwu_transfer_ledger_direct")==null,"alerted and direct branches are mutually exclusive")
	await _place(field,Vector2(.51,.56))
	await _capture(field,"ch7_mingwu_outer")
	if not await _talk(field,&"ch7_mingwu_transfer_ledger_alerted",Vector2(.273,.451)): _done(); return
	_expect(bool(quests.call("is_completed",OUTER_QUEST)),"outer wards quest completes from both live clue actions and isolated victory")
	await process_frame
	field=await _ready_field(MINGWU_OUTER)
	if field==null: _done(); return
	if not await _npc_talk(field,Vector2(.649,.48),&"ch7_inner_routes_open"): _done(); return
	field=await _ready_field(MINGWU_OUTER)
	if field==null: _done(); return
	field=await _door(field,MINGWU_INNER,Vector2(.5,.180))
	if field==null: _done(); return
	_verify_layout(field,MINGWU_INNER)
	_expect(_locked_door(field,MINGWU_ARCHIVE),"permission archive remains gated")
	await _place(field,Vector2(.51,.57))
	await _capture(field,"ch7_mingwu_inner")
	if not await _npc_talk(field,Vector2(.274,.46),&"ch7_mingwu_clerk_witness_alerted"): _done(); return
	_expect(bool(flags.get("ch7_mingwu_witness_heard",false)),"original witness testimony recorded")
	field=await _ready_field(MINGWU_INNER)
	if field==null: _done(); return
	field=await _door(field,MINGWU_OUTER,Vector2(.5,.925))
	if field==null: _done(); return
	_expect(_feet(field).distance_to(Vector2(.5,.180)*SIZE)<2.0,"Mingwu inner returns to exact outer gate")
	field=await _door(field,TEA_TOWN,Vector2(.5,.925))
	if field==null: _done(); return
	_expect(_feet(field).distance_to(Vector2(4080,1350))<2.0,"outer return exact native tea town gate")
	if not _expect(bool(_router.call("go_field_smart",FERRY,null,"",-1,1)),"reopen official Lieyun exterior"): _done(); return
	field=await _ready_field(FERRY)
	if field==null: _done(); return
	field=await _native_gate(field,LIEYUN_OUTER,Vector2(3100,1160))
	if field==null: _done(); return
	field=await _door(field,LIEYUN_HALL,Vector2(.5,.180))
	if field==null: _done(); return
	_verify_layout(field,LIEYUN_HALL)
	_expect(_locked_door(field,LIEYUN_ARCHIVE),"resettlement archive remains gated")
	await _place(field,Vector2(.50,.60))
	await _capture(field,"ch7_lieyun_hall")
	if not await _npc_talk(field,Vector2(.555,.305),&"ch7_qi_yunsheng_meeting"): _done(); return
	_expect(bool(flags.get("ch7_qi_reform_testimony_heard",false)),"original Qi Yunsheng testimony recorded")
	field=await _ready_field(LIEYUN_HALL)
	if field==null: _done(); return
	field=await _door(field,LIEYUN_OUTER,Vector2(.5,.925))
	if field==null: _done(); return
	_expect(_feet(field).distance_to(Vector2(.5,.180)*SIZE)<2.0,"Lieyun hall returns to exact outer gate")
	_done()
