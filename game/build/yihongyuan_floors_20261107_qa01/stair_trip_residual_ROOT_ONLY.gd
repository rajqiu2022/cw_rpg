extends "res://build/yihongyuan_floors_20261107_qa01/stair_trip_ROOT_ONLY.gd"

func _wait_upper(previous: int) -> Node:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 30000:
		await process_frame
		var field: Node = current_scene
		if not is_instance_valid(field) or field.get_script() == null: continue
		evidence["last_field_script"] = field.get_script().resource_path
		if field.get_script().resource_path != FIELD: continue
		var region: Dictionary = field.get("_region")
		evidence["last_region"] = region.get("id","")
		if field.get_instance_id() == previous or region.get("id") != UPPER: continue
		if field.get("_field_loading_failed") == true: need(false,"UPPER_FIELD_FAILED"); return null
		var loader := root.get_node("LoadingManager")
		if field.get("_field_loading_complete") != true or loader.get("_transition_active") == true or loader.get("_external_active") == true: continue
		var player: Node = field.get("_player")
		if player == null or player.get("can_move") != true: continue
		var owner: RefCounted = field.get("_region_owner")
		var receipt: Dictionary = owner.call("receipt") if owner != null else {}
		if not need(receipt.get("phase") == "LIVE" and receipt.get("source_first") == receipt.get("source_final"), "UPPER_STRICT_SOURCE_OWNER_LIVE"): return null
		var mini: Node = field.get("_world_travel_minimap")
		evidence["upper_minimap_present"] = mini != null
		await physics_frame
		await RenderingServer.frame_post_draw
		return field
	need(false,"FINITE_UPPER_FIELD")
	return null
