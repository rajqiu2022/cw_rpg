extends RefCounted
## Geometry and exact original road business projection. No new plot or tuning.
const ID: StringName=&"ch1_s1_road"
const VERSION:=3003
const SIZE:=Vector2(4608,3456)
const LINXI_ARRIVAL:=Vector2(420,3150)
const ZHUWEI_ARRIVAL:=Vector2(4080,470)
const CAVE_ENTRY:=Vector2(2420,1530)
const CAVE_RETURN:=Vector2(2400,1610)
const ORIGINAL:="res://data/scenes/ch1_s1_road.tres"
const DATA:="res://build/linxi_mountain_road_20261030g_system01/road_layout.json"
const SOIL:="res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
const CAVE_TEXTURE:="res://art/modules/linxi_mountain_road_20261030g/cave_mouth.png"

static func data() -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return raw if raw is Dictionary else {}
static func ready() -> bool:return data().cave_module.get("status","")=="ROOT_NATIVE_READY" and ResourceLoader.exists(CAVE_TEXTURE)
static func point(raw: Variant) -> Vector2:return raw if raw is Vector2 else Vector2(float(raw[0]),float(raw[1]))
static func polygon(raw: Array) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for p: Variant in raw:out.append(point(p))
	return out
static func rect_polygon(r: Rect2) -> PackedVector2Array:return PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
static func _truthy(value: Variant) -> bool:
	if value==null:return false
	if typeof(value)==TYPE_BOOL:return value
	if typeof(value)==TYPE_INT:return value!=0
	if typeof(value)==TYPE_STRING:return value!=""
	return true
static func presence(row: Dictionary,flags: Dictionary,active_quest: bool=true,completed_quest: bool=true) -> bool:
	var required: String=String(row.get("require_flag",""));var hidden: String=String(row.get("hide_flag",""))
	if required!="" and not _truthy(flags.get(required,null)):return false
	if hidden!="" and _truthy(flags.get(hidden,null)):return false
	if String(row.get("require_quest_active",""))!="" and not active_quest:return false
	if String(row.get("require_quest_completed",""))!="" and not completed_quest:return false
	return true
static func row_present(row: Dictionary) -> bool:
	var active: StringName=StringName(String(row.get("require_quest_active","")))
	var completed: StringName=StringName(String(row.get("require_quest_completed","")))
	return presence(row,GameState.flags,active==&"" or QuestManager.is_active(active),completed==&"" or QuestManager.is_completed(completed))

static func specs() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for raw: Dictionary in data().specs:
		var row: Dictionary=raw.duplicate(true);row.foot=point(raw.foot)
		var box: Array=raw.body;row.body=Rect2(box[0],box[1],box[2],box[3]);out.append(row)
	# Root supplies one complete native cave module. Pending contract is not
	# silently replaced with an old background crop or a rectangular painted hole.
	var cave: Dictionary=data().cave_module
	if cave.get("status","")=="ROOT_NATIVE_READY":
		var c: Dictionary=cave.spec.duplicate(true);c.foot=point(c.foot)
		if c.has("body"):
			var b: Array=c.body;c.body=Rect2(b[0],b[1],b[2],b[3])
		out.append(c)
	return out
static func roads() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for raw: Dictionary in data().roads:
		var row: Dictionary=raw.duplicate(true);row.points=polygon(raw.points);out.append(row)
	return out
static func ground_rows() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for raw: Dictionary in data().ground:
		var row: Dictionary=raw.duplicate(true);row.polygon=polygon(raw.polygon);row.period=point(raw.period);out.append(row)
	return out
static func solid_polygons() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array]=[]
	for raw: Array in data().get("solids",[]):out.append(polygon(raw))
	return out

static func npc_rows() -> Array[Dictionary]:
	var original: SceneScript=load(ORIGINAL) as SceneScript
	var out: Array[Dictionary]=original.npcs.duplicate(true)
	for row: Dictionary in out:
		if String(row.npc_id)=="ch1_caravan_master_fan":row.pos=point(data().business.caravan_foot)/SIZE
	return out

