extends "res://build/adventure_20261030k_root01/live_new01_ROOT_ONLY.gd"
func click(button:Control)->void:
	var at:Vector2=button.get_global_rect().get_center()
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.pressed=down;event.button_index=MOUSE_BUTTON_LEFT
		Input.parse_input_event(event);inputs+=1;await process_frame
	await create_timer(.15).timeout
func hold(code:Key,seconds:float)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);inputs+=1;await create_timer(seconds).timeout
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);inputs+=1;await create_timer(.2).timeout
func battle_ready()->Node:
	var began:int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<14000:
		await process_frame
		if current_scene!=null and current_scene.get_script()!=null and current_scene.get_script().resource_path=="res://scripts/battle/battle_controller.gd":
			var button:Button=current_scene.get("btn_flee") as Button
			if button!=null and button.is_visible_in_tree() and not button.disabled:return current_scene
	check(false,"BATTLE_ACTUALLY_READY");return null
func _run()->void:
	out="res://build/adventure_20261030k_root01/live03/%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(out)
	var router:Node=root.get_node("SceneRouter");var adventure:Node=root.get_node("AdventureRuntime")
	var field:Node=await go("ch4_s4_ancient_temple",Vector2(.11067708581686,.904296875))
	if field==null:finish();return
	await hold(KEY_D,.29);await hold(KEY_W,1.70)
	var actor:Player=field.get("_player") as Player
	if not check(actor.position.distance_to(Vector2(900,3560))<104,"TEMPLE_REAL_INPUT_WALK_TO_CONNECTOR"):records.append({"actual_foot":str(actor.position)});finish();return
	await key(KEY_G);field=await ready_field("adventure_luoyang_riverside_route")
	if field==null:finish();return
	check(true,"TEMPLE_REAL_G_OUTWARD_CONNECTION")
	var mini:Control=adventure.get("_ui").get_node_or_null("AdventureTerrainMinimap")
	check(mini!=null and (mini.get("_image") as Control).size==Vector2(256,192),"MINIMAP_EXACT_256_192_NOT_OVERSIZED")
	await shot("luoyang_entry_water_and_small_map")
	field=await go("adventure_zhuwei_hunting_ground",Vector2(3150,1820)/Vector2(4096,3072))
	if field==null:finish();return
	await key(KEY_G)
	if not check(adventure.call("get_adventure_state").modal_open,"WOLF_G_CHALLENGE_CONFIRM_VISIBLE"):finish();return
	await key(KEY_ESCAPE)
	check(current_scene==field and field.get("_system_panel_open")==false,"CHALLENGE_CANCEL_STAYS_SAFE_FIELD")
	await shot("wolf_optional_ground")
	await key(KEY_G);await key(KEY_ENTER)
	var battle:Node=await battle_ready()
	if battle==null:finish();return
	var payload:Dictionary=router.call("get_battle_payload")
	check(String(payload.get("return_scene"))=="adventure_zhuwei_hunting_ground" and payload.enemy_ids==[&"zhuwei_pack_wolf"] and String(payload.get("victory_action",""))=="","NORMAL_WOLF_ORIGINAL_ENEMY_NO_NEW_PLOT_ACTION")
	await click(battle.get("btn_flee") as Button)
	var confirm:FormalConfirmDialog=battle.get("_flee_confirm_dialog")
	if not check(confirm.is_open(),"ORIGINAL_BATTLE_FLEE_CONFIRM"):finish();return
	await click(confirm.get("_confirm_button") as Button)
	field=await ready_field("adventure_zhuwei_hunting_ground")
	if field==null:finish();return
	check((field.get("_player") as Player).position.distance_to(Vector2(3150,1820))<1,"REAL_RETREAT_RETURN_SAME_FOOT")
	check(adventure.call("get_adventure_state").progress.get("wins",{}).is_empty(),"NO_WIN_OR_REWARD_FROM_RETREAT")
	field=await go("adventure_xiangzhou_deep_mine",Vector2(3150,820)/Vector2(4096,3072))
	if field==null:finish();return
	await key(KEY_G);await key(KEY_ENTER);battle=await battle_ready()
	if battle==null:finish();return
	payload=router.call("get_battle_payload")
	check(String(payload.get("return_scene"))=="adventure_xiangzhou_deep_mine" and payload.enemy_ids==[&"mine_brute",&"mine_outlaw"],"ELITE_MINE_ORIGINAL_TWO_ENEMIES")
	await shot("elite_mine_actual_battle")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"SAVES_STILL_SUSPENDED")
	finish()
