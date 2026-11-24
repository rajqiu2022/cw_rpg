extends "res://scripts/dev/build_luoyang_modular_v3_roof_revision.gd"

## NEW material-only revision relative to ROOT100's raised-cap geometry.
## Original masonry and every roof/ground vertex, normal, UV and index remain exact.
## Clay tile curvature here is a surface-normal detail, NOT new curved geometry.
const TILE_PARENT_PATH := "res://scripts/dev/build_luoyang_modular_v3_roof_revision.gd"
const TILE_PARENT_SHA := "9cca9ac63a4a059cc5ac87478ab6ae17ce0c661b1c3d453271da505ea1ca3439"
const TILE_IDENTITY := "PROJECT_NATIVE_WEATHERED_GREY_CLAY_TILE_CAP_MATERIAL_V1"

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--luoyang-v3-grey-tile-roof-capture" not in args or FileAccess.get_sha256(TILE_PARENT_PATH).to_lower() != TILE_PARENT_SHA:
		error = "Explicit NEW grey-tile roof flag and exact frozen raised-cap parent required."
		await _roof_refuse()
		return
	await super._run()

func _source_graph() -> Dictionary:
	var graph: Dictionary = super._source_graph()
	graph[TILE_PARENT_PATH] = FileAccess.get_sha256(TILE_PARENT_PATH)
	return graph

func _prop_mesh(kind: String) -> ArrayMesh:
	var mesh: ArrayMesh = super._prop_mesh(kind)
	if mesh == null or kind not in ["wall_horizontal", "wall_vertical"]: return mesh
	var cap_index: int = mesh.get_surface_count() - 1
	if cap_index < 0:
		error = "No actual raised cap to receive grey tile material."
		return null
	mesh.surface_set_material(cap_index, _grey_tile_material(kind == "wall_horizontal"))
	return mesh

