extends "res://scripts/dev/preview_world_map_v14_material_relief_sixth.gd"

# New local candidate, not a causal lighting experiment or formal map build.
# Original sixth preview, shadow controls and fifth world remain read-only.
const REFINED := "res://build/world_map_v14_sixth_refined_preview/"
const WATER_Y := -.025
const AMBIENT := .35
const DIRECT := .85
var case_height_image: Image
var case_height_texture: ImageTexture
var case_grid_origin := Vector2.ZERO
var case_grid_shape := Vector2i.ZERO
var case_mesh: ArrayMesh
var source_hashes: Dictionary = {}

func _initialize() -> void:
	_refined_run.call_deferred()

func _fail(reason: String) -> void:
	failed = true
	push_error("[SixthRefinedPreview] "+reason)
	if DirAccess.dir_exists_absolute(REFINED):
		_refined_json("result.json",{"status":"REFINED_PREVIEW_TECHNICAL_FAIL","reason":reason,"production_approved":false})
	quit(1)

func _refined_json(name: String,data: Dictionary) -> void:
	var stream := FileAccess.open(REFINED+name,FileAccess.WRITE)
	assert(stream!=null)
	stream.store_string(JSON.stringify(data,"\t"))

func _height(p: Vector2) -> float:
	var base := _base_height(p)
	var bank := _bank(p)
	if bank<0:
		# Continuous at shore: both dry and wet sides start exactly on WATER_Y.
		# This is authored bathymetry, subsequently sampled to actual 6px mesh.
		return WATER_Y-1.10*smoothstep(0,95,-bank)
	var ridge_roi := smoothstep(1020,1130,p.x)*(1.0-smoothstep(2450,2570,p.x))*(1.0-smoothstep(890,1020,p.y))
	var dry := lerpf(base,_ridge(p)+.08,ridge_roi*(1.0-_protection(p)))
	# Shore correction stays narrow, not a new traversable water apron.
	# A future production run must recheck bank>24px and all17 feet; this
	# preview never creates/saves/whitens navigation or structure masks.
	return lerpf(WATER_Y,dry,smoothstep(0,36,bank))

func _local_mesh(center: Vector2) -> ArrayMesh:
	var mesh := super._local_mesh(center)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	case_grid_origin = uv[0]*WORLD_PX
	var last := uv[uv.size()-1]*WORLD_PX
	case_grid_shape = Vector2i(roundi((last.x-case_grid_origin.x)/STEP)+1,roundi((last.y-case_grid_origin.y)/STEP)+1)
	if case_grid_shape.x*case_grid_shape.y!=vertices.size():
		_fail("Actual mesh row-major local RF shape mismatch")
		return null
	# The GPU water depth texture is built from this actual native mesh's
	# returned FLOAT32 Y coordinates, not recomputed analytical bank distance.
	var values := PackedFloat32Array()
	values.resize(vertices.size())
	for i in vertices.size(): values[i] = vertices[i].y
	case_height_image = Image.create_from_data(case_grid_shape.x,case_grid_shape.y,false,Image.FORMAT_RF,values.to_byte_array())
	case_height_texture = ImageTexture.create_from_image(case_height_image)
	case_mesh = mesh
	return mesh

