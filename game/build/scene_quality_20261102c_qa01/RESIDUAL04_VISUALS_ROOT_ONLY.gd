extends "res://build/scene_quality_20261102c_qa01/RESIDUAL03_BASE_ROOT_ONLY.gd"
## Two remaining normal images only. Pair/Civic/Docks prefix is not repeated.
## Temple successful readiness earns Luoyang visited naturally in this process.
func run() -> void:
	await process_frame
	if not bind_residual("TEMPLE_RETIRED_WALL_AND_WORLD_CATEGORY_VISIT_TWO_IMAGES_ONLY"): finish(); return
	var field: Node = await near_region(TEMPLE, "ch4_s4_ancient_temple", Vector2(1000,820))
	if field == null or done: finish(); return
	if not region_retired(field) or not await capture("temple_retired_small_broken_wall_normal"): finish(); return
	router.call("go_world_map")
	field = await wait_field("WORLD")
	if field == null or done: finish(); return
	if not icon_checks(true) or not await capture("world_pure_category_visited_icons_normal"): finish(); return
	records.append({"two_remaining_images_only":true,"visit_earned_by_actual_temple_not_seeded":true,"final":diagnostic()})
	finish()
