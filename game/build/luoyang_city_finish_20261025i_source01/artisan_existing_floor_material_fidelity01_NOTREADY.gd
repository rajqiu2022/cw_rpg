extends RefCounted
# Authoring-only faithful drawing of original118 material uniforms. No owner proxy.
# Actual runtime still requires original source lease + full new overlay admission.
const SHADER_PATH: String="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_use_candidate.gdshader"
const SIZE: Vector2=Vector2(3072,2048)
static func v(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)
static func attach_authoring_only(world: Node2D,contract: Dictionary,shader: Shader) -> bool:
	if world==null or shader==null or shader.resource_path!=SHADER_PATH or contract.get("ground",[]).size()!=118: return false
	var nodes: Dictionary={}
	for layer: Node in world.get_children():
		if not layer is Node2D or not layer.y_sort_enabled: continue
		for pivot: Node in layer.get_children():
			if pivot.get_child_count()!=1 or not pivot.get_child(0) is Sprite2D: continue
			if nodes.has(String(pivot.name)): return false
			nodes[String(pivot.name)]={"pivot":pivot,"sprite":pivot.get_child(0)}
	var selected: Array=[]
	for row: Dictionary in contract.ground:
		var entry: Dictionary=nodes.get(String(row.id),{})
		if entry.is_empty(): return false
		var node: Sprite2D=entry.sprite
		var origin: Vector2=v(row.pos)*SIZE
		if node.texture==null or node.texture.resource_path!=String(row.texture) or entry.pivot.position+node.position!=origin: return false
		if node.scale!=v(row.render_size_px)/node.texture.get_size() or not node.centered or node.material!=null or node.z_index!=int(row.z_index): return false
		if not contract.profiles.has(String(row.profile)): return false
		selected.append({"node":node,"row":row,"origin":origin})
	if selected.size()!=118: return false
	for entry: Dictionary in selected:
		var row: Dictionary=entry.row
		var node: Sprite2D=entry.node
		var profile: Dictionary=contract.profiles[row.profile]
		var material: ShaderMaterial=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("ap_sprite_origin",entry.origin)
		material.set_shader_parameter("ap_source_to_world",node.scale)
		material.set_shader_parameter("ap_coverage",float(profile.coverage))
		material.set_shader_parameter("ap_edge_width",float(profile.edge_world))
		var tree: bool=String(row.profile)=="tree_pit"
		material.set_shader_parameter("ap_tree_pit",tree)
		if tree:
			var rectangle: Array=contract.section_rects[row.section]
			material.set_shader_parameter("ap_tree_rect",Vector4(float(rectangle[0]),float(rectangle[1]),float(rectangle[2]),float(rectangle[3])))
			material.set_shader_parameter("ap_grass_saturation",float(profile.saturation))
		else:
			material.set_shader_parameter("ap_tone",Color(float(profile.tone[0]),float(profile.tone[1]),float(profile.tone[2]),1.0))
			material.set_shader_parameter("ap_contrast",float(profile.contrast))
			var edges: Array=contract.union_exterior_segments[row.profile]
			var packed: PackedVector4Array=PackedVector4Array()
			if edges.size()>64: return false
			for index: int in range(64):
				var edge: Array=edges[index] if index<edges.size() else [0,0,0,0]
				packed.append(Vector4(float(edge[0]),float(edge[1]),float(edge[2]),float(edge[3])))
			material.set_shader_parameter("ap_edges",packed)
			material.set_shader_parameter("ap_edge_count",edges.size())
		node.material=material
	return true
