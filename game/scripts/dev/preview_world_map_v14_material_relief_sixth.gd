extends SceneTree

# Isolated visual experiment, never a production publisher or v14 build hook.
# Fifth source, PNGs, RF and native mesh are read-only inputs. Running this
# script requires the producer's exclusive GPU window, not merely check-only.
const OUT := "res://build/world_map_v14_sixth_local_preview/"
const BASE := "res://art/maps/world_map_v14/"
const SOURCES := "res://art/external/polyhaven/world_terrain_v14_sixth/"
const BASE_EXECUTED_SHA := "abaef796ecb10c09f0999c17bc2c07c28dfb5e203850249ae50a5e3e952bf059"
const WORLD := Vector2(45.0,42.42640687)
const WORLD_PX := Vector2(4608,3072)
const CANVAS := Vector2i(1536,1024)
const PPM := 102.4
const STEP := 6.0
const COLS := 768
const ROWS := 512
const ASSETS := [
	{"id":"rock_01","meters":1.5},
	{"id":"leafy_grass","meters":2.0},
	{"id":"forest_ground_04","meters":3.2},
	{"id":"brown_mud_03","meters":1.3},
]
const CASES := [
	{"id":"north_ridge","center":Vector2(1750,650)},
	{"id":"central_road_soil","center":Vector2(2130,1620)},
	{"id":"south_riverbank","center":Vector2(3170,2200)},
]
var contract: Dictionary = {}
var heights := PackedFloat32Array()
var topology: ImageTexture
var material_textures: Dictionary = {}
var texture_audit: Array[Dictionary] = []
var route_buckets: Dictionary = {}
var source_routes: Array[Dictionary] = []
var compile_audit: Array[Dictionary] = []
var tree_records: Array[Dictionary] = []
var sky: Sky
var surface: ShaderMaterial
var water: ShaderMaterial
var failed := false

func _initialize() -> void:
	_run.call_deferred()

func _fail(reason: String) -> void:
	failed = true
	push_error("[V14SixthPreview] " + reason)
	if DirAccess.dir_exists_absolute(OUT):
		_write_json(OUT+"result.json",{"status":"PREVIEW_TECHNICAL_FAIL","reason":reason,"production_approved":false})
	quit(1)

func _write_json(path: String,value: Dictionary) -> void:
	assert(path.begins_with(OUT),"Preview writes must stay in isolated build prefix")
	var stream := FileAccess.open(path,FileAccess.WRITE)
	assert(stream != null)
	stream.store_string(JSON.stringify(value,"\t"))

func _read_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func _base_height(p: Vector2) -> float:
	var u := p/STEP
	var x := clampi(floori(u.x),0,COLS-1)
	var y := clampi(floori(u.y),0,ROWS-1)
	var f := (u-Vector2(x,y)).clamp(Vector2.ZERO,Vector2.ONE)
	var a := heights[y*(COLS+1)+x]
	var b := heights[y*(COLS+1)+x+1]
	var c := heights[(y+1)*(COLS+1)+x]
	var d := heights[(y+1)*(COLS+1)+x+1]
	return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y<=1.0 else d+(c-d)*(1.0-f.x)+(b-d)*(1.0-f.y)

func _inverse_fifth(screen: Vector2) -> Vector2:
	var p := screen
	for i in 12:
		p.y = screen.y + _base_height(p)*PPM/sqrt(2.0)
	return p

func _point(p: Vector2,h: float) -> Vector3:
	return Vector3((p.x/WORLD_PX.x-.5)*WORLD.x,h,(p.y/WORLD_PX.y-.5)*WORLD.y)

func _segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
	var ab := b-a
	return p.distance_to(a+ab*clampf((p-a).dot(ab)/maxf(ab.length_squared(),.0001),0,1))

func _prepare_routes() -> void:
	for record in contract.get("routes",[]):
		var points := PackedVector2Array()
		for raw in record["points_px"]:
			points.append(_inverse_fifth(Vector2(raw[0],raw[1])))
		var item := {"id":record["id"],"points":points,"width":float(record["width_px"])}
		source_routes.append(item)
		for i in range(1,points.size()):
			var a := points[i-1]
			var b := points[i]
			var apron: float = item["width"]*.5+150.0
			var lo := Vector2i(((a.min(b)-Vector2.ONE*apron)/128.0).floor())
			var hi := Vector2i(((a.max(b)+Vector2.ONE*apron)/128.0).floor())
			for yy in range(lo.y,hi.y+1):
				for xx in range(lo.x,hi.x+1):
					var key := Vector2i(xx,yy)
					if not route_buckets.has(key): route_buckets[key] = []
					route_buckets[key].append({"a":a,"b":b,"width":item["width"]})

