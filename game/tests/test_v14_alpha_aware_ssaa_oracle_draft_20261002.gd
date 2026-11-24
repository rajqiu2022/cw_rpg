extends SceneTree

## Independently rebuild B70B's immutable raw frame, not its pipeline helper.
## SOURCE ONLY; no Field/slots/OUT/production approval or new GPU capture.
const ORACLE := preload("res://tests/helpers/v14_ssaa_alpha_aware_oracle_draft.gd")
const ORACLE_SHA := "01059ce6f42fd0678b38e2be4117c0b282046970fc851282025138f44024b6ce"
const RAW_PATH := "res://build/world_map_v14_ninth_native_preview_visual_v11_forest_transition/entities/native_tree_000_sourcebody_raw_ssaa2.png"
const REPEAT_PATH := "res://build/world_map_v14_ninth_native_preview_visual_v11_forest_transition/entities/native_tree_000_sourcebody_repeat_raw_ssaa2.png"
const RAW_SHA := "89217ad0bd42c09358a1413f0998acebf306a3a4ac97fdc8c071ddb39b1a1f2f"
const ALPHA_PATH := "res://build/world_map_v14_alpha_resampling_visual_v12/alpha_aware_body.png"
const ALPHA_SHA := "fe6699478af30c121fe7655f3b376cc93baa5565e6dd9872cb884134cab36025"
const STRAIGHT_PATH := "res://build/world_map_v14_alpha_resampling_visual_v12/straight_body.png"
const STRAIGHT_SHA := "c219dd2bfc90ffa6c3f25da307918307e496506e42729830c37aab617dabd7ae"
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[IndependentSSAAOracle FAIL] " + message)

func _image(path: String) -> Image:
	var image := Image.load_from_file(path)
	_check(image != null and image.get_format() == Image.FORMAT_RGBA8, "original decoded RGBA8: " + path)
	return image

