extends "res://build/pc_sprite_view_20261102c_runtime01/root_residual_ROOT_ONLY.gd"
## ROOT ONLY: only the two remaining failures. Original eight PASSes and the
## material/unmapped residual two PASSes are inherited without repetition.


func _run() -> void:
	var adapter = root.get_node_or_null("PCSpriteViewRuntime")
	if adapter == null or adapter.get_script() != Adapter:
		_check("precondition: existing exact formal PCSpriteViewRuntime autoload", false)
		quit(1)
		return
	var player := load("res://scenes/player.tscn").instantiate() as Player
	# Fixture initial positions, before tree entry. This is not gameplay travel.
	player.position = Vector2(-1000, 0)
	root.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
	npc.position = Vector2.ZERO
	npc.sprite_path = Adapter.FARMER_SOURCE
	npc.sprite_scale = 0.9
	root.add_child(npc)
	npc.set_process(false)
	# Retain the initial-ready baseline, before any deferred adoption.
	var native_player := _native_state(player, player.sprite)
	var native_npc := _native_state(npc, npc.sprite)
	await process_frame
	await process_frame
	var player_deferred_same := _diff("separated_player_ready_to_registered", native_player, _native_state(player, player.sprite))
	var npc_deferred_same := _diff("separated_npc_ready_to_registered", native_npc, _native_state(npc, npc.sprite))
	if not adapter._actors.has(npc.get_instance_id()) or not adapter._actors.has(player.get_instance_id()) or not adapter._mappings.has(Adapter.FARMER_SOURCE):
		_check("precondition: formal autoload registered both separated fixtures and farmer", false)
		npc.queue_free()
		player.queue_free()
		await process_frame
		quit(1)
		return
	var player_before_sync := _native_state(player, player.sprite)
	var npc_before_sync := _native_state(npc, npc.sprite)
	adapter._sync_entry(adapter._actors[player.get_instance_id()])
	adapter._sync_entry(adapter._actors[npc.get_instance_id()])
	var player_direct_same := _diff("separated_player_direct_sync", player_before_sync, _native_state(player, player.sprite))
	var npc_direct_same := _diff("separated_npc_direct_sync", npc_before_sync, _native_state(npc, npc.sprite))
	_check("native data unchanged from initial-ready baseline and direct sync", player_deferred_same and npc_deferred_same and player_direct_same and npc_direct_same and player.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and npc.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
	var entry: Dictionary = adapter._actors[npc.get_instance_id()]
	var mapping: Dictionary = adapter._mappings[Adapter.FARMER_SOURCE]
	var view: Sprite2D = entry.view.get_ref() as Sprite2D
	print("PC_VIEW_SEPARATED_METADATA ", JSON.stringify({"fixture_distance": player.position.distance_to(npc.position), "native_material": str(npc.sprite.material), "in_range": npc.get("_in_range"), "view_id": view.get_instance_id(), "child_count": npc.sprite.get_child_count(), "source_anchors": mapping.source_anchors, "body_anchors": mapping.body_anchors, "ratio": mapping.ratio}))
	var all_anchors_match := true
	var all_hd_active := true
	for frame: int in range(4):
		for flip: bool in [false, true]:
			npc.sprite.frame = frame
			npc.sprite.flip_h = flip
			npc.sprite.offset = Vector2(3.25, -2.5)
			adapter._sync_entry(entry)
			var hd_active: bool = view.visible and entry.reason == "AUTHORED_NATIVE_HD_VIEW"
			all_hd_active = all_hd_active and hd_active
			var old_point: Vector2 = mapping.source_anchors[frame]
			var new_point: Vector2 = mapping.body_anchors[frame]
			if flip:
				old_point.x = mapping.source_cell.x - old_point.x
				new_point.x = mapping.cell.x - new_point.x
			var old_world := npc.sprite.to_global(npc.sprite.get_rect().position + old_point)
			var new_world := view.to_global(new_point)
			var distance := old_world.distance_to(new_world)
			print("PC_VIEW_SEPARATED_FOOT_SAMPLE ", JSON.stringify({"frame": frame, "flip_h": flip, "hd_visible": view.visible, "reason": entry.reason, "hd_active": hd_active, "source_rect": npc.sprite.get_rect(), "old_local": old_point, "new_local": new_point, "old_world": old_world, "new_world": new_world, "distance": distance, "view_position": view.position, "view_scale": view.scale, "atlas_region": (view.texture as AtlasTexture).region}))
			all_anchors_match = all_anchors_match and distance < 0.001
	_check("active authored HD four frames/flips/offset original world foot (EPS0.001)", all_hd_active and all_anchors_match)
	npc.queue_free()
	player.queue_free()
	await process_frame
	print("PC_VIEW_SEPARATED_RESIDUAL_RESULT ", JSON.stringify({"passed": _passed, "failed": _failed, "inherited_original_passes_not_repeated": 8, "inherited_material_and_unmapped_passes_not_repeated": 2, "formal_autoload_not_freed": is_instance_valid(adapter), "real_save_access": false, "real_field_or_travel": false}))
	quit(0 if _failed == 0 else 1)
