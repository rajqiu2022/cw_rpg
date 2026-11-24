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

## Exact25i Artisan descendant only. The entire original helper above is immutable.
const FINISH_RUNTIME_PATH="res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/finish8_runtime_READY.gd"
const FINISH_RUNTIME_SHA="05ef868ff19bb03f81cffe4e1f8f304a6fae3990d3f24bd52637555b25c818e9"
const FINISH_BIND_PATH="res://build/scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json"
const FINISH_BIND_SHA="08a52adce7ab3b032baf7b33904304808352c77231009b09efd18b6bd45b0e31"
const FINISH_MOVED_FEET={
	"ap_courtyard_home_west":Vector2(590,480),"ap_courtyard_home_east":Vector2(2460,480),
	"ap_woodwork_court_west_chinese_v3":Vector2(560,1150),"ap_cloth_dye_workshop_east":Vector2(2530,1150),
	"ap_carpentry_general_shop_south":Vector2(1536,900),"ap_carpentry_cart_v2":Vector2(1200,1760),
	"ap_cloth_rack_v2":Vector2(2470,1330)}
const FINISH_NEW_SOURCES={
	"new_open_forge":{"texture":"res://art/modules/luoyang_city_finish_20261025i/chinese_open_ironwork_v2.png","size":Vector2(1938,967),"anchor":Vector2(688,805),"ratio":760.0/1487.0,"foot":Vector2(480,1840)},
	"new_pottery_kiln_workshop":{"texture":"res://art/modules/luoyang_city_finish_20261025i/pottery_kiln_house_v2.png","size":Vector2(1750,1010),"anchor":Vector2(686,844),"ratio":170.0/297.0,"foot":Vector2(2190,1840)},
	"new_plain_kitchen_rear_house":{"texture":"res://art/modules/luoyang_city_finish_20261025i/ordinary_kitchen_rear_body_v2.png","size":Vector2(1664,1088),"anchor":Vector2(864,893),"ratio":145.0/294.0,"foot":Vector2(1536,410)}}
## Exact fourteen FINAL11 authored street additions; never a generic increment admission.
const SEVEN_STREET_SOURCES={
	"seven26c_artisan_home_west_front_left":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(450,740)},
	"seven26c_artisan_home_west_front_right":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(900,740)},
	"seven26c_artisan_home_west_side":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/entities/v11_yamen_west_north_940.png","sha256":"d1a110ea2cbd5c5d9f90b3e151cf4a4375f5b61dfdc73513f241d9a130194ea7","size":Vector2(111,358),"anchor":Vector2(54,336),"ratio":0.55,"foot":Vector2(1080,735)},
	"seven26c_artisan_home_east_front_left":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(2180,740)},
	"seven26c_artisan_home_east_front_right":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(2650,740)},
	"seven26c_artisan_home_east_side":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/entities/v11_yamen_west_north_940.png","sha256":"d1a110ea2cbd5c5d9f90b3e151cf4a4375f5b61dfdc73513f241d9a130194ea7","size":Vector2(111,358),"anchor":Vector2(54,336),"ratio":0.55,"foot":Vector2(1900,735)},
	"seven26c_artisan_carpentry_front_left":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(300,1400)},
	"seven26c_artisan_carpentry_front_right":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(900,1400)},
	"seven26c_artisan_dye_front_left":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(2200,1400)},
	"seven26c_artisan_dye_front_right":{"texture":"res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","sha256":"664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0","size":Vector2(640,132),"anchor":Vector2(319,124),"ratio":0.3,"foot":Vector2(2740,1400)},
	"seven26c_artisan_home_west_bench":{"texture":"res://art/modules/luoyang_assembled_interiors_20261016g/long_bench_v1.png","sha256":"41759460141f9a6ba742d5df9d2de3fce10ba040af5a86fa8f31bd540877108e","size":Vector2(1536,1024),"anchor":Vector2(768,784),"ratio":0.1,"foot":Vector2(840,680)},
	"seven26c_artisan_home_east_wash_tub":{"texture":"res://art/modules/luoyang_assembled_20261016b/quench_tub_v1.png","sha256":"81e74615f03e9deefa7e2592adb271e3c7c995c0e3731c74bc68f6c17cc60ad7","size":Vector2(1536,1024),"anchor":Vector2(768,905),"ratio":0.085,"foot":Vector2(2250,680)},
	"seven26c_artisan_home_east_linen_rack":{"texture":"res://art/modules/luoyang_assembled_interiors_20261016g/cloth_roll_rack_v1.png","sha256":"078b1086cd2003916e73bb9c9f7a5f98d52286eabd765c609cb928e9ea84fc0e","size":Vector2(1536,1024),"anchor":Vector2(768,951),"ratio":0.1,"foot":Vector2(2420,680)},
	"seven26c_artisan_carpentry_street_gallery":{"texture":"res://art/modules/luoyang_estate_components_20261021am/corridor.png","sha256":"a335bb05e3155a1933314525824b90eba098bbd878f1f85d1db60889a549388d","size":Vector2(2615,975),"anchor":Vector2(1307,807),"ratio":0.36,"foot":Vector2(650,1550)}}
