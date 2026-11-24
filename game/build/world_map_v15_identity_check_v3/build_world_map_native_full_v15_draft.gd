extends SceneTree

# Deliberately isolated first v15 review: four real compounds + one seam piece.
# Default execution refuses GPU. No sealed v14 source/assets are written.
const SOURCE := preload("res://scripts/dev/world_map_v15_source.gd")
const SURFACE := preload("res://scripts/dev/world_map_v15_surface.gd")
const PREVIEW := "res://build/world_map_v15_martial_identity_preview_v3/"
const CANVAS := Vector2i(1280,1024)
const SSAA := 2
const DOOR_PIXELS := {"huashan":Vector2(766,921),"wudang":Vector2(711,1031),"gufeng":Vector2(790,930),"lingyue":Vector2(617,1105),"mingwu":Vector2(688,991)}
var source: SOURCE
var surface: SURFACE
var height_texture: ImageTexture
var active_view: SubViewport
var records: Array[Dictionary]=[]
var error := ""
var sample_entities: Array[Dictionary]=[]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if "--v15-source-plan-only" in args:
		await _source_plan()
		return
	var identity_only: bool="--v15-identity-samples" in args
	if not "--v15-local-samples" in args and not identity_only:
		push_error("v15 default GPU/full export refused. Explicit producer-approved --v15-local-samples only; no production activation.")
		quit(2)
		return
	if DisplayServer.get_name()=="headless":
		push_error("Native visual samples require an actual GPU; headless is not a render.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW))
	source=SOURCE.new()
	source.prepare()
	surface=SURFACE.new()
	if not surface.load_sources():
		error=surface.error
		await _finish(false)
		return
	if not _write_json(PREVIEW+"status.json",{"status":"BUILD_IN_PROGRESS","production_approved":false,"executed_builder_path":get_script().resource_path,"executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path)}):
		await _finish(false)
		return
	var compound_ids: Array[String]=[]
	if identity_only: compound_ids.assign(["gufeng","lingyue","mingwu"])
	else: compound_ids.assign(["huashan","gufeng","lingyue"])
	for id: String in compound_ids:
		var landmark: Dictionary={}
		for site in SOURCE.LANDMARKS:
			if site["id"]==id: landmark=site
		if not await _compound_sample(landmark):
			await _finish(false)
			return
	if not identity_only:
		for sample in [{"id":"northern_snow_shoulder","center":Vector2(4500,600)}, {"id":"southern_bamboo_stand","center":Vector2(3650,6800)}, {"id":"southeastern_reed_wetland","center":Vector2(10750,6480)}, {"id":"northern_real_bridge_bank","center":Vector2(source.structures[1]["center"])}]:
			if not await _ground_sample(sample["id"],sample["center"],{}):
				await _finish(false)
				return
	if not _write_json(PREVIEW+"result.json",{"status":"LOCAL_SAMPLES_TECHNICAL_COMPLETE_REQUIRES_VISUAL_REVIEW","version":"world_v15","production_approved":false,"source_contract_plan":source.source_contract_plan(),"materials":surface.evidence,"cases":records,"generated_architecture_source":"project-original builtin-imagegen; already baked light, NOT native relighting or CC0","render_mode":"same-source native ground; unchanged original alpha compound in independent Sprite2D layer","no_full_export":true}):
		await _finish(false)
		return
	await _finish(true)

func _source_plan() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW))
	source=SOURCE.new()
	source.prepare()
	var bad: Array[Dictionary]=[]
	var centers := 0
	for route in source.routes:
		var points: PackedVector2Array=route["points"]
		for segment in range(points.size()-1):
			var count: int=maxi(1,ceili(points[segment].distance_to(points[segment+1])/4.))
			for n in range(count+1):
				var point: Vector2=points[segment].lerp(points[segment+1],float(n)/count)
				centers+=1
				for foot in SOURCE.foot_offsets():
					var q: Vector2=point+foot
					if not source.supported_walk(q):
						if bad.size()<256: bad.append({"route_id":route["id"],"source_center_px":[point.x,point.y],"source_shoe_px":[q.x,q.y],"selector":source.selector_cell_info(q)})
						break
	var structures: Array[Dictionary]=[]
	for entry in source.structures:
		var polygon: PackedVector2Array=entry["source_deck_polygon"]
		var corners: Array=[]
		for p in polygon: corners.append([p.x,p.y])
		var passage: Array=[]
		for p in entry["source_passage_px"]: passage.append([p.x,p.y])
		structures.append({"id":entry["id"],"route_id":entry["route_id"],"river_id":entry["river_id"],"source_deck_polygon":corners,"source_passage_px":passage,"deck_height_m":0.,"actual_wet_bed_m":source.triangle_height(entry["center"]),"visual_capture_status":"PENDING_NATIVE_BRIDGE_EXPORT"})
	var actual_source_path: String=source.get_script().resource_path
	var result: Dictionary={"status":"SOURCE_PLAN_ONLY_NOT_PRODUCTION_ASSETS","passed":bad.is_empty(),"route_count":source.routes.size(),"full17_centers":centers,"first_failures":bad,"structures":structures,"core_spacing":source.core_spacing(),"actual_cached_float32_vertices":source.vertex_cache.size(),"source_plan":source.source_contract_plan(),"limitations":["Door pixels for four compounds measured; 12 other landmark semantics still pending actual source review.","Bridge support authored real native geometry, not yet rendered/collision/rail audited.","This source-space full17 forecast does not substitute projected PNG+Field full17 proof."],"executed_source_path":actual_source_path,"executed_source_sha256":FileAccess.get_sha256(actual_source_path)}
	var plan_name: String="source_plan_retry1.json" if "--v15-source-plan-retry1" in OS.get_cmdline_user_args() else "source_plan.json"
	var wrote: bool=_write_json(PREVIEW+plan_name,result)
	print("V15_SOURCE_PLAN routes=",source.routes.size()," centers=",centers," bridge_count=",structures.size()," bad=",bad.size())
	if not wrote or not bad.is_empty(): error="Source-space road/full17 forecast failed; no GPU sample until legitimate route correction."
	await _finish(wrote and bad.is_empty())

func _compound_sample(landmark: Dictionary) -> bool:
	var path: String=landmark["source"]
	var image: Image=Image.load_from_file(path)
	if image==null or image.is_empty():
		error="Actual complete compound missing: "+path
		return false
	var id: String=landmark["id"]
	var pixel: Vector2=DOOR_PIXELS[id]
	var scale: float=float(landmark["width"])/image.get_width()
	var min_alpha := 1.
	for offset in SOURCE.foot_offsets():
		var q: Vector2=pixel+offset/scale
		min_alpha=minf(min_alpha,image.get_pixel(roundi(q.x),roundi(q.y)).a)
	if min_alpha <= .12:
		error="Measured stone-step 17-foot alpha support failed: "+id
		return false
	var actual: Dictionary={"id":id,"image":image,"path":path,"source_sha256":FileAccess.get_sha256(path),"doorstep_pixel":pixel,"doorstep_uv":pixel/Vector2(image.get_size()),"min_full17_source_alpha":min_alpha,"render_width":landmark["width"],"foot":landmark["foot"]}
	return await _ground_sample(id,Vector2(landmark["foot"])+Vector2(0,-220),actual)

func _ground_sample(id: String,center: Vector2,compound: Dictionary) -> bool:
	sample_entities.clear()
	var window:=Rect2(center-Vector2(CANVAS)*.5,Vector2(CANVAS))
	var mesh_rect:=window.grow(384.)
	var maps:=_material_maps(mesh_rect)
	var rf_origin:=Vector2i((mesh_rect.position/8.).floor())
	var rf_end:=Vector2i((mesh_rect.end/8.).ceil())+Vector2i.ONE
	var rf_size:=rf_end-rf_origin
	var rf_values:=PackedFloat32Array()
	rf_values.resize(rf_size.x*rf_size.y)
	for y in range(rf_size.y):
		for x in range(rf_size.x): rf_values[y*rf_size.x+x]=source.vertex_height(rf_origin+Vector2i(x,y))
	var height_image:=Image.create_from_data(rf_size.x,rf_size.y,false,Image.FORMAT_RF,rf_values.to_byte_array())
	height_texture=ImageTexture.create_from_image(height_image)
	active_view=SubViewport.new()
	active_view.size=CANVAS*SSAA
	active_view.msaa_3d=Viewport.MSAA_DISABLED
	active_view.own_world_3d=true
	active_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	var world:=Node3D.new()
	active_view.add_child(world)
	var environment:=WorldEnvironment.new()
	environment.environment=surface.environment()
	world.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	sun.shadow_enabled=true
	sun.shadow_normal_bias=1.
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance=60.
	world.add_child(sun)
	var terrain:=MeshInstance3D.new()
	terrain.mesh=_mesh(mesh_rect,false)
	terrain.material_override=surface.terrain_material(maps["ecology"],maps["roads"],mesh_rect)
	terrain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	world.add_child(terrain)
	var water:=MeshInstance3D.new()
	water.mesh=_mesh(mesh_rect,true)
	water.material_override=surface.water_material(height_texture,rf_origin,rf_size)
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(water)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(CANVAS.y)/SOURCE.PPM
	camera.near=.05
	camera.far=100.
	var target:=SOURCE.point3(center,0.)
	camera.position=target+Vector3(0,20,20)
	world.add_child(camera)
	camera.look_at(target)
	camera.current=true
	if not "--v15-identity-samples" in OS.get_cmdline_user_args():
		_add_bridge_geometry(world,mesh_rect)
		_add_reed_geometry(world,mesh_rect)
		_add_bamboo_objects(active_view,camera,mesh_rect)
	var overlay: Sprite2D
	if not compound.is_empty():
		var texture_image: Image=compound["image"].duplicate() as Image
		texture_image.generate_mipmaps()
		overlay=Sprite2D.new()
		overlay.texture=ImageTexture.create_from_image(texture_image)
		overlay.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var scale: float=float(compound["render_width"])/texture_image.get_width()
		overlay.scale=Vector2.ONE*scale*SSAA
		overlay.position=camera.unproject_position(SOURCE.point3(compound["foot"],source.triangle_height(compound["foot"])))+(Vector2(texture_image.get_size())*.5-compound["doorstep_pixel"])*scale*SSAA
		active_view.add_child(overlay)
	await _sync()
	if not _shader_gate(terrain.material_override,["biome_weights","road_weights","grass_ground_diff","rock_01_arm"]) or not _shader_gate(water.material_override,["actual_height_rf","grid_origin","grid_shape"]):
		error="Actual shader reflection rejected default/fallback material: "+id
		return false
	var raw: Image=active_view.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat: Image=active_view.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	var exact: bool=raw.get_data()==repeat.get_data()
	if raw.save_png(PREVIEW+id+"_raw.png")!=OK or repeat.save_png(PREVIEW+id+"_raw_repeat.png")!=OK or not exact:
		error="Actual raw GPU repeat/PNG save rejected: "+id
		return false
	var logical: Image=raw.duplicate() as Image
	logical.resize(CANVAS.x,CANVAS.y,Image.INTERPOLATE_LANCZOS)
	if logical.save_png(PREVIEW+id+"_scene.png")!=OK:
		error="Logical preview PNG save rejected: "+id
		return false
	var record: Dictionary={"id":id,"source_window_px":[window.position.x,window.position.y,window.size.x,window.size.y],"actual_canvas":[active_view.size.x,active_view.size.y],"logical_canvas":[CANVAS.x,CANVAS.y],"raw_path":PREVIEW+id+"_raw.png","raw_repeat_path":PREVIEW+id+"_raw_repeat.png","image_path":PREVIEW+id+"_scene.png","raw_repeat_byte_exact":exact,"msaa_3d_enum":active_view.msaa_3d,"source_grid_spacing_px":SOURCE.GRID_STEP,"actual_local_rf_sha256":_bytes_sha(rf_values.to_byte_array()),"actual_local_rf_origin_grid":[rf_origin.x,rf_origin.y],"actual_local_rf_size":[rf_size.x,rf_size.y],"rf_provenance":"same global lattice authored Float32 values; lazy bounded preview, full global height artifact NOT generated","actual_camera":{"position":[camera.position.x,camera.position.y,camera.position.z],"size":camera.size,"projection":camera.projection,"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"native_to_logical_factor":SSAA},"native_land_nav_exported":false,"independent_ecology_entities":sample_entities.duplicate(true)}
	if not compound.is_empty():
		var uv: Vector2=compound["doorstep_uv"]
		record["compound"]={"source":compound["path"],"source_sha256":compound["source_sha256"],"source_doorstep_uv":[uv.x,uv.y],"source_doorstep_pixel":[compound["doorstep_pixel"].x,compound["doorstep_pixel"].y],"minimum17_source_alpha":compound["min_full17_source_alpha"],"render_width":compound["render_width"],"alpha_resampling":"source original alpha untouched; opaque whole preview spatial Lanczos only","legacy_baked_light":true,"separate_runtime_entity":true}
	records.append(record)
	active_view.queue_free()
	active_view=null
	await _sync()
	return true

func _add_bamboo_objects(view: SubViewport,camera: Camera3D,rect: Rect2) -> void:
	# Each single-stock alpha has its own actual bottom, ground foot and Y.
	# Existing project-generated bamboo is not misattributed to a CC0 model.
	for stand_index in range(SOURCE.BAMBOO_STANDS.size()):
		var stand: Vector2=SOURCE.BAMBOO_STANDS[stand_index]
		for i in range(13):
			var foot: Vector2=stand+Vector2(sin(i*2.399)*sqrt(i+1)*38.,cos(i*2.399)*sqrt(i+1)*26.)
			if not rect.has_point(foot) or source.bank(foot)<40.: continue
			var path: String=SOURCE.BAMBOO_TEXTURES[i%2]
			var image: Image=Image.load_from_file(path)
			if image==null: continue
			var actual_rect: Rect2i=image.get_used_rect()
			var source_foot:=Vector2(actual_rect.position.x+actual_rect.size.x*.5,actual_rect.end.y-3)
			var scale: float=(94.+(i%3)*9.)/actual_rect.size.y
			image.generate_mipmaps()
			var sprite:=Sprite2D.new()
			sprite.texture=ImageTexture.create_from_image(image)
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.scale=Vector2.ONE*scale*SSAA
			sprite.position=camera.unproject_position(SOURCE.point3(foot,source.triangle_height(foot)))+(Vector2(image.get_size())*.5-source_foot)*scale*SSAA
			sprite.z_index=roundi(source.project_source(foot).y*.1)
			view.add_child(sprite)
			sample_entities.append({"id":"bamboo_%d_%d"%[stand_index,i],"nature":"project-original generated single bamboo alpha; measured alpha bottom, pending physical stem review","source":path,"source_sha256":FileAccess.get_sha256(path),"source_foot_px":[source_foot.x,source_foot.y],"source_XZ_foot_px":[foot.x,foot.y],"depth_foot_y":source.project_source(foot).y,"collision_size_px":[12,10],"independent_alpha_layer":true})

func _add_reed_geometry(world: Node3D,rect: Rect2) -> void:
	# Project-original native reeds: actual stems, narrow bent leaves and seed
	# heads. Neither a recoloured terrain patch nor a mislabeled shrub model.
	for i in range(36):
		var foot:=Vector2(10720.+cos(i*2.399)*sqrt(i+1)*28.,6470.+sin(i*2.399)*sqrt(i+1)*22.)
		if not rect.has_point(foot) or absf(source.bank(foot))>95.: continue
		var ground: float=source.triangle_height(foot)
		var root3: Vector3=SOURCE.point3(foot,ground)
		var node:=Node3D.new()
		world.add_child(node)
		node.position=root3
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(.27,.34,.12)
		material.roughness=.9
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		for stem in range(7):
			var height: float=.46+.1*((i+stem)%5)
			var base:=Vector3(sin(stem*2.4)*.045,0,cos(stem*2.4)*.045)
			var stalk:=MeshInstance3D.new()
			var cylinder:=CylinderMesh.new()
			cylinder.top_radius=.003
			cylinder.bottom_radius=.007
			cylinder.height=height
			cylinder.radial_segments=5
			stalk.mesh=cylinder
			stalk.material_override=material
			stalk.position=base+Vector3(0,height*.5,0)
			node.add_child(stalk)
			var leaves:=SurfaceTool.new()
			leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
			for side in [-1.,1.]:
				var a:=base+Vector3(0,height*.50,0)
				var b:=base+Vector3(side*.035,height*.62,.006)
				var c:=base+Vector3(side*.15,height*.73,.045)
				for p in [a,b,c]: leaves.add_vertex(p)
			leaves.generate_normals()
			var leaf:=MeshInstance3D.new()
			leaf.mesh=leaves.commit()
			leaf.material_override=material
			node.add_child(leaf)
			var head:=MeshInstance3D.new()
			var cap:=CapsuleMesh.new()
			cap.radius=.012
			cap.height=.075
			cap.radial_segments=5
			head.mesh=cap
			head.position=base+Vector3(0,height,0)
			var seed:=StandardMaterial3D.new()
			seed.albedo_color=Color(.33,.25,.10)
			head.material_override=seed
			node.add_child(head)
		sample_entities.append({"id":"native_reed_%d"%i,"nature":"project-original native narrow-leaf reed geometry; nonblocking shallow-water vegetation","source_XZ_foot_px":[foot.x,foot.y],"ground_m":ground,"depth_foot_y":source.project_source(foot).y,"blocking":false,"native_cast_shadow":true,"separate_runtime_export":"PENDING_ALPHA_CAPTURE; sample native instances independent"})

func _add_bridge_geometry(world: Node3D,rect: Rect2) -> void:
	for structure in source.structures:
		var center: Vector2=structure["center"]
		if not rect.grow(128).has_point(center): continue
		var node:=Node3D.new()
		world.add_child(node)
		node.position=SOURCE.point3(center,0.)
		var axis: Vector2=structure["axis"]
		var lateral:=Vector2(-axis.y,axis.x)
		var half_length_px: float=structure["half_length_px"]
		var half_width_px: float=structure["half_width_px"]
		var center3: Vector3=SOURCE.point3(center,0.)
		var timber:=StandardMaterial3D.new()
		timber.albedo_color=Color(.30,.22,.13)
		timber.roughness=.85
		var count: int=ceili(half_length_px*2./13.)
		for i in range(count):
			var plank:=MeshInstance3D.new()
			var start: float=-half_length_px+i*half_length_px*2./count+.2
			var end: float=-half_length_px+(i+1)*half_length_px*2./count-.2
			var vertices:=PackedVector3Array()
			for p in [center+axis*start-lateral*half_width_px,center+axis*end-lateral*half_width_px,center+axis*start+lateral*half_width_px,center+axis*end+lateral*half_width_px]:
				vertices.append(SOURCE.point3(p,0.)-center3)
			var arrays: Array=[]
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX]=vertices
			arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP])
			arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,1,3,2])
			var mesh:=ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			plank.mesh=mesh
			plank.material_override=timber
			node.add_child(plank)
		for side in [-1.,1.]:
			var posts: int=ceili(half_length_px*2./60.)
			for i in range(posts+1):
				var post:=MeshInstance3D.new()
				var mesh:=BoxMesh.new()
				mesh.size=Vector3(.045,.38,.045)
				post.mesh=mesh
				post.material_override=timber
				var foot: Vector2=center+axis*(-half_length_px+i*half_length_px*2./posts)+lateral*side*half_width_px
				post.position=SOURCE.point3(foot,.19)-center3
				node.add_child(post)
			var rail:=MeshInstance3D.new()
			var rail_mesh:=BoxMesh.new()
			var endpoint_a: Vector3=SOURCE.point3(center-axis*half_length_px+lateral*side*half_width_px,.33)-center3
			var endpoint_b: Vector3=SOURCE.point3(center+axis*half_length_px+lateral*side*half_width_px,.33)-center3
			var rail_delta: Vector3=endpoint_b-endpoint_a
			rail_mesh.size=Vector3(rail_delta.length(),.045,.045)
			rail.mesh=rail_mesh
			rail.material_override=timber
			rail.position=(endpoint_a+endpoint_b)*.5
			rail.rotation.y=atan2(-rail_delta.z,rail_delta.x)
			node.add_child(rail)
		sample_entities.append({"id":structure["id"],"nature":"project-original native timber planks Y0 plus independent physical rail parts; not navigation white paint","deck_height_m":0.,"source_XZ_center_px":[center.x,center.y],"negative_bed_m":source.triangle_height(center),"separate_runtime_exports":"PENDING_DECK_AND_EACH_RAIL_ALPHA_EXPORT"})

