extends "res://tests/test_v14_alpha_domain_long_reachable_cells_unit_20261002.gd"

## NEW isolated cost-scheduling test; active helper/main and old units stay frozen.
## SOURCE ONLY until the producer runs it in its serial engine window.
const ROOT_DRAFT_PATH := "res://tests/helpers/v14_alpha_domain_interval_proof_root_box_draft.gd"
const ROOT_DRAFT_SHA := "15f02c21f8d16d12fc5ed6e909418d162eee200dc3efe6ea9c6b13f47d0f6acc"
const LONG_UNIT_SHA := "695b89c683f9327797be89fe3a1b8ec576cf854ca32162f7624841f6d42a4016"
const ACTIVE_BASELINE_SHA := "b07c5301ca9e4eace6577541fa0f1b9bd9e09840ee1815b8131b9a8f03b5c21e"

func _fixture(linear: bool = false, transparent: bool = false, prop_size: Vector2i = Vector2i(2, 2), prop_frame: Rect2i = Rect2i(0, 0, 2, 2), prop_rect: Rect2 = Rect2(-1, -1, 2, 2), origin: Vector2 = Vector2(5, 5)) -> Dictionary:
	var data: Dictionary = super._fixture(linear, transparent, prop_size, prop_frame, prop_rect, origin)
	# The inherited long unit explicitly loads D462: replace it once more so
	# every original group and callback actually tests this independent draft.
	var draft: RefCounted = load(ROOT_DRAFT_PATH).new() as RefCounted
	_check(draft.call("configure_mask", data.nav, WORLD), "root draft receives immutable original raw mask")
	_check(draft.call("configure_prop", data.prop, prop_frame, prop_rect, data.prop_transform, linear, false, false, 1.), "root draft receives immutable original prop source/frame")
	data.proof = draft
	data.bundle = draft.call("actor_row_runs", data.actor, Rect2i(0, 0, 2, 2), Rect2(-.5, -.5, 2, 2), Transform2D.IDENTITY, Vector2.ZERO, false, false, "idle_down_0")
	_check(data.bundle.strong_pixel_count == 1, "all inherited cases really use the new root draft")
	return data

func _root_box_scheduling_cases() -> void:
	var data: Dictionary = _fixture(true, true, Vector2i(16, 2), Rect2i(0, 0, 16, 2), Rect2(-8, -1, 16, 2))
	data.prop.set_pixel(8, 1, Color.WHITE)
	_check(data.proof.configure_prop(data.prop, data.prop_frame, data.prop_rect, data.prop_transform, true, false, false, 1.), "root scheduling uses original strong neighbour texel")
	data.proof.set("_max_alpha_queries", 2000000)
	data.proof.set("_alpha_queries", 0)
	var soft: Rect2 = Rect2(2.5, 4.55, 5.05, .02)
	data.proof.set("_current_box", {"box": Rect2(0, 0, 90, 45), "depth": 0})
	_check(not data.proof.call("_prop_alpha_upper_zero", soft), "costly envelope under large current root is UNKNOWN, never DENIED")
	_check(int(data.proof.get("_alpha_queries")) == 0, "large root does not spend clipped-corner budget before subdivision")
	data.proof.set("_current_box", {"box": Rect2(3, 4.5, .04, .04), "depth": 24})
	_check(data.proof.call("_prop_alpha_upper_zero", soft), "small terminal root precisely evaluates the full greater-four source row")
	_check(int(data.proof.get("_alpha_queries")) > 0, "terminal proof consumes actual clipped-corner work")
	data.proof.set("_current_box", {})
	_check(data.proof.call("_prop_alpha_upper_zero", soft), "direct auxiliary bound without current root retains complete long-row evaluation")
	data.proof.set("_current_box", {"box": Rect2(0, 0, 90, 45), "depth": 0})
	var before_short: int = int(data.proof.get("_alpha_queries"))
	_check(data.proof.call("_prop_alpha_upper_zero", Rect2(5.49, 4.55, .02, .02)), "cheap short source interval still refines with a large root context")
	_check(int(data.proof.get("_alpha_queries")) > before_short, "short neighbour-backed interval really retains original corner query costs")
	_check(data.proof.call("_prop_alpha_upper_zero", Rect2(-100, -100, 10, 10)), "already-proven outside-prop bound is not needlessly deferred")
	data.proof.set("_current_box", {"box": Rect2(3, 4.5, 1, 1), "depth": 20})
	_check(data.proof.call("_prop_alpha_upper_zero", soft), "root side exactly one is inclusive for precise long-row evaluation")
	_check(not data.proof.call("_prop_alpha_upper_zero", Rect2(2.5, 4.99, 5.05, .02)), "small root never denies reachable strong source support")
	data.proof.set("_current_box", {})

