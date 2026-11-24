extends "res://scripts/dev/build_world_map_native_pair_ortho_v9.gd"

# The inherited GEOGRAPHY remains explicitly v9: height/nav/contact flattening
# are frozen. A new material and output boundary do NOT replace static consts.
const V10 := preload("res://scripts/dev/world_native_pair_landmark_contract_v10.gd")
var _v10_sites: Array[Dictionary]=[]
var _frozen_hashes: Dictionary={}


func _initialize() -> void:
	call_deferred("_build")


func _output_prefix() -> String:
	return V10.PREFIX


func _read_png(path: String) -> Image:
	# Read the actual frozen v9 topology, never regenerate it from a parent
	# SOURCE_PREFIX or accidentally consult the older v2 river stencil.
	var actual: String=GEOGRAPHY.PREFIX+"topology.png" if path.ends_with("topology.png") else path
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(actual))==OK else null


func _contact_sites_v10() -> Array[Dictionary]:
	if not _v10_sites.is_empty():
		return _v10_sites
	for object in GEOGRAPHY.scene_objects():
		if not object.has("collision_size"):
			continue
		var foot: Vector2=object["pos"]*GEOGRAPHY.WORLD_SIZE+object["collision_offset"]*GEOGRAPHY.WORLD_SIZE
		var footprint: Vector2=object["collision_size"]*GEOGRAPHY.WORLD_SIZE
		_v10_sites.append({"id":object["id"],"foot":foot,"radius":footprint*Vector2(0.58,0.54),"offset":Vector2(5,footprint.y*0.23),"strength":0.56 if String(object["id"]).begins_with("cc0_boulder") else 0.43})
	_v10_sites.append({"id":"city_wall_ground","foot":Vector2(900,349),"radius":Vector2(267,15),"offset":Vector2(3,5),"strength":0.30})
	_v10_sites.append({"id":"pavilion_dry_foundation","foot":Vector2(2300,603),"radius":Vector2(76,12),"offset":Vector2(3,4),"strength":0.27})
	return _v10_sites


