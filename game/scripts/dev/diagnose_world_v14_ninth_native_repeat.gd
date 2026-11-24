extends "res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd"

# Isolated single-raw-mesh temporal readback fixture. No full contract, world
# preparation, production OUT, editor import, geometry or colour alterations.
const DIAG := "res://build/world_map_v14_ninth_repeat_fixture_v2/"
const FROZEN_BUILDER_SHA := "9540d5eb661d6b20386bf02d8f9182102219dd266856c9b144ad68711f7d1529"
const RF_SOURCE := "res://build/world_map_v14_ninth_native_preview_v4/actual_height_grid.rf"
const FAILED_CAPTURE := "res://build/world_map_v14_ninth_native_preview_v4/capture_failure_native_ridge_face_near.json"

func _initialize() -> void:
	source_design_only=true
	call_deferred("_repeat_fixture")

func _frame_readback(view: SubViewport,frames: int) -> Image:
	for frame in frames: await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _raw_pair_diff(a: Image,b: Image) -> Dictionary:
	var aa: PackedByteArray=a.get_data()
	var bb: PackedByteArray=b.get_data()
	var bytes: int=absi(aa.size()-bb.size())
	var delta: int=0
	for i in mini(aa.size(),bb.size()):
		if aa[i]!=bb[i]: bytes+=1
		delta=maxi(delta,absi(int(aa[i])-int(bb[i])))
	var pixels: int=0
	var alpha_pixels: int=0
	var rgb_pixels: int=0
	var rgb_only_pixels: int=0
	var examples: Array=[]
	for y in mini(a.get_height(),b.get_height()):
		for x in mini(a.get_width(),b.get_width()):
			if a.get_pixel(x,y)==b.get_pixel(x,y): continue
			pixels+=1
			var alpha_changed: bool=a.get_pixel(x,y).a!=b.get_pixel(x,y).a
			var rgb_changed: bool=Vector3(a.get_pixel(x,y).r,a.get_pixel(x,y).g,a.get_pixel(x,y).b)!=Vector3(b.get_pixel(x,y).r,b.get_pixel(x,y).g,b.get_pixel(x,y).b)
			if alpha_changed: alpha_pixels+=1
			if rgb_changed: rgb_pixels+=1
			if rgb_changed and not alpha_changed: rgb_only_pixels+=1
			if examples.size()<32:
				var ca: Color=a.get_pixel(x,y)
				var cb: Color=b.get_pixel(x,y)
				examples.append({"pixel":[x,y],"a":[ca.r,ca.g,ca.b,ca.a],"b":[cb.r,cb.g,cb.b,cb.a],"alpha_changed":alpha_changed,"rgb_changed":rgb_changed})
	return {"exact":aa==bb,"different_bytes":bytes,"different_pixels":pixels,"maximum_byte_delta":delta,"alpha_changed_pixels":alpha_pixels,"rgb_changed_pixels":rgb_pixels,"rgb_only_changed_pixels":rgb_only_pixels,"only_rgb_one_byte_delta":pixels>0 and alpha_pixels==0 and delta==1,"examples":examples}

