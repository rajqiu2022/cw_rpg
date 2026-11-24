extends "res://tests/test_chapter7_outer_inner_wards_1109.gd"

const SEAL_ROOM := &"ch7_s9_mingwu_seal_audit_room"
const NIGHT_STATION := &"ch7_s10_lieyun_night_transfer_station"
const REFORM_QUEST := &"q_ch7_main_04_reform_and_witness"
const DEAD_NAME_QUEST := &"q_ch7_main_05_dead_name_live_access"
const IDENTITY_QUEST := &"q_ch7_main_06_threefold_identity_check"
const AUTHORIZATION_QUEST := &"q_ch7_main_08_inner_office_authorization"
const PERSONAL_QUEST := &"q_ch7_main_10_personal_authorization"

func _done() -> void:
	print("CH7_ARCHIVE_TRANSFER_RESULT ",_checks,"/",_failed)
	quit(0 if _failed == 0 else 1)

func _settle(id: StringName) -> Node:
	await process_frame
	await physics_frame
	return await _ready_field(id)

func _exact(field: Node, uv: Vector2, name: String) -> void:
	_expect(_feet(field).distance_to(uv*SIZE)<2.0,name + ": " + str(_feet(field)))

func _start_at(id: StringName) -> Node:
	if not _expect(bool(_router.call("go_field_smart",id,null,"",-1,2)),"official scene " + String(id)): return null
	return await _ready_field(id)

