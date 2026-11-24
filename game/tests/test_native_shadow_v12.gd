extends SceneTree

# Minimal native-shadow capability only. This test never constructs Field,
# renders/imports assets, runs v11, promotes a candidate or writes old outputs.
# Raw ON/OFF and independently captured body alpha are the evidence; neither
# producer statistics nor a nonempty precomputed diff can establish a shadow.
const PREFIX := "res://build/native_shadow_v12_"
const SIZE := Vector2i(1536,512)
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const PROTECTED := [
	"res://build/world_native_pair_ortho_v11_art.json",
	"res://build/world_native_pair_ortho_v11_shadow.png",
	"res://scripts/dev/run_world_native_pair_landmark_v11.gd",
	"res://tests/test_world_native_pair_landmark_v11.gd",
]
var _checks := 0
var _failures := 0
var _successes: Array[String] = []
var _empty_cases: Array[String] = []
var _ground_only_successes: Array[String] = []
var _raw: Dictionary = {}
var _capture_audit: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, description: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("[NativeShadowV12 QA] " + description)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func _read_image(path: String) -> Image:
	var result := Image.new()
	if result.load(path) != OK or result.get_size() != SIZE:
		_check(false,"Missing/wrong-size raw image: " + path)
		return null
	result.convert(Image.FORMAT_RGBA8)
	return result


func _luma(color: Color) -> float:
	return color.r * 0.299 + color.g * 0.587 + color.b * 0.114


func _numbers_match(value: Variant, expected: Array) -> bool:
	# JSON parses numbers as floats, whereas camera/rect literals are integers.
	if not value is Array or value.size() != expected.size():
		return false
	for index in expected.size():
		if not (value[index] is float or value[index] is int):
			return false
		if not is_equal_approx(float(value[index]),float(expected[index])):
			return false
	return true


func _body_exclusion(body: Image) -> PackedByteArray:
	var exclusion := PackedByteArray()
	exclusion.resize(SIZE.x * SIZE.y)
	for y in SIZE.y:
		for x in SIZE.x:
			if body.get_pixel(x,y).a <= 0.01:
				continue
			for oy in range(-2,3):
				for ox in range(-2,3):
					var tx := clampi(x+ox,0,SIZE.x-1)
					var ty := clampi(y+oy,0,SIZE.y-1)
					exclusion[ty*SIZE.x+tx] = 1
	return exclusion


