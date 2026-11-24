extends SceneTree
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var failures:=0
	for path: String in ["res://scripts/world/world_v15_visible_stream_20261018r.gd","res://scripts/world/world_v15_stream_overlap_20261018r.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/autoload/loading_manager.gd","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/city/luoyang_precomputed_bundle_20261018r.gd","res://build/luoyang_loading_10s_20261018r_system01/revision4/publish_bundle_candidate.gd"]:
		var source: Script=load(path) as Script
		var ok: bool=source!=null and source.can_instantiate()
		print("R_FINAL_COMPILE ",path," ",ok)
		if not ok: failures+=1
	quit(0 if failures==0 else 1)
