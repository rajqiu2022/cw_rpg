extends SceneTree
## SOURCE UNIT ONLY. No approval documents, candidate resources, gameplay or saves
## are written. The exact current walker is compiled with an in-memory filesystem
## adapter so BOTH approval paths exist: absence cannot make this test pass.
const GATE_PATH: String = "res://scripts/dev/joint_world_city_v15_acceptance.gd"
const GATE_SHA: String = "af4a20998d0fe6c02322ecfab8f08b8e622330c51cdde53c06442c669bd00926"
const VISUAL: String = "res://data/maps/joint_world_city_v15_visual_review.json"
const TECHNICAL: String = "res://data/maps/joint_world_city_v15_technical_review.json"
const WORLD_REVIEW: String = "res://data/maps/world_map_v15_complete_v7_visual_review.json"
var checks: int = 0
var failures: int = 0
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[approval dependency SOURCE UNIT] " + label)

func _protected_files() -> Dictionary:
	var paths: Array[String] = [GATE_PATH, VISUAL, TECHNICAL, WORLD_REVIEW,
		"res://data/scenes/world_map_jianghu.tres",
		"res://data/scenes/ch4_s0_luoyang_gate.tres",
		"res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s2_canal_docks.tres",
		"res://data/scenes/ch4_s3_luoyang_market.tres",
		"res://data/config/outskirts_native_adoption.json"]
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			paths.append("user://save_%d.json%s" % [slot, suffix])
	var result: Dictionary = {}
	for path: String in paths:
		var row: Dictionary = {"exists":FileAccess.file_exists(path)}
		if row.exists:
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			row["readable"] = file != null
			row["size"] = file.get_length() if file != null else -1
			row["sha256"] = FileAccess.get_sha256(path)
			row["modified_seconds"] = FileAccess.get_modified_time(path)
			if file != null: file.close()
		result[path] = row
	return result

func _walker(source: String) -> String:
	var start: int = source.find("static func _dependency_tree(")
	if start < 0: return ""
	var end: int = source.find("\nstatic func ", start + 1)
	return source.substr(start, end - start) if end >= 0 else source.substr(start)

func _control_source(walker: String) -> String:
	# Only filesystem access and append persistence are adapted. The exact guard,
	# regex, recursive traversal, existence handling and return logic are retained.
	var adapted: String = walker.replace("FileAccess.get_file_as_string", "_fixture_text").replace("FileAccess.file_exists", "_fixture_exists")
	return "extends RefCounted\nconst VISUAL_REVIEW: String = %s\nconst TECHNICAL_REVIEW: String = %s\nstatic var contents: Dictionary = {}\nstatic func configure(value: Dictionary) -> void:\n\tcontents = value.duplicate(true)\nstatic func _fixture_text(path: String) -> String:\n\treturn String(contents.get(path, \"\"))\nstatic func _fixture_exists(path: String) -> bool:\n\treturn contents.has(path)\nstatic func _append(result: Dictionary, path: String) -> bool:\n\tif not contents.has(path): return false\n\tresult[path] = String(contents[path]).sha256_text()\n\treturn true\n%s" % [JSON.stringify(VISUAL), JSON.stringify(TECHNICAL), adapted]

func _case(control: GDScript, name: String, fixtures: Dictionary, root_path: String, expected: Array[String]) -> void:
	control.call("configure", fixtures)
	var result: Dictionary = {}
	var visited: Dictionary = {}
	var success: bool = bool(control.call("_dependency_tree", result, root_path, visited))
	_check(success, name + " completes exact walker")
	_check(result.size() == expected.size(), name + " exact dependency count")
	for path: String in expected:
		_check(result.has(path) and result[path] == String(fixtures[path]).sha256_text(), name + " exact included bytes: " + path)
	_check(not result.has(VISUAL) and not result.has(TECHNICAL), name + " only exact joint approval documents excluded")
	records.append({"name":name,"all_fixture_paths_exist":true,"result":result.duplicate(true),"visited":visited.duplicate(true),"expected_paths":expected.duplicate(),"production_snapshot_executed":false})
	control.call("configure", {})

