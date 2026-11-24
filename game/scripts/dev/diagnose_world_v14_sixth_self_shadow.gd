extends "res://scripts/dev/preview_world_map_v14_material_relief_sixth.gd"

# Three isolated same-receiver controls. Never touches original three preview
# outputs or fifth production assets. GPU execution needs producer scheduling.
const DIAG := "res://build/world_map_v14_sixth_self_shadow/"
const FIXTURE := Vector2(2130,1620)
const SHADOW_CASES := [
	{"id":"self_on_original","cast":true,"bias":.02,"normal_bias":.08},
	{"id":"self_off_control","cast":false,"bias":.02,"normal_bias":.08},
	{"id":"self_on_normal_bias_1","cast":true,"bias":.02,"normal_bias":1.0},
]

func _initialize() -> void:
	_diagnose.call_deferred()

func _fail(reason: String) -> void:
	failed = true
	push_error("[SixthSelfShadow] "+reason)
	if DirAccess.dir_exists_absolute(DIAG):
		_diag_json("result.json",{"status":"SELF_SHADOW_DIAGNOSTIC_FAIL","reason":reason,"production_approved":false})
	quit(1)

func _diag_json(name: String,value: Dictionary) -> void:
	var stream := FileAccess.open(DIAG+name,FileAccess.WRITE)
	assert(stream!=null)
	stream.store_string(JSON.stringify(value,"\t"))

