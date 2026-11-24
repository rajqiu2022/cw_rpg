extends RefCounted
# Pure visible material factory. Does not make bodies, routes or mask claims.
const SHADER_PATH: String="res://build/luoyang_city_finish_20261025i_source01/city_purpose_surface02_soft_joint_NOTREADY.gdshader"
static func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
static func create(rows: Array,textures: Dictionary,shader: Shader) -> Node2D:
	if shader==null or shader.resource_path!=SHADER_PATH: return null
	var root: Node2D=Node2D.new();root.name="CityPurposeGround25i";root.z_index=-3
	var seen: Dictionary={}
	for raw: Variant in rows:
		if not raw is Dictionary: root.free();return null
		var row: Dictionary=raw
		var id: String=String(row.get("id",""));var role: String=String(row.get("texture_role",""))
		if id=="" or seen.has(id) or not textures.get(role) is Texture2D: root.free();return null
		seen[id]=true
		var path: PackedVector2Array=PackedVector2Array()
		var bounds: Rect2
		var shoulder: float=float(row.get("shoulder_px",14.0))
		if row.has("polyline_px"):
			if not row.polyline_px is Array or row.polyline_px.size()<2 or row.polyline_px.size()>16: root.free();return null
			for point: Variant in row.polyline_px:
				var p: Vector2=v(point)
				if not p.is_finite(): root.free();return null
				path.append(p)
			bounds=Rect2(path[0],Vector2.ZERO)
			for p: Vector2 in path: bounds=bounds.expand(p)
			bounds=bounds.grow(float(row.get("width_px",144.0))*0.5+shoulder)
		else:
			var r: Variant=row.get("rect_xywh")
			if not r is Array or r.size()!=4: root.free();return null
			bounds=Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
		if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x<=0 or bounds.size.y<=0: root.free();return null
		var material: ShaderMaterial=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("source_material",textures[role])
		material.set_shader_parameter("bounds_origin_px",bounds.position);material.set_shader_parameter("bounds_size_px",bounds.size)
		material.set_shader_parameter("repeat_period_px",v(row.get("repeat_period_px",[256,256])))
		var c: Array=row.get("tint_rgba",[1,1,1,1])
		if c.size()!=4: root.free();return null
		material.set_shader_parameter("tint",Color(float(c[0]),float(c[1]),float(c[2]),float(c[3])))
		material.set_shader_parameter("contrast",float(row.get("contrast",0.8)))
		material.set_shader_parameter("opacity",float(row.get("opacity",1.0)))
		material.set_shader_parameter("full_base_coverage",row.get("full_base_coverage",false)==true)
		material.set_shader_parameter("shoulder_px",shoulder)
		material.set_shader_parameter("corner_radius_px",float(row.get("corner_radius_px",20.0)))
		material.set_shader_parameter("is_path",not path.is_empty());material.set_shader_parameter("path_count",path.size())
		material.set_shader_parameter("path_half_width_px",float(row.get("width_px",144.0))*0.5)
		var points: PackedVector2Array=path.duplicate()
		while points.size()<16: points.append(Vector2.ZERO)
		material.set_shader_parameter("path_points",points)
		var tile: Polygon2D=Polygon2D.new();tile.name=id;tile.material=material
		tile.z_index=int(row.get("relative_z_index",0))
		tile.polygon=PackedVector2Array([bounds.position,bounds.position+Vector2(bounds.size.x,0),bounds.end,bounds.position+Vector2(0,bounds.size.y)])
		tile.uv=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN])
		root.add_child(tile)
	return root
