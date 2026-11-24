extends RefCounted
## Test-owned continuous-domain classifier. Not a Field/navigation replacement.
## SOURCE ONLY independent root-box subdivision draft, not active production QA.
## Exact D462 reachable-cells baseline retained; defer costly precise alpha bounds
## for large current root boxes, keeping them UNKNOWN and subdividing normally.
## One prove() covers ONE actual actor direction/frame, not all animations.
## A finite search miss is NEVER DENIED. Only completely eliminated closed
## interval boxes are DENIED; precision, resource or work limits are INCONCLUSIVE.

const STRONG_ALPHA := .12
const EDGE_GUARD := .01
const ALPHA_ROUNDING_GUARD := .000001 # uncertainty only makes denial harder
const MAX_IMAGE_PIXELS := 16777216
const MAX_WORLD_SIDE := 8192.

var _mask: Dictionary = {}
var _prop: Dictionary = {}
var _alpha_queries := 0
var _max_alpha_queries := 0
var _proof_geometry: Dictionary = {}
var _current_box: Dictionary = {}
var _last_live: Dictionary = {}

func configure_mask(original: Image, world_size: Vector2) -> bool:
	_mask = {}
	if not _valid_image(original) or not world_size.is_finite() or world_size.x <= 0 or world_size.y <= 0 or world_size.x > MAX_WORLD_SIDE or world_size.y > MAX_WORLD_SIDE: return false
	var snapshot := original.duplicate() as Image
	var prefix := _prefix(snapshot, false, 1.)
	if prefix.is_empty(): return false
	_mask = {"image": snapshot, "prefix": prefix, "world_size": world_size, "rgba_sha256": _image_sha(snapshot)}
	return true

func configure_prop(original: Image, frame: Rect2i, render_rect: Rect2, prop_to_world: Transform2D, linear: bool, flip_h: bool, flip_v: bool, modulation_alpha: float) -> bool:
	_prop = {}
	if not _valid_image(original) or not Rect2i(Vector2i.ZERO, original.get_size()).encloses(frame) or frame.size.x <= 0 or frame.size.y <= 0: return false
	if not _finite_rect(render_rect) or render_rect.size.x <= 0 or render_rect.size.y <= 0 or not _finite_transform(prop_to_world) or absf(prop_to_world.determinant()) < .00000001: return false
	if not is_finite(modulation_alpha) or modulation_alpha < 0 or modulation_alpha > 1: return false
	var snapshot := original.duplicate() as Image
	var prefix := _prefix(snapshot, true, modulation_alpha)
	if prefix.is_empty(): return false
	_prop = {"image": snapshot, "prefix": prefix, "frame": frame, "rect": render_rect, "to_world": prop_to_world, "to_local": prop_to_world.affine_inverse(), "linear": linear, "flip_h": flip_h, "flip_v": flip_v, "modulation_alpha": modulation_alpha, "rgba_sha256": _image_sha(snapshot)}
	return true

func actor_row_runs(original: Image, frame: Rect2i, render_rect: Rect2, sprite_to_world: Transform2D, root_world_position: Vector2, flip_h: bool, flip_v: bool, frame_identity: String) -> Dictionary:
	# Exact original strong actor pixel CENTRES become conservative row-run
	# bounding boxes relative to its root. Rotation/shear only widens these
	# bounds, never discards a contributing pixel. No actor alpha threshold drop.
	if not _valid_image(original) or not Rect2i(Vector2i.ZERO, original.get_size()).encloses(frame) or frame.size.x <= 0 or frame.size.y <= 0: return {}
	if not _finite_rect(render_rect) or render_rect.size.x <= 0 or render_rect.size.y <= 0 or not _finite_transform(sprite_to_world) or not root_world_position.is_finite() or frame_identity.is_empty(): return {}
	var runs: Array[Rect2] = []
	var pixel_count := 0
	for y in frame.size.y:
		var start := -1
		for x in range(frame.size.x + 1):
			var strong := false
			if x < frame.size.x: strong = original.get_pixel(frame.position.x + x, frame.position.y + y).a > STRONG_ALPHA
			if strong:
				pixel_count += 1
				if start < 0: start = x
			elif start >= 0:
				var a := _actor_pixel(start, y, frame.size, render_rect, sprite_to_world, root_world_position, flip_h, flip_v)
				var b := _actor_pixel(x - 1, y, frame.size, render_rect, sprite_to_world, root_world_position, flip_h, flip_v)
				runs.append(Rect2(a.min(b), a.max(b) - a.min(b)))
				start = -1
	if runs.is_empty(): return {}
	return {"runs": runs, "strong_pixel_count": pixel_count, "frame": frame, "frame_identity": frame_identity, "actor_rgba_sha256": _image_sha(original), "rect": render_rect, "sprite_to_world": sprite_to_world, "root_world_position": root_world_position, "flip_h": flip_h, "flip_v": flip_v, "threshold": STRONG_ALPHA}

