extends "res://scripts/dev/luoyang_modular_v3_surface.gd"

# NEW SOURCE-ONLY material proposal. No geometry, pixel-file edits or exports.
# All details are native authoring over the registered original stone ALBEDO
# and CC0 rock_01 micro-normal/ARM, not new or falsely licensed pavement scans.
const PARENT_PATH := "res://scripts/dev/luoyang_modular_v3_surface.gd"
const PARENT_SHA := "76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52"
const MAX_SEGMENTS := 128
const MAX_APRONS := 32
const PPM := 64.0
const ZPPM := 32.0
var district := ""
var route_segments: Array[Vector4]=[]
var contact_segments: Array[Vector4]=[]
var apron_rects: Array[Vector4]=[]
var material_records: Array[Dictionary]=[]
var authoring_snapshot_sha := ""

func configure(snapshot: Dictionary) -> bool:
	error=""
	district=String(snapshot.get("scene_id",""))
	route_segments.clear()
	contact_segments.clear()
	apron_rects.clear()
	material_records.clear()
	if not district in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks"] or snapshot.get("logical_size_px",[])!=[3072,2048]:
		error="Exact existing city snapshot/3072x2048 required; no guessed layout."
		return false
	for route in snapshot.get("routes",[]):
		var points: Array=route["points_px"]
		for i in range(points.size()-1):
			var a: Vector2=_world_m(points[i])
			var b: Vector2=_world_m(points[i+1])
			route_segments.append(Vector4(a.x,a.y,b.x,b.y))
	for object in snapshot.get("objects",[]):
		if not bool(object.get("blocking",false)): continue
		var footprints: Array=object.get("solid_polygons_px",[]).duplicate(true)
		if footprints.is_empty():
			var dimensions: Array=object.get("collision_size_px",[0,0])
			var midpoint: Array=object.get("physical_center_px",[])
			if midpoint.size()==2 and dimensions.size()==2 and float(dimensions[0])>0. and float(dimensions[1])>0.:
				var x0: float=float(midpoint[0])-float(dimensions[0])*.5
				var x1: float=float(midpoint[0])+float(dimensions[0])*.5
				var y0: float=float(midpoint[1])-float(dimensions[1])*.5
				var y1: float=float(midpoint[1])+float(dimensions[1])*.5
				footprints.append([[x0,y0],[x1,y0],[x1,y1],[x0,y1]])
		for polygon in footprints:
			if polygon.size()<3:
				error="Invalid existing physical footprint; do not derive contact from alpha shadow."
				return false
			var low:=Vector2(INF,INF)
			var high:=Vector2(-INF,-INF)
			for i in range(polygon.size()):
				var a: Vector2=_world_m(polygon[i])
				var b: Vector2=_world_m(polygon[(i+1)%polygon.size()])
				contact_segments.append(Vector4(a.x,a.y,b.x,b.y))
				low=low.min(a)
				high=high.max(a)
			var id: String=object.get("id","")
			if "front" in id or id in ["inn","shop","north_canal_warehouse"]:
				# Actual visible forward side, not entire alpha-canvas rectangle.
				apron_rects.append(Vector4(low.x,high.y,high.x,high.y+3.2))
	if route_segments.size()>MAX_SEGMENTS or contact_segments.size()>MAX_SEGMENTS or apron_rects.size()>MAX_APRONS:
		error="Bounded native shader geometry-owner budget exceeded; no silent omission."
		return false
	authoring_snapshot_sha=_bytes_sha(var_to_bytes(snapshot))
	return true

func load_sources() -> bool:
	if FileAccess.get_sha256(PARENT_PATH).to_lower()!=PARENT_SHA:
		error="Frozen city surface changed; proposal refuses."
		return false
	return super.load_sources()

