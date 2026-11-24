extends "res://tests/test_luoyang_docks08_remove_two_cpu_ready_20261019aa.gd"
## Independent AC delta only; inherited fact/raster helpers, never inherited AA exercise.
const ACROOT = "res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/"
const ACAPI = "res://scripts/city/luoyang_docks_workyard_20261019ac.gd"
const ACPUB = "res://build/luoyang_docks_workyard_20261019ac_cpu/114284/result.json"
const ACART = "res://build/luoyang_docks_workyard_20261019ac_art01/layout_contract.json"
const ACBASIS = "DOCKS_WORKYARD_EXACT_ADD_FOUR_LOCAL_GEOMETRY_20261019ac"
const ACMETA = "luoyang_docks_workyard_20261019ac"
const IMPORT_PROOF = "res://build/luoyang_docks_workyard_20261019ac_qa01/isolate/ac_mask_import_result_118860.json"
var ac: Script
func _mask_delta(old: Dictionary, child: Dictionary, raw: Image, geometry: Dictionary) -> bool:
	var before: PackedByteArray = old.walk_bytes; var after: PackedByteArray = child.walk_bytes
	var raw_bytes := raw.get_data()
	if not check(before.size() == 3072 * 2048 * 4 and after.size() == before.size() and raw_bytes.size() == before.size(), "Actual complete 3072x2048 RGBA mask byte domains"): return false
	var old_shapes := polygons(old.record.objects); var new_shapes := polygons(child.record.objects)
	var boxes: Array[Rect2i] = []
	for object: Dictionary in child.record.objects.slice(25):
		for shape: Dictionary in polygons([object]):
			if not check(not shape.has("rect"), "All four new native bases are explicit polygons " + String(object.id)): return false
			var low: Vector2 = shape.low; var high: Vector2 = shape.high
			boxes.append(Rect2i(Vector2i(floori(low.x) - 1, floori(low.y) - 1), Vector2i(ceili(high.x) - floori(low.x) + 3, ceili(high.y) - floori(low.y) + 3)))
	var changed := 0; var locally_checked := 0
	var per_prop := [0,0,0,0]
	var black := PackedByteArray([0, 0, 0, 255]); var white := PackedByteArray([255, 255, 255, 255])
	for y: int in 2048:
		if Time.get_ticks_msec() - began >= BUDGET_MS: return check(false, "Fixed60s independent delta audit budget")
		var left := 3072; var right := -1
		for box: Rect2i in boxes:
			if y >= box.position.y and y < box.end.y: left = mini(left, box.position.x); right = maxi(right, box.end.x)
		var start := y * 3072 * 4
		if right < 0:
			if not check(before.slice(start, start + 3072 * 4) == after.slice(start, start + 3072 * 4), "Entire RGBA row outside new native raster is unchanged " + str(y)): return false
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
				if not pixel_equal(before, offset, white) or not pixel_equal(after, offset, black): return check(false, "Only white255 to black255 blocking; never alpha/color/water edits", [x, y])
				changed += 1
				var memberships := 0
				for i: int in 4:
					if blocked(point,polygons([child.record.objects[25+i]])):
						per_prop[i] += 1; memberships += 1
				if memberships != 1: return check(false,"Changed pixel belongs to exactly one authorized new solid",[x,y])
			locally_checked += 1
	if not check(changed == 19594 and geometry.mask_delta.blocked_pixels == changed and per_prop == [2869,1968,12789,1968], "Independent total and all four per-prop changed counts exactly equal authorized add-only counters", [changed,per_prop]): return false
	records.append({"kind": "INDEPENDENT_LOCAL_INTEGER_RASTER_PLUS_ALL_OTHER_RGBA_UNCHANGED", "changed_pixels": changed, "local_pixels_recomputed": locally_checked, "all_other_pixels_byte_exact": true, "no_whole_city_geometry_rerun": true})
	return true


