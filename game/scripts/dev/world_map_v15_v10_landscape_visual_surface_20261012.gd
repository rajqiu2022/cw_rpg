extends "res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd"

## Independent visual candidate. Existing 18 CC0 scan channels retain their
## physical scales and complete RGB/normal/ARM ownership. No displacement,
## water discard/alpha, RF, navigation, plant placement or bridge mesh edit.
const LANDSCAPE_ID := "V10_LANDSCAPE_GRASS_BANK_WATER_TIMBER_VISUAL_ONLY"
var landscape_records: Array[Dictionary] = []

func _v9c_fragment() -> String:
	var code: String = super._v9c_fragment()
	var edits: Array = [
		["vec3 turf=(gd*.80+ld*.20)*vec3(.86,1.10,.80);", "float meadow=n2(xyz.xz/9.7+vec2(2.1,-6.3))*.62+n2(xyz.xz/3.4)*.38;\n float leaf_owner=mix(.12,.42,smoothstep(.28,.72,meadow));\n vec3 grass_pigment=mix(vec3(.60,.79,.52),vec3(.94,1.01,.73),smoothstep(.24,.77,meadow));\n vec3 turf=mix(gd,ld,leaf_owner)*grass_pigment;"],
		["vec3 turf_a=ga*.80+la*.20,turf_n=gnscan*.80+ln*.20;", "vec3 turf_a=mix(ga,la,leaf_owner),turf_n=mix(gnscan,ln,leaf_owner);"],
		["float dry_island=.015+.085*(1.-growth);", "float dry_island=.035+.19*(1.-smoothstep(.25,.73,meadow))*(1.-wet);"],
		["col=mix(col,litter*vec3(.74,.94,.69),forest*.80);", "col=mix(col,litter*mix(vec3(.49,.66,.43),vec3(.74,.87,.62),patch),forest*.80);"],
		["// Material snow coverage is irregular;", "// Damp mineral/litter shoreline on existing dry receiver only.\n float moist_bank=(1.-smoothstep(.03,.27,xyz.y))*smoothstep(-.005,.025,xyz.y)*(1.-route)*(1.-snow)*(1.-rock*.6);\n float bank_grain=n2(xyz.xz/.32)*.35+n2(xyz.xz/1.4)*.65;\n vec3 bank_rgb=mix(bd*.60+fd*.30+rd*.10,ld*.30+fd*.45+bd*.25,bank_grain)*vec3(.63,.67,.55);\n col=mix(col,bank_rgb,moist_bank*.52);\n arm=mix(arm,mix(ba*.60+fa*.30+ra*.10,la*.30+fa*.45+ba*.25,bank_grain),moist_bank*.52);\n detail=mix(detail,mix(bn*.60+fn*.30+rn*.10,ln*.30+fn*.45+bn*.25,bank_grain),moist_bank*.52);\n // Material snow coverage is irregular;"]
	]
	for pair: Array in edits:
		code = _replace_once(code, pair[0], pair[1])
		if code.is_empty(): return ""
	return code

func terrain_material(weights: Texture2D, roads: Texture2D, local_rect: Rect2) -> ShaderMaterial:
	var material: ShaderMaterial = super.terrain_material(weights, roads, local_rect)
	if material == null: return null
	landscape_records.append({"kind":"terrain", "identity":LANDSCAPE_ID,
		"actual_code_sha256":_v7_code_sha(material.shader.code), "bindings":_v7_binding_evidence(material),
		"grass_leaf_owner_range":[.12,.42], "soil_owner_range":[.035,.225],
		"provenance":"same18 registered CC0 channels plus project-original moisture/pigment formulas",
		"geometry_navigation_changed":false, "visual_approved":false})
	return material

static func native_wildflower_mesh(variant: int) -> ArrayMesh:
	# NEW project-original low decorative geometry. No bitmap/AI/external
	# flower asset or CC0 claim. Nonblocking authoring preview only.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var flower_color: Color = [Color(.72,.66,.45),Color(.72,.60,.64),Color(.77,.79,.67)][posmod(variant,3)]
	for stem in 3:
		var origin := Vector3(cos(stem*2.4)*.075,0.,sin(stem*2.4)*.075)
		var head: Vector3 = origin+Vector3(.018,.13+.035*stem,-.013)
		for point: Vector3 in [origin+Vector3(-.004,0,0),head,origin+Vector3(.004,0,0)]:
			tool.set_color(Color(.22,.34,.12))
			tool.add_vertex(point)
		for petal in 5:
			var angle: float = petal*TAU/5.
			for point: Vector3 in [head,head+Vector3(cos(angle-.35)*.041,-.005,sin(angle-.35)*.041),head+Vector3(cos(angle+.35)*.041,-.005,sin(angle+.35)*.041)]:
				tool.set_color(flower_color)
				tool.add_vertex(point)
	tool.generate_normals()
	var mesh: ArrayMesh = tool.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = .88
	mesh.surface_set_material(0,material)
	return mesh

func water_material(height_rf: Texture2D, grid_origin: Vector2i, grid_shape: Vector2i) -> ShaderMaterial:
	var material: ShaderMaterial = super.water_material(height_rf, grid_origin, grid_shape)
	if material == null: return null
	var code: String = material.shader.code
	code = _replace_once(code,
		"return .00065*sin(a)*( .35+.65*rich_n(q/1.1))+ .00042*sin(q.y*8.3-q.x*2.1+(rich_n(q/2.8)-.5)*3.2);",
		"return .00105*sin(a)*(.25+.75*rich_n(q/1.1))+.00048*sin(q.y*12.7-q.x*3.9+(rich_n(q/1.9)-.5)*4.1)+.00022*sin(q.x*23.4+q.y*6.1);")
	if code.is_empty(): return null
	_rich_install(material, code)
	landscape_records.append({"kind":"water", "identity":LANDSCAPE_ID,
		"actual_code_sha256":_v7_code_sha(code), "actual_RF_texture_bound":material.get_shader_parameter("actual_height_rf") == height_rf,
		"depth_discard_alpha_water_Y_unchanged":true, "static_baked_detail_not_live_flow":true,
		"provenance":"project-original fixed global ripple normals; not a licensed water scan",
		"geometry_navigation_changed":false, "visual_approved":false})
	return material

func bridge_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 p;void vertex(){p=VERTEX;}
float hash(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 float board=hash(vec2(floor(p.x*7.8),floor(p.z*7.8)));
 float bend=sin(p.z*4.1+p.x*.8)*1.4;
 float fine=sin(p.x*138.+bend)*.022+sin(p.x*367.+p.z*6.)*.009;
 float ring=sin(p.x*48.+sin(p.z*2.1)*2.4)*.018;
 float age=.5+.5*sin(p.z*.7+board*5.);
 vec3 timber=mix(vec3(.16,.105,.059),vec3(.30,.235,.145),board*.62+age*.20);
 ALBEDO=timber+fine+ring;ROUGHNESS=.73+board*.13;SPECULAR=.19;
 vec3 wn=normalize(NORMAL+vec3(fine*.8,0.,ring*.3));NORMAL=wn;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	landscape_records.append({"kind":"bridge", "identity":LANDSCAPE_ID,
		"actual_code_sha256":_v7_code_sha(shader.code), "provenance":"project-original procedural timber; not CC0 wood scan",
		"geometry_navigation_changed":false, "visual_approved":false})
	return material