func prove(actor: Dictionary, relation: String, depth_axis: Vector2, depth_offset: float, prop_depth: float, grown_blockers: Array[Rect2], foot_offsets: PackedVector2Array, physics_forbidden_root_rects: Array[Rect2], live_validator: Callable = Callable(), limits: Dictionary = {}) -> Dictionary:
	# depth = depth_axis.dot(root_world_local) + depth_offset must come from
	# actual current get_depth_sort_y(), not normalized authoring coordinates.
	# Blockers are exact world-local already-grown source rectangles. Optional
	# physical forbidden-root rectangles must be reconstructed from ACTUAL
	# immutable static collider transforms/Minkowski sums (not moving NPCs);
	# omit if that derivation is not exact.
	if not _valid_limits(limits): return _inconclusive("malformed_fail_closed_budget")
	var max_boxes := int(limits.get("max_boxes", 50000))
	_max_alpha_queries = int(limits.get("max_alpha_queries", 2000000))
	var max_live := int(limits.get("max_live_probes", 256))
	var max_depth := int(limits.get("max_depth", 24))
	var precision := float(limits.get("minimum_box_side", .03125))
	_alpha_queries = 0
	_proof_geometry = {}
	_current_box = {}
	_last_live = {}
	if _mask.is_empty() or _prop.is_empty() or not _valid_actor_data(actor): return _inconclusive("invalid_source_context")
	if relation not in ["front", "behind"] or not depth_axis.is_finite() or depth_axis.length_squared() < .00000001 or not is_finite(depth_offset) or not is_finite(prop_depth): return _inconclusive("invalid_actual_depth_affine")
	if foot_offsets.size() != 17 or foot_offsets[0] != Vector2.ZERO or actor.get("threshold") != STRONG_ALPHA or int(actor.get("strong_pixel_count", 0)) <= 0: return _inconclusive("invalid_original_alpha_or_full17")
	if max_boxes <= 0 or _max_alpha_queries <= 0 or max_live <= 0 or max_depth <= 0 or not is_finite(precision) or precision <= 0: return _inconclusive("invalid_fail_closed_budget")
	for offset in foot_offsets:
		if not offset.is_finite(): return _inconclusive("invalid_shoe_offset")
	for obstacle in grown_blockers:
		if not _finite_rect(obstacle) or obstacle.size.x <= 0 or obstacle.size.y <= 0: return _inconclusive("invalid_grown_blocker")
	for forbidden in physics_forbidden_root_rects:
		if not _finite_rect(forbidden) or forbidden.size.x <= 0 or forbidden.size.y <= 0: return _inconclusive("invalid_physics_forbidden_root_rect")
	var relative := Rect2()
	var first := true
	for item: Variant in actor.runs:
		if not item is Rect2 or not _finite_rect(item) or item.size.x < 0 or item.size.y < 0: return _inconclusive("invalid_actor_run")
		relative = item if first else relative.merge(item)
		first = false
	if first: return _inconclusive("empty_actor_support")
	var prop_bounds := _transformed_rect(_prop.rect, _prop.to_world)
	var domain := Rect2(prop_bounds.position - relative.end, prop_bounds.size + relative.size).grow(EDGE_GUARD)
	if not _finite_rect(domain) or domain.size.x <= 0 or domain.size.y <= 0: return _inconclusive("invalid_complete_overlap_domain")
	var obstacle_snapshot: Array[Rect2] = []
	for obstacle in grown_blockers: obstacle_snapshot.append(obstacle)
	var physical_snapshot: Array[Rect2] = []
	for forbidden in physics_forbidden_root_rects: physical_snapshot.append(forbidden)
	var shoe_snapshot := foot_offsets.duplicate()
	# The live callback must not be able to mutate the frame/report metadata
	# belonging to the geometry this invocation is actually proving.
	actor = actor.duplicate(true)
	_proof_geometry = {"relation": relation, "actual_depth_axis": depth_axis, "actual_depth_offset": depth_offset, "actual_prop_depth": prop_depth, "world_size": _mask.world_size, "mandatory17_offsets": shoe_snapshot, "grown_source_blockers": obstacle_snapshot, "static_actual_physics_forbidden_roots": physical_snapshot, "numerical_world_guard_px": EDGE_GUARD, "source_integral_texel_apron": 1, "maximum_box_count": max_boxes, "maximum_alpha_queries": _max_alpha_queries, "maximum_live_probes": max_live, "maximum_subdivision_depth": max_depth, "minimum_box_side": precision}
	var pending: Array[Dictionary] = []
	pending.append({"box": domain, "depth": 0})
	var eliminated: Dictionary = {}
	var eliminated_area := 0.
	var processed := 0
	var live_probes := 0
	while not pending.is_empty():
		if processed >= max_boxes: return _report("INCONCLUSIVE", "box_work_budget", actor, domain, processed, pending.size(), eliminated, eliminated_area, live_probes)
		var entry: Dictionary = pending.pop_back()
		var box: Rect2 = entry.box
		_current_box = {"box": box, "depth": int(entry.depth)}
		processed += 1
		var reason := _rejection(box, actor.runs, relation, depth_axis, depth_offset, prop_depth, obstacle_snapshot, shoe_snapshot, physical_snapshot)
		if reason == "alpha_query_budget": return _report("INCONCLUSIVE", reason, actor, domain, processed, pending.size() + 1, eliminated, eliminated_area, live_probes)
		if not reason.is_empty():
			eliminated[reason] = int(eliminated.get(reason, 0)) + 1
			eliminated_area += box.get_area()
			continue
		var point := box.get_center()
		if live_validator.is_valid() and _raw_point_clear(point, obstacle_snapshot, shoe_snapshot, physical_snapshot) and _point_relation(point, relation, depth_axis, depth_offset, prop_depth):
			if live_probes >= max_live: return _report("INCONCLUSIVE", "live_probe_work_budget", actor, domain, processed, pending.size() + 1, eliminated, eliminated_area, live_probes)
			live_probes += 1
			var evidence: Variant = live_validator.call(point, actor.frame_identity, relation)
			_last_live = _live_diagnostic(evidence, point, String(actor.frame_identity), relation)
			if _valid_live_positive(evidence):
				var result := _report("POSITIVE", "strict_live_current_frame", actor, domain, processed, pending.size() + 1, eliminated, eliminated_area, live_probes)
				result["point"] = point
				result["live_evidence"] = evidence
				return result
		if int(entry.depth) >= max_depth or maxf(box.size.x, box.size.y) <= precision: return _report("INCONCLUSIVE", "unresolved_precision_or_depth", actor, domain, processed, pending.size() + 1, eliminated, eliminated_area, live_probes)
		var split_x := box.size.x >= box.size.y
		var half := box.size.x * .5 if split_x else box.size.y * .5
		var a := box
		var b := box
		if split_x:
			a.size.x = half
			b.position.x = box.position.x + half
			b.size.x = box.end.x - b.position.x
		else:
			a.size.y = half
			b.position.y = box.position.y + half
			b.size.y = box.end.y - b.position.y
		if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0: return _report("INCONCLUSIVE", "floating_split_stagnation", actor, domain, processed, pending.size() + 1, eliminated, eliminated_area, live_probes)
		pending.append({"box": b, "depth": int(entry.depth) + 1})
		pending.append({"box": a, "depth": int(entry.depth) + 1})
	return _report("DENIED", "all_closed_boxes_proven", actor, domain, processed, 0, eliminated, eliminated_area, live_probes)

