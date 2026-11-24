extends "res://build/adventure_20261030k_root01/live_combat04_ROOT_ONLY.gd"
func battle_ready()->Node:
	var began:int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<18000:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		if bool(root.get_node("LoadingManager").get("_external_active")):continue
		if current_scene!=null and current_scene.get_script()!=null and current_scene.get_script().resource_path=="res://scripts/battle/battle_controller.gd":
			var button:Button=current_scene.get("btn_flee") as Button
			if button!=null and button.is_visible_in_tree() and not button.disabled:
				await create_timer(.3).timeout
				return current_scene
	check(false,"BATTLE_FINISHED_LOADING_AND_ACTUALLY_READY");return null
