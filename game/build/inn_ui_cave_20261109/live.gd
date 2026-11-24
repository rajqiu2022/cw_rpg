extends "res://build/victory_quest_20261108/story_live.gd"

const CAVE := &"interior_bandit_cave"
const CASE := &"q_ch1_side_10_bandit_cave"
const MAIN := &"q_ch1_main_village_inquiry"
const VILLAGE := &"ch1_s2_qingfeng"

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
	for stage in OS.get_cmdline_user_args():
		match stage:
			"ui": await ui()
			"inn": await inn()
			"cave": await cave()
			"shop": await shop()
	finish()

func finish() -> void:
	print("INN_UI_CAVE_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/inn_ui_cave_20261109/"+name+".png")

func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	var release:=event.duplicate() as InputEventKey
	release.pressed=false
	Input.parse_input_event(release)
	await process_frame

func click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release,true)
	await process_frame

func ui() -> void:
	quests.accept(MAIN)
	var field:=await enter(VILLAGE)
	if field==null:return
	await settle(field)
	var inventory: Control=field.get("_inventory_panel")
	await key(KEY_I)
	expect(inventory.visible,"I opens inventory")
	await key(KEY_I)
	expect(not inventory.visible,"I closes inventory")
	await key(KEY_O)
	var layer: CanvasLayer=field.get("_system_ui_canvas_layer")
	var system := layer.get_node_or_null("SystemMenu") as Control
	if not expect(system!=null and system.visible,"O opens system"):return
	expect(not system.has_node("Dim") and not system.has_node("Panel/PlainSurface"),"system has no old masks")
	await shot("01_system")
	await click(system.get_node("%SaveBtn"))
	var slots: Control=system.get("_slot_panel")
	expect(slots.visible and not system.get_node("%Panel").visible and slots.get("_mode")==0,"save page opens separately")
	await shot("02_save")
	await key(KEY_ESCAPE)
	expect(not slots.visible and system.get_node("%Panel").visible,"escape returns to system")
	await click(system.get_node("%LoadBtn"))
	expect(slots.visible and slots.get("_mode")==1 and slots.get("_btn_confirm").disabled,"load page opens separately and nothing preselected")
	expect(slots.get("_slot_container").get_child(0).disabled,"empty slots cannot load")
	await shot("03_load")
	await key(KEY_O)
	expect(not system.visible and not field.get("_system_panel_open"),"O closes the system from slot page")
	await key(KEY_J)
	var quest: Control=field.get("_quest_panel_full")
	var track: BaseButton=quest.find_child("ViewMainTarget",true,false)
	if expect(track!=null and await wait_for(func():return track.is_visible_in_tree(),3000),"main quest has working tracking button"):
		await shot("04_tracking")
		await click(track)
		expect(not quest.visible and not field.get("_system_panel_open"),"main quest click returns to map tracking")
		var hud: Control=field.get("_primary_hud")
		expect(hud.get_node("QuestSummaryPanel/QuestSummary").text.contains("村中异闻"),"HUD shows tracked main quest")
	quests.accept(CASE)
	await key(KEY_J)
	await click(quest.get_node("%PrimarySide"))
	var side_button := quest.get_node("%TrackBtn") as TextureButton
	expect(await wait_for(func():return side_button.visible and not side_button.disabled,2200),"side quest tracker stays actionable")
	await click(side_button)
	expect(quests.tracked_side_quest_id==&"","click cancels the tracked side quest")
	await click(side_button)
	expect(quests.tracked_side_quest_id==CASE,"click tracks the side quest again")
	await key(KEY_J)
	await key(KEY_ESCAPE)
	await create_timer(.33).timeout
	var hud: Control=field.get("_primary_hud")
	var life := hud.get_node_or_null("BtnQuest/BtnLifeSkills") as Button
	expect(life!=null and hud.is_right_menu_visible(),"six compact HUD buttons with life entry")
	expect(root.get_node("LifeSkills").find_child("MedicineRecipes",true,false)==null,"old lower-left medicine button gone")
	await shot("05_hud")
	if life==null:return
	await click(life)
	var journal: Control=root.get_node("LifeSkills").get("_journal")
	if not expect(is_instance_valid(journal) and journal.visible,"life skills opens from real mouse click"):return
	await shot("06_life")
	await click(journal.find_child("Smithing",true,false))
	expect(not journal.find_child("OpenMedicine",true,false).visible,"smithing only shows station information")
	await click(journal.find_child("Medicine",true,false))
	await click(journal.find_child("OpenMedicine",true,false))
	expect(is_instance_valid(root.get_node("LifeSkills").get("_panel")),"medicine uses existing recipe panel")
	await key(KEY_ESCAPE)
	expect(not field.get("_system_panel_open"),"closing recipes restores walking")

