extends SceneTree

# One isolated GPU matrix only. No scene-data, project setting, production
# outputs or v11 failure artifacts are written. A visible caster comparison
# keeps the body in both frames, masks its actual alpha, and NEVER labels body
# darkness as a ground cast shadow.
const SIZE := Vector2i(1536,512)
const PREFIX := "res://build/native_shadow_v12_"
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const LOCAL_SURFACE := preload("res://scripts/dev/build_world_map_native_pair_ortho_v11.gd")
var _local_surface: SceneTree
var _results: Array[Dictionary]=[]


func _initialize() -> void:
	if "--audit-only" in OS.get_cmdline_user_args():
		call_deferred("_audit_existing")
		return
	if "--ortho-controls" in OS.get_cmdline_user_args():
		call_deferred("_ortho_controls")
		return
	call_deferred("_diagnose")


func _json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	assert(file!=null)
	file.store_string(JSON.stringify(data,"\t"))
	file.close()


func _meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_meshes(child,result)


func _caster(subject: String) -> Node3D:
	var node := Node3D.new()
	if subject=="cube":
		var cube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size=Vector3(1.3,1.3,1.3)
		cube.mesh=box
		cube.position.y=0.65
		var material := StandardMaterial3D.new()
		material.albedo_color=Color(0.58,0.51,0.40)
		material.roughness=1.0
		cube.material_override=material
		node.add_child(cube)
	else:
		var packed := load(BOULDER) as PackedScene
		assert(packed!=null)
		var rock := packed.instantiate() as Node3D
		rock.position.y=0.0736429691314697
		rock.rotation_degrees.y=35.0
		node.add_child(rock)
	return node


func _receiver_material(kind: String) -> Material:
	if kind=="standard":
		var material := StandardMaterial3D.new()
		material.albedo_color=Color(0.36,0.41,0.30)
		material.roughness=1.0
		return material
	var source := Image.create(3072,1024,false,Image.FORMAT_RGBA8)
	source.fill(Color(1,0,0,1))
	var texture := ImageTexture.create_from_image(source)
	# Only call the exact existing material implementation. Never initialize,
	# call _build or run its frozen-path/output hook.
	return _local_surface.call("_surface_material",texture,texture,false)


func _fixture(receiver_kind: String, subject: String, mode: String, atlas: int) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size=SIZE
	viewport.own_world_3d=true
	var default_atlas := viewport.positional_shadow_atlas_size
	viewport.positional_shadow_atlas_size=atlas
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color(0.08,0.19,0.24)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color.WHITE
	settings.ambient_light_energy=0.62
	environment.environment=settings
	world.add_child(environment)
	var receiver := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size=Vector2(30.0,14.1421356)
	receiver.mesh=plane
	receiver.material_override=_receiver_material(receiver_kind)
	receiver.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(receiver)
	var caster := _caster(subject)
	world.add_child(caster)
	var caster_meshes: Array[MeshInstance3D]=[]
	_meshes(caster,caster_meshes)
	for mesh in caster_meshes:
		mesh.layers=2 if mode=="camera_excluded" else 1
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=1.15
	light.shadow_enabled=true
	light.shadow_bias=0.02
	light.shadow_normal_bias=0.08
	light.directional_shadow_max_distance=32.0
	light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=10.0
	camera.position=Vector3(0,12,12)
	camera.cull_mask=1
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	return {"viewport":viewport,"receiver":receiver,"caster":caster,"meshes":caster_meshes,"camera":camera,"light":light,"environment":environment,"default_positional_atlas":default_atlas}


func _settle() -> void:
	for frame in range(6):
		await process_frame
	# Both transforms/cast state and raster readback explicitly finish drawing.
	await RenderingServer.frame_post_draw