func _protection(p: Vector2) -> float:
	var protected := 0.0
	for segment in route_buckets.get(Vector2i((p/128.0).floor()),[]):
		var distance := _segment_distance(p,segment["a"],segment["b"])
		var half_width: float = float(segment["width"])*.5+36.0
		protected = maxf(protected,1.0-smoothstep(half_width,half_width+100.0,distance))
	for landmark in contract.get("landmark_sources",[]):
		# These explicitly authored source rectangles are not screen roof bounds.
		var source_center: Array = landmark.get("source_collision_center_px",[])
		var source_size: Array = landmark.get("collision_size_px",[])
		if source_center.size()!=2 or source_size.size()!=2: continue
		var dimensions := Vector2(source_size[0],source_size[1])
		var rect := Rect2(Vector2(source_center[0],source_center[1])-dimensions*.5,dimensions)
		var q := (p-rect.get_center()).abs()-rect.size*.5
		var distance := Vector2(maxf(q.x,0),maxf(q.y,0)).length()
		protected = maxf(protected,1.0-smoothstep(45.0,145.0,distance))
	return protected

func _bank(p: Vector2) -> float:
	var bay_width := lerpf(108,82,smoothstep(1730,1790,p.y))
	var d := 4355+55*sin(p.y/285)-125*exp(-pow((p.y-1290)/116,2))-135*exp(-pow((p.y-1730)/bay_width,2))-p.x
	for channel in contract.get("waterways",[]):
		var points: Array = channel["points"]
		var radii: Array = channel["radii"]
		for i in range(1,points.size()):
			var a := Vector2(points[i-1][0],points[i-1][1])
			var b := Vector2(points[i][0],points[i][1])
			var ab := b-a
			var t := clampf((p-a).dot(ab)/maxf(ab.length_squared(),.0001),0,1)
			d = minf(d,p.distance_to(a+ab*t)-lerpf(float(radii[i-1]),float(radii[i]),t))
	return d

func _ridge(p: Vector2) -> float:
	# Piecewise crest segments and asymmetric fractured shoulders, not one
	# Gaussian latitude belt. Limits are source geometry, not shader fake hills.
	var summits := [Vector3(1180,490,2.3),Vector3(1450,640,3.0),Vector3(1720,485,3.7),Vector3(1930,685,2.15),Vector3(2220,495,3.05),Vector3(2440,720,1.4)]
	var result := 0.0
	for i in range(1,summits.size()):
		var a := Vector2(summits[i-1].x,summits[i-1].y)
		var b := Vector2(summits[i].x,summits[i].y)
		var ab := b-a
		var t := clampf((p-a).dot(ab)/ab.length_squared(),0,1)
		var closest := a+ab*t
		var side := signf(ab.cross(p-closest))
		var shoulder := 195.0 if side>0 else 280.0
		var across := p.distance_to(closest)/shoulder
		var profile := maxf(1.0-pow(across,.78),0)
		var crest := lerpf(summits[i-1].z,summits[i].z,t)
		var end_taper := smoothstep(-70,0,(p-a).dot(ab.normalized()))*(1.0-smoothstep(ab.length(),ab.length()+70,(p-a).dot(ab.normalized())))
		var broken := .87+.13*sin((p.x+.62*p.y)/51.0)
		result = maxf(result,crest*profile*end_taper*broken)
	# Real narrow drainage cuts on the south-facing flank, centimetres to .4m.
	var envelope := smoothstep(560,690,p.y)*(1.0-smoothstep(810,930,p.y))
	var drainage := pow(maxf(cos((p.x+.47*p.y)/63),0),10)*.42*envelope
	return maxf(result-drainage,0)

func _height(p: Vector2) -> float:
	var base := _base_height(p)
	var bank := _bank(p)
	if bank<0:
		# Actual submerged bed is present under the transparent water sheet.
		# Channel bed depth is metres, distinct from horizontal shore distance.
		return -.05-1.10*smoothstep(0,95,-bank)
	var ridge_roi := smoothstep(1020,1130,p.x)*(1.0-smoothstep(2450,2570,p.x))*(1.0-smoothstep(890,1020,p.y))
	var ridge_height := _ridge(p)+.08
	return lerpf(base,ridge_height,ridge_roi*(1.0-_protection(p)))

