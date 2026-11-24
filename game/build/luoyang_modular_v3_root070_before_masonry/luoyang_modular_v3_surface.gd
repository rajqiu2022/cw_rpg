extends RefCounted

const ROOT := "res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"
const STONE := "res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png"
const STONE_SHA := "7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d"
var textures: Dictionary={}
var evidence: Array[Dictionary]=[]
var error := ""

func load_sources() -> bool:
	var registry: Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"SOURCE.json"))
	if not registry is Dictionary: return false
	var hashes := {"diff":"fe9013368539b5604602e64bfa48bef1a2a4c452fcb6894868fb556d0b14501c","nor_gl":"70427a2c81f85c0e1ee4a147e273d028c3d0188bad2583f2509d6df9a3d55b89","arm":"a954de58336738e6f963466f1453202ef7e186bd6492106c3b989c39f0d2e23c"}
	for channel: String in hashes:
		var path: String=ROOT+"rock_01_"+channel+"_2k.jpg"
		if FileAccess.get_sha256(path)!=hashes[channel]:
			error="Registered city microdetail source mismatch: "+path
			return false
		var image: Image=Image.load_from_file(path)
		if image==null or image.generate_mipmaps()!=OK: return false
		textures[channel]=ImageTexture.create_from_image(image)
		evidence.append({"path":path,"sha256":hashes[channel],"license":"CC0-1.0","source_path":ROOT+"SOURCE.json","source_sha256":FileAccess.get_sha256(ROOT+"SOURCE.json"),"physical_width_m":1.5,"actual_mip_count":image.get_mipmap_count(),"usage":"rock scan microdetail on PROJECT-NATIVE flagstone geometry; not claimed as a scanned city pavement"})
	if FileAccess.get_sha256(STONE)!=STONE_SHA:
		error="Original generated stone albedo SHA mismatch."
		return false
	var stone_image: Image=Image.load_from_file(STONE)
	if stone_image==null or stone_image.get_size()!=Vector2i(1254,1254) or stone_image.generate_mipmaps()!=OK: return false
	textures["stone"]=ImageTexture.create_from_image(stone_image)
	evidence.append({"path":STONE,"sha256":STONE_SHA,"license":"Project original builtin-imagegen; NOT CC0","source_path":"res://art/maps/luoyang_modular_v3/source/generation_record.json","source_sha256":FileAccess.get_sha256("res://art/maps/luoyang_modular_v3/source/generation_record.json"),"physical_width_m":2.,"actual_size_px":[1254,1254],"actual_mip_count":stone_image.get_mipmap_count(),"usage":"Original stone ALBEDO only; native stone polygon supplies joints/bevel, licensed rock normal/ARM only low-amplitude microdetail; not matching stone PBR scan"})
	return true

