extends SceneTree
## Root-only isolated verifier for four y static soldier candidates.
## It never opens or writes the main project's .godot directory.

const PREPARED_PATH := "res://prepared.json"
const PREPARED_SHA := "226f38a389e741daa39aaefa4a795251873d7481c790020c87086ff17a145506"
const WHOLE_MS := 15000

var failures: Array[String] = []
var first: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func require(ok: bool, label: String) -> bool:
	if not ok:
		failures.append(label)
	return ok


func sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func source(path: String, expected: String = "") -> bool:
	var actual := FileAccess.get_sha256(path)
	if not require(actual.length() == 64 and (expected.is_empty() or actual == expected), "Exact source " + path):
		return false
	first[path] = actual
	return true


func decoded(image: Image) -> Image:
	if image == null:
		return null
	if image.is_compressed() and not require(image.decompress() == OK, "Lossless native decode"):
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func alpha_rect(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	return Rect2i() if max_x < 0 else Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func edge_alpha_max(image: Image) -> int:
	var result := 0
	for x: int in image.get_width():
		result = maxi(result, roundi(image.get_pixel(x, 0).a * 255.0))
		result = maxi(result, roundi(image.get_pixel(x, image.get_height() - 1).a * 255.0))
	for y: int in image.get_height():
		result = maxi(result, roundi(image.get_pixel(0, y).a * 255.0))
		result = maxi(result, roundi(image.get_pixel(image.get_width() - 1, y).a * 255.0))
	return result


func _run() -> void:
	var began := Time.get_ticks_msec()
	var prepared: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREPARED_PATH))
	require(source(PREPARED_PATH, PREPARED_SHA), "Prepared source")
	source("res://project.godot")
	source(get_script().resource_path)
	require(prepared is Dictionary and prepared.get("status") == "FOUR_STATIC_SOLDIER_ISOLATED_IMPORT_SOURCE_READY_NOT_RUN", "Prepared schema")
	var rows: Array = prepared.get("rows", []) if prepared is Dictionary else []
	var expected_params: Dictionary = prepared.get("params23", {}) if prepared is Dictionary else {}
	require(rows.size() == 4, "Exactly four source rows")
	require(expected_params.size() == 23, "Exactly 23 prepared params")
	var reports: Array[Dictionary] = []
	for row_value: Variant in rows:
		if not require(row_value is Dictionary, "Row dictionary"):
			continue
		var row: Dictionary = row_value
		var texture_path: String = row.get("texture", "")
		var import_path := texture_path + ".import"
		var compiled_path: String = row.get("compiled_path", "")
		var expected_source_sha: String = row.get("source_sha256", "")
		require(source(texture_path, expected_source_sha), "PNG source " + texture_path)
		require(source(import_path), "Actual isolated import " + import_path)
		require(source(compiled_path), "Actual isolated ctex " + compiled_path)
		var config := ConfigFile.new()
		var config_ok := require(config.load(import_path) == OK, "Import config parses " + import_path)
		var params_ok := false
		if config_ok:
			params_ok = require(config.get_section_keys("params").size() == 23, "23 import params " + import_path)
			for key: String in expected_params:
				params_ok = require(config.get_value("params", key, null) == expected_params[key], "Strict param " + key + " " + import_path) and params_ok
			var remap_meta: Variant = config.get_value("remap", "metadata", null)
			var destinations: Variant = config.get_value("deps", "dest_files", null)
			params_ok = require(config.get_value("remap", "importer", "") == "texture", "Texture importer") and params_ok
			params_ok = require(config.get_value("remap", "type", "") == "CompressedTexture2D", "CompressedTexture2D type") and params_ok
			params_ok = require(config.get_value("remap", "path", "") == compiled_path and not config.has_section_key("remap", "path.s3tc"), "Ordinary compiled path") and params_ok
			params_ok = require(remap_meta is Dictionary and remap_meta.get("vram_texture", true) == false, "Non-VRAM metadata") and params_ok
			params_ok = require(config.get_value("deps", "source_file", "") == texture_path and destinations is Array and destinations.size() == 1 and destinations[0] == compiled_path, "Exact dependencies") and params_ok
		var raw := decoded(Image.load_from_file(texture_path))
		var imported_texture := ResourceLoader.load(texture_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var direct_texture := CompressedTexture2D.new()
		var direct_ok := require(direct_texture.load(compiled_path) == OK, "Direct ctex load")
		var imported := decoded(imported_texture.get_image()) if imported_texture != null else null
		var direct := decoded(direct_texture.get_image()) if direct_ok else null
		var rect := Rect2i()
		var edge_max := -1
		var rgba := ""
		var full_rgba_exact := false
		var mipmaps_zero := false
		if raw != null and imported != null and direct != null:
			rect = alpha_rect(raw)
			edge_max = edge_alpha_max(raw)
			rgba = sha(raw.get_data())
			full_rgba_exact = raw.get_size() == Vector2i(160, 160) and raw.get_data() == imported.get_data() and raw.get_data() == direct.get_data()
			mipmaps_zero = raw.get_mipmap_count() == 0 and imported.get_mipmap_count() == 0 and direct.get_mipmap_count() == 0
		var rect_data: Array = row.get("alpha_gt_zero_rect_xywh", [])
		var expected_rect := Rect2i(rect_data[0], rect_data[1], rect_data[2], rect_data[3]) if rect_data.size() == 4 else Rect2i()
		require(full_rgba_exact, "Complete raw/import/direct ctex RGBA exact " + texture_path)
		require(mipmaps_zero, "All zero mipmaps " + texture_path)
		require(rect == expected_rect and rect.size.y == 140 and rect.end.y == 152, "Exact 140px alpha/foot rect " + texture_path)
		require(edge_max == 0, "Transparent canvas edge " + texture_path)
		reports.append({
			"identity": row.get("identity", ""),
			"texture": texture_path,
			"source_sha256": FileAccess.get_sha256(texture_path),
			"import_path": import_path,
			"import_sha256": FileAccess.get_sha256(import_path),
			"compiled_path": compiled_path,
			"compiled_sha256": FileAccess.get_sha256(compiled_path),
			"params23": params_ok,
			"full_rgba_exact": full_rgba_exact,
			"rgba_sha256": rgba,
			"mipmap_count": imported.get_mipmap_count() if imported != null else -1,
			"alpha_gt_zero_rect_xywh": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"edge_alpha_max": edge_max,
		})
	var last: Dictionary = {}
	for path: String in first:
		last[path] = FileAccess.get_sha256(path)
		require(last[path] == first[path], "Own source unchanged " + path)
	require(Time.get_ticks_msec() - began < WHOLE_MS, "Whole15s finite verifier")
	var passed := failures.is_empty()
	var report := {
		"passed": passed,
		"scope": "FOUR_STATIC_SOLDIER_ISOLATED_IMPORT_NO_MAIN_PROJECT_OR_NPC_BINDING",
		"failures": failures,
		"elapsed_ms": Time.get_ticks_msec() - began,
		"rows": reports,
		"prepared_sha256": FileAccess.get_sha256(PREPARED_PATH),
		"script_sha256": FileAccess.get_sha256(get_script().resource_path),
		"source_first": first,
		"source_last": last,
	}
	var output := "res://soldier_static_import_result_%d.json" % OS.get_process_id()
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t", true, true))
		file.close()
	else:
		passed = false
		failures.append("Open report output")
	print(JSON.stringify({"passed": passed, "output": output, "failures": failures}))
	quit(0 if passed else 1)
