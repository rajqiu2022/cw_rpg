extends "res://tests/test_chapter7_outer_inner_wards_1109.gd"

const MUSTER := &"ch8_s1_alliance_staging_ground"
const MISTWOOD := &"ch8_s2_mistwood_blockade"
const PERIMETER := &"ch8_s3_manor_perimeter_encampment"
const GALLERY := &"ch8_s4_alliance_mechanism_gallery"
const MISTWOOD_QUEST := &"q_ch8_main_02_mistwood_blockade"
const ORDERS_QUEST := &"q_ch8_main_03_false_order_matrix"

func _done() -> void:
	print("CH8_ALLIANCE_MODULAR_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _ready_field(id: StringName) -> Node:
	if id != MUSTER:
		return await super._ready_field(id)
	var deadline := Time.get_ticks_msec() + 25000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var field := current_scene
		if field == null or not field.has_method("get_field_loading_state") or _router.call("get_current_field_id") != id: continue
		var status: Dictionary = field.call("get_field_loading_state")
		var actor := field.get("_player") as Player
		if not bool(status.get("complete",false)) or not is_instance_valid(actor): continue
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		var dialog := root.get_node("DialogPlayer")
		var active := dialog.get("_current_script") as DialogScript
		if actor.can_move or (bool(dialog.call("is_playing")) and active != null and active.dialog_id == &"ch8_alliance_intro"):
			await physics_frame
			return field
	_expect(false,"muster field or chapter opening ready")
	return null

func _exact_feet(field: Node, uv: Vector2, label: String) -> void:
	_expect(_feet(field).distance_to(uv*Vector2(field.get("_world_size"))) < 2.0, label + " feet " + str(_feet(field)))

func _await_unlock(field: Node, target: StringName) -> bool:
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var zone := _portal(field,target)
		if is_instance_valid(zone) and not zone.is_locked and bool(field.call("get_field_loading_state").get("complete",false)):
			return true
	return _expect(false,"live gate did not refresh after story " + String(target))

func _run() -> void:
	if not _expect(_paused_checkpoints,"private checkpoint saves suspended"): _done(); return
	_router = root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	var flags: Dictionary = state.get("flags")
	var quests := root.get_node("QuestManager")
	flags["chapter7_complete"] = true
	flags["ch7_witness_plan_split"] = true
	if not _expect(bool(_router.call("go_chapter",8)), "open chapter 8 by the official chapter entry"): _done(); return
	var field: Node = await _ready_field(MUSTER)
	if field == null: _done(); return
	if not await _drain(&"ch8_alliance_intro"): _done(); return
	field = await _ready_field(MUSTER)
	if field == null: _done(); return
	_verify_layout(field,MUSTER)
	_exact_feet(field,Vector2(.5,.88),"chapter opening")
	_expect(bool(quests.call("is_active",&"q_ch8_main_01_alliance_muster")), "original opening accepts muster quest")
	_expect(_locked_door(field,MISTWOOD),"muster door locked until clerk briefing")
	await _place(field,Vector2(.51,.62))
	await _capture(field,"ch8_muster")
	if not await _npc_talk(field,Vector2(.452,.537),&"ch8_muster_split"): _done(); return
	_expect(bool(flags.get("ch8_alliance_mustered",false)) and bool(quests.call("is_active",MISTWOOD_QUEST)), "clerk opens mistwood and accepts the quest")
	field = await _ready_field(MUSTER)
	if field == null: _done(); return
	if not await _await_unlock(field,MISTWOOD): _done(); return
	# Ordinary Field's physics body is 42 px below the actor origin.
	field = await _door(field,MISTWOOD,Vector2(.5,.207))
	if field == null: _done(); return
	_verify_layout(field,MISTWOOD)
	_exact_feet(field,Vector2(.5,.86),"mistwood south entry")
	_expect(_locked_door(field,PERIMETER),"mistwood door locked before victory")
	var mistwood := field.get("_current_scene") as SceneScript
	_expect(mistwood.encounter_groups.size()==3 and mistwood.encounter_step_distance==840.0 and mistwood.encounter_require_flag==&"ch8_mistwood_blockade_cleared","old repeat encounters remain gated")
	_expect(field.get("_npc_nodes").size()==1,"original blockade envoy visible")
	await _place(field,Vector2(.5,.59))
	await _capture(field,"ch8_mistwood")
	field = await _door(field,MUSTER,Vector2(.5,.92))
	if field == null: _done(); return
	# The original router recalls the departure spot and nudges it to clear geometry.
	_expect(_feet(field).distance_to(Vector2(.5,.207)*SIZE)<12.0,"return to the original muster exit approach")
	field = await _door(field,MISTWOOD,Vector2(.5,.207))
	if field == null: _done(); return
	# Isolate combat: use the original victory dialogue, not a simulated fight.
	var victory := load("res://data/dialogs/ch8_mistwood_victory.tres") as DialogScript
	root.get_node("DialogPlayer").call("play",victory)
	if not await _drain(&"ch8_mistwood_victory"): _done(); return
	field = await _ready_field(MISTWOOD)
	if field == null: _done(); return
	_expect(bool(flags.get("ch8_mistwood_blockade_cleared",false)) and bool(quests.call("is_active",ORDERS_QUEST)), "existing victory dialogue clears the road")
	if not await _await_unlock(field,PERIMETER): _done(); return
	field = await _door(field,PERIMETER,Vector2(.5,.22))
	if field == null: _done(); return
	_verify_layout(field,PERIMETER)
	_exact_feet(field,Vector2(.5,.86),"outer encampment south entry")
	_expect(_locked_door(field,GALLERY),"gallery remains gated until orders are checked")
	await _place(field,Vector2(.50,.61))
	await _capture(field,"ch8_perimeter")
	if not await _talk(field,&"ch8_false_order_matrix",Vector2(.25,.50)): _done(); return
	_expect(bool(flags.get("ch8_mechanism_gallery_open",false)) and bool(quests.call("is_completed",ORDERS_QUEST)), "live document action completes orders and unlocks the gallery")
	field = await _ready_field(PERIMETER)
	if field == null: _done(); return
	if not await _await_unlock(field,GALLERY): _done(); return
	field = await _door(field,GALLERY,Vector2(.5,.22))
	if field == null: _done(); return
	_exact_feet(field,Vector2(.5,.86),"original gallery threshold")
	field = await _door(field,PERIMETER,Vector2(.5,.92))
	if field == null: _done(); return
	_exact_feet(field,Vector2(.5,.22),"gallery returns beside its door")
	field = await _door(field,MISTWOOD,Vector2(.5,.92))
	if field == null: _done(); return
	_exact_feet(field,Vector2(.5,.22),"encampment returns to mistwood north trail")
	_done()