func _run() -> void:
	if not _expect(_paused_checkpoints,"private test profile and suspended checkpoints"): _done(); return
	_router = root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	var flags: Dictionary = state.get("flags")
	var quests := root.get_node("QuestManager")
	flags["chapter6_complete"] = true
	flags["chapter7_investigation_unlocked"] = true
	flags["ch7_inner_routes_opened"] = true
	quests.call("accept",REFORM_QUEST)
	quests.call("complete",REFORM_QUEST)
	var field: Node = await _start_at(LIEYUN_HALL)
	if field == null: _done(); return
	_expect(_locked_door(field,LIEYUN_ARCHIVE),"first archive sealed before speaking to Qi")
	if not await _npc_talk(field,Vector2(.555,.305),&"ch7_dead_code_routes_open"): _done(); return
	field = await _ready_field(LIEYUN_HALL)
	if field == null: _done(); return
	field = await _door(field,LIEYUN_ARCHIVE,Vector2(.5,.175))
	if field == null: _done(); return
	_verify_layout(field,LIEYUN_ARCHIVE)
	_exact(field,Vector2(.5,.875),"original resettlement archive arrival")
	_expect(_locked_door(field,NIGHT_STATION),"night station initially gated")
	await _place(field,Vector2(.50,.66))
	await _capture(field,"ch7_resettlement_archive")
	if not await _npc_talk(field,Vector2(.281,.421),&"ch7_lieyun_record_keeper_testimony"): _done(); return
	_expect(bool(flags.get("ch7_lieyun_posthumous_code_heard",false)),"original keeper testimony")
	field = await _ready_field(LIEYUN_ARCHIVE)
	if field == null: _done(); return
	field = await _door(field,LIEYUN_HALL,Vector2(.5,.925))
	if field == null: _done(); return
	_exact(field,Vector2(.5,.175),"resettlement archive returns by hall door")

	field = await _start_at(MINGWU_INNER)
	if field == null: _done(); return
	field = await _door(field,MINGWU_ARCHIVE,Vector2(.5,.175))
	if field == null: _done(); return
	_verify_layout(field,MINGWU_ARCHIVE)
	_exact(field,Vector2(.5,.875),"original permission archive arrival")
	_expect(_locked_door(field,SEAL_ROOM),"seal room initially gated")
	await _place(field,Vector2(.50,.64))
	await _capture(field,"ch7_permission_archive")
	if not await _talk(field,&"ch7_mingwu_revoked_access_roll",Vector2(.285,.370)): _done(); return
	_expect(bool(quests.call("is_completed",DEAD_NAME_QUEST)),"cross-checked the revoked roll and keeper testimony")
	field = await _settle(MINGWU_ARCHIVE)
	if field == null: _done(); return
	field = await _door(field,MINGWU_INNER,Vector2(.5,.925))
	if field == null: _done(); return
	_exact(field,Vector2(.5,.175),"permission archive returns to original inner gate")

	field = await _start_at(LIEYUN_HALL)
	if field == null: _done(); return
	if not await _npc_talk(field,Vector2(.555,.305),&"ch7_identity_routes_open"): _done(); return
	_expect(bool(flags.get("ch7_identity_routes_opened",false)),"original conversation opens audit room and station")
	field = await _ready_field(LIEYUN_HALL)
	if field == null: _done(); return
	field = await _door(field,LIEYUN_ARCHIVE,Vector2(.5,.175))
	if field == null: _done(); return
	field = await _door(field,NIGHT_STATION,Vector2(.5,.175))
	if field == null: _done(); return
	_verify_layout(field,NIGHT_STATION)
	_exact(field,Vector2(.5,.86),"original night station arrival")
	var night := field.get("_current_scene") as SceneScript
	_expect(not bool(field.call("_spawn_has_foot_clearance",night,Vector2(.28,.872))) and not bool(field.call("_spawn_has_foot_clearance",night,Vector2(.78,.872))),"water and side loading jetty do not extend the walkable footprint")
	await _place(field,Vector2(.51,.62))
	await _capture(field,"ch7_night_transfer")
	if not await _talk(field,&"ch7_posthumous_route_timeline",Vector2(.50,.62)): _done(); return
	_expect(bool(flags.get("ch7_route_timeline_checked",false)),"original chronology evidence")
	quests.call("accept",AUTHORIZATION_QUEST)
	field = await _settle(NIGHT_STATION)
	if field == null: _done(); return
	if not await _talk(field,&"ch7_retrieval_objectives",Vector2(.721,.419)): _done(); return
	_expect(bool(flags.get("ch7_retrieval_objectives_checked",false)),"original road bundles evidence")
	field = await _settle(NIGHT_STATION)
	if field == null: _done(); return
	field = await _door(field,LIEYUN_ARCHIVE,Vector2(.5,.92))
	if field == null: _done(); return
	_exact(field,Vector2(.5,.175),"night station returns by archive's rear door")

	field = await _start_at(MINGWU_INNER)
	if field == null: _done(); return
	field = await _door(field,MINGWU_ARCHIVE,Vector2(.5,.175))
	if field == null: _done(); return
	field = await _door(field,SEAL_ROOM,Vector2(.5,.275))
	if field == null: _done(); return
	_verify_layout(field,SEAL_ROOM)
	_exact(field,Vector2(.5,.86),"original audit room arrival")
	await _place(field,Vector2(.49,.65))
	await _capture(field,"ch7_seal_audit")
	if not await _talk(field,&"ch7_mingwu_counterseal_check",Vector2(.48,.60)): _done(); return
	field = await _settle(SEAL_ROOM)
	if field == null: _done(); return
	if not await _npc_talk(field,Vector2(.317,.450),&"ch7_mingwu_instructor_recognition"): _done(); return
	_expect(bool(quests.call("is_completed",IDENTITY_QUEST)),"original seal, witness and timeline complete threefold check")
	field = await _settle(SEAL_ROOM)
	if field == null: _done(); return
	if not await _talk(field,&"ch7_inner_office_order",Vector2(.706,.413)): _done(); return
	_expect(bool(flags.get("ch7_inner_office_order_checked",false)),"original authorization roll evidence")
	quests.call("accept",PERSONAL_QUEST)
	field = await _settle(SEAL_ROOM)
	if field == null: _done(); return
	_expect(_area_for_action(field,"dialog:ch7_su_signed_directive")==null,"private order unavailable before defeating guard")
	state.call("set_flag",&"ch7_inner_office_destroyers_defeated",true)
	field = await _settle(SEAL_ROOM)
	if field == null: _done(); return
	if not await _talk(field,&"ch7_su_signed_directive",Vector2(.727,.525)): _done(); return
	_expect(bool(flags.get("ch7_su_signed_directive_checked",false)),"original signed directive evidence")
	field = await _settle(SEAL_ROOM)
	if field == null: _done(); return
	field = await _door(field,MINGWU_ARCHIVE,Vector2(.5,.92))
	if field != null: _exact(field,Vector2(.5,.275),"audit room returns by permission archive door")
	_done()