func _repeat_fixture() -> void:
	DirAccess.make_dir_recursive_absolute(DIAG)
	var ignore: FileAccess=FileAccess.open(DIAG+".gdignore",FileAccess.WRITE)
	assert(ignore!=null)
	ignore.store_string("")
	ignore.close()
	assert(FileAccess.get_sha256("res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd")==FROZEN_BUILDER_SHA,"Frozen production source changed; diagnostic binding invalid")
	var historical: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FAILED_CAPTURE))
	assert(historical["id"]=="native_ridge_face_near")
	var rf: FileAccess=FileAccess.open(RF_SOURCE,FileAccess.READ)
	assert(rf!=null)
	height_grid=rf.get_buffer(rf.get_length()).to_float32_array()
	rf.close()
	assert(height_grid.size()==(HEIGHT_COLS+1)*(HEIGHT_ROWS+1))
	var source_foot:=Vector2(2070,785)
	var ground: Vector3=_point(source_foot)
	var document: GLTFDocument=GLTFDocument.new()
	var state: GLTFState=GLTFState.new()
	assert(document.append_from_file(ROCKFACE,state)==OK)
	var imported: Node3D=document.generate_scene(state) as Node3D
	assert(imported!=null)
	var raw_meshes: Array[MeshInstance3D]=[]
	_meshes(imported,raw_meshes)
	assert(raw_meshes.size()==1)
	var mesh: MeshInstance3D=raw_meshes[0].duplicate() as MeshInstance3D
	mesh.transform=Transform3D.IDENTITY
	for child in mesh.get_children(): child.free()
	var model:=Node3D.new()
	model.rotation_degrees.y=-24.
	model.scale=Vector3.ONE*.62
	var recipe: Array=_apply_native_material_derivative(mesh,ROCKFACE)
	model.add_child(mesh)
	var points:=PackedVector3Array()
	var bounds:=AABB()
	var first: bool=true
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array=mesh.mesh.surface_get_arrays(surface)
		var used: Dictionary={}
		for index in arrays[Mesh.ARRAY_INDEX]: used[index]=true
		for index in used:
			var point: Vector3=model.transform*arrays[Mesh.ARRAY_VERTEX][index]
			points.append(point)
			if first: bounds=AABB(point,Vector3.ZERO);first=false
			else: bounds=bounds.expand(point)
	var support:=AABB()
	first=true
	for point in points:
		if point.y>bounds.position.y+bounds.size.y*.06: continue
		if first: support=AABB(point,Vector3.ZERO);first=false
		else: support=support.expand(point)
	assert(not first)
	var contact:=Vector3(support.get_center().x,bounds.position.y,support.end.z)
	model.position=ground-contact
	imported.free()
	raw_meshes.clear()
	document=null
	state=null
	var extent: float=0.
	for corner in 8:
		var vertex: Vector3=bounds.get_endpoint(corner)-contact
		extent=maxf(extent,maxf(absf(vertex.x*102.4),absf((vertex.z-vertex.y)/sqrt(2.)*102.4)))
	var canvas: int=maxi(512,ceili((extent*2.+32.)/256.)*256)
	assert(canvas==768,"Fixture must reproduce exact failed capture canvas")
	var view:=SubViewport.new()
	view.size=Vector2i(canvas,canvas)
	view.own_world_3d=true
	view.transparent_bg=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	var environment:=WorldEnvironment.new()
	environment.environment=native_surface.environment(true)
	world.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=NINTH.DIRECT
	world.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(canvas)/102.4
	camera.position=ground+Vector3(0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET)
	world.add_child(camera)
	camera.look_at(ground)
	camera.current=true
	world.add_child(model)
	var cases: Array=[]
	var fixture_valid: bool=true
	var total_frames: int=0
	# Same viewport/world/material/light/camera. MSAA0 follows the original8
	# case as an explicitly already-warmed resolve control, not a cold-world test.
	for case_spec: Dictionary in [{"mode":Viewport.MSAA_4X,"name":"msaa4","factor":1},{"mode":Viewport.MSAA_2X,"name":"msaa2","factor":1},{"mode":Viewport.MSAA_DISABLED,"name":"ssaa2_native_no_msaa","factor":2}]:
		var mode: int=case_spec["mode"]
		var factor: int=case_spec["factor"]
		view.msaa_3d=mode
		view.size=Vector2i(canvas,canvas)*factor
		var name: String=case_spec["name"]
		var records: Array=[]
		var pairs: Array=[]
		var first_image: Image
		var previous: Image
		var previous_high: Image
		var case_frames: int=0
		for i in 6:
			var frames: int=[8,8,16,32,8,8][i]
			case_frames+=frames
			total_frames+=frames
			var image: Image=await _frame_readback(view,frames)
			var high_record: Dictionary={}
			if factor>1:
				var high_path: String=DIAG+name+"_frame_%d_high.png"%i
				assert(image.save_png(high_path)==OK)
				high_record={"path":high_path,"sha256":FileAccess.get_sha256(high_path),"size":[image.get_width(),image.get_height()],"native_msaa_disabled":true,"logical_projection_unchanged":true}
				if previous_high!=null: high_record["difference_from_previous"]=_raw_pair_diff(previous_high,image)
				previous_high=image.duplicate()
				image.resize(canvas,canvas,Image.INTERPOLATE_LANCZOS)
				high_record["derivation"]="Image.resize exact factor2 to logical canvas; INTERPOLATE_LANCZOS; no temporal blending or quantization"
			var path: String=DIAG+name+"_frame_%d_after_%d.png"%[i,case_frames]
			assert(image.save_png(path)==OK)
			var used: Rect2i=image.get_used_rect()
			var valid: bool=image.get_size()==Vector2i(canvas,canvas) and used.has_area() and image.get_pixel(0,0).a==0
			fixture_valid=fixture_valid and valid
			var record: Dictionary={"index":i,"additional_natural_frames":frames,"case_cumulative_frames":case_frames,"fixture_total_frames":total_frames,"path":path,"sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()],"used_rect":[used.position.x,used.position.y,used.size.x,used.size.y],"corner_alpha":image.get_pixel(0,0).a,"valid_body":valid}
			if factor>1: record["actual_high_readback"]=high_record
			if i==0: first_image=image
			else:
				record["difference_from_first"]=_raw_pair_diff(first_image,image)
				pairs.append({"from_index":i-1,"to_index":i,"raw_difference":_raw_pair_diff(previous,image)})
			records.append(record)
			previous=image
		cases.append({"id":name,"actual_msaa_enum":view.msaa_3d,"same_viewport":true,"capture_resolution_factor":factor,"prewarmed_control":true,"readbacks":records,"consecutive_pairs":pairs})
		first_image=null
		previous=null
		previous_high=null
	var basis: Basis=camera.transform.basis
	var result: Dictionary={"status":"DIAGNOSTIC_CAPTURE_COMPLETE" if fixture_valid else "INVALID_FIXTURE_CAPTURE","not_a_repeat_gate_override":true,"no_production_write":true,"frozen_builder_path":"res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd","frozen_builder_sha256":FROZEN_BUILDER_SHA,"fixture_path":get_script().resource_path,"fixture_sha256":FileAccess.get_sha256(get_script().resource_path),"frozen_failure_json":FAILED_CAPTURE,"frozen_failure_json_sha256":FileAccess.get_sha256(FAILED_CAPTURE),"rf_path":RF_SOURCE,"rf_sha256":FileAccess.get_sha256(RF_SOURCE),"rf_used_only_for_identical_ground_translation":true,"source":ROCKFACE,"source_sha256":FileAccess.get_sha256(ROCKFACE),"raw_gltf_import":true,"geometry_unchanged":true,"pose":{"yaw":-24.,"scale":.62,"source_foot":[2070,785],"ground":[ground.x,ground.y,ground.z],"contact":[contact.x,contact.y,contact.z],"model_position":[model.position.x,model.position.y,model.position.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]},"camera":{"projection":camera.projection,"size":camera.size,"position":[camera.position.x,camera.position.y,camera.position.z],"basis_columns":[[basis.x.x,basis.x.y,basis.x.z],[basis.y.x,basis.y.y,basis.y.z],[basis.z.x,basis.z.y,basis.z.z]],"canvas":[canvas,canvas],"pixels_per_meter":102.4},"light":{"rotation":[-55,-34,0],"energy":light.light_energy,"shadow_enabled":light.shadow_enabled},"environment":{"background_mode":environment.environment.background_mode,"background_alpha":environment.environment.background_color.a,"ambient_energy":environment.environment.ambient_light_energy,"reflection_source":environment.environment.reflected_light_source,"sky_process_mode":environment.environment.sky.process_mode,"sky_radiance_size":environment.environment.sky.radiance_size},"actual_native_material_derivative":recipe,"wait_semantics":"additional process_frame intervals8/8/16/32/8/8 produce case cumulative8/16/32/64/72/80; actual frame_post_draw before each raw readback","cases":cases,"fixture_valid":fixture_valid,"successful_run_means_diagnostic_written_not_repeat_PASS":true,"actual_renderer":RenderingServer.get_current_rendering_method()}
	_json(DIAG+"result.json",result)
	print("[NinthRepeatFixture] complete valid=",fixture_valid," logical_captures=18 high_captures=6; inspect exact raw pairs, no production gate changed")
	view.queue_free()
	recipe.clear()
	_release_capture_resource_refs()
	height_grid=PackedFloat32Array()
	for frame in 16: await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if fixture_valid else 1)

