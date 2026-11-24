extends SceneTree

func _initialize() -> void:
	var path := "res://build/joint_world_luoyang_20261003_qa/v9d_before_independent_revision4_20261004_01/source_ready_v9d_revision4.json"
	var ledger: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not ledger is Dictionary or not ledger.get("sources") is Array or ledger.sources.size() != 15:
		push_error("Exactly thirteen source records and two new city entries required")
		quit(1)
		return
	var passed := true
	for row: Dictionary in ledger.sources:
		var source: String = "res://" + String(row.path).trim_prefix("game/")
		var archived: String = "res://" + String(row.origin_archive_path).trim_prefix("game/")
		var script := ResourceLoader.load(source, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := FileAccess.get_sha256(source).to_lower() == String(row.sha256).to_lower() and FileAccess.get_sha256(archived).to_lower() == String(row.origin_sha256).to_lower() and script != null and script.can_instantiate()
		passed = passed and valid
		print(JSON.stringify({"path":source,"sha256":FileAccess.get_sha256(source),"can_instantiate_and_archive_exact":valid,"scope":"SOURCE_COMPILE_ONLY_NOT_FIELD_FULL_OR_VISUAL"}))
	quit(0 if passed else 1)
