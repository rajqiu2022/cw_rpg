extends "res://build/victory_quest_20261108/story_live.gd"
const OUT := "res://build/zhuwei_rebuild_20261109/"
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
	match OS.get_cmdline_user_args()[0]:
		"map": await zhuwei()
		"ui": await save_pages()
	finish()

func shot(key: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+key+".png")

func zhuwei() -> void:
	var field:=await enter(&"ch1_s2_qingfeng")
	if field==null:return
	var town: Node=field.get("native_town")
	var hero:=await position_at(field,Vector2(1050,1950))
	check_clear(hero,"inn front lane")
	expect(town.layout.objects.size()==45,"45 native props")
	for id in ["WestLaneHouse1","WestLaneHouse2","NorthLaneHouse","EastLaneHouse","SouthLaneHouse1","SouthLaneHouse2"]:
		expect(town.has_node("Town/"+id+"/Body/Shape"),"new structure and foundation "+id)
	await shot("zhuwei_inn_street")
	town.view_mode=0
	town.update_view()
	await shot("zhuwei_overview")
	town.view_mode=1
	field=await take(field,&"interior_inn_hall")
	if field!=null:
		var patrons: Dictionary={}
		for npc: NPCNode in field.get("_npc_nodes"):
			if npc.npc_id.begins_with("inn_guest_"):
				patrons[npc.npc_id]=npc
		if expect(patrons.size()==2,"two original guest identities"):
			var left: NPCNode=patrons["inn_guest_left"]
			var right: NPCNode=patrons["inn_guest_right"]
			expect(left.sprite.texture!=right.sprite.texture and right.sprite.texture.resource_path.ends_with("guest.png"),"different seated textures")
			expect(left.sprite.hframes==1 and right.sprite.hframes==1,"no directional frame flicker")
			await position_at(field,left.global_position+Vector2(42,95))
			await shot("inn_guest_left")
			await position_at(field,right.global_position+Vector2(-42,95))
			await shot("inn_guest_right")
		field=await take(field,&"ch1_s2_qingfeng")
		if field!=null:
			var returned: Player=field.get("_player")
			expect(returned.global_position.distance_to(Vector2(950,1838))<2.0,"original inn return foot")
	state.set_flag(&"chapter1_complete",true)
	field=await enter(&"ch2_s1_zhuwei_market")
	if field!=null:
		await settle(field)
		await position_at(field,Vector2(2200,2010))
		await shot("zhuwei_market")
		for pair in [[&"ch2_s1_market_inn",Vector2(950,1838)],[&"ch2_s1_market_training_hall",Vector2(3143.5,1698)]]:
			var gate:=zone_to(field,pair[0])
			if expect(gate!=null,"original ch2 gate "+String(pair[0])):
				expect(gate.global_position.distance_to(pair[1])<2.0,"original chapter 2 arrow")
		for id in ["huilan_zhuwei_echo","huilan_zhuwei_balance"]:
			expect(area(field,id)!=null,"existing quest hotspot "+id)

func click(button: BaseButton) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.position=button.get_global_rect().get_center()
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await create_timer(.17).timeout

func save_pages() -> void:
	var field:=await enter(&"linxi_village_center")
	if field==null:return
	var saves:=root.get_node("SaveManager")
	field.call("_open_system_menu")
	var menu: Control=field.get("_system_ui_canvas_layer").get_node("SystemMenu")
	await shot("system_menu")
	var panel: Control=menu.get("_slot_panel")
	await click(menu.save_btn)
	expect(panel.visible and not menu.panel.visible and panel.get("_mode")==0,"only save page opens")
	var list: VBoxContainer=panel.get("_slot_container")
	var confirm: Button=panel.get("_btn_confirm")
	expect(list.get_child_count()==5 and confirm.disabled,"one five-slot list requires explicit selection")
	await shot("save_page")
	await click(list.get_child(0))
	expect(not saves.has_save(0) and not confirm.disabled,"selection alone does not write")
	await click(confirm)
	expect(saves.has_save(0),"manual save writes only chosen isolated slot")
	var dialog: Control=panel.get("_formal_dialog")
	await click(dialog.get("_confirm_button"))
	await process_frame
	expect(menu.panel.visible and not panel.visible,"save completion returns to system menu")
	await click(menu.save_btn)
	await click(list.get_child(0))
	await click(confirm)
	expect(dialog.is_open() and panel.get("_pending_dialog_action")==&"overwrite","occupied save requests explicit overwrite")
	await click(dialog.get("_cancel_button"))
	await click(panel.get("_btn_cancel"))
	await click(menu.load_btn)
	expect(panel.visible and not menu.panel.visible and panel.get("_mode")==1,"only load page opens")
	expect(list.get_child(1).disabled and confirm.disabled,"empty load slot disabled")
	await shot("load_page")
	await click(list.get_child(0))
	await click(confirm)
	expect(dialog.is_open() and panel.get("_pending_dialog_action")==&"load","load warns before switching progress")
	await click(dialog.get("_cancel_button"))
	expect(panel.visible and panel.get("_pending_dialog_action")==&"","cancel read keeps the current scene")
	state.gold=987
	await click(confirm)
	await click(dialog.get("_confirm_button"))
	expect(await wait_for(func():return state.gold!=987,1800),"confirmed read restores the isolated save")
	expect(not saves.has_save(1),"other slots remain untouched")