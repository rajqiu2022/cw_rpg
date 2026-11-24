extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var suspend: Node=root.get_node("PlatformBridge");suspend.call("set_checkpoint_saves_suspended",true)
	var parsed: Script=load("res://build/adventure_world_20261031f_qa01/three_world_doors_ROOT_ONLY.gd") as Script
	var helper: Script=load("res://build/adventure_world_20261031f_system01/world_links.gd") as Script
	var valid: bool=parsed!=null and parsed.can_instantiate() and helper!=null and helper.can_instantiate() and helper.call("portal_rows").size()==3
	print(JSON.stringify({"passed":valid,"probe_script_instantiable":parsed!=null and parsed.can_instantiate(),"helper_instantiable":helper!=null and helper.can_instantiate(),"scene_instances":0,"real_save_API_calls":0}))
	quit(0 if valid else 1)