func paving() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D rock_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D stone_albedo:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float native_flagstone_identity=1.;
varying vec3 local_p;
void vertex(){local_p=VERTEX;}
void fragment(){vec2 uv=local_p.xz/1.5;vec3 arm=texture(rock_arm,uv).rgb;
vec3 stone=texture(stone_albedo,UV).rgb;
float zone=COLOR.a;float polish=1.-smoothstep(.05,.18,zone);
// Broad native slab-edge wear/grime is vertex colour, not a second fake grout grid.
float edge=min(min(local_p.x+24.,24.-local_p.x),min((local_p.z+32.)*.5,(32.-local_p.z)*.5));
float shoulder=1.-smoothstep(1.,6.,edge);
// One continuous weathered perimeter, never a random missing-brick checker mask.
// Construction zones still choose actual slab widths, but NOT alternating
// whole-slab colours. The earlier palette turned route boundaries into a
// stair-stepped brown/blue checkerboard. Subtle continuous wear belongs to
// the world surface, independently of the semantic navigation mask.
float avenue=1.-smoothstep(2.5,4.2,abs(local_p.x));
float patina=.5+.22*sin(local_p.x*.17+local_p.z*.11)+.14*sin(local_p.z*.31-local_p.x*.08);
vec3 finish=mix(vec3(.86,.845,.805),vec3(.88,.88,.86),avenue*.45);
finish*=.97+patina*.045;
float stone_share=.96;
vec3 surface=mix(vec3(.34,.305,.25),stone,stone_share)*finish;
ALBEDO=mix(surface,vec3(.27,.255,.22),shoulder*.22)*COLOR.rgb*native_flagstone_identity;
ROUGHNESS=clamp(mix(.84,.66,polish)+arm.g*.055,.64,.94);AO=mix(1.,arm.r,.07);
NORMAL_MAP=texture(rock_normal,uv).rgb;NORMAL_MAP_DEPTH=.065;SPECULAR=.22;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("rock_diff",textures["diff"])
	material.set_shader_parameter("rock_normal",textures["nor_gl"])
	material.set_shader_parameter("rock_arm",textures["arm"])
	material.set_shader_parameter("stone_albedo",textures["stone"])
	return material

func shoulder() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D stone_albedo:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 p;void vertex(){p=VERTEX;}
void fragment(){vec3 stone=texture(stone_albedo,p.xz/2.).rgb;
// Compacted gritty joints/outer verge, NOT a claimed scanned soil or cast shadow.
ALBEDO=mix(vec3(.29,.28,.255),stone,.30);ROUGHNESS=.97;SPECULAR=.1;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("stone_albedo",textures["stone"])
	return material

func masonry(tint: Color) -> ShaderMaterial:
	# Original limestone colour plus independently registered rock microdetail.
	# This is a project-authored masonry material, never a claimed CC0 wall kit.
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D original_stone:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec3 masonry_tint=vec3(1.);
varying vec3 p;varying vec3 n;
void vertex(){p=VERTEX;n=NORMAL;}
vec3 scan(sampler2D image,vec3 w){return texture(image,p.zy/.8).rgb*w.x+texture(image,p.xz/.8).rgb*w.y+texture(image,p.xy/.8).rgb*w.z;}
void fragment(){vec3 w=pow(abs(n),vec3(4.));w/=max(w.x+w.y+w.z,.0001);
vec3 stone=scan(original_stone,w);vec3 arm=scan(registered_arm,w);
float dirt=.045*(.5+.5*sin(p.x*.71+p.z*.43));
// The adjoining authored wall has plaster over a dark stone plinth, matching
// the original courtyard gate. A paving-coloured face visually vanished into
// the street; this height-owned finish changes no geometry/solid footprint.
float base=1.-smoothstep(.25,.48,p.y);float cap=smoothstep(1.22,1.28,p.y);
vec3 plaster=vec3(.69,.665,.61)*(.965+stone.r*.065);
vec3 face=mix(plaster,stone*.73,base);face=mix(face,mix(plaster,stone*.75,.30),cap);
ALBEDO=face*masonry_tint*(1.-dirt);ROUGHNESS=clamp(.84+arm.g*.035,.8,.95);AO=mix(1.,arm.r,.06);SPECULAR=.16;
vec3 detail=scan(registered_normal,w);vec3 normal=normalize(n+vec3(detail.r-.5,detail.g-.5,0.)*.04);NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.)).xyz);}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("original_stone",textures["stone"])
	material.set_shader_parameter("registered_normal",textures["nor_gl"])
	material.set_shader_parameter("registered_arm",textures["arm"])
	material.set_shader_parameter("masonry_tint",Vector3(tint.r,tint.g,tint.b))
	return material

func canal_water() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode blend_mix,cull_disabled,depth_draw_never;
uniform float native_canal_water_identity=1.;
varying vec3 p;void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){float phase=p.z*7.2+p.x*3.9+sin(p.x*1.3+p.z*.7)*1.9;
float wave=sin(phase)*sin(p.x*8.3-p.z*2.1)*.0023+sin(p.z*17.1+p.x*12.3)*.0012;
vec3 n=normalize(vec3(.012*cos(phase+p.x*2.7),1.,.016*sin(p.x*9.7-p.z*3.2)));
float shore=1.-smoothstep(.15,2.8,p.x-10.84375);
// Constructed quay and flat negative bed, not fictitious natural bathymetry.
vec3 water=mix(vec3(.10,.205,.205),vec3(.19,.27,.235),shore*.65)+wave;
NORMAL=normalize((VIEW_MATRIX*vec4(n,0.)).xyz);ALBEDO=water*native_canal_water_identity;ROUGHNESS=.25;SPECULAR=.6;ALPHA=.94;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	return material

static func environment(transparent: bool=false) -> Environment:
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(.37,.39,.4,0 if transparent else 1)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.82,.85,.88)
	env.ambient_light_energy=.45
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	return env

static func wood() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;varying vec3 p;void vertex(){p=VERTEX;}
void fragment(){float grain=sin(p.y*73.+sin(p.x*13.)*.8)*.025+sin(p.y*241.+p.z*14.)*.012;ALBEDO=vec3(.22,.13,.068)+grain;ROUGHNESS=.86;SPECULAR=.16;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	return material

static func plain(color: Color) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=.86
	return material

func release() -> void:
	textures.clear()
	evidence.clear()
