extends "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd"

## NEW bounded material authoring, not a full exporter/publisher/Field test.
## Read the current frozen derivation; never rederive RF or regenerate sites.
const LANDSCAPE_SURFACE := preload("res://scripts/dev/world_map_v15_v10_landscape_visual_surface_20261012.gd")
const LANDSCAPE_SURFACE_PATH := "res://scripts/dev/world_map_v15_v10_landscape_visual_surface_20261012.gd"
const LANDSCAPE_SCOPE := "V10_THREE_LOCAL_LANDSCAPE_GPU_SAMPLES_NOT_FULL_NAV_FIELD"
const CURRENT_REPORT := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const CURRENT_REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const LANDSCAPE_CANVAS := Vector2i(1280,1024)
const CURRENT_FILES := {
	CURRENT_REPORT:CURRENT_REPORT_SHA,
	"res://data/scenes/world_map_jianghu.tres":"685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046",
	"res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
	"res://data/maps/world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	"res://art/maps/world_map_v15_complete_v9c/art_contract.json":"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a"
}
var landscape_bridge_records: Array[Dictionary] = []
var landscape_original_signature := ""
var landscape_source_before: Dictionary = {}
var landscape_decorations: Array[Dictionary] = []

static func authorization_template() -> Dictionary:
	return {"approved":false, "approved_by":"root", "scope":LANDSCAPE_SCOPE,
		"builder_path":"res://scripts/dev/build_world_map_v15_v10_landscape_visual_proposal_20261012.gd",
		"builder_sha256":"PENDING_CURRENT_SHA", "surface_path":LANDSCAPE_SURFACE_PATH,
		"surface_sha256":"PENDING_CURRENT_SHA", "allow_full64":false,
		"maximum_native_canvas":[2560,2048], "current_report_sha256":CURRENT_REPORT_SHA}

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var selected := "all"
	var auth_path := ""
	for arg: String in args:
		if arg.begins_with("--authorization="): auth_path = arg.trim_prefix("--authorization=")
		if arg.begins_with("--landscape-region="): selected = arg.trim_prefix("--landscape-region=")
	pilot_output = "res://build/world_map_v15_v10_landscape_visual/%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(pilot_output)) or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output)) != OK:
		push_error("Unique landscape BUILD unavailable.")
		quit(1)
		return
	pilot_result = {"scope":LANDSCAPE_SCOPE,"status":"SOURCE_LOADING","visual_approved":false,
		"production_approved":false,"Field_credit":false,"nav_credit":false,"full64_credit":false,
		"audio_tested":false,"actual_audio_driver":AudioServer.get_driver_name(),"cases":[],
		"engine_pid":OS.get_process_id(),"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)}}
	if "--world-landscape-visual-samples" not in args or DisplayServer.get_name() == "headless" or selected not in ["all","grass","bridge","forest"] or bridge.call("is_checkpoint_saves_suspended") != true or not _landscape_authorized(auth_path):
		if error.is_empty(): error = "Explicit local GPU scope/region/public suspension required."
		await _landscape_finish(false)
		return
	# This unchanged inherited loader prepares baseline sites, applies the
	# original Bianzhou approach, then installs the exact current derived RF.
	# It checks the original 2687 preparation and all18 actual PBR samplers.
	if not _load_pilot_inputs():
		await _landscape_finish(false)
		return
	landscape_original_signature = _landscape_geometry_signature()
	surface.release()
	surface = LANDSCAPE_SURFACE.new()
	if not surface.load_sources() or surface.evidence.size() != 18:
		error = "NEW existing18 complete PBR inputs unavailable: " + surface.error
		await _landscape_finish(false)
		return
	for row: Dictionary in surface.evidence:
		for key: String in ["path","source_path"]:
			if not _landscape_track(row[key]):
				await _landscape_finish(false)
				return
	pilot_result["geometry_before"] = landscape_original_signature
	pilot_result["current_geometry_artifacts"] = v9c_geometry_result["artifacts"].duplicate(true)
	pilot_result["revision_geometry_scope"] = "CURRENT_ROOT250_RF_REUSED_BYTE_EXACT_NOT_A_NEW_DERIVATION; ORIGINAL_NAV_AND_COLLISION_FILES_UNTOUCHED"
	pilot_result["original_preparation"] = pilot_result["original_site_preparation"].duplicate(true)
	pilot_result["source_before"] = landscape_source_before.duplicate(true)
	var samples: Array[Dictionary] = [{"id":"grass","center":Vector2(2600,3991)},
		{"id":"bridge","center":Vector2(source.structures[0]["center"])},
		{"id":"forest","center":Vector2(2050,4300)}]
	for sample: Dictionary in samples:
		if selected != "all" and selected != sample["id"]: continue
		if not await _landscape_capture(sample["id"],sample["center"]):
			await _landscape_finish(false)
			return
	pilot_result["geometry_after"] = _landscape_geometry_signature()
	pilot_result["geometry_fingerprint_unchanged"] = pilot_result["geometry_after"] == landscape_original_signature
	pilot_result["bridge_material_replacements"] = landscape_bridge_records.duplicate(true)
	pilot_result["actual_materials"] = (surface as LANDSCAPE_SURFACE).landscape_records.duplicate(true)
	pilot_result["licensed_PBR_inputs"] = surface.evidence.duplicate(true)
	pilot_result["new_nonblocking_visual_decorations"] = landscape_decorations.duplicate(true)
	pilot_result["decoration_runtime_carriers_and_Field_sort_credit"] = false
	if pilot_result["geometry_fingerprint_unchanged"] != true:
		error = "Source RF/routes/bridges/vegetation changed during visual-only draw."
		await _landscape_finish(false)
		return
	await _landscape_finish(true)

func _landscape_authorized(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		error = "Missing new root landscape authorization."
		return false
	var auth: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	pilot_result["authorization_observation"] = {"path":path,"sha256":FileAccess.get_sha256(path),"parsed_type":typeof(auth),"is_dictionary":auth is Dictionary}
	if not auth is Dictionary:
		error = "Exact new root builder/surface/local GPU authorization differs."
		return false
	var canvas: Variant = auth.get("maximum_native_canvas")
	var canvas_valid: bool = canvas is Array and canvas.size() == 2
	if canvas_valid:
		canvas_valid = typeof(canvas[0]) == TYPE_FLOAT and typeof(canvas[1]) == TYPE_FLOAT
		if canvas_valid: canvas_valid = is_finite(canvas[0]) and is_finite(canvas[1]) and canvas[0] == 2560.0 and canvas[1] == 2048.0
	var gates: Dictionary = {
		"approved_type_bool":typeof(auth.get("approved")) == TYPE_BOOL,"approved_true":auth.get("approved") == true,
		"approved_by_root":auth.get("approved_by") == "root","scope_exact":auth.get("scope") == LANDSCAPE_SCOPE,
		"builder_path_exact":auth.get("builder_path") == get_script().resource_path,
		"builder_sha256_exact":auth.get("builder_sha256") == FileAccess.get_sha256(get_script().resource_path),
		"surface_path_exact":auth.get("surface_path") == LANDSCAPE_SURFACE_PATH,
		"surface_sha256_exact":auth.get("surface_sha256") == FileAccess.get_sha256(LANDSCAPE_SURFACE_PATH),
		"allow_full64_false":auth.get("allow_full64") == false,"maximum_native_canvas_json_float_exact":canvas_valid,
		"current_report_sha256_exact":auth.get("current_report_sha256") == CURRENT_REPORT_SHA}
	pilot_result["authorization_observation"]["gates"] = gates.duplicate(true)
	pilot_result["authorization_observation"]["actual_authorization"] = auth.duplicate(true)
	pilot_result["authorization_observation"]["executed_builder_path"] = get_script().resource_path
	pilot_result["authorization_observation"]["executed_builder_sha256"] = FileAccess.get_sha256(get_script().resource_path)
	pilot_result["authorization_observation"]["actual_canvas_type"] = typeof(canvas)
	if canvas is Array:
		var element_types: Array[int] = []
		for element: Variant in canvas: element_types.append(typeof(element))
		pilot_result["authorization_observation"]["actual_canvas_element_types"] = element_types
	for gate: String in gates:
		if gates[gate] != true:
			error = "Exact new root builder/surface/local GPU authorization differs: " + gate
			return false
	for file: String in CURRENT_FILES:
		if FileAccess.get_sha256(file).to_lower() != CURRENT_FILES[file]:
			error = "Frozen current world input changed: " + file
			return false
	var frozen: Variant = JSON.parse_string(FileAccess.get_file_as_string(CURRENT_REPORT))
	if not frozen is Dictionary or not frozen.get("cached_inputs_sha256") is Dictionary or not frozen.get("derived_geometry_inputs") is Dictionary:
		error = "Current ROOT250 frozen path/geometry contract missing."
		return false
	pilot_inputs = frozen["cached_inputs_sha256"].duplicate(true)
	pilot_auth = {"derived_geometry_inputs":frozen["derived_geometry_inputs"].duplicate(true)}
	for file: String in CURRENT_FILES: pilot_inputs[file] = CURRENT_FILES[file]
	for file: String in [path,get_script().resource_path,LANDSCAPE_SURFACE_PATH]:
		pilot_inputs[file] = FileAccess.get_sha256(file)
	if not _v9c_bind_executed_script_closure(get_script().resource_path,{}): return false
	for file: String in pilot_inputs:
		if not _landscape_track(file): return false
	return true

func _landscape_track(path: String) -> bool:
	if not FileAccess.file_exists(path) or not pilot_inputs.has(path) or FileAccess.get_sha256(path).to_lower() != String(pilot_inputs[path]).to_lower():
		error = "Current consumed source differs or is unbound: " + path
		return false
	landscape_source_before[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size()}
	return true

func _landscape_geometry_signature() -> String:
	return _bytes_sha(var_to_bytes([source.heights.to_byte_array(),source.routes,source.rivers,
		source.structures,source.vegetation_sites]))

func _landscape_mesh_signature(node: Node) -> String:
	var rows: Array = []
	_landscape_mesh_rows(node,rows)
	return _bytes_sha(var_to_bytes(rows))

func _landscape_mesh_rows(node: Node,rows: Array) -> void:
	if node is Node3D: rows.append(node.transform)
	if node is MeshInstance3D:
		rows.append([node.mesh.get_class(),node.mesh.get_surface_count()])
		for index in node.mesh.get_surface_count(): rows.append(node.mesh.surface_get_arrays(index))
	for child in node.get_children(): _landscape_mesh_rows(child,rows)

func _add_bridge_geometry(world: Node3D,rect: Rect2) -> void:
	var holder := Node3D.new()
	world.add_child(holder)
	super._add_bridge_geometry(holder,rect)
	var before := _landscape_mesh_signature(holder)
	var material: ShaderMaterial = (surface as LANDSCAPE_SURFACE).bridge_material()
	_landscape_replace_timber(holder,material)
	var after := _landscape_mesh_signature(holder)
	landscape_bridge_records.append({"before":before,"after":after,"geometry_byte_exact":before == after,
		"deck_Y_rail_support_and_transforms_unchanged":before == after,"actual_code_sha256":_bytes_sha(material.shader.code.to_utf8_buffer())})
	if before != after: error = "Bridge geometry changed during material-only replacement."

func _landscape_replace_timber(node: Node,material: ShaderMaterial) -> void:
	if node is MeshInstance3D: node.material_override = material
	for child in node.get_children(): _landscape_replace_timber(child,material)

func _shader_gate(material: ShaderMaterial,required: Array[String]) -> bool:
	# Loader still constructs the exact ancestral V9E instance first. Do not
	# weaken its gate. Only the explicitly installed NEW surface uses this
	# current creation/code identity instead of the frozen V9E record path.
	if not surface is LANDSCAPE_SURFACE: return super._shader_gate(material,required)
	if material == null or material.shader == null or surface.get_script().resource_path != LANDSCAPE_SURFACE_PATH or not pilot_inputs.has(LANDSCAPE_SURFACE_PATH) or FileAccess.get_sha256(LANDSCAPE_SURFACE_PATH) != pilot_inputs[LANDSCAPE_SURFACE_PATH]: return false
	var found: Array[String] = []
	for uniform: Dictionary in material.shader.get_shader_uniform_list(): found.append(String(uniform["name"]))
	for key: String in required:
		if key not in found: return false
		if surface.textures.has(key) and material.get_shader_parameter(key) != surface.textures[key]: return false
	var kind := "water" if required.has("actual_height_rf") else "terrain"
	var current_code := _bytes_sha(material.shader.code.to_utf8_buffer())
	for row: Dictionary in (surface as LANDSCAPE_SURFACE).landscape_records:
		if row.get("kind") != kind or row.get("identity") != LANDSCAPE_SURFACE.LANDSCAPE_ID or row.get("actual_code_sha256") != current_code: continue
		if kind == "terrain": return row.get("bindings") == surface._v7_binding_evidence(material)
		return row.get("actual_RF_texture_bound") == true and row.get("depth_discard_alpha_water_Y_unchanged") == true and material.get_shader_parameter("actual_height_rf") == full_rf and material.get_shader_parameter("grid_origin") == Vector2i.ZERO and material.get_shader_parameter("grid_shape") == SOURCE.GRID_SIZE
	return false

func _landscape_add_low_cover(window: Rect2,id: String) -> bool:
	# Keep existing tree/bamboo positions and blocking bodies immutable. Low
	# clumps occupy deterministic route/door/bridge-external dry ground only.
	var flowers: Array[ArrayMesh] = []
	for variant in 3: flowers.append(LANDSCAPE_SURFACE.native_wildflower_mesh(variant))
	var serial := 0
	for y in range(5):
		for x in range(7):
			var anchor: Vector2 = window.position+Vector2(120+x*166+sin(y*2.3+x)*32,100+y*180+cos(x*1.7-y)*29)
			var road: Vector2 = source.road_distance(anchor)
			if road.x <= road.y+150. or source.triangle_height(anchor) <= .025: continue
			var reserved := false
			for landmark: Dictionary in SOURCE.LANDMARKS:
				if anchor.distance_to(Vector2(landmark["foot"])) < 440.: reserved = true
			for structure: Dictionary in source.structures:
				if anchor.distance_to(Vector2(structure["center"])) < float(structure["half_length_px"])+180.: reserved = true
			if reserved: continue
			var key: String = "herb"+str(posmod(x+y,3))
			if not native_prototype_cache.has(key): error = "Original licensed low-cover prototype missing."; return false
			var prototype: Dictionary = native_prototype_cache[key]
			for clump in 4:
				var point: Vector2 = anchor+Vector2(cos(clump*2.4)*24,sin(clump*2.4)*19)
				var distance: Vector2 = source.road_distance(point)
				var height: float = source.triangle_height(point)
				if distance.x <= distance.y+120. or height <= .025: continue
				var flower_point: Vector2 = point+Vector2(12,-8)
				var flower_height: float = source.triangle_height(flower_point)
				if flower_height <= .025: continue
				var plant := MeshInstance3D.new()
				plant.mesh = prototype["mesh"]
				plant.transform = Transform3D(prototype["basis"],SOURCE.point3(point,height)-Vector3(prototype["support"]))
				pilot_world.add_child(plant)
				var flower := MeshInstance3D.new()
				flower.mesh = flowers[posmod(x+y+clump,3)]
				flower.position = SOURCE.point3(flower_point,flower_height)
				pilot_world.add_child(flower)
				landscape_decorations.append({"id":id+"_low_cover_"+str(serial),"source_foot_px":[point.x,point.y],
					"height_m":height,"world_foot_px":[source.project_source(point).x,source.project_source(point).y],
					"blocking":false,"walk_support":false,"route_clearance_px":distance.x-distance.y,
					"low_cover_source":"Poly Haven shrub_03 CC0; exact original prototype mesh/material/basis",
					"original_prototype":prototype["record"].duplicate(true),
					"flower_source":"project-original native_wildflower_mesh in NEW surface; not CC0/AI",
					"flower_source_foot_px":[flower_point.x,flower_point.y],"flower_height_m":flower_height,
					"flower_mesh_sha256":_bytes_sha(var_to_bytes(flower.mesh.surface_get_arrays(0))),
					"scope":"LOCAL_3D_VISUAL_DECORATION_NOT_YET_RUNTIME_SPRITE_OR_FIELD_CREDIT"})
				serial += 1
	return true

func _landscape_capture(id: String,center: Vector2) -> bool:
	sample_entities.clear()
	var window := Rect2(center-Vector2(LANDSCAPE_CANVAS)*.5,Vector2(LANDSCAPE_CANVAS))
	var receiver := window.grow(384.)
	var maps: Dictionary = _material_maps(receiver)
	if maps.is_empty(): return false
	active_view = SubViewport.new()
	active_view.size = LANDSCAPE_CANVAS*SSAA
	active_view.own_world_3d = true
	active_view.msaa_3d = Viewport.MSAA_DISABLED
	active_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	pilot_world = Node3D.new()
	active_view.add_child(pilot_world)
	var environment := WorldEnvironment.new()
	environment.environment = surface.environment()
	pilot_world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-34,0)
	sun.light_energy = .85
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	pilot_world.add_child(sun)
	var terrain := MeshInstance3D.new()
	terrain.mesh = _mesh(receiver,false)
	terrain.material_override = surface.terrain_material(maps["ecology"],maps["roads"],receiver)
	if terrain.material_override == null: error = surface.error; return false
	pilot_world.add_child(terrain)
	var water := MeshInstance3D.new()
	water.mesh = _mesh(receiver,true)
	water.material_override = surface.water_material(full_rf,Vector2i.ZERO,SOURCE.GRID_SIZE)
	if water.material_override == null: error = surface.error; return false
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pilot_world.add_child(water)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(LANDSCAPE_CANVAS.y)/SOURCE.PPM
	camera.near = .05
	camera.far = 100.
	var target: Vector3 = SOURCE.point3(center,0.)
	camera.position = target+Vector3(0,20,20)
	pilot_world.add_child(camera)
	camera.look_at(target)
	camera.current = true
	var coverage: Dictionary = _receiver_coverage(camera,terrain.mesh as ArrayMesh,active_view.size)
	if coverage.get("passed") != true: error = "Original local receiver coverage failed: " + id; return false
	_add_bridge_geometry(pilot_world,receiver)
	if not error.is_empty(): return false
	_add_ecology_component_layers(active_view,pilot_world,camera,receiver)
	if not _landscape_add_low_cover(window,id): return false
	await _sync()
	if not _shader_gate(terrain.material_override,["biome_weights","road_weights","grass_ground_diff","rock_01_arm"]) or not _shader_gate(water.material_override,["actual_height_rf","grid_origin","grid_shape"]):
		error = "Actual shader reflection/sampler bindings refused: " + id
		return false
	var raw: Image = active_view.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat: Image = active_view.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	if raw.get_data() != repeat.get_data(): error = "Static native repeated draw differs: " + id; return false
	var prefix := pilot_output+id
	if raw.save_png(prefix+"_raw.png") != OK or repeat.save_png(prefix+"_repeat.png") != OK: error = "GPU raw save failed."; return false
	var logical: Image = raw.duplicate() as Image
	logical.resize(LANDSCAPE_CANVAS.x,LANDSCAPE_CANVAS.y,Image.INTERPOLATE_LANCZOS)
	if logical.save_png(prefix+"_scene.png") != OK: error = "GPU logical save failed."; return false
	pilot_result["cases"].append({"id":id,"source_window_px":_recti(Rect2i(window)),
		"image_path":prefix+"_scene.png","image_sha256":FileAccess.get_sha256(prefix+"_scene.png"),
		"raw_path":prefix+"_raw.png","raw_sha256":FileAccess.get_sha256(prefix+"_raw.png"),
		"repeat_path":prefix+"_repeat.png","repeat_sha256":FileAccess.get_sha256(prefix+"_repeat.png"),
		"raw_repeat_byte_exact":true,"receiver_coverage":coverage,"native_canvas":[2560,2048],
		"ecology_instances":sample_entities.duplicate(true),"ecology_placement_and_sort_original":true,
		"local_RF_geometry_only_not_whole_mesh_capture":true})
	await _pilot_release_world()
	return true

func _landscape_finish(passed: bool) -> void:
	await _pilot_release_world()
	var changes: Array = []
	for path: String in landscape_source_before:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != landscape_source_before[path]["sha256"] or FileAccess.get_file_as_bytes(path).size() != landscape_source_before[path]["bytes"]: changes.append(path)
	if not changes.is_empty(): passed = false; error = "Source inputs changed during local GPU run."
	pilot_result["source_changes"] = changes
	pilot_result["status"] = "LOCAL_VISUAL_CANDIDATE_REQUIRES_ROOT_IMAGE_REVIEW" if passed else "TECHNICAL_FAIL"
	pilot_result["reason"] = error
	pilot_result["checkpoint_suspension_held_to_quit"] = root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")
	if not _write_json(pilot_output+"result.json",pilot_result): passed = false
	if not passed: push_error(error)
	if surface != null: surface.release()
	surface = null
	source = null
	full_map_textures.clear()
	v9c_geometry_result.clear()
	native_mesh_cache.clear()
	native_prototype_cache.clear()
	native_texture_cache.clear()
	pilot_global_mesh = null
	pilot_support_mesh = null
	pilot_transport = null
	pilot_shader = null
	full_rf = null
	full_topology = null
	height_texture = null
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick in 16: await process_frame
	print("WORLD_LANDSCAPE_VISUAL_RESULT ",pilot_output+"result.json"," passed=",passed)
	quit(0 if passed else 1)
