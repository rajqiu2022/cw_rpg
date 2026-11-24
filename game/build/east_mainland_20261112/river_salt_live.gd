extends "res://build/east_mainland_20261112/live.gd"

const CANGPU := &"east_cangpu_city"
const SALT := &"east_salt_bay_village"


func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	var field := await enter(REGION)
	if field == null or not await cross(field, "east_cangpu_city_entry", CANGPU):
		finish()
		return
	field = current_scene
	check_minimap(field, CANGPU)
	check_foot(field, Vector2(0.514, 0.840), true, "city arrival unchanged and walkable")
	check_foot(field, Vector2(0.833, 0.557), true, "market reaches promenade")
	check_foot(field, Vector2(0.852, 0.557), true, "quay head accessible")
	check_foot(field, Vector2(0.916, 0.557), false, "river does not gain walkability from pier")
	check_foot(field, Vector2(0.973, 0.48), false, "open river blocked")
	expect(field.get("_visual_layer").has_node("TravelRoute_river_promenade"), "river road passed clearance and rendered")
	var river_actor: Node2D = field.get("_player")
	river_actor.position = Vector2(0.837, 0.566) * Vector2(field.get("_world_size"))
	var river_start := river_actor.position.y
	await walk(KEY_S, 25)
	expect(river_actor.position.y > river_start + 28.0, "actual input walks south along riverside")
	field.get("_player").position = Vector2(0.846, 0.576) * Vector2(field.get("_world_size"))
	await picture("01_cangpu_river.png")
	if not await cross(field, "east_road_return", REGION) or not await cross(current_scene, "east_salt_bay_village_entry", SALT):
		finish()
		return
	field = current_scene
	check_minimap(field, SALT)
	check_foot(field, Vector2(0.501, 0.225), true, "village arrival unchanged and walkable")
	check_foot(field, Vector2(0.397, 0.672), true, "main berm walkable")
	check_foot(field, Vector2(0.240, 0.634), true, "cross-berm walkable")
	for row: Dictionary in field.get("_current_scene").map_layout.blockers:
		check_foot(field, row.pos, false, "salt pan blocked " + str(row.id))
	expect(field.get("_visual_layer").has_node("TravelRoute_salt_berm"), "salt road passed clearance and rendered")
	var salt_actor: Node2D = field.get("_player")
	salt_actor.position = Vector2(0.397, 0.635) * Vector2(field.get("_world_size"))
	var salt_start := salt_actor.position.x
	await walk(KEY_A, 25)
	expect(salt_actor.position.x < salt_start - 28.0, "actual input crosses between pan rows")
	field.get("_player").position = Vector2(0.398, 0.639) * Vector2(field.get("_world_size"))
	await picture("02_salt_bay_pans.png")
	await cross(field, "east_road_return", REGION)
	finish()


func check_foot(field: Node, uv: Vector2, safe: bool, label: String) -> void:
	var world: Node2D = field.get("world_container")
	var px: Vector2 = uv * Vector2(field.get("_world_size"))
	expect(field.call("_is_inside_walkable_screen", world.to_global(px)) == safe, label)


func walk(key: Key, ticks: int) -> void:
	var input := InputEventKey.new()
	input.keycode = key
	input.physical_keycode = key
	input.pressed = true
	Input.parse_input_event(input)
	for i in ticks:
		await physics_frame
	input = input.duplicate()
	input.pressed = false
	Input.parse_input_event(input)
	await process_frame