func _material_maps(rect: Rect2) -> Dictionary:
	var size:=Vector2i(ceili(rect.size.x/8.),ceili(rect.size.y/8.))
	var ecology:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	var roads:=Image.create(size.x,size.y,false,Image.FORMAT_RGB8)
	for y in range(size.y):
		for x in range(size.x):
			var p: Vector2=rect.position+Vector2(x+.5,y+.5)*8.
			var biome: Vector4=source.habitat(p)
			ecology.set_pixel(x,y,Color(biome.x,biome.y,biome.z,biome.w))
			var distance: Vector2=source.road_distance(p)
			var core: float=1.-smoothstep(distance.y*.45,distance.y*.95,distance.x)
			var verge: float=1.-smoothstep(distance.y*.7,distance.y+50.,distance.x)
			roads.set_pixel(x,y,Color(core,verge,0))
	return {"ecology":ImageTexture.create_from_image(ecology),"roads":ImageTexture.create_from_image(roads)}

func _mesh(rect: Rect2,water: bool) -> ArrayMesh:
	var start:=Vector2i((rect.position/SOURCE.GRID_STEP).floor())
	var end:=Vector2i((rect.end/SOURCE.GRID_STEP).ceil())
	var width: int=end.x-start.x+1
	var height: int=end.y-start.y+1
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var uv:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for y in range(height):
		for x in range(width):
			var p:=Vector2((start.x+x)*SOURCE.GRID_STEP,(start.y+y)*SOURCE.GRID_STEP)
			var h: float=SOURCE.WATER_Y if water else source.triangle_height(p)
			vertices.append(SOURCE.point3(p,h))
			var dx: float=(source.triangle_height(p+Vector2(8,0))-source.triangle_height(p-Vector2(8,0)))*SOURCE.PPM/16.
			var dz: float=(source.triangle_height(p+Vector2(0,8))-source.triangle_height(p-Vector2(0,8)))*SOURCE.Z_PPM/16.
			normals.append(Vector3.UP if water else Vector3(-dx,1,-dz).normalized())
			uv.append(p/Vector2(SOURCE.SIZE))
	for y in range(height-1):
		for x in range(width-1):
			var a: int=y*width+x
			indices.append_array(PackedInt32Array([a,a+1,a+width,a+1,a+width+1,a+width]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _sync() -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw

func _shader_gate(material: ShaderMaterial,required: Array[String]) -> bool:
	if material==null or material.shader==null: return false
	var found: Array[String]=[]
	for uniform in material.shader.get_shader_uniform_list(): found.append(String(uniform["name"]))
	for key in required:
		if not key in found: return false
	return true

func _finish(passed: bool) -> void:
	if not passed:
		push_error(error)
		_write_json(PREVIEW+"failed.json",{"status":"TECHNICAL_FAIL","reason":error,"production_approved":false})
	if active_view!=null:
		active_view.queue_free()
		active_view=null
	if surface!=null: surface.release()
	surface=null
	source=null
	height_texture=null
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var cursor:=root.get_node_or_null("CursorManager")
	if cursor!=null:
		for key in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for i in range(16): await process_frame
	quit(0 if passed else 1)

func _write_json(path: String,data: Dictionary) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		error="JSON open failed: "+path
		return false
	var text: String=JSON.stringify(data,"\t")
	file.store_string(text)
	file.flush()
	var code: int=file.get_error()
	file.close()
	if code!=OK or FileAccess.get_file_as_string(path)!=text or not JSON.parse_string(text) is Dictionary:
		error="JSON exact write/parse failed: "+path
		return false
	return true

func _bytes_sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _v3(value: Vector3) -> Array:
	return [value.x,value.y,value.z]
