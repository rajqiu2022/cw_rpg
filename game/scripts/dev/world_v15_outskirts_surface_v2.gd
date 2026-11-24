extends RefCounted

# Independent v15 renderer material. Registered sources stay byte unchanged.
const PBR := [
 {"id":"grass_ground","meters":2.51,"directory":"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/"},
 {"id":"forest_ground_04","meters":3.2,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/"},
 {"id":"rock_01","meters":1.5,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"},
 {"id":"brown_mud_03","meters":1.3,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/"},
 {"id":"aerial_grass_rock","meters":15.,"directory":"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/"}]
var textures: Dictionary={}
var evidence: Array[Dictionary]=[]
var error := ""
var field_ecology_mode := 0

func load_sources() -> bool:
	for asset in PBR:
		var source_path: String=asset["directory"]+"SOURCE.json"
		var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(source_path))
		if not source is Dictionary or source.get("license","")!="CC0-1.0" or source.get("asset","")!=asset["id"]:
			error="Registered PBR identity rejected: "+source_path
			return false
		for channel: String in ["diff","nor_gl","arm"]:
			var path: String=asset["directory"]+asset["id"]+"_"+channel+"_2k.jpg"
			var record: Dictionary={}
			for item in source.get("channels",[]):
				if item.get("channel","")==channel: record=item
			var hash: String=FileAccess.get_sha256(path)
			if hash.is_empty() or record.get("sha256","").to_lower()!=hash.to_lower() or not record.get("md5_verified",false):
				error="Registered PBR bytes rejected: "+path
				return false
			var image: Image=Image.load_from_file(path)
			if image==null or image.is_empty() or image.generate_mipmaps()!=OK:
				error="PBR mip construction failed: "+path
				return false
			textures[asset["id"]+"_"+channel]=ImageTexture.create_from_image(image)
			evidence.append({"path":path,"sha256":hash,"source_path":source_path,"source_sha256":FileAccess.get_sha256(source_path),"physical_width_m":asset["meters"],"actual_mip_count":image.get_mipmap_count(),"channel":channel,"color_space":"sRGB" if channel=="diff" else "linear"})
	return true

func environment() -> Environment:
	var material:=ProceduralSkyMaterial.new()
	material.sky_top_color=Color(.25,.43,.63)
	material.sky_horizon_color=Color(.72,.78,.81)
	material.ground_bottom_color=Color(.24,.26,.20)
	material.sky_energy_multiplier=.8
	var sky:=Sky.new()
	sky.sky_material=material
	var result:=Environment.new()
	result.background_mode=Environment.BG_SKY
	result.sky=sky
	result.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	result.ambient_light_color=Color(.90,.94,1.)
	result.ambient_light_energy=.35
	result.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	return result

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled;
uniform sampler2D biome_weights:filter_linear,repeat_disable;
uniform sampler2D road_weights:filter_linear,repeat_disable;
uniform int field_ecology_mode;
uniform vec4 source_rect;uniform vec2 world_size=vec2(12288.,8192.);
uniform sampler2D grass_ground_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_ground_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_ground_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_arm:filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 xyz;varying vec3 geo;void vertex(){xyz=VERTEX;geo=NORMAL;}
vec3 scan(sampler2D tex,float meters,vec3 w){return texture(tex,xyz.zy/meters).rgb*w.x+texture(tex,xyz.xz/meters).rgb*w.y+texture(tex,xyz.xy/meters).rgb*w.z;}
void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 ecology=texture(biome_weights,uv);vec2 road=texture(road_weights,uv).rg;
 vec3 w=pow(abs(geo),vec3(4.));w/=max(dot(w,vec3(1.)),.0001);
 vec3 grass=scan(grass_ground_diff,2.51,w),soil=scan(forest_ground_04_diff,3.2,w),stone=scan(rock_01_diff,1.5,w),mud=scan(brown_mud_03_diff,1.3,w);
 vec3 mids=scan(aerial_grass_rock_diff,15.,w);
 // Full-colour registered15m organisation, not a wider fake tint/noise patch.
 vec3 meadow=mix(mids,grass,.30);
 vec3 base=meadow;
 if(field_ecology_mode==1)base=mix(mix(soil,mud,.38),meadow,road.g*.65);
 if(field_ecology_mode==2)base=mix(meadow,mud,.50+.35*ecology.b);
 vec3 color=mix(base,mix(soil,mud,.22),ecology.r*.55);color=mix(color,stone,ecology.g*.6);color=mix(color,mud,ecology.b*.65);
 // Snow is a disclosed native material over the same mesh, not a fake scan.
 color=mix(color,vec3(.70,.75,.78),ecology.a*.9);
 vec3 roadsoil=mix(soil,mud,.55);
 float wear=.76+.24*sin(xyz.x*1.7+xyz.z*2.3)*sin(xyz.z*3.4);
 color=mix(color,mix(meadow,soil,.35),road.g*.24*(1.-road.r));color=mix(color,roadsoil,road.r*.82*wear);
 vec3 arm=mix(scan(grass_ground_arm,2.51,w),scan(forest_ground_04_arm,3.2,w),ecology.r);arm=mix(arm,scan(rock_01_arm,1.5,w),ecology.g);arm=mix(arm,scan(brown_mud_03_arm,1.3,w),ecology.b*.8);
 vec3 detail=mix(scan(grass_ground_nor_gl,2.51,w),scan(forest_ground_04_nor_gl,3.2,w),ecology.r);detail=mix(detail,scan(rock_01_nor_gl,1.5,w),ecology.g);detail=mix(detail,scan(brown_mud_03_nor_gl,1.3,w),ecology.b);
 ALBEDO=color;AO=mix(1.,arm.r,.55);ROUGHNESS=clamp(mix(arm.g,.86,ecology.a),.25,.98);SPECULAR=.3;METALLIC=0.;
 vec3 wn=normalize(geo+vec3((detail.r-.5)*.35,0.,(detail.g-.5)*.35));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""
	var result:=ShaderMaterial.new()
	result.shader=shader
	for key in textures: result.set_shader_parameter(key,textures[key])
	result.set_shader_parameter("field_ecology_mode",field_ecology_mode)
	result.set_shader_parameter("biome_weights",weights)
	result.set_shader_parameter("road_weights",roads)
	result.set_shader_parameter("source_rect",Vector4(local_rect.position.x,local_rect.position.y,local_rect.size.x,local_rect.size.y))
	return result

func water_material(height_rf: Texture2D,grid_origin: Vector2i,grid_shape: Vector2i) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled,blend_mix,depth_draw_never;
uniform sampler2D actual_height_rf:filter_nearest,repeat_disable;
uniform ivec2 grid_origin;uniform ivec2 grid_shape;
varying vec3 xyz;void vertex(){xyz=VERTEX;}
float bed(vec2 p){vec2 q=p/8.-vec2(grid_origin);ivec2 c=clamp(ivec2(floor(q)),ivec2(0),grid_shape-ivec2(2));vec2 f=clamp(q-vec2(c),vec2(0.),vec2(1.));float a=texelFetch(actual_height_rf,c,0).r,b=texelFetch(actual_height_rf,c+ivec2(1,0),0).r,d=texelFetch(actual_height_rf,c+ivec2(1,1),0).r,e=texelFetch(actual_height_rf,c+ivec2(0,1),0).r;return f.x+f.y<=1.?a+(b-a)*f.x+(e-a)*f.y:d+(e-d)*(1.-f.x)+(b-d)*(1.-f.y);}
void fragment(){vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);float depth=-.025-bed(p);if(depth<=0.)discard;
 vec2 wave=vec2(.025*cos(xyz.x*5.7+xyz.z*1.3),.03*cos(xyz.z*6.9-xyz.x*1.8));vec3 normal=normalize(vec3(-wave.x,1.,-wave.y));NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.)).xyz);
 ALBEDO=mix(vec3(.24,.37,.31),vec3(.07,.24,.30),smoothstep(.03,.28,depth));ROUGHNESS=.16;SPECULAR=.65;METALLIC=0.;ALPHA=mix(.3,.97,smoothstep(.015,.23,depth));}
"""
	var result:=ShaderMaterial.new()
	result.shader=shader
	result.set_shader_parameter("actual_height_rf",height_rf)
	result.set_shader_parameter("grid_origin",grid_origin)
	result.set_shader_parameter("grid_shape",grid_shape)
	return result

func release() -> void:
	textures.clear()
	evidence.clear()