func _body_alpha(fixture: Dictionary) -> Image:
	var viewport: SubViewport=fixture["viewport"]
	var receiver: MeshInstance3D=fixture["receiver"]
	var camera: Camera3D=fixture["camera"]
	var meshes: Array[MeshInstance3D]=fixture["meshes"]
	var light: DirectionalLight3D=fixture["light"]
	var environment: Environment=fixture["environment"].environment
	var original_background := environment.background_color
	receiver.visible=false
	viewport.transparent_bg=true
	environment.background_color=Color(original_background.r,original_background.g,original_background.b,0)
	camera.cull_mask=3
	light.shadow_enabled=false
	for mesh in meshes:
		mesh.visible=true
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	await _settle()
	var body := viewport.get_texture().get_image()
	body.convert(Image.FORMAT_RGBA8)
	assert(_body_statistics(body)["valid"],"Invalid sourcebody alpha; refusing ground shadow evidence")
	receiver.visible=true
	viewport.transparent_bg=false
	environment.background_color=original_background
	camera.cull_mask=1
	light.shadow_enabled=true
	return body


func _body_statistics(body: Image) -> Dictionary:
	var opaque := 0
	var transparent := 0
	for y in body.get_height():
		for x in body.get_width():
			var alpha := body.get_pixel(x,y).a
			if alpha>0.01:
				opaque+=1
			if alpha==0.0:
				transparent+=1
	var used := body.get_used_rect()
	return {"valid":body.get_size()==SIZE and opaque>0 and transparent>0 and used.size.x<SIZE.x and used.size.y<SIZE.y,"entity_alpha_pixels":opaque,"zero_alpha_pixels":transparent,"used_rect":[used.position.x,used.position.y,used.size.x,used.size.y],"corner_alpha":body.get_pixel(0,0).a}


func _audit_existing() -> void:
	# Readback validation only: never starts a viewport or rewrites raw evidence.
	var success := _audit_matrix("matrix")
	if FileAccess.file_exists(PREFIX+"ortho_control_matrix.json"):
		success=_audit_matrix("ortho_control_matrix") and success
	quit(0 if success else 1)


func _audit_matrix(matrix_name: String) -> bool:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREFIX+matrix_name+".json"))
	assert(parsed is Dictionary)
	var cases: Array[Dictionary]=[]
	var invalid: Array[String]=[]
	var successes: Array[String]=[]
	var receivers := {"standard":false,"local_surface":false}
	for original: Dictionary in parsed["cases"]:
		var name: String=original["case"]
		var body := Image.load_from_file(original["paths"]["source_body"])
		assert(body!=null)
		var body_stats := _body_statistics(body)
		var dimensions_ok := true
		for suffix in ["on","off","on_repeat","off_repeat","difference","ground_difference"]:
			var capture := Image.load_from_file(PREFIX+name+"_"+suffix+".png")
			dimensions_ok=dimensions_ok and capture!=null and capture.get_size()==SIZE
		var repeat_on := FileAccess.get_sha256(PREFIX+name+"_on.png")==FileAccess.get_sha256(PREFIX+name+"_on_repeat.png")
		var repeat_off := FileAccess.get_sha256(PREFIX+name+"_off.png")==FileAccess.get_sha256(PREFIX+name+"_off_repeat.png")
		var valid: bool=body_stats["valid"] and dimensions_ok and repeat_on and repeat_off
		var ground := Image.load_from_file(original["paths"]["ground_difference"])
		var ground_used := ground.get_used_rect()
		# Preserve the initial geometric-expand extent as evidence of the 1px
		# bookkeeping error; PNG pixels are immutable. Extent now comes from alpha.
		if not original.has("initial_geometric_extent"):
			original["initial_geometric_extent"]=original["statistics"]["ground_used_rect"]
		original["statistics"]["ground_used_rect"]=[ground_used.position.x,ground_used.position.y,ground_used.size.x,ground_used.size.y]
		original["statistics_extent_source"]="stored_ground_PNG_get_used_rect_no_GPU"
		original["body_alpha_statistics"]=body_stats
		original["valid_case"]=valid
		original["capture_class"]="INVALID_CAPTURE" if not valid else "VALID_NONEMPTY" if int(original["statistics"]["outside_body_ground_pixels"])>0 else "VALID_EMPTY"
		_json(PREFIX+name+".json",original)
		var nonempty := int(original["statistics"]["outside_body_ground_pixels"])>0
		cases.append({"case":name,"valid_case":valid,"body_alpha":body_stats,"dimensions_ok":dimensions_ok,"on_repeat_exact":repeat_on,"off_repeat_exact":repeat_off,"capture_class":"INVALID_CAPTURE" if not valid else "VALID_NONEMPTY" if nonempty else "VALID_EMPTY","outside_body_ground_pixels":original["statistics"]["outside_body_ground_pixels"]})
		if not valid:
			invalid.append(name)
		elif nonempty:
			successes.append(name)
			receivers[original["receiver"]]=true
	var valid_capability: bool=invalid.is_empty() and (receivers["standard"] and receivers["local_surface"] if matrix_name=="matrix" else receivers["local_surface"])
	var status := "INVALID_CAPTURE" if not invalid.is_empty() else "ALL_CASES_EMPTY" if successes.is_empty() else "PARTIAL_RECEIVER_CAPABILITY" if not valid_capability else "GROUND_CAST_EVIDENCE_FOUND"
	parsed["stored_capture_audit_status"]=status
	parsed["statistics_extent_source"]="stored_ground_PNG_get_used_rect_no_GPU"
	_json(PREFIX+matrix_name+".json",parsed)
	_json(PREFIX+("capture_audit" if matrix_name=="matrix" else "ortho_control_capture_audit")+".json",{"status":status,"cases":cases,"invalid_cases":invalid,"valid_nonempty_cases":successes,"receiver_nonempty":receivers,"no_GPU_or_raw_output_overwrite":true,"alpha0_hardening_added_after_original_capture":matrix_name=="matrix"})
	print("[NativeShadowV12] read-only capture audit ",status," valid_nonempty=",successes.size()," invalid=",invalid.size())
	return valid_capability


