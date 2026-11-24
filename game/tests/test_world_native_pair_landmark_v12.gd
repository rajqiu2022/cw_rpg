extends "res://scripts/dev/run_world_native_pair_landmark_v12.gd"

# First full native v12 candidate suite. Old v11 STATIC WIP stays read-only.
# Parser success is not runtime/API or visual acceptance. READY is required
# before Field; body-ground shadows and current-frame alpha are independently
# recomputed below. No render/import hooks are called by this test.
const BASE_V10 := preload("res://scripts/dev/world_native_pair_landmark_contract_v10.gd")
const V12_GEOMETRY := preload("res://scripts/dev/build_world_map_native_pair_ortho_v12.gd")
const ORIGINAL_V11_GEOMETRY := preload("res://scripts/dev/build_world_map_native_pair_ortho_v11.gd")
const V10_GEOMETRY := preload("res://scripts/dev/build_world_map_native_pair_ortho_v10.gd")
const REPLACED_IDS := ["cc0_boulder_west", "generated_shrub_west", "cc0_boulder_east_low", "grove_east_a"]
const REPLACED_ROCKS := ["cc0_boulder_west", "cc0_boulder_east_low"]
const REPLACED_GRASS := ["generated_shrub_west", "grove_east_a"]
const APPROVED_SOURCE_HEIGHT_ROI := Rect2i(120,160,440,200)
const APPROVED_PROJECTED_TERRAIN_ROI := Rect2i(64,0,576,400)
const APPROVED_ENTITY_VISUAL_ROIS := [Rect2i(710,470,290,270),Rect2i(1100,635,170,180),Rect2i(1750,505,320,285),Rect2i(2200,785,170,180)]

var failures := 0
var checks := 0
var route_probes := 0


func _numeric_equal(actual: Variant, expected: Variant) -> bool:
	if (actual is int or actual is float) and (expected is int or expected is float):
		return absf(float(actual)-float(expected)) < 0.00002
	if actual is Array and expected is Array:
		if actual.size() != expected.size():
			return false
		for index in actual.size():
			if not _numeric_equal(actual[index],expected[index]):
				return false
		return true
	if actual is Dictionary and expected is Dictionary:
		if actual.size() != expected.size():
			return false
		for key in expected:
			if not actual.has(key) or not _numeric_equal(actual[key],expected[key]):
				return false
		return true
	return actual == expected


func _hash_bytes(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()


func _v12_body_capture_check(data: Dictionary) -> Image:
	var id: String = data["id"]
	var path: String = CONTRACT.PREFIX+"sourcebody_"+id+".png"
	var repeat_path: String = CONTRACT.PREFIX+"sourcebody_"+id+"_repeat.png"
	var body := _read_png(path)
	var repeated := _read_png(repeat_path)
	var crop := _read_png(CONTRACT.PREFIX+"entity_"+id+".png")
	var readable := body != null and repeated != null and crop != null
	_check(readable, "fresh whole-canvas body/repeat and new cropped runtime alpha are readable: "+id)
	if not readable:
		return null
	var rect := body.get_used_rect()
	var transparent_corners := true
	for corner in [Vector2i.ZERO,Vector2i(3071,0),Vector2i(0,1023),Vector2i(3071,1023)]:
		if body.get_size() != Vector2i(3072,1024) or body.get_pixelv(corner).a != 0.0:
			transparent_corners = false
	var valid := body.get_format() == Image.FORMAT_RGBA8 and body.get_size() == Vector2i(3072,1024) and rect.has_area() and rect.size.x < 1536 and rect.size.y < 512 and transparent_corners
	_check(valid, "actual body is nonempty localized RGBA8 with all transparent corners, never full opaque background: "+id)
	_check(data.get("sourcebody_path") == path and data.get("sourcebody_repeat_path") == repeat_path and _numeric_equal(data.get("sourcebody_canvas"),[3072,1024])
		and data.get("sourcebody_valid",false) and data.get("sourcebody_repeat_exact",false), "current entity metadata binds its own whole-source repeat capture: "+id)
	_check(body.get_data() == repeated.get_data() and FileAccess.get_sha256(path) == FileAccess.get_sha256(repeat_path)
		and data.get("sourcebody_png_sha") == FileAccess.get_sha256(path) and data.get("sourcebody_repeat_png_sha") == FileAccess.get_sha256(repeat_path), "actual sourcebody pixel and PNG SHA repeat exactly: "+id)
	if not valid:
		return null
	var crop_rect := rect.grow(4).intersection(Rect2i(0,0,3072,1024))
	var foot := Vector2(data["world_foot"][0],data["world_foot"][1])
	var uv := Vector2(data["foot_uv"][0],data["foot_uv"][1])
	_check(crop.get_data() == body.get_region(crop_rect).get_data() and crop.get_size() == crop_rect.size
		and (foot-uv*Vector2(crop_rect.size)).distance_to(Vector2(crop_rect.position)) < 0.01
		and _numeric_equal(data.get("projected_used_rect"),[rect.position.x,rect.position.y,rect.size.x,rect.size.y]),
		"runtime alpha is exact fresh wholebody crop and its measured foot transform, not reused old entity sprite: "+id)
	return body


func _independent_mesh_nodes(node: Node, found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		_independent_mesh_nodes(child,found)


func _v12_actual_source_vertices(data: Dictionary, spec: Dictionary, topology: Image, terrain: Object) -> void:
	var id: String = data["id"]
	var packed := load(String(data["source_path"])) as PackedScene
	_check(packed != null, "original licensed source model can reconstruct actual vertices: "+id)
	if packed == null:
		return
	var imported := packed.instantiate()
	var meshes: Array[MeshInstance3D] = []
	_independent_mesh_nodes(imported,meshes)
	var variant: int = int(spec["variant"])
	_check(variant >= 0 and variant < meshes.size(), "approved individual primitive exists, not catalogue group alias: "+id)
	if variant < 0 or variant >= meshes.size():
		imported.free()
		return
	var vertices: Array[Vector3] = []
	var bounds := AABB()
	var basis := Basis(Vector3.UP,deg_to_rad(float(spec["yaw"]))).scaled(Vector3.ONE*float(spec["scale"]))
	for surface in meshes[variant].mesh.get_surface_count():
		var arrays := meshes[variant].mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for source in positions:
			var point: Vector3 = basis*source
			bounds = AABB(point,Vector3.ZERO) if vertices.is_empty() else bounds.expand(point)
			vertices.append(point)
	imported.free()
	var support := AABB()
	var support_count := 0
	for point in vertices:
		if point.y > bounds.position.y+bounds.size.y*0.06:
			continue
		support = AABB(point,Vector3.ZERO) if support_count == 0 else support.expand(point)
		support_count += 1
	_check(not vertices.is_empty() and support_count > 0 and int(data.get("actual_vertex_count",-1)) == vertices.size()
		and int(data.get("support_vertex_count",-1)) == support_count, "source count and lowest-six-percent support independently recomputed from all actual vertices: "+id)
	var foot: Vector2 = spec["foot"]
	var ground := Vector3((foot.x/3072.0-0.5)*30.0,float(terrain.call("terrain_height",foot,topology)),(foot.y/1024.0-0.5)*14.1421356)
	var local_foot := Vector3(support.get_center().x,bounds.position.y,support.end.z)
	var expected_position := ground-local_foot
	var position := Vector3(data["cast_source_transform"][0],data["cast_source_transform"][1],data["cast_source_transform"][2])
	_check(position.distance_to(expected_position) < 0.00001 and absf(position.y+bounds.position.y-ground.y) < 0.00001
		and absf(float(data.get("actual_vertex_min_y_minus_ground",999))) < 0.00001, "actual lowest vertex rests on terrain and front-XZ foot owns real caster translation: "+id)
	_check(_numeric_equal(data.get("model_bounds_m"),[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z])
		and _numeric_equal(data.get("support_bounds_m"),[support.position.x,support.position.y,support.position.z,support.size.x,support.size.y,support.size.z])
		and data.get("bounds_method") == "all_actual_mesh_vertices_after_yaw_scale_not_rotated_AABB_corners"
		and data.get("support_method") == "lowest_six_percent_height_actual_vertices_front_z_min_y", "source bounds are true transformed vertices, never rotated AABB corner extremities: "+id)
	var projected := Vector2(1536.0+ground.x*1024.0/10.0,512.0+(ground.z-ground.y)*sqrt(0.5)*1024.0/10.0)
	var actual_foot := Vector2(data["world_foot"][0],data["world_foot"][1])
	var expected_size := Vector2(bounds.size.x*3072.0/30.0,bounds.size.z*1024.0/14.1421356)
	var expected_center := projected+Vector2((bounds.get_center().x-local_foot.x)*3072.0/30.0,(bounds.get_center().z-local_foot.z)*1024.0/14.1421356)
	var actual_center := Vector2(data["collision_center"][0],data["collision_center"][1])
	var actual_size := Vector2(data["collision_size"][0],data["collision_size"][1])
	_check(actual_foot.distance_to(projected) < 0.01 and absf(float(data["world_base_y"])-projected.y) < 0.01
		and actual_center.distance_to(expected_center) < 0.01 and actual_size.distance_to(expected_size) < 0.01, "independent ortho projection binds source foot/depth and full XZ physical extent: "+id)


func _v12_index_only_checks(terrain: Object, topology: Image) -> void:
	var original_builder := ORIGINAL_V11_GEOMETRY.new()
	var original: ArrayMesh = original_builder.call("_mesh",topology,false)
	var actual: ArrayMesh = terrain.call("_mesh",topology,false)
	original_builder.free()
	var before: Array = original.surface_get_arrays(0)
	var after: Array = actual.surface_get_arrays(0)
	var vertices: PackedVector3Array = before[Mesh.ARRAY_VERTEX]
	var old_indices: PackedInt32Array = before[Mesh.ARRAY_INDEX]
	var new_indices: PackedInt32Array = after[Mesh.ARRAY_INDEX]
	var preserved := true
	for slot in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV]:
		preserved = preserved and _hash_bytes(before[slot].to_byte_array()) == _hash_bytes(after[slot].to_byte_array())
	var exact_swap := old_indices.size() == new_indices.size() and old_indices.size()%3 == 0
	var positive := 0
	var negative := 0
	var degenerate := 0
	if exact_swap:
		for offset in range(0,old_indices.size(),3):
			exact_swap = exact_swap and new_indices[offset] == old_indices[offset] and new_indices[offset+1] == old_indices[offset+2] and new_indices[offset+2] == old_indices[offset+1]
			var a := vertices[old_indices[offset]]
			var b := vertices[old_indices[offset+1]]
			var c := vertices[old_indices[offset+2]]
			var sign_y := (b.z-a.z)*(c.x-a.x)-(b.x-a.x)*(c.z-a.z)
			positive += 1 if sign_y > 0.0 else 0
			var ar: Vector3 = after[Mesh.ARRAY_VERTEX][new_indices[offset]]
			var br: Vector3 = after[Mesh.ARRAY_VERTEX][new_indices[offset+1]]
			var cr: Vector3 = after[Mesh.ARRAY_VERTEX][new_indices[offset+2]]
			var reversed_sign := (br.z-ar.z)*(cr.x-ar.x)-(br.x-ar.x)*(cr.z-ar.z)
			negative += 1 if reversed_sign < 0.0 else 0
			degenerate += 1 if sign_y == 0.0 or reversed_sign == 0.0 else 0
	var old_packed: Array = original.get("_surfaces")
	var new_packed: Array = actual.get("_surfaces")
	var exact_other_fields := old_packed.size() == new_packed.size()
	for surface in range(mini(old_packed.size(),new_packed.size())):
		for key in old_packed[surface]:
			if key != "index_data":
				exact_other_fields = exact_other_fields and old_packed[surface][key] == new_packed[surface].get(key)
	_check(preserved and exact_other_fields and exact_swap and positive == 36800 and negative == 36800 and degenerate == 0, "independent full builder mesh matches old actual v11 vertices/UV/normals/packed fields; ONLY all 36800 indices reverse with no degeneration")
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX+"art.json"))
	var facts: Dictionary = record.get("mesh_winding",{})
	var actual_facts := {"triangle_count":old_indices.size()/3,
		"vertex_SHA":_hash_bytes(before[Mesh.ARRAY_VERTEX].to_byte_array()),
		"normal_SHA":_hash_bytes(before[Mesh.ARRAY_NORMAL].to_byte_array()),
		"UV_SHA":_hash_bytes(before[Mesh.ARRAY_TEX_UV].to_byte_array()),
		"before_index_SHA":_hash_bytes(old_indices.to_byte_array()),"after_index_SHA":_hash_bytes(new_indices.to_byte_array())}
	var agrees := true
	for key in actual_facts:
		agrees = agrees and facts.get(key) == actual_facts[key]
	_check(agrees and facts.get("only_index_changed",false) and facts.get("exact_triangle_swap_asserted",false), "actual imported capture mesh SHA and winding metadata bind independently rebuilt new implementation")
	var plane := PlaneMesh.new()
	var plane_arrays := plane.surface_get_arrays(0)
	var pv: PackedVector3Array = plane_arrays[Mesh.ARRAY_VERTEX]
	var pi: PackedInt32Array = plane_arrays[Mesh.ARRAY_INDEX]
	var all_negative := true
	for offset in range(0,pi.size(),3):
		var a := pv[pi[offset]]
		var b := pv[pi[offset+1]]
		var c := pv[pi[offset+2]]
		all_negative = all_negative and (b.z-a.z)*(c.x-a.x)-(b.x-a.x)*(c.z-a.z) < 0.0
	_check(all_negative and pi.size() == 6, "actual engine PlaneMesh negative winding remains independent control")
	print("[WorldLandmarkV12 mesh winding] original_positive=%d reversed_negative=%d degenerate=%d" % [positive,negative,degenerate])


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[WorldLandmarkV12 FAIL] " + message)