func _geometry_evidence(mesh: ArrayMesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var positive := 0
	var negative := 0
	var zero := 0
	var minimum_normal_y := 1.0
	var maximum_normal_y := -1.0
	for normal in normals:
		minimum_normal_y = minf(minimum_normal_y,normal.y)
		maximum_normal_y = maxf(maximum_normal_y,normal.y)
	for i in range(0,indices.size(),3):
		var y := (vertices[indices[i+1]]-vertices[indices[i]]).cross(vertices[indices[i+2]]-vertices[indices[i]]).y
		if y>.00000001: positive += 1
		elif y<-.00000001: negative += 1
		else: zero += 1
	return {"triangles":indices.size()/3,"cross_y_positive":positive,"cross_y_negative":negative,"cross_y_zero":zero,"normal_y_min":minimum_normal_y,"normal_y_max":maximum_normal_y,"positions_sha256":vertices.to_byte_array().hex_encode().sha256_text(),"indices_sha256":indices.to_byte_array().hex_encode().sha256_text(),"normal_sha256":normals.to_byte_array().hex_encode().sha256_text(),"uv_sha256":uv.to_byte_array().hex_encode().sha256_text(),"sha_semantics":"SHA256 of hex-encoded actual native packed-array bytes; explicit same method for all fixture controls","index_order":"[a,b,c,b,d,c], positive up normals; Godot clockwise front cross.y negative"}

func _plane_uv_evidence() -> Dictionary:
	var plane := PlaneMesh.new()
	plane.size = WORLD
	var arrays := plane.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var records: Array[Dictionary] = []
	var max_error := 0.0
	for i in vertices.size():
		var source_from_vertex := Vector2((vertices[i].x/WORLD.x+.5)*WORLD_PX.x,(vertices[i].z/WORLD.y+.5)*WORLD_PX.y)
		var source_from_uv := uv[i]*WORLD_PX
		var error := source_from_vertex.distance_to(source_from_uv)
		max_error = maxf(max_error,error)
		records.append({"actual_vertex":[vertices[i].x,vertices[i].y,vertices[i].z],"actual_uv":[uv[i].x,uv[i].y],"source_px_by_point_inverse":[source_from_vertex.x,source_from_vertex.y],"source_px_by_current_water_shader_uv":[source_from_uv.x,source_from_uv.y],"error_px":error})
	return {"engine_type":"PlaneMesh","actual_size_m":[plane.size.x,plane.size.y],"actual_vertex_uv_records":records,"maximum_source_px_mapping_error":max_error,"water_first_matrix_unchanged":true,"interpretation":"mapping witness only; a mismatch requires a separate later water variant, never changes the three shadow controls"}

func _differences(on: Image,off: Image,name: String) -> Dictionary:
	var difference := Image.create(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8)
	var changed := 0
	var darker := 0
	var lighter := 0
	var maximum := 0.0
	for y in CANVAS.y:
		for x in CANVAS.x:
			var a := on.get_pixel(x,y)
			var b := off.get_pixel(x,y)
			var la := a.r*.2126+a.g*.7152+a.b*.0722
			var lb := b.r*.2126+b.g*.7152+b.b*.0722
			var relative := (lb-la)/maxf(lb,.05)
			maximum = maxf(maximum,absf(relative))
			if absf(relative)>.015:
				changed += 1
				if relative>0: darker += 1
				else: lighter += 1
				difference.set_pixel(x,y,Color(clampf(maxf(relative,0),0,1),0,clampf(maxf(-relative,0),0,1),1))
	assert(difference.save_png(DIAG+name+".png")==OK)
	return {"pixels_abs_relative_luma_gt_015":changed,"on_darker_pixels":darker,"on_lighter_pixels":lighter,"maximum_relative_luma_delta":maximum,"diff_png":DIAG+name+".png","red":"ON darker than OFF","blue":"ON lighter than OFF","body_contamination":"no native entity/body in fixture; geometry/sky/surface identical"}

func _diagnose() -> void:
	if DisplayServer.get_name()=="headless":
		_fail("Actual GPU controls required")
		return
	var manifest := _read_json(BASE+"manifest.json")
	if String(manifest.get("executed_builder_sha256","")).to_lower()!=BASE_EXECUTED_SHA:
		_fail("Frozen fifth source binding changed")
		return
	contract = _read_json(BASE+"source_contract.json")
	heights = FileAccess.get_file_as_bytes(BASE+"height_grid.rf").to_float32_array()
	if heights.size()!=(COLS+1)*(ROWS+1):
		_fail("Frozen RF source invalid")
		return
	var source_topology := Image.load_from_file(BASE+"source_topology.png")
	if source_topology==null:
		_fail("Frozen source topology unavailable")
		return
	topology = ImageTexture.create_from_image(source_topology)
	if not _load_pbr(): return
	surface = _surface_material()
	water = _water_material()
	if failed or surface==null or water==null: return
	_prepare_routes()
	var mesh := _local_mesh(FIXTURE)
	var geometry := _geometry_evidence(mesh)
	if geometry["cross_y_positive"]!=0 or geometry["cross_y_zero"]!=0 or geometry["normal_y_min"]<=0:
		_fail("Actual winding/up-normal geometry control failed")
		return
	DirAccess.make_dir_recursive_absolute(DIAG)
	_diag_json("result.json",{"status":"SELF_SHADOW_DIAGNOSTIC_IN_PROGRESS","production_approved":false})
	var view := _viewport(FIXTURE,mesh)
	var world: Node = view.get_child(0)
	var terrain: MeshInstance3D = null
	var light: DirectionalLight3D = null
	var camera: Camera3D = null
	for child in world.get_children():
		if child is MeshInstance3D and child.mesh==mesh: terrain=child
		if child is DirectionalLight3D: light=child
		if child is Camera3D: camera=child
	if terrain==null or light==null or camera==null:
		_fail("Fixture actual nodes missing")
		return
	var cases: Array[Dictionary] = []
	var captures: Dictionary = {}
	for spec in SHADOW_CASES:
		terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if spec["cast"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		light.shadow_bias = spec["bias"]
		light.shadow_normal_bias = spec["normal_bias"]
		var name: String = spec["id"]
		var image := await _capture(view,DIAG+name+".png")
		var repeated := await _capture(view,DIAG+name+"_repeat.png")
		if failed or image==null or repeated==null: return
		if image.get_data()!=repeated.get_data():
			_fail("Exact repeat failed: "+name)
			return
		captures[name] = image
		cases.append({"id":name,"actual_cast_mode":terrain.cast_shadow,"actual_shadow_bias":light.shadow_bias,"actual_shadow_normal_bias":light.shadow_normal_bias,"shadow_enabled":light.shadow_enabled,"directional_shadow_mode":light.directional_shadow_mode,"directional_shadow_max_distance":light.directional_shadow_max_distance,"directional_atlas_project_setting":ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size"),"viewport_positional_shadow_atlas":view.positional_shadow_atlas_size,"repeat_exact":true,"camera_projection":camera.projection,"camera_size":camera.size,"canvas":[view.size.x,view.size.y],"camera_position":[camera.position.x,camera.position.y,camera.position.z],"light_rotation_degrees":[light.rotation_degrees.x,light.rotation_degrees.y,light.rotation_degrees.z],"light_energy":light.light_energy})
	var original_vs_off := _differences(captures["self_on_original"],captures["self_off_control"],"original_minus_off")
	var larger_bias_vs_off := _differences(captures["self_on_normal_bias_1"],captures["self_off_control"],"normal_bias_1_minus_off")
	_diag_json("result.json",{"status":"SELF_SHADOW_CONTROLS_EXPORTED_REQUIRES_VISUAL_DIAGNOSIS","production_approved":false,"preview_source_sha256":FileAccess.get_sha256("res://scripts/dev/preview_world_map_v14_material_relief_sixth.gd"),"diagnostic_source_sha256":FileAccess.get_sha256(get_script().resource_path),"fifth_binding_sha256":BASE_EXECUTED_SHA,"geometry":geometry,"actual_plane_uv":_plane_uv_evidence(),"actual_cases":cases,"original_vs_off":original_vs_off,"larger_normal_bias_vs_off":larger_bias_vs_off,"texture_audit":texture_audit,"shader_compile_audit":compile_audit,"only_case_changes":"terrain.cast_shadow ON/OFF or normal_bias .08→1.0; shadow_bias .02 constant; all actual same mesh/source tex/normal/camera/light/sky","shore_geometry_unchanged":true,"sync":"8 frames and frame_post_draw for each capture"})
	view.queue_free()
	captures.clear()
	surface = null
	water = null
	sky = null
	topology = null
	material_textures.clear()
	for frame in 8: await process_frame
	print("[SixthSelfShadow] THREE_CONTROLS_EXPORTED "+DIAG)
	quit(0)
