extends RefCounted
## Drawing-only district shapes. No physics, NPC, portal or saved-foot mutation.
const DATA := "res://build/city_visual_diversity_20261031c/district_patches.json"
const EDGE = preload("res://build/city_visual_diversity_20261031c/district_ground_edge.gdshader")

static func rows(city: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not raw is Dictionary or int(raw.get("schema_version", 0)) != 1:
        return result
    for source: Dictionary in raw.get("cities", {}).get(city, []):
        var polygon := PackedVector2Array()
        for point: Array in source.polygon:
            polygon.append(Vector2(float(point[0]), float(point[1])))
        if polygon.size() < 3 or polygon.size() > 16:
            return []
        result.append({"id": source.id, "polygon": polygon, "texture": source.texture,
            "period": Vector2(float(source.period[0]), float(source.period[1])),
            "z": int(source.z), "feather_px": float(source.get("feather_px", 24.0))})
    return result

static func install_luoyang(field: Node, region: Dictionary) -> bool:
    if String(region.get("id", "")) != "luoyang_civic_market_region_27d":
        return true
    var layer: Node = field.get("_visual_layer")
    var sources: Dictionary = field.get("_region_sources")
    if not is_instance_valid(layer):
        return false
    var descriptors := rows("luoyang")
    if descriptors.size() != 3:
        return false
    for row: Dictionary in descriptors:
        if not sources.has(String(row.texture)):
            return false
        var texture := load(String(row.texture)) as Texture2D
        if texture == null:
            return false
        var polygon: PackedVector2Array = row.polygon
        var node := Polygon2D.new()
        node.name = "District31c_" + String(row.id)
        node.polygon = polygon
        node.texture = texture
        node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        node.z_index = int(row.z)
        var uv := PackedVector2Array()
        for point: Vector2 in polygon:
            uv.append(point / row.period * texture.get_size())
        node.uv = uv
        var material := ShaderMaterial.new()
        material.shader = EDGE
        var boundary: PackedVector2Array = polygon.duplicate()
        boundary.resize(16)
        material.set_shader_parameter("edge_points", boundary)
        material.set_shader_parameter("edge_count", polygon.size())
        material.set_shader_parameter("feather_px", float(row.feather_px))
        node.material = material
        layer.add_child(node)
    return true
