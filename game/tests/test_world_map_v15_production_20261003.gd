extends SceneTree
## NEW expanded-world suite. Original v14 tests/approval remain read-only.
## SOURCE WIP: every unfinished mandatory phase fails closed, never grants PASS.
const RAW_ORACLE := preload("res://tests/helpers/v15_raw_world_oracle.gd")
const INPUT_DRIVER := preload("res://tests/helpers/v15_input_driver.gd")
const GEOMETRY_ORACLE := preload("res://tests/helpers/v15_geometry_oracle.gd")
const OVERVIEW_PROBE := preload("res://tests/helpers/v15_overview_input_probe.gd")
const BATTLE_PROBE := preload("res://tests/helpers/v15_battle_return_probe.gd")
const NORMAL_NPC_PROBE := preload("res://tests/helpers/v15_normal_npc_depth_probe.gd")
const ISOLATED_SAVES_PATH := "res://tests/helpers/v15_isolated_save_manager.gd"
const MIGRATION_SUBJECT := preload("res://scripts/world/world_map_v15_contract.gd")
const PHASES := ["raw", "portal", "depth", "migration", "full"]
const SIZE := Vector2(12288, 8192)
const CHUNK_SIZE := Vector2i(1536, 1024)
const SCENE_PATH := "res://data/scenes/world_map_jianghu_v15.tres"
const SCENE_ID := &"world_map_jianghu_v15"
const SOURCE_PATH := "res://art/maps/world_map_v15/source_contract.json"
const MANIFEST_PATH := "res://art/maps/world_map_v15/manifest.json"
const CORE_IDS := ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue"]
const NEW_SECT_IDS := ["huashan", "gufeng", "wudang", "lingyue"]
const DESTINATIONS := {
	"yanmen_pass": "openworld_yanmen_pass", "huashan": "openworld_huashan_forecourt", "wudang": "openworld_wudang_gate", "gufeng": "ch5_s1_relief_road", "lingyue": "ch2_s4_lingyue_gate",
	"bianzhou": "openworld_bianzhou_city", "linxi_village": "linxi_village_scrollmap", "luoyang": "ch4_s0_luoyang_gate", "xiangzhou": "openworld_xiangzhou_city", "east_sea_port": "openworld_east_sea_port", "bailu_ferry": "openworld_bailu_ferry",
	"zhuwei_village": "ch1_s2_qingfeng", "qinghe_town": "openworld_qinghe_town", "jinling": "openworld_jinling_city", "mingwu": "ch7_s2_mingwu_tea_town", "lieyun_valley": "ch7_s1_lieyun_valley_ferry"}
var checks := 0
var failures := 0
var completed_phases: Array[String] = []
var incomplete_phases: Array[String] = []
var world: SceneScript
var source: Dictionary
var manifest: Dictionary
var oracle: RefCounted
var field: Node
var before_saves: Dictionary
var prior_navigation: Dictionary
var prior_active: StringName
var prior_slot := -1
var output := ""
var route_centers := 0
var portals_by_id: Dictionary = {}
var requested_phase := "full"
var requested_portal := ""
var requested_mode := "all"
var input_driver: RefCounted
var runtime_started := false
var actual_portal_roundtrips: Array[Dictionary] = []
var ordinary_images: Array[Dictionary] = []
var ordinary_blockers: Array[Rect2] = []
var ordinary_size := Vector2.ZERO
var alpha_oracle: RefCounted
var isolated_slots: Node
var isolated_directory := ""

func _default_phase() -> String:
	return "full"

func _parse_phase() -> bool:
	requested_phase = _default_phase()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-phase="): requested_phase = argument.trim_prefix("--qa-phase=")
		elif argument.begins_with("--portal-id="): requested_portal = argument.trim_prefix("--portal-id=")
		elif argument.begins_with("--portal-mode="): requested_mode = argument.trim_prefix("--portal-mode=")
	_check(requested_phase in PHASES, "explicit known phase; unknown request cannot run another phase")
	_check(requested_portal.is_empty() or DESTINATIONS.has(requested_portal), "optional portal filter is exact unchanged target ID")
	_check(requested_mode in ["all", "space", "door_mouse", "arrow"], "optional device filter is an explicit real input mode")
	_check(requested_phase != "full" or (requested_portal.is_empty() and requested_mode == "all"), "FULL cannot silently filter out portals or input modes")
	return failures == 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[WorldV15 FAIL] " + label)

func _json(path: String) -> Dictionary:
	_check(FileAccess.file_exists(path), "required current v15 JSON exists: " + path)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	_check(value is Dictionary, "required JSON parses as object: " + path)
	return value as Dictionary if value is Dictionary else {}

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _actual_saves() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot, suffix]
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
	var directory := DirAccess.open("user://")
	_check(directory != null, "normal player save directory is readable without writes")
	if directory != null:
		for filename: String in directory.get_files():
			if filename.begins_with("save"):
				var path: String = "user://" + filename
				result[path] = FileAccess.get_sha256(path)
	return result

