extends "res://scripts/drafts/sect_maps_20261029k/controller.gd"
const Ghost=preload("res://scripts/drafts/sect_completion_20261030a/ghost.gd")
var ghost:Node2D
var in_hall:=false
var return_foot:=Vector2.ZERO
func _ready()->void:
	super._ready();ghost=Ghost.new();add_child(ghost);ghost.setup(self);update_view()
func update_view()->void:
	super.update_view()
	for item in $Town.get_children():
		var art=item.get_node_or_null("Art")
		if art is Sprite2D and art.material is ShaderMaterial:art.material.set_shader_parameter("fade_enabled",0.0)
	if is_instance_valid(ghost):ghost.refresh()
func examine()->void:
	var e:=InputEventKey.new();e.keycode=KEY_SPACE;e.physical_keycode=KEY_SPACE;e.pressed=true
	super._unhandled_key_input(e)
