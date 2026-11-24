extends "res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd"
## OPTIONAL CANDIDATE, not an adopted autoload. Adds explicit atlas cell order.
## All native sprite/animation/material/ghost ownership remains in the parent.
const BaseAdapter = preload("res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd")


func _install_mapping(source_path: String, declaration: Dictionary) -> void:
	if not declaration.has("frame_cells"):
		super._install_mapping(source_path, declaration)
		return
	var atlas_path := String(declaration.get("atlas", ""))
	if not ResourceLoader.exists(source_path) or not ResourceLoader.exists(atlas_path):
		return
	# Same path and exact-byte gates as the adopted parent's single-row mode.
	if not source_path.begins_with("res://art/characters/") or not atlas_path.begins_with("res://art/characters/pc_hd_20261102c/") or ".." in source_path or ".." in atlas_path:
		_map_errors.append("MAPPING_PATH_SCOPE:" + source_path)
		return
	for pair: Array in [[source_path, "source_sha256"], [atlas_path, "atlas_sha256"]]:
		var expected := String(declaration.get(pair[1], ""))
		if expected.length() != 64 or FileAccess.get_sha256(pair[0]) != expected:
			_map_errors.append("MAPPING_SHA:" + source_path)
			return
	var source := load(source_path) as Texture2D
	var atlas := load(atlas_path) as Texture2D
	var mapping := prepare_declared_cell_mapping(source, atlas, declaration)
	if mapping.is_empty():
		_map_errors.append("MAPPING_DECLARED_CELLS_GEOMETRY:" + source_path)
		return
	_mappings[source_path] = mapping


static func prepare_declared_cell_mapping(source: Texture2D, atlas: Texture2D, declaration: Dictionary) -> Dictionary:
	if not declaration.has("frame_cells"):
		return BaseAdapter.prepare_mapping(source, atlas, declaration)
	if source == null or atlas == null:
		return {}
	var cols := int(declaration.get("cols", 0))
	var rows := int(declaration.get("rows", 0))
	var count := int(declaration.get("framecount", 0))
	var source_hframes := int(declaration.get("source_hframes", 0))
	var source_vframes := int(declaration.get("source_vframes", 0))
	var source_cell_raw: Variant = declaration.get("source_cell")
	var atlas_size_raw: Variant = declaration.get("atlas_size")
	var cells_raw: Variant = declaration.get("frame_cells")
	var source_height := float(declaration.get("source_body_height", 0))
	var height := float(declaration.get("body_height", 0))
	var minimum := float(declaration.get("minimum_native_body_height", 320))
	if cols <= 0 or rows <= 0 or count <= 0 or count > cols * rows or source_hframes <= 0 or source_vframes <= 0 or count != source_hframes * source_vframes:
		return {}
	if not BaseAdapter._numeric_pair(source_cell_raw) or not BaseAdapter._numeric_pair(atlas_size_raw) or not cells_raw is Array or cells_raw.size() != count:
		return {}
	var source_cell := Vector2(float(source_cell_raw[0]), float(source_cell_raw[1]))
	var atlas_size := Vector2(float(atlas_size_raw[0]), float(atlas_size_raw[1]))
	if source_cell.x <= 0 or source_cell.y <= 0 or source.get_size() != source_cell * Vector2(source_hframes, source_vframes) or atlas.get_size() != atlas_size or atlas.get_width() % cols != 0 or atlas.get_height() % rows != 0:
		return {}
	if not is_finite(source_height) or not is_finite(height) or not is_finite(minimum) or source_height <= 0 or height < maxf(320, minimum):
		return {}
	var source_anchors: Variant = declaration.get("source_anchors")
	var body_anchors: Variant = declaration.get("body_anchors")
	if not source_anchors is Array or not body_anchors is Array or source_anchors.size() != count or body_anchors.size() != count:
		return {}
	var cell := atlas_size / Vector2(cols, rows)
	if source_height > source_cell.y or height > cell.y:
		return {}
	var frames: Array[AtlasTexture] = []
	var source_points: Array[Vector2] = []
	var body_points: Array[Vector2] = []
	var used_cells: Dictionary = {}
	for frame: int in range(count):
		if not BaseAdapter._numeric_pair(cells_raw[frame]) or not BaseAdapter._numeric_pair(source_anchors[frame]) or not BaseAdapter._numeric_pair(body_anchors[frame]):
			return {}
		var column_value := float(cells_raw[frame][0])
		var row_value := float(cells_raw[frame][1])
		if column_value != floorf(column_value) or row_value != floorf(row_value) or column_value < 0 or row_value < 0 or column_value >= cols or row_value >= rows:
			return {}
		var coordinate := Vector2i(int(column_value), int(row_value))
		if used_cells.has(coordinate):
			# No duplicate cell used to turn a static/short strip into eight frames.
			return {}
		used_cells[coordinate] = true
		var source_point := Vector2(float(source_anchors[frame][0]), float(source_anchors[frame][1]))
		var body_point := Vector2(float(body_anchors[frame][0]), float(body_anchors[frame][1]))
		if source_point.x < 0 or source_point.y < 0 or source_point.x > source_cell.x or source_point.y > source_cell.y or body_point.x < 0 or body_point.y < 0 or body_point.x > cell.x or body_point.y > cell.y:
			return {}
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = atlas
		frame_texture.region = Rect2(Vector2(coordinate) * cell, cell)
		frame_texture.filter_clip = true
		frames.append(frame_texture)
		source_points.append(source_point)
		body_points.append(body_point)
	return {"source": source, "atlas": atlas, "frames": frames,
		"source_hframes": source_hframes, "source_vframes": source_vframes,
		"source_cell": source_cell, "cell": cell,
		"source_anchors": source_points, "body_anchors": body_points,
		"ratio": source_height / height, "source_body_height": source_height,
		"body_height": height, "declared_frame_cells": cells_raw.duplicate(true)}