func _run() -> void:
	var before: Dictionary = _protected_files()
	var manager: Node = root.get_node_or_null("SaveManager")
	var before_slot: Variant = manager.get("active_slot") if manager != null else null
	_check(FileAccess.get_sha256(GATE_PATH).to_lower() == GATE_SHA, "exact root-patched gate source SHA")
	var source: String = FileAccess.get_file_as_string(GATE_PATH)
	var walker: String = _walker(source)
	_check(not walker.is_empty() and walker.count("if dependency in [VISUAL_REVIEW, TECHNICAL_REVIEW]: continue") == 1, "exact two-path guard occurs once in actual walker")
	var control: GDScript = GDScript.new()
	control.source_code = _control_source(walker)
	var compile_error: Error = control.reload()
	_check(compile_error == OK and control.can_instantiate(), "exact walker filesystem-only adapter compiles")
	if compile_error == OK and control.can_instantiate():
		var ordinary: String = "res://fixture/ordinary.tres"
		var nested: String = "res://fixture/nested.gd"
		var nested_asset: String = "res://fixture/nested.png"
		var lookalike: String = VISUAL + ".copy.json"
		var root_path: String = "res://fixture/root.gd"
		var fixtures: Dictionary = {
			root_path:"const A='%s'\nconst B=\"%s\"\nconst W='%s'\nconst R='%s'\nconst N='%s'\nconst L='%s'\n" % [VISUAL, TECHNICAL, WORLD_REVIEW, ordinary, nested, lookalike],
			VISUAL:"{\"exists_but_must_not_hash\":true}",
			TECHNICAL:"{\"exists_but_must_not_hash\":true}",
			WORLD_REVIEW:"{\"world_review_remains_bound\":true}",
			ordinary:"ordinary fixture bytes", nested:"const R='%s'\nconst Cycle='%s'\n" % [nested_asset,root_path],
			nested_asset:"nested PNG fixture bytes", lookalike:"similar name is not an approval exclusion"}
		_case(control, "all-present approvals plus world/normal/nested/cycle", fixtures, root_path, [WORLD_REVIEW,ordinary,nested,nested_asset,lookalike,root_path])
		var reversed: Dictionary = fixtures.duplicate(true)
		reversed[root_path] = "const B='%s'\nconst A='%s'\nconst W='%s'\n" % [TECHNICAL,VISUAL,WORLD_REVIEW]
		_case(control, "reversed exact approval paths", reversed, root_path, [WORLD_REVIEW])
		var altered: Dictionary = fixtures.duplicate(true)
		altered[WORLD_REVIEW] = "world review changed independent bytes"
		control.call("configure", fixtures)
		var first: Dictionary = {}
		_check(bool(control.call("_dependency_tree", first, root_path, {})), "original world-review dependency control")
		control.call("configure", altered)
		var second: Dictionary = {}
		_check(bool(control.call("_dependency_tree", second, root_path, {})), "changed world-review dependency control")
		_check(first.has(WORLD_REVIEW) and second.has(WORLD_REVIEW) and first[WORLD_REVIEW] != second[WORLD_REVIEW], "world review mutation changes exact dependency hash")
		control.call("configure", {})
	# The real production walker is also invoked against a small existing item;
	# fixture adaptation above is separately labelled and never called FULL.
	var gate: GDScript = load(GATE_PATH) as GDScript
	_check(gate != null and gate.can_instantiate(), "actual gate loads in deferred autoload context")
	if gate != null and gate.can_instantiate():
		var actual: Dictionary = {}
		_check(bool(gate.call("_dependency_tree", actual, "res://data/items/zhuwei_map.tres", {})), "actual filesystem production walker executes on readonly item resource")
		var item_script: String = "res://scripts/domain/item.gd"
		_check(actual.has(item_script) and actual[item_script] == FileAccess.get_sha256(item_script), "normal actual item script remains SHA-bound")
		_check(not actual.has(VISUAL) and not actual.has(TECHNICAL), "actual closure excludes both exact joint approvals if present")
		var mandatory: Array = gate.get_script_constant_map().get("SYSTEM_PATHS", [])
		_check(mandatory.has(GATE_PATH) and mandatory.has("res://scripts/dev/publish_luoyang_layered_v3.gd"), "mandatory gate and historical publisher source paths retained")
		_check(source.contains("WORLD_GATE.REVIEW") and source.contains("WORLD.CANDIDATE_PATH"), "world review and candidate explicit mandatory snapshot roots retained")
	gate = null
	control = null
	for frame in 8: await process_frame
	await _natural_audio_cleanup()
	_check(before == _protected_files(), "approval/formal/source and all fifteen player paths unchanged")
	_check(manager == null or manager.get("active_slot") == before_slot, "active save slot unchanged")
	print(JSON.stringify({"scope":"SOURCE_UNIT_APPROVAL_DEPENDENCY_EXCLUSION_NOT_FIELD_OR_APPROVAL","checks":checks,"failed":failures,"gate_sha256":GATE_SHA,"in_memory_control_only":true,"records":records,"actual_protected_files_unchanged":before==_protected_files(),"approval_documents_written":false,"production_snapshot_executed":false}))
	print("JOINT_APPROVAL_DEPENDENCY_SOURCE_UNIT: %d checks / %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _natural_audio_cleanup() -> void:
	# SOURCE assertions are finished. Allow the autoload's existing warmup/audio
	# continuations normal wall-clock stages; do not cancel timers or clear caches.
	var began: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - began < 9000000:
		await process_frame
	var audio: Node = root.get_node_or_null("AudioManager")
	_check(audio != null, "normal public AudioManager cleanup exists after source assertions")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
