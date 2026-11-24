extends SceneTree
## Root-only changed-domain checks. Public near setups are not continuous travel.
const HOME := "res://build/scene_quality_20261102c_qa01/"
const PAIRS := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const GEO := "res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd"
const DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const SPEC := "res://build/scene_cleanup_20261102c_system01/publication_spec_READY.json"
const CIVIC := "luoyang_civic_market_region_27d"
const TEMPLE := "luoyang_temple_region_27d"
const DOCKS := "ch4_s2_canal_docks"
var router: Node
var nav: Node
var icons: Node
var loader: Node
var geometry: GDScript
var pairs: GDScript
var errors: Array[String] = []
var records: Array = []
var checks := 0
var inputs := 0
var images := 0
var suspended := false
var done := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children(): _early(node)
	run.call_deferred()
	watch.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func watch() -> void:
	await create_timer(180.0, true, false, true).timeout
	if not done:
		need(false, "180S_CHANGED_DOMAIN_WATCHDOG")
		finish()

func prop(object: Object, key: String, fallback: Variant = null) -> Variant:
	if not is_instance_valid(object): return fallback
	for row: Dictionary in object.get_property_list():
		if String(row.name) == key: return object.get(key)
	return fallback

func physical(field: Node) -> String:
	var scene: SceneScript = prop(field, "_current_scene") as SceneScript
	return String(scene.scene_id) if scene != null else ""

func foot(field: Node) -> Vector2:
	var actor: Node2D = prop(field, "_player") as Node2D
	var world: Node2D = prop(field, "world_container") as Node2D
	return world.to_local(actor.global_position) if actor != null and world != null else Vector2(INF, INF)

func diagnostic() -> Dictionary:
	var field: Node = current_scene
	return {"physical":physical(field), "foot":foot(field), "loading":field.call("get_field_loading_state") if is_instance_valid(field) and field.has_method("get_field_loading_state") else {}, "nav":nav.call("get_debug_state") if is_instance_valid(nav) else {}, "icons":icons.call("get_debug_state") if is_instance_valid(icons) else {}}

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		errors.append(label)
		records.append({"failure":label, "actual":diagnostic()})
		printerr("SCENE_QUALITY02C_FAIL ", label)
	return ok

func wait_field(id: String) -> Node:
	var until := Time.get_ticks_msec() + 35000
	while Time.get_ticks_msec() < until and not done:
		await process_frame
		var field: Node = current_scene
		var actual_id: String = physical(field)
		if (not actual_id.begins_with("world_map_jianghu") if id == "WORLD" else actual_id != id) or not field.has_method("get_field_loading_state"): continue
		var state: Dictionary = field.call("get_field_loading_state")
		if state.get("failed") == true:
			need(false, "FIELD_FAILED:" + id)
			return null
		var actor: Node = prop(field, "_player") as Node
		var screen: Node = loader.get("_screen") as Node
		if state.get("complete") != true or loader.get("_transition_active") == true or loader.get("_external_active") == true or (screen != null and screen.call("is_showing")) or actor == null or actor.get("can_move") != true: continue
		if id in pairs.call("area_ids"):
			var debug: Dictionary = nav.call("get_debug_state")
			if debug.get("attached_scene") != id or debug.get("mini_ok") != true or not debug.get("pending", {}).is_empty(): continue
		var ui: Dictionary = icons.call("get_debug_state")
		if ui.get("overlay", {}).get("markers", []).is_empty(): continue
		if id == "WORLD" and ui.get("overlay", {}).get("kind") != "WORLD": continue
		return field
	need(false, "35S_READY:" + id)
	return null

func near_region(id: String, logical: String, point: Vector2) -> Node:
	var compiled: Dictionary = geometry.call("region_for", id)
	if not need(not compiled.is_empty() and geometry.call("safe_segment", id, point, point), "DECLARED_REGION_NEAR_SAFE:" + id): return null
	var extension := {"region_id":id, "revision":compiled.revision, "logical_id":logical, "global_foot_px":[point.x, point.y]}
	var dispatch: GDScript = load(DISPATCH) as GDScript
	var accepted: bool = dispatch.call("start", router, StringName(logical), compiled.districts[logical].save_fallback_uv, "", 3, extension)
	if not need(accepted, "PUBLIC_REGION_NEAR_NOT_TRAVEL:" + id): return null
	var field: Node = await wait_field(id)
	if field != null: need(foot(field).distance_to(point) < .05, "EXACT_PUBLIC_NEAR_FOOT:" + id)
	return field

