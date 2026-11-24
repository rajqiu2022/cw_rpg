extends SceneTree

# Independent VERSION15 full64/112-seam execution candidate. Explicit producer
# authorization is required for each scope; no sealed/formal assets are written.
const SOURCE := preload("res://scripts/dev/world_map_v15_complete_v5_source.gd")
const SURFACE := preload("res://scripts/dev/world_map_v15_complete_v5_surface.gd")
const PLANTS := preload("res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd")
const TREE_MESH := "res://art/maps/world_map_v14/entities/tree_small02_native_hybrid.res"
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const BOULDER_RAW_SHA := {
 "boulder_01_1k.gltf":"51487934db898b4c24072780a451e34eca5c02e3ada24a62bbc600bbc4019e92",
 "boulder_01.bin":"7f5b06503d62bd95bfe9c6b8a354a5cc8ff04a4d271a8cf87a3e3125db4232d7",
 "textures/boulder_01_diff_1k.jpg":"c38f0e918f6dc16b8d386ba3cdd89805c78320c119a1ceec85856f82b09a65b8",
 "textures/boulder_01_nor_gl_1k.jpg":"0810cf6e89d89bb6eb065b4d2e2855288f5dcbd2c15c6e40ab90d462021b50aa",
 "textures/boulder_01_arm_1k.jpg":"c57187c5746b6be913fa53846cb44ff78743e7ca5000f131c9627b99563c2b87"}
const PREVIEW := "res://art/maps/world_map_v15_complete_v5/prototypes/"
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
var native_mesh_cache: Dictionary={}
var native_prototype_cache: Dictionary={}
var native_texture_cache: Dictionary={}
var failure_output := "res://build/world_map_v15_complete_v5_full_draft_failure/"

func _initialize() -> void:
	call_deferred("_run")

func _run_samples_not_authorized() -> void:
	var args:=OS.get_cmdline_user_args()
	if "--complete-v5-source-plan" in args:
		await _source_plan()
		return
	var identity_only: bool="--complete-v5-identity-samples" in args
	if not "--complete-v5-macro-samples" in args and not identity_only:
		push_error("v15 default GPU/full export refused. Explicit producer-approved --complete-v5-macro-samples only; no production activation.")
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
	# The first macro window is regional ground + real independent vegetation.
	# New sect identities were reviewed separately; do not spend a whole run
	# repeating all compounds before testing the deficient macro environment.
	if not identity_only: compound_ids.clear()
	for id: String in compound_ids:
		var landmark: Dictionary={}
		for site in SOURCE.LANDMARKS:
			if site["id"]==id: landmark=site
		if not await _compound_sample(landmark):
			await _finish(false)
			return
	if not identity_only:
		for sample in [{"id":"north_rock_snow","center":Vector2(5560,700)}, {"id":"northwest_sand_road","center":Vector2(1450,1120)}, {"id":"central_forest_meadow","center":Vector2(2050,4300)}, {"id":"southeast_wet_bamboo","center":Vector2(10440,6350)}, {"id":"real_bridge_bank","center":Vector2(source.structures[1]["center"])}]:
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
	var center_spacing: Dictionary=source.actual_center_spacing()
	if not bool(center_spacing["passed"]): bad.append({"kind":"nine_actual_sprite_center_spacing","evidence":center_spacing})
	var result: Dictionary={"status":"SOURCE_PLAN_ONLY_NOT_PRODUCTION_ASSETS","passed":bad.is_empty(),"route_count":source.routes.size(),"full17_centers":centers,"first_failures":bad,"structures":structures,"core_spacing":source.core_spacing(),"actual_cached_float32_vertices":source.vertex_cache.size(),"source_plan":source.source_contract_plan(),"limitations":["Five generated sects and eleven legacy landmark doorstep UVs measured; source-direction review is not full Field/passage approval.","Bridge support authored real native geometry, not yet rendered/collision/rail audited.","This source-space full17 forecast does not substitute projected PNG+Field full17 proof."],"executed_source_path":actual_source_path,"executed_source_sha256":FileAccess.get_sha256(actual_source_path)}
	var plan_name: String="source_plan_retry1.json" if "--v15-source-plan-retry1" in OS.get_cmdline_user_args() else "source_plan.json"
	result["actual_core_center_spacing"]=center_spacing
	result["measured_centers"]=source.measured_centers
	result["independent_vegetation_sites"]=source.vegetation_sites.size()
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
	for site in source.vegetation_sites:
		if not window.grow(128).has_point(site["source_foot"]): continue
		if not await _ensure_native_prototype(site["kind"],site["pose"]): return false
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
	sun.shadow_normal_bias=2.
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
	var coverage: Dictionary=_receiver_coverage(camera,terrain.mesh as ArrayMesh,active_view.size)
	if not bool(coverage["passed"]):
		error="Actual same-camera receiver projection or shadow-depth coverage failed: "+id
		return false
	if not "--complete-v5-identity-samples" in OS.get_cmdline_user_args():
		_add_bridge_geometry(world,mesh_rect)
		_add_ecology_component_layers(active_view,world,camera,mesh_rect)
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
	record["actual_material_mode"]=surface.field_ecology_mode
	record["native_surface_authoring"]={"road":"project-authored compacted earth, nonperiodic .65/3.1m deposits; 8% coarsest registered brown_mud mean; cracked full-resolution mud is not road core","sand":"nonperiodic project-authored deposit material + unequal real RF dune lobes; NOT CC0 sand scan","rock":"real RF asymmetric ledges + original registered independent Boulder01 UV/geometry; not model atlas as terrain","forest":"occupied independent stem stands own root floor, nonperiodic medium-scale leaf/meadow ownership","water":"actual RF bed with locally shallower deposited bars, same native triangles own surface line"}
	record["actual_receiver_coverage"]=coverage
	record["source_graph"]={get_script().resource_path:FileAccess.get_sha256(get_script().resource_path),source.get_script().resource_path:FileAccess.get_sha256(source.get_script().resource_path),surface.get_script().resource_path:FileAccess.get_sha256(surface.get_script().resource_path),"res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd":FileAccess.get_sha256("res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd")}
	if not compound.is_empty():
		var uv: Vector2=compound["doorstep_uv"]
		record["compound"]={"source":compound["path"],"source_sha256":compound["source_sha256"],"source_doorstep_uv":[uv.x,uv.y],"source_doorstep_pixel":[compound["doorstep_pixel"].x,compound["doorstep_pixel"].y],"minimum17_source_alpha":compound["min_full17_source_alpha"],"render_width":compound["render_width"],"alpha_resampling":"source original alpha untouched; opaque whole preview spatial Lanczos only","legacy_baked_light":true,"separate_runtime_entity":true}
	records.append(record)
	active_view.queue_free()
	active_view=null
	await _sync()
	return true


func _add_bridge_geometry(world: Node3D,rect: Rect2) -> void:
	for structure in source.structures:
		var center: Vector2=structure["center"]
		if not rect.grow(128).has_point(center): continue
		var node:=Node3D.new()
		node.set_meta("structure_id",structure["id"])
		node.set_meta("source_foot",center)
		world.add_child(node)
		node.position=SOURCE.point3(center,0.)
		var axis: Vector2=structure["axis"]
		var lateral:=Vector2(-axis.y,axis.x)
		var half_length_px: float=structure["half_length_px"]
		var half_width_px: float=structure["half_width_px"]
		var center3: Vector3=SOURCE.point3(center,0.)
		var timber:=ShaderMaterial.new()
		var wood_shader:=Shader.new()
		wood_shader.code="""shader_type spatial;varying vec3 p;void vertex(){p=VERTEX;}
void fragment(){float grain=sin(p.x*91.+sin(p.z*9.)*.75)*.022+sin(p.x*277.+p.z*13.)*.007;
float knot=exp(-pow(p.x*.9,2.)-pow((p.z-.25)*8.,2.))*.035;
ALBEDO=vec3(.24,.165,.09)+grain-knot;ROUGHNESS=.86;SPECULAR=.14;}
"""
		timber.shader=wood_shader
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
			plank.set_meta("runtime_role","bridge_deck")
			node.add_child(plank)
		for side in [-1.,1.]:
			var posts: int=ceili(half_length_px*2./60.)
			for i in range(posts+1):
				var post:=MeshInstance3D.new()
				var mesh:=BoxMesh.new()
				mesh.size=Vector3(.065,.62,.065)
				post.mesh=mesh
				post.material_override=timber
				var foot: Vector2=center+axis*(-half_length_px+i*half_length_px*2./posts)+lateral*side*half_width_px
				post.position=SOURCE.point3(foot,.31)-center3
				post.set_meta("runtime_role","bridge_post")
				post.set_meta("source_foot",foot)
				node.add_child(post)
			var rail:=MeshInstance3D.new()
			var rail_mesh:=BoxMesh.new()
			var endpoint_a: Vector3=SOURCE.point3(center-axis*half_length_px+lateral*side*half_width_px,.33)-center3
			var endpoint_b: Vector3=SOURCE.point3(center+axis*half_length_px+lateral*side*half_width_px,.33)-center3
			var rail_delta: Vector3=endpoint_b-endpoint_a
			rail_mesh.size=Vector3(rail_delta.length(),.08,.07)
			rail.mesh=rail_mesh
			rail.material_override=timber
			rail.position=(endpoint_a+endpoint_b)*.5
			rail.rotation.y=atan2(-rail_delta.z,rail_delta.x)
			rail.set_meta("runtime_role","bridge_rail")
			rail.set_meta("source_foot",center+lateral*side*half_width_px)
			node.add_child(rail)
			# Continuous structural edge beam beneath real deck Y0. Its depth and
			# diagonal braces are native geometry, never a painted toy rail strip.
			var beam:=MeshInstance3D.new()
			var beam_mesh:=BoxMesh.new()
			beam_mesh.size=Vector3(rail_delta.length(),.20,.12)
			beam.mesh=beam_mesh
			beam.material_override=timber
			beam.position=(endpoint_a+endpoint_b)*.5-Vector3(0,.48,0)
			beam.rotation.y=rail.rotation.y
			beam.set_meta("runtime_role","bridge_underbeam")
			node.add_child(beam)
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
			roads.set_pixel(x,y,Color(core,verge,source.sand_weight(p)))
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
		if surface.textures.has(key) and material.get_shader_parameter(key)!=surface.textures[key]: return false
	return true

func _receiver_coverage(camera: Camera3D,mesh: ArrayMesh,raw_canvas: Vector2i) -> Dictionary:
	var minimum := Vector2(INF,INF)
	var maximum := Vector2(-INF,-INF)
	var depth_min := INF
	var depth_max := -INF
	var vertices: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var inverse: Transform3D=camera.global_transform.affine_inverse()
	for p in vertices:
		var projected: Vector2=camera.unproject_position(p)
		minimum=minimum.min(projected)
		maximum=maximum.max(projected)
		var depth: float=-(inverse*p).z
		depth_min=minf(depth_min,depth)
		depth_max=maxf(depth_max,depth)
	var covered: bool=minimum.x<=0. and minimum.y<=0. and maximum.x>=raw_canvas.x and maximum.y>=raw_canvas.y
	return {"passed":covered and depth_min>camera.near and depth_max<60.,"actual_vertex_count":vertices.size(),"raw_projection_bounds_px":[minimum.x,minimum.y,maximum.x,maximum.y],"logical_projection_bounds_px":[minimum.x/SSAA,minimum.y/SSAA,maximum.x/SSAA,maximum.y/SSAA],"actual_depth_min_m":depth_min,"actual_depth_max_m":depth_max,"directional_shadow_max_distance_m":60.,"all_receiver_vertices_within_shadow_depth":depth_min>camera.near and depth_max<60.,"method":"actual current ArrayMesh vertices transformed by actual Camera3D inverse; no inherited whole-camera proof"}

