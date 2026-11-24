extends "res://build/sect_repair_20261031c_system01/huashan_controller.gd"
const ENVIRONMENT=preload("res://build/environment_residual_20261031d_system01/huashan_environment.gd")
const MOUNTAINS := "res://art/modules/environment_residual_20261031d/huashan_valley_backdrop_v1.png"
const MOUNTAINS_SHA := "fd08b4a0b2c0edcb892bdb806af5ac2eb1a7728db7399b1d472d7fa64ff95293"
var environment_state31d: Dictionary={}

func _ready() -> void:
	super._ready()
	if not native_visual_ready:return
	environment_state31d=ENVIRONMENT.install(self,MOUNTAINS,MOUNTAINS_SHA,Vector2i(1672,941))
	if not bool(environment_state31d.get("ready",false)):
		controls_enabled=false;push_error("[Sect31d] Huashan mountain background source refused")

func get_environment31d_debug() -> Dictionary:
	var state:=environment_state31d.duplicate(true)
	var art:=get_node_or_null("HuashanFarMountains31d/WholeNativeMountainBackdrop") as Sprite2D
	if art!=null:
		state.visible=art.is_visible_in_tree();state.scale=art.scale;state.position=art.position
		state.viewport_size=get_viewport_rect().size;state.source_size=art.texture.get_size()
	return state
