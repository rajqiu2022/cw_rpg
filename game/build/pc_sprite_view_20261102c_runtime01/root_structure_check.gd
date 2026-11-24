extends SceneTree
## ROOT ONLY: isolated actor fixtures, no save/Router/field/real-game travel.
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
	print("PC_VIEW_CHECK ", "PASS " if value else "FAIL ", label)


func _native_state(actor: Node2D, sprite: Sprite2D) -> Array:
	return [actor.position, actor.scale, actor.rotation, sprite.texture,
		sprite.position, sprite.scale, sprite.rotation, sprite.offset,
		sprite.centered, sprite.hframes, sprite.vframes, sprite.frame,
		sprite.flip_h, sprite.flip_v, sprite.region_enabled, sprite.region_rect,
		sprite.material, actor.get("_frame_timer")]


func _run() -> void:
	var player := load("res://scenes/player.tscn").instantiate() as Player
	root.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
	npc.sprite_path = Adapter.FARMER_SOURCE
	npc.sprite_scale = 0.9
	root.add_child(npc)
	npc.set_process(false)
	var native_npc := _native_state(npc, npc.sprite)
	var native_player := _native_state(player, player.sprite)
	var original_color := npc.sprite.self_modulate
	var body := npc.get("_body_collider") as StaticBody2D
	var shape := body.get_child(0) as CollisionShape2D
	var body_state := [body.position, body.collision_layer, body.collision_mask,
		shape.position, shape.shape, (shape.shape as RectangleShape2D).size]
	var adapter := Adapter.new()
	root.add_child(adapter)
	await process_frame
	adapter._adopt_actor(player)
	adapter._adopt_actor(npc)
	_check("player/npc LINEAR, native data unchanged", player.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and npc.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and _native_state(player, player.sprite) == native_player and _native_state(npc, npc.sprite) == native_npc)
	_check("farmer mapping loaded; Root must first copy/import unchanged raw", adapter._mappings.has(Adapter.FARMER_SOURCE))
	if adapter._mappings.has(Adapter.FARMER_SOURCE):
		var mapping: Dictionary = adapter._mappings[Adapter.FARMER_SOURCE]
		var view := npc.sprite.get_node_or_null(Adapter.VIEW_NAME) as Sprite2D
		_check("native pointer/hframes unchanged, view has explicit 384x1024 cell", view != null and view.texture is AtlasTexture and view.texture.get_size() == Vector2(384, 1024) and npc.sprite.hframes == 4 and npc.sprite.texture == native_npc[3])
		var all_anchors_match := true
		var uniform_ratio := true
		for frame: int in range(4):
			for flip: bool in [false, true]:
				npc.sprite.frame = frame
				npc.sprite.flip_h = flip
				npc.sprite.offset = Vector2(3.25, -2.5)
				adapter._sync_entry(adapter._actors[npc.get_instance_id()])
				var old_point: Vector2 = mapping.source_anchors[frame]
				var new_point: Vector2 = mapping.body_anchors[frame]
				if flip:
					old_point.x = mapping.source_cell.x - old_point.x
					new_point.x = mapping.cell.x - new_point.x
				all_anchors_match = all_anchors_match and npc.sprite.to_global(npc.sprite.get_rect().position + old_point).distance_to(view.to_global(new_point)) < 0.001
				uniform_ratio = uniform_ratio and view.scale == Vector2.ONE * (140.0 / 808.0)
		_check("all four frames and flips retain world foot with offset", all_anchors_match)
		_check("one isotropic scale, original world body height", uniform_ratio and is_equal_approx(view.scale.y * npc.sprite.scale.y * 808, npc.sprite.scale.y * 140))
		npc._set_interaction_highlight(true)
		var highlight := npc.sprite.material
		adapter._sync_entry(adapter._actors[npc.get_instance_id()])
		_check("highlight restores original self_modulate and keeps native material", npc.sprite.self_modulate == original_color and not view.visible and npc.sprite.material == highlight)
		npc._set_interaction_highlight(false)
		adapter._sync_entry(adapter._actors[npc.get_instance_id()])
		_check("leaving highlight restores authored HD display", view.visible and npc.sprite.self_modulate.a == 0)
		npc.sprite.texture = player.sprite.texture
		adapter._sync_entry(adapter._actors[npc.get_instance_id()])
		_check("unmapped conversation/walk source restores native drawing", not view.visible and npc.sprite.self_modulate == original_color and npc.sprite.texture == player.sprite.texture)
	_check("NPC original body unchanged", body_state == [body.position, body.collision_layer, body.collision_mask, shape.position, shape.shape, (shape.shape as RectangleShape2D).size])
	player.set_building_overlap(true, 0.42, true)
	var ghost := player.get("_overlap_ghost") as Sprite2D
	_check("original ghost texture/frame/filter/alpha contract", ghost.texture == player.sprite.texture and ghost.frame == player.sprite.frame and ghost.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and is_equal_approx(ghost.modulate.a, 0.42))
	var late := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
	root.add_child(late)
	late.set_process(false)
	await process_frame
	await process_frame
	_check("late node-added actor adopted without recurring tree scan", adapter._actors.has(late.get_instance_id()))
	adapter.queue_free()
	await process_frame
	_check("adapter teardown leaves restored native farmer color", npc.sprite.self_modulate == original_color)
	late.queue_free()
	npc.queue_free()
	player.queue_free()
	await process_frame
	print("PC_VIEW_STRUCTURE_RESULT ", JSON.stringify({"passed": _passed, "failed": _failed, "real_save_access": false, "real_field_or_travel": false}))
	quit(0 if _failed == 0 else 1)