func _local_mesh(center: Vector2) -> ArrayMesh:
	var minimum := ((center-Vector2(1100,1050)).max(Vector2.ZERO)/STEP).floor()*STEP
	var maximum := ((center+Vector2(1100,1050)).min(WORLD_PX)/STEP).ceil()*STEP
	var columns := roundi((maximum.x-minimum.x)/STEP)
	var rows := roundi((maximum.y-minimum.y)/STEP)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.resize((columns+1)*(rows+1))
	normals.resize(vertices.size())
	uv.resize(vertices.size())
	for y in range(rows+1):
		for x in range(columns+1):
			var index := y*(columns+1)+x
			var p := minimum+Vector2(x,y)*STEP
			vertices[index] = _point(p,_height(p))
			uv[index] = p/WORLD_PX
	for y in rows:
		for x in columns:
			var a := y*(columns+1)+x
			var b := a+1
			var c := a+columns+1
			var d := c+1
			indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	for i in range(0,indices.size(),3):
		var a := indices[i]
		var b := indices[i+1]
		var c := indices[i+2]
		var n := (vertices[c]-vertices[a]).cross(vertices[b]-vertices[a])
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size(): normals[i] = normals[i].normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _load_pbr() -> bool:
	for spec in ASSETS:
		var id: String = spec["id"]
		var source_json := SOURCES+id+"/SOURCE.json"
		if not FileAccess.file_exists(source_json):
			_fail("Missing verified SOURCE.json: "+source_json)
			return false
		var registered := _read_json(source_json)
		if registered.get("asset","")!=id or registered.get("license","")!="CC0-1.0" or absf(float(registered.get("physical_width_m",0))-float(spec["meters"]))>.001:
			_fail("Verified tileable source identity/license/metre scale mismatch: "+id)
			return false
		for suffix in ["diff","nor_gl","arm"]:
			var path := SOURCES+id+"/"+id+"_"+String(suffix)+"_2k.jpg"
			var channel_record: Dictionary = {}
			for item in registered.get("channels",[]):
				if item.get("channel","")==suffix: channel_record = item
			if channel_record.get("path","")!=path or channel_record.get("md5_verified",false)!=true or String(channel_record.get("sha256","")).to_lower()!=FileAccess.get_sha256(path).to_lower():
				_fail("Registered channel provenance/hash mismatch: "+path)
				return false
			var image := Image.load_from_file(path)
			if image==null or image.is_empty():
				_fail("Missing registered PBR image: "+path)
				return false
			var error := image.generate_mipmaps()
			if error!=OK or image.get_mipmap_count()==0:
				_fail("Real image mipchain generation failed: "+path)
				return false
			material_textures[id+"_"+String(suffix)] = ImageTexture.create_from_image(image)
			texture_audit.append({"path":path,"sha256":FileAccess.get_sha256(path),"source_json":source_json,"source_json_sha256":FileAccess.get_sha256(source_json),"asset":id,"tile_width_m":spec["meters"],"size":[image.get_width(),image.get_height()],"actual_mipmap_count":image.get_mipmap_count(),"mip_method":"Image.generate_mipmaps then ImageTexture, independent from frozen imports","color_space":"sRGB source_color" if suffix=="diff" else "linear data", "arm_channels":"R ambient occlusion / G roughness / B metallic" if suffix=="arm" else "not ARM"})
	return true

func _bank_shader() -> String:
	var text := "float bank(vec2 p){float bw=mix(108.,82.,smoothstep(1730.,1790.,p.y));float d=4355.+55.*sin(p.y/285.)-125.*exp(-pow((p.y-1290.)/116.,2.))-135.*exp(-pow((p.y-1730.)/bw,2.))-p.x;"
	for channel in contract["waterways"]:
		var points: Array = channel["points"]
		var radii: Array = channel["radii"]
		for i in range(1,points.size()):
			text += "{vec2 a=vec2(%f,%f),b=vec2(%f,%f);vec2 ab=b-a;float t=clamp(dot(p-a,ab)/dot(ab,ab),0.,1.);d=min(d,length(p-mix(a,b,t))-mix(%f,%f,t));}"%[points[i-1][0],points[i-1][1],points[i][0],points[i][1],radii[i-1],radii[i]]
	return text+"return d;}"

