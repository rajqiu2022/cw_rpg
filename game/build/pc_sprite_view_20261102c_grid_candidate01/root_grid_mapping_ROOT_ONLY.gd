extends SceneTree
## ROOT ONLY, after artwork/alpha/body audit AND approved source.json exist.
## Pure new-grid mapping check: no second adapter, actors, saves or old matrix.
const Candidate = preload("res://build/pc_sprite_view_20261102c_grid_candidate01/pc_sprite_view_grid_candidate.gd")
var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
	print("PC_GRID_CHECK ", "PASS " if condition else "FAIL ", label)


func _run() -> void:
	if not FileAccess.file_exists(Candidate.OPTIONAL_MANIFEST):
		print("PC_GRID_NOT_RUN: no accepted manifest; Root must not accept artwork by code alone")
		quit(2)
		return
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(Candidate.OPTIONAL_MANIFEST))
	if not document is Dictionary or document.get("schema") != Candidate.MANIFEST_SCHEMA or document.get("approved") != true or not document.get("mappings") is Dictionary:
		print("PC_GRID_NOT_RUN: artwork manifest not approved or wrong schema")
		quit(2)
		return
	var tested := 0
	for source_path: String in document.mappings:
		var declaration: Dictionary = document.mappings[source_path]
		if not declaration.has("frame_cells"):
			continue
		tested += 1
		var atlas_path := String(declaration.get("atlas", ""))
		var exact_sources := ResourceLoader.exists(source_path) and ResourceLoader.exists(atlas_path) and FileAccess.get_sha256(source_path) == String(declaration.get("source_sha256", "")) and FileAccess.get_sha256(atlas_path) == String(declaration.get("atlas_sha256", ""))
		if not exact_sources:
			_check("new grid exact accepted resources: " + source_path, false)
			continue
		var source := load(source_path) as Texture2D
		var atlas := load(atlas_path) as Texture2D
		var mapping := Candidate.prepare_declared_cell_mapping(source, atlas, declaration)
		_check("new declared grid accepted with original source pointer: " + source_path, not mapping.is_empty() and mapping.source == source and mapping.atlas == atlas)
		if mapping.is_empty():
			continue
		var correct_regions := true
		for frame: int in range(int(declaration.framecount)):
			var coordinate: Array = declaration.frame_cells[frame]
			var expected := Rect2(Vector2(float(coordinate[0]), float(coordinate[1])) * mapping.cell, mapping.cell)
			var frame_texture: AtlasTexture = mapping.frames[frame]
			correct_regions = correct_regions and frame_texture.atlas == atlas and frame_texture.region == expected and frame_texture.filter_clip
			print("PC_GRID_CELL_SAMPLE ", JSON.stringify({"source": source_path, "source_frame": frame, "declared_cell": coordinate, "actual_region": frame_texture.region, "uniform_ratio": mapping.ratio, "source_anchor": mapping.source_anchors[frame], "target_anchor": mapping.body_anchors[frame]}))
		_check("all new frame cells and one common scale: " + source_path, correct_regions and is_equal_approx(float(mapping.ratio), float(declaration.source_body_height) / float(declaration.body_height)))
		var invalid := declaration.duplicate(true)
		invalid.body_height = 319
		var low_native_rejected := Candidate.prepare_declared_cell_mapping(source, atlas, invalid).is_empty()
		invalid = declaration.duplicate(true)
		invalid.frame_cells[0] = [int(declaration.cols), 0]
		var outside_rejected := Candidate.prepare_declared_cell_mapping(source, atlas, invalid).is_empty()
		invalid = declaration.duplicate(true)
		invalid.frame_cells[1] = invalid.frame_cells[0].duplicate()
		var duplicate_rejected := Candidate.prepare_declared_cell_mapping(source, atlas, invalid).is_empty()
		_check("new grid invalid geometry and non-HD rejected: " + source_path, low_native_rejected and outside_rejected and duplicate_rejected)
	print("PC_GRID_RESULT ", JSON.stringify({"tested_new_mappings": tested, "passed": _passed, "failed": _failed, "no_art_acceptance_implied": true, "old_matrix_repeated": false, "real_save_access": false}))
	quit(2 if tested == 0 else (0 if _failed == 0 else 1))