func _rejection(box: Rect2, runs: Array, relation: String, axis: Vector2, offset: float, prop_depth: float, obstacles: Array[Rect2], shoes: PackedVector2Array, physical: Array[Rect2]) -> String:
	var values := Vector2(INF, -INF)
	for corner in _corners(box):
		var value := axis.dot(corner) + offset
		values.x = minf(values.x, value)
		values.y = maxf(values.y, value)
	if relation == "behind" and values.x > prop_depth + EDGE_GUARD: return "outside_behind_halfplane"
	if relation == "front" and values.y < prop_depth - EDGE_GUARD: return "outside_front_halfplane"
	for shoe in shoes:
		var sample_box := Rect2(box.position + shoe, box.size)
		for obstacle in obstacles:
			if _strictly_contained(sample_box, obstacle): return "mandatory_shoe_grown_blocker"
		if _all_nav_denied(sample_box): return "mandatory_shoe_original_raw_mask_or_boundary"
	for forbidden in physical:
		if _strictly_contained(box, forbidden): return "actual_physical_forbidden_root"
	for run: Rect2 in runs:
		_alpha_queries += 1
		if _alpha_queries > _max_alpha_queries: return "alpha_query_budget"
		var possible_pixel_region := Rect2(box.position + run.position, box.size + run.size)
		var zero_upper := _prop_alpha_upper_zero(possible_pixel_region)
		if _alpha_queries > _max_alpha_queries: return "alpha_query_budget"
		if not zero_upper: return ""
	return "all_original_actor_runs_prop_alpha_upper_at_most_threshold"