func _save_snapshot() -> Dictionary:
	var result := {}
	var saves := root.get_node("SaveManager")
	for slot in range(5):
		for path: String in [saves.slot_path(slot), saves.slot_backup_path(slot)]:
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return result


func _stored_stats(stats: Resource) -> Dictionary:
	var result := {}
	if stats == null:
		return result
	for property in stats.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var value: Variant = stats.get(property["name"])
		result[property["name"]] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result


func _gameplay_snapshot() -> Dictionary:
	var state := root.get_node("GameState")
	var result := {"player":_stored_stats(state.player),"party":[]}
	for member in state.party:
		result["party"].append(_stored_stats(member))
	for name in ["gold","current_chapter","flags","player_faction","skill_mastery","pending_skill_unlocks","training_points_total","training_points_available","reputation","sparring_records"]:
		var value: Variant = state.get(name)
		result[name] = value.duplicate(true) if value is Dictionary or value is Array else value
	for name in ["Inventory","QuestManager","BountyManager","InvestigationState"]:
		var singleton := root.get_node(name)
		_check(singleton.has_method("to_dict"), "real gameplay serializer exists for isolation snapshot: "+name)
		result[name] = singleton.call("to_dict").duplicate(true)
	return result


func _old_source_snapshot() -> Dictionary:
	var result := {}
	for path in ["res://tests/test_world_native_pair_landmark_v9.gd","res://tests/test_world_native_pair_landmark_v10.gd","res://tests/test_world_native_pair_landmark_v11.gd",
		"res://tests/test_native_shadow_v12.gd","res://tests/test_native_shadow_transition_v12.gd","res://tests/test_native_shadow_mesh_v12.gd"]:
		result[path] = FileAccess.get_sha256(path)
	var directory := DirAccess.open("res://build")
	for filename in directory.get_files():
		if filename.begins_with("world_native_pair_ortho_v9_") or filename.begins_with("world_native_pair_ortho_v10_") or filename.begins_with("world_native_pair_ortho_v11_") or filename.begins_with("native_shadow_v12_") or filename.begins_with("native_shadow_transition_v12_") or filename.begins_with("native_shadow_mesh_v12_"):
			result["res://build/"+filename] = FileAccess.get_sha256("res://build/"+filename)
	return result


func _walks(point: Vector2) -> bool:
	return bool(field.call("_is_inside_walkable_screen", field.world_container.to_global(point)))


func _foot_clear(point: Vector2) -> bool:
	return bool(field.call("_spawn_has_foot_clearance", field._current_scene, point / Vector2(field._world_size)))


func _run_tests() -> void:
	if not _v12_ready_preflight():
		print("[WorldLandmarkV12 PRECHECK] checks=%d failures=%d; candidate refused BEFORE Field load; full runtime/GPU suite NOT RUN" % [checks,failures])
		quit(1)
		return
	var saves_before := _save_snapshot()
	var flags_before: Dictionary = root.get_node("GameState").flags.duplicate(true)
	var gameplay_before := _gameplay_snapshot()
	var old_source_before := _old_source_snapshot()
	if not await start_preview():
		return
	if "--rock-diagnostic-only" in OS.get_cmdline_user_args():
		await _v12_original_rock_diagnostics()
		_check(_save_snapshot() == saves_before and _gameplay_snapshot() == gameplay_before, "diagnostic leaves saves/gameplay untouched")
		restore_preview_state()
		print("[WorldLandmarkV12 rock diagnostic ONLY] original failed stations logged; full suite NOT REPEATED/GPU NOT RUN")
		quit(0 if failures == 0 else 1)
		return
	_check(field._world_size == CONTRACT.WORLD_SIZE, "native 3072x1024 world preserves geometry")
	_check(field._current_scene.scene_id == CONTRACT.LAB_ID, "runtime-only lab is active")
	_check(field._current_scene.on_enter_dialog == null and field._current_scene.npcs.is_empty(), "no plot or reward NPCs in preview")
	_v12_local_contract_checks()
	await _v12_replacement_object_checks()
	var routes := CONTRACT.route_points()
	_check(routes.size() >= 90, "projected source route has enough samples")
	_check(not routes.is_empty() and routes[-1].distance_to(CONTRACT.FERRY_SPUR[0]) < 0.01, "main road ends exactly at ferry spur start without an unsampled tail")
	for index in range(1, routes.size()):
		var start: Vector2 = routes[index - 1]
		var finish: Vector2 = routes[index]
		var steps := maxi(1, ceili(start.distance_to(finish) / 4.0))
		for step in range(steps + 1):
			var foot := start.lerp(finish, float(step) / steps)
			_check(_walks(foot) and _foot_clear(foot), "continuous main road clears full foot at %s" % foot)
			route_probes += 1
	for spur in [CONTRACT.CITY_SPUR, CONTRACT.FERRY_SPUR]:
		var from: Vector2 = spur[0]
		var to: Vector2 = spur[1]
		var count := maxi(1, ceili(from.distance_to(to) / 4.0))
		for index in range(count + 1):
			var foot := from.lerp(to, float(index) / count)
			_check(_walks(foot) and _foot_clear(foot), "landmark spur clears full foot at %s" % foot)
	_surface_support_checks()
	_terrain_boundary_checks()
	_slope_semantics_checks()
	_dock_support_checks()
	_dock_foreground_exclusion_checks()
	_inherited_prop_land_checks()
	# Explicit bridge deck exception: water on both sides, real rails do not open.
	for x in range(1425, 1896, 10):
		_check(_walks(Vector2(x, 365)) and _foot_clear(Vector2(x, 365)), "deck traversable x=%d" % x)
	# Current measured slope witnesses follow v9 relief; water/rails remain strict.
	for foot in [Vector2(1660, 325), Vector2(1660, 398), Vector2(1660, 295), Vector2(1660, 440), Vector2(2900, 650), Vector2(2600, 900)]:
		_check(not _walks(foot), "rail/water negative blocked at %s" % foot)
	for blocker in CONTRACT.blockers():
		var foot: Vector2 = blocker["pos"] * CONTRACT.WORLD_SIZE
		_check(not _walks(foot), "paired independent blocker: " + String(blocker["id"]))
	for landmark in CONTRACT.landmarks():
		_check(_walks(landmark["entry"]) and _foot_clear(landmark["entry"]), "landward entry full foot: " + String(landmark["id"]))
	_depth_checks()
	_rail_part_depth_checks()
	await _movement_checks()
	await _seam_movement_checks()
	await _dock_movement_checks()
	await _capture("city", Vector2(900, 390))
	await _capture("bridge", Vector2(1660, 365))
	for station in [{"label": "bridge_front", "foot": Vector2(1660, 376)}, {"label": "bridge_back", "foot": Vector2(1660, 355)}]:
		_check(_foot_clear(station["foot"]), "bridge screenshot station preserves full foot: " + String(station["label"]))
		await _capture(station["label"], station["foot"])
	await _capture("dock", CONTRACT.DOCK_ROUTE[-1])
	await _capture("dock_side", Vector2(2435, 640))
	field._player.set_walk_direction(Vector2.RIGHT, false)
	await _capture("dock_middle_front", Vector2(2435,686))
	await _capture("ferry", CONTRACT.landmarks()[1]["entry"])
	await _gateway_checks()
	field._open_system_menu()
	field._open_save_slot_panel()
	_check(field._system_ui_canvas_layer.get_node_or_null("SystemMenu") == null, "preview cannot open save-capable menu")
	_check(String(root.get_node("SceneRouter").get_current_field_id()).is_empty(), "preview never registers a saveable current field")
	if String(root.get_node("SceneRouter").get_current_field_id()).is_empty():
		_check(not root.get_node("PlatformBridge").request_checkpoint_save(), "platform lifecycle checkpoint refuses unsaveable preview")
	_check(_save_snapshot() == saves_before, "all five user saves and backups unchanged")
	_check(root.get_node("GameState").flags == flags_before, "no plot/quest flags emitted")
	_check(_gameplay_snapshot() == gameplay_before, "party resources/skills/gold/reputation/inventory/quests/bounties/investigation unchanged, no destination rewards or tasks")
	var old_changed := 0
	for path in old_source_before:
		old_changed += 1 if old_source_before[path] != FileAccess.get_sha256(path) else 0
	_check(old_changed == 0, "all protected old v9/v10/v11 and prior capability experiments remain SHA unchanged")
	restore_preview_state()
	_check(root.get_node("SceneRouter").get_navigation_state() == navigation_before, "runtime Router navigation restored")
	print("[WorldLandmarkV12] checks=%d failures=%d continuous_main_road=%d; isolated, shipping map unchanged" % [checks, failures, route_probes])
	quit(0 if failures == 0 else 1)


func _surface_support_checks() -> void:
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	_check(walk != null and land != null and walk.get_size() == Vector2i(CONTRACT.WORLD_SIZE) and land.get_size() == walk.get_size(), "same-camera land/navigation native sizes")
	if walk == null or land == null:
		return
	for family in [{"full": "visual", "left": "center", "right": "coast"}, {"full": "walk", "left": "center_walk", "right": "coast_walk"},
		{"full": "land", "left": "center_land", "right": "coast_land"}]:
		var source := _read_png(CONTRACT.PREFIX + String(family["full"]) + ".png")
		var left := _read_png(CONTRACT.PREFIX + String(family["left"]) + ".png")
		var right := _read_png(CONTRACT.PREFIX + String(family["right"]) + ".png")
		var matched := source != null and left != null and right != null
		matched = matched and source.get_size() == Vector2i(3072, 1024) and left.get_size() == Vector2i(1536,1024) and right.get_size() == left.get_size()
		if matched:
			# Raw pixels, not just a sampling grid: both region images are exact crops.
			matched = left.get_data() == source.get_region(Rect2i(0, 0, 1536, 1024)).get_data()
			matched = matched and right.get_data() == source.get_region(Rect2i(1536, 0, 1536, 1024)).get_data()
		_check(matched, "same-camera region crops exact all pixels: " + String(family["full"]))
	var invalid := 0
	var declared_deck := 0
	for y in range(0, walk.get_height(), 4):
		for x in range(0, walk.get_width(), 4):
			var pixel := Vector2(x, y)
			if walk.get_pixel(x, y).r > 0.5 and land.get_pixel(x, y).r < 0.5:
				if _structure_supports(pixel):
					declared_deck += 1
				else:
					invalid += 1
	_check(invalid == 0, "navigation never opens water outside declared bridge/dock decks (%d invalid)" % invalid)
	_check(declared_deck > 0, "structural bridge is explicitly allowed above river, not mislabeled natural land")


func _read_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


func _inherited_prop_land_checks() -> void:
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	_check(land != null, "land mask available for inherited physical bases")
	if land == null:
		return
	var audited := 0
	for object in CONTRACT.scene_objects():
		if not object.has("collision_size"):
			continue
		audited += 1
		var center: Vector2 = (object["pos"] + object["collision_offset"]) * CONTRACT.WORLD_SIZE
		var size: Vector2 = object["collision_size"] * CONTRACT.WORLD_SIZE
		var base := Rect2(center - size * 0.5, size)
		var x_steps := ceili(size.x / 4.0)
		var y_steps := ceili(size.y / 4.0)
		var invalid := 0
		for yi in range(y_steps + 1):
			for xi in range(x_steps + 1):
				var pixel := Vector2i(base.position + Vector2(size.x * xi / x_steps, size.y * yi / y_steps))
				if pixel.x < 0 or pixel.y < 0 or pixel.x >= land.get_width() or pixel.y >= land.get_height() or land.get_pixelv(pixel).r < 0.5:
					invalid += 1
		_check(invalid == 0, "inherited full base rests on land: %s (%d water/out-of-bounds samples)" % [object["id"], invalid])
	var expected_physical: Array[String] = []
	for original in BASE_V10.scene_objects():
		if original.has("collision_size") and not String(original["id"]) in REPLACED_GRASS:
			expected_physical.append(String(original["id"]))
	var actual_physical: Array[String] = []
	for object in CONTRACT.scene_objects():
		if object.has("collision_size"):
			actual_physical.append(String(object["id"]))
	expected_physical.sort()
	actual_physical.sort()
	_check(actual_physical == expected_physical and audited == expected_physical.size(), "all approved rock/unchanged physical bases audited; low grass does not inherit shrub blockers")


func _depth_checks() -> void:
	var player: Player = field._player
	for pair in [{"id": "lab_luoyang", "foot": CONTRACT.CITY_FOOT}, {"id": "lab_ferry_pavilion_foreground", "foot": Vector2(2420,625)},
		{"id": "lab_bridge_front_rail", "foot": Vector2(1660, 408)}]:
		var visual := field._actor_layer.get_node_or_null("SceneObject_" + String(pair["id"])) as Sprite2D
		_check(visual != null, "independent depth sprite exists: " + String(pair["id"]))
		if visual != null:
			player.position = pair["foot"] + Vector2(0, -72)
			player.refresh_depth_sort()
			_check(player.z_index < visual.z_index, "actor behind foreground: " + String(pair["id"]))
			player.position = pair["foot"] + Vector2(0, 72)
			player.refresh_depth_sort()
			_check(player.z_index > visual.z_index, "actor in front of foreground: " + String(pair["id"]))
	var deck := field._visual_layer.get_node_or_null("SceneObject_lab_bridge_deck") as Sprite2D
	_check(deck != null and deck.z_index < 0, "whole bridge deck is below actors, not whole-image foreground")
	var dock := field._visual_layer.get_node_or_null("SceneObject_lab_bailu") as Sprite2D
	_check(dock != null and dock.z_index < 0, "whole dock floor is below actors, not whole-image foreground")


