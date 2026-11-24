extends Node2D

# A movable prop owns its foot collider. Removing or rebuilding the sprite
# on a quest update removes the same collider, including on save reload.
func _ready() -> void:
	child_entered_tree.connect(_on_layer_added)


func _on_layer_added(layer: Node) -> void:
	var field := get_parent()
	if layer != field.get("_actor_layer"):
		return
	var scene := field.get("_current_scene") as SceneScript
	if scene == null or scene.map_layout == null or not scene.map_layout.has_meta("sprite_footprints_uv"):
		return
	var footprints: Dictionary = scene.map_layout.get_meta("sprite_footprints_uv")
	layer.child_entered_tree.connect(_attach_footprint.bind(footprints))


func _attach_footprint(node: Node, footprints: Dictionary) -> void:
	var sprite := node as Sprite2D
	if sprite == null or not footprints.has(sprite.name):
		return
	var uv: Rect2 = footprints[sprite.name]
	var art := sprite.get_rect()
	var body := StaticBody2D.new()
	body.name = "Footprint"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = art.position + art.size * uv.get_center()
	var shape := RectangleShape2D.new()
	shape.size = art.size * uv.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	sprite.add_child(body)
