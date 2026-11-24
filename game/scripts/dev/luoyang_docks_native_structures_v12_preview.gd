extends RefCounted

## NEW authored structural assets only. No publisher/engine/production writes.
## Detailed cargo boxes keep the existing project PNG; native timber is
## original procedural authoring, NOT an imported CC0 wood/PBR or scan.
const BOX_SOURCE := "res://art/props/interactive/expansion_v1/chest_common_wood_v1.png"
const BOX_SHA := "c571bf698d5c12c29032501e83188fd49b46d35d26ba086910ce4a7b3f2396cc"
var error := ""
var materials: Dictionary={}
var buckets: Dictionary={}
var component_counts: Dictionary={}

func prepare() -> bool:
	if FileAccess.get_sha256(BOX_SOURCE).to_lower()!=BOX_SHA:
		error="Original detailed cargo chest source changed; no fallback."
		return false
	var image:=Image.load_from_file(BOX_SOURCE)
	if image==null or image.get_size()!=Vector2i(512,512) or image.get_format()!=Image.FORMAT_RGBA8:
		error="Exact original cargo512RGBA8 required."
		return false
	materials["timber"]=_wood(Color(.29,.225,.155))
	materials["dark_timber"]=_wood(Color(.205,.17,.125))
	materials["iron"]=_plain(Color(.15,.16,.155),.60)
	materials["canvas"]=_plain(Color(.145,.145,.125),.96)
	materials["rope"]=_plain(Color(.34,.305,.23),.94)
	return true

func _plain(color: Color,roughness: float) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=roughness
	return material

