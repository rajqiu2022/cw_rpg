extends "res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd"

## Visual-only experiment after the actual ROOT234 review. The completed V9D
## capture remains immutable. Same CC0 channels, mesh, RF, water discard and
## navigation; damp surface films are not newly navigable water or reed meshes.
const V9E_PARENT_PATH := "res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd"
const V9E_PARENT_SHA := "4bb8890a6142d5d23931c949243d19f9754cf47642e62080de7e18f7f2546854"
const V9E_ID := "V9E_SNOW_EXPOSURE_DAMP_FILM_DEPTH_WATER_VISUAL_EXPERIMENT"
var v9e_records: Array[Dictionary] = []

func _replace_once(code: String, old: String, replacement: String) -> String:
	if code.count(old) != 1:
		error = "V9E immutable shader anchor missing or ambiguous: " + old
		return ""
	return code.replace(old, replacement)

func _v9c_fragment() -> String:
	var code: String = super._v9c_fragment()
	# Snow was clipping to white in the actual lit output. Keep genuine scan
	# grains and broaden frost continuity rather than painting brighter shelves.
	var replacements: Array = [
		["uniform float v9d_material_identity=1.;", "uniform float v9d_material_identity=1.;\nuniform float v9e_material_identity=1.;"],
		["vec3 snow_col=mix(vec3(.68,.71,.70),vec3(.85,.87,.86),clamp(rd.r*.80+patch*.45,0.,1.));", "float crust=n2(xyz.xz/.18)*.24+n2(xyz.xz/.73)*.31+patch*.45;\n vec3 snow_col=mix(vec3(.48,.52,.51),vec3(.70,.73,.72),clamp(crust,0.,1.));\n snow_col*=.93+.07*rd;"],
		["float deposit=snow*smoothstep(.22,.60,n2(xyz.xz/1.8)*.38+n2(xyz.xz/4.7+vec2(-3.,5.))*.62)*(1.-smoothstep(.30,.68,grade));", "float deposit=snow*(.22+.60*smoothstep(.24,.68,n2(xyz.xz/1.8)*.38+n2(xyz.xz/4.7+vec2(-3.,5.))*.62))*(1.-smoothstep(.22,.54,grade));"],
		["col=mix(col,mineral,snow_bed);", "col=mix(col,mineral*vec3(.74,.81,.87),snow_bed);"],
		["float pool=smoothstep(.43,.64,n2(xyz.xz/1.2)*.30+n2(xyz.xz/3.4+vec2(4.,9.))*.70);", "float pool=smoothstep(.42,.59,n2(xyz.xz/2.8)*.38+n2(xyz.xz/6.7+vec2(4.,9.))*.62);"],
		["vec3 silt=fd*.76+ld*.20+bd*.04;", "vec3 silt=fd*.60+ld*.05+bd*.35;"],
		["vec3 wet_col=mix(silt*vec3(.47,.58,.44),silt*vec3(.24,.34,.29),pool*.68+bank_film*.20);", "vec3 wet_col=mix(silt*vec3(.62,.57,.48),mix(silt*vec3(.28,.34,.32),vec3(.065,.10,.11),.54),pool*.83+bank_film*.12);"],
		["vec3 wet_a=fa*.76+la*.20+ba*.04;wet_a.g=mix(wet_a.g*.55,.18,clamp(pool*.66+bank_film*.28,0.,1.));", "vec3 wet_a=fa*.60+la*.05+ba*.35;wet_a.g=mix(.74,.11,clamp(pool*.90+bank_film*.12,0.,1.));"],
		["detail=mix(detail,fn*.76+ln*.20+bn*.04,wet_owner*(1.-pool*.25));", "detail=mix(detail,mix(fn*.60+ln*.05+bn*.35,vec3(.5,.5,1.),pool*.94),wet_owner);"],
		["SPECULAR=mix(.18,.38,clamp((pool*.70+bank_film*.30)*wet_owner,0.,1.));", "SPECULAR=mix(.18,.52,clamp((pool*.90+bank_film*.10)*wet_owner,0.,1.));"]
	]
	for pair: Array in replacements:
		code = _replace_once(code, pair[0], pair[1])
		if code.is_empty(): return ""
	return code

