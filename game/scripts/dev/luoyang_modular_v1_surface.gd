extends RefCounted

const ROOT := "res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"
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
	return true

func paving() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D rock_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform float native_flagstone_identity=1.;
varying vec3 local_p;
void vertex(){local_p=VERTEX;}
void fragment(){vec2 uv=local_p.xz/1.5;vec3 scan=texture(rock_diff,uv).rgb;vec3 arm=texture(rock_arm,uv).rgb;
float wear=dot(scan,vec3(.2126,.7152,.0722));
vec3 stone=vec3(.34,.355,.355)*( .95+wear*.10 );
ALBEDO=mix(stone,scan,.15)*native_flagstone_identity*COLOR.rgb;
ROUGHNESS=clamp(.82+arm.g*.12,.75,1.);AO=mix(1.,arm.r,.15);
NORMAL_MAP=texture(rock_normal,uv).rgb;NORMAL_MAP_DEPTH=.14;SPECULAR=.22;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("rock_diff",textures["diff"])
	material.set_shader_parameter("rock_normal",textures["nor_gl"])
	material.set_shader_parameter("rock_arm",textures["arm"])
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
