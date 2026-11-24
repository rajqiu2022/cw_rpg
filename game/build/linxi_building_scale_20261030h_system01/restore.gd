extends RefCounted
## Only the two building-scale revisions. No nearest search or save-schema write.
const VERSION:=3004
const BASE:="res://build/linxi_building_scale_20261030h_system01/"
const IDS:={"linxi_village_center":"linxi_center","linxi_village_scrollmap":"linxi_south"}
const FUNCTIONS:={"linxi_center":{"School":"linxi_scholar_house","FarmerHome":"linxi_farmer_cottage","HerbHome":"linxi_herbal_home"},"linxi_south":{"VillagerHome":"linxi_south_villager_home","SouthSchool":"linxi_south_scholar_house","Apothecary":"linxi_south_apothecary_home"}}
const HERBAL_BODY := "Town/HerbHome/Body"
const OLD_HERBAL_BASE := [[-253.4784,-120],[253.4784,-120],[253.4784,0],[-253.4784,0]]
static func _data(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func _poly(data: Dictionary,row: Dictionary) -> PackedVector2Array:
	var origin:=Vector2.ZERO
	var path: String=String(row.path)
	if path.begins_with("Town/") and path.ends_with("/Body"):
		var owner: String=path.split("/")[1]
		for object: Dictionary in data.objects:
			if String(object.name)==owner:origin=Vector2(object.foot[0],object.foot[1]);break
	var polygon:=PackedVector2Array()
	for p: Array in row.polygon:polygon.append(origin+Vector2(p[0],p[1]))
	return polygon
static func _overlap(foot: Vector2,polygon: PackedVector2Array) -> bool:
	var body:=PackedVector2Array([foot+Vector2(-17,-12),foot+Vector2(17,-12),foot+Vector2(17,12),foot+Vector2(-17,12)])
	return not Geometry2D.intersect_polygons(body,polygon).is_empty()
static func safe(data: Dictionary,foot: Vector2,old_herbal_base := false) -> bool:
	var size:=Vector2(data.size[0],data.size[1])
	if not Rect2(Vector2(110,110),size-Vector2(220,220)).encloses(Rect2(foot-Vector2(17,12),Vector2(34,24))):return false
	for row: Dictionary in data.blockers:
		var polygon := _poly(data,row)
		if old_herbal_base and row.path==HERBAL_BODY:
			polygon = _poly(data,{"path": HERBAL_BODY, "polygon": OLD_HERBAL_BASE})
		if _overlap(foot,polygon):return false
	return true
static func restore(id: StringName,uv: Vector2,source_version: int) -> Variant:
	if not IDS.has(String(id)) or not uv.is_finite() or uv.x<0 or uv.x>1 or uv.y<0 or uv.y>1:return null
	var key: String=IDS[String(id)]
	var current: Dictionary=_data(BASE+key+".json")
	var size:=Vector2(current.size[0],current.size[1]);var foot: Vector2=uv*size
	var arrival:=Vector2(current.spawn[0],current.spawn[1])
	if source_version==VERSION:
		if safe(current,foot):return uv
		# The drying porch extends only on the east side. Restore an old
		# walkable foot covered by that extension to the same home's entrance.
		if key=="linxi_center" and safe(current,foot,true):
			var door: Array=current.business.portal_targets.linxi_herbal_home
			var step := Vector2(door[0],door[1])
			if safe(current,step):return step/size
		return null
	if source_version not in [-1,0,1,3001]:return null
	if source_version!=3001:return arrival/size if safe(current,arrival) else null
	var previous: Dictionary=_data(BASE+"before/game/art/modules/four_settlements_20261030e/"+key+".json")
	# Old actual house/tree interiors remain illegal. Only a genuinely old legal
	# foot newly covered by the enlarged native body receives an explicit anchor.
	if not safe(previous,foot):return null
	if safe(current,foot):return uv
	var target:=arrival
	for row: Dictionary in current.blockers:
		if not _overlap(foot,_poly(current,row)):continue
		var path: String=String(row.path)
		if path.begins_with("Town/") and path.ends_with("/Body"):
			var owner: String=path.split("/")[1]
			if FUNCTIONS[key].has(owner):
				var p: Array=current.business.portal_targets[FUNCTIONS[key][owner]]
				target=Vector2(p[0],p[1])
		break
	return target/size if safe(current,target) else null
