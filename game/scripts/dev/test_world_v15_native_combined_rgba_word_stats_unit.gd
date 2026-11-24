extends SceneTree
## Isolated predicate proof only. Never imports/publishes/approves terrain assets.
## NEW native-word predicate; original unit A679 and FULL gate remain unchanged.
const ORIGINAL_UNIT := "res://scripts/dev/test_world_v15_native_binary_stats_unit.gd"
const ORIGINAL_UNIT_SHA := "a679604939127e55333f28d08e19d387a0c2dea1f1bf487d5c19f21a76052f46"
const ALGORITHM_IDENTITY := "RGBA8_COMBINED_OPAQUE_BINARY_NATIVE_SIGNED_WORD_COUNTS_V2_UNIT_ONLY"
const SCOPE := "NATIVE_IMAGE_PREDICATE_EQUIVALENCE_NOT_TERRAIN_OR_PROTOCOL_APPROVAL"
var _records: Array[Dictionary] = []
var _failed: Array[String] = []
var _checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--native-combined-rgba-word-stats-unit" not in OS.get_cmdline_user_args() or FileAccess.get_sha256(ORIGINAL_UNIT).to_lower() != ORIGINAL_UNIT_SHA:
		printerr("Explicit NEW word unit and exact original A679 source required; no terrain authority tested.")
		quit(2)
		return
	# Exhaust every binary RGB combination and the exact requested alpha values.
	for bits in 8:
		var rgb := PackedByteArray([255 if bits & 1 else 0, 255 if bits & 2 else 0, 255 if bits & 4 else 0])
		for alpha: int in [0, 1, 254, 255]:
			var bytes := PackedByteArray([rgb[0], rgb[1], rgb[2], alpha])
			_case("rgb_%d_alpha_%d" % [bits, alpha], Vector2i.ONE, bytes, alpha == 255, alpha == 255 and bits in [0, 7])
		# Every RGB binary corner with one nonbinary channel, including 1/254.
		for channel in 3:
			for value: int in [1, 254]:
				var bytes := PackedByteArray([rgb[0], rgb[1], rgb[2], 255])
				bytes[channel] = value
				_case("rgb_%d_channel_%d_value_%d" % [bits, channel, value], Vector2i.ONE, bytes, true, false)
	# Odd sizes and a single bad pixel at beginning/middle/end of native storage.
	var size := Vector2i(257, 17)
	var legal := PackedByteArray()
	for index in size.x * size.y:
		var shade: int = 255 if index % 3 == 0 else 0
		legal.append_array(PackedByteArray([shade, shade, shade, 255]))
	_case("odd_native_binary_mixture", size, legal, true, true)
	for pixel: int in [0, int(size.x * size.y / 2), size.x * size.y - 1]:
		for channel in 4:
			for value: int in ([0, 1, 254] if channel == 3 else [1, 254]):
				var bytes: PackedByteArray = legal.duplicate()
				bytes[pixel * 4 + channel] = value
				_case("single_bad_pixel_%d_channel_%d_value_%d" % [pixel, channel, value], size, bytes, channel != 3, false)
	var result := {
		"scope": SCOPE, "algorithm_identity": ALGORITHM_IDENTITY,
		"status": "UNIT_EQUIVALENCE_PASS" if _failed.is_empty() else "UNIT_EQUIVALENCE_FAIL",
		"passed": _failed.is_empty(), "checks": _checks, "case_count": _records.size(),
		"failed": _failed, "cases": _records, "zero_tolerance": true,
		"uses_alpha_threshold": false, "uses_pixel_epsilon": false,
		"tested_format": "FORMAT_RGBA8", "tested_alpha_values": [0, 1, 254, 255],
		"tested_binary_RGB_corners": 8, "tested_nonbinary_channel_values": [1, 254],
		"original_gate_modified": false, "terrain_or_protocol_approved": false,
		"source_path": get_script().resource_path,
		"source_sha256": FileAccess.get_sha256(get_script().resource_path),
		"godot_version": Engine.get_version_info(), "display_server": DisplayServer.get_name(),
	}
	var output: String = "res://build/world_v15_native_binary_stats_unit/%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		printerr("Cannot retain isolated unit evidence."); quit(1); return
	var file: FileAccess = FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file == null:
		printerr("Cannot retain isolated unit result."); quit(1); return
	file.store_string(JSON.stringify(result, "\t")); file.close()
	print(JSON.stringify({"scope": SCOPE, "checks": _checks, "failed": _failed.size(), "case_count": _records.size(), "result_path": output + "result.json"}))
	quit(0 if _failed.is_empty() else 1)

func _case(id: String, size: Vector2i, bytes: PackedByteArray, expected_opaque: bool, expected_binary: bool) -> void:
	var image: Image = Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, bytes)
	if image == null:
		_assert(false, id + ": native Image creation failed"); return
	var reference: Dictionary = _pixel_reference(image)
	var native: Dictionary = _native_candidate(image)
	_assert(reference.opaque == expected_opaque, id + ": original opacity oracle disagrees with authored case")
	_assert(reference.binary == expected_binary, id + ": original binary oracle disagrees with authored case")
	_assert(native.byte_count_valid, id + ": native RGBA byte and word counts disagree with canvas")
	_assert(native.binary == reference.binary, id + ": native binary predicate disagrees with exact per-pixel oracle")
	_assert(image.get_format() == Image.FORMAT_RGBA8 and image.get_data() == bytes and image.get_size() == size and not image.has_mipmaps(), id + ": predicate mutated original data/format/canvas")
	_records.append({"id": id, "size": [size.x, size.y], "source_RGBA_sha256": _sha(bytes), "expected_opaque": expected_opaque, "expected_binary": expected_binary, "original_pixel_oracle": reference, "native_candidate": native})

static func _pixel_reference(image: Image) -> Dictionary:
	# Byte-for-byte predicate copied from frozen FULL gate _roi_error, no color API.
	var bytes: PackedByteArray = image.get_data()
	var opaque := true
	var binary := true
	for offset in range(0, bytes.size(), 4):
		if bytes[offset + 3] != 255: opaque = false
		if not ((bytes[offset] == 0 and bytes[offset + 1] == 0 and bytes[offset + 2] == 0) or (bytes[offset] == 255 and bytes[offset + 1] == 255 and bytes[offset + 2] == 255)): binary = false
	return {"opaque": opaque, "binary": opaque and binary}

static func _native_candidate(image: Image) -> Dictionary:
	# Native signed little-endian words retain ALL four original RGBA8 bytes.
	# Only FF000000 (black) and FFFFFFFF (white) are legal; alpha254 is denied.
	var bytes: PackedByteArray = image.get_data()
	var words: PackedInt32Array = bytes.to_int32_array()
	var black: int = words.count(-16777216)
	var white: int = words.count(-1)
	var valid: bool = bytes.size() == image.get_width() * image.get_height() * 4 and words.size() == image.get_width() * image.get_height()
	# detect_alpha() is deliberately NOT used: actual ROOT107 proved alpha254
	# is reported opaque by that API. The two legal full RGBA words require 255.
	return {"byte_count_valid":valid,"binary":valid and black+white==words.size(),"RGBA_byte_count":bytes.size(),"native_word_count":words.size(),"opaque_black_word_count":black,"opaque_white_word_count":white,"alpha_thresholding":false,"source_conversion":false,"detect_alpha_used":false}

func _assert(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed.append(message)
		printerr(message)

static func _sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	return context.finish().hex_encode()