func _run() -> void:
	var phase_valid: bool = _parse_phase()
	output = "res://build/world_map_v15_qa/%s_%d/" % [requested_phase if phase_valid else "invalid_request", Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique v15 QA evidence output")
	before_saves = _actual_saves()
	var router := root.get_node("SceneRouter")
	prior_navigation = router.call("get_navigation_state").duplicate(true)
	prior_active = StringName(router.get("_active_world_map_scene"))
	prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	if not phase_valid:
		await _finish()
		return
	manifest = _json(MANIFEST_PATH)
	source = _json(SOURCE_PATH)
	_check("--candidate-before-cutover" in OS.get_cmdline_user_args(), "current v15 stage explicitly requests candidate, never mutates canonical")
	_check(ResourceLoader.exists(SCENE_PATH), "published v15 production candidate exists")
	# Final owner status/compiler schema will be explicitly bound after SOURCE_READY.
	if failures > 0:
		await _finish()
		return
	world = load(SCENE_PATH) as SceneScript
	_check(world != null and world.scene_id == SCENE_ID and world.map_layout != null and world.map_layout.schema_version == 15 and world.map_layout.design_size == Vector2i(SIZE), "actual candidate ID/layout/schema/full logical size")
	if failures > 0:
		await _finish()
		return
	oracle = RAW_ORACLE.new()
	_check(oracle.call("configure", world.map_layout), "independent original tile/margin/full17 oracle is complete: " + str(oracle.get("errors")))
	_static_portals_and_spacing()
	if requested_phase in ["raw", "full"]:
		_route_fullfoot_checks()
		_neighbor_geometry_checks()
	if requested_phase in ["portal", "full"]:
		await _portal_runtime_phase()
		await _door_negative_phase()
	if requested_phase in ["migration", "full"]:
		_migration_prepare_phase()
		await _migration_isolated_save_phase()
		await _gameplay_return_phase()
	if requested_phase in ["depth", "full"]:
		await _depth_runtime_phase()
		await _normal_npc_patrol_phase()
	# These are NOT waived: source implementation continues when final source
	# contracts are available; this skeleton cannot claim complete acceptance.
	var unfinished: Array[String] = []
	if requested_phase in ["raw", "full"]: unfinished.append_array(["ready_shader_and_frozen_catalog", "64_global_capture_pixel_authority", "112_neighbor_actual_connectivity", "dual_river_snow_bamboo_swamp_mesh_nav", "model_body_alpha_support_current_frame"])
	if requested_phase in ["depth", "full"]: unfinished.append("all_model_current_frame_alpha_and_ordinary_depth_cleanup")
	if requested_phase in ["migration", "full"]: unfinished.append("actual_nonportal_and_indoor_historic_saved_contexts")
	if requested_phase == "full": unfinished.append("GPU_all_world_visual_review")
	for phase: String in unfinished:
		incomplete_phases.append(phase)
		_check(false, "SOURCE_WIP required v15 phase not yet implemented/executed: " + phase)
	await _finish()

func _static_portals_and_spacing() -> void:
	var portals: Array = world.map_layout.portals
	_check(portals.size() == 16, "exact sixteen existing target entrances preserved")
	for portal: Dictionary in portals:
		var id: String = portal.get("id", "")
		_check(DESTINATIONS.has(id) and not portals_by_id.has(id), "unique unchanged portal ID: " + id)
		_check(String(portal.get("target_scene", "")) == String(DESTINATIONS.get(id, "INVALID")), "actual unchanged destination: " + id)
		var point := _point(portal.get("pos")) * SIZE
		_check(point.is_finite() and point.x >= 0 and point.y >= 0 and point.x < SIZE.x and point.y < SIZE.y, "finite in-domain portal foot: " + id)
		if oracle.get("valid"): _check(oracle.call("clear", point), "independent complete17 portal landing is clear: %s %s" % [id, oracle.call("foot_evidence", point)])
		portals_by_id[id] = portal
	var landmarks: Dictionary = {}
	for object: Dictionary in world.map_layout.visual_objects:
		var id: String = object.get("portal_id", "")
		if id in CORE_IDS:
			_check(not landmarks.has(id), "unique actual central landmark, not arbitrary portal marker: " + id)
			landmarks[id] = object
	for first in CORE_IDS.size():
		var id: String = CORE_IDS[first]
		_check(landmarks.has(id), "core city/sect owns a real runtime landmark: " + id)
		if not landmarks.has(id): continue
		var a := _point(landmarks[id].get("pos")) * SIZE
		for second in range(first + 1, CORE_IDS.size()):
			var other: String = CORE_IDS[second]
			if not landmarks.has(other): continue
			var b := _point(landmarks[other].get("pos")) * SIZE
			_check(a.distance_to(b) >= 3072, "core actual landmark logical spacing >=3072 (not screen pixels): %s/%s actual=%.6f" % [id, other, a.distance_to(b)])
	completed_phases.append("static_16_targets_and_8_core_logical_spacing")

func _route_fullfoot_checks() -> void:
	if not oracle.get("valid"): return
	var routes: Array = world.map_layout.travel_routes
	_check(not routes.is_empty(), "actual production candidate owns continuous route contracts")
	for route: Dictionary in routes:
		var points: Variant = route.get("points")
		_check(points is PackedVector2Array or points is Array, "route actual point array: " + String(route.get("id", "")))
		if not (points is PackedVector2Array or points is Array): continue
		_check(points.size() >= 2, "route has endpoints; no unsampled terminal")
		for index in range(1, points.size()):
			var a := _point(points[index - 1]) * SIZE
			var b := _point(points[index]) * SIZE
			var evidence: Dictionary = oracle.call("segment_evidence", a, b)
			_check(bool(evidence.clear), "actual route entire <=4px/17foot segment: %s #%d %s" % [String(route.get("id", "")), index, evidence])
			if evidence.clear: route_centers += int(evidence.centers)
	completed_phases.append("actual_route_entire_4px_full17")

func _neighbor_geometry_checks() -> void:
	# 64 chunks imply 56 vertical + 56 horizontal internal edges. This does NOT
	# claim all are open: current source passage/blocked contracts decide that.
	var edges: Array[Dictionary] = []
	for row in 8:
		for col in 8:
			if col < 7: edges.append({"a": [row, col], "b": [row, col + 1], "axis": "vertical", "line_px": (col + 1) * CHUNK_SIZE.x})
			if row < 7: edges.append({"a": [row, col], "b": [row + 1, col], "axis": "horizontal", "line_px": (row + 1) * CHUNK_SIZE.y})
	_check(edges.size() == 112, "independently enumerated complete 112 internal adjacency boundaries")
	_check(_write_json("expected_112_neighbors.json", {"scope": "SOURCE_ADJACENCY_ENUMERATION_NOT_RUNTIME_PROOF", "edges": edges}), "expected adjacency evidence persisted failclosed")
	completed_phases.append("112_adjacencies_enumerated_not_open_pass")

func _source_door(id: String) -> Dictionary:
	var found: Dictionary = {}
	var entries: Variant = source.get("portals")
	_check(entries is Array, "current source has actual portal measurements, not an authoring plan")
	if not entries is Array: return found
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == id:
			_check(found.is_empty(), "source door ID is unique: " + id)
			found = entry
	var foot := _point(found.get("door_foot_px"))
	var uv := _point(found.get("source_doorstep_uv"))
	_check(found.get("doorstep_visual_review_status") == "APPROVED", "doorstep source PNG/UV explicitly reviewed, never PENDING: " + id)
	_check(not found.is_empty() and foot.is_finite() and uv.is_finite() and uv.x >= 0 and uv.y >= 0 and uv.x <= 1 and uv.y <= 1, "measured actual source doorway UV and projected door foot: " + id)
	return found if foot.is_finite() and uv.is_finite() else {}

func _independent_local_repair(point: Vector2) -> Variant:
	if bool(oracle.call("clear", point * SIZE)): return point
	if not point.is_finite(): return null
	var origin: Vector2 = point.clamp(Vector2.ZERO, Vector2.ONE) * SIZE
	for radius in range(4, 197, 4):
		var count: int = maxi(16, ceili(TAU * radius / 6.0))
		for index in count:
			var candidate: Vector2 = origin + Vector2(cos(TAU * index / count), sin(TAU * index / count)) * radius
			if bool(oracle.call("clear", candidate)): return candidate / SIZE
	return null

func _independent_historic_mapping(old: SceneScript, point: Vector2) -> Dictionary:
	# Read immutable old/current gateways, not the production migration's debug
	# claim. Free coordinates must demonstrably retain local geography whenever
	# its <=196px repair domain has complete feet; gateway fallback is separate.
	var anchors: Array[Dictionary] = []
	var old_size := Vector2(old.map_layout.design_size)
	for previous: Dictionary in old.map_layout.portals:
		var id: String = previous.get("id", "")
		if not portals_by_id.has(id): continue
		var old_pos: Vector2 = previous.get("pos", Vector2(INF, INF))
		var new_pos: Vector2 = portals_by_id[id].get("pos", Vector2(INF, INF))
		var distance: float = ((point - old_pos) * old_size).length()
		if distance <= 64: return {"expected": _independent_local_repair(new_pos), "kind": "paired_gateway", "id": id}
		anchors.append({"distance": distance, "delta": new_pos - old_pos, "new_pos": new_pos, "id": id})
	anchors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	var delta := Vector2.ZERO
	var total := 0.0
	for index in mini(4, anchors.size()):
		var weight: float = 1.0 / maxf(1.0, float(anchors[index].distance) * float(anchors[index].distance))
		delta += (anchors[index].delta as Vector2) * weight
		total += weight
	if total <= 0: return {"expected": null, "kind": "no_source_pairs"}
	var mapped: Vector2 = point + delta / total
	var repaired: Variant = _independent_local_repair(mapped)
	if repaired is Vector2: return {"expected": repaired, "kind": "independent_local_free_mapping", "mapped": mapped}
	for anchor: Dictionary in anchors:
		if bool(oracle.call("clear", (anchor.new_pos as Vector2) * SIZE)):
			return {"expected": anchor.new_pos, "kind": "historic_gateway_fallback", "mapped": mapped, "id": anchor.id}
	return {"expected": null, "kind": "geography_unrepairable", "mapped": mapped}

func _migration_prepare_phase() -> void:
	if not bool(oracle.get("valid")): return
	var router: Node = root.get_node("SceneRouter")
	var navigation_before: Dictionary = router.call("get_navigation_state").duplicate(true)
	var active_before := StringName(router.get("_active_world_map_scene"))
	var evidence: Array[Dictionary] = []
	var old_paths: Dictionary = {12: "res://data/maps/world_map_jianghu_legacy_v12_scene.tres", 13: "res://data/scenes/world_map_jianghu_v13_staging.tres", 14: "res://data/scenes/world_map_jianghu_v14.tres"}
	for version: int in [12, 13, 14]:
		var path: String = old_paths[version]
		_check(ResourceLoader.exists(path), "historic coordinate source is real immutable resource v%d" % version)
		if not ResourceLoader.exists(path): continue
		var old: SceneScript = load(path) as SceneScript
		_check(old != null and old.map_layout != null, "historic map carries actual portal anchor coordinates")
		if old == null or old.map_layout == null: continue
		for previous: Dictionary in old.map_layout.portals:
			var id: String = previous.get("id", "")
			if not portals_by_id.has(id): continue
			var pos: Vector2 = previous.get("pos", Vector2(INF, INF))
			var paired: Dictionary = _independent_historic_mapping(old, pos)
			var target_scene: String = DESTINATIONS.get(id, "")
			var inner := Vector2(.25, .75)
			var data: Dictionary = {"current_field": String(old.scene_id), "current_field_spawn": [pos.x, pos.y], "world_map_version": version, "portal_return_spawns": {target_scene + "->" + String(old.scene_id): [pos.x, pos.y], String(old.scene_id) + "->" + target_scene: [inner.x, inner.y]}}
			var prepared: Dictionary = router.call("prepare_v15_navigation", data, &"", SCENE_ID)
			_check(prepared.get("world_map_version") == 15 and prepared.get("current_field_id") == SCENE_ID, "real pure router migration selects version15 world: v%d/%s" % [version, id])
			_check(prepared.get("current_field_spawn") == paired.get("expected"), "old paired portal migrates to independently matched exact new door")
			var returns: Dictionary = prepared.get("portal_return_spawns", {})
			_check(returns.get(target_scene + "->" + String(SCENE_ID)) == paired.get("expected"), "world-side remembered portal spawn remaps to same ID")
			_check(returns.get(String(SCENE_ID) + "->" + target_scene) == inner, "indoor remembered coordinate only changes route key, never world scaling")
			_check(router.call("get_navigation_state") == navigation_before and StringName(router.get("_active_world_map_scene")) == active_before, "prepare phase cannot mutate managed navigation")
			evidence.append({"source_version": version, "id": id, "source_path": path, "source_sha256": FileAccess.get_sha256(path), "kind": paired.kind, "prepared_spawn": prepared.get("current_field_spawn")})
		var nonportal_positives := 0
		if not _configure_ordinary(old): continue
		for y in range(1, 8):
			for x in range(1, 8):
				var pos := Vector2(float(x) / 8, float(y) / 8)
				if not _ordinary_static_clear(pos * Vector2(old.map_layout.design_size)): continue
				var expected: Dictionary = _independent_historic_mapping(old, pos)
				if expected.kind != "independent_local_free_mapping": continue
				var station: Vector2 = expected.expected
				var nearest: float = INF
				for current: Dictionary in world.map_layout.portals: nearest = minf(nearest, ((station - (current.pos as Vector2)) * SIZE).length())
				if nearest <= 64: continue
				var result: Variant = MIGRATION_SUBJECT.migrate_spawn(pos, version, world)
				_check(result == station and bool(oracle.call("clear", station * SIZE)), "free old coordinate preserves independent local geography and complete feet, not unconditional portal snap: v%d" % version)
				var again: Variant = MIGRATION_SUBJECT.migrate_spawn(station, 15, world)
				_check(again == station, "version15 free-coordinate migration is exact one-time identity")
				evidence.append({"source_version": version, "kind": expected.kind, "old_point": [pos.x, pos.y], "mapped_point": [station.x, station.y], "nearest_portal_distance_px": nearest})
				nonportal_positives += 1
				if nonportal_positives >= 3: break
			if nonportal_positives >= 3: break
		_check(nonportal_positives >= 3, "each old coordinate space has >=3 genuinely free, safe, non-portal migration witnesses")
	for invalid_version: int in [-1, 0, 16, 99]:
		_check(MIGRATION_SUBJECT.migrate_spawn(Vector2(.5, .5), invalid_version, world) == null, "unknown source version refused, never silently interpreted as legacy12")
	_check(router.call("get_navigation_state") == navigation_before and before_saves == _actual_saves(), "pure migration cases and negative versions leave navigation/player files unchanged")
	_check(_write_json("migration_prepare.json", {"scope": "PURE_MIGRATION_NOT_SAVE_LOAD_OR_BATTLE_RETURN", "records": evidence, "actual_source_sha256": FileAccess.get_sha256("res://scripts/world/world_map_v15_contract.gd")}), "independent migration expectation evidence persisted")
	completed_phases.append("pure_12_13_14_paired_free_identity_unknown_version_migration")

func _write_checked_isolated_slot(slot: int, data: Dictionary) -> bool:
	if not is_instance_valid(isolated_slots): return false
	var path: String = isolated_slots.call("slot_path", slot)
	if isolated_directory.is_empty() or not path.begins_with(isolated_directory + "/") or not path.begins_with("user://world_map_v15_qa/"): return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	file = null
	return error == OK and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(JSON.stringify(data))

func _migration_isolated_save_phase() -> void:
	if not bool(oracle.get("valid")): return
	_ensure_runtime_fixture()
	isolated_directory = "user://world_map_v15_qa/run_%d" % Time.get_ticks_usec()
	# SaveManager references autoload names: parse its inherited script only
	# after the normal SceneTree has registered those real singletons.
	var isolated_script: Script = load(ISOLATED_SAVES_PATH) as Script
	_check(isolated_script != null and isolated_script.can_instantiate(), "real inherited SaveManager loads after singleton registration")
	if isolated_script == null or not isolated_script.can_instantiate(): return
	isolated_slots = isolated_script.new() as Node
	_check(isolated_slots != null, "isolated real SaveManager instance is available")
	if isolated_slots == null: return
	_check(bool(isolated_slots.call("configure_directory", isolated_directory)), "unique real SaveManager primary/bak/tmp paths remain inside test directory")
	if String(isolated_slots.get("isolated_dir")) != isolated_directory: return
	root.add_child(isolated_slots)
	for slot in 5:
		_check(String(isolated_slots.call("slot_path", slot)).begins_with(isolated_directory + "/") and String(isolated_slots.call("slot_backup_path", slot)).begins_with(isolated_directory + "/"), "all five actual slot+backup paths are isolated")
	_check(bool(isolated_slots.call("save_to_slot", 0)), "real current domain/state serialization writes only isolated template slot")
	var template: Dictionary = _json(String(isolated_slots.call("slot_path", 0)))
	if template.is_empty(): return
	var old_paths: Dictionary = {12: "res://data/maps/world_map_jianghu_legacy_v12_scene.tres", 13: "res://data/scenes/world_map_jianghu_v13_staging.tres", 14: "res://data/scenes/world_map_jianghu_v14.tres"}
	var records: Array[Dictionary] = []
	var router: Node = root.get_node("SceneRouter")
	var expected_cases := 0
	for version: int in [12, 13, 14]:
		var old: SceneScript = load(old_paths[version]) as SceneScript
		if old == null or old.map_layout == null:
			_check(false, "actual historical save source resource available")
			continue
		for previous: Dictionary in old.map_layout.portals:
			var id: String = previous.get("id", "")
			if not portals_by_id.has(id): continue
			expected_cases += 1
			var point: Vector2 = previous.get("pos", Vector2(INF, INF))
			var expected: Dictionary = _independent_historic_mapping(old, point)
			var data: Dictionary = template.duplicate(true)
			data["current_field"] = String(old.scene_id)
			data["navigation"] = {"current_field": String(old.scene_id), "current_field_spawn": [point.x, point.y], "portal_return_spawns": {}}
			# Test missing-version inference independently for candidate IDs; explicit
			# v12 also covers canonical legacy evidence without reading mutated art.
			if version == 12: data.navigation["world_map_version"] = 12
			_check(_write_checked_isolated_slot(0, data), "historic coordinate JSON checked persistence in isolated slot")
			var preview: Variant = isolated_slots.call("get_save_field_id", 0, SCENE_ID)
			_check(preview == SCENE_ID, "actual save preview resolves v15 candidate without applying domain data")
			var loaded: bool = isolated_slots.call("load_from_slot", 0, SCENE_ID)
			_check(loaded, "real SaveManager historic coordinate load succeeds: v%d/%s" % [version, id])
			if not loaded: continue
			var navigation: Dictionary = router.call("get_navigation_state")
			_check(navigation.get("world_map_version") == 15 and navigation.get("current_field") == String(SCENE_ID), "actual loaded managed navigation is new world15")
			var actual: Vector2 = _point(navigation.get("current_field_spawn"))
			_check(actual == expected.get("expected") and bool(oracle.call("clear", actual * SIZE)), "loaded historic slot exactly matches independent paired geometry/full17")
			router.call("resume_current_field")
			if not await _wait_field(SCENE_ID) or not await _normal_intro(): continue
			var player: Node2D = field.get("_player") as Node2D
			_check(player.position.distance_to(actual * SIZE) < .02 and bool(oracle.call("clear", player.position)), "real production Field receives migrated slot birth, not preview-only success")
			_check(bool(isolated_slots.call("save_to_slot", 1)), "actual upgraded state persists in second isolated slot")
			var saved: Dictionary = _json(String(isolated_slots.call("slot_path", 1)))
			_check(saved.get("version") == 14 and (saved.get("navigation", {}) as Dictionary).get("world_map_version") == 15, "SaveManager schema stays14 while world coordinate space is15")
			_check(bool(isolated_slots.call("load_from_slot", 1, SCENE_ID)), "upgraded isolated slot reads via same real SaveManager")
			var twice: Dictionary = router.call("get_navigation_state")
			_check(_point(twice.get("current_field_spawn")) == _point((saved.get("navigation", {}) as Dictionary).get("current_field_spawn")), "explicit world15 reread does not migrate coordinates a second time")
			records.append({"old_version": version, "id": id, "old_source_path": old_paths[version], "old_source_sha256": FileAccess.get_sha256(old_paths[version]), "actual_slot_birth": [actual.x, actual.y], "actual_field_birth_px": [player.position.x, player.position.y], "isolated_slot_sha256": FileAccess.get_sha256(String(isolated_slots.call("slot_path", 1)))})
	_check(records.size() == expected_cases and expected_cases == 48, "all3 historic versions x16 gateway slots actually load/spawn and reread")
	_check(before_saves == _actual_saves() and int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "isolated migration does not alter normal manager slot or player files")
	_check(_write_json("isolated_migration_loads.json", {"scope": "ACTUAL48_SAVE_LOAD_FIELD_SPAWN_NOT_BATTLE_OR_MENU_CONTINUE", "isolated_directory": isolated_directory, "records": records}), "actual isolation/load/spawn history checked persistence")
	if records.size() == 48: completed_phases.append("actual48_historic_isolated_save_load_Field_birth_and15_reread")

func _open_owned_world_fixture(point: Vector2) -> bool:
	_check(point.is_finite() and bool(oracle.call("clear", point)), "new runtime category begins at independently safe v15 fixture point")
	if not point.is_finite() or not bool(oracle.call("clear", point)): return false
	_ensure_runtime_fixture()
	root.get_node("SceneRouter").call("go_field_smart", SCENE_ID, point / SIZE, "", 15)
	if not await _wait_field(SCENE_ID) or not await _normal_intro(): return false
	_check(root.get_node("SceneRouter").call("get_current_field_id") == SCENE_ID and current_scene == field, "normal authored intro does not leave a stale fixture Field")
	if root.get_node("SceneRouter").call("get_current_field_id") != SCENE_ID or not is_instance_valid(field) or current_scene != field: return false
	var player: Node2D = field.get("_player") as Node2D
	_check(player != null and player.position.distance_to(point) < .02 and bool(oracle.call("clear", player.position)), "actual explicit version15 fixture origin retains exact complete feet")
	return player != null and player.position.distance_to(point) < .02 and bool(oracle.call("clear", player.position))

func _gameplay_return_phase() -> void:
	if not bool(oracle.get("valid")): return
	if not await _open_owned_world_fixture(world.player_spawn * SIZE): return
	var failures_at_start: int = failures
	var overview: RefCounted = OVERVIEW_PROBE.new()
	overview.call("configure", self, input_driver, _check, Callable(oracle, "clear"))
	var map_record: Dictionary = await overview.call("run", field, world)
	overview.call("release")
	overview = null
	_check(_write_json("actual_M_overview.json", map_record), "actual M input/current v15 preview/labels/marker evidence persists")
	if failures == failures_at_start and bool(map_record.get("opened", false)) and bool(map_record.get("closed", false)):
		completed_phases.append("actual_M_v15_overview_sixteen_labels_and_current_player_marker")
	var battle: RefCounted = BATTLE_PROBE.new()
	battle.call("configure", self, input_driver, _check, _wait_field, _normal_intro, Callable(oracle, "clear"))
	var records: Array[Dictionary] = []
	var passed := 0
	for mode: String in ["victory", "defeat", "flee"]:
		if not await _open_owned_world_fixture(world.player_spawn * SIZE): break
		var before: int = failures
		var record: Dictionary = await battle.call("run", field, mode)
		record["passed"] = failures == before and bool(record.get("entered", false)) and bool(record.get("returned", false))
		records.append(record)
		if bool(record.passed): passed += 1
		# An unresolved real battle must not be silently replaced by the next
		# fixture. Keep its failed outcome and stop this finite category.
		if not bool(record.get("returned", false)): break
	battle.call("release")
	battle = null
	_check(passed == 3 and records.size() == 3, "actual Victory, Defeat and ordinary confirmed team Flee all complete version15 exact-foot returns")
	_check(before_saves == _actual_saves(), "real gameplay outcomes do not write normal player slots")
	_check(_write_json("actual_battle_version15_returns.json", {"scope": "ACTUAL_UI_OUTCOMES_NOT_LEGACY_RANDOM_FLEE", "records": records, "passed": passed}), "real outcome/accepted-action/payload/full17 evidence persists")
	if passed == 3: completed_phases.append("actual_victory_defeat_confirmed_team_flee_version15_exact_returns")

func _normal_npc_patrol_phase() -> void:
	if not bool(oracle.get("valid")): return
	if not await _open_owned_world_fixture(world.player_spawn * SIZE): return
	if alpha_oracle == null: alpha_oracle = GEOMETRY_ORACLE.new()
	var failures_at_start: int = failures
	var probe: RefCounted = NORMAL_NPC_PROBE.new()
	probe.call("configure", self, input_driver, alpha_oracle, _check, Callable(oracle, "clear"), _physical_clear, Callable(oracle, "segment_evidence"))
	var evidence: Dictionary = await probe.call("run", field, world)
	probe.call("release")
	probe = null
	_check(_write_json("normal_patrol_same_band_v15.json", evidence), "normal current-frame patrol/physical-body/tie/late-cleanup evidence persists")
	if failures == failures_at_start and int(evidence.get("front_count", 0)) > 0 and int(evidence.get("behind_count", 0)) > 0:
		completed_phases.append("normal_spawned_NPC_south_gt512_same_band_both_directions_four_frames_tie_cleanup")

func _wait_field(id: StringName) -> bool:
	var deadline: int = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		if not is_instance_valid(current_scene): continue
		var definition: Variant = current_scene.get("_current_scene")
		var player: Variant = current_scene.get("_player")
		if definition is SceneScript and player is Node2D and definition.scene_id == id:
			field = current_scene
			for settle in 6: await physics_frame
			await input_driver.call("completed_actor_stage")
			return true
	_check(false, "normal production Field actually enters exact scene through Loading: " + String(id))
	return false

func _runtime_input_ready() -> bool:
	if not is_instance_valid(field) or current_scene != field: return false
	var player: Node2D = field.get("_player") as Node2D
	return is_instance_valid(player) and bool(player.get("can_move")) and not bool(root.get_node("DialogPlayer").call("is_playing")) and not bool(field.get("_system_panel_open")) and not bool(field.get("_encounter_locked"))

func _door_negative_phase() -> void:
	var preflight_failures: int = failures
	# Source semantic witnesses are mandatory. Do not infer a roof/wall solely
	# from a large alpha bbox, and never place the actor on those illegal pixels.
	var cases: Array[Dictionary] = []
	for id: String in DESTINATIONS:
		if not requested_portal.is_empty() and requested_portal != id: continue
		var door: Dictionary = _source_door(id)
		var probes: Variant = door.get("input_negative_probes")
		_check(probes is Array, "door owns independently reviewed wall/roof/wrongside witnesses: " + id)
		if not probes is Array: continue
		var kinds: Dictionary = {}
		for probe: Dictionary in probes:
			var kind: String = probe.get("kind", "")
			_check(kind in ["wall_approach", "roof_click", "wrongside"] and probe.get("semantic_review_status") == "APPROVED", "negative case source semantics explicitly reviewed: %s/%s" % [id, kind])
			_check(not kinds.has(kind), "one unambiguous negative contract per kind")
			kinds[kind] = true
			cases.append({"id": id, "door": door, "probe": probe})
		_check(kinds.size() == 3, "each selected doorway has all three distinct negative mechanisms")
	if failures != preflight_failures or not runtime_started or input_driver == null: return
	var records: Array[Dictionary] = []
	for entry: Dictionary in cases:
		var id: String = entry.id
		var probe: Dictionary = entry.probe
		var kind: String = probe.kind
		var stand: Vector2 = _point(probe.get("legal_start_px" if kind == "wall_approach" else "legal_stand_px"))
		_check(stand.is_finite() and bool(oracle.call("clear", stand)), "negative actor origin is independently full17 legal: %s/%s" % [id, kind])
		if not stand.is_finite() or not bool(oracle.call("clear", stand)): continue
		root.get_node("SceneRouter").call("go_field_smart", SCENE_ID, stand / SIZE, "", 15)
		if not await _wait_field(SCENE_ID) or not await _normal_intro(): continue
		_check(_runtime_input_ready(), "negative input not suppressed by dialog/disabled actor/modal")
		var published: Dictionary = portals_by_id[id]
		var polygon: PackedVector2Array = published.get("interaction_polygon_px", PackedVector2Array())
		var evidence: Dictionary = {"id": id, "kind": kind, "source_review": probe.semantic_review_status, "stand_px": [stand.x, stand.y]}
		var zone: Node2D
		for node: Node2D in field.get("_exit_nodes"):
			if String(node.get("target_scene_id")) == String(DESTINATIONS[id]): zone = node
		_check(zone != null, "negative exercises existing exact target ExitZone")
		if zone == null: continue
		if kind == "wall_approach":
			var blocked: Vector2 = _point(probe.get("blocked_foot_px"))
			var reason: Dictionary = oracle.call("foot_evidence", blocked)
			_check(blocked.is_finite() and not bool(reason.clear) and reason.get("kind") == "source_collision", "reviewed wall is independently a physical solid, not arbitrary black terrain")
			if not blocked.is_finite(): continue
			var drive: Dictionary = await input_driver.call("drive", field, blocked, Callable(oracle, "clear"))
			_check(not bool(drive.get("reached", true)) and bool(drive.get("all_recorded_feet_clear", false)), "actual movement stops at wall with no shoe entering forbidden footprint")
			evidence["blocked_source"] = reason
			evidence["drive"] = drive
			var player: Node2D = field.get("_player") as Node2D
			_check(not Geometry2D.is_point_in_polygon(player.position, polygon), "wall stop remains on wrong side of actual doorway")
			await input_driver.call("key", KEY_SPACE)
		elif kind == "roof_click":
			var uv: Vector2 = _point(probe.get("source_uv"))
			var click: Vector2 = _point(probe.get("world_click_px"))
			var prop: Sprite2D = _actual_landmark_sprite(id)
			_check(prop != null and uv.is_finite() and click.is_finite(), "roof click uses reviewed original source UV and exact runtime landmark")
			if prop == null or not uv.is_finite() or not click.is_finite(): continue
			var texture_image: Image = prop.texture.get_image()
			_check(texture_image != null and not texture_image.is_empty(), "actual roof source texture is readable")
			if texture_image == null or texture_image.is_empty(): continue
			var original: Image = texture_image.duplicate() as Image
			if original.is_compressed(): original.decompress()
			var pixel := Vector2i(clampi(floori(uv.x * original.get_width()), 0, original.get_width() - 1), clampi(floori(uv.y * original.get_height()), 0, original.get_height() - 1))
			_check(uv.x >= 0 and uv.y >= 0 and uv.x < 1 and uv.y < 1 and original.get_pixelv(pixel).a > .12, "roof source witness is an actual visible entity pixel, not transparent bbox")
			var rect: Rect2 = prop.get_rect()
			var container: Node2D = field.get("world_container") as Node2D
			var draw_uv: Vector2 = Vector2(1.0 - uv.x if prop.flip_h else uv.x, 1.0 - uv.y if prop.flip_v else uv.y)
			var projected: Vector2 = container.to_local(prop.to_global(rect.position + draw_uv * rect.size))
			_check(projected.distance_to(click) < .01 and not Geometry2D.is_point_in_polygon(click, polygon), "reviewed roof source maps exactly outside doorway polygon")
			evidence["pointer"] = await input_driver.call("pointer", container.get_global_transform_with_canvas() * click)
			evidence["source_uv"] = [uv.x, uv.y]
			evidence["source_texture_sha256"] = FileAccess.get_sha256(prop.texture.resource_path)
		else:
			_check(not Geometry2D.is_point_in_polygon(stand, polygon), "wrongside standing point is legal ground but strictly outside doorway")
			await input_driver.call("key", KEY_SPACE)
			var stayed_space: bool = await _stays_world_after_negative()
			_check(stayed_space, "wrongside actual Space cannot trigger exact destination")
			if not stayed_space: continue
			var click: Vector2 = _point(probe.get("world_click_px"))
			var container: Node2D = field.get("world_container") as Node2D
			_check(click.is_finite() and Geometry2D.is_point_in_polygon(click, polygon), "wrongside mouse targets real door while actor remains outside")
			if not click.is_finite(): continue
			evidence["pointer"] = await input_driver.call("pointer", container.get_global_transform_with_canvas() * click)
			var stayed_door: bool = await _stays_world_after_negative()
			_check(stayed_door, "wrongside actual door click cannot trigger exact destination")
			if not stayed_door: continue
			var marker: Sprite2D = zone.get("marker_visual") as Sprite2D
			_check(marker != null and marker.visible, "wrongside negative also clicks actual arrow")
			if marker == null: continue
			evidence["arrow_pointer"] = await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin)
		var stayed: bool = await _stays_world_after_negative()
		_check(stayed, "wall/roof/wrongside real input cannot enter target across solid geometry: %s/%s" % [id, kind])
		evidence["stayed_world"] = stayed
		records.append(evidence)
	_check(records.size() == cases.size(), "all selected semantic negative inputs actually ran, not skipped")
	_check(_write_json("door_input_negatives.json", {"scope": "ACTUAL_DOOR_NEGATIVES_NOT_VISUAL_APPROVAL", "source_sha256": FileAccess.get_sha256(SOURCE_PATH), "records": records}), "negative input evidence checked persistence")
	if requested_portal.is_empty() and records.size() == 48: completed_phases.append("all16_wall_roof_wrongside_actual_input_negatives")

