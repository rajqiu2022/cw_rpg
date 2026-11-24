extends "res://scripts/dev/world_map_v15_complete_v5_surface.gd"

# Independent visual proposal, never substituted into the frozen v6 capture.
# Same eighteen registered, byte-unchanged CC0 channels/physical metre scales.
# Native loam/compacted earth/sand/snow/wave models are project authoring, NOT
# fictitious scans. All three PBR channels share actual material ownership.
const V7_PARENT_SURFACE := "res://scripts/dev/world_map_v15_complete_v5_surface.gd"
const V7_PARENT_SURFACE_SHA := "ad83c3c9626f86628638f1bea7abcb9b4bd7113917694fc138e14d0198cd7480"
const V7_TERRAIN_ID := "V7_OCCUPIED_FOREST_MACRO_LOAM_PHYSICAL_SCAN_COMPACT_ROAD_PROPOSAL"
const V7_WATER_ID := "V7_EXACT_RF_TRIANGLE_DEPTH_FIXED_GLOBAL_WAVE_BANDS_PROPOSAL"
var v7_material_records: Array[Dictionary]=[]

func load_sources() -> bool:
	if FileAccess.get_sha256(V7_PARENT_SURFACE).to_lower()!=V7_PARENT_SURFACE_SHA:
		error="Frozen AD83 surface changed; independent v7 proposal refuses inheritance."
		return false
	return super.load_sources()

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled;
uniform sampler2D biome_weights:filter_linear,repeat_disable;
uniform sampler2D road_weights:filter_linear,repeat_disable;
uniform vec4 source_rect;uniform vec2 world_size=vec2(12288.,8192.);
uniform int field_ecology_mode=3;
uniform sampler2D grass_ground_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_ground_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_ground_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_arm:filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 xyz;varying vec3 geo;
void vertex(){xyz=VERTEX;geo=NORMAL;}
float h2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h2(i),h2(i+vec2(1.,0.)),f.x),mix(h2(i+vec2(0.,1.)),h2(i+vec2(1.)),f.x),f.y);}
vec3 scan(sampler2D s,float metres,vec3 w,float bias){return texture(s,xyz.zy/metres,bias).rgb*w.x+texture(s,xyz.xz/metres,bias).rgb*w.y+texture(s,xyz.xy/metres,bias).rgb*w.z;}
void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 eco=texture(biome_weights,uv);vec3 road=texture(road_weights,uv).rgb;
 vec3 gn=normalize(geo);vec3 w=pow(abs(gn),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 float forest=clamp(eco.r,0.,1.);
 float rock=clamp(eco.g,0.,1.);
 float wet=clamp(eco.b,0.,1.);
 float snow=clamp(eco.a,0.,1.);
 float sand=road.b*(1.-snow)*(1.-forest);
 float route=clamp(road.r,0.,1.);
 // 8-18m patch ownership and 15m registered scan carry macro organization;
 // no repeated per-chunk phase and no whole-field tiny pink/yellow colour noise.
 float patch=n2(xyz.xz/8.7)*.65+n2(xyz.xz/18.3+vec2(6.,-4.))*.35;
 float pasture=smoothstep(.38,.69,patch)*(1.-forest)*(1.-wet);
 // Land use owns coherent roughly 4-9m strips only inside the authored
 // Luoyang/Jiangnan field regions. This is native cultivation material,
 // not planted physical crop geometry or navigation authoring.
 float field_west=1.-smoothstep(.55,1.10,length((p-vec2(4100.,3100.))/vec2(1900.,1150.)));
 float field_south=1.-smoothstep(.55,1.10,length((p-vec2(7900.,6100.))/vec2(1900.,1400.)));
 float field=max(field_west,field_south)*(1.-forest)*(1.-wet)*(1.-rock);
 float plot=step(.46,n2(vec2(floor(xyz.x/4.8),floor((xyz.z+.21*xyz.x)/8.6))));
 float bare=smoothstep(.53,.75,n2(xyz.xz/5.1))*smoothstep(.30,.75,patch);
 float wl=mix(.15,.58,forest)*(1.-bare*.45);
 float wg=pasture*.24;
 float ws=.04+forest*.12;
 float wm=wet*.43;
 float wr=rock*.92;
 float wa=(1.-forest)*.23;
 float sum=max(wl+wg+ws+wm+wr+wa,.00001);
 wl/=sum;wg/=sum;ws/=sum;wm/=sum;wr/=sum;wa/=sum;
 // Positive mip bias 1 on the fine colour scans suppresses sub-metre colour
 // speckles; the physical 2/2.51/3.2/1.3/1.5/15m periods are NOT enlarged.
 vec3 col=scan(leafy_grass_diff,2.,w,1.)*wl+scan(grass_ground_diff,2.51,w,1.)*wg+scan(forest_ground_04_diff,3.2,w,.4)*ws+scan(brown_mud_03_diff,1.3,w,.5)*wm+scan(rock_01_diff,1.5,w,0.)*wr+scan(aerial_grass_rock_diff,15.,w,0.)*wa;
 vec3 arm=scan(leafy_grass_arm,2.,w,1.)*wl+scan(grass_ground_arm,2.51,w,1.)*wg+scan(forest_ground_04_arm,3.2,w,.4)*ws+scan(brown_mud_03_arm,1.3,w,.5)*wm+scan(rock_01_arm,1.5,w,0.)*wr+scan(aerial_grass_rock_arm,15.,w,0.)*wa;
 vec3 detail=scan(leafy_grass_nor_gl,2.,w,1.)*wl+scan(grass_ground_nor_gl,2.51,w,1.)*wg+scan(forest_ground_04_nor_gl,3.2,w,.4)*ws+scan(brown_mud_03_nor_gl,1.3,w,.5)*wm+scan(rock_01_nor_gl,1.5,w,0.)*wr+scan(aerial_grass_rock_nor_gl,15.,w,0.)*wa;
 // Native humus is an occupied root soil derivative, not gravelly soil scan
 // multiplied nearly black. Its macro extent is tied to actual accepted stems.
 vec3 humus=mix(vec3(.145,.142,.105),vec3(.245,.235,.16),patch);
 vec3 loam=mix(vec3(.255,.27,.18),vec3(.36,.345,.245),patch);
 // ROOT123 showed identical yellow speckling under occupied woods and open
 // grass. Keep all physical scan periods; give actual accepted-root ownership
 // a continuous humus floor rather than a weak tint of the pasture scan.
 float native_owner=mix(.48+bare*.18,.84,forest)*(1.-rock)*(1.-snow)*(1.-wet*.65);
 col=mix(col,mix(loam,humus,forest),native_owner);
 col=mix(col,mix(loam,scan(leafy_grass_diff,2.,w,1.),plot),field*.33);
 arm=mix(arm,mix(vec3(1.,.94,0.),scan(leafy_grass_arm,2.,w,1.),plot),field*.33);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),plot),field*.33);
 arm=mix(arm,vec3(1.,.93,0.),native_owner);
 detail=mix(detail,vec3(.5,.5,1.),native_owner*.8);
 // Broad green pasture / bare-earth islands stay continuous across chunks.
 // These are declared native growth/weather treatments, not new CC0 scans.
 float growing=(1.-bare)*smoothstep(.32,.67,patch);
 vec3 turf=mix(vec3(.19,.235,.115),vec3(.29,.32,.17),patch);
 vec3 open_floor=mix(loam,turf,growing);
 col=mix(col,open_floor,(1.-forest)*(1.-rock)*(1.-snow)*(1.-wet)*.32);
 // Irregular deposited sand/gravel, not periodic sine ripples or giant dune
 // volume invented in a shader. All inherited RF relief remains exact.
 float deposit=n2(xyz.xz/3.7)*.4+n2(xyz.xz/12.9)*.6;
 vec3 mineral=scan(forest_ground_04_diff,3.2,w,0.);
 vec3 sand_col=mix(vec3(.38,.33,.235),vec3(.51,.465,.35),deposit);
 sand_col=mix(sand_col,mineral,.24*smoothstep(.38,.65,n2(xyz.xz/2.3)));
 col=mix(col,sand_col,sand*.92);
 arm=mix(arm,vec3(1.,.94,0.),sand*.92);
 detail=mix(detail,scan(forest_ground_04_nor_gl,3.2,w,0.),sand*.18);
 // Dirty packed snow deposits expose actual same-mesh rock, no white board.
 float crust=smoothstep(.25,.72,n2(xyz.xz/1.8)*.7+n2(xyz.xz/5.4)*.3);
 vec3 snow_col=mix(vec3(.45,.51,.55),vec3(.70,.74,.75),crust);
 col=mix(col,snow_col,snow*.9);arm=mix(arm,vec3(1.,.78,0.),snow*.9);
 detail=mix(detail,vec3(.5,.5,1.),snow*.8);
 // The actual compact lane uses honest registered 3.2m mineral/soil detail
 // and authored fine earth, NOT the cracked brown_mud ALBEDO or its LOD8 mean.
 // Narrow 4px-authored core boundary is already in R; no second broad smoothstep.
 float compact=n2(xyz.xz/.72)*.35+n2(xyz.xz/2.6)*.65;
 float grit=smoothstep(.66,.86,n2(xyz.xz/.095));
 vec3 earth=mix(vec3(.32,.275,.20),vec3(.43,.365,.265),compact);
 vec3 mineral_neutral=vec3(dot(mineral,vec3(.2126,.7152,.0722)));
 vec3 lane=mix(earth,mineral_neutral,.25)+vec3(grit*.018);
 float shoulder=clamp(road.g-route,0.,1.);
 col=mix(col,mix(loam,earth,.5),shoulder*.38);
 col=mix(col,lane,route);
 arm=mix(arm,scan(forest_ground_04_arm,3.2,w,0.),route*.25);
 arm=mix(arm,vec3(1.,.91,0.),route*.65);
 detail=mix(detail,scan(forest_ground_04_nor_gl,3.2,w,0.),route*.22);
 ALBEDO=col;AO=mix(1.,arm.r,.18);ROUGHNESS=clamp(arm.g,.50,.98);SPECULAR=.18;METALLIC=0.;
 float strength=mix(.17,.10,route);
 vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));
 NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	for key in textures: material.set_shader_parameter(key,textures[key])
	material.set_shader_parameter("biome_weights",weights)
	material.set_shader_parameter("road_weights",roads)
	material.set_shader_parameter("field_ecology_mode",3)
	material.set_shader_parameter("source_rect",Vector4(local_rect.position.x,local_rect.position.y,local_rect.size.x,local_rect.size.y))
	v7_material_records.append({"identity":V7_TERRAIN_ID,"shader_code_sha256":_v7_code_sha(shader.code),"status":"PROPOSAL_MATERIAL_CREATED_NOT_GPU_VALIDATED","source_rect":local_rect,"registered_binding":_v7_binding_evidence(material),"ownership_sampler":"linear non-mip source4px; future executor must call ecology.visual_material_maps, not frozen8px map function","scan_physical_scales_m":{"leafy_grass":2.,"grass_ground":2.51,"forest_ground_04":3.2,"rock_01":1.5,"brown_mud_03":1.3,"aerial_grass_rock":15.},"provenance":"eighteen existing official CC0 channels unchanged + declared project-native humus/earth/sand/snow; soil mineral detail is forest_ground_04, not a claimed road scan","geometry":"no VERTEX modification; inherited Float32 RF/world mesh/selector unchanged"})
	return material

