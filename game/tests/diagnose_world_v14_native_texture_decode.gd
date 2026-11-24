extends SceneTree

## Isolated representation/alias diagnostic, NOT production-world acceptance.
## Reads captured metadata/source textures only. No Field, renderer export,
## source pixels, material, imported file, or existing QA result is modified.
const ART_DIR := "res://art/maps/world_map_v14/"
const MANIFEST_PATH := ART_DIR + "manifest.json"
var report: Dictionary = {}
var failed := 0
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition: return
	failed += 1
	push_error("[TextureDecodeDiagnostic FAIL] " + message)

func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(value is Dictionary, "read actual JSON dictionary: " + path)
	return value if value is Dictionary else {}

func _sha(image: Image) -> String:
	if image == null or image.is_empty(): return ""
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(image.get_data())
	return hash.finish().hex_encode()

func _describe(image: Image, expected: Array) -> Dictionary:
	if image == null or image.is_empty(): return {"valid": false}
	var sha := _sha(image)
	var matches: Array[String] = []
	for record: Dictionary in expected:
		if sha == String(record.get("decoded_before_mipmap_sha256", "")).to_lower():
			matches.append(String(record.get("binding", "")))
	return {"valid": true, "image_instance_id": image.get_instance_id(), "format_enum": image.get_format(), "byte_count": image.get_data().size(), "canvas": [image.get_width(), image.get_height()], "has_mipmaps": image.has_mipmaps(), "mipmap_count": image.get_mipmap_count(), "compressed": image.is_compressed(), "rgba_or_original_bytes_sha256": sha, "exact_record_matches": matches}

func _representations(image: Image, expected: Array) -> Array:
	var records: Array = []
	if image == null or image.is_empty(): return records
	var formats: Array[int] = [Image.FORMAT_RGB8, Image.FORMAT_RGBA8]
	if image.get_format() == Image.FORMAT_RG8: formats.append(Image.FORMAT_RG8)
	for format: int in formats:
		var converted := image.duplicate() as Image
		converted.convert(format)
		var record := _describe(converted, expected)
		var roundtrip := converted.duplicate() as Image
		roundtrip.convert(image.get_format())
		record["lossless_roundtrip_to_original_format"] = roundtrip.get_data() == image.get_data()
		record["operation"] = "native Image.convert only; no colour rounding/tolerance or source edit"
		records.append(record)
	return records

func _decode(path: String, expected: Array) -> Dictionary:
	var result := {"path": path, "recorded_gpu_bindings": expected, "source_file_sha256": FileAccess.get_sha256(path)}
	_check(FileAccess.file_exists(path), "actual declared texture exists: " + path)
	var imported := load(path) as Texture2D
	_check(imported != null, "original actual Texture2D loads: " + path)
	if imported == null: return result
	if DisplayServer.get_name() != "headless":
		for frame in 2: await process_frame
		await RenderingServer.frame_post_draw
	result["texture_class"] = imported.get_class()
	result["texture_resource_path"] = imported.resource_path
	var before := imported.get_image()
	_check(before != null and not before.is_empty(), "original actual Texture2D image exists: " + path)
	if before == null or before.is_empty(): return result
	var original_before_sha := _sha(before)
	result["texture_original_before_any_operation"] = _describe(before, expected)
	# Preserve original bytes in an independent Image before any decompression
	# or mip control can mutate an Image returned by the rendering backend.
	var decoded := before.duplicate() as Image
	if decoded.is_compressed(): _check(decoded.decompress() == OK, "independent clone decompresses: " + path)
	result["texture_decompressed_clone"] = _describe(decoded, expected)
	result["texture_lossless_format_candidates"] = _representations(decoded, expected)
	var raw := Image.load_from_file(path)
	_check(raw != null and not raw.is_empty(), "actual original JPEG/PNG independently decodes: " + path)
	if raw != null and not raw.is_empty():
		result["raw_file_decoded"] = _describe(raw, expected)
		result["raw_lossless_format_candidates"] = _representations(raw, expected)
		result["raw_equals_original_texture_bytes"] = raw.get_data() == decoded.get_data()
		result["raw_same_canvas"] = raw.get_size() == decoded.get_size()
	var import_path := path + ".import"
	result["import_settings_path"] = import_path
	result["import_settings_sha256"] = FileAccess.get_sha256(import_path) if FileAccess.file_exists(import_path) else ""
	result["import_settings_verbatim"] = FileAccess.get_file_as_string(import_path) if FileAccess.file_exists(import_path) else ""
	# Safe control: independently clone and generate mips. Observe the original
	# texture again, proving whether the intended test fix leaves it unchanged.
	var clone := decoded.duplicate() as Image
	_check(clone.generate_mipmaps() == OK, "duplicate-only native mip control succeeds: " + path)
	result["duplicate_generated_mipmap_control"] = _describe(clone, expected)
	var after_clone := imported.get_image()
	result["texture_after_duplicate_only_mips"] = _describe(after_clone, expected)
	result["duplicate_only_keeps_texture_bytes_exact"] = _sha(after_clone) == original_before_sha
	_check(bool(result["duplicate_only_keeps_texture_bytes_exact"]), "duplicate-only mip control does not alter the source texture: " + path)
	# Intentional causal control reproduces only the prior test's in-memory
	# operation on a returned Image in THIS separate process. No .ctex/JPEG/PNG
	# is written. A mismatch is evidence, not accepted production correctness.
	var probe := imported.get_image()
	var probe_before := _describe(probe, expected)
	if probe.is_compressed(): _check(probe.decompress() == OK, "returned-Image control decompresses: " + path)
	_check(probe.generate_mipmaps() == OK, "returned-Image alias control generates mips: " + path)
	var after_direct := imported.get_image()
	result["intentional_returned_image_alias_control"] = {"before": probe_before, "mutated_returned_image": _describe(probe, expected), "new_get_image_after": _describe(after_direct, expected), "same_image_instance": probe.get_instance_id() == after_direct.get_instance_id(), "texture_bytes_changed": String(probe_before.get("rgba_or_original_bytes_sha256", "")) != _sha(after_direct), "scope": "isolated process-memory reproduction; no source/import/capture writes"}
	return result