func paving() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D stone_albedo:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform float native_flagstone_identity=1.;
uniform int route_count;uniform int contact_count;uniform int apron_count;
uniform vec4 route_segments[128];uniform vec4 contact_segments[128];uniform vec4 apron_rects[32];
varying vec3 p;void vertex(){p=VERTEX;}
float seg(vec2 q,vec4 v){vec2 d=v.zw-v.xy;return length(q-v.xy-d*clamp(dot(q-v.xy,d)/max(dot(d,d),.00001),0.,1.));}
float hash2(vec2 v){return fract(sin(dot(v,vec2(127.1,311.7)))*43758.5453);}
float patina(vec2 v){vec2 i=floor(v),f=fract(v);f=f*f*(3.-2.*f);return mix(mix(hash2(i),hash2(i+vec2(1.,0.)),f.x),mix(hash2(i+vec2(0.,1.)),hash2(i+vec2(1.)),f.x),f.y);}
void fragment(){
 float route_d=10000.,wall_d=10000.,apron=0.;
 for(int i=0;i<128;i++){if(i<route_count)route_d=min(route_d,seg(p.xz,route_segments[i]));if(i<contact_count)wall_d=min(wall_d,seg(p.xz,contact_segments[i]));}
 for(int i=0;i<32;i++){if(i<apron_count){vec4 r=apron_rects[i];vec2 outside=max(max(r.xy-p.xz,p.xz-r.zw),vec2(0.));apron=max(apron,1.-smoothstep(.0,.65,length(outside)));}}
 // Continuous traffic sheen/dust, never whole-slab zone colours/checker blocks.
 float traffic=1.-smoothstep(.65,1.65,route_d);
 float verge=smoothstep(2.2,4.5,route_d)*(1.-apron);
 float contact=(1.-smoothstep(.03,.40,wall_d))*(.60+.40*patina(p.xz/.65));
 float broad=patina(p.xz/4.7)*.65+patina(p.xz/11.3)*.35;
 vec3 stone=texture(stone_albedo,UV).rgb;
 vec3 arm=texture(rock_arm,p.xz/1.5).rgb;
 // Original per-stone UV offsets remain exact. Native world-space wear only
 // changes a restrained portion of the real ALBEDO, not a new brick grid.
 vec3 finish=mix(vec3(.81,.815,.80),vec3(.89,.885,.85),traffic);
 finish=mix(finish,vec3(.87,.86,.82),apron*.48);
 finish*=.985+(broad-.5)*.045;
 vec3 dust=mix(vec3(.32,.305,.265),vec3(.405,.385,.32),broad);
 vec3 face=stone*finish;
 face=mix(face,dust,verge*.18+contact*.055);
 // Geometry's existing bevel dirt and footprint-contact vertex colours stay
 // present. No new decal mesh, cast shadow, physical edge or navigation layer.
 ALBEDO=face*COLOR.rgb*native_flagstone_identity;
 ROUGHNESS=clamp(.88-traffic*.15+verge*.035+(arm.g-.5)*.035,.69,.96);
 AO=mix(1.,arm.r,.06);SPECULAR=.19;
 NORMAL_MAP=texture(rock_normal,p.xz/1.5).rgb;NORMAL_MAP_DEPTH=.045;
}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	for pair in [["stone_albedo","stone"],["rock_diff","diff"],["rock_normal","nor_gl"],["rock_arm","arm"]]: material.set_shader_parameter(pair[0],textures[pair[1]])
	material.set_shader_parameter("route_count",route_segments.size())
	material.set_shader_parameter("contact_count",contact_segments.size())
	material.set_shader_parameter("apron_count",apron_rects.size())
	material.set_shader_parameter("route_segments",_uniform_vectors(route_segments,MAX_SEGMENTS))
	material.set_shader_parameter("contact_segments",_uniform_vectors(contact_segments,MAX_SEGMENTS))
	material.set_shader_parameter("apron_rects",_uniform_vectors(apron_rects,MAX_APRONS))
	_record(material,"continuous_traffic_apron_verge_material_only")
	return material

func shoulder() -> ShaderMaterial:
	var material: ShaderMaterial=super.shoulder()
	# Actual existing joints/base retain full coverage and geometry. Avoid high
	# contrast pseudo-empty dark cracks beneath pale flags; no omitted slab.
	material.shader=material.shader.duplicate() as Shader
	material.shader.code=material.shader.code.replace("ALBEDO=mix(vec3(.29,.28,.255),stone,.30);", "ALBEDO=mix(vec3(.31,.305,.28),stone,.34);")
	_record(material,"existing_base_joints_lower_contrast_material_only")
	return material

