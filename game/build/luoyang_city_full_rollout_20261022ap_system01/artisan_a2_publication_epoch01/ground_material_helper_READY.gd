extends RefCounted
## Pure exact132-sprite A2 preview constructor only. No Field/Family lease.
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
static func attach_exact_preview(container: Node2D,world_size: Vector2) -> Dictionary:
	if container==null or world_size!=SIZE: return fail("A2_EXACT_PREVIEW_CONTEXT")
	if FileAccess.get_sha256(CONTRACT)!=CONTRACT_SHA or FileAccess.get_sha256(SHADER)!=SHADER_SHA: return fail("A2_EXACT_MATERIAL_SOURCE")
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not data is Dictionary or data.get("status")!="FROZEN_EXACT_A2_118_GROUND_14_PROPS_PREVIEW_ONLY" or data.scene_id!=String(ID): return fail("A2_EXACT_CONTRACT")
	var shader:=ResourceLoader.load(SHADER) as Shader
	if shader==null: return fail("A2_SHADER")
	var nodes: Dictionary={}
	for child: Node in container.get_children():
		if not String(child.name).begins_with("SceneObject_"): continue
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
	if matched.size()!=132: return fail("A2_ALL_ROWS_EXACT")
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
	return {"ok":true,"ground_material_count":118,"opaque_props_unchanged":14,"no_Field_lease_or_runtime_admission":true,"no_geometry_modified":true,"all_source_pixels_unchanged":true}