func _run() -> void:
	var tag := "unspecified"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="): tag = argument.trim_prefix("--tag=").validate_filename()
	output = "res://build/world_map_v14_qa/texture_decode_%s_%d/" % [tag, Time.get_unix_time_from_system()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "create distinct diagnostic result directory")
	var manifest := _json(MANIFEST_PATH)
	var by_path: Dictionary = {}
	for material: Dictionary in manifest.get("actual_native_material_derivatives", []):
		for texture: Dictionary in material.get("textures", []):
			var path := String(texture.get("source_texture_resource_path", ""))
			_check(not path.is_empty() and path.begins_with("res://art/external/"), "actual capture declares concrete original texture path")
			if path.is_empty(): continue
			var record := texture.duplicate(true)
			record["binding"] = "%s:material%d:slot%d" % [material.get("source_gltf", ""), int(material.get("source_material_index", -1)), int(texture.get("slot_enum", -1))]
			if not by_path.has(path): by_path[path] = []
			by_path[path].append(record)
	_check(not by_path.is_empty(), "actual recorded GPU material texture set is nonempty")
	var paths: Array = by_path.keys()
	paths.sort()
	var results: Array = []
	for path: String in paths: results.append(await _decode(path, by_path[path]))
	report = {"scope": "NATIVE_TEXTURE_DECODE_CAUSAL_DIAGNOSTIC_NOT_FULL_MAP", "tag": tag, "display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(), "script_path": get_script().resource_path, "script_sha256": FileAccess.get_sha256(get_script().resource_path), "manifest_path": MANIFEST_PATH, "manifest_sha256": FileAccess.get_sha256(MANIFEST_PATH), "capture_iteration": manifest.get("capture_iteration"), "unique_texture_paths": paths.size(), "records": results, "diagnostic_io_failures": failed, "production_approved": false, "full_map_test_run": false, "matches_are_exact_byte_SHA_not_tolerance": true}
	call_deferred("_finish")

func _finish() -> void:
	# Only process-exit cleanup; never changes normal production cursor behavior.
	var cursors := root.get_node_or_null("CursorManager")
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	if cursors != null:
		for field_name: String in ["_arrow", "_hand", "_wait"]: cursors.set(field_name, null)
	for frame in 8: await process_frame
	report["diagnostic_io_failures"] = failed
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	_check(file != null, "save separate actual diagnostic result")
	if file != null:
		file.store_string(JSON.stringify(report, "\t")); file.close()
	print("[TextureDecodeDiagnostic] unique_paths=%d io_failures=%d result=%s; diagnostic only, NOT production/full-map PASS" % [int(report.get("unique_texture_paths", 0)), failed, output + "result.json"])
	quit(0 if failed == 0 else 1)
