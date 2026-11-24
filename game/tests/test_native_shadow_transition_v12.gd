extends "res://tests/test_native_shadow_v12.gd"

# Reuse only frozen raw-image/math helpers. Override _run: never execute the
# earlier diagnostic, any renderer, Field, or a GPU viewport. This test checks
# the four transition experiments and deliberately preserves empty-mesh cases.
const TRANSITION := "res://build/native_shadow_transition_v12_"
const TOPOLOGY := "res://build/world_native_pair_ortho_v9_topology.png"
const TERRAIN := preload("res://scripts/dev/build_world_map_native_pair_ortho_v11.gd")
var _transition_raw: Dictionary = {}
var _transition_configs: Dictionary = {}
var _transition_nonempty: Array[String] = []
var _transition_empty: Array[String] = []
var _source_bounds := AABB()
var _source_support := AABB()
var _source_vertex_count := 0
var _source_ground := Vector3.ZERO


func _mesh_nodes(node: Node, found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		_mesh_nodes(child,found)


func _source_geometry() -> void:
	# Independent actual source vertices after the declared yaw and uniform
	# scale, not rotated AABB corners and not _prepare_models' reported bounds.
	var packed := load(BOULDER) as PackedScene
	_check(packed != null,"Original licensed caster model is readable")
	if packed == null:
		return
	var imported := packed.instantiate()
	var meshes: Array[MeshInstance3D] = []
	_mesh_nodes(imported,meshes)
	_check(not meshes.is_empty(),"Source caster has actual mesh vertices")
	if meshes.is_empty():
		imported.free()
		return
	var vertices: Array[Vector3] = []
	var basis := Basis(Vector3.UP,deg_to_rad(35.0))
	for surface in meshes[0].mesh.get_surface_count():
		var arrays := meshes[0].mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for vertex in positions:
			var turned := basis * vertex
			if vertices.is_empty():
				_source_bounds = AABB(turned,Vector3.ZERO)
			else:
				_source_bounds = _source_bounds.expand(turned)
			vertices.append(turned)
	_source_vertex_count = vertices.size()
	var support_first := true
	for vertex in vertices:
		if vertex.y > _source_bounds.position.y + _source_bounds.size.y * 0.06:
			continue
		if support_first:
			_source_support = AABB(vertex,Vector3.ZERO)
			support_first = false
		else:
			_source_support = _source_support.expand(vertex)
	_check(_source_vertex_count > 0 and not support_first,"Actual lowest-six-percent support exists")
	imported.free()
	var topology := Image.load_from_file(TOPOLOGY)
	_check(topology != null and topology.get_size() == Vector2i(3072,1024),"Same actual v9 topology used by transition")
	if topology == null:
		return
	# CPU height function only: no _initialize/_build/_prepare_models or hooks.
	var terrain := TERRAIN.new()
	var height: float = terrain.call("terrain_height",Vector2(855,650),topology)
	terrain.free()
	_source_ground = Vector3((855.0/3072.0-0.5)*30.0,height,(650.0/1024.0-0.5)*14.1421356)


func _vec3(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))


