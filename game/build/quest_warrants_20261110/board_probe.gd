extends "res://build/victory_quest_20261108/story_live.gd"

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	dialogue = root.get_node("DialogPlayer")
	state.reset_for_new_game()
	router.reset_for_new_game()
	for row in [[&"ch4_s0_luoyang_gate","luoyang"],[&"openworld_bianzhou_city","bianzhou"],[&"openworld_xiangzhou_city","xiangzhou"],[&"openworld_jinling_city","jinling"]]:
		if "three-cities" in OS.get_cmdline_user_args() and row[1]=="luoyang": continue
		print("BOARD_PROBE_START ",row)
		var field := await enter(row[0])
		if field == null:
			print("BOARD_ROUTE ",router.get_public_city_preparation_state(), " ",router.LUOYANG_V3.transition_validation_state())
			continue
		await settle(field)
		var board: Area2D
		for area_node: Area2D in field.get("_trigger_areas"):
			if area_node.get_meta("trigger_data",{}).get("action") == "bounty_board:"+row[1]:
				board = area_node
				break
		if not expect(is_instance_valid(board),"board exists "+row[1]): continue
		var center := board.global_position
		var opened := false
		for offset: Vector2 in [Vector2.ZERO,Vector2(0,72),Vector2(0,-72),Vector2(72,0),Vector2(-72,0),Vector2(136,80),Vector2(-136,80)]:
			var actor := await position_at(field,center+offset)
			await physics_frame
			if not board.overlaps_body(actor) or not load("res://build/three_towns_world_20261029j_system01/town_registry.gd").actor_shape_clear(actor): continue
			await press_space()
			if await wait_for(func(): return current_scene != null and current_scene.scene_file_path=="res://scenes/bounty_board.tscn",1400):
				opened = current_scene.get_node("BountyEntries").get_child_count() > 0
				if opened:
					if "visual" in OS.get_cmdline_user_args():
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("user://warrant-board-"+row[1]+".png")
					var first: Node = current_scene.get_node("BountyEntries").get_child(0)
					var id := StringName(String(first.name).trim_prefix("BountyEntry_"))
					first.get_node("Content/AcceptButton").pressed.emit()
					expect(root.get_node("BountyManager")._state_for(id).status==&"active","real card and accept button "+row[1])
					current_scene.get_node("CloseButton").pressed.emit()
					expect(await wait_for(func(): return current_scene != null and current_scene.has_method("_on_player_interacted") and router.get_current_field_id()==row[0] and not root.get_node("LoadingManager").get("_transition_active"),26000),"board closes back to city "+row[1])
				break
			if dialogue.is_playing() and is_instance_valid(field):
				await settle(field)
			if not is_instance_valid(field): break
		expect(opened, "physical board opens "+row[1])
	finish()