func _prop_alpha_upper_zero(region: Rect2) -> bool:
	# Grow in world space before inverse mapping to cover Float32 composition
	# uncertainty. The integral query adds a texel apron as well. Both changes
	# can only widen possible alpha, making DENIED harder, never easier.
	var local := _transformed_rect(region.grow(EDGE_GUARD), _prop.to_local)
	var render: Rect2 = _prop.rect
	# Inclusive closed box intersection: zero-width boundary contacts are not
	# thrown away. Runtime right/bottom UV exclusion only makes this broader.
	var lo := local.position.max(render.position)
	var hi := local.end.min(render.end)
	if hi.x < lo.x or hi.y < lo.y: return true
	var uv_lo := (lo - render.position) / render.size
	var uv_hi := (hi - render.position) / render.size
	if _prop.flip_h:
		var previous := uv_lo.x
		uv_lo.x = 1. - uv_hi.x
		uv_hi.x = 1. - previous
	if _prop.flip_v:
		var previous := uv_lo.y
		uv_lo.y = 1. - uv_hi.y
		uv_hi.y = 1. - previous
	var frame: Rect2i = _prop.frame
	var low := Vector2(frame.position) + uv_lo * Vector2(frame.size)
	var high := Vector2(frame.position) + uv_hi * Vector2(frame.size)
	var lower: Vector2i
	var upper: Vector2i
	if _prop.linear:
		lower = Vector2i(floori(low.x - .5), floori(low.y - .5))
		upper = Vector2i(floori(high.x - .5) + 1, floori(high.y - .5) + 1)
	else:
		lower = Vector2i(floori(low.x), floori(low.y)).max(frame.position)
		upper = Vector2i(floori(high.x), floori(high.y)).min(frame.end - Vector2i.ONE)
	var image: Image = _prop.image
	lower = (lower - Vector2i.ONE).clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)
	upper = (upper + Vector2i.ONE).clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)
	# Fast zero bound still queries a conservative texel apron. Equality near
	# .12 remains a candidate, never a fast DENIED decision.
	if _sum(_prop.prefix, image.get_width(), lower, upper) == 0: return true
	if not _prop.linear: return false
	# A cheap <=4px source interval retains the original precise work/budget
	# behaviour. For a costly long source envelope, the feasible actor-root
	# interval sets when precise work is useful. A large root remains UNKNOWN:
	# the caller keeps it live/subdivides it; this is never a denial reason.
	# An empty context is a direct auxiliary bound query and retains the full
	# reachable-cell behaviour. All actual corner queries keep the old budget.
	if not _current_box.is_empty():
		var root_box: Rect2 = _current_box.box
		if maxf(root_box.size.x, root_box.size.y) > 1. and maxf(high.x - low.x, high.y - low.y) > 4.: return false
	# On the complete feasible UV rectangle, each bilinear cell's extrema occur at
	# its four CLIPPED corners. The apron selects candidate texels only: it does
	# not enlarge the feasible interpolation weights into a whole source cell.
	# Rotated actor runs/local AABBs remain overestimates, so this is an upper
	# bound, not a claim that all corner positions can actually be reached.
	return _reachable_bilinear_below_threshold(low - Vector2(.5, .5), high - Vector2(.5, .5))