const FINISH_GEOMETRY_KEYS=["blocking","city_v3_solid_polygons_px","collision_size_px","physical_center_px","world_foot_px"]

static func _finish_fingerprint(value: Variant) -> String:
	var hash: HashingContext=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256);hash.update(var_to_bytes(value))
	return hash.finish().hex_encode()

static func _finish_rows(rows: Array) -> Dictionary:
	var result: Dictionary={}
	for raw: Variant in rows:
		if not raw is Dictionary or not raw.get("id") is String or String(raw.id).is_empty() or result.has(raw.id): return {}
		result[raw.id]=raw
	return result

static func _finish_source_geometry(row: Dictionary,size: Vector2,anchor: Vector2,ratio: float,foot: Vector2) -> bool:
	return row.get("pos")==((foot+(size*0.5-anchor)*ratio)/SIZE) and row.get("render_size_px")==size*ratio and row.get("depth_sort_foot_y")==foot.y/SIZE.y and row.get("sort_by_feet")==true and row.get("centered")==true and row.get("world_foot_px") is Array and v(row.world_foot_px)==foot and row.get("physical_center_px") is Array and v(row.physical_center_px)==foot

static func _finish_actual_sprite(field: Node,world: Node2D,node: Sprite2D,row: Dictionary,finish: RefCounted,state: Dictionary) -> bool:
	var path: String=String(row.get("texture",""))
	if path.is_empty() or node.texture==null or node.texture.resource_path!=path or not finish.texture_matches(path,node.texture): return false
	var source_sha: String=String(state.first.get(path,state.captured.get(path,"")))
	if source_sha.length()!=64 or (state.first.has(path) and state.captured.has(path) and state.first[path]!=state.captured[path]): return false
	if not row.get("pos") is Vector2 or not row.get("render_size_px") is Vector2 or node.texture.get_width()<=0 or node.texture.get_height()<=0: return false
	if node.position!=row.pos*SIZE or node.scale!=row.render_size_px/Vector2(node.texture.get_size()) or node.rotation_degrees!=float(row.get("rotation",0.0)) or node.centered!=bool(row.get("centered",true)): return false
	if node.hframes!=1 or node.vframes!=1 or node.frame!=0 or node.region_enabled or node.flip_h or node.flip_v or node.offset!=Vector2.ZERO or node.modulate!=Color.WHITE or node.self_modulate!=Color.WHITE or node.material!=null or not node.visible: return false
	if bool(row.get("sort_by_feet",false)):
		if node.get_parent()!=field.get("_actor_layer") or not row.get("depth_sort_foot_y") is float: return false
		var overlap: Variant=field.get("_v14_modular_overlap")
		if overlap==null or overlap.get_script().resource_path!="res://scripts/world/v14_modular_overlap.gd": return false
		var match_entry: Dictionary={}
		for entry: Dictionary in overlap._depth_entries:
			if entry.get("node")==node:
				if not match_entry.is_empty() or entry.get("id")!=String(row.id) or entry.get("actor")!=false: return false
				match_entry=entry
		if match_entry.is_empty(): return false
		var source_foot: Vector2=world.to_global(Vector2(node.position.x,float(row.depth_sort_foot_y)*SIZE.y))
		if match_entry.foot_local!=node.to_local(source_foot): return false
		# Two exact existing lifecycle stages, selected by the real depth registry.
		var expected_band: int=clampi(int(floor(source_foot.y/8.0)),0,int(field.call("_scene_depth_band_max")))
		if int(match_entry.band)>=0:
			var registered_foot: float=node.to_global(match_entry.foot_local).y
			expected_band=clampi(int(floor(registered_foot/8.0)),0,512)
			if int(match_entry.band)!=expected_band or float(match_entry.foot_y)!=registered_foot: return false
		if node.z_index!=expected_band: return false
	else:
		var expected_parent: Node=field.get("_foreground_layer") if String(row.get("render_layer",""))=="foreground" else field.get("_visual_layer")
		if node.get_parent()!=expected_parent or node.z_index!=int(row.get("z_index",0)): return false
	return world.is_ancestor_of(node)

