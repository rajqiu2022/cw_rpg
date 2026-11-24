extends SceneTree
## ROOT-only dynamic compile check; no bundle load, authoring or Field.
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var failures: int=0
	for path: String in ["res://build/luoyang_loading_10s_20261018r_system01/bundle_helper_candidate.gd","res://build/luoyang_loading_10s_20261018r_system01/C_candidate.gd","res://build/luoyang_loading_10s_20261018r_system01/publish_bundle_candidate.gd"]:
		var script: Script=load(path) as Script
		var ok: bool=script!=null and script.can_instantiate()
		print("R_CANDIDATE_SOURCE ",path," can_instantiate=",ok)
		if not ok: failures+=1
	quit(0 if failures==0 else 1)