func _geometry_receipt(report: Dictionary) -> bool:
	var g: Dictionary = report.geometry
	var routes: Dictionary = g.original_routes
	var combined: Dictionary = g.combined
	var delta: Dictionary = g.mask_delta
	if not check(g.passed == true and g.four_new_solids == 4 and g.full87517 == true and g.local_approach_samples == 624 and g.max_step_px == 4 and wire_equal(g.npc_continuous_body_px, [34,30]) and g.moving_domains_no_new_overlap == true and g.original_25_and_gameplay_unchanged == true, "Actual NEW four-solid geometry receipt, no rerun or Field credit"): return false
	if not check(routes.passed == true and routes.all_routes_and_crowd_samples == 2739 and routes.crowd_samples == 264 and routes.crowd_count == 10 and routes.moving == 6 and routes.stationary == 4 and routes.full875_and17 == true and routes.max_step_px == 4 and wire_equal(routes.npc_envelope_px,[34,30]) and routes.dynamic_avoidance_promised == false, "Pinned actual original route/crowd component fields"): return false
	if not check(combined.passed == true and combined.samples == 2812 and combined.district_polygons == 10 and combined.full87517 == true and combined.max_step_px == 4 and wire_equal(combined.npc_continuous_body_px,[34,30]) and combined.all_original_routes_and_six_moving_lanes == true, "Pinned actual combined District component fields"): return false
	return check(delta.passed == true and delta.blocked_pixels == 19594 and wire_equal(delta.per_prop_blocked_pixels,[2869,1968,12789,1968]) and delta.integer_point_polygon_membership_exact == true and delta.old_blocked_never_restored == true and delta.unchanged_pixels_all_RGBA_exact == true, "Pinned new add-only raster counters")

