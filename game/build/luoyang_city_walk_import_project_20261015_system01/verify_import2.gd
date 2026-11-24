extends SceneTree
## NEW isolated two published walk PNG import verification.
## Adapted from the frozen 648996E5 farmland retry2 verifier; original unchanged.
## ROOT alone may execute import/verify. No game autoloads or production writes.
const PREPARED_PATH := "res://prepared2.json"
const PREPARED_SHA := "d9692cbcbee26d1cbde39492f5359a0840d55d02f34b8671e03bf47e966e4621"
const PROJECT_SHA := "5377449262242838785ed29f7802648272663f36aedd95645f2e2ab7bdad4bca"
const IDS := ["market", "docks"]
const PATHS := {
	"market": "res://art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/walk.png",
	"docks": "res://art/maps/luoyang_city_revision_v1_20261015/ch4_s2_canal_docks/walk.png"
}
const SOURCE_SHAS := {
	"market": "554a863d0c53510533b02eb2cadf58121b75ed5e20b5fc462ef82966e37ae4a3",
	"docks": "0077ddcc3069e51198f06f418db132b6131a0b4184ba6494f0d70e500c318c08"
}
const PARAMS := {
	"compress/mode": 0, "compress/high_quality": false,
	"compress/lossy_quality": 0.7, "compress/uastc_level": 0,
	"compress/rdo_quality_loss": 0.0, "compress/hdr_compression": 1,
	"compress/normal_map": 0, "compress/channel_pack": 0,
	"mipmaps/generate": false, "mipmaps/limit": -1,
	"roughness/mode": 0, "roughness/src_normal": "",
	"process/channel_remap/red": 0, "process/channel_remap/green": 1,
	"process/channel_remap/blue": 2, "process/channel_remap/alpha": 3,
	"process/fix_alpha_border": false, "process/premult_alpha": false,
	"process/normal_map_invert_y": false, "process/hdr_as_srgb": false,
	"process/hdr_clamp_exposure": false, "process/size_limit": 0,
	"detect_3d/compress_to": 0
}
const BUDGET_MS := 60000
var started: int
var failures: Array[String] = []
var checks := 0
var evidence: Array[Dictionary] = []

func _initialize() -> void:
	started = Time.get_ticks_msec()
	_run.call_deferred()

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("[ISOLATED LUOYANG WALK IMPORT2] " + label)
	return ok

