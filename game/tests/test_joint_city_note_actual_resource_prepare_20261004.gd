extends SceneTree
const C = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	for id: String in C.MANIFEST_SHAS:
		var valid := C.prepare(StringName(id))
		passed = passed and valid
		print(JSON.stringify({"region":id,"actual_prepare":valid,"errors":C.errors(),"manifest_sha256":C.MANIFEST_SHAS[id],"scope":"ACTUAL_READONLY_RESOURCE_PREPARE_NOT_FIELD_INPUT_OR_PUBLICATION"}))
	quit(0 if passed else 1)
