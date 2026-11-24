extends SceneTree
## SOURCE unit only: ROOT231 84 actual scalar witnesses plus exact negatives.
## No candidate materialization, gameplay, save, publication or Field credit.
const CONTRACT_PATH := "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const CONTRACT_SHA := "4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1"
const OLD_PATH := "res://build/luoyang_note_contract_before_native_scalar_20261004_01/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const OLD_SHA := "10a2bf0330b695ad6086f5d3cdefae54d242f72d0dc212881a27e2ee5296f2a4"
const EVIDENCE_PATH := "res://build/joint_world_luoyang_20261003_qa/231_city_note_serialized_fidelity_diagnostic/stdout.log"
const EVIDENCE_SHA := "27814a519a1f87e17fb7e1043605502f87a42259eb82410e17ec5a70191eb84b"
var _checks: int = 0
var _failed: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not "--note-native-visual-scalar-unit" in OS.get_cmdline_user_args(): quit(2); return
	for binding: Array in [[CONTRACT_PATH, CONTRACT_SHA], [OLD_PATH, OLD_SHA], [EVIDENCE_PATH, EVIDENCE_SHA]]:
		if FileAccess.get_sha256(binding[0]) != binding[1]: push_error("Exact source/evidence changed: " + binding[0]); quit(2); return
	var contract: Script = load(CONTRACT_PATH) as Script
	if contract == null or not contract.can_instantiate(): quit(2); return
	var evidence: Dictionary = {}
	for line: String in FileAccess.get_file_as_string(EVIDENCE_PATH).split("\n"):
		if line.begins_with("NOTE_CANDIDATE_FIDELITY_DIAGNOSTIC="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("NOTE_CANDIDATE_FIDELITY_DIAGNOSTIC="))
			if parsed is Dictionary: evidence = parsed
	_assert(evidence.get("scope") == "READ_ONLY_SERIALIZED_CANDIDATE_FIDELITY_NOT_FIELD_OR_FULL", "Exact diagnostic scope")
	var actual_count: int = 0
	var token_regex := RegEx.new()
	if token_regex.compile("[A-Za-z_][A-Za-z0-9_]*|\\[([0-9]+)\\]") != OK: quit(2); return
	for row: Dictionary in evidence.get("rows", []):
		if row.get("status") == "ABSENT_NO_COMPARISON": continue
		_assert(row.mismatched_leaf_count == row.mismatches.size(), "Complete witnesses " + String(row.id))
		for witness: Dictionary in row.mismatches:
			actual_count += 1
			var path: Array = []
			for token: RegExMatch in token_regex.search_all(String(witness.path)):
				if token.get_string(1) != "": path.append(token.get_string(1).to_int())
				elif token.get_string(0) != "layout": path.append(token.get_string(0))
			var expected: float = String(witness.expected).to_float()
			var actual: float = String(witness.actual).to_float()
			var label: String = String(row.id) + "/" + String(witness.path)
			_assert(witness.expected_type == TYPE_FLOAT and witness.actual_type == TYPE_FLOAT, label + " measured types")
			_assert(contract.equal_visual_serialized_value(expected, actual, path), label + " native bytes equal")
			_assert(not contract._equal_value(expected, actual), label + " original semantic float64 remains exact")
			var native_bytes: PackedByteArray = PackedFloat32Array([expected]).to_byte_array()
			var next_bytes: PackedByteArray = native_bytes.duplicate()
			next_bytes.encode_u32(0, native_bytes.decode_u32(0) + 1)
			_assert(not contract.equal_visual_serialized_value(expected, next_bytes.decode_float(0), path), label + " one native ULP rejected")
			_assert(not contract.equal_visual_serialized_value(expected, expected + 1.0, path), label + " actual offset rejected")
			for wrong: Variant in [int(expected), str(expected), null, NAN, INF, -INF, 1e300]:
				_assert(not contract.equal_visual_serialized_value(expected, wrong, path), label + " type/finite strict " + str(typeof(wrong)))
	_assert(actual_count == 84, "All ROOT231 actual 32+23+29 witnesses")
	var before: Dictionary = {"depth_sort_foot_y": .810546875, "foot_uv": [.5, .9228515625], "source_semantics": {"foot_uv": [.5, .8896484375], "solid_polygons_uv": [[[.943359375, .7978515625]]]}, "native_transform": {"origin": [1.0, 2.0, -5.1189999580383301]}, "source_sha256": "immutable", "interaction_action": "dialog:original", "world_foot_px": [1536.0, 1660.0]}
	var roundtrip: Dictionary = before.duplicate(true)
	roundtrip.depth_sort_foot_y = .8105469
	roundtrip.foot_uv[1] = .92285156
	roundtrip.source_semantics.foot_uv[1] = .88964844
	roundtrip.source_semantics.solid_polygons_uv[0][0] = [.9433594, .79785156]
	roundtrip.native_transform.origin[2] = -5.119
	var aliases_expected: Array = [before, before]
	var aliases_actual: Array = [roundtrip, roundtrip]
	var before_bytes: PackedByteArray = var_to_bytes(aliases_expected)
	var actual_bytes: PackedByteArray = var_to_bytes(aliases_actual)
	_assert(contract.equal_visual_serialized_value(aliases_expected, aliases_actual, ["visual_objects"]), "Nested aliased witness")
	_assert(var_to_bytes(aliases_expected) == before_bytes and var_to_bytes(aliases_actual) == actual_bytes, "Inputs and aliases byte-exact unmodified")
	for key: String in ["source_sha256", "interaction_action"]:
		var changed: Dictionary = roundtrip.duplicate(true)
		changed[key] = "changed"
		_assert(not contract.equal_visual_serialized_value([before], [changed], ["visual_objects"]), "Unlisted hash/action exact " + key)
	var renamed: Dictionary = roundtrip.duplicate(true)
	renamed["depth_sort_foot_x"] = renamed.depth_sort_foot_y
	renamed.erase("depth_sort_foot_y")
	_assert(not contract.equal_visual_serialized_value([before], [renamed], ["visual_objects"]), "Key rename rejected")
	var position_changed: Dictionary = roundtrip.duplicate(true)
	position_changed.world_foot_px[0] += .000001
	_assert(not contract.equal_visual_serialized_value([before], [position_changed], ["visual_objects"]), "Unlisted world position remains float64 exact")
	for bad_path: Array in [["npcs", 0, "depth_sort_foot_y"], ["visual_objects", 0, "unknown"], ["visual_objects", 0, "native_transform", "origin", 0], ["visual_objects", 0, "foot_uv", 2], ["visual_objects", 0, "source_semantics", "solid_polygons_uv", 0, 0, 2]]:
		_assert(not contract.equal_visual_serialized_value(.810546875, .8105469, bad_path), "Unlisted path exact " + str(bad_path))
	_assert(not contract.equal_visual_serialized_value(INF, INF, ["visual_objects", 0, "depth_sort_foot_y"]), "Nonfinite equal values rejected")
	_assert(not contract.equal_visual_serialized_value(1e300, 1e300, ["visual_objects", 0, "depth_sort_foot_y"]), "Native overflow rejected")
	var negative_zero_bytes := PackedByteArray([0, 0, 0, 128])
	_assert(not contract.equal_visual_serialized_value(0.0, negative_zero_bytes.decode_float(0), ["visual_objects", 0, "depth_sort_foot_y"]), "Signed zero distinct native bits")
	for binding: Array in [[CONTRACT_PATH, CONTRACT_SHA], [OLD_PATH, OLD_SHA], [EVIDENCE_PATH, EVIDENCE_SHA]]:
		_assert(FileAccess.get_sha256(binding[0]) == binding[1], "Source/evidence unchanged " + binding[0])
	print(JSON.stringify({"scope": "SOURCE_NATIVE_VISUAL_SCALAR_UNIT_NOT_FIELD_OR_FULL", "checks": _checks, "failed": _failed, "actual_witnesses": actual_count}))
	contract = null
	aliases_expected.clear()
	aliases_actual.clear()
	await create_timer(9.0).timeout
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null and audio.has_method("stop_bgm"): audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	quit(0 if _failed.is_empty() else 1)

func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition: _failed.append(label); push_error(label)
