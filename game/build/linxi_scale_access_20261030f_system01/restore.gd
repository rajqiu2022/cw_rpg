extends RefCounted
## Only Linxi3001->3002 enlarged-body restoration; no nearest-foot search.
const SIZE := Vector2(2900,2400)
const VERSION := 3002
const NEW := "res://build/linxi_scale_access_20261030f_system01/linxi_master.json"
const OLD := "res://build/linxi_scale_access_20261030f_system01/before/game/art/modules/four_settlements_20261030e/linxi_master.json"
const ARRIVAL := Vector2(1450,2140)

static func _load_data(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func _body_polygon(data: Dictionary, row: Dictionary) -> PackedVector2Array:
	var origin:=Vector2.ZERO
	var path: String=String(row.path)
	if path.begins_with("Town/") and path.ends_with("/Body"):
		var name: String=path.split("/")[1]
		for object: Dictionary in data.objects:
			if String(object.name)==name:origin=Vector2(object.foot[0],object.foot[1]);break
	var result:=PackedVector2Array()
	for point: Array in row.polygon:result.append(origin+Vector2(point[0],point[1]))
	return result

static func _overlaps(foot: Vector2, polygon: PackedVector2Array) -> bool:
	var p:=PackedVector2Array([foot+Vector2(-17,-12),foot+Vector2(17,-12),foot+Vector2(17,12),foot+Vector2(-17,12)])
	return not Geometry2D.intersect_polygons(p,polygon).is_empty()

static func _town_clear(data: Dictionary, foot: Vector2) -> bool:
	if not Rect2(110,110,2680,2180).encloses(Rect2(foot-Vector2(17,12),Vector2(34,24))):return false
	for row: Dictionary in data.blockers:
		if _overlaps(foot,_body_polygon(data,row)):return false
	return true

static func restore(uv: Vector2, source_version: int) -> Variant:
	if not uv.is_finite() or uv.x<0 or uv.x>1 or uv.y<0 or uv.y>1:return null
	var foot: Vector2=uv*SIZE
	var current: Dictionary=_load_data(NEW)
	if source_version==VERSION:return uv if _town_clear(current,foot) else null
	if source_version!=3001:return ARRIVAL/SIZE
	var previous: Dictionary=_load_data(OLD)
	# A genuinely illegal old house/tree foot is not legalized by this migration.
	if not _town_clear(previous,foot):return null
	# Preserve the old narrow-rail negative domain; only newly added real wall
	# contacts get the explicit stair-entry migration below.
	for rect: Rect2 in [Rect2(500,345,1900,10),Rect2(2395,350,10,750),Rect2(2115,1095,285,10),Rect2(1215,1095,770,10),Rect2(500,1095,585,10),Rect2(495,350,10,750)]:
		if rect.intersects(Rect2(foot-Vector2(17,12),Vector2(34,24)),true):return null
	for x: float in [1085.0,1215.0,1985.0,2115.0]:
		if Rect2(x-5,1078,10,120.5).intersects(Rect2(foot-Vector2(17,12),Vector2(34,24)),true):return null
	for row: Dictionary in current.blockers:
		var path: String=String(row.path)
		if not path in ["Town/MasterHall/Body","Town/Bedroom/Body","Town/Kitchen/Body","Terrain/RampRail0-1","Terrain/RampRail01","Terrain/RampRail1-1","Terrain/RampRail11"]:continue
		if not _overlaps(foot,_body_polygon(current,row)):continue
		var target:=Vector2(650,1740)
		if path=="Town/MasterHall/Body":target=Vector2(1249.3851102941176,818)
		elif path=="Town/Bedroom/Body":target=Vector2(2069.592944369064,858)
		elif path.begins_with("Terrain/RampRail0"):target=Vector2(1150,1290)
		elif path.begins_with("Terrain/RampRail1"):target=Vector2(2050,1290)
		return target/SIZE if _town_clear(current,target) else null
	return uv if _town_clear(current,foot) else null
