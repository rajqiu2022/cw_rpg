extends RefCounted

# Honest project-native plant geometry: segmented bent culms and lance leaves.
# These are NOT claimed to be PolyHaven or photogrammetry.
const TREE_ROOT := "res://art/external/polyhaven/tree_small_02/"
static var leaf_textures: Dictionary={}
static var texture_evidence: Array[Dictionary]=[]

static func leaf_material() -> StandardMaterial3D:
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TREE_ROOT+"SOURCE.json"))
	if registry.get("license","")!="CC0-1.0": return null
	for channel: String in ["diff","nor_gl","arm"]:
		var name: String="textures/tree_small_02_leaves_"+channel+"_1k.jpg"
		var path: String=TREE_ROOT+name
		var sha: String=FileAccess.get_sha256(path)
		var verified:=false
		for record in registry["files"]:
			if record["name"]==name and String(record["sha256"]).to_lower()==sha.to_lower(): verified=true
		if not verified: return null
		if not leaf_textures.has(channel):
			var image: Image=Image.load_from_file(path)
			if image==null or image.generate_mipmaps()!=OK: return null
			leaf_textures[channel]=ImageTexture.create_from_image(image)
			texture_evidence.append({"path":path,"sha256":sha,"source_path":TREE_ROOT+"SOURCE.json","source_sha256":FileAccess.get_sha256(TREE_ROOT+"SOURCE.json"),"actual_mips":image.get_mipmap_count(),"license":"CC0-1.0","derivative_usage":"green internal vein tissue atlas UV [.315,.47] to [.365,.49] mapped onto native lance leaf geometry; NOT a bamboo scan/model, NOT a tileable atlas"})
	var value:=StandardMaterial3D.new()
	value.albedo_texture=leaf_textures["diff"]
	value.normal_enabled=true
	value.normal_texture=leaf_textures["nor_gl"]
	value.normal_scale=.55
	value.roughness_texture=leaf_textures["arm"]
	value.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	value.roughness=.90
	value.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	value.cull_mode=BaseMaterial3D.CULL_DISABLED
	return value

static func culm_material() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled;uniform float native_culm_contract=1.;varying vec3 p;void vertex(){p=VERTEX;}void fragment(){float longitudinal=.5+.5*sin(p.x*150.+p.z*119.+.5*sin(p.y*23.));float age=.5+.5*sin(p.x*31.+p.z*43.);float node=1.-smoothstep(.008,.022,abs(fract(p.y/.235)-.5)*.235);ALBEDO=mix(vec3(.20,.29,.085),vec3(.39,.40,.18),age*.55+longitudinal*.12);ALBEDO=mix(ALBEDO,vec3(.31,.33,.14),node*.65);ROUGHNESS=clamp(.76*native_culm_contract,0.,1.);SPECULAR=.24;}"""
	var result:=ShaderMaterial.new()
	result.shader=shader
	return result

static func timber_material() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;uniform float native_timber_contract=1.;varying vec3 p;void vertex(){p=VERTEX;}void fragment(){float grain=.5+.5*sin(p.x*92.+sin(p.y*12.+p.z*8.)*2.);float weather=.5+.5*sin(p.x*13.+p.y*17.);ALBEDO=mix(vec3(.17,.12,.068),vec3(.42,.31,.18),grain*.45+weather*.4);ROUGHNESS=clamp(.91*native_timber_contract,0.,1.);SPECULAR=.18;}"""
	var result:=ShaderMaterial.new()
	result.shader=shader
	return result

static func release() -> void:
	leaf_textures.clear()
	texture_evidence.clear()
static func material(color: Color) -> StandardMaterial3D:
	var value:=StandardMaterial3D.new()
	value.albedo_color=color
	value.roughness=.87
	value.cull_mode=BaseMaterial3D.CULL_DISABLED
	return value

static func tube(tool: SurfaceTool,points: PackedVector3Array,radius: float,sides: int=7) -> void:
	for i in range(points.size()-1):
		var forward: Vector3=(points[i+1]-points[i]).normalized()
		var x: Vector3=forward.cross(Vector3.FORWARD).normalized()
		var z: Vector3=forward.cross(x).normalized()
		for j in range(sides):
			var a: Vector3=x*cos(TAU*j/sides)*radius+z*sin(TAU*j/sides)*radius
			var b: Vector3=x*cos(TAU*(j+1)/sides)*radius+z*sin(TAU*(j+1)/sides)*radius
			for vertex in [points[i]+a,points[i+1]+a,points[i]+b,points[i]+b,points[i+1]+a,points[i+1]+b]: tool.add_vertex(vertex)

static func leaf(tool: SurfaceTool,start: Vector3,direction: Vector3,length: float,width: float,drop: float) -> void:
	var sideways: Vector3=direction.cross(Vector3.UP).normalized()
	if sideways.length_squared()<.01: sideways=Vector3.RIGHT
	var left:=PackedVector3Array()
	var right:=PackedVector3Array()
	for i in range(7):
		var t: float=i/6.
		var center: Vector3=start+direction*length*t+Vector3(0,-drop*t*t,0)
		var breadth: float=sin(PI*t)*width
		left.append(center-sideways*breadth)
		right.append(center+sideways*breadth)
	for i in range(6):
		# Actual first stored normals had leaf meanY=-.984, all10368 down.
		# Godot clockwise front face: reverse leaves only, preserve the culms.
		for corner in [Vector2i(i,-1),Vector2i(i+1,-1),Vector2i(i,1),Vector2i(i,1),Vector2i(i+1,-1),Vector2i(i+1,1)]:
			var t: float=corner.x/6.
			tool.set_uv(Vector2(.315+t*.050,.480+corner.y*.010*sin(PI*t)))
			tool.add_vertex(left[corner.x] if corner.y<0 else right[corner.x])

