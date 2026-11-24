extends SceneTree
## Independent synthetic unit fixture. SOURCE ONLY until producer runs it.
## No Field/Router/rendering, production data, files, slots or approval writes.
## Invoke only under the producer's serial engine window.

const PROOF := preload("res://tests/helpers/v14_alpha_domain_interval_proof.gd")
const THRESHOLD := .12
const WORLD := Vector2(10, 10)
var checks := 0
var failures := 0
var active: Dictionary = {}
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("INTERVAL UNIT: " + message)

func _image(size: Vector2i, color: Color) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image

func _shoes() -> PackedVector2Array:
	var offsets := PackedVector2Array()
	offsets.append(Vector2.ZERO)
	for index in 16:
		var angle := TAU * float(index) / 16.
		offsets.append(Vector2(cos(angle) * .01, sin(angle) * .006))
	return offsets

func _fixture(linear: bool = false, transparent: bool = false, prop_size: Vector2i = Vector2i(2, 2), prop_frame: Rect2i = Rect2i(0, 0, 2, 2), prop_rect: Rect2 = Rect2(-1, -1, 2, 2), origin: Vector2 = Vector2(5, 5)) -> Dictionary:
	var nav := _image(Vector2i(32, 32), Color.WHITE)
	var actor := _image(Vector2i(2, 2), Color.TRANSPARENT)
	actor.set_pixel(0, 0, Color.WHITE)
	var prop := _image(prop_size, Color.TRANSPARENT)
	if not transparent: prop.set_pixel(prop_frame.position.x + 1, prop_frame.position.y + 1, Color.WHITE)
	var proof := PROOF.new()
	var transform := Transform2D(0., origin)
	_check(proof.configure_mask(nav, WORLD), "synthetic original raw mask configures")
	_check(proof.configure_prop(prop, prop_frame, prop_rect, transform, linear, false, false, 1.), "synthetic original prop configures")
	# Pixel (0,0) centre maps exactly to the actor root, independently of prop.
	var bundle: Dictionary = proof.actor_row_runs(actor, Rect2i(0, 0, 2, 2), Rect2(-.5, -.5, 2, 2), Transform2D.IDENTITY, Vector2.ZERO, false, false, "idle_down_0")
	_check(not bundle.is_empty() and bundle.strong_pixel_count == 1, "actual one original strong actor pixel generates one-frame support")
	var data := {"proof": proof, "nav": nav, "actor": actor, "prop": prop, "bundle": bundle, "prop_frame": prop_frame, "prop_rect": prop_rect, "prop_transform": transform, "linear": linear, "flip_h": false, "flip_v": false, "modulation_alpha": 1., "shoes": _shoes(), "blockers": [], "physical": [], "depth": 6., "allowed_root": Rect2(), "require_gate": false, "evidence_override": {}}
	return data

func _prove(data: Dictionary, callback: bool = false, limits: Dictionary = {}, relation: String = "behind") -> Dictionary:
	active = data
	var blockers: Array[Rect2] = []
	for rect: Rect2 in data.blockers: blockers.append(rect)
	var physical: Array[Rect2] = []
	for rect: Rect2 in data.physical: physical.append(rect)
	var validator := Callable()
	if callback: validator = Callable(self, "_live_evidence")
	var result: Dictionary = data.proof.prove(data.bundle, relation, Vector2.DOWN, 0., float(data.depth), blockers, data.shoes, physical, validator, limits)
	results.append(result)
	_check(result.get("status") in ["POSITIVE", "DENIED", "INCONCLUSIVE"], "closed status vocabulary")
	print("INTERVAL_CASE %d status=%s reason=%s boxes=%s live=%s" % [results.size(), result.get("status"), result.get("reason"), result.get("closed_interval_box_count", 0), result.get("strict_live_probe_count", 0)])
	return result

