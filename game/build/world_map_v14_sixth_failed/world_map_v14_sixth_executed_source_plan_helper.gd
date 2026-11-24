extends RefCounted

# Self-contained sixth native authoring. No fifth RF/contract/build reads.
# Four official tileable materials, not the boulder model's UV atlas.
const SOURCE_DIR := "res://art/external/polyhaven/world_terrain_v14_sixth/"
const WATER_Y := -.025
const AMBIENT := .35
const DIRECT := .85
const PPM := 102.4
const ASSETS := [
	{"id":"rock_01","meters":1.5},{"id":"leafy_grass","meters":2.0},
	{"id":"forest_ground_04","meters":3.2},{"id":"brown_mud_03","meters":1.3}]
# Broad overlapping source-space habitats. Not chunk-aligned coloured squares.
# Weights are forest soil / exposed rock / moist soil, all backed by real scans.
const HABITATS := [
	["western_pass",Vector2(475,610),Vector2(620,430),.28,.78,.02],
	["grey_ridge",Vector2(1880,620),Vector2(820,465),.14,.83,.02],
	["northeastern_pine",Vector2(3550,920),Vector2(650,420),.73,.38,.05],
	["western_woodland",Vector2(585,1550),Vector2(550,630),.79,.12,.16],
	["central_fields",Vector2(2080,1560),Vector2(850,510),.34,.04,.04],
	["coastal_scrub",Vector2(3900,1570),Vector2(450,600),.47,.15,.28],
	["southwestern_meadow",Vector2(810,2490),Vector2(750,500),.23,.06,.39],
	["southern_floodplain",Vector2(2440,2540),Vector2(720,460),.30,.04,.62],
	["tea_foothills",Vector2(3580,2630),Vector2(660,500),.63,.24,.16]]
var textures: Dictionary = {}
var audit: Array[Dictionary] = []
var sky: Sky
var last_error := ""

func load_verified_sources() -> bool:
	if not textures.is_empty(): return true
	for spec in ASSETS:
		var id: String = spec["id"]
		var source_path := SOURCE_DIR+id+"/SOURCE.json"
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_path))
		if not raw is Dictionary or raw.get("asset","")!=id or raw.get("license","")!="CC0-1.0" or absf(float(raw.get("physical_width_m",0))-float(spec["meters"]))>.001:
			last_error="Official tileable source identity/CC0/metre scale rejected: "+source_path
			return false
		for channel: String in ["diff","nor_gl","arm"]:
			var path := SOURCE_DIR+id+"/"+id+"_"+channel+"_2k.jpg"
			var record: Dictionary={}
			for item in raw.get("channels",[]):
				if item.get("channel","")==channel: record=item
			var hash := FileAccess.get_sha256(path)
			if record.get("path","")!=path or not record.get("md5_verified",false) or hash=="" or String(record.get("sha256","")).to_lower()!=hash.to_lower():
				last_error="Registered source bytes/provenance rejected: "+path
				return false
			var image:=Image.load_from_file(path)
			if image==null or image.is_empty() or image.generate_mipmaps()!=OK or image.get_mipmap_count()==0:
				last_error="Actual mip generation failed: "+path
				return false
			textures[id+"_"+channel]=ImageTexture.create_from_image(image)
			audit.append({"path":path,"sha256":hash,"source_json":source_path,"source_json_sha256":FileAccess.get_sha256(source_path),"asset":id,"tile_width_m":spec["meters"],"actual_mipmap_count":image.get_mipmap_count(),"size":[image.get_width(),image.get_height()],"color_space":"sRGB source_color" if channel=="diff" else "linear data","arm_channels":"R AO/G roughness/B metallic","mip_method":"actual Image.generate_mipmaps then ImageTexture; no imported frozen bytes changed"})
	return true

