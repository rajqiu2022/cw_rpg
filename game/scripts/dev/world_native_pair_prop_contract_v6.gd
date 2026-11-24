extends RefCounted

const BASE := preload("res://scripts/dev/world_native_pair_prop_contract_v5.gd")
const WORLD_SIZE := Vector2(3072, 1024)
const BOULDER := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4.png"
const META := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4.json"
const BOULDER_B := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4b.png"
const META_B := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4b.json"
const SHRUB := "res://art/modules/world_map_v13/shrub_cluster_generated_v1_candidate.png"


static func props() -> Array[Dictionary]:
	var entries := BASE.props()
	# Hand-authored groves and outcrops, never a uniform/random prop carpet.
	for entry in [
		{"id": "grove_west_a", "texture": SHRUB, "foot": Vector2(280, 795), "size": Vector2(240, 160), "footprint": Vector2(142, 46)},
		{"id": "grove_west_b", "texture": SHRUB, "foot": Vector2(510, 755), "size": Vector2(190, 127), "footprint": Vector2(114, 38)},
		{"id": "grove_west_c", "texture": SHRUB, "foot": Vector2(680, 810), "size": Vector2(235, 157), "footprint": Vector2(140, 46)},
		{"id": "grove_middle_a", "texture": SHRUB, "foot": Vector2(1470, 735), "size": Vector2(235, 157), "footprint": Vector2(140, 46)},
		{"id": "grove_middle_b", "texture": SHRUB, "foot": Vector2(1740, 800), "size": Vector2(200, 134), "footprint": Vector2(120, 40)},
		{"id": "grove_east_a", "texture": SHRUB, "foot": Vector2(2270, 895), "size": Vector2(205, 137), "footprint": Vector2(120, 40)},
		{"id": "cc0_boulder_west_low", "texture": BOULDER, "foot": Vector2(400, 895), "size": Vector2(130, 100), "footprint": Vector2(80, 52)},
		{"id": "cc0_boulder_middle", "texture": BOULDER, "foot": Vector2(1540, 645), "size": Vector2(120, 92), "footprint": Vector2(74, 48)},
		{"id": "cc0_boulder_east_low", "texture": BOULDER, "foot": Vector2(1850, 685), "size": Vector2(130, 100), "footprint": Vector2(80, 52)},
	]:
		entries.append(entry)
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(META))
	var metadata_b: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_B))
	if not metadata is Dictionary or not metadata_b is Dictionary:
		push_error("Render and import the v4 CC0 boulder with foot metadata first")
		return []
	for prop in entries:
		if String(prop["id"]).begins_with("cc0_boulder"):
			var use_b: bool = String(prop["id"]) in ["cc0_boulder_east", "cc0_boulder_middle"]
			var source: Dictionary = metadata_b if use_b else metadata
			var foot_uv := Vector2(source["foot_uv"][0], source["foot_uv"][1])
			var ratio: float = float(source["size"][1]) / float(source["size"][0])
			prop["texture"] = BOULDER_B if use_b else BOULDER
			prop["size"] = Vector2(prop["size"].x, prop["size"].x * ratio)
			prop["foot_uv"] = foot_uv
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
			# The projected rock base extends below its 3D center. A contact
			# patch smaller than that silhouette is entirely hidden by the rock.
			"ground_shadow_size_px": prop["footprint"] * (Vector2(1.55, 1.4) if prop["texture"] == SHRUB else Vector2(1.85, 1.9)),
			"modulate": Color(0.91, 0.97, 0.92) if prop["texture"] == SHRUB else Color.WHITE,
		})
	return objects