func _full_long_row_nav_closure() -> void:
	var data: Dictionary = _fixture(true, true, Vector2i(16, 2), Rect2i(0, 0, 16, 2), Rect2(-8, -1, 16, 2))
	data.prop.set_pixel(8, 1, Color.WHITE)
	_check(data.proof.configure_prop(data.prop, data.prop_frame, data.prop_rect, data.prop_transform, true, false, false, 1.), "full domain retains original white source support")
	data.actor = _image(Vector2i(16, 2), Color.TRANSPARENT)
	for x in range(2, 14): data.actor.set_pixel(x, 0, Color.WHITE)
	data.bundle = data.proof.actor_row_runs(data.actor, Rect2i(0, 0, 16, 2), Rect2(-.5, -.5, 16, 2), Transform2D.IDENTITY, Vector2.ZERO, false, false, "idle_down_0")
	_check(data.bundle.strong_pixel_count == 12 and data.bundle.runs.size() == 1 and data.bundle.runs[0].size.x == 11., "full proof retains all twelve actual strong actor centres in one long row")
	# Actual nearest raw nav is a thin legal horizontal strip. Its original
	# samples, including the existing conservative apron, confine roots to soft
	# LINEAR prop alpha. Do not give helper a fabricated alpha-domain rectangle.
	data.nav = _image(Vector2i(1024, 1024), Color.BLACK)
	for y in data.nav.get_height():
		var world_y: float = float(y) / float(data.nav.get_height() - 1) * WORLD.y
		if world_y < 4.52 or world_y > 4.55: continue
		for x in data.nav.get_width(): data.nav.set_pixel(x, y, Color.WHITE)
	_check(data.proof.configure_mask(data.nav, WORLD), "full proof configures original high-resolution strip nav")
	_check(_independent_full17(Vector2(5, 4.535), data), "nav strip contains a genuinely complete17 legal root")
	for point: Vector2 in [Vector2(5.5, 4.51), Vector2(5.5, 4.58), Vector2(5.49, 4.59)]:
		_check(_independent_prop_alpha(point, data) + .000001 < .12, "independent exact source bilinear maximum at guarded strip is below threshold")
	var denied: Dictionary = _prove(data, false)
	_check(denied.status == "DENIED" and denied.unresolved_box_count == 0 and not denied.positive, "complete long-row domain closes without live callback or absence waiver")
	_check(int(denied.closed_interval_box_count) > 1 and float(denied.domain.size.x) > 20., "complete proof really subdivides a large original overlap domain")
	_check(int(denied.alpha_interval_queries) > 4 and int(denied.alpha_interval_queries) < 2000000, "full proof uses real precise corners without exhausting unchanged original budget")
	_check(denied.eliminated_counts.has("mandatory_shoe_original_raw_mask_or_boundary") and denied.eliminated_counts.has("all_original_actor_runs_prop_alpha_upper_at_most_threshold"), "DENIED combines independent raw full17 exclusions with actual complete alpha bounds")
	_check(denied.proof_geometry.maximum_alpha_queries == 2000000 and denied.proof_geometry.maximum_box_count == 50000 and denied.proof_geometry.maximum_live_probes == 256 and denied.proof_geometry.maximum_subdivision_depth == 24 and denied.proof_geometry.minimum_box_side == .03125 and denied.threshold == .12, "no production budget, threshold or precision was relaxed")
	# Strong same source remains reachable if the raw strip is removed. A short
	# budget can only return INCONCLUSIVE, never reuse the previous DENIED proof.
	data.nav.fill(Color.WHITE)
	_check(data.proof.configure_mask(data.nav, WORLD), "control restores actual white navigation")
	var unresolved: Dictionary = _prove(data, false, {"max_alpha_queries": 1})
	_check(unresolved.status == "INCONCLUSIVE" and unresolved.reason == "alpha_query_budget" and not unresolved.denied and unresolved.alpha_interval_queries == 2, "unchanged budget1 remains strict after subdivision scheduling")

func _run() -> void:
	_check(FileAccess.get_sha256(ORIGINAL_UNIT_PATH) == ORIGINAL_UNIT_SHA and FileAccess.get_sha256("res://tests/test_v14_alpha_domain_reachable_bilinear_unit_20261002.gd") == EXTRA_UNIT_SHA and FileAccess.get_sha256("res://tests/test_v14_alpha_domain_long_reachable_cells_unit_20261002.gd") == LONG_UNIT_SHA, "all three inherited suites remain byte-exact frozen")
	_check(FileAccess.get_sha256("res://tests/helpers/v14_alpha_domain_interval_proof.gd") == ACTIVE_BASELINE_SHA and FileAccess.get_sha256(CELLS_DRAFT_PATH) == CELLS_DRAFT_SHA and FileAccess.get_sha256(ROOT_DRAFT_PATH) == ROOT_DRAFT_SHA, "active/helper history exact and new scheduling draft explicitly pinned")
	_negative_and_positive_cases()
	_narrow_and_linear_cases()
	_closure_and_malformed_cases()
	_source_immutability_cases()
	_small_reachable_cases()
	_equality_budget_diagnostics()
	_long_reachable_cases()
	_root_box_scheduling_cases()
	_full_long_row_nav_closure()
	active.clear()
	results.clear()
	for settle in 4: await process_frame
	print("ROOT_BOX_ALPHA_UNIT checks=%d failures=%d scope=SYNTHETIC_ORIGINAL_RGBA_ONE_FRAME_NOT_FULL_WORLD active_sources_unchanged" % [checks, failures])
	quit(0 if failures == 0 else 1)
