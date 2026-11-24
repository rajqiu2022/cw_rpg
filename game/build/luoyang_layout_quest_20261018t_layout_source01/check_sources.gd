extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var rows: Array=[]; var ok: bool=true
	for name: String in ["layout_transform.gd","room_successors.gd","g_geometry_original.gd","g_facade_candidate.gd","bundle_helper_candidate.gd","C_candidate.gd","District_candidate.gd","District_fade_candidate.gd","assembled_rooms_candidate.gd","room_index_candidate.gd","bundle_index_candidate.gd"]:
		var path: String="res://build/luoyang_layout_quest_20261018t_layout_source01/"+name
		var script: Script=load(path) as Script
		var passed: bool=script!=null and script.can_instantiate()
		rows.append({"path":path,"sha256":FileAccess.get_sha256(path),"can_instantiate":passed})
		ok=ok and passed
	print(JSON.stringify({"passed":ok,"source_only_not_geometry_or_runtime":true,"scripts":rows})); quit(0 if ok else 1)
