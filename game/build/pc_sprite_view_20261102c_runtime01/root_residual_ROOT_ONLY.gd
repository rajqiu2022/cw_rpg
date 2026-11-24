extends SceneTree
## ROOT ONLY residual of the four original FAILs. The eight PASSes are inherited.
## Use the existing autoload: never construct a competing display adapter.
const Adapter = preload("res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd")
var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, value: bool) -> void:
	if value:
		_passed += 1
	else:
		_failed += 1
	print("PC_VIEW_RESIDUAL ", "PASS " if value else "FAIL ", label)


func _native_state(actor: Node2D, sprite: Sprite2D) -> Dictionary:
	return {"actor_position": actor.position, "actor_scale": actor.scale,
		"actor_rotation": actor.rotation, "texture": sprite.texture,
		"sprite_position": sprite.position, "sprite_scale": sprite.scale,
		"sprite_rotation": sprite.rotation, "offset": sprite.offset,
		"centered": sprite.centered, "hframes": sprite.hframes,
		"vframes": sprite.vframes, "frame": sprite.frame,
		"flip_h": sprite.flip_h, "flip_v": sprite.flip_v,
		"region_enabled": sprite.region_enabled, "region_rect": sprite.region_rect,
		"material": sprite.material, "native_frame_timer": actor.get("_frame_timer")}


func _diff(label: String, before: Dictionary, after: Dictionary) -> bool:
	var differences: Array[Dictionary] = []
	for key: String in before:
		if before[key] != after.get(key):
			differences.append({"field": key, "before": str(before[key]), "after": str(after.get(key))})
	print("PC_VIEW_NATIVE_DIFF ", JSON.stringify({"actor": label, "differences": differences}))
	return differences.is_empty()


func _run() -> void:
	var adapter = root.get_node_or_null("PCSpriteViewRuntime")
	if adapter == null or adapter.get_script() != Adapter:
		_check("precondition: existing exact formal PCSpriteViewRuntime autoload", false)
		quit(1)
		return
	var player := load("res://scenes/player.tscn").instantiate() as Player
	root.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
	npc.sprite_path = Adapter.FARMER_SOURCE
	npc.sprite_scale = 0.9
	root.add_child(npc)
	npc.set_process(false)
	var native_player := _native_state(player, player.sprite)
	var native_npc := _native_state(npc, npc.sprite)
	var original_color := npc.sprite.self_modulate
	await process_frame
	await process_frame
	# Direct synchronization isolates this adapter's writes from any unrelated
	# deferred addon. Both before-deferred and direct-sync diffs remain printed.
	var player_deferred_same := _diff("player_ready_to_registered", native_player, _native_state(player, player.sprite))
	var npc_deferred_same := _diff("npc_ready_to_registered", native_npc, _native_state(npc, npc.sprite))
	if not adapter._actors.has(npc.get_instance_id()) or not adapter._actors.has(player.get_instance_id()) or not adapter._mappings.has(Adapter.FARMER_SOURCE):
		_check("precondition: formal autoload registered both fixtures and farmer", false)
		npc.queue_free()
		player.queue_free()
		await process_frame
		quit(1)
		return
	var player_before_sync := _native_state(player, player.sprite)
	var npc_before_sync := _native_state(npc, npc.sprite)
	adapter._sync_entry(adapter._actors[player.get_instance_id()])
	adapter._sync_entry(adapter._actors[npc.get_instance_id()])
	var player_direct_same := _diff("player_direct_sync", player_before_sync, _native_state(player, player.sprite))
	var npc_direct_same := _diff("npc_direct_sync", npc_before_sync, _native_state(npc, npc.sprite))
	_check("native data unchanged (exact fields, initial and direct sync)", player_deferred_same and npc_deferred_same and player_direct_same and npc_direct_same and player.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and npc.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
	var entry: Dictionary = adapter._actors[npc.get_instance_id()]
	var mapping: Dictionary = adapter._mappings[Adapter.FARMER_SOURCE]
	var view: Sprite2D = entry.view.get_ref() as Sprite2D
	print("PC_VIEW_FOOT_METADATA ", JSON.stringify({"autoload_id": adapter.get_instance_id(), "registered_view_id": view.get_instance_id(), "named_view_id": npc.sprite.get_node(Adapter.VIEW_NAME).get_instance_id(), "child_count": npc.sprite.get_child_count(), "source_anchors": mapping.source_anchors, "body_anchors": mapping.body_anchors, "ratio": mapping.ratio, "cell": mapping.cell, "source_cell": mapping.source_cell}))
	var all_anchors_match := true
	for frame: int in range(4):
		for flip: bool in [false, true]:
			npc.sprite.frame = frame
			npc.sprite.flip_h = flip
			npc.sprite.offset = Vector2(3.25, -2.5)
			adapter._sync_entry(entry)
			var old_point: Vector2 = mapping.source_anchors[frame]
			var new_point: Vector2 = mapping.body_anchors[frame]
			if flip:
				old_point.x = mapping.source_cell.x - old_point.x
				new_point.x = mapping.cell.x - new_point.x
			var old_world := npc.sprite.to_global(npc.sprite.get_rect().position + old_point)
			var new_world := view.to_global(new_point)
			var distance := old_world.distance_to(new_world)
			print("PC_VIEW_FOOT_SAMPLE ", JSON.stringify({"frame": frame, "flip_h": flip, "source_rect": npc.sprite.get_rect(), "old_local": old_point, "new_local": new_point, "old_world": old_world, "new_world": new_world, "distance": distance, "view_position": view.position, "view_scale": view.scale, "atlas_region": (view.texture as AtlasTexture).region}))
			all_anchors_match = all_anchors_match and distance < 0.001
	_check("four frames/flips/offset original world foot (unchanged EPS0.001)", all_anchors_match)
	npc._set_interaction_highlight(true)
	var highlight := npc.sprite.material
	adapter._sync_entry(entry)
	print("PC_VIEW_HIGHLIGHT_SAMPLE ", JSON.stringify({"original_color": original_color, "actual_color": npc.sprite.self_modulate, "hd_visible": view.visible, "native_material_identity": npc.sprite.material == highlight, "reason": entry.reason}))
	_check("highlight restores original drawing and native material", npc.sprite.self_modulate == original_color and not view.visible and npc.sprite.material == highlight)
	npc._set_interaction_highlight(false)
	adapter._sync_entry(entry)
	npc.sprite.texture = player.sprite.texture
	adapter._sync_entry(entry)
	print("PC_VIEW_UNMAPPED_SAMPLE ", JSON.stringify({"original_color": original_color, "actual_color": npc.sprite.self_modulate, "hd_visible": view.visible, "source_pointer_identity": npc.sprite.texture == player.sprite.texture, "reason": entry.reason}))
	_check("unmapped texture restores original drawing", not view.visible and npc.sprite.self_modulate == original_color and npc.sprite.texture == player.sprite.texture)
	npc.queue_free()
	player.queue_free()
	await process_frame
	print("PC_VIEW_RESIDUAL_RESULT ", JSON.stringify({"passed": _passed, "failed": _failed, "inherited_original_passes_not_repeated": 8, "formal_autoload_not_freed": is_instance_valid(adapter), "real_save_access": false, "real_field_or_travel": false}))
	quit(0 if _failed == 0 else 1)
