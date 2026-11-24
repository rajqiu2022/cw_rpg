extends "res://scripts/dev/diagnose_native_shadow_v12.gd"

# Isolated transition matrix. Inherited helpers are read-only computation /
# fixture construction; never invoke inherited _case/_diagnose or v11 hooks.
const TRANSITION_PREFIX := "res://build/native_shadow_transition_v12_"
const TOPOLOGY := "res://build/world_native_pair_ortho_v9_topology.png"
const COLOR := "res://build/world_native_pair_ortho_v10_visual.png"
var _topology: Image
var _rock: Dictionary
var _matrix: Array[Dictionary]=[]


func _initialize() -> void:
	call_deferred("_transition")


func _transition_fixture(kind: String) -> Dictionary:
	var fixture := _fixture("local_surface","cube","shadows_only",2048)
	var world: Node3D=fixture["caster"].get_parent()
	var discarded: Node3D=fixture["caster"]
	world.remove_child(discarded)
	discarded.free()
	var caster: Node3D=_rock["node"].duplicate()
	world.add_child(caster)
	var meshes: Array[MeshInstance3D]=[]
	_meshes(caster,meshes)
	for mesh in meshes:
		mesh.layers=1
	fixture["caster"]=caster
	fixture["meshes"]=meshes
	var receiver: MeshInstance3D=fixture["receiver"]
	if kind=="actual_v11_mesh":
		receiver.mesh=_local_surface.call("_mesh",_topology,false)
	else:
		# Keep the model's real transform unchanged. Flat receiver passes through
		# the actual support anchor, not a translated origin-centered rock.
		receiver.position.y=_rock["ground_world"].y
	var topology_tex := ImageTexture.create_from_image(_topology)
	receiver.material_override=_local_surface.call("_surface_material",load(COLOR),topology_tex,false)
	return fixture


