extends SceneTree

const QUEST := &"q_legend_huilan_redirecting_art"
const ECHO := "huilan_zhuwei_echo"
const BALANCE := "huilan_zhuwei_balance"
const TRIAL := "huilan_zhuwei_trial"
var router: Node
var state: Node
var quests: Node
var dialogue: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func expect(ok: bool, label: String) -> bool:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL ",label)
	return ok

func wait_for(test: Callable, ms := 14000) -> bool:
	var end := Time.get_ticks_msec()+ms
	while Time.get_ticks_msec()<end:
		await process_frame
		if test.call(): return true
	return false

func enter(id: StringName) -> Node:
	var before:=current_scene.get_instance_id() if current_scene!=null else 0
	if not expect(router.go_field_smart(id),"router accepts "+String(id)): return null
	if not expect(await wait_for(func():
		var field:=current_scene
		return field!=null and field.get_instance_id()!=before and router.get_current_field_id()==id and field.has_method("get_field_loading_state") and field.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active")
	),"ready field "+String(id)): return null
	await physics_frame
	return current_scene

func area(field: Node, id: String) -> Area2D:
	if not is_instance_valid(field): return null
	for trigger: Area2D in field.get("_trigger_areas"):
		if is_instance_valid(trigger) and not trigger.is_queued_for_deletion() and trigger.get_meta("trigger_data",{}).get("id","")==id:
			return trigger
	return null

func press_space() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_SPACE
	event.physical_keycode=KEY_SPACE
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	var release:=event.duplicate() as InputEventKey
	release.pressed=false
	Input.parse_input_event(release)

func play_at(field: Node, id: String, expected: StringName, choices: Array[int]) -> bool:
	var trigger:=area(field,id)
	if not expect(trigger!=null,"spawned "+id): return false
	var player: Player=field.get("_player")
	player.global_position=trigger.global_position
	var town: Node=field.get("native_town")
	if town!=null:
		var terrain: Node=town.terrain
		terrain.reset_actor(terrain.level_at(player.position))
	var overlaps:=await wait_for(func():
		var current:=area(field,id)
		return current!=null and current.overlaps_body(player)
	,1800)
	trigger=area(field,id)
	var registry: Script=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	var clear: bool=registry.actor_shape_clear(player)
	if not expect(trigger!=null and clear and overlaps,"real foot and overlap %s foot=%s target=%s clear=%s overlap=%s" % [id,player.global_position,trigger.global_position if trigger!=null else Vector2.ZERO,clear,overlaps]): return false
	await press_space()
	if not expect(await wait_for(func(): return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==expected,2500),"Space opened "+id): return false
	for selected: int in choices:
		for i in range(12):
			if not dialogue.is_playing() or dialogue.get("_current_node").has_choices():break
			dialogue.advance()
		if not expect(dialogue.is_playing() and dialogue.get("_current_node").has_choices(),"puzzle choice "+id):return false
		dialogue.choose(selected)
	for i in range(12):
		if not dialogue.is_playing():break
		dialogue.advance()
	return expect(not dialogue.is_playing(),"dialogue closed "+id)

func finish() -> void:
	print("HUILAN_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	var field:=await enter(&"ch1_s2_qingfeng")
	if field==null:
		finish()
		return
	expect(area(field,ECHO)!=null and area(field,BALANCE)!=null,"two Zhuwei clue interactions on the actual field")
	expect(area(field,TRIAL)==null,"trial hidden before all five clues")
	if "baseline" in OS.get_cmdline_user_args():
		finish()
		return
	if not await play_at(field,ECHO,&"huilan_openworld_echo",[1]):
		finish()
		return
	expect(state.flags.get("huilan_echo_understood",false) and quests.is_active(QUEST),"correct echo starts the real quest")
	if not await play_at(field,BALANCE,&"huilan_openworld_balance",[1]):
		finish()
		return
	expect(state.flags.get("huilan_balance_understood",false) and not state.flags.get("huilan_openworld_clues_complete",false),"second clue does not skip other maps")
	for flag: StringName in [&"huilan_bell_counterforce_understood",&"huilan_yielding_position_understood",&"huilan_water_rule_understood"]:
		state.set_flag(flag,true)
	expect(await wait_for(func(): return area(field,TRIAL)!=null),"all five clues expose the trial without a map reload")
	if not await play_at(field,TRIAL,&"huilan_openworld_final_trial",[1,0]):
		finish()
		return
	expect(quests.is_completed(QUEST) and state.flags.get("huilan_openworld_trial_complete",false),"trial completes actual quest")
	expect(state.player.skills.has(&"huilan_redirecting_art") or state.pending_skill_unlocks.has(&"huilan_redirecting_art"),"reward is learned or queued by insight")
	expect(await wait_for(func(): return area(field,TRIAL)==null),"completed trial cannot repeat")
	field=await enter(&"ch2_s1_zhuwei_market")
	if field!=null:
		expect(area(field,ECHO)==null and area(field,BALANCE)==null and area(field,TRIAL)==null,"both village identities share progress")
		state.set_flag(&"huilan_balance_understood",false)
		expect(await wait_for(func(): return area(field,BALANCE)!=null),"second Zhuwei identity can expose unfinished clue")
		await play_at(field,BALANCE,&"huilan_openworld_balance",[1])
	finish()