func _compiled(code: String,required: Array,label: String) -> Shader:
	var shader := Shader.new()
	shader.code = code
	var found: Array = []
	for item in shader.get_shader_uniform_list(): found.append(String(item["name"]))
	var good := true
	for name in required: good = good and found.has(name)
	compile_audit.append({"label":label,"required":required,"actual":found,"valid":good})
	if not good:
		_fail("Native shader compiler/reflection rejected "+label)
		return null
	return shader

func _surface_material() -> ShaderMaterial:
	var code := "shader_type spatial;render_mode cull_disabled,depth_draw_opaque;uniform sampler2D topo:filter_linear;uniform bool detail_normals=true;varying vec3 xyz;varying vec3 geometric_n;void vertex(){xyz=VERTEX;geometric_n=NORMAL;}"
	for spec in ASSETS:
		var id: String = spec["id"]
		code += "uniform sampler2D %s_diff:source_color,repeat_enable,filter_linear_mipmap;uniform sampler2D %s_nor_gl:hint_normal,repeat_enable,filter_linear_mipmap;uniform sampler2D %s_arm:repeat_enable,filter_linear_mipmap;"%[id,id,id]
	code += _bank_shader()+"""
vec3 tri(sampler2D image,vec3 p,vec3 w,float meters){return texture(image,p.zy/meters).rgb*w.x+texture(image,p.xz/meters).rgb*w.y+texture(image,p.xy/meters).rgb*w.z;}
vec3 detail(sampler2D image,vec3 p,vec3 g,vec3 w,float meters){
 vec3 nx=texture(image,p.zy/meters).rgb*2.-1.;vec3 ny=texture(image,p.xz/meters).rgb*2.-1.;vec3 nz=texture(image,p.xy/meters).rgb*2.-1.;
 vec3 dx=vec3(0.,nx.y,nx.x);vec3 dy=vec3(ny.x,0.,ny.y);vec3 dz=vec3(nz.x,nz.y,0.);
 vec3 q=dx*w.x+dy*w.y+dz*w.z;return q-g*dot(q,g);
}
void fragment(){
 vec2 p=UV*vec2(4608.,3072.);vec3 g=normalize(geometric_n);vec3 w=pow(abs(g),vec3(5.));w/=max(dot(w,vec3(1.)),.0001);
 float b=bank(p);float road=texture(topo,UV).g;
 float rock=smoothstep(.13,.43,1.-g.y)*smoothstep(.18,1.2,xyz.y);
 float north=(1.-smoothstep(840.,1120.,p.y))*smoothstep(.23,1.5,xyz.y);rock=max(rock,north*.83);
 float forest=(.5+.5*sin(xyz.x*.39+xyz.z*.18))*(.5+.5*cos(xyz.z*.43-xyz.x*.11));forest=smoothstep(.29,.64,forest)*.72*(1.-road);
 float wet=1.-smoothstep(3.,58.,b);wet=max(wet,1.-smoothstep(-.12,.04,xyz.y));
 vec3 grass=tri(leafy_grass_diff,xyz,w,2.);vec3 soil=tri(forest_ground_04_diff,xyz,w,3.2);vec3 stone=tri(rock_01_diff,xyz,w,1.5);vec3 mud=tri(brown_mud_03_diff,xyz,w,1.3);
 vec3 color=mix(grass,soil,forest);color=mix(color,stone,rock);color=mix(color,mud,wet*.86);
 // Route is scan-backed compacted litter/earth, not a painted yellow ribbon.
 color=mix(color,mix(soil,mud,.18)*.88,road*.90);
 vec3 arm=mix(tri(leafy_grass_arm,xyz,w,2.),tri(forest_ground_04_arm,xyz,w,3.2),forest);arm=mix(arm,tri(rock_01_arm,xyz,w,1.5),rock);arm=mix(arm,tri(brown_mud_03_arm,xyz,w,1.3),wet*.86);
 arm=mix(arm,tri(forest_ground_04_arm,xyz,w,3.2),road*.90);
 vec3 q=mix(detail(leafy_grass_nor_gl,xyz,g,w,2.),detail(forest_ground_04_nor_gl,xyz,g,w,3.2),forest);q=mix(q,detail(rock_01_nor_gl,xyz,g,w,1.5),rock);q=mix(q,detail(brown_mud_03_nor_gl,xyz,g,w,1.3),wet*.86);q=mix(q,detail(forest_ground_04_nor_gl,xyz,g,w,3.2)*.35,road*.90);
 vec3 wn=normalize(g+(detail_normals?q:vec3(0.))*.70);NORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(wn,0.)).xyz);
 ALBEDO=color;AO=mix(1.,arm.r,.60);ROUGHNESS=clamp(arm.g,.22,.98);METALLIC=0.;SPECULAR=.35;
}
"""
	var shader := _compiled(code,["topo","detail_normals","rock_01_nor_gl","leafy_grass_arm","forest_ground_04_diff","brown_mud_03_arm"],"true_tileable_pbr")
	if shader==null: return null
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("topo",topology)
	for name in material_textures: material.set_shader_parameter(name,material_textures[name])
	return material

