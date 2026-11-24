extends SceneTree
## Two actual NPC components only, not Field/city/population acceptance.
const PINS := {
	"res://build/luoyang_npc_scale_before_20261015_root01/npc_node.gd.source": "9da0e3d61185c45568071f40a4f2de4f1f1287a105fd66f4c5a9e162c3af3b72",
	"res://.godot/imported/npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png-c3750cc0d38b0d47dc64c37802336b81.ctex": "11ba2a082b78c197056adcbab63abca049fae9fda7ec10c9bf5610685099d046",
	"res://scripts/autoload/save_manager.gd": "67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://scripts/field/npc_node.gd": "67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea",
	"res://shaders/interaction_outline.gdshader": "e7dfbe9bae6b04a78a8fe78917806fe0baaedd8b44438c1a7a6fdd99bbcb3f39",
	"res://scripts/autoload/platform_bridge.gd": "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://art/characters/npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png.import": "5a0566ebcea25a8f7c9e99fdd9abc1b0198aa0420905edce0382a4d8c47e116d",
	"res://.godot/imported/npc_escort_guard_idle_down_4f_v2_runtime.png-9bed8ac8c0ba413abb599cd7da84ee31.ctex": "6907aa51f29afde180db2c4e80044e44059b6f75f935b1c6d9b2d0065fc27d79",
	"res://art/characters/npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png": "933bb04d48c13135a0674f760fb479315617d37a15117f92a20965dda44d8e7e",
	"res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png": "03695af14571f765c9f8721af4d668892216cca6183ebf9ffc9333606da21fa8",
	"res://scenes/npc_node.tscn": "fd497082cbb1c7e2028cb6063074aeb066f81d4c8505d35f5428bb0607ca4191",
	"res://data/scenes/ch4_s3_luoyang_market.tres": "2df5059ab647d956e7b37c8bb5f7d0d568d575deac7931b3ccadb5451c6fe8f6",
	"res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png.import": "1e6800f8894794d3188c43feb5e1a44f9c1c0494a18371b3b0ff7999c25636d3"
}
const NODE_PATH := "res://scripts/field/npc_node.gd"
const OLD_PATH := "res://build/luoyang_npc_scale_before_20261015_root01/npc_node.gd.source"
const PACKED_PATH := "res://scenes/npc_node.tscn"
const OLD_LINE := 'const SMALL_ADULT_FAMILIES := ["npc_zhuwei_gate_guard_", "npc_zhuwei_inn_waiter_", "npc_escort_guard_"]'
const NEW_LINE := 'const SMALL_ADULT_FAMILIES := ["npc_zhuwei_gate_guard_", "npc_zhuwei_inn_waiter_", "npc_escort_guard_", "npc_linxi_martial_hall_master_"]'
const BUDGET_MS := 30000
var started: int
var failures: Array[String] = []
var checks := 0
var records: Array[Dictionary] = []
var first: Dictionary = {}
var save_before: Dictionary = {}
var output := ""
var container: Node2D

func _initialize() -> void:
	started = Time.get_ticks_msec()
	_run.call_deferred()

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("[NPC ADULT KEY] " + label)
	return ok

func _fact(path: String) -> Dictionary:
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ) if exists else null
	return {"exists": exists, "sha256": FileAccess.get_sha256(path) if exists else "ABSENT", "bytes": file.get_length() if file != null else 0, "mtime_seconds": FileAccess.get_modified_time(path) if exists else 0}

func _saves() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path := "user://save_%d.json%s" % [slot, suffix]
			result[path] = _fact(path)
	return result

func _values(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x, value.y]
	if value is Rect2 or value is Rect2i: return [_values(value.position), _values(value.size)]
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _values(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_values(item))
		return result
	return value

