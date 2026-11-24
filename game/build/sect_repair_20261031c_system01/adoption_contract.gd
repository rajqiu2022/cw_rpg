extends RefCounted
const BASE=preload("res://build/sect_adoption_20261030n_system01/adoption_contract.gd")
const ROOT := "res://build/sect_repair_20261031c_system01/"
const FIELD := ROOT+"sect_field.tscn"
const DATA := ROOT+"adoption_data.json"
const VERSION := 3006
const IDS := [&"openworld_wudang_gate",&"openworld_huashan_forecourt",&"openworld_wudang_taiji_court"]
const WORLD_SIZE := Vector2(12288,8192)
const WUDANG := &"openworld_wudang_gate"
const TAIJI := &"openworld_wudang_taiji_court"
const PURPLE := &"openworld_wudang_purple_cloud_court"
const ASSEMBLY := &"ch3_s1_wulin_assembly"
const ASSEMBLY_GATE_FOOT := Vector2(1700,3875)
static var _data: Dictionary={}

static func raw(id: StringName) -> Dictionary:
	if _data.is_empty():
		var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if value is Dictionary and int(value.get("schema_version",0))==1:_data=value
	return _data.get("towns",{}).get(String(id),{})

static func vec(value: Variant) -> Vector2:return BASE.vec(value)
static func polygon(value: Variant) -> PackedVector2Array:return BASE.polygon(value)

static func town(id: StringName) -> Dictionary:
	var row:=raw(id)
	if not IDS.has(id) or row.is_empty():return {}
	return {"id":id,"label":row.label,"scene":row.scene,"size":vec(row.size),"arrival":vec(row.arrival),"inner_arrival":vec(row.inner_return),"inner_source":StringName(row.inner_source),"world_foot":vec(row.world_uv)*WORLD_SIZE,"adoption30n":true,"repair31c":true}

static func level_at(id: StringName,foot: Vector2) -> int:
	return BASE.level_at(WUDANG if id==TAIJI else id,foot)

static func ramp_at(id: StringName,foot: Vector2) -> int:
	return BASE.ramp_at(WUDANG if id==TAIJI else id,foot)

static func safe_native(id: StringName,foot: Vector2) -> bool:
	var row:=raw(id)
	if row.is_empty() or not foot.is_finite():return false
	var size:=vec(row.size);var box:=Rect2(foot-Vector2(17.5,12.5),Vector2(35,25))
	if box.position.x<0 or box.position.y<0 or box.end.x>size.x or box.end.y>size.y:return false
	var body:=PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
	if not Geometry2D.clip_polygons(body,polygon(row.base_outline)).is_empty():return false
	var mask: int=8|(16<<level_at(id,foot));var ramp:=ramp_at(id,foot)
	if ramp>=0:
		var r: Dictionary=row.terrain.ramps[ramp];mask=8|(16<<int(r.low))|(16<<int(r.high))
	for solid: Dictionary in row.solids:
		if (int(solid.layer)&mask)!=0 and not Geometry2D.intersect_polygons(body,polygon(solid.polygon)).is_empty():return false
	for point: Variant in row.npc_feet.values():
		var npc:=vec(point)
		if (mask&(16<<level_at(id,npc)))!=0 and box.intersects(Rect2(npc-Vector2(10.4,13.3),Vector2(20.8,26.6))):return false
	return true

static func safe_legacy(id: StringName,uv: Vector2) -> bool:
	if id!=TAIJI:return BASE.safe_legacy(id,uv)
	if not uv.is_finite() or uv.x<0 or uv.y<0 or uv.x>1 or uv.y>1:return false
	var source:=load("res://data/scenes/openworld_wudang_taiji_court.tres") as SceneScript
	if source==null or source.map_layout==null:return false
	var map: WalkableMapLayout=source.map_layout;var size:=Vector2(map.design_size)
	var body:=PackedVector2Array([uv+Vector2(-17.5,-12.5)/size,uv+Vector2(17.5,-12.5)/size,uv+Vector2(17.5,12.5)/size,uv+Vector2(-17.5,12.5)/size])
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

static func _new_wall_covers(id: StringName,foot: Vector2) -> bool:
	if id!=WUDANG or level_at(id,foot)!=0 or ramp_at(id,foot)>=0:return false
	var box:=Rect2(foot-Vector2(17.5,12.5),Vector2(35,25))
	var body:=PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
	for wall: Dictionary in raw(id).get("new_gate_walls",[]):
		if not Geometry2D.intersect_polygons(body,polygon(wall.polygon)).is_empty():return true
	return false

static func resolve_spawn(id: StringName,requested: Variant,source: StringName,version: int,known_version: int,same: bool,last: Variant) -> Dictionary:
	var row:=town(id);var authored:=raw(id)
	if row.is_empty() or not [-1,0,1,3005,VERSION].has(version):return {}
	var foot: Vector2=row.arrival;var reason: String="AUTHORED_ARRIVAL"
	if id==WUDANG and source==TAIJI:reason="ORIGINAL_TAIJI_RETURN_TO_GATE_IDENTITY_AND_ENTRY"
	elif id==WUDANG and source==ASSEMBLY:foot=ASSEMBLY_GATE_FOOT;reason="ASSEMBLY_RETURN_TO_AUTHORED_GATE"
	elif id==TAIJI and source==PURPLE:foot=vec(authored.purple_return);reason="ORIGINAL_PURPLE_RETURN_ON_SITE"
	elif id==&"openworld_huashan_forecourt" and source==row.inner_source:foot=vec(authored.inner_return);reason="ORIGINAL_INNER_RETURN_EXACT"
	elif source in [&"world_map_jianghu",&"world_map_jianghu_v15",&"world_map_jianghu_v16"]:
		if id==TAIJI:return {} # Not a World door. Never borrow an alias's World fallback.
		reason="ORIGINAL_WORLD_GATE_ARRIVAL"
	else:
		var candidate: Variant=requested if requested is Vector2 else (last if same and last is Vector2 else null)
		if candidate is Vector2:
			var native_version: int=version if version>=0 else known_version
			if native_version in [3005,VERSION]:
				foot=candidate*row.size;reason="CURRENT_NATIVE_EXACT_FULLFOOT"
				if not safe_native(id,foot):
					if native_version!=3005 or not BASE.safe_native(id,foot) or not _new_wall_covers(id,foot):return {}
					foot=vec(authored.gate_wall_safe_entry);reason="OLD3005_LEGAL_NEW_WALL_ONLY_DECLARED_GATE_FRONT"
			else:
				if not safe_legacy(id,candidate):return {}
				if id==TAIJI:
					foot=vec(authored.purple_return) if candidate==Vector2(.5,.15) else row.arrival
					reason="LEGACY_TAIJI_ID_ON_SITE_AUTHORED_RETURN"
				elif candidate==vec(authored.old_inner_return_uv):foot=vec(authored.inner_return);reason="LEGACY_INNER_UV_EXPLICIT_RETURN"
				else:reason="LEGACY_LEGAL_UV_EXPLICIT_SAFE_ENTRY"
	if not safe_native(id,foot):return {}
	return {"ok":true,"spawn":foot/row.size,"foot":foot,"version":VERSION,"reason":reason,"level":level_at(id,foot),"ramp":ramp_at(id,foot)}