func _surface_material() -> ShaderMaterial:
	var base := super._surface_material()
	if base==null: return null
	var code := base.shader.code
	# Authored broad soil habitats instead of a global sinusoidal forest mask.
	var old_forest := "float forest=(.5+.5*sin(xyz.x*.39+xyz.z*.18))*(.5+.5*cos(xyz.z*.43-xyz.x*.11));forest=smoothstep(.29,.64,forest)*.72*(1.-road);"
	if not code.contains(old_forest):
		_fail("Immutable parent PBR forest replacement marker unavailable")
		return null
	code = code.replace(old_forest,"float forest=0.;{vec2 q=(p-vec2(1440.,1000.))/vec2(340.,235.);forest=max(forest,1.-smoothstep(.40,1.25,length(q)));}{vec2 q=(p-vec2(1960.,1430.))/vec2(360.,245.);forest=max(forest,1.-smoothstep(.40,1.25,length(q)));}{vec2 q=(p-vec2(3260.,2430.))/vec2(350.,285.);forest=max(forest,1.-smoothstep(.40,1.25,length(q)));}forest*=.82*(1.-road);")
	code = code.replace("color=mix(color,mix(soil,mud,.18)*.88,road*.90);","color=mix(color,mix(soil,mud,.12)*vec3(.78,.75,.70),road*.94);")
	var shader := _compiled(code,["topo","detail_normals","rock_01_nor_gl","leafy_grass_arm","forest_ground_04_diff","brown_mud_03_arm"],"refined_authored_habitat_pbr")
	if shader==null: return null
	base.shader = shader
	return base

func _water_material() -> ShaderMaterial:
	var code := """shader_type spatial;render_mode cull_disabled,blend_mix,depth_draw_never;
uniform sampler2D actual_height_rf:filter_nearest,repeat_disable;
uniform vec2 grid_origin_px=vec2(0.);
uniform ivec2 grid_shape=ivec2(2);
uniform float grid_step_px=6.;
uniform float water_y_m=-.025;
varying vec3 xyz;
void vertex(){xyz=VERTEX;}
float triangle_height(vec2 source){
 vec2 u=(source-grid_origin_px)/grid_step_px;
 ivec2 cell=clamp(ivec2(floor(u)),ivec2(0),grid_shape-ivec2(2));
 vec2 f=clamp(u-vec2(cell),vec2(0.),vec2(1.));
 float a=texelFetch(actual_height_rf,cell,0).r;
 float b=texelFetch(actual_height_rf,cell+ivec2(1,0),0).r;
 float c=texelFetch(actual_height_rf,cell+ivec2(0,1),0).r;
 float d=texelFetch(actual_height_rf,cell+ivec2(1,1),0).r;
 return f.x+f.y<=1.?a+(b-a)*f.x+(c-a)*f.y:d+(c-d)*(1.-f.x)+(b-d)*(1.-f.y);
}
void fragment(){
 vec2 source=UV*vec2(4608.,3072.);
 float depth=water_y_m-triangle_height(source);
 if(depth<=0.){discard;}
 vec2 q=vec2(.034*cos(xyz.x*5.7+xyz.z*1.3)+.018*cos(xyz.z*11.9),.045*cos(xyz.z*6.9-xyz.x*1.8));
 vec3 wn=normalize(vec3(-q.x,1.,-q.y));NORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(wn,0.)).xyz);
 ALBEDO=mix(vec3(.22,.34,.29),vec3(.085,.24,.28),smoothstep(.03,.70,depth));
 ROUGHNESS=.18;SPECULAR=.68;METALLIC=0.;ALPHA=mix(.30,.85,smoothstep(.015,1.1,depth));
}
"""
	var shader := _compiled(code,["actual_height_rf","grid_origin_px","grid_shape","grid_step_px","water_y_m"],"actual_triangle_rf_water_depth")
	if shader==null: return null
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _viewport(center: Vector2,mesh: ArrayMesh) -> SubViewport:
	water.set_shader_parameter("actual_height_rf",case_height_texture)
	water.set_shader_parameter("grid_origin_px",case_grid_origin)
	water.set_shader_parameter("grid_shape",case_grid_shape)
	water.set_shader_parameter("grid_step_px",STEP)
	water.set_shader_parameter("water_y_m",WATER_Y)
	var view := super._viewport(center,mesh)
	for child in view.get_child(0).get_children():
		if child is WorldEnvironment: child.environment.ambient_light_energy=AMBIENT
		if child is DirectionalLight3D:
			child.light_energy=DIRECT
			child.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
			child.directional_shadow_max_distance=60.0
			child.shadow_bias=.02
			child.shadow_normal_bias=1.0
	return view

