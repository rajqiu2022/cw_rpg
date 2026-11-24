extends SceneTree
## Independent SOURCE UNIT proposal: default JSON representation, not a tolerance.
## No gate/builder calls, active raw reads, approval/candidate/formal/save writes.
## RF, Vector2 operations and saved resource bytes must remain independent oracles.
const ENTITY: String = "res://art/maps/world_map_v15_complete_v7/entities/v7_bank_cover_0011.json"
const ENTITY_SHA: String = "224324a8ac27b88d78b290ca9b29d9bb389e0964be94cff9d4c4c9d59a209e68"
const ORIGINAL: String = "res://art/maps/world_map_v15_complete_v5/prototypes/native_herb2.json"
const ORIGINAL_SHA: String = "471ed22c3eb120d70b1ba32f896edf7b0c77fdeeAd485d934077467b3cd30218"
const GATE_PATH: String = "res://scripts/dev/world_map_v15_complete_v7_publication_gate_proposal.gd"
const GATE_SHA: String = "636769e29d745655d8adddaef67460498c1f646c5a79dcd01b362363a554491b"
const RF_PATH: String = "res://art/maps/world_map_v15_complete_v5/terrain_height.rf"
const RF_SHA: String = "b7210634cbc2d7a2809bfab608e47930d5717459b01dc42df33ae9e6919548b9"
const PROTOTYPES: Array = [
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder0.json","sha256":"bfdebaa990e6fb38a0cc474c9903411a93732f5ef69a0c85a21457a7d49dee1a"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder1.json","sha256":"782861d676d9953c832c298b0f67c44ea5c811a55bb1b9edb4ebc9e40f54a05d"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder2.json","sha256":"9db386cde64980d6e29ad3b60b6e6043e5b4f22f034a036497ddaaf69537725e"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_tree0.json","sha256":"7fabeb4855a5c73738ebd753e2feb9a773a9ddd436b2332d774328f8f959f256"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_tree1.json","sha256":"9c84f5c4fad85633063ce7bbc7ca1b6eecc84fee6844a622cfe1bf84d0fd781f"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_tree2.json","sha256":"6ab4e8a5c142270e7ef6e198e14d48206c9e2de10894c131595e57f95cae5097"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_bamboo0.json","sha256":"cbf1dfc9220df15c75c8bae656b11f2d2e74e18c1c00f2196e2c44264b7a0a9f"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_bamboo1.json","sha256":"79d0c8b23b9c6fc6ef46240709f3e697ad0c745be42368dc90227951f108f0a7"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_bamboo2.json","sha256":"1fbc06269542cac3893c460e60b1331de46131f92315d80498522bdfbc07ea33"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_herb0.json","sha256":"53e90bc14494dc2db0fdf80c2b573caa5ef5e853c6200a88846fc5147fbc8f44"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_herb1.json","sha256":"876f0005ea2300d9b455d54ae3a7b8b5b13e6255e2b082c6a2e134d2c6a8fbfb"},
	{"path":"res://art/maps/world_map_v15_complete_v5/prototypes/native_herb2.json","sha256":"471ed22c3eb120d70b1ba32f896edf7b0c77fdeead485d934077467b3cd30218"}
]
var gate_script: GDScript
var checks: int = 0
var failures: int = 0
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[default JSON native SOURCE UNIT] " + label)

func _codec(value: Variant) -> Variant:
	# Exactly the capture writer's default full_precision=false codec. Vectors
	# must first become explicit component arrays, as in the actual capture.
	return JSON.parse_string(JSON.stringify(value))

func _exact(saved: Variant, expected: Variant) -> bool:
	if typeof(saved) in [TYPE_INT, TYPE_FLOAT] and typeof(expected) in [TYPE_INT, TYPE_FLOAT]:
		return is_finite(float(saved)) and is_finite(float(expected)) and float(saved) == float(expected)
	if typeof(saved) != typeof(expected): return false
	if saved is Array:
		if saved.size() != expected.size(): return false
		for index in saved.size():
			if not _exact(saved[index], expected[index]): return false
		return true
	if saved is Dictionary:
		if saved.size() != expected.size(): return false
		for key: Variant in saved:
			if not expected.has(key) or not _exact(saved[key], expected[key]): return false
		return true
	return saved == expected

