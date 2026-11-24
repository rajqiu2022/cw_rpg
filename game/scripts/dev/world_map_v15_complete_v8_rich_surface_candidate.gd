extends "res://scripts/dev/source_archives/world_v15_v8_before_rich_v2/world_map_v15_complete_v8_surface_proposal.gd"

## Independent candidate only. No executor, capture, approval or production pin.
## Parent RF/geometry/discard/opacity and all 18 CC0 channels/metres/mips stay intact.
const RICH_SURFACE_ID := "V8_RICH_FIELD_DRY_SEDIMENT_NATIVE_SNOW_ROCK_DIRECTIONAL_WATER_V2_CANDIDATE"
var cultivation_candidate_enabled: bool=true
var water_candidate_enabled: bool=true
var dry_sediment_candidate_enabled: bool=true
var snow_rock_candidate_enabled: bool=true
var rich_material_records: Array[Dictionary]=[]

func _rich_replace(code: String,before: String,after: String) -> String:
	if code.count(before)!=1:
		error="Rich candidate shader anchor absent/ambiguous; refuse substitution."
		return ""
	return code.replace(before,after)

func _rich_install(material: ShaderMaterial,code: String) -> void:
	# Retain the actual parent bindings, including defaults/nulls, before replacing
	# the shader. No new sampler, derived texture, mip or physical period is added.
	var bound: Dictionary={}
	for uniform in material.shader.get_shader_uniform_list():
		var name: String=String(uniform["name"])
		bound[name]=material.get_shader_parameter(name)
	var shader:=Shader.new()
	shader.code=code
	material.shader=shader
	for name in bound: material.set_shader_parameter(name,bound[name])