static func attach_finish_exact_runtime(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if not READY or not LIFE_READY or field==null or scene==null or scene.scene_id!=ID or scene.map_layout==null or world==null or world_size!=SIZE or not owner.is_valid() or not owner.call(): return fail("FINISH_A2_EXACT_FIELD_SCENE")
	if field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or field.get("world_container")!=world or field.get("_scene_rebuilding")!=true: return fail("FINISH_A2_ACTUAL_REBUILD_OWNER")
	if FileAccess.get_sha256(FINISH_RUNTIME_PATH)!=FINISH_RUNTIME_SHA or FileAccess.get_sha256(FINISH_BIND_PATH)!=FINISH_BIND_SHA or FileAccess.get_sha256(CONTRACT)!=CONTRACT_SHA or FileAccess.get_sha256(SHADER)!=SHADER_SHA: return fail("FINISH_A2_IMMUTABLE_INPUT_PINS")
	var finish: RefCounted=field.get("_finish25i")
	if finish==null or finish.get_script().resource_path!=FINISH_RUNTIME_PATH or not finish._owned(true,true): return fail("FINISH_A2_REAL_WEAK_LEASE")
	var state: Dictionary=finish._state
	if state.get("binding_sha")!=FINISH_BIND_SHA or not state.get("scene") is WeakRef or state.scene.get_ref()!=scene or not state.get("layout") is WeakRef or state.layout.get_ref()!=scene.map_layout or not state.get("field") is WeakRef or state.field.get_ref()!=field or state.get("owner_kind")!="QUARTER_ORIGINAL": return fail("FINISH_A2_SAME_WEAK_OBJECTS")
	var family: Variant=load(FAMILY)
	if not family is GDScript or family.resource_path!=FAMILY or not family.life_source_bound_scene(scene): return fail("FINISH_A2_ORIGINAL_FAMILY_STORAGE")
	var original: Dictionary=family.original_receipt_for(scene)
	if original.is_empty() or original.get("serial")!=state.token or original.get("key")!=state.owner_key or var_to_bytes(original.get("source_first"))!=var_to_bytes(state.first): return fail("FINISH_A2_ORIGINAL_FIRST_OWNER")
	var binding: Variant=JSON.parse_string(FileAccess.get_file_as_string(FINISH_BIND_PATH))
	if not binding is Dictionary or binding.get("ready")!=true or not binding.get("scenes") is Dictionary: return fail("FINISH_A2_FIXED_BINDING_SCHEMA")
	var bound: Dictionary=binding.scenes.get(String(ID),{})
	var payload: Dictionary=state.get("payload",{})
	if bound.is_empty() or payload.is_empty() or bound.get("payload",{}).get("sha256")!="93dac66cc5e07ae84e0fd4e946856df7f8e732f387dcf84f5666e834a8484a09" or _finish_fingerprint(payload)!=state.get("payload_sha"): return fail("FINISH_A2_FIXED_PUBLISHED_PAYLOAD")
	for key: String in ["parent_native_navigation","parent_navigation","effective_navigation","visual_patches","visual_additions","visual_retired"]:
		if not payload.get(key) is Array or _finish_fingerprint(payload[key])!=bound.get("fingerprints",{}).get(key): return fail("FINISH_A2_WHOLE_TYPED_PUBLISHED_ROWS:"+key)
	if var_to_bytes(payload.parent_native_navigation)!=var_to_bytes(scene.map_layout.visual_objects) or var_to_bytes(payload.parent_navigation)!=var_to_bytes(payload.parent_native_navigation) or var_to_bytes(state.parent_blockers)!=var_to_bytes(scene.map_layout.blockers): return fail("FINISH_A2_ORIGINAL136_COMPLETE_TYPED")
	var before: Array=payload.parent_navigation
	var after: Array=payload.effective_navigation
	if before.size()!=136 or after.size()!=139+SEVEN_STREET_SOURCES.size() or payload.visual_patches.size()!=18 or payload.visual_additions.size()!=3+SEVEN_STREET_SOURCES.size() or not payload.visual_retired.is_empty(): return fail("FINISH_A2_DECLARED_DESCENDANT_SHAPE")
	var parent_rows: Dictionary=_finish_rows(before)
	var next_rows: Dictionary=_finish_rows(after)
	if parent_rows.size()!=136 or next_rows.size()!=139+SEVEN_STREET_SOURCES.size(): return fail("FINISH_A2_UNIQUE_DECLARED_IDS")
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not data is Dictionary or data.get("status")!="FROZEN_EXACT_A2_118_GROUND_14_PROPS_PREVIEW_ONLY" or data.scene_id!=String(ID) or data.ground.size()!=118 or data.props.size()!=14: return fail("FINISH_A2_ORIGINAL_CONTRACT")
	var props: Dictionary={};var ground_nodes: Array[Dictionary]=[]
	for row: Dictionary in data.props: props[String(row.placement.id)]=true
	for row: Dictionary in LIFE_ROWS:
		if props.has(String(row.id)): return fail("FINISH_A2_PARENT_PROP_ALIAS")
		props[String(row.id)]=true
	var patches: Dictionary={}
	for patch: Dictionary in payload.visual_patches:
		var id: String=String(patch.get("id",""))
		if not props.has(id) or patches.has(id) or var_to_bytes(patch.before)!=var_to_bytes(parent_rows.get(id)) or var_to_bytes(patch.after)!=var_to_bytes(next_rows.get(id)): return fail("FINISH_A2_FIXED18_PATCH_IDENTITIES")
		for key: String in patch.before:
			if not patch.after.has(key): return fail("FINISH_A2_RETAINED_PROPERTY_REMOVED")
			if var_to_bytes(patch.before[key])!=var_to_bytes(patch.after[key]) and (not FINISH_MOVED_FEET.has(id) or key not in ["pos","depth_sort_foot_y"]): return fail("FINISH_A2_NONAUTHORED_PROPERTY_CHANGE")
		var added: Array=[]
		for key: String in patch.after:
			if not patch.before.has(key): added.append(key)
		if added.size()!=5: return fail("FINISH_A2_EXACT_FIVE_GEOMETRY_ADDITIONS")
		for key: String in FINISH_GEOMETRY_KEYS:
			if key not in added: return fail("FINISH_A2_GEOMETRY_ADDITION_KEYS")
		if FINISH_MOVED_FEET.has(id) and (patch.before.pos==patch.after.pos or patch.before.depth_sort_foot_y==patch.after.depth_sort_foot_y): return fail("FINISH_A2_SEVEN_REAL_MIGRATIONS")
		patches[id]=true
	if patches.size()!=props.size() or props.size()!=18: return fail("FINISH_A2_ALL18_PARENT_PROPS_ACCOUNTED")
	var new_ids: Dictionary={}
	for row: Dictionary in payload.visual_additions:
		if (not FINISH_NEW_SOURCES.has(String(row.id)) and not SEVEN_STREET_SOURCES.has(String(row.id))) or new_ids.has(String(row.id)) or var_to_bytes(row)!=var_to_bytes(next_rows.get(String(row.id))): return fail("FINISH_A2_THREE_NEW_SOURCE_IDS")
		new_ids[String(row.id)]=true
	var nodes: Dictionary={}
	var actual: Variant=field.get("_scene_object_nodes")
	if not actual is Array: return fail("FINISH_A2_ACTUAL_SPRITE_ARRAY")
	for child: Variant in actual:
		if not is_instance_valid(child) or not child is Sprite2D or not String(child.name).begins_with("SceneObject_") or nodes.has(String(child.name)): return fail("FINISH_A2_ACTUAL_UNIQUE_SPRITE_OWNERSHIP")
		nodes[String(child.name)]=child
	if nodes.size()!=after.size(): return fail("FINISH_A2_ACTUAL139_NO_EXTRA_OR_MISSING")
	for row: Dictionary in after:
		var name: String="SceneObject_"+String(row.id)
		if not nodes.has(name) or not _finish_actual_sprite(field,world,nodes[name],row,finish,state): return fail("FINISH_A2_ACTUAL_EFFECTIVE_ROW:"+String(row.id))
	var matched: Dictionary={}
	for row: Dictionary in data.ground:
		var id: String=String(row.id);var name: String="SceneObject_"+id
		if not parent_rows.has(id) or var_to_bytes(parent_rows[id])!=var_to_bytes(next_rows.get(id)) or matched.has(name): return fail("FINISH_A2_ORIGINAL118_WHOLE_ROWS")
		var node: Sprite2D=nodes[name]
		# The full original118 ground node checks are kept verbatim.
		if node.texture==null or node.texture.resource_path!=row.texture or node.position!=v(row.pos)*SIZE or node.scale!=v(row.render_size_px)/Vector2(node.texture.get_size()) or not node.centered or node.rotation!=0 or node.z_index!=int(row.z_index) or node.material!=null: return fail("A2_GROUND_EXACT_SOURCE_AND_TRANSFORM")
		matched[name]=true;ground_nodes.append({"node":node,"row":row})
	for row: Dictionary in data.props:
		var id: String=String(row.placement.id);var asset: Dictionary=row.asset;var placement: Dictionary=row.placement
		var source_size: Vector2=v(asset.source_size);var anchor: Vector2=v(asset.ground_anchor);var ratio: float=float(placement.width)/float(asset.used_rect[2])
		var old_foot: Vector2=v(placement.foot);var foot: Vector2=FINISH_MOVED_FEET.get(id,old_foot)
		var parent: Dictionary=parent_rows[id];var child: Dictionary=next_rows[id]
		if parent.get("texture")!=asset.texture or parent.get("pos")!=((old_foot+(source_size*.5-anchor)*ratio)/SIZE) or parent.get("render_size_px")!=source_size*ratio or child.texture!=asset.texture or nodes["SceneObject_"+id].texture.get_size()!=source_size or not _finish_source_geometry(child,source_size,anchor,ratio,foot): return fail("FINISH_A2_14_SOURCE_FOOT_AND_ALPHA_CANVAS:"+id)
		matched["SceneObject_"+id]=true
	var declared: Dictionary=family.manifest()
	if declared.is_empty(): return fail("LIFE_FAMILY_HEADER")
	for row: Dictionary in LIFE_ROWS:
		var id: String=String(row.id);var source_size: Vector2=v(row.source_size_px);var anchor: Vector2=v(row.source_ground_anchor_px);var foot: Vector2=v(row.foot_px);var ratio: float=float(row.uniform_scale)
		var node: Sprite2D=nodes["SceneObject_"+id]
		if declared.source_sha256.get(row.texture)!=row.source_png_sha256 or parent_rows[id].get("texture")!=row.texture or parent_rows[id].get("pos")!=((foot+(source_size*.5-anchor)*ratio)/SIZE) or node.texture.get_size()!=source_size or not _finish_source_geometry(next_rows[id],source_size,anchor,ratio,foot): return fail("FINISH_A2_FOUR_LIFE_SOURCE_FOOT_AND_NATIVE_CANVAS")
		matched["SceneObject_"+id]=true
	for id: String in FINISH_NEW_SOURCES:
		var spec: Dictionary=FINISH_NEW_SOURCES[id];var row: Dictionary=next_rows[id];var node: Sprite2D=nodes["SceneObject_"+id]
		if row.texture!=spec.texture or node.texture.get_size()!=spec["size"] or not row.get("finish_source_size_px") is Array or v(row.finish_source_size_px)!=spec["size"] or not row.get("finish_source_anchor_px") is Array or v(row.finish_source_anchor_px)!=spec.anchor or row.get("finish_source_scale")!=spec.ratio or not _finish_source_geometry(row,spec["size"],spec.anchor,spec.ratio,spec.foot): return fail("FINISH_A2_THREE_PROCESSED_NATIVE_SOURCE_GEOMETRY")
		matched["SceneObject_"+id]=true
	if matched.size()!=139: return fail("FINISH_A2_ORIGINAL139_ALL_ACCOUNTED")
	for id: String in SEVEN_STREET_SOURCES:
		var spec: Dictionary=SEVEN_STREET_SOURCES[id];var row: Dictionary=next_rows[id];var node: Sprite2D=nodes["SceneObject_"+id]
		if matched.has("SceneObject_"+id) or row.texture!=spec.texture or String(state.first.get(spec.texture,state.captured.get(spec.texture,"")))!=spec.sha256 or node.texture.get_size()!=spec["size"] or not _finish_source_geometry(row,spec["size"],spec.anchor,spec.ratio,spec.foot): return fail("SEVEN_A2_EXACT_FROZEN_STREET_SOURCE_GEOMETRY:"+id)
		matched["SceneObject_"+id]=true
	if matched.size()!=139+SEVEN_STREET_SOURCES.size() or not owner.call() or not finish._owned(true,true) or field.get("_finish25i")!=finish: return fail("FINISH_A2_COMPLETE139_PLUS_EXACT14_OR_FINAL_OWNER")
	var shader: Shader=ResourceLoader.load(SHADER) as Shader
	if shader==null or shader.resource_path!=SHADER: return fail("A2_SHADER")
	# Same118 shader assignment/parameters as the immutable life helper, no props material.
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
	if not owner.call() or not finish._owned(true,true): return fail("A2_RUNTIME_OWNER_CHANGED")
	return {"ok":true,"ground_material_count":118,"original_parent_visual_rows":136,"effective_visual_rows":139+SEVEN_STREET_SOURCES.size(),"exact_street_additions":SEVEN_STREET_SOURCES.size(),"original_parent_props":18,"real_source_migrations":7,"geometry_only_schema_patches":11,"new_source_buildings":3,"actual_all139_source_texture_transform_native_checked":true,"original118_ground_shader_and_parameters_unchanged":true,"original_complete_Family_storage_and_sameWeak_finish_FIRST":true,"not_source_final_credit":true,"no_geometry_modified":true,"all_source_pixels_unchanged":true}
