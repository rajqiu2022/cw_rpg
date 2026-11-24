extends SceneTree
## Candidate resources only. Canonical scene IDs/actions retained, no cutover.
const C = preload("res://scripts/city/luoyang_layered_v3_contract.gd")

func _initialize() -> void:
	call_deferred("_publish")

func _publish() -> void:
	if "--activate" in OS.get_cmdline_user_args() or not "--publish-candidate" in OS.get_cmdline_user_args(): _fail("Explicit candidate publication required; formal activation is separate"); return
	var candidates: Dictionary = {}
	# Validate all four before writing any candidate. Pending manifests cannot
	# create a partial set or replace any canonical/legacy resource.
	for id: String in C.LEGACY_SHAS:
		var scene: SceneScript = C.materialize(StringName(id))
		if scene == null: _fail("City NOT_READY: " + id + "; " + "; ".join(C.errors())); return
		candidates[id] = scene
	for id: String in candidates:
		var candidate_path: String = C.candidate_path(StringName(id))
		var layout_path: String = C.layout_path(StringName(id))
		if FileAccess.file_exists(candidate_path) or FileAccess.file_exists(layout_path):
			var current: SceneScript = ResourceLoader.load(candidate_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
			if not C.is_v3(current) or not C.runtime_fidelity(current): _fail("Existing candidate differs; preserve it and explicitly archive before new publication: " + id); return
	for id: String in candidates:
		var scene: SceneScript = candidates[id]
		var candidate_path: String = C.candidate_path(StringName(id))
		if FileAccess.file_exists(candidate_path): continue # Reuse exact validated set.
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(candidate_path.get_base_dir())) != OK: _fail("Cannot create independent candidate directory"); return
		scene.map_layout.take_over_path(C.layout_path(StringName(id)))
		if ResourceSaver.save(scene.map_layout, C.layout_path(StringName(id))) != OK or ResourceSaver.save(scene, candidate_path) != OK: _fail("Independent city candidate write failed: " + id); return
		var current: SceneScript = ResourceLoader.load(candidate_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not C.is_v3(current) or current.scene_id != StringName(id) or not C.runtime_fidelity(current): _fail("Fresh city candidate lost native/gameplay binding: " + id); return
	print("LUOYANG_V3_FOUR_NORMAL_GAMEPLAY_CANDIDATES_PUBLISHED_NOT_ACTIVATED")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