func _independent_prop_alpha(point: Vector2, data: Dictionary, force_nearest: bool = false) -> float:
	# Direct original RGBA formula; never call helper alpha/integral methods.
	var rect: Rect2 = data.prop_rect
	var local: Vector2 = data.prop_transform.affine_inverse() * point
	if not rect.has_point(local): return 0.
	var uv := (local - rect.position) / rect.size
	if data.flip_h: uv.x = 1. - uv.x
	if data.flip_v: uv.y = 1. - uv.y
	var frame: Rect2i = data.prop_frame
	var image: Image = data.prop
	if force_nearest or not data.linear:
		var pixel := frame.position + Vector2i(clampi(int(uv.x * frame.size.x), 0, frame.size.x - 1), clampi(int(uv.y * frame.size.y), 0, frame.size.y - 1))
		return image.get_pixelv(pixel).a * float(data.modulation_alpha)
	var texel := Vector2(frame.position) + uv * Vector2(frame.size) - Vector2(.5, .5)
	var floor_x := floori(texel.x)
	var floor_y := floori(texel.y)
	var fraction := texel - Vector2(floor_x, floor_y)
	var alpha := 0.
	for dy in 2:
		for dx in 2:
			var weight := (fraction.x if dx == 1 else 1. - fraction.x) * (fraction.y if dy == 1 else 1. - fraction.y)
			alpha += weight * image.get_pixel(clampi(floor_x + dx, 0, image.get_width() - 1), clampi(floor_y + dy, 0, image.get_height() - 1)).a
	return alpha * float(data.modulation_alpha)

func _independent_full17(point: Vector2, data: Dictionary) -> bool:
	var image: Image = data.nav
	if data.shoes.size() != 17: return false
	for offset: Vector2 in data.shoes:
		var sample := point + offset
		if sample.x < 0 or sample.y < 0 or sample.x >= WORLD.x or sample.y >= WORLD.y: return false
		var pixel := Vector2i(roundi(sample.x / WORLD.x * (image.get_width() - 1)), roundi(sample.y / WORLD.y * (image.get_height() - 1)))
		var color := image.get_pixelv(pixel)
		if color.a < .5 or maxf(color.r, maxf(color.g, color.b)) < .5: return false
		for blocker: Rect2 in data.blockers:
			if blocker.has_point(sample): return false
	return true

func _independent_physical(point: Vector2, data: Dictionary) -> bool:
	for forbidden: Rect2 in data.physical:
		if forbidden.has_point(point): return false
	return not data.require_gate or data.allowed_root.has_point(point)

func _live_evidence(point: Vector2, frame_identity: String, relation: String) -> Dictionary:
	var evidence := {"full17_clear": _independent_full17(point, active), "physical_clear": _independent_physical(point, active), "relation_clear": point.y < float(active.depth) if relation == "behind" else point.y > float(active.depth), "current_frame_matches": frame_identity == "idle_down_0", "strong_alpha_hits": 1 if _independent_prop_alpha(point, active) > THRESHOLD else 0, "source_alpha_threshold": THRESHOLD}
	var override: Dictionary = active.evidence_override
	if override.has("omit"): evidence.erase(override.omit)
	if override.has("set_key"): evidence[override.set_key] = override.value
	return evidence

func _negative_and_positive_cases() -> void:
	var black := _fixture()
	black.nav.fill(Color.BLACK)
	_check(black.proof.configure_mask(black.nav, WORLD), "black raw mask replaces context")
	var denied := _prove(black)
	_check(denied.get("status") == "DENIED" and denied.get("unresolved_box_count", -1) == 0 and denied.get("eliminated_counts", {}).has("mandatory_shoe_original_raw_mask_or_boundary"), "all-black nav denies whole continuous alpha domain")
	var blocked := _fixture()
	blocked.blockers.append(Rect2(-100, -100, 210, 210))
	denied = _prove(blocked)
	_check(denied.get("status") == "DENIED" and denied.get("eliminated_counts", {}).has("mandatory_shoe_grown_blocker"), "exact grown full-foot blocker covers whole domain")
	var transparent := _fixture(false, true)
	denied = _prove(transparent)
	_check(denied.get("status") == "DENIED" and denied.get("eliminated_counts", {}).has("all_original_actor_runs_prop_alpha_upper_at_most_threshold"), "fully transparent original prop has no strong overlap anywhere")
	var one_pixel := _fixture()
	var positive := _prove(one_pixel, true)
	_check(positive.get("status") == "POSITIVE" and positive.get("live_evidence", {}).get("strong_alpha_hits", 0) == 1, "actual one-pixel strict callback yields positive")
	_check(_independent_full17(positive.get("point", Vector2(-1, -1)), one_pixel) and _independent_physical(positive.get("point", Vector2(-1, -1)), one_pixel), "positive independently has all17 shoes and physical clearance")
	_check(String(positive.get("coverage_scope", "")).contains("one actual direction/frame") and not positive.has("all_animation_frames_denied"), "one frame result never pretends to cover all animation frames")

