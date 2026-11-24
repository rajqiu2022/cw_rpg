extends RefCounted
## Author geometry only. Existing business doors/NPC/actions remain the owners'.
const DATA := "res://build/city_neighborhoods_20261031d/neighborhoods03.json"
const Common = preload("res://build/three_settlements_20261030e_system01/common_author.gd")
static var _data: Dictionary = {}

static func definition(city: String) -> Dictionary:
	if _data.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if not raw is Dictionary or raw.get("schema") != 1:return {}
		_data = raw
	return _data.cities.get(city,{})

static func _building(raw: Array) -> Dictionary:
	var texture: String
	match String(raw[1]):
		"east":texture=Common.EAST
		"west":texture=Common.WEST
		"warehouse":texture=Common.BASE+"canal_warehouse_v3.png"
		"row":texture=Common.BASE+"street_row_v3.png"
		_:return {}
	return Common.building(String(raw[0]),texture,Vector2(raw[2],raw[3]),float(raw[4]),float(raw[5]),String(raw[6]))

static func buildings(city: String, original: Array[Dictionary]) -> Array[Dictionary]:
	var spec: Dictionary=definition(city)
	var out: Array[Dictionary]=original.duplicate(true)
	for removed: String in spec.get("remove",[]):
		for i: int in range(out.size()-1,-1,-1):
			if String(out[i].id)==removed:out.remove_at(i)
	for raw: Array in spec.get("replace",[]):
		var index := -1
		for i: int in range(out.size()):
			if String(out[i].id)==String(raw[0]):index=i;break
		if index<0:return []
		out[index]=_building(raw)
	for raw: Array in spec.get("add",[]):out.append(_building(raw))
	return out

static func roads(city: String, original: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary]=original.duplicate(true)
	for raw: Array in definition(city).get("replace_routes",[]):
		for i: int in range(out.size()):
			if String(out[i].id)!=String(raw[0]):continue
			var points:=PackedVector2Array()
			for point: Array in raw[1]:points.append(Vector2(point[0],point[1]))
			out[i].points=points;out[i].width=float(raw[2])
	for raw: Array in definition(city).get("routes",[]):
		var points:=PackedVector2Array()
		for point: Array in raw[1]:points.append(Vector2(point[0],point[1]))
		out.append({"id":String(raw[0]),"points":points,"width":float(raw[2]),"texture":"res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"})
	return out

static func restore(city: String, uv: Vector2, old_safe: Callable, new_safe: Callable) -> Variant:
	if not uv.is_finite() or not old_safe.is_valid() or not new_safe.is_valid() or not bool(old_safe.call(uv)):return null
	if bool(new_safe.call(uv)):return uv
	var point:=uv*Vector2(5632,4096)
	var foot_body:=Rect2(point-Vector2(17,12),Vector2(34,24))
	var spec: Dictionary=definition(city)
	var hit := false
	for key: String in ["replace","add"]:
		for raw: Array in spec.get(key,[]):
			if foot_body.intersects(_building(raw).body,true):hit=true;break
	if not hit:return null
	var raw_target: Array=spec.get("migration_foot",[])
	if raw_target.size()!=2:return null
	var target:=Vector2(raw_target[0],raw_target[1])/Vector2(5632,4096)
	return target if bool(new_safe.call(target)) else null