func _reachable_bilinear_below_threshold(low: Vector2, high: Vector2) -> bool:
	var image: Image = _prop.image
	var cell_lo := Vector2i(floori(low.x), floori(low.y))
	var cell_hi := Vector2i(floori(high.x), floori(high.y))
	var maximum := 0.
	for y in range(cell_lo.y, cell_hi.y + 1):
		for x in range(cell_lo.x, cell_hi.x + 1):
			var clipped_lo := low.max(Vector2(x, y))
			var clipped_hi := high.min(Vector2(x + 1, y + 1))
			if clipped_hi.x < clipped_lo.x or clipped_hi.y < clipped_lo.y: continue
			var a := image.get_pixel(clampi(x, 0, image.get_width() - 1), clampi(y, 0, image.get_height() - 1)).a
			var b := image.get_pixel(clampi(x + 1, 0, image.get_width() - 1), clampi(y, 0, image.get_height() - 1)).a
			var c := image.get_pixel(clampi(x, 0, image.get_width() - 1), clampi(y + 1, 0, image.get_height() - 1)).a
			var d := image.get_pixel(clampi(x + 1, 0, image.get_width() - 1), clampi(y + 1, 0, image.get_height() - 1)).a
			for corner in _corners(Rect2(clipped_lo, clipped_hi - clipped_lo)):
				_alpha_queries += 1
				if _alpha_queries > _max_alpha_queries: return false
				var t := corner - Vector2(x, y)
				var alpha := lerpf(lerpf(a, b, t.x), lerpf(c, d, t.x), t.y) * float(_prop.modulation_alpha)
				maximum = maxf(maximum, alpha)
				if maximum + ALPHA_ROUNDING_GUARD >= STRONG_ALPHA: return false
	return maximum + ALPHA_ROUNDING_GUARD < STRONG_ALPHA

func _all_nav_denied(sample: Rect2) -> bool:
	var size: Vector2 = _mask.world_size
	if sample.end.x < 0 or sample.end.y < 0 or sample.position.x >= size.x or sample.position.y >= size.y: return true
	var lo := sample.position.max(Vector2.ZERO)
	var hi := sample.end.min(size)
	var image: Image = _mask.image
	# roundi over positive coordinates is monotone. Include all extrema and
	# a closed right/bottom endpoint; a spurious white boundary can only keep
	# a box unresolved, never falsely deny a fractional legal stand.
	var scale := Vector2(image.get_size() - Vector2i.ONE) / size
	var lower := (Vector2i(roundi(lo.x * scale.x), roundi(lo.y * scale.y)) - Vector2i.ONE).clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)
	var upper := (Vector2i(roundi(hi.x * scale.x), roundi(hi.y * scale.y)) + Vector2i.ONE).clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)
	return _sum(_mask.prefix, image.get_width(), lower, upper) == 0