func _movement_checks() -> void:
	var player: Player = field._player
	player.position = Vector2(1410, 365)
	player.refresh_depth_sort()
	Input.action_press("move_right")
	for tick in range(78):
		await physics_frame
	Input.action_release("move_right")
	await physics_frame
	_check(player.position.x > 1900 and absf(player.position.y - 365) < 2, "actual physics input crosses bridge west to east: %s" % player.position)
	Input.action_press("move_left")
	for tick in range(78):
		await physics_frame
	Input.action_release("move_left")
	await physics_frame
	_check(player.position.x < 1430 and absf(player.position.y - 365) < 2, "actual physics input returns east to west: %s" % player.position)
	player.position = Vector2(1660, 365)
	Input.action_press("move_down")
	for tick in range(24):
		await physics_frame
	Input.action_release("move_down")
	await physics_frame
	_check(player.position.y < 390, "front rail/deck boundary blocks actual downward motion")


func _capture(label: String, position: Vector2) -> void:
	var player: Player = field._player
	player.position = position
	player.refresh_depth_sort()
	field._snap_camera_to_player()
	for tick in range(10):
		await process_frame
	if DisplayServer.get_name() != "headless":
		var image := root.get_texture().get_image()
		_check(image != null and image.get_size() == Vector2i(1920, 1080), "runtime capture uses physical 1920x1080 viewport: " + label)
		_check(image != null and image.save_png("res://build/world_native_pair_landmark_v12_" + label + ".png") == OK, "1920 runtime capture: " + label)


func _gateway_checks() -> void:
	for landmark in CONTRACT.landmarks():
		var expected_anchor: Vector2 = landmark["entry"] / CONTRACT.WORLD_SIZE
		var player: Player = field._player
		player.position = landmark["entry"]
		field._snap_camera_to_player()
		for tick in range(10):
			await process_frame
		for tick in range(5):
			await physics_frame
		var zone: ExitZone = null
		for candidate: ExitZone in field._exit_nodes:
			if candidate.target_scene_id == String(landmark["target_scene"]):
				zone = candidate
		_check(zone != null and zone._in_range, "real portal range accepts outside stand point")
		var interactions := [0]
		if landmark["kind"] == "city":
			player.interacted.connect(func(): interactions[0] += 1)
			var key := InputEventKey.new()
			key.keycode = KEY_SPACE
			key.physical_keycode = KEY_SPACE
			key.pressed = true
			Input.parse_input_event(key)
			Input.flush_buffered_events()
			await process_frame
			key = InputEventKey.new()
			key.keycode = KEY_SPACE
			key.physical_keycode = KEY_SPACE
			key.pressed = false
			Input.parse_input_event(key)
			Input.flush_buffered_events()
		else:
			var dispatch_before: int = field.pointer_dispatch_count
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = zone.marker_visual.get_global_transform_with_canvas().origin
			click.global_position = click.position
			var click_point := click.position
			click.pressed = true
			Input.parse_input_event(click)
			Input.flush_buffered_events()
			await process_frame
			click = InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = click_point
			click.global_position = click_point
			click.pressed = false
			Input.parse_input_event(click)
			Input.flush_buffered_events()
			for tick in range(8):
				await process_frame
			_check(field.pointer_dispatch_count > dispatch_before, "real pointer reaches isolated Field dispatch")
		for tick in range(12):
			await process_frame
		if landmark["kind"] == "city":
			_check(interactions[0] > 0, "Space input dispatched to real Player.interacted")
		_check(field._current_scene.scene_id == landmark["target_scene"], "existing destination art loaded in runtime copy: " + String(landmark["id"]))
		_check(return_anchor.distance_to(expected_anchor) < 0.0001, "source doorway anchor preserved exactly: " + String(landmark["id"]))
		player = field._player
		_check(_foot_clear(player.position), "destination spawn has complete foot clearance")
		_check(field._current_scene.npcs.is_empty() and field._current_scene.on_enter_dialog == null and field._current_scene.map_layout.interactions.is_empty(), "destination preview cannot issue plot/rewards")
		await _capture(String(landmark["kind"]) + "_arrival", player.position)
		for tick in range(5):
			await physics_frame
		_check(field._exit_nodes.size() == 1 and field._exit_nodes[0].try_interact(), "real return interaction activates")
		for tick in range(12):
			await process_frame
		_check(field._current_scene.scene_id == CONTRACT.LAB_ID, "returns to exact runtime lab")
		_check(field._player.position.distance_to(landmark["entry"]) < 0.01, "returns at same outside doorway, not nearest-road repair")



func _terrain_boundary_checks() -> void:
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	var old_land := _read_png(BASE_V10.PREFIX + "land.png")
	var topology := _read_png(CONTRACT.PREFIX + "topology.png")
	var visual := _read_png(CONTRACT.PREFIX + "visual.png")
	_check(land != null and walk != null and old_land != null and topology != null and visual != null, "v12 source topology/visual/land/walk and unchanged v10 baseline boundary evidence available")
	if land == null or walk == null or old_land == null or topology == null or visual == null:
		return
	var bad_river_land := 0
	var bad_river_walk := 0
	var bad_river_topology := 0
	var bad_river_visual := 0
	var river_witnesses := 0
	for y in range(0, 1024):
		var river := CONTRACT.river_x(y)
		var half_width := CONTRACT.river_half_width(y)
		for fraction in [0.0, -0.3, 0.3, -0.75, 0.75]:
			river_witnesses += 1
			var pixel := Vector2i(roundi(river + half_width * fraction), y)
			if land.get_pixelv(pixel).r > 0.5:
				bad_river_land += 1
			if topology.get_pixelv(pixel).r > 0.5:
				bad_river_topology += 1
			var color := visual.get_pixelv(pixel)
			if color.b <= color.r + 0.02:
				bad_river_visual += 1
			if walk.get_pixelv(pixel).r > 0.5 and not _structure_supports(Vector2(pixel)):
				bad_river_walk += 1
	_check(bad_river_land == 0, "authored river remains natural water along every-row variable-width center/bank witnesses")
	_check(bad_river_walk == 0, "authored river remains blocked except declared structural bridge/dock")
	_check(bad_river_topology == 0, "actual source topology independently contains curved variable-width river")
	_check(bad_river_visual == 0, "rendered source river pixels visibly retain blue-green water rather than land (%d mismatches)" % bad_river_visual)
	var added_land := 0
	var removed_land := 0
	for y in range(0, 1024, 4):
		for x in range(0, 3072, 4):
			var before := old_land.get_pixel(x, y).r > 0.5
			var after := land.get_pixel(x, y).r > 0.5
			if after and not before:
				added_land += 1
			elif before and not after:
				removed_land += 1
	print("[WorldLandmarkV12 boundary] river_witnesses=%d bad_river_land=%d bad_river_walk=%d; 4px lattice added_land=%d removed_land=%d; route/base/coast contracts tested independently" % [river_witnesses, bad_river_land, bad_river_walk, added_land, removed_land])


func _slope_semantics_checks() -> void:
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX + "art.json"))
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	_check(metadata is Dictionary and walk != null and land != null, "current art metadata and same-camera slope masks available")
	if not metadata is Dictionary or walk == null or land == null:
		return
	var topology := _read_png(CONTRACT.PREFIX+"topology.png")
	_check(topology != null, "real source topology available for independent slope/projection recomputation")
	if topology == null:
		return
	var helper := V12_GEOMETRY.new()
	var gentle: Array = metadata.get("gentle_examples", [])
	_check(gentle.size() >= 2, "current geography supplies explicit gentle land witnesses")
	for probe in gentle:
		var coords: Array = probe.get("projected_point", []) if probe is Dictionary else probe
		var foot := Vector2(coords[0], coords[1])
		var pixel := Vector2i(foot.round())
		if probe is Dictionary:
			_check(float(probe["world_gradient"]) < 0.72, "gentle witness is below unchanged physical threshold at %s" % foot)
			var source := Vector2(probe["source_point"][0],probe["source_point"][1])
			_check(absf(float(probe["world_gradient"])-helper.terrain_gradient(source,topology)) < 0.00002 and foot.distance_to(helper.terrain_project(source,topology)) < 0.01, "gentle source callback gradient and real projected station independently agree")
		_check(land.get_pixelv(pixel).r > 0.5 and walk.get_pixelv(pixel).r > 0.5 and _walks(foot) and _foot_clear(foot), "current gentle witness rests on natural land with complete foot at %s" % foot)
	var examples: Array = metadata.get("steep_examples", [])
	_check(examples.size() >= 12, "new relief supplies twelve actual steep source/projected witnesses")
	for example in examples:
		var point := Vector2(example["projected_point"][0], example["projected_point"][1])
		var source := Vector2(example["source_point"][0],example["source_point"][1])
		var pixel := Vector2i(point.round())
		_check(float(example["world_gradient"]) > 0.72, "new slope exceeds unchanged physical threshold at %s" % point)
		_check(absf(float(example["world_gradient"])-helper.terrain_gradient(source,topology)) < 0.00002 and point.distance_to(helper.terrain_project(source,topology)) < 0.01, "fresh steep source gradient/projection recomputed, not metadata-only slope assertion")
		_check(land.get_pixelv(pixel).r > 0.5 and walk.get_pixelv(pixel).r < 0.5 and not _walks(point), "actual projected steep land rejects Field movement at %s" % point)
	helper.free()



func _structure_supports(point: Vector2) -> bool:
	if CONTRACT.BRIDGE_DECK.has_point(point):
		return true
	for deck: Rect2 in CONTRACT.DOCK_DECKS:
		if deck.has_point(point):
			return true
	return false


func _rectangle_support(rect: Rect2, land: Image, walk: Image, wants_land: bool, label: String) -> void:
	var steps_x := ceili(rect.size.x / 4.0)
	var steps_y := ceili(rect.size.y / 4.0)
	var wrong := 0
	for y in range(steps_y + 1):
		for x in range(steps_x + 1):
			var pixel := Vector2i((rect.position + rect.size * Vector2(float(x) / steps_x, float(y) / steps_y)).round())
			var supported := land.get_pixelv(pixel).r > 0.5
			if supported != wants_land or (not wants_land and walk.get_pixelv(pixel).r > 0.5):
				wrong += 1
	_check(wrong == 0, "%s full 4px base including edges (%d incorrect pixels)" % [label, wrong])


func _dock_alpha_support(foot: Vector2, dock: Sprite2D, image: Image) -> bool:
	var local := dock.to_local(field.world_container.to_global(foot))
	var rect := dock.get_rect()
	var uv := (local - rect.position) / rect.size
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return false
	return image.get_pixelv(Vector2i(uv * Vector2(image.get_size()))).a > 0.5


func _dock_full_foot_alpha_support(foot: Vector2, dock: Sprite2D, image: Image, land: Image) -> bool:
	for index in range(17):
		var point := foot
		if index < 16:
			var angle := TAU * float(index) / 16.0
			point += Vector2(cos(angle) * 10.0, sin(angle) * 6.0)
		if land.get_pixelv(Vector2i(point.round())).r < 0.5 and not _dock_alpha_support(point, dock, image):
			return false
	return true


func _dock_support_checks() -> void:
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	_check(land != null and walk != null, "dock needs same-camera natural-land/navigation evidence")
	if land == null or walk == null:
		return
	_rectangle_support(CONTRACT.PAVILION_FOUNDATION, land, walk, true, "pavilion foundation stays on natural land")
	_rectangle_support(CONTRACT.DOCK_APPROACH, land, walk, true, "stone/soil dock approach stays on natural land without structural exemption")
	_rectangle_support(CONTRACT.SHIP_WATER, land, walk, false, "ship hull lies over real blocked water")
	var topology := _read_png(CONTRACT.PREFIX + "topology.png")
	var visual := _read_png(CONTRACT.PREFIX + "visual.png")
	var ship_center := Vector2i(CONTRACT.SHIP_WATER.get_center().round())
	_check(topology != null and topology.get_pixelv(ship_center).r < 0.5 and visual != null and visual.get_pixelv(ship_center).b > visual.get_pixelv(ship_center).r + 0.02, "harbor is actual source-topology and rendered water below ship, not merely navigation paint")
	var dock := field._visual_layer.get_node_or_null("SceneObject_lab_bailu") as Sprite2D
	_check(dock != null and dock.texture != null, "dock actual floor sprite is loaded")
	if dock == null or dock.texture == null:
		return
	var alpha := dock.texture.get_image()
	var masks: Array[Image] = []
	for filename in ["ferry_pavilion_foreground.png", "ferry_near_rail.png"]:
		var mask := _read_png(CONTRACT.PREFIX + filename)
		_check(mask != null and mask.get_size() == alpha.get_size() and ResourceLoader.exists(CONTRACT.PREFIX + filename), "readable imported foreground shares exact source canvas: " + filename)
		if mask != null:
			masks.append(mask)
	var water_supported := 0
	var samples := 0
	for index in range(1, CONTRACT.DOCK_ROUTE.size()):
		var from: Vector2 = CONTRACT.DOCK_ROUTE[index - 1]
		var to: Vector2 = CONTRACT.DOCK_ROUTE[index]
		var count := maxi(1, ceili(from.distance_to(to) / 4.0))
		for step in range(count + 1):
			var foot := from.lerp(to, float(step) / count)
			var pixel := Vector2i(foot.round())
			_check(_walks(foot) and _foot_clear(foot), "continuous real dock route clears full foot at %s" % foot)
			_check(_dock_alpha_support(foot, dock, alpha), "real dock sprite alpha supports route at %s" % foot)
			_check(_dock_full_foot_alpha_support(foot, dock, alpha, land), "real dock sprite alpha supports entire over-water foot at %s" % foot)
			for mask in masks:
				_check(not _dock_alpha_support(foot, dock, mask), "separate dock foreground excludes central walkable wooden floor at %s" % foot)
			if land.get_pixelv(pixel).r < 0.5:
				water_supported += 1
				_check(_structure_supports(foot), "only declared physical deck supports watery dock route")
			samples += 1
	_check(water_supported > 0, "real dock route actually spans water, not a dry-land prop masquerading as dock")
	for foot in [Vector2(2495,609), Vector2(2490,650), Vector2(2510,710)]:
		var pixel := Vector2i(foot)
		_check(land.get_pixelv(pixel).r < 0.5 and walk.get_pixelv(pixel).r < 0.5 and not _walks(foot), "water beside dock rejects full actor: %s" % foot)
	print("[WorldLandmarkV12 dock] route_samples=%d structurally_supported_water=%d" % [samples, water_supported])