func environment(transparent: bool=false) -> Environment:
	if sky==null:
		sky=Sky.new()
		var material:=ProceduralSkyMaterial.new()
		material.sky_top_color=Color(.23,.40,.60)
		material.sky_horizon_color=Color(.71,.77,.80)
		material.ground_bottom_color=Color(.21,.22,.18)
		material.ground_horizon_color=Color(.62,.66,.64)
		material.sky_energy_multiplier=.8
		sky.sky_material=material
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR if transparent else Environment.BG_SKY
	settings.background_color=Color.TRANSPARENT if transparent else Color(.05,.115,.135)
	settings.sky=sky
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color(.90,.94,1.)
	settings.ambient_light_energy=AMBIENT
	settings.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	return settings

func _chain(p: Vector2,knots: Array,width: float,asymmetry: float) -> float:
	var result:=0.
	for i in range(1,knots.size()):
		var a: Vector3=knots[i-1]
		var b: Vector3=knots[i]
		var start:=Vector2(a.x,a.y)
		var delta:=Vector2(b.x-a.x,b.y-a.y)
		var along:=clampf((p-start).dot(delta)/delta.length_squared(),0.,1.)
		var near:=start+delta*along
		var side:=signf(delta.cross(p-near))
		var shoulder:=width*(asymmetry if side>0 else 1.)
		var distance:=p.distance_to(near)/shoulder
		if distance>=1.: continue
		# Real crest/spur profile with broad feet; not a Gaussian hill field.
		var shape:=maxf(1.-pow(distance,.88),0.)
		var crest:=lerpf(a.z,b.z,along)
		var end_distance:=minf((p-start).dot(delta.normalized()),delta.length()-(p-start).dot(delta.normalized()))
		var taper:=smoothstep(-65.,25.,end_distance)
		result=maxf(result,crest*shape*taper)
	return result

func regional_relief(p: Vector2) -> float:
	# Disconnected northwest and central crests leave two low road passes.
	var northwest:=_chain(p,[Vector3(180,590,1.9),Vector3(370,490,2.7),Vector3(590,690,1.7),Vector3(710,610,1.0)],235.,.75)
	var central:=_chain(p,[Vector3(1130,490,2.25),Vector3(1450,650,3.0),Vector3(1720,480,3.65),Vector3(1930,690,2.1)],275.,.72)
	var northeast:=_chain(p,[Vector3(2160,495,2.3),Vector3(2430,585,3.05),Vector3(2730,790,1.8),Vector3(3050,710,1.5)],280.,.78)
	var eastern:=_chain(p,[Vector3(3320,425,1.05),Vector3(3540,590,1.85),Vector3(3760,840,1.20)],245.,.81)
	var north:=maxf(maxf(northwest,central),maxf(northeast,eastern))
	var north_flank:=smoothstep(540.,660.,p.y)*(1.-smoothstep(810.,1000.,p.y))
	var drainage:=pow(maxf(cos((p.x+.47*p.y)/63.),0.),10.)*.36*north_flank
	north=maxf(north-drainage,0.)
	var western:=_chain(p,[Vector3(140,1260,.95),Vector3(270,1440,1.45),Vector3(155,1770,.7)],210.,.78)
	var southeastern:=_chain(p,[Vector3(3890,2460,1.45),Vector3(4090,2650,1.9),Vector3(3950,2870,.85)],280.,.76)
	var tea:=_chain(p,[Vector3(2970,2670,.42),Vector3(3250,2430,.82),Vector3(3510,2690,.60)],380.,.9)
	# Broad agricultural rolling terrain and southern river terraces keep
	# native volume without repeating equidistant cones or rendered fake hills.
	var central_roll:=.22*maxf(1.-pow(((p-Vector2(1990,1510))/Vector2(830,480)).length(),1.7),0.)
	var meadow:=.15*maxf(1.-pow(((p-Vector2(820,2300))/Vector2(750,560)).length(),1.6),0.)
	var terrace:=.20*maxf(1.-pow(((p-Vector2(2900,1780))/Vector2(500,380)).length(),1.8),0.)
	return maxf(maxf(north,western),maxf(southeastern,tea))+.085+central_roll+meadow+terrace