func _json_native_exact(saved: Variant, native_expected: Variant) -> bool:
	var independent: bool = _exact(saved, _codec(native_expected))
	if gate_script == null: return false
	var actual: Variant = gate_script.call("_json_native_exact", saved, native_expected)
	_check(actual is bool and actual == independent, "pinned gate helper equals independent default codec predicate")
	return actual is bool and actual == true

func _next_positive_float32(value: float) -> float:
	var bytes: PackedByteArray = PackedFloat32Array([value]).to_byte_array()
	bytes.encode_u32(0, bytes.decode_u32(0) + 1)
	return bytes.decode_float(0)

func _protected_files() -> Dictionary:
	var paths: Array[String] = [ENTITY, ORIGINAL, GATE_PATH, RF_PATH]
	for prototype: Dictionary in PROTOTYPES: paths.append(prototype.path)
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			paths.append("user://save_%d.json%s" % [slot,suffix])
	var result: Dictionary = {}
	for path: String in paths:
		var row: Dictionary = {"exists":FileAccess.file_exists(path)}
		if row.exists:
			row["sha256"] = FileAccess.get_sha256(path)
			row["mtime_seconds"] = FileAccess.get_modified_time(path)
		result[path] = row
	return result

func _body_case() -> void:
	_check(FileAccess.get_sha256(ENTITY).to_lower() == ENTITY_SHA.to_lower(), "completed entity exact frozen JSON bytes")
	_check(FileAccess.get_sha256(ORIGINAL).to_lower() == ORIGINAL_SHA.to_lower(), "original prototype exact frozen JSON bytes")
	var body_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENTITY))
	var prototype_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(ORIGINAL))
	_check(body_value is Dictionary and prototype_value is Dictionary, "actual completed metadata dictionaries")
	if not body_value is Dictionary or not prototype_value is Dictionary: return
	var body: Dictionary = body_value
	var prototype: Dictionary = prototype_value
	var size: Vector2 = Vector2(prototype.render_size_px[0], prototype.render_size_px[1])
	# Replay the actual cache operation: scalar double multiplication occurs
	# BEFORE the Vector2 constructor, then the native foot is divided by size.
	var original_foot: Vector2 = Vector2(float(prototype.foot_uv[0]) * size.x, float(prototype.foot_uv[1]) * size.y)
	var uv: Vector2 = original_foot / size
	var components: Array = [uv.x, uv.y]
	_check(not _exact(body.foot_uv, components), "reproduce raw double-vs-native UV inequality, not UV geometry failure")
	_check(_json_native_exact(body.foot_uv, components), "actual native UV passes only exact default JSON expected representation")
	var wrong_uv: Array = [_next_positive_float32(uv.x), uv.y]
	_check(not _json_native_exact(body.foot_uv, wrong_uv), "one native Float32 ULP changed UV remains rejected")
	var foot: Vector2 = Vector2(body.world_foot_px[0], body.world_foot_px[1])
	var depth: float = foot.y / 8192.0
	_check(not _exact(body.depth_sort_foot_y, depth), "reproduce depth default JSON representation inequality")
	_check(_json_native_exact(body.depth_sort_foot_y, depth), "depth exact codec representation binds same native foot")
	_check(not _json_native_exact(body.depth_sort_foot_y, (foot.y + 1.0) / 8192.0), "different physical foot remains rejected")
	_check(FileAccess.get_sha256(RF_PATH).to_lower() == RF_SHA, "original frozen RF exact SHA independent input")
	var rf_bytes: PackedByteArray = FileAccess.get_file_as_bytes(RF_PATH)
	_check(rf_bytes.size() == 1537*1025*4, "original Float32 RF literal grid byte count")
	if FileAccess.get_sha256(RF_PATH).to_lower() != RF_SHA or rf_bytes.size() != 1537*1025*4: return
	var rf: PackedFloat32Array = rf_bytes.to_float32_array()
	var source_foot: Vector2 = Vector2(body.source_XZ_foot_px[0],body.source_XZ_foot_px[1])
	var height: float = _height_from_frozen_RF(rf,source_foot)
	_check(_json_native_exact(body.actual_ground_m,height), "completed entity actual independent frozen RF affine height exact codec")
	_check(not _json_native_exact(body.actual_ground_m,height+0.0001), "completed entity changed RF height rejected without epsilon")
	var projected_foot: Vector2 = Vector2(source_foot.x,source_foot.y-height*102.4*sqrt(.5))
	_check(_json_native_exact(body.world_foot_px,[projected_foot.x,projected_foot.y]), "actual RF projected native foot exact codec")
	_check(rf.to_byte_array() == rf_bytes, "RF decode and independent sample leave original bytes exact")
	records.append({"scope":"ONE_COMPLETED_ENTITY_FROZEN_RF_TRIANGLE_CODEC_NOT_FULL_GEOMETRY","entity_sha256":ENTITY_SHA.to_lower(),"original_sha256":ORIGINAL_SHA.to_lower(),"rf_path":RF_PATH,"rf_sha256":RF_SHA,"source_foot_px":body.source_XZ_foot_px,"stored_height":body.actual_ground_m,"independent_height_default_codec":_codec(height),"stored_uv":body.foot_uv,"native_uv_default_codec":_codec(components),"stored_depth":body.depth_sort_foot_y,"native_depth_default_codec":_codec(depth),"actual_RF_recomputed":true})