func _case(name: String, receiver: String, subject: String, mode: String,
		shadow_mode: int = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, max_distance: float = 32.0) -> void:
	var config := _read_json(PREFIX + name + ".json")
	_check(not config.is_empty(),"Case config exists: " + name)
	if config.is_empty():
		return
	_check(config.get("case") == name and config.get("receiver") == receiver
		and config.get("subject") == subject and config.get("caster_mode") == mode,
		"Case/resource identity must not alias another experiment: " + name)
	var paths: Dictionary = config.get("paths",{})
	var required_paths := {"on":"on","off":"off","source_body":"body",
		"raw_difference":"difference","ground_difference":"ground_difference"}
	var path_matches := true
	for key in required_paths:
		path_matches = path_matches and paths.get(key) == PREFIX + name + "_" + required_paths[key] + ".png"
	_check(path_matches,"All evidence paths bound to this case: " + name)
	_check(_numbers_match(config.get("canvas"),[SIZE.x,SIZE.y]) and _numbers_match(config.get("camera_position"),[0,12,12])
		and float(config.get("camera_ortho_size",0)) == 10.0
		and config.get("camera_mask") == 1 and config.get("own_world_3d") == true,
		"Common camera/canvas/isolated world: " + name)
	_check(_numbers_match(config.get("light_rotation"),[-55,-34,0])
		and is_equal_approx(float(config.get("light_energy",0)),1.15)
		and is_equal_approx(float(config.get("ambient_energy",0)),0.62)
		and config.get("light_shadow_enabled") == true and config.get("receiver_self_cast") == false,
		"Receiver/light fixture invariant, receiver is not caster: " + name)
	_check(config.get("caster_layer") == (2 if mode == "camera_excluded" else 1)
		and (int(config.get("light_cull_mask",0)) & int(config.get("caster_layer",0))) != 0,
		"Camera visibility experiment distinguished from light inclusion: " + name)
	var expected_change := "cast_shadow_ON_vs_OFF_with_body_kept" if mode == "visible" else "SHADOWS_ONLY_vs_hidden" if mode == "shadows_only" else "layer2_active_ON_vs_OFF_camera_mask1"
	_check(config.get("only_on_off_change") == expected_change
		and config.get("synchronized_readback") == "6_process_frames_then_RenderingServer.frame_post_draw_per_state"
		and config.get("body_mask") == "actual_source_transparent_render_dilated_2px_for_ground_difference",
		"Explicit state delta/body exclusion/postdraw readback: " + name)
	_check(config.get("render_method") == "gl_compatibility"
		and config.get("render_driver") == "opengl3"
		and int(config.get("positional_shadow_atlas_size",0)) == 2048
		and config.get("positional_atlas_is_not_directional_atlas") == true
		and int(config.get("directional_shadow_atlas_setting",0)) > 0,
		"Actual driver and separate positional/directional atlas records: " + name)
	_check(int(config.get("directional_shadow_mode",-1)) == shadow_mode
		and float(config.get("directional_shadow_max_distance",0)) == max_distance
		and is_equal_approx(float(config.get("shadow_bias",0)),0.02)
		and is_equal_approx(float(config.get("shadow_normal_bias",0)),0.08),
		"Explicit shadow frustum/mode and common bias settings: " + name)
	_check(config.get("source") == (BOULDER if subject == "boulder" else "native_BoxMesh_1.3m")
		and config.get("source_sha256") == (FileAccess.get_sha256(BOULDER) if subject == "boulder" else "native_geometry"),
		"Original caster source/hash: " + name)
	var images: Dictionary = {}
	for suffix in ["on","off","on_repeat","off_repeat","body","difference","ground_difference"]:
		var loaded := _read_image(PREFIX + name + "_" + suffix + ".png")
		if loaded == null:
			return
		images[suffix] = loaded
	var on: Image = images["on"]
	var off: Image = images["off"]
	var body: Image = images["body"]
	var full: Image = images["difference"]
	var ground: Image = images["ground_difference"]
	var repeat_on: Image = images["on_repeat"]
	var repeat_off: Image = images["off_repeat"]
	_check(on.get_data() == repeat_on.get_data() and off.get_data() == repeat_off.get_data(),
		"Independent same-state repeated pixels stable: " + name)
	_check(FileAccess.get_sha256(PREFIX+name+"_on.png") == FileAccess.get_sha256(PREFIX+name+"_on_repeat.png")
		and FileAccess.get_sha256(PREFIX+name+"_off.png") == FileAccess.get_sha256(PREFIX+name+"_off_repeat.png")
		and config.get("on_repeat_sha") == FileAccess.get_sha256(PREFIX+name+"_on_repeat.png")
		and config.get("off_repeat_sha") == FileAccess.get_sha256(PREFIX+name+"_off_repeat.png"),
		"Actual repeated PNG SHA, not reported boolean: " + name)
	var body_rect := body.get_used_rect()
	_check(body_rect.has_area() and body_rect.size.x < SIZE.x and body_rect.size.y < SIZE.y,
		"Independent original body alpha must be nonempty, localized and transparent: " + name)
	_check(body.get_pixel(0,0).a == 0 and body.get_pixel(SIZE.x-1,0).a == 0
		and body.get_pixel(0,SIZE.y-1).a == 0 and body.get_pixel(SIZE.x-1,SIZE.y-1).a == 0,
		"Sourcebody corners must be truly transparent, not opaque background contamination: " + name)
	var validity: Dictionary = _capture_audit.get(name,{})
	if config.has("valid_case"):
		validity = config
	_check(validity.get("valid_case") == true and validity.get("on_repeat_exact") == true
		and validity.get("off_repeat_exact") == true,
		"Source capture gate and independent body/repeats agree: " + name)
	var exclusion := _body_exclusion(body)
	var dark := 0
	var ground_count := 0
	var inside_body := 0
	var signed_changes := 0
	var full_mismatch := 0
	var ground_mismatch := 0
	var nonblack_diff := 0
	var max_delta := 0.0
	var max_alpha := 0.0
	var min_pixel := SIZE
	var max_pixel := Vector2i(-1,-1)
	for y in SIZE.y:
		for x in SIZE.x:
			var before := _luma(off.get_pixel(x,y))
			var delta := before - _luma(on.get_pixel(x,y))
			max_delta = maxf(max_delta,absf(delta))
			if absf(delta) > 0.004:
				signed_changes += 1
			var alpha := clampf(delta / maxf(before,0.025),0,0.95)
			if alpha < 0.015:
				alpha = 0.0
			var ground_alpha := 0.0
			if alpha > 0:
				dark += 1
				if exclusion[y*SIZE.x+x] != 0:
					inside_body += 1
				else:
					ground_count += 1
					ground_alpha = alpha
					max_alpha = maxf(max_alpha,alpha)
					min_pixel.x = mini(min_pixel.x,x)
					min_pixel.y = mini(min_pixel.y,y)
					max_pixel.x = maxi(max_pixel.x,x)
					max_pixel.y = maxi(max_pixel.y,y)
			var fp := full.get_pixel(x,y)
			var gp := ground.get_pixel(x,y)
			# Image.set_pixel(RGBA8) truncates alpha*255 to the byte, not round.
			# Compare exact encoded bytes; do not allow an arbitrary alpha slack.
			if roundi(fp.a*255.0) != int(alpha*255.0):
				full_mismatch += 1
			if roundi(gp.a*255.0) != int(ground_alpha*255.0):
				ground_mismatch += 1
			if fp.r != 0 or fp.g != 0 or fp.b != 0 or gp.r != 0 or gp.g != 0 or gp.b != 0:
				nonblack_diff += 1
	# Pixel extent includes the final nonzero pixel in both dimensions.
	var used := Rect2i(min_pixel,max_pixel-min_pixel+Vector2i.ONE) if ground_count > 0 else Rect2i()
	var stats: Dictionary = config.get("statistics",{})
	_check(full_mismatch == 0 and ground_mismatch == 0 and nonblack_diff == 0,
		"Whole-pixel raw luma reconstructs both masks, body excluded: %s full=%d ground=%d RGB=%d" % [name,full_mismatch,ground_mismatch,nonblack_diff])
	_check(dark == int(stats.get("dark_difference_pixels",-1))
		and ground_count == int(stats.get("outside_body_ground_pixels",-1))
		and inside_body == int(stats.get("inside_dilated_body_difference_pixels",-1))
		and signed_changes == int(stats.get("signed_change_pixels",-1))
		and is_equal_approx(max_delta,float(stats.get("max_any_luma_delta",-1)))
		and is_equal_approx(max_alpha,float(stats.get("max_ground_alpha",-1))),
		"Independent full image statistics match declared evidence: " + name)
	_check(_numbers_match(stats.get("ground_used_rect"),[used.position.x,used.position.y,used.size.x,used.size.y])
		and ground.get_used_rect() == used and dark == inside_body+ground_count,
		"Nonempty alpha extent is actual raw darkening outside source body: " + name)
	if ground_count > 0:
		_successes.append(name)
		if mode != "visible":
			_ground_only_successes.append(name)
	else:
		_empty_cases.append(name)
	_raw[name] = images
	print("[NativeShadowV12 QA case] ",name," ground=",ground_count," body=",inside_body,
		" dark=",dark," alpha=",max_alpha," rect=",used," repeat_exact=true")