func _exercise() -> bool:
	if not check(OS.get_cmdline_user_args().is_empty(), "Independent delta CPU no flags, no Field"): return false
	for row: Array in [
		[ACPUB,"bb6aeef4a5faf77f2376671e6942946276af33374bedf9566c2fb67ad670fd34"],
		[ACAPI,"71f57304c3da2a78b5ca16ff10f2b4dae89485f358015f16477cabc178a3b0c5"],
		[ACART,"2004f7fe1c2b56e163c4e514eda49248d951a7d9d0645b32129d2a7754f04bdf"],
		[IMPORT_PROOF,"b5ce9ce5154db24fb590f39afb417c0eae600087ab1c60f2904342024b79a30b"],
		["res://tests/test_luoyang_docks08_remove_two_cpu_ready_20261019aa.gd","1e09dbfd06d449091c744b3d6f0d00a111dec0136f628567058507f6bade85ae"]]:
		if not track(row[0],row[1]): return false
	var report: Dictionary = json(ACPUB)
	if not check(report.passed == true and report.error == "" and report.elapsed_ms < 60000 and report.limit_ms == 60000 and report.source_first.size() == 57 and report.source_first == report.source_final, "One Root actual publisher result complete, all57 sources unchanged"): return false
	for path: String in report.source_first:
		if not track(path,report.source_first[path]): return false
	for path: String in report.artifacts:
		if not track(path,report.artifacts[path]): return false
	if not track(ACROOT+"walk.png","efb5ad36eda76ed346c66a1fdb82326e221824d95bf6888fef51626392d929d8"): return false
	serial = load(SERIAL); ac = load(ACAPI)
	if not check(serial is GDScript and serial.can_instantiate() and ac is GDScript and ac.can_instantiate(), "Runtime dependencies compile before any API use"): return false
	var author: Dictionary = ac.author()
	var art: Dictionary = json(ACART)
	if not check(not author.is_empty() and author.props.size() == 4 and art.placements.size() == 4 and report.parent_count == 25 and report.child_count == 29 and report.geometry_basis == ACBASIS and report.author_sha256 == ac.AUTHOR_SHA, "Frozen exact four slots and25to29 contract"): return false
	var parent: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(author.parent_bundle_root+"packet.bin"))
	var child: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(ACROOT+"packet.bin"))
	if not check(parent.record.objects.size() == 25 and child.record.objects.size() == 29 and equal(child.record.objects.slice(0,25),parent.record.objects), "Every first25 complete rows retains order, types, fields and values"): return false
	var wanted: Dictionary = parent.record.duplicate(true)
	wanted.objects = parent.record.objects.duplicate(true)
	wanted.walk_path = ACROOT+"walk.png"; wanted["ac_geometry_basis"] = ACBASIS; wanted["ac_author_sha256"] = ac.AUTHOR_SHA
	var expected_visuals: Array[Dictionary] = []
	var old_scene := ResourceLoader.load(author.parent_bundle_root+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var old_layout := ResourceLoader.load(author.parent_bundle_root+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var child_scene := ResourceLoader.load(ACROOT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var child_layout := ResourceLoader.load(ACROOT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not check(old_scene != null and old_layout != null and child_scene != null and child_layout != null,"Four actual native resources load"): return false
	old_scene.map_layout = old_layout; child_scene.map_layout = child_layout
	for visual: Dictionary in old_layout.visual_objects: expected_visuals.append(visual.duplicate(true))
	for i: int in 4:
		var placement: Dictionary = art.placements[i]
		var prop: Dictionary = author.props[i]
		if not check(prop.id == "workyard_"+placement.id and prop.art_placement_id == placement.id and prop.role == "workyard_low_prop" and prop.texture == placement.asset_path and prop.source == placement.asset_path and prop.source_sha256 == String(placement.asset_sha256).to_lower() and prop.source_scale == placement.source_scale and wire_equal(prop.source_size_px,placement.source_size_px) and wire_equal(prop.world_foot_px,placement.foot_px) and wire_equal(prop.physical_center_px,placement.foot_px) and wire_equal(prop.render_size_px,placement.render_size_px) and wire_equal(prop.foot_uv,placement.foot_uv) and wire_equal(prop.solid_polygons_px,[placement.solid_polygon_px]) and prop.ac_group_id == placement.group_id and prop.blocking == true and prop.ghost_occlusion == true and wire_equal(prop.collision_size_px,[0,0]),"Independent ART exact slot "+placement.id): return false
		if not check(equal(child.record.objects[25+i],prop),"Appended exact authored row "+prop.id): return false
		wanted.objects.append(prop.duplicate(true))
		var render := vec(placement.render_size_px)
		var foot := vec(placement.foot_px)
		var uv := vec(placement.foot_uv)
		var expected: Dictionary = prop.duplicate(true)
		expected["pos"] = (foot+(Vector2(0.5,0.5)-uv)*render)/Vector2(3072,2048)
		expected["render_size_px"] = render
		expected["centered"] = true; expected["sort_by_feet"] = true
		expected["city_v3_solid_polygons_px"] = expected.solid_polygons_px.duplicate(true)
		expected["depth_sort_foot_y"] = foot.y/2048.0
		expected.erase("solid_polygons_px")
		expected_visuals.append(expected)
	if not check(equal(wanted,child.record),"Whole record only append4/walk/declared AC metadata"): return false
	if not check(equal(serial.storage(old_scene),parent.scene_storage) and equal(serial.storage(old_layout),parent.layout_storage) and equal(serial.storage(child_scene),child.scene_storage) and equal(serial.storage(child_layout),child.layout_storage),"Four native full typed storage equal actual packets"): return false
	if not check(equal(expected_visuals,child_layout.visual_objects) and child_layout.walkable_mask_path == ACROOT+"walk.png" and child_scene.get_meta(ACMETA) == ac.AUTHOR_SHA and child_scene.get_meta(NEW_META) == old_scene.get_meta(NEW_META),"Independent native4 visual transformation plus AA ancestry unchanged"): return false
	var inverse := child_scene.duplicate(true) as SceneScript
	inverse.map_layout = child_layout.duplicate(true) as WalkableMapLayout
	inverse.map_layout.visual_objects = old_layout.visual_objects.duplicate(true)
	inverse.map_layout.walkable_mask_path = old_layout.walkable_mask_path
	inverse.remove_meta(ACMETA)
	if not check(equal(serial.storage(inverse),serial.storage(old_scene)) and equal(serial.storage(inverse.map_layout),serial.storage(old_layout)),"Whole native inverse preserves every NPC/dialogue/door/ship/office/return field"): return false
	var expected_packet: Dictionary = parent.duplicate(true)
	expected_packet.geometry_basis = ACBASIS; expected_packet.record = wanted
	expected_packet.solids = ac.c().object_solids(wanted.objects)
	expected_packet.walk_bytes = child.walk_bytes; expected_packet.mask_sha = serial.bytes_sha(child.walk_bytes)
	expected_packet.scene_storage = serial.storage(child_scene); expected_packet.layout_storage = serial.storage(child_layout)
	expected_packet["ac_author_sha256"] = ac.AUTHOR_SHA; expected_packet["ac_parent_record"] = parent.record.duplicate(true)
	expected_packet["ac_parent_packet_sha256"] = "69da39b21c56d4598dd4e5e8d3b9cfd9912823ee4c8c8c3cc0ad99f77e03aa1e"
	if not check(equal(expected_packet,child),"Whole typed packet independent old+finite delta including original AA/Harbour28 ancestry"): return false
	if not _geometry_receipt(report): return false
	var proof: Dictionary = json(IMPORT_PROOF)
	if not check(proof.passed == true and proof.checks == 60 and proof.failures.is_empty() and proof.source_first == proof.source_last and proof.row.full_rgba_exact == true and proof.row.params23 == true and proof.row.zero_mipmaps == true and proof.row.cpu_evidence_exact == true and proof.row.rgba_sha256 == child.mask_sha and proof.row.cpu_packet_sha256 == report.artifacts[ACROOT+"packet.bin"],"Single newmask actual isolated import receipt only"): return false
	if not track(proof.row.import_path,proof.row.import_sha256) or not track(proof.row.compiled_path,proof.row.compiled_sha256): return false
	if not check(report.texture_proofs.passed == true and report.texture_proofs.instances == 4 and report.texture_proofs.unique_textures == 3 and report.texture_proofs.rows.size() == 3,"Consume already-actual three texture proofs; never rerun imports"): return false
	for row: Dictionary in report.texture_proofs.rows:
		if not check(row.full_rgba_exact == true and row.params23 == true and row.zero_mipmaps == true,"Already actual texture complete RGBA/settings "+row.texture): return false
	var raw := Image.load_from_file(author.raw_walk_path)
	var saved := Image.load_from_file(ACROOT+"walk.png")
	if raw != null: raw.convert(Image.FORMAT_RGBA8)
	if saved != null: saved.convert(Image.FORMAT_RGBA8)
	if not check(raw != null and saved != null and saved.get_data() == child.walk_bytes and child.mask_sha == "733709ffc4c79143c0ca073e7c5564350a51a589c9d21298fc34c90abecc2a84","Actual raw/source mask and saved PNG fullRGBA domain"): return false
	if not _mask_delta(parent,child,raw,report.geometry): return false
	records.append({"kind":"AC_ONLY_APPEND_FOUR_COMPLETE_NATIVE_PACKET_INVERSE","old_count":25,"new_count":29,"old_gameplay_unchanged":true,"geometry_receipt_consumed_not_rerun":true,"new_Field_credit":false})
	return check(report.whole_typed_packet_inverse == true and report.all_npcs_portals_returns_routes_exact == true and report.ground_image_unchanged == true and report.new_room_count == 0 and report.native_Physics_not_run == true and report.not_formal == true and report.geometry_not_Field_credit == true,"No old CPU receipt promoted into Field/nativePhysics/runtime credit")

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
	var folder := "res://build/luoyang_docks_workyard_20261019ac_qa01/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var result := {"scope": "INDEPENDENT_ADD_FOUR_NATIVE_PACKET_LOCAL_RASTER_NOT_FIELD", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "limit_ms": BUDGET_MS, "records": records, "source_before": sources, "source_after": after, "players_before": saves_before, "players_after": saves_after, "state_before": state_before, "state_after": state_after, "Field_credit": false, "Physics_credit": false, "import_credit": false, "formal_credit": false, "district08_art_complete": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file == null: failures += 1
	else: file.store_string(JSON.stringify(result, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)




