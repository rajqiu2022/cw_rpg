extends SceneTree

var _checks := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://data/scenes/world_map_layered_prototype_20260928.tres") as SceneScript
	_check(scene != null and scene.map_layout != null, "layered prototype resource loads")
	if scene == null or scene.map_layout == null:
		quit(1)
		return
	var layout := scene.map_layout
	_check(scene.background_path != "" and layout.walkable_mask_path != "", "terrain and navigation are independent assets")
	_check(layout.visual_objects.size() == 1, "city is one independent visual object, not painted into terrain")
	var city: Dictionary = layout.visual_objects[0]
	_check(city.get("sort_by_feet", false) and city.has("collision_size") and city.has("depth_sort_foot_y"), "city owns visual, foot collision and depth contract")
	var city_texture := load(city.get("texture", "")) as Texture2D
	_check(city_texture != null, "transparent city texture imports")
	if city_texture != null:
		var image := city_texture.get_image()
		_check(image.get_pixel(0, 0).a < 0.1, "city sprite has real transparent exterior")
		_check(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.8, "city sprite has opaque architecture")

	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", scene)
	field.set("_screen_size", Vector2(1536, 1024))
	field.set("_world_size", Vector2(1536, 1024))
	field.call("_load_walkable_mask", layout.walkable_mask_path)
	field.call("_rebuild_walkability_collision_entries", layout.blockers, layout.visual_objects)
	for probe: Dictionary in layout.walkable_probes:
		var position: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(field.call("_is_walkable_by_mask", position) and not field.call("_is_blocked_by_layout", position), "walkable %s" % probe.get("id", ""))
	for probe: Dictionary in layout.blocked_probes:
		var position: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(not field.call("_is_walkable_by_mask", position) or field.call("_is_blocked_by_layout", position), "blocked %s" % probe.get("id", ""))

	var world_container := Node2D.new()
	var actor_layer := Node2D.new()
	var visual_layer := Node2D.new()
	var foreground_layer := Node2D.new()
	var collision_layer := Node2D.new()
	field.add_child(world_container)
	world_container.add_child(visual_layer)
	world_container.add_child(collision_layer)
	world_container.add_child(actor_layer)
	world_container.add_child(foreground_layer)
	field.set("world_container", world_container)
	field.set("_actor_layer", actor_layer)
	field.set("_visual_layer", visual_layer)
	field.set("_foreground_layer", foreground_layer)
	field.set("_collision_layer", collision_layer)
	field.call("_spawn_scene_objects", layout.visual_objects)
	_check(actor_layer.get_child_count() == 1, "depth-sorted city is rendered on the actor ladder")
	_check(collision_layer.get_child_count() == 1, "city has a physical foot blocker")
	if actor_layer.get_child_count() == 1:
		var sprite := actor_layer.get_child(0) as Sprite2D
		var actor_behind_band := int(floor(0.47 * 1024.0 / 8.0))
		var actor_in_front_band := int(floor(0.60 * 1024.0 / 8.0))
		_check(sprite.z_index > actor_behind_band and sprite.z_index < actor_in_front_band, "city sorts ahead of actor behind and behind actor in front")
	field.free()
	print("[LayeredWorldPrototype20260928] checks=%d failed=%d" % [_checks, _failed])
	quit(_failed)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
