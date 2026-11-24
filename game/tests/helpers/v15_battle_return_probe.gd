extends RefCounted
## Genuine single-enemy ordinary team battle UI. Result payloads, enemies,
## reward logic, return routing and production controllers are never replaced.
var tree: SceneTree
var driver: RefCounted
var report_check: Callable
var wait_field: Callable
var finish_intro: Callable
var clear_foot: Callable

func configure(owner: SceneTree, input: RefCounted, check: Callable, actual_field_wait: Callable, ordinary_intro: Callable, independent_fullfoot: Callable) -> void:
	tree = owner
	driver = input
	report_check = check
	wait_field = actual_field_wait
	finish_intro = ordinary_intro
	clear_foot = independent_fullfoot

func _check(ok: bool, label: String) -> void:
	if report_check.is_valid(): report_check.call(ok, label)

func run(field: Node, mode: String) -> Dictionary:
	var evidence: Dictionary = {"scope": "ACTUAL_V15_BATTLE_UI_RETURN_NOT_FAKE_RESULT", "mode": mode, "entered": false, "returned": false, "accepted_commands": 0}
	_check(mode in ["victory", "defeat", "flee"], "battle probe uses exact declared outcome fixture")
	_check(is_instance_valid(field) and tree.current_scene == field, "battle starts from live ordinary Field")
	if not mode in ["victory", "defeat", "flee"] or not is_instance_valid(field): return evidence
	var player: Node2D = field.get("_player") as Node2D
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var size: Vector2 = field.get("_world_size")
	_check(definition != null and definition.scene_id == &"world_map_jianghu_v15" and size == Vector2(12288, 8192), "actual v15 battle source ID and coordinate domain")
	_check(is_instance_valid(player) and bool(clear_foot.call(player.position)), "battle source has independently legal complete shoes")
	_check(not bool(tree.root.get_node("DialogPlayer").call("is_playing")), "no pending story modal is suppressed for battle")
	if definition == null or definition.scene_id != &"world_map_jianghu_v15" or size != Vector2(12288, 8192) or not is_instance_valid(player): return evidence
	if not bool(clear_foot.call(player.position)) or bool(tree.root.get_node("DialogPlayer").call("is_playing")): return evidence
	var original_px: Vector2 = player.position
	var original: Vector2 = original_px / size
	var state: Node = tree.root.get_node("GameState")
	# Public new-game data is a fixture only; no Router reset, enemy edit,
	# GM command, fabricated battle_ended signal or result-scene shortcut.
	for singleton: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState"]:
		tree.root.get_node(singleton).call("reset_for_new_game")
	var stats: Resource = state.get("player") as Resource
	_check(stats != null, "normal new-game battle stats exist")
	if stats == null: return evidence
	if mode == "victory": stats.call("gain_exp", 250)
	stats.set("hp", 1 if mode == "defeat" else stats.get("max_hp"))
	stats.set("mp", stats.get("max_mp"))
	var gold_before: int = state.get("gold")
	var bus: Node = tree.root.get_node("EventBus")
	var outcomes: Array[Dictionary] = []
	var observer: Callable = func(won: bool, fled: bool): outcomes.append({"won": won, "fled": fled})
	bus.connect("battle_ended", observer)
	var router: Node = tree.root.get_node("SceneRouter")
	var enemies: Array[StringName] = [&"thug_lone"]
	router.call("start_encounter", enemies, definition.scene_id, original)
	var battle: Node
	var deadline: int = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if bool(tree.root.get_node("LoadingManager").get("_transition_active")): continue
		if is_instance_valid(tree.current_scene) and tree.current_scene.get_node_or_null("%BtnAttack") != null:
			battle = tree.current_scene
			break
	_check(is_instance_valid(battle), "actual ordinary battle scene appears for " + mode)
	if not is_instance_valid(battle):
		bus.disconnect("battle_ended", observer)
		return evidence
	evidence.entered = true
	var payload: Dictionary = router.call("get_battle_payload")
	_check(payload.get("return_world_map_version", -1) == 15 and StringName(payload.get("return_scene", "")) == definition.scene_id, "actual battle carries source coordinate version15")
	_check(_point(payload.get("return_spawn")) == original, "actual battle payload keeps exact pre-battle source point")
	_check(bool(battle.get("_team_mode")), "fixture is normal team mode, not legacy random 1v1 retreat coverage")
	var button_name: String = "%BtnAttack" if mode == "victory" else ("%BtnDefend" if mode == "defeat" else "%BtnFlee")
	var action_button: Button = battle.get_node_or_null(button_name) as Button
	var presses: Array[bool] = []
	if action_button != null: action_button.pressed.connect(func(): presses.append(true))
	_check(action_button != null, "ordinary battle action control is available")
	var attempts := 0
	var accepted := 0
	var result_scene: Node
	var commands: Array[Dictionary] = []
	deadline = Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if bool(tree.root.get_node("LoadingManager").get("_transition_active")): continue
		# Immediate result-scene replacement has a genuine null frame.
		# It is not a failure or permission to fabricate an outcome.
		if not is_instance_valid(tree.current_scene): continue
		if tree.current_scene != battle:
			if mode == "victory" and tree.current_scene.scene_file_path.contains("victory"):
				result_scene = tree.current_scene
			elif mode == "defeat" and tree.current_scene.scene_file_path.contains("defeat"):
				result_scene = tree.current_scene
			elif mode == "flee" and tree.current_scene.scene_file_path in ["res://scenes/field.tscn", "res://scenes/field_walkable.tscn"]:
				result_scene = tree.current_scene
			break
		if not is_instance_valid(battle) or not is_instance_valid(action_button) or attempts >= 32: continue
		var modal: Control = battle.get("_flee_confirm_dialog") as Control
		var panel: Control = battle.get("action_panel") as Control
		if int(battle.get("_state")) != 1 or not action_button.is_visible_in_tree() or action_button.disabled: continue
		if modal != null and modal.is_visible_in_tree(): continue
		if panel == null or not panel.is_visible_in_tree(): continue
		_check(int(battle.get("_team_pending_skill_index")) == -1, "single-enemy fixture has no unhandled target-choice UI")
		if int(battle.get("_team_pending_skill_index")) != -1: break
		var pressed_before: int = presses.size()
		var pointer: Dictionary = await driver.call("pointer", action_button.get_global_rect().get_center())
		attempts += 1
		var received: bool = presses.size() == pressed_before + 1
		_check(received, "PLAYER_TURN actual " + mode + " button receives pressed signal")
		if not received: continue
		var confirmed := mode != "flee"
		if mode == "flee" and is_instance_valid(battle):
			modal = battle.get("_flee_confirm_dialog") as Control
			_check(modal != null and modal.is_visible_in_tree(), "real Flee opens ordinary blocking confirmation")
			if modal != null and modal.is_visible_in_tree():
				var confirm: Button = modal.get_node_or_null("%ConfirmAction") as Button
				var confirmation: Array[bool] = []
				_check(confirm != null, "actual modal confirmation control exists")
				if confirm != null:
					confirm.pressed.connect(func(): confirmation.append(true), CONNECT_ONE_SHOT)
					await driver.call("pointer", confirm.get_global_rect().get_center())
					confirmed = confirmation.size() == 1
					_check(confirmed, "actual modal receives confirmation input")
		var accepted_now: bool = confirmed and (not is_instance_valid(battle) or int(battle.get("_state")) != 1 or not outcomes.is_empty())
		_check(accepted_now, "ready command changes actual action state; INTRO clicks are not counted")
		if accepted_now: accepted += 1
		commands.append({"attempt": attempts, "pointer": pointer, "pressed": received, "confirmed": confirmed, "accepted": accepted_now})
		for settle in 6: await tree.process_frame
	var expected_won: bool = mode == "victory"
	var expected_fled: bool = mode == "flee"
	var outcome_ok := false
	for outcome: Dictionary in outcomes:
		if bool(outcome.won) == expected_won and bool(outcome.fled) == expected_fled: outcome_ok = true
	_check(outcome_ok and accepted > 0 and result_scene != null, "actual gameplay reaches declared " + mode + " outcome within finite budget")
	evidence["outcomes"] = outcomes.duplicate(true)
	evidence["commands"] = commands
	evidence.accepted_commands = accepted
	if result_scene != null and mode != "flee":
		var result: Dictionary = router.call("get_result_payload")
		_check(result.get("return_world_map_version", -1) == 15 and StringName(result.get("return_scene", "")) == definition.scene_id, "real result preserves version15/source ID")
		_check(_point(result.get("return_spawn")) == original, "real result keeps exact source return coordinate")
		var return_button: Button = result_scene.get_node_or_null("%BtnContinue" if mode == "victory" else "%BtnBack") as Button
		_check(return_button != null and return_button.is_visible_in_tree(), "actual result exposes its ordinary return button")
		if return_button != null: await driver.call("pointer", return_button.get_global_rect().get_center())
	if result_scene != null:
		var arrived: bool = await wait_field.call(definition.scene_id)
		_check(arrived, "normal result/action really returns to candidate v15")
		if arrived:
			await finish_intro.call()
			var returned: Node2D = tree.current_scene.get("_player") as Node2D
			_check(returned != null and returned.position.distance_to(original_px) < .03 and bool(clear_foot.call(returned.position)), "real " + mode + " resumes exact independent-full17 feet without second migration")
			_check((router.call("get_navigation_state") as Dictionary).get("world_map_version", -1) == 15, "actual resumed managed navigation remains15")
			evidence.returned = returned != null and returned.position.distance_to(original_px) < .03
			evidence["actual_end_px"] = [returned.position.x, returned.position.y] if returned != null else []
	if mode == "victory":
		_check(int(state.get("gold")) > gold_before and bool((state.get("flags") as Dictionary).get("defeated_thug_lone", false)), "ordinary victory effects and rewards remain enabled")
	else:
		_check(int(state.get("gold")) == gold_before and not bool((state.get("flags") as Dictionary).get("defeated_thug_lone", false)), "defeat/retreat never fabricates victory rewards")
	evidence["original_px"] = [original_px.x, original_px.y]
	bus.disconnect("battle_ended", observer)
	return evidence

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func release() -> void:
	tree = null
	driver = null
	report_check = Callable()
	wait_field = Callable()
	finish_intro = Callable()
	clear_foot = Callable()