func _footprint_foreground_free(foot: Vector2, dock: Sprite2D, mask: Image) -> bool:
	for index in range(17):
		var point := foot
		if index < 16:
			var angle := TAU * float(index) / 16.0
			point += Vector2(cos(angle) * 10.0, sin(angle) * 6.0)
		if _dock_alpha_support(point, dock, mask):
			return false
	return true


# Independently inspected in the ORIGINAL source image, not derived from the
# generated foreground/navigation: wood floors must never occlude footwear.
const VERIFIED_DOCK_FLOORS := [Rect2i(650,440,210,45), Rect2i(650,590,190,120), Rect2i(840,580,26,35)]
# These tiny source areas are actual north column roots and south post-cap
# edges. A legal actor may stand behind these entities, unlike a floor plank.
const VERIFIED_RAIL_ENTITY_PIXELS := [
	Vector2i(933,510),Vector2i(925,517),Vector2i(913,522),Vector2i(948,510),Vector2i(940,517),Vector2i(928,522),Vector2i(914,523),
	Vector2i(921,516),Vector2i(918,524),Vector2i(910,531),Vector2i(899,536),Vector2i(936,516),Vector2i(933,524),Vector2i(925,531),
	Vector2i(913,536),Vector2i(899,538),Vector2i(950,516),Vector2i(948,524),Vector2i(940,531),Vector2i(928,536),Vector2i(914,538),
	Vector2i(900,536),Vector2i(948,507),Vector2i(856,744),Vector2i(859,750),Vector2i(856,758),Vector2i(856,742),Vector2i(859,765),
	Vector2i(856,773),Vector2i(856,756),Vector2i(859,779),Vector2i(856,771)]


func _source_in_regions(pixel: Vector2i, regions: Array) -> bool:
	for region: Rect2i in regions:
		if region.has_point(pixel):
			return true
	return false


func _dock_foreground_exclusion_checks() -> void:
	var dock := field._visual_layer.get_node_or_null("SceneObject_lab_bailu") as Sprite2D
	_check(dock != null, "actual dock floor exists for legal side-foot foreground audit")
	if dock == null:
		return
	var known_side := Vector2(2435, 640)
	_check(_walks(known_side) and _foot_clear(known_side), "review side-foot witness remains fully legal without collision masking")
	for filename in ["ferry_pavilion_foreground.png", "ferry_near_rail.png"]:
		var mask := _read_png(CONTRACT.PREFIX + filename)
		_check(mask != null, "actual foreground pixels readable for side-foot audit: " + filename)
		if mask == null:
			continue
		_check(mask.get_used_rect().has_area(), "semantic foreground remains nonempty: " + filename)
		var entity_points: Array = [Vector2i(400,120), Vector2i(337,350)] if filename == "ferry_pavilion_foreground.png" else [Vector2i(900,720), Vector2i(462,844), Vector2i(920,850)]
		for pixel in entity_points:
			_check(mask.get_pixelv(pixel).a > 0.5, "semantic foreground retains actual roof/column/post/stone at source %s: %s" % [pixel, filename])
		var wooden_floor := Vector2i(666,458) if filename == "ferry_pavilion_foreground.png" else Vector2i(859,600)
		_check(mask.get_pixelv(wooden_floor).a < 0.5, "known real wooden floor source pixel is excluded, not covered: %s %s" % [wooden_floor,filename])
		for floor_region: Rect2i in VERIFIED_DOCK_FLOORS:
			var floor_hits := 0
			for y in range(floor_region.position.y, floor_region.end.y):
				for x in range(floor_region.position.x, floor_region.end.x):
					if mask.get_pixel(x,y).a > 0.5:
						floor_hits += 1
			_check(floor_hits == 0, "independently verified source wooden floor stays foreground-free: %s %s invalid=%d" % [filename,floor_region,floor_hits])
		_check(_footprint_foreground_free(known_side, dock, mask), "known legal side foot (2435,640) and its complete 16-point ellipse stay clear of " + filename)
		var legal_centers := 0
		var failures_on_floor := 0
		var verified_entity_centers := 0
		var verified_entity_pixels: Array[Vector2i] = []
		var examples: Array[String] = []
		for deck: Rect2 in CONTRACT.DOCK_DECKS:
			for y in range(int(deck.position.y), int(deck.end.y), 4):
				for x in range(int(deck.position.x), int(deck.end.x), 4):
					var foot := Vector2(x, y)
					if not _walks(foot) or not _foot_clear(foot):
						continue
					legal_centers += 1
					if not _footprint_foreground_free(foot, dock, mask):
						var hits: Array[String] = []
						for sample in range(17):
							var point := foot
							if sample < 16:
								var angle := TAU * float(sample) / 16.0
								point += Vector2(cos(angle) * 10.0, sin(angle) * 6.0)
							if _dock_alpha_support(point, dock, mask):
								var local := dock.to_local(field.world_container.to_global(point))
								var pixel := Vector2i((local - dock.get_rect().position) / dock.get_rect().size * Vector2(mask.get_size()))
								if filename != "ferry_near_rail.png" or _source_in_regions(pixel,VERIFIED_DOCK_FLOORS) or not pixel in VERIFIED_RAIL_ENTITY_PIXELS:
									hits.append(str(pixel))
								elif not pixel in verified_entity_pixels:
									verified_entity_pixels.append(pixel)
						if hits.is_empty():
							verified_entity_centers += 1
						else:
							failures_on_floor += 1
							if examples.size() < 8:
								examples.append("%s source=%s" % [foot,hits])
		_check(legal_centers == 272, "all 272 unchanged complete-foot legal deck centers remain covered, not only route centerline")
		_check(failures_on_floor == 0, "foreground excludes every legal 4px-grid full-foot wooden floor: %s invalid=%d first=%s" % [filename, failures_on_floor, examples])
		print("[WorldLandmarkV12 floor foreground] mask=%s legal_centers=%d failures=%d independently_verified_entity_overlap=%d" % [filename, legal_centers, failures_on_floor, verified_entity_centers])
		if not verified_entity_pixels.is_empty():
			print("[WorldLandmarkV12 verified source entity pixels] ",verified_entity_pixels)


func _dock_movement_checks() -> void:
	var player: Player = field._player
	player.position = CONTRACT.DOCK_ROUTE[0]
	player.refresh_depth_sort()
	for index in range(1, CONTRACT.DOCK_ROUTE.size()):
		var target: Vector2 = CONTRACT.DOCK_ROUTE[index]
		for tick in range(100):
			var offset := target - player.position
			if offset.length() <= 8.0:
				break
			var direction := offset.normalized()
			Input.action_press("move_right", maxf(direction.x, 0.0))
			Input.action_press("move_left", maxf(-direction.x, 0.0))
			Input.action_press("move_down", maxf(direction.y, 0.0))
			Input.action_press("move_up", maxf(-direction.y, 0.0))
			await physics_frame
		for action in ["move_right", "move_left", "move_down", "move_up"]:
			Input.action_release(action)
		await physics_frame
		_check(player.position.distance_to(target) <= 10.0, "actual physics input traverses dock bend %d to %s (actor=%s)" % [index,target,player.position])
		_check(_foot_clear(player.position), "actual dock input ends on complete supported foot")


const VERIFIED_RAIL_BASES := {"north":648.3390625,"right_middle":682.7921875,"right_near":728.45625,"left_middle":670.7609375,"left_near":724.628125}


func _actual_actor_alpha_intersection(part: Sprite2D) -> int:
	var actor: Sprite2D = field._player.sprite
	var actor_sheet := actor.texture.get_image()
	var frame_size := actor_sheet.get_size() / Vector2i(actor.hframes,actor.vframes)
	var actor_image := actor_sheet.get_region(Rect2i(actor.frame_coords*frame_size,frame_size))
	var part_image := part.texture.get_image()
	var hits := 0
	for y in range(actor_image.get_height()):
		for x in range(actor_image.get_width()):
			if actor_image.get_pixel(x,y).a <= 0.5:
				continue
			var local_pixel := actor.get_rect().position + (Vector2(x,y)+Vector2(0.5,0.5)) / Vector2(actor_image.get_size()) * actor.get_rect().size
			var on_part := part.to_local(actor.to_global(local_pixel))
			var uv := (on_part-part.get_rect().position)/part.get_rect().size
			if uv.x >= 0 and uv.y >= 0 and uv.x < 1 and uv.y < 1 and part_image.get_pixelv(Vector2i(uv*Vector2(part_image.get_size()))).a > 0.5:
				hits += 1
	return hits


func _rail_part_depth_checks() -> void:
	var player: Player = field._player
	var rail_images: Array[Image] = []
	_check(field._actor_layer.get_node_or_null("SceneObject_lab_ferry_near_rail") == null, "combined near-rail mask is audit-only, not a runtime shared-Y entity")
	for name: String in VERIFIED_RAIL_BASES:
		var part := field._actor_layer.get_node_or_null("SceneObject_lab_ferry_rail_"+name) as Sprite2D
		_check(part != null, "independent physical rail part exists: "+name)
		if part == null:
			continue
		var texture_path := CONTRACT.PREFIX+"ferry_rail_"+name+".png"
		var image := _read_png(texture_path)
		_check(image != null and image.get_size() == Vector2i(1536,1024) and image.get_used_rect().has_area() and ResourceLoader.exists(texture_path), "readable nonempty exact source canvas rail part: "+name)
		if image != null:
			rail_images.append(image)
		var object_found := false
		for object in CONTRACT.scene_objects():
			if object["id"] == "lab_ferry_rail_"+name:
				object_found = true
				_check(absf(float(object["depth_sort_foot_y"])*CONTRACT.WORLD_SIZE.y-float(VERIFIED_RAIL_BASES[name])) < 0.001, "rail depth uses independently verified actual source bottom: "+name)
		_check(object_found, "per-post depth contract exists: "+name)
		# Generic non-intersection witnesses cross the existing 8px sort band;
		# exact overlapping same-band semantics are checked separately below.
		player.position = Vector2(2435,float(VERIFIED_RAIL_BASES[name])-9.0)
		player.refresh_depth_sort()
		_check(player.z_index < part.z_index, "actor north of actual rail base sorts behind: "+name)
		player.position.y += 18.0
		player.refresh_depth_sort()
		_check(_actor_draws_after(part), "actor south of actual rail base effectively sorts in front, including same-band sibling order: "+name)
	var aggregate := _read_png(CONTRACT.PREFIX+"ferry_near_rail.png")
	_check(rail_images.size() == 5 and aggregate != null, "all five actual rail images available for independent full-pixel partition audit")
	if rail_images.size() == 5 and aggregate != null:
		var duplicate_pixels := 0
		var mismatches := 0
		for y in range(aggregate.get_height()):
			for x in range(aggregate.get_width()):
				var nonempty := 0
				var alpha := 0.0
				for image in rail_images:
					var part_alpha := image.get_pixel(x,y).a
					if part_alpha > 0.0:
						nonempty += 1
					alpha = maxf(alpha,part_alpha)
				if nonempty > 1:
					duplicate_pixels += 1
				if absf(alpha-aggregate.get_pixel(x,y).a) > 0.001:
					mismatches += 1
		_check(duplicate_pixels == 0, "five actual rail masks never duplicate source entity pixels (%d)" % duplicate_pixels)
		_check(mismatches == 0, "five actual rail masks reconstruct aggregate alpha at every source pixel (%d)" % mismatches)
		print("[WorldLandmarkV12 rail partition] duplicate_pixels=%d aggregate_alpha_mismatches=%d" % [duplicate_pixels,mismatches])
	var middle := field._actor_layer.get_node_or_null("SceneObject_lab_ferry_rail_right_middle") as Sprite2D
	if middle == null:
		return
	player.set_walk_direction(Vector2.RIGHT,false)
	for station in [{"y":677.0,"front":false},{"y":686.0,"front":true},{"y":689.0,"front":true}]:
		player.position = Vector2(2435,station["y"])
		player.refresh_depth_sort()
		_check(_walks(player.position) and _foot_clear(player.position), "actual overlapping middle-post station preserves complete legal foot: %s" % player.position)
		var hits := _actual_actor_alpha_intersection(middle)
		_check(hits > 0, "standing-right actor actual opaque pixels intersect middle post at %s hits=%d" % [player.position,hits])
		_check(_actor_draws_after(middle) == station["front"], "actual alpha-overlapping actor has correct middle-post front/behind at %s" % player.position)
		if station["y"] == 689.0:
			_check(player.z_index > middle.z_index, "middle-post south witness crosses a full depth band, not only a tie")
		print("[WorldLandmarkV12 post overlap] foot=%s actual_alpha_hits=%d actor_z=%d part_z=%d" % [player.position,hits,player.z_index,middle.z_index])


