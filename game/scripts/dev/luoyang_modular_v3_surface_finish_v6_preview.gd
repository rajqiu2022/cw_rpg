extends "res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd"

## Isolated material experiment over saved V5 geometry. Never an adoption source.
## Existing project stone + registered rock microdetail; wood is project authoring.
const PREVIEW_ID := "LUOYANG_SURFACE_FINISH_V6_PREVIEW_NOT_ADOPTED"
var replacements_evidence: Array[Dictionary] = []

func revise_paving(original: ShaderMaterial) -> ShaderMaterial:
	return _revise(original, "paving", [
		["float broad=patina(p.xz/4.7)*.65+patina(p.xz/11.3)*.35;", """// Continuous 2-7m surface states, not per-slab palettes or UV edits.
 vec2 state_warp=vec2(patina(p.xz/3.1+vec2(2.7,5.3)),patina(p.xz/4.3+vec2(8.1,1.9)))-vec2(.5);
 vec2 state_q=p.xz+state_warp*2.2;
 float broad=patina(state_q/3.8)*.65+patina(state_q/7.1+vec2(3.2,7.4))*.35;
 float settled=smoothstep(.42,.67,broad)*(1.-traffic*.72)*(1.-court*.30);
 float scuff=smoothstep(.58,.78,patina(state_q/1.3+vec2(6.1,2.4)))*(.25+.75*traffic);
 float damp=clamp(wet*(.52+.48*patina(state_q/2.3))+contact*.15,0.,1.);"""],
		["vec3 finish=mix(vec3(.745,.75,.735),vec3(.985,.975,.925),traffic);", "vec3 finish=mix(vec3(.70,.69,.65),vec3(.94,.925,.875),traffic);"],
		["finish=mix(finish,vec3(1.015,1.005,.955),avenue*.40);", "finish=mix(finish,vec3(.99,.975,.925),avenue*.16);"],
		["finish=mix(finish,vec3(.975,.975,.95),court*.68);", "finish=mix(finish,vec3(.96,.945,.905),court*.20);"],
		["finish=mix(finish,vec3(1.005,.965,.875),apron*.78*(1.-court*.65));", "finish=mix(finish,vec3(.95,.90,.80),apron*.35*(1.-court*.65));"],
		["finish=mix(finish,vec3(.49,.555,.545),wet*.50);", "// Wet ownership is retained; damp below supplies irregular local coverage."],
		["finish*=.98+(broad-.5)*mix(.09,.035,court);", "finish*=.93+(broad-.5)*mix(.42,.28,court);"],
		["vec3 face=stone*finish;", """vec3 face=stone*finish;
 float stone_luma=dot(stone,vec3(.2126,.7152,.0722));
 vec3 settled_dust=vec3(stone_luma)*vec3(.72,.675,.56);
 face=mix(face,settled_dust,settled*.34);
 face*=1.-damp*.20;
 face=mix(face,stone*vec3(.96,.945,.90),scuff*.20);"""],
		["face=mix(face,dust,(verge*.24*(1.-court*.72)+contact*.10)*(1.-avenue*.28));", "face=mix(face,dust,(verge*.10*(1.-court*.72)+contact*.16)*(1.-avenue*.28));"],
		["ALBEDO=face*COLOR.rgb*native_flagstone_identity*zone_finish_identity;", "ALBEDO=face*mix(vec3(1.),COLOR.rgb,.60)*native_flagstone_identity*zone_finish_identity;"],
		["ROUGHNESS=clamp(.92-traffic*.23-avenue*.055-court*.035-wet*.19+verge*.025+(arm.g-.5)*.035,.60,.97);", "ROUGHNESS=clamp(.94-traffic*.20-damp*.15+settled*.035+(arm.g-.5)*.025,.64,.98);"]
	])