func _actual_landmark_sprite(portal_id: String) -> Sprite2D:
	var object_id := ""
	for entry: Dictionary in world.map_layout.visual_objects:
		if String(entry.get("portal_id", "")) == portal_id: object_id = String(entry.get("id", ""))
	for prop: Sprite2D in field.get("_scene_object_nodes"):
		if String(prop.name) == "SceneObject_" + object_id and prop.texture != null: return prop
	return null

func _stays_world_after_negative() -> bool:
	var original_field: Node = field
	for settle in 12:
		await process_frame
		await physics_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")) or current_scene != original_field: return false
	return is_instance_valid(original_field) and root.get_node("SceneRouter").call("get_current_field_id") == SCENE_ID

func _normal_intro() -> bool:
	var dialog: Node = root.get_node("DialogPlayer")
	for step in 80:
		if not bool(dialog.call("is_playing")): return true
		var node: Resource = dialog.get("_current_node") as Resource
		if node != null and not (node.get("choices") as Array).is_empty(): dialog.call("choose", 0)
		else: dialog.call("advance")
		for settle in 4: await process_frame
	_check(false, "authored introduction finishes without stripping gameplay/dialog resources")
	return false

func _portal_runtime_phase() -> void:
	var preflight_failures: int = failures
	if not bool(oracle.get("valid")): return
	# Preflight ALL selected measurements before any Field load. A pending/null
	# doorstep can never be silently replaced by a sprite bbox or old stone.
	var selected: Array[String] = []
	for id: String in DESTINATIONS:
		if requested_portal.is_empty() or requested_portal == id: selected.append(id)
	var doors: Dictionary = {}
	for id: String in selected:
		var measured: Dictionary = _source_door(id)
		if measured.is_empty(): continue
		var published: Dictionary = portals_by_id.get(id, {})
		var polygon: Variant = published.get("interaction_polygon_px")
		_check(polygon is PackedVector2Array and polygon.size() >= 3, "published doorway uses an independent reviewed pixel polygon: " + id)
		var foot := _point(measured.door_foot_px)
		_check(_point(published.get("pos")) * SIZE == foot, "runtime door is exactly measured projected doorstep, not source XZ: " + id)
		_check(polygon is PackedVector2Array and Geometry2D.is_point_in_polygon(foot, polygon), "actual measured foot lies inside its doorway polygon: " + id)
		_check(bool(oracle.call("clear", foot)), "measured doorway has independent full17 clearance: " + id)
		doors[id] = measured
	if failures != preflight_failures or doors.size() != selected.size(): return
	_ensure_runtime_fixture()
	var modes: Array[String] = ["space", "door_mouse", "arrow"] if requested_mode == "all" else [requested_mode]
	for id: String in selected:
		for mode: String in modes:
			await _portal_roundtrip(id, mode, doors[id])
	var passed := 0
	for record: Dictionary in actual_portal_roundtrips:
		if bool(record.get("passed", false)): passed += 1
	_check(passed == selected.size() * modes.size(), "every requested real mode completes destination AND actual paired return")
	_check(_write_json("portal_roundtrips.json", {"scope": "LIMITED_REAL_PORTAL_INPUT_NOT_FULL_WORLD" if requested_phase != "full" else "FULL_PORTAL_CATEGORY", "door_modes": modes, "selected_ids": selected, "records": actual_portal_roundtrips, "source_sha256": FileAccess.get_sha256(SOURCE_PATH)}), "actual roundtrip input evidence persists with source SHA")
	if passed == 48 and requested_portal.is_empty() and requested_mode == "all": completed_phases.append("all16_space_door_mouse_arrow_actual_returns")