func masonry(tint: Color,profile: String) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D original_stone:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec3 masonry_tint=vec3(1.);uniform float masonry_profile=0.;
varying vec3 p;varying vec3 source_n;varying vec3 world_n;
void vertex(){p=VERTEX;source_n=NORMAL;world_n=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);}
vec3 scan(sampler2D t,float width,vec3 w){return texture(t,p.zy/width).rgb*w.x+texture(t,p.xz/width).rgb*w.y+texture(t,p.xy/width).rgb*w.z;}
float h(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
float weather(vec2 q){vec2 i=floor(q),f=fract(q);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1.,0.)),f.x),mix(h(i+vec2(0.,1.)),h(i+vec2(1.)),f.x),f.y);}
void fragment(){
 vec3 n=normalize(world_n);vec3 w=pow(abs(source_n),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 vec3 stone=scan(original_stone,2.,w),arm=scan(registered_arm,1.5,w);
 float luma=dot(stone,vec3(.2126,.7152,.0722));
 float age=weather(vec2(p.x+p.z*.17,p.y)*1.4);
 float stain=(1.-smoothstep(.04,.45,p.y))*(.4+.6*weather(vec2(p.x+p.z,p.y)/.45));
 float base=1.-smoothstep(.25,.48,p.y),cap=smoothstep(1.22,1.28,p.y);
 // Real original 0.25m brick-row geometry provides seams, not a second shader
 // brick grid. South gate stays grey masonry; yamen stays white-lime/dark base.
 vec3 brick=vec3(.355,.37,.38)*(.79+luma*.36)+(stone-vec3(luma))*.05;
 vec3 lime=vec3(.675,.675,.65)*(.95+luma*.07);
 vec3 face=masonry_profile>.5?lime:brick;
 face=mix(face,vec3(.25,.27,.285)*(.83+luma*.28),base);
 face=mix(face,vec3(.25,.265,.275)*(.86+luma*.23),cap);
 face*=.975+(age-.5)*.035;
 ALBEDO=face*masonry_tint*(1.-stain*.045);
 ROUGHNESS=clamp((masonry_profile>.5?.89:.91)+(arm.g-.5)*.025,.84,.97);AO=mix(1.,arm.r,.045);SPECULAR=.14;
 vec3 d=scan(registered_normal,1.5,w)-vec3(.5);
 vec3 tangent=abs(n.y)<.8?normalize(cross(vec3(0.,1.,0.),n)):vec3(1.,0.,0.);
 vec3 bitangent=normalize(cross(n,tangent));
 vec3 wn=normalize(n+tangent*d.x*.032+bitangent*d.y*.032);
 NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("original_stone",textures["stone"])
	material.set_shader_parameter("registered_normal",textures["nor_gl"])
	material.set_shader_parameter("registered_arm",textures["arm"])
	material.set_shader_parameter("masonry_tint",Vector3(tint.r,tint.g,tint.b))
	material.set_shader_parameter("masonry_profile",1. if profile=="yamen_white_lime_dark_stone" else 0.)
	_record(material,"same_brick_geometry_region_profile_metre_scale_weather")
	return material

func _record(material: ShaderMaterial,role: String) -> void:
	material_records.append({"role":role,"status":"SOURCE_ONLY_NOT_RENDERED_OR_APPROVED","scene_id":district,"authoring_snapshot_variant_sha256":authoring_snapshot_sha,"shader_code_sha256":_bytes_sha(material.shader.code.to_utf8_buffer()),"actual_sampler_paths":{"stone_albedo":STONE,"rock_normal":ROOT+"rock_01_nor_gl_2k.jpg","rock_arm":ROOT+"rock_01_arm_2k.jpg"},"provenance":"Original builtin-generated stone ALBEDO unchanged; official CC0 rock_01 at1.5m microdetail; native traffic polish/apron dust/contact weather is procedural project authoring, NOT cast shadow, CC0 pavement/wall/roof scan or extra geometry","layout_navigation_geometry_scope":"material assignment only; same arrays, UVs, support, sourcePNG and physics required byte exact"})

func _uniform_vectors(values: Array[Vector4],count: int) -> Array[Vector4]:
	var result: Array[Vector4]=values.duplicate()
	while result.size()<count: result.append(Vector4.ZERO)
	return result

func _world_m(point: Array) -> Vector2:
	return Vector2((float(point[0])-1536.)/PPM,(float(point[1])-1024.)/ZPPM)

func _bytes_sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()

func release() -> void:
	route_segments.clear()
	contact_segments.clear()
	apron_rects.clear()
	material_records.clear()
	super.release()
