extends "res://scripts/dev/build_world_map_native_pair_ortho_v7.gd"

# Native two-region visual candidate; v7 route/river/portal geometry is retained.
# Terrain, natural-land and walk silhouettes still use one orthographic camera.
# No entity sprites are baked here: contact soil belongs to the terrain only.
var _contact_sites: Array[Dictionary] = []
var _height_roads: Array[Vector2] = []


func _output_prefix() -> String:
	return "res://build/world_native_pair_ortho_v8_"


func _ellipse_weight(p: Vector2, center: Vector2, radius: Vector2, outer: float = 2.0) -> float:
	return 1.0 - smoothstep(1.0,outer,((p-center)/radius).length())


func _height(pixel: Vector2, topology: Image) -> float:
	# Wide shoulders replace tall narrow hills and the rectangular pad cliffs.
	# The ridge peaks live away from authored settlements and the bridge axis.
	var west := 1.75 * exp(-pow((pixel.x-325.0)/410.0,2.0)-pow((pixel.y-140.0)/240.0,2.0))
	var east := 1.20 * exp(-pow((pixel.x-2110.0)/490.0,2.0)-pow((pixel.y-0.0)/290.0,2.0))
	var south := 0.82 * exp(-pow((pixel.x-1120.0)/610.0,2.0)-pow((pixel.y-1180.0)/400.0,2.0))
	var folds := 0.05*sin(pixel.x*0.007+pixel.y*0.011)+0.03*sin(pixel.x*0.016-pixel.y*0.009)
	var elevation := maxf(0.0,west+east+south+folds)
	var road_distance := _height_road_distance(pixel)
	road_distance = minf(road_distance,_segment_distance(pixel,CONTRACT.CITY_SPUR[0],CONTRACT.CITY_SPUR[1]))
	road_distance = minf(road_distance,_segment_distance(pixel,CONTRACT.FERRY_SPUR[0],CONTRACT.FERRY_SPUR[1]))
	var flatten := 1.0-smoothstep(52.0,210.0,road_distance)
	flatten = maxf(flatten,_ellipse_weight(pixel,Vector2(900,270),Vector2(310,190),2.0))
	flatten = maxf(flatten,_ellipse_weight(pixel,Vector2(2410,645),Vector2(225,175),2.0))
	flatten = maxf(flatten,1.0-smoothstep(95.0,320.0,absf(pixel.x-_river_x(pixel.y))))
	# Existing sprites are screen-space entities: ground is flat at their full
	# bases rather than moving physics or pretending their cutout changed pose.
	for site in _contacts():
		var foot: Vector2 = site["foot"]
		var radius: Vector2 = site["radius"]
		flatten = maxf(flatten,_ellipse_weight(pixel,foot,radius+Vector2(26,22),2.8))
	return elevation * (1.0-flatten) * smoothstep(86.0,320.0,_coast_distance(pixel))


func _height_road_distance(pixel: Vector2) -> float:
	if _height_roads.is_empty():
		for x in range(-352,SIZE.x+385,32):
			_height_roads.append(Vector2(x,_road_y(x)))
	var index := clampi(floori((pixel.x+352)/32.0),0,_height_roads.size()-2)
	var distance := INF
	# Height pads use actual nearby curve distance. The nav normal-width
	# approximation is fine for road cores, but using it 200px off an acute
	# bend produced a fake vertical ridge when that derivative changed.
	for segment in range(maxi(0,index-10),mini(_height_roads.size()-1,index+11)):
		distance=minf(distance,_segment_distance(pixel,_height_roads[segment],_height_roads[segment+1]))
	return distance