func _transition_case(name: String, kind: String, schedule: String) -> void:
	var config := _read_json(TRANSITION+name+".json")
	_check(not config.is_empty(),"Complete config required: "+name)
	if config.is_empty():
		return
	_transition_configs[name] = config
	_check(config.get("case") == name and config.get("receiver") == kind and config.get("schedule") == schedule,
		"Unique receiver/schedule case identity: "+name)
	var paths: Dictionary = config.get("paths",{})
	var path_matches := true
	for suffix in ["on","off","body","ground_difference"]:
		path_matches = path_matches and paths.get(suffix) == TRANSITION+name+"_"+suffix+".png"
	_check(path_matches,"Raw evidence bound to new transition prefix: "+name)
	_check(config.get("source") == BOULDER and config.get("source_sha256") == FileAccess.get_sha256(BOULDER)
		and config.get("source_topology") == TOPOLOGY and config.get("topology_sha256") == FileAccess.get_sha256(TOPOLOGY),
		"Actual licensed source and same topology SHA: "+name)
	_check(config.get("model_id") == "cc0_boulder_west" and _numbers_match(config.get("source_foot"),[855,650])
		and float(config.get("yaw",0)) == 35 and float(config.get("scale",0)) == 1
		and int(config.get("actual_vertex_count",0)) == _source_vertex_count,
		"Real west rock spec/yaw/unflattened scale and independent vertex count: "+name)
	var reported_ground := _vec3(config.get("ground_world",[0,0,0]))
	var position := _vec3(config.get("actual_model_position",[0,0,0]))
	var contact_local := Vector3(_source_support.get_center().x,_source_bounds.position.y,_source_support.end.z)
	var expected_position := _source_ground-contact_local
	_check(reported_ground.distance_to(_source_ground) < 0.00001 and position.distance_to(expected_position) < 0.00001,
		"Actual source front-XZ/minY support anchors unchanged, not translated to origin: "+name)
	var independent_lowest := position.y+_source_bounds.position.y
	_check(absf(independent_lowest-reported_ground.y) < 0.00001
		and absf(float(config.get("model_lowest_y",999))-independent_lowest) < 0.00001
		and absf(float(config.get("lowest_y_minus_ground_y",999))) < 0.00001,
		"Independent actual source vertices lowest Y rests on true ground: "+name)
	var reported_foot: Array = config.get("camera_unprojected_foot",[999,999])
	var reported_projection := Vector2(float(reported_foot[0]),float(reported_foot[1]))
	# Independent orthographic camera projection at (0,12,12), ortho vertical
	# span10 and 3:1 canvas: screen Y is the 45-degree camera down vector.
	var expected_projection := Vector2(SIZE.x*0.5+reported_ground.x*SIZE.y/10.0,
		SIZE.y*0.5+(reported_ground.z-reported_ground.y)*sqrt(0.5)*SIZE.y/10.0)
	var projection_error := reported_projection.distance_to(expected_projection)
	_check(projection_error < 0.01 and float(config.get("projection_error_px",999)) < 0.01
		and _numbers_match(config.get("analytic_projected_foot_at_half_resolution"),[expected_projection.x,expected_projection.y]),
		"Independent projection agrees with real camera foot within .01px: "+name)
	_check(_numbers_match(config.get("canvas"),[SIZE.x,SIZE.y]) and _numbers_match(config.get("camera_position"),[0,12,12])
		and float(config.get("camera_size",0)) == 10 and config.get("camera_mask") == 1
		and config.get("caster_layer") == 1 and (int(config.get("light_mask",0)) & 1) != 0
		and config.get("own_world_3d") == true and config.get("receiver_cast_shadow") == false,
		"Same camera/layers/isolated world and noncaster receiver: "+name)
	_check(config.get("cast") == "same_layer_SHADOWS_ONLY_ON_vs_hidden_OFF"
		and config.get("material") == "exact_v11_surface_material_with_actual_topology"
		and _numbers_match(config.get("light_rotation"),[-55,-34,0])
		and is_equal_approx(float(config.get("energy",0)),1.15) and is_equal_approx(float(config.get("ambient",0)),0.62)
		and int(config.get("shadow_mode",-1)) == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		and float(config.get("max_distance",0)) == 32 and is_equal_approx(float(config.get("bias",0)),0.02)
		and is_equal_approx(float(config.get("normal_bias",0)),0.08),
		"Only receiver mesh/schedule vary, cast/material/light/frustum fixed: "+name)
	_check(config.get("render_method") == "gl_compatibility" and config.get("render_driver") == "opengl3"
		and config.get("sync") == "6_process_frames_then_frame_post_draw_per_state_and_repeat"
		and config.get("no_v11_build_initialize_or_save_hooks") == true
		and int(config.get("mesh_surface_count",0)) == 1 and int(config.get("positional_atlas",0)) == 2048
		and int(config.get("directional_atlas",0)) > 0,
		"Recorded driver/readback/mesh isolation, not a full-map build: "+name)
	var images: Dictionary = {}
	for suffix in ["on","off","on_repeat","off_repeat","body","difference","ground_difference"]:
		var loaded := _read_image(TRANSITION+name+"_"+suffix+".png")
		if loaded == null:
			return
		images[suffix] = loaded
	_transition_raw[name] = images
	var on: Image = images["on"]
	var off: Image = images["off"]
	var body: Image = images["body"]
	var repeat_on: Image = images["on_repeat"]
	var repeat_off: Image = images["off_repeat"]
	var full: Image = images["difference"]
	var ground: Image = images["ground_difference"]
	_check(on.get_data() == repeat_on.get_data() and off.get_data() == repeat_off.get_data()
		and FileAccess.get_sha256(TRANSITION+name+"_on.png") == FileAccess.get_sha256(TRANSITION+name+"_on_repeat.png")
		and FileAccess.get_sha256(TRANSITION+name+"_off.png") == FileAccess.get_sha256(TRANSITION+name+"_off_repeat.png")
		and config.get("valid_case") == true and config.get("on_repeat_exact") == true and config.get("off_repeat_exact") == true,
		"Capture gate and actual repeat pixels/SHA are valid: "+name)
	var body_alpha := 0
	var body_zero := 0
	for y in SIZE.y:
		for x in SIZE.x:
			body_alpha += 1 if body.get_pixel(x,y).a > 0.01 else 0
			body_zero += 1 if body.get_pixel(x,y).a == 0 else 0
	var body_rect := body.get_used_rect()
	var body_stats: Dictionary = config.get("body_alpha",{})
	_check(body_alpha > 0 and body_zero > 0 and body_rect.has_area()
		and body_rect.size.x < SIZE.x and body_rect.size.y < SIZE.y and body.get_pixel(0,0).a == 0
		and body_alpha == int(body_stats.get("entity_alpha_pixels",-1)) and body_zero == int(body_stats.get("zero_alpha_pixels",-1))
		and body_stats.get("valid") == true
		and _numbers_match(body_stats.get("used_rect"),[body_rect.position.x,body_rect.position.y,body_rect.size.x,body_rect.size.y]),
		"Independent sourcebody localized transparent alpha and exact counts: "+name)
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
	_check(mismatch == 0,"Independent every-pixel luma/alpha-byte reconstruction excludes body: "+name+" mismatch="+str(mismatch))
	_check(dark == int(stats.get("dark_difference_pixels",-1)) and outside == int(stats.get("outside_body_ground_pixels",-1))
		and inside == int(stats.get("inside_dilated_body_difference_pixels",-1)) and signed == int(stats.get("signed_change_pixels",-1))
		and is_equal_approx(max_delta,float(stats.get("max_any_luma_delta",-1))) and is_equal_approx(max_alpha,float(stats.get("max_ground_alpha",-1)))
		and ground.get_used_rect() == used
		and _numbers_match(stats.get("ground_used_rect"),[used.position.x,used.position.y,used.size.x,used.size.y]),
		"Recorded statistics/true pixel extent match raw images: "+name)
	if kind == "plain_plane":
		_check(outside > 0 and config.get("capture_class") == "VALID_NONEMPTY", "Plain receiver is a real positive shadow control: "+name)
	else:
		_check(outside == 0 and dark == 0 and max_delta == 0 and on.get_data() == off.get_data()
			and config.get("capture_class") == "VALID_EMPTY", "Actual-mesh empty raw ON/OFF is preserved as a true failed capability, not a PASS: "+name)
	if outside > 0:
		_transition_nonempty.append(name)
	else:
		_transition_empty.append(name)
	print("[ShadowTransitionV12 QA case] ",name," ground=",outside," body_alpha=",body_alpha,
		" max_delta=",max_delta," rect=",used," projection_error=",projection_error," valid=true")