func _actor_draws_after(part: Sprite2D) -> bool:
	var player: Player = field._player
	return player.z_index > part.z_index or (player.z_index == part.z_index and player.get_parent() == part.get_parent() and player.get_index() > part.get_index())


func _route_y_at_x(x: float) -> float:
	var points: Array[Vector2] = CONTRACT.route_points()
	for index in range(1,points.size()):
		var first: Vector2 = points[index-1]
		var last: Vector2 = points[index]
		if first.x <= x and last.x >= x and last.x > first.x:
			return lerpf(first.y,last.y,(x-first.x)/(last.x-first.x))
	return -1.0


func _drive_to(target: Vector2, tick_limit: int = 100) -> bool:
	var started: Vector2 = field._player.position
	var good_foot := true
	var first_bad := Vector2(INF,INF)
	for tick in range(tick_limit):
		var offset: Vector2 = target-field._player.position
		if offset.length() <= 5.0:
			break
		var direction := offset.normalized()
		Input.action_press("move_right",maxf(direction.x,0.0))
		Input.action_press("move_left",maxf(-direction.x,0.0))
		Input.action_press("move_down",maxf(direction.y,0.0))
		Input.action_press("move_up",maxf(-direction.y,0.0))
		await physics_frame
		var valid_now := _walks(field._player.position) and _foot_clear(field._player.position)
		if not valid_now and not first_bad.is_finite():
			first_bad = field._player.position
		good_foot = good_foot and valid_now
	for action in ["move_right","move_left","move_down","move_up"]:
		Input.action_release(action)
	await physics_frame
	if not good_foot or field._player.position.distance_to(target) > 10.0:
		print("[WorldLandmarkV12 drive diagnostic] start=",started," target=",target," end=",field._player.position," distance=",field._player.position.distance_to(target)," goodfullfoot=",good_foot," first_bad=",first_bad)
	return good_foot and field._player.position.distance_to(target) <= 10.0


func _original_foot_reason(point: Vector2) -> Dictionary:
	var reasons: Array = []
	for index in range(17):
		var sample := point
		if index < 16:
			var angle := TAU*index/16.0
			sample += Vector2(cos(angle)*10.0,sin(angle)*6.0)
		var normalized := sample/CONTRACT.WORLD_SIZE
		var nav: bool = field.call("_is_walkable_by_mask",normalized)
		var blocked: bool = field.call("_is_blocked_by_layout",normalized)
		if not nav or blocked:
			reasons.append({"sample":sample,"nav":nav,"layout_blocked":blocked})
	var land := _read_png(CONTRACT.PREFIX+"land.png")
	var topology := _read_png(CONTRACT.PREFIX+"topology.png")
	var natural_pixel := Vector2i(point.round())
	var natural_land: bool = land.get_pixelv(natural_pixel).r > 0.5
	var topology_land: bool = topology.get_pixelv(natural_pixel).r > 0.5
	var river_distance := absf(point.x-CONTRACT.river_x(point.y))-CONTRACT.river_half_width(point.y)
	return {"station":point,"center_walk":_walks(point),"fullfeet":_foot_clear(point),"natural_land":natural_land,"topology_land":topology_land,"river_bank_distance":river_distance,"bad_samples":reasons}


func _current_actor_alpha_world_bounds() -> Rect2:
	var actor: Sprite2D = field._player.sprite
	var source: Image = actor.texture.get_image()
	var cell := Vector2i(source.get_width()/actor.hframes,source.get_height()/actor.vframes)
	var origin := Vector2i(actor.frame%actor.hframes,actor.frame/actor.hframes)*cell
	var used := source.get_region(Rect2i(origin,cell)).get_used_rect()
	var minimum := actor.get_rect().position+Vector2(used.position)
	var a: Vector2 = field.world_container.to_local(actor.to_global(minimum))
	var b: Vector2 = field.world_container.to_local(actor.to_global(minimum+Vector2(used.size)))
	return Rect2(a,b-a)


func _v12_original_rock_diagnostics() -> void:
	for data in CONTRACT.entity_metadata():
		if not String(data["id"]) in REPLACED_ROCKS:
			continue
		var id: String = data["id"]
		var sprite := field._actor_layer.get_node("SceneObject_"+id) as Sprite2D
		var center := Vector2(data["collision_center"][0],data["collision_center"][1])
		var extent := Vector2(data["collision_size"][0],data["collision_size"][1])
		var base := Rect2(center-extent*0.5,extent)
		var left_top := base.position+Vector2(-16,-16)
		var left_bottom := Vector2(left_top.x,base.end.y+16)
		var right_top := Vector2(base.end.x+16,base.position.y-16)
		var right_bottom := Vector2(right_top.x,base.end.y+16)
		print("[WorldLandmarkV12 original rock] id=",id," base=",base," actualdepth=",data["world_base_y"]," sourcealpha=",data["projected_used_rect"])
		for point in [left_top,left_bottom,right_top,right_bottom]:
			print("[WorldLandmarkV12 original static foot] ",_original_foot_reason(point))
		for pair in [[left_top,left_bottom],[right_top,right_bottom]]:
			field._player.position = pair[0]
			var traversed := await _drive_to(pair[1])
			print("[WorldLandmarkV12 original side input] id=",id," passed=",traversed," endpoint_reasons=",_original_foot_reason(field._player.position))
		field._player.set_walk_direction(Vector2.RIGHT,false)
		for front in [false,true]:
			for dx in [0.0,-8.0,8.0,-16.0,16.0]:
				var point := Vector2(center.x+dx,base.end.y+10 if front else base.position.y-10)
				field._player.position = point
				field._player.refresh_depth_sort()
				print("[WorldLandmarkV12 original alpha probe] id=",id," front=",front," reason=",_original_foot_reason(point)," frame=",field._player.sprite.frame," hframes=",field._player.sprite.hframes," actor_bbox=",_current_actor_alpha_world_bounds()," actual_hits=",_actual_actor_alpha_intersection(sprite))
		await _v12_planned_rock_diagnostic(data,sprite,base)


func _v12_planned_rock_diagnostic(data: Dictionary, sprite: Sprite2D, base: Rect2) -> void:
	# Explicit bounded diagnostics only: no candidate collision/nav/alpha edits.
	var id: String = data["id"]
	var collider := field._player.get_node("CollisionShape2D") as CollisionShape2D
	var physical_half: Vector2 = collider.shape.get_rect().size*0.5
	var margin := Vector2(maxf(physical_half.x,0.004*3072+10.0),maxf(physical_half.y,0.004*1024+6.0))+Vector2(2,2)
	print("[WorldLandmarkV12 derived safe proposal] id=",id," physicalhalf=",physical_half," collideroffset=",collider.position," margin=",margin)
	for side in [-1,1]:
		var x := base.position.x-margin.x if side < 0 else base.end.x+margin.x
		var north := Vector2(x,base.position.y-margin.y)
		var south := Vector2(x,base.end.y+margin.y)
		var route_legal := true
		for step in range(ceili(north.distance_to(south)/4.0)+1):
			var p := north.lerp(south,float(step)/ceili(north.distance_to(south)/4.0))
			route_legal = route_legal and _walks(p) and _foot_clear(p)
		print("[WorldLandmarkV12 proposed route] id=",id," side=",side," all4pxfullfeet=",route_legal," north=",_original_foot_reason(north)," south=",_original_foot_reason(south))
		if route_legal:
			field._player.position = north
			print("[WorldLandmarkV12 proposed trueinput] id=",id," side=",side," actualpass=",await _drive_to(south))
	var best := {false:{"hits":0},true:{"hits":0}}
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		field._player.set_walk_direction(direction,false)
		# Every tested sprite uses its real CURRENT source frame, never a
		# combined strip. Only bounded perimeter/legal land positions qualify.
		for y in range(floori(base.position.y)-40,ceili(base.end.y)+41,2):
			for x in range(floori(base.position.x)-40,ceili(base.end.x)+41,4):
				var p := Vector2(x,y)
				if base.grow_individual(physical_half.x+1,physical_half.y+1,physical_half.x+1,physical_half.y+1).has_point(p) or not _walks(p) or not _foot_clear(p):
					continue
				field._player.position = p
				field._player.refresh_depth_sort()
				var front: bool = p.y > float(data["world_base_y"])
				var used: Array = data["projected_used_rect"]
				var alpha_box := Rect2(used[0],used[1],used[2],used[3])
				if not _current_actor_alpha_world_bounds().intersects(alpha_box):
					continue
				var hits := _actual_actor_alpha_intersection(sprite)
				if hits > int(best[front]["hits"]):
					best[front] = {"hits":hits,"point":p,"direction":direction,"frame":field._player.sprite.frame,"bbox":_current_actor_alpha_world_bounds(),"order_correct":_actor_draws_after(sprite) == front}
	print("[WorldLandmarkV12 bounded legal alpha proposal] id=",id," best=",best)


func _seam_movement_checks() -> void:
	# Traverse the actual runtime coordinate seam in both directions, not
	# teleport two sides or infer real input from exact PNG crops alone.
	var west := Vector2(1512,_route_y_at_x(1512))
	var east := Vector2(1560,_route_y_at_x(1560))
	_check(west.y >= 0 and east.y >= 0, "v12 current projected road covers both sides of the 1536px seam")
	_check(_foot_clear(west) and _foot_clear(east), "seam approach and departure both have complete supported feet")
	field._player.position = west
	field._player.refresh_depth_sort()
	_check(await _drive_to(east) and field._player.position.x > 1536, "actual input crosses center-to-coast seam with full foot every physics frame")
	_check(await _drive_to(west) and field._player.position.x < 1536, "actual input returns coast-to-center seam without teleport or boundary stall")



# Candidate-specific static assertions, not v10's globally frozen nav SHA.
# New READY capture is required before these sections can execute.
func _normalize_versioned_paths(value: Variant) -> Variant:
	if value is String or value is StringName:
		return String(value).replace(CONTRACT.PREFIX,BASE_V10.PREFIX).replace(String(CONTRACT.LAB_ID),String(BASE_V10.LAB_ID))
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _normalize_versioned_paths(value[key])
		return result
	if value is Array:
		var result: Array = []
		for entry in value:
			result.append(_normalize_versioned_paths(entry))
		return result
	return value


func _objects_by_id(objects: Array) -> Dictionary:
	var result := {}
	for object in objects:
		var id: String = String(object.get("id",""))
		_check(not id.is_empty() and not result.has(id), "independent entity has nonempty unique id: "+id)
		result[id] = object
	return result


func _same_frozen_png(suffix: String) -> void:
	var path: String = CONTRACT.PREFIX+suffix
	var old_path: String = BASE_V10.PREFIX+suffix
	var after := _read_png(path)
	var before := _read_png(old_path)
	_check(after != null and before != null, "readable unchanged-source v12/v10 artifact: "+suffix)
	if after == null or before == null:
		return
	_check(after.get_size() == before.get_size() and after.get_format() == before.get_format() and after.get_data() == before.get_data(), "unchanged-source artifact matches all old pixels: "+suffix)
	_check(FileAccess.get_sha256(path) == FileAccess.get_sha256(old_path), "unchanged-source artifact retains PNG SHA: "+suffix)