func _set_cast(fixture: Dictionary, mode: String, enabled: bool) -> void:
	var meshes: Array[MeshInstance3D]=fixture["meshes"]
	for mesh in meshes:
		# Visible controls retain the source body and pose in both captures.
		mesh.visible=enabled or mode!="shadows_only"
		mesh.cast_shadow=(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if mode=="shadows_only" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON) if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _difference(on: Image, off: Image, body: Image, mode: String) -> Dictionary:
	on.convert(Image.FORMAT_RGBA8)
	off.convert(Image.FORMAT_RGBA8)
	var full := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	var ground := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	var dark_pixels := 0
	var ground_pixels := 0
	var body_pixels := 0
	var max_ground_alpha := 0.0
	var max_any_delta := 0.0
	var signed_changes := 0
	for y in SIZE.y:
		for x in SIZE.x:
			var before := off.get_pixel(x,y)
			var after := on.get_pixel(x,y)
			var before_luma := before.r*0.299+before.g*0.587+before.b*0.114
			var after_luma := after.r*0.299+after.g*0.587+after.b*0.114
			var delta := before_luma-after_luma
			max_any_delta=maxf(max_any_delta,absf(delta))
			if absf(delta)>0.004:
				signed_changes+=1
			var alpha := clampf(delta/maxf(before_luma,0.025),0,0.95)
			if alpha<0.015:
				continue
			full.set_pixel(x,y,Color(0,0,0,alpha))
			dark_pixels+=1
			# Sourcebody evidence comes from its independent transparent render,
			# conservatively dilated two pixels to exclude antialiasing fringes.
			var in_body := false
			for oy in range(-2,3):
				for ox in range(-2,3):
					if body.get_pixel(clampi(x+ox,0,SIZE.x-1),clampi(y+oy,0,SIZE.y-1)).a>0.01:
						in_body=true
			if in_body:
				body_pixels+=1
				continue
			ground.set_pixel(x,y,Color(0,0,0,alpha))
			ground_pixels+=1
			max_ground_alpha=maxf(max_ground_alpha,alpha)
	var ground_used := ground.get_used_rect()
	return {"full":full,"ground":ground,"statistics":{"dark_difference_pixels":dark_pixels,"outside_body_ground_pixels":ground_pixels,"inside_dilated_body_difference_pixels":body_pixels,"signed_change_pixels":signed_changes,"max_any_luma_delta":max_any_delta,"max_ground_alpha":max_ground_alpha,"ground_used_rect":[ground_used.position.x,ground_used.position.y,ground_used.size.x,ground_used.size.y],"ground_only_raw_case":mode!="visible","body_contamination_excluded_for_visible_case":mode=="visible","raw_difference_is_not_ground_proof_alone":true}}