func inn() -> void:
	var outside:=await enter(VILLAGE)
	if outside==null:return
	var field:=await take(outside,&"interior_inn_hall")
	if field==null:return
	var sprites: Array=field.get("_scene_object_nodes")
	for id in ["left_table","right_table","east_tea_table","west_tea_table","cookline"]:
		expect(sprites.any(func(n):return String(n.name)=="SceneObject_"+id),"inn object "+id)
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id in ["inn_guest_left","inn_guest_right"]:
			expect(npc.sprite.texture.resource_path.contains("qingfeng_inn_20261109"),"new seated pose "+npc.npc_id)
	await shot("07_inn")
	await take(field,VILLAGE)

func cave() -> void:
	state.set_flag(&"master_training_done",true)
	state.set_flag(&"defeated_bandit_mountain",true)
	state.set_flag(&"rumour_bandit_cave",true)
	quests.accept(CASE)
	var road:=await enter(&"ch1_s1_road")
	if road==null:return
	var field:=await take(road,CAVE)
	if field==null:return
	expect(area(field,"bandit_cave_banner")==null,"road victory does not unlock cave goods")
	var guard: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="bandit_cave_guard":guard=npc
	if not expect(is_instance_valid(guard),"actual cave guard present"):return
	await shot("08_cave")
	var actor:=await position_at(field,guard.global_position+Vector2(0,47))
	check_clear(actor,"guard approach")
	var foot:=actor.global_position
	state.player.speed=1000
	state.player.agility=180
	await press_space()
	if not expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"interior_bandit_cave_guard",3500),"guard conversation opens with Space"):return
	for _i in range(4):
		if not dialogue.is_playing() or dialogue.get("_current_node").has_choices():break
		dialogue.advance()
		await process_frame
	expect(dialogue.is_playing() and dialogue.get("_current_node").has_choices(),"guard offers explicit choice")
	dialogue.choose(1)
	expect(await wait_for(func():return not dialogue.is_playing() and current_scene==field,1600),"declining challenge leaves the party in cave")
	await create_timer(.2).timeout
	await press_space()
	if not await wait_for(func():return dialogue.is_playing(),2000):return
	for _i in range(4):
		if not dialogue.is_playing() or dialogue.get("_current_node").has_choices():break
		dialogue.advance()
		await process_frame
	dialogue.choose(0)
	await process_frame
	dialogue.advance()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1),"real cave fight"):return
	var battle:=current_scene
	var units: Array=battle.get("_team_enemies")
	if not expect(units.size()==1,"one cave guard in battle"):return
	units[0].stats.hp=1
	var acting: BattleCombatant=battle._team_active_unit
	var skills: Array=battle._skills_for_stats(acting.stats)
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack":
			battle._team_player_action_skill_use(i,units[0].unit_id)
			break
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",16000),"genuine battle victory screen"):return
	current_scene.get_node("%BtnContinue").pressed.emit()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.has_method("get_field_loading_state") and router.get_current_field_id()==CAVE and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active"),16000),"victory returns to cave"):return
	field=current_scene
	actor=field.get("_player")
	expect(actor.global_position.distance_to(foot)<1.0,"victory restores encounter feet")
	expect(state.flags.get("defeated_bandit_cave_guard",false),"cave-specific win flag")
	await settle(field)
	var again := false
	for npc: NPCNode in field.get("_npc_nodes"):
		again = again or npc.npc_id=="bandit_cave_guard"
	expect(not again,"no repeat story battle")
	var crate:=area(field,"bandit_cave_banner")
	if crate!=null:
		await position_at(field,crate.global_position)
		expect(await wait_for(func():
			var current := area(field,"bandit_cave_banner")
			if not is_instance_valid(current):return false
			var marker := current.get_node_or_null("EvidencePrompt") as Label
			return marker!=null and marker.visible
		,1800),"evidence shows the contextual prompt at the reachable foot")
		await shot("09_cave_evidence")
	await play_at(field,"bandit_cave_banner",&"interior_bandit_cave_banner",[])
	expect(state.flags.get("clue_bandit_cave_mist_mark",false) and quests.is_completed(CASE),"crate evidence completes the actual quest")
	await take(field,&"ch1_s1_road")

func shop() -> void:
	var field:=await enter(VILLAGE)
	if field==null:return
	await settle(field)
	router.go_shop(&"qingfeng_merchant")
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn"),"trade UI opens"):return
	var confirm:=current_scene.get_node("%ConfirmTradeButton") as Button
	expect(confirm.disabled and confirm.get_theme_stylebox("normal") is StyleBoxFlat,"blue steel square-corner trade button and disabled state")
	await shot("10_shop")