func _role(role: String, path: String, authored: float, source_heights: Array, at: Vector2) -> void:
	var raw := Image.load_from_file(path)
	var imported := ResourceLoader.load(path, "Texture2D") as Texture2D
	var image := imported.get_image() if imported != null else null
	if not _check(raw != null and image != null and raw.get_size() == Vector2i(640, 160) and image.get_size() == raw.get_size(), role + " exact four160-square strip"):
		return
	var bounds: Array[Rect2i] = []
	for frame in 4:
		var source_bounds := raw.get_region(Rect2i(frame * 160, 0, 160, 160)).get_used_rect()
		var actual_bounds := image.get_region(Rect2i(frame * 160, 0, 160, 160)).get_used_rect()
		_check(source_bounds == actual_bounds and source_bounds.size.y == source_heights[frame], role + " actual imported alpha>0 frame" + str(frame))
		bounds.append(actual_bounds)
	var packed := ResourceLoader.load(PACKED_PATH) as PackedScene
	var npc := packed.instantiate() as NPCNode if packed != null else null
	if not _check(npc != null, role + " actual production packed NPC instance"):
		return
	npc.npc_id = role
	npc.sprite_path = path
	npc.sprite_scale = authored
	npc.position = at
	npc.movement_mode = "idle"
	container.add_child(npc)
	npc.set_process(false)
	await process_frame
	_check(npc.get_script().resource_path == NODE_PATH and bool(npc.get("_calibrate_adult_body")) and npc.sprite.hframes == 4, role + " actual new-family calibration selected")
	var expected_scale: Vector2 = Vector2.ONE * authored * (140.0 / float(bounds[0].size.y))
	var old_expected_scale: Vector2 = Vector2.ONE * authored if role == "spar_luoyang_blademaster" else expected_scale
	_check(expected_scale.y > old_expected_scale.y if role == "spar_luoyang_blademaster" else expected_scale == old_expected_scale, role + " only newly selected family grows; existing patrol visual unchanged")
	var body: StaticBody2D = npc.get("_body_collider") as StaticBody2D
	var shape: CollisionShape2D = body.get_child(0) as CollisionShape2D if body != null and body.get_child_count() == 1 else null
	if not _check(shape != null and shape.shape is RectangleShape2D, role + " real rectangular original collider"):
		npc.queue_free(); return
	var rectangle := shape.shape as RectangleShape2D
	var old_size := Vector2(160.0 * authored * .14, 160.0 * authored * .18)
	var old_shape_position := Vector2(0.0, 160.0 * authored * .12)
	var authored_legacy_foot: float = 160.0 * authored * .45
	var expected_legacy_foot := Vector2(at.x, at.y + authored_legacy_foot)
	_check(npc.sprite_scale == authored and npc.sprite.scale == expected_scale, role + " unchanged authored scale and exact native visible calibration")
	_check(rectangle.size == old_size and shape.position == old_shape_position and body.position == Vector2.ZERO and body.collision_layer == 1 and body.collision_mask == 0, role + " legacy original rectangle size/local/global placement unchanged")
	_check(Vector2(at.x, float(npc.call("get_depth_sort_y"))) == expected_legacy_foot, role + " original authored legacy foot native identity")
	var first_legacy_body_transform: Transform2D = shape.global_transform
	var frames: Array[Dictionary] = []
	npc.set_ground_anchored(true)
	await physics_frame
	await process_frame
	_check(rectangle.size == old_size and shape.position == old_shape_position and body.position == -old_shape_position and shape.global_position == at, role + " ground-anchor collider stays original size and same authored world foot")
	for frame in 4:
		npc.sprite.frame = frame
		npc.set_ground_anchored(true)
		var visible_height: float = float(bounds[frame].size.y) * npc.sprite.scale.y
		var expected_height: float = float(bounds[frame].size.y) * expected_scale.y
		var visible_foot := npc.sprite.to_global(Vector2(0.0, float(bounds[frame].end.y) - 80.0))
		_check(visible_height == expected_height and npc.sprite.scale == expected_scale and Vector2(at.x, float(npc.call("get_depth_sort_y"))) == at and visible_foot == at, role + " frame" + str(frame) + " visible height/source foot exact native")
		_check(rectangle.size == old_size and shape.position == old_shape_position and body.position == -old_shape_position and shape.global_position == at, role + " frame" + str(frame) + " no physical enlargement or drift")
		frames.append({"frame": frame, "source_alpha_gt0_bounds": bounds[frame], "source_visible_height": bounds[frame].size.y, "sprite_scale": npc.sprite.scale, "visible_world_height": visible_height, "nominal_first_frame_target": 140.0 * authored, "visible_world_foot": visible_foot, "raw_depth_foot": npc.call("get_depth_sort_y"), "collider_size": rectangle.size, "collider_local_position": shape.position, "body_position": body.position, "collider_world_position": shape.global_position})
	npc.set_ground_anchored(false)
	_check(rectangle.size == old_size and shape.position == old_shape_position and body.position == Vector2.ZERO and shape.global_transform == first_legacy_body_transform and Vector2(at.x, float(npc.call("get_depth_sort_y"))) == expected_legacy_foot, role + " legacy restore exact original foot and complete collider transform")
	records.append({"role": role, "source_path": path, "authored_scale": authored, "old_native_sprite_scale": old_expected_scale, "old_native_visible_height": float(bounds[0].size.y) * old_expected_scale.y, "new_nominal_visible_height": 140.0 * authored, "old_expected_physical_size": old_size, "legacy_world_foot": expected_legacy_foot, "ground_world_foot": at, "frames": frames})
	npc.queue_free()
	await process_frame

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "Checkpoint suspension before first await")
	save_before = _saves()
	var active_slot: int = int(root.get_node("SaveManager").get("active_slot"))
	output = "res://build/luoyang_npc_adult_key_20261015/%d_%d/" % [OS.get_process_id(), started]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "Unique bounded NPC-only output")
	for path: String in PINS:
		first[path] = _fact(path)
		_check(first[path].exists and first[path].sha256 == PINS[path], "Exact frozen current/old code or asset " + path)
	first[get_script().resource_path] = _fact(get_script().resource_path)
	var old := FileAccess.get_file_as_string(OLD_PATH)
	var current := FileAccess.get_file_as_string(NODE_PATH)
	_check(old.count(OLD_LINE) == 1 and current.count(NEW_LINE) == 1 and old.replace(OLD_LINE, NEW_LINE) == current, "Only one family-list line changes; all physics/anchor/animation source identical")
	container = Node2D.new()
	container.name = "OwnedTwoNPCComponentKey"
	root.add_child(container)
	if failures.is_empty():
		await _role("spar_luoyang_blademaster", "res://art/characters/npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png", .82, [120, 120, 120, 120], Vector2(500, 500))
		await _role("spar_luoyang_patrol", "res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png", .96, [127, 126, 127, 126], Vector2(800, 500))
	container.queue_free(); container = null
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _fact(path)
	_check(first == last and _saves() == save_before and root.get_node("SaveManager").get("active_slot") == active_slot and bridge.call("is_checkpoint_saves_suspended") == true, "All source/player15/slot/checkpoint facts retained; ROOT exactticks guard required")
	_check(records.size() == 2 and Time.get_ticks_msec() - started < BUDGET_MS, "Exactly two NPC/four frames each; shared30 seconds")
	var report := {"scope": "TWO_ACTUAL_NPC_COMPONENTS_VISIBLE_ALPHA_NATIVE_SCALE_AND_ORIGINAL_RECTANGLE_ONLY", "passed": failures.is_empty(), "checks": checks, "failures": failures.duplicate(), "records": records, "source_before": first, "source_after": last, "players_before": save_before, "players_after": _saves(), "elapsed_ms": Time.get_ticks_msec() - started, "budget_ms": BUDGET_MS, "Field_loaded": false, "city_or_route_or_BGM_credit": false, "animation_clock_advance_credit": false, "frame_selection": "Explicit four actual source frames, not a claim of elapsed idle playback", "comparison_domain": "Exact native Vector2 scale/feet/collider; source PNG alpha>0 height; no epsilon", "fresh_ROOT_player15_exactticks_guard_required": true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file == null: push_error("Cannot save bounded NPC-only report"); quit(1); return
	file.store_string(JSON.stringify(_values(report), "\t")); file.flush(); file.close()
	print("NPC_ADULT_KEY_RESULT=", output + "result.json passed=", report.passed, " checks=", checks, " failures=", failures.size(), " elapsed_ms=", report.elapsed_ms)
	quit(0 if failures.is_empty() else 1)