func _ensure_runtime_fixture() -> void:
	if runtime_started: return
	input_driver = INPUT_DRIVER.new()
	input_driver.call("configure", self)
	# Same public new-game setup as the menu. It is process-local fixture data;
	# no ordinary slot is loaded/written and all authored scene behavior remains.
	for singleton: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "WeatherManager", "SceneRouter"]:
		root.get_node(singleton).call("reset_for_new_game")
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	prior_active = StringName(root.get_node("SceneRouter").get("_active_world_map_scene"))
	_check(before_saves == _actual_saves() and int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "public runtime fixture startup does not touch normal slots/files")
	runtime_started = true
	var gm: Node = root.get_node_or_null("GMConsole")
	if gm != null:
		if gm is CanvasLayer: gm.visible = false
		gm.set_process(false)
		gm.set_process_unhandled_input(false)

func _depth_runtime_phase() -> void:
	if not bool(oracle.get("valid")): return
	_ensure_runtime_fixture()
	alpha_oracle = GEOMETRY_ORACLE.new()
	var records: Array[Dictionary] = []
	var southern_mechanism_pairs := 0
	for entry: Dictionary in world.map_layout.visual_objects:
		if not bool(entry.get("sort_by_feet", false)) or not entry.has("depth_sort_foot_y"): continue
		var foot_y: float = float(entry.depth_sort_foot_y) * SIZE.y
		if foot_y <= 4300: continue
		var anchor: Vector2 = _point(entry.get("pos")) * SIZE
		var origin := Vector2(INF, INF)
		for radius in [64, 128, 192, 256]:
			for index in 16:
				var point: Vector2 = anchor + Vector2(cos(TAU * index / 16), sin(TAU * index / 16)) * radius
				if bool(oracle.call("clear", point)):
					origin = point
					break
			if origin.is_finite(): break
		if not origin.is_finite(): continue
		root.get_node("SceneRouter").call("go_field_smart", SCENE_ID, origin / SIZE, "", 15)
		if not await _wait_field(SCENE_ID) or not await _normal_intro(): continue
		var prop: Sprite2D
		for sprite: Sprite2D in field.get("_scene_object_nodes"):
			if String(sprite.name) == "SceneObject_" + String(entry.get("id", "")): prop = sprite
		if prop == null: continue
		var player: Node2D = field.get("_player") as Node2D
		var actor: Sprite2D = player.get("sprite") as Sprite2D
		var container: Node2D = field.get("world_container") as Node2D
		_check(int(player.get_meta("depth_band_max", -1)) == 1024 and int(field.call("_scene_depth_band_max")) == 1024, "v15 actual normally spawned actor/Field select8192 depth domain")
		_check(absf(container.global_rotation) < .000001 and container.global_scale == Vector2.ONE, "logical foot-depth projection uses actual unscaled/unrotated world container")
		var global_foot: float = container.to_global(Vector2(0, foot_y)).y
		var expected_band: int = clampi(floori(global_foot / 8), 0, 1024)
		_check(prop.z_index == expected_band and prop.z_index > 512, "actual southern object matches independent global-foot band >512, not saturatedv14")
		var bounds: Rect2 = alpha_oracle.call("bounds_in", prop, container)
		player.call("set_walk_direction", Vector2.DOWN, false)
		await input_driver.call("completed_actor_stage")
		var actor_offset: float = float(player.call("get_depth_sort_y")) - player.global_position.y
		var stations: Dictionary = {}
		for relation: String in ["behind", "front"]:
			for delta: float in [1.0, 2.0, 3.0]:
				var desired: float = global_foot + (-delta if relation == "behind" else delta)
				if floori(desired / 8) != expected_band: continue
				var y: float = desired - actor_offset - container.global_position.y
				for x in range(floori(bounds.position.x - 100), ceili(bounds.end.x + 100) + 1, 16):
					var point := Vector2(x, y)
					if not bool(oracle.call("clear", point)) or not _physical_clear(point): continue
					var shift: Vector2 = container.to_global(point) - player.global_position
					var overlap: Dictionary = alpha_oracle.call("strong_intersection", actor, prop, shift)
					if bool(overlap.get("valid", false)) and int(overlap.hits) >= 100:
						stations[relation] = point
						break
				if stations.has(relation): break
		# Missing coarse stations are NOT a negative proof or waiver. Other props
		# may supply the limited mechanism witness; FULL all-prop proof is separate.
		if stations.size() != 2: continue
		var all_ok := true
		for relation: String in ["behind", "front"]:
			var target: Vector2 = stations[relation]
			var path: PackedVector2Array = input_driver.call("plan", player.position, target, SIZE, Callable(oracle, "clear"), Callable(oracle, "segment_evidence"))
			_check(path.size() >= 2, "independent full17 edge path exists to same-band strong alpha station")
			if path.size() < 2:
				all_ok = false
				continue
			var drive: Dictionary = await input_driver.call("follow", field, path, Callable(oracle, "clear"), Callable(oracle, "segment_evidence"))
			_check(bool(drive.get("ok", false)), "actual input reaches same-band depth station without crossing fullXZ")
			player.call("set_walk_direction", Vector2.DOWN, false)
			await input_driver.call("completed_actor_stage")
			var overlap: Dictionary = alpha_oracle.call("strong_intersection", actor, prop)
			var actor_foot: float = float(player.call("get_depth_sort_y"))
			var actor_band: int = clampi(floori(actor_foot / 8), 0, 1024)
			var correct_relation: bool = actor_foot < global_foot if relation == "behind" else actor_foot > global_foot
			var is_front: bool = alpha_oracle.call("actual_in_front", player, prop)
			var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
			var ghost_hits: int = int((debug.get("prop_hits", {}) as Dictionary).get(String(entry.id), 0))
			var valid: bool = bool(drive.get("ok", false)) and bool(oracle.call("clear", player.position)) and _physical_clear(player.position) and correct_relation and player.z_index == actor_band and actor_band == expected_band and actor_band > 512 and int(overlap.get("hits", 0)) >= 100 and is_front == (relation == "front")
			_check(valid, "normal completed idle stage real foot/strong-current-alpha/effective order agrees within same band >512")
			_check(ghost_hits > 0 if relation == "behind" else ghost_hits == 0, "real ghost union includes behind prop only, front actor never ghosts through it")
			all_ok = all_ok and valid
			records.append({"id": entry.id, "relation": relation, "actual_player_px": [player.position.x, player.position.y], "actual_actor_global_foot": actor_foot, "actual_prop_global_foot": global_foot, "actor_band": actor_band, "prop_band": prop.z_index, "actor_sibling": player.get_index(), "prop_sibling": prop.get_index(), "overlap": overlap, "ghost_prop_hits": ghost_hits, "drive": drive})
		if all_ok: southern_mechanism_pairs += 1
		if southern_mechanism_pairs >= 3: break
	_check(southern_mechanism_pairs >= 3, ">=3 actual strong southern prop pairs prove expanded and same-band depth mechanism")
	_check(_write_json("expanded_same_band_depth.json", {"scope": "LIMITED_SOUTHERN_CURRENT_FRAME_MECHANISM_NOT_ALL_PROPS_OR_PATROL", "pairs_passed": southern_mechanism_pairs, "records": records}), "actual depth/source/current-frame evidence persisted")
	if southern_mechanism_pairs >= 3: completed_phases.append("three_southern_strong_current_frame_same_band_gt512_pairs")

