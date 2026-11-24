extends SceneTree
## Ground-only residual04: actual91364 112/0 and actual95060 88/0 retained.
## Both ground ART rejections remain. QA03 local-z assertions did not prove
## rendering order. This version checks real inherited CanvasItem effective z.
## No seated/decor/doors/2s replay; no save access.
## Near setups use the existing public versioned Region dispatcher; they are
## explicitly not continuous World/city travel. No Yihong setup or door replay.
const HOME := "res://build/luoyang_quality_20261101b_runtime01/"
const MANIFEST := HOME + "source_pins_READY.json"
const OUTPUT := HOME + "actual_ground04/"
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const LOGICAL := "ch4_s3_luoyang_market"
const ROOM := "yihongyuan27n_interior"
const GROUND_CASES := [
	{"id": "luoyang_estate_region_27d", "logical": "luoyang_estate_riverside_20261021ai", "foot": [1850, 3672], "image": "estate_servants_edge_normal"},
	{"id": "luoyang_civic_market_region_27d", "logical": LOGICAL, "foot": [2640, 4280], "image": "civic_cloth_court_normal"},
	{"id": "luoyang_temple_region_27d", "logical": "ch4_s4_ancient_temple", "foot": [850, 3100], "image": "temple_court_edge_normal"},
]
var errors: Array[String] = []
var records: Array = []
var checks := 0
var input_ticks := 0
var began := 0
var finished := false
var pins: Dictionary = {}
var first: Dictionary = {}
var router: Node
var host: Node
var _previous_field_instance := 0

func _initialize() -> void:
	_watchdog.call_deferred(); _run.call_deferred()

func _watchdog() -> void:
	await create_timer(180.0, true, false, true).timeout
	if not finished: need(false, "INDEPENDENT_180S_COROUTINE_WATCHDOG"); finish()

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label); printerr("QUALITY31B_QA_FAIL ", label)
	return ok

func _point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))

func _facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in pins:
		var file := FileAccess.open(path, FileAccess.READ)
		result[path] = {"sha256": FileAccess.get_sha256(path), "bytes": file.get_length() if file != null else -1, "mtime_seconds": FileAccess.get_modified_time(path)}
	return result

func _run() -> void:
	began = Time.get_ticks_msec()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not need(raw is Dictionary and raw.get("ready") == true, "ROOT_FROZEN_INDEPENDENT_SOURCE_MANIFEST"): finish(); return
	pins = raw.source_pins.duplicate(true)
	pins[MANIFEST] = FileAccess.get_sha256(MANIFEST)
	first = _facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path], "SOURCE_FIRST:" + path): finish(); return
	router = root.get_node("SceneRouter")
	host = root.get_node_or_null("SceneArtQualityRuntime")
	if not need(host != null and host.has_method("get_debug_state") and host.call("get_debug_state").get("ready") == true, "NEW_HOST_READY_FROM_REAL_AUTOLOAD"): finish(); return
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "CHECKPOINT_SUSPENDED_NO_REAL_SAVE_API"): finish(); return
	for item: Dictionary in GROUND_CASES:
		if not _setup(String(item.id), String(item.logical), _point(item.foot)): finish(); return
		var field: Node = await _wait_field(String(item.id), true)
		if field == null: finish(); return
		if not need((field.get("_player") as Node2D).position.distance_to(_point(item.foot)) <= 0.02, "PUBLIC_VERSIONED_EXACT_NEAR_FOOT:" + String(item.id)): finish(); return
		var receipt: Dictionary = field.get_meta("ground_quality31b", {})
		if not need(receipt.get("attached") == true and receipt.get("physics_changed") == false and receipt.get("compiled_changed") == false and receipt.get("period_px") == Vector2(256, 512.0 / 3.0) and receipt.get("visual_revision") == 4 and receipt.get("soil_period_px") == Vector2(768, 768) and receipt.get("curb_width_px") == 18.0 and receipt.get("dust_width_px") == 6.0, "REAL_GROUND_VIEW_RECEIPT:" + String(item.id)): finish(); return
		var view: Node = (field.get("_visual_layer") as Node).get_node_or_null("SourceBoundGroundView31b")
		if not need(view != null and _flat_view_only(view), "NEW_VIEW_HAS_ONLY_TEXTURED_UNSCRIPTED_GROUND:" + String(item.id)): finish(); return
		if not need(_ground04_details(view, String(item.id)), "REAL_EFFECTIVE_ANCESTOR_Z_ORDER_OLD_SOIL_PAVING_GARDEN:" + String(item.id)): finish(); return
		if not await _capture(String(item.image)): finish(); return
		var mini: Node = field.get("_world_travel_minimap")
		var debug: Dictionary = mini.call("get_debug_state") if is_instance_valid(mini) else {}
		if not need(debug.get("visual_cache_ready") == true and debug.get("cache_render_requests") == 1, "REAL_MINI_REBUILT_READY_ONE_SHOT:" + String(item.id)): finish(); return
	finish()