func _contact_shader() -> String:
	var code := "vec2 entity_contact(vec2 p){float soil=0.0;float ao=0.0;\n"
	for site in _contact_sites_v10():
		var foot: Vector2=site["foot"]
		var radius: Vector2=site["radius"]
		var offset: Vector2=site["offset"]
		code+="{vec2 d=(p-vec2(%f,%f))/vec2(%f,%f);float r=length(d);float grain=noise(p/6.0);soil=max(soil,(1.0-smoothstep(0.62,1.25,r+(grain-0.5)*0.18)));vec2 s=(p-vec2(%f,%f))/vec2(%f,%f);float core=exp(-dot(s,s)*2.6)*(1.0-smoothstep(0.82,1.08,r));ao=max(ao,core*%f);}\n" % [foot.x,foot.y,radius.x,radius.y,foot.x+offset.x,foot.y+offset.y,radius.x*0.91,radius.y*0.69,site["strength"]]
	# Diagnostics and visible contact share THIS function. No ocean/structure
	# contact is drawn, even where an authored entity has a ground footprint.
	code+="float support=1.0;\n"
	for rect in [GEOGRAPHY.BRIDGE_DECK,GEOGRAPHY.DOCK_DECKS[0],GEOGRAPHY.DOCK_DECKS[1]]:
		code+="if(p.x>=%f&&p.x<%f&&p.y>=%f&&p.y<%f){support=0.0;}\n" % [rect.position.x,rect.end.x,rect.position.y,rect.end.y]
	code+="return vec2(soil,ao)*support;}\n"
	return code


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	if mask:
		return super._surface_material(color,selector,true)
	var shader := Shader.new()
	shader.code="""
shader_type spatial;
render_mode cull_disabled,depth_draw_opaque;
uniform sampler2D topology_tex : filter_nearest;
uniform sampler2D grass_tex : source_color,repeat_enable,filter_linear_mipmap;
uniform sampler2D road_tex : source_color,repeat_enable,filter_linear_mipmap;
uniform sampler2D rock_tex : source_color,repeat_enable,filter_linear_mipmap;
uniform bool contact_debug=false;
varying vec3 terrain_normal;
void vertex(){terrain_normal=NORMAL;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*0.56+noise(p*2.03+17.1)*0.28+noise(p*4.11+43.7)*0.16;}
// Irregular stone cells with small worn joints, not a rectilinear gray grid.
vec2 paving_cells(vec2 p){vec2 i=floor(p);float a=20.0;float b=20.0;float shade=0.0;for(int y=-1;y<=1;y++){for(int x=-1;x<=1;x++){vec2 g=i+vec2(float(x),float(y));vec2 q=g+vec2(0.18+0.64*hash(g),0.18+0.64*hash(g+91.0));float d=length(p-q);if(d<a){b=a;a=d;shade=hash(g+37.0);}else if(d<b){b=d;}}}return vec2(b-a,shade);}
"""+_geography_shader()+_contact_shader()+"""
void fragment(){
 vec2 p=UV*vec2(3072,1024);
 vec4 topo=texture(topology_tex,clamp(UV,vec2(0),vec2(1)));
 if(topo.r<0.5){discard;}
 vec2 warp=vec2(noise(p/310.0),noise((p+vec2(550,213))/370.0))-0.5;
 float broad=fbm((p+warp*75.0)/360.0);
 float patch=fbm((p+warp*50.0)/140.0);
 // Keep actual scan's middle/fine structure, remove only its aerial swirls.
 vec2 guv=(p+warp*35.0)/610.0;
 vec2 guv_b=(-p.yx+vec2(371,159))/790.0;
 vec3 ga=textureLod(grass_tex,guv,1.35).rgb-textureLod(grass_tex,guv,7.0).rgb;
 vec3 gb=textureLod(grass_tex,guv_b,1.65).rgb-textureLod(grass_tex,guv_b,7.0).rgb;
 vec3 scan=clamp(mix(ga,gb,smoothstep(0.24,0.77,patch)),vec3(-0.16),vec3(0.16));
 vec3 grass=mix(vec3(0.245,0.315,0.145),vec3(0.37,0.415,0.24),broad)+scan*1.25;
 grass*=0.87+0.24*fbm(p/3.4);
 vec3 roadscan=texture(road_tex,(p+warp*22.0)/430.0).rgb;
 float stonegrain=dot(roadscan,vec3(0.299,0.587,0.114));
 vec3 soil=mix(vec3(0.35,0.295,0.21),vec3(stonegrain)*vec3(1.37,1.22,0.90),0.64);
 float dry=smoothstep(0.42,0.71,patch)*(0.26+0.56*smoothstep(0.24,0.73,broad));
 vec3 land=mix(grass,soil,dry);
 vec3 stonescan=texture(rock_tex,(p+vec2(95,211))/420.0).rgb;
 vec3 stone=stonescan*vec3(0.80,0.85,0.78);
 float slope=1.0-normalize(terrain_normal).y;
 float exposure=smoothstep(0.08,0.27,slope)*smoothstep(0.34,0.73,patch);
 land=mix(land,stone,exposure*0.72);
 float y=clamp(p.y,0.0,1023.0);
 float coast=shore_x(y)-p.x;
 float river=abs(p.x-river_center(y))-river_width(y);
 float bank=1.0-smoothstep(2.0,22.0+22.0*fbm(p/85.0),min(coast,river));
 land=mix(land,mix(soil,stone,0.50),bank*0.86);
 float rockbelt=exp(-pow((p.y-(190.0+45.0*sin(p.x/180.0)))/88.0,2.0))*exp(-pow((p.x-210.0)/520.0,2.0));
 land=mix(land,stone*1.04,rockbelt*0.86);
 float road=topo.g;
 vec3 path=mix(soil*1.09,roadscan*vec3(1.39,1.27,1.03),0.57);
 land=mix(land,path,road*0.94);
 // Existing courtyard extent retained; breaks/moss wear its edge and joints.
 float plaza=boxzone(p,vec2(900,381),vec2(274,45),28.0);
 plaza*=0.75+0.25*smoothstep(0.12,0.72,noise(p/17.0));
	vec2 cells=paving_cells((p+warp*9.0)/20.0);
	float joint=1.0-smoothstep(0.035,0.105,cells.x);
	float pavegrain=dot(stonescan,vec3(0.299,0.587,0.114));
	vec3 paving=vec3(0.455,0.47,0.435)+(pavegrain-0.32)*0.33;
	paving*=0.83+0.22*cells.y;
	paving+=clamp(roadscan-vec3(stonegrain),vec3(-0.06),vec3(0.06))*0.30;
	paving=mix(paving,mix(soil*0.81,grass*0.86,0.18),joint*0.71);
 land=mix(land,paving,plaza*0.92);
 // Eroded irregular field borders and scan-filled soil replace solid strips.
 vec2 fieldp=p+(vec2(noise(p/35.0),noise((p+77.0)/41.0))-0.5)*25.0;
 float fields=max(boxzone(fieldp,vec2(693,501),vec2(105,49),27.0),boxzone(fieldp,vec2(1168,569),vec2(108,42),27.0));
 float furrow=0.5+0.5*sin((p.x+p.y*0.21+noise(p/28.0)*3.0)/4.8);
 vec3 cultivated=mix(soil*0.78,grass*0.74,furrow*0.35);
 land=mix(land,cultivated,fields*0.67);
 float landing=boxzone(p,vec2(2370,720),vec2(85,35),27.0);
 land=mix(land,mix(soil,paving,0.36),landing*0.65);
 vec2 contact=entity_contact(p);
 land=mix(land,soil*0.91,contact.x*0.58);
 land*=1.0-contact.y;
 land*=0.94+0.12*broad;
 ALBEDO=contact_debug ? vec3(max(contact.x,contact.y)) : land;
 ROUGHNESS=1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("topology_tex",selector)
	material.set_shader_parameter("grass_tex",load(GRASS_PH))
	material.set_shader_parameter("road_tex",load(ROAD_PH))
	material.set_shader_parameter("rock_tex",load(ROCK_MAT))
	return material


func _contact_viewport(color: Texture2D, selector: Texture2D, topology: Image) -> SubViewport:
	var viewport := _make_viewport(color,selector,topology,false)
	var world := viewport.get_child(0)
	var meshes: Array[MeshInstance3D]=[]
	for child in world.get_children():
		if child is WorldEnvironment:
			child.environment.background_color=Color.BLACK
		if child is MeshInstance3D:
			meshes.append(child)
	meshes[0].visible=false # Water base has no contact. Same land mesh/camera.
	var material := meshes[1].material_override as ShaderMaterial
	material.shader.code=material.shader.code.replace("render_mode cull_disabled,depth_draw_opaque;","render_mode cull_disabled,depth_draw_opaque,unshaded;")
	material.set_shader_parameter("contact_debug",true)
	return viewport


func _same_pixels(a: Image, b: Image) -> bool:
	if a==null or b==null or a.get_size()!=b.get_size():
		return false
	var first := a.duplicate() as Image
	var second := b.duplicate() as Image
	first.convert(Image.FORMAT_RGBA8)
	second.convert(Image.FORMAT_RGBA8)
	return first.get_data()==second.get_data()


func _sha(path: String) -> String:
	return FileAccess.get_sha256(path)


func _freeze_hashes() -> void:
	var suffixes: Array[String]=["visual.png","land.png","walk.png","center.png","center_land.png","center_walk.png","coast.png","coast_land.png","coast_walk.png","topology.png","route.json","art.json","ferry_pavilion_foreground.png","ferry_near_rail.png"]
	for part in GEOGRAPHY.RAIL_PARTS:
		suffixes.append("ferry_rail_"+String(part["name"])+".png")
	for suffix in suffixes:
		_frozen_hashes[GEOGRAPHY.PREFIX+suffix]=_sha(GEOGRAPHY.PREFIX+suffix)
	for path in ["res://scripts/dev/build_world_map_native_pair_ortho_v9.gd","res://scripts/dev/world_native_pair_landmark_contract_v9.gd","res://scripts/dev/run_world_native_pair_landmark_v9.gd"]:
		_frozen_hashes[path]=_sha(path)


func _after_outputs_saved(_topology: Image) -> void:
	# Never call the v9 hook: its fixed metadata/version and geometric rebuild
	# are wrong for a material-only candidate. Copy immutable evidence instead.
	var suffixes: Array[String]=["topology.png","route.json","ferry_pavilion_foreground.png","ferry_near_rail.png"]
	for part in GEOGRAPHY.RAIL_PARTS:
		suffixes.append("ferry_rail_"+String(part["name"])+".png")
	for suffix in suffixes:
		var file := FileAccess.open(V10.PREFIX+suffix,FileAccess.WRITE)
		file.store_buffer(FileAccess.get_file_as_bytes(GEOGRAPHY.PREFIX+suffix))
		file.close()
	var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(GEOGRAPHY.PREFIX+"art.json"))
	metadata["version"]="v10"
	metadata["geometry_contract"]="frozen_v9"
	metadata["material_only_geometry_frozen"]=true
	metadata["inherited_const_policy"]="v9_GEOGRAPHY_intentionally_frozen_v10_output_hook_explicit"
	metadata["v9_source_hashes"]=_frozen_hashes
	metadata["contact_actual_shader_capture"]="contact.png"
	metadata["contact_exclusions"]={"natural_water":true,"bridge_deck":true,"dock_decks":true,"dry_road_not_blanket_excluded":true}
	metadata["removed_visual_prop_field"]="ground_shadow_size_px"
	var sites: Array=[]
	for site in _contact_sites_v10():
		var foot: Vector2=site["foot"]
		var radius: Vector2=site["radius"]
		var offset: Vector2=site["offset"]
		sites.append({"id":site["id"],"foot":[foot.x,foot.y],"radius":[radius.x,radius.y],"light_offset":[offset.x,offset.y],"ao_strength":site["strength"]})
	metadata["contact_material_sites"]=sites
	metadata["visual_status"]="AWAITING_FIELD_REVIEW_NOT_PROMOTED"
	metadata["material_render_rounds"]=2
	metadata["targeted_second_revision"]="gray_irregular_paving_larger_cells_narrow_contact_core_only_grass_frozen"
	metadata["asset_sources"]={"CC0":[GRASS_PH,ROAD_PH],"existing_project_candidate_materials":[ROCK_MAT,WATER_MAT],"entity_cutouts":"existing_generated_assets_not_CC0"}
	var file := FileAccess.open(V10.PREFIX+"art.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata,"\t"))
	file.close()


func _build() -> void:
	_freeze_hashes()
	var topology := _read_png(GEOGRAPHY.PREFIX+"topology.png")
	var color := load(GEOGRAPHY.PREFIX+"visual.png") as Texture2D
	var walk := load(GEOGRAPHY.PREFIX+"walk.png") as Texture2D
	if topology==null or color==null or walk==null:
		push_error("Frozen v9 render inputs unavailable")
		quit(1)
		return
	var selector := ImageTexture.create_from_image(topology)
	var visual_viewport := _make_viewport(color,selector,topology,false)
	var mask_viewport := _make_viewport(color,_walk_texture(topology,walk),topology,true)
	var land_viewport := _make_viewport(color,selector,topology,true)
	var contact_viewport := _contact_viewport(color,selector,topology)
	for frame in range(24):
		await process_frame
	var visual := visual_viewport.get_texture().get_image()
	var mask_image := mask_viewport.get_texture().get_image()
	var land_image := land_viewport.get_texture().get_image()
	var contact := contact_viewport.get_texture().get_image()
	if visual==null or contact==null or not _same_pixels(mask_image,_read_png(GEOGRAPHY.PREFIX+"walk.png")) or not _same_pixels(land_image,_read_png(GEOGRAPHY.PREFIX+"land.png")):
		push_error("v10 must render exact frozen v9 land/walk pixels; no post-copy geometry masking permitted")
		quit(1)
		return
	if not _save_pair(visual,"visual") or not _save_pair(mask_image,"walk") or not _save_pair(land_image,"land") or not _save_pair(contact,"contact"):
		quit(1)
		return
	_after_outputs_saved(topology)
	for path in _frozen_hashes:
		if _sha(path)!=_frozen_hashes[path]:
			push_error("Frozen v9 file changed during v10 render: "+String(path))
			quit(1)
			return
	print("[WorldNativePairV10] material/contact candidate rendered; frozen v9 geometry and outputs untouched")
	for viewport in [visual_viewport,mask_viewport,land_viewport,contact_viewport]:
		viewport.queue_free()
	await process_frame
	quit(0)
