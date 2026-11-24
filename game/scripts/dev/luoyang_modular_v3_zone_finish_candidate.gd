extends "res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd"

## SOURCE-ONLY follow-up to ROOT168 ordinary-camera images. Not adopted.
## No vertex, UV, feet, layout, physics, nav, texture or gameplay mutation.
const ZONE_FINISH_ID := "PROJECT_SOFT_AVENUE_APRON_COURT_QUAY_FINISH_CANDIDATE_V1"
const ZONE_SOURCE_PINS := {
	"res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd": "7ccbb9f4a27234de3da4d41076e5374d7702d276a01c13e968c5790f537153eb",
	"res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd": "5f6a3f901645bdaed5e8a544c617375e2e2e02f5f2730b42d43895cf129c4dfa",
	"res://scripts/dev/luoyang_modular_v3_source.gd": "3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5",
	"res://scripts/dev/build_luoyang_modular_v3.gd": "3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30"
}
var zone_material_records: Array[Dictionary] = []

func _zone_sources_current() -> bool:
	for path: String in ZONE_SOURCE_PINS:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower() != ZONE_SOURCE_PINS[path]:
			error = "Zone finish refuses changed parent/zone authoring: " + path
			return false
	return true

func configure(snapshot: Dictionary) -> bool:
	zone_material_records.clear()
	if not _zone_sources_current(): return false
	return super.configure(snapshot)

func load_sources() -> bool:
	if not _zone_sources_current(): return false
	return super.load_sources()

func paving() -> ShaderMaterial:
	if not _zone_sources_current(): return null
	var material: ShaderMaterial = super.paving()
	if material == null or material.shader == null:
		error = "Zone finish requires the actual parent paving material."
		return null
	# Source.ground_zone: avenue [1360,500]..[1712,1940], yamen court
	# [1000,740]..[2070,1640]. Same point3: X=(px-1536)/64,Z=(py-1024)/32.
	# Do NOT index COLOR.a into slab palettes: semantic values are per-stone and
	# would recreate the rejected checker. Soft native-coordinate ownership only.
	var declaration := """uniform float zone_finish_identity=1.;
uniform float zone_court_profile=0.;
uniform vec4 zone_avenue_bounds=vec4(-2.75,-16.375,2.75,28.625);
uniform vec4 zone_court_bounds=vec4(-8.375,-8.875,8.34375,19.25);
float zone_soft_rect(vec2 q,vec4 bounds,float feather){
 float edge=min(min(q.x-bounds.x,bounds.z-q.x),min(q.y-bounds.y,bounds.w-q.y));
 return smoothstep(-feather,feather,edge);
}
void fragment(){"""
	var replacements: Array = [
		["void fragment(){", declaration],
		["float traffic=1.-smoothstep(.90,2.10,route_d);", "float traffic=1.-smoothstep(.90,2.10,route_d);\n float avenue=zone_soft_rect(p.xz,zone_avenue_bounds,.90);\n float court=zone_court_profile*zone_soft_rect(p.xz,zone_court_bounds,1.20);"],
		["vec3 finish=mix(vec3(.76,.765,.755),vec3(.92,.91,.865),traffic);", "vec3 finish=mix(vec3(.745,.75,.735),vec3(.985,.975,.925),traffic);\n finish=mix(finish,vec3(1.015,1.005,.955),avenue*.40);\n finish=mix(finish,vec3(.975,.975,.95),court*.68);"],
		["finish=mix(finish,vec3(.94,.925,.87),apron*.72);", "finish=mix(finish,vec3(1.005,.965,.875),apron*.78*(1.-court*.65));"],
		["finish=mix(finish,vec3(.56,.60,.60),wet*.42);", "finish=mix(finish,vec3(.49,.555,.545),wet*.50);"],
		["finish*=.97+(broad-.5)*.11;", "finish*=.98+(broad-.5)*mix(.09,.035,court);"],
		["face=mix(face,dust,verge*.24+contact*.10);", "face=mix(face,dust,(verge*.24*(1.-court*.72)+contact*.10)*(1.-avenue*.28));"],
		["ALBEDO=face*COLOR.rgb*native_flagstone_identity;", "ALBEDO=face*COLOR.rgb*native_flagstone_identity*zone_finish_identity;"],
		["ROUGHNESS=clamp(.91-traffic*.21-wet*.17+verge*.025+(arm.g-.5)*.035,.62,.97);", "ROUGHNESS=clamp(.92-traffic*.23-avenue*.055-court*.035-wet*.19+verge*.025+(arm.g-.5)*.035,.60,.97);"]
	]
	var patch: Dictionary = _zone_patch(material, replacements)
	if not patch.get("passed", false): return null
	material.set_shader_parameter("zone_finish_identity", 1.)
	material.set_shader_parameter("zone_court_profile", 1. if district == "ch4_s1_luoyang_yamen" else 0.)
	material.set_shader_parameter("zone_avenue_bounds", Vector4(-2.75,-16.375,2.75,28.625))
	material.set_shader_parameter("zone_court_bounds", Vector4(-8.375,-8.875,8.34375,19.25))
	_zone_record(material, "continuous_avenue_apron_court_quay_material_only", patch)
	return material

