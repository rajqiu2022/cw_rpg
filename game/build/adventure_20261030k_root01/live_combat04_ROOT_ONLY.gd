extends "res://build/adventure_20261030k_root01/live_finish03_ROOT_ONLY.gd"
func _run()->void:
	out="res://build/adventure_20261030k_root01/combat04/%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(out)
	var router:Node=root.get_node("SceneRouter");var adventure:Node=root.get_node("AdventureRuntime")
	var field:Node=await go("adventure_zhuwei_hunting_ground",Vector2(3150,1820)/Vector2(4096,3072))
	if field==null:finish();return
	await key(KEY_G);await key(KEY_ENTER)
	var battle:Node=await battle_ready()
	if battle==null:records.append({"scene":str(current_scene),"adventure":adventure.call("get_adventure_state")});finish();return
	var payload:Dictionary=router.call("get_battle_payload")
	check(String(payload.get("return_scene"))=="adventure_zhuwei_hunting_ground" and payload.enemy_ids==[&"zhuwei_pack_wolf"] and String(payload.get("victory_action",""))=="","NORMAL_WOLF_EXISTING_ENEMY_NO_NEW_PLOT_ACTION")
	await click(battle.get("btn_flee") as Button)
	var confirm:FormalConfirmDialog=battle.get("_flee_confirm_dialog")
	if not check(confirm.is_open(),"ORIGINAL_BATTLE_FLEE_CONFIRM"):finish();return
	await click(confirm.get("_confirm_button") as Button)
	field=await ready_field("adventure_zhuwei_hunting_ground")
	if field==null:finish();return
	check((field.get("_player") as Player).position.distance_to(Vector2(3150,1820))<1,"REAL_RETREAT_RETURN_SAME_FOOT")
	check(adventure.call("get_adventure_state").progress.get("wins",{}).is_empty(),"NO_NEW_WIN_LEDGER_FROM_RETREAT")
	field=await go("adventure_xiangzhou_deep_mine",Vector2(3150,820)/Vector2(4096,3072))
	if field==null:finish();return
	await key(KEY_G);await key(KEY_ENTER);battle=await battle_ready()
	if battle==null:finish();return
	payload=router.call("get_battle_payload")
	check(String(payload.get("return_scene"))=="adventure_xiangzhou_deep_mine" and payload.enemy_ids==[&"mine_brute",&"mine_outlaw"],"ELITE_MINE_EXISTING_TWO_ENEMIES")
	await shot("elite_mine_actual_battle")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"SAVES_STILL_SUSPENDED")
	finish()
