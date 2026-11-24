extends "res://build/adventure_20261030k_root01/live_new01_ROOT_ONLY.gd"
func _run()->void:
	out="res://build/adventure_20261030k_root01/live02/%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(out)
	var adventure:Node=root.get_node("AdventureRuntime")
	var field:Node=await go("adventure_zhuwei_hunting_ground",Vector2(.5,.93))
	if field==null:finish();return
	check(field.get("_exit_nodes")[0].call("_can_enter"),"FOREST_ACTUAL_FEET_INSIDE_RETURN_RECT")
	await key(KEY_SPACE)
	field=await ready_field("ch1_s3_zhuwei_forest")
	if field==null:finish();return
	check(String(adventure.get("_near"))=="entry_adventure_zhuwei_hunting_ground","FOREST_ORIGINAL_SOURCE_CONNECTOR_NEAR")
	await key(KEY_G);field=await ready_field("adventure_zhuwei_hunting_ground")
	if field==null:finish();return
	check(true,"FOREST_PUBLIC_REAL_SPACE_RETURN_AND_G_REENTER")
	var mini:Control=adventure.get("_ui").get_node_or_null("AdventureTerrainMinimap")
	check(mini!=null and mini.get("_viewport")!=null and mini.get("_portrait")!=null,"MINIMAP_NEW_WORLD_AND_PORTRAIT")
	await shot("forest_entry_minimap")
	field=await go("adventure_xiangzhou_deep_mine",Vector2(1150,790)/Vector2(4096,3072))
	if field==null:finish();return
	check(field.get("_world_size")==Vector2(4096,3072),"MINE_WORLD_SIZE")
	await key(KEY_G)
	if not check(adventure.call("get_adventure_state").modal_open,"MINE_REAL_G_CLUE"):finish();return
	await key(KEY_ENTER)
	check(adventure.call("get_adventure_state").progress.get("viewed",{}).get("mine_old_cut")==true and field.get("_system_panel_open")==false,"MINE_CLUE_CONFIRM_RELEASE")
	await shot("mine_shelter_minimap")
	field=await go("adventure_xiangzhou_deep_mine",Vector2(.5,.93))
	if field==null:finish();return
	await key(KEY_SPACE);field=await ready_field("openworld_xiangzhou_mine_valley")
	if field==null:finish();return
	check(String(adventure.get("_near"))=="entry_adventure_xiangzhou_deep_mine","MINE_ORIGINAL_CONNECTOR_NEAR")
	await key(KEY_G);field=await ready_field("adventure_xiangzhou_deep_mine")
	if field==null:finish();return
	check(true,"MINE_PUBLIC_REAL_SPACE_RETURN_AND_G_REENTER")
	field=await go("adventure_luoyang_riverside_route",Vector2(1460,1590)/Vector2(4096,3072))
	if field==null:finish();return
	check(field.get("_world_size")==Vector2(4096,3072),"LUOYANG_WORLD_SIZE")
	await shot("luoyang_relay_minimap")
	await key(KEY_G)
	if not check(adventure.call("get_adventure_state").modal_open,"LUOYANG_REAL_G_OBSERVATION"):finish();return
	await key(KEY_ENTER)
	check(adventure.call("get_adventure_state").progress.get("viewed",{}).get("luoyang_shelter_observation")==true,"LUOYANG_OBSERVATION_NO_QUEST")
	field=await go("adventure_luoyang_riverside_route",Vector2(.5,.93))
	if field==null:finish();return
	await key(KEY_SPACE);field=await ready_field("ch4_s4_ancient_temple")
	if field==null:finish();return
	check(field.get_script().resource_path=="res://build/luoyang_regions_20261027d_source01/region_field.gd","REAL_PUBLIC_RETURN_ORIGINAL_TEMPLE_REGION")
	var actor:Player=field.get("_player") as Player
	check(actor.position.distance_to(Vector2(760,4380))<1,"ORIGINAL_TEMPLE_SAFE_FOOT_760_4380")
	check(adventure.get("_features").has("entry_adventure_luoyang_riverside_route"),"TEMPLE_ACTUAL_REGION_CONNECTOR_INSTALLED")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"SAVES_STILL_SUSPENDED")
	finish()