func _setup(id: String, logical: String, foot: Vector2) -> bool:
	_previous_field_instance = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var dispatcher: GDScript = load(DISPATCH) as GDScript
	var extension := {"region_id": id, "revision": 1, "logical_id": logical, "global_foot_px": [foot.x, foot.y]}
	records.append({"kind": "PUBLIC_VERSIONED_NEAR_SETUP_NOT_CONTINUOUS_TRAVEL", "region_id": id, "logical": logical, "foot": foot})
	return need(dispatcher != null and dispatcher.call("start", router, StringName(logical), Vector2(0.5, 0.5), "", -1, extension) == true, "EXISTING_PUBLIC_VERSIONED_SETUP:" + id)

func _wait_field(id: String, ground: bool) -> Node:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 30000:
		await process_frame
		var field: Node = current_scene
		if not is_instance_valid(field) or field.get_script() == null or field.get_script().resource_path != FIELD: continue
		if field.get_instance_id() == _previous_field_instance: continue
		var region: Dictionary = field.get("_region")
		if String(region.get("id", "")) != id: continue
		if field.get("_field_loading_failed") == true: need(false, "FIELD_LOADING_FAILED:" + id); return null
		if field.get("_field_loading_complete") != true or field.get("_scene_rebuilding") == true: continue
		var loading: Node = root.get_node("LoadingManager")
		if loading.get("_transition_active") == true or loading.get("_external_active") == true: continue
		var quality: Dictionary = field.get_meta("scene_art_quality31b", {})
		if quality.get("ok") != true:
			if not String(host.call("get_debug_state").get("last_error", "")).is_empty(): need(false, "HOST_ATTACH_FAILED:" + id); return null
			continue
		var mini: Node = field.get("_world_travel_minimap")
		if ground and (not is_instance_valid(mini) or mini.call("get_debug_state").get("visual_cache_ready") != true): continue
		var player: Node = field.get("_player")
		if not is_instance_valid(player) or player.get("can_move") != true: continue
		await physics_frame; await RenderingServer.frame_post_draw
		return field
	need(false, "FINITE_30S_FIELD_BOUND:" + id); return null

func _flat_view_only(view: Node) -> bool:
	if view.get_script() != null: return false
	for child: Node in view.get_children():
		if not child is Polygon2D or child.get_script() != null or child.texture == null or child.get_child_count() != 0: return false
	return view.get_child_count() > 0

func _effective_z(source: CanvasItem) -> int:
	var total := 0
	var cursor: Node = source
	while cursor != null:
		if cursor is CanvasLayer: break
		if cursor is CanvasItem:
			var item: CanvasItem = cursor as CanvasItem
			total += item.z_index
			if not item.z_as_relative: break
		cursor = cursor.get_parent()
	return clampi(total, -4096, 4095)