func _finish(passed: bool) -> void:
	_release_full_refs()
	if not passed:
		push_error(error)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(failure_output))
		_write_json(failure_output+"failed_"+str(Time.get_unix_time_from_system()).replace(".","_")+".json",{"status":"TECHNICAL_FAIL","reason":error,"production_approved":false,"executed_builder_path":get_script().resource_path,"executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path)})
	if active_view!=null:
		active_view.queue_free()
		active_view=null
	if surface!=null: surface.release()
	surface=null
	source=null
	height_texture=null
	native_mesh_cache.clear()
	native_prototype_cache.clear()
	native_texture_cache.clear()
	PLANTS.textures.clear()
	PLANTS.texture_evidence.clear()
	PLANTS.geometry_evidence.clear()
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

func _native_mesh(kind: String,pose: int) -> ArrayMesh:
	var key: String=kind+str(pose)
	if native_mesh_cache.has(key): return native_mesh_cache[key]
	var mesh: ArrayMesh
	if kind=="bamboo": mesh=PLANTS.bamboo()
	elif kind=="herb": mesh=PLANTS.low_grass(pose)
	elif kind=="boulder":
		for filename: String in BOULDER_RAW_SHA:
			if FileAccess.get_sha256(BOULDER.get_base_dir()+"/"+filename)!=BOULDER_RAW_SHA[filename]: return null
		var document:=GLTFDocument.new()
		var state:=GLTFState.new()
		if document.append_from_file(BOULDER,state)!=OK: return null
		var scene: Node=document.generate_scene(state)
		if scene==null: return null
		var nodes: Array[MeshInstance3D]=[]
		_collect_boulder_nodes(scene,nodes)
		if nodes.size()!=1:
			scene.free()
			return null
		mesh=nodes[0].mesh as ArrayMesh
		scene.free()
	else:
		var original: ArrayMesh=load(TREE_MESH) as ArrayMesh
		if original==null: return null
		mesh=ArrayMesh.new()
		for i in range(original.get_surface_count()):
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,original.surface_get_arrays(i))
			var old_material: StandardMaterial3D=original.surface_get_material(i) as StandardMaterial3D
			if old_material==null: return null
			var material: StandardMaterial3D=old_material.duplicate() as StandardMaterial3D
			for slot: String in ["albedo_texture","normal_texture","roughness_texture","ao_texture"]:
				var texture: Texture2D=material.get(slot)
				if texture==null: continue
				var texture_id: int=texture.get_instance_id()
				if not native_texture_cache.has(texture_id):
					var im: Image=texture.get_image().duplicate() as Image
					if im.is_compressed() and im.decompress()!=OK: return null
					if im.generate_mipmaps()!=OK: return null
					native_texture_cache[texture_id]=ImageTexture.create_from_image(im)
				material.set(slot,native_texture_cache[texture_id])
			material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if i==1:
				material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.alpha_scissor_threshold=.4
			mesh.surface_set_material(i,material)
	if mesh!=null: native_mesh_cache[key]=mesh
	return mesh

func _collect_boulder_nodes(node: Node,found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: found.append(node as MeshInstance3D)
	for child in node.get_children(): _collect_boulder_nodes(child,found)

func _ensure_native_prototype(kind: String,pose: int) -> bool:
	var key: String=kind+str(pose)
	if native_prototype_cache.has(key): return true
	var mesh: ArrayMesh=_native_mesh(kind,pose)
	if mesh==null:
		error="Registered actual native model unavailable: "+key
		return false
	var metric_scale: float=[.19,.20,.20][pose] if kind=="tree" else .0050 if kind=="bamboo" else [.85,1.05,.70][pose] if kind=="boulder" else .65
	var basis:=Basis(Vector3.UP,deg_to_rad(25.+pose*65.)).scaled(Vector3.ONE*metric_scale)
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	var points:=PackedVector3Array()
	for surface_id in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(surface_id)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var seen: Dictionary={}
		for index in indices:
			if seen.has(index): continue
			seen[index]=true
			var p: Vector3=basis*vertices[index]
			points.append(p)
			minimum=minimum.min(p)
			maximum=maximum.max(p)
	var sum_x:=0.
	var front: float=-INF
	var support_count:=0
	for p in points:
		if p.y<=minimum.y+(maximum.y-minimum.y)*.02:
			sum_x+=p.x
			front=maxf(front,p.z)
			support_count+=1
	if support_count==0:
		error="Actual model has no supported drawn bottom vertices: "+key
		return false
	var support:=Vector3(sum_x/support_count,minimum.y,front)
	var view:=SubViewport.new()
	view.size=Vector2i(1024,1024)
	view.own_world_3d=true
	view.transparent_bg=true
	view.msaa_3d=Viewport.MSAA_DISABLED
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=surface.environment()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,0)
	world.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	world.add_child(sun)
	var body:=MeshInstance3D.new()
	body.mesh=mesh
	body.transform=Transform3D(basis,-support)
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=5.
	camera.position=Vector3(0,20,20)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	await _sync()
	var raw: Image=view.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat: Image=view.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	var prefix: String=PREVIEW+"native_"+key
	var exact: bool=raw.get_data()==repeat.get_data()
	var saved: bool=raw.save_png(prefix+"_raw.png")==OK and repeat.save_png(prefix+"_repeat.png")==OK
	if not exact or not saved:
		error="Actual sourcebody repeat failed: "+key
		view.queue_free()
		await _sync()
		return false
	var logical: Image=_alpha_resize(raw,Vector2i(512,512))
	var used: Rect2i=logical.get_used_rect()
	if used.size==Vector2i.ZERO or used.position.x<8 or used.position.y<8 or used.end.x>504 or used.end.y>504:
		error="Actual sourcebody crop safety failed: "+key
		view.queue_free()
		await _sync()
		return false
	var crop:=Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8))
	var image: Image=logical.get_region(crop)
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)/SSAA-Vector2(crop.position)
	if image.save_png(prefix+".png")!=OK:
		error="Native prototype crop PNG save failed: "+key
		view.queue_free()
		await _sync()
		return false
	var record: Dictionary={"id":key,"texture":prefix+".png","sourcebody_raw":prefix+"_raw.png","sourcebody_repeat":prefix+"_repeat.png","sourcebody_exact":true,"logical_canvas":[512,512],"actual_canvas":[1024,1024],"crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"render_size_px":[image.get_width(),image.get_height()],"foot_uv":[foot.x/image.get_width(),foot.y/image.get_height()],"basis_columns":[_v3(basis.x),_v3(basis.y),_v3(basis.z)],"support_m":_v3(support),"used_vertex_bounds_m":[_v3(minimum),_v3(maximum)],"metric_scale":metric_scale,"geometry":"actual indices-referenced native vertices; no fake reed/bamboo substitute","alpha_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","sourcebody_and_caster_same_model_material_transform":true,"camera":{"projection":camera.projection,"size":camera.size,"position":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)]}}
	record["algorithm_identity"]="RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
	record["kind"]=kind
	record["pose"]=pose
	record["metadata_path"]=prefix+".json"
	record["alpha_unpremultiply_epsilon"]=.00001
	record["draw_mesh_source"]=TREE_MESH if kind=="tree" else PLANTS.BAMBOO_MESH if kind=="bamboo" else BOULDER if kind=="boulder" else PLANTS.HERB
	record["draw_mesh_source_sha256"]=FileAccess.get_sha256(record["draw_mesh_source"])
	var drawn_mesh_path: String=prefix+"_actual_draw_mesh.res"
	if ResourceSaver.save(mesh,drawn_mesh_path)!=OK:
		error="Actual native prototype draw mesh save failed: "+key
		view.queue_free()
		await _sync()
		return false
	record["actual_draw_mesh_path"]=drawn_mesh_path
	record["actual_draw_mesh_sha256"]=FileAccess.get_sha256(drawn_mesh_path)
	var surfaces: Array=[]
	for surface_index in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(surface_index)
		var attributes: Dictionary={}
		for slot: int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_INDEX]:
			if arrays[slot]!=null: attributes[str(slot)]=_bytes_sha(arrays[slot].to_byte_array())
		surfaces.append({"surface_index":surface_index,"native_surface_format":mesh.surface_get_format(surface_index),"draw_arrays_sha256":attributes})
	record["actual_surfaces"]=surfaces
	if kind=="boulder":
		record["registered_geometry_evidence"]={"source_gltf":BOULDER,"source_sha256":FileAccess.get_sha256(BOULDER),"source_import_method":"GLTFDocument raw scene; exact original used indices/vertices/UVs/normals; model atlas never sampled as terrain","license_evidence":"docs/licensed-world-assets-polyhaven-20260929.md; existing registered CC0 boulder_01","actual_surface_count":mesh.get_surface_count(),"verified_raw_dependencies_sha256":BOULDER_RAW_SHA}
	else:
		record["registered_geometry_evidence"]=PLANTS.geometry_evidence.duplicate(true) if kind!="tree" else {"recipe":"source leaves L0 plus native branch/trunk LOD2, actual registered hybrid draw arrays unchanged","source_gltf":"res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf","source_sha256":FileAccess.get_sha256("res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf")}
	if not _write_json(prefix+".json",record):
		view.queue_free()
		await _sync()
		return false
	native_prototype_cache[key]={"mesh":mesh,"basis":basis,"support":support,"image":image,"foot":foot,"record":record}
	view.queue_free()
	await _sync()
	return true

func _add_ecology_component_layers(view: SubViewport,world: Node3D,camera: Camera3D,rect: Rect2) -> void:
	for site in source.vegetation_sites:
		if not rect.grow(-256).has_point(site["source_foot"]): continue
		var key: String=String(site["kind"])+str(site["pose"])
		if not native_prototype_cache.has(key): continue
		var proto: Dictionary=native_prototype_cache[key]
		var foot: Vector2=site["source_foot"]
		var height: float=source.triangle_height(foot)
		var caster:=MeshInstance3D.new()
		caster.mesh=proto["mesh"]
		caster.transform=Transform3D(proto["basis"],SOURCE.point3(foot,height)-Vector3(proto["support"]))
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		world.add_child(caster)
		var sprite:=Sprite2D.new()
		sprite.texture=ImageTexture.create_from_image(proto["image"])
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale=Vector2.ONE*SSAA
		sprite.position=camera.unproject_position(SOURCE.point3(foot,height))+(Vector2(proto["image"].get_size())*.5-Vector2(proto["foot"]))*SSAA
		sprite.z_index=clampi(roundi(source.project_source(foot).y*.1),-4096,4096)
		view.add_child(sprite)
		var record: Dictionary=site.duplicate(true)
		record.erase("source_foot")
		record["source_XZ_foot_px"]=[foot.x,foot.y]
		record["world_foot_px"]=[source.project_source(foot).x,source.project_source(foot).y]
		record["depth_foot_y"]=source.project_source(foot).y
		record["sourcebody_evidence"]=proto["record"]
		record["collision_size_px"]=[site["collision_size_px"].x,site["collision_size_px"].y]
		if site["kind"]=="boulder":
			var bounds: Array=proto["record"]["used_vertex_bounds_m"]
			var minimum:=Vector3(bounds[0][0],bounds[0][1],bounds[0][2])
			var maximum:=Vector3(bounds[1][0],bounds[1][1],bounds[1][2])
			var support: Vector3=proto["support"]
			var physical_origin: Vector2=foot+Vector2((minimum.x-support.x)*SOURCE.PPM,(minimum.z-support.z)*SOURCE.Z_PPM)
			var physical_size:=Vector2((maximum.x-minimum.x)*SOURCE.PPM,(maximum.z-minimum.z)*SOURCE.Z_PPM)
			record["source_fullxz_rect_px"]=[physical_origin.x,physical_origin.y,physical_size.x,physical_size.y]
			record["collision_size_px"]=[physical_size.x,physical_size.y]
			record["source_collision_center_px"]=[physical_origin.x+physical_size.x*.5,physical_origin.y+physical_size.y*.5]
			record["world_collision_center_px"]=[physical_origin.x+physical_size.x*.5,physical_origin.y+physical_size.y*.5-height*SOURCE.Z_PPM]
			record["actual_minY_ground_delta_m"]=0.
		sample_entities.append(record)