func _v12_local_contract_checks() -> void:
	_check(CONTRACT.LAB_ID != BASE_V10.LAB_ID and CONTRACT.PREFIX == "res://build/world_native_pair_ortho_v12_", "v12 independent lab id and exact resource prefix")
	_check(field._current_scene.background_path == CONTRACT.PREFIX+"visual.png" and field._current_scene.map_layout.walkable_mask_path == CONTRACT.PREFIX+"walk.png", "actual Field binds v12 background/navigation")
	for suffix in ["topology.png","ferry_pavilion_foreground.png","ferry_near_rail.png"]:
		_same_frozen_png(suffix)
	for part in BASE_V10.RAIL_PARTS:
		_same_frozen_png("ferry_rail_"+String(part["name"])+".png")
	for pair in [[CONTRACT.WORLD_SIZE,BASE_V10.WORLD_SIZE],[CONTRACT.BRIDGE_DECK,BASE_V10.BRIDGE_DECK],
		[CONTRACT.DOCK_DECKS,BASE_V10.DOCK_DECKS],[CONTRACT.DOCK_APPROACH,BASE_V10.DOCK_APPROACH],
		[CONTRACT.DOCK_ROUTE,BASE_V10.DOCK_ROUTE],[CONTRACT.PAVILION_FOUNDATION,BASE_V10.PAVILION_FOUNDATION],
		[CONTRACT.SHIP_WATER,BASE_V10.SHIP_WATER],[CONTRACT.ROAD_STOPS,BASE_V10.ROAD_STOPS],
		[CONTRACT.CITY_SPUR,BASE_V10.CITY_SPUR],[CONTRACT.FERRY_SPUR,BASE_V10.FERRY_SPUR],[CONTRACT.RAIL_PARTS,BASE_V10.RAIL_PARTS]]:
		_check(pair[0] == pair[1], "authored route controls/structure/entrance/rail sources remain frozen")
	var water_equal := true
	for y in range(1024):
		if CONTRACT.river_x(y) != BASE_V10.river_x(y) or CONTRACT.river_half_width(y) != BASE_V10.river_half_width(y) or CONTRACT.shore_x(y) != BASE_V10.shore_x(y):
			water_equal = false
	_check(water_equal, "every-row authored river/width/coast functions remain frozen")
	var road_equal := true
	for x in range(3072):
		if CONTRACT.road_y(x) != BASE_V10.road_y(x):
			road_equal = false
	_check(road_equal, "source road control function frozen before fresh projection")
	_check(_normalize_versioned_paths(CONTRACT.landmarks()) == _normalize_versioned_paths(BASE_V10.landmarks()), "landmark anchors/targets frozen")
	_check(_normalize_versioned_paths(CONTRACT.blockers()) == _normalize_versioned_paths(BASE_V10.blockers()), "standalone city/bridge/dock blockers frozen")
	var old_objects := _objects_by_id(BASE_V10.scene_objects())
	var new_objects := _objects_by_id(CONTRACT.scene_objects())
	var expected_ids: Array = old_objects.keys()
	expected_ids.append("native_cast_shadows") # Only explicitly declared ground-only visual shadow layer.
	for id: String in REPLACED_GRASS:
		expected_ids.erase(id)
		for suffix: String in ["a","b","c","d"]:
			expected_ids.append(id+"_"+suffix)
	expected_ids.sort()
	var actual_ids: Array = new_objects.keys()
	actual_ids.sort()
	_check(actual_ids == expected_ids, "only approved two rocks/two-to-eight separate low-grass replacements alter membership")
	var unchanged_physical := 0
	for id in old_objects:
		if id in REPLACED_IDS:
			continue
		_check(new_objects.has(id) and _normalize_versioned_paths(new_objects.get(id,{})) == _normalize_versioned_paths(old_objects[id]), "unreplaced entity alpha/path/pose/collider/depth frozen: "+String(id))
		if old_objects[id].has("collision_size"):
			unchanged_physical += 1
	_check(unchanged_physical == 9, "nine unreplaced paired physical props frozen")
	var old_scene: SceneScript = BASE_V10.make_scene()
	var new_scene: SceneScript = CONTRACT.make_scene()
	for property in ["is_walkable","actor_positions_are_feet","is_settlement","player_spawn","player_visual_scale","npc_visual_scale","camera_zoom","npcs","hotspots","exits","collision_rects","trigger_zones","encounter_enemy_ids","encounter_groups","encounter_step_distance","encounter_chance","encounter_allow_full_group_for_solo","encounter_require_flag","bgm_path","ambience_path","ambience_volume_db","on_enter_dialog","on_enter_require_flag","on_enter_once_flag","animated_props","streamed_background"]:
		_check(_normalize_versioned_paths(new_scene.get(property)) == _normalize_versioned_paths(old_scene.get(property)), "SceneScript unaffected field frozen: "+property)
	for property in ["schema_version","design_size","display_at_native_size","fill_viewport","walkable_regions","walkable_mask_path","walkable_mask_tiles","tiles","travel_routes","occluders","actor_fade_zones","blockers","interactions","portals","walkable_probes","blocked_probes","seam_crossing_probes"]:
		_check(_normalize_versioned_paths(new_scene.map_layout.get(property)) == _normalize_versioned_paths(old_scene.map_layout.get(property)), "MapLayout unaffected gameplay frozen: "+property)
	var route_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX+"route.json"))
	var own_route: Array[Vector2] = []
	if route_data is Dictionary:
		for coords in route_data.get("road_feet",[]):
			own_route.append(Vector2(coords[0],coords[1]))
	_check(not own_route.is_empty() and own_route == CONTRACT.route_points(), "runtime projected route binds own v12 JSON, not old-version fallback")
	for family: String in ["land","walk"]:
		var before := _read_png(BASE_V10.PREFIX+family+".png")
		var after := _read_png(CONTRACT.PREFIX+family+".png")
		_check(before != null and after != null and after.get_size() == before.get_size(), "readable real v12 capture and v10 baseline: "+family)
		if before == null or after == null or after.get_size() != before.get_size():
			continue
		var changed_inside := 0
		var changed_outside := 0
		var additions := 0
		var removals := 0
		for y in range(after.get_height()):
			for x in range(after.get_width()):
				var pixel := Vector2i(x,y)
				var original: Color = before.get_pixelv(pixel)
				var current: Color = after.get_pixelv(pixel)
				if original == current:
					continue
				if APPROVED_PROJECTED_TERRAIN_ROI.has_point(pixel):
					changed_inside += 1
				else:
					changed_outside += 1
				if current.r > 0.5 and original.r <= 0.5:
					additions += 1
				elif current.r <= 0.5 and original.r > 0.5:
					removals += 1
		if family == "land":
			_check(changed_inside == 0, "natural land is identical at EVERY pixel, including relief ROI")
		_check(changed_outside == 0, "real %s pixels freeze outside terrain projection ROI, not entity/shadow ROIs (%d escaped)" % [family,changed_outside])
		print("[WorldLandmarkV12 local capture] %s changed_inside=%d changed_outside=%d added=%d removed=%d; all pixels" % [family,changed_inside,changed_outside,additions,removals])
	_v12_relief_capture_checks()
	_v12_source_shadow_checks()


func _v12_relief_capture_checks() -> void:
	var topology := _read_png(CONTRACT.PREFIX+"topology.png")
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX+"geometry.json"))
	_check(topology != null and record is Dictionary, "v12 source topology and actual mesh geometry diagnostics available")
	if topology == null or not record is Dictionary:
		return
	_check(_numeric_equal(record.get("source_roi"),[120,160,440,200]) and _numeric_equal(record.get("projected_roi"),[64,0,576,400]), "geometry source and projected scopes equal producer-approved independent constants")
	var height_before := Image.load_from_file(CONTRACT.PREFIX+"height_before.exr")
	var height_after := Image.load_from_file(CONTRACT.PREFIX+"height_after.exr")
	var normal_before := _read_png(CONTRACT.PREFIX+"normal_before.png")
	var normal_after := _read_png(CONTRACT.PREFIX+"normal_after.png")
	var png_before := _read_png(CONTRACT.PREFIX+"height_before.png")
	var png_after := _read_png(CONTRACT.PREFIX+"height_after.png")
	var available := true
	for image in [height_before,height_after,normal_before,normal_after,png_before,png_after]:
		available = available and image != null and image.get_size() == Vector2i(3072,1024)
	_check(available, "before/after RF height, normalized PNG and normal diagnostics share complete native source canvas")
	if not available:
		return
	var helper := V12_GEOMETRY.new()
	var old_helper := V10_GEOMETRY.new()
	var height_bad := 0
	var normal_bad := 0
	var height_changed := 0
	var normal_changed := 0
	var escaped_height := 0
	var escaped_normal := 0
	for y in range(0,1024,4):
		for x in range(0,3072,4):
			var point := Vector2(x,y)
			var original: float = old_helper.call("_height",point,topology)
			var inherited: float = helper.terrain_height_before(point,topology)
			var current: float = helper.terrain_height(point,topology)
			if absf(original-inherited)>0.00002 or absf(height_before.get_pixel(x,y).r-original)>0.00002 or absf(height_after.get_pixel(x,y).r-current)>0.00002:
				height_bad += 1
			if absf(png_before.get_pixel(x,y).r-clampf(original/4.0,0.0,1.0))>0.006 or absf(png_after.get_pixel(x,y).r-clampf(current/4.0,0.0,1.0))>0.006:
				height_bad += 1
			if absf(current-original)>0.00002:
				height_changed += 1
				if not APPROVED_SOURCE_HEIGHT_ROI.has_point(Vector2i(x,y)):
					escaped_height += 1
			for version in [0,1]:
				var method: String = "terrain_height_before" if version == 0 else "terrain_height"
				var dx: float = (helper.call(method,point+Vector2(4,0),topology)-helper.call(method,point-Vector2(4,0),topology))/(8.0*30.0/3072.0)
				var dz: float = (helper.call(method,point+Vector2(0,4),topology)-helper.call(method,point-Vector2(0,4),topology))/(8.0*7.0710678*2.0/1024.0)
				var expected := Vector3(-dx,1,-dz).normalized()*0.5+Vector3.ONE*0.5
				var actual: Color = (normal_before if version == 0 else normal_after).get_pixel(x,y)
				if Vector3(actual.r,actual.g,actual.b).distance_to(expected)>0.009:
					normal_bad += 1
			if normal_before.get_pixel(x,y) != normal_after.get_pixel(x,y):
				normal_changed += 1
				if not APPROVED_SOURCE_HEIGHT_ROI.grow(4).has_point(Vector2i(x,y)):
					escaped_normal += 1
	_check(height_bad == 0, "RF/PNG analytic 4px diagnostics match independently recomputed old/new height callback; not GPU height readback (%d mismatches)" % height_bad)
	_check(normal_bad == 0, "analytic 4px normal diagnostics reflect same before/after derivative, not GPU normal readback (%d mismatches)" % normal_bad)
	_check(height_changed > 0 and normal_changed > 0 and escaped_height == 0 and escaped_normal == 0, "real volume and normals change inside source scope; derivative guard only +4px")
	# Inspect actual ArrayMesh CPU buffers. This never creates a viewport,
	# invokes renderer._build(), imports resources or writes render outputs.
	var old_mesh: ArrayMesh = old_helper.call("_mesh",topology)
	var mesh: ArrayMesh = helper.call("_mesh",topology)
	var before_arrays: Array = old_mesh.surface_get_arrays(0)
	var after_arrays: Array = mesh.surface_get_arrays(0)
	var before_vertices: PackedVector3Array = before_arrays[Mesh.ARRAY_VERTEX]
	var vertices: PackedVector3Array = after_arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = after_arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = after_arrays[Mesh.ARRAY_TEX_UV]
	_check(vertices.size() == before_vertices.size() and vertices.size()>10000 and normals.size() == vertices.size() and uvs.size() == vertices.size(), "same dense terrain grid yields real vertices/normals, not a material-only photograph")
	var mesh_changed := 0
	var mesh_bad := 0
	var mesh_escaped := 0
	for index in range(mini(vertices.size(),before_vertices.size())):
		var source: Vector2 = uvs[index]*Vector2(3072,1024)
		var height: float = helper.terrain_height(source,topology)
		if absf(vertices[index].y-height)>0.0001 or Vector2(vertices[index].x,vertices[index].z).distance_to(Vector2(before_vertices[index].x,before_vertices[index].z))>0.0001:
			mesh_bad += 1
		if vertices[index].distance_to(before_vertices[index])>0.0001:
			mesh_changed += 1
			if not Rect2(APPROVED_SOURCE_HEIGHT_ROI).has_point(source):
				mesh_escaped += 1
	_check(mesh_changed > 0 and mesh_bad == 0 and mesh_escaped == 0, "real ArrayMesh vertex changes match scoped source height, unchanged XZ/source-grid support")
	var witness_bad := 0
	var witnesses: Array = record.get("witnesses",[])
	for witness in witnesses:
		var source := Vector2(witness["source_point"][0],witness["source_point"][1])
		var projected := Vector2(witness["projected_point"][0],witness["projected_point"][1])
		if absf(float(witness["height_before"])-helper.terrain_height_before(source,topology))>0.00002 or absf(float(witness["height_after"])-helper.terrain_height(source,topology))>0.00002 or projected.distance_to(helper.terrain_project(source,topology))>0.01 or absf(float(witness["world_gradient"])-helper.terrain_gradient(source,topology))>0.00002:
			witness_bad += 1
	_check(witnesses.size() >= 20 and witness_bad == 0, "source/projected relief witness records match real height/gradient callbacks")
	var route := CONTRACT.route_points()
	var route_bad := 0
	for point in route:
		if point.distance_to(helper.terrain_project(Vector2(point.x,CONTRACT.road_y(point.x)),topology))>0.01:
			route_bad += 1
	_check(route_bad == 0, "every actual route point is freshly projected from frozen source road controls")
	_v12_index_only_checks(helper,topology)
	print("[WorldLandmarkV12 real mesh] changed_height_cells=%d changed_normal_cells=%d changed_vertices=%d height_bad=%d normal_bad=%d escaped_vertex=%d" % [height_changed,normal_changed,mesh_changed,height_bad,normal_bad,mesh_escaped])
	helper.free()
	old_helper.free()


