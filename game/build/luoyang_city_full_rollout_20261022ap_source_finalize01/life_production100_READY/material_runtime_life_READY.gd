extends RefCounted
## Closed runtime draft: exact Field owner plus finite Family source-FIRST.
const READY=true
const FAMILY="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const CONTRACT="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_contract_READY.json"
const CONTRACT_SHA="87abb71b03de83e2d5c14434b52d56a8be51dfe940ed85478fc34b029a4ed5af"
const SHADER="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_use_candidate.gdshader"
const SHADER_SHA="11b32bb0efbc9b1317c2ad06d028742d9bfce899e2d9b9467874c28898c2eb1e"
const ID=&"luoyang_artisan_residential_20261022ap"
const SIZE=Vector2(3072,2048)
static func v(raw: Array) -> Vector2: return Vector2(raw[0],raw[1])
static func fail(error: String) -> Dictionary: return {"ok":false,"error":error}
static func material_source_paths(id: StringName) -> Array[String]:
	return [CONTRACT,SHADER] if id==ID else []
static func attach_exact_runtime(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if LIFE_READY and scene!=null and scene.scene_id==ID:
		var life_family: Variant=load(FAMILY)
		if life_family is GDScript and life_family.resource_path==FAMILY and life_family.life_requested_scene(scene):
			return _attach_life_exact_runtime(field,scene,world,world_size,owner)
	if not READY or field==null or scene==null or scene.scene_id!=ID or world==null or world_size!=SIZE or not owner.is_valid() or not owner.call(): return fail("A2_RUNTIME_NOT_ADMITTED_OR_OWNER")
	if field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or field.get("world_container")!=world: return fail("A2_EXACT_FIELD_SCENE_WORLD")
	var family: Variant=load(FAMILY)
	if not family is GDScript or family.resource_path!=FAMILY or not family.a2_source_bound_scene(scene): return fail("A2_EXACT_FAMILY_NATIVE_SOURCE_FIRST")
	if FileAccess.get_sha256(CONTRACT)!=CONTRACT_SHA or FileAccess.get_sha256(SHADER)!=SHADER_SHA: return fail("A2_EXACT_MATERIAL_SOURCE")
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not data is Dictionary or data.get("status")!="FROZEN_EXACT_A2_118_GROUND_14_PROPS_PREVIEW_ONLY" or data.scene_id!=String(ID): return fail("A2_EXACT_CONTRACT")
	var shader:=ResourceLoader.load(SHADER) as Shader
	if shader==null: return fail("A2_SHADER")
	var nodes: Dictionary={}
	var existing: Variant=field.get("_scene_object_nodes")
	if not existing is Array: return fail("A2_FIELD_NATIVE_SPRITE_ARRAY")
	for child: Node in existing:
		if not is_instance_valid(child) or not world.is_ancestor_of(child) or not String(child.name).begins_with("SceneObject_"): return fail("A2_FIELD_NATIVE_OWNER_OR_NAME")
		if not child is Sprite2D or nodes.has(String(child.name)): return fail("A2_UNIQUE_NATIVE_SPRITE")
		nodes[String(child.name)]=child
	if nodes.size()!=132 or data.ground.size()!=118 or data.props.size()!=14: return fail("A2_EXACT132_NOT_GENERIC_COUNT_ADMISSION")
	var matched: Dictionary={};var ground_nodes: Array[Dictionary]=[]
	for row: Dictionary in data.ground:
		var name: String="SceneObject_"+String(row.id)
		if not nodes.has(name) or matched.has(name): return fail("A2_GROUND_ID")
		var node: Sprite2D=nodes[name]
		if node.texture==null or node.texture.resource_path!=row.texture or node.position!=v(row.pos)*SIZE or node.scale!=v(row.render_size_px)/Vector2(node.texture.get_size()) or not node.centered or node.rotation!=0 or node.z_index!=int(row.z_index) or node.material!=null: return fail("A2_GROUND_EXACT_SOURCE_AND_TRANSFORM")
		matched[name]=true;ground_nodes.append({"node":node,"row":row})
	for row: Dictionary in data.props:
		var name: String="SceneObject_"+String(row.placement.id)
		if not nodes.has(name) or matched.has(name): return fail("A2_RETAINED_PROP_ID")
		var node: Sprite2D=nodes[name];var asset: Dictionary=row.asset;var placement: Dictionary=row.placement
		var s: float=float(placement.width)/float(asset.used_rect[2]);var foot: Vector2=v(placement.foot)
		var center: Vector2=(foot+(v(asset.source_size)*.5-v(asset.ground_anchor))*s)/SIZE
		if node.texture==null or node.texture.resource_path!=asset.texture or node.position!=center*SIZE or node.scale!=(v(asset.source_size)*s)/Vector2(node.texture.get_size()) or not node.centered or node.rotation!=0 or node.material!=null: return fail("A2_PROP_OPAQUE_ORIGINAL_SOURCE_AND_SOURCE_FOOT")
		matched[name]=true
	if matched.size()!=132 or not owner.call(): return fail("A2_ALL_ROWS_EXACT_OR_OWNER")
	# Attach only after the entire118ground+14prop immutable whitelist passed.
	for entry: Dictionary in ground_nodes:
		var node: Sprite2D=entry.node;var row: Dictionary=entry.row;var profile: Dictionary=data.profiles[row.profile]
		var material:=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("ap_sprite_origin",node.position)
		material.set_shader_parameter("ap_source_to_world",node.scale)
		material.set_shader_parameter("ap_coverage",float(profile.coverage))
		material.set_shader_parameter("ap_edge_width",float(profile.edge_world))
		var tree: bool=row.profile=="tree_pit";material.set_shader_parameter("ap_tree_pit",tree)
		if tree:
			var r: Array=data.section_rects[row.section]
			material.set_shader_parameter("ap_tree_rect",Vector4(r[0],r[1],r[2],r[3]))
			material.set_shader_parameter("ap_grass_saturation",float(profile.saturation))
		else:
			material.set_shader_parameter("ap_tone",Color(profile.tone[0],profile.tone[1],profile.tone[2],1))
			material.set_shader_parameter("ap_contrast",float(profile.contrast))
			var edges: Array=data.union_exterior_segments[row.profile];var packed:=PackedVector4Array()
			for i: int in 64:
				var edge: Array=edges[i] if i<edges.size() else [0,0,0,0]
				packed.append(Vector4(edge[0],edge[1],edge[2],edge[3]))
			material.set_shader_parameter("ap_edges",packed)
			material.set_shader_parameter("ap_edge_count",edges.size())
		node.material=material
		node.set_meta("ap_a2_exact_use_material",{"section":row.section,"profile":row.profile,"whole_use_union_exterior":true,"not_per_tile_feather":true})
	if not owner.call(): return fail("A2_RUNTIME_OWNER_CHANGED")
	return {"ok":true,"ground_material_count":118,"opaque_props_unchanged":14,"exact_Field_owner_and_Family_source_first":true,"not_source_final_credit":true,"no_geometry_modified":true,"all_source_pixels_unchanged":true}

## Four fixed additive props only; old132/14 path above remains unchanged.
const LIFE_READY=true
const LIFE_ROWS=[
	{
		"id": "ap_life_dye_rinse_tub_a",
		"texture": "res://art/modules/luoyang_assembled_20261016b/quench_tub_v1.png",
		"source_png_sha256": "81e74615f03e9deefa7e2592adb271e3c7c995c0e3731c74bc68f6c17cc60ad7",
		"source_size_px": [
			1536,
			1024
		],
		"source_ground_anchor_px": [
			768,
			905
		],
		"uniform_scale": 0.085,
		"foot_px": [
			2128,
			1344
		]
	},
	{
		"id": "ap_life_dye_rinse_tub_b",
		"texture": "res://art/modules/luoyang_assembled_20261016b/quench_tub_v1.png",
		"source_png_sha256": "81e74615f03e9deefa7e2592adb271e3c7c995c0e3731c74bc68f6c17cc60ad7",
		"source_size_px": [
			1536,
			1024
		],
		"source_ground_anchor_px": [
			768,
			905
		],
		"uniform_scale": 0.085,
		"foot_px": [
			2264,
			1344
		]
	},
	{
		"id": "ap_life_well_tea_table",
		"texture": "res://art/modules/luoyang_assembled_interiors_20261016g/dining_table_v1.png",
		"source_png_sha256": "6874cc7448d617579e5c6f358333f7d90e403b8738c7762edf5b8886261a2ae6",
		"source_size_px": [
			1536,
			1024
		],
		"source_ground_anchor_px": [
			768,
			934
		],
		"uniform_scale": 0.12,
		"foot_px": [
			1260,
			1080
		]
	},
	{
		"id": "ap_life_well_wait_bench",
		"texture": "res://art/modules/luoyang_assembled_interiors_20261016g/long_bench_v1.png",
		"source_png_sha256": "41759460141f9a6ba742d5df9d2de3fce10ba040af5a86fa8f31bd540877108e",
		"source_size_px": [
			1536,
			1024
		],
		"source_ground_anchor_px": [
			768,
			784
		],
		"uniform_scale": 0.12,
		"foot_px": [
			1260,
			1224
		]
	}
]
static func _attach_life_exact_runtime(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if not LIFE_READY or not READY or field==null or scene==null or scene.scene_id!=ID or world==null or world_size!=SIZE or not owner.is_valid() or not owner.call(): return fail("A2_RUNTIME_NOT_ADMITTED_OR_OWNER")
	if field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or field.get("world_container")!=world: return fail("A2_EXACT_FIELD_SCENE_WORLD")
	var family: Variant=load(FAMILY)
	if not family is GDScript or family.resource_path!=FAMILY or not family.life_source_bound_scene(scene): return fail("A2_EXACT_FAMILY_NATIVE_SOURCE_FIRST")
	if FileAccess.get_sha256(CONTRACT)!=CONTRACT_SHA or FileAccess.get_sha256(SHADER)!=SHADER_SHA: return fail("A2_EXACT_MATERIAL_SOURCE")
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not data is Dictionary or data.get("status")!="FROZEN_EXACT_A2_118_GROUND_14_PROPS_PREVIEW_ONLY" or data.scene_id!=String(ID): return fail("A2_EXACT_CONTRACT")
	var shader:=ResourceLoader.load(SHADER) as Shader
	if shader==null: return fail("A2_SHADER")
	var nodes: Dictionary={}
	var existing: Variant=field.get("_scene_object_nodes")
	if not existing is Array: return fail("A2_FIELD_NATIVE_SPRITE_ARRAY")
	for child: Node in existing:
		if not is_instance_valid(child) or not world.is_ancestor_of(child) or not String(child.name).begins_with("SceneObject_"): return fail("A2_FIELD_NATIVE_OWNER_OR_NAME")
		if not child is Sprite2D or nodes.has(String(child.name)): return fail("A2_UNIQUE_NATIVE_SPRITE")
		nodes[String(child.name)]=child
	if nodes.size()!=136 or data.ground.size()!=118 or data.props.size()!=14: return fail("LIFE_EXACT136_WITH_ORIGINAL118_GROUND_AND14_PROPS")
	var matched: Dictionary={};var ground_nodes: Array[Dictionary]=[]
	for row: Dictionary in data.ground:
		var name: String="SceneObject_"+String(row.id)
		if not nodes.has(name) or matched.has(name): return fail("A2_GROUND_ID")
		var node: Sprite2D=nodes[name]
		if node.texture==null or node.texture.resource_path!=row.texture or node.position!=v(row.pos)*SIZE or node.scale!=v(row.render_size_px)/Vector2(node.texture.get_size()) or not node.centered or node.rotation!=0 or node.z_index!=int(row.z_index) or node.material!=null: return fail("A2_GROUND_EXACT_SOURCE_AND_TRANSFORM")
		matched[name]=true;ground_nodes.append({"node":node,"row":row})
	for row: Dictionary in data.props:
		var name: String="SceneObject_"+String(row.placement.id)
		if not nodes.has(name) or matched.has(name): return fail("A2_RETAINED_PROP_ID")
		var node: Sprite2D=nodes[name];var asset: Dictionary=row.asset;var placement: Dictionary=row.placement
		var s: float=float(placement.width)/float(asset.used_rect[2]);var foot: Vector2=v(placement.foot)
		var center: Vector2=(foot+(v(asset.source_size)*.5-v(asset.ground_anchor))*s)/SIZE
		if node.texture==null or node.texture.resource_path!=asset.texture or node.position!=center*SIZE or node.scale!=(v(asset.source_size)*s)/Vector2(node.texture.get_size()) or not node.centered or node.rotation!=0 or node.material!=null: return fail("A2_PROP_OPAQUE_ORIGINAL_SOURCE_AND_SOURCE_FOOT")
		matched[name]=true
	var declared: Dictionary=family.manifest()
	if declared.is_empty(): return fail("LIFE_FAMILY_HEADER")
	for row: Dictionary in LIFE_ROWS:
		var name: String="SceneObject_"+String(row.id)
		if not nodes.has(name) or matched.has(name) or declared.source_sha256.get(row.texture)!=row.source_png_sha256: return fail("LIFE_EXACT_FOUR_SOURCE_IDS")
		var node: Sprite2D=nodes[name]
		var source_size: Vector2=v(row.source_size_px);var anchor: Vector2=v(row.source_ground_anchor_px)
		var foot: Vector2=v(row.foot_px);var scale_value: float=float(row.uniform_scale)
		var native_center: Vector2=(foot+(source_size*.5-anchor)*scale_value)/SIZE
		if node.texture==null or node.texture.resource_path!=row.texture or node.texture.get_size()!=source_size or node.position!=native_center*SIZE or node.scale!=(source_size*scale_value)/Vector2(node.texture.get_size()) or not node.centered or node.rotation!=0 or node.material!=null: return fail("LIFE_EXACT_SOURCE_CANVAS_SCALE_AND_NATIVE_FOOT_FORMULA")
		if node.hframes!=1 or node.vframes!=1 or node.region_enabled or node.flip_h or node.flip_v or node.offset!=Vector2.ZERO or node.modulate!=Color.WHITE or node.self_modulate!=Color.WHITE: return fail("LIFE_WHOLE_PNG_OPAQUE_UNCROPPED_UNALTERED")
		matched[name]=true
	if matched.size()!=136 or not owner.call(): return fail("LIFE_ALL136_ROWS_EXACT_OR_OWNER")
	# Attach the original118ground material only after all14+4 opaque props passed.
	for entry: Dictionary in ground_nodes:
		var node: Sprite2D=entry.node;var row: Dictionary=entry.row;var profile: Dictionary=data.profiles[row.profile]
		var material:=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("ap_sprite_origin",node.position)
		material.set_shader_parameter("ap_source_to_world",node.scale)
		material.set_shader_parameter("ap_coverage",float(profile.coverage))
		material.set_shader_parameter("ap_edge_width",float(profile.edge_world))
		var tree: bool=row.profile=="tree_pit";material.set_shader_parameter("ap_tree_pit",tree)
		if tree:
			var r: Array=data.section_rects[row.section]
			material.set_shader_parameter("ap_tree_rect",Vector4(r[0],r[1],r[2],r[3]))
			material.set_shader_parameter("ap_grass_saturation",float(profile.saturation))
		else:
			material.set_shader_parameter("ap_tone",Color(profile.tone[0],profile.tone[1],profile.tone[2],1))
			material.set_shader_parameter("ap_contrast",float(profile.contrast))
			var edges: Array=data.union_exterior_segments[row.profile];var packed:=PackedVector4Array()
			for i: int in 64:
				var edge: Array=edges[i] if i<edges.size() else [0,0,0,0]
				packed.append(Vector4(edge[0],edge[1],edge[2],edge[3]))
			material.set_shader_parameter("ap_edges",packed)
			material.set_shader_parameter("ap_edge_count",edges.size())
		node.material=material
		node.set_meta("ap_a2_exact_use_material",{"section":row.section,"profile":row.profile,"whole_use_union_exterior":true,"not_per_tile_feather":true})
	if not owner.call(): return fail("A2_RUNTIME_OWNER_CHANGED")
	return {"ok":true,"ground_material_count":118,"original_opaque_props_unchanged":14,"life_props_added":4,"opaque_props_total":18,"exact_Field_owner_and_Family_source_first":true,"not_source_final_credit":true,"no_geometry_modified":true,"all_source_pixels_unchanged":true,"new_actor_local_ghost_not_tested_here":true}