func terrain_material(weights: Texture2D, roads: Texture2D, local_rect: Rect2) -> ShaderMaterial:
	if FileAccess.get_sha256(V9E_PARENT_PATH).to_lower() != V9E_PARENT_SHA:
		error = "V9E refuses a changed V9D parent."
		return null
	var material: ShaderMaterial = super.terrain_material(weights, roads, local_rect)
	if material == null or material.shader.code.count("uniform float v9e_material_identity=1.;") != 1:
		error = "Actual V9E shader was not installed."
		return null
	material.set_shader_parameter("v9e_material_identity", 1.)
	# Keep the actual inherited V9D/base-uniform lineage explicit. The revision,
	# active shader and measured pigment weights must describe this V9E object,
	# not the parent recipe that was replaced before the draw.
	for records: Array in [v7_material_records, v8_material_records, v9_material_records]:
		for row: Dictionary in records:
			if row.get("kind", "terrain") == "terrain" and not row.get("no_longer_attached_to_receiver", false):
				row["material_revision_identity"] = V9E_ID
				row["actual_script_path"] = get_script().resource_path
				row["actual_script_sha256"] = FileAccess.get_sha256(get_script().resource_path)
	var active: Dictionary = v9_material_records.back()
	active["actual_code_sha256"] = _v7_code_sha(material.shader.code)
	active["registered_binding"] = _v7_binding_evidence(material)
	active["opaque_damp_soil_triplet_weights"] = {"forest":.60, "leafy":.05, "mud":.35}
	active["snow_deposit_actual_grade_fade"] = [.22, .54]
	active["snow_pigment_range"] = [[.48,.52,.51], [.70,.73,.72]]
	active["water_depth_discard_alpha_and_support_unchanged"] = true
	v9e_records.append({"kind":"terrain", "identity":V9E_ID, "source_path":get_script().resource_path,
		"source_sha256":FileAccess.get_sha256(get_script().resource_path), "code_sha256":_v7_code_sha(material.shader.code),
		"registered_binding":_v7_binding_evidence(material), "geometry_navigation_changed":false,
		"damp_film_not_water_support":true, "snow_shelf_geometry_not_claimed_fixed":true,
		"visual_approved":false, "production_approved":false})
	return material

func water_material(height_rf: Texture2D, grid_origin: Vector2i, grid_shape: Vector2i) -> ShaderMaterial:
	var material: ShaderMaterial = super.water_material(height_rf, grid_origin, grid_shape)
	if material == null: return null
	var code: String = material.shader.code
	# Break the long diagonal highlight train. Native bed interpolation, depth,
	# discard and alpha remain exact; no shoreline geometry or support changes.
	code = _replace_once(code,
		"return .0018*sin(a)+.00035*sin(q.y*8.3-q.x*2.1+(rich_n(q/2.8)-.5)*2.);",
		"return .00065*sin(a)*( .35+.65*rich_n(q/1.1))+ .00042*sin(q.y*8.3-q.x*2.1+(rich_n(q/2.8)-.5)*3.2);")
	if code.is_empty(): return null
	code = _replace_once(code, "float bed_visible=exp(-depth*3.2);", "float bed_visible=exp(-depth*1.7);")
	if code.is_empty(): return null
	code = _replace_once(code, "ROUGHNESS=mix(.60,.54,deep);SPECULAR=.18;METALLIC=0.;", "ROUGHNESS=mix(.44,.32,deep);SPECULAR=.27;METALLIC=0.;")
	if code.is_empty(): return null
	_rich_install(material, code)
	v9e_records.append({"kind":"water", "identity":V9E_ID, "source_path":get_script().resource_path,
		"source_sha256":FileAccess.get_sha256(get_script().resource_path), "code_sha256":_v7_code_sha(code),
		"actual_RF_texture_bound":material.get_shader_parameter("actual_height_rf") == height_rf,
		"depth_discard_alpha_water_Y_unchanged":true, "geometry_navigation_changed":false,
		"visual_approved":false, "production_approved":false})
	return material