func _wood(color: Color) -> ShaderMaterial:
	# Shared material, structural planks/ribs supply detail. Never ALPHA,
	# discard, vertex displacement, or a fake scanned material claim.
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform vec3 timber_colour;
varying vec2 timber_uv;
void vertex(){timber_uv=UV;}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(fract(sin(dot(i,vec2(127.1,311.7)))*43758.5453),fract(sin(dot(i+vec2(1.,0.),vec2(127.1,311.7)))*43758.5453),f.x),mix(fract(sin(dot(i+vec2(0.,1.),vec2(127.1,311.7)))*43758.5453),fract(sin(dot(i+vec2(1.),vec2(127.1,311.7)))*43758.5453),f.x),f.y);}
void fragment(){float grain=(noise(timber_uv*vec2(3.,85.))-.5)*.065+(noise(timber_uv*vec2(12.,260.))-.5)*.025;ALBEDO=timber_colour+grain;ROUGHNESS=.88;SPECULAR=.15;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("timber_colour",Vector3(color.r,color.g,color.b))
	return material

func _reset() -> void:
	buckets.clear()
	component_counts.clear()

func _tri(a: Vector3,b: Vector3,c: Vector3,outside: Vector3,key: String,ua: Vector2=Vector2.ZERO,ub: Vector2=Vector2.RIGHT,uc: Vector2=Vector2.ONE) -> void:
	var normal: Vector3=(b-a).cross(c-a).normalized()
	if normal.length_squared()<.9 or outside.length_squared()<.000001:
		error="Native structural triangle has no outward normal."
		return
	if normal.dot(outside)<0.: normal=-normal
	# Godot front faces CLOCKWISE. Geometric cross must oppose outward normal.
	if (b-a).cross(c-a).dot(normal)>0.:
		var swap: Vector3=b;b=c;c=swap
		var uv_swap: Vector2=ub;ub=uc;uc=uv_swap
	if not buckets.has(key): buckets[key]={"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"uv":PackedVector2Array()}
	var row: Dictionary=buckets[key]
	for p: Vector3 in [a,b,c]: row.vertices.append(p);row.normals.append(normal)
	for p: Vector2 in [ua,ub,uc]: row.uv.append(p)
	buckets[key]=row

func _quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,outside: Vector3,key: String) -> void:
	_tri(a,b,c,outside,key,Vector2.ZERO,Vector2.RIGHT,Vector2.ONE)
	_tri(a,c,d,outside,key,Vector2.ZERO,Vector2.ONE,Vector2.DOWN)

func _box(center: Vector3,size: Vector3,key: String) -> void:
	var h:=size*.5
	var a:=center+Vector3(-h.x,-h.y,-h.z)
	var b:=center+Vector3(h.x,-h.y,-h.z)
	var c:=center+Vector3(h.x,h.y,-h.z)
	var d:=center+Vector3(-h.x,h.y,-h.z)
	var e:=center+Vector3(-h.x,-h.y,h.z)
	var f:=center+Vector3(h.x,-h.y,h.z)
	var g:=center+Vector3(h.x,h.y,h.z)
	var h0:=center+Vector3(-h.x,h.y,h.z)
	_quad(a,b,c,d,Vector3.FORWARD,key)
	_quad(e,h0,g,f,Vector3.BACK,key)
	_quad(a,d,h0,e,Vector3.LEFT,key)
	_quad(b,f,g,c,Vector3.RIGHT,key)
	_quad(a,e,f,b,Vector3.DOWN,key)
	_quad(d,c,g,h0,Vector3.UP,key)

func _beam(a: Vector3,b: Vector3,width: float,depth: float,key: String) -> void:
	var along: Vector3=(b-a).normalized()
	var reference:=Vector3.UP if absf(along.dot(Vector3.UP))<.95 else Vector3.RIGHT
	var cross:=along.cross(reference).normalized()*width*.5
	var other:=along.cross(cross.normalized()).normalized()*depth*.5
	var ring0:=PackedVector3Array([a-cross-other,a+cross-other,a+cross+other,a-cross+other])
	var ring1:=PackedVector3Array([b-cross-other,b+cross-other,b+cross+other,b-cross+other])
	for i in range(4):
		var j: int=(i+1)%4
		var outward: Vector3=((ring0[i]+ring0[j])*.5-a).normalized()
		_quad(ring0[i],ring1[i],ring1[j],ring0[j],outward,key)
	_quad(ring0[0],ring0[1],ring0[2],ring0[3],-along,key)
	_quad(ring1[0],ring1[1],ring1[2],ring1[3],along,key)

func _commit() -> ArrayMesh:
	if error!="": return null
	var mesh:=ArrayMesh.new()
	for key: String in buckets:
		var row: Dictionary=buckets[key]
		var arrays: Array=[]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=row.vertices
		arrays[Mesh.ARRAY_NORMAL]=row.normals
		arrays[Mesh.ARRAY_TEX_UV]=row.uv
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_material(mesh.get_surface_count()-1,materials[key])
	return mesh

func build_deck() -> ArrayMesh:
	if materials.size()!=5:
		error="prepare() must validate original inputs before native construction."
		return null
	_reset()
	# Existing dry-land footprint only:1.56mX by6.4mZ. Real thickness,
	# visible gaps, staggered joints, framed edges, under-beams and mooring posts.
	for i in range(20):
		var z: float=-3.04+float(i)*.32
		var split: float=.10 if i%3==0 else -.19 if i%3==1 else .28
		var left_width: float=split+.78-.007
		var right_width: float=.78-split-.007
		_box(Vector3((-.78+split-.007)*.5,.11,z),Vector3(left_width,.12,.303),"timber")
		_box(Vector3((split+.007+.78)*.5,.11,z),Vector3(right_width,.12,.303),"timber")
		for x in [-.54,.54]: _box(Vector3(x,.174,z),Vector3(.023,.006,.023),"iron")
	for x in [-.53,.53]: _box(Vector3(x,.018,0),Vector3(.17,.15,6.4),"dark_timber")
	for z in [-3.13,3.13]: _box(Vector3(0,.065,z),Vector3(1.56,.17,.14),"dark_timber")
	for z in [-2.5,2.5]:
		_box(Vector3(.61,.31,z),Vector3(.17,.62,.17),"dark_timber")
		_box(Vector3(.61,.61,z),Vector3(.27,.08,.23),"dark_timber")
		_box(Vector3(.61,.47,z),Vector3(.37,.075,.075),"dark_timber")
	component_counts={"real_deck_board_pieces":40,"iron_fasteners":40,"under_beams":2,"end_frames":2,"mooring_posts":2}
	return _commit()

func _hull_ring(t: float) -> PackedVector3Array:
	var z: float=-3.5+7.*t
	var width: float=.13+1.02*pow(sin(PI*t),.70)
	var lift: float=.24*pow(absf(2.*t-1.),3.)
	var ring:=PackedVector3Array()
	for p: Vector2 in [Vector2(-1.,.70),Vector2(-.91,.48),Vector2(-.70,.20),Vector2(-.36,.025),Vector2(0,-.055),Vector2(.36,.025),Vector2(.70,.20),Vector2(.91,.48),Vector2(1.,.70)]:
		ring.append(Vector3(p.x*width,p.y+lift,z))
	return ring

func _canopy_point(t: float,z: float) -> Vector3:
	var angle: float=t*PI
	return Vector3(-.92*cos(angle),.73+1.04*sin(angle),z)

func build_boat() -> ArrayMesh:
	if materials.size()!=5:
		error="prepare() must validate original inputs before native construction."
		return null
	_reset()
	# Open true curved hull:24long intervals and8separate strake bands,
	# with a second inner shell, visible gunwales, ribs, floor and fitted canopy.
	for j in range(24):
		var r0:=_hull_ring(float(j)/24.)
		var r1:=_hull_ring(float(j+1)/24.)
		for k in range(8):
			var a: Vector3=r0[k];var b: Vector3=r1[k];var c: Vector3=r1[k+1];var d: Vector3=r0[k+1]
			var outside: Vector3=(b-a).cross(d-a).normalized()
			var middle_t: float=(float(j)+.5)/24.
			var lift: float=.24*pow(absf(2.*middle_t-1.),3.)
			var radial: Vector3=Vector3((a.x+d.x)*.5,(a.y+d.y)*.5-.2-lift,0).normalized()
			if outside.dot(radial)<0.: outside=-outside
			_quad(a,b,c,d,outside,"timber")
			var inset: Vector3=-outside*.045
			_quad(a+inset,d+inset,c+inset,b+inset,-outside,"dark_timber")
			# Real narrow strake seam batten, rather than a flat striped shader.
			if k>0: _beam(a,b,.020,.015,"dark_timber")
		_beam(r0[0],r1[0],.075,.065,"dark_timber")
		_beam(r0[8],r1[8],.075,.065,"dark_timber")
		_beam(r0[4],r1[4],.075,.060,"dark_timber")
	for t: float in [.02,.98]:
		var end_ring:=_hull_ring(t)
		for k in range(8): _beam(end_ring[k],end_ring[k+1],.06,.06,"dark_timber")
	for t: float in [.16,.28,.4,.52,.64,.76,.88]:
		var ring:=_hull_ring(t)
		for k in range(8): _beam(ring[k]+Vector3(0,.055,0),ring[k+1]+Vector3(0,.055,0),.045,.045,"dark_timber")
	for i in range(6): _box(Vector3(-.5+float(i)*.20,.26,0),Vector3(.188,.07,4.9),"timber")
	for z: float in [-2.15,2.0]: _box(Vector3(0,.57,z),Vector3(1.75,.075,.26),"timber")
	# Longitudinal canopy panels are curved3Dcloth; arches remain independent.
	for j in range(12):
		var t0: float=float(j)/12.;var t1: float=float(j+1)/12.
		var a:=_canopy_point(t0,-1.48);var b:=_canopy_point(t0,1.25)
		var c:=_canopy_point(t1,1.25);var d:=_canopy_point(t1,-1.48)
		var n: Vector3=Vector3(-cos((t0+t1)*.5*PI),sin((t0+t1)*.5*PI),0)
		_quad(a,b,c,d,n,"canvas")
		_quad(a+Vector3(0,-.015,0),d+Vector3(0,-.015,0),c+Vector3(0,-.015,0),b+Vector3(0,-.015,0),-n,"canvas")
	for z: float in [-1.49,-.80,-.11,.58,1.26]:
		for j in range(12): _beam(_canopy_point(float(j)/12.,z),_canopy_point(float(j+1)/12.,z),.045,.045,"dark_timber")
	for z in [-1.5,1.28]:
		for x in [-.9,.9]: _beam(Vector3(x,.47,z),Vector3(x,.86,z),.04,.04,"dark_timber")
	_beam(Vector3(.87,.72,2.4),Vector3(1.4,.4,3.5),.042,.042,"timber")
	_box(Vector3(1.38,.36,3.45),Vector3(.20,.065,.43),"timber")
	component_counts={"longitudinal_hull_intervals":24,"strake_bands":8,"inner_shell":true,"transverse_ribs":7,"floor_planks":6,"cross_seats":2,"canopy_curved_panels":12,"canopy_arches":5,"oar":1}
	return _commit()

func author_native_specs() -> Array:
	# This helper does NOT export sprites or claim actual bounds/alpha/Physics.
	# Renderer must project explicitlocal anchor, keep canvas around it, measure
	# actual body and give standalone new resource to runtime object exporter.
	return [
		{"id":"dry_loading_wharf","method":"build_deck","world_foot_px":[2150,1640],"physical_center_px":[2150,1640],"local_ground_anchor_m":[0,0,0],"ground_size_m":[1.56,6.4],"solid_polygons_px":[],"blocking":false,"role":"ground_overlay","walk_support":false,"z_index":-2,"ghost_occlusion":false,"scope":"Dry-land support unchanged; no water painted walkable. Geometry underneath the deck is not a player blocking solid."},
		{"id":"moored_canal_boat","method":"build_boat","world_foot_px":[2570,1430],"physical_center_px":[2570,1430],"local_ground_anchor_m":[0,0,0],"solid_polygons_px":[],"blocking":false,"role":"water_decoration","walk_support":false,"ghost_occlusion":false,"water_surface_height_m":-.025,"scope":"Mooring-origin water depth anchor, not lowest2percent screen alpha or player support. New canopy/oar envelope must pass legalActorDomain/currentframe alpha negative independently."}
	]

func existing_cargo_records() -> Array:
	var out: Array=[]
	for p: Vector2 in [Vector2(2010,1530),Vector2(2100,1740),Vector2(1950,1640),Vector2(1740,1250)]:
		var scale_value: float=.25 if p.x==1740. else .21
		var id: String="canal_feud_chest" if p.x==1740. else "quay_crate_"+str(int(p.x))
		var origin: Vector2=p-Vector2(257,459)*scale_value
		var solid: Array=[]
		for uv: Vector2 in [Vector2(82,346),Vector2(454,315),Vector2(465,448),Vector2(157,469)]:
			var q: Vector2=origin+uv*scale_value
			solid.append([q.x,q.y])
		out.append({"id":id,"source":BOX_SOURCE,"source_sha256":BOX_SHA,"source_size_px":[512,512],"world_foot_px":[p.x,p.y],"origin_px":[origin.x,origin.y],"scale":scale_value,"foot_source_px":[257,459],"solid_polygons_px":[solid],"blocking":true,"scope":"Existing detailed project-original chest source/semantic ground kept. Existing story/action id retained; not a new generic CC0 shipping crate."})
	return out

func release() -> void:
	buckets.clear()
	materials.clear()
