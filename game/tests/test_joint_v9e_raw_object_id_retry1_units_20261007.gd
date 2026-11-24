extends SceneTree
## NEW retry of preserved ROOT272 failure: same-JSON-decoder association.
## Read-only raw ObjectID units; no capture, gameplay, publication or approval.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "f6548fecb298321995319f0ee616e795423d616bf6d8c379bb054c0c0b843a9b"
const FULL_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const FULL_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const REGIONAL_PATH := "res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/1791137714_2690526/result.json"
const REGIONAL_SHA := "fe50ec4312753bd62eee0e4c62a1944dfb29859e6f339e04282dc05864f960d0"
const PRIMARY_ID := "-9223371108688851939"
const REFERENCE_ID := "-9223369778020742319"
const FULL_TOKENS := {
	"primary": {"world_node_instance_id": "928182701131", "viewport_instance_id": "928115591784", "world_3d_instance_id": PRIMARY_ID},
	"reference": {"world_node_instance_id": "2258850810955", "viewport_instance_id": "2258783702186", "world_3d_instance_id": REFERENCE_ID},
}
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _fixture(first: String = PRIMARY_ID, second: String = REFERENCE_ID) -> String:
	return '{"worlds":{"primary":{"world_node_instance_id":11,"viewport_instance_id":12,"world_3d_instance_id":%s},"reference":{"world_node_instance_id":21,"viewport_instance_id":22,"world_3d_instance_id":%s}}}' % [first, second]

func _worlds(raw: String) -> Dictionary:
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK: return {} # Expected malformed negatives do not emit engine ERROR logs.
	var parsed: Variant = parser.data
	return parsed.worlds if parsed is Dictionary and parsed.get("worlds") is Dictionary else {}

func _tokens(raw: String) -> Dictionary:
	return GATE._world_instance_tokens(_worlds(raw), raw)

func _diagnose_primary(raw: String, label: String) -> void:
	var worlds: Dictionary = _worlds(raw)
	var raw_worlds: String = GATE._raw_named_object(raw, "worlds")
	var raw_primary: String = GATE._raw_named_object(raw_worlds, "primary")
	print("V9E_RAW_OBJECT_ID_DIAGNOSTIC_SCOPE ", JSON.stringify({"label": label, "raw_worlds_chars": raw_worlds.length(), "raw_primary_chars": raw_primary.length()}))
	for key: String in ["world_node_instance_id", "viewport_instance_id", "world_3d_instance_id"]:
		var pattern: RegEx = RegEx.create_from_string('"' + key + '"\\s*:\\s*([^,}\\r\\n]+)')
		var matches: Array[RegExMatch] = pattern.search_all(raw_primary)
		var token: String = matches[0].get_string(1).strip_edges() if matches.size() == 1 else ""
		var value: Variant = worlds.get("primary", {}).get(key)
		var parser: JSON = JSON.new()
		var parsed_ok: bool = not token.is_empty() and parser.parse(token) == OK
		var data: Dictionary = {"label": label, "key": key, "raw_field_matches": matches.size(), "token": token, "parsed_type": typeof(value), "parsed_str": str(value), "int64_exact_str": str(token.to_int()), "same_json_parse_ok": parsed_ok, "same_json_type": typeof(parser.data), "same_json_str": str(parser.data)}
		if typeof(value) == TYPE_FLOAT and parsed_ok and typeof(parser.data) == TYPE_FLOAT:
			data.merge({"parsed_17dp": "%.17f" % value, "int64_cast_17dp": "%.17f" % float(token.to_int()), "same_json_17dp": "%.17f" % parser.data, "parsed_float64_hex": PackedFloat64Array([value]).to_byte_array().hex_encode(), "int64_cast_float64_hex": PackedFloat64Array([float(token.to_int())]).to_byte_array().hex_encode(), "same_json_float64_hex": PackedFloat64Array([parser.data]).to_byte_array().hex_encode(), "parsed_equals_same_json": value == parser.data, "parsed_equals_int64_cast": value == float(token.to_int())})
		print("V9E_RAW_OBJECT_ID_DIAGNOSTIC ", JSON.stringify(data))

