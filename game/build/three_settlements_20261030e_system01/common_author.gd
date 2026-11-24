extends RefCounted
## Geometry only. No runtime, canonical scene, business or save writes.
const BASE := "res://art/maps/luoyang_modular_v3/source/"
const EAST := "res://art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png"
const WEST := "res://art/maps/luoyang_city_rebuild_20261027d/west_shop_residence_v1_padded.png"
const NATIVE := {EAST:[708.5,1204.0,1009.0],WEST:[674.0,1300.0,1058.0],BASE+"street_row_v3.png":[775.0,920.0,1498.0],BASE+"inn_v1.png":[768.0,974.0,1326.0],BASE+"shop_v1.png":[768.0,950.0,1498.0],BASE+"canal_warehouse_v3.png":[888.0,709.0,1744.0],BASE+"notice_pavilion_v2.png":[768.5,969.0,1331.0]}

static func building(id: String, texture: String, foot: Vector2, width: float, depth: float, usage: String) -> Dictionary:
	var source: Array=NATIVE[texture]
	return {"id":id,"texture":texture,"foot":foot,"native_scale":width/float(source[2]),"source_foot_px":[source[0],source[1]],"visible_width":width,"body":Rect2(foot-Vector2(width*.43,depth),Vector2(width*.86,depth)),"usage":usage}

static func good(id: String, texture: String, foot: Vector2, scale_factor: float, source_foot: Vector2, source_body: Rect2, usage: String) -> Dictionary:
	return {"id":id,"texture":texture,"foot":foot,"native_scale":scale_factor,"source_foot_px":[source_foot.x,source_foot.y],"body":Rect2(foot+(source_body.position-source_foot)*scale_factor,source_body.size*scale_factor),"usage":usage}

static func rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

static func normalized_polygon(polygon: PackedVector2Array, size: Vector2) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for point: Vector2 in polygon:out.append(point/size)
	return out

static func safe_foot(author: Variant, uv: Vector2, include_npcs: bool = true) -> bool:
	if not uv.is_finite():return false
	var size: Vector2=author.SIZE
	var foot: Vector2=uv*size
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	var polygon:=rect_polygon(body)
	var layout: WalkableMapLayout=author.layout()
	for corner: Vector2 in polygon:
		var admitted:=false
		for region: PackedVector2Array in layout.walkable_regions:
			if Geometry2D.is_point_in_polygon(corner/size,region):admitted=true;break
		if not admitted:return false
	var shapes: Array[Dictionary]=author.building_specs();shapes.append_array(author.prop_specs())
	for row: Dictionary in shapes:
		if row.has("body") and body.intersects(row.body,true):return false
	for solid: PackedVector2Array in author.solid_polygons():
		if not Geometry2D.intersect_polygons(polygon,solid).is_empty():return false
	if include_npcs:
		for npc: Dictionary in author.npc_rows():
			var sweep: Vector2=Vector2.ZERO
			if String(npc.get("movement_mode","idle"))=="patrol":sweep=(npc.get("patrol_axis",Vector2.RIGHT) as Vector2).abs()*float(npc.get("patrol_distance",32))
			var center: Vector2=npc.pos*size
			if body.intersects(Rect2(center-Vector2(14,15)-sweep,Vector2(28,30)+sweep*2),true):return false
	return true
