extends Node

var _field: Node
var _depth := preload("res://scripts/world/v14_modular_overlap.gd").new()


func configure(field: Node) -> void:
	_field = field
	var world := field.get("world_container") as Node2D
	var layer := field.get("_actor_layer") as Node2D
	var extent: Vector2 = field.get("_world_size")
	var scene := field.get("_current_scene") as SceneScript
	_depth.configure(world)
	for entry: Dictionary in scene.map_layout.visual_objects:
		var prop := layer.get_node_or_null("SceneObject_%s" % entry.id) as Sprite2D
		if prop != null:
			prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_depth.add_prop(prop, String(entry.id), float(entry.depth_sort_foot_y) * extent.y)


func _process(_delta: float) -> void:
	var hero := _field.get("_player") as Player
	if is_instance_valid(hero):
		_depth.refresh(hero)