static func scene() -> SceneScript:
	var original: SceneScript=load(ORIGINAL) as SceneScript
	var out: SceneScript=original.duplicate(true)
	out.background_path="";out.actor_positions_are_feet=true;out.camera_zoom=1.0
	out.player_spawn=LINXI_ARRIVAL/SIZE;out.npcs=npc_rows();out.map_layout=layout()
	# Intro/once flag, legacy rows, encounter groups620/.16/training gate and
	# is_settlement all remain original; MainField is the actual movement owner.
	return out

static func layout() -> WalkableMapLayout:
	var original: SceneScript=load(ORIGINAL) as SceneScript
	var out: WalkableMapLayout=original.map_layout.duplicate(true)
	var d: Dictionary=data();out.schema_version=VERSION;out.design_size=Vector2i(SIZE);out.display_at_native_size=true
	out.walkable_mask_path="";out.walkable_mask_tiles.clear();out.walkable_regions.clear()
	for raw: Array in d.land_regions:
		var normalized:=PackedVector2Array()
		for p: Vector2 in polygon(raw):normalized.append(p/SIZE)
		out.walkable_regions.append(normalized)
	out.blockers.clear();out.occluders.clear();out.actor_fade_zones.clear()
	for spec: Dictionary in specs():
		if spec.has("body"):
			var b: Rect2=spec.body
			out.blockers.append({"id":spec.id,"pos":b.get_center()/SIZE,"size":b.size/SIZE,"walkability_margin":0.0})
	for row: Dictionary in out.portals:
		row.pos=point(d.business.portal_positions[String(row.id)])/SIZE;row.size=Vector2(150,120)/SIZE
	for row: Dictionary in out.interactions:
		row.pos=point(d.business.interaction_positions[String(row.id)])/SIZE
		row.size=(row.get("native_trigger_size", Vector2(160,120)) as Vector2)/SIZE
	for row: Dictionary in out.visual_objects:
		var id: String=String(row.id);var foot: Vector2=point(d.business.visual_feet[id])
		# Keep all original flags/quest/action/render values; only map geometry moves.
		var pivot:=Vector2.ZERO;var native_size:=Vector2.ONE;var scale:=Vector2.ONE
		match id:
			"road_stone_tablet_visual":pivot=Vector2(165,354);native_size=Vector2(329,369);scale=Vector2(.34,.34)
			"road_corpse_visual":pivot=Vector2(637,479);native_size=Vector2(1274,504);scale=Vector2(145.0/1274,56.0/504)
			"road_supply_box_closed":pivot=Vector2(218.5,408);native_size=Vector2(437,426);scale=Vector2(.24,.24)
			"road_cliff_herb_visual":
				pivot=Vector2(510,570)
				native_size=Vector2(2172,724)
				scale=Vector2.ONE*0.044
				row.texture="res://art/modules/user_fixes_20261109/cliff_creeping_vine.png"
				row.render_size_px=native_size*scale
				row.sort_by_feet=true
				row.depth_sort_foot_y=foot.y/SIZE.y
		var visual_center: Vector2=foot+(native_size*.5-pivot)*scale
		row.pos=visual_center/SIZE
		# Retain authored original pixel dimensions while changing map dimensions.
		for field: String in ["interaction_size","interaction_offset","prompt_offset"]:
			if row.has(field):row[field]=(row[field] as Vector2)*Vector2(1536,1024)/SIZE
		if row.has("collision_size"):
			var body_size:=Vector2(72,44) if id=="road_stone_tablet_visual" else Vector2(78,38)
			row.collision_size=body_size/SIZE;row.collision_offset=(foot-Vector2(0,body_size.y*.5)-visual_center)/SIZE
	out.walkable_probes=[{"id":"arrival","pos":LINXI_ARRIVAL/SIZE},{"id":"stone","pos":Vector2(1120,2670)/SIZE},{"id":"corpse","pos":Vector2(2230,2380)/SIZE},{"id":"cave","pos":CAVE_RETURN/SIZE},{"id":"zhuwei","pos":ZHUWEI_ARRIVAL/SIZE}]
	out.blocked_probes=[{"id":"real_granite_mass","pos":Vector2(1290,1700)/SIZE}]
	return out

