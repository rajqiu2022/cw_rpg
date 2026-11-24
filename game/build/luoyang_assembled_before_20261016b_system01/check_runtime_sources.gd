extends SceneTree
const ROOMS=preload("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
const CITY=preload("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd")
const FADE=preload("res://scripts/city/luoyang_city_assembled_fade_20261016b.gd")
const FURNITURE_FADE=preload("res://scripts/city/luoyang_assembled_furniture_fade_20261016b.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
func _initialize() -> void: call_deferred("_check")
func _check() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var ok:=true
	for path: String in ["res://scripts/autoload/scene_router.gd","res://scripts/autoload/loading_manager.gd","res://scripts/field/field_walkable_controller.gd"]:
		var value: Script=load(path) as Script
		var valid:=value!=null and value.can_instantiate()
		print("SOURCE_COMPILE "+path+" "+str(valid)); ok=ok and valid
	print("ASSEMBLED_CHECK "+str(ok)); quit(0 if ok else 1)
