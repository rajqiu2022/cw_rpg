extends "res://build/adventure_20261030k_root01/live_new01_ROOT_ONLY.gd"
func _run()->void:
	out="res://build/gather_actions_20261030l_root01/mine_view03/%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(out)
	var field:Node=await go("adventure_xiangzhou_deep_mine",Vector2(875,1730)/Vector2(4096,3072))
	if field==null:finish();return
	var life:Node=root.get_node("LifeSkills");var inv:Node=root.get_node("Inventory")
	var actor:Player=field.get("_player") as Player
	var at:Vector2=actor.position;var before:int=inv.call("count_of",&"iron_ore")
	if not check(life.get("_active_sites")["adventure_mine_ore_01"].runtime_foot==Vector2(925,1680),"SINGLE_ORE_POINT_ONLY115PX_WEST"):finish();return
	await key(KEY_F)
	var began:int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<1700:
		await process_frame
		var state:Dictionary=life.call("get_gather_action_debug")
		if state.get("active")==true and state.get("frame_index")==2:
			check(actor.position==at and inv.call("count_of",&"iron_ore")==before,"FRAME2_STABLE_FOOT_NO_EARLY_MATERIAL")
			await shot("mine01_unobstructed_frame2")
			break
	while life.call("get_gather_action_debug").get("active",false):await process_frame
	check(inv.call("count_of",&"iron_ore")==before+2 and actor.can_move and actor.sprite.visible and actor.position==at,"RELOCATED_POINT_FINISH_PLUS2_RESTORE")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"SAVES_STILL_SUSPENDED")
	finish()
