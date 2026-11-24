extends SceneTree

# Isolated VERSION15 five-region macro review; no full64 or formal writes.
# Default execution refuses GPU. No sealed v14 source/assets are written.
const SOURCE := preload("res://scripts/dev/world_map_v15_complete_v5_source.gd")
const SURFACE := preload("res://scripts/dev/world_map_v15_complete_v5_surface.gd")
const PLANTS := preload("res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd")
const TREE_MESH := "res://art/maps/world_map_v14/entities/tree_small02_native_hybrid.res"
const PREVIEW := "res://build/world_map_v15_complete_v5_macro_preview_retry1/"
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

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
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
		for sample in [{"id":"north_rock_snow","center":Vector2(5600,650)}, {"id":"northwest_sand_road","center":Vector2(1450,1120)}, {"id":"central_forest_meadow","center":Vector2(2050,4300)}, {"id":"southeast_wet_bamboo","center":Vector2(10900,4700)}, {"id":"real_bridge_bank","center":Vector2(source.structures[1]["center"])}]:
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

func _ensure_native_prototype(kind: String,pose: int) -> bool:
	var key: String=kind+str(pose)
	if native_prototype_cache.has(key): return true
	var mesh: ArrayMesh=_native_mesh(kind,pose)
	if mesh==null:
		error="Registered actual native model unavailable: "+key
		return false
	var metric_scale: float=[.19,.20,.20][pose] if kind=="tree" else .0050 if kind=="bamboo" else .65
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
	record["draw_mesh_source"]=TREE_MESH if kind=="tree" else PLANTS.BAMBOO_MESH if kind=="bamboo" else PLANTS.HERB
	record["draw_mesh_source_sha256"]=FileAccess.get_sha256(record["draw_mesh_source"])
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
