extends SceneTree
## Root alone launches this parse-only probe. No scene instantiation, input or save writes.
const ROOT := "res://build/three_towns_world_20261029j_system01/"
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var count:=0
	for file: String in ["town_registry.gd","town_field.gd","world_watcher.gd","minimap_pips.gd"]:
		var script: GDScript=load(ROOT+file)
		if script==null or not script.can_instantiate():
			push_error("THREE_TOWNS_PARSE_FAIL "+file)
			quit(1)
			return
		count+=1
	var packed: PackedScene=load(ROOT+"town_field.tscn")
	if packed==null or not packed.can_instantiate():
		push_error("THREE_TOWNS_PARSE_FAIL wrapper")
		quit(1)
		return
	count+=1
	for id: String in ["openworld_redrock_town","openworld_desert_city","openworld_lanxi_zhai"]:
		var definition: SceneScript=load(ROOT+id+".tres")
		if definition==null or definition.scene_id!=StringName(id) or not definition.is_settlement:
			push_error("THREE_TOWNS_PARSE_FAIL "+id)
			quit(1)
			return
		count+=1
	var registry: GDScript=load(ROOT+"town_registry.gd")
	if not registry.source_valid():
		push_error("THREE_TOWNS_PARSE_FAIL native source binding")
		quit(1)
		return
	print("THREE_TOWNS_PARSE_READY checks=",count+1," engine_scope=parse_only saves=0 input=0")
	quit(0)
