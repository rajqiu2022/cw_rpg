extends SceneTree
## Enumerate the same byte identities the live gate, docks, market and yamen verify.
func _initialize() -> void:
	call_deferred("collect")

func collect() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var out := FileAccess.open(args[0], FileAccess.WRITE)
	if out == null:
		printerr("Cannot write the Windows city resource list: ", args[0])
		quit(1)
		return
	var city := load("res://scripts/city/luoyang_layered_v3_contract.gd")
	for id: String in city.LEGACY_SHAS:
		var scene := load("res://data/scenes/%s.tres" % id)
		if scene == null:
			printerr("Cannot load city scene ", id)
			quit(2)
			return
		var assets: Dictionary = city._transition_sources(scene, false)
		print("Windows city dependencies ", id, ": ", assets.size())
		if assets.is_empty():
			quit(2)
			return
		for path: String in assets:
			if not path.begins_with("res://") or not FileAccess.file_exists(path):
				printerr("Missing required city input ", path)
				quit(3)
				return
			out.store_line(path.trim_prefix("res://"))
	out.close()
	quit()