func _alpha_resize(image: Image,size: Vector2i) -> Image:
	var result: Image=image.duplicate() as Image
	result.convert(Image.FORMAT_RGBAF)
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var c: Color=result.get_pixel(x,y)
			result.set_pixel(x,y,Color(c.r*c.a,c.g*c.a,c.b*c.a,c.a))
	result.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	for y in range(size.y):
		for x in range(size.x):
			var c: Color=result.get_pixel(x,y)
			result.set_pixel(x,y,Color(c.r/c.a,c.g/c.a,c.b/c.a,c.a) if c.a>.00001 else Color(0,0,0,0))
	result.convert(Image.FORMAT_RGBA8)
	return result



# Full execution draft only. Producer must approve this exact graph AFTER
# macro visual review. No current source/builder/helper is changed by this file.
const FULL_ROOT := "res://art/maps/world_map_v15_complete_v5/"
const FULL_APPROVAL := "res://data/maps/world_map_v15_full_capture_authorization.json"
const FULL_OVERSCAN := 96
var full_rf: ImageTexture
var full_topology: ImageTexture
var full_map_textures: Dictionary={}
var full_catalog: Dictionary={}
var full_chunks: Array[Dictionary]=[]
var full_seams: Array[Dictionary]=[]
var full_objects: Array[Dictionary]=[]
var full_geometry: Dictionary={}
var full_graph: Dictionary={}
var full_terrain_shader_code := ""
var full_shadow_pixels := 0
var full_portals: Array[Dictionary]=[]
var full_core_landmarks: Array[Dictionary]=[]
const FULL_FOOTPRINTS := "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if "--complete-v5-full-source-plan" in args:
		await _full_source_plan()
		return
	var seam_only: bool="--complete-v5-full-seam-preflight" in args
	if not "--complete-v5-full-capture" in args and not seam_only:
		error="Independent full draft refuses default execution; exact producer approval and explicit full/seam scope required."
		await _finish(false)
		return
	if DisplayServer.get_name()=="headless":
		error="Full native capture cannot be run on a headless renderer."
		await _finish(false)
		return
	if not _full_authorized(seam_only):
		await _finish(false)
		return
	source=SOURCE.new()
	source.prepare()
	# A measured foot UV alone does NOT authorize guessed walls/hotspots.
	if not _full_prepare_semantics():
		await _finish(false)
		return
	surface=SURFACE.new()
	if not surface.load_sources():
		error=surface.error
		await _finish(false)
		return
	for folder: String in ["chunks","seams","prototypes","entities","capture"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FULL_ROOT+folder))
	if not _write_json(FULL_ROOT+"manifest.json",{"version":"world_v15","status":"BUILD_IN_PROGRESS","production_approved":false,"visual_approved":false,"actual_executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path)}):
		await _finish(false)
		return
	if not _full_prepare_geometry():
		await _finish(false)
		return
	# Sourcebody resources are generated again from licensed native inputs. No
	# v14 alpha/ground/nav is copied into this generation.
	for site in source.vegetation_sites:
		if not await _ensure_native_prototype(site["kind"],site["pose"]):
			await _finish(false)
			return
	if not await _full_export_structures():
		await _finish(false)
		return
	# Actual binary/visual edge preflight is a separate small GPU scope. It
	# catches shadow-atlas or phase disagreements before an expensive full64.
	if seam_only:
		for edge in [_edge(0,0,true),_edge(2,3,false),_edge(5,5,true)]:
			for neighbor: String in [edge["from"],edge["to"]]:
				if not await _full_ensure_chunk(neighbor):
					await _finish(false)
					return
			var evidence: Dictionary=await _full_capture_edge(edge)
			if evidence.is_empty():
				await _finish(false)
				return
			full_seams.append(evidence)
		if not _write_json(FULL_ROOT+"capture/seam_preflight.json",{"status":"INDEPENDENT_SEAM_PREFLIGHT_NOT_FULL_EXPORT","source_graph":full_graph,"cases":full_seams,"production_approved":false}):
			await _finish(false)
			return
		await _finish(true)
		return
	for authored in SOURCE.chunks():
		var rect:=_rect_from_array(authored["logical_rect_px"])
		var captured: Dictionary=await _full_window(String(authored["id"]),rect,FULL_ROOT+"chunks/")
		if captured.is_empty():
			await _finish(false)
			return
		var record: Dictionary=authored.duplicate(true)
		captured.erase("images")
		record["capture"]=captured
		full_chunks.append(record)
	for row in range(8):
		for col in range(8):
			for vertical in [true,false]:
				if (vertical and col==7) or (not vertical and row==7): continue
				var evidence: Dictionary=await _full_capture_edge(_edge(row,col,vertical))
				if evidence.is_empty():
					await _finish(false)
					return
				full_seams.append(evidence)
	var body_bound: bool=await _full_export_native_instances()
	if not body_bound or full_chunks.size()!=64 or full_seams.size()!=112:
		error="Full64 matrix/independent112/native entity binding incomplete."
		await _finish(false)
		return
	if not _full_export_compounds() or not _full_assemble_contract():
		await _finish(false)
		return
	await _finish(true)

func _full_prepare_semantics() -> bool:
	var approved: Variant=JSON.parse_string(FileAccess.get_file_as_string(FULL_APPROVAL))
	var authored: Variant=JSON.parse_string(FileAccess.get_file_as_string(FULL_FOOTPRINTS))
	if not approved is Dictionary or not authored is Dictionary or approved.get("source_footprints_sha256","").to_lower()!=FileAccess.get_sha256(FULL_FOOTPRINTS).to_lower():
		error="Exact producer SOURCE_AUTHORING footprint approval missing; no guessed portal solids."
		return false
	source.semantics.clear()
	for landmark in SOURCE.LANDMARKS:
		var id: String=landmark["id"]
		var record: Dictionary=authored.get("landmarks",{}).get(id,{})
		if record.get("status","")!="SOURCE_FOOTPRINT_AUTHORED_REQUIRES_ROOT_REVIEW" or record.get("source","")!=landmark["source"] or record.get("source_sha256","").to_lower()!=FileAccess.get_sha256(landmark["source"]).to_lower():
			error="Missing or changed actually measured footprint "+id
			return false
		if record.get("solid_polygons_source_px",[]).is_empty() or record.get("passage_path_source_px",[]).size()<2:
			error="Incomplete real wall/passage source "+id
			return false
		var actual: Dictionary=record.duplicate(true)
		actual["status"]="MEASURED_ACTUAL_SOURCE"
		actual["visual_review_status"]="PENDING_CURRENT_COMPOSITE_AND_FIELD"
		actual["root_source_authoring_approval_sha256"]=FileAccess.get_sha256(FULL_FOOTPRINTS)
		source.semantics[id]=actual
	return true

func _full_authorized(seam_only: bool) -> bool:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FULL_APPROVAL))
	if not parsed is Dictionary:
		error="Missing exact producer full-capture authorization."
		return false
	var required: String="SEAM_PREFLIGHT_ONLY" if seam_only else "FULL64_AFTER_MACRO_VISUAL_APPROVAL"
	if parsed.get("scope","")!=required or parsed.get("approved_by","")!="root":
		error="Wrong authorized capture scope."
		return false
	for script_path: String in [get_script().resource_path,"res://scripts/dev/world_map_v15_complete_v5_source.gd","res://scripts/dev/world_map_v15_complete_v5_surface.gd","res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd"]:
		if parsed.get("source_graph",{}).get(script_path,"")!=FileAccess.get_sha256(script_path):
			error="Changed or unapproved executed source: "+script_path
			return false
	return true

