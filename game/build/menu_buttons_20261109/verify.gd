extends "res://build/inn_ui_cave_20261109/live.gd"

const OUTPUT := "res://build/menu_buttons_20261109/"
const BUTTON_ART := preload("res://scripts/ui/menu_button_art.gd")

func finish() -> void:
	print("MENU_ART ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)

func shot(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+id+".png")

func painted(button: Button, family: String) -> bool:
	for state_name in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style := button.get_theme_stylebox(state_name) as StyleBoxTexture
		if style == null or not style.texture.resource_path.ends_with("/"+family+".png"):
			return false
	return absf(button.size.aspect()-BUTTON_ART.aspect(family))<.13

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
	var field:=await enter(&"ch1_s1_road")
	if field==null:
		finish()
		return
	await settle(field)
	var hud: Control=field.get("_primary_hud")
	await key(KEY_ESCAPE)
	if not expect(await wait_for(func():return hud.is_right_menu_visible() and hud.get_node("BtnSystem").position.x<1671),"Esc reveals field menu"):
		finish()
		return
	var life := hud.get_node("BtnQuest/BtnLifeSkills") as TextureButton
	for path in ["BtnEquipment","BtnSkill","BtnQuest","BtnQuest/BtnLifeSkills","BtnSystem"]:
		var button := hud.get_node(path) as TextureButton
		expect(button.visible and button.texture_normal is AtlasTexture and button.texture_hover is AtlasTexture and button.texture_pressed is AtlasTexture and button.texture_disabled is AtlasTexture,"four HUD states "+path)
		expect(button.stretch_mode==TextureButton.STRETCH_KEEP_ASPECT_CENTERED and absf(button.size.aspect()-BUTTON_ART.aspect("hud"))<.015,"correct HUD ratio "+path)
	expect(not hud.get_node("BtnInventory").visible,"legacy inventory entry hidden")
	await shot("01_hud")
	await click(life)
	var journal: Control=root.get_node("LifeSkills").get("_journal")
	expect(is_instance_valid(journal) and journal.visible,"actual life skills click")
	await key(KEY_ESCAPE)
	await key(KEY_O)
	var layer: CanvasLayer=field.get("_system_ui_canvas_layer")
	var system := layer.get_node_or_null("SystemMenu") as Control if layer!=null else null
	if not expect(is_instance_valid(system) and system.visible,"O opens system"):
		finish()
		return
	for button: Button in [system.settings_btn,system.save_btn,system.load_btn]:
		expect(painted(button,"system"),"textured button states "+button.name)
	expect(system.settings_btn.button_pressed and system.settings_page.visible,"settings selected on opening")
	await shot("02_system")
	await click(system.save_btn)
	var slots: Control=system.get("_slot_panel")
	expect(slots.visible and slots.get("_mode")==0 and not system.settings_page.visible and system.save_btn.button_pressed,"save page from click")
	await process_frame
	for button: Button in [slots.get("_btn_confirm"),slots.get("_btn_cancel")]:
		expect(painted(button,"compact"),"textured slot action "+button.name+" "+str(button.size))
	await shot("03_save")
	await click(system.load_btn)
	expect(slots.visible and slots.get("_mode")==1 and system.load_btn.button_pressed,"load separated and directly reachable")
	expect(slots.get("_btn_confirm").disabled and slots.get("_slot_container").get_child(0).disabled,"empty slots disabled")
	await shot("04_load")
	await click(system.settings_btn)
	expect(not slots.visible and system.settings_page.visible and system.settings_btn.button_pressed,"settings returns from load")
	await key(KEY_O)
	expect(not system.visible and not field.get("_system_panel_open"),"O closes and restores gameplay")
	await key(KEY_C)
	var character: Control=field.get("_equipment_panel")
	if expect(is_instance_valid(character) and character.visible,"C opens character"):
		for id in ["_inventory_action_button","_inventory_drop_button"]:
			var button := character.get(id) as Button
			expect(button!=null and painted(button,"action"),"character action uses texture "+id)
		await shot("05_character")
		await key(KEY_C)
		expect(not character.visible,"C closes character")
	await key(KEY_I)
	expect(not character.visible and not field.get("_inventory_panel").visible,"I remains inactive")

	state.add_gold(100)
	router.go_shop(&"qingfeng_merchant")
	if expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn"),"shop consumer opens"):
		var shop:=current_scene
		var confirm:=shop.get_node("%ConfirmTradeButton") as Button
		expect(confirm.disabled and painted(confirm,"compact"),"trade confirm is textured, disabled until selection")
		var buy_list:=shop.get_node("%BuyList")
		for row in buy_list.get_children():
			var matches := row.find_children("*","Button",true,false)
			if matches.size()>=2:
				expect(painted(matches[0],"action") and painted(matches[1],"action"),"quantity buttons use textured states")
				await click(matches[1])
				expect(not confirm.disabled,"quantity click enables checkout")
				break
		await shot("06_trade")
		await click(confirm)
		expect(shop.get_node("%TradeConfirmOverlay").visible,"checkout opens confirmation")
		await click(shop.get_node("%CancelTradeButton"))
		expect(not shop.get_node("%TradeConfirmOverlay").visible and state.gold==100,"cancel returns without a trade")
	finish()

