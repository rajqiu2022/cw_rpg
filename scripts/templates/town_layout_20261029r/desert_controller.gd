extends "res://scripts/drafts/desert_town_20261029d/town_controller.gd"
const Ghost=preload("res://scripts/drafts/town_layout_20261029r/actor_ghost.gd")
var ghost:Node2D
func _ready()->void:
	super._ready()
	ghost=Ghost.new();ghost.name="OccludedActor";add_child(ghost);ghost.setup(self)
	update_view()
func update_view()->void:
	super.update_view()
	# Buildings retain their opaque source pixels; only the obstructed actor gets a ghost.
	for item in $Town.get_children():
		for name in ["Art","ForeArt"]:
			var art=item.get_node_or_null(name)
			if art is CanvasItem:art.modulate.a=1.0
	$Town/WallFront/Art.material.set_shader_parameter("fade_enabled",0.0)
	if is_instance_valid(ghost):ghost.refresh()
