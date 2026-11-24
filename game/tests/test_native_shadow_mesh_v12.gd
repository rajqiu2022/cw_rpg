extends "res://tests/test_native_shadow_transition_v12.gd"

# Independent CPU winding and raw-image checks only. Inherit frozen pure
# image/sourcevertex helpers, override _run, never invoke a renderer or Field.
const MESH_OUTPUT := "res://build/native_shadow_mesh_v12_"
var _facts: Dictionary = {}
var _mesh_images: Dictionary = {}
var _mesh_configs: Dictionary = {}
var _mesh_nonempty: Array[String] = []


func _hash_bytes(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()


func _facts_for(mesh: Mesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var count := indices.size() if not indices.is_empty() else vertices.size()
	var positive := 0
	var negative := 0
	var zero := 0
	for index in range(0,count,3):
		var a := vertices[indices[index] if not indices.is_empty() else index]
		var b := vertices[indices[index+1] if not indices.is_empty() else index+1]
		var c := vertices[indices[index+2] if not indices.is_empty() else index+2]
		# Direct XZ determinant, independently of diagnostic cross-vector helper.
		var sign_y := (b.z-a.z)*(c.x-a.x)-(b.x-a.x)*(c.z-a.z)
		positive += 1 if sign_y > 0 else 0
		negative += 1 if sign_y < 0 else 0
		zero += 1 if sign_y == 0 else 0
	return {"vertices":vertices.size(),"triangles":count/3,
		"cross_y_positive":positive,"cross_y_negative":negative,"cross_y_zero":zero,
		"vertex_sha256":_hash_bytes(vertices.to_byte_array()),"normal_sha256":_hash_bytes(normals.to_byte_array()),
		"UV_sha256":_hash_bytes(uv.to_byte_array()),"index_sha256":_hash_bytes(indices.to_byte_array())}


func _geometry_checks() -> void:
	var topology := Image.new()
	_check(topology.load(TOPOLOGY) == OK,"Actual topology readable for CPU mesh reconstruction")
	var renderer := TERRAIN.new()
	# Existing CPU geometry function only. No _initialize/build/export hooks.
	var actual: ArrayMesh = renderer.call("_mesh",topology,false)
	var flat: ArrayMesh = renderer.call("_mesh",topology,true)
	renderer.free()
	var reversed := ArrayMesh.new()
	var original_packed: Array = actual.get("_surfaces")
	var new_packed := original_packed.duplicate(true)
	var every_swap := true
	var every_sign := true
	var packed_preserved := true
	var total_triangles := 0
	for surface in actual.get_surface_count():
		var arrays := actual.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var rewritten: PackedInt32Array = indices.duplicate()
		_check(not indices.is_empty() and indices.size()%3 == 0,"Indexed triangle source, no degenerate strip")
		for offset in range(0,indices.size(),3):
			rewritten[offset] = indices[offset]
			rewritten[offset+1] = indices[offset+2]
			rewritten[offset+2] = indices[offset+1]
			var a := vertices[indices[offset]]
			var b := vertices[indices[offset+1]]
			var c := vertices[indices[offset+2]]
			var original_y := (b.z-a.z)*(c.x-a.x)-(b.x-a.x)*(c.z-a.z)
			var reversed_y := (c.z-a.z)*(b.x-a.x)-(c.x-a.x)*(b.z-a.z)
			every_sign = every_sign and original_y > 0 and reversed_y < 0 and original_y == -reversed_y
			total_triangles += 1
		var bytes: PackedByteArray = new_packed[surface]["index_data"]
		var stride := bytes.size()/indices.size()
		_check(stride == 2 or stride == 4,"Source packed index stride explicitly derived, not forced32")
		for index in rewritten.size():
			if stride == 2:
				bytes.encode_u16(index*2,rewritten[index])
			else:
				bytes.encode_u32(index*4,rewritten[index])
		new_packed[surface]["index_data"] = bytes
		for key in original_packed[surface]:
			if key != "index_data":
				packed_preserved = packed_preserved and original_packed[surface][key] == new_packed[surface][key]
	reversed.set("_surfaces",new_packed)
	for surface in actual.get_surface_count():
		var original_indices: PackedInt32Array = actual.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
		var swapped_indices: PackedInt32Array = reversed.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
		every_swap = every_swap and original_indices.size() == swapped_indices.size()
		for offset in range(0,original_indices.size(),3):
			every_swap = every_swap and swapped_indices[offset] == original_indices[offset]
			every_swap = every_swap and swapped_indices[offset+1] == original_indices[offset+2]
			every_swap = every_swap and swapped_indices[offset+2] == original_indices[offset+1]
	_check(every_swap and every_sign and total_triangles == 36800,"All36800 actual triangles exact(0,2,1) with opposite nonzero determinant")
	_check(packed_preserved,"Every original packed surface field except index_data is byte/Variant identical")
	var plane := PlaneMesh.new()
	plane.size = Vector2(30,14.1421356)
	_facts = {"actual":_facts_for(actual),"reverse":_facts_for(reversed),"flat":_facts_for(flat),"engine_PlaneMesh":_facts_for(plane)}
	for key in ["vertex_sha256","normal_sha256","UV_sha256"]:
		_check(_facts["actual"][key] == _facts["reverse"][key],"Independent index-only reversal leaves source stream SHA unchanged: "+key)
	_check(_facts["actual"]["index_sha256"] != _facts["reverse"]["index_sha256"],"Reversal actually changes index stream SHA")
	_check(_facts["actual"]["cross_y_positive"] == 36800 and _facts["actual"]["cross_y_zero"] == 0
		and _facts["reverse"]["cross_y_negative"] == 36800 and _facts["reverse"]["cross_y_zero"] == 0,
		"Actual positive / reversed negative, zero degenerate faces independently recomputed")
	_check(_facts["engine_PlaneMesh"]["cross_y_negative"] == 2 and _facts["engine_PlaneMesh"]["cross_y_positive"] == 0,
		"Engine PlaneMesh's actual negative winding is control, not inferred from normals")
	var preflight := _read_json(MESH_OUTPUT+"geometry_preflight.json")
	for kind in _facts:
		var agrees := true
		for key in _facts[kind]:
			agrees = agrees and preflight.get(kind,{}).get(key) == _facts[kind][key]
		_check(agrees,"Independent actual CPU geometry/SHA agrees with preflight: "+kind)
	print("[ShadowMeshV12 QA CPU] original+=",_facts["actual"]["cross_y_positive"],
		" reverse-=",_facts["reverse"]["cross_y_negative"]," degenerate=",_facts["reverse"]["cross_y_zero"]," index-only=true")


func _mesh_case_check(kind: String, matrix_config: Dictionary) -> void:
	var config := _read_json(MESH_OUTPUT+kind+".json")
	_check(not config.is_empty() and config == matrix_config and config.get("case") == kind
		and config.get("only_case_variable") == kind,"Matrix and unique raw case config bind actual experiment: "+kind)
	if config.is_empty():
		return
	_mesh_configs[kind] = config
	var paths: Dictionary = config.get("paths",{})
	var paths_match := true
	for suffix in ["on","off","body","ground_difference"]:
		paths_match = paths_match and paths.get(suffix) == MESH_OUTPUT+kind+"_"+suffix+".png"
	_check(paths_match,"Every rawcase path uses independent mesh prefix: "+kind)
	_check(config.get("source") == BOULDER and config.get("source_sha256") == FileAccess.get_sha256(BOULDER)
		and config.get("source_topology") == TOPOLOGY and config.get("topology_sha256") == FileAccess.get_sha256(TOPOLOGY)
		and config.get("source_mesh") == "exact_v11_mesh" and _numbers_match(config.get("source_foot"),[855,650]),
		"Real source/topology hashes and unchanged sourcefoot: "+kind)
	var expected_fact: Dictionary = _facts["reverse" if kind == "reverse_winding" else "flat" if kind == "flat_actual_topology" else "actual"]
	var facts_match := true
	for key in expected_fact:
		facts_match = facts_match and config.get("mesh_after",{}).get(key) == expected_fact[key]
		facts_match = facts_match and config.get("mesh_before",{}).get(key) == _facts["actual"][key]
	_check(facts_match,"Actual capture mesh_before/after bind independently rebuilt streams: "+kind)
	_check(config.get("material") == ("StandardMaterial3D_cull_disabled" if kind == "standard_material" else "exact_v11_surface_material_cull_disabled")
		and _numbers_match(config.get("canvas"),[SIZE.x,SIZE.y]) and _numbers_match(config.get("camera_position"),[0,12,12])
		and float(config.get("camera_size",0)) == 10 and config.get("caster_layer") == 1 and config.get("camera_mask") == 1,
		"Material is case-only variable and camera/visibility unchanged: "+kind)
	_check(config.get("cast") == "same_layer_SHADOWS_ONLY_ON_vs_hidden_OFF" and config.get("shadow_mode") == "PARALLEL_2_SPLITS"
		and float(config.get("max_distance",0)) == 32 and _numbers_match(config.get("light_rotation"),[-55,-34,0])
		and is_equal_approx(float(config.get("energy",0)),1.15) and is_equal_approx(float(config.get("ambient",0)),0.62)
		and is_equal_approx(float(config.get("bias",0)),0.02) and is_equal_approx(float(config.get("normal_bias",0)),0.08)
		and config.get("sync") == "6_process_frames_then_frame_post_draw_per_state_and_repeat" and config.get("old_outputs_written") == false,
		"Same actual light/cast/frustum/postdraw; no old writes: "+kind)
	var images: Dictionary = {}
	for suffix in ["on","off","on_repeat","off_repeat","body","difference","ground_difference"]:
		var loaded := _read_image(MESH_OUTPUT+kind+"_"+suffix+".png")
		if loaded == null:
			return
		images[suffix] = loaded
	_mesh_images[kind] = images
	var on: Image = images["on"]
	var off: Image = images["off"]
	var body: Image = images["body"]
	var repeat_on: Image = images["on_repeat"]
	var repeat_off: Image = images["off_repeat"]
	var full: Image = images["difference"]
	var ground: Image = images["ground_difference"]
	_check(config.get("valid_case") == true and config.get("on_repeat_exact") == true and config.get("off_repeat_exact") == true
		and on.get_data() == repeat_on.get_data() and off.get_data() == repeat_off.get_data()
		and FileAccess.get_sha256(MESH_OUTPUT+kind+"_on.png") == FileAccess.get_sha256(MESH_OUTPUT+kind+"_on_repeat.png")
		and FileAccess.get_sha256(MESH_OUTPUT+kind+"_off.png") == FileAccess.get_sha256(MESH_OUTPUT+kind+"_off_repeat.png"),
		"Independent body/readback capture valid and repeated pixels/SHA stable: "+kind)
	var opaque := 0
	var transparent := 0
	for y in SIZE.y:
		for x in SIZE.x:
			opaque += 1 if body.get_pixel(x,y).a > 0.01 else 0
			transparent += 1 if body.get_pixel(x,y).a == 0 else 0
	var body_rect := body.get_used_rect()
	var body_stats: Dictionary = config.get("body_alpha",{})
	_check(opaque > 0 and transparent > 0 and body_rect.has_area() and body_rect.size.x < SIZE.x and body_rect.size.y < SIZE.y
		and body.get_pixel(0,0).a == 0 and body.get_pixel(SIZE.x-1,SIZE.y-1).a == 0 and body_stats.get("valid") == true
		and opaque == int(body_stats.get("entity_alpha_pixels",-1)) and transparent == int(body_stats.get("zero_alpha_pixels",-1))
		and _numbers_match(body_stats.get("used_rect"),[body_rect.position.x,body_rect.position.y,body_rect.size.x,body_rect.size.y]),
		"Real independent sourcebody alpha nonempty/localized, not full opaque background: "+kind)
	var exclusion := _body_exclusion(body)
	var dark := 0
	var outside := 0
	var inside := 0
	var signed := 0
	var max_delta := 0.0
	var max_alpha := 0.0
	var mismatch := 0
	var min_pixel := SIZE
	var max_pixel := Vector2i(-1,-1)
	for y in SIZE.y:
		for x in SIZE.x:
			var before := _luma(off.get_pixel(x,y))
			var delta := before-_luma(on.get_pixel(x,y))
			max_delta = maxf(max_delta,absf(delta))
			signed += 1 if absf(delta) > 0.004 else 0
			var alpha := clampf(delta/maxf(before,0.025),0,0.95)
			if alpha < 0.015:
				alpha = 0
			var ground_alpha := 0.0
			if alpha > 0:
				dark += 1
				if exclusion[y*SIZE.x+x] != 0:
					inside += 1
				else:
					outside += 1
					ground_alpha = alpha
					max_alpha = maxf(max_alpha,alpha)
					min_pixel.x = mini(min_pixel.x,x)
					min_pixel.y = mini(min_pixel.y,y)
					max_pixel.x = maxi(max_pixel.x,x)
					max_pixel.y = maxi(max_pixel.y,y)
			var fp := full.get_pixel(x,y)
			var gp := ground.get_pixel(x,y)
			if (roundi(fp.a*255.0) != int(alpha*255.0) or roundi(gp.a*255.0) != int(ground_alpha*255.0)
					or fp.r != 0 or fp.g != 0 or fp.b != 0 or gp.r != 0 or gp.g != 0 or gp.b != 0):
				mismatch += 1
	var used := Rect2i(min_pixel,max_pixel-min_pixel+Vector2i.ONE) if outside > 0 else Rect2i()
	var stats: Dictionary = config.get("statistics",{})
	_check(mismatch == 0 and ground.get_used_rect() == used,"Whole-pixel actual luma/precise alpha bytes and body exclusion: "+kind)
	_check(dark == int(stats.get("dark_difference_pixels",-1)) and outside == int(stats.get("outside_body_ground_pixels",-1))
		and inside == int(stats.get("inside_dilated_body_difference_pixels",-1)) and signed == int(stats.get("signed_change_pixels",-1))
		and is_equal_approx(max_delta,float(stats.get("max_any_luma_delta",-1))) and is_equal_approx(max_alpha,float(stats.get("max_ground_alpha",-1)))
		and _numbers_match(stats.get("ground_used_rect"),[used.position.x,used.position.y,used.size.x,used.size.y]),
		"Independent raw statistics/range agree, not merely nonempty metadata: "+kind)
	if kind == "reverse_winding":
		_check(outside > 0 and config.get("capture_class") == "VALID_NONEMPTY","Index-only reversal restores true nonvisible body-outside ground cast")
		_mesh_nonempty.append(kind)
	else:
		_check(outside == 0 and dark == 0 and max_delta == 0 and on.get_data() == off.get_data()
			and config.get("capture_class") == "VALID_EMPTY","Original/material/flat actual indexed mesh remains true zero negative: "+kind)
	print("[ShadowMeshV12 QA case] ",kind," ground=",outside," body=",opaque," maxdelta=",max_delta," alpha=",max_alpha," rect=",used)


func _run() -> void:
	var protected_sha := {}
	var directory := DirAccess.open("res://build")
	for filename in directory.get_files():
		if filename.begins_with("native_shadow_v12_") or filename.begins_with("native_shadow_transition_v12_"):
			protected_sha["res://build/"+filename] = FileAccess.get_sha256("res://build/"+filename)
	for path in PROTECTED + ["res://tests/test_native_shadow_v12.gd","res://tests/test_native_shadow_transition_v12.gd",
		"res://scripts/dev/diagnose_native_shadow_v12.gd","res://scripts/dev/diagnose_native_shadow_transition_v12.gd"]:
		protected_sha[path] = FileAccess.get_sha256(path)
	var matrix := _read_json(MESH_OUTPUT+"matrix.json")
	_check(matrix.get("cases",[]).size() == 4 and matrix.get("GPU_matrix_count") == 1 and matrix.get("max_cases") == 4
		and matrix.get("no_full_map_outputs") == true and matrix.get("old_scripts_outputs_frozen") == true
		and matrix.get("status") == "MESH_VARIABLE_EVIDENCE_NOT_FORMAL_PASS","Complete isolated four-case mesh matrix, not formal ready")
	if matrix.is_empty():
		quit(1)
		return
	_geometry_checks()
	var expected_ids := ["actual_original","reverse_winding","standard_material","flat_actual_topology"]
	var seen: Array[String] = []
	for config: Dictionary in matrix.get("cases",[]):
		var kind: String = config.get("case","")
		_check(expected_ids.has(kind) and not seen.has(kind),"Unique approved mesh variable: "+kind)
		seen.append(kind)
		_mesh_case_check(kind,config)
	var common_fields := ["actual_model_position","source_foot","camera_unprojected_foot","ground_world","receiver_y",
		"source","source_sha256","topology_sha256","source_topology","caster_layer","camera_mask","cast",
		"camera_position","camera_size","light_rotation","energy","ambient","shadow_mode","max_distance","bias","normal_bias","sync"]
	var invariants := true
	for kind in _mesh_configs:
		for key in common_fields:
			invariants = invariants and _mesh_configs[kind].get(key) == _mesh_configs["actual_original"].get(key)
	_check(invariants,"Four captures keep actual model/camera/light/source unchanged; controlled case variables only")
	if _mesh_images.has("actual_original") and _mesh_images.has("reverse_winding"):
		var original_body: Image = _mesh_images["actual_original"]["body"]
		var reversed_body: Image = _mesh_images["reverse_winding"]["body"]
		_check(original_body.get_data() == reversed_body.get_data(),"Restored shadow did not change actual caster silhouette or placement")
	_check(_mesh_nonempty == ["reverse_winding"],"Index-only reversal is the single true ground-positive experiment")
	var changed := 0
	for path in protected_sha:
		changed += 1 if protected_sha[path] != FileAccess.get_sha256(path) else 0
	_check(changed == 0,"Old14/transition evidence and tests/source/v11 WIP SHA unchanged")
	print("[ShadowMeshV12 QA] checks=",_checks," failures=",_failures," protected_files=",protected_sha.size(),
		"; index-only local mesh capability ","PASS" if _failures == 0 else "FAIL",
		"; whole-map NOT VALIDATED/promote NOT authorized/Field NOT RUN/QA GPU NOT RUN")
	quit(0 if _failures == 0 else 1)