func _narrow_and_linear_cases() -> void:
	var narrow := _fixture(false, false, Vector2i(2, 2), Rect2i(0, 0, 2, 2), Rect2(-.1, -.1, .2, .2), Vector2(4.5, 4.5))
	narrow.require_gate = true
	narrow.allowed_root = Rect2(4.45, 4.45, .1, .1)
	# Exact static forbidden-root Minkowski rectangles leave only the small gate.
	# Both independent callback and the proof receive the SAME physical model.
	narrow.physical.append(Rect2(-100, -100, 104.45, 210))
	narrow.physical.append(Rect2(4.55, -100, 110, 210))
	narrow.physical.append(Rect2(4.45, -100, .1, 104.45))
	narrow.physical.append(Rect2(4.45, 4.55, .1, 110))
	var coarse_hits := 0
	for y in range(0, 10, 8):
		for x in range(0, 10, 8):
			var point := Vector2(x, y)
			if _independent_full17(point, narrow) and _independent_physical(point, narrow) and _independent_prop_alpha(point, narrow) > THRESHOLD: coarse_hits += 1
	_check(coarse_hits == 0, "8px lattice really misses the narrow legal stand")
	var positive := _prove(narrow, true)
	_check(positive.status == "POSITIVE" and narrow.allowed_root.has_point(positive.get("point", Vector2(-1, -1))), "interval solver finds strict positive missed by8px lattice")
	# Nonzero atlas frame: strong texel is OUTSIDE frame, but LINEAR samples it.
	var linear := _fixture(true, true, Vector2i(4, 2), Rect2i(1, 0, 2, 2))
	linear.prop.set_pixel(0, 0, Color.WHITE)
	linear.prop.set_pixel(0, 1, Color.WHITE)
	_check(linear.proof.configure_prop(linear.prop, linear.prop_frame, linear.prop_rect, linear.prop_transform, true, false, false, 1.), "LINEAR adjacent source texels reconfigure independently")
	_check(_independent_prop_alpha(Vector2(4.1, 5), linear) > THRESHOLD and _independent_prop_alpha(Vector2(4.1, 5), linear, true) == 0., "actual bilinear neighbour strong while nearest frame texel is empty")
	positive = _prove(linear, true)
	_check(positive.status == "POSITIVE", "bilinear neighbour must not become false DENIED")
	if positive.status == "POSITIVE":
		_check(_independent_prop_alpha(positive.point, linear) > THRESHOLD and _independent_prop_alpha(positive.point, linear, true) == 0., "solver positive is specifically an adjacent-texel LINEAR contribution")
	# Same atlas frame under affine scale + horizontal flip, no runtime texture.
	linear.prop_transform = Transform2D(Vector2(1.5, 0), Vector2(0, .75), Vector2(5, 5))
	linear.flip_h = true
	_check(linear.proof.configure_prop(linear.prop, linear.prop_frame, linear.prop_rect, linear.prop_transform, true, true, false, 1.), "actual scale/flip prop configures")
	positive = _prove(linear, true)
	_check(positive.status != "DENIED", "scale/flip original neighbour support is not falsely denied")