func _grey_tile_material(horizontal: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform sampler2D original_stone:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D registered_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec3 masonry_tint=vec3(.99,.99,.97);
uniform float masonry_profile=0.;
uniform float native_grey_tile_cap_identity=1.;
uniform float horizontal_axis=1.;
uniform float cap_half_span_m=.575;
uniform float tile_pitch_m=.15625;
uniform float course_pitch_m=.20;
varying vec3 roof_local_p;
varying vec3 roof_native_normal;
varying vec3 roof_axis_tangent;
void vertex(){
	roof_local_p=VERTEX;
	roof_native_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);
	vec3 axis=horizontal_axis>.5?vec3(1.,0.,0.):vec3(0.,0.,1.);
	roof_axis_tangent=normalize((MODEL_MATRIX*vec4(axis,0.)).xyz);
}
float clay_hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float clay_patch(vec2 p){
	vec2 c=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);
	return mix(mix(clay_hash(c),clay_hash(c+vec2(1.,0.)),f.x),
	           mix(clay_hash(c+vec2(0.,1.)),clay_hash(c+vec2(1.,1.)),f.x),f.y);
}
void fragment(){
	float axis=horizontal_axis>.5?roof_local_p.x:roof_local_p.z;
	float across=horizontal_axis>.5?roof_local_p.z:roof_local_p.x;
	float along=(axis+2.5)/tile_pitch_m;
	float column=floor(along);
	float u=fract(along);
	float slope_len=length(vec2(cap_half_span_m,.25));
	float descent=abs(across)/cap_half_span_m*slope_len;
	float course=descent/course_pitch_m;
	float v=fract(course);
	float seam=1.-smoothstep(.015,.060,min(u,1.-u));
	float lap=1.-smoothstep(.010,.060,min(v,1.-v));
	float tile_age=clay_hash(vec2(column,floor(course)))-.5;
	float weather=clay_patch(vec2(axis*.95,descent*1.7))-.5;
	vec2 micro_uv=vec2(axis,descent)/1.5;
	vec3 old_stone=texture(original_stone,micro_uv).rgb;
	vec3 arm=texture(registered_arm,micro_uv).rgb;
	vec3 micro=texture(registered_normal,micro_uv).rgb*2.-1.;
	float stone_luma=dot(old_stone,vec3(.2126,.7152,.0722));
	// Project-native clay organization; generated stone contributes only a
	// measured low-amplitude weather mark, not a claimed scanned roof texture.
	vec3 clay=vec3(.285,.300,.310)+tile_age*.032+weather*.034;
	clay+=vec3((stone_luma-.45)*.035);
	clay+=vec3(.006*masonry_profile);
	clay*=1.-seam*.14-lap*.10;
	float crown=.5+.5*cos((u-.5)*6.28318530718);
	clay+=vec3(crown*.018);
	ALBEDO=clay*masonry_tint*native_grey_tile_cap_identity;
	ROUGHNESS=clamp(.87+(arm.g-.5)*.05+tile_age*.018,.82,.94);
	AO=mix(1.,arm.r,.05)*(1.-seam*.06-lap*.04);
	SPECULAR=.18;
	vec3 n=normalize(roof_native_normal);
	vec3 t=normalize(roof_axis_tangent);
	vec3 b=normalize(cross(n,t));
	// Explicit material-only barrel detail: no silhouette, vertices or support
	// change. Same local native axis/normal is transformed to actual view space.
	float arch_slope=sin((u-.5)*6.28318530718)*.115;
	float overlap_slope=sin(v*6.28318530718)*.026;
	vec3 detailed=normalize(n-t*(arch_slope+micro.x*.012)+b*(overlap_slope+micro.y*.012));
	NORMAL=normalize((VIEW_MATRIX*vec4(detailed,0.)).xyz);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("original_stone", surface.textures["stone"])
	material.set_shader_parameter("registered_normal", surface.textures["nor_gl"])
	material.set_shader_parameter("registered_arm", surface.textures["arm"])
	material.set_shader_parameter("masonry_tint", Vector3(.99, .99, .97))
	material.set_shader_parameter("masonry_profile", 1. if _masonry_profile() == "yamen_white_lime_dark_stone" else 0.)
	material.set_shader_parameter("native_grey_tile_cap_identity", 1.)
	material.set_shader_parameter("horizontal_axis", 1. if horizontal else 0.)
	material.set_shader_parameter("cap_half_span_m", .575 if horizontal else .650)
	material.set_shader_parameter("tile_pitch_m", .15625)
	material.set_shader_parameter("course_pitch_m", .20)
	return material

func _prototype(kind: String) -> bool:
	if kind not in ["wall_horizontal", "wall_vertical"]:
		return await super._prototype(kind)
	var frozen_geometry: ArrayMesh = super._prop_mesh(kind)
	var prepared: ArrayMesh = _prop_mesh(kind)
	if frozen_geometry == null or prepared == null or not _roof_arrays_byte_exact(frozen_geometry, prepared):
		error = "Grey tile material changed frozen raised-cap surface arrays."
		return false
	var before: Dictionary = _tile_unchanged_geometry(frozen_geometry, prepared)
	if not bool(before["passed"]): return false
	if not await super._prototype(kind): return false
	var actual: ArrayMesh = prototypes[kind]["mesh"]
	var after: Dictionary = _tile_unchanged_geometry(frozen_geometry, actual)
	if not bool(after["passed"]):
		error = "Actual grey tile capture changed original native surfaces/support."
		return false
	var index: int = actual.get_surface_count() - 1
	var material: ShaderMaterial = actual.surface_get_material(index) as ShaderMaterial
	if material == null or material.shader == null:
		error = "Actual tile cap material missing."
		return false
	var declared: Array[String] = []
	for uniform: Dictionary in material.shader.get_shader_uniform_list(): declared.append(String(uniform["name"]))
	for uniform: String in ["native_grey_tile_cap_identity", "horizontal_axis", "cap_half_span_m", "tile_pitch_m", "course_pitch_m", "original_stone", "registered_normal", "registered_arm"]:
		if not uniform in declared:
			error = "Actual grey tile shader reflection failed: " + uniform
			return false
	if material.get_shader_parameter("original_stone") != surface.textures["stone"] or material.get_shader_parameter("registered_normal") != surface.textures["nor_gl"] or material.get_shader_parameter("registered_arm") != surface.textures["arm"]:
		error = "Actual grey tile registered sampler objects differ."
		return false
	var horizontal: bool = kind == "wall_horizontal"
	if material.get_shader_parameter("native_grey_tile_cap_identity") != 1. or material.get_shader_parameter("horizontal_axis") != (1. if horizontal else 0.) or material.get_shader_parameter("cap_half_span_m") != (.575 if horizontal else .650) or material.get_shader_parameter("tile_pitch_m") != .15625 or material.get_shader_parameter("course_pitch_m") != .20:
		error = "Actual grey tile physical parameter binding mismatch."
		return false
	var record: Dictionary = prototypes[kind]["record"]
	record["roof_cap_material_revision"] = {
		"algorithm_identity": TILE_IDENTITY,
		"surface_index": index,
		"changed_surfaces": [index],
		"scope": "MATERIAL_ONLY_RELATIVE_TO_FROZEN_ROOT100_RAISED_CAP_GEOMETRY",
		"parent_builder": {"path": TILE_PARENT_PATH, "sha256": FileAccess.get_sha256(TILE_PARENT_PATH)},
		"executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)},
		"pre_capture_geometry": before, "actual_capture_geometry": after,
		"actual_shader_code_sha256": _text_sha(material.shader.code),
		"actual_sampler_objects_equal_registered_textures": true,
		"actual_shader_parameters": {
			"native_grey_tile_cap_identity": material.get_shader_parameter("native_grey_tile_cap_identity"),
			"horizontal_axis": material.get_shader_parameter("horizontal_axis"),
			"cap_half_span_m": material.get_shader_parameter("cap_half_span_m"),
			"tile_pitch_m": material.get_shader_parameter("tile_pitch_m"),
			"course_pitch_m": material.get_shader_parameter("course_pitch_m"),
			"masonry_profile": material.get_shader_parameter("masonry_profile"),
			"masonry_tint": _v3(material.get_shader_parameter("masonry_tint"))},
		"material_provenance": "Project-authored grey clay tile organization; existing original generated stone only 0.035 luma weather contribution, registered CC0 rock normal/ARM only microdetail. NOT a photographed/scanned clay roof, NOT CC0 native geometry.",
		"curvature_scope": "Native raised cap silhouette/geometry unchanged; barrel curvature only bounded local tangent-space normal detail.",
		"all_original_wall_materials_unchanged": true,
		"layout_collision_ground_navigation_unchanged": true,
		"production_approved": false
	}
	record["geometry_change_scope"] = "No further geometry change: ROOT100 raised-cap arrays and support exact; only its final surface receives the independently recorded grey tile material."
	# The parent generic masonry evidence is retained for every original wall.
	# Correct only the last cap entry so it cannot be mistaken for wall brick.
	for evidence: Dictionary in record.get("masonry_material_evidence", []):
		if int(evidence["surface_index"]) == index:
			evidence["profile"] = TILE_IDENTITY
			evidence["provenance"] = record["roof_cap_material_revision"]["material_provenance"]
			evidence["surface_role"] = "raised_roof_cap_not_wall_masonry"
	if not _json(String(record["metadata_path"]), record): return false
	prototypes[kind]["record"] = record
	return true

func _tile_unchanged_geometry(original: ArrayMesh, current: ArrayMesh) -> Dictionary:
	var arrays_exact: bool = _roof_arrays_byte_exact(original, current)
	var a: Dictionary = _bounds(original, Basis.IDENTITY)
	var b: Dictionary = _bounds(current, Basis.IDENTITY)
	var bounds_exact: bool = not a.is_empty() and not b.is_empty() and var_to_bytes(a) == var_to_bytes(b)
	var old_materials_exact := true
	for index in range(original.get_surface_count() - 1):
		var old: ShaderMaterial = original.surface_get_material(index) as ShaderMaterial
		var now: ShaderMaterial = current.surface_get_material(index) as ShaderMaterial
		if old == null or now == null or old.shader.code != now.shader.code:
			old_materials_exact = false
			continue
		for uniform: Dictionary in old.shader.get_shader_uniform_list():
			var name: String = uniform["name"]
			if var_to_bytes(old.get_shader_parameter(name)) != var_to_bytes(now.get_shader_parameter(name)):
				# Texture Resource instance IDs differ in independently authored
				# meshes; compare actual registered object identity instead.
				if old.get_shader_parameter(name) != now.get_shader_parameter(name): old_materials_exact = false
	return {"passed": arrays_exact and bounds_exact and old_materials_exact,
		"all_surface_arrays_primitive_byte_exact": arrays_exact,
		"actual_bounds_support_byte_exact": bounds_exact,
		"all_original_wall_material_code_parameters_exact": old_materials_exact,
		"surface_count": current.get_surface_count(),
		"slots_checked": current.get_surface_count() * Mesh.ARRAY_MAX,
		"unchanged_raised_cap_surface": _roof_cap_evidence(current, current.get_surface_count() - 1),
		"method": "Every native surface array slot/primitive exact; original materials code/actual parameters exact; final raised cap material alone differs."}
