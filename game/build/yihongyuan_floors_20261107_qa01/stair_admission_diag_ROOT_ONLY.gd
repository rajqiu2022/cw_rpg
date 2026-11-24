extends SceneTree

const ENTRY := "res://build/luoyang_regions_20261027d_source01/region_entry.gd"
const DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"

func _initialize() -> void:
	_check.call_deferred()

func _check() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	var entry := load(ENTRY) as GDScript
	var dispatch := load(DISPATCH) as GDScript
	var sha: String = dispatch.call("author_sha", root.get_node("SceneRouter"))
	var upstairs: Dictionary = entry.call("prepare_authored", {"region_id":"yihongyuan27n_upper","logical_id":"yihongyuan27n_upper","foot_px":[768,832]}, sha)
	entry.call("abort_pending")
	var downstairs: Dictionary = entry.call("prepare_authored", {"region_id":"yihongyuan27n_interior","logical_id":"yihongyuan27n_interior","foot_px":[416,576]}, sha)
	entry.call("abort_pending")
	print(JSON.stringify({"up":upstairs,"down":downstairs,"sha":sha}))
	quit(0 if upstairs.get("ok") == true and downstairs.get("ok") == true else 1)
