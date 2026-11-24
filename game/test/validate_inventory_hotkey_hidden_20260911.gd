extends SceneTree

## Targeted HUD/input regression. The 2026-09-12 product decision supersedes
## the earlier hidden-button/active-hotkey contract: I is now fully disabled.
## Deliberately never instantiates SystemMenu
## (its _ready enumerates user save slots), and never calls SaveManager.
var checks := 0
var failed := 0

func _init() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[HiddenInventoryHotkey] " + label)

func run() -> void:
	root.get_node("GameState").reset_for_new_game()
	root.get_node("Inventory").reset_for_new_game()
	await check_hud()
	await check_field("res://scenes/field.tscn",false)
	await check_field("res://scenes/field_walkable.tscn",true)
	# Full scene setup starts real BGM. Stop it before the headless process exits
	# so an active AudioStreamPlaybackWAV does not create a misleading leak error.
	await root.get_node("AudioManager").stop_bgm(0.0)
	root.get_node("AudioManager").stop_all_sfx()
	root.get_node("AudioManager").stop_dialog_audio()
	await create_timer(0.15).timeout
	print("[HiddenInventoryHotkey] checks=%d failed=%d; real viewport InputEventKey dispatch, no save-slot access" % [checks,failed])
	quit(1 if failed else 0)

func assert_menu_buttons(hud: Control, context: String) -> void:
	check(not hud.get_node("BtnInventory").visible,context+": inventory entry remains hidden")
	for name in ["BtnEquipment","BtnSkill","BtnQuest","BtnSystem"]:
		check(hud.get_node(name).visible,context+": unrelated entry remains enabled for display: "+name)

func check_hud() -> void:
	var hud: Control = load("res://scenes/ui/field_primary_hud.tscn").instantiate()
	check(not hud.get_node("BtnInventory").visible,"HUD packed-scene initial visibility")
	root.add_child(hud)
	await process_frame
	assert_menu_buttons(hud,"HUD ready")
	for i in 3:
		hud.toggle_right_menu()
		await create_timer(0.25).timeout
		check(hud.is_right_menu_visible(),"HUD toggle opens menu")
		check(is_equal_approx(hud.get_node("BtnSystem").position.x,1670.0),"other menu entry reaches on-screen position")
		assert_menu_buttons(hud,"HUD expanded %d" % i)
		hud.hide_for_system_ui()
		assert_menu_buttons(hud,"HUD system hide %d" % i)
		hud.show_after_system_ui()
		await create_timer(0.25).timeout
		check(hud.is_right_menu_visible(),"HUD restores previously open menu")
		assert_menu_buttons(hud,"HUD restored %d" % i)
		hud.toggle_right_menu()
		await create_timer(0.25).timeout
		check(not hud.is_right_menu_visible(),"HUD toggle closes menu")
		assert_menu_buttons(hud,"HUD collapsed %d" % i)
	hud.queue_free()
	await process_frame

func key_event(code: Key, pressed: bool = true, repeated: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = repeated
	return event

func press_key(code: Key) -> void:
	# Goes through GUI/unhandled routing rather than directly calling a toggle.
	root.push_input(key_event(code))
	await process_frame
	root.push_input(key_event(code,false))
	await process_frame

func check_field(path: String, walkable: bool) -> void:
	var label := "walkable" if walkable else "classic"
	# This real scene has no entry dialogue/quest reward or save operations.
	root.get_node("SceneRouter").set("_field_payload",{"scene_id":&"linxi_hero_bedroom"})
	var field: Control = load(path).instantiate()
	check(not field.get_node("HUD/InventoryBtn").visible,label+": packed InventoryBtn hidden")
	root.add_child(field)
	await process_frame
	await process_frame
	var inventory: Control = field.get("_inventory_panel")
	check(inventory != null and not inventory.visible,label+": real inventory initially closed")
	check(not field.get("inventory_btn").visible,label+": initialized InventoryBtn hidden")
	var player: Player = field.get("_player") as Player if walkable else null
	if walkable:
		check(player != null and player.can_move,"walkable: real player initially unlocked")
		for i in 2:
			await press_key(KEY_ESCAPE)
			var hud: Control = field.get("_primary_hud")
			check(hud.is_right_menu_visible(),"walkable: real Esc input expands HUD menu")
			assert_menu_buttons(hud,"walkable actual Esc open")
			await press_key(KEY_ESCAPE)
			check(not hud.is_right_menu_visible(),"walkable: second Esc closes HUD menu")
			assert_menu_buttons(hud,"walkable actual Esc closed")
	for i in 2:
		await press_key(KEY_I)
		check(not inventory.visible,label+": actual I key stays disabled")
		check(not field.get("inventory_btn").visible,label+": I does not reveal hidden button")
		if walkable:
			check(not field.get("_system_panel_open") and player.can_move,"walkable: disabled I does not claim the movement lock")
			var position_before := player.position
			Input.action_press("move_right")
			await physics_frame
			await physics_frame
			Input.action_release("move_right")
			check(not player.position.is_equal_approx(position_before),"walkable: movement remains active after disabled I")
		root.push_input(key_event(KEY_I,true,true))
		await process_frame
		check(not inventory.visible,label+": keyboard echo cannot open disabled inventory")
		await press_key(KEY_I)
		check(not inventory.visible,label+": repeated I remains disabled")
		if walkable: check(not field.get("_system_panel_open") and player.can_move,"walkable: repeated disabled I leaves movement unlocked")
	var script := DialogScript.new()
	script.dialog_id = StringName("qa_inventory_modal_"+label)
	var node := DialogNode.new()
	node.node_id = &"start"
	node.text = "QA: inventory must stay closed while dialogue is active."
	node.on_end = "end"
	script.nodes = [node] as Array[DialogNode]
	var dialogs := root.get_node("DialogPlayer")
	dialogs.play(script)
	await process_frame
	check(dialogs.is_playing(),label+": real dialogue modal is active")
	if walkable: check(not player.can_move,"walkable: dialogue owns movement lock")
	await press_key(KEY_I)
	check(not inventory.visible,label+": I cannot open inventory during dialogue")
	# Also invoke the actual controller input branch to prove its own modal gate,
	# rather than relying solely on the dialog UI consuming the viewport event.
	field.call("_unhandled_input",key_event(KEY_I))
	check(not inventory.visible,label+": controller explicitly rejects I during dialogue")
	dialogs._end_dialog()
	await process_frame
	if walkable: check(player.can_move,"walkable: ending dialogue restores movement")
	await press_key(KEY_I)
	check(not inventory.visible,label+": I remains disabled after dialogue")
	await press_key(KEY_I)
	check(not inventory.visible,label+": final repeated I remains disabled")
	if walkable: check(player.can_move,"walkable: no movement lock leak after all toggles")
	else: print("[HiddenInventoryHotkey] classic is click-to-explore and has no movable Player; movement assertions apply to walkable controller only")
	field.queue_free()
	await process_frame
	await process_frame
