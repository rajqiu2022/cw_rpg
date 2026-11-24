extends "res://tests/test_v14_alpha_domain_reachable_bilinear_unit_20261002.gd"

## NEW isolated draft test. Neither the active 08366 helper nor old units change.
const CELLS_DRAFT_PATH := "res://tests/helpers/v14_alpha_domain_interval_proof_reachable_cells_draft.gd"
const CELLS_DRAFT_SHA := "d4629c822dfdeb5d5854dcea150152c41375f990c0f4bcf9e108ea80bc29ca57"
const EXTRA_UNIT_SHA := "def42a1d98263ccbda1186a03f98345157b31aa6c2062d42c868e34cf728a066"

func _fixture(linear: bool = false, transparent: bool = false, prop_size: Vector2i = Vector2i(2, 2), prop_frame: Rect2i = Rect2i(0, 0, 2, 2), prop_rect: Rect2 = Rect2(-1, -1, 2, 2), origin: Vector2 = Vector2(5, 5)) -> Dictionary:
	var data := super._fixture(linear, transparent, prop_size, prop_frame, prop_rect, origin)
	# All inherited FC4F/DEF42 cases really exercise the new draft, not the old pin.
	var draft := load(CELLS_DRAFT_PATH).new() as RefCounted
	_check(draft.call("configure_mask", data.nav, WORLD), "draft receives exact original synthetic raw mask")
	_check(draft.call("configure_prop", data.prop, prop_frame, prop_rect, data.prop_transform, linear, false, false, 1.), "draft receives exact original synthetic source/frame")
	data.proof = draft
	data.bundle = draft.call("actor_row_runs", data.actor, Rect2i(0, 0, 2, 2), Rect2(-.5, -.5, 2, 2), Transform2D.IDENTITY, Vector2.ZERO, false, false, "idle_down_0")
	_check(data.bundle.strong_pixel_count == 1, "new draft preserves one actual strong source pixel")
	return data

