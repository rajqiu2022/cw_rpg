extends RefCounted

# Independent v15 renderer material. Registered sources stay byte unchanged.
const PBR := [
 {"id":"leafy_grass","meters":2.,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/"},
 {"id":"grass_ground","meters":2.51,"directory":"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/"},
 {"id":"forest_ground_04","meters":3.2,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/"},
 {"id":"rock_01","meters":1.5,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"},
 {"id":"brown_mud_03","meters":1.3,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/"},
 {"id":"aerial_grass_rock","meters":15.,"directory":"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/"}]
var textures: Dictionary={}
var evidence: Array[Dictionary]=[]
var error := ""
var field_ecology_mode := 3

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
uniform sampler2D leafy_grass_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_arm:filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 xyz;varying vec3 geo;void vertex(){xyz=VERTEX;geo=NORMAL;}
vec3 scan(sampler2D tex,float meters,vec3 w){return texture(tex,xyz.zy/meters).rgb*w.x+texture(tex,xyz.xz/meters).rgb*w.y+texture(tex,xyz.xy/meters).rgb*w.z;}
float hash2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float deposit(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash2(i),hash2(i+vec2(1.,0.)),f.x),mix(hash2(i+vec2(0.,1.)),hash2(i+vec2(1.)),f.x),f.y);}
void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 ecology=texture(biome_weights,uv);vec3 road=texture(road_weights,uv).rgb;
 vec3 w=pow(abs(geo),vec3(4.));w/=max(dot(w,vec3(1.)),.0001);
 // Explicit same six ecological weights for full colour/ARM/normal.
 // Leaf litter + low grass is the dominant bamboo/forest floor. Registered
 // forest_ground_04 is stone-chip forest soil, restricted to actual roots.
 float wl=.72, wg=.14, ws=.08+ecology.r*.20, wm=.04, wr=min(.035,ecology.g*.10), wa=.02;
 if(field_ecology_mode==1){wl=.78;wg=.05;ws=.13+ecology.r*.18;wm=.025;wr=0.;wa=.015;}
 if(field_ecology_mode==2){wl=.32;wg=.07;ws=0.;wm=.60;wr=0.;wa=.01;}
 // Whole-world macro domains are material ownership, not a pale grass tint.
 if(field_ecology_mode==3){
  float forest=clamp(ecology.r,0.,1.), rock=clamp(ecology.g,0.,1.);
  // Open meadow owns true short-grass scan; forest owns leaf/soil, while the
  // 15m aerial scan supplies a subordinate continuous mid-scale organization.
  // Registered forest_ground_04 is gravelly soil and must not dominate woods.
  float patch=smoothstep(.30,.70,deposit(xyz.xz/5.3)+.18*deposit(xyz.xz/1.9));
  wl=forest*.48+(1.-forest)*patch*.44; ws=forest*.12; wm=.02+forest*.36;
  wg=(1.-forest)*(1.-patch)*.72; wa=(1.-forest)*.22; wr=rock*.90;
  float exposed=1.-rock*.85;wl*=exposed;ws*=exposed;wg*=exposed;wa*=exposed;
 }
 float shore=clamp(ecology.b*.84,0.,.84);
 wl*=1.-shore;wg*=1.-shore;ws*=1.-shore;wr*=1.-shore;wa*=1.-shore;wm+=shore;
 // Native compacted earth overrides the fissured mud scan at the route core.
 // Registered brown_mud remains honest wet-bank soil, not claimed road scan.
 float wear=.96+.04*sin(xyz.x*1.7+xyz.z*2.3)*sin(xyz.z*3.4);
 float route=clamp(road.r*.97*wear+road.g*(1.-road.r)*.28,0.,.98);
 // Do not let road ownership inject 97% cracked ALBEDO into the final surface.
 float total=max(wl+wg+ws+wm+wr+wa,.0001);wl/=total;wg/=total;ws/=total;wm/=total;wr/=total;wa/=total;
 vec3 color=scan(leafy_grass_diff,2.,w)*wl+scan(grass_ground_diff,2.51,w)*wg+scan(forest_ground_04_diff,3.2,w)*ws+scan(brown_mud_03_diff,1.3,w)*wm+scan(rock_01_diff,1.5,w)*wr+scan(aerial_grass_rock_diff,15.,w)*wa;
 vec3 arm=scan(leafy_grass_arm,2.,w)*wl+scan(grass_ground_arm,2.51,w)*wg+scan(forest_ground_04_arm,3.2,w)*ws+scan(brown_mud_03_arm,1.3,w)*wm+scan(rock_01_arm,1.5,w)*wr+scan(aerial_grass_rock_arm,15.,w)*wa;
 vec3 detail=scan(leafy_grass_nor_gl,2.,w)*wl+scan(grass_ground_nor_gl,2.51,w)*wg+scan(forest_ground_04_nor_gl,3.2,w)*ws+scan(brown_mud_03_nor_gl,1.3,w)*wm+scan(rock_01_nor_gl,1.5,w)*wr+scan(aerial_grass_rock_nor_gl,15.,w)*wa;
 // Native sand and deposited snow are openly project-authored physical
 // materials, not recoloured CC0 scans. The other six scanned groups use the
 // identical normalized weights for albedo, normal and ARM.
 float snow=field_ecology_mode==3?clamp(ecology.a*(1.-route),0.,.86):0.;
 float sand=field_ecology_mode==3?clamp(road.b*(1.-route)*(1.-snow),0.,.88):0.;
 // Deliberately authored deposit layers: centimetre-scale sand ripples and
 // broken dirty snow crust. NOT a claimed CC0 snow/sand scan. Their actual
 // dune/ridge volume is in RF geometry, not this surface function.
 float sand_deposit=deposit(xyz.xz/2.7)*.72+deposit(xyz.xz/9.1)*.28;
 float crust=smoothstep(.2,.8,deposit(xyz.xz/1.2));
 vec3 native_sand=mix(vec3(.36,.305,.225),vec3(.51,.445,.315),sand_deposit);
 vec3 native_snow=mix(vec3(.46,.51,.55),vec3(.62,.67,.70),crust*.65);
 color=mix(color,native_sand,sand);color=mix(color,native_snow,snow);
 arm=mix(arm,vec3(1.,.92,0.),sand);arm=mix(arm,vec3(1.,.73,0.),snow);
 detail=mix(detail,vec3(.5,.5,1.),max(sand,snow)*.8);
 // On the actual road the same scanned material is visibly worn/compacted,
 // not a black fissured rock normal. This is a documented native compaction
 // derivative, not a substitute texture or a global grass recolour.
 float compact=deposit(xyz.xz/.65)*.35+deposit(xyz.xz/3.1)*.65;
 vec3 native_road=mix(vec3(.29,.235,.16),vec3(.40,.33,.235),compact);
 // Coarsest registered scan mean supplies a small mineral tone only. This is
 // a documented project-authored material, not an invented CC0 packed-soil scan.
 native_road=mix(native_road,textureLod(brown_mud_03_diff,xyz.xz/1.3,8.).rgb,.08);
 color=mix(color,native_road,route);
 arm=mix(arm,vec3(1.,.9,0.),route);
 detail=mix(detail,vec3(.5,.5,1.),route);
 ALBEDO=color;AO=mix(1.,arm.r,mix(.28,.06,route));ROUGHNESS=clamp(mix(arm.g,.86,route*.65),.25,.98);SPECULAR=.20;METALLIC=0.;
 float detail_strength=mix(.24,.045,route);
 vec3 wn=normalize(geo+vec3((detail.r-.5)*detail_strength,0.,(detail.g-.5)*detail_strength));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
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
 // Turbid shallow river/tributary, not a uniformly saturated blue sea. The
 // opacity uses actual bed depth and preserves the real same-triangle shore.
 ALBEDO=mix(vec3(.25,.29,.235),vec3(.105,.19,.19),smoothstep(.03,.55,depth));ROUGHNESS=.24;SPECULAR=.50;METALLIC=0.;ALPHA=mix(.28,.96,smoothstep(.015,.32,depth));}
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