func _v12_source_shadow_checks() -> void:
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX+"art.json"))
	_check(record is Dictionary and record.get("version") == "v12" and record.get("entities_baked") == false, "native v12 metadata is current independent ground-only capture")
	if not record is Dictionary:
		return
	var baseline_hashes: Dictionary = record.get("v9_source_hashes",{})
	_check(baseline_hashes.size() >= 28, "v9/v10 original source/output hash snapshots retained")
	for path in baseline_hashes:
		_check(FileAccess.file_exists(path) and FileAccess.get_sha256(path) == baseline_hashes[path], "old source/output untouched during v12: "+String(path))
	var land := _read_png(CONTRACT.PREFIX+"land.png")
	var on := _read_png(CONTRACT.PREFIX+"shadow_on.png")
	var off := _read_png(CONTRACT.PREFIX+"shadow_off.png")
	var shadow := _read_png(CONTRACT.PREFIX+"shadow.png")
	var contact := _read_png(CONTRACT.PREFIX+"contact.png")
	var visual := _read_png(CONTRACT.PREFIX+"visual.png")
	var repeat_on := _read_png(CONTRACT.PREFIX+"shadow_on_repeat.png")
	var repeat_off := _read_png(CONTRACT.PREFIX+"shadow_off_repeat.png")
	var union_image := _read_png(CONTRACT.PREFIX+"sourcebody_union.png")
	var available := true
	for image in [land,on,off,shadow,contact,visual,repeat_on,repeat_off,union_image]:
		available = available and image != null and image.get_size() == Vector2i(3072,1024)
	_check(available, "real ground ON/OFF/repeat/body-union/alpha/contact share complete native source canvas")
	if not available:
		return
	for raw in [on,off,repeat_on,repeat_off,visual]:
		raw.convert(Image.FORMAT_RGBA8)
	var repeat_facts: Dictionary = record.get("capture_repeats",{})
	_check(on.get_data() == repeat_on.get_data() and off.get_data() == repeat_off.get_data()
		and FileAccess.get_sha256(CONTRACT.PREFIX+"shadow_on.png") == FileAccess.get_sha256(CONTRACT.PREFIX+"shadow_on_repeat.png")
		and FileAccess.get_sha256(CONTRACT.PREFIX+"shadow_off.png") == FileAccess.get_sha256(CONTRACT.PREFIX+"shadow_off_repeat.png"),
		"independent ground raw pixels and PNG SHA repeat exactly, not metadata-only sync claim")
	var hash_fields := {"on_raw_RGBA_sha":on,"off_raw_RGBA_sha":off,"on_repeat_raw_RGBA_sha":repeat_on,"off_repeat_raw_RGBA_sha":repeat_off}
	for key in hash_fields:
		_check(repeat_facts.get(key) == _hash_bytes(hash_fields[key].get_data()), "recorded raw readback SHA binds actual original pixels: "+key)
	_check(repeat_facts.get("on_exact",false) and repeat_facts.get("off_exact",false) and repeat_facts.get("post_draw_per_state",false) and repeat_facts.get("same_viewport_sequential",false), "same-viewport/postdraw repeat capture gate remains required")
	_check(on.get_data() != off.get_data() and visual.get_data() == off.get_data(), "shadow-only caster changes actual ground; opaque body never baked into runtime visual")
	var bodies := PackedByteArray()
	bodies.resize(3072*1024)
	var complete_bodies := 0
	var entities: Array[Dictionary] = CONTRACT.entity_metadata()
	for data in entities:
		var id: String = data["id"]
		var body := _v12_body_capture_check(data)
		if body == null:
			continue
		complete_bodies += 1
		var rect := body.get_used_rect()
		for y in range(rect.position.y,rect.end.y):
			for x in range(rect.position.x,rect.end.x):
				if body.get_pixel(x,y).a > 0.01:
					bodies[y*3072+x] = 1
	_check(complete_bodies == 10, "all ten independently valid repeat sourcebodies available for ground exclusion")
	var dilated := PackedByteArray()
	dilated.resize(bodies.size())
	for y in 1024:
		for x in 3072:
			if bodies[y*3072+x] == 0:
				continue
			for oy in range(-2,3):
				for ox in range(-2,3):
					dilated[clampi(y+oy,0,1023)*3072+clampi(x+ox,0,3071)] = 1
	var alpha_bad := 0
	var union_bad := 0
	var shadow_bad := 0
	var contact_bad := 0
	var body_bad := 0
	var shadow_count := 0
	var raw_darkening := 0
	var shadow_escaped := 0
	var group_counts := [0,0,0,0]
	for y in 1024:
		for x in 3072:
			var pixel := Vector2i(x,y)
			var union_pixel: Color = union_image.get_pixelv(pixel)
			var union_expected := Color.WHITE if bodies[y*3072+x] != 0 else Color(0,0,0,0)
			if union_pixel != union_expected:
				union_bad += 1
			var before: Color = off.get_pixelv(pixel)
			var after: Color = on.get_pixelv(pixel)
			var base_luma := before.r*0.299+before.g*0.587+before.b*0.114
			var cast_luma := after.r*0.299+after.g*0.587+after.b*0.114
			var relative := clampf((base_luma-cast_luma)/maxf(base_luma,0.025),0.0,0.85)
			var structure_or_water := land.get_pixelv(pixel).r < 0.5 or _structure_supports(Vector2(pixel))
			var body_excluded := dilated[y*3072+x] != 0
			var expected := 0.0 if relative < 0.015 or structure_or_water or body_excluded else relative
			var actual: Color = shadow.get_pixelv(pixel)
			# RGBA8 Image.set_pixel truncates alpha to a byte. This exact rule
			# was independently verified in the frozen minimum-mesh diagnostic.
			if roundi(actual.a*255.0) != int(expected*255.0) or actual.r != 0.0 or actual.g != 0.0 or actual.b != 0.0:
				alpha_bad += 1
			if relative >= 0.015:
				raw_darkening += 1
			if structure_or_water and actual.a > 0.0:
				shadow_bad += 1
			if structure_or_water and contact.get_pixelv(pixel).r > 0.0:
				contact_bad += 1
			if body_excluded and actual.a > 0.0:
				body_bad += 1
			if actual.a <= 0.0:
				continue
			shadow_count += 1
			var in_entity_roi := false
			for index in range(APPROVED_ENTITY_VISUAL_ROIS.size()):
				if APPROVED_ENTITY_VISUAL_ROIS[index].has_point(pixel):
					in_entity_roi = true
					group_counts[index] += 1
			if not in_entity_roi:
				shadow_escaped += 1
	_check(union_bad == 0, "full-pixel sourcebody union independently rebuilds all ten actual original transparent captures (%d)" % union_bad)
	_check(alpha_bad == 0, "every native shadow alpha byte independently reconstructs actual ground ON/OFF with water/deck/body-dilate2 exclusion (%d)" % alpha_bad)
	_check(shadow_count > 0 and raw_darkening > 0, "true sourcebody-outside ground cast is nonempty, not empty/painted mask")
	_check(shadow_bad == 0 and contact_bad == 0 and body_bad == 0, "water/bridge/docks and actual sourcebody 2px exclusion remain exactly shadow-free; contact separately excludes water/decks")
	_check(shadow_escaped == 0, "actual ground cast stays in four approved model/shadow visual envelopes (%d)" % shadow_escaped)
	for index in range(group_counts.size()):
		_check(group_counts[index] > 0, "each independent rock/herb group has actual ground-only cast evidence: "+str(index))
	for family: String in ["shadow_on","shadow_off","shadow_on_repeat","shadow_off_repeat","shadow","contact"]:
		var full := _read_png(CONTRACT.PREFIX+family+".png")
		var left := _read_png(CONTRACT.PREFIX+"center_"+family+".png")
		var right := _read_png(CONTRACT.PREFIX+"coast_"+family+".png")
		_check(full != null and left != null and right != null and left.get_data() == full.get_region(Rect2i(0,0,1536,1024)).get_data() and right.get_data() == full.get_region(Rect2i(1536,0,1536,1024)).get_data(), "actual native source diagnostic crops match every pixel: "+family)
	var layer := field._visual_layer.get_node_or_null("SceneObject_native_cast_shadows") as Sprite2D
	_check(layer != null and layer.texture.resource_path == CONTRACT.PREFIX+"shadow.png" and layer.texture.get_size() == CONTRACT.WORLD_SIZE and layer.z_index == -3, "actual Field binds sole ground-only native shadow under actors")
	_check(field._actor_layer.get_node_or_null("SceneObject_native_cast_shadows") == null and field._collision_layer.get_node_or_null("ObjectCollision_native_cast_shadows") == null, "cast layer cannot become foreground or collision")
	var objects := _objects_by_id(CONTRACT.scene_objects())
	_check(objects.has("native_cast_shadows") and not objects["native_cast_shadows"].has("collision_size") and not objects["native_cast_shadows"].get("sort_by_feet",false), "only approved cast layer remains pure ground-only visual")
	print("[WorldLandmarkV12 native shadow] alpha_pixels=%d source_darkening_pixels=%d reconstruction_bad=%d union_bad=%d water_deck_bad=%d body_exclusion_bad=%d escaped_roi=%d per_group=%s" % [shadow_count,raw_darkening,alpha_bad,union_bad,shadow_bad,body_bad,shadow_escaped,group_counts])


func _v12_replacement_object_checks() -> void:
	var topology := _read_png(CONTRACT.PREFIX+"topology.png")
	var land := _read_png(CONTRACT.PREFIX+"land.png")
	var entities: Array[Dictionary] = CONTRACT.entity_metadata()
	_check(entities.size() == 10 and land != null and topology != null, "exact two native rocks/eight separate low herbs and same-camera natural land available")
	if land == null or topology == null:
		return
	var objects := _objects_by_id(CONTRACT.scene_objects())
	var helper := V12_GEOMETRY.new()
	var specifications := _independent_model_specs()
	var source_hashes := {"res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf":"51487934DB898B4C24072780A451E34ECA5C02E3ADA24A62BBC600BBC4019E92", "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf":"B76D7C14BC027E834E82D3F984C32B5D060E62908AA90FF9420A637CA253A8EA"}
	var group_bases: Dictionary = {}
	for data in entities:
		var id: String = String(data.get("id",""))
		_check(specifications.has(id) and objects.has(id), "approved distinct source entity and runtime object: "+id)
		if not specifications.has(id) or not objects.has(id):
			continue
		var spec: Dictionary = specifications[id]
		_v12_actual_source_vertices(data,spec,topology,helper)
		var expected_path: String = CONTRACT.PREFIX+"entity_"+id+".png"
		var expected_json: String = CONTRACT.PREFIX+"entity_"+id+".json"
		var source_path: String = String(data["source_path"])
		var image := _read_png(expected_path)
		_check(source_hashes.has(source_path) and String(data["source_sha256"]).to_lower() == String(source_hashes.get(source_path,"")).to_lower() and FileAccess.get_sha256(source_path).to_lower() == String(source_hashes.get(source_path,"")).to_lower(), "new sprite derives from specific verified local CC0 model bytes: "+id)
		_check(data["texture_path"] == expected_path and data["metadata_path"] == expected_json and FileAccess.file_exists(expected_json) and ResourceLoader.exists(expected_path), "independent current-version source/texture/metadata paths are real: "+id)
		_check(image != null and image.get_size() == Vector2i(data["size"][0],data["size"][1]) and image.get_used_rect().has_area(), "actual new source image has nonempty alpha and measured canvas: "+id)
		if image == null:
			continue
		_check(data["size"] == data["render_size"] and data["blocking"] == spec["blocking"] and data["variant"] == spec["variant"] and absf(float(data["model_scale"])-float(spec["scale"]))<0.00001 and absf(float(data["yaw"])-float(spec["yaw"]))<0.00001, "source primitive, uncompressed model scale and physical role equal approved per-entity spec: "+id)
		var source_foot := Vector2(data["source_foot"][0],data["source_foot"][1])
		var world_foot := Vector2(data["world_foot"][0],data["world_foot"][1])
		var uv := Vector2(data["foot_uv"][0],data["foot_uv"][1])
		var size := Vector2(image.get_size())
		var base_y: float = float(data["world_base_y"])
		_check(source_foot.distance_to(spec["foot"])<0.001 and world_foot.distance_to(helper.terrain_project(source_foot,topology))<0.01 and absf(base_y-world_foot.y)<0.001, "source anchored front-XZ/min-Y foot truly projects through current terrain and owns its depth line: "+id)
		var object: Dictionary = objects[id]
		var sprite := field._actor_layer.get_node_or_null("SceneObject_"+id) as Sprite2D
		_check(sprite != null and sprite.texture.resource_path == expected_path and sprite.texture.get_size() == size and object["texture"] == expected_path and object.get("sort_by_feet",false), "real Field binds actual independent alpha sprite on actor depth ladder: "+id)
		if sprite == null:
			continue
		var rendered_foot: Vector2 = sprite.position+(sprite.get_rect().position+uv*sprite.get_rect().size)*sprite.scale
		_check(rendered_foot.distance_to(world_foot)<0.01 and absf(float(object["depth_sort_foot_y"])*1024.0-base_y)<0.001 and sprite.scale.distance_to(Vector2.ONE)<0.001, "runtime texture/foot/scale/depth agree with new cropped source, not old foot blindly reused: "+id)
		var used: Rect2i = image.get_used_rect()
		var origin: Vector2 = world_foot-uv*size
		var recorded_used: Array = data["projected_used_rect"]
		var world_used := Rect2i(Vector2i((origin+Vector2(used.position)).round()),used.size)
		_check(world_used == Rect2i(recorded_used[0],recorded_used[1],recorded_used[2],recorded_used[3]), "recorded global source alpha extent equals actual cropped pixels/foot transform: "+id)
		var roi: Rect2i = APPROVED_ENTITY_VISUAL_ROIS[int(spec["roi"])]
		_check(roi.encloses(world_used), "real source alpha remains within approved entity projection envelope: "+id)
		_check(_numeric_equal(data["camera"],{"position":[0,12,12],"ortho_size":10,"canvas":[3072,1024]}) and _numeric_equal(data["light"],{"rotation_degrees":[-55,-34,0],"energy":1.15,"ambient":0.62}) and data.get("same_transform_shadow_and_alpha",false) and data.get("ground_anchor_is_front_XZ_min_Y",false), "new source capture shares actual terrain camera/light and unshifted shadow transform: "+id)
		var body := field._collision_layer.get_node_or_null("ObjectCollision_"+id) as StaticBody2D
		var center := Vector2(data["collision_center"][0],data["collision_center"][1])
		var footprint := Vector2(data["collision_size"][0],data["collision_size"][1])
		if spec["blocking"]:
			_check(body != null and object.has("collision_size") and not _walks(center) and not _foot_clear(center), "solid rock source support owns real blocking body and rejects foot center: "+id)
			if body != null:
				var shape := body.get_child(0) as CollisionShape2D
				_check(shape != null and shape.shape is RectangleShape2D and (body.position+shape.position).distance_to(center)<0.01 and shape.shape.size.distance_to(footprint)<0.01, "real rock collider exact center/extent matches source XZ projected support: "+id)
			await _v12_rock_foot_and_input_checks(id,sprite,center,footprint,base_y)
		else:
			_check(body == null and not object.has("collision_size") and not object.has("collision_offset"), "individual natural low herb has no inherited shrub collider: "+id)
			_check(_walks(world_foot) and _foot_clear(world_foot) and land.get_pixelv(Vector2i(world_foot.round())).r>0.5, "low herb remains rooted on walkable natural land without phantom foliage blocking: "+id)
			var group: String = String(data["old_id"])
			if not group_bases.has(group):
				group_bases[group] = []
			group_bases[group].append(base_y)
			_check(used.size.y < 80 and used.size.x < 100, "0.25-0.40m scanned herb remains low groundcover, not enlarged shrub/tree: "+id)
			_v12_exact_new_alpha_order(sprite,world_foot,base_y,id)
	for group: String in REPLACED_GRASS:
		var original: Dictionary = _objects_by_id(BASE_V10.scene_objects())[group]
		var center: Vector2 = (original["pos"]+original["collision_offset"])*CONTRACT.WORLD_SIZE
		var extent: Vector2 = original["collision_size"]*CONTRACT.WORLD_SIZE
		var freed := Rect2(center-extent*0.5,extent)
		var escaped := 0
		for yi in range(ceili(extent.y/4.0)+1):
			for xi in range(ceili(extent.x/4.0)+1):
				var point: Vector2 = freed.position+extent*Vector2(float(xi)/ceili(extent.x/4.0),float(yi)/ceili(extent.y/4.0))
				if not _walks(point) or not _foot_clear(point):
					escaped += 1
		_check(escaped == 0 and field._collision_layer.get_node_or_null("ObjectCollision_"+group) == null, "only approved old shrub footprint fully releases to low-herb walking, including edges: "+group)
		var bases: Array = group_bases.get(group,[])
		_check(bases.size() == 4 and bases[0] != bases[1] and bases[1] != bases[2] and bases[2] != bases[3], "four low herbs keep distinct actual foot Y, no shared group depth line: "+group)
	helper.free()
	await _capture("native_rocks_west",Vector2(855,680))
	await _capture("native_herbs_west",Vector2(1175,775))
	await _capture("native_rocks_east",Vector2(1910,715))
	await _capture("native_herbs_east",Vector2(2270,925))
	await _capture("relief_west",Vector2(450,410))


