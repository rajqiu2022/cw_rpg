extends "res://build/quest_warrants_20261110/live.gd"

var bounty: Node
var bag: Node

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	bounty=root.get_node("BountyManager")
	bag=root.get_node("Inventory")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	bounty.reset_for_new_game()
	var board_id := &"redrock" if "redrock" in OS.get_cmdline_user_args() else &"qinghe"
	await county_run(board_id)
	finish()

func county_run(board_id: StringName) -> void:
	var county: Dictionary = bounty.COUNTY_BOARDS[board_id]
	var county_field := await enter(county.scene)
	if county_field==null:return
	await settle(county_field)
	var notice := (county_field.get("world_container") as Node2D).get_node_or_null("CountyBountyNotice") as Node2D
	if not expect(notice!=null,"county board object exists "+String(board_id)):return
	var actor := await position_at(county_field,notice.global_position+Vector2(0,105))
	var registry: Script = load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	if not expect(registry.actor_shape_clear(actor),"walkable board approach"):return
	var foot: Vector2 = actor.global_position
	if board_id==&"qinghe":
		county_field.call("_update_actor_depth",actor)
	await snapshot("county-field-"+String(board_id))
	await press_space()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/bounty_board.tscn"),"Space opens county list"):return
	var board := current_scene
	var cards := board.get_node("BountyEntries")
	if not expect(cards.get_child_count()==2,"two separate county cases"):return
	expect(board.get_node("BoardTitle").text==county.name and board.get_node("BoardHint").text.contains(bounty.office_label_for_board(board_id)),"board explicitly names city office")
	await snapshot("county-list-"+String(board_id))
	var card: Node = cards.get_child(1 if "second" in OS.get_cmdline_user_args() else 0)
	var id := StringName(String(card.name).trim_prefix("BountyEntry_"))
	var def: BountyDef = bounty.get_definition(id)
	card.get_node("Content/AcceptButton").pressed.emit()
	if not expect(def!=null and def.board_city==board_id and bounty._state_for(id).status==&"active","clicked a real county case"):return
	board.get_node("CloseButton").pressed.emit()
	if not expect(await wait_for(func():
		return current_scene!=null and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active")
	,20000),"board closes to county"):return
	expect(router.get_current_field_id()==county.scene and current_scene.get("_player").global_position.distance_to(foot)<3,"same approach foot after closing board")
	expect(not bounty.start_bounty(StringName("warrant_office_"+String(county.office))),"county cannot file")
	var location: Dictionary = def.locations[bounty._state_for(id).location_index]
	print("COUNTY_CASE ",id," ",location.label)
	var field := await enter(location.scene_id)
	if field==null:return
	await settle(field)
	var target: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.npc_id=="bounty_"+String(id):target=npc
	if not expect(is_instance_valid(target),"genuine county target spawned "+String(id)+" at "+String(location.label)):return
	actor=await approach_officer(field,target)
	if not expect(actor!=null,"target has safe approach"):return
	state.player.skills.assign([&"basic_attack"])
	state.player.speed=1000
	state.player.agility=180
	var gold: int = state.gold
	var reputation: int = state.reputation
	await press_space()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,23000),"Space starts actual county hunt"):return
	var battle := current_scene
	var enemy: BattleCombatant=battle.get("_team_enemies")[0]
	enemy.stats.hp=1
	var active: BattleCombatant=battle.get("_team_active_unit")
	var skills: Array=battle._skills_for_stats(active.stats)
	var skill:=0
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack": skill=i
	var ref: WeakRef=weakref(battle)
	for attempt in range(5):
		if not is_instance_valid(battle) or current_scene!=battle or not enemy.alive: break
		if battle.get("_state")==1:battle._team_player_action_skill_use(skill,enemy.unit_id)
		await wait_for(func():
			var current: Node=ref.get_ref()
			return current_scene!=null and (current_scene!=current or (current!=null and current.get("_state")==1))
		,6500)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",26000),"real victory"):return
	var proof: StringName = bounty._evidence_id(id)
	expect(bag.count_of(proof)==1 and bounty._state_for(id).status==&"evidence","proof held after combat")
	expect(bag.count_of(bounty.FIELD_LOOT[id])>=1,"equipment dropped")
	expect(state.gold==gold and state.reputation==reputation,"no early reward")
	expect(String(router.get_result_payload().bounty_result.summary).contains(bounty.office_label_for_board(board_id)),"victory directs to assigned prefecture")
	bounty.from_dict(JSON.parse_string(JSON.stringify(bounty.to_dict())))
	var wrong_office := &"jinling"
	await visit_office(wrong_office,bounty.office_label_for_board(board_id))
	expect(bag.count_of(proof)==1 and state.gold==gold and bounty._state_for(id).status==&"evidence","wrong province cannot take proof or pay reward")
	await visit_office(county.office)
	expect(bag.count_of(proof)==0 and bounty._state_for(id).status==&"captured","correct prefecture consumes proof")
	expect(state.gold==gold+def.reward_gold and state.reputation==reputation+def.reward_reputation,"correct gold and renown")
	bounty._file_city_cases(county.office)
	expect(state.gold==gold+def.reward_gold,"cannot double claim")

func visit_office(city: StringName, expected_redirect: String = "") -> void:
	await wait_for(func():return not root.get_node("LoadingManager").get("_transition_active"))
	var field := await enter(bounty.OFFICES[city][0])
	if field==null:return
	await settle(field)
	for npc: NPCNode in field.get("_npc_nodes"):
		if not is_instance_valid(npc) or npc.npc_id!="warrant_office_"+String(city): continue
		if not expect(await approach_officer(field,npc)!=null,"approach "+String(city)):return
		await press_space()
		await process_frame
		expect(dialogue.is_playing() and String(dialogue.get("_current_script").dialog_id)=="warrant_report_"+String(city),"real Space at "+String(city)+" office")
		if not expected_redirect.is_empty() and dialogue.is_playing():
			var script: DialogScript = dialogue.get("_current_script")
			expect(script.find_node_by_id(&"reply").text.contains(expected_redirect),"wrong office names the correct destination")
		await settle(field)
		return
	expect(false,"office missing "+String(city))

func snapshot(name: String) -> void:
	if not "visual" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://"+name+".png")