func _long_reachable_cases() -> void:
	var data := _fixture(true, true, Vector2i(16, 2), Rect2i(0, 0, 16, 2), Rect2(-8, -1, 16, 2))
	data.prop.set_pixel(8, 1, Color.WHITE)
	_check(data.proof.configure_prop(data.prop, data.prop_frame, data.prop_rect, data.prop_transform, true, false, false, 1.), "long-row original white corner reconfigures")
	data.proof.set("_max_alpha_queries", 2000000)
	for length in [5.05, 4.36]:
		var soft := Rect2(2.5, 4.55, length, .02)
		# Independent original interpolation at the white-column extremum plus
		# every source-cell boundary; actual maximum is .08 with the .01 guard.
		for x in range(3, 8):
			_check(_independent_prop_alpha(Vector2(x, 4.58), data) + .000001 < .12, "long soft strip original source interpolation is strictly below unchanged threshold")
		var before := int(data.proof.get("_alpha_queries"))
		_check(data.proof.call("_prop_alpha_upper_zero", soft), "reachable soft span greater than four source pixels can now be proved without deleting support")
		_check(int(data.proof.get("_alpha_queries")) > before, "long strip actually enumerates clipped corners inside existing query budget")
	var strong := Rect2(2.5, 4.99, 5.05, .02)
	_check(_independent_prop_alpha(Vector2(5.5, 5), data) > .12 and not data.proof.call("_prop_alpha_upper_zero", strong), "same long interval with reachable strong white support cannot become denied")
	data.flip_h = true
	_check(data.proof.configure_prop(data.prop, data.prop_frame, data.prop_rect, data.prop_transform, true, true, false, 1.), "long strip real flip reconfigures")
	_check(data.proof.call("_prop_alpha_upper_zero", Rect2(2.45, 4.55, 5.05, .02)), "flipped long soft strip uses original RGBA and reachable weights")
	_check(_independent_prop_alpha(Vector2(4.5, 5), data) > .12 and not data.proof.call("_prop_alpha_upper_zero", Rect2(2.45, 4.99, 5.05, .02)), "flipped long reachable strong strip remains possible")
	var equality := _fixture(true, true, Vector2i(16, 2), Rect2i(0, 0, 16, 2), Rect2(-8, -1, 16, 2))
	equality.prop.fill(Color.WHITE)
	_check(equality.proof.configure_prop(equality.prop, equality.prop_frame, equality.prop_rect, equality.prop_transform, true, false, false, .12), "long equality source configures unchanged .12")
	equality.proof.set("_max_alpha_queries", 2000000)
	_check(not equality.proof.call("_prop_alpha_upper_zero", Rect2(2.5, 4.55, 5.05, .02)), "long interval .12 equality remains possible, not falsely absent")
	var adjacent := _fixture(true, true, Vector2i(12, 2), Rect2i(2, 0, 8, 2), Rect2(-4, -1, 8, 2))
	adjacent.prop.set_pixel(1, 0, Color.WHITE)
	adjacent.prop.set_pixel(1, 1, Color.WHITE)
	_check(adjacent.proof.configure_prop(adjacent.prop, adjacent.prop_frame, adjacent.prop_rect, adjacent.prop_transform, true, false, false, 1.), "long atlas interval reconfigures actual outside-frame texels")
	adjacent.proof.set("_max_alpha_queries", 2000000)
	_check(_independent_prop_alpha(Vector2(1.1, 5), adjacent) > .12 and _independent_prop_alpha(Vector2(1.1, 5), adjacent, true) == 0, "long atlas boundary genuinely contributes only through LINEAR")
	_check(not adjacent.proof.call("_prop_alpha_upper_zero", Rect2(1.01, 4.99, 4.36, .02)), "greater-four interval preserves original atlas neighbour support")
	adjacent.flip_h = true
	_check(adjacent.proof.configure_prop(adjacent.prop, adjacent.prop_frame, adjacent.prop_rect, adjacent.prop_transform, true, true, false, 1.), "long atlas flip configures")
	_check(_independent_prop_alpha(Vector2(8.9, 5), adjacent) > .12 and not adjacent.proof.call("_prop_alpha_upper_zero", Rect2(4.63, 4.99, 4.36, .02)), "flipped long original atlas edge remains possible")
	# Full prove() control: one genuine long actor row, not a direct helper-only
	# budget check. The first clipped corner consumes the SAME existing budget.
	var budget := _fixture(true, true, Vector2i(16, 2), Rect2i(0, 0, 16, 2), Rect2(-8, -1, 16, 2))
	budget.prop.set_pixel(8, 1, Color.WHITE)
	budget.actor = _image(Vector2i(16, 2), Color.TRANSPARENT)
	for x in range(2, 14): budget.actor.set_pixel(x, 0, Color.WHITE)
	_check(budget.proof.configure_prop(budget.prop, budget.prop_frame, budget.prop_rect, budget.prop_transform, true, false, false, 1.), "full proof long actor control configures original source")
	budget.bundle = budget.proof.actor_row_runs(budget.actor, Rect2i(0, 0, 16, 2), Rect2(-.5, -.5, 16, 2), Transform2D.IDENTITY, Vector2.ZERO, false, false, "idle_down_0")
	_check(budget.bundle.strong_pixel_count == 12 and budget.bundle.runs.size() == 1 and budget.bundle.runs[0].size.x > 4, "actual long row retains every original actor support centre")
	var unresolved := _prove(budget, false, {"max_alpha_queries": 1})
	_check(unresolved.status == "INCONCLUSIVE" and unresolved.reason == "alpha_query_budget" and not unresolved.denied, "full long-row proof exhausts existing corner budget fail-closed")
	_check(unresolved.alpha_interval_queries == 2 and unresolved.proof_geometry.maximum_alpha_queries == 1 and unresolved.proof_geometry.maximum_box_count == 50000 and unresolved.proof_geometry.maximum_live_probes == 256 and unresolved.proof_geometry.maximum_subdivision_depth == 24 and unresolved.proof_geometry.minimum_box_side == .03125, "all other production budgets unchanged with exact consumed corner count")

func _run() -> void:
	_check(FileAccess.get_sha256(ORIGINAL_UNIT_PATH) == ORIGINAL_UNIT_SHA and FileAccess.get_sha256("res://tests/test_v14_alpha_domain_reachable_bilinear_unit_20261002.gd") == EXTRA_UNIT_SHA, "both original synthetic suites remain byte-exact frozen")
	_check(FileAccess.get_sha256("res://tests/helpers/v14_alpha_domain_interval_proof.gd") == REACHABLE_HELPER_SHA and FileAccess.get_sha256(CELLS_DRAFT_PATH) == CELLS_DRAFT_SHA, "active helper untouched and isolated new draft exact source bound")
	_negative_and_positive_cases()
	_narrow_and_linear_cases()
	_closure_and_malformed_cases()
	_source_immutability_cases()
	_small_reachable_cases()
	_equality_budget_diagnostics()
	_long_reachable_cases()
	active.clear()
	results.clear()
	for settle in 4: await process_frame
	print("LONG_REACHABLE_CELLS_UNIT checks=%d failures=%d scope=SYNTHETIC_ORIGINAL_RGBA_CURRENT_FRAME_NOT_FULL_WORLD active_sources_unchanged" % [checks, failures])
	quit(0 if failures == 0 else 1)