func _rich_record(kind: String,original: String,material: ShaderMaterial) -> void:
	var actual: String=material.shader.code
	rich_material_records.append({"identity":RICH_SURFACE_ID,"kind":kind,
		"candidate_script_path":get_script().resource_path,
		"candidate_script_sha256":FileAccess.get_sha256(get_script().resource_path),
		"actual_inheritance":rich_execution_contract(),
		"parent_shader_code_sha256":_v7_code_sha(original),
		"actual_shader_code_sha256":_v7_code_sha(actual),
		"cultivation_candidate_enabled":cultivation_candidate_enabled,
		"water_candidate_enabled":water_candidate_enabled,
		"dry_sediment_candidate_enabled":dry_sediment_candidate_enabled,
		"snow_rock_candidate_enabled":snow_rock_candidate_enabled,
		"registered_binding":_v7_binding_evidence(material) if kind=="terrain" else {},
		"provenance":"project-authored material formula, NOT a new CC0 scan or new geometry",
		"status":"CANDIDATE_CODE_CREATED_NOT_ENGINE_VALIDATED",
		"geometry_navigation_change":false,"visual_approved":false,"production_approved":false})
	# Generated parent evidence must not continue advertising the pre-delta code.
	v7_material_records.back()["shader_code_sha256"]=_v7_code_sha(actual)
	v7_material_records.back()["identity"]=RICH_SURFACE_ID
	v8_material_records.back()["actual_code_sha256"]=_v7_code_sha(actual)
	v8_material_records.back()["identity"]=RICH_SURFACE_ID

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var material: ShaderMaterial=super.terrain_material(weights,roads,local_rect)
	if material==null: return null
	var original: String=material.shader.code
	var code: String=original
	if cultivation_candidate_enabled:
		# Same 2*pi/6.8 = .924m phase; continuous ownership, never floor/step plots.
		code=_rich_replace(code,"float plot=.32+.28*smoothstep(.22,.78,furrow);","float plot=.24+.44*smoothstep(.22,.78,furrow);")
		if code.is_empty(): return null
		code=_rich_replace(code,"float furrow_detail=.014*sin(furrow_phase)*field*(1.-route);","float furrow_detail=.032*sin(furrow_phase)*field*(1.-route)*(1.-snow)*(1.-sand);")
		if code.is_empty(): return null
		var old_field: String=""" col=mix(col,mix(loam,scan(leafy_grass_diff,2.,w,1.),plot),field*.33);
 arm=mix(arm,mix(vec3(1.,.94,0.),scan(leafy_grass_arm,2.,w,1.),plot),field*.33);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),plot),field*.33);"""
		code=_rich_replace(code,old_field," // Cultivation owner is applied after open-floor dilution below.")
		if code.is_empty(): return null
		var open_floor: String=" col=mix(col,open_floor,(1.-forest)*(1.-rock)*(1.-snow)*(1.-wet)*.32);"
		code=_rich_replace(code,open_floor,open_floor+"""
 // Candidate cultivation is a continuous grass/loam treatment, not crop solids.
 // ALBEDO/ARM/normal share the same owner and unchanged registered 2m scan.
 float field_owner=field*(1.-route)*(1.-snow)*(1.-sand)*.45;
 col=mix(col,mix(loam,scan(leafy_grass_diff,2.,w,1.),plot),field_owner);
 arm=mix(arm,mix(vec3(1.,.94,0.),scan(leafy_grass_arm,2.,w,1.),plot),field_owner);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),plot),field_owner);""")
		if code.is_empty(): return null
	if dry_sediment_candidate_enabled:
		# ROOT167 dry RF survey: median .308m, all surveyed dry points <.65m.
		# Preserve the height range; clarify material ownership rather than expand
		# it arbitrarily. No cracked-mud ALBEDO dominance or olive leaf dominance.
		var old_sediment: String=""" col=mix(col,mix(wet_loam,leaf,.18),wet_owner*.88);
 arm=mix(arm,mix(vec3(1.,.68,0.),scan(leafy_grass_arm,2.,w,1.),.18),wet_owner*.88);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),.18),wet_owner*.88);"""
		code=_rich_replace(code,old_sediment," // Dry sediment channels are composed after open-floor coverage below.")
		if code.is_empty(): return null
		code=_rich_replace(code,"vec3 wet_loam=mix(vec3(.145,.175,.135),vec3(.265,.285,.20),sediment);","vec3 wet_loam=mix(vec3(.135,.115,.095),vec3(.24,.215,.175),sediment);")
		if code.is_empty(): return null
		# Insert immediately before sand/snow/lane composition; identical owner for
		# native colour, honest registered mineral detail, ARM and normal channels.
		var deposition_anchor: String=" // Irregular deposited sand/gravel, not periodic sine ripples or giant dune"
		code=_rich_replace(code,deposition_anchor,""" // Candidate dry wetland sediment: project-authored brown loam plus unchanged
 // 3.2m forest mineral scan, NOT a claimed new wet-mud scan or new landform.
 vec3 dry_sediment_col=mix(wet_loam,scan(forest_ground_04_diff,3.2,w,.4),.12);
 dry_sediment_col=mix(dry_sediment_col,leaf,.08);
 vec3 dry_sediment_arm=mix(vec3(1.,mix(.62,.76,sediment),0.),scan(forest_ground_04_arm,3.2,w,.4),.12);
 dry_sediment_arm=mix(dry_sediment_arm,scan(leafy_grass_arm,2.,w,1.),.08);
 vec3 dry_sediment_normal=mix(vec3(.5,.5,1.),scan(forest_ground_04_nor_gl,3.2,w,.4),.12);
 dry_sediment_normal=mix(dry_sediment_normal,scan(leafy_grass_nor_gl,2.,w,1.),.08);
 float dry_sediment_owner=wet_owner*.94;
 col=mix(col,dry_sediment_col,dry_sediment_owner);
 arm=mix(arm,dry_sediment_arm,dry_sediment_owner);
 detail=mix(detail,dry_sediment_normal,dry_sediment_owner);
"""+deposition_anchor)
		if code.is_empty(): return null
	if snow_rock_candidate_enabled:
		var old_snow: String=""" float crust=smoothstep(.25,.72,n2(xyz.xz/1.8)*.7+n2(xyz.xz/5.4)*.3);
 vec3 snow_col=mix(vec3(.45,.51,.55),vec3(.70,.74,.75),crust);
 col=mix(col,snow_col,snow*.9);arm=mix(arm,vec3(1.,.78,0.),snow*.9);
 detail=mix(detail,vec3(.5,.5,1.),snow*.8);"""
		code=_rich_replace(code,old_snow,""" // Same RF native height and interpolated geometry normal, not displacement.
 // The ecology owner separately measures exact actual RF triangle gradients.
 float cold_region=1.-smoothstep(.52,1.1,length((p-vec2(5000.,430.))/vec2(4600.,860.)));
 float native_grade=length(gn.xz)/max(abs(gn.y),.05);
 float exposed_ridge=cold_region*smoothstep(.65,2.2,xyz.y)*smoothstep(.22,.85,native_grade)*(1.-route);
 col=mix(col,scan(rock_01_diff,1.5,w,0.),exposed_ridge*.82);
 arm=mix(arm,scan(rock_01_arm,1.5,w,0.),exposed_ridge*.82);
 detail=mix(detail,scan(rock_01_nor_gl,1.5,w,0.),exposed_ridge*.82);
 float crust=smoothstep(.25,.72,n2(xyz.xz/1.8)*.7+n2(xyz.xz/5.4)*.3);
 vec3 snow_col=mix(vec3(.45,.51,.55),vec3(.70,.74,.75),crust);
 float deposited_snow=snow*.88*(1.-smoothstep(.65,1.6,native_grade)*.65);
 col=mix(col,snow_col,deposited_snow);
 arm=mix(arm,vec3(1.,.78,0.),deposited_snow);
 detail=mix(detail,vec3(.5,.5,1.),deposited_snow*.8);""")
		if code.is_empty(): return null
	_rich_install(material,code)
	_rich_record("terrain",original,material)
	return material

