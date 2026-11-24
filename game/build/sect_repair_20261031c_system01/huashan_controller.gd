extends "res://scripts/drafts/huashan_map_20261029m/controller.gd"
const RepairGhost=preload("res://build/sect_repair_20261031c_system01/actor_ghost.gd")
const NativeVisuals=preload("res://build/sect_repair_20261031c_system01/native_visuals.gd")
var repair_ghost: Node2D
var native_visual_ready:=false

func _ready() -> void:
	super._ready()
	if not NativeVisuals.setup(self,"huashan"):
		controls_enabled=false;push_error("[Sect31c] Huashan native visual source refused");return
	native_visual_ready=true
	repair_ghost=RepairGhost.new();repair_ghost.name="OpaqueArchitectureActorGhost";add_child(repair_ghost);repair_ghost.setup(self);update_view()

func update_view() -> void:
	super.update_view()
	for item: Node in $Town.get_children():
		if not item.has_meta("fade"):continue
		var art:=item.get_node_or_null("Art") as Sprite2D
		if art!=null and art.material is ShaderMaterial:art.material.set_shader_parameter("fade_enabled",0.0)
	if is_instance_valid(repair_ghost):repair_ghost.refresh()
