extends SceneTree
const C = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	for id: String in C.LEGACY_SHAS:
		var path: String = C.candidate_path(StringName(id))
		var scene := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as SceneScript
		var valid: bool = C.is_v3(scene) and C.runtime_fidelity(scene)
		passed = passed and valid
		print(JSON.stringify({"scope":"FRESH_PROCESS_READ_ONLY_CANDIDATE_LOAD_NOT_FIELD_OR_FULL","id":id,"path":path,"sha256":FileAccess.get_sha256(path),"layout_sha256":FileAccess.get_sha256(C.layout_path(StringName(id))),"runtime_fidelity":valid,"errors":C.errors()}))
		scene = null
	var audio := root.get_node_or_null("AudioManager")
	if audio != null and audio.has_method("stop_bgm"): audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	quit(0 if passed else 1)