func _ground04_details(view: Node, id: String) -> bool:
	var soil: Polygon2D = view.get_node_or_null("GroundQuality31b_CompactedFineSoil") as Polygon2D
	if soil == null or soil.texture == null or soil.texture.resource_path != "res://art/modules/miao_town_20261029f/ground.png" or soil.z_index != -1050 or not soil.z_as_relative: return false
	var original: Polygon2D = view.get_parent().get_node_or_null("RegionDecorativeUnderlay") as Polygon2D
	if original == null or _effective_z(original) >= _effective_z(soil): return false
	var paving_depths: Array[int] = []
	var garden_depths: Array[int] = []
	var grass_count := 0
	var route_count := 0
	var curbs := 0
	for child: Node in view.get_children():
		if child is Polygon2D and child != soil and not child.has_meta("continuous_source_edge"):
			if not child.z_as_relative or child.z_index != -1000 or _effective_z(soil) >= _effective_z(child): return false
			paving_depths.append(_effective_z(child))
		if not child is Polygon2D or not child.has_meta("continuous_source_edge"): continue
		curbs += 1
		if child.z_index != -999 or not child.z_as_relative or not child.material is ShaderMaterial or child.texture.resource_path != "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png": return false
		if _effective_z(child) <= _effective_z(soil): return false
		var material: ShaderMaterial = child.material as ShaderMaterial
		if material.shader == null or material.shader.resource_path != "res://build/luoyang_quality_20261101b_ground01/curb_transition.gdshader" or material.get_shader_parameter("dust_width") != 6.0: return false
		var sample: Texture2D = material.get_shader_parameter("soil_texture") as Texture2D
		if sample == null or sample.resource_path != soil.texture.resource_path: return false
	for sibling: Node in view.get_parent().get_children():
		if not sibling is Polygon2D or not sibling.visible or sibling.texture == null: continue
		var is_grass: bool = sibling.texture.resource_path == "res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg"
		var is_route: bool = sibling.z_index == -998 and sibling.texture.resource_path == "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
		if is_grass or is_route:
			if is_grass: grass_count += 1
			if is_route: route_count += 1
			garden_depths.append(_effective_z(sibling))
			for depth: int in paving_depths:
				if depth >= _effective_z(sibling): return false
	if paving_depths.is_empty() or (id == "luoyang_estate_region_27d" and (grass_count == 0 or route_count == 0)): return false
	records.append({"real_depths": {"old_underlay": _effective_z(original), "fine_soil": _effective_z(soil), "paving": paving_depths, "garden": garden_depths}, "region_id": id})
	return curbs > 0 and curbs <= 256

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	var path := OUTPUT + str(OS.get_process_id()) + "/" + name + ".png"
	if not need(image != null and image.get_size() == Vector2i(1920, 1080) and not FileAccess.file_exists(path), "NORMAL_UNALTERED_1920_IMAGE:" + name): return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path) == OK, "SAVE_NEW_EVIDENCE_IMAGE:" + name): return false
	records.append({"image": path, "sha256": FileAccess.get_sha256(path), "normal_camera": true}); return true

func finish() -> void:
	if finished: return
	finished = true
	for code: int in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = false; Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not first.is_empty(): need(first == _facts(), "INDEPENDENT_FROZEN_SOURCE_FIRST_FINAL")
	var path := OUTPUT + str(OS.get_process_id()) + "/quality_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: quit(2); return
	file.store_string(JSON.stringify({"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "input_ticks": input_ticks, "elapsed_ms": Time.get_ticks_msec() - began, "save_file_reads": 0, "save_writes": 0, "actor_camera_writes": 0, "public_near_setups_not_continuous_travel": true, "old_success_matrices_replayed": false, "host": host.call("get_debug_state") if is_instance_valid(host) else {}}, "\t")); file.close()
	print("[SceneArtQuality31b QA] ", checks, " checks / ", errors.size(), " failures; ", path)
	quit(0 if errors.is_empty() else 1)