func _run() -> void:
	var protected_sha := {}
	for path in PROTECTED:
		protected_sha[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	var matrix := _read_json(PREFIX + "matrix.json")
	_check(not matrix.is_empty() and matrix.get("version") == "native-shadow-capability-v12",
		"Completed minimal matrix required; no partial assets tested as ready")
	if matrix.is_empty():
		print("[NativeShadowV12 QA] checks=",_checks," failures=",_failures,"; matrix not ready; Field/GPU/full-map NOT RUN")
		quit(1)
		return
	_check(matrix.get("cases",[]).size() == 12 and matrix.get("single_GPU_matrix_only") == true
		and matrix.get("formal_or_v11_writes") == false
		and matrix.get("raw_visible_body_differences_not_accepted_as_ground_shadow") == true,
		"Complete diagnostic-only 12 case matrix, not whole-map readiness")
	var audit := _read_json(PREFIX+"capture_audit.json")
	_check(audit.get("cases",[]).size() == 12 and audit.get("invalid_cases",[]).is_empty()
		and audit.get("no_GPU_or_raw_output_overwrite") == true,
		"Original matrix has completed fail-closed sourcebody/repeat audit")
	for validity: Dictionary in audit.get("cases",[]):
		_capture_audit[validity.get("case","")] = validity
	for receiver in ["standard","local_surface"]:
		for subject in ["cube","boulder"]:
			for mode in ["visible","shadows_only","camera_excluded"]:
				_case(receiver+"_"+subject+"_"+mode+"_atlas2048",receiver,subject,mode)
			var hidden_key: String = receiver+"_"+subject+"_shadows_only_atlas2048"
			var excluded_key: String = receiver+"_"+subject+"_camera_excluded_atlas2048"
			if _raw.has(hidden_key) and _raw.has(excluded_key):
				var hidden_off: Image = _raw[hidden_key]["off"]
				var excluded_off: Image = _raw[excluded_key]["off"]
				_check(hidden_off.get_data() == excluded_off.get_data(),
					"Caster-hidden and camera-excluded OFF share identical receiver-only frame: " + receiver+"/"+subject)
			var visible_key: String = receiver+"_"+subject+"_visible_atlas2048"
			if _raw.has(visible_key) and _raw.has(hidden_key):
				var visible_off: Image = _raw[visible_key]["off"]
				var hidden_off: Image = _raw[hidden_key]["off"]
				var visible_ground: Image = _raw[visible_key]["ground_difference"]
				var hidden_ground: Image = _raw[hidden_key]["ground_difference"]
				_check(visible_off.get_data() != hidden_off.get_data()
					and visible_ground.get_data() == hidden_ground.get_data(),
					"Body is present in visible baseline, yet true ground cast agrees with SHADOWS_ONLY: " + receiver+"/"+subject)
	var actual_status := "GROUND_CAST_EVIDENCE_FOUND" if not _successes.is_empty() else "ALL_CASES_EMPTY_NEEDS_TECHNICAL_DIAGNOSIS"
	_check(matrix.get("status") == actual_status and matrix.get("ground_nonempty_cases") == _successes,
		"Matrix classification follows independent ground pixels, not body or metadata assertion")
	_check(not _successes.is_empty(),"CAPABILITY gate: at least one true ground cast outside body must be nonempty; empty or body-only difference is FAIL")
	for receiver in ["standard","local_surface"]:
		var valid_ground_only := false
		for name in _ground_only_successes:
			valid_ground_only = valid_ground_only or name.begins_with(receiver+"_")
		_check(valid_ground_only,"CAPABILITY gate: receiver "+receiver+" must have nonvisible ground-only raw cast evidence")
	# Two explicitly authorized frustum controls have their own master/audit;
	# they must never replace the original twelve case matrix.
	var supplement := _read_json(PREFIX+"ortho_control_matrix.json")
	var supplement_audit := _read_json(PREFIX+"ortho_control_capture_audit.json")
	_check(supplement.get("version") == "native-shadow-capability-v12-ortho-control"
		and supplement.get("cases",[]).size() == 2
		and supplement.get("supplement_authorized_cases") == 2
		and supplement.get("full_map_rendered") == false
		and supplement.get("invalid_cases",[]).is_empty(),
		"Two supplemental controls isolated from original twelve; no map capture")
	_check(supplement_audit.get("cases",[]).size() == 2
		and supplement_audit.get("invalid_cases",[]).is_empty(),
		"Supplemental body/readback captures fail closed independently")
	for validity: Dictionary in supplement_audit.get("cases",[]):
		_capture_audit[validity.get("case","")] = validity
	var baseline_key := "local_surface_boulder_shadows_only_atlas2048"
	for distance in [40,32]:
		var name := baseline_key+"_ortho_control_max"+str(distance)
		_case(name,"local_surface","boulder","shadows_only",DirectionalLight3D.SHADOW_ORTHOGONAL,float(distance))
		_check(_ground_only_successes.has(name),"Supplement has actual nonvisible cast, not a body difference: "+name)
		if _raw.has(name) and _raw.has(baseline_key):
			var supplemental_off: Image = _raw[name]["off"]
			var baseline_off: Image = _raw[baseline_key]["off"]
			_check(supplemental_off.get_data() == baseline_off.get_data(),
				"Frustum control preserves actual receiver-only OFF pixels: "+name)
	for path in PROTECTED:
		_check(protected_sha[path] == (FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"),
			"v11 failed candidate/runner/WIP unchanged by minimum diagnostic QA: " + path)
	print("[NativeShadowV12 QA] checks=",_checks," failures=",_failures,
		" true_ground_cases=",_successes," raw_ground_only_cases=",_ground_only_successes,
		" empty_controls=",_empty_cases,"; Field/GPU/full-map NOT RUN; v11 readiness NOT changed")
	quit(0 if _failures == 0 else 1)