func habitat_shader() -> String:
	var code:="vec3 habitat(vec2 p){vec3 sum=vec3(0.);float total=0.;"
	for region in HABITATS:
		var center: Vector2=region[1]
		var radius: Vector2=region[2]
		code+="{vec2 q=(p-vec2(%f,%f))/vec2(%f,%f);float w=pow(max(1.-smoothstep(.30,1.80,length(q)),0.),2.);sum+=vec3(%f,%f,%f)*w;total+=w;}"%[center.x,center.y,radius.x,radius.y,region[3],region[4],region[5]]
	return code+"return (sum+vec3(.28,.06,.12)*.08)/(total+.08);}"

func surface_code(mode: int,bank_code: String,foundation_code: String,cultivation_code: String) -> String:
	if mode>0:
		# Land is the actual visible dry triangle surface, not an independent
		# flat analytic coastline. Navigation additionally uses the conservative
		# continuous bank>24 + exact triangle slope selector in topo.B.
		return """shader_type spatial;render_mode cull_disabled,depth_draw_opaque,unshaded;
uniform sampler2D topo:filter_nearest;uniform int mode=1;uniform float water_y_m=-.025;
varying vec3 xyz;void vertex(){xyz=VERTEX;}
void fragment(){if(xyz.y<=water_y_m){discard;}ALBEDO=vec3(mode==1?1.:texture(topo,UV).b);}
"""
	var code:="shader_type spatial;render_mode cull_disabled,depth_draw_opaque;uniform sampler2D topo:filter_nearest;uniform int mode=0;uniform bool detail_normals=true;varying vec3 xyz;varying vec3 terrain_n;void vertex(){xyz=VERTEX;terrain_n=NORMAL;}"
	for spec in ASSETS:
		var id: String=spec["id"]
		code+="uniform sampler2D %s_diff:source_color,repeat_enable,filter_linear_mipmap;uniform sampler2D %s_nor_gl:hint_normal,repeat_enable,filter_linear_mipmap;uniform sampler2D %s_arm:repeat_enable,filter_linear_mipmap;"%[id,id,id]
	code+="""
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+1.),f.x),f.y);}
float shore(float y){float bw=mix(108.,82.,smoothstep(1730.,1790.,y));return 4355.+55.*sin(y/285.)-125.*exp(-pow((y-1290.)/116.,2.))-135.*exp(-pow((y-1730.)/bw,2.));}
vec3 tri(sampler2D image,vec3 p,vec3 w,float meters){return texture(image,p.zy/meters).rgb*w.x+texture(image,p.xz/meters).rgb*w.y+texture(image,p.xy/meters).rgb*w.z;}
vec3 detail(sampler2D image,vec3 p,vec3 g,vec3 w,float meters){
 vec3 nx=texture(image,p.zy/meters).rgb*2.-1.,ny=texture(image,p.xz/meters).rgb*2.-1.,nz=texture(image,p.xy/meters).rgb*2.-1.;
 vec3 q=vec3(0.,nx.y,nx.x)*w.x+vec3(ny.x,0.,ny.y)*w.y+vec3(nz.x,nz.y,0.)*w.z;return q-g*dot(q,g);
}
"""
	code+=bank_code+habitat_shader()+foundation_code+cultivation_code
	code+="""
void fragment(){
 vec2 p=UV*vec2(4608.,3072.);vec3 g=normalize(terrain_n);vec3 w=pow(abs(g),vec3(5.));w/=max(dot(w,vec3(1.)),.0001);
 vec3 biome=habitat(p);float road=texture(topo,UV).g;float bank=bank_distance(p);
 float forest=biome.x*(1.-road);float rock=max(biome.y*smoothstep(.15,1.4,xyz.y),smoothstep(.13,.43,1.-g.y)*smoothstep(.18,1.2,xyz.y));
 float wet=max(1.-smoothstep(3.,58.,bank),biome.z*.48);
 wet=max(wet,1.-smoothstep(-.12,.04,xyz.y));
 vec3 grass=tri(leafy_grass_diff,xyz,w,2.),soil=tri(forest_ground_04_diff,xyz,w,3.2),stone=tri(rock_01_diff,xyz,w,1.5),mud=tri(brown_mud_03_diff,xyz,w,1.3);
 vec3 color=mix(grass,soil,forest);color=mix(color,stone,rock);color=mix(color,mud,wet*.86);
 color=cultivated_land(p,color,soil,grass);
 color=mix(color,mix(soil,mud,.12)*vec3(.78,.75,.70),road*.94);
 vec2 foundation=site_contact(p);color=mix(color,mix(soil,stone,.18),foundation.x*.32);color*=1.-foundation.y;
 vec3 arm=mix(tri(leafy_grass_arm,xyz,w,2.),tri(forest_ground_04_arm,xyz,w,3.2),forest);arm=mix(arm,tri(rock_01_arm,xyz,w,1.5),rock);arm=mix(arm,tri(brown_mud_03_arm,xyz,w,1.3),wet*.86);arm=mix(arm,tri(forest_ground_04_arm,xyz,w,3.2),road*.94);
 vec3 q=mix(detail(leafy_grass_nor_gl,xyz,g,w,2.),detail(forest_ground_04_nor_gl,xyz,g,w,3.2),forest);q=mix(q,detail(rock_01_nor_gl,xyz,g,w,1.5),rock);q=mix(q,detail(brown_mud_03_nor_gl,xyz,g,w,1.3),wet*.86);q=mix(q,detail(forest_ground_04_nor_gl,xyz,g,w,3.2)*.35,road*.94);
 vec3 wn=normalize(g+(detail_normals?q:vec3(0.))*.70);NORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(wn,0.)).xyz);
 ALBEDO=color;AO=mix(1.,arm.r,.60);ROUGHNESS=clamp(arm.g,.22,.98);METALLIC=0.;SPECULAR=.35;
}
"""
	return code