static func safe_foot(uv: Vector2, include_npcs: bool=true) -> bool:
	if not uv.is_finite():return false
	var foot: Vector2=uv*SIZE;var body:=Rect2(foot-Vector2(17,12),Vector2(34,24));var corners:=rect_polygon(body)
	var d: Dictionary=data()
	for p: Vector2 in corners:
		var yes:=false
		for raw: Array in d.land_regions:
			if Geometry2D.is_point_in_polygon(p,polygon(raw)):yes=true;break
		if not yes:return false
	for row: Dictionary in specs():
		if row.has("body") and body.intersects(row.body,true):return false
	for solid: PackedVector2Array in solid_polygons():
		if not Geometry2D.intersect_polygons(corners,solid).is_empty():return false
	var original: SceneScript=load(ORIGINAL) as SceneScript
	for row: Dictionary in original.map_layout.visual_objects:
		if not row.has("collision_size"):continue
		if not row_present(row):continue
		var p: Vector2=point(d.business.visual_feet[String(row.id)])
		var size:=Vector2(72,44) if String(row.id)=="road_stone_tablet_visual" else Vector2(78,38)
		if body.intersects(Rect2(p-Vector2(size.x*.5,size.y),size),true):return false
	if include_npcs:
		for row: Dictionary in npc_rows():
			if not row_present(row):continue
			var p: Vector2=row.pos*SIZE
			if body.intersects(Rect2(p-Vector2(10.304,13.248),Vector2(20.608,26.496)),true):return false
	return true

static func migration(uv: Vector2, version: int) -> Variant:
	if not uv.is_finite() or uv.x<0 or uv.x>1 or uv.y<0 or uv.y>1:return null
	if version==VERSION:return uv if safe_foot(uv) else null
	if version not in [-1,0,1,2,5]:return null
	var original: SceneScript=load(ORIGINAL) as SceneScript
	var old_body:=Rect2(uv-Vector2(17,12)/Vector2(1536,1024),Vector2(34,24)/Vector2(1536,1024))
	for row: Dictionary in original.map_layout.blockers:
		var old_size: Vector2=row.size;var old_center: Vector2=row.pos
		if old_body.intersects(Rect2(old_center-old_size*.5,old_size),true):return null
	for row: Dictionary in original.map_layout.visual_objects:
		if not row.has("collision_size"):continue
		if not row_present(row):continue
		var old_size: Vector2=row.collision_size;var old_center: Vector2=row.pos+row.get("collision_offset",Vector2.ZERO)
		if old_body.intersects(Rect2(old_center-old_size*.5,old_size),true):return null
	for offset: Vector2 in [Vector2.ZERO,Vector2(-17,-12),Vector2(17,-12),Vector2(17,12),Vector2(-17,12)]:
		var admitted:=false
		for region: PackedVector2Array in original.map_layout.walkable_regions:
			if Geometry2D.is_point_in_polygon(uv+offset/Vector2(1536,1024),region):admitted=true;break
		if not admitted:return null
	var p:=LINXI_ARRIVAL
	if uv.distance_to(Vector2(.700,.560))<.00001 or uv.distance_to(Vector2(.705,.585))<.00001:p=CAVE_RETURN
	elif uv.y<.30 and uv.x>.68:p=ZHUWEI_ARRIVAL
	elif uv.x>.75 and uv.y<.65:p=Vector2(3780,1650)
	elif uv.x>.40:p=Vector2(2230,2450)
	return p/SIZE if safe_foot(p/SIZE) else null
