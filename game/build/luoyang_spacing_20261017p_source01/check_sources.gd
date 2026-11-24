extends SceneTree
## ROOT-only normal headless context for autoload names; no scene setup.
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var ok: bool=true
	for path: String in ["res://scripts/city/luoyang_building_spacing_20261017p.gd","res://build/luoyang_spacing_20261017p_source01/harbour_candidate.gd","res://build/luoyang_spacing_20261017p_source01/district_candidate.gd","res://build/luoyang_spacing_20261017p_source01/publish_spacing.gd"]:
		var script: Script=load(path) as Script
		var valid: bool=script!=null and script.can_instantiate()
		print(JSON.stringify({"path":path,"can_instantiate":valid})); ok=ok and valid
	quit(0 if ok else 1)