func _save_transition(name: String, kind: String, schedule: String, fixture: Dictionary, body: Image, on: Image, off: Image, on_repeat: Image, off_repeat: Image) -> void:
	var difference := _difference(on,off,body,"shadows_only")
	var captures := {"on":on,"off":off,"on_repeat":on_repeat,"off_repeat":off_repeat,"body":body,"difference":difference["full"],"ground_difference":difference["ground"]}
	for suffix: String in captures:
		assert(captures[suffix].save_png(TRANSITION_PREFIX+name+"_"+suffix+".png")==OK)
	var on_stable := FileAccess.get_sha256(TRANSITION_PREFIX+name+"_on.png")==FileAccess.get_sha256(TRANSITION_PREFIX+name+"_on_repeat.png")
	var off_stable := FileAccess.get_sha256(TRANSITION_PREFIX+name+"_off.png")==FileAccess.get_sha256(TRANSITION_PREFIX+name+"_off_repeat.png")
	var body_stats := _body_statistics(body)
	var valid: bool=body_stats["valid"] and on_stable and off_stable and on.get_size()==SIZE and off.get_size()==SIZE
	var camera: Camera3D=fixture["camera"]
	var light: DirectionalLight3D=fixture["light"]
	var node: Node3D=_rock["node"]
	var bounds: AABB=_rock["bounds"]
	var ground: Vector3=_rock["ground_world"]
	var projected := camera.unproject_position(ground)
	var source_foot: Vector2=_rock["spec"]["foot"]
	var predicted: Vector2=_local_surface.call("terrain_project",source_foot,_topology)
	var mesh: Mesh=fixture["receiver"].mesh
	var spec: Dictionary=_rock["spec"]
	var config := {"case":name,"receiver":kind,"schedule":schedule,"valid_case":valid,"capture_class":"INVALID_CAPTURE" if not valid else "VALID_NONEMPTY" if difference["statistics"]["outside_body_ground_pixels"]>0 else "VALID_EMPTY","statistics":difference["statistics"],"body_alpha":body_stats,"on_repeat_exact":on_stable,"off_repeat_exact":off_stable,"canvas":[SIZE.x,SIZE.y],"source_topology":TOPOLOGY,"topology_sha256":FileAccess.get_sha256(TOPOLOGY),"mesh_surface_count":mesh.get_surface_count(),"receiver_cast_shadow":false,"receiver_offset_y":fixture["receiver"].position.y,"material":"exact_v11_surface_material_with_actual_topology","model_id":spec["id"],"source":spec["source"],"source_sha256":FileAccess.get_sha256(spec["source"]),"source_foot":[source_foot.x,source_foot.y],"camera_unprojected_foot":[projected.x,projected.y],"analytic_projected_foot_at_half_resolution":[predicted.x*0.5,predicted.y*0.5],"projection_error_px":projected.distance_to(predicted*0.5),"actual_model_position":[node.position.x,node.position.y,node.position.z],"yaw":spec["yaw"],"scale":spec["scale"],"actual_vertex_count":_rock["actual_vertex_count"],"ground_world":[ground.x,ground.y,ground.z],"model_lowest_y":node.position.y+bounds.position.y,"lowest_y_minus_ground_y":node.position.y+bounds.position.y-ground.y,"support_method":"v11_actual_vertices_lowest6percent_frontZ_minY_synthetic_anchor","caster_layer":1,"camera_mask":camera.cull_mask,"light_mask":light.light_cull_mask,"camera_position":[0,12,12],"camera_size":camera.size,"light_rotation":[-55,-34,0],"energy":light.light_energy,"ambient":0.62,"cast":"same_layer_SHADOWS_ONLY_ON_vs_hidden_OFF","shadow_mode":light.directional_shadow_mode,"max_distance":light.directional_shadow_max_distance,"bias":light.shadow_bias,"normal_bias":light.shadow_normal_bias,"own_world_3d":fixture["viewport"].own_world_3d,"sync":"6_process_frames_then_frame_post_draw_per_state_and_repeat","render_method":RenderingServer.get_current_rendering_method(),"render_driver":RenderingServer.get_current_rendering_driver_name(),"directional_atlas":ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size"),"positional_atlas":fixture["viewport"].positional_shadow_atlas_size,"paths":{"on":TRANSITION_PREFIX+name+"_on.png","off":TRANSITION_PREFIX+name+"_off.png","body":TRANSITION_PREFIX+name+"_body.png","ground_difference":TRANSITION_PREFIX+name+"_ground_difference.png"},"no_v11_build_initialize_or_save_hooks":true}
	_json(TRANSITION_PREFIX+name+".json",config)
	_matrix.append(config)
	print("[NativeShadowTransitionV12] ",name," ground=",difference["statistics"]["outside_body_ground_pixels"]," valid=",valid," projection_error=",config["projection_error_px"])


func _sequence(kind: String) -> void:
	var fixture := _transition_fixture(kind)
	var body: Image=await _body_alpha(fixture)
	_set_cast(fixture,"shadows_only",true)
	await _settle()
	var on: Image=fixture["viewport"].get_texture().get_image()
	await _settle()
	var on_repeat: Image=fixture["viewport"].get_texture().get_image()
	_set_cast(fixture,"shadows_only",false)
	await _settle()
	var off: Image=fixture["viewport"].get_texture().get_image()
	await _settle()
	var off_repeat: Image=fixture["viewport"].get_texture().get_image()
	_save_transition(kind+"_sequential",kind,"one_viewport_sequential",fixture,body,on,off,on_repeat,off_repeat)
	fixture["viewport"].queue_free()
	await process_frame


func _concurrent(kind: String) -> void:
	var on_fixture := _transition_fixture(kind)
	var body: Image=await _body_alpha(on_fixture)
	var off_fixture := _transition_fixture(kind)
	_set_cast(on_fixture,"shadows_only",true)
	_set_cast(off_fixture,"shadows_only",false)
	await _settle()
	var on: Image=on_fixture["viewport"].get_texture().get_image()
	var off: Image=off_fixture["viewport"].get_texture().get_image()
	await _settle()
	var on_repeat: Image=on_fixture["viewport"].get_texture().get_image()
	var off_repeat: Image=off_fixture["viewport"].get_texture().get_image()
	_save_transition(kind+"_concurrent",kind,"two_independent_world_viewports_concurrent",on_fixture,body,on,off,on_repeat,off_repeat)
	on_fixture["viewport"].queue_free()
	off_fixture["viewport"].queue_free()
	await process_frame


func _transition() -> void:
	_topology=Image.load_from_file(TOPOLOGY)
	assert(_topology!=null)
	_local_surface=LOCAL_SURFACE.new()
	_local_surface.call("_prepare_models",_topology)
	var entries: Array=_local_surface.get("_models")
	assert(entries.size()==10)
	_rock=entries[0]
	assert(_rock["spec"]["old_id"]=="cc0_boulder_west")
	# No other prepared models are captured or exported. Free all at completion.
	for kind in ["plain_plane","actual_v11_mesh"]:
		await _sequence(kind)
		await _concurrent(kind)
	var invalid: Array[String]=[]
	var nonempty: Array[String]=[]
	for entry in _matrix:
		if not entry["valid_case"]:
			invalid.append(entry["case"])
		elif int(entry["statistics"]["outside_body_ground_pixels"])>0:
			nonempty.append(entry["case"])
	_json(TRANSITION_PREFIX+"matrix.json",{"status":"INVALID_CAPTURE" if not invalid.is_empty() else "ALL_TRANSITIONS_NONEMPTY" if nonempty.size()==4 else "PARTIAL_TRANSITION_FAILURE" if not nonempty.is_empty() else "ALL_TRANSITIONS_EMPTY","cases":_matrix,"invalid_cases":invalid,"ground_nonempty_cases":nonempty,"one_GPU_transition_matrix":true,"formal_or_old_output_writes":false,"full_map_outputs_generated":false})
	for entry in entries:
		entry["node"].free()
	_local_surface.free()
	await process_frame
	quit(0 if invalid.is_empty() and nonempty.size()==4 else 1)
