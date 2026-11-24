extends "res://tests/test_v14_alpha_domain_interval_proof_unit_20261002.gd"

## Independent extra tests; the original FC4F synthetic source stays unchanged.
const ORIGINAL_UNIT_PATH := "res://tests/test_v14_alpha_domain_interval_proof_unit_20261002.gd"
const ORIGINAL_UNIT_SHA := "fc4f928e4f8da8c5855346e8947958f0413fc51512144c2d03d516fdfc5b1d66"
const REACHABLE_HELPER_SHA := "08366bb486074aff11d740e26913921f9e2ca512e85b8cbc94330cc1f9bfbb15"

func _small_reachable_cases() -> void:
	var data := _fixture(true)
	data.proof.set("_max_alpha_queries", 2000000)
	data.proof.set("_alpha_queries", 0)
	var negative := Rect2(4.59, 4.59, .02, .02)
	for point: Vector2 in [negative.position, negative.end, Vector2(negative.end.x, negative.position.y), Vector2(negative.position.x, negative.end.y)]:
		_check(_independent_prop_alpha(point, data) < .12, "independent original RGBA subcell negative really below unchanged threshold")
	_check(data.proof.call("_prop_alpha_upper_zero", negative), "reachable clipped bilinear rectangle denies soft alpha despite nearby white source texel")
	var positive := Rect2(5.04, 5.04, .02, .02)
	_check(_independent_prop_alpha(positive.get_center(), data) > .12 and not data.proof.call("_prop_alpha_upper_zero", positive), "actual reachable strong subcell cannot be denied")
	# Mirroring changes the reachable weights, not the source RGBA values.
	data.flip_h = true
	_check(data.proof.configure_prop(data.prop, data.prop_frame, data.prop_rect, data.prop_transform, true, true, false, 1.), "actual source/frame horizontal flip configures")
	var mirrored := Rect2(5.39, 4.59, .02, .02)
	_check(_independent_prop_alpha(mirrored.get_center(), data) < .12 and data.proof.call("_prop_alpha_upper_zero", mirrored), "flipped reachable soft subcell retains conservative strict bound")
	# Nonzero atlas frame must sample the actual adjacent texel even at a small
	# rectangle; an empty nearest frame pixel is not a bilinear absence proof.
	var neighbour := _fixture(true, true, Vector2i(4, 2), Rect2i(1, 0, 2, 2))
	neighbour.prop.set_pixel(0, 0, Color.WHITE)
	neighbour.prop.set_pixel(0, 1, Color.WHITE)
	_check(neighbour.proof.configure_prop(neighbour.prop, neighbour.prop_frame, neighbour.prop_rect, neighbour.prop_transform, true, false, false, 1.), "original atlas neighbour configures")
	neighbour.proof.set("_max_alpha_queries", 2000000)
	var boundary := Rect2(4.09, 4.99, .02, .02)
	_check(_independent_prop_alpha(boundary.get_center(), neighbour) > .12 and _independent_prop_alpha(boundary.get_center(), neighbour, true) == 0, "original bilinear neighbour is genuinely strong while nearest texel stays empty")
	_check(not neighbour.proof.call("_prop_alpha_upper_zero", boundary), "small reachable interval does not erase adjacent atlas contribution")
	neighbour.flip_h = true
	_check(neighbour.proof.configure_prop(neighbour.prop, neighbour.prop_frame, neighbour.prop_rect, neighbour.prop_transform, true, true, false, 1.), "atlas neighbour flip configures")
	_check(not neighbour.proof.call("_prop_alpha_upper_zero", Rect2(5.89, 4.99, .02, .02)), "flipped LINEAR neighbour remains possible at actual render boundary")

func _equality_budget_diagnostics() -> void:
	var equality := _fixture(true)
	equality.prop.fill(Color.WHITE)
	equality.modulation_alpha = .12
	_check(equality.proof.configure_prop(equality.prop, equality.prop_frame, equality.prop_rect, equality.prop_transform, true, false, false, .12), "exact-threshold original white/modulation configures")
	_check(_independent_prop_alpha(Vector2(5, 5), equality) == .12, "independent native original RGBA interpolation is exactly .12")
	var unresolved := _prove(equality, true, {"max_depth": 1})
	_check(unresolved.status == "INCONCLUSIVE" and not unresolved.denied and not unresolved.positive, ".12 equality stays unresolved under unchanged threshold, never synthetic DENIED")
	var terminal: Dictionary = unresolved.get("terminal_box", {})
	var last: Dictionary = unresolved.get("last_live_probe", {})
	_check(typeof(terminal.get("box")) == TYPE_RECT2 and int(terminal.get("depth", -1)) == 1, "actual first terminal rectangle/depth preserved")
	for key: String in ["full17_clear", "physical_clear", "relation_clear", "current_frame_matches", "strong_alpha_hits", "source_alpha_threshold"]:
		_check(last.has(key), "terminal retains actual last live predicate rather than guessing a missing reason: " + key)
	_check(last.get("strong_alpha_hits") == 0 and last.get("source_alpha_threshold") == .12 and last.get("current_frame_matches") == true, "exact-threshold live record has zero strict hits/current frame")
	var constrained := _fixture(true)
	unresolved = _prove(constrained, true, {"max_alpha_queries": 1})
	_check(unresolved.status == "INCONCLUSIVE" and unresolved.reason == "alpha_query_budget" and not unresolved.denied, "extra four-corner evaluations consume existing alpha budget and cannot grant absence when exhausted")
	var geometry: Dictionary = unresolved.get("proof_geometry", {})
	_check(geometry.get("maximum_alpha_queries") == 1 and geometry.get("maximum_box_count") == 50000 and geometry.get("maximum_live_probes") == 256 and geometry.get("maximum_subdivision_depth") == 24 and geometry.get("minimum_box_side") == .03125, "refinement leaves all production default budgets intact")

func _run() -> void:
	_check(FileAccess.get_sha256(ORIGINAL_UNIT_PATH) == ORIGINAL_UNIT_SHA, "unchanged original FC4F synthetic source bound")
	_check(FileAccess.get_sha256("res://tests/helpers/v14_alpha_domain_interval_proof.gd") == REACHABLE_HELPER_SHA, "actual independently reviewed refined helper exact source bound")
	_negative_and_positive_cases()
	_narrow_and_linear_cases()
	_closure_and_malformed_cases()
	_source_immutability_cases()
	_small_reachable_cases()
	_equality_budget_diagnostics()
	active.clear()
	results.clear()
	for settle in 4: await process_frame
	print("REACHABLE_BILINEAR_UNIT checks=%d failures=%d scope=SYNTHETIC_ORIGINAL_RGBA_CURRENT_FRAME_NOT_FULL_WORLD no_Field_no_save_no_GPU" % [checks, failures])
	quit(0 if failures == 0 else 1)