func _closure_and_malformed_cases() -> void:
	var solid := _fixture()
	var unresolved := _prove(solid, false, {"max_boxes": 1})
	_check(unresolved.status == "INCONCLUSIVE" and unresolved.reason == "box_work_budget", "one-box finite miss stays inconclusive")
	for malformed: Dictionary in [{"max_boxes": "1"}, {"max_boxes": 1.5}, {"max_depth": -1}, {"minimum_box_side": NAN}, {"minimum_box_side": 0}, {"unknown_budget": 1}]:
		var result := _prove(solid, false, malformed)
		_check(result.status == "INCONCLUSIVE" and not result.positive and not result.denied, "malformed budgets cannot produce a proof: " + str(malformed))
	for key: String in ["full17_clear", "physical_clear", "relation_clear", "current_frame_matches", "strong_alpha_hits", "source_alpha_threshold"]:
		solid.evidence_override = {"omit": key}
		var result := _prove(solid, true, {"max_boxes": 1})
		_check(result.status == "INCONCLUSIVE" and not result.positive, "missing strict callback evidence rejects positive: " + key)
	for corrupt: Dictionary in [{"set_key": "full17_clear", "value": 1}, {"set_key": "physical_clear", "value": false}, {"set_key": "current_frame_matches", "value": false}, {"set_key": "strong_alpha_hits", "value": 0}, {"set_key": "strong_alpha_hits", "value": 1.0}, {"set_key": "source_alpha_threshold", "value": .01}]:
		solid.evidence_override = corrupt
		var result := _prove(solid, true, {"max_boxes": 1})
		_check(result.status == "INCONCLUSIVE" and not result.positive, "incorrect callback evidence cannot grant a positive: " + str(corrupt))
	solid.evidence_override = {}
	solid.depth = 5.
	for relation: String in ["front", "behind"]:
		var result := _prove(solid, true, {"max_boxes": 1}, relation)
		_check(result.status == "INCONCLUSIVE", "centre at exact depth equality cannot become positive or false full-domain denial: " + relation)
	# closed inner box touching a Rect2 exclusive right/bottom cannot be covered.
	_check(not solid.proof.call("_strictly_contained", Rect2(1, 1, 1, 1), Rect2(0, 0, 2, 2)), "exclusive right/bottom equality remains unproved")
	_check(not solid.proof.call("_strictly_contained", Rect2(0, 0, 1, 1), Rect2(0, 0, 2, 2)), "left/top equality is conservatively unproved too")
	_check(not solid.proof.call("_all_nav_denied", Rect2(9.9, 4, .1, 1)), "closed canvas boundary contact retains its legal interior")
	_check(solid.proof.call("_all_nav_denied", Rect2(10, 4, .1, 1)), "entire box at exclusive canvas boundary is really outside")
	var edge_offsets: PackedVector2Array = solid.shoes.duplicate()
	var empty_rects: Array[Rect2] = []
	var edge_reason: String = solid.proof.call("_rejection", Rect2(4, 5, 2, 0), solid.bundle.runs, "behind", Vector2.DOWN, 0., 5., empty_rects, edge_offsets, empty_rects)
	_check(edge_reason != "outside_behind_halfplane", "closed depth-equality boundary is never eliminated by halfplane")

func _source_immutability_cases() -> void:
	var data := _fixture()
	var nav_before: PackedByteArray = data.nav.get_data().duplicate()
	var prop_before: PackedByteArray = data.prop.get_data().duplicate()
	var actor_before: PackedByteArray = data.actor.get_data().duplicate()
	var result := _prove(data, true)
	_check(result.status == "POSITIVE", "immutability control is a real strict positive")
	_check(data.nav.get_data() == nav_before and data.prop.get_data() == prop_before and data.actor.get_data() == actor_before, "configure/run never mutate caller original images")
	# Context snapshots must not be aliases of mutable caller Images.
	data.nav.fill(Color.BLACK)
	data.prop.fill(Color.TRANSPARENT)
	var raw_context: Dictionary = data.proof.get("_mask")
	var prop_context: Dictionary = data.proof.get("_prop")
	_check(raw_context.image.get_data() == nav_before and prop_context.image.get_data() == prop_before, "configured proof snapshots remain exact after caller image mutation")
	var bad_actor: Dictionary = data.bundle.duplicate(true)
	bad_actor.erase("frame_identity")
	var empty_rects: Array[Rect2] = []
	result = data.proof.prove(bad_actor, "behind", Vector2.DOWN, 0., 6., empty_rects, data.shoes, empty_rects)
	_check(result.status == "INCONCLUSIVE", "missing actual frame identity cannot prove denial")

func _run() -> void:
	_negative_and_positive_cases()
	_narrow_and_linear_cases()
	_closure_and_malformed_cases()
	_source_immutability_cases()
	print("INTERVAL_SYNTHETIC checks=%d failures=%d scope=ONE_DIRECTION_FRAME_ONLY no_Field_no_save_no_approval" % [checks, failures])
	active.clear()
	results.clear()
	quit(0 if failures == 0 else 1)