func near_legacy(id: String, point: Vector2) -> Node:
	if not need(router.call("go_field_smart", StringName(id), null, "", -1, 3) == true, "PUBLIC_LEGACY_BOOTSTRAP:" + id): return null
	var field: Node = await wait_field(id)
	if field == null: return null
	if not need(router.call("go_field_smart", StringName(id), point / geometry.call("size_for", id), "", -1, 3) == true, "PUBLIC_LEGACY_CURRENT_NEAR:" + id): return null
	field = await wait_field(id)
	if field != null: need(foot(field).distance_to(point) < .05, "EXACT_PUBLIC_NEAR_FOOT:" + id)
	return field

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	Input.parse_input_event(event); Input.flush_buffered_events(); inputs += 1

func walk(code: int, frames: int) -> void:
	key(code, true)
	for frame: int in range(frames): await physics_frame
	key(code, false)
	await physics_frame
	await process_frame

func space() -> void:
	key(KEY_SPACE, true); await physics_frame
	key(KEY_SPACE, false); await process_frame

func region_retired(field: Node) -> bool:
	var id: String = physical(field)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	var compiled: Dictionary = field.get("_region")
	var missing := true
	for owner: Dictionary in spec.scenes[id].owners:
		for render: Dictionary in compiled.render:
			if String(render.get("id", "")) == String(owner.id): missing = false
	return need(missing, "ALL_THIS_REGION_RETIRED_IDS_ABSENT:" + id)

func icon_checks(world: bool) -> bool:
	var debug: Dictionary = icons.call("get_debug_state")
	var overlay: Dictionary = debug.get("overlay", {})
	var ok := need(not overlay.is_empty() and overlay.get("missing_assets", []).is_empty() and overlay.get("atlas_ready") == true, "REAL_ICON_ASSETS_READY")
	ok = need(overlay.get("ordinary_building_markers") == 0 and overlay.get("icon_backplates") == 0 and overlay.get("icon_text") == 0, "PURE_GLYPHS_NO_DOORS_BACKPLATES_OR_TEXT") and ok
	for zone: ExitZone in prop(current_scene, "_exit_nodes", []):
		if is_instance_valid(zone) and zone.visible and zone.prompt != null and zone.prompt.visible:
			ok = need(not zone.prompt.text.contains("空格"), "NO_VISIBLE_INPUT_KEY_PREFIX") and ok
	if world:
		var has_bright_city := false
		var has_gray := false
		var kinds: Dictionary = {}
		for row: Dictionary in overlay.get("rows", []):
			kinds[row.kind] = true
			if row.target == "ch4_s0_luoyang_gate" and row.get("visited") == true: has_bright_city = true
			if row.get("visited") != true: has_gray = true
		ok = need(has_bright_city and has_gray and kinds.size() >= 4, "ACTUAL_SUCCESSFUL_CITY_BRIGHT_UNVISITED_GRAY_CATEGORIES") and ok
		ok = need(overlay.get("world_player_portrait", {}).get("kind") == "PLAYER_PORTRAIT" and overlay.get("world_player_arrow") == false, "WORLD_EXISTING_PORTRAIT_NOT_ARROW") and ok
	records.append({"icon_actual":debug, "world":world})
	return ok

func capture(label: String) -> bool:
	if not need(images < 4, "AT_MOST_FOUR_CHANGED_DOMAIN_IMAGES"): return false
	await RenderingServer.frame_post_draw
	if done: return false
	var pixels: Image = root.get_viewport().get_texture().get_image()
	var output: String = HOME + "actual/%d/" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	if not need(pixels != null and pixels.get_size() == Vector2i(1920,1080), "NATIVE_NORMAL1920_IMAGE"): return false
	if not need(pixels.save_png(output + label + ".png") == OK, "NORMAL_CAPTURE:" + label): return false
	images += 1
	var camera: Camera2D = prop(current_scene, "_world_camera") as Camera2D
	records.append({"image":output + label + ".png", "physical":physical(current_scene), "foot":foot(current_scene), "native_zoom":camera.zoom if camera != null else Vector2.ZERO, "no_camera_or_actor_writes":true})
	return true

