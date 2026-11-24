extends "res://build/player_portrait_minimap_20261030f_system01/portrait_marker.gd"

func sync_marker(point: Vector2) -> void:
	super.sync_marker(point)
	var side := roundf(clampf(32.0 * get_viewport_rect().size.y / 1080.0, 24.0, 44.0))
	size = Vector2.ONE * side
	position = (point - size * 0.5).round()

func _draw() -> void:
	var center := size * 0.5
	var radius := center.x
	draw_circle(center, radius + 1, Color("#1a2426"), true, -1, true)
	draw_circle(center, radius, Color("#dcc594"), true, -1, true)
	if _texture != null:
		var sheet := _texture
		var crop := _source_rect
		if sheet is AtlasTexture:
			var atlas := sheet as AtlasTexture
			# The face crop is local to the bust. Polygon UVs address the full sheet.
			crop = atlas.get_meta("face_region", crop)
			crop.position += atlas.region.position
			sheet = atlas.atlas
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for index in 48:
			var dir := Vector2.from_angle(index * TAU / 48.0)
			points.append(center + dir * (radius - 1.6))
			uvs.append((crop.position + (dir + Vector2.ONE) * 0.5 * crop.size) / sheet.get_size())
		draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, sheet)
	else:
		var font: Font=ThemeDB.fallback_font
		var text_size: int=14
		var extent: Vector2=font.get_string_size(_initial,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size)
		draw_string(font,Vector2((size.x-extent.x)*.5,(size.y-extent.y)*.5+font.get_ascent(text_size)),_initial,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,Color(0.82,0.94,0.95))
