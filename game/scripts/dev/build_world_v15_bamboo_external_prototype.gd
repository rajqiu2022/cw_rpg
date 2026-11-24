extends SceneTree

# Only the isolated OBJ audit project. No RPG/autoload/Field or production writes.
const OBJ := "res://original/Bamboo 01.obj"
const OBJ_SHA := "63c07217c0644acd4671871ba03b69f71ef7fa91f8a30050b43ff33ff119be77"
const PPM := 102.4
const SCALE := .015
var viewport: SubViewport
var textures: Dictionary={}
var error := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name()=="headless" or not "--licensed-bamboo-prototype" in OS.get_cmdline_user_args():
		push_error("Explicit producer-authorised actual GPU prototype required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://prototype/"))
	if FileAccess.get_sha256(OBJ)!=OBJ_SHA:
		error="Original registered OBJ changed"
		await _finish(false)
		return
	var imported: ArrayMesh=load(OBJ) as ArrayMesh
	var audit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://result.json"))
	if imported==null or not audit.get("passed",false) or imported.get_surface_count()!=1:
		error="Native1440 OBJ pre-audit unavailable"
		await _finish(false)
		return
	var mesh:=ArrayMesh.new()
	var arrays: Array=imported.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var original_geometry: Dictionary=audit["surfaces"][0].duplicate(true)
	var material:=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled,depth_prepass_alpha;