static func plant(kind: String,variant: int=0) -> ArrayMesh:
	var result:=ArrayMesh.new()
	var stem:=SurfaceTool.new()
	var foliage:=SurfaceTool.new()
	stem.begin(Mesh.PRIMITIVE_TRIANGLES)
	foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bamboo: bool=kind=="bamboo"
	var count: int=4 if bamboo else 9
	for i in range(count):
		var angle: float=i*2.399963+variant*.4
		var base:=Vector3(cos(angle)*.055,0,sin(angle)*.055)
		var high: float=(2.1+i*.19+variant*.12) if bamboo else (.62+(i%4)*.13)
		var drift:=Vector3(cos(angle)*.13,0,sin(angle)*.13)
		var points:=PackedVector3Array()
		for n in range(13):
			var t: float=n/12.
			points.append(base+Vector3(0,high*t,0)+drift*t*t)
		tube(stem,points,.017 if bamboo else .0035)
		if bamboo:
			# Culm nodes are discrete native collars, not a plain straight cylinder.
			for n in range(1,12):
				tube(stem,PackedVector3Array([points[n]-Vector3(0,.004,0),points[n]+Vector3(0,.004,0)]),.022,9)
			for n in range(3,11):
				var root: Vector3=points[n]
				var branch_dir:=Vector3(cos(angle+n*1.8),.16,sin(angle+n*1.8)).normalized()
				var end: Vector3=root+branch_dir*(.28+(n%3)*.1)
				tube(stem,PackedVector3Array([root,end]),.004)
				for j in range(9):
					var side: float=-1. if j%2==0 else 1.
					var dir: Vector3=(branch_dir+branch_dir.cross(Vector3.UP)*side*.65+Vector3(0,.1,0)).normalized()
					leaf(foliage,root.lerp(end,(j+1)/10.),dir,.16+(j%3)*.035,.016,.055)
		else:
			for n in range(3):
				var dir:=Vector3(cos(angle+n*2.),.30,sin(angle+n*2.)).normalized()
				leaf(foliage,points[4+n*2],dir,.30+n*.08,.018,.22)
			# Bent seed head uses real short tube geometry rather than one capsule.
			tube(stem,PackedVector3Array([points[-1],points[-1]+Vector3(.01,.085,.016),points[-1]+Vector3(.025,.16,.025)]),.01)
	stem.generate_normals()
	foliage.generate_normals()
	foliage.generate_tangents()
	stem.commit(result)
	foliage.commit(result)
	var leaves: StandardMaterial3D=leaf_material()
	if leaves==null: return null
	result.surface_set_material(0,culm_material() if bamboo else material(Color(.37,.31,.15)))
	result.surface_set_material(1,leaves)
	return result

static func waymarker() -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box:=BoxMesh.new()
	box.size=Vector3(.08,.75,.08)
	tool.append_from(box,0,Transform3D(Basis.IDENTITY,Vector3(0,.375,0)))
	box=BoxMesh.new()
	box.size=Vector3(.42,.16,.035)
	tool.append_from(box,0,Transform3D(Basis.IDENTITY,Vector3(.08,.57,0)))
	var arrow:=SurfaceTool.new()
	arrow.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [Vector3(.29,.49,.022),Vector3(.38,.57,.022),Vector3(.29,.65,.022)]: arrow.add_vertex(p)
	arrow.generate_normals()
	var arrow_mesh: ArrayMesh=arrow.commit()
	tool.append_from(arrow_mesh,0,Transform3D.IDENTITY)
	var mesh: ArrayMesh=tool.commit()
	mesh.surface_set_material(0,timber_material())
	return mesh

static func discovery() -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base:=BoxMesh.new()
	base.size=Vector3(.30,.17,.20)
	tool.append_from(base,0,Transform3D(Basis.IDENTITY,Vector3(0,.085,0)))
	var plank:=BoxMesh.new()
	plank.size=Vector3(.33,.022,.22)
	tool.append_from(plank,0,Transform3D(Basis.IDENTITY,Vector3(0,.18,0)))
	# Visible slats/ribs and bound material rolls, not a single solid brown box.
	for offset: float in [-.12,-.04,.04,.12]:
		plank=BoxMesh.new()
		plank.size=Vector3(.022,.155,.225)
		tool.append_from(plank,0,Transform3D(Basis.IDENTITY,Vector3(offset,.09,0)))
	var roll:=CylinderMesh.new()
	roll.top_radius=.03
	roll.bottom_radius=.03
	roll.height=.27
	roll.radial_segments=10
	for i in range(3): tool.append_from(roll,0,Transform3D(Basis(Vector3.FORWARD,PI*.5),Vector3(0,.225+i*.035,0)))
	var mesh: ArrayMesh=tool.commit()
	mesh.surface_set_material(0,timber_material())
	return mesh