func water_material(height_rf: Texture2D,grid_origin: Vector2i,grid_shape: Vector2i) -> ShaderMaterial:
	var material: ShaderMaterial=super.water_material(height_rf,grid_origin,grid_shape)
	if material==null: return null
	var original: String=material.shader.code
	var code: String=original
	if water_candidate_enabled:
		# Static non-repeating value-noise phase; no TIME/random frame/local origin.
		# Finite-difference slopes are from this same height formula, not unrelated
		# normals. This is native lit microdetail, NOT geometry or simulated fluid.
		var wave_functions: String="""
float rich_h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float rich_n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*f*(f*(f*6.-15.)+10.);return mix(mix(rich_h(i),rich_h(i+vec2(1.,0.)),f.x),mix(rich_h(i+vec2(0.,1.)),rich_h(i+vec2(1.)),f.x),f.y);}
float rich_phase(vec2 q){return q.x*13.1+q.y*5.7+(rich_n(q/1.7)-.5)*3.2+(rich_n(q/4.9+vec2(7.,-3.))-.5)*1.1;}
float rich_wave(vec2 q){float a=rich_phase(q);return .0018*sin(a)+.00035*sin(q.y*8.3-q.x*2.1+(rich_n(q/2.8)-.5)*2.);}
"""
		code=_rich_replace(code,"void fragment(){",wave_functions+"void fragment(){")
		if code.is_empty(): return null
		var old_wave: String=""" float warp=1.7*sin(xyz.x*.73+xyz.z*.41)+.9*cos(xyz.z*1.13-xyz.x*.29);
 float a=xyz.x*13.1+xyz.z*5.7+warp,b=xyz.z*19.3-xyz.x*3.6+.61*warp;
 vec2 slope=vec2(.018*cos(a)+.006*cos(b)*-.19,.008*cos(a)+.019*cos(b));"""
		code=_rich_replace(code,old_wave,""" vec2 q=xyz.xz;
 float a=rich_phase(q);
 float derivative_step=.015;
 vec2 slope=vec2(rich_wave(q+vec2(derivative_step,0.))-rich_wave(q-vec2(derivative_step,0.)),rich_wave(q+vec2(0.,derivative_step))-rich_wave(q-vec2(0.,derivative_step)))/(2.*derivative_step);""")
		if code.is_empty(): return null
		code=_rich_replace(code,"float crest=pow(max(0.,.55*sin(a)+.45*sin(b)),8.);","float crest=smoothstep(.52,.96,sin(a));")
		if code.is_empty(): return null
		var old_colour: String=""" float fine=.5+.5*sin(a*.73+b*.21);
 ALBEDO=mix(shallow,channel,deep)+vec3(.018,.025,.021)*crest+vec3(.004,.006,.005)*(fine-.5)*deep;"""
		code=_rich_replace(code,old_colour,""" // Same native RF bed changes sediment exposure continuously with actual
 // depth and neighbouring bed grade, not a receiver-local painted water mask.
 float bed_dx=(bed(p+vec2(8.,0.))-bed(p-vec2(8.,0.)))*102.4/16.;
 float bed_dz=(bed(p+vec2(0.,8.))-bed(p-vec2(0.,8.)))*72.40773439/16.;
 float bed_grade=length(vec2(bed_dx,bed_dz));
 vec3 bed_sediment=mix(vec3(.23,.215,.16),vec3(.175,.20,.175),smoothstep(.12,.7,bed_grade));
 float bed_visible=exp(-depth*3.2);
 ALBEDO=mix(channel,bed_sediment,bed_visible)+vec3(.003,.005,.004)*crest;""")
		if code.is_empty(): return null
		code=_rich_replace(code,"float deep=smoothstep(.035,.45,depth);","float deep=1.-exp(-depth*2.4);")
		if code.is_empty(): return null
		code=_rich_replace(code,"ROUGHNESS=mix(.53,.43,deep)+crest*.015;SPECULAR=.25;METALLIC=0.;","ROUGHNESS=mix(.60,.54,deep);SPECULAR=.18;METALLIC=0.;")
		if code.is_empty(): return null
	_rich_install(material,code)
	_rich_record("water",original,material)
	rich_material_records.back()["same_actual_RF_texture"]=material.get_shader_parameter("actual_height_rf")==height_rf
	rich_material_records.back()["unchanged_water_authority"]="bed interpolation/depth/discard/ALPHA/waterY unchanged; shore facets remain"
	rich_material_records.back()["material_limits"]="RF depth/grade sediment attenuation only; no changed river width/shore topology, no new fluid or scan"
	return material

func release() -> void:
	rich_material_records.clear()
	super.release()

func rich_execution_contract() -> Dictionary:
	return {
		"actual_object_script":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},
		"rich_implementation":{"path":"res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd","sha256":FileAccess.get_sha256("res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd")},
		"archived_parent":{"path":"res://scripts/dev/source_archives/world_v15_v8_before_rich_v2/world_map_v15_complete_v8_surface_proposal.gd","sha256":FileAccess.get_sha256("res://scripts/dev/source_archives/world_v15_v8_before_rich_v2/world_map_v15_complete_v8_surface_proposal.gd")},
		"geometry_navigation_change":false,"production_approved":false}