func water_code() -> String:
	return """shader_type spatial;render_mode cull_disabled,blend_mix,depth_draw_never;
uniform sampler2D actual_height_rf:filter_nearest,repeat_disable;
uniform ivec2 grid_shape=ivec2(769,513);uniform float water_y_m=-.025;
varying vec3 xyz;void vertex(){xyz=VERTEX;}
float triangle_height(vec2 source){
 vec2 u=source/6.;ivec2 cell=clamp(ivec2(floor(u)),ivec2(0),grid_shape-ivec2(2));vec2 f=clamp(u-vec2(cell),vec2(0.),vec2(1.));
 float a=texelFetch(actual_height_rf,cell,0).r,b=texelFetch(actual_height_rf,cell+ivec2(1,0),0).r,c=texelFetch(actual_height_rf,cell+ivec2(0,1),0).r,d=texelFetch(actual_height_rf,cell+ivec2(1,1),0).r;
 return f.x+f.y<=1.?a+(b-a)*f.x+(c-a)*f.y:d+(c-d)*(1.-f.x)+(b-d)*(1.-f.y);
}
void fragment(){
 float depth=water_y_m-triangle_height(UV*vec2(4608.,3072.));if(depth<=0.){discard;}
 vec2 q=vec2(.034*cos(xyz.x*5.7+xyz.z*1.3)+.018*cos(xyz.z*11.9),.045*cos(xyz.z*6.9-xyz.x*1.8));
 vec3 wn=normalize(vec3(-q.x,1.,-q.y));NORMAL=normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(wn,0.)).xyz);
 ALBEDO=mix(vec3(.22,.34,.29),vec3(.085,.24,.28),smoothstep(.03,.70,depth));
 ROUGHNESS=.18;SPECULAR=.68;METALLIC=0.;ALPHA=mix(.30,.85,smoothstep(.015,1.1,depth));
}
"""
