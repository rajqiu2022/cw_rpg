extends RefCounted
## Native image bytes + measured atlas regions. No resampled body images.
const ROOT := "res://art/characters/hero_combat_20261111/"
const ROWS := preload("res://art/characters/hero_combat_20261111/source_frames.gd").DATA

static func install(clips: Dictionary, textures: Dictionary) -> void:
	install_rows(ROOT, ROWS, clips, textures)

static func install_rows(root: String, rows: Dictionary, clips: Dictionary, textures: Dictionary, prefer_imported := false) -> void:
	var sheets: Dictionary = {}
	for key: String in rows:
		var row: Dictionary = rows[key]
		var path: String = root + row.file
		if not sheets.has(path):
			sheets[path] = _load_sheet(path, row, prefer_imported)
		var sheet := sheets[path] as Texture2D
		if sheet == null:
			continue
		textures[key] = sheet
		var frames: Array = []
		for i in range(row.frames.size()):
			var spec: Dictionary = row.frames[i]
			var ratio: float = row.ratio
			var foot := Vector2(spec.foot[0], spec.foot[1]) * ratio
			var near := Vector2(spec.near[0], spec.near[1]) * ratio
			var far := Vector2(spec.far[0], spec.far[1]) * ratio
			var polygon := PackedVector2Array()
			for point: Array in spec.get("fingers", []):
				polygon.append(Vector2(point[0], point[1]))
			var far_polygon := PackedVector2Array()
			for point: Array in spec.get("far_fingers", []):
				far_polygon.append(Vector2(point[0], point[1]))
			frames.append({
				"texture":key, "cell_index":i, "source_scale":ratio,
				"region":Rect2(spec.region[0], spec.region[1], spec.region[2], spec.region[3]),
				"foot":[foot.x,foot.y], "grip":[near.x,near.y], "hand_center":[near.x,near.y],
				"far_hand":far, "angle":spec.angle, "weapon_z":3,
				"show_concealed":spec.get("show_concealed", false),
				"fingers":polygon, "far_fingers":far_polygon,
				"weapon_grips":{"seven_star_sword":[512,1120], "jinhe_duanyue_blade":[512,1045]},
			})
		clips[key] = {"cell":row.size, "frames":frames}

static func _load_sheet(path: String, row: Dictionary, prefer_imported: bool) -> Texture2D:
	var has_source := FileAccess.file_exists(path)
	if has_source and FileAccess.get_sha256(path) != row.sha:
		push_warning("Hero combat source rejected: " + path)
		return null
	var expected := Vector2i(row.size[0], row.size[1])
	var source: Image
	if (prefer_imported or not has_source) and ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			if prefer_imported and imported.get_size() == Vector2(expected):
				return imported
			source = imported.get_image()
	elif has_source:
		source = Image.load_from_file(path)
	if source == null or source.get_size() != expected:
		return null
	if source.is_compressed() and source.decompress() != OK:
		return null
	if not source.has_mipmaps():
		source.generate_mipmaps()
	return ImageTexture.create_from_image(source)
