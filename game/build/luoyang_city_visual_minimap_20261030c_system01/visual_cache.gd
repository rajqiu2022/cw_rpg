extends Node
## Isolated one-shot visual rendering. Creates only unscripted Sprite2D and
## Polygon2D leaves: no duplicated actors, collisions, cameras, HUD or exits.
var capture_ready := false
var render_requests := 0
var visual_node_count := 0
var compiled_render_count := 0
var full_compiled_render_count := 0
var texture_paths: Array[String] = []
var _viewport: SubViewport
var _canvas: Node2D
var _items: Array[Dictionary] = []
var _ordinal := 0
var _world: Node2D
var _source_root: Node
var _generation := 0
var _valid := true
var _compiled_rows: Array[Dictionary] = []

func configure(world: Node2D, source_root: Node, world_size: Vector2, world_origin: Vector2, compiled: Dictionary) -> Texture2D:
	_generation += 1
	capture_ready = false; render_requests = 0; visual_node_count = 0
	compiled_render_count = 0; full_compiled_render_count = 0
	_valid = true; _compiled_rows.clear()
	_world = world; _source_root = source_root
	var factor: float = 1024.0 / maxf(world_size.x, world_size.y)
	var dimensions := Vector2i(maxi(1, roundi(world_size.x * factor)), maxi(1, roundi(world_size.y * factor)))
	_viewport = SubViewport.new(); _viewport.name = "StaticCityVisualCache"
	_viewport.size = dimensions; _viewport.disable_3d = true
	_viewport.transparent_bg = false; _viewport.gui_disable_input = true
	_viewport.world_2d = World2D.new()
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	var scale := Vector2(dimensions) / world_size
	add_child(_viewport)
	_canvas = Node2D.new(); _canvas.name = "UnscriptedStaticVisuals"; _viewport.add_child(_canvas)
	_viewport.canvas_transform = Transform2D(Vector2(scale.x,0), Vector2(0,scale.y), -world_origin * scale)
	if compiled.is_empty():
		_scan(source_root, false)
	else:
		# All ground/enclosure polygons are resident, unlike chunked Sprite rows.
		_scan(source_root, true)
		full_compiled_render_count = compiled.get("render", []).size()
		for row: Dictionary in compiled.get("render", []): _compiled_sprite(row)
	_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.z != b.z: return a.z < b.z
		if a.y != b.y: return a.y < b.y
		return a.ordinal < b.ordinal)
	for item: Dictionary in _items: _canvas.add_child(item.node)
	visual_node_count = _items.size()
	_items.clear()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	render_requests = 1
	_finish_capture(_generation)
	return _viewport.get_texture()

func _finish_capture(generation: int) -> void:
	await RenderingServer.frame_post_draw
	if generation != _generation or not is_instance_valid(_viewport) or not is_inside_tree(): return
	# UPDATE_ONCE already turns itself off; explicitly retain that invariant.
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	capture_ready = _valid and compiled_render_count == full_compiled_render_count
	_world = null; _source_root = null

func _material(source: CanvasItem) -> Material:
	var current: CanvasItem = source
	while current != null:
		if current.material != null:
			var material: Material = current.material.duplicate(true) as Material
			if material is ShaderMaterial:
				for uniform: Dictionary in material.shader.get_shader_uniform_list():
					if String(uniform.name) == "fade_enabled": material.set_shader_parameter("fade_enabled", 0.0)
			return material
		if not current.use_parent_material: break
		current = current.get_parent() as CanvasItem
	return null

func _effective_z(source: Node2D) -> int:
	var z: int = source.z_index
	var item: Node2D = source
	while item.z_as_relative and item.get_parent() is Node2D and item.get_parent() != _world:
		item = item.get_parent() as Node2D; z += item.z_index
	return clampi(z, -4096, 4095)

func _sort_y(source: Node2D) -> float:
	var item: Node2D = source
	while item.get_parent() is Node2D and item.get_parent() != _world:
		var parent := item.get_parent() as Node2D
		if parent.y_sort_enabled: return _world.to_local(item.global_position).y
		item = parent
	return 0.0

func _record(node: Node2D, z: int, y: float) -> void:
	node.z_as_relative = false; node.z_index = z
	# Every cloned visual is a fresh leaf without source script or callbacks.
	node.set_process(false); node.set_physics_process(false)
	node.set_process_input(false); node.set_process_unhandled_input(false)
	_items.append({"node": node, "z": z, "y": y, "ordinal": _ordinal})
	_ordinal += 1

