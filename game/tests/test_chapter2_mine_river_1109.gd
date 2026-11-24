extends "res://tests/test_inner_courts_modular_1108.gd"

const AMBUSH := &"ch2_s3_forest_ambush"
const MINE := &"ch2_s5_bandit_cave"
const WORKSHOP := &"ch2_s5_mine_workshop"
const COMMAND := &"ch2_s5_mine_command"
const RIVER := &"ch2_s6_river_camp"
const MARKET := &"ch2_s1_zhuwei_market"
const GATE_LINGYUE := &"ch2_s4_lingyue_gate"
const SIZE := Vector2(1536, 1024)
const OLD_LAYOUTS := {
	MINE:"ch2_s5_bandit_cave_entrance_layout_v2",
	WORKSHOP:"ch2_s5_mine_workshop_layout_v2",
	COMMAND:"ch2_s5_mine_command_layout_v2",
	RIVER:"ch2_s6_river_camp_layout_v1",
}

func _done() -> void:
	print("CH2_MINE_RIVER_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _contract(field: Node, id: StringName, uv: Vector2) -> void:
	var scene := field.get("_current_scene") as SceneScript
	var old := load("res://data/maps/%s.tres" % OLD_LAYOUTS[id]) as WalkableMapLayout
	var layout := scene.map_layout
	_expect(scene.scene_id == id and scene.background_path.is_empty() and layout.resource_path != old.resource_path and layout.visual_objects.size() >= 17, "live modular layout " + String(id))
	_expect(Vector2(field.get("_world_size")) == SIZE, "original logical extent " + String(id))
	_expect(layout.schema_version == old.schema_version and layout.walkable_regions == old.walkable_regions and layout.portals == old.portals and layout.interactions == old.interactions, "original version, boundaries and story contract " + String(id))
	_expect(_feet(field).distance_to(uv * SIZE) < 2.0, "original arrival " + String(id) + ": " + str(_feet(field)))
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance", scene, probe.pos)), "clear " + String(probe.id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance", scene, probe.pos)), "blocked " + String(probe.id))
	for solid: Dictionary in layout.blockers:
		_expect(not bool(field.call("_spawn_has_foot_clearance", scene, solid.pos)), "solid at the object base: " + String(solid.id))

func _locked(field: Node, name: String) -> bool:
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.destination_name == name:
			return zone.is_locked and zone.target_scene_id.is_empty()
	return false

func _door(field: Node, target: StringName, uv: Vector2) -> Node:
	await _place(field, uv)
	var zone := _portal(field, target)
	if not _expect(is_instance_valid(zone) and not zone.is_locked and bool(zone.get("_in_range")), "in range of original door to " + String(target) + " at " + str(_feet(field))):
		return null
	print("CH2_MINE_RIVER_INPUT Space ", target)
	await _press_space()
	return await _ready_field(target)

func _talk(field: Node, id: StringName, uv: Vector2) -> bool:
	var area := _area_for_action(field, "dialog:" + String(id))
	if not _expect(is_instance_valid(area), "existing story area " + String(id)):
		return false
	if id == &"ch2_mine_burned_ledger":
		await _place(field, Vector2(0.643, 0.675))
		var walk := InputEventKey.new()
		walk.keycode = KEY_S
		walk.physical_keycode = KEY_S
		walk.pressed = true
		Input.parse_input_event(walk)
		for i in range(60):
			await physics_frame
			area = _area_for_action(field, "dialog:" + String(id))
			if is_instance_valid(area) and area.overlaps_body(field.get("_player")): break
		var release := walk.duplicate() as InputEventKey
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
	else:
		await _place(field, uv)
	area = _area_for_action(field, "dialog:" + String(id))
	var actor := field.get("_player") as Player
	if not _expect(is_instance_valid(area) and area.overlaps_body(actor), "physically in story area " + String(id) + ": " + str(_feet(field))):
		return false
	print("CH2_MINE_RIVER_INPUT Space ", id)
	await _press_space()
	var dialog := root.get_node("DialogPlayer")
	for i in range(32):
		if bool(dialog.call("is_playing")): break
		await process_frame
	var active := dialog.get("_current_script") as DialogScript
	if not _expect(active != null and active.dialog_id == id, "original dialogue " + String(id) + " got " + (String(active.dialog_id) if active != null else "none")):
		return false
	for i in range(12):
		if not bool(dialog.call("is_playing")): break
		dialog.call("advance")
		await process_frame
	return true