func _portal_roundtrip(id: String, mode: String, measurement: Dictionary) -> void:
	var failures_at_start: int = failures
	var router: Node = root.get_node("SceneRouter")
	var door: Vector2 = _point(measurement.door_foot_px)
	# Fixture placement is only the first local approach point. The door itself
	# must then be reached by real movement along independently checked edges.
	var approach: PackedVector2Array = PackedVector2Array()
	for route: Dictionary in world.map_layout.travel_routes:
		if String(route.get("id", "")) == "portal_" + id:
			var values: Variant = route.get("points")
			if values is PackedVector2Array or values is Array:
				for value: Variant in values: approach.append(_point(value) * SIZE)
	_check(approach.size() >= 2 and approach[approach.size() - 1].distance_to(door) < .01, "actual approach route terminates at measured doorstep: " + id)
	if approach.size() < 2: return
	if not bool(oracle.call("clear", approach[0])):
		_check(false, "approach fixture first point is not full17 safe: " + id)
		return
	router.call("go_field_smart", SCENE_ID, approach[0] / SIZE, "", 15)
	if not await _wait_field(SCENE_ID): return
	if not await _normal_intro(): return
	_check(field.get("_world_size") == SIZE, "actual production Field uses expanded world canvas")
	var player: Node2D = field.get("_player") as Node2D
	_check(player.position.distance_to(approach[0]) < .02, "explicit version15 fixture origin is preserved exactly")
	var driven: Dictionary = await input_driver.call("follow", field, approach, Callable(oracle, "clear"), Callable(oracle, "segment_evidence"))
	_check(bool(driven.get("ok", false)), "real movement reaches doorstep with every physics foot legal: %s/%s %s" % [id, mode, driven])
	if not bool(driven.get("ok", false)): return
	var zone: Node2D
	for entry: Node2D in field.get("_exit_nodes"):
		if String(entry.get("target_scene_id")) == String(DESTINATIONS[id]): zone = entry
	_check(zone != null and bool(zone.get("_in_range")), "actual physics overlap reaches doorway, not radius across wall: " + id)
	if zone == null: return
	var input_evidence: Dictionary = {"mode": mode}
	if mode == "space": await input_driver.call("key", KEY_SPACE)
	elif mode == "door_mouse":
		var container: Node2D = field.get("world_container") as Node2D
		_check(container != null, "actual production world canvas transform exists")
		if container == null: return
		input_evidence.merge(await input_driver.call("pointer", container.get_global_transform_with_canvas() * door), true)
	else:
		var marker: Sprite2D = zone.get("marker_visual") as Sprite2D
		_check(marker != null and marker.texture != null and marker.visible, "actual drawn arrow exists and is visible: " + id)
		if marker == null: return
		input_evidence.merge(await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin), true)
	var destination: StringName = StringName(DESTINATIONS[id])
	if not await _wait_field(destination): return
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	_check(definition.resource_path == "res://data/scenes/%s.tres" % destination, "normal unchanged target resource, no probe scene substitute: " + id)
	player = field.get("_player") as Node2D
	_check(int(player.get_meta("depth_band_max", -1)) == 255, "ordinary target restores player depth255 after v15: " + id)
	for npc: Node in field.get("_npc_nodes"):
		if is_instance_valid(npc): _check(int(npc.get_meta("depth_band_max", -1)) == 255, "normally spawned target NPC restores depth255: " + id)
	if not _configure_ordinary(definition): return
	_check(_ordinary_clear(player.position), "actual target arrival full17/raw source/physics legal: " + id)
	if not await _normal_intro(): return
	if not await _actual_return(destination): return
	player = field.get("_player") as Node2D
	_check(player.position.distance_to(door) < .02 and bool(oracle.call("clear", player.position)), "actual paired exit restores exact door with complete feet: " + id)
	var navigation: Dictionary = router.call("get_navigation_state")
	_check(int(navigation.get("world_map_version", -1)) == 15, "paired target roundtrip retains world coordinate version15")
	actual_portal_roundtrips.append({"id": id, "mode": mode, "passed": failures == failures_at_start, "target_scene": String(destination), "target_resource": definition.resource_path, "door_foot_px": [door.x, door.y], "source_doorstep_uv": measurement.source_doorstep_uv, "approach": driven, "input": input_evidence, "actual_return_px": [player.position.x, player.position.y], "world_map_version": navigation.get("world_map_version")})