func _contacts() -> Array[Dictionary]:
	if not _contact_sites.is_empty():
		return _contact_sites
	for object in CONTRACT.scene_objects():
		if not object.has("collision_size"):
			continue
		var foot: Vector2 = object["pos"]*CONTRACT.WORLD_SIZE+object["collision_offset"]*CONTRACT.WORLD_SIZE
		var radius: Vector2 = object["collision_size"]*CONTRACT.WORLD_SIZE*0.65
		_contact_sites.append({"id":object["id"],"foot":foot,"radius":radius})
	_contact_sites.append({"id":"city_foundation","foot":Vector2(900,345),"radius":Vector2(280,35)})
	_contact_sites.append({"id":"ferry_pavilion_foundation","foot":Vector2(2310,605),"radius":Vector2(95,24)})
	return _contact_sites


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	if mask:
		return super._surface_material(color,selector,true)
	var contact_code := "float contact_soil(vec2 p) {float value=0.0;\n"
	for site in _contacts():
		var foot: Vector2 = site["foot"]
		var radius: Vector2 = site["radius"]
		contact_code += "value=max(value,1.0-smoothstep(0.55,1.65,length((p-vec2(%f,%f))/vec2(%f,%f))));\n" % [foot.x,foot.y,radius.x,radius.y]
	contact_code += "return value;}\n"
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform sampler2D topology_tex : filter_nearest;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D road_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_tex : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 terrain_normal;
void vertex(){terrain_normal=NORMAL;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*0.56+noise(p*2.03+17.1)*0.28+noise(p*4.11+43.7)*0.16;}
""" + contact_code + """
void fragment(){
 vec2 p=UV*vec2(3072.0,1024.0);
 vec4 topo=texture(topology_tex,clamp(UV,vec2(0),vec2(1)));
 if(topo.r<0.5){discard;}
 vec2 warp=vec2(noise(p/260.0),noise((p+vec2(550,213))/310.0))-0.5;
 float broad=fbm((p+warp*130.0)/360.0);
 float patch=fbm((p+warp*90.0)/160.0);
 float detail=noise(p/18.0);
 vec2 guv=p/890.0+warp*0.19;
 vec2 guv_b=(-p.yx+vec2(371,159))/1210.0;
 // Remove the scan's large baked aerial swirls before mixing actual detail.
 // Sampling whole diffuse tiles at enormous scale preserved those swirls.
 vec3 ga=textureLod(grass_tex,guv,2.5).rgb-textureLod(grass_tex,guv,7.0).rgb;
 vec3 gb=textureLod(grass_tex,guv_b,2.5).rgb-textureLod(grass_tex,guv_b,7.0).rgb;
 vec3 scan_detail=clamp(mix(ga,gb,0.45),vec3(-0.09),vec3(0.09));
 vec3 grass=mix(vec3(0.29,0.355,0.185),vec3(0.375,0.425,0.255),broad);
 grass+=scan_detail*0.75;
 grass*=0.90+0.17*fbm(p/4.5);
 vec3 soil_sample=texture(road_tex,(p+warp*65.0)/720.0).rgb;
 float soil_luma=dot(soil_sample,vec3(0.299,0.587,0.114));
 vec3 soil=mix(vec3(0.37,0.32,0.235),vec3(soil_luma)*vec3(1.42,1.27,0.96),0.35);
 float dry=smoothstep(0.43,0.73,patch)*(0.22+0.64*smoothstep(0.24,0.73,broad));
 vec3 land=mix(grass,soil,dry);
 vec3 stone=texture(rock_tex,(p+warp*80.0+vec2(95,211))/780.0).rgb*vec3(0.78,0.83,0.76);
 float slope=1.0-normalize(terrain_normal).y;
 float exposure=smoothstep(0.09,0.29,slope)*smoothstep(0.37,0.74,patch);
 land=mix(land,stone,exposure*0.60);
 float y=clamp(p.y,0.0,1023.0);
 float coast=2795.0-0.39*y+46.0*sin(y*0.0082)+24.0*sin(y*0.021)-p.x;
 float river=abs(p.x-(1660.0+28.0*sin((p.y-365.0)*0.004)))-64.0;
 float shore_width=22.0+35.0*fbm(vec2(p.y/110.0,p.x/370.0));
 float bank=(1.0-smoothstep(2.0,shore_width,min(coast,river)));
 land=mix(land,mix(soil,stone,0.24+0.42*patch),bank*0.88);
 float contact=contact_soil(p);
 float compressed=contact*(0.74+0.26*detail);
 land=mix(land,soil*0.83,compressed*0.65);
 land*=1.0-contact*0.10;
 float road=topo.g;
 vec3 path=mix(soil*1.12,soil_sample*vec3(1.57,1.44,1.14),0.48);
 land=mix(land,path,road*0.94);
 land*=0.93+0.12*broad;
 ALBEDO=land;ROUGHNESS=1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("topology_tex",selector)
	material.set_shader_parameter("grass_tex",load(GRASS_PH))
	material.set_shader_parameter("road_tex",load(ROAD_PH))
	material.set_shader_parameter("rock_tex",load(ROCK_MAT))
	return material


func _after_outputs_saved(topology: Image) -> void:
	super._after_outputs_saved(topology)
	var sites: Array=[]
	for site in _contacts():
		var foot: Vector2=site["foot"]
		var radius: Vector2=site["radius"]
		sites.append({"id":site["id"],"foot":[foot.x,foot.y],"radius":[radius.x,radius.y]})
	var file := FileAccess.open(_output_prefix()+"art.json",FileAccess.WRITE)
	var slope_probes: Array=[]
	for point in [Vector2(530,180),Vector2(2070,180)]:
		slope_probes.append({"point":[point.x,point.y],"world_gradient":_gradient(point,topology)})
	var steep_examples: Array=[]
	for y in range(40,970,20):
		for x in range(40,2650,20):
			var point := Vector2(x,y)
			if _gradient(point,topology)>0.78 and _coast_distance(point)>100.0 and absf(point.x-_river_x(point.y))>100.0 and topology.get_pixel(x,y).g<0.02:
				steep_examples.append({"source_point":[x,y],"projected_point":[x,y-_height(point,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0)],"world_gradient":_gradient(point,topology)})
				if steep_examples.size()>=12:
					break
		if steep_examples.size()>=12:
			break
	file.store_string(JSON.stringify({"status":"ISOLATED_VISUAL_CANDIDATE","version":"v8","geometry_contract":"v7","contact_soil_sites":sites,"entities_baked":false,"external_sources":[GRASS_PH,ROAD_PH],"same_camera_visual_land_walk":true,"old_steep_probes":slope_probes,"steep_examples":steep_examples},"\t"))
	file.close()


func _gradient(pixel: Vector2, topology: Image) -> float:
	var dx := (_height(pixel+Vector2(6,0),topology)-_height(pixel-Vector2(6,0),topology))/(12.0*30.0/SIZE.x)
	var dz := (_height(pixel+Vector2(0,6),topology)-_height(pixel-Vector2(0,6),topology))/(12.0*Z_HALF*2.0/SIZE.y)
	return Vector2(dx,dz).length()


func _save_front_rail() -> void:
	# The v8 candidate reuses the validated v7 cutout without overwriting it.
	pass