func revise_wall(original: ShaderMaterial, kind: String, surface_index: int) -> ShaderMaterial:
	if kind not in ["wall_horizontal", "wall_vertical"] or surface_index < 0 or surface_index >= 18:
		error = "Strong finish requires an explicit saved V5 wall orientation/surface index."
		return null
	# Separate coping from plaster. All choices are shader literals, not new
	# uniforms/samplers, mesh attributes, instance transforms or PNG alpha edits.
	if surface_index in [16,17]:
		return _revise(original, "native_grey_tile_"+kind+"_surface_"+str(surface_index), [
			["vec3 face=vec3(.265,.28,.29)*(.79+luma*.35)+(stone-vec3(luma))*.055;", "vec3 face=vec3(.235,.24,.235)*(.86+luma*.25)+(stone-vec3(luma))*.035;"],
			["face*=.965+(age-.5)*.075;", "face*=.97+(age-.5)*.12;"]
		])
	var declaration: String = "const bool preview_wall_horizontal=" + ("true" if kind == "wall_horizontal" else "false") + ";\nconst int preview_wall_surface=" + str(surface_index) + ";\nvarying vec3 preview_wall_axis;\nvoid vertex(){p=VERTEX;source_n=NORMAL;world_n=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);preview_wall_axis=normalize((MODEL_MATRIX*vec4(preview_wall_horizontal?vec3(0.,0.,1.):vec3(1.,0.,0.),0.)).xyz);}"
	var edits: Array = [
		["void vertex(){p=VERTEX;source_n=NORMAL;world_n=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);}", declaration],
		["float age=weather(vec2(p.x+p.z*.17,p.y)*1.4);", """// Project-authored broken lime coat, in metres along the explicit wall axis.
 float along=preview_wall_horizontal?p.x:p.z;
 vec2 wall_q=vec2(along,p.y);
 vec2 warp=vec2(weather(wall_q*vec2(.61,1.1)+vec2(3.7,8.1)),weather(wall_q*vec2(.83,1.6)+vec2(9.2,2.4)))-vec2(.5);
 float age=weather(wall_q*vec2(.73,1.18)+warp*.66);
 float broken=weather(wall_q*vec2(7.7,9.1)+warp*1.4);
 float erosion=weather(vec2(along*.94,2.37));
 float peel_top=.14+smoothstep(.38,.71,erosion)*.48;
 float lower_peel=1.-smoothstep(peel_top-.06,peel_top+.045+(broken-.5)*.05,p.y);
 float islands=smoothstep(.67,.78,age+(broken-.5)*.14)*(1.-smoothstep(.92,1.32,p.y))*.72;
 float exposed=clamp(max(lower_peel,islands),0.,1.);
 float plaster=masonry_profile>.5?1.-exposed:0.;
 // Retained piers meet the same coat above their grey foot; cornice stays
 // aged mortar. Only merged upper surface14 gets planar plaster shading.
 if(preview_wall_surface<14)plaster*=smoothstep(.22,.46,p.y);
 if(preview_wall_surface==15)plaster=masonry_profile>.5?1.:0.;
 float mortar_rim=1.-abs(exposed*2.-1.);"""],
		["float stain=(1.-smoothstep(.04,.45,p.y))*(.4+.6*weather(vec2(p.x+p.z,p.y)/.45));", """float drip_lane=smoothstep(.61,.76,weather(vec2(along*8.1+weather(vec2(along*1.9,4.7))*2.2,7.23)));
 float drip_length=.16+.42*weather(vec2(along*3.8,2.1));
 float below_eave=1.67-p.y;
 float drip=drip_lane*(1.-smoothstep(drip_length-.045,drip_length+.055,below_eave))*smoothstep(0.,.05,below_eave);
 float toe_damp=(1.-smoothstep(.08,.40,p.y))*(.35+.65*weather(vec2(along*2.3,p.y*4.1)));
 float stain=clamp(drip*.58+toe_damp*.34,0.,1.);"""],
		["float base=1.-smoothstep(.25,.48,p.y),cap=smoothstep(1.66,1.70,p.y);", "float base=1.-smoothstep(.09,.28,p.y),cap=smoothstep(1.66,1.70,p.y);"],
		["vec3 brick=vec3(.365,.36,.345)*(.58+luma*.85)+(stone-vec3(luma))*.13;", "vec3 brick=vec3(.31,.315,.305)*(.90+luma*.22)+(stone-vec3(luma))*.045;"],
		["vec3 lime=vec3(.70,.695,.665)*(.87+luma*.20);", "vec3 lime=mix(vec3(.62,.605,.565),vec3(.76,.745,.70),age)*(.97+(luma-.5)*.025);"],
		["vec3 face=masonry_profile>.5?lime:brick;", """vec3 face=mix(brick,lime,plaster);
 face=mix(face,vec3(.49,.465,.415)*(.94+(broken-.5)*.12),mortar_rim*.58*(masonry_profile>.5?1.:0.));
 if(preview_wall_surface==15)face=mix(vec3(.35,.345,.32),vec3(.47,.455,.41),age);"""],
		["face=mix(face,vec3(.25,.27,.285)*(.83+luma*.28),base);", "face=mix(face,brick,base*.75);"],
		["face=mix(face,vec3(.25,.265,.275)*(.86+luma*.23),cap);", "face=mix(face,vec3(.35,.345,.32)*(.94+luma*.12),cap*.55);"],
		["face*=.965+(age-.5)*.075;", "face*=.96+(age-.5)*mix(.18,.28,plaster);"],
		["ALBEDO=face*masonry_tint*(1.-stain*.045);", "ALBEDO=face*masonry_tint*(1.-stain*.42);"],
		["vec3 tangent=abs(n.y)<.8?normalize(cross(vec3(0.,1.,0.),n)):vec3(1.,0.,0.);\n vec3 bitangent=normalize(cross(n,tangent));\n vec3 wn=normalize(n+tangent*d.x*.075+bitangent*d.y*.075);", """// Lighting normals only: real brick gaps, silhouette and mesh NORMAL slots
 // remain unchanged. Coat suppresses bright row facets, not actual holes.
 float across=preview_wall_horizontal?p.z:p.x;
 vec3 plane_n=normalize(preview_wall_axis)*(across<0.?-1.:1.);
 float coat_shading=preview_wall_surface==14?plaster*.94:0.;
 vec3 shade_n=normalize(mix(n,plane_n,coat_shading));
 vec3 tangent=abs(shade_n.y)<.8?normalize(cross(vec3(0.,1.,0.),shade_n)):vec3(1.,0.,0.);
 vec3 bitangent=normalize(cross(shade_n,tangent));
 float micro_strength=mix(.075,.014,plaster);
 vec3 wn=normalize(shade_n+tangent*d.x*micro_strength+bitangent*d.y*micro_strength);"""]
	]
	return _revise(original, "native_broken_lime_grey_foot_"+kind+"_surface_"+str(surface_index), edits)