func _configure_ordinary(definition: SceneScript) -> bool:
	ordinary_images.clear()
	ordinary_blockers.clear()
	var layout: Resource = definition.map_layout
	_check(layout != null, "target has actual navigation resource, no center-only fallback")
	if layout == null: return false
	ordinary_size = Vector2(layout.get("design_size"))
	_check(ordinary_size.x > 0 and ordinary_size.y > 0, "target navigation design dimensions are real")
	var tiles: Array = layout.get("walkable_mask_tiles")
	if tiles.is_empty():
		var path: String = layout.get("walkable_mask_path")
		var image: Image = Image.load_from_file(path) if not path.is_empty() else null
		_check(image != null and not image.is_empty(), "target original raw navigation PNG decoded failclosed: " + path)
		if image == null or image.is_empty(): return false
		ordinary_images.append({"image": image, "rect": Rect2(Vector2.ZERO, ordinary_size), "path": path, "sha256": FileAccess.get_sha256(path)})
	else:
		for tile: Dictionary in tiles:
			var path: String = tile.get("path", "")
			var image: Image = Image.load_from_file(path)
			var rect: Rect2 = tile.get("logical_rect", Rect2())
			_check(image != null and not image.is_empty() and rect.size.x > 0 and rect.size.y > 0, "target original tile+logical_rect decoded failclosed")
			if image == null or image.is_empty() or rect.size.x <= 0 or rect.size.y <= 0: return false
			ordinary_images.append({"image": image, "rect": rect, "path": path, "sha256": FileAccess.get_sha256(path)})
	for kind: String in ["visual_objects", "blockers"]:
		for entry: Dictionary in layout.get(kind):
			if kind == "visual_objects" and not entry.has("collision_size"): continue
			var extent: Vector2 = entry.get("collision_size" if kind == "visual_objects" else "size", Vector2.ZERO)
			var center: Vector2 = (entry.get("pos", Vector2.ZERO) + entry.get("collision_offset", Vector2.ZERO)) * ordinary_size
			var margin: Vector2 = ordinary_size * (.004 if kind == "visual_objects" else .014)
			ordinary_blockers.append(Rect2(center - extent * ordinary_size * .5 - margin, extent * ordinary_size + margin * 2))
	return not ordinary_images.is_empty()

