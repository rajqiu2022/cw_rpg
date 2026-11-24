extends "res://tests/diagnose_world_v14_alpha_terminal_bounds_20261002.gd"

## Capture the ORIGINAL prove entry before its live callback changes the actor.
## Diagnostic only; no DENIED classification, limits or production edits.
class FrozenEntryProof:
	extends "res://tests/helpers/v14_alpha_domain_interval_proof.gd"
	var captured: Array[Dictionary] = []

	func prove(actor: Dictionary, relation: String, depth_axis: Vector2, depth_offset: float, prop_depth: float, grown_blockers: Array[Rect2], foot_offsets: PackedVector2Array, physics_forbidden_root_rects: Array[Rect2], live_validator: Callable = Callable(), limits: Dictionary = {}) -> Dictionary:
		var entry := {"actor": actor.duplicate(true), "prop_transform": _prop.to_world, "prop_frame": _prop.frame, "prop_rect": _prop.rect, "prop_rgba_sha256": _prop.rgba_sha256, "prop_linear": _prop.linear, "limits": limits.duplicate(true)}
		var result := super.prove(actor, relation, depth_axis, depth_offset, prop_depth, grown_blockers, foot_offsets, physics_forbidden_root_rects, live_validator, limits)
		entry["result"] = result.duplicate(true)
		captured.append(entry)
		return result

var normal_stage_pair: Dictionary = {}

func _complete_alpha_station(d: Dictionary, prop: Sprite2D, front: bool) -> Dictionary:
	if not alpha_interval_prover is FrozenEntryProof:
		_check(FileAccess.get_sha256(ALPHA_INTERVAL_PATH) == TERMINAL_HELPER_SHA, "capturing subclass inherits exact frozen original helper")
		alpha_interval_prover = FrozenEntryProof.new()
		_check(alpha_interval_prover.call("configure_mask", native_images.get("walk"), WORLD_SIZE), "capturing helper original full raw mask configures")
	(alpha_interval_prover as FrozenEntryProof).captured.clear()
	return super._complete_alpha_station(d, prop, front)

func _same_point_state() -> Dictionary:
	var player: Node2D = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	var inverse := (field.get("world_container") as Node2D).global_transform.affine_inverse()
	return {"root_position": player.position, "full17": _foot_clear(player.position), "raw_reason": _raw_foot_reason(world, player.position / WORLD_SIZE), "texture_path": actor.texture.resource_path, "frame": actor.frame, "sprite_position": actor.position, "sprite_scale": actor.scale, "actor_transform": inverse * actor.global_transform}

func _completed_normal_actor_stage() -> void:
	var before := _same_point_state()
	await super._completed_normal_actor_stage()
	var after := _same_point_state()
	normal_stage_pair = {"before": before, "after": after, "same_root": before.root_position == after.root_position, "same_frame": before.frame == after.frame and before.texture_path == after.texture_path, "same_actor_transform": before.actor_transform == after.actor_transform}

func _terminal_original_pixel_bounds(prop: Sprite2D, box: Rect2) -> Dictionary:
	var result := super._terminal_original_pixel_bounds(prop, box)
	result["normal_stage_same_point"] = normal_stage_pair.duplicate(true)
	var player: Node2D = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	var current_source := _read_image(actor.texture.resource_path)
	var current_frame := _sprite_frame(actor, current_source)
	# Match the capture by its actual frame/source. Facing is recorded in the
	# original frame identity; no guessed private Player direction is required.
	var capture: Dictionary = {}
	for entry: Dictionary in (alpha_interval_prover as FrozenEntryProof).captured:
		if String(entry.actor.get("frame_identity", "")).begins_with(actor.texture.resource_path + ":") and entry.actor.get("frame") == current_frame and entry.result.get("status") == "INCONCLUSIVE":
			capture = entry
	_check(not capture.is_empty(), "actual failed original frame has a prove-entry capture")
	if capture.is_empty(): return result
	var container: Node2D = field.get("world_container")
	var inverse := container.global_transform.affine_inverse()
	var image := _read_image(prop.texture.resource_path)
	_check(capture.prop_transform == inverse * prop.global_transform and capture.prop_frame == _sprite_frame(prop, image) and capture.prop_rect == prop.get_rect(), "original and diagnostic prop transform/frame/rect unchanged")
	var original_actor: Dictionary = capture.actor
	var identity := String(original_actor.get("frame_identity", ""))
	var origin: Vector2 = original_actor.root_world_position
	var original_transform: Transform2D = original_actor.sprite_to_world
	var current_relative := inverse * actor.global_transform
	current_relative.origin -= player.position
	var frozen_relative := original_transform
	frozen_relative.origin -= origin
	var isolated := FrozenEntryProof.new()
	_check(isolated.configure_prop(image, _sprite_frame(prop, image), prop.get_rect(), inverse * prop.global_transform, prop.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, prop.flip_h, prop.flip_v, prop.modulate.a * prop.self_modulate.a), "independent instance uses original helper alpha context")
	isolated.set("_max_alpha_queries", 2000000)
	var conservative_rows: Array[Dictionary] = []
	var row_index := 0
	var maximum_original_upper := 0.
	for run: Rect2 in original_actor.runs:
		var region := Rect2(box.position + run.position, box.size + run.size)
		var bound := _original_linear_upper(region, prop, image, inverse)
		var original_zero: bool = isolated.call("_prop_alpha_upper_zero", region)
		maximum_original_upper = maxf(maximum_original_upper, float(bound.upper))
		if not original_zero:
			conservative_rows.append({"run_index": row_index, "frozen_run": run, "region": region, "helper_below_threshold": original_zero, "independent_original_rgba_bound": bound})
		row_index += 1
	result["exact_original_prove_input"] = {"frame_identity": identity, "frame": original_actor.frame, "actor_rgba_sha256": original_actor.actor_rgba_sha256, "actor_transform": original_transform, "root_position": origin, "original_relative_transform": frozen_relative, "current_relative_transform": current_relative, "relative_transform_exact": frozen_relative == current_relative, "actor_rect_exact": original_actor.rect == actor.get_rect(), "prop_rgba_sha256": capture.prop_rgba_sha256, "limits": capture.limits, "original_row_count": row_index, "maximum_independent_frozen_row_upper": maximum_original_upper, "helper_conservative_nonzero_rows": conservative_rows, "isolated_diagnostic_alpha_queries": isolated.get("_alpha_queries"), "classification": "DIAGNOSTIC_ONLY_NO_DENIED"}
	isolated = null
	return result