func masonry(tint: Color, profile: String) -> ShaderMaterial:
	if not _zone_sources_current(): return null
	var material: ShaderMaterial = super.masonry(tint, profile)
	if material == null or material.shader == null:
		error = "Zone finish requires the actual parent masonry material."
		return null
	# Warm only the south-gate grey brick branch. Keep yamen lime, native dark
	# base/cap, brick geometry, joints, UVs and normal strength unchanged.
	var patch: Dictionary = _zone_patch(material, [
		["vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;", "vec3 brick=vec3(.365,.36,.345)*(.58+luma*.85)+(stone-vec3(luma))*.13;"]
	])
	if not patch.get("passed", false): return null
	_zone_record(material, "warm_grey_brick_same_white_lime_dark_base_cap", patch)
	return material

func _zone_patch(material: ShaderMaterial, replacements: Array) -> Dictionary:
	var original: String = material.shader.code
	var code: String = original
	var anchors: Array[Dictionary] = []
	for pair: Array in replacements:
		var count: int = code.count(String(pair[0]))
		anchors.append({"anchor": pair[0], "actual_count": count, "required_count": 1})
		if count != 1:
			error = "Zone finish unique shader anchor mismatch: " + String(pair[0])
			return {"passed": false, "anchors": anchors}
		code = code.replace(String(pair[0]), String(pair[1]))
	var retained: Dictionary = {}
	for entry: Dictionary in material.shader.get_shader_uniform_list():
		var name: String = String(entry["name"])
		retained[name] = material.get_shader_parameter(name)
	var shader: Shader = material.shader.duplicate() as Shader
	shader.code = code
	material.shader = shader
	for name: String in retained: material.set_shader_parameter(name, retained[name])
	for name: String in retained:
		if material.get_shader_parameter(name) != retained[name]:
			error = "Zone finish changed an inherited sampler/parameter: " + name
			return {"passed": false, "anchors": anchors}
	return {"passed": true, "anchors": anchors, "parent_shader_code_sha256": _bytes_sha(original.to_utf8_buffer()), "retained_uniform_count": retained.size(), "inherited_parameters_and_actual_sampler_objects_unchanged": true}

func _zone_record(material: ShaderMaterial, role: String, patch: Dictionary) -> void:
	# Parent records alone precede this final edit. Add an explicit FINAL code
	# row rather than relabeling those earlier hashes as the final shader.
	_record(material, role)
	var record: Dictionary = material_records.back().duplicate(true)
	record["material_identity"] = ZONE_FINISH_ID
	record["candidate_script"] = {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}
	record["exact_source_pins"] = ZONE_SOURCE_PINS.duplicate(true)
	record["actual_final_shader_code_sha256"] = _bytes_sha(material.shader.code.to_utf8_buffer())
	record["patch_evidence"] = patch.duplicate(true)
	record["ownership"] = {"main_street_px": [1360,500,1712,1940], "yamen_court_px": [1000,740,2070,1640], "soft_edges_m": [.90,1.20], "apron_and_contact": "unchanged parent actual polygons/route segments", "quay_x_px": 2230, "court_enabled": district == "ch4_s1_luoyang_yamen", "COLOR_a_palette_used": false}
	record["scope"] = "SOURCE_ONLY_MATERIAL_CANDIDATE: actual compile/GPU/Field/visual approval NOT RUN; no geometry/nav/875/17/feet/UV/actor/NPC/action/texture changes"
	record["visual_approved"] = false
	record["production_approved"] = false
	material_records[-1] = record
	zone_material_records.append(record.duplicate(true))

func release() -> void:
	zone_material_records.clear()
	super.release()