func _full_prepare_geometry() -> bool:
	source.generate_height_grid()
	var path: String=FULL_ROOT+"terrain_height.rf"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		error="Cannot open actual global RF."
		return false
	file.store_buffer(source.heights.to_byte_array())
	var io: Error=file.get_error()
	file.close()
	if io!=OK or FileAccess.get_file_as_bytes(path)!=source.heights.to_byte_array():
		error="Global RF bytes/readback mismatch."
		return false
	var mesh: ArrayMesh=_mesh(Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)),false)
	var mesh_path: String=FULL_ROOT+"terrain_mesh.res"
	if ResourceSaver.save(mesh,mesh_path)!=OK:
		error="Cannot save actual global native mesh."
		return false
	var image:=Image.create_from_data(SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y,false,Image.FORMAT_RF,source.heights.to_byte_array())
	full_rf=ImageTexture.create_from_image(image)
	var shape: Vector2i=SOURCE.SIZE/SOURCE.SELECTOR_STEP
	var topology:=Image.create(shape.x,shape.y,false,Image.FORMAT_RGB8)
	for y in range(shape.y):
		for x in range(shape.x):
			var cell: Dictionary=source.selector_cell_info(Vector2(x,y)*SOURCE.SELECTOR_STEP)
			topology.set_pixel(x,y,Color(1. if cell["land"] else 0.,0.,1. if cell["walk"] else 0.))
	if topology.save_png(FULL_ROOT+"source_topology.png")!=OK:
		error="Cannot save conservative whole-selector source."
		return false
	full_topology=ImageTexture.create_from_image(topology)
	full_map_textures=_material_maps(Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	var actual_material: ShaderMaterial=surface.terrain_material(full_map_textures["ecology"],full_map_textures["roads"],Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	var shader_path: String=FULL_ROOT+"capture/terrain_shader.gdshader"
	if actual_material==null or actual_material.shader==null or ResourceSaver.save(actual_material.shader,shader_path)!=OK:
		error="Cannot save actual full terrain shader resource."
		return false
	full_catalog[shader_path]=FileAccess.get_sha256(shader_path)
	full_graph[shader_path]=full_catalog[shader_path]
	full_terrain_shader_code=actual_material.shader.code
	full_geometry={"height_grid_shape":[SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y],"height_grid_origin_px":[0,0],"source_node_spacing_px":SOURCE.GRID_STEP,"height_interpolation":"actual stored Float32 [a,b,c,b,d,c] triangles","selector_cell_rule":"entire 2px selector-cell intersects both native triangles independently; strict bank28 and gradient .72","rf_path":path,"rf_sha256":FileAccess.get_sha256(path),"terrain_mesh_path":mesh_path,"terrain_mesh_sha256":FileAccess.get_sha256(mesh_path),"source_topology_path":FULL_ROOT+"source_topology.png","native_binary_msaa_enum":0,"native_binary_resized":false}
	for script_path: String in [get_script().resource_path,source.get_script().resource_path,surface.get_script().resource_path,"res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd"]:
		full_graph[script_path]=FileAccess.get_sha256(script_path)
	full_graph[path]=FileAccess.get_sha256(path)
	full_graph[mesh_path]=FileAccess.get_sha256(mesh_path)
	for item in surface.evidence:
		full_graph[item["path"]]=item["sha256"]
		full_graph[item["source_path"]]=item["source_sha256"]
	for asset_path: String in full_graph: full_catalog[asset_path]=full_graph[asset_path]
	if not _full_register_literal_inputs(get_script().resource_path,{}): return false
	if not _write_json(FULL_ROOT+"geometry.json",full_geometry): return false
	full_catalog[FULL_ROOT+"geometry.json"]=FileAccess.get_sha256(FULL_ROOT+"geometry.json")
	full_catalog[FULL_ROOT+"source_topology.png"]=FileAccess.get_sha256(FULL_ROOT+"source_topology.png")
	return true

func _rect_from_array(raw: Array) -> Rect2:
	return Rect2(raw[0],raw[1],raw[2],raw[3])

func _full_authority(mode: int) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode unshaded,cull_disabled;
uniform sampler2D selector:filter_nearest,repeat_disable;uniform int mode;
varying vec3 xyz;void vertex(){xyz=VERTEX;}
void fragment(){vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
if(p.x<0.||p.y<0.||p.x>=12288.||p.y>=8192.)discard;
float dry=xyz.y>-.025?1.:0.;float walk=texture(selector,p/vec2(12288.,8192.)).b>.5?1.:0.;
ALBEDO=vec3(mode==0?dry:dry*walk);}"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("selector",full_topology)
	material.set_shader_parameter("mode",mode)
	return material

func _full_support_mesh() -> ArrayMesh:
	var vertices:=PackedVector3Array()
	var indices:=PackedInt32Array()
	var normals:=PackedVector3Array()
	for structure in source.structures:
		var polygon: PackedVector2Array=structure["source_deck_polygon"]
		var triangulated: PackedInt32Array=Geometry2D.triangulate_polygon(polygon)
		var start: int=vertices.size()
		for p in polygon:
			vertices.append(SOURCE.point3(p,0.))
			normals.append(Vector3.UP)
		for index in triangulated: indices.append(start+index)
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var result:=ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _full_read_exact(prefix: String,logical: Vector2i,factor: int,crop: Rect2i) -> Dictionary:
	await _sync()
	var raw: Image=active_view.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat: Image=active_view.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	if raw.get_size()!=logical*factor or raw.get_data()!=repeat.get_data():
		error="Actual raw byte-repeat/canvas failure: "+prefix
		return {}
	if raw.save_png(prefix+"_raw.png")!=OK or repeat.save_png(prefix+"_raw_repeat.png")!=OK:
		error="Actual raw save failure: "+prefix
		return {}
	var derived: Image=raw.duplicate() as Image
	var derived_repeat: Image=repeat.duplicate() as Image
	if factor>1:
		derived.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
		derived_repeat.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	if derived.get_data()!=derived_repeat.get_data():
		error="Derived byte-repeat failure."
		return {}
	derived=derived.get_region(crop)
	derived_repeat=derived_repeat.get_region(crop)
	if derived.get_data()!=derived_repeat.get_data() or derived.save_png(prefix+".png")!=OK or derived_repeat.save_png(prefix+"_repeat.png")!=OK:
		error="Logical native image save failure."
		return {}
	for output_path: String in [prefix+"_raw.png",prefix+"_raw_repeat.png",prefix+".png",prefix+"_repeat.png"]:
		full_catalog[output_path]=FileAccess.get_sha256(output_path)
	return {"logical_image":derived,"raw_path":prefix+"_raw.png","raw_repeat_path":prefix+"_raw_repeat.png","path":prefix+".png","repeat_path":prefix+"_repeat.png","raw_repeat_exact":true,"derived_repeat_exact":true,"raw_canvas":[raw.get_width(),raw.get_height()],"logical_overscan":[logical.x,logical.y],"crop":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"resize_method":"opaque Lanczos SSAA2" if factor>1 else "NONE_NATIVE_MSAA0","factor":factor}

func _full_window(id: String,rect: Rect2,directory: String) -> Dictionary:
	var logical:=Vector2i(rect.size)+Vector2i(FULL_OVERSCAN*2,FULL_OVERSCAN*2)
	var geometry_rect: Rect2=rect.grow(1024.)
	active_view=SubViewport.new()
	active_view.size=logical*SSAA
	active_view.msaa_3d=Viewport.MSAA_DISABLED
	active_view.own_world_3d=true
	active_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	var world:=Node3D.new()
	active_view.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=surface.environment()
	world.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	sun.shadow_enabled=true
	sun.shadow_normal_bias=2.
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance=60.
	world.add_child(sun)
	var terrain:=MeshInstance3D.new()
	terrain.mesh=_mesh(geometry_rect,false)
	var actual_mesh_path: String=directory+id+"_actual_terrain_mesh.res"
	if ResourceSaver.save(terrain.mesh,actual_mesh_path)!=OK:
		error="Cannot save actual capture-window mesh "+id
		return {}
	full_catalog[actual_mesh_path]=FileAccess.get_sha256(actual_mesh_path)
	var visual_material: ShaderMaterial=surface.terrain_material(full_map_textures["ecology"],full_map_textures["roads"],Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	if visual_material==null or visual_material.shader==null or visual_material.shader.code!=full_terrain_shader_code:
		error="Actual capture shader differs from saved terrain shader."
		return {}
	terrain.material_override=visual_material
	world.add_child(terrain)
	var water:=MeshInstance3D.new()
	water.mesh=_mesh(geometry_rect,true)
	water.material_override=surface.water_material(full_rf,Vector2i.ZERO,SOURCE.GRID_SIZE)
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(water)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(logical.y)/SOURCE.PPM
	camera.near=.05
	camera.far=100.
	var target: Vector3=SOURCE.point3(rect.get_center(),0.)
	camera.position=target+Vector3(0,20,20)
	world.add_child(camera)
	camera.look_at(target)
	camera.current=true
	var coverage: Dictionary=_receiver_coverage(camera,terrain.mesh as ArrayMesh,active_view.size)
	if not bool(coverage["passed"]):
		error="Actual receiver coverage/depth rejected "+id
		return {}
	var casters: Array[MeshInstance3D]=[]
	var bridges:=Node3D.new()
	world.add_child(bridges)
	_add_bridge_geometry(bridges,geometry_rect)
	_full_set_shadow_only(bridges,casters)
	for site in source.vegetation_sites:
		# Conservative geometry/cast envelope; no independent visible body in
		# ground. The same native mesh/pose later becomes the independent sprite.
		if not geometry_rect.has_point(site["source_foot"]): continue
		var key: String=String(site["kind"])+str(site["pose"])
		var proto: Dictionary=native_prototype_cache[key]
		var caster:=MeshInstance3D.new()
		caster.mesh=proto["mesh"]
		var foot: Vector2=site["source_foot"]
		caster.transform=Transform3D(proto["basis"],SOURCE.point3(foot,source.triangle_height(foot))-Vector3(proto["support"]))
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		world.add_child(caster)
		casters.append(caster)
	await _sync()
	if not _shader_gate(visual_material,["biome_weights","road_weights","grass_ground_diff","rock_01_arm"]) or not _shader_gate(water.material_override,["actual_height_rf","grid_origin","grid_shape"]):
		error="Actual full shader binding/default material rejected."
		return {}
	var crop:=Rect2i(Vector2i(FULL_OVERSCAN,FULL_OVERSCAN),Vector2i(rect.size))
	var on: Dictionary=await _full_read_exact(directory+id+"_visual",logical,SSAA,crop)
	if on.is_empty(): return {}
	# Runtime visual and explicit shadow_ON authority are the same actual
	# capture. Preserve original PNG bytes as aliases, never re-render/average.
	for suffix: String in [".png","_repeat.png","_raw.png","_raw_repeat.png"]:
		if not _full_copy_exact(directory+id+"_visual"+suffix,directory+id+"_shadow_on"+suffix): return {}
	for caster in casters: caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var off: Dictionary=await _full_read_exact(directory+id+"_shadow_off",logical,SSAA,crop)
	if off.is_empty(): return {}
	var ground_evidence: Dictionary=_full_ground_evidence(id,rect,on["logical_image"],off["logical_image"],directory)
	if ground_evidence.is_empty(): return {}
	# Authority shares the same exact camera/geometry but original logical
	# canvas MSAA0, with NO Lanczos or body/caster/light.
	active_view.size=logical
	water.visible=false
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,1)
	terrain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain.material_override=_full_authority(0)
	var land: Dictionary=await _full_read_exact(directory+id+"_land",logical,1,crop)
	if land.is_empty(): return {}
	terrain.material_override=_full_authority(1)
	var raw_walk: Dictionary=await _full_read_exact(directory+id+"_raw_walk",logical,1,crop)
	if raw_walk.is_empty(): return {}
	var support:=MeshInstance3D.new()
	support.mesh=_full_support_mesh()
	var white:=StandardMaterial3D.new()
	white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	white.cull_mode=BaseMaterial3D.CULL_DISABLED
	white.albedo_color=Color.WHITE
	support.material_override=white
	world.add_child(support)
	var support_path: String=directory+id+"_actual_deck_support_mesh.res"
	if ResourceSaver.save(support.mesh,support_path)!=OK:
		error="Cannot save actual separate Y0 support mesh "+id
		return {}
	full_catalog[support_path]=FileAccess.get_sha256(support_path)
	var walk: Dictionary=await _full_read_exact(directory+id+"_walk",logical,1,crop)
	if walk.is_empty(): return {}
	var images: Dictionary={"visual":on["logical_image"],"land":land["logical_image"],"raw_walk":raw_walk["logical_image"],"walk":walk["logical_image"]}
	var outputs: Dictionary={}
	for role: String in ["visual","shadow_on","shadow_off","land","raw_walk","walk"]:
		for suffix: String in [".png","_repeat.png","_raw.png","_raw_repeat.png"]:
			var output_path: String=directory+id+"_"+role+suffix
			outputs[output_path]=full_catalog[output_path]
	var record: Dictionary={"logical_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"actual_logical_canvas":[int(rect.size.x),int(rect.size.y)],"actual_native_canvas":[logical.x*SSAA,logical.y*SSAA],"ssaa_scale":SSAA,"overscan_px":FULL_OVERSCAN,"raw_repeat_exact":true,"derived_repeat_exact":true,"land_nav_msaa_enum":0,"land_nav_resized":false,"rf_sha256":full_geometry["rf_sha256"],"shader_sha256":FileAccess.get_sha256(surface.get_script().resource_path),"height_source_grid_origin":[0,0],"height_source_grid_size":[SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y],"geometry_source_window_px":[geometry_rect.position.x,geometry_rect.position.y,geometry_rect.size.x,geometry_rect.size.y],"terrain_mesh_path":full_geometry["terrain_mesh_path"],"terrain_mesh_sha256":full_geometry["terrain_mesh_sha256"],"actual_camera":{"projection":camera.projection,"size":camera.size,"position":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"raw_canvas":[logical.x*SSAA,logical.y*SSAA],"logical_canvas":[logical.x,logical.y],"camera_center_global_px":[rect.get_center().x,rect.get_center().y]},"actual_receiver_coverage":coverage,"outputs_sha256":outputs,"images":images,"ground_native_shadow_on":on["path"],"ground_native_shadow_off":off["path"],"native_caster_count":casters.size(),"native_body_baked_into_ground":false,"structure_support":"actual separate triangulated Y0 deck; RF bed remains negative"}
	active_view.queue_free()
	active_view=null
	await _sync()
	record["global_terrain_mesh_path"]=full_geometry["terrain_mesh_path"]
	record["global_terrain_mesh_sha256"]=full_geometry["terrain_mesh_sha256"]
	record["terrain_mesh_path"]=actual_mesh_path
	record["terrain_mesh_sha256"]=full_catalog[actual_mesh_path]
	record["actual_deck_mesh_path"]=support_path
	record["actual_deck_mesh_sha256"]=full_catalog[support_path]
	# Actual canvas is the real overscanned viewport. The cropped native
	# authority is separately named, never substituted for a camera canvas.
	record["cropped_native_canvas"]=[int(rect.size.x)*SSAA,int(rect.size.y)*SSAA]
	record["raw_viewport_canvas"]=[logical.x*SSAA,logical.y*SSAA]
	record["logical_overscan"]=[logical.x,logical.y]
	record["crop_px"]=[FULL_OVERSCAN,FULL_OVERSCAN,int(rect.size.x),int(rect.size.y)]
	record["shader_path"]=FULL_ROOT+"capture/terrain_shader.gdshader"
	record["shader_sha256"]=full_catalog[record["shader_path"]]
	record["outside_sourcebody_shadow_evidence"]=ground_evidence
	record["opaque_resampling_recipe"]={"algorithm_identity":"OPAQUE_RGBA8_LANCZOS_V1","factor":SSAA,"method":"Image.INTERPOLATE_LANCZOS then exact logical crop; no alpha reconstruction for opaque terrain","shadow_on_visual_alias":"original byte-identical actual ON PNG copies; no additional capture"}
	for role: String in images:
		record[role+"_path"]=directory+id+"_"+role+".png"
		record[role+"_repeat_path"]=directory+id+"_"+role+"_repeat.png"
	return record

func _full_ground_evidence(id: String,rect: Rect2,on: Image,off: Image,directory: String) -> Dictionary:
	var union:=Image.create(on.get_width(),on.get_height(),false,Image.FORMAT_RGBA8)
	union.fill(Color(0,0,0,0))
	for site in source.vegetation_sites:
		var key: String=String(site["kind"])+str(site["pose"])
		var proto: Dictionary=native_prototype_cache[key]
		var body: Image=proto["image"]
		var origin: Vector2=source.project_source(site["source_foot"])-Vector2(proto["foot"])-rect.position
		if not Rect2(origin,Vector2(body.get_size())).grow(2.).intersects(Rect2(Vector2.ZERO,Vector2(on.get_size()))): continue
		for y in range(body.get_height()):
			for x in range(body.get_width()):
				if body.get_pixel(x,y).a<=.12: continue
				var p:=Vector2i((origin+Vector2(x,y)).round())
				for dy in range(-2,3):
					for dx in range(-2,3):
						var q:=p+Vector2i(dx,dy)
						if q.x>=0 and q.y>=0 and q.x<union.get_width() and q.y<union.get_height(): union.set_pixelv(q,Color.WHITE)
	for object: Dictionary in full_objects:
		if not String(object.get("role","")).begins_with("bridge_"): continue
		var body: Image=Image.load_from_file(object["texture"])
		if body==null or body.is_empty():
			error="Missing actual structural sourcebody union input."
			return {}
		var origin: Vector2=Vector2(object["pos"][0]*SOURCE.SIZE.x,object["pos"][1]*SOURCE.SIZE.y)-Vector2(body.get_size())*.5-rect.position
		if not Rect2(origin,Vector2(body.get_size())).grow(2.).intersects(Rect2(Vector2.ZERO,Vector2(on.get_size()))): continue
		for y in range(body.get_height()):
			for x in range(body.get_width()):
				if body.get_pixel(x,y).a<=.12: continue
				var p:=Vector2i((origin+Vector2(x,y)).round())
				for dy in range(-2,3):
					for dx in range(-2,3):
						var q:=p+Vector2i(dx,dy)
						if q.x>=0 and q.y>=0 and q.x<union.get_width() and q.y<union.get_height(): union.set_pixelv(q,Color.WHITE)
	var shadow:=Image.create(on.get_width(),on.get_height(),false,Image.FORMAT_RGBA8)
	shadow.fill(Color(0,0,0,0))
	var count := 0
	for y in range(on.get_height()):
		for x in range(on.get_width()):
			var a: Color=on.get_pixel(x,y)
			var b: Color=off.get_pixel(x,y)
			var difference: float=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
			if difference>1./255. and union.get_pixel(x,y).a<.5:
				count+=1
				shadow.set_pixel(x,y,Color(0,0,0,difference))
	var union_path: String=directory+id+"_sourcebody_union_dilate2.png"
	var shadow_path: String=directory+id+"_actual_ground_shadow.png"
	if union.save_png(union_path)!=OK or shadow.save_png(shadow_path)!=OK:
		error="Cannot save actual outside-body ground evidence."
		return {}
	full_catalog[union_path]=FileAccess.get_sha256(union_path)
	full_catalog[shadow_path]=FileAccess.get_sha256(shadow_path)
	if not id.contains("--"): full_shadow_pixels+=count
	return {"sourcebody_union_path":union_path,"ground_shadow_path":shadow_path,"outside_sourcebody_pixels":count,"body_threshold":.12,"body_dilation_px":2,"ground_difference_threshold":1./255.,"method":"actual same-camera SHADOWS_ONLY ON/OFF RGB difference, excluding actual sourcebody union; no painted shadow"}

func _full_set_shadow_only(node: Node3D,casters: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		casters.append(node)
	for child in node.get_children():
		if child is Node3D: _full_set_shadow_only(child,casters)

func _edge(row: int,col: int,vertical: bool) -> Dictionary:
	var from: String="r%d_c%d"%[row,col]
	var to: String="r%d_c%d"%[row,col+1] if vertical else "r%d_c%d"%[row+1,col]
	var rect:=Rect2((col+1)*SOURCE.TILE.x-16,row*SOURCE.TILE.y,32,SOURCE.TILE.y) if vertical else Rect2(col*SOURCE.TILE.x,(row+1)*SOURCE.TILE.y-16,SOURCE.TILE.x,32)
	return {"id":from+"--"+to,"from":from,"to":to,"vertical":vertical,"rect":rect}

func _full_ensure_chunk(id: String) -> bool:
	for record in full_chunks:
		if record["id"]==id: return true
	for authored in SOURCE.chunks():
		if authored["id"]!=id: continue
		var captured: Dictionary=await _full_window(id,_rect_from_array(authored["logical_rect_px"]),FULL_ROOT+"chunks/")
		if captured.is_empty(): return false
		captured.erase("images")
		var record: Dictionary=authored.duplicate(true)
		record["capture"]=captured
		full_chunks.append(record)
		return true
	error="Unknown actual chunk "+id
	return false

func _full_capture_edge(edge: Dictionary) -> Dictionary:
	var rect: Rect2=edge["rect"]
	var captured: Dictionary=await _full_window(String(edge["id"]),rect,FULL_ROOT+"seams/")
	if captured.is_empty(): return {}
	var references: Dictionary=captured["images"]
	var mismatches: Dictionary={}
	var reference_paths: Dictionary={}
	for role: String in ["visual","land","raw_walk","walk"]:
		var reference: Image=references[role]
		var from: Image=Image.load_from_file(FULL_ROOT+"chunks/"+String(edge["from"])+"_"+role+".png")
		var to: Image=Image.load_from_file(FULL_ROOT+"chunks/"+String(edge["to"])+"_"+role+".png")
		if from==null or to==null or from.get_size()!=SOURCE.TILE or to.get_size()!=SOURCE.TILE:
			error="Independent seam missing native chunk authority "+String(edge["id"])+"/"+role
			return {}
		from.convert(Image.FORMAT_RGBA8)
		to.convert(Image.FORMAT_RGBA8)
		var expected:=Image.create(reference.get_width(),reference.get_height(),false,Image.FORMAT_RGBA8)
		if edge["vertical"]:
			expected.blit_rect(from,Rect2i(SOURCE.TILE.x-16,0,16,SOURCE.TILE.y),Vector2i.ZERO)
			expected.blit_rect(to,Rect2i(0,0,16,SOURCE.TILE.y),Vector2i(16,0))
		else:
			expected.blit_rect(from,Rect2i(0,SOURCE.TILE.y-16,SOURCE.TILE.x,16),Vector2i.ZERO)
			expected.blit_rect(to,Rect2i(0,0,SOURCE.TILE.x,16),Vector2i(0,16))
		var expected_bytes: PackedByteArray=expected.get_data()
		var actual_bytes: PackedByteArray=reference.get_data()
		var different_bytes := 0
		if expected_bytes.size()!=actual_bytes.size():
			error="Independent seam byte-size disagreement"
			return {}
		for n in range(actual_bytes.size()):
			if expected_bytes[n]!=actual_bytes[n]: different_bytes+=1
		mismatches[role]=different_bytes
		reference_paths[role]=FULL_ROOT+"seams/"+String(edge["id"])+"_"+role+".png"
		if different_bytes>0:
			error="Independent seam exactRGBA rejected "+String(edge["id"])+"/"+role+": "+str(different_bytes)+" bytes"
			captured.erase("images")
			_write_json(FULL_ROOT+"capture/"+String(edge["id"])+"_failed_comparison.json",{"status":"TECHNICAL_FAIL","case":edge["id"],"different_bytes":mismatches,"independent_reference_capture":captured,"no_shadow_atlas_waiver":true})
			return {}
	# Classify actual projected raster, NOT project-space points as source XZ.
	# Full17 crosses normal to this seam; endpoints are inside the measured strip.
	var walk: Image=references["walk"]
	var witnesses: Array=[]
	var blocked_witnesses: Array=[]
	for n in range(12,int(rect.size.y if edge["vertical"] else rect.size.x)-12,4):
		var center: Vector2=rect.position+(Vector2(16,n) if edge["vertical"] else Vector2(n,16))
		var clear := true
		var actual_bad_shoe:=Vector2(INF,INF)
		for side in [-4.,4.]:
			var foot: Vector2=center+(Vector2(side,0) if edge["vertical"] else Vector2(0,side))
			for offset: Vector2 in source.foot_offsets():
				var local:=Vector2i((foot+offset-rect.position).round())
				if local.x<0 or local.y<0 or local.x>=walk.get_width() or local.y>=walk.get_height() or walk.get_pixelv(local).r<.5:
					clear=false
					if actual_bad_shoe.x==INF and local.x>=0 and local.y>=0 and local.x<walk.get_width() and local.y<walk.get_height(): actual_bad_shoe=Vector2(local)+rect.position
		if clear and witnesses.size()<12:
			witnesses.append({"from_px":[center.x-4 if edge["vertical"] else center.x,center.y if edge["vertical"] else center.y-4],"to_px":[center.x+4 if edge["vertical"] else center.x,center.y if edge["vertical"] else center.y+4],"basis":"actual native MSAA0 projected walk raster; all17 shoes at both crossing sides"})
		elif not clear and actual_bad_shoe.x!=INF and blocked_witnesses.size()<12:
			blocked_witnesses.append({"foot_px":[actual_bad_shoe.x,actual_bad_shoe.y],"crossing_center_px":[center.x,center.y],"basis":"exact actual black pixel at the failed complete17 crossing shoe in independent MSAA0 walk; not inferred from region labels"})
	captured.erase("images")
	var result: Dictionary=edge.duplicate()
	result.erase("rect")
	result["classification"]="open" if not witnesses.is_empty() else "blocked"
	if witnesses.is_empty() and blocked_witnesses.is_empty():
		error="No true black pixel negative for blocked independent seam."
		return {}
	result["projected_witnesses"]=witnesses if not witnesses.is_empty() else blocked_witnesses
	result["independent_reference_capture"]=captured
	result["independent_reference_capture"]["four_paths"]=reference_paths
	result["comparison_status"]="ACTUAL_ALL_RGBA_EXACT"
	result["compared_byte_difference"]=mismatches
	return result

func _full_export_native_instances() -> bool:
	for site in source.vegetation_sites:
		var key: String=String(site["kind"])+str(site["pose"])
		if not native_prototype_cache.has(key):
			error="Missing actual native prototype for "+String(site["id"])
			return false
		var proto: Dictionary=native_prototype_cache[key]
		var id: String=site["id"]
		var path: String=FULL_ROOT+"entities/"+id+".png"
		var source_png: String=proto["record"]["texture"]
		var bytes: PackedByteArray=FileAccess.get_file_as_bytes(source_png)
		var out:=FileAccess.open(path,FileAccess.WRITE)
		if out==null:
			error="Cannot save independent entity "+id
			return false
		out.store_buffer(bytes)
		var io: Error=out.get_error()
		out.close()
		if io!=OK or FileAccess.get_file_as_bytes(path)!=bytes:
			error="Instance alpha bytes differ from actual pose prototype "+id
			return false
		full_catalog[path]=FileAccess.get_sha256(path)
		var foot: Vector2=source.project_source(site["source_foot"])
		var actual: Dictionary=site.duplicate(true)
		actual.erase("source_foot")
		var image: Image=proto["image"]
		var uv: Vector2=Vector2(proto["foot"])/Vector2(image.get_size())
		var center: Vector2=foot-(uv-Vector2(.5,.5))*Vector2(image.get_size())
		actual["texture"]=path
		actual["source_XZ_foot_px"]=[site["source_foot"].x,site["source_foot"].y]
		actual["world_foot_px"]=[foot.x,foot.y]
		actual["pos"]=[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y]
		actual["foot_uv"]=[uv.x,uv.y]
		actual["render_size_px"]=[image.get_width(),image.get_height()]
		actual["depth_sort_foot_y"]=foot.y/SOURCE.SIZE.y
		actual["sort_by_feet"]=true
		actual["blocking"]=bool(site["blocking"])
		actual["walkability_margin_px"]=[0.,0.]
		actual["prototype_actual_sourcebody_evidence"]=proto["record"]
		_full_register_paths(proto["record"])
		_full_register_paths(PLANTS.texture_evidence)
		_full_register_paths(PLANTS.geometry_evidence)
		actual["collision_size_px"]=[site["collision_size_px"].x,site["collision_size_px"].y]
		var physical_center: Vector2=foot
		if site["kind"]=="boulder":
			var bounds: Array=proto["record"]["used_vertex_bounds_m"]
			var support: Vector3=proto["support"]
			var source_foot: Vector2=site["source_foot"]
			var start: Vector2=source_foot+Vector2((bounds[0][0]-support.x)*SOURCE.PPM,(bounds[0][2]-support.z)*SOURCE.Z_PPM)
			var size:=Vector2((bounds[1][0]-bounds[0][0])*SOURCE.PPM,(bounds[1][2]-bounds[0][2])*SOURCE.Z_PPM)
			actual["source_fullxz_rect_px"]=[start.x,start.y,size.x,size.y]
			actual["collision_size_px"]=[size.x,size.y]
			actual["collision_center_world_px"]=[start.x+size.x*.5,start.y+size.y*.5-source.triangle_height(source_foot)*SOURCE.Z_PPM]
			physical_center=Vector2(actual["collision_center_world_px"][0],actual["collision_center_world_px"][1])
		else:
			actual["collision_center_world_px"]=[physical_center.x,physical_center.y]
		if actual["blocking"]:
			var physical_size:=Vector2(actual["collision_size_px"][0],actual["collision_size_px"][1])
			actual["collision_size"]=[physical_size.x/SOURCE.SIZE.x,physical_size.y/SOURCE.SIZE.y]
			actual["collision_offset"]=[(physical_center.x-center.x)/SOURCE.SIZE.x,(physical_center.y-center.y)/SOURCE.SIZE.y]
		if not _write_json(FULL_ROOT+"entities/"+id+".json",actual): return false
		full_catalog[FULL_ROOT+"entities/"+id+".json"]=FileAccess.get_sha256(FULL_ROOT+"entities/"+id+".json")
		full_objects.append(actual)
	return true

func _full_register_paths(value: Variant) -> void:
	if value is String:
		if value.begins_with("res://") and FileAccess.file_exists(value):
			full_catalog[value]=FileAccess.get_sha256(value)
			if value.get_extension() in ["gd","gdshader","res","gltf","glb","obj","tga","jpg","png","json","bin"]: full_graph[value]=full_catalog[value]
	elif value is Dictionary:
		for key in value:
			_full_register_paths(key)
			_full_register_paths(value[key])
	elif value is Array:
		for item in value: _full_register_paths(item)

func _full_register_literal_inputs(path: String,visited: Dictionary) -> bool:
	if visited.has(path): return true
	visited[path]=true
	if not FileAccess.file_exists(path):
		error="Missing exact full-source input "+path
		return false
	full_catalog[path]=FileAccess.get_sha256(path)
	full_graph[path]=full_catalog[path]
	if path.get_extension()=="gltf":
		var gltf: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not gltf is Dictionary:
			error="Invalid registered GLTF dependency graph "+path
			return false
		for section: String in ["buffers","images"]:
			for entry: Dictionary in gltf.get(section,[]):
				var uri: String=entry.get("uri","")
				if uri.is_empty() or uri.begins_with("data:"): continue
				if not _full_register_literal_inputs(path.get_base_dir().path_join(uri.uri_decode()),visited): return false
		return true
	if path.get_extension()!="gd": return true
	var regex:=RegEx.new()
	if regex.compile("['\"](res://[^'\"]+)['\"]")!=OK:
		error="Cannot close source dependency graph."
		return false
	for match in regex.search_all(FileAccess.get_file_as_string(path)):
		var dependency: String=match.get_string(1)
		if dependency.begins_with("res://build/") or dependency.begins_with(FULL_ROOT): continue
		if dependency.get_extension() not in ["gd","gltf","glb","res","obj","tga","png","jpg","json"]: continue
		if not _full_register_literal_inputs(dependency,visited): return false
	return true

func _full_copy_exact(original: String,destination: String) -> bool:
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(original)
	if bytes.is_empty():
		error="Missing actual original bytes "+original
		return false
	var file:=FileAccess.open(destination,FileAccess.WRITE)
	if file==null:
		error="Cannot copy independent runtime source "+destination
		return false
	file.store_buffer(bytes)
	var io: Error=file.get_error()
	file.close()
	if io!=OK or FileAccess.get_file_as_bytes(destination)!=bytes:
		error="Runtime original-alpha copy differs "+destination
		return false
	full_catalog[destination]=FileAccess.get_sha256(destination)
	full_catalog[original]=FileAccess.get_sha256(original)
	full_graph[original]=full_catalog[original]
	return true

func _full_map_source_point(raw: Array,door: Vector2,measured: Dictionary) -> Array:
	var original_size: Array=measured["source_size_px"]
	var render_size: Array=measured["render_size_px"]
	var source_door: Array=measured["source_doorstep_px"]
	return [door.x+(float(raw[0])-float(source_door[0]))*float(render_size[0])/float(original_size[0]),door.y+(float(raw[1])-float(source_door[1]))*float(render_size[1])/float(original_size[1])]

func _full_map_points(points: Array,door: Vector2,measured: Dictionary) -> Array:
	var result: Array=[]
	for p: Array in points: result.append(_full_map_source_point(p,door,measured))
	return result

func _full_export_compounds(copy_assets: bool=true) -> bool:
	full_portals.clear()
	full_core_landmarks.clear()
	for landmark in SOURCE.LANDMARKS:
		var id: String=landmark["id"]
		var measured: Dictionary=source.semantics[id]
		var texture: String=FULL_ROOT+"entities/compound_"+id+".png"
		if copy_assets and not _full_copy_exact(landmark["source"],texture): return false
		var foot: Vector2=source.project_source(landmark["foot"])
		var uv:=Vector2(float(measured["source_doorstep_uv"][0]),float(measured["source_doorstep_uv"][1]))
		var size:=Vector2(float(measured["render_size_px"][0]),float(measured["render_size_px"][1]))
		var center: Vector2=foot-(uv-Vector2(.5,.5))*size
		var solids: Array=[]
		for polygon: Array in measured["solid_polygons_source_px"]: solids.append(_full_map_points(polygon,foot,measured))
		var object: Dictionary={"id":"compound_"+id,"role":"independent_generated_compound","texture":texture,"source":landmark["source"],"source_sha256":measured["source_sha256"],"source_size_px":measured["source_size_px"],"render_size_px":[size.x,size.y],"foot_uv":[uv.x,uv.y],"world_foot_px":[foot.x,foot.y],"pos":[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y],"depth_sort_foot_y":foot.y/SOURCE.SIZE.y,"sort_by_feet":true,"centered":true,"blocking":true,"solid_polygons_px":solids,"legacy_baked_light":true,"source_provenance":"project-original generated source, NOT CC0; original alpha and pixels unchanged"}
		full_objects.append(object)
		var passage: Array=_full_map_points(measured["passage_path_source_px"],foot,measured)
		var portal: Dictionary={"id":id,"compound_id":object["id"],"target_scene":landmark["target"],"target_pos":[landmark["target_pos"].x,landmark["target_pos"].y],"pos":[foot.x/SOURCE.SIZE.x,foot.y/SOURCE.SIZE.y],"source":landmark["source"],"source_sha256":measured["source_sha256"],"source_doorstep_uv":measured["source_doorstep_uv"],"source_XZ_foot_px":[landmark["foot"].x,landmark["foot"].y],"door_foot_px":[foot.x,foot.y],"interaction_polygon_px":_full_map_points(measured["interaction_polygon_source_px"],foot,measured),"passage_polygon_px":_full_map_points(measured["passage_polygon_source_px"],foot,measured),"passage_path_px":passage,"approach_direction":[0,1],"auto_trigger":false,"doorstep_visual_review_status":"PENDING_ROOT_ACTUAL_CURRENT_CAPTURE","size":[96./SOURCE.SIZE.x,48./SOURCE.SIZE.y]}
		full_portals.append(portal)
		if id in SOURCE.CORE_IDS: full_core_landmarks.append({"id":id,"center_px":[center.x,center.y],"door_foot_px":[foot.x,foot.y]})
	if full_portals.size()!=16 or full_core_landmarks.size()!=9:
		error="Incomplete actual compound/doorway assembly."
		return false
	for i in range(full_core_landmarks.size()):
		for j in range(i+1,full_core_landmarks.size()):
			for role: String in ["center_px","door_foot_px"]:
				var a: Array=full_core_landmarks[i][role]
				var b: Array=full_core_landmarks[j][role]
				if Vector2(a[0],a[1]).distance_to(Vector2(b[0],b[1]))<SOURCE.MIN_CORE_SPACING:
					error="Actual nine-core center/door spacing failed."
					return false
	return true

func _full_source_plan() -> void:
	var approval: Variant=JSON.parse_string(FileAccess.get_file_as_string(FULL_APPROVAL))
	if not approval is Dictionary or approval.get("scope","")!="SOURCE_PLAN_ONLY" or approval.get("approved_by","")!="root":
		error="Full source forecast requires separate exact SOURCE_PLAN_ONLY authorization."
		await _finish(false)
		return
	for path: String in [get_script().resource_path,"res://scripts/dev/world_map_v15_complete_v5_source.gd","res://scripts/dev/world_map_v15_complete_v5_surface.gd","res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd"]:
		if approval.get("source_graph",{}).get(path,"").to_lower()!=FileAccess.get_sha256(path).to_lower():
			error="Changed full source-plan executed graph."
			await _finish(false)
			return
	source=SOURCE.new()
	source.prepare()
	if not _full_prepare_semantics() or not _full_export_compounds(false):
		await _finish(false)
		return
	var failures: Array=[]
	var centers := 0
	for route in source.routes:
		var points: PackedVector2Array=route["points"]
		for segment in range(points.size()-1):
			var steps: int=maxi(1,ceili(points[segment].distance_to(points[segment+1])/4.))
			for n in range(steps+1):
				var p: Vector2=points[segment].lerp(points[segment+1],float(n)/steps)
				centers+=1
				var projected: Vector2=source.project_source(p)
				for structure in source.structures:
					if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): projected=p
				for offset: Vector2 in source.foot_offsets():
					if not source.supported_walk(p+offset) or not _full_compound_clear(projected+offset):
						if failures.size()<256: failures.append({"route_id":route["id"],"source_center_px":[p.x,p.y],"projected_center_px":[projected.x,projected.y],"shoe_offset_px":[offset.x,offset.y],"source_selector":source.selector_cell_info(p+offset)})
						break
	for portal in full_portals:
		var points: Array=portal["passage_path_px"]
		for segment in range(points.size()-1):
			var a:=Vector2(points[segment][0],points[segment][1])
			var b:=Vector2(points[segment+1][0],points[segment+1][1])
			var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
			for n in range(steps+1):
				var p: Vector2=a.lerp(b,float(n)/steps)
				for offset: Vector2 in source.foot_offsets():
					if not _full_compound_clear(p+offset):
						if failures.size()<256: failures.append({"portal_id":portal["id"],"projected_passage_point_px":[p.x,p.y],"shoe_offset_px":[offset.x,offset.y],"kind":"actual measured source solid blocks door approach"})
	var directory: String="res://build/world_map_v15_complete_v5_full_source_plan/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var result: Dictionary={"scope":"CPU_AUTHORING_FORECAST_NOT_NAV_OR_FIELD","passed":failures.is_empty(),"actual_executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path),"source_sha256":FileAccess.get_sha256(source.get_script().resource_path),"source_footprints_sha256":FileAccess.get_sha256(FULL_FOOTPRINTS),"centers":centers,"route_count":source.routes.size(),"portals":full_portals,"core_landmarks":full_core_landmarks,"compound_count":full_objects.size(),"failures":failures,"limitations":["Source Float32 selector and projected measured solids are predicted separately; only actual captured PNG and ordinary Field can establish full-foot/875/Physics traversal.","No art, raw PNG, RF, native mesh or formal resource written."]}
	var output: String=directory+"source_plan_"+str(Time.get_unix_time_from_system()).replace(".","_")+".json"
	var wrote: bool=_write_json(output,result)
	if not wrote or not failures.is_empty(): error="Actual source contract forecast failed; no full GPU export."
	await _finish(wrote and failures.is_empty())

func _full_compound_clear(p: Vector2) -> bool:
	for object in full_objects:
		for polygon: Array in object.get("solid_polygons_px",[]):
			var points:=PackedVector2Array()
			for q: Array in polygon: points.append(Vector2(q[0],q[1]))
			if Geometry2D.is_point_in_polygon(p,points): return false
	return true

func _full_export_structures() -> bool:
	var holder:=Node3D.new()
	root.add_child(holder)
	_add_bridge_geometry(holder,Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	for bridge: Node3D in holder.get_children():
		var id: String=bridge.get_meta("structure_id")
		var foot: Vector2=bridge.get_meta("source_foot")
		var deck:=Node3D.new()
		bridge.add_child(deck)
		var part_index := 0
		var parts: Array[Node3D]=[]
		for child in bridge.get_children():
			if not child is MeshInstance3D: continue
			var role: String=child.get_meta("runtime_role","")
			if role in ["bridge_deck","bridge_underbeam"]:
				child.reparent(deck,false)
			else: parts.append(child)
		var deck_record: Dictionary=await _full_capture_part(deck,id+"_deck",foot,"bridge_deck",false)
		if deck_record.is_empty():
			holder.queue_free()
			return false
		full_objects.append(deck_record)
		for part: Node3D in parts:
			var part_foot: Vector2=part.get_meta("source_foot")
			var role: String=part.get_meta("runtime_role")
			var record: Dictionary=await _full_capture_part(part,id+"_"+role+str(part_index),part_foot,role,true)
			if record.is_empty():
				holder.queue_free()
				return false
			full_objects.append(record)
			part_index+=1
		bridge.queue_free()
	holder.queue_free()
	await _sync()
	return true

func _full_part_vertices(node: Node3D) -> PackedVector3Array:
	var result:=PackedVector3Array()
	if node is MeshInstance3D:
		var mesh: Mesh=node.mesh
		for surface_index in range(mesh.get_surface_count()):
			var arrays: Array=mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:=PackedInt32Array()
			if arrays[Mesh.ARRAY_INDEX]!=null: indices=arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for vertex in vertices: result.append(node.global_transform*vertex)
			else:
				for index in indices: result.append(node.global_transform*vertices[index])
	for child in node.get_children():
		if child is Node3D: result.append_array(_full_part_vertices(child))
	return result

func _full_capture_part(original: Node3D,id: String,source_foot: Vector2,role: String,blocking: bool) -> Dictionary:
	var actual_vertices: PackedVector3Array=_full_part_vertices(original)
	if actual_vertices.is_empty():
		error="Empty actual bridge draw vertices "+id
		return {}
	var view:=SubViewport.new()
	view.own_world_3d=true
	view.transparent_bg=true
	view.msaa_3d=Viewport.MSAA_DISABLED
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=surface.environment()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,0)
	world.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	world.add_child(sun)
	var object:=original.duplicate() as Node3D
	world.add_child(object)
	object.global_transform=original.global_transform
	var foot3: Vector3=SOURCE.point3(source_foot,0.)
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.position=foot3+Vector3(0,20,20)
	camera.look_at(foot3)
	var low:=Vector2(INF,INF)
	var high:=Vector2(-INF,-INF)
	var min3:=Vector3(INF,INF,INF)
	var max3:=Vector3(-INF,-INF,-INF)
	for v in actual_vertices:
		min3=min3.min(v)
		max3=max3.max(v)
		var delta: Vector3=v-foot3
		var pixel:=Vector2(delta.dot(camera.basis.x),-delta.dot(camera.basis.y))*SOURCE.PPM
		low=low.min(pixel)
		high=high.max(pixel)
	# The real worldY0 foot is part of the canvas contract even for a rail
	# bolted above it. Do not let a tight high-face bbox put foot_uv outside.
	low=low.min(Vector2.ZERO)
	high=high.max(Vector2.ZERO)
	var canvas:=Vector2i(ceili(high.x-low.x)+32,ceili(high.y-low.y)+32)
	canvas.x=maxi(canvas.x,64)
	canvas.y=maxi(canvas.y,64)
	view.size=canvas*SSAA
	camera.size=float(canvas.y)/SOURCE.PPM
	var offset: Vector2=(low+high)*.5/SOURCE.PPM
	camera.position+=camera.basis.x*offset.x-camera.basis.y*offset.y
	camera.current=true
	await _sync()
	var raw: Image=view.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat: Image=view.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	var prefix: String=FULL_ROOT+"entities/"+id
	if raw.get_size()!=canvas*SSAA or raw.get_data()!=repeat.get_data() or raw.save_png(prefix+"_raw.png")!=OK or repeat.save_png(prefix+"_raw_repeat.png")!=OK:
		error="Actual bridge body/raw-repeat failed "+id
		view.queue_free()
		return {}
	var logical: Image=_alpha_resize(raw,canvas)
	var logical_repeat: Image=_alpha_resize(repeat,canvas)
	var used: Rect2i=logical.get_used_rect()
	if logical.get_data()!=logical_repeat.get_data() or used.size==Vector2i.ZERO or used.position.x<4 or used.position.y<4 or used.end.x>canvas.x-4 or used.end.y>canvas.y-4:
		error="Actual bridge alpha/canvas/repeat failed "+id
		view.queue_free()
		return {}
	if logical.save_png(prefix+".png")!=OK or logical_repeat.save_png(prefix+"_repeat.png")!=OK:
		error="Bridge logical alpha save failed "+id
		view.queue_free()
		return {}
	var image_foot: Vector2=camera.unproject_position(foot3)/SSAA
	var foot: Vector2=source_foot # physical deck is exactly worldY0, not negative RF bed
	var origin: Vector2=foot-image_foot
	var center: Vector2=origin+Vector2(canvas)*.5
	var source_polygons: Array=[]
	if blocking:
		var projected_xz:=PackedVector2Array()
		for v in actual_vertices: projected_xz.append(Vector2(v.x*SOURCE.PPM+SOURCE.SIZE.x*.5,v.z*SOURCE.Z_PPM+SOURCE.SIZE.y*.5))
		var hull: PackedVector2Array=Geometry2D.convex_hull(projected_xz)
		var polygon: Array=[]
		for p in hull: polygon.append([p.x,p.y])
		if polygon.size()<3:
			error="Degenerate actual structural fullXZ hull "+id
			view.queue_free()
			return {}
		source_polygons=[polygon]
	var record: Dictionary={"id":id,"role":role,"texture":prefix+".png","render_size_px":[canvas.x,canvas.y],"source_size_px":[canvas.x,canvas.y],"world_foot_px":[foot.x,foot.y],"foot_uv":[image_foot.x/canvas.x,image_foot.y/canvas.y],"pos":[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y],"sort_by_feet":blocking,"z_index":0 if blocking else -2,"depth_sort_foot_y":foot.y/SOURCE.SIZE.y,"blocking":blocking,"walk_support":role=="bridge_deck","deck_height_m":0.,"sourcebody_raw":prefix+"_raw.png","sourcebody_repeat":prefix+"_raw_repeat.png","body_repeat_path":prefix+"_repeat.png","sourcebody_exact":true,"alpha_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","actual_used_world_bounds_m":[_v3(min3),_v3(max3)],"actual_camera":{"projection":camera.projection,"size":camera.size,"position":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"raw_canvas":[canvas.x*SSAA,canvas.y*SSAA],"logical_canvas":[canvas.x,canvas.y]},"provenance":"project-original native timber geometry; no CC0 claim; actual captured native material"}
	record["alpha_unpremultiply_epsilon"]=.00001
	record["algorithm_identity"]="RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
	record["walkability_margin_px"]=[0.,0.]
	var geometry_arrays: Array=[]
	geometry_arrays.resize(Mesh.ARRAY_MAX)
	geometry_arrays[Mesh.ARRAY_VERTEX]=actual_vertices
	var actual_geometry:=ArrayMesh.new()
	actual_geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,geometry_arrays)
	var geometry_path: String=prefix+"_actual_world_draw_geometry.res"
	if ResourceSaver.save(actual_geometry,geometry_path)!=OK:
		error="Actual bridge draw geometry proof save failed "+id
		view.queue_free()
		return {}
	record["actual_draw_geometry_path"]=geometry_path
	record["actual_draw_geometry_sha256"]=FileAccess.get_sha256(geometry_path)
	record["actual_draw_geometry_vertex_space"]="global world metres; identity transform; actual drawn triangle vertices in source order"
	full_catalog[geometry_path]=record["actual_draw_geometry_sha256"]
	record["sourcebody_camera"]=record["actual_camera"].duplicate(true)
	if blocking: record["solid_polygons_px"]=source_polygons
	for path: String in [prefix+".png",prefix+"_repeat.png",prefix+"_raw.png",prefix+"_raw_repeat.png"]: full_catalog[path]=FileAccess.get_sha256(path)
	record["metadata_path"]=prefix+".json"
	if not _write_json(record["metadata_path"],record):
		view.queue_free()
		return {}
	full_catalog[record["metadata_path"]]=FileAccess.get_sha256(record["metadata_path"])
	view.queue_free()
	await _sync()
	return record

