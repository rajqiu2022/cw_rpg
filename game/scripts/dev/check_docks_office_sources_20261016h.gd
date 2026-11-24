extends SceneTree
## ROOT-only: parse/dynamic-load source check, never creates a Field or map.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	for path: String in ["res://scripts/city/luoyang_docks_office_roles_20261016h.gd","res://scripts/city/luoyang_harbour_life_runtime_20261016.gd"]:
		var source: Script=load(path) as Script
		if source==null or not source.can_instantiate(): printerr("DOCKS_OFFICE_SCRIPT_REFUSED ",path); quit(1); return
	var helper: Script=load("res://scripts/city/luoyang_docks_office_roles_20261016h.gd") as Script
	print(JSON.stringify({"can_instantiate":true,"formal":helper.FORMAL_ENABLED,"candidate":helper.enabled(),"author_ready":not helper.author().is_empty(),"source_only_not_Field":true}))
	quit(0)
