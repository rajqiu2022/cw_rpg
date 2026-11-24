extends RefCounted

## Original native asset prototype. The detailed central gate is an existing
## project-generated PNG, NOT a native mesh reconstructed by this script.
const SURFACE := preload("res://scripts/dev/luoyang_modular_v3_surface.gd")
const GATE_SOURCE := "res://art/maps/luoyang_modular_v3/source/courtyard_wall_gate_v3.png"
const SOURCE_PATCHES := {"plaster_left":Rect2i(225,455,485,157),"plaster_right":Rect2i(1190,455,520,157),"brick":Rect2i(220,628,515,51),"tile":Rect2i(292,405,9,12)}
const TILE_INTERIOR_RGBA_SHA := "bf09597d4ba672a02c32267c497b24b939670d31d5b1396eab0a58a9083a006f"
const SOURCE_PINS := {
	GATE_SOURCE:"dbe22e8e6072cbfee28fd5fb01cbc393f532de12ed9f356e7ec269fff5248221",
	"res://scripts/dev/luoyang_modular_v3_surface.gd":"76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52",
	"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d",
	"res://art/maps/luoyang_modular_v3/source/generation_record.json":"55c9a621ff125b736db2da85350a208a08f530e81bea1d2c11dc165cf76858c5",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/SOURCE.json":"33b0d87d8a159028397b6a7a112b66106e5b78d87130d385a26f7471eed5487a",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg":"fe9013368539b5604602e64bfa48bef1a2a4c452fcb6894868fb556d0b14501c",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg":"70427a2c81f85c0e1ee4a147e273d028c3d0188bad2583f2509d6df9a3d55b89",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg":"a954de58336738e6f963466f1453202ef7e186bd6492106c3b989c39f0d2e23c"
}
var surface: SURFACE
var error := ""
var materials: Dictionary = {}
var buckets: Dictionary = {}
var counts: Dictionary = {}
var patch_observations: Dictionary = {}
var gate_texture: ImageTexture