func _full_assemble_contract() -> bool:
	if full_shadow_pixels<=0:
		error="No actual outside-sourcebody shadow evidence; empty exports cannot be READY."
		return false
	var routes: Array=[]
	for route in source.routes:
		var points: Array=[]
		for p: Vector2 in route["points"]:
			var projected: Vector2=source.project_source(p)
			# Authored bridges are worldY0 support, distinct from their wet RF bed.
			for structure in source.structures:
				if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): projected=p
			points.append([projected.x,projected.y])
		routes.append({"id":route["id"],"points_px":points,"width_px":float(route["half_width_px"])*2.,"kind":route["kind"]})
	var supports: Array=[]
	for structure in source.structures:
		var polygon: Array=[]
		for p: Vector2 in structure["source_deck_polygon"]: polygon.append([p.x,p.y])
		var source_path: Array=[]
		var projected_path: Array=[]
		for p: Vector2 in structure["source_passage_px"]:
			source_path.append([p.x,p.y])
			var q: Vector2=source.project_source(p)
			if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): q=p
			projected_path.append([q.x,q.y])
		var support: Dictionary={"id":structure["id"],"kind":"bridge","route_id":structure["route_id"],"river_id":structure["river_id"],"source_deck_polygon":polygon,"projected_deck_polygon_px":polygon,"source_passage_px":source_path,"projected_passage_px":projected_path,"deck_height_m":0.,"actual_wet_bed_m":source.triangle_height(structure["center"]),"actual_deck_mesh_path":full_chunks[0]["capture"]["actual_deck_mesh_path"],"actual_deck_mesh_sha256":full_chunks[0]["capture"]["actual_deck_mesh_sha256"],"mesh_vertex_space":"global world metres","mesh_transform":{"basis_columns":[[1,0,0],[0,1,0],[0,0,1]],"origin":[0,0,0]},"deck_object_id":String(structure["id"])+"_deck","water_negative_probes":[]}
		var center: Vector2=structure["center"]
		var axis: Vector2=structure["axis"]
		for side in [-1.,1.]:
			var negative: Vector2=center+Vector2(-axis.y,axis.x)*(float(structure["half_width_px"])+64.)*side
			if source.triangle_height(negative)<SOURCE.WATER_Y:
				support["water_negative_probes"].append({"source_px":[negative.x,negative.y],"projected_water_px":[negative.x,negative.y-SOURCE.WATER_Y*SOURCE.Z_PPM],"side":side})
			else:
				error="Missing genuine two-sided off-deck wet-bed negative "+String(structure["id"])
				return false
		supports.append(support)
	var ecology: Array=[]
	var profiles: Array[String]=["snow_rock_ridge","western_limestone","northeastern_pine_forest","luoyang_fields","central_meadow","western_forest","southern_bamboo","river_fields","southeastern_marsh"]
	for index in range(9):
		var habitat: Dictionary=SOURCE.HABITATS[index]
		var source_point: Vector2=habitat["center"]
		var point: Vector2=source.project_source(source_point)
		var selector: Dictionary=source.selector_cell_info(source_point)
		var all17 := true
		for offset: Vector2 in source.foot_offsets():
			if not _full_sample_walk(point+offset): all17=false
		ecology.append({"id":habitat["id"],"source_XZ_px":[source_point.x,source_point.y],"projected_px":[point.x,point.y],"profile":profiles[index],"actual_rf_height_m":source.triangle_height(source_point),"native_selector":{"gradient":selector["gradient"],"min_height":selector["min_height"],"min_bank":selector["min_bank"],"walk":selector["walk"]},"walkable":all17,"material_binding":full_graph.duplicate(true),"visual_approved":false})
	var camera_path: String=FULL_ROOT+"capture/camera_contract.json"
	if not _write_json(camera_path,{"projection":"orthographic","logical_pixels_per_meter_x":SOURCE.PPM,"logical_pixels_per_meter_source_z":SOURCE.Z_PPM,"source_world_size_px":[SOURCE.SIZE.x,SOURCE.SIZE.y],"view_direction":[0,-1,-1],"source_ground_y_projects_minus_height_times_zppm":true,"chunk_overscan_px":FULL_OVERSCAN,"visual_ssaa_scale":SSAA,"binary_msaa_enum":0,"binary_resized":false,"actual_cameras_in_chunks":full_chunks}): return false
	full_catalog[camera_path]=FileAccess.get_sha256(camera_path)
	full_graph[camera_path]=full_catalog[camera_path]
	var semantics_path: String=FULL_ROOT+"landmark_semantics.json"
	if not _write_json(semantics_path,{"schema_version":15,"status":"MEASURED_ACTUAL_SOURCE_NOT_FIELD_APPROVED","landmarks":source.semantics,"source_authoring_path":FULL_FOOTPRINTS,"source_authoring_sha256":FileAccess.get_sha256(FULL_FOOTPRINTS)}): return false
	full_catalog[semantics_path]=FileAccess.get_sha256(semantics_path)
	full_graph[semantics_path]=full_catalog[semantics_path]
	full_catalog[FULL_FOOTPRINTS]=FileAccess.get_sha256(FULL_FOOTPRINTS)
	full_graph[FULL_FOOTPRINTS]=full_catalog[FULL_FOOTPRINTS]
	if not _full_overview_and_door_reviews(): return false
	var source_contract: Dictionary={"schema_version":15,"version":"world_v15","status":"ART_ASSETS_READY","authoring_revision":"complete_v5_geography_v4","world_size":[SOURCE.SIZE.x,SOURCE.SIZE.y],"tile_size":[SOURCE.TILE.x,SOURCE.TILE.y],"overview_path":FULL_ROOT+"overview.png","chunks":full_chunks,"seams":full_seams,"objects":full_objects,"portals":full_portals,"core_landmarks":full_core_landmarks,"routes":routes,"structures":supports,"ecology_probes":ecology,"geometry":{"grid_size":[SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y],"grid_step_px":SOURCE.GRID_STEP,"height_rf_path":full_geometry["rf_path"],"height_rf_sha256":full_geometry["rf_sha256"],"terrain_mesh_path":full_geometry["terrain_mesh_path"],"terrain_mesh_sha256":full_geometry["terrain_mesh_sha256"]},"pixel_sampling":"round_world_pixel","physical_navigation_margin_px":0,"visual_approved":false,"production_approved":false}
	var contract_path: String=FULL_ROOT+"source_contract.json"
	if not _write_json(contract_path,source_contract): return false
	full_catalog[contract_path]=FileAccess.get_sha256(contract_path)
	full_graph[contract_path]=full_catalog[contract_path]
	var roles: Dictionary={"source_script":source.get_script().resource_path,"builder_script":get_script().resource_path,"surface_script":surface.get_script().resource_path,"selector_script":source.get_script().resource_path,"terrain_shader":FULL_ROOT+"capture/terrain_shader.gdshader","height_rf":full_geometry["rf_path"],"landmark_semantics":semantics_path,"camera_contract":camera_path}
	var capture_graph: Dictionary={}
	for role: String in roles:
		capture_graph[role]={"path":roles[role],"sha256":FileAccess.get_sha256(roles[role])}
	if not _write_json(FULL_ROOT+"manifest.json",{"version":"world_v15","status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","source_graph":full_graph,"capture_graph":capture_graph,"asset_sha256":full_catalog,"chunks":full_chunks,"seams":full_seams,"outside_sourcebody_shadow_pixels":full_shadow_pixels,"native_object_count":source.vegetation_sites.size(),"structure_count":supports.size(),"portal_count":16,"core_count":9,"visual_approved":false,"production_approved":false,"door_review_requires_root":true}): return false
	return true