func _coverage(view: SubViewport,mesh: ArrayMesh) -> Dictionary:
	var camera: Camera3D = null
	var light: DirectionalLight3D = null
	for node in view.get_child(0).get_children():
		if node is Camera3D: camera=node
		if node is DirectionalLight3D: light=node
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var min_depth := INF
	var max_depth := -INF
	var min_y := INF
	var max_y := -INF
	var in_canvas := 0
	var image_rect := Rect2(Vector2.ZERO,Vector2(CANVAS))
	for vertex in vertices:
		min_y=minf(min_y,vertex.y)
		max_y=maxf(max_y,vertex.y)
		if not image_rect.has_point(camera.unproject_position(vertex)): continue
		var depth := -(camera.global_transform.affine_inverse()*vertex).z
		min_depth=minf(min_depth,depth)
		max_depth=maxf(max_depth,depth)
		in_canvas+=1
	# Orthographic ray depth at top screen edge is distance+size/2, with
	# terrain Y contribution -sqrt(2)*Y. This covers triangle interiors too,
	# even if every original triangle vertex projects outside the screen.
	var conservative_far := 36.0*sqrt(2.0)+camera.size*.5-sqrt(2.0)*min_y
	return {"actual_camera_projection":camera.projection,"actual_camera_size":camera.size,"actual_camera_position":[camera.position.x,camera.position.y,camera.position.z],"actual_camera_basis_columns":[[camera.basis.x.x,camera.basis.x.y,camera.basis.x.z],[camera.basis.y.x,camera.basis.y.y,camera.basis.y.z],[camera.basis.z.x,camera.basis.z.y,camera.basis.z.z]],"actual_direct_energy":light.light_energy,"ambient_energy":AMBIENT,"actual_shadow_mode":light.directional_shadow_mode,"actual_shadow_bias":light.shadow_bias,"actual_shadow_normal_bias":light.shadow_normal_bias,"actual_max_shadow_distance":light.directional_shadow_max_distance,"in_canvas_native_vertex_count":in_canvas,"in_canvas_depth_min":min_depth,"in_canvas_depth_max":max_depth,"actual_mesh_min_height":min_y,"actual_mesh_max_height":max_y,"whole_visible_receiver_far_bound":conservative_far,"shadow_distance_covers_entire_case":conservative_far<light.directional_shadow_max_distance,"cover_formula":"36*sqrt(2)+ortho_size/2-sqrt(2)*actual_mesh_minY; affine camera ray and actual triangle mesh","not_a_full_world_shadow_distance_contract":true}

