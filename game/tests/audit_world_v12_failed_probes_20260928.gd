extends SceneTree

## Diagnostic only: preserve the four historical v12 failures and classify
## whether they are road-mask breaks or stale old-1536 coordinate witnesses.

const BACKGROUND := "res://art/backgrounds/region_masters_v2/bg_world_map_jianghu_v12_2304.png"
const MASK := "res://art/navigation_masks/world_map_jianghu_walk_v12.png"
const OUTPUT_DIR := "res://screenshots/world_map_v13_staging_qa/v12_failed_probes"
const OLD_SIZE := Vector2(1536, 1024)
const V12_SIZE := Vector2(2304, 1536)
const SAMPLES := [Vector2(760, 470), Vector2(1160, 760), Vector2(1210, 835)]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var background := Image.load_from_file(BACKGROUND)
	var mask := (load(MASK) as Texture2D).get_image()
	if background == null or mask == null:
		push_error("[FAIL] v12 diagnostic could not load background/mask")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	var scene := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	field.set("_current_scene", scene)
	field.set("_world_size", V12_SIZE)
	field.call("_load_walkable_mask", MASK)
	field.call("_load_walkable_mask_tiles", scene.map_layout.walkable_mask_tiles)
	field.call("_rebuild_walkability_collision_entries", scene.map_layout.blockers, scene.map_layout.visual_objects)
	for raw_sample in SAMPLES:
		var sample: Vector2 = raw_sample
		var normalized: Vector2 = sample / OLD_SIZE
		var pixel := Vector2i(normalized * V12_SIZE)
		var color := mask.get_pixelv(pixel)
		var mask_pass: bool = field.call("_is_walkable_by_mask", normalized)
		var full_foot: bool = field.call("_spawn_has_foot_clearance", scene, normalized)
		var crop_origin := Vector2i(clampi(pixel.x - 170, 0, background.get_width() - 340), clampi(pixel.y - 170, 0, background.get_height() - 340))
		var crop := background.get_region(Rect2i(crop_origin, Vector2i(340, 340)))
		var path := OUTPUT_DIR.path_join("sample_%d_%d.png" % [int(sample.x), int(sample.y)])
		crop.save_png(path)
		var nearest := _nearest_safe(field, normalized, 120)
		print("[V12_PROBE] old=%s native=%s mask=%s mask_pass=%s full_foot=%s nearest_native=%s crop=%s" % [sample, pixel, color, mask_pass, full_foot, nearest * V12_SIZE, ProjectSettings.globalize_path(path)])
	field.free()
	quit(0)


func _nearest_safe(field: Node, point: Vector2, radius_px: int) -> Vector2:
	for radius in range(4, radius_px + 4, 4):
		for index in range(32):
			var candidate := point + Vector2.from_angle(TAU * float(index) / 32.0) * float(radius) / V12_SIZE
			if field.call("_is_walkable_by_mask", candidate) and not field.call("_is_blocked_by_layout", candidate):
				return candidate
	return point