func _water_material() -> ShaderMaterial:
	var code := "shader_type spatial;render_mode cull_disabled,blend_mix,depth_draw_never;uniform bool water_guard=true;varying vec3 xyz;void vertex(){xyz=VERTEX;}"+_bank_shader()+"""
void fragment(){
 vec2 p=UV*vec2(4608.,3072.);float shore=bank(p);if(shore>=0.||!water_guard){discard;}
 float bed_depth=.05+1.10*smoothstep(0.,95.,-shore);
 // Global metre phases stay continuous across curve-segment ownership.
 vec2 q=vec2(.034*cos(xyz.x*5.7+xyz.z*1.3)+.018*cos(xyz.z*11.9),.045*cos(xyz.z*6.9-xyz.x*1.8));
 vec3 wn=normalize(vec3(-q.x,1.,-q.y));NORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(wn,0.)).xyz);
 ALBEDO=mix(vec3(.22,.34,.29),vec3(.085,.24,.28),smoothstep(.03,.70,bed_depth));
 ROUGHNESS=.18;SPECULAR=.68;METALLIC=0.;ALPHA=mix(.34,.86,smoothstep(.05,1.1,bed_depth));
}
"""
	var shader := _compiled(code,["water_guard"],"lit_sky_bathymetric_water")
	if shader==null: return null
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _environment() -> Environment:
	if sky==null:
		sky = Sky.new()
		var material := ProceduralSkyMaterial.new()
		material.sky_top_color = Color(.23,.40,.60)
		material.sky_horizon_color = Color(.71,.77,.80)
		material.ground_bottom_color = Color(.21,.22,.18)
		material.ground_horizon_color = Color(.62,.66,.64)
		material.sky_energy_multiplier = .8
		sky.sky_material = material
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	settings.sky = sky
	# Direct illumination, ambient colour/energy and camera are fifth constants.
	# Only reflected radiance was absent; use documented native procedural sky.
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(.90,.94,1.0)
	settings.ambient_light_energy = .54
	settings.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	return settings

func _viewport(center: Vector2,mesh: ArrayMesh) -> SubViewport:
	var view := SubViewport.new()
	view.size = CANVAS
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world := Node3D.new()
	view.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = _environment()
	world.add_child(environment)
	var terrain := MeshInstance3D.new()
	terrain.mesh = mesh
	terrain.material_override = surface
	# Real terrain self-shadow is common to both normal/PBR diagnostic states.
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	world.add_child(terrain)
	var river := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = WORLD
	river.mesh = plane
	river.position.y = -.025
	river.material_override = water
	river.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(river)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-34,0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	light.shadow_bias = .02
	light.shadow_normal_bias = .08
	light.directional_shadow_max_distance = 95.0
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	world.add_child(light)
	var target := _point(center,0)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CANVAS.y/PPM
	camera.position = target+Vector3(0,36,36)
	world.add_child(camera)
	camera.look_at(target)
	camera.current = true
	return view

func _sync() -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw

func _capture(view: SubViewport,path: String) -> Image:
	await _sync()
	var image := view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_size()!=CANVAS or image.save_png(path)!=OK:
		_fail("Actual viewport readback/save failed: "+path)
		return null
	return image