func _height_from_frozen_RF(rf: PackedFloat32Array,p: Vector2) -> float:
	# Independent decoded [a,b,c,b,d,c] affine triangle; explicitly preserve
	# native Vector2 grid-coordinate construction, not bilinear interpolation.
	var q: Vector2 = p/8.0
	var cell: Vector2i = Vector2i(mini(floori(q.x),1535),mini(floori(q.y),1023))
	var f: Vector2 = q-Vector2(cell)
	var index: int = cell.y*1537+cell.x
	var a: float = rf[index]
	var b: float = rf[index+1]
	var c: float = rf[index+1537]
	var d: float = rf[index+1538]
	return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y<=1.0 else d+(c-d)*(1.0-f.x)+(b-d)*(1.0-f.y)

func _prototype_operation_cases() -> void:
	var gate_text: String = FileAccess.get_file_as_string(GATE_PATH)
	_check(gate_text.contains("var original_foot := Vector2(float(prototype.foot_uv[0]) * image.get_width(), float(prototype.foot_uv[1]) * image.get_height())") and gate_text.contains("var reconstructed_uv: Vector2 = original_foot / Vector2(image.get_size())"), "actual pinned gate scalar-multiply then native body UV construction literal bound before independent replay")
	for entry: Dictionary in PROTOTYPES:
		_check(FileAccess.get_sha256(entry.path).to_lower()==entry.sha256,"twelve actual original prototype bytes "+entry.path)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(entry.path))
		_check(parsed is Dictionary,"prototype metadata parses "+entry.path)
		if not parsed is Dictionary: continue
		var prototype: Dictionary = parsed
		var size: Vector2 = Vector2(prototype.render_size_px[0],prototype.render_size_px[1])
		var builder_foot: Vector2 = Vector2(float(prototype.foot_uv[0])*size.x,float(prototype.foot_uv[1])*size.y)
		var builder_uv: Vector2 = builder_foot/size
		var gate_original_foot: Vector2 = Vector2(float(prototype.foot_uv[0])*int(size.x),float(prototype.foot_uv[1])*int(size.y))
		var gate_uv: Vector2 = gate_original_foot/size
		var historical_native_uv: Vector2 = (Vector2(prototype.foot_uv[0],prototype.foot_uv[1])*size)/size
		_check(builder_uv.x==gate_uv.x and builder_uv.y==gate_uv.y,"actual twelve prototype capture and current gate operation order equivalent "+entry.path)
		_check(builder_uv.x==historical_native_uv.x and builder_uv.y==historical_native_uv.y,"historical vector-first formula has no actual twelve-prototype mismatch "+entry.path)
		_check(_json_native_exact(_codec([builder_uv.x,builder_uv.y]),[gate_uv.x,gate_uv.y]),"actual gate body UV expected accepts independently replayed capture UV "+entry.path)
		_check(not _json_native_exact(_codec([builder_uv.x,builder_uv.y]),[_next_positive_float32(gate_uv.x),gate_uv.y]),"gate body UV expected altered one ULP rejected "+entry.path)
		records.append({"scope":"ACTUAL_TWELVE_PROTOTYPE_OPERATION_EQUIVALENCE_NOT_FULL_BODY_GATE","path":entry.path,"sha256":entry.sha256,"size":prototype.render_size_px,"authoring_uv":prototype.foot_uv,"capture_native_uv":_codec([builder_uv.x,builder_uv.y]),"gate_native_uv":_codec([gate_uv.x,gate_uv.y]),"actual_full_body_gate_invoked":false})

