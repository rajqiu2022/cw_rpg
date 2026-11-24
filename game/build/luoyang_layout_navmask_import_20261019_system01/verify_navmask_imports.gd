extends SceneTree
## ROOT-only isolated verifier for exactly two published Luoyang NAV masks.
## No geometry replay, no per-pixel alpha loop, no production or save writes.

const LIMIT_MS: int = 30000
const PREPARED_SHA: String = "d95b10d1986f705b2f3a1f845997d049fda23a86c73d5d5e9a8509945a7749c4"

var _started: int = 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _require(value: bool, label: String) -> void:
	if not value:
		failures.append(label)

func _sha(bytes: PackedByteArray) -> String:
	var hash: HashingContext = HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

func _snapshot(paths: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for path: String in paths:
		result[path] = {
			"exists": FileAccess.file_exists(path),
			"sha256": FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "",
		}
	return result

func _run() -> void:
	_started = Time.get_ticks_msec()
	var output: String = "res://navmask_import_result_" + str(OS.get_process_id()) + ".json"
	_require(FileAccess.get_sha256("res://prepared.json") == PREPARED_SHA, "prepared_exact_sha")
	var prepared: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://prepared.json"))
	if not prepared is Dictionary or prepared.get("rows", []).size() != 2 or prepared.get("params23", {}).size() != 23:
		failures.append("prepared_schema")
		_finish(output, {}, {})
		return
	var source_paths: Array[String] = ["res://project.godot", "res://prepared.json", "res://verify_navmask_imports.gd"]
	for row_variant: Variant in prepared.rows:
		if row_variant is Dictionary:
			var seed: Dictionary = row_variant
			source_paths.append(String(seed.texture))
			source_paths.append(String(seed.texture) + ".import")
			source_paths.append(String(seed.compiled_path))
	var source_first: Dictionary = _snapshot(source_paths)
	var seen: Dictionary = {}
	for row_variant: Variant in prepared.rows:
		if not row_variant is Dictionary:
			failures.append("row_not_dictionary")
			continue
		var seed: Dictionary = row_variant
		var scene_id: String = String(seed.get("scene_id", ""))
		var path: String = String(seed.get("texture", ""))
		var prefix: String = scene_id + ":"
		_require(not scene_id.is_empty() and not seen.has(scene_id), prefix + "unique_scene_id")
		seen[scene_id] = true
		_require(path.begins_with("res://data/maps/luoyang_layout_bundle_20261018t_retry2/" + scene_id + "/"), prefix + "same_res_path")
		_require(FileAccess.get_sha256(path) == seed.get("source_sha256", ""), prefix + "png_exact_sha")
		_require(String(seed.get("packet_walk_bytes_sha256", "")).length() == 64, prefix + "packet_walk_sha_literal")
		_require(String(seed.get("packet_sha256", "")).length() == 64, prefix + "packet_sha_literal")
		var config: ConfigFile = ConfigFile.new()
		if config.load(path + ".import") != OK:
			failures.append(prefix + "import_load")
			continue
		var exact_params: bool = config.get_section_keys("params").size() == 23
		_require(exact_params, prefix + "exact23params_count")
		for key: String in prepared.params23:
			var matches: bool = config.get_value("params", key, null) == prepared.params23[key]
			exact_params = exact_params and matches
			_require(matches, prefix + "param:" + key)
		var compiled: String = String(config.get_value("remap", "path", ""))
		_require(compiled == seed.get("compiled_path", "") and FileAccess.file_exists(compiled), prefix + "exact_compiled_identity")
		_require(config.get_value("remap", "importer", "") == "texture", prefix + "importer_texture")
		_require(config.get_value("remap", "type", "") == "CompressedTexture2D", prefix + "type_compressed_texture_2d")
		_require(config.get_value("deps", "source_file", "") == path, prefix + "deps_source_identity")
		var dest: Variant = config.get_value("deps", "dest_files", null)
		_require((dest is Array or dest is PackedStringArray) and dest.size() == 1 and String(dest[0]) == compiled, prefix + "deps_single_ctex")
		var raw: Image = Image.load_from_file(path)
		var texture: Texture2D = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var direct: CompressedTexture2D = CompressedTexture2D.new()
		var direct_error: Error = direct.load(compiled)
		_require(raw != null, prefix + "raw_png_load")
		_require(texture != null, prefix + "resource_loader_texture")
		_require(direct_error == OK, prefix + "direct_native_ctex_load")
		var imported: Image = texture.get_image() if texture != null else null
		var native: Image = direct.get_image() if direct_error == OK else null
		var size: Vector2i = Vector2i(int(prepared.size_px[0]), int(prepared.size_px[1]))
		var format_rgba8: bool = raw != null and imported != null and native != null and raw.get_format() == Image.FORMAT_RGBA8 and imported.get_format() == Image.FORMAT_RGBA8 and native.get_format() == Image.FORMAT_RGBA8
		var dimensions_exact: bool = raw != null and imported != null and native != null and raw.get_size() == size and imported.get_size() == size and native.get_size() == size
		var mipmap_count: int = -1
		var full_rgba_exact: bool = false
		var rgba_sha256: String = ""
		if format_rgba8 and dimensions_exact:
			var raw_bytes: PackedByteArray = raw.get_data()
			var imported_bytes: PackedByteArray = imported.get_data()
			var native_bytes: PackedByteArray = native.get_data()
			rgba_sha256 = _sha(raw_bytes)
			full_rgba_exact = raw_bytes == imported_bytes and raw_bytes == native_bytes and rgba_sha256 == seed.packet_walk_bytes_sha256
			mipmap_count = maxi(raw.get_mipmap_count(), maxi(imported.get_mipmap_count(), native.get_mipmap_count()))
		_require(format_rgba8, prefix + "all_images_rgba8")
		_require(dimensions_exact, prefix + "all_images_3072x2048")
		_require(mipmap_count == int(prepared.expected_mipmap_count), prefix + "all_images_mipmap_count_zero")
		_require(full_rgba_exact, prefix + "raw_import_direct_ctex_full_rgba_equals_packet_walk_bytes")
		rows.append({
			"scene_id": scene_id,
			"texture": path,
			"source_sha256": FileAccess.get_sha256(path),
			"import_path": path + ".import",
			"import_sha256": FileAccess.get_sha256(path + ".import"),
			"compiled_path": compiled,
			"compiled_sha256": FileAccess.get_sha256(compiled),
			"size_px": [size.x, size.y],
			"format": "RGBA8" if format_rgba8 else "NOT_RGBA8",
			"rgba_sha256": rgba_sha256,
			"packet_path": seed.packet_path,
			"packet_sha256": seed.packet_sha256,
			"packet_walk_bytes_sha256": seed.packet_walk_bytes_sha256,
			"full_rgba_exact": full_rgba_exact,
			"params23": exact_params,
			"mipmap_count": mipmap_count,
			"report_path": output,
			"verifier_path": "res://verify_navmask_imports.gd",
			"verifier_sha256": FileAccess.get_sha256("res://verify_navmask_imports.gd"),
		})
		texture = null
		direct = null
		raw = null
		imported = null
		native = null
	var source_final: Dictionary = _snapshot(source_paths)
	_require(source_first == source_final, "all_sources_first_final_exact")
	_require(Time.get_ticks_msec() - _started < LIMIT_MS, "original30s_budget")
	_finish(output, source_first, source_final)

func _finish(output: String, source_first: Dictionary, source_final: Dictionary) -> void:
	var passed: bool = failures.is_empty() and rows.size() == 2
	var report: Dictionary = {
		"passed": passed,
		"failures": failures,
		"rows": rows,
		"prepared_sha256": FileAccess.get_sha256("res://prepared.json"),
		"project_sha256": FileAccess.get_sha256("res://project.godot"),
		"verifier_path": "res://verify_navmask_imports.gd",
		"verifier_sha256": FileAccess.get_sha256("res://verify_navmask_imports.gd"),
		"actual_geometry_result_path": "res://build/luoyang_layout_quest_publication_20261018t/110780/result.json",
		"actual_geometry_result_sha256": "1145360fa730b0fd654f69bffe14c7ad02e04d578e37b70c9ef043a1d6fdc8a9",
		"source_first": source_first,
		"source_final": source_final,
		"elapsed_ms": Time.get_ticks_msec() - _started,
		"limit_ms": LIMIT_MS,
		"status": "ISOLATED_TWO_NAVMASK_IMPORT_ONLY_NOT_RUNTIME_NOT_GEOMETRY_REPLAY",
	}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		print("NAV mask import report write refused")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t", true, true))
	file.close()
	print(JSON.stringify({"passed": passed, "failures": failures, "rows": rows.size(), "output": output}))
	quit(0 if passed else 1)
