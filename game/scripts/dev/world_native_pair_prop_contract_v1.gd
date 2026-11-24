extends RefCounted

# Isolated two-region lab contract. These props are deliberately not part of the
# shipped v12 map or the nine-tile v13 staging map.
const WORLD_SIZE := Vector2(3072.0, 1024.0)
const BOULDER := "res://art/modules/world_map_v13/boulder_01_cc0_southwest_v2.png"
const SHRUB := "res://art/modules/world_map_v13/shrub_cluster_generated_v1_candidate.png"


static func props() -> Array[Dictionary]:
	return [
		{"id": "cc0_boulder_west", "texture": BOULDER, "foot": Vector2(855, 650), "size": Vector2(154, 113), "footprint": Vector2(94, 42)},
		{"id": "generated_shrub_west", "texture": SHRUB, "foot": Vector2(1175, 745), "size": Vector2(250, 167), "footprint": Vector2(155, 47)},
		{"id": "cc0_boulder_east", "texture": BOULDER, "foot": Vector2(2130, 750), "size": Vector2(145, 106), "footprint": Vector2(88, 40)},
		{"id": "generated_shrub_east", "texture": SHRUB, "foot": Vector2(2250, 265), "size": Vector2(220, 147), "footprint": Vector2(135, 42)},
	]


static func scene_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary] = []
	for prop in props():
		var foot: Vector2 = prop["foot"]
		var size: Vector2 = prop["size"]
		var visual_center := foot - Vector2(0.0, size.y * 0.5 - 6.0)
		objects.append({
			"id": prop["id"],
			"texture": prop["texture"],
			"pos": visual_center / WORLD_SIZE,
			"render_size_px": size,
			"sort_by_feet": true,
			"depth_sort_foot_y": foot.y / WORLD_SIZE.y,
			"collision_offset": (foot - visual_center) / WORLD_SIZE,
			"collision_size": prop["footprint"] / WORLD_SIZE,
			"ground_shadow_size_px": prop["footprint"] * Vector2(1.65, 1.60),
		})
	return objects