func _operations_cases() -> void:
	var authoring_uv: Array = [0.4986979166666667, 0.9]
	var native_uv: Vector2 = Vector2(authoring_uv[0], authoring_uv[1])
	var rendered_uv: Variant = _codec([native_uv.x, native_uv.y])
	_check(not _exact(rendered_uv, _codec(authoring_uv)), "door original-double UV differs from rendered native UV by operation, not just serialization")
	_check(_json_native_exact(rendered_uv, [native_uv.x, native_uv.y]), "door render matches explicit native construction; original authoring UV untouched")
	var scalar_size: Array = [17.0 / 12288.0, 14.0 / 8192.0]
	var vector_size: Vector2 = Vector2(17,14) / Vector2(12288,8192)
	var saved_scalar: Variant = _codec(scalar_size)
	_check(_json_native_exact(saved_scalar, scalar_size), "collision components retain actual scalar double division order")
	_check(not _json_native_exact(saved_scalar, [vector_size.x, vector_size.y]), "codec cannot excuse replacing scalar division with Vector2 Float32 division")
	for width: float in [18.0, 12.0]:
		var exact_scalar: float = width / 12288.0
		var exact_vector: Vector2 = Vector2(width,14) / Vector2(12288,8192)
		_check(exact_scalar == exact_vector.x, "current tree/bamboo literal width binary-exact: " + str(width))
	var center: Vector2 = Vector2(6200.00732421875, 1000)
	var scalar_position: Array = [center.x / 12288.0, center.y / 8192.0]
	var parsed_position: Array = _codec(scalar_position)
	var runtime_center: Vector2 = Vector2(parsed_position[0], parsed_position[1]) * Vector2(12288,8192)
	_check(center.x != runtime_center.x, "spacing counterexample exposes real scalar-position to native-render roundtrip ULP")
	_check(not _json_native_exact(_codec([center.x,center.y]), [runtime_center.x,runtime_center.y]), "default codec alone cannot waive changed spacing operation")
	records.append({"scope":"SYNTHETIC_OPERATION_ORDER_NOT_ACTUAL_CORE_FAILURE","original_door_uv":authoring_uv,"rendered_uv":rendered_uv,"scalar_collision":saved_scalar,"vector_collision":_codec([vector_size.x,vector_size.y]),"original_center":_codec([center.x,center.y]),"runtime_center":_codec([runtime_center.x,runtime_center.y]),"epsilon_added":false})