func _hash(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(data) != OK: return "HASH_ERROR"
	return context.finish().hex_encode()

func _row(row: Dictionary, id: String) -> void:
	var path: String = row.get("path", "")
	var expected: String = row.get("sha256", "")
	var size := Vector2i(3072, 2048)
	if not _check(path == PATHS[id] and expected == SOURCE_SHAS[id] and FileAccess.get_sha256(path) == expected, "Exact published PNG copy " + id): return
	var import_path := path + ".import"
	var import_sha := FileAccess.get_sha256(import_path)
	var config := ConfigFile.new()
	if not _check(config.load(import_path) == OK and import_sha.length() == 64, "Actual import sidecar " + id): return
	var params: Dictionary = {}
	var param_ok: bool = config.has_section("params")
	var keys: PackedStringArray = config.get_section_keys("params") if param_ok else PackedStringArray()
	param_ok = param_ok and keys.size() == PARAMS.size()
	for key: String in keys:
		params[key] = config.get_value("params", key)
		param_ok = param_ok and PARAMS.has(key) and typeof(params[key]) == typeof(PARAMS.get(key)) and params[key] == PARAMS.get(key)
	_check(param_ok, "Strict complete lossless/no-mip/no-alpha-fix parameters " + id)
	var compiled_path: String = config.get_value("remap", "path", "")
	var dest: Variant = config.get_value("deps", "dest_files", null)
	var metadata: Variant = config.get_value("remap", "metadata", null)
	var dest_ok: bool = (dest is Array or dest is PackedStringArray) and dest.size() == 1 and dest[0] == compiled_path
	var binding_ok: bool = compiled_path.begins_with("res://.godot/imported/") and compiled_path.ends_with(".ctex") and config.get_value("remap", "importer", "") == "texture" and config.get_value("remap", "type", "") == "CompressedTexture2D" and config.get_value("deps", "source_file", "") == path and dest_ok and metadata is Dictionary and metadata.get("vram_texture") == false
	if not _check(binding_ok and FileAccess.file_exists(compiled_path), "Actual source/remap/deps/compiled binding " + id): return
	var compiled_sha := FileAccess.get_sha256(compiled_path)
	var source := Image.load_from_file(path)
	if not _check(source != null and source.get_format() == Image.FORMAT_RGBA8 and source.get_size() == size and source.get_mipmap_count() == 0, "Actual bounded original PNG RGBA8/no-mip " + id): return
	var texture := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if not _check(texture != null and texture is CompressedTexture2D and texture.resource_path == path and texture.get_size() == Vector2(size), "Actual ResourceLoader imported texture " + id): return
	var imported := texture.get_image()
	var full_exact: bool = imported != null and not imported.is_compressed() and imported.get_format() == Image.FORMAT_RGBA8 and imported.get_size() == size and imported.get_mipmap_count() == 0 and imported.get_data() == source.get_data()
	_check(full_exact, "Every source/imported RGBA byte exact " + id)
	var direct := CompressedTexture2D.new()
	var direct_load: Error = direct.load(compiled_path)
	var compiled_image := direct.get_image() if direct_load == OK else null
	var compiled_exact: bool = direct_load == OK and direct is CompressedTexture2D and compiled_image != null and not compiled_image.is_compressed() and compiled_image.get_format() == Image.FORMAT_RGBA8 and compiled_image.get_size() == size and compiled_image.get_mipmap_count() == 0 and compiled_image.get_data() == source.get_data()
	_check(compiled_exact, "Exact direct compiled import pixels " + id)
	_check(FileAccess.get_sha256(path) == expected and FileAccess.get_sha256(import_path) == import_sha and FileAccess.get_sha256(compiled_path) == compiled_sha, "Source/import/compiled unchanged after real loading " + id)
	evidence.append({"id": id, "path": path, "source_sha256": expected, "import_path": import_path, "import_sha256": import_sha, "compiled_path": compiled_path, "compiled_sha256": compiled_sha, "full_RGBA_exact": full_exact and compiled_exact, "source_RGBA_sha256": _hash(source.get_data()), "imported_RGBA_sha256": _hash(imported.get_data()) if imported != null else "NO_IMAGE", "compiled_RGBA_sha256": _hash(compiled_image.get_data()) if compiled_image != null else "NO_IMAGE", "mipmap_count": imported.get_mipmap_count() if imported != null else -1, "size": [size.x, size.y], "params": params, "params_exact": param_ok, "compiled_identity_exact": binding_ok and compiled_exact})
	_check(Time.get_ticks_msec() - started < BUDGET_MS, "Shared60s after actual import row " + id)

func _run() -> void:
	if not _check(FileAccess.get_sha256(PREPARED_PATH) == PREPARED_SHA and FileAccess.get_sha256("res://project.godot") == PROJECT_SHA, "Pinned prepared2 and standalone no-autoload project"):
		_finish(); return
	var config := ConfigFile.new()
	_check(config.load("res://project.godot") == OK and not config.has_section("autoload"), "Standalone project has no game autoloads")
	var prepared: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREPARED_PATH))
	if not _check(prepared is Dictionary and prepared.get("schema") == 1 and prepared.get("scope") == "PREPARED2_CITY_WALK_ISOLATED_IMPORT_NOT_APPROVED" and prepared.get("approved") == false and prepared.get("approved_by") == "" and prepared.get("no_game_source_or_import_writes") == true and prepared.get("no_autoloads") == true, "Prepared contract is not import/adoption approval"):
		_finish(); return
	var entries: Array = prepared.get("entries", [])
	if not _check(entries.size() == 2 and PARAMS.size() == 23, "Exactly two published walk PNG copies and all23 parameters"):
		_finish(); return
	for index in entries.size():
		var row: Dictionary = entries[index]
		if _check(row.get("id") == IDS[index], "Ordered distinct walk identity " + IDS[index]): _row(row, IDS[index])
	_finish()

func _finish() -> void:
	_check(evidence.size() == 2, "Both actual import receipts complete")
	_check(FileAccess.get_sha256(PREPARED_PATH) == PREPARED_SHA and FileAccess.get_sha256("res://project.godot") == PROJECT_SHA, "Prepared/project unchanged after all reads")
	_check(Time.get_ticks_msec() - started < BUDGET_MS, "Complete isolated import verify within60s")
	var report := {"schema": 1, "scope": "ROOT_ACTUAL2_CITY_WALK_RESOURCELOADER_NATIVE_CTEX_FULL_RGBA_NOT_ADOPTION", "passed": failures.is_empty(), "approved": false, "approved_by": "", "prepared_path": PREPARED_PATH, "prepared_sha256": PREPARED_SHA, "project_sha256": PROJECT_SHA, "driver_path": get_script().resource_path, "driver_sha256": FileAccess.get_sha256(get_script().resource_path), "engine_path": OS.get_executable_path(), "engine_sha256": FileAccess.get_sha256(OS.get_executable_path()), "engine_pid": OS.get_process_id(), "checks": checks, "failures": failures.duplicate(), "rows": evidence, "elapsed_ms": Time.get_ticks_msec() - started, "budget_ms": BUDGET_MS, "no_autoloads": true, "no_production_or_game_NAV_or_save_writes": true, "import_or_repair_requested_by_driver": false}
	var path := "res://rootboundproof2_%d_%d.json" % [OS.get_process_id(), started]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save isolated root-bound two-walk evidence"); quit(1); return
	file.store_string(JSON.stringify(report, "\t")); file.flush(); file.close()
	print("ISOLATED_LUOYANG_WALK_IMPORT2_RESULT=", path, " passed=", report.passed, " rows=", evidence.size(), " failures=", failures.size(), " elapsed_ms=", report.elapsed_ms)
	quit(0 if failures.is_empty() else 1)