func _run() -> void:
	var inputs: Dictionary = {GATE_PATH: GATE_SHA, FULL_PATH: FULL_SHA, REGIONAL_PATH: REGIONAL_SHA}
	for path: String in inputs: _check(FileAccess.get_sha256(path).to_lower() == inputs[path], "actual frozen unit source: " + path)
	if errors.is_empty():
		var full_raw: String = FileAccess.get_file_as_string(FULL_PATH)
		var actual: Dictionary = _tokens(full_raw)
		_check(actual == FULL_TOKENS, "actual CDD74 full original six ObjectID tokens, including two signed-negative RefCounted IDs")
		_check(not _tokens(FileAccess.get_file_as_string(REGIONAL_PATH)).is_empty(), "actual frozen regional raw ObjectIDs use the same strict representation")
		for identity: String in FULL_TOKENS:
			for key: String in FULL_TOKENS[identity]: _check(actual.get(identity, {}).get(key) == FULL_TOKENS[identity][key], "exact bound full identity: " + identity + "/" + key)
	var ordinary: String = _fixture()
	_diagnose_primary(ordinary, "canonical_synthetic_three_tokens")
	_diagnose_primary(FileAccess.get_file_as_string(FULL_PATH), "actual_CDD74_primary_three_tokens")
	_check(not _tokens(ordinary).is_empty(), "canonical six unique nonzero ObjectIDs")
	var adjacent: String = _fixture(PRIMARY_ID, "-9223371108688851938")
	var rounded: Dictionary = _worlds(adjacent)
	_check(rounded.primary.world_3d_instance_id == rounded.reference.world_3d_instance_id, "actual JSON Float64 loses adjacent ObjectID low bits")
	var adjacent_tokens: Dictionary = _tokens(adjacent)
	_check(not adjacent_tokens.is_empty() and adjacent_tokens.primary.world_3d_instance_id != adjacent_tokens.reference.world_3d_instance_id, "raw adjacent int64 IDs remain provably unique despite same parsed double")
	_check(_tokens(_fixture(PRIMARY_ID, PRIMARY_ID)).is_empty(), "duplicate exact raw World3D token rejected, never float-based identity credit")
	_check(not _tokens(_fixture("-9223372036854775808", "9223372036854775807")).is_empty(), "both canonical signed-int64 boundary ObjectIDs remain representable")
	for invalid: String in ["0", "-0", '"123"', "1.5", "1e3", "01", "+1", "9223372036854775808", "-9223372036854775809", "null", "true", "false", "NaN", "Infinity"]:
		_check(_tokens(_fixture(invalid)).is_empty(), "invalid/noncanonical/overflow ObjectID rejected: " + invalid)
	for field: String in ["world_node_instance_id", "viewport_instance_id", "world_3d_instance_id"]:
		var first: String = '"' + field + '":' + ({"world_node_instance_id": "11", "viewport_instance_id": "12", "world_3d_instance_id": PRIMARY_ID}[field])
		_check(_tokens(ordinary.replace(first, first + "," + first)).is_empty(), "duplicate raw identity key rejected: " + field)
		_check(_tokens(ordinary.replace(first + ",", "").replace("," + first, "")).is_empty(), "missing identity field rejected: " + field)
	_check(_tokens(ordinary.replace('"primary":{', '"primary":{},"primary":{')).is_empty(), "duplicate raw primary object key rejected")
	_check(_tokens('{"worlds":{},' + ordinary.trim_prefix("{")).is_empty(), "duplicate raw worlds object key rejected")
	_check(_tokens(ordinary.replace('"world_node_instance_id":11', '"world_node_instance_id":-11')).is_empty(), "Node identity remains positive")
	_check(_tokens(ordinary.replace('"viewport_instance_id":12', '"viewport_instance_id":-12')).is_empty(), "Viewport identity remains positive")
	_check(_tokens(ordinary.replace('"world_node_instance_id":21', '"world_node_instance_id":11')).is_empty(), "duplicate exact Node identity rejected")
	_check(_tokens(ordinary.replace('"viewport_instance_id":22', '"viewport_instance_id":12')).is_empty(), "duplicate exact Viewport identity rejected")
	var mismatched: Dictionary = _worlds(ordinary)
	mismatched.primary.world_3d_instance_id = -100.0
	_check(GATE._world_instance_tokens(mismatched, ordinary).is_empty(), "raw token must bind the supplied parsed world identity")
	_check(GATE._object_id_token(PRIMARY_ID.to_int() + 1, PRIMARY_ID, true).is_empty(), "native int64 association remains exact even when Float64 would merge")
	for invalid: Variant in [null, true, false, PRIMARY_ID, NAN, INF]: _check(GATE._object_id_token(invalid, PRIMARY_ID, true).is_empty(), "parsed nonnumeric/nonfinite association rejected: " + str(invalid))
	for path: String in inputs: _check(FileAccess.get_sha256(path).to_lower() == inputs[path], "actual unit source unchanged: " + path)
	print("V9E_RAW_OBJECT_ID_RETRY1_UNITS ", JSON.stringify({"scope": "READ_ONLY_RAW_OBJECT_ID_UNIT_NOT_FIELD_OR_PUBLICATION", "checks": checks, "failures": errors.size(), "errors": errors, "Field_executed": false, "GPU_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
