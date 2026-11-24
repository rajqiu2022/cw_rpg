extends "res://build/inn_ui_cave_20261109/live.gd"

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
	await menu_checks()
	await overlap_checks()
	await traveler_checks()
	finish()

func menu_checks() -> void:
	var field:=await enter(VILLAGE)
	if field==null:return
	await settle(field)
	root.get_node("Inventory").add_item(&"healing_pill_minor",2)
	var bag: Control = field.get("_inventory_panel")
	var character: Control = field.get("_equipment_panel")
	await key(KEY_I)
	expect(not bag.visible and not character.visible,"I no longer opens backpack")
	await key(KEY_C)
	if not expect(character.visible,"C opens character and bag"):return
	await key(KEY_I)
	expect(character.visible and not bag.visible,"I does nothing with C panel open")
	var grid: GridContainer=character.get("_inventory_grid")
	for child in grid.get_children():
		if child is TextureButton and child.tooltip_text.contains("小还丹"):
			await click(child)
			break
	var use_button: Button=character.get("_inventory_action_button")
	var drop_button: Button=character.get("_inventory_drop_button")
	expect(use_button.text=="使用" and not use_button.disabled and drop_button.text=="丢弃","select potion shows both actions")
	for button in [use_button,drop_button]:
		var style:=button.get_theme_stylebox("normal") as StyleBoxFlat
		expect(style!=null and style.corner_radius_top_left==0,"action uses square style")
	await shot("recheck_character")
	await click(drop_button)
	var confirm: Control=character.get("_confirm_dialog")
	expect(confirm.visible,"drop still asks for confirmation")
	await key(KEY_ESCAPE)
	await key(KEY_C)
	await key(KEY_O)
	var layer: CanvasLayer=field.get("_system_ui_canvas_layer")
	var menu: Control=layer.get_node_or_null("SystemMenu")
	if not expect(menu!=null and menu.visible,"O opens system"):return
	var settings: Control=menu.get_node("%SettingsPage")
	var settings_btn: Button=menu.get_node("%SettingsBtn")
	var load_btn: Button=menu.get_node("%LoadBtn")
	var save_btn: Button=menu.get_node("%SaveBtn")
	await shot("recheck_settings")
	await click(load_btn)
	var slots: Control=menu.get("_slot_panel")
	expect(slots.visible and not settings.visible and settings_btn.is_visible_in_tree() and load_btn.button_pressed,"load shows right page and keeps settings link")
	await shot("recheck_load")
	await click(settings_btn)
	expect(settings.visible and not slots.visible and settings_btn.button_pressed,"mouse on Settings returns from load")
	await click(save_btn)
	expect(slots.visible and slots.get("_mode")==0,"save remains independent")
	await click(load_btn)
	expect(slots.visible and slots.get("_mode")==1,"can switch from save to load directly")
	await key(KEY_ESCAPE)
	expect(menu.visible and settings.visible and not slots.visible,"Escape returns from load to settings")
	await key(KEY_O)
	expect(not menu.visible,"O closes system")

func overlap_checks() -> void:
	var field:=await enter(&"linxi_village_center")
	if field==null:return
	await settle(field)
	var town: Node=field.get("native_town")
	var actor: Player=field.get("_player")
	if not expect(town!=null and "ghost" in town and town.ghost!=null,"native Linxi roof occluder"):return
	var overlay: Sprite2D=town.ghost.overlay
	var normal:=actor.sprite.get_node_or_null("LayeredNamedWeapon") as Sprite2D
	var translucent:=overlay.get_node_or_null("LayeredTownOverlap") as Sprite2D
	if not expect(normal!=null and translucent!=null,"same layered texture adopted by town overlay"):return
	var foot_before := actor.global_position
	var found := false
	for roof: Sprite2D in town.ghost.occluders:
		var parent: Node2D=roof.get_parent()
		if not roof.is_visible_in_tree() or roof.get_rect().size.length()<100.0:continue
		for delta in [Vector2(0,-100),Vector2(60,-95),Vector2(-60,-95),Vector2(105,-70),Vector2(-105,-70)]:
			await position_at(field,parent.global_position+delta)
			town.ghost.refresh()
			await process_frame
			await process_frame
			if overlay.visible and translucent.visible:
				found=true
				break
		if found:break
	if expect(found,"native roof overlap reproduced"):
		expect(not normal.visible and is_zero_approx(overlay.self_modulate.a) and translucent.texture==normal.texture,"exactly one layered render while covered")
		expect(translucent.global_transform.is_equal_approx(normal.global_transform),"same registered pose and transform")
		await shot("recheck_overlap")
	await position_at(field,foot_before)
	town.ghost.refresh()
	await process_frame
	await process_frame
	expect(normal.visible and not translucent.visible,"normal pose restored outside roof")


func traveler_checks() -> void:
	var field:=await enter(&"interior_inn_hall")
	if field==null:return
	await settle(field)
	var traveler: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="inn_guest_right":traveler=npc
	if not expect(traveler!=null and traveler.sprite.hframes==4,"traveler uses four-frame eating sheet"):return
	var foot:=traveler.global_position
	var cells: Dictionary={}
	var until_tick := Time.get_ticks_msec()+2000
	while Time.get_ticks_msec()<until_tick:
		cells[traveler.sprite.frame]=true
		await process_frame
	expect(cells.size()==4 and traveler.global_position==foot,"all four eating frames play on the same seat")
	var width: Vector2=field.get("_world_size")
	var table: Sprite2D
	for prop: Node in field.get("_scene_object_nodes"):
		if prop.name==&"SceneObject_right_table":table=prop
	expect(table!=null and absf(foot.x-table.global_position.x)/width.x<0.05,"traveler sits close to the dining table")
	await shot("recheck_eating")
	await position_at(field,foot+Vector2(32,45))
	await press_space()
	if expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"interior_inn_guest_chatter",1500),"traveler dialogue still reachable"):
		for _i in range(8):
			if not dialogue.is_playing():break
			dialogue.advance()
			await process_frame
		await create_timer(.5).timeout
		expect(traveler.sprite.hframes==4 and traveler.global_position==foot,"traveler resumes its registered animation after talking")