func _run() -> void:
	# No inherited SceneTree builder is instantiated and no fifth write hook
	# exists anywhere in this file. A completed preview remains non-production.
	if DisplayServer.get_name()=="headless":
		_fail("This is actual GPU preview, not a headless substitute")
		return
	var manifest := _read_json(BASE+"manifest.json")
	if String(manifest.get("executed_builder_sha256","")).to_lower()!=BASE_EXECUTED_SHA:
		_fail("Frozen fifth executed-source binding mismatch")
		return
	contract = _read_json(BASE+"source_contract.json")
	heights = FileAccess.get_file_as_bytes(BASE+"height_grid.rf").to_float32_array()
	if heights.size()!=(COLS+1)*(ROWS+1) or contract.get("routes",[]).size()!=30:
		_fail("Actual frozen fifth height/routes unavailable")
		return
	var source_topology := Image.load_from_file(BASE+"source_topology.png")
	if source_topology==null:
		_fail("Frozen source topology missing")
		return
	topology = ImageTexture.create_from_image(source_topology)
	if not _load_pbr(): return
	surface = _surface_material()
	water = _water_material()
	if failed or surface==null or water==null: return
	_prepare_routes()
	DirAccess.make_dir_recursive_absolute(OUT)
	_write_json(OUT+"result.json",{"status":"PREVIEW_BUILD_IN_PROGRESS","production_approved":false})
	var baseline := Image.load_from_file(BASE+"visual.png")
	var evidence: Array[Dictionary] = []
	for entry in CASES:
		var center: Vector2 = entry["center"]
		var prefix := OUT+String(entry["id"])+"_"
		var mesh := _local_mesh(center)
		var view := _viewport(center,mesh)
		surface.set_shader_parameter("detail_normals",true)
		var first := await _capture(view,prefix+"pbr.png")
		var repeat := await _capture(view,prefix+"pbr_repeat.png")
		if failed or first==null or repeat==null: return
		if first.get_data()!=repeat.get_data():
			_fail("Non-reproducible actual PBR viewport: "+String(entry["id"]))
			return
		surface.set_shader_parameter("detail_normals",false)
		if await _capture(view,prefix+"normal_disabled_control.png")==null: return
		var crop := Rect2i(Vector2i(center)-CANVAS/2,CANVAS)
		if baseline!=null and Rect2i(Vector2i.ZERO,baseline.get_size()).encloses(crop): baseline.get_region(crop).save_png(prefix+"fifth_baseline.png")
		var arrays := mesh.surface_get_arrays(0)
		evidence.append({"case":entry["id"],"source_center":[center.x,center.y],"canvas":[CANVAS.x,CANVAS.y],"actual_orthographic_size":float(CANVAS.y)/PPM,"pixels_per_meter":PPM,"camera_offset_m":[0,36,36],"target_ground_y":0,"source_height_spacing_px":6,"actual_vertices":arrays[Mesh.ARRAY_VERTEX].size(),"actual_triangles":arrays[Mesh.ARRAY_INDEX].size()/3,"pbr_repeat_exact":true,"normal_control":"only detail_normals false; same geometry, base self-shadow, light, sky and camera","terrain_self_shadow":"ON in both states; not a native-prop shadow difference","height_preview_not_navigation_approval":true,"tree_building_bodies_not_baked":true})
		view.queue_free()
		await process_frame
	_write_json(OUT+"result.json",{"status":"LOCAL_VISUAL_CANDIDATES_REQUIRE_PRODUCER_REVIEW","production_approved":false,"whole_map_pass":false,"fifth_inputs_read_only":true,"fifth_executed_sha256":BASE_EXECUTED_SHA,"preview_executed_sha256":FileAccess.get_sha256(get_script().resource_path),"baseline_mesh_sha256":FileAccess.get_sha256(BASE+"terrain_mesh.res"),"baseline_height_sha256":FileAccess.get_sha256(BASE+"height_grid.rf"),"texture_audit":texture_audit,"compiler_gates":compile_audit,"cases":evidence,"environment_change":"native ProceduralSky reflected radiance, ambient .54/direct1.05 unchanged","geology_change":"piecewise asymmetric ridge segments and incised south drainage, route/source foundation protection; local only","water_change":"actual submerged bed in mesh and transparent normally-lit static water, no horizontal-bank-distance labelled as metre depth","sync":"8 process frames plus RenderingServer.frame_post_draw before every actual readback"})
	surface = null
	water = null
	sky = null
	topology = null
	material_textures.clear()
	for frame in 8: await process_frame
	print("[V14SixthPreview] LOCAL_PREVIEWS_EXPORTED, no production pass; "+OUT)
	quit(0)
