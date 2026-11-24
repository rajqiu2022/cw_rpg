extends "res://tests/test_chapter3_modular_maps_1109.gd"

const MASTER_HALL := &"linxi_master_hall"
const LINXI := &"linxi_tutorial"
const ARCHIVE := &"ch6_s3_underground_archive"
const ROUTE := &"ch6_s4_baishui_convoy_route"
const INN := &"ch6_s5_ancient_road_inn"
const QUEST_ARCHIVE := &"q_ch6_main_03_underground_archive"
const QUEST_ROUTE := &"q_ch6_main_04_old_convoy_route"

func _done() -> void:
	print("CH6_MODULAR_MAPS_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _ready_field(id: StringName) -> Node:
	var intro := &"ch6_archive_intro" if id == ARCHIVE else (&"ch6_baishui_route_intro" if id == ROUTE else &"")
	if intro == &"": return await super._ready_field(id)
	var deadline := Time.get_ticks_msec() + 30000
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
		if actor.can_move or (bool(dialog.call("is_playing")) and active != null and active.dialog_id == intro):
			await physics_frame
			return field
	_expect(false,"field or expected opening dialog ready " + String(id))
	return null

func _verify_layout(field: Node, id: StringName) -> void:
	var scene := field.get("_current_scene") as SceneScript
	var old := load("res://data/maps/%s_layout_v1.tres" % id) as WalkableMapLayout
	var layout := scene.map_layout
	_expect(scene.scene_id == id and scene.background_path.is_empty() and layout.resource_path.ends_with("_layout_v2.tres"), "original ID loads independent layout " + String(id))
	_expect(Vector2(field.get("_world_size")) == SIZE and layout.schema_version == old.schema_version and layout.walkable_regions == old.walkable_regions, "original footprint and version " + String(id))
	var interactions := layout.interactions.duplicate(true)
	if id == INN and interactions.size() == 1 and old.interactions.size() == 1:
		for key: String in ["pos","size","visual_render_size_px"]: interactions[0][key] = old.interactions[0][key]
		interactions[0].erase("visual_z_index")
	_expect(interactions == old.interactions and layout.portals == old.portals, "original hotspot and portal contracts " + String(id))
	for row: Dictionary in layout.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance",scene,row.pos)), "safe approach " + String(row.id))
	for row: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance",scene,row.pos)), "solid object " + String(row.id))

func _drain(id: StringName, choice: int = -1) -> bool:
	var dialog := root.get_node("DialogPlayer")
	for i in range(45):
		if bool(dialog.call("is_playing")): break
		await process_frame
	var active := dialog.get("_current_script") as DialogScript
	if not _expect(active != null and active.dialog_id == id, "real dialog " + String(id)):
		return false
	for i in range(18):
		if not bool(dialog.call("is_playing")): return true
		var line := dialog.get("_current_node") as DialogNode
		if line != null and line.has_choices() and choice >= 0: dialog.call("choose",choice)
		else: dialog.call("advance")
		await process_frame
	return _expect(false, "dialog ended " + String(id))

func _run() -> void:
	if not _expect(_paused_checkpoints,"private checkpoint saves suspended"): _done(); return
	_router = root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	var flags: Dictionary = state.get("flags")
	var quests := root.get_node("QuestManager")
	flags["chapter5_complete"] = true
	flags["master_farewell_done"] = true
	flags["ch6_residence_note_found"] = true
	flags["seen_ch6_return_intro"] = true
	quests.call("accept",QUEST_ARCHIVE)
	if not _expect(bool(_router.call("go_field_smart",MASTER_HALL,null,"",-1,2)), "open actual master hall"): _done(); return
	var field: Node = await _ready_field(MASTER_HALL)
	if field == null: _done(); return
	_expect(_portal(field,ARCHIVE) == null,"hatch hidden before investigating the weapon rack")
	if not await _talk(field,&"ch6_residence_weapon_rack",Vector2(.378,.417)): _done(); return
	field = await _ready_field(MASTER_HALL)
	if field == null: _done(); return
	field = await _door(field,ARCHIVE,Vector2(.375,.425))
	if field == null: _done(); return
	if not await _drain(&"ch6_archive_intro"): _done(); return
	_verify_layout(field,ARCHIVE)
	_expect(_feet(field).distance_to(Vector2(.50,.885)*SIZE)<2.0,"archive hatch original arrival")
	_expect(_area_for_action(field,"dialog:ch6_archive_parent_roster") == null,"roster hidden before combat")
	_expect(not is_instance_valid(_portal(field,ROUTE)) or _portal(field,ROUTE).is_locked,"north exit gated before clearance")
	await _place(field,Vector2(.50,.66))
	await _capture(field,"ch6_archive")
	state.call("set_flag",&"ch6_archive_reclaimers_defeated",true)
	field = await _ready_field(ARCHIVE)
	if field == null: _done(); return
	if not await _talk(field,&"ch6_archive_parent_roster",Vector2(.315,.509)): _done(); return
	await process_frame
	await physics_frame
	_expect(bool(flags.get("ch6_archive_roster_found",false)),"roster action sets its original flag")
	field = await _ready_field(ARCHIVE)
	if field == null: _done(); return
	var amendment := _area_for_action(field,"dialog:ch6_archive_amendment")
	if amendment != null: print("CH6_AMENDMENT_AREA ",amendment.position," ",(amendment.get_child(0) as CollisionShape2D).shape.get_rect())
	if not await _talk(field,&"ch6_archive_amendment",Vector2(.688,.379)): _done(); return
	_expect(bool(flags.get("ch6_archive_records_secured",false)),"original archive evidence flag")
	state.call("set_flag",&"ch6_old_convoy_route_unlocked",true)
	quests.call("accept",QUEST_ROUTE)
	field = await _ready_field(ARCHIVE)
	if field == null: _done(); return
	field = await _door(field,ROUTE,Vector2(.50,.190))
	if field == null: _done(); return
	if not await _drain(&"ch6_baishui_route_intro"): _done(); return
	_verify_layout(field,ROUTE)
	_expect(_feet(field).distance_to(Vector2(.50,.875)*SIZE)<2.0,"road original south arrival")
	_expect(_area_for_action(field,"dialog:ch6_baishui_cart_trace") == null,"wreck clues gated before milestone")
	await _place(field,Vector2(.51,.57))
	await _capture(field,"ch6_baishui")
	if not await _talk(field,&"ch6_baishui_milestone",Vector2(.235,.50)): _done(); return
	field = await _ready_field(ROUTE)
	if field == null: _done(); return
	if not await _talk(field,&"ch6_baishui_cart_trace",Vector2(.585,.555)): _done(); return
	_expect(bool(flags.get("ch6_baishui_cart_checked",false)),"original cart evidence flag")
	_expect((field.get("_current_scene") as SceneScript).encounter_groups.size()==3,"original three encounter groups")
	state.call("set_flag",&"ch6_convoy_pursuers_defeated",true)
	field = await _ready_field(ROUTE)
	if field == null: _done(); return
	field = await _door(field,ARCHIVE,Vector2(.50,.905))
	if field == null: _done(); return
	_expect(absf(_feet(field).y - .20*SIZE.y) < 28.0,"road return arrives by the archive north gate")
	field = await _door(field,MASTER_HALL,Vector2(.50,.915))
	if field == null: _done(); return
	var hall_size := Vector2(field.get("_world_size"))
	print("CH6_ARCHIVE_RETURN_UV ",_feet(field)/hall_size)
	_expect(_feet(field).distance_to(Vector2(.375,.425)*hall_size)<2.0,"archive return arrives at exact master's hatch")
	field = await _door(field,LINXI,Vector2(.50,.900))
	if field == null: _done(); return
	var def := load("res://data/dialogs/ch6_master_confrontation.tres") as DialogScript
	root.get_node("DialogPlayer").call("play",def)
	if not await _drain(&"ch6_master_confrontation",0): _done(); return
	field = await _ready_field(INN)
	if field == null: _done(); return
	_verify_layout(field,INN)
	var inn_scene := field.get("_current_scene") as SceneScript
	print("CH6_INN_ARRIVAL ",_feet(field))
	_expect(bool(field.call("_spawn_has_foot_clearance",inn_scene,_feet(field)/SIZE)),"confrontation arrives on walkable inn floor")
	var letter := _area_for_action(field,"dialog:ch6_qiyun_letter")
	await _place(field,Vector2(.551,.585))
	_expect(is_instance_valid(letter) and letter.overlaps_body(field.get("_player")),"original sealed letter reachable at its desk")
	await _place(field,Vector2(.50,.712))
	await _capture(field,"ch6_ancient_road_inn")
	field = await _door(field,LINXI,Vector2(.50,.795))
	if field == null: _done(); return
	if not _expect(bool(_router.call("go_field_smart",INN)), "revisit inn in isolated test to check finale"): _done(); return
	field = await _ready_field(INN)
	if field == null: _done(); return
	if not await _talk(field,&"ch6_qiyun_letter",Vector2(.551,.585)): _done(); return
	_expect(bool(flags.get("ch6_qiyun_letter_read",false)) and bool(flags.get("chapter7_investigation_unlocked",false)),"letter sets the original read and chapter 7 flags")
	_done()
