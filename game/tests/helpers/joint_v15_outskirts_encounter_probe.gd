extends RefCounted
## Real distance/chance Encounter only. Never calls start_encounter,
## _end_battle/go_victory or emits gameplay/result signals itself.
var tree: SceneTree
var driver: RefCounted
var report_check: Callable
var clear_foot: Callable
var clear_segment: Callable
var wait_field: Callable
var finish_intro: Callable

func configure(owner: SceneTree, input: RefCounted, check: Callable, independent_fullfoot: Callable, independent_segment: Callable, normal_field_wait: Callable, ordinary_intro: Callable) -> void:
	tree = owner
	driver = input
	report_check = check
	clear_foot = independent_fullfoot
	clear_segment = independent_segment
	wait_field = normal_field_wait
	finish_intro = ordinary_intro

func _check(ok: bool, label: String) -> void:
	if report_check.is_valid(): report_check.call(ok, label)

func run(field: Node, route: PackedVector2Array, random_seed: int) -> Dictionary:
	var evidence: Dictionary = {"scope": "NATURAL_ENCOUNTER_REAL_INPUT_VICTORY_RETURN", "seed": random_seed, "battle_entered": false, "returned": false, "movement": [], "commands": []}
	_check(is_instance_valid(field) and tree.current_scene == field, "Encounter probe starts at current ordinary Field")
	if not is_instance_valid(field): return evidence
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var player: Node2D = field.get("_player") as Node2D
	var size: Vector2 = field.get("_world_size")
	_check(definition != null and not definition.is_settlement and definition.encounter_step_distance > 0 and definition.encounter_chance > 0, "ordinary authored distance/chance Encounter remains enabled")
	_check(route.size() >= 2 and player != null, "natural encounter has actual independently legal movement path")
	if definition == null or player == null or definition.is_settlement or definition.encounter_step_distance <= 0 or definition.encounter_chance <= 0 or route.size() < 2: return evidence
	if not String(definition.encounter_require_flag).is_empty():
		_check(bool((tree.root.get_node("GameState").get("flags") as Dictionary).get(definition.encounter_require_flag, false)), "ordinary encounter requirement is already earned by fixture, not stripped")
	for index in range(1, route.size()):
		_check(bool((clear_segment.call(route[index - 1], route[index]) as Dictionary).get("clear", false)), "Encounter travel path includes every <=4px/full17 intermediate centre")
	seed(random_seed)
	var router: Node = tree.root.get_node("SceneRouter")
	var expected_version: int = (router.call("get_navigation_state") as Dictionary).get("world_map_version", -1)
	var original: Vector2 = Vector2(INF, INF)
	var movements: Array[Dictionary] = []
	var locked := false
	# Ordinary encounter probability is not changed to guarantee a result.
	# A finite eight laps failing to encounter is a genuine FAIL with seed/path.
	for lap in 8:
		for index in route.size():
			if not is_instance_valid(player) or tree.current_scene != field: break
			var target: Vector2 = route[index]
			var budget: int = maxi(120, ceili(player.position.distance_to(target) / 2) + 180)
			for tick in budget:
				if not is_instance_valid(player) or tree.current_scene != field: break
				if bool(field.get("_encounter_locked")):
					original = player.position / size
					locked = true
					break
				var delta: Vector2 = target - player.position
				if delta.length() <= .3: break
				driver.call("release_movement")
				var deadzone := 0.0
				for action: String in ["move_right", "move_left", "move_down", "move_up"]: deadzone += InputMap.action_get_deadzone(action) * .25
				var amount: float = deadzone + (1 - deadzone) * minf(1, delta.length() / (480.0 / Engine.physics_ticks_per_second))
				var direction: Vector2 = delta.normalized()
				Input.action_press("move_right", maxf(direction.x, 0) * amount)
				Input.action_press("move_left", maxf(-direction.x, 0) * amount)
				Input.action_press("move_down", maxf(direction.y, 0) * amount)
				Input.action_press("move_up", maxf(-direction.y, 0) * amount)
				await tree.physics_frame
				if is_instance_valid(player):
					_check(bool(clear_foot.call(player.position)), "natural encounter movement retains independently complete feet at every physics sample")
					movements.append({"lap": lap, "segment": index, "point_px": [player.position.x, player.position.y]})
			driver.call("release_movement")
			if locked or not is_instance_valid(player) or tree.current_scene != field: break
		if locked or not is_instance_valid(player) or tree.current_scene != field: break
	driver.call("release_movement")
	_check(locked and original.is_finite() and bool(clear_foot.call(original * size)), "actual ordinary movement naturally locks Encounter on a legal observed original foot")
	evidence.movement = movements
	if not locked or not original.is_finite(): return evidence
	var deadline: int = Time.get_ticks_msec() + 30000
	var battle: Node
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if bool(tree.root.get_node("LoadingManager").get("_transition_active")): continue
		if is_instance_valid(tree.current_scene) and tree.current_scene.get_node_or_null("%BtnAttack") != null:
			battle = tree.current_scene
			break
	_check(is_instance_valid(battle), "authored Encounter itself starts actual ordinary Battle")
	if not is_instance_valid(battle): return evidence
	evidence.battle_entered = true
	var payload: Dictionary = router.call("get_battle_payload")
	_check(StringName(payload.get("return_scene", "")) == definition.scene_id and int(payload.get("return_world_map_version", -1)) == expected_version, "natural Encounter payload retains source ordinary field and world-side version")
	_check(_point(payload.get("return_spawn")) == original, "natural Encounter return point equals independently observed locked feet")
	var state: Node = tree.root.get_node("GameState")
	var gold_before: int = state.get("gold")
	var events: Array[Dictionary] = []
	var bus: Node = tree.root.get_node("EventBus")
	var listener: Callable = func(won: bool, fled: bool): events.append({"won": won, "fled": fled})
	bus.connect("battle_ended", listener)
	var attacks: Array[bool] = []
	var attack: Button = battle.get_node("%BtnAttack") as Button
	attack.pressed.connect(func(): attacks.append(true))
	var accepted := 0
	var commands: Array[Dictionary] = []
	var victory: Node
	deadline = Time.get_ticks_msec() + 150000
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if bool(tree.root.get_node("LoadingManager").get("_transition_active")) or not is_instance_valid(tree.current_scene): continue
		if tree.current_scene != battle:
			if tree.current_scene.scene_file_path.contains("victory"): victory = tree.current_scene
			break
		if accepted >= 64 or not is_instance_valid(attack) or int(battle.get("_state")) != 1: continue
		var panel: Control = battle.get("action_panel") as Control
		var pending: int = battle.get("_team_pending_skill_index")
		if pending >= 0:
			# Actual multi-target selection is ordinary UI, not forced_target.
			var formation: Node = battle.get("formation_view") as Node
			var buttons: Array = formation.get("target_buttons") if formation != null else []
			var target: Button
			for candidate: Button in buttons:
				if candidate.is_visible_in_tree() and not candidate.disabled:
					target = candidate
					break
			_check(target != null, "ordinary multi-enemy Attack has actual selectable target UI")
			if target == null: break
			var received: Array[bool] = []
			target.pressed.connect(func(): received.append(true), CONNECT_ONE_SHOT)
			await driver.call("pointer", target.get_global_rect().get_center())
			_check(received.size() == 1, "real target choice receives actual pressed signal")
			var target_accepted: bool = received.size() == 1 and (not is_instance_valid(battle) or (int(battle.get("_team_pending_skill_index")) == -1 and int(battle.get("_state")) != 1))
			_check(target_accepted, "ordinary target choice actually consumes pending selection and begins action")
			if target_accepted: accepted += 1
			commands.append({"kind": "target", "received": received.size() == 1, "accepted": target_accepted})
			continue
		if panel == null or not panel.is_visible_in_tree() or not attack.is_visible_in_tree() or attack.disabled: continue
		var before: int = attacks.size()
		await driver.call("pointer", attack.get_global_rect().get_center())
		var received: bool = attacks.size() == before + 1
		_check(received, "natural encounter PLAYER_TURN Attack receives real input")
		var needs_target: bool = is_instance_valid(battle) and int(battle.get("_team_pending_skill_index")) >= 0
		var accepted_now: bool = received and (not is_instance_valid(battle) or int(battle.get("_state")) != 1 or needs_target)
		_check(accepted_now, "Attack is genuinely accepted rather than INTRO/modal button spam")
		if accepted_now and not needs_target: accepted += 1
		commands.append({"kind": "attack", "received": received, "needs_target": needs_target, "accepted": accepted_now})
		for settle in 6: await tree.process_frame
	var won := false
	for event: Dictionary in events:
		if bool(event.won) and not bool(event.fled): won = true
	_check(victory != null and won and accepted > 0, "normal Encounter is genuinely won with enabled battle/reward logic")
	evidence.commands = commands
	evidence["actual_outcomes"] = events.duplicate(true)
	evidence["actual_battle_payload"] = payload.duplicate(true)
	if victory != null:
		var result: Dictionary = router.call("get_result_payload")
		_check(StringName(result.get("return_scene", "")) == definition.scene_id and int(result.get("return_world_map_version", -1)) == expected_version, "actual victory result preserves ordinary source/version")
		_check(int(result.get("gold", 0)) > 0 or int(result.get("exp", 0)) > 0, "real Encounter yields authored rewards, not empty fabricated success")
		_check(int(state.get("gold")) >= gold_before, "ordinary victory does not lose pre-result gold")
		var button: Button = victory.get_node_or_null("%BtnContinue") as Button
		_check(button != null, "real victory exposes normal Continue UI")
		if button != null: await driver.call("pointer", button.get_global_rect().get_center())
		var arrived: bool = await wait_field.call(definition.scene_id)
		_check(arrived, "real Victory Continue returns to the same new ordinary ecology field")
		if arrived:
			await finish_intro.call()
			var actor: Node2D = tree.current_scene.get("_player") as Node2D
			_check(actor != null and actor.position.distance_to(original * size) < .03 and bool(clear_foot.call(actor.position)), "normal battle resumes exact original complete feet without doorway snap")
			evidence.returned = actor != null and actor.position.distance_to(original * size) < .03
			evidence["actual_return_px"] = [actor.position.x, actor.position.y] if actor != null else []
			evidence["result_payload"] = result.duplicate(true)
	bus.disconnect("battle_ended", listener)
	evidence["original_lock_px"] = [original.x * size.x, original.y * size.y]
	return evidence

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func release() -> void:
	tree = null
	driver = null
	report_check = Callable()
	clear_foot = Callable()
	clear_segment = Callable()
	wait_field = Callable()
	finish_intro = Callable()
