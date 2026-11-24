extends RefCounted
## Pure fixed-author arithmetic only. Never reads a live Sprite/Field/packet.
## NOT parsed/executed here. Root must separately approve any consumer key.
static func expected_sprite(author_row: Dictionary) -> Dictionary:
	if author_row.get("uniform_scale") != .12: return {}
	var raw_size: Array = author_row.full_source_size_px
	var raw_anchor: Array = author_row.source_ground_anchor_px
	var raw_foot: Array = author_row.foot_px
	var size := Vector2(raw_size[0], raw_size[1])
	var anchor := Vector2(raw_anchor[0], raw_anchor[1])
	var foot := Vector2(raw_foot[0], raw_foot[1])
	if size != Vector2(1536,1024): return {}
	# Use native Vector2 operators, not a Python double-multiply surrogate.
	# The scalar conversion and each Vector2 storage step are therefore owned
	# by the exact running Godot language, independent of the actual prop node.
	var source_scalar: float = float(author_row.uniform_scale)
	var render_size: Vector2 = size * source_scalar
	var foot_uv: Vector2 = anchor / size
	var center: Vector2 = foot + (Vector2(.5,.5) - foot_uv) * render_size
	var normalized: Vector2 = center / Vector2(3072,2048)
	var native_scale := Vector2(render_size.x / float(size.x), render_size.y / float(size.y))
	var field_position := Vector2(normalized.x * 3072.0, normalized.y * 2048.0)
	return {"id":author_row.id,"texture_path":author_row.texture,"texture_size":size,"render_size":render_size,"source_foot_uv":foot_uv,"source_position_uv":normalized,"native_scale":native_scale,"field_position":field_position,"uniform_author_scalar":source_scalar,"expected_from":"FROZEN_AUTHOR_SOURCE_EXPRESSION_NOT_ACTUAL_NODE"}
