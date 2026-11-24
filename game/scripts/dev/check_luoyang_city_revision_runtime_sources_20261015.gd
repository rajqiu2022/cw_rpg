extends SceneTree
## ROOT --check-only entry; never a game/test run.
const REVISION = preload("res://scripts/city/luoyang_city_revision_runtime_20261015.gd")
const ROUTER_SOURCE = preload("res://scripts/autoload/scene_router.gd")
const FIELD_SOURCE = preload("res://scripts/field/field_walkable_controller.gd")
const LOADING_SOURCE = preload("res://scripts/autoload/loading_manager.gd")
func _initialize() -> void:
	push_error("Use --check-only for this source compilation entry")
	quit(1)