func _full_sample_walk(p: Vector2) -> bool:
	var pixel:=Vector2i(p.round())
	if pixel.x<0 or pixel.y<0 or pixel.x>=SOURCE.SIZE.x or pixel.y>=SOURCE.SIZE.y: return false
	var col: int=pixel.x/SOURCE.TILE.x
	var row: int=pixel.y/SOURCE.TILE.y
	var image: Image=Image.load_from_file(FULL_ROOT+"chunks/r%d_c%d_walk.png"%[row,col])
	return image!=null and image.get_pixel(pixel.x-col*SOURCE.TILE.x,pixel.y-row*SOURCE.TILE.y).r>=.5

func _full_overview_and_door_reviews() -> bool:
	# One logical composite only. No impossible whole-world 24576x16384 GPU
	# viewport or RGBAF allocation; each source chunk is released after blit.
	var overview:=Image.create(SOURCE.SIZE.x,SOURCE.SIZE.y,false,Image.FORMAT_RGBA8)
	for chunk in full_chunks:
		var image: Image=Image.load_from_file(chunk["visual_path"])
		if image==null or image.get_size()!=SOURCE.TILE:
			error="Incomplete captured overview ground."
			return false
		overview.blit_rect(image,Rect2i(Vector2i.ZERO,SOURCE.TILE),Vector2i(chunk["col"]*SOURCE.TILE.x,chunk["row"]*SOURCE.TILE.y))
	var ordered: Array[Dictionary]=full_objects.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var ground_a: bool=int(a.get("z_index",0))<0
		var ground_b: bool=int(b.get("z_index",0))<0
		if ground_a!=ground_b: return ground_a
		return float(a.get("depth_sort_foot_y",0.))<float(b.get("depth_sort_foot_y",0.)))
	for object in ordered:
		var image: Image=Image.load_from_file(object["texture"])
		if image==null or image.is_empty():
			error="Missing independent overview entity "+String(object["id"])
			return false
		var size:=Vector2i(object["render_size_px"][0],object["render_size_px"][1])
		if size!=image.get_size(): image=_alpha_resize(image,size)
		var center:=Vector2(object["pos"][0]*SOURCE.SIZE.x,object["pos"][1]*SOURCE.SIZE.y)
		overview.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i((center-Vector2(image.get_size())*.5).round()))
	for portal in full_portals:
		var foot:=Vector2(portal["door_foot_px"][0],portal["door_foot_px"][1])
		var rect:=Rect2i(Vector2i((foot-Vector2(380,400)).round()),Vector2i(760,500)).intersection(Rect2i(Vector2i.ZERO,SOURCE.SIZE))
		var path: String=FULL_ROOT+"capture/doorstep_"+String(portal["id"])+"_review.png"
		if overview.get_region(rect).save_png(path)!=OK:
			error="Door review capture save failure."
			return false
		full_catalog[path]=FileAccess.get_sha256(path)
		portal["doorstep_review_image_path"]=path
		portal["doorstep_review_image_sha256"]=full_catalog[path]
		portal["doorstep_review_image_scope"]="Actual captured native chunk ground composited with independent original-alpha runtime entities, not Field input proof"
	overview.resize(3072,2048,Image.INTERPOLATE_LANCZOS)
	if overview.save_png(FULL_ROOT+"overview.png")!=OK:
		error="Overview save failure."
		return false
	full_catalog[FULL_ROOT+"overview.png"]=FileAccess.get_sha256(FULL_ROOT+"overview.png")
	return true

func _release_full_refs() -> void:
	full_rf=null
	full_topology=null
	full_map_textures.clear()
	for chunk in full_chunks:
		if chunk.has("capture"): chunk["capture"].erase("images")
	full_chunks.clear()
	full_seams.clear()
	full_objects.clear()
	full_graph.clear()
	full_catalog.clear()
	full_geometry.clear()
	full_portals.clear()
	full_core_landmarks.clear()

