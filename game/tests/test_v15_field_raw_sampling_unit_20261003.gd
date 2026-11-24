extends SceneTree
## Synthetic native pixel-boundary unit only; no Field/GPU/production verdict.
const RAW := preload("res://tests/helpers/v15_field_raw_oracle.gd")
var checks := 0
var failures := 0
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[V15 raw sampling unit] " + label)

func _run() -> void:
	output = "res://build/world_map_v15_outskirts_qa/sampling_unit_%d/" % Time.get_ticks_usec()
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)), "unit evidence path is new, never overwrites historical capture")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "owned unit evidence directory created")
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var white_path: String = output + "synthetic_white.png"
	_check(image.save_png(white_path) == OK, "synthetic all-white original PNG saved only to unit-owned build path")
	var layout := WalkableMapLayout.new()
	layout.design_size = Vector2i(32, 32)
	layout.walkable_mask_path = white_path
	var native: RefCounted = RAW.new()
	_check(bool(native.call("configure", layout, "round_world_pixel", 0.0)), "explicit native direct-round/zero-margin unit contract")
	var last_x: Dictionary = native.call("pixel_evidence", Vector2(31.75, 12))
	var last_y: Dictionary = native.call("pixel_evidence", Vector2(12, 31.75))
	var last_corner: Dictionary = native.call("pixel_evidence", Vector2(31.75, 31.75))
	_check(bool(last_x.get("clear", false)) and last_x.get("pixel") == [31, 12], "valid last X half-pixel clamps to the original last texel")
	_check(bool(last_y.get("clear", false)) and last_y.get("pixel") == [12, 31], "valid last Y half-pixel clamps to the original last texel")
	_check(bool(last_corner.get("clear", false)) and last_corner.get("pixel") == [31, 31], "valid last half-pixel corner remains an actual source sample")
	for point: Vector2 in [Vector2(32, 12), Vector2(12, 32), Vector2(32.01, 31.75), Vector2(-.01, 12), Vector2(12, -.01)]:
		var record: Dictionary = native.call("pixel_evidence", point)
		_check(not bool(record.get("clear", true)) and record.get("kind") == "invalid_or_outside", "literal logical outside point rejected before any clamp: " + str(point))
	_check(bool(native.call("clear", Vector2(21.75, 16))), "all17 shoes inside including last-half-pixel right shoe remain legal")
	_check(not bool(native.call("clear", Vector2(22, 16))), "full17 rejects right shoe exactly at logical size, despite white edge texel")
	_check(bool(native.call("clear", Vector2(16, 25.75))), "all17 shoes including last-half-pixel bottom shoe remain legal")
	_check(not bool(native.call("clear", Vector2(16, 26))), "full17 rejects bottom shoe exactly at logical size")
	_check(bool(native.call("verify_sources")), "unit original PNG remains unchanged")
	native.call("release")
	native = null
	# Different texels make old normalized sampling distinguishable from native
	# literal rounding. This prevents the native fix silently changing old maps.
	for y in 32: image.set_pixel(31, y, Color.BLACK)
	var edge_path: String = output + "synthetic_black_last_column.png"
	_check(image.save_png(edge_path) == OK, "second original unit PNG saved without mutating the first")
	layout.walkable_mask_path = edge_path
	var legacy: RefCounted = RAW.new()
	native = RAW.new()
	_check(bool(legacy.call("configure", layout)), "legacy default normalized-image-round contract remains explicit")
	_check(bool(native.call("configure", layout, "round_world_pixel", 0.0)), "second native contract configured independently")
	var old_record: Dictionary = legacy.call("pixel_evidence", Vector2(30.6, 12))
	var new_record: Dictionary = native.call("pixel_evidence", Vector2(30.6, 12))
	_check(bool(old_record.get("clear", false)) and old_record.get("pixel") == [30, 12], "legacy normalized 30.6 coordinate still samples white texel30")
	_check(not bool(new_record.get("clear", true)) and new_record.get("pixel") == [31, 12], "native literal 30.6 coordinate samples original black texel31")
	_check(not bool((native.call("pixel_evidence", Vector2(31.75, 12)) as Dictionary).get("clear", true)), "edge clamp preserves real black-source denial, never turns invalid water white")
	var invalid: RefCounted = RAW.new()
	_check(not bool(invalid.call("configure", layout, "arbitrary_unknown_sampler", 0.0)), "unknown sampler stays failclosed")
	_check(bool(native.call("verify_sources")) and bool(legacy.call("verify_sources")), "original edge source hashes remain unchanged for both contracts")
	for owned: RefCounted in [native, legacy, invalid]: owned.call("release")
	native = null
	legacy = null
	invalid = null
	layout = null
	image = null
	var polygon_records: Array[Dictionary] = _legacy_polygon_cases()
	var result: Dictionary = {"schema": 1, "scope": "SYNTHETIC_RAW_PIXEL_AND_LEGACY_POLYGON_UNIT_NOT_FIELD_ACCEPTANCE", "checks": checks + 1, "failures": failures, "last_half_pixels": [last_x, last_y, last_corner], "legacy_sample": old_record, "native_sample": new_record, "legacy_polygon_records": polygon_records, "actual_Field_executed": false, "GPU_executed": false, "executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path), "oracle_sha256": FileAccess.get_sha256("res://tests/helpers/v15_field_raw_oracle.gd")}
	_check(_write_checked(result), "actual unit result persists with exact checked parsed readback")
	for settle in 4: await process_frame
	print("V15_RAW_SAMPLING_UNIT: %d checks / %d failures; output=%s" % [checks, failures, output])
	quit(0 if failures == 0 else 1)

func _legacy_polygon_cases() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var polygon := PackedVector2Array([Vector2(.2, .2), Vector2(.8, .2), Vector2(.8, .8), Vector2(.2, .8)])
	var layout := WalkableMapLayout.new()
	layout.design_size = Vector2i(64, 64)
	layout.walkable_regions = [polygon]
	var oracle: RefCounted = RAW.new()
	_check(bool(oracle.call("configure", layout)), "actual legacy empty-mask schema accepts original valid normalized polygon, not synthetic PNG")
	var inside: Dictionary = oracle.call("foot_evidence", Vector2(32, 32))
	var partial: Dictionary = oracle.call("foot_evidence", Vector2(15, 32))
	var outside: Dictionary = oracle.call("pixel_evidence", Vector2(4, 32))
	_check(bool(inside.get("clear", false)) and inside.get("kind") == "full17", "legacy polygon contains independently sampled complete17 shoes")
	_check(bool((oracle.call("pixel_evidence", Vector2(15, 32)) as Dictionary).get("clear", false)) and not bool(partial.get("clear", true)) and partial.get("kind") == "outside_original_legacy_polygons", "white polygon centre does not excuse a shoe outside its original union")
	_check(not bool(outside.get("clear", true)) and outside.get("kind") == "outside_original_legacy_polygons", "original polygon outside point denied")
	_check(not bool((oracle.call("pixel_evidence", Vector2(64, 32)) as Dictionary).get("clear", true)), "legacy polygon preserves literal canvas-domain rejection")
	records.append({"case": "legacy_original_polygon", "inside17": inside, "partial17": partial, "outside": outside})
	oracle.call("release")
	layout.blockers = [{"id": "unit_original_blocker", "pos": Vector2(.5, .5), "size": Vector2(.05, .05)}]
	_check(bool(oracle.call("configure", layout)), "legacy original blocker configured without zero-margin override")
	var blocked: Dictionary = oracle.call("foot_evidence", Vector2(40, 32))
	_check(not bool(blocked.get("clear", true)) and blocked.get("kind") == "source_collision" and blocked.get("id") == "unit_original_blocker", "legacy polygon full17 still respects original normalized .014 grown blocker")
	records.append({"case": "legacy_original_grown_blocker", "evidence": blocked})
	layout.blockers.clear()
	layout.walkable_regions = [PackedVector2Array([Vector2(.2, .2), Vector2(.8, .8)])]
	_check(not bool(oracle.call("configure", layout)), "legacy original two-point invalid polygon fails closed")
	layout.walkable_regions = [PackedVector2Array([Vector2(.2, .2), Vector2(1.1, .2), Vector2(.8, .8)])]
	_check(not bool(oracle.call("configure", layout)), "legacy normalized polygon outside source domain fails closed")
	layout.walkable_regions = [polygon]
	_check(not bool(oracle.call("configure", layout, "round_world_pixel", 0.0)), "native missing captured PNG cannot fall back to otherwise valid legacy polygon")
	layout.walkable_mask_path = output + "deliberately_absent_original.png"
	_check(not FileAccess.file_exists(layout.walkable_mask_path), "missing source negative really has no original PNG")
	_check(not bool(oracle.call("configure", layout)), "legacy explicitly declared missing PNG cannot fall back to polygon")
	_check(not bool(oracle.call("configure", layout, "round_world_pixel", 0.0)), "native explicitly declared missing PNG remains failclosed")
	layout.walkable_mask_path = ""
	layout.walkable_regions.clear()
	_check(not bool(oracle.call("configure", layout)), "legacy empty PNG and empty original union remain failclosed")
	oracle.call("release")
	oracle = null
	layout = null
	return records

func _write_checked(value: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	file = null
	return error == OK and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) == JSON.parse_string(JSON.stringify(value))