func _run() -> void:
	var protected_sha := {}
	var directory := DirAccess.open("res://build")
	for filename in directory.get_files():
		if filename.begins_with("native_shadow_v12_"):
			protected_sha["res://build/"+filename] = FileAccess.get_sha256("res://build/"+filename)
	for path in PROTECTED + ["res://tests/test_native_shadow_v12.gd","res://scripts/dev/diagnose_native_shadow_v12.gd"]:
		protected_sha[path] = FileAccess.get_sha256(path)
	var matrix := _read_json(TRANSITION+"matrix.json")
	_check(matrix.get("cases",[]).size() == 4 and matrix.get("invalid_cases",[]).is_empty()
		and matrix.get("one_GPU_transition_matrix") == true and matrix.get("formal_or_old_output_writes") == false
		and matrix.get("full_map_outputs_generated") == false,"Completed four-case isolated transition matrix only")
	if matrix.is_empty():
		quit(1)
		return
	_source_geometry()
	for kind in ["plain_plane","actual_v11_mesh"]:
		_transition_case(kind+"_sequential",kind,"one_viewport_sequential")
		_transition_case(kind+"_concurrent",kind,"two_independent_world_viewports_concurrent")
		if _transition_raw.has(kind+"_sequential") and _transition_raw.has(kind+"_concurrent"):
			for suffix in ["on","off","body","difference","ground_difference"]:
				var sequential: Image = _transition_raw[kind+"_sequential"][suffix]
				var concurrent: Image = _transition_raw[kind+"_concurrent"][suffix]
				_check(sequential.get_data() == concurrent.get_data(),"Same receiver sequential/concurrent raw pixels identical: "+kind+"/"+suffix)
	var model_fields := ["source","source_sha256","actual_model_position","ground_world","source_foot",
		"yaw","scale","actual_vertex_count","camera_position","camera_size","camera_mask","light_mask",
		"light_rotation","energy","ambient","cast","shadow_mode","max_distance","bias","normal_bias","material"]
	var invariant_matches := true
	var first_config: Dictionary = _transition_configs.get("plain_plane_sequential",{})
	for name in _transition_configs:
		for key in model_fields:
			invariant_matches = invariant_matches and _transition_configs[name].get(key) == first_config.get(key)
	_check(invariant_matches,"Model transform/camera/light/material identical across all four: only mesh/schedule vary")
	_check(matrix.get("status") == "PARTIAL_TRANSITION_FAILURE" and matrix.get("ground_nonempty_cases") == _transition_nonempty
		and _transition_nonempty.size() == 2 and _transition_empty.size() == 2,
		"Stable receiver-mesh failure branch must not be called ALL_TRANSITIONS_NONEMPTY")
	var protected_changes := 0
	for path in protected_sha:
		protected_changes += 1 if protected_sha[path] != FileAccess.get_sha256(path) else 0
	_check(protected_changes == 0,"Frozen previous fourteen evidence/source/test and v11 WIP unchanged; count="+str(protected_sha.size()))
	print("[ShadowTransitionV12 QA] evidence_checks=",_checks," evidence_failures=",_failures,
		"; localization evidence ","PASS" if _failures == 0 else "FAIL",
		"; true_positive=",_transition_nonempty,"; actual_mesh_CAPABILITY_FAIL=",_transition_empty,
		"; whole-map NOT PASS/Field NOT RUN/QA GPU NOT RUN")
	# Exit0 means evidence consistency only, explicitly not mesh/full-map pass.
	quit(0 if _failures == 0 else 1)