func _remember(texture: Texture2D) -> void:
	if texture != null and not texture.resource_path.is_empty() and not texture_paths.has(texture.resource_path): texture_paths.append(texture.resource_path)

func _is_actor_texture(texture: Texture2D) -> bool:
	if texture == null: return false
	var path: String = texture.resource_path.to_lower()
	return "/characters/" in path or "npc_" in path or "merchant_walk" in path or "worker_walk" in path

func _scan(node: Node, polygons_only: bool) -> void:
	# StaticBody children may contain authored building art: traverse the body
	# but never copy it. Actors/exits are excluded at their roots instead.
	if node is CanvasLayer or node is Control or node is CharacterBody2D or node is Area2D or node is Camera2D or node is NPCNode: return
	if node.has_meta("npc_id") or node.has_meta("actor_id") or node.name in [&"GateSentinel", &"Keeper"]: return
	if node is Node2D and not node.is_visible_in_tree(): return
	if node is Sprite2D and not polygons_only and node.texture != null and not _is_actor_texture(node.texture):
		var sprite := Sprite2D.new()
		for property: String in ["texture", "centered", "offset", "flip_h", "flip_v", "hframes", "vframes", "frame", "region_enabled", "region_rect", "region_filter_clip_enabled"]: sprite.set(property, node.get(property))
		sprite.transform = _world.global_transform.affine_inverse() * node.global_transform
		sprite.modulate = node.modulate; sprite.self_modulate = node.self_modulate
		sprite.texture_repeat = node.texture_repeat; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.material = _material(node); _remember(sprite.texture)
		_record(sprite, _effective_z(node), _sort_y(node))
	elif node is Polygon2D:
		var polygon := Polygon2D.new()
		for property: String in ["polygon", "uv", "vertex_colors", "color", "offset", "texture", "texture_offset", "texture_scale", "texture_rotation", "invert_enabled", "invert_border", "antialiased", "polygons", "internal_vertex_count"]: polygon.set(property, node.get(property))
		polygon.transform = _world.global_transform.affine_inverse() * node.global_transform
		polygon.modulate = node.modulate; polygon.self_modulate = node.self_modulate
		polygon.texture_repeat = node.texture_repeat; polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		polygon.material = _material(node); _remember(polygon.texture)
		_record(polygon, _effective_z(node), _sort_y(node))
	for child: Node in node.get_children(): _scan(child, polygons_only)

func _compiled_sprite(row: Dictionary) -> void:
	var texture: Texture2D = load(String(row.get("texture", ""))) as Texture2D
	if texture == null or texture.get_size() != row.get("texture_size_px", Vector2.ZERO):
		_valid = false
		push_error("[CityVisualMinimap30c] Full row texture mismatch: " + String(row.get("key", "")))
		return
	var sprite := Sprite2D.new(); sprite.texture = texture
	sprite.set_meta("source_compiled_key", String(row.get("key", "")))
	sprite.position = row.position_px; sprite.scale = row.scale
	sprite.centered = bool(row.get("centered", true))
	var original: Dictionary = row.get("source_row", {})
	if original.get("modulate") is Color: sprite.modulate = original.modulate
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var z: int = clampi(floori(row.foot_px.y / 8.0), 0, 4095) if original.get("sort_by_feet", true) else int(original.get("z_index", 0))
	_record(sprite, z, row.foot_px.y); _remember(texture)
	compiled_render_count += 1
	_compiled_rows.append({"key": String(row.get("key", "")), "texture": texture.resource_path, "position_px": sprite.position, "foot_px": row.foot_px, "scale": sprite.scale, "centered": sprite.centered, "texture_size_px": texture.get_size(), "z_index": z})

func get_texture() -> Texture2D:
	return _viewport.get_texture() if is_instance_valid(_viewport) else null

func get_debug_state() -> Dictionary:
	return {"ready": capture_ready, "valid": _valid, "render_requests": render_requests, "visual_node_count": visual_node_count, "compiled_render_count": compiled_render_count, "full_compiled_render_count": full_compiled_render_count, "compiled_rows": _compiled_rows.duplicate(true), "texture_paths": texture_paths.duplicate(), "cache_size": _viewport.size if is_instance_valid(_viewport) else Vector2i.ZERO, "viewport_update_mode": _viewport.render_target_update_mode if is_instance_valid(_viewport) else -1, "scripted_visual_copies": 0, "actor_copies": 0, "collision_copies": 0}