func _case(receiver: String, subject: String, mode: String, atlas: int, suffix: String="", shadow_mode: int=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, max_distance: float=32.0) -> void:
	var name := receiver+"_"+subject+"_"+mode+"_atlas"+str(atlas)+suffix
	var fixture := _fixture(receiver,subject,mode,atlas)
	var case_light: DirectionalLight3D=fixture["light"]
	case_light.directional_shadow_mode=shadow_mode
	case_light.directional_shadow_max_distance=max_distance
	var body: Image=await _body_alpha(fixture)
	_set_cast(fixture,mode,true)
	await _settle()
	var viewport: SubViewport=fixture["viewport"]
	var on := viewport.get_texture().get_image()
	await _settle()
	var on_repeat := viewport.get_texture().get_image()
	_set_cast(fixture,mode,false)
	await _settle()
	var off := viewport.get_texture().get_image()
	await _settle()
	var off_repeat := viewport.get_texture().get_image()
	var result := _difference(on,off,body,mode)
	assert(on.save_png(PREFIX+name+"_on.png")==OK)
	assert(off.save_png(PREFIX+name+"_off.png")==OK)
	assert(on_repeat.save_png(PREFIX+name+"_on_repeat.png")==OK)
	assert(off_repeat.save_png(PREFIX+name+"_off_repeat.png")==OK)
	assert(body.save_png(PREFIX+name+"_body.png")==OK)
	assert(result["full"].save_png(PREFIX+name+"_difference.png")==OK)
	assert(result["ground"].save_png(PREFIX+name+"_ground_difference.png")==OK)
	var light: DirectionalLight3D=fixture["light"]
	var camera: Camera3D=fixture["camera"]
	var config := {"case":name,"receiver":receiver,"subject":subject,"source":BOULDER if subject=="boulder" else "native_BoxMesh_1.3m","source_sha256":FileAccess.get_sha256(BOULDER) if subject=="boulder" else "native_geometry","caster_mode":mode,"only_on_off_change":"cast_shadow_ON_vs_OFF_with_body_kept" if mode=="visible" else "SHADOWS_ONLY_vs_hidden" if mode=="shadows_only" else "layer2_active_ON_vs_OFF_camera_mask1","caster_layer":2 if mode=="camera_excluded" else 1,"camera_mask":camera.cull_mask,"light_cull_mask":light.light_cull_mask,"light_shadow_enabled":light.shadow_enabled,"camera_position":[0,12,12],"camera_ortho_size":camera.size,"canvas":[SIZE.x,SIZE.y],"light_rotation":[-55,-34,0],"light_energy":light.light_energy,"ambient_energy":0.62,"shadow_bias":light.shadow_bias,"shadow_normal_bias":light.shadow_normal_bias,"directional_shadow_max_distance":light.directional_shadow_max_distance,"directional_shadow_mode":light.directional_shadow_mode,"positional_shadow_atlas_size":viewport.positional_shadow_atlas_size,"directional_shadow_atlas_setting":ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size"),"render_method":RenderingServer.get_current_rendering_method(),"render_driver":RenderingServer.get_current_rendering_driver_name(),"own_world_3d":viewport.own_world_3d,"synchronized_readback":"6_process_frames_then_RenderingServer.frame_post_draw_per_state","receiver_self_cast":false,"body_mask":"actual_source_transparent_render_dilated_2px_for_ground_difference","paths":{"on":PREFIX+name+"_on.png","off":PREFIX+name+"_off.png","source_body":PREFIX+name+"_body.png","raw_difference":PREFIX+name+"_difference.png","ground_difference":PREFIX+name+"_ground_difference.png"},"statistics":result["statistics"]}
	config["positional_atlas_default_before_explicit_setting"]=fixture["default_positional_atlas"]
	config["positional_atlas_is_not_directional_atlas"]=true
	config["on_repeat_sha"]=FileAccess.get_sha256(PREFIX+name+"_on_repeat.png")
	config["off_repeat_sha"]=FileAccess.get_sha256(PREFIX+name+"_off_repeat.png")
	config["on_repeat_exact"]=config["on_repeat_sha"]==FileAccess.get_sha256(PREFIX+name+"_on.png")
	config["off_repeat_exact"]=config["off_repeat_sha"]==FileAccess.get_sha256(PREFIX+name+"_off.png")
	config["body_alpha_statistics"]=_body_statistics(body)
	config["valid_case"]=config["body_alpha_statistics"]["valid"] and config["on_repeat_exact"] and config["off_repeat_exact"] and on.get_size()==SIZE and off.get_size()==SIZE
	config["capture_class"]="INVALID_CAPTURE" if not config["valid_case"] else "VALID_NONEMPTY" if int(result["statistics"]["outside_body_ground_pixels"])>0 else "VALID_EMPTY"
	_json(PREFIX+name+".json",config)
	_results.append(config)
	print("[NativeShadowV12] ",name," ground=",result["statistics"]["outside_body_ground_pixels"]," body=",result["statistics"]["inside_dilated_body_difference_pixels"]," any_delta=",result["statistics"]["max_any_luma_delta"])
	viewport.queue_free()
	await process_frame


func _ortho_controls() -> void:
	# A separately approved two-case technical supplement. Retain all first
	# matrix evidence; only mode/maxdistance differ from its local boulder case.
	_local_surface=LOCAL_SURFACE.new()
	await _case("local_surface","boulder","shadows_only",2048,"_ortho_control_max40",DirectionalLight3D.SHADOW_ORTHOGONAL,40.0)
	await _case("local_surface","boulder","shadows_only",2048,"_ortho_control_max32",DirectionalLight3D.SHADOW_ORTHOGONAL,32.0)
	var invalid: Array[String]=[]
	var successes: Array[String]=[]
	for result in _results:
		if not result["valid_case"]:
			invalid.append(result["case"])
		elif int(result["statistics"]["outside_body_ground_pixels"])>0:
			successes.append(result["case"])
	_json(PREFIX+"ortho_control_matrix.json",{"version":"native-shadow-capability-v12-ortho-control","status":"INVALID_CAPTURE" if not invalid.is_empty() else "ORTHOGONAL_NONEMPTY_EVIDENCE" if not successes.is_empty() else "VALID_ORTHOGONAL_EMPTY","cases":_results,"invalid_cases":invalid,"ground_nonempty_cases":successes,"baseline":"local_surface_boulder_shadows_only_atlas2048: PARALLEL_2_SPLITS/max32","supplement_authorized_cases":2,"full_map_rendered":false})
	_local_surface.free()
	await process_frame
	quit(0 if invalid.is_empty() and not successes.is_empty() else 1)


func _diagnose() -> void:
	_local_surface=LOCAL_SURFACE.new()
	# First diagnostic includes normal same-layer visible baseline. Directional
	# and positional atlas settings are recorded separately, not conflated.
	for receiver in ["standard","local_surface"]:
		for subject in ["cube","boulder"]:
			for mode in ["visible","shadows_only","camera_excluded"]:
				await _case(receiver,subject,mode,2048)
	var successes: Array[String]=[]
	var invalid: Array[String]=[]
	var receiver_success := {"standard":false,"local_surface":false}
	for result in _results:
		if not result["valid_case"]:
			invalid.append(result["case"])
		elif int(result["statistics"]["outside_body_ground_pixels"])>0:
			successes.append(result["case"])
			receiver_success[result["receiver"]]=true
	var capability_valid: bool=invalid.is_empty() and receiver_success["standard"] and receiver_success["local_surface"]
	var status := "INVALID_CAPTURE" if not invalid.is_empty() else "ALL_CASES_EMPTY" if successes.is_empty() else "PARTIAL_RECEIVER_CAPABILITY" if not capability_valid else "GROUND_CAST_EVIDENCE_FOUND"
	_json(PREFIX+"matrix.json",{"version":"native-shadow-capability-v12","status":status,"cases":_results,"invalid_cases":invalid,"receiver_nonempty":receiver_success,"ground_nonempty_cases":successes,"raw_visible_body_differences_not_accepted_as_ground_shadow":true,"single_GPU_matrix_only":true,"formal_or_v11_writes":false})
	_local_surface.free()
	await process_frame
	print("[NativeShadowV12] one minimal matrix completed; nonempty ground cases=",successes.size(),"; no full map render/import/promote")
	quit(0 if capability_valid else 1)

