extends "res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"

## New project-authored finish, not a new CC0 scan or approved city revision.
## Geometry owners come from the exact frozen layout in configure().
const WALL_STREET_MATERIAL_ID := "PROJECT_CONTINUOUS_TRAFFIC_APRON_QUAY_FINE_MASONRY_FINISH_V1"

func paving() -> ShaderMaterial:
	var material: ShaderMaterial=super.paving()
	material.shader=material.shader.duplicate() as Shader
	var code: String=material.shader.code
	code=code.replace("uniform float native_flagstone_identity=1.;", "uniform float native_flagstone_identity=1.;\nuniform float quay_wet_profile=0.;\nuniform float wall_street_finish_identity=1.;")
	code=code.replace("float traffic=1.-smoothstep(.65,1.65,route_d);", "float traffic=1.-smoothstep(.90,2.10,route_d);")
	code=code.replace("float verge=smoothstep(2.2,4.5,route_d)*(1.-apron);", "float verge=smoothstep(2.8,5.8,route_d)*(1.-apron);\n float wet=quay_wet_profile*(1.-smoothstep(.45,4.2,abs(p.x-10.84375)));")
	code=code.replace("vec3 finish=mix(vec3(.81,.815,.80),vec3(.89,.885,.85),traffic);", "vec3 finish=mix(vec3(.76,.765,.755),vec3(.92,.91,.865),traffic);")
	code=code.replace("finish=mix(finish,vec3(.87,.86,.82),apron*.48);", "finish=mix(finish,vec3(.94,.925,.87),apron*.72);\n finish=mix(finish,vec3(.56,.60,.60),wet*.42);")
	code=code.replace("finish*=.985+(broad-.5)*.045;", "finish*=.97+(broad-.5)*.11;")
	code=code.replace("verge*.18+contact*.055", "verge*.24+contact*.10")
	code=code.replace("ROUGHNESS=clamp(.88-traffic*.15+verge*.035+(arm.g-.5)*.035,.69,.96);", "ROUGHNESS=clamp(.91-traffic*.21-wet*.17+verge*.025+(arm.g-.5)*.035,.62,.97);")
	material.shader.code=code
	material.set_shader_parameter("quay_wet_profile",1. if district=="ch4_s2_canal_docks" else 0.)
	material.set_shader_parameter("wall_street_finish_identity",1.)
	# ROOT144 proved serialized defaults/Array type tags, not shader or pixel
	# changes. Construct the exact saved representation, retaining every Vec4.
	material.set_shader_parameter("native_flagstone_identity",1.)
	for name: String in ["route_segments","contact_segments","apron_rects"]:
		var original: Variant=material.get_shader_parameter(name)
		var canonical: Array=[]
		for value: Vector4 in original: canonical.append(value)
		material.set_shader_parameter(name,canonical)
	_record(material,"continuous_same_native_stone_traffic_shop_apron_quay_wetdry")
	return material

func masonry(tint: Color,profile: String) -> ShaderMaterial:
	var material: ShaderMaterial=super.masonry(tint,profile)
	material.shader=material.shader.duplicate() as Shader
	var code: String=material.shader.code
	code=code.replace("cap=smoothstep(1.22,1.28,p.y)", "cap=smoothstep(1.66,1.70,p.y)")
	code=code.replace("vec3 brick=vec3(.355,.37,.38)*(.79+luma*.36)+(stone-vec3(luma))*.05;", "vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;")
	code=code.replace("vec3 lime=vec3(.675,.675,.65)*(.95+luma*.07);", "vec3 lime=vec3(.70,.695,.665)*(.87+luma*.20);")
	code=code.replace("face*=.975+(age-.5)*.035;", "face*=.965+(age-.5)*.075;")
	code=code.replace("tangent*d.x*.032+bitangent*d.y*.032", "tangent*d.x*.075+bitangent*d.y*.075")
	material.shader.code=code
	_record(material,"real_finer_brick_geometry_grey_stone_or_lime_plaster")
	return material

func curved_tile(profile: String) -> ShaderMaterial:
	var material: ShaderMaterial=masonry(Color(.99,.99,.97),profile)
	material.shader=material.shader.duplicate() as Shader
	var code: String=material.shader.code
	code=code.replace("uniform vec3 masonry_tint=vec3(1.);", "uniform float actual_curved_tile_geometry_identity=1.;\nuniform vec3 masonry_tint=vec3(1.);")
	code=code.replace("vec3 face=masonry_profile>.5?lime:brick;", "vec3 face=vec3(.265,.28,.29)*(.79+luma*.35)+(stone-vec3(luma))*.055;")
	code=code.replace("face=mix(face,vec3(.25,.27,.285)*(.83+luma*.28),base);", "// Real narrow curved tile vertices, not material-only barrel illusion.")
	code=code.replace("face=mix(face,vec3(.25,.265,.275)*(.86+luma*.23),cap);", "face*=actual_curved_tile_geometry_identity;")
	material.shader.code=code
	material.set_shader_parameter("actual_curved_tile_geometry_identity",1.)
	_record(material,"actual_curved_native_grey_clay_tile_with_registered_microdetail")
	return material

func _record(material: ShaderMaterial,role: String) -> void:
	super._record(material,role)
	var row: Dictionary=material_records.back()
	row["material_identity"]=WALL_STREET_MATERIAL_ID
	row["layout_navigation_geometry_scope"]="Ground geometry/layout/nav unchanged; new wall upper geometry is independently enumerated by adapter, NOT material-only or unchanged whole-wall arrays."
	row["provenance"]="Unedited project-generated old stone ALBEDO; original CC0 rock_01 normal/ARM at1.5m only microdetail. Continuous traffic/apron/quay finishes and actual finer masonry/curved clay geometry are project authoring, NOT a newly scanned or CC0 wall/roof."