func _mine_route(flags: Dictionary) -> void:
	flags["seen_ch2_first_ambush"] = true
	flags["defeated_masked_killer_minion"] = true
	flags["defeated_masked_killer_elite"] = true
	flags["ch2_rescue_complete"] = true
	root.get_node("InvestigationState").call("acquire_evidence", &"ev_ch2_split_tracks", &"isolated_route_fixture")
	if not _expect(bool(_router.call("go_field_smart", AMBUSH, Vector2(.76,.34), "", -1, 1)), "load official ambush parent"):
		return
	var field: Node = await _ready_field(AMBUSH)
	if field == null or not await _talk(field, &"ch2_hideout_intro", Vector2(.78,.34)): return
	field = await _ready_field(MINE)
	if field == null: return
	# The legacy dialogue route's deferred quest refresh carries the source UV.
	# It is separate from the authored default/door arrivals in these layouts.
	_contract(field, MINE, Vector2(.78,.34))
	_expect(bool(field.call("_spawn_has_foot_clearance",field.get("_current_scene"),Vector2(.115,.835))), "authored lower entrance is physically clear")
	await _place(field, Vector2(.50,.52))
	await _capture(field, "ch2_mine_entrance")
	_expect(_locked(field,"沿矿轨进入制牌作坊"), "workshop initially locked")
	if not await _talk(field, &"ch2_mine_entry_tracks", Vector2(.515,.532)): return
	field = await _ready_field(MINE)
	if field == null: return
	_expect(bool(flags.get("ch2_mine_tracks_examined", false)), "original tracks action unlocks workshop")
	field = await _door(field, WORKSHOP, Vector2(.905,.215))
	if field == null: return
	_contract(field, WORKSHOP, Vector2(.120,.840))
	_expect(_locked(field,"推开账房木门"), "command initially locked")
	_expect(_area_for_action(field,"dialog:ch2_mine_burned_ledger") == null, "burned ledger stays hidden until sentry victory")
	_expect(field.get("_npc_nodes").size() == 1, "original sentry is loaded")
	await _place(field, Vector2(.555,.57))
	await _capture(field, "ch2_mine_workshop")
	if not await _talk(field, &"ch2_mine_token_molds", Vector2(.646,.700)): return
	# Inject only the sentry battle outcome; the evidence interaction still uses live input.
	root.get_node("GameState").call("set_flag", "defeated_ch2_mine_sentry", true)
	field = await _ready_field(WORKSHOP)
	if field == null or not await _talk(field, &"ch2_mine_burned_ledger", Vector2(.650,.760)): return
	field = await _ready_field(WORKSHOP)
	if field == null: return
	_expect(bool(flags.get("ch2_mine_workshop_searched",false)), "original ledger action unlocks command")
	field = await _door(field, COMMAND, Vector2(.910,.225))
	if field == null: return
	_contract(field, COMMAND, Vector2(.130,.825))
	_expect(field.get("_npc_nodes").size() == 1, "original masked leader is loaded")
	_expect(_area_for_action(field,"dialog:ch2_hideout_result") == null, "evidence chest cannot be opened before victory")
	await _place(field, Vector2(.586,.59))
	await _capture(field, "ch2_mine_command")
	field = await _door(field, WORKSHOP, Vector2(.105,.855))
	if field == null: return
	_expect(_feet(field).distance_to(Vector2(.910,.225)*SIZE)<2.0, "return to remembered command-door anchor " + str(_feet(field)))
	field = await _door(field, MINE, Vector2(.105,.855))
	if field == null: return
	_expect(_feet(field).distance_to(Vector2(.905,.215)*SIZE)<2.0, "return to remembered workshop-door anchor " + str(_feet(field)))
	field = await _door(field, AMBUSH, Vector2(.095,.860))
	if field == null: return
	_expect(_feet(field).distance_to(Vector2(.78,.34)*Vector2(field.get("_world_size")))<2.0, "return to original ambush tracks")

func _river_route() -> void:
	if not _expect(bool(_router.call("go_field_smart", MARKET, null, "", -1, 1)), "formal morning market"): return
	var outside: Node = await _ready_field(MARKET)
	if outside == null: return
	var zone := _portal(outside, RIVER)
	var world := outside.get("world_container") as Node2D
	if not _expect(zone != null and await _outside_approach(outside, RIVER, world.to_local(zone.global_position)), "physical original market river door"):
		return
	var return_foot := _feet(outside)
	print("CH2_MINE_RIVER_INPUT Space ", RIVER)
	await _press_space()
	var field: Node = await _ready_field(RIVER)
	if field == null: return
	_contract(field, RIVER, Vector2(.16,.78))
	var scene := field.get("_current_scene") as SceneScript
	_expect(scene.encounter_groups.size() == 2 and is_equal_approx(scene.encounter_chance, .20) and is_equal_approx(scene.encounter_step_distance, 520.0), "original river encounters and timing")
	_expect(not bool(field.call("_spawn_has_foot_clearance",scene,Vector2(.75,.74))), "water remains unwalkable")
	await _place(field, Vector2(.46,.54))
	await _capture(field, "ch2_river_camp")
	outside = await _door(field, MARKET, Vector2(.10,.82))
	if outside != null: _expect(_feet(outside).distance_to(return_foot)<2.0, "river returns to paired market trail " + str(_feet(outside)) + " vs " + str(return_foot))

func _run() -> void:
	if not _expect(_paused_checkpoints, "private test profile and suspended checkpoints"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var flags: Dictionary = root.get_node("GameState").get("flags")
	flags["chapter1_complete"] = true
	flags["seen_ch2_zhuwei_intro"] = true
	flags["heard_about_missing_lingyue"] = true
	await _mine_route(flags)
	await _river_route()
	_done()