func _schema_cases() -> void:
	_check(ORACLE.method_kind({"resampling_method": ORACLE.OLD_BODY_METHOD}) == "STRAIGHT" and ORACLE.method_kind({"resampling_method": ORACLE.OLD_WHOLE_METHOD}) == "STRAIGHT", "both historical exact straight methods preserved")
	_check(ORACLE.method_kind({"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID}) == "ALPHA_AWARE", "new exact body identity selects independent alpha-aware algorithm")
	_check(ORACLE.method_kind({"resampling_method": ORACLE.ALPHA_WHOLE_METHOD, "algorithm_identity": ORACLE.ALPHA_ID, "alpha_aware_transparent_body": true}, {"algorithm_identity": ORACLE.ALPHA_ID}) == "ALPHA_AWARE", "whole explicit record identity and top-level recipe exactly agree")
	_check(ORACLE.method_kind({"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID, "alpha_aware_transparent_body": true}) == "ALPHA_AWARE", "optional explicit body boolean true is consistent")
	_check(ORACLE.method_kind({"resampling_method": ORACLE.OPAQUE_METHOD, "algorithm_identity": ORACLE.OPAQUE_ID, "alpha_aware_transparent_body": false}) == "OPAQUE_STRAIGHT", "new explicit opaque identity selects unchanged straight reconstruction")
	for malformed: Dictionary in [
		{"resampling_method": "anything containing INTERPOLATE_LANCZOS"},
		{"resampling_method": ORACLE.ALPHA_BODY_METHOD},
		{"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": "UNKNOWN"},
		{"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID, "alpha_aware_transparent_body": false},
		{"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID, "alpha_aware_transparent_body": "true"},
		{"resampling_method": ORACLE.ALPHA_WHOLE_METHOD, "alpha_aware_transparent_body": true},
		{"resampling_method": ORACLE.ALPHA_WHOLE_METHOD, "algorithm_identity": ORACLE.ALPHA_ID, "alpha_aware_transparent_body": "true"},
		{"resampling_method": ORACLE.OLD_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID},
		{"resampling_method": ORACLE.OPAQUE_METHOD, "alpha_aware_transparent_body": true},
	]: _check(ORACLE.method_kind(malformed) == "REJECT", "unknown/inconsistent identity or non-boolean selector fail-closed")
	for conflict: Array in [
		[{"resampling_method": ORACLE.ALPHA_WHOLE_METHOD, "algorithm_identity": ORACLE.OPAQUE_ID, "alpha_aware_transparent_body": true}, {"algorithm_identity": ORACLE.ALPHA_ID}],
		[{"resampling_method": ORACLE.ALPHA_WHOLE_METHOD, "algorithm_identity": ORACLE.ALPHA_ID, "alpha_aware_transparent_body": true}, {"algorithm_identity": ORACLE.OPAQUE_ID}],
		[{"resampling_method": ORACLE.ALPHA_WHOLE_METHOD, "alpha_aware_transparent_body": true}, {"algorithm_identity": ORACLE.ALPHA_ID}],
		[{"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID}, {"algorithm_identity": ORACLE.OPAQUE_ID}],
		[{"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID}, {"algorithm_identity": "UNKNOWN"}],
		[{"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID}, {"algorithm_identity": true}],
	]: _check(ORACLE.method_kind(conflict[0], conflict[1]) == "REJECT", "record identity cannot be overridden or supplied by conflicting recipe identity")
	var a := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	a.fill(Color(1, 0, 0, 0))
	a.set_pixel(3, 3, Color(.2, .8, .1, 1))
	var b := a.duplicate() as Image
	for y in 8:
		for x in 8:
			if b.get_pixel(x, y).a == 0: b.set_pixel(x, y, Color(0, 1, .5, 0))
	var recipe := {"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID}
	var before := a.get_data().duplicate()
	var first := ORACLE.rebuild(a, Vector2i(4, 4), recipe)
	var second := ORACLE.rebuild(b, Vector2i(4, 4), recipe)
	_check(first != null and second != null and first.get_data() == second.get_data(), "fully transparent source RGB cannot create alpha-aware halo")
	_check(a.get_data() == before, "independent packed reconstruction never mutates original RGBA")
	var low := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	low.fill(Color(.2, .8, .1, 1. / 255.))
	var rebuilt := ORACLE.rebuild(low, Vector2i(4, 4), recipe)
	_check(rebuilt != null and rebuilt.get_pixel(1, 1).a > 0 and rebuilt.get_pixel(1, 1).a < .12, "actual weak alpha survives without threshold cutout")
	var opaque_recipe := {"resampling_method": ORACLE.OPAQUE_METHOD, "algorithm_identity": ORACLE.OPAQUE_ID, "alpha_aware_transparent_body": false}
	_check(ORACLE.rebuild(a, Vector2i(4, 4), opaque_recipe) == null, "opaque-only recipe rejects a genuinely transparent raw frame")
	_check(ORACLE.rebuild(a, Vector2i(3, 4), recipe) == null and ORACLE.rebuild(a, Vector2i(4, 4), {}) == null, "wrong native ratio and unknown schema reject reconstruction")

func _run() -> void:
	_check(FileAccess.get_sha256("res://tests/helpers/v14_ssaa_alpha_aware_oracle_draft.gd") == ORACLE_SHA, "independent QA draft exact source bound")
	_schema_cases()
	for pair: Array in [[RAW_PATH, RAW_SHA], [REPEAT_PATH, RAW_SHA], [ALPHA_PATH, ALPHA_SHA], [STRAIGHT_PATH, STRAIGHT_SHA]]:
		_check(FileAccess.get_sha256(pair[0]) == pair[1], "actual B70B source/output immutable bytes bound: " + pair[0])
	var raw := _image(RAW_PATH)
	var repeat := _image(REPEAT_PATH)
	var alpha := _image(ALPHA_PATH)
	var straight := _image(STRAIGHT_PATH)
	if raw != null and repeat != null and alpha != null and straight != null:
		var raw_before := raw.get_data().duplicate()
		_check(raw.get_data() == repeat.get_data(), "actual native high frames repeat every original RGBA byte")
		var record := {"resampling_method": ORACLE.ALPHA_BODY_METHOD, "algorithm_identity": ORACLE.ALPHA_ID}
		var rebuilt := ORACLE.rebuild(raw, alpha.get_size(), record)
		var rebuilt_repeat := ORACLE.rebuild(repeat, alpha.get_size(), record)
		_check(rebuilt != null and rebuilt.get_data() == alpha.get_data(), "packed scalar independent algorithm equals every actual alpha-aware output byte")
		_check(rebuilt_repeat != null and rebuilt_repeat.get_data() == rebuilt.get_data(), "native repeat independently derives every exact logical repeat byte")
		var old := ORACLE.rebuild(raw, straight.get_size(), {"resampling_method": ORACLE.OLD_BODY_METHOD})
		_check(old != null and old.get_data() == straight.get_data(), "historical straight alpha/RGB route remains byte-exact unchanged")
		_check(raw.get_data() == raw_before and FileAccess.get_sha256(RAW_PATH) == RAW_SHA, "actual source is unchanged in memory and on disk")
	raw = null
	repeat = null
	alpha = null
	straight = null
	for settle in 4: await process_frame
	print("INDEPENDENT_ALPHA_AWARE_SSAA_ORACLE checks=%d failures=%d scope=LIMITED_CPU_RAW_FRAME_RECONSTRUCTION_NOT_FULL_OR_VISUAL no_Field_no_slots_no_GPU" % [checks, failures])
	quit(0 if failures == 0 else 1)
