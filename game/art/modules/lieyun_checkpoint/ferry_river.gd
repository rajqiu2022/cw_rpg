extends MeshInstance2D
## The collision outline follows the west bank downstream, then the east bank upstream.
## Each cross section carries its own width so the wet margin stays in world pixels.
## Separate collision reaches leave walkable bridge decks. The surface spans those gaps.
@export var bank_shapes: Array[NodePath] = [NodePath("../Town/RiverBank/Shape")]

func _ready() -> void:
	var west_bank := PackedVector2Array()
	var east_bank := PackedVector2Array()
	for path in bank_shapes:
		var shape := get_node(path) as CollisionPolygon2D
		var outline := shape.polygon
		for j in range(outline.size() / 2):
			west_bank.append(to_local(shape.to_global(outline[j])))
			east_bank.append(to_local(shape.to_global(outline[-1 - j])))
	var points := PackedVector2Array()
	var coords := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var distance := 0.0
	var previous := Vector2.ZERO
	for i in west_bank.size():
		var west := west_bank[i]
		var east := east_bank[i]
		var center := (west + east) * 0.5
		if i > 0:
			distance += center.distance_to(previous)
		previous = center
		var width := east.x - west.x
		var margin := 68.0
		for x: float in [west.x - margin, west.x, east.x, east.x + margin]:
			points.append(Vector2(x, center.y))
			coords.append(Vector2((x - west.x) / width, distance / 512.0))
			colors.append(Color(width / 1600.0, 1.0, 1.0))
		if i > 0:
			for lane in 3:
				var a := (i - 1) * 4 + lane
				indices.append_array(PackedInt32Array([a, a + 1, a + 4, a + 1, a + 5, a + 4]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = coords
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var ribbon := ArrayMesh.new()
	ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = ribbon