uniform sampler2D original_diffuse:source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform sampler2D original_normal:filter_linear_mipmap_anisotropic,repeat_disable;
uniform sampler2D original_specular:filter_linear_mipmap_anisotropic,repeat_disable;
void fragment(){vec4 c=texture(original_diffuse,UV);ALBEDO=c.rgb;ALPHA=c.a;ALPHA_SCISSOR_THRESHOLD=.35;NORMAL_MAP=texture(original_normal,UV).rgb;NORMAL_MAP_DEPTH=.7;SPECULAR=clamp(texture(original_specular,UV).r*.65,0.,1.);ROUGHNESS=.82;}
"""
	material.shader=shader
	for channel: String in ["diffuse","normal","specular"]:
		var image: Image=Image.load_from_file("res://original/"+channel+".tga")
		if image==null or image.generate_mipmaps()!=OK:
			error="Author texture decode/mips failed"
			await _finish(false)
			return
		textures[channel]=ImageTexture.create_from_image(image)
		material.set_shader_parameter("original_"+channel,textures[channel])
	mesh.surface_set_material(0,material)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	for index in indices:
		low=low.min(vertices[index]*SCALE)
		high=high.max(vertices[index]*SCALE)
	var support:=Vector3(0,low.y,0)
	var used:=0
	var support_x:=0.
	var support_z:=-INF
	for index in indices:
		var p: Vector3=vertices[index]*SCALE
		if p.y<=low.y+(high.y-low.y)*.02:
			used+=1
			support_x+=p.x
			support_z=maxf(support_z,p.z)
	support=Vector3(support_x/maxi(used,1),low.y,support_z)
	viewport=_view(Vector2i(1024,1024),true)
	var world: Node3D=viewport.get_child(0)
	var model:=MeshInstance3D.new()
	model.mesh=mesh
	model.transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*SCALE),-support)
	model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(model)
	var camera:=_camera(world,Vector2i(512,512),Vector3(0,1.4,0))
	await _sync()
	var uniforms: Array[String]=[]
	for uniform in shader.get_shader_uniform_list(): uniforms.append(String(uniform["name"]))
	for expected: String in ["original_diffuse","original_normal","original_specular"]:
		if not expected in uniforms:
			error="Actual original-map shader compile/reflection failed"
			await _finish(false)
			return
	var raw: Image=_read()
	await _sync()
	var repeat: Image=_read()
	if not _save_pair("body",raw,repeat):
		await _finish(false)
		return
	var body: Image=_alpha(raw,Vector2i(512,512))
	var used_rect: Rect2i=body.get_used_rect()
	if used_rect.size==Vector2i.ZERO or used_rect.position.x<4 or used_rect.position.y<4 or used_rect.end.x>508 or used_rect.end.y>508:
		error="Actual licensed body alpha/canvas apron invalid"
		await _finish(false)
		return
	var crop: Rect2i=used_rect.grow(4)
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)*.5-Vector2(crop.position)
	if body.get_region(crop).save_png("res://prototype/body.png")!=OK:
		error="Body save failed"
		await _finish(false)
		return
	var body_camera: Dictionary=_camera_data(camera)
	viewport.queue_free()
	viewport=null
	await _sync()
	viewport=_view(Vector2i(2048,1440),false)
	world=viewport.get_child(0)
	camera=_camera(world,Vector2i(1024,720),Vector3(0,1.0,0))
	var ground:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(14,14)
	ground.mesh=plane
	var ground_material:=StandardMaterial3D.new()
	ground_material.albedo_color=Color(.28,.25,.18)
	ground_material.roughness=.95
	ground.material_override=ground_material
	world.add_child(ground)
	var poses: Array[Vector3]=[Vector3(-3,0,-.6),Vector3(-2.3,0,.2),Vector3(-2.7,0,1.15),Vector3(-.5,0,-1.5),Vector3(.4,0,-.9),Vector3(.8,0,.5)]
	var models: Array[MeshInstance3D]=[]
	var instances: Array[Dictionary]=[]
	for i in range(poses.size()):
		var m:=MeshInstance3D.new()
		m.mesh=mesh
		var basis:=Basis(Vector3.UP,deg_to_rad(float(i)*47.))
		m.transform=Transform3D(basis.scaled(Vector3.ONE*SCALE),poses[i]-basis*support)
		world.add_child(m)
		models.append(m)
		var projected: Vector2=camera.unproject_position(poses[i])*.5
		instances.append({"id":"licensed_bamboo_%d"%i,"world_foot_px":[projected.x,projected.y],"source_pose_m":_v3(poses[i]),"yaw_degrees":i*47.,"physical_footprint":"proposed narrow stem only, NOT canopy; this prototype is not a Field collision acceptance","own_depth_foot_y":projected.y})
	var sign:=MeshInstance3D.new()
	var sign_mesh:=BoxMesh.new()
	sign_mesh.size=Vector3(.08,.7,.08)
	sign.mesh=sign_mesh
	sign.position=Vector3(2.25,.35,.9)
	var sign_material:=StandardMaterial3D.new()
	sign_material.albedo_color=Color(.25,.13,.055)
	sign_material.roughness=.9
	sign.material_override=sign_material
	world.add_child(sign)
	var board:=MeshInstance3D.new()
	var board_mesh:=BoxMesh.new()
	board_mesh.size=Vector3(.46,.16,.04)
	board.mesh=board_mesh
	board.position=Vector3(2.30,.60,.9)
	board.material_override=sign_material
	world.add_child(board)
	await _sync()
	var scene: Image=_read()
	await _sync()
	var scene_repeat: Image=_read()
	if not _save_pair("sparse_scene",scene,scene_repeat):
		await _finish(false)
		return
	scene.resize(1024,720,Image.INTERPOLATE_LANCZOS)
	if scene.save_png("res://prototype/sparse_scene.png")!=OK:
		error="Scene save failed"
		await _finish(false)
		return
	var actor_original: Image=Image.load_from_file("res://actor_idle_down.png")
	var actor_frame: Image=actor_original.get_region(Rect2i(0,0,160,160))
	var actor: Image=_alpha(actor_frame,Vector2i(146,146))
	var actor_foot: Vector2=camera.unproject_position(Vector3(1.8,0,1.45))*.5
	scene.blend_rect(actor,Rect2i(Vector2i.ZERO,actor.get_size()),Vector2i((actor_foot-Vector2(80,152)*(146./160.)).round()))
	if scene.save_png("res://prototype/sparse_scene_actor_scale.png")!=OK:
		error="Actor-scale scene save failed"
		await _finish(false)
		return
	for m in models: m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	sign.hide()
	board.hide()
	await _sync()
	var shadow_on: Image=_read()
	await _sync()
	var shadow_on_repeat: Image=_read()
	if not _save_pair("ground_shadow_on",shadow_on,shadow_on_repeat):
		await _finish(false)
		return
	for m in models: m.hide()
	await _sync()
	var shadow_off: Image=_read()
	await _sync()
	var shadow_off_repeat: Image=_read()
	if not _save_pair("ground_shadow_off",shadow_off,shadow_off_repeat):
		await _finish(false)
		return
	var a: PackedByteArray=shadow_on.get_data()
	var b: PackedByteArray=shadow_off.get_data()
	var darkened:=0
	for offset in range(0,a.size(),4):
		if int(a[offset])+int(a[offset+1])+int(a[offset+2])<int(b[offset])+int(b[offset+1])+int(b[offset+2])-3: darkened+=1
	var record: Dictionary={"status":"LICENSED_NATIVE_BAMBOO_PROTOTYPE_REQUIRES_ROOT_VISUAL_REVIEW","production_approved":false,"original_obj_sha256":OBJ_SHA,"actual_native_arrays":original_geometry,"metric_scale":SCALE,"source_units_declared":false,"actual_height_m":high.y-low.y,"ground_anchor":_v3(support),"ground_anchor_method":"minimum actual draw-index Y and average X/frontZ of lowest2%, synthetic support point not a claimed vertex","body_crop_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"foot_uv":[foot.x/crop.size.x,foot.y/crop.size.y],"body_camera":body_camera,"scene_camera":_camera_data(camera),"instances":instances,"source_texture_channel_semantics":"Original512 diffuseRGBA+normal+specular unchanged, native shader adapter, NOT claimed metallic/roughness scans; original normal convention not flipped","alpha_scissor_threshold":.35,"resampling":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","actual_raw_repeat_exact":true,"shadow_on_off_darkened_pixels":darkened,"actor_source_sha256":FileAccess.get_sha256("res://actor_idle_down.png"),"actor_frame":[0,0,160,160],"actor_texture_scale_requested":.91,"actor_resampling_scale_actual":146./160.,"actor_overlay_is_scale_reference_not_actual_Field":true,"executed_script_sha256":FileAccess.get_sha256(get_script().resource_path)}
	if darkened==0 or not _json("res://prototype/result.json",record):
		error="Actual ground-cast or checked metadata output missing"
		await _finish(false)
		return
	models.clear()
	mesh=null
	imported=null
	material=null
	shader=null
	await _finish(true)

func _view(size: Vector2i,transparent: bool) -> SubViewport:
	var v:=SubViewport.new()
	v.size=size
	v.transparent_bg=transparent
	v.own_world_3d=true
	v.msaa_3d=Viewport.MSAA_DISABLED
	v.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(v)
	var world:=Node3D.new()
	v.add_child(world)
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(0,0,0,0) if transparent else Color(.35,.36,.33,1)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.90,.94,1)
	env.ambient_light_energy=.35
	environment.environment=env
	world.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=.85
	light.shadow_enabled=true
	light.shadow_normal_bias=1.
	light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_max_distance=60.
	world.add_child(light)
	return v

func _camera(world: Node3D,size: Vector2i,target: Vector3) -> Camera3D:
	var c:=Camera3D.new()
	c.projection=Camera3D.PROJECTION_ORTHOGONAL
	c.size=size.y/PPM
	c.position=target+Vector3(0,20,20)
	c.near=.05
	c.far=100.
	world.add_child(c)
	c.look_at(target)
	c.current=true
	return c

func _camera_data(c: Camera3D) -> Dictionary:
	return {"position":_v3(c.position),"basis":[_v3(c.basis.x),_v3(c.basis.y),_v3(c.basis.z)],"size":c.size,"actual_canvas":[viewport.size.x,viewport.size.y],"actual_to_logical":2,"ppm_logical":PPM,"msaa":viewport.msaa_3d}

func _read() -> Image:
	var image: Image=viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _sync() -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw

func _save_pair(name: String,a: Image,b: Image) -> bool:
	if a.get_data()!=b.get_data() or a.save_png("res://prototype/"+name+"_raw.png")!=OK or b.save_png("res://prototype/"+name+"_raw_repeat.png")!=OK:
		error="Actual readback repeat/save failed "+name
		return false
	return true

func _alpha(raw: Image,size: Vector2i) -> Image:
	var image: Image=raw.duplicate() as Image
	image.convert(Image.FORMAT_RGBAF)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c: Color=image.get_pixel(x,y)
			image.set_pixel(x,y,Color(c.r*c.a,c.g*c.a,c.b*c.a,c.a))
	image.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	for y in range(size.y):
		for x in range(size.x):
			var c: Color=image.get_pixel(x,y)
			image.set_pixel(x,y,Color(c.r/c.a,c.g/c.a,c.b/c.a,c.a) if c.a>.00001 else Color(0,0,0,0))
	image.convert(Image.FORMAT_RGBA8)
	return image

func _json(path: String,data: Dictionary) -> bool:
	var text: String=JSON.stringify(data,"\t")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(text)
	file.flush()
	var e: int=file.get_error()
	file.close()
	return e==OK and FileAccess.get_file_as_string(path)==text and JSON.parse_string(text) is Dictionary

func _finish(passed: bool) -> void:
	if not passed:
		push_error(error)
		_json("res://prototype/failed.json",{"status":"TECHNICAL_FAIL","reason":error})
	if viewport!=null:
		viewport.queue_free()
		viewport=null
	textures.clear()
	for i in range(16): await process_frame
	print("ACTUAL_LICENSED_BAMBOO_PROTOTYPE passed=",passed)
	quit(0 if passed else 1)

func _v3(p: Vector3) -> Array:
	return [p.x,p.y,p.z]
