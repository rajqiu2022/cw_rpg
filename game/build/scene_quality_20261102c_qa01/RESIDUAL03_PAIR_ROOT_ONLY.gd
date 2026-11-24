extends "res://build/scene_quality_20261102c_qa01/RESIDUAL03_BASE_ROOT_ONLY.gd"
## Pair only: one public near at moved Docks mouth; exactly two real Space legs.
## No Civic or accepted Docks screenshot replay. No near between pair legs.
func run() -> void:
	await process_frame
	if not bind_residual("MOVED_DOCKS_GARDEN_PAIR_TWO_TRUE_DIRECTIONS_ONLY"): finish(); return
	var garden: Dictionary = {}
	for endpoint: Dictionary in pairs.call("endpoints", DOCKS):
		if endpoint.pair_id == "docks_garden": garden = endpoint
	if not need(not garden.is_empty() and garden.mouth == Vector2(96,1216) and garden.arrival == Vector2(200,1216), "ORIGINAL_MOVED_PAIR_IDENTITY"): finish(); return
	var field: Node = await near_legacy(DOCKS, Vector2(116,1216))
	if field == null or done: finish(); return
	records.append({"single_absolute_setup_complete":diagnostic(),"default_bootstraps":0})
	await space()
	field = await wait_field(String(garden.target.scene_id))
	if field == null or done: finish(); return
	if not need(foot(field).distance_to(garden.target.arrival) < .05, "TRUE_GARDEN_LEG_EXACT_ARRIVAL"): finish(); return
	await walk(KEY_D, 10)
	await space()
	field = await wait_field(DOCKS)
	if field == null or done: finish(); return
	if not need(foot(field).distance_to(Vector2(200,1216)) < .05, "TRUE_PAIR_RETURN_TO_MOVED_DOCKS2001216"): finish(); return
	records.append({"new_pair_true_directions":2,"history":nav.call("get_debug_state").get("route_history", []),"no_near_between_pair_legs":true,"final":diagnostic(),"normal_images_requested":0})
	finish()
