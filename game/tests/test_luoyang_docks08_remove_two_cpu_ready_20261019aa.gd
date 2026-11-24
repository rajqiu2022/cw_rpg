extends SceneTree
## Independent bounded before/after admission only. Never invokes publisher/geometry/Field.
const READY := true
const BUDGET_MS := 60000
const FREEZE := "res://tests/fixtures/luoyang_docks08_remove_two_cpu_20261019aa.json"
const FREEZE_SHA := "d978964e1992e506a25b1a02150b1437970fd37f00bddde5a46cbbfcc15eaa22"
const PUBLICATION := "res://build/luoyang_docks_district08_20261019aa_cpu/111516/result.json"
const PUBLICATION_SHA := "d99ca2d36a4b392ae76e73c6e1747042cb4ca9208497c4bb6434e10e3be9b0ce"
const ART := "res://build/luoyang_docks_district08_20261019aa_art01/layout_spec.json"
const ART_SHA := "281c64ffa5b081468d53e1e08cd3184d7cff40221659f6f6f575cdfbb0c34942"
const SERIAL := "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const AA := "res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const ROOT := "res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/"
const REMOVED := ["harbour_small_cargo_store", "south_canal_front"]
const OLD_META := "luoyang_building_spacing_author_20261017p"
const NEW_META := "luoyang_docks_district08_20261019aa"
const BASIS := "DOCKS08_EXACT_REMOVE_TWO_NEW_LOCAL_GEOMETRY_20261019aa"
var checks := 0
var failures := 0
var began := 0
var sources: Dictionary = {}
var records: Array = []
var serial: Script
var aa: Script

func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("DOCKS_AA_QA_FAIL ", label, " ", detail)
	return value
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds_string": "0"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"exists": false, "sha256": "OPEN_FAILED", "bytes": 0, "mtime_seconds_string": "0"}
	var size := file.get_length(); file.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": size, "mtime_seconds_string": str(FileAccess.get_modified_time(path))}
func track(path: String, sha: String) -> bool:
	var current := fact(path)
	if sources.has(path): return check(sources[path] == current and current.sha256 == sha, "Repeated source has one exact unchanged authority " + path)
	sources[path] = current
	return check(current.exists and sha.length() == 64 and current.sha256 == sha, "Fixed independent source " + path)
func json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func saves() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in 5:
		for suffix: String in [".json", ".json.bak", ".json.tmp"]:
			var path := "user://save_" + str(slot) + suffix
			result[path] = fact(path)
	return result
func world_state() -> Dictionary:
	return {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "gold": root.get_node("GameState").get("gold")}
func wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value, "\t", true, true))
func equal(left: Variant, right: Variant) -> bool: return serial.equal(left, right)
func wire_equal(left: Variant, right: Variant) -> bool: return equal(wire(left), wire(right))
func vec(value: Variant) -> Vector2: return value if value is Vector2 else Vector2(value[0], value[1])
func index_objects(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var id: String = String(row.get("id", ""))
		if id.is_empty() or result.has(id): return {}
		result[id] = row
	return result

func polygons(objects: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object: Dictionary in objects:
		for raw: Array in object.get("solid_polygons_px", []):
			var poly := PackedVector2Array()
			var low := Vector2(INF, INF); var high := Vector2(-INF, -INF)
			for point: Variant in raw:
				var p := vec(point); poly.append(p); low = low.min(p); high = high.max(p)
			result.append({"poly": poly, "low": low, "high": high})
		var size := vec(object.get("collision_size_px", [0, 0]))
		if size.x > 0 and size.y > 0:
			var low := vec(object.physical_center_px) - size * 0.5
			result.append({"rect": Rect2(low, size)})
	return result
func blocked(point: Vector2, shapes: Array[Dictionary]) -> bool:
	if point.x < 24 or point.y < 24 or point.x >= 3048 or point.y >= 2024: return true
	for row: Dictionary in shapes:
		if row.has("rect"):
			# Frozen raster's rectangle rule is ceil-start / exclusive ceil-end.
			var r: Rect2 = row.rect
			if point.x >= ceili(r.position.x) and point.y >= ceili(r.position.y) and point.x < ceili(r.end.x) and point.y < ceili(r.end.y): return true
		else:
			var low: Vector2 = row.low; var high: Vector2 = row.high
			if point.x < low.x or point.y < low.y or point.x > high.x or point.y > high.y: continue
			# Integer-point raster, explicitly not pixel centres / roof bounds.
			if Geometry2D.is_point_in_polygon(point, row.poly): return true
	return false
func pixel_equal(bytes: PackedByteArray, offset: int, wanted: PackedByteArray) -> bool:
	for channel: int in 4:
		if bytes[offset + channel] != wanted[channel]: return false
	return true

func _mask_delta(old: Dictionary, child: Dictionary, raw: Image, geometry: Dictionary) -> bool:
	var before: PackedByteArray = old.walk_bytes; var after: PackedByteArray = child.walk_bytes
	var raw_bytes := raw.get_data()
	if not check(before.size() == 3072 * 2048 * 4 and after.size() == before.size() and raw_bytes.size() == before.size(), "Actual complete 3072x2048 RGBA mask byte domains"): return false
	var old_shapes := polygons(old.record.objects); var new_shapes := polygons(child.record.objects)
	var boxes: Array[Rect2i] = []
	var old_index := index_objects(old.record.objects)
	for id: String in REMOVED:
		for shape: Dictionary in polygons([old_index[id]]):
			if not check(not shape.has("rect"), "Both authorized removed native bases are explicit polygons " + id): return false
			var low: Vector2 = shape.low; var high: Vector2 = shape.high
			boxes.append(Rect2i(Vector2i(floori(low.x) - 1, floori(low.y) - 1), Vector2i(ceili(high.x) - floori(low.x) + 3, ceili(high.y) - floori(low.y) + 3)))
	var changed := 0; var locally_checked := 0
	var black := PackedByteArray([0, 0, 0, 255]); var white := PackedByteArray([255, 255, 255, 255])
	for y: int in 2048:
		if Time.get_ticks_msec() - began >= BUDGET_MS: return check(false, "Fixed60s independent delta audit budget")
		var left := 3072; var right := -1
		for box: Rect2i in boxes:
			if y >= box.position.y and y < box.end.y: left = mini(left, box.position.x); right = maxi(right, box.end.x)
		var start := y * 3072 * 4
		if right < 0:
			if not check(before.slice(start, start + 3072 * 4) == after.slice(start, start + 3072 * 4), "Entire RGBA row outside removed native raster is unchanged " + str(y)): return false
			continue
		left = maxi(0, left); right = mini(3072, right)
		if not check(before.slice(start, start + left * 4) == after.slice(start, start + left * 4) and before.slice(start + right * 4, start + 3072 * 4) == after.slice(start + right * 4, start + 3072 * 4), "Both full-RGBA row tails unchanged, water and unrelated geometry retained " + str(y)): return false
		for x: int in range(left, right):
			var point := Vector2(x, y); var offset := start + x * 4
			var raw_pixel := raw_bytes.slice(offset, offset + 4)
			var old_wanted := black if blocked(point, old_shapes) else raw_pixel
			var new_wanted := black if blocked(point, new_shapes) else raw_pixel
			if not pixel_equal(before, offset, old_wanted) or not pixel_equal(after, offset, new_wanted): return check(false, "Independent raw-minus-solids integer raster exact locally", [x, y])
			if not pixel_equal(after, offset, before.slice(offset, offset + 4)):
				if not pixel_equal(before, offset, black) or not pixel_equal(after, offset, white): return check(false, "Only black255 to white255 restoration; never alpha/color/water edits", [x, y])
				changed += 1
			locally_checked += 1
	if not check(changed > 0 and geometry.local_mask.changed_pixels == changed and geometry.local_mask.monotonic.restored_pixels == changed, "Independent changed count exactly equals every publisher monotonic counter", changed): return false
	records.append({"kind": "INDEPENDENT_LOCAL_INTEGER_RASTER_PLUS_ALL_OTHER_RGBA_UNCHANGED", "changed_pixels": changed, "local_pixels_recomputed": locally_checked, "all_other_pixels_byte_exact": true, "no_whole_city_geometry_rerun": true})
	return true

func _geometry_receipt(report: Dictionary) -> bool:
	var g: Dictionary = report.get("geometry", {})
	if not check(g.get("passed") == true and g.get("basis") == BASIS and g.get("full87517") == true and wire_equal(g.get("npc_continuous_body_px"), [34, 30]) and g.get("all_npcs_portals_routes_unchanged") == true, "Actual new CPU geometry receipt domain; never old PASS or Field credit"): return false
	var original: Dictionary = g.get("original_routes", {})
	if not check(original.get("passed") == true and original.get("all_routes_and_crowd_samples") == 2739 and original.get("crowd_samples") == 264 and original.get("crowd_count") == 10 and original.get("moving") == 6 and original.get("stationary") == 4 and original.get("full875_and17") == true and wire_equal(original.get("npc_envelope_px"), [34, 30]) and original.get("max_step_px") == 4 and original.get("dynamic_avoidance_promised") == false, "Every original-route/crowd proof field explicit, no synthetic navigation or avoidance credit"): return false
	var combined: Dictionary = g.get("combined", {})
	if not check(combined.get("passed") == true and combined.get("samples") == 2812 and combined.get("district_polygons") == 10 and combined.get("full87517") == true and wire_equal(combined.get("npc_continuous_body_px"), [34, 30]) and combined.get("max_step_px") == 4 and combined.get("all_original_routes_and_six_moving_lanes") == true, "Every additive-District/continuous NPC audit item is present and true"): return false
	var local: Dictionary = g.get("local_mask", {})
	if not check(local.get("passed") == true and local.get("changed_pixels", 0) > 0 and local.get("monotonic", {}).get("passed") == true and local.monotonic.get("no_previously_walkable_pixel_blocked") == true and local.monotonic.get("restored_pixels") == local.changed_pixels, "Actual remove-only local mask receipt, no old spacing result substitute"): return false
	return check(wire_equal(g.get("clearance_stations"), [[500, 1130], [560, 1570], [560, 1600]]), "All three new clear stations exact, no cherry-picked subset")

func _exercise() -> bool:
	if not check(READY and OS.get_cmdline_user_args().is_empty(), "Frozen independent aa CPU admission, no Field/candidate setup"): return false
	if not track(FREEZE, FREEZE_SHA) or not track(PUBLICATION, PUBLICATION_SHA) or not track(ART, ART_SHA): return false
	var freeze := json(FREEZE)
	for path: String in freeze.get("source_sha256", {}):
		if not track(path, freeze.source_sha256[path]): return false
	serial = load(SERIAL); aa = load(AA)
	if not check(serial is GDScript and serial.can_instantiate() and aa is GDScript and aa.can_instantiate(), "Real dependency scripts compile before constant access"): return false
	var author: Dictionary = aa.author(); var art := json(ART); var report := json(PUBLICATION)
	if not check(not author.is_empty() and report.get("passed") == true and report.get("status") == "AA_LOCAL_GEOMETRY_NATIVE_CANDIDATE_NOT_IMPORTED_NOT_RUNTIME" and report.get("limit_ms") == 60000 and report.get("elapsed_ms", 60000) < 60000 and report.get("source_first", {}) == report.get("source_final") and not report.source_first.is_empty(), "Root actual publication complete within original60s and full first/final source agreement"): return false
	for path: String in report.source_first:
		if not track(path, report.source_first[path]): return false
	for path: String in report.artifacts:
		if not track(path, report.artifacts[path]): return false
	if not track(report.walk_path, report.walk_sha256): return false
	for row: Dictionary in art.source_basis:
		if not track(row.path, row.sha256): return false
	var old_manifest := json(author.parent_manifest_path)
	if not check(equal(old_manifest, report.parent_complete_immutable_manifest) and report.parent_manifest_sha256 == author.source_sha256[author.parent_manifest_path] and report.artifact_root == ROOT and report.parent_count == 27 and report.child_count == 25 and report.geometry_basis == BASIS and report.author_sha256 == aa.AUTHOR_SHA, "Frozen exact parent and declared remove2 artifact root/count/basis"): return false
	for path: String in old_manifest.artifacts:
		if not track(path, old_manifest.artifacts[path]): return false
	var old: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(author.parent_bundle_root + "packet.bin"))
	var child: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(ROOT + "packet.bin"))
	var old_objects := index_objects(old.record.objects); var child_objects := index_objects(child.record.objects)
	if not check(old_objects.size() == 27 and child_objects.size() == 25 and not old_objects.has("harbour_main_warehouse") and not child_objects.has("harbour_main_warehouse"), "Exact27→25 after original north duplicate removal, never reintroduced"): return false
	var wanted_record: Dictionary = old.record.duplicate(true); var retained: Array = []
	for object: Dictionary in old.record.objects:
		if String(object.id) in REMOVED: continue
		retained.append(object.duplicate(true))
	wanted_record.objects = retained; wanted_record.walk_path = ROOT + "walk.png"
	wanted_record["aa_geometry_basis"] = BASIS; wanted_record["aa_author_sha256"] = aa.AUTHOR_SHA
	if not check(equal(wanted_record, child.record), "Whole complete record equals independent old-plus-only-two-deletions and exact authorized metadata/walk path"): return false
	for row: Dictionary in art.building_delta.remove:
		if not check(old_objects.has(row.id) and not child_objects.has(row.id) and row.has_current_portal_or_room == false and row.has_current_interaction == false and wire_equal(old_objects[row.id].world_foot_px, row.world_foot_px) and wire_equal(old_objects[row.id].solid_polygons_px, row.solid_polygons_px) and old_objects[row.id].texture == row.texture_path, "Only ART-authorized exact doorless/interaction-free old building removed " + row.id): return false
	for id: String in child_objects:
		if not check(equal(old_objects[id], child_objects[id]), "Every retained complete object remains type/field exact " + id): return false
	for row: Dictionary in art.retain_exact_landmarks + art.building_delta.retain_exact:
		if not check(child_objects.has(row.id), "Protected office/two ships/warehouse/rope landmark retained " + row.id): return false
	for slot_kind: String in ["npcs", "interactions", "portals"]:
		if not check(equal(old.record.gameplay_slots[slot_kind], child.record.gameplay_slots[slot_kind]), "Every original identity/primary/foot/passage/arrival field unchanged " + slot_kind): return false
	if not _geometry_receipt(report): return false
	var raw := Image.load_from_file(author.raw_walk_path)
	var saved := Image.load_from_file(ROOT + "walk.png")
	if raw != null: raw.convert(Image.FORMAT_RGBA8)
	if saved != null: saved.convert(Image.FORMAT_RGBA8)
	if not check(raw != null and saved != null and saved.get_data() == child.walk_bytes and serial.bytes_sha(child.walk_bytes) == child.mask_sha and child.mask_sha == report.mask_sha256, "Full saved PNG/typed packet/hash RGBA identical"): return false
	if not _mask_delta(old, child, raw, report.geometry): return false
	var old_scene := ResourceLoader.load(author.parent_bundle_root + "scene.res", "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var old_layout := ResourceLoader.load(author.parent_bundle_root + "layout.res", "", ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var next_scene := ResourceLoader.load(ROOT + "scene.res", "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var next_layout := ResourceLoader.load(ROOT + "layout.res", "", ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not check(old_scene != null and old_layout != null and next_scene != null and next_layout != null, "Four actual native resources load, no constructed fake Field"): return false
	old_scene.map_layout = old_layout; next_scene.map_layout = next_layout
	if not check(equal(serial.storage(old_scene), old.scene_storage) and equal(serial.storage(old_layout), old.layout_storage) and equal(serial.storage(next_scene), child.scene_storage) and equal(serial.storage(next_layout), child.layout_storage), "All four native full typed storage graphs equal their packet authorities"): return false
	var expected_visuals: Array[Dictionary] = []
	for row: Dictionary in old_layout.visual_objects:
		if String(row.id) not in REMOVED: expected_visuals.append(row.duplicate(true))
	if not check(equal(expected_visuals, next_layout.visual_objects) and next_layout.walkable_mask_path == ROOT + "walk.png" and old_scene.has_meta(OLD_META) and not next_scene.has_meta(OLD_META) and next_scene.get_meta(NEW_META) == aa.AUTHOR_SHA, "Native exact two visuals disappear; only explicit walk/metadata successor"): return false
	var inverse := next_scene.duplicate(true) as SceneScript
	inverse.map_layout = next_layout.duplicate(true) as WalkableMapLayout
	inverse.map_layout.visual_objects = old_layout.visual_objects.duplicate(true); inverse.map_layout.walkable_mask_path = old_layout.walkable_mask_path
	inverse.remove_meta(NEW_META); inverse.set_meta(OLD_META, old_scene.get_meta(OLD_META))
	if not check(equal(serial.storage(inverse), serial.storage(old_scene)) and equal(serial.storage(inverse.map_layout), serial.storage(old_layout)), "Complete native Scene/layout inverse: all doors/returns/NPC/dialogues/ships/office untouched"): return false
	var expected_packet: Dictionary = old.duplicate(true)
	expected_packet.geometry_basis = BASIS; expected_packet.record = wanted_record
	expected_packet.solids = aa.c().object_solids(retained)
	expected_packet.walk_bytes = child.walk_bytes; expected_packet.mask_sha = serial.bytes_sha(child.walk_bytes)
	expected_packet.scene_storage = serial.storage(next_scene); expected_packet.layout_storage = serial.storage(next_layout)
	expected_packet["aa_author_sha256"] = aa.AUTHOR_SHA; expected_packet["aa_parent_record"] = old.record.duplicate(true)
	expected_packet["aa_district_parent_record"] = json(author.old_spacing_manifest).parent_record.duplicate(true)
	expected_packet["aa_parent_packet_sha256"] = old_manifest.artifacts[author.parent_bundle_root + "packet.bin"]
	if not check(equal(expected_packet, child), "Whole typed packet exact inverse; no unreviewed fields omitted"): return false
	return check(report.all_npcs_portals_returns_routes_exact == true and report.ground_image_unchanged == true and report.new_room_count == 0 and report.native_Physics_not_run == true and report.import_pending == true and report.not_formal == true and report.geometry_not_Field_credit == true, "Explicit publication credit boundaries: no import/Field/Physics/formal/room claim")

func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	var saves_before := saves(); var state_before := world_state()
	var self_path: String = get_script().resource_path
	sources[self_path] = fact(self_path)
	var complete := _exercise()
	var after: Dictionary = {}
	for path: String in sources: after[path] = fact(path)
	var saves_after := saves(); var state_after := world_state()
	if not check(sources == after and saves_before == saves_after and saves_before.size() == 15 and state_before == state_after, "All finite sources, fifteen save facts and in-memory task/flags/inventory/gold unchanged"): complete = false
	if not check(Time.get_ticks_msec() - began < BUDGET_MS, "Independent bounded60s before/after only; no whole city reraster/routes replay"): complete = false
	var folder := "res://build/luoyang_docks08_remove_two_qa_20261019aa/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var result := {"scope": "INDEPENDENT_REMOVE_TWO_NATIVE_PACKET_LOCAL_RASTER_NOT_FIELD", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "limit_ms": BUDGET_MS, "records": records, "source_before": sources, "source_after": after, "players_before": saves_before, "players_after": saves_after, "state_before": state_before, "state_after": state_after, "Field_credit": false, "Physics_credit": false, "import_credit": false, "formal_credit": false, "district08_art_complete": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file == null: failures += 1
	else: file.store_string(JSON.stringify(result, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)


