extends RefCounted

const ROOT := "res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"
const STONE := "res://art/maps/luoyang_modular_v2/source/worn_bluestone_v2.png"
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
	evidence.append({"path":STONE,"sha256":STONE_SHA,"license":"Project original builtin-imagegen; NOT CC0","source_path":"res://art/maps/luoyang_modular_v2/source/generation_record.json","source_sha256":FileAccess.get_sha256("res://art/maps/luoyang_modular_v2/source/generation_record.json"),"physical_width_m":2.,"actual_size_px":[1254,1254],"actual_mip_count":stone_image.get_mipmap_count(),"usage":"Original stone ALBEDO only; native stone polygon supplies joints/bevel, licensed rock normal/ARM only low-amplitude microdetail; not matching stone PBR scan"})
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
float zone=COLOR.a;float polish=1.-smoothstep(.05,.22,zone);
// Broad native slab-edge wear/grime is vertex colour, not a second fake grout grid.
float edge=min(min(local_p.x+24.,24.-local_p.x),min((local_p.z+32.)*.5,(32.-local_p.z)*.5));
float shoulder=1.-smoothstep(1.,6.,edge);
// One continuous weathered perimeter, never a random missing-brick checker mask.
ALBEDO=mix(stone,vec3(.29,.28,.255),shoulder*.28)*COLOR.rgb*native_flagstone_identity;
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
