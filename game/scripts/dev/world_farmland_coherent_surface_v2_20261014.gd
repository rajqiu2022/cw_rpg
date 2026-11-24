extends "res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd"
## Rewrite only the original fragment's finite farm block, never captured pixels.
const AUTHOR := preload("res://scripts/dev/world_farmland_coherent_author_v2_20261014.gd")
const ID := "WORLD_COHERENT_FARMLAND12_NATIVE_VISUAL_PHASE1_20261014"
var patch_record: Dictionary = {}

func rewrite_original(material: ShaderMaterial,clearance_rf: Texture2D) -> ShaderMaterial:
	if material == null or material.shader == null: error="Missing saved native terrain material."; return null
	var old := material.shader.code
	var start := old.find("float field_owner=0.,crop=0.,furrow_n=0.;")
	var end := old.find(" field_owner*=.88*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);")
	if start < 0 or end <= start or old.count("float angle=sin(") != 18:
		error="Original actual shader's exact18 finite farm block absent."; return null
	var code := old.substr(0,start)+AUTHOR.new().literal_code()+old.substr(end)
	var clearance_header := """uniform sampler2D farm_clearance_rf : filter_nearest, repeat_disable;
float farm_h(vec2 point){
 vec2 q=point/8.;ivec2 base=clamp(ivec2(floor(q)),ivec2(0),ivec2(1535,1023));vec2 f=q-vec2(base);
 float a=texelFetch(farm_clearance_rf,base,0).r,b=texelFetch(farm_clearance_rf,base+ivec2(1,0),0).r;
 float c=texelFetch(farm_clearance_rf,base+ivec2(0,1),0).r,d=texelFetch(farm_clearance_rf,base+ivec2(1,1),0).r;
 return f.x+f.y<=1.?a+(b-a)*f.x+(c-a)*f.y:d+(c-d)*(1.-f.x)+(b-d)*(1.-f.y);
}
"""
	code=code.replace("void fragment(){",clearance_header+"void fragment(){")
	# Road.g includes the old shoulder. Hard exclusion—not old soft route fade.
	var previous := " field_owner*=.88*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);"
	var guard := " if(field_owner>0.){float farm_forbidden=max(max(road.r,road.g),max(max(forest,wet),max(rock,max(snow,sand))));\n float farm_water=1.;\n"
	for y in [-32,0,32]:
		for x in [-32,0,32]:
			guard += " {vec3 near_road=texture(road_weights,uv+vec2(%d.,%d.)/source_rect.zw).rgb;farm_forbidden=max(farm_forbidden,max(near_road.r,max(near_road.g,near_road.b)));}\n"%[x,y]
	for y in [-64,0,64]:
		for x in [-64,0,64]:
			guard += " farm_water*=step(-.015,farm_h(p+vec2(%d.,%d.)));\n"%[x,y]
	guard += " field_owner*=.72*(1.-step(.02,farm_forbidden))*farm_water;}\n"
	if code.count(previous) != 1: error="Farm-only exclusion anchor ambiguous."; return null
	code = code.replace(previous,guard)
	var copied := material.duplicate(false) as ShaderMaterial
	var uniforms: Dictionary = {}
	for item: Dictionary in material.shader.get_shader_uniform_list(): uniforms[item.name]=material.get_shader_parameter(item.name)
	var shader := Shader.new(); shader.code = code; copied.shader = shader
	for name: String in uniforms: copied.set_shader_parameter(name,uniforms[name])
	copied.set_shader_parameter("farm_clearance_rf",clearance_rf)
	patch_record = {"identity":ID,"parcel_count":12,"groups":2,"angle_radians":0.0,"old_random18_removed":code.count("float angle=sin(")==0,"uniforms_original_preserved":true,"vertex_function_original_preserved":code.substr(0,code.find("void fragment(){")).replace(clearance_header,"") == old.substr(0,old.find("void fragment(){")),"actual_clearance_RF_bound":copied.get_shader_parameter("farm_clearance_rf")==clearance_rf,"road_clearance_px":32,"water_clearance_px":64,"clearance_samples_per_fragment":[9,9],"old_code_sha256":_v7_code_sha(old),"new_code_sha256":_v7_code_sha(code),"scope":"NATIVE_VISUAL_MATERIAL_CANDIDATE_ONLY","RF_NAV_objects_changed":false,"visual_approved":false,"production_approved":false}
	return copied
