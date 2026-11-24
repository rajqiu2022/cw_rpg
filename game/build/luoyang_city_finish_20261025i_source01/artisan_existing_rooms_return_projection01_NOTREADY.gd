extends RefCounted
# Terminal scalar projection only, after the original G native/storage gates.
# No room Scene/Layout/author/storage mutation and no new interior geometry.
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/artisan_existing_rooms_return_projection01_NOTREADY.gd"
const AUTHOR: String="res://build/luoyang_city_finish_20261025i_source01/author_artisan_residential_block06_threshold_short_cross_NOTREADY.json"
const AUTHOR_SHA: String="80a93c9fc6a8938eb3484cc11f2326d70bac8722d4aed67b0dc72124eec5c256"
const CITY: StringName=&"luoyang_artisan_residential_20261022ap"
const SIZE: Vector2=Vector2(3072,2048)
const ROOMS: Dictionary={
 "luoyang_market_market_west_ward_frontage_interior_20261015":{"building":"ap_courtyard_home_west","old_threshold":Vector2(650,674),"old_return":Vector2(650,674),"new_threshold":Vector2(590,504),"new_return":Vector2(590,504)},
 "luoyang_market_market_northwest_rear_frontage_interior_20261015":{"building":"ap_courtyard_home_east","old_threshold":Vector2(2290,674),"old_return":Vector2(2290,674),"new_threshold":Vector2(2460,504),"new_return":Vector2(2460,504)},
 "luoyang_market_southeast_market_front_interior_20261015":{"building":"ap_carpentry_general_shop_south","old_threshold":Vector2(1536,1900),"old_return":Vector2(1536,1924),"new_threshold":Vector2(1536,924),"new_return":Vector2(1536,924)}
}
static var _author: Dictionary={}
static func v(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)
static func owns(id: StringName) -> bool: return ROOMS.has(String(id))
static func source_paths() -> Dictionary: return {SELF:true,AUTHOR:true}
static func source_bound() -> bool:
	if not _author.is_empty(): return true
	if FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA: return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not value is Dictionary or value.get("scene_id")!=String(CITY) or not value.get("same_room_migrations") is Array or value.same_room_migrations.size()!=3: return false
	var seen: Dictionary={}
	for row: Dictionary in value.same_room_migrations:
		var id: String=String(row.get("room_id",""))
		if not ROOMS.has(id) or seen.has(id): return false
		var fixed: Dictionary=ROOMS[id]
		if row.get("exterior_object_id")!=fixed.building or row.get("room_native_or_geometry_change")!=false or v(row.get("old_portal_foot_px"))!=fixed.old_threshold or v(row.get("new_portal_foot_px"))!=fixed.new_threshold or v(row.get("new_return_fallback_foot_px"))!=fixed.new_return: return false
		seen[id]=true
	_author=value;return true
static func room_binding(id: StringName,before: Dictionary) -> Dictionary:
	if not owns(id): return before
	if not source_bound(): return {}
	var fixed: Dictionary=ROOMS[String(id)]
	if before.get("city_id")!=String(CITY) or before.get("building_id")!=fixed.building or v(before.get("return_foot_px"))!=fixed.old_return: return {}
	var out: Dictionary=before.duplicate(true)
	out.return_foot_px=[float(fixed.new_return.x),float(fixed.new_return.y)]
	return out
static func _door(foot: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])
static func portals(scene: SceneScript,before: Array) -> Dictionary:
	if scene==null: return {"ok":false,"error":"ARTISAN25I_NULL_SCENE","portals":[]}
	if scene.scene_id!=CITY and not owns(scene.scene_id): return {"ok":true,"portals":before}
	if not source_bound(): return {"ok":false,"error":"ARTISAN25I_SOURCE_BINDING","portals":[]}
	var out: Array=before.duplicate(true)
	if scene.scene_id==CITY:
		var family: Variant=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
		if not family.matches(scene): return {"ok":false,"error":"ARTISAN25I_ORIGINAL_FAMILY_OWNER","portals":[]}
		for id: String in ROOMS:
			var fixed: Dictionary=ROOMS[id];var found: int=0
			for row: Dictionary in out:
				if String(row.get("target_scene",""))!=id: continue
				found+=1
				if row.get("pos")!=fixed.old_threshold/SIZE or row.get("size")!=Vector2(40,32)/SIZE or row.get("auto_trigger")!=false or not row.get("target_pos") is Vector2: return {"ok":false,"error":"ARTISAN25I_EXACT_OLD_THRESHOLD:"+id,"portals":[]}
				if not family.safe_body(CITY,fixed.new_threshold) or not family.safe_body(CITY,fixed.new_return): return {"ok":false,"error":"ARTISAN25I_NEW_EFFECTIVE_THRESHOLD_BODY:"+id,"portals":[]}
				row.pos=fixed.new_threshold/SIZE;row.interaction_polygon_px=_door(fixed.new_threshold)
			if found!=1: return {"ok":false,"error":"ARTISAN25I_UNIQUE_TARGET_ROOM:"+id,"portals":[]}
	else:
		var fixed: Dictionary=ROOMS[String(scene.scene_id)];var found: int=0
		for row: Dictionary in out:
			if String(row.get("target_scene",""))!=String(CITY): continue
			found+=1
			if row.get("target_pos")!=fixed.old_return/SIZE: return {"ok":false,"error":"ARTISAN25I_EXACT_NATIVE_ROOM_EXIT","portals":[]}
			row.target_pos=fixed.new_return/SIZE
		if found!=1: return {"ok":false,"error":"ARTISAN25I_UNIQUE_NATIVE_ROOM_EXIT","portals":[]}
	return {"ok":true,"portals":out,"original_12_native_storage_unchanged":true,"only_three_room_threshold_return_scalars":true}