func revise_wood(original: ShaderMaterial) -> ShaderMaterial:
	# The frozen deck is made of sixteen X-long boards. The old y-dependent
	# periodic shader appears as uniform bands on its constant-Y top faces.
	# This is deliberately original procedural wood, not a licensed wood scan.
	if original == null or original.shader == null:
		error = "Preview wood requires an actual saved ShaderMaterial."
		return null
	var result: ShaderMaterial = original.duplicate() as ShaderMaterial
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 p;void vertex(){p=VERTEX;}
float h(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
float wood_noise(vec2 q){vec2 i=floor(q),f=fract(q);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1.,0.)),f.x),mix(h(i+vec2(0.,1.)),h(i+vec2(1.)),f.x),f.y);}
void fragment(){
 float long_grain=wood_noise(vec2(p.x*.62,p.z*23.)+vec2(wood_noise(p.xz*.7)*.35,0.));
 float broad=wood_noise(p.xz*vec2(.42,1.9));
 float fine=wood_noise(p.xz*vec2(2.1,67.));
 vec3 old_timber=mix(vec3(.115,.102,.078),vec3(.24,.205,.145),broad*.65+long_grain*.35);
 ALBEDO=old_timber*(.94+(fine-.5)*.095);
 ROUGHNESS=.89;SPECULAR=.12;
}
"""
	if not candidate_code_safe(shader.code): return null
	result.shader = shader
	# Current frozen wood has no parameters; don't silently discard future ones.
	if not original.shader.get_shader_uniform_list().is_empty():
		error = "Preview refuses an unexpected parameterized old wood material."
		return null
	replacements_evidence.append({"role":"original_procedural_weathered_wood", "old_code_sha256":_bytes_sha(original.shader.code.to_utf8_buffer()), "new_code_sha256":_bytes_sha(shader.code.to_utf8_buffer()), "new_external_sources":[], "provenance":"Project procedural authoring, NOT CC0 wood/PBR scan", "scope":PREVIEW_ID})
	return result

func candidate_code_safe(code: String) -> bool:
	var forbidden := RegEx.new()
	if forbidden.compile("\\b(ALPHA|ALPHA_SCISSOR_THRESHOLD|ALPHA_HASH_SCALE|discard)\\b|\\b(VERTEX|POSITION)\\s*(?:[+*/-])?=") != OK or forbidden.search(code) != null:
		error = "Preview candidate uses forbidden opacity/discard/vertex displacement."
		return false
	return true

func _revise(original: ShaderMaterial, role: String, edits: Array) -> ShaderMaterial:
	if original == null or original.shader == null:
		error = "Preview requires a saved material/shader, never a fallback."
		return null
	var code: String = original.shader.code
	var anchors: Array[Dictionary] = []
	for edit: Array in edits:
		var count: int = code.count(String(edit[0]))
		anchors.append({"anchor":edit[0], "actual_count":count, "required_count":1})
		if count != 1:
			error = "Preview exact frozen shader anchor differs: " + String(edit[0])
			return null
		code = code.replace(String(edit[0]), String(edit[1]))
	if not candidate_code_safe(code): return null
	var result: ShaderMaterial = original.duplicate() as ShaderMaterial
	var retained: Dictionary = {}
	for uniform: Dictionary in original.shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		retained[name] = original.get_shader_parameter(name)
	var shader: Shader = original.shader.duplicate() as Shader
	shader.code = code
	result.shader = shader
	for name: String in retained: result.set_shader_parameter(name, retained[name])
	for name: String in retained:
		var before: Variant = retained[name]
		var after: Variant = result.get_shader_parameter(name)
		if (before is Texture2D and before != after) or (not before is Texture2D and var_to_bytes(before) != var_to_bytes(after)):
			error = "Preview changed a saved sampler/parameter: " + name
			return null
	replacements_evidence.append({"role":role, "old_code_sha256":_bytes_sha(original.shader.code.to_utf8_buffer()), "new_code_sha256":_bytes_sha(code.to_utf8_buffer()), "anchors":anchors, "retained_parameters":retained.keys(), "actual_sampler_objects_retained":true, "scope":PREVIEW_ID})
	return result
