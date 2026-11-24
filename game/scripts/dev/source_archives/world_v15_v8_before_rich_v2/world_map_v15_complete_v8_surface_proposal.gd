extends "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd"

## Isolated V8 shader delta. No RF/vertex/discard/navigation modification.
const V8_ID := "V8_CONTINUOUS_CULTIVATION_DRY_BANK_SEDIMENT_STATIC_WATER_PROPOSAL"
var v8_material_records: Array[Dictionary]=[]

func _replace_once(code: String,before: String,after: String) -> String:
	if code.count(before)!=1:
		error="Frozen V7 shader anchor not unique; refuse unreviewed substitution."
		return ""
	return code.replace(before,after)

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var material: ShaderMaterial=super.terrain_material(weights,roads,local_rect)
	var original: String=material.shader.code
	var code: String=_replace_once(original,"float plot=step(.46,n2(vec2(floor(xyz.x/4.8),floor((xyz.z+.21*xyz.x)/8.6))));","""// Continuous 0.8-1.3m cultivated furrows; no categorical plot floor/step.
 float field_warp=.19*sin(xyz.z*.61)+.12*sin(xyz.x*.37+xyz.z*.23);
 float furrow_phase=(xyz.x+.21*xyz.z+field_warp)*6.8;
 float furrow=.5+.5*sin(furrow_phase);
 float plot=.32+.28*smoothstep(.22,.78,furrow);
 float furrow_detail=.014*sin(furrow_phase)*field*(1.-route);""")
	if code.is_empty(): return null
	code=_replace_once(code,"// Broad green pasture / bare-earth islands stay continuous across chunks.","""// Same-owner wet sediment replaces cracked-mud dominance on actual dry banks.
 float wet_owner=wet*(1.-route)*(1.-rock)*(1.-snow);
 float sediment=n2(xyz.xz/1.65)*.35+n2(xyz.xz/6.2)*.65;
 vec3 wet_loam=mix(vec3(.145,.175,.135),vec3(.265,.285,.20),sediment);
 vec3 leaf=scan(leafy_grass_diff,2.,w,1.);
 col=mix(col,mix(wet_loam,leaf,.18),wet_owner*.88);
 arm=mix(arm,mix(vec3(1.,.68,0.),scan(leafy_grass_arm,2.,w,1.),.18),wet_owner*.88);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),.18),wet_owner*.88);
 // Broad green pasture / bare-earth islands stay continuous across chunks.""")
	if code.is_empty(): return null
	code=_replace_once(code,"vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));","vec3 wn=normalize(gn+vec3((detail.r-.5)*strength+furrow_detail,0.,(detail.g-.5)*strength+furrow_detail*.21));")
	if code.is_empty(): return null
	material.shader=Shader.new()
	material.shader.code=code
	# Rebind every original uniform after changing the Shader resource.
	for key in textures: material.set_shader_parameter(key,textures[key])
	material.set_shader_parameter("biome_weights",weights)
	material.set_shader_parameter("road_weights",roads)
	material.set_shader_parameter("source_rect",Vector4(local_rect.position.x,local_rect.position.y,local_rect.size.x,local_rect.size.y))
	material.set_shader_parameter("field_ecology_mode",3)
	v7_material_records.back()["original_v7_shader_code_sha256"]=_v7_code_sha(original)
	v7_material_records.back()["shader_code_sha256"]=_v7_code_sha(code)
	v7_material_records.back()["identity"]=V8_ID
	v8_material_records.append({"identity":V8_ID,"kind":"terrain","original_code_sha256":_v7_code_sha(original),"actual_code_sha256":_v7_code_sha(code),"actual_registered_binding":_v7_binding_evidence(material),"source_rect":local_rect,"provenance":"project-authored continuous cultivation/sediment treatment; same18 official CC0 channels/physical widths, NOT a new scan","geometry_navigation_change":false,"visual_approved":false})
	return material

func water_material(height_rf: Texture2D,grid_origin: Vector2i,grid_shape: Vector2i) -> ShaderMaterial:
	var material: ShaderMaterial=super.water_material(height_rf,grid_origin,grid_shape)
	var original: String=material.shader.code
	var code: String=_replace_once(original,"ALBEDO=mix(shallow,channel,deep)+vec3(.007,.011,.009)*crest;","""// Native static interference detail: no TIME, fake foam, or new wet mask.
 float fine=.5+.5*sin(a*.73+b*.21);
 ALBEDO=mix(shallow,channel,deep)+vec3(.018,.025,.021)*crest+vec3(.004,.006,.005)*(fine-.5)*deep;""")
	if code.is_empty(): return null
	material.shader=Shader.new()
	material.shader.code=code
	material.set_shader_parameter("actual_height_rf",height_rf)
	material.set_shader_parameter("grid_origin",grid_origin)
	material.set_shader_parameter("grid_shape",grid_shape)
	v7_material_records.back()["original_v7_shader_code_sha256"]=_v7_code_sha(original)
	v7_material_records.back()["shader_code_sha256"]=_v7_code_sha(code)
	v7_material_records.back()["identity"]=V8_ID
	v8_material_records.append({"identity":V8_ID,"kind":"water","original_code_sha256":_v7_code_sha(original),"actual_code_sha256":_v7_code_sha(code),"same_actual_RF_texture":material.get_shader_parameter("actual_height_rf")==height_rf,"interpolation":"unchanged exact8px native triangle; same depth/discard/opacity/waterY","visual_approved":false})
	return material

func release() -> void:
	v8_material_records.clear()
	super.release()
