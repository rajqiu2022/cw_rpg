extends RefCounted
## Data-only adoption contract; source guard is the unchanged registry source_valid.
const ROOT := "res://build/sect_adoption_20261030n_system01/"
const FIELD := ROOT+"sect_adoption_field.tscn"
const DATA := ROOT+"adoption_data.json"
const VERSION := 3005
const IDS := [&"openworld_wudang_gate",&"openworld_huashan_forecourt"]
const WORLD_SIZE := Vector2(12288,8192)
static var _data: Dictionary={}

static func _load() -> Dictionary:
	if _data.is_empty():
		var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if value is Dictionary and int(value.get("schema_version",0))==1:_data=value
	return _data

static func vec(value: Variant) -> Vector2:
	return Vector2(float(value[0]),float(value[1])) if value is Array and value.size()==2 else Vector2(INF,INF)

static func polygon(value: Variant) -> PackedVector2Array:
	var result:=PackedVector2Array()
	if not value is Array:return result
	for point: Variant in value:result.append(vec(point))
	return result

static func town(id: StringName) -> Dictionary:
	var data:=_load()
	if not IDS.has(id) or not data.get("towns",{}).has(String(id)):return {}
	var raw: Dictionary=data.towns[String(id)]
	return {"id":id,"label":raw.label,"scene":raw.scene,"size":vec(raw.size),"arrival":vec(raw.arrival),"inner_arrival":vec(raw.inner_return),"inner_source":StringName(raw.inner_source),"world_foot":vec(raw.world_uv)*WORLD_SIZE,"adoption30n":true}

static func raw(id: StringName) -> Dictionary:
	return _load().get("towns",{}).get(String(id),{})

static func level_at(id: StringName,foot: Vector2) -> int:
	var result:=0
	for platform: Dictionary in raw(id).get("terrain",{}).get("platforms",[]):
		if Geometry2D.is_point_in_polygon(foot,polygon(platform.polygon)):result=maxi(result,int(platform.level))
	return result

static func ramp_at(id: StringName,foot: Vector2) -> int:
	var terrain: Dictionary=raw(id).get("terrain",{})
	var ramps: Array=terrain.get("ramps",[])
	for i: int in range(ramps.size()):
		var ramp: Dictionary=ramps[i];var top:=vec(ramp.top);var bottom:=vec(ramp.bottom)
		if absf(foot.x-top.x)<=float(terrain.portal_half_width)-20.0 and foot.y>=top.y and foot.y<=bottom.y:return i
	return -1

static func safe_native(id: StringName,foot: Vector2) -> bool:
	var row:=raw(id)
	if row.is_empty() or not foot.is_finite():return false
	var size:=vec(row.size)
	var box:=Rect2(foot-Vector2(17.5,12.5),Vector2(35,25))
	if box.position.x<0 or box.position.y<0 or box.end.x>size.x or box.end.y>size.y:return false
	var body:=PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
	if not Geometry2D.clip_polygons(body,polygon(row.base_outline)).is_empty():return false
	var mask: int=8|(16<<level_at(id,foot));var ramp:=ramp_at(id,foot)
	if ramp>=0:
		var r: Dictionary=row.terrain.ramps[ramp]
		mask=8|(16<<int(r.low))|(16<<int(r.high))
	for solid: Dictionary in row.solids:
		if (int(solid.layer)&mask)!=0 and not Geometry2D.intersect_polygons(body,polygon(solid.polygon)).is_empty():return false
	# Preserve the sole original static disciple. No invented residents/services.
	for point: Variant in row.npc_feet.values():
		var npc:=vec(point)
		if (mask&(16<<level_at(id,npc)))!=0 and box.intersects(Rect2(npc-Vector2(10.4,13.3),Vector2(20.8,26.6))):return false
	return true

static func safe_legacy(id: StringName,uv: Vector2) -> bool:
	if not IDS.has(id) or not uv.is_finite() or uv.x<0 or uv.y<0 or uv.x>1 or uv.y>1:return false
	var scene:=load("res://data/scenes/"+String(id)+".tres") as SceneScript
	if scene==null or scene.map_layout==null:return false
	var map: WalkableMapLayout=scene.map_layout;var size:=Vector2(map.design_size)
	var body:=PackedVector2Array([uv+Vector2(-17.5,-12.5)/size,uv+Vector2(17.5,-12.5)/size,uv+Vector2(17.5,12.5)/size,uv+Vector2(-17.5,12.5)/size])
	# Subtract the union of the old authored walkable polygons from the full
	# foot. Testing only center/corners could admit a narrow gap between them.
	var remaining: Array[PackedVector2Array]=[];remaining.append(body)
	for region: PackedVector2Array in map.walkable_regions:
		var outside: Array[PackedVector2Array]=[]
		for piece: PackedVector2Array in remaining:
			for part: PackedVector2Array in Geometry2D.clip_polygons(piece,region):outside.append(part)
		remaining=outside
		if remaining.is_empty():break
	if not remaining.is_empty():return false
	for blocker: Dictionary in map.blockers:
		var bounds:=Rect2(blocker.pos-blocker.size*.5,blocker.size).grow(maxf(0,float(blocker.get("walkability_margin",.014))))
		var poly:=PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
		if not Geometry2D.intersect_polygons(body,poly).is_empty():return false
	return true

static func resolve_spawn(id: StringName,requested: Variant,source: StringName,version: int,known_version: int,same: bool,last: Variant) -> Dictionary:
	var row:=town(id);var authored:=raw(id)
	if row.is_empty() or version>VERSION or (version>1 and version!=VERSION):return {}
	var foot: Vector2=row.arrival;var reason: String="AUTHORED_ARRIVAL"
	if source==row.inner_source:foot=vec(authored.inner_return);reason="ORIGINAL_INNER_RETURN_EXACT"
	elif source in [&"world_map_jianghu",&"world_map_jianghu_v15"]:reason="ORIGINAL_WORLD_GATE_ARRIVAL"
	else:
		var candidate: Variant=requested if requested is Vector2 else (last if same and last is Vector2 else null)
		if candidate is Vector2:
			if version==VERSION or (version<0 and known_version==VERSION):
				foot=candidate*row.size;reason="CURRENT3005_EXACT_FULLFOOT"
			else:
				if not safe_legacy(id,candidate):return {}
				if candidate==vec(authored.old_inner_return_uv):foot=vec(authored.inner_return);reason="LEGACY_INNER_UV_EXPLICIT_RETURN"
				else:reason="LEGACY_LEGAL_UV_EXPLICIT_SAFE_ENTRY"
	if not safe_native(id,foot):return {}
	return {"ok":true,"spawn":foot/row.size,"foot":foot,"version":VERSION,"reason":reason,"level":level_at(id,foot),"ramp":ramp_at(id,foot)}