func _raw_point_clear(point: Vector2, obstacles: Array[Rect2], shoes: PackedVector2Array, physical: Array[Rect2]) -> bool:
	var size: Vector2 = _mask.world_size
	var image: Image = _mask.image
	for offset in shoes:
		var sample := point + offset
		if sample.x < 0 or sample.y < 0 or sample.x >= size.x or sample.y >= size.y: return false
		for obstacle in obstacles:
			if obstacle.has_point(sample): return false
		var pixel := Vector2i(roundi(sample.x / size.x * (image.get_width() - 1)), roundi(sample.y / size.y * (image.get_height() - 1)))
		if _sum(_mask.prefix, image.get_width(), pixel, pixel) == 0: return false
	for forbidden in physical:
		if forbidden.has_point(point): return false
	return true

func _valid_live_positive(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["full17_clear", "physical_clear", "relation_clear", "current_frame_matches"]:
		if typeof(value.get(key)) != TYPE_BOOL or value.get(key) != true: return false
	return typeof(value.get("strong_alpha_hits")) == TYPE_INT and value.strong_alpha_hits > 0 and value.get("source_alpha_threshold") == STRONG_ALPHA

func _prefix(image: Image, alpha_only: bool, modulation: float) -> PackedInt32Array:
	var width := image.get_width()
	var height := image.get_height()
	var result := PackedInt32Array()
	if result.resize((width + 1) * (height + 1)) != OK: return PackedInt32Array()
	result.fill(0)
	for y in height:
		var row := 0
		for x in width:
			var color := image.get_pixel(x, y)
			var counted := color.a * modulation + ALPHA_ROUNDING_GUARD >= STRONG_ALPHA if alpha_only else color.a >= .5 and maxf(color.r, maxf(color.g, color.b)) >= .5
			if counted: row += 1
			result[(y + 1) * (width + 1) + x + 1] = result[y * (width + 1) + x + 1] + row
	return result

func _sum(prefix: PackedInt32Array, width: int, lo: Vector2i, hi: Vector2i) -> int:
	if hi.x < lo.x or hi.y < lo.y: return 0
	var stride := width + 1
	return prefix[(hi.y + 1) * stride + hi.x + 1] - prefix[lo.y * stride + hi.x + 1] - prefix[(hi.y + 1) * stride + lo.x] + prefix[lo.y * stride + lo.x]

func _strictly_contained(inner: Rect2, outer: Rect2) -> bool:
	# has_point has exclusive right/bottom. Also leave numerical uncertainty on
	# left/top as unresolved; never treat equality as a proof of full coverage.
	return inner.position.x > outer.position.x + EDGE_GUARD and inner.position.y > outer.position.y + EDGE_GUARD and inner.end.x < outer.end.x - EDGE_GUARD and inner.end.y < outer.end.y - EDGE_GUARD

func _point_relation(point: Vector2, relation: String, axis: Vector2, offset: float, prop_depth: float) -> bool:
	var value := axis.dot(point) + offset
	return value < prop_depth if relation == "behind" else value > prop_depth

func _actor_pixel(x: int, y: int, size: Vector2i, rect: Rect2, transform: Transform2D, root_position: Vector2, flip_h: bool, flip_v: bool) -> Vector2:
	var uv := Vector2((float(x) + .5) / size.x, (float(y) + .5) / size.y)
	if flip_h: uv.x = 1. - uv.x
	if flip_v: uv.y = 1. - uv.y
	return transform * (rect.position + uv * rect.size) - root_position

func _corners(rect: Rect2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	result.append(rect.position)
	result.append(Vector2(rect.end.x, rect.position.y))
	result.append(rect.end)
	result.append(Vector2(rect.position.x, rect.end.y))
	return result

func _transformed_rect(rect: Rect2, transform: Transform2D) -> Rect2:
	var first := true
	var result := Rect2()
	for point in _corners(rect):
		var mapped := transform * point
		if first:
			result = Rect2(mapped, Vector2.ZERO)
			first = false
		else: result = result.expand(mapped)
	return result

func _valid_image(image: Image) -> bool:
	return image != null and not image.is_empty() and not image.is_compressed() and image.get_width() > 1 and image.get_height() > 1 and image.get_width() * image.get_height() <= MAX_IMAGE_PIXELS

func _valid_actor_data(actor: Dictionary) -> bool:
	if actor.is_empty() or not actor.get("runs") is Array: return false
	if typeof(actor.get("frame_identity")) != TYPE_STRING or String(actor.frame_identity).is_empty(): return false
	if typeof(actor.get("frame")) != TYPE_RECT2I or typeof(actor.get("rect")) != TYPE_RECT2 or typeof(actor.get("sprite_to_world")) != TYPE_TRANSFORM2D or typeof(actor.get("root_world_position")) != TYPE_VECTOR2: return false
	if typeof(actor.get("actor_rgba_sha256")) != TYPE_STRING or String(actor.actor_rgba_sha256).length() != 64: return false
	if typeof(actor.get("strong_pixel_count")) != TYPE_INT or int(actor.strong_pixel_count) <= 0 or actor.get("threshold") != STRONG_ALPHA: return false
	return _finite_rect(actor.rect) and _finite_transform(actor.sprite_to_world) and actor.root_world_position.is_finite()

func _valid_limits(limits: Dictionary) -> bool:
	for key: Variant in limits:
		if key not in ["max_boxes", "max_alpha_queries", "max_live_probes", "max_depth", "minimum_box_side"]: return false
		var value: Variant = limits[key]
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
		if not is_finite(float(value)) or float(value) <= 0: return false
		if key != "minimum_box_side" and (float(value) != floorf(float(value)) or float(value) > 2147483647.): return false
	return true

func _finite_rect(rect: Rect2) -> bool:
	return rect.position.is_finite() and rect.size.is_finite() and rect.end.is_finite()

func _finite_transform(transform: Transform2D) -> bool:
	return transform.x.is_finite() and transform.y.is_finite() and transform.origin.is_finite()

func _image_sha(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()

func _inconclusive(reason: String) -> Dictionary:
	return {"status": "INCONCLUSIVE", "reason": reason, "denied": false, "positive": false, "threshold": STRONG_ALPHA, "live_positive_verified": false}

func _report(status: String, reason: String, actor: Dictionary, domain: Rect2, boxes: int, pending: int, eliminated: Dictionary, area: float, live_probes: int) -> Dictionary:
	return {"status": status, "reason": reason, "denied": status == "DENIED", "positive": status == "POSITIVE", "threshold": STRONG_ALPHA, "frame_identity": actor.frame_identity, "actor_frame": actor.frame, "actor_rgba_sha256": actor.actor_rgba_sha256, "prop_rgba_sha256": _prop.rgba_sha256, "raw_mask_rgba_sha256": _mask.rgba_sha256, "prop_frame": _prop.frame, "prop_to_world": _prop.to_world, "actor_sprite_to_world": actor.sprite_to_world, "domain": domain, "proof_geometry": _proof_geometry, "closed_interval_box_count": boxes, "unresolved_box_count": pending, "eliminated_counts": eliminated, "eliminated_area": area, "domain_area": domain.get_area(), "alpha_interval_queries": _alpha_queries, "strict_live_probe_count": live_probes, "last_processed_box": _current_box.duplicate(true), "terminal_box": _current_box.duplicate(true) if reason in ["unresolved_precision_or_depth", "floating_split_stagnation", "alpha_query_budget", "live_probe_work_budget"] else {}, "last_live_probe": _last_live.duplicate(true), "coverage_scope": "one actual direction/frame, original actor pixel centres>.12, original prop bilinear/nearest support, original raw full17; not all animation frames", "live_positive_verified": status == "POSITIVE"}

func _live_diagnostic(value: Variant, point: Vector2, frame_identity: String, relation: String) -> Dictionary:
	# Never retain callback-owned Nodes, Resources, Callables or arbitrary nested
	# dictionaries in diagnostics. Missing/wrong evidence remains explicitly absent.
	var result: Dictionary = {"point": point, "frame_identity": frame_identity, "relation": relation, "returned_dictionary": value is Dictionary, "valid_positive": _valid_live_positive(value)}
	if not value is Dictionary: return result
	for key in ["full17_clear", "physical_clear", "relation_clear", "current_frame_matches", "strong_alpha_hits", "source_alpha_threshold"]:
		var item: Variant = value.get(key)
		if typeof(item) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]: result[key] = item
	return result

