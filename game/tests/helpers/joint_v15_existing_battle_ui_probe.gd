extends RefCounted
## Handles ONLY a battle already entered by ordinary entity/dialog input.
## Never starts an encounter, emits an outcome, edits an enemy or jumps to results.
var tree: SceneTree
var driver: RefCounted
var check: Callable

func configure(owner: SceneTree, actual_driver: RefCounted, checker: Callable) -> void:
	tree=owner
	driver=actual_driver
	check=checker

func victory(expected_source: String, expected_foot: Vector2, expected_local_version: int, expected_size: Vector2=Vector2(3072,2048)) -> Dictionary:
	var result: Dictionary={"scope":"EXISTING_NORMAL_ACTION_BATTLE_UI","entered":false,"won":false,"returned":false,"commands":[]}
	var router: Node=tree.root.get_node("SceneRouter")
	var bus: Node=tree.root.get_node("EventBus")
	var outcomes: Array[Dictionary]=[]
	var outcome_observer: Callable=func(won: bool,fled: bool): outcomes.append({"won":won,"fled":fled})
	bus.connect("battle_ended",outcome_observer)
	var battle: Node
	var deadline: int=Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		if is_instance_valid(tree.current_scene) and tree.current_scene.get_node_or_null("%BtnAttack")!=null:
			battle=tree.current_scene
			break
	check.call(is_instance_valid(battle),"normal entity/dialog action really enters production Battle")
	if not is_instance_valid(battle):
		bus.disconnect("battle_ended",outcome_observer)
		return result
	result.entered=true
	var payload: Dictionary=router.call("get_battle_payload")
	check.call(String(payload.get("return_scene",""))==expected_source,"real action battle carries exact source scene")
	check.call(payload.get("return_spawn") is Vector2 and (payload.return_spawn as Vector2).distance_to(expected_foot/expected_size)<.00001,"real action battle preserves pre-action ordinary feet in its actual source domain")
	check.call(int(payload.get("return_local_layout_version",-1))==expected_local_version,"real city action battle carries local layout version")
	result["original_payload"]=payload.duplicate(true)
	var commands: Array[Dictionary]=[]
	deadline=Time.get_ticks_msec()+180000
	var result_scene: Node
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		if not is_instance_valid(tree.current_scene): continue
		if tree.current_scene!=battle:
			if tree.current_scene.scene_file_path.contains("victory"): result_scene=tree.current_scene
			break
		if not is_instance_valid(battle) or int(battle.get("_state"))!=1: continue
		var modal: Control=battle.get("_flee_confirm_dialog") as Control
		if modal!=null and modal.is_visible_in_tree():
			check.call(false,"unexpected Flee modal; no UI bypass")
			break
		var panel: Control=battle.get("action_panel") as Control
		var formation: Node=battle.get("formation_view") as Node
		var targets: Array=formation.get("target_buttons") if formation!=null and formation.get("target_buttons") is Array else []
		if int(battle.get("_team_pending_skill_index"))>=0:
			var selected: bool=false
			for target: Variant in targets:
				if target is Button and target.is_visible_in_tree() and not target.disabled:
					var presses: Array[bool]=[]
					target.pressed.connect(func(): presses.append(true),CONNECT_ONE_SHOT)
					var pointer: Dictionary=await driver.call("pointer",target.get_global_rect().get_center())
					selected=presses.size()==1
					commands.append({"kind":"normal_target","pressed":selected,"pointer":pointer})
					break
			check.call(selected,"ordinary multi-enemy target selection receives genuine input")
			if not selected: break
			continue
		if panel==null or not panel.is_visible_in_tree() or commands.size()>=96: continue
		var button: Button=battle.get_node_or_null("%BtnAttack") as Button
		if button==null or not button.is_visible_in_tree() or button.disabled: continue
		var presses: Array[bool]=[]
		button.pressed.connect(func(): presses.append(true),CONNECT_ONE_SHOT)
		var pointer: Dictionary=await driver.call("pointer",button.get_global_rect().get_center())
		var accepted: bool=presses.size()==1 and (not is_instance_valid(battle) or int(battle.get("_state"))!=1 or int(battle.get("_team_pending_skill_index"))>=0 or not outcomes.is_empty())
		check.call(accepted,"PLAYER_TURN normal attack accepted; INTRO clicks never count")
		commands.append({"kind":"normal_attack","pressed":presses.size()==1,"accepted":accepted,"pointer":pointer})
		for tick in 6: await tree.process_frame
	var won: bool=false
	for outcome: Dictionary in outcomes:
		if bool(outcome.won) and not bool(outcome.fled): won=true
	check.call(won and is_instance_valid(result_scene),"actual gameplay reaches Victory, not fabricated payload")
	result.won=won
	result.commands=commands
	result["outcomes"]=outcomes.duplicate(true)
	if is_instance_valid(result_scene):
		var actual_result: Dictionary=router.call("get_result_payload")
		check.call(String(actual_result.get("return_scene",""))==expected_source and int(actual_result.get("return_local_layout_version",-1))==expected_local_version,"actual Victory preserves original city/local version")
		result["actual_result_payload"]=actual_result.duplicate(true)
		var button: Button=result_scene.get_node_or_null("%BtnContinue") as Button
		check.call(button!=null and button.is_visible_in_tree(),"normal Victory return button exists")
		if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
		deadline=Time.get_ticks_msec()+30000
		while Time.get_ticks_msec()<deadline:
			await tree.process_frame
			if not is_instance_valid(tree.current_scene) or not tree.current_scene.get("_current_scene") is SceneScript: continue
			var definition: SceneScript=tree.current_scene.get("_current_scene") as SceneScript
			if String(definition.scene_id)==expected_source:
				var player: Node2D=tree.current_scene.get("_player") as Node2D
				if player!=null:
					result.returned=player.position.distance_to(expected_foot)<.03
					result["actual_return_foot_px"]=[player.position.x,player.position.y]
				break
		check.call(bool(result.returned),"normal result button returns to exact pre-action feet")
	bus.disconnect("battle_ended",outcome_observer)
	return result

func release() -> void:
	tree=null
	driver=null
	check=Callable()