func prepare() -> bool:
	for path: String in SOURCE_PINS:
		if FileAccess.get_sha256(path).to_lower() != SOURCE_PINS[path]:
			error = "Native join original/registered material source changed: " + path
			return false
	surface = SURFACE.new()
	if not surface.load_sources():
		error = surface.error
		return false
	var gate: Image = Image.load_from_file(GATE_SOURCE)
	if gate == null or gate.get_size() != Vector2i(1942,809):
		error = "Actual original detailed gate image missing/wrong size."
		return false
	gate.convert(Image.FORMAT_RGBA8)
	for name: String in SOURCE_PATCHES:
		var rect: Rect2i = SOURCE_PATCHES[name]
		var minimum_alpha := 255
		for y in range(rect.position.y,rect.end.y):
			for x in range(rect.position.x,rect.end.x):
				minimum_alpha = mini(minimum_alpha,int(round(gate.get_pixel(x,y).a*255.)))
		patch_observations[name] = {"source_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"actual_minimum_alpha":minimum_alpha,"usage":"Original project image RGB on NEW opaque geometry; not a licensed scan, no source edit or gate-hole sampling"}
		if name == "tile":
			var context := HashingContext.new()
			if context.start(HashingContext.HASH_SHA256) != OK or context.update(gate.get_region(rect).get_data()) != OK:
				error = "Cannot hash actual single-tile interior RGB source."
				return false
			var actual_sha: String = context.finish().hex_encode()
			patch_observations[name]["source_sha256_pin"] = SOURCE_PINS[GATE_SOURCE]
			patch_observations[name]["rgba_sha256_pin"] = TILE_INTERIOR_RGBA_SHA
			patch_observations[name]["actual_rgba_sha256"] = actual_sha
			patch_observations[name]["mapping"] = "Per-native-tile local UV; source barrel interior only, excludes tile rim/course joint/roof silhouette"
			if actual_sha != TILE_INTERIOR_RGBA_SHA or minimum_alpha != 252:
				error = "Actual single-tile interior differs from measured source pin."
				return false
		if minimum_alpha < 240:
			error = "Gate material patch contains a hole/transparent exterior: " + name
			return false
	gate_texture = ImageTexture.create_from_image(gate)
	for row: Array in [["brick",Color(.32,.325,.31),.18],["mortar",Color(.40,.39,.35),.09],["plaster",Color(.68,.665,.62),.055],["plaster_edge",Color(.47,.445,.39),.08],["tile",Color(.245,.25,.24),.20],["tile_rim",Color(.29,.295,.28),.13]]:
		materials[row[0]] = _material(row[1],row[2],row[0])
		if materials[row[0]] == null: return false
	return true

func _material(tint: Color, grain: float, role: String) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform sampler2D original_stone:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D project_gate_rgb:source_color,filter_linear,repeat_disable;
uniform vec4 project_patch_px=vec4(0.);
uniform int project_patch_mode=0;
uniform vec3 authored_tint;
uniform float authored_grain;
varying vec3 p;varying vec3 source_n;varying vec3 world_n;
void vertex(){p=VERTEX;source_n=NORMAL;world_n=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);}
vec3 sample3(sampler2D t,vec3 q,vec3 w){return texture(t,q.zy).rgb*w.x+texture(t,q.xz).rgb*w.y+texture(t,q.xy).rgb*w.z;}
void fragment(){
 vec3 w=pow(abs(source_n),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 vec3 stone=sample3(original_stone,p/1.8,w);
 vec3 fine=sample3(original_stone,p/.19+vec3(.23,.61,.47),w);
 vec3 arm=sample3(registered_arm,p/1.5,w);
 float luma=dot(stone,vec3(.2126,.7152,.0722));
 float micro=dot(fine,vec3(.2126,.7152,.0722));
 vec3 face=authored_tint;
 if(project_patch_mode>0){
  vec2 q=vec2(p.x/5.+.5,1.-(p.y-.5)/1.55);
  if(project_patch_mode==1&&abs(source_n.x)>.5)q.x=p.z/5.+.5;
  if(project_patch_mode==2)q=vec2((abs(source_n.x)>.5?p.z:p.x)/5.+.5,1.-fract(max(p.y,0.)/.50));
  if(project_patch_mode==3)q=UV;
  // Explicit interior patch/clamp, linear mip0 sampling. Never sample the
  // source door hole/exterior or transfer source alpha onto the new asset.
  vec2 px=project_patch_px.xy+vec2(2.)+clamp(q,vec2(0.),vec2(1.))*(project_patch_px.zw-vec2(4.));
  face=mix(authored_tint,texture(project_gate_rgb,px/vec2(1942.,809.)).rgb,.86);
 }
 ALBEDO=face*(.97+(luma-.5)*authored_grain*.35+(micro-.5)*.055);
 ROUGHNESS=.91+(arm.g-.5)*.035;AO=mix(1.,arm.r,.06);SPECULAR=.12;
 // Native flat/chamfer normals are authoritative; microdetail uses a local
 // shading basis, not missing mesh tangents or geometry displacement.
 vec3 n=normalize(world_n);vec3 d=sample3(registered_normal,p/1.5,w)-vec3(.5);
 vec3 tangent=abs(n.y)<.8?normalize(cross(vec3(0.,1.,0.),n)):vec3(1.,0.,0.);
 vec3 bitangent=normalize(cross(n,tangent));
 NORMAL=normalize((VIEW_MATRIX*vec4(normalize(n+tangent*d.x*.025+bitangent*d.y*.025),0.)).xyz);
}
"""
	var material := ShaderMaterial.new()
	var uniforms: Dictionary = {}
	for uniform: Dictionary in shader.get_shader_uniform_list(): uniforms[String(uniform["name"])] = true
	for name: String in ["original_stone","registered_normal","registered_arm","project_gate_rgb","project_patch_px","project_patch_mode","authored_tint","authored_grain"]:
		if not uniforms.has(name):
			error = "Native asset shader reflection/compile missing: " + name
			return null
	material.shader = shader
	material.set_shader_parameter("original_stone",surface.textures["stone"])
	material.set_shader_parameter("registered_normal",surface.textures["nor_gl"])
	material.set_shader_parameter("registered_arm",surface.textures["arm"])
	material.set_shader_parameter("project_gate_rgb",gate_texture)
	var patch_name := ""
	var mode := 0
	if role == "plaster":
		patch_name = "plaster_left"
		mode = 1
	elif role in ["brick","mortar"]:
		patch_name = "brick"
		mode = 2
	elif role in ["tile","tile_rim"]:
		patch_name = "tile"
		mode = 3
	if patch_name != "":
		var rect: Rect2i = SOURCE_PATCHES[patch_name]
		material.set_shader_parameter("project_patch_px",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
	material.set_shader_parameter("project_patch_mode",mode)
	material.set_shader_parameter("authored_tint",Vector3(tint.r,tint.g,tint.b))
	material.set_shader_parameter("authored_grain",grain)
	return material

func build(side: String) -> ArrayMesh:
	if side not in ["left","right"] or materials.is_empty():
		error = "Explicit left/right prepared native join required."
		return null
	buckets.clear()
	counts = {"brick_blocks":0,"barrel_tiles":0,"pan_tiles":0,"tile_end_rims":0,"plaster_faces":0,"crack_paths":0,"end_piers":0,"return_walls":0}
	# X length remains centred on the original wing transform. Wall front is
	# deliberately deeper and its silhouette NEW; no old-alpha/bounds promise.
	_box(Vector3(5.,2.05,.96),Vector3(0,1.025,.20),"mortar")
	_courses(-2.5,2.5,0.,.50,.20,1.02,3,.52)
	_courses(-2.5,2.5,.50,2.05,.20,.98,10,.46)
	_plaster(side)
	# Real projected cornice layers and undersized bed joint, not a flat cap.
	_box(Vector3(5.10,.075,1.09),Vector3(0,2.055,.20),"brick")
	_box(Vector3(5.15,.055,1.16),Vector3(0,2.12,.20),"mortar")
	_roof(-2.62,2.62,.20)
	var outer: float = -2.38 if side == "left" else 2.38
	_pier(outer,.20)
	_end_wrap(side)
	# A short rearward return remains outside the central door/main avenue.
	_box(Vector3(.43,1.95,.66),Vector3(outer,.975,-.59),"mortar")
	for row in range(3):
		_bevel_box(Vector3(.49,.155,.70),Vector3(outer,.0825+row*.166,-.59),.014,"brick")
	_box(Vector3(.52,.10,.75),Vector3(outer,2.,-.59),"brick")
	counts["return_walls"] += 1
	# Small coping tiles continue around the outer corner, not into the gate.
	for piece in range(4):
		_coping(outer,-.88+piece*.18)
	var mesh := ArrayMesh.new()
	for role: String in buckets:
		var bucket: Dictionary = buckets[role]
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = bucket["v"]
		arrays[Mesh.ARRAY_NORMAL] = bucket["n"]
		arrays[Mesh.ARRAY_TEX_UV] = bucket["uv"]
		arrays[Mesh.ARRAY_INDEX] = bucket["i"]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material: ShaderMaterial = materials[role].duplicate() as ShaderMaterial
		if role == "plaster" and side == "right":
			var rect: Rect2i = SOURCE_PATCHES["plaster_right"]
			material.set_shader_parameter("project_patch_px",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
		mesh.surface_set_material(mesh.get_surface_count()-1,material)
	return mesh

func _courses(x0: float,x1: float,y0: float,y1: float,z: float,depth: float,rows: int,pitch: float) -> void:
	var row_height: float = (y1-y0)/rows
	for row in range(rows):
		var start: float = x0-(pitch*.5 if row%2 else 0.)
		while start < x1:
			var lo: float = maxf(start,x0)
			var hi: float = minf(start+pitch,x1)
			if hi-lo > .035:
				_bevel_box(Vector3(hi-lo-.009,row_height-.009,depth),Vector3((lo+hi)*.5,y0+(row+.5)*row_height,z),.012,"brick")
				counts["brick_blocks"] += 1
			start += pitch

func _plaster(side: String) -> void:
	# Authored angular, stepped fractures expose actual underlying brick. These
	# are geometry contours, neither smooth noise bands nor shader cutouts.
	var edge := PackedVector2Array([
		Vector2(-2.5,.52),Vector2(-2.29,.55),Vector2(-2.24,.66),Vector2(-2.12,.64),Vector2(-2.07,.86),Vector2(-1.91,.82),Vector2(-1.94,.97),Vector2(-1.77,.95),Vector2(-1.72,.72),Vector2(-1.59,.73),Vector2(-1.54,.57),Vector2(-1.16,.54),Vector2(-1.11,.62),Vector2(-.94,.59),Vector2(-.87,.53),Vector2(-.49,.52),Vector2(-.42,.66),Vector2(-.31,.65),Vector2(-.27,.80),Vector2(-.08,.76),Vector2(.01,.61),Vector2(.19,.62),Vector2(.26,.53),Vector2(.70,.54),Vector2(.76,.64),Vector2(.89,.63),Vector2(.92,.86),Vector2(1.06,.90),Vector2(1.03,1.05),Vector2(1.21,1.01),Vector2(1.27,.85),Vector2(1.45,.82),Vector2(1.49,.63),Vector2(1.63,.65),Vector2(1.72,.54),Vector2(2.11,.52),Vector2(2.18,.62),Vector2(2.33,.59),Vector2(2.38,.53),Vector2(2.5,.54)
	])
	if side == "right":
		for j in range(edge.size()):
			edge[j] = Vector2(-edge[j].x,edge[j].y+(.045 if j%3 == 0 else -.015))
		edge.reverse()
	var polygon: PackedVector2Array = edge.duplicate()
	polygon.append(Vector2(2.5,2.015))
	polygon.append(Vector2(-2.5,2.015))
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	if triangles.is_empty():
		error = "Authored plaster contour cannot triangulate."
		return
	var twice_area := 0.
	for j in range(polygon.size()):
		var next: int = (j+1)%polygon.size()
		twice_area += polygon[j].x*polygon[next].y-polygon[next].x*polygon[j].y
	var winding: float = 1. if twice_area > 0. else -1.
	for front: bool in [true,false]:
		var face_z: float = .705 if front else -.305
		var normal := Vector3.FORWARD if front else Vector3.BACK
		# Godot FORWARD=-Z; the exposed front here is +Z.
		normal = -normal
		for i in range(0,triangles.size(),3):
			_tri(Vector3(polygon[triangles[i]].x,polygon[triangles[i]].y,face_z),Vector3(polygon[triangles[i+1]].x,polygon[triangles[i+1]].y,face_z),Vector3(polygon[triangles[i+2]].x,polygon[triangles[i+2]].y,face_z),normal,"plaster")
		counts["plaster_faces"] += 1
		for j in range(edge.size()-1):
			var a := Vector3(edge[j].x,edge[j].y,face_z)
			var b := Vector3(edge[j+1].x,edge[j+1].y,face_z)
			var edge_direction: Vector3 = b-a
			var thickness_direction: Vector3 = -normal*.025
			var edge_normal: Vector3 = edge_direction.cross(thickness_direction).normalized()
			var polygon_outward := Vector3(edge_direction.y,-edge_direction.x,0.)*winding
			if edge_normal.dot(polygon_outward) < 0.: edge_normal = -edge_normal
			_quad(a,b,b+thickness_direction,a+thickness_direction,edge_normal,"plaster_edge")
	# Existing source plaster already carries irregular hairline damage.
	# Do not overlay evenly spaced native black zigzags.

func _end_wrap(side: String) -> void:
	# Close the exposed terminal plaster thickness without adding a new pier.
	# Side RGB uses the same metre-scale patch as the front, turned around Z.
	var outward: float = -1. if side == "left" else 1.
	var x: float = outward*2.502
	var bottom: float = .52 if side == "left" else .565
	_quad(Vector3(x,bottom,-.305),Vector3(x,bottom,.705),Vector3(x,2.015,.705),Vector3(x,2.015,-.305),Vector3(outward,0,0),"plaster")

func _coping(x: float,z: float) -> void:
	# Replace only the old .56 x .065 x .19 box envelope with a curved,
	# sealed coping tile. Same extrema, no taller/wider/longer return wall.
	var low := 2.0575
	var z0: float = z-.095
	var z1: float = z+.095
	for arc in range(8):
		var u0: float = arc/8.
		var u1: float = (arc+1)/8.
		var a := Vector3(x-.28+u0*.56,low+sin(u0*PI)*.065,z0)
		var b := Vector3(x-.28+u1*.56,low+sin(u1*PI)*.065,z0)
		var c := Vector3(b.x,b.y,z1)
		var d := Vector3(a.x,a.y,z1)
		var normal: Vector3 = -(b-a).cross(c-a).normalized()
		_quad_uv(a,b,c,d,normal,"tile",Vector2(u0,0),Vector2(u1,0),Vector2(u1,1),Vector2(u0,1))
		_tri(Vector3(x,low,z0),a,b,Vector3.FORWARD,"tile_rim",PackedVector2Array([Vector2(.5,0),Vector2(u0,1),Vector2(u1,1)]))
		_tri(Vector3(x,low,z1),d,c,Vector3.BACK,"tile_rim",PackedVector2Array([Vector2(.5,0),Vector2(u0,1),Vector2(u1,1)]))
	_quad_uv(Vector3(x-.28,low,z0),Vector3(x+.28,low,z0),Vector3(x+.28,low,z1),Vector3(x-.28,low,z1),Vector3.DOWN,"tile_rim",Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1))

func _pier(x: float,z: float) -> void:
	for row in range(4):
		_bevel_box(Vector3(.43,.145,1.12),Vector3(x,.0775+row*.151,z),.014,"brick")
	_box(Vector3(.33,1.42,1.02),Vector3(x,1.30,z),"plaster")
	_bevel_box(Vector3(.46,.095,1.16),Vector3(x,2.055,z),.015,"brick")
	counts["end_piers"] += 1

func _roof(x0: float,x1: float,center_z: float) -> void:
	var columns: int = int(ceil((x1-x0)/.205))
	var pitch: float = (x1-x0)/columns
	for wing in [-1.,1.]:
		for course in range(3):
			var near: float = center_z+wing*course*.265
			var far: float = center_z+wing*minf((course+1)*.265+.055,.85)
			for column in range(columns):
				var x: float = x0+(column+.5)*pitch
				_tile(x-.059,x+.059,near,far,center_z,true)
				counts["barrel_tiles"] += 1
				if column < columns-1:
					_tile(x+.054,x+pitch-.054,near,far,center_z,false)
					counts["pan_tiles"] += 1
				if course == 2:
					_rim(x,far,center_z,wing)
					counts["tile_end_rims"] += 1
	for section in range(12):
		var lo: float = x0+(x1-x0)*section/12.
		var hi: float = x0+(x1-x0)*(section+1)/12.-.008
		for arc in range(8):
			var a: float = PI*arc/8.
			var b: float = PI*(arc+1)/8.
			_quad_uv(Vector3(lo,2.455+sin(a)*.075,center_z+cos(a)*.075),Vector3(hi,2.455+sin(a)*.075,center_z+cos(a)*.075),Vector3(hi,2.455+sin(b)*.075,center_z+cos(b)*.075),Vector3(lo,2.455+sin(b)*.075,center_z+cos(b)*.075),Vector3(0,sin((a+b)*.5),cos((a+b)*.5)),"tile_rim",Vector2(0,arc/8.),Vector2(1,arc/8.),Vector2(1,(arc+1)/8.),Vector2(0,(arc+1)/8.))

func _roof_y(x: float,z: float,center_z: float) -> float:
	return 2.42-absf(z-center_z)*.34+pow(maxf(absf(x)-2.30,0.),2.)*.40

func _tile(x0: float,x1: float,z0: float,z1: float,center_z: float,barrel: bool) -> void:
	for across in range(6):
		for length_step in range(3):
			var points: Array[Vector3] = []
			for uv: Vector2 in [Vector2(across/6.,length_step/3.),Vector2((across+1)/6.,length_step/3.),Vector2((across+1)/6.,(length_step+1)/3.),Vector2(across/6.,(length_step+1)/3.)]:
				var x: float = lerpf(x0,x1,uv.x)
				var z: float = lerpf(z0,z1,uv.y)
				var curve: float = sin(uv.x*PI)*(.054 if barrel else -.012)
				points.append(Vector3(x,_roof_y(x,z,center_z)+curve+.014,z))
			var normal: Vector3 = -(points[1]-points[0]).cross(points[2]-points[0]).normalized()
			if normal.y < 0.: normal = -normal
			_quad_uv(points[0],points[1],points[2],points[3],normal,"tile",Vector2(across/6.,length_step/3.),Vector2((across+1)/6.,length_step/3.),Vector2((across+1)/6.,(length_step+1)/3.),Vector2(across/6.,(length_step+1)/3.))

func _rim(x: float,z: float,center_z: float,wing: float) -> void:
	var y: float = _roof_y(x,z,center_z)+.014
	for arc in range(8):
		var a: float = PI*arc/8.
		var b: float = PI*(arc+1)/8.
		_quad_uv(Vector3(x+cos(a)*.059,y+sin(a)*.054,z),Vector3(x+cos(b)*.059,y+sin(b)*.054,z),Vector3(x+cos(b)*.044,y+sin(b)*.039,z+wing*.004),Vector3(x+cos(a)*.044,y+sin(a)*.039,z+wing*.004),Vector3(0,0,wing),"tile_rim",Vector2(arc/8.,0),Vector2((arc+1)/8.,0),Vector2((arc+1)/8.,1),Vector2(arc/8.,1))

func _bevel_box(size: Vector3,center: Vector3,bevel: float,role: String) -> void:
	var low: float = center.y-size.y*.5
	var high: float = center.y+size.y*.5
	var rings: Array[PackedVector3Array] = []
	for spec: Vector2 in [Vector2(low,bevel),Vector2(low+bevel,0),Vector2(high-bevel,0),Vector2(high,bevel)]:
		var hx: float = size.x*.5-spec.y
		var hz: float = size.z*.5-spec.y
		rings.append(PackedVector3Array([Vector3(center.x-hx,spec.x,center.z-hz),Vector3(center.x+hx,spec.x,center.z-hz),Vector3(center.x+hx,spec.x,center.z+hz),Vector3(center.x-hx,spec.x,center.z+hz)]))
	_quad(rings[0][0],rings[0][1],rings[0][2],rings[0][3],Vector3.DOWN,role)
	_quad(rings[3][0],rings[3][1],rings[3][2],rings[3][3],Vector3.UP,role)
	for level in range(3):
		for side in range(4):
			var next: int = (side+1)%4
			var a: Vector3 = rings[level][side]
			var b: Vector3 = rings[level][next]
			var c: Vector3 = rings[level+1][next]
			var desired: Vector3 = -(b-a).cross(c-a).normalized()
			_quad(a,b,c,rings[level+1][side],desired,role)

func _box(size: Vector3,center: Vector3,role: String) -> void:
	var source := BoxMesh.new()
	source.size = size
	var arrays: Array = source.get_mesh_arrays()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0,indices.size(),3):
		_tri(v[indices[i]]+center,v[indices[i+1]]+center,v[indices[i+2]]+center,n[indices[i]],role)

func _quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,n: Vector3,role: String) -> void:
	_tri(a,b,c,n,role)
	_tri(a,c,d,n,role)

func _quad_uv(a: Vector3,b: Vector3,c: Vector3,d: Vector3,n: Vector3,role: String,ua: Vector2,ub: Vector2,uc: Vector2,ud: Vector2) -> void:
	_tri(a,b,c,n,role,PackedVector2Array([ua,ub,uc]))
	_tri(a,c,d,n,role,PackedVector2Array([ua,uc,ud]))

func _tri(a: Vector3,b: Vector3,c: Vector3,n: Vector3,role: String,uvs: PackedVector2Array = PackedVector2Array()) -> void:
	if not buckets.has(role): buckets[role] = {"v":PackedVector3Array(),"n":PackedVector3Array(),"uv":PackedVector2Array(),"i":PackedInt32Array()}
	var draw_uv: PackedVector2Array = uvs.duplicate() if uvs.size() == 3 else PackedVector2Array([Vector2(a.x,a.y),Vector2(b.x,b.y),Vector2(c.x,c.y)])
	if (b-a).cross(c-a).dot(n) > 0.:
		var swap: Vector3 = b
		b = c
		c = swap
		var uv_swap: Vector2 = draw_uv[1]
		draw_uv[1] = draw_uv[2]
		draw_uv[2] = uv_swap
	var bucket: Dictionary = buckets[role]
	var points: Array[Vector3] = [a,b,c]
	for index in range(3):
		var p: Vector3 = points[index]
		bucket["i"].append(bucket["v"].size())
		bucket["v"].append(p)
		bucket["n"].append(n.normalized())
		bucket["uv"].append(draw_uv[index])

func release() -> void:
	buckets.clear()
	materials.clear()
	gate_texture = null
	if surface != null: surface.release()
	surface = null