func _ordinary_static_clear(center: Vector2) -> bool:
	if not center.is_finite(): return false
	var shoes: PackedVector2Array = oracle.call("samples", center)
	for shoe: Vector2 in shoes:
		if shoe.x < 0 or shoe.y < 0 or shoe.x >= ordinary_size.x or shoe.y >= ordinary_size.y: return false
		var covered := false
		for tile: Dictionary in ordinary_images:
			var rect: Rect2 = tile.rect
			if not rect.has_point(shoe): continue
			var image: Image = tile.image
			var uv: Vector2 = (shoe - rect.position) / rect.size
			var pixel := Vector2i(roundi(uv.x * (image.get_width() - 1)), roundi(uv.y * (image.get_height() - 1)))
			var color: Color = image.get_pixelv(pixel)
			if color.a < .5 or maxf(color.r, maxf(color.g, color.b)) < .5: return false
			covered = true
			break
		if not covered: return false
		for blocker: Rect2 in ordinary_blockers:
			if blocker.has_point(shoe): return false
	return true

func _ordinary_clear(center: Vector2) -> bool:
	return _ordinary_static_clear(center) and _physical_clear(center)

func _physical_clear(center: Vector2) -> bool:
	if not is_instance_valid(field): return false
	var player: Node2D = field.get("_player") as Node2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	if shape == null or shape.shape == null or container == null: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += container.to_global(center) - player.global_position
	query.collision_mask = int(player.get("collision_mask"))
	query.exclude = [player.call("get_rid")]
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _ordinary_segment(a: Vector2, b: Vector2) -> Dictionary:
	var count: int = maxi(1, ceili(a.distance_to(b) / 4))
	for index in range(count + 1):
		var point: Vector2 = a.lerp(b, float(index) / count)
		if not _ordinary_clear(point): return {"clear": false, "index": index, "point": [point.x, point.y]}
	return {"clear": true, "centers": count + 1, "max_step_px": a.distance_to(b) / count}

