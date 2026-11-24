extends SceneTree
## Independent four-city candidate paths. Never changes formal/old candidates.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")

func _initialize() -> void: call_deferred("_publish")
func _publish() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): _fail("Public checkpoint guard unavailable"); return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true: _fail("Public checkpoint guard not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not "--publish-candidate" in args or not C.CANDIDATE_FLAG in args or "--activate" in args: _fail("Explicit NEW candidate publication only"); return
	var candidates: Dictionary = {}
	for id: String in C.LEGACY_SHAS:
		var scene: SceneScript = C.materialize(StringName(id))
		if scene == null: _fail("City NOT_READY: " + id + "; " + "; ".join(C.errors())); return
		candidates[id] = scene
	# Validate all four before any write; exact existing resources may be reused.
	for id: String in candidates:
		var path: String = C.candidate_path(StringName(id)); var layout: String = C.layout_path(StringName(id))
		if FileAccess.file_exists(path) or FileAccess.file_exists(layout):
			var current: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
			if current == null or not C.runtime_fidelity(current) or current.map_layout.resource_path != layout: _fail("Existing independent V11 resource differs; preserve and choose NEW revision"); return
	for id: String in candidates:
		var path: String = C.candidate_path(StringName(id)); var layout: String = C.layout_path(StringName(id))
		if FileAccess.file_exists(path): continue
		for directory: String in [path.get_base_dir(), layout.get_base_dir()]:
			if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK: _fail("Independent resource directory creation failed"); return
		var scene: SceneScript = candidates[id]
		scene.map_layout.take_over_path(layout)
		if ResourceSaver.save(scene.map_layout, layout) != OK or ResourceSaver.save(scene, path) != OK: _fail("Independent V11 resource write failed"); return
		var current: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if current == null or not C.runtime_fidelity(current): _fail("Serialized V11 current source/gameplay binding failed"); return
	print("LUOYANG_ENCLOSURE_V11_FOUR_CANDIDATES_PUBLISHED_NOT_ACTIVATED")
	quit(0)
func _fail(error: String) -> void:
	push_error(error); quit(1)
