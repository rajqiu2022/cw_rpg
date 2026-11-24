extends "res://build/adventure_20261030k_root01/live_combat05_ROOT_ONLY.gd"
func battle_ready()->Node:
	var began:int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<18000:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")) or bool(root.get_node("LoadingManager").get("_external_active")):continue
		if current_scene==null or current_scene.get_script()==null or current_scene.get_script().resource_path!="res://scripts/battle/battle_controller.gd":continue
		# The original command buttons exist during INTRO, before input is legal.
		if int(current_scene.get("_state"))!=1:continue
		var button:Button=current_scene.get("btn_flee") as Button
		if button!=null and button.is_visible_in_tree() and not button.disabled:
			await process_frame
			return current_scene
	records.append({"timeout_scene":str(current_scene),"state":current_scene.get("_state") if current_scene!=null else null})
	check(false,"BATTLE_LEGAL_PLAYER_TURN_READY");return null