func _actual_return(destination: StringName) -> bool:
	var reverse: Node2D
	for zone: Node2D in field.get("_exit_nodes"):
		if String(zone.get("target_scene_id")) in [String(SCENE_ID), "world_map_jianghu"] or String(zone.get("action")) == "world_map":
			reverse = zone
			break
	_check(reverse != null, "actual target has public reverse exit: " + String(destination))
	if reverse == null: return false
	var player: Node2D = field.get("_player") as Node2D
	var path := PackedVector2Array()
	for radius in [0, 16, 32, 48, 64]:
		for direction in 16:
			var point: Vector2 = reverse.position + Vector2(cos(TAU * direction / 16), sin(TAU * direction / 16)) * radius
			if not _ordinary_clear(point): continue
			var shape: CollisionShape2D = reverse.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var container: Node2D = field.get("world_container") as Node2D
			if shape == null or not shape.shape is RectangleShape2D or container == null: continue
			var local: Vector2 = shape.to_local(container.to_global(point))
			if not Rect2(-shape.shape.size * .5, shape.shape.size).has_point(local): continue
			path = input_driver.call("plan", player.position, point, ordinary_size, _ordinary_clear, _ordinary_segment)
			if path.size() >= 2: break
		if path.size() >= 2: break
	_check(path.size() >= 2, "independent all-edge full17 path exists to actual reverse trigger: " + String(destination))
	if path.size() < 2: return false
	var driven: Dictionary = await input_driver.call("follow", field, path, _ordinary_clear, _ordinary_segment)
	_check(bool(driven.get("ok", false)), "real ordinary target input completes planned reverse path: %s %s" % [destination, driven])
	_check(bool(reverse.get("_in_range")), "normal physics reaches reverse exit; no direct router return")
	if not bool(driven.get("ok", false)) or not bool(reverse.get("_in_range")): return false
	var marker: Sprite2D = reverse.get("marker_visual") as Sprite2D
	_check(marker != null, "actual target reverse arrow exists")
	if marker == null: return false
	await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin)
	return await _wait_field(SCENE_ID)

func _write_json(name: String, value: Dictionary) -> bool:
	var path: String = output + name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	file = null
	return error == OK and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(JSON.stringify(value))

func _finish() -> void:
	# Only this process's fixture ownership. Runtime baseline was established by
	# the public new-game operation before candidate travel, not a hidden slot.
	if input_driver != null: input_driver.call("release")
	input_driver = null
	if alpha_oracle != null: alpha_oracle.call("release")
	alpha_oracle = null
	if is_instance_valid(isolated_slots):
		var slots_reference: WeakRef = weakref(isolated_slots)
		if isolated_slots.get_parent() != null: isolated_slots.get_parent().remove_child(isolated_slots)
		isolated_slots.queue_free()
		isolated_slots = null
		for settle in 4: await process_frame
		_check(slots_reference.get_ref() == null, "owned isolated SaveManager actually released")
	ordinary_images.clear()
	ordinary_blockers.clear()
	if runtime_started:
		if is_instance_valid(current_scene):
			var owned_scene: Node = current_scene
			var reference: WeakRef = weakref(owned_scene)
			current_scene = null
			owned_scene.queue_free()
			owned_scene = null
			field = null
			for settle in 8: await process_frame
			_check(reference.get_ref() == null, "owned production Field actually freed after natural stages")
		var router: Node = root.get_node("SceneRouter")
		router.call("restore_navigation_state", prior_navigation)
		router.set("_active_world_map_scene", prior_active)
		var audio: Node = root.get_node_or_null("AudioManager")
		if audio != null:
			audio.call("stop_bgm", 0.0)
			audio.call("stop_music_sting")
			audio.call("stop_ambience", 0.0)
			audio.call("stop_all_sfx")
			audio.call("stop_dialog_audio")
		await create_timer(.20).timeout
		for settle in 8: await process_frame
	if oracle != null: oracle.call("release")
	oracle = null
	world = null
	_check(before_saves == _actual_saves(), "normal player files unchanged before and after requested phase")
	_check(int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "normal active save slot unchanged")
	_check(root.get_node("SceneRouter").call("get_navigation_state") == prior_navigation, "test cleanup preserves managed fixture baseline without slot I/O or version drift")
	_check(StringName(root.get_node("SceneRouter").get("_active_world_map_scene")) == prior_active, "source-only suite does not change active world")
	var report: Dictionary = {"schema": 1, "scope": "V15_SOURCE_WIP_NOT_FULL_ACCEPTANCE" if requested_phase == "full" else "V15_LIMITED_" + requested_phase.to_upper(), "requested_phase": requested_phase, "source_complete": false, "checks": checks, "failures": failures, "completed_phases": completed_phases, "incomplete_phases": incomplete_phases, "route_4px_full17_centers": route_centers, "field_input_executed": runtime_started, "portal_roundtrips": actual_portal_roundtrips, "GPU_executed": false, "player_saves_unchanged": before_saves == _actual_saves(), "executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path)}
	_check(_write_json("result.json", report), "honest source-WIP result checked write/readback")
	print("[WorldV15] SOURCE_WIP checks=%d failures=%d NO_FULL_FIELD_ACCEPTANCE output=%s" % [checks, failures, output])
	quit(1 if failures > 0 else 0)