func _union_and_RF_cases() -> void:
	var pixels: int = 749534
	var area: int = 6291456
	var fraction: float = float(pixels) / float(area)
	var native_union: Dictionary = {"actual_union_pixels":pixels,"actual_union_fraction":fraction,"source_sha256":"original-byte-binding","minimum_exclusive":.08,"passed":fraction>.08}
	var saved_union: Variant = _codec(native_union)
	_check(not _exact(saved_union,native_union), "raw recomputed union ratio differs from default encoded record")
	_check(_json_native_exact(saved_union,native_union), "complete recomputed union exact codec retains all fields and byte bindings")
	var changed: Dictionary = native_union.duplicate(true)
	changed.actual_union_pixels += 1
	changed.actual_union_fraction = float(changed.actual_union_pixels) / float(area)
	_check(not _json_native_exact(saved_union,changed), "one alpha occupancy pixel change remains rejected")
	changed = native_union.duplicate(true)
	changed.source_sha256 = "different-source-bytes"
	_check(not _json_native_exact(saved_union,changed), "union source SHA mismatch remains rejected")
	_check(fraction > .08 and not (.08 > .08), "strict8percent threshold and equality boundary remain unchanged")
	# A synthetic stored Float32 RF triangle. Codec never touches original bytes.
	var rf: PackedFloat32Array = PackedFloat32Array([.11,.23,.37,.41])
	var original_bytes: PackedByteArray = rf.to_byte_array()
	var u: float = 3.0 / 8.0
	var v: float = 2.0 / 8.0
	var height: float = rf[0]*(1.0-u-v)+rf[1]*u+rf[2]*v
	var encoded_height: Variant = _codec(height)
	_check(_json_native_exact(encoded_height,height), "synthetic RF affine expected height uses default codec only at JSON boundary")
	_check(not _json_native_exact(encoded_height,height+0.0001), "different RF height remains rejected without epsilon")
	_check(original_bytes == rf.to_byte_array(), "RF Float32 source bytes unchanged by codec")
	_check(not _json_native_exact("0.5", .5) and not _json_native_exact(true,1.0), "strings/booleans never accepted as numeric metadata")
	# Serializing a nonfinite expected value itself causes JSON's exponent warning.
	# Keep the public codec's stored-INF negative, and test expected-INF against
	# the pinned gate's actual strict finite primitive without serializing INF.
	var nonfinite_expected_actual: Variant = gate_script.call("_equal_exact_value", 1.0, INF)
	_check(not _json_native_exact(INF,1.0) and nonfinite_expected_actual is bool and nonfinite_expected_actual == _exact(1.0,INF) and nonfinite_expected_actual == false, "public codec rejects stored INF; pinned finite primitive rejects expected INF exactly")
	records.append({"scope":"SYNTHETIC_ALPHA_RATIO_AND_RF_CODEC_NOT_ACTUAL_PIXEL_OR_RF_VALIDATION","default_encoded_union":saved_union,"default_encoded_RF_height":encoded_height,"RF_bytes_unchanged":original_bytes==rf.to_byte_array(),"epsilon_added":false,"raw_RGBA_or_resource_arrays_reencoded":false})

func _run() -> void:
	var before: Dictionary = _protected_files()
	var save: Node = root.get_node_or_null("SaveManager")
	var slot_before: Variant = save.get("active_slot") if save != null else null
	_check(FileAccess.get_sha256(GATE_PATH).to_lower() == GATE_SHA, "actual gate exact producer-frozen source SHA")
	if FileAccess.get_sha256(GATE_PATH).to_lower() != GATE_SHA:
		quit(1)
		return
	# Deferred runtime load keeps ordinary autoload context intact. No gate
	# publication/approval/body/capture methods are invoked, only this predicate.
	gate_script = load(GATE_PATH) as GDScript
	_check(gate_script != null and gate_script.can_instantiate(), "actual pinned gate parses in normal autoload context")
	if gate_script == null or not gate_script.can_instantiate():
		quit(1)
		return
	_body_case()
	_prototype_operation_cases()
	_operations_cases()
	_union_and_RF_cases()
	gate_script = null
	for frame in 8: await process_frame
	await _natural_audio_cleanup()
	_check(before == _protected_files(), "completed source metadata and all fifteen ordinary player paths unchanged")
	_check(save == null or save.get("active_slot") == slot_before, "active save slot unchanged")
	print(JSON.stringify({"scope":"SOURCE_UNIT_DEFAULT_JSON_NATIVE_CODEC_PROPOSAL_NOT_FIELD_OR_PUBLICATION","checks":checks,"failed":failures,"records":records,"gate_path":GATE_PATH,"gate_sha256":GATE_SHA,"gate_method_invoked":"_json_native_exact for finite expected values; _equal_exact_value for nonfinite expected scalar","nonfinite_expected_public_codec_executed":false,"nonfinite_expected_predicate":"PINNED_STRICT_FINITE_PRIMITIVE_NOT_PUBLIC_CODEC_SERIALIZATION","epsilon_added":false,"gate_publication_or_builder_invoked":false,"active_raw_read":false,"approval_or_formal_or_player_written":false}))
	print("JOINT_DEFAULT_JSON_NATIVE_CODEC_SOURCE_UNIT: %d checks / %d failures" % [checks, failures])
	quit(0 if failures==0 else 1)

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
