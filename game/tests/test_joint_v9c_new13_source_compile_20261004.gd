extends SceneTree

func _initialize() -> void:
	var ledger_path := "res://build/joint_world_luoyang_20261003_qa/v9c_before_gpu_cache_parsefix_revision2_20261004_01/source_ready_v9c_revision3_parsefix.json"
	var ledger: Variant = JSON.parse_string(FileAccess.get_file_as_string(ledger_path))
	if not ledger is Dictionary or not ledger.get("source_files") is Array or ledger.source_files.size() != 13:
		push_error("Exactly thirteen frozen NEW source records required")
		quit(1)
		return
	var passed := true
	for row: Dictionary in ledger.source_files:
		var path: String = "res://" + String(row.path).trim_prefix("game/")
		var sha: String = FileAccess.get_sha256(path)
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := sha.to_lower() == String(row.sha256).to_lower() and script != null and script.can_instantiate()
		passed = passed and valid
		print(JSON.stringify({"path":path,"sha256":sha,"can_instantiate":valid,"scope":"SOURCE_COMPILE_ONLY_NO_WORLD_CAPTURE_FIELD_FULL_OR_APPROVAL"}))
	quit(0 if passed else 1)