func run() -> void:
	await process_frame
	if not need(suspended, "EARLY_CHECKPOINT_SUSPEND"): finish(); return
	router = root.get_node("SceneRouter"); nav = root.get_node("CityNavigationRuntime"); icons = root.get_node("MapIconRuntime"); loader = root.get_node("LoadingManager")
	pairs = load(PAIRS) as GDScript; geometry = load(GEO) as GDScript
	var field: Node = await near_region(CIVIC, "ch4_s1_luoyang_yamen", Vector2(2500,2240))
	if field == null or done: finish(); return
	var instance: int = field.get_instance_id()
	await walk(KEY_S, 14)
	if not need(current_scene == field and field.get_instance_id() == instance and foot(field).y > 2320 and absf(foot(field).x - 2500) < .1, "REAL_S_CROSSES_FORMER40PX_SOIL_GAP"): finish(); return
	await walk(KEY_W, 14)
	if not need(current_scene == field and foot(field).y < 2250, "SAME_INSTANCE_REAL_W_RETURNS_ACROSS_GAP"): finish(); return
	records.append({"new_floor_true_walk":true, "end":foot(field), "private_actor_moves":0})
	field = await near_region(CIVIC, "ch4_s1_luoyang_yamen", Vector2(1300,2225))
	if field == null or done: finish(); return
	instance = field.get_instance_id(); await walk(KEY_W, 22)
	if not need(current_scene == field and field.get_instance_id() == instance and foot(field).y < 2090, "REAL_W_CROSSES_RETIRED_WAITING_FRONT_WALL"): finish(); return
	if not region_retired(field) or not icon_checks(false) or not await capture("civic_retired_walls_ground_icons_normal"): finish(); return
	field = await near_legacy(DOCKS, Vector2(200,1450))
	if field == null or done: finish(); return
	var garden: Dictionary = {}
	var market: Dictionary = {}
	for endpoint: Dictionary in pairs.call("endpoints", DOCKS):
		if endpoint.pair_id == "docks_garden": garden = endpoint
		if endpoint.pair_id == "market_docks": market = endpoint
	if not need(not garden.is_empty() and not market.is_empty() and garden.mouth == Vector2(96,1216) and garden.arrival == Vector2(200,1216) and garden.mouth.distance_to(market.mouth) > 540, "ONE_MOVED_GARDEN_MOUTH_SEPARATED_FROM_MARKET"): finish(); return
	if not icon_checks(false) or not await capture("docks_separated_exits_retired_walls_normal"): finish(); return
	field = await near_legacy(DOCKS, garden.mouth - garden.outward * 20.0)
	if field == null or done: finish(); return
	await space()
	field = await wait_field(String(garden.target.scene_id))
	if field == null or done: finish(); return
	if not need(foot(field).distance_to(garden.target.arrival) < .05, "TRUE_GARDEN_LEG_EXACT_ARRIVAL"): finish(); return
	await walk(KEY_D, 10)
	await space()
	field = await wait_field(DOCKS)
	if field == null or done: finish(); return
	if not need(foot(field).distance_to(Vector2(200,1216)) < .05, "TRUE_PAIR_RETURN_TO_MOVED_DOCKS2001216"): finish(); return
	records.append({"new_pair_true_directions":2, "history":nav.call("get_debug_state").get("route_history", []), "no_near_between_pair_legs":true})
	field = await near_region(TEMPLE, "ch4_s4_ancient_temple", Vector2(1000,820))
	if field == null or done: finish(); return
	if not region_retired(field) or not await capture("temple_retired_small_broken_wall_normal"): finish(); return
	router.call("go_world_map")
	field = await wait_field("WORLD")
	if field == null or done: finish(); return
	if not icon_checks(true) or not await capture("world_pure_category_visited_icons_normal"): finish(); return
	finish()

func finish() -> void:
	if done: return
	done = true
	for code: int in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
		if Input.is_physical_key_pressed(code): key(code, false)
	var output: String = HOME + "actual/%d/" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"passed":errors.is_empty(), "checks":checks, "errors":errors, "records":records, "input_events":inputs, "normal_images":images, "scope":"CHANGED_CIVIC_FLOOR_WALLS_DOCKS_GARDEN_PAIR_AND_PURE_ICONS_ONLY", "public_near_not_continuous_world_travel":true, "private_actor_or_camera_writes":false, "real_save_contents_read":false, "save_API_calls":0, "old20_pair_directions_retested":false}, "\t") + "\n")
		file.close()
	print("SCENE_QUALITY02C_NEW_DOMAIN_RESULT ", checks, " / ", errors.size(), " ", output)
	quit(0 if errors.is_empty() else 1)
