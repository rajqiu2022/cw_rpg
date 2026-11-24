extends SceneTree

## Run first/resume in separate processes with the same isolated profile.
## Position at each interaction or road gate, then use the field's Space handler.
const CASE := &"q_east_tidesound_blade"
const BLADE := &"east_tidesound_blade"
const CITY := &"east_cangpu_city"
const TEA := &"east_tea_ridge_village"
const SALT := &"east_salt_bay_village"
const PORT := &"east_tidegate_port"
const ROAD := &"east_mainland_overworld"
var router: Node
var dialogue: Node
var state: Node
var quests: Node
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		printerr("TIDE_FAIL ", label)
		quit(1)
	return ok

func ready_at(id: StringName) -> bool:
	var end := Time.get_ticks_msec() + 45000
	while Time.get_ticks_msec() < end:
		await process_frame
		if current_scene != null and current_scene.has_method("get_field_loading_state") and router.get_current_field_id() == id and current_scene.get_field_loading_state().get("complete", false) and not root.get_node("LoadingManager")._transition_active:
			await physics_frame
			return true
	return check(false, "field did not load: " + str(id))

func interact_at(point: Vector2) -> void:
	var actor: Node2D = current_scene._player
	actor.global_position = point
	for tick in 4:
		await physics_frame
	current_scene._on_player_interacted()

func door(id: StringName) -> bool:
	var field := current_scene
	for gate in field._exit_nodes:
		if gate.target_scene_id == String(id):
			await interact_at(gate.global_position)
			return await ready_at(id)
	return check(false, "gate missing: " + str(id))

func travel(to: StringName) -> bool:
	return await door(ROAD) and await door(to)

func opened(id: String) -> bool:
	for frame in 12:
		if dialogue.is_playing():
			break
		await process_frame
	var actual: String = str(dialogue._current_script.dialog_id) if dialogue.is_playing() else "(none)"
	return check(actual == id, "wanted %s, opened %s" % [id, actual])

func talk(npc_id: String, id: String) -> bool:
	for npc in current_scene._npc_nodes:
		if npc.npc_id == npc_id:
			await interact_at(npc.global_position + Vector2(0, 32))
			return await opened(id)
	return check(false, "NPC missing: " + npc_id)

func inspect(id: String, script_id: String) -> bool:
	for zone in current_scene._trigger_areas:
		if not is_instance_valid(zone) or zone.is_queued_for_deletion():
			continue
		if zone.get_meta("trigger_data", {}).get("id", "") == id:
			if not check(current_scene._is_inside_walkable_screen(zone.global_position), "blocked foot: " + id):
				return false
			await interact_at(zone.global_position)
			return await opened(script_id)
	return check(false, "inspection missing: " + id)

func finish_dialogue() -> void:
	var end := Time.get_ticks_msec() + 5000
	while dialogue.is_playing():
		if not check(Time.get_ticks_msec() < end, "dialogue did not finish"):
			return
		dialogue.advance()
		await process_frame
	for tick in 5:
		await physics_frame

func capture(filename: String) -> void:
	var destination := OS.get_environment("TIDESOUND_CAPTURES")
	if destination.is_empty() or DisplayServer.get_name() == "headless":
		return
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(destination.path_join(filename)) == OK, "capture " + filename)

func witness(town: StringName) -> bool:
	if not await travel(town):
		return false
	if town == TEA:
		if not await talk("tea_ridge_carrier", "east_tide_tea"):
			return false
	elif not await talk("saltbay_resident", "east_tide_salt"):
		return false
	await finish_dialogue()
	return true

func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if not check("--isolated-profile" in args and OS.get_environment("TIDESOUND_QA") == "1", "use an isolated QA profile"):
		return
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	dialogue = root.get_node("DialogPlayer")
	quests = root.get_node("QuestManager")
	var saves := root.get_node("SaveManager")
	var inventory := root.get_node("Inventory")
	var evidence := root.get_node("InvestigationState")
	var first := SALT if "--salt-first" in args else TEA
	if "--resume" not in args:
		router.go_field_smart(ROAD)
		if not await ready_at(ROAD) or not await door(CITY):
			return
		if not await talk("cangpu_postmaster", "east_tide_offer"):
			return
		dialogue.choose(0)
		dialogue.choose(1)
		if not check(not quests.is_active(CASE) and not state.get_flag("tide_case_opened"), "declining leaves case available"):
			return
		if not await talk("cangpu_postmaster", "east_tide_offer"):
			return
		dialogue.choose(0)
		dialogue.choose(0)
		await finish_dialogue()
		if not check(quests.is_active(CASE) and evidence.has_evidence(&"ev_tide_sample"), "tea chest sample entered journal"):
			return
		if not await witness(first):
			return
		if not await travel(PORT) or not await talk("tidegate_clerk", "east_tidegate_clerk"):
			return
		await finish_dialogue()
		if not check(not state.get_flag("tide_waybills_open") and saves.save_to_slot(1), "single clue cannot open bills, save written"):
			return
	else:
		if not check(saves.load_from_slot(1) and saves.get_save_field_id(1) == PORT, "cold load port save"):
			return
		router.go_field_smart(PORT)
		if not await ready_at(PORT):
			return
		if not check(quests.is_active(CASE) and evidence.has_evidence(&"ev_tide_silt" if first == SALT else &"ev_tide_lashing"), "first witness survived restart"):
			return
		if not await witness(TEA if first == SALT else SALT):
			return
		if not await travel(PORT) or not await talk("tidegate_clerk", "east_tide_clerk"):
			return
		await finish_dialogue()
		if not await inspect("tide_ship_bills", "east_tide_bills"):
			return
		await capture("waybills.png")
		dialogue.choose(0)
		if not check(not state.get_flag("tide_berth_known"), "wrong ship does not unlock chest"):
			return
		dialogue.advance()
		dialogue.choose(1)
		await finish_dialogue()
		if not await inspect("tide_sunken_chest", "east_tide_chest"):
			return
		await capture("west-berth.png")
		await finish_dialogue()
		if not check(evidence.has_evidence(&"ev_tide_blade") and inventory.count_of(BLADE) == 0, "rusted blade is evidence before repair"):
			return
		if not await travel(CITY) or not await talk("cangpu_postmaster", "east_tide_repair"):
			return
		dialogue.advance()
		await capture("blade-reward.png")
		await finish_dialogue()
		if not check(quests.is_completed(CASE) and inventory.count_of(BLADE) == 1 and evidence.is_evidence_verified(&"ev_tide_blade"), "case closed and exactly one repaired weapon"):
			return
		if not await talk("cangpu_postmaster", "east_cangpu_clerk"):
			return
		await finish_dialogue()
		if not check(inventory.count_of(BLADE) == 1 and inventory.equip(BLADE) and inventory.get_equipped_id(0) == BLADE, "revisit does not pay twice; blade equips"):
			return
	print("TIDE_PASS first=", first, " resume=", "--resume" in args, " checks=", checks)
	quit()