func _refined_run() -> void:
	if DisplayServer.get_name()=="headless":
		_fail("Actual GPU preview required")
		return
	var manifest := _read_json(BASE+"manifest.json")
	if String(manifest.get("executed_builder_sha256","")).to_lower()!=BASE_EXECUTED_SHA:
		_fail("Frozen fifth binding mismatch")
		return
	contract=_read_json(BASE+"source_contract.json")
	heights=FileAccess.get_file_as_bytes(BASE+"height_grid.rf").to_float32_array()
	if heights.size()!=(COLS+1)*(ROWS+1):
		_fail("Frozen height source invalid")
		return
	var topo_image := Image.load_from_file(BASE+"source_topology.png")
	if topo_image==null:
		_fail("Frozen topology source missing")
		return
	topology=ImageTexture.create_from_image(topo_image)
	if not _load_pbr(): return
	surface=_surface_material()
	water=_water_material()
	if failed or surface==null or water==null: return
	_prepare_routes()
	DirAccess.make_dir_recursive_absolute(REFINED)
	_refined_json("result.json",{"status":"REFINED_PREVIEW_IN_PROGRESS","production_approved":false})
	var entries: Array[Dictionary]=[]
	for spec in CASES:
		var center: Vector2=spec["center"]
		var mesh:=_local_mesh(center)
		if failed or mesh==null: return
		var name: String=spec["id"]
		var prefix:=REFINED+name+"_"
		var view:=_viewport(center,mesh)
		var coverage:=_coverage(view,mesh)
		if not coverage["shadow_distance_covers_entire_case"]:
			_fail("Shadow max distance excludes actual receiver: "+name)
			return
		var frame:=await _capture(view,prefix+"pbr.png")
		var repeated:=await _capture(view,prefix+"pbr_repeat.png")
		if failed or frame==null or repeated==null: return
		if frame.get_data()!=repeated.get_data():
			_fail("Refined PBR repeat mismatch: "+name)
			return
		if name=="north_ridge":
			for node in view.get_child(0).get_children():
				if node is MeshInstance3D and node.mesh==mesh: node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if await _capture(view,prefix+"self_off_control.png")==null: return
		var rf_stream:=FileAccess.open(prefix+"actual_height_grid.rf",FileAccess.WRITE)
		if rf_stream==null:
			_fail("Local actual RF save failed")
			return
		rf_stream.store_buffer(case_height_image.get_data())
		rf_stream.close()
		if ResourceSaver.save(mesh,prefix+"actual_mesh.res")!=OK:
			_fail("Actual preview mesh save failed")
			return
		entries.append({"case":name,"source_center":[center.x,center.y],"coverage":coverage,"actual_mesh_path":prefix+"actual_mesh.res","actual_mesh_sha256":FileAccess.get_sha256(prefix+"actual_mesh.res"),"actual_height_rf_path":prefix+"actual_height_grid.rf","actual_height_rf_sha256":FileAccess.get_sha256(prefix+"actual_height_grid.rf"),"rf_shape":[case_grid_shape.x,case_grid_shape.y],"rf_origin_source_px":[case_grid_origin.x,case_grid_origin.y],"rf_format":"little endian float32, actual native mesh returned Y bytes, row-major","rf_mipmap_count":case_height_image.get_mipmap_count(),"rf_filter":"nearest texelFetch LOD0 no mip","height_interpolation":"same fx+fy<=1 [a,b,c] / [b,d,c] affine formula as actual native mesh","water_y_m":WATER_Y,"water_depth":"waterY minus actual triangle-affine height RF; no analytic-bank discard or depth-buffer refraction claim","dry_shore_blend_width_source_px":36,"repeat_exact":true,"local_candidate_not_navigation_or_whole_map_pass":true})
		view.queue_free()
		case_mesh=null
		case_height_texture=null
		case_height_image=null
		await process_frame
	_refined_json("result.json",{"status":"REFINED_LOCAL_CANDIDATES_REQUIRE_VISUAL_REVIEW","production_approved":false,"whole_map_pass":false,"executed_source_sha256":FileAccess.get_sha256(get_script().resource_path),"parent_source_sha256":FileAccess.get_sha256("res://scripts/dev/preview_world_map_v14_material_relief_sixth.gd"),"fifth_inputs_unchanged":true,"fifth_executed_binding":BASE_EXECUTED_SHA,"material_sources":texture_audit,"compile_gates":compile_audit,"cases":entries,"illumination_change":"ambient .54→.35; direct1.05→.85; native proceduralSky same; all independent props would need recapture with this common light before formal adoption","candidate_multiple_variables_not_causal_experiment":true,"shadow_change":"ORTHOGONAL max60 normalbias1, same terrain selfcast ON; north only OFF diagnostic; visible receiver bound audited","shore_change":"continuous shore height plus actual RF-affine water coverage/depth; uniform6px rows preserved; no nav/support writes"})
	surface=null
	water=null
	sky=null
	topology=null
	material_textures.clear()
	for frame in 8: await process_frame
	print("[SixthRefinedPreview] THREE_LOCAL_CANDIDATES_EXPORTED "+REFINED)
	quit(0)