func water_material(height_rf: Texture2D,grid_origin: Vector2i,grid_shape: Vector2i) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled,blend_mix,depth_draw_never;
uniform sampler2D actual_height_rf:filter_nearest,repeat_disable;
uniform ivec2 grid_origin;uniform ivec2 grid_shape;
varying vec3 xyz;void vertex(){xyz=VERTEX;}
float bed(vec2 p){vec2 q=p/8.-vec2(grid_origin);ivec2 c=clamp(ivec2(floor(q)),ivec2(0),grid_shape-ivec2(2));vec2 f=clamp(q-vec2(c),vec2(0.),vec2(1.));float a=texelFetch(actual_height_rf,c,0).r,b=texelFetch(actual_height_rf,c+ivec2(1,0),0).r,d=texelFetch(actual_height_rf,c+ivec2(1,1),0).r,e=texelFetch(actual_height_rf,c+ivec2(0,1),0).r;return f.x+f.y<=1.?a+(b-a)*f.x+(e-a)*f.y:d+(e-d)*(1.-f.x)+(b-d)*(1.-f.y);}
void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 float depth=-.025-bed(p);if(depth<=0.)discard;
 // Static global phases keep byte-exact captures possible. 28-60cm ripples
 // remain 20-60 logical pixels at this camera, not a flat sky-blue gradient.
 // Static noncommensurate phase warping prevents ROOT123's regular spot grid.
 // Restrained ripples are lit surface detail, not opaque foam dots or a flow
 // simulation. No TIME, no receiver-local origin, no ownership/nav changes.
 float warp=1.7*sin(xyz.x*.73+xyz.z*.41)+.9*cos(xyz.z*1.13-xyz.x*.29);
 float a=xyz.x*13.1+xyz.z*5.7+warp,b=xyz.z*19.3-xyz.x*3.6+.61*warp;
 vec2 slope=vec2(.018*cos(a)+.006*cos(b)*-.19,.008*cos(a)+.019*cos(b));
 vec3 wn=normalize(vec3(-slope.x,1.,-slope.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
 float crest=pow(max(0.,.55*sin(a)+.45*sin(b)),8.);
 float deep=smoothstep(.035,.45,depth);
 vec3 shallow=vec3(.255,.29,.205),channel=vec3(.095,.205,.19);
 ALBEDO=mix(shallow,channel,deep)+vec3(.007,.011,.009)*crest;
 ROUGHNESS=mix(.53,.43,deep)+crest*.015;SPECULAR=.25;METALLIC=0.;
 // Steeper opacity falloff leaves a narrow visible sediment shallows band.
 // Actual RF triangles still exclusively decide shoreline and water support.
 ALPHA=mix(.38,.96,smoothstep(.008,.11,depth));
}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("actual_height_rf",height_rf)
	material.set_shader_parameter("grid_origin",grid_origin)
	material.set_shader_parameter("grid_shape",grid_shape)
	v7_material_records.append({"identity":V7_WATER_ID,"shader_code_sha256":_v7_code_sha(shader.code),"status":"PROPOSAL_MATERIAL_CREATED_NOT_GPU_VALIDATED","same_RF_texture_bound":material.get_shader_parameter("actual_height_rf")==height_rf,"grid_origin":grid_origin,"grid_shape":grid_shape,"interpolation":"unchanged8px [a,b,c,b,d,c] actual Float32 triangle; depth=-.025-bed","wave_phase":"static global worldXZ, no TIME/window offset/random draw","wave_scope":"project-native lit wave normal + low-amplitude crest colour; NOT captured fluid/refraction or sourced water scan","shore_risk":"8px contour geometry unchanged, so this revision cannot claim geometric removal of any existing shore faceting"})
	return material

func _v7_binding_evidence(material: ShaderMaterial) -> Dictionary:
	var result: Dictionary={}
	for record in evidence:
		var path: String=record["path"]
		var key: String=path.get_file().trim_suffix("_2k.jpg")
		result[key]={"path":path,"sha256":record["sha256"],"physical_width_m":record["physical_width_m"],"actual_mip_count":record["actual_mip_count"],"same_registered_texture_object":material.get_shader_parameter(key)==textures.get(key)}
	return result

func _v7_code_sha(code: String) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if context.update(code.to_utf8_buffer())!=OK: return ""
	return context.finish().hex_encode()

func release() -> void:
	v7_material_records.clear()
	super.release()