func _independent_model_specs() -> Dictionary:
	var specs := {
		"cc0_boulder_west":{"foot":Vector2(855,650),"scale":1.0,"yaw":35.0,"variant":0,"blocking":true,"roi":0},
		"cc0_boulder_east_low":{"foot":Vector2(1910,685),"scale":0.82,"yaw":-24.0,"variant":0,"blocking":true,"roi":2}}
	var suffixes := ["a","b","c","d"]
	var offsets := [Vector2(-17,-7),Vector2(12,-2),Vector2(-4,10),Vector2(27,13)]
	for group in [{"id":"generated_shrub_west","foot":Vector2(1175,745),"roi":1},{"id":"grove_east_a","foot":Vector2(2270,895),"roi":3}]:
		for index in range(4):
			specs[String(group["id"])+"_"+suffixes[index]] = {"foot":group["foot"]+offsets[index],"scale":1.0,"yaw":22.0+73.0*index,"variant":index,"blocking":false,"roi":group["roi"]}
	return specs


func _v12_exact_new_alpha_order(sprite: Sprite2D, foot: Vector2, base_y: float, id: String) -> void:
	field._player.set_walk_direction(Vector2.RIGHT,false)
	for front in [false,true]:
		var found := false
		for dx in [0.0,-4.0,4.0,-8.0,8.0]:
			var point := Vector2(foot.x+dx,base_y+(9.0 if front else -9.0))
			if not _walks(point) or not _foot_clear(point):
				continue
			field._player.position = point
			field._player.refresh_depth_sort()
			var hits := _actual_actor_alpha_intersection(sprite)
			if hits <= 0:
				continue
			found = true
			_check(_actor_draws_after(sprite) == front, "actual CURRENT actor frame intersects new alpha with correct front/behind effective order: %s %s hits=%d" % [id,point,hits])
			print("[WorldLandmarkV12 new alpha] entity=%s foot=%s front=%s actual_hits=%d" % [id,point,front,hits])
			break
		_check(found, "new alpha has real legal-foot intersection on each side of base, not empty sprite/depth-only claim: %s front=%s" % [id,front])


func _v12_rock_foot_and_input_checks(id: String, sprite: Sprite2D, center: Vector2, extent: Vector2, base_y: float) -> void:
	var base := Rect2(center-extent*0.5,extent)
	var clear_on_solid := 0
	for yi in range(ceili(extent.y/4.0)+1):
		for xi in range(ceili(extent.x/4.0)+1):
			var point := base.position+extent*Vector2(float(xi)/ceili(extent.x/4.0),float(yi)/ceili(extent.y/4.0))
			if _foot_clear(point):
				clear_on_solid += 1
	_check(clear_on_solid == 0, "rock complete actual source XZ base blocks full feet including edges: %s bad=%d" % [id,clear_on_solid])
	var collider := field._player.get_node("CollisionShape2D") as CollisionShape2D
	var physical_half: Vector2 = collider.shape.get_rect().size*0.5
	_check(collider.position == Vector2.ZERO and collider.shape is RectangleShape2D and physical_half == Vector2(17,12), "actual ground-anchored Player physical Rectangle34x24 remains unchanged")
	# First2135/10 WIP failed because fixed16/10 offsets ignored BOTH the
	# actual Rectangle and Field's .004 visual-layout inset + foot ellipse.
	# Keep failed original stations in diagnostic log; do not change assets.
	var margin := Vector2(maxf(physical_half.x,0.004*3072+10.0),maxf(physical_half.y,0.004*1024+6.0))+Vector2(2,2)
	var expected_layout := Rect2(base.position/CONTRACT.WORLD_SIZE,base.size/CONTRACT.WORLD_SIZE).grow(0.004)
	var current_layout_found := false
	for footprint: Rect2 in field._walkability_blocker_footprints:
		current_layout_found = current_layout_found or (footprint.position.distance_to(expected_layout.position)<0.000001 and footprint.size.distance_to(expected_layout.size)<0.000001)
	_check(current_layout_found, "margin is based on actual runtime expanded rock footprint, not arbitrary epsilon: "+id)
	var sides := [-1,1] if id == "cc0_boulder_west" else [1]
	var side_samples := 0
	for side in sides:
		var x: float = base.position.x-margin.x if side < 0 else base.end.x+margin.x
		var north := Vector2(x,base.position.y-margin.y)
		var south := Vector2(x,base.end.y+margin.y)
		var samples := maxi(1,ceili(north.distance_to(south)/4.0))
		for sample in range(samples+1):
			var point := north.lerp(south,float(sample)/samples)
			_check(_walks(point) and _foot_clear(point) and not Rect2(point-physical_half,physical_half*2.0).intersects(base,true), "approved rock flank <=4px probe supports full ellipse AND actual Player Rectangle: %s side=%d %s" % [id,side,point])
			side_samples += 1
		field._player.position = north
		_check(await _drive_to(south), "actual input continuously bypasses new solid rock with complete feet: %s side=%d" % [id,side])
		_check(await _drive_to(north), "actual input returns on approved land flank with complete feet: %s side=%d" % [id,side])
	if id == "cc0_boulder_east_low":
		_v12_east_river_side_negative(base)
	field._player.position = Vector2(center.x,base.position.y-margin.y)
	_check(_walks(field._player.position) and _foot_clear(field._player.position), "dry northern rock-stop approach has complete legal foot: "+id)
	Input.action_press("move_down")
	for tick in range(24):
		await physics_frame
	Input.action_release("move_down")
	await physics_frame
	_check(field._player.position.y <= base.position.y+0.5, "actual input cannot cross solid rock from approved dry northern approach: "+id)
	# Four producer-approved witnesses selected from a bounded finite scan of
	# genuine current-frame alpha, not old center/right points. Directions are
	# part of evidence; do not combine an entire sheet into a fake source cell.
	var stations := [{"foot":Vector2(852,559),"direction":Vector2.DOWN,"front":false},{"foot":Vector2(888,701),"direction":Vector2.UP,"front":true}] if id == "cc0_boulder_west" else [{"foot":Vector2(1890,589),"direction":Vector2.DOWN,"front":false},{"foot":Vector2(1882,727),"direction":Vector2.UP,"front":true}]
	for station in stations:
		var point: Vector2 = station["foot"]
		field._player.set_walk_direction(station["direction"],false)
		field._player.position = point
		field._player.refresh_depth_sort()
		var hits := _actual_actor_alpha_intersection(sprite)
		_check(_walks(point) and _foot_clear(point) and not Rect2(point-physical_half,physical_half*2.0).intersects(base,true), "actual alpha witness also has full legal feet and nonintersecting physical Rectangle: %s %s" % [id,point])
		_check(hits > 0, "actual CURRENT source cell really overlaps new rock alpha at approved front/behind station: %s %s hits=%d" % [id,point,hits])
		_check(_actor_draws_after(sprite) == station["front"] and ((point.y>base_y) == station["front"]), "real source-foot base sorts alpha-overlapping actor correctly: %s %s" % [id,point])
		print("[WorldLandmarkV12 legal rock alpha] entity=",id," foot=",point," direction=",station["direction"]," current_frame=",field._player.sprite.frame," actual_hits=",hits," actor_bbox=",_current_actor_alpha_world_bounds())
		await _capture("native_"+id+("_front" if station["front"] else "_behind"),point)
	print("[WorldLandmarkV12 rock side scope] id=",id," continuous_fullfoot_samples=",side_samples," margin=",margin," sides=",sides,"; east river-side bypass NOT promised")


func _v12_east_river_side_negative(base: Rect2) -> void:
	var land := _read_png(CONTRACT.PREFIX+"land.png")
	var topology := _read_png(CONTRACT.PREFIX+"topology.png")
	var original_north := base.position+Vector2(-16,-16)
	var original_south := Vector2(original_north.x,base.end.y+16)
	for point in [original_north,original_south]:
		var pixel := Vector2i(point.round())
		_check(land.get_pixelv(pixel).r > 0.5 and topology.get_pixelv(pixel).r > 0.5 and not _foot_clear(point), "preserved original west-side station is natural dry bank but complete foot is forbidden by river safety strip, not collider removal: %s" % point)
	_check(not _walks(original_north) and _walks(original_south), "preserved exact river-side north center denied, south center legal but ellipse crosses forbidden bank")
	var samples := 0
	var legal := 0
	# Dense half-pixel centers across the finite adjacent west gap at three
	# cross-sections. Natural river geometry/masks and .004 collider inset
	# remain frozen; this is NOT a claim that all land west of the river is bad.
	for y in [604.0,620.0,640.0]:
		var row_legal := 0
		for half_step in range(81):
			var point := Vector2(base.position.x-40.0+half_step*0.5,y)
			samples += 1
			if _walks(point) and _foot_clear(point):
				row_legal += 1
				legal += 1
		_check(row_legal == 0, "east rock's adjacent 40px west gap has no complete-foot center at frozen river cross-section y="+str(y))
		var first_nav := -1
		for x in range(roundi(CONTRACT.river_x(y)),ceili(base.position.x)+1):
			if bool(field.call("_is_walkable_by_mask",Vector2(x,y)/CONTRACT.WORLD_SIZE)):
				first_nav = x
				break
		var max_rock_side_x := base.position.x-0.004*3072.0-10.0
		_check(first_nav >= 0 and float(first_nav)+10.0 > max_rock_side_x, "actual river safe-nav edge + ellipse and actual expanded rock edge have disjoint local bypass interval")
		print("[WorldLandmarkV12 east bank no corridor] y=",y," actual_first_nav_x=",first_nav," min_fullfoot_bank_x=",first_nav+10," max_fullfoot_rock_x=",max_rock_side_x," local_legal_centers=",row_legal)
	print("[WorldLandmarkV12 east bank negative] halfpixel_centers=",samples," legal=",legal," original_north=",original_north," original_south=",original_south,"; natural dry-bank safety restriction retained, east LANDWARD bypass only")


func _v12_ready_preflight() -> bool:
	var record: Variant = null
	var path: String = CONTRACT.PREFIX+"art.json"
	if FileAccess.file_exists(path):
		record = JSON.parse_string(FileAccess.get_file_as_string(path))
	var shadow := _read_png(CONTRACT.PREFIX+"shadow.png")
	var ready: bool = record is Dictionary and record.get("version") == "v12" and record.get("status") == "ISOLATED_VISUAL_CANDIDATE" and not bool(record.get("current_outputs_not_ready",false)) and record.get("outputs_ready",true) != false
	ready = ready and shadow != null and shadow.get_format() == Image.FORMAT_RGBA8 and shadow.get_size() == Vector2i(3072,1024) and shadow.get_used_rect().has_area()
	if record is Dictionary:
		ready = ready and record.get("mesh_winding",{}).get("only_index_changed",false) and record.get("capture_repeats",{}).get("on_exact",false) and record.get("capture_repeats",{}).get("off_exact",false) and record.get("entities",[]).size() == 10
	_check(ready, "PRECHECK requires READY candidate state and real nonempty native cast alpha; partial TECHNICAL_FAIL/empty shadow refused BEFORE Field load")
	return ready



