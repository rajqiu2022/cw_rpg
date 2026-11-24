extends RefCounted

const BASE := preload("res://scripts/dev/world_native_pair_prop_contract_v1.gd")
const WORLD_SIZE := Vector2(3072, 1024)
const BOULDER := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v3.png"
const BOULDER_META := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v3.json"


static func props() -> Array[Dictionary]:
	var entries := BASE.props()
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(BOULDER_META))
	var foot_uv := Vector2(0.5, 0.642471)
	if metadata is Dictionary and metadata.has("foot_uv"):
		foot_uv = Vector2(metadata["foot_uv"][0], metadata["foot_uv"][1])
	for prop in entries:
		if String(prop["id"]) == "generated_shrub_east":
			prop["foot"] = Vector2(2260, 650)
		if String(prop["id"]).begins_with("cc0_boulder"):
			prop["texture"] = BOULDER
			prop["size"] = Vector2(prop["size"].x, prop["size"].x * 399.0 / 372.0)
			prop["foot_uv"] = foot_uv
			prop["footprint"] = Vector2(prop["footprint"].x, 58)
		else:
			prop["foot_uv"] = Vector2(0.5, 0.94)
	return entries


static func scene_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary] = []
	for prop in props():
		var foot: Vector2 = prop["foot"]
		var size: Vector2 = prop["size"]
		var visual_center: Vector2 = foot + (Vector2(0.5, 0.5) - prop["foot_uv"]) * size
		objects.append({
			"id": prop["id"], "texture": prop["texture"],
			"pos": visual_center / WORLD_SIZE, "render_size_px": size,
			"sort_by_feet": true, "depth_sort_foot_y": foot.y / WORLD_SIZE.y,
			"collision_offset": (foot - visual_center) / WORLD_SIZE,
			"collision_size": prop["footprint"] / WORLD_SIZE,
			"ground_shadow_size_px": prop["footprint"] * Vector2(1.35, 0.95),
		})
	return objects
