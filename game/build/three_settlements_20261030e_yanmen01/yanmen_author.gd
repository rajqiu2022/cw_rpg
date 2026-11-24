extends RefCounted
## Yanmen author-only geometry. Original encounters, parcel and cave remain canonical.
const Common = preload("res://build/three_settlements_20261030e_system01/common_author.gd")
const ID: StringName = &"openworld_yanmen_pass"
const SIZE := Vector2(4608,4096)
const VERSION := 30
const SOUTH_ARRIVAL := Vector2(2304,3880)
const SOUTH_EXIT := Vector2(2304,3990)
const CAVE_FOOT := Vector2(3640.32,1064.96)
const CAVE_RETURN := Vector2(3640.32,1269.76)
const MEDICINE_FOOT := Vector2(3910,3340)
const HUA := "res://art/modules/huashan_map_20261029m/"
const GATE := "res://art/maps/bianzhou_southgate_20261028/main_gatehouse_v1_padded.png"
const WALL := "res://art/maps/bianzhou_enclosure_20261028d/horizontal_wall_v1_padded.png"
const WALL_W := "res://art/maps/bianzhou_enclosure_20261028d/west_longitudinal_wall_v2_edit_padded.png"
const WALL_E := "res://art/maps/bianzhou_enclosure_20261028d/east_longitudinal_wall_v2_edit_padded.png"
const GRASS := HUA+"granite_ground.png" # Deliberately rock, not green turf.
const SNOW := "res://art/modules/yanmen_rebuild_20261030e/snow_gravel.png" # Actual native1254 square, never resized to requested1024.
const SOIL := "res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
const STONE := "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const PAVING := "res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
const LORE := "res://build/bianzhou_city_20261028_lore01/ambient_dialogues.json"
const ORIGINAL := "res://data/scenes/openworld_yanmen_pass.tres"

static func district_rows() -> Array[Dictionary]:
	return [
		{"id":"south_post_road","name":"南驿道","rect":Rect2(1300,3370,2000,650)},
		{"id":"outer_checkpoint","name":"外关候检","rect":Rect2(1200,2820,2200,570)},
		{"id":"main_barbican","name":"瓮城主门","rect":Rect2(900,2380,2820,460)},
		{"id":"barrack_stores","name":"关内军营仓院","rect":Rect2(900,1260,2820,1120)},
		{"id":"side_mountain_paths","name":"两侧山路","rect":Rect2(480,1260,3650,2450)},
		{"id":"north_snow_fork","name":"北雪径与隐洞岔路","rect":Rect2(2740,790,1450,610)}
	]

static func roads() -> Array[Dictionary]:
	return [
		{"id":"winding_post_road","points":PackedVector2Array([SOUTH_EXIT,Vector2(2304,3810),Vector2(2600,3580),Vector2(2304,3290),Vector2(2304,2860),Vector2(2304,2380),Vector2(2304,1840)]),"width":220.0,"texture":SOIL},
		{"id":"inner_camp_cross","points":PackedVector2Array([Vector2(1030,2230),Vector2(3500,2230)]),"width":170.0,"texture":PAVING},
		{"id":"north_court","points":PackedVector2Array([Vector2(1060,1660),Vector2(3300,1660),CAVE_RETURN,CAVE_FOOT]),"width":170.0,"texture":SOIL},
		{"id":"west_mountain_loop","points":PackedVector2Array([Vector2(2304,3290),Vector2(1270,3290),Vector2(720,2860),Vector2(720,1800),Vector2(1060,1660),Vector2(1060,2230),Vector2(2304,2230)]),"width":132.0,"texture":SOIL},
		{"id":"east_supply_loop","points":PackedVector2Array([Vector2(2304,3580),Vector2(3360,3580),Vector2(4160,3450),Vector2(4160,1810),Vector2(3500,1660),Vector2(3500,2230),Vector2(2304,2230)]),"width":132.0,"texture":SOIL},
		{"id":"parcel_rock_approach","points":PackedVector2Array([Vector2(3360,3580),Vector2(3700,3340),MEDICINE_FOOT]),"width":120.0,"texture":SOIL},
		{"id":"north_patrol_return","points":PackedVector2Array([Vector2(1060,1660),Vector2(1060,1280),Vector2(2800,1280),Vector2(3300,1660)]),"width":128.0,"texture":SOIL}
	]

static func ground_rows() -> Array[Dictionary]:
	return [
		{"id":"grey_granite_base","polygon":Common.rect_polygon(Rect2(Vector2.ZERO,SIZE)),"texture":GRASS,"period":Vector2(512,512),"z":-1200},
		{"id":"north_thin_snow_gravel","polygon":PackedVector2Array([Vector2(-200,-200),Vector2(4808,-200),Vector2(4808,2160),Vector2(4060,2040),Vector2(3620,1650),Vector2(2900,1530),Vector2(2360,1700),Vector2(1900,1400),Vector2(1380,1750),Vector2(800,1690),Vector2(-200,2180)]),"texture":SNOW,"period":Vector2(640,640),"z":-1195,"feather_px":160.0},
		{"id":"camp_compacted_soil","polygon":PackedVector2Array([Vector2(900,1200),Vector2(3390,1200),Vector2(3690,1760),Vector2(3680,2350),Vector2(930,2350)]),"texture":SOIL,"period":Vector2(512,512),"z":-1190,"feather_px":76.0},
		{"id":"gate_stone_apron","polygon":Common.rect_polygon(Rect2(1810,2380,990,450)),"texture":STONE,"period":Vector2(384,384),"z":-1185,"feather_px":48.0},
		{"id":"outer_inspection_soil","polygon":PackedVector2Array([Vector2(1120,2820),Vector2(3460,2820),Vector2(3500,3210),Vector2(3000,3430),Vector2(1330,3380)]),"texture":SOIL,"period":Vector2(512,512),"z":-1190,"feather_px":80.0}
	]

static func _house(id: String, key: String, foot: Vector2, scale_factor: float, width: float, depth: float, usage: String) -> Dictionary:
	var anchors := {"dormitory":Vector2(958.5,945),"kitchen":Vector2(939.5,891),"tall_house":Vector2(663,1414),"main_hall":Vector2(977.5,961)}
	var row: Dictionary=Common.good(id,HUA+key+".png",foot,scale_factor,anchors[key],Rect2(),usage)
	# Building body includes the real house ground volume, not just a narrow doorstep.
	row.body=Rect2(foot-Vector2(width*.43,depth),Vector2(width*.86,depth))
	return row

static func _gate(id: String, foot: Vector2, scale_factor: float) -> Dictionary:
	var row: Dictionary=Common.good(id,GATE,foot,scale_factor,Vector2(1044.5,1047),Rect2(347,855,475,192),"整座石木关楼；中央为有厚度的通道")
	return row

static func _wall(id: String, foot: Vector2, scale_factor: float) -> Dictionary:
	var row: Dictionary=Common.good(id,WALL,foot,scale_factor,Vector2(723,375),Rect2(0,285,1446,90),"连续高城墙，与关楼和侧墙搭接")
	row.source_region_px=[946,386,1446,375]
	return row

static func _side_wall(id: String, texture: String, foot: Vector2, scale_factor: float) -> Dictionary:
	var west: bool=texture==WALL_W
	var row: Dictionary=Common.good(id,texture,foot,scale_factor,Vector2(148.5,892) if west else Vector2(136.5,624),Rect2(49,329,199,563) if west else Rect2(50,337,173,287),"高城墙侧向收口，非悬浮小墙")
	row.source_region_px=[638,493,297,892] if west else [655,478,274,624]
	return row

static func building_specs() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[
		_gate("main_pass_gate",Vector2(2304,2670),.70),
		_gate("outer_barbican_gate",Vector2(2304,3090),.48),
		_house("west_long_barrack","dormitory",Vector2(1480,2110),.75,869,230,"西军舍完整石木长屋"),
		_house("east_long_barrack","dormitory",Vector2(3075,2110),.75,869,230,"东军舍完整石木长屋"),
		_house("west_north_barrack","dormitory",Vector2(1480,1540),.75,869,230,"北西军舍"),
		_house("east_north_barrack","dormitory",Vector2(2980,1160),.75,869,230,"北东军舍"),
		_house("camp_kitchen","kitchen",Vector2(1430,2500),.60,596,210,"关内伙房柴棚"),
		_house("camp_store","kitchen",Vector2(3150,2500),.60,596,210,"关内军需储屋"),
		_house("command_house","main_hall",Vector2(2100,1130),.60,839,240,"关内公用正屋，无新增服务或专名"),
		_house("west_watch_loft","tall_house",Vector2(1120,1180),.60,464,190,"西侧两层瞭望屋"),
		_house("east_watch_loft","tall_house",Vector2(3500,1000),.60,464,190,"东侧两层瞭望屋"),
		_house("post_road_inn","dormitory",Vector2(1550,3740),.75,869,230,"驿道客舍外观，未新增客栈业务"),
		_house("supply_lodge","kitchen",Vector2(3260,3330),.60,596,210,"外关补给房外观"),
		Common.good("west_inspection_shelter","res://art/maps/bianzhou_southgate_20261028/checkpoint_shelter_v1_padded.png",Vector2(1530,3020),.37,Vector2(1045,1065),Rect2(420,810,1150,255),"候检值守棚整屋"),
		Common.good("east_inspection_shelter","res://art/maps/bianzhou_southgate_20261028/checkpoint_shelter_v1_padded.png",Vector2(3100,3020),.37,Vector2(1045,1065),Rect2(420,810,1150,255),"候检行旅棚整屋")
	]
	# Wall courses overlap only at structural joins; no lane is closed by a tiny wall.
	for item: Array in [["main_wall_w",Vector2(1340,2670)],["main_wall_e",Vector2(3268,2670)]]:
		rows.append(_wall(item[0],item[1],.72))
	for item: Array in [["west_return_n",WALL_W,Vector2(844,2260),.72],["west_return_s",WALL_W,Vector2(844,2670),.72],["east_return_n",WALL_E,Vector2(3764,2260),.72],["east_return_s",WALL_E,Vector2(3764,2470),.72],["east_return_join",WALL_E,Vector2(3764,2670),.72]]:
		rows.append(_side_wall(item[0],item[1],item[2],item[3]))
	for item: Array in [["barbican_w_n",WALL_W,Vector2(1954,2820),.48],["barbican_w_s",WALL_W,Vector2(1954,3090),.48],["barbican_e_n",WALL_E,Vector2(2653,2676),.48],["barbican_e_m1",WALL_E,Vector2(2653,2814),.48],["barbican_e_m2",WALL_E,Vector2(2653,2952),.48],["barbican_e_s",WALL_E,Vector2(2653,3090),.48]]:
		rows.append(_side_wall(item[0],item[1],item[2],item[3]))
	return rows

static func prop_specs() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	for p: Vector2 in [Vector2(250,1750),Vector2(250,2460),Vector2(320,3200),Vector2(650,3620),Vector2(4660,1760),Vector2(4660,2470),Vector2(4660,3220),Vector2(4660,3860),Vector2(830,930),Vector2(2000,750),Vector2(4200,1030)]:
		var row: Dictionary=Common.good("granite_boundary_%02d"%rows.size(),HUA+"granite_crag.png",p,.59,Vector2(1107,976),Rect2(360,535,1460,441),"连续灰岩山口；脚底与山体共同阻挡")
		rows.append(row)
	# The road bends around this real spine rather than crossing a painted cliff.
	rows.append(Common.good("post_road_rock_spine",HUA+"granite_crag.png",Vector2(1750,3560),.39,Vector2(1107,976),Rect2(360,535,1460,441),"驿道避风岩脊"))
	rows.append(Common.good("parcel_shelter_rock",HUA+"granite_crag.png",Vector2(3750,3220),.33,Vector2(1107,976),Rect2(360,535,1460,441),"原药包背后的避风岩"))
	var pine: String="res://art/modules/sect_maps_20261029k/wudang_pine.png"
	for p: Vector2 in [Vector2(520,1520),Vector2(550,2810),Vector2(1130,3870),Vector2(3450,3830),Vector2(4250,1510),Vector2(4290,2730),Vector2(3050,860),Vector2(3920,1000)]:
		rows.append(Common.good("mountain_pine_%02d"%rows.size(),pine,p,.30,Vector2(990,1116),Rect2(920,1050,140,66),"崖畔常绿松"))
	var base: String="res://art/modules/redrock_luoyang_standard_20261028b/"
	for p: Vector2 in [Vector2(1700,2540),Vector2(2900,2540),Vector2(3500,2410),Vector2(3530,3350)]:
		rows.append(Common.good("supply_cargo_%02d"%rows.size(),base+"cargo.png",p,.14,Vector2(1005,966),Rect2(600,780,810,186),"军需低货组，不新增掉落"))
	for p: Vector2 in [Vector2(1280,2540),Vector2(3280,2540)]:
		rows.append(Common.good("camp_water_jar_%02d"%rows.size(),base+"water_jars.png",p,.14,Vector2(643.5,965),Rect2(300,780,687,185),"伙房水缸"))
	return rows

static func land_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(1050,4020),Vector2(3370,4020),Vector2(4250,3650),Vector2(4250,1360),Vector2(4010,790),Vector2(3020,790),Vector2(2780,930),Vector2(950,930),Vector2(480,1290),Vector2(480,3210),Vector2(970,3610)])

static func solid_polygons() -> Array[PackedVector2Array]:
	var rows: Array[PackedVector2Array]=[]
	# Right piers complement each gate's independently authored left body.
	for item: Array in [[Vector2(2304,2670),.70],[Vector2(2304,3090),.48]]:
		rows.append(Common.rect_polygon(Rect2(item[0]+(Vector2(1267,855)-Vector2(1044.5,1047))*item[1],Vector2(475,192)*item[1])))
	# A thick barbican has real side returns; its central south/north openings stay clear.
	rows.append(Common.rect_polygon(Rect2(1930,2670,50,420)))
	rows.append(Common.rect_polygon(Rect2(2628,2670,50,420)))
	return rows

static func npc_rows() -> Array[Dictionary]:
	# Original Yanmen has no NPCs. No new named resident or invented dialogue.
	return []

static func scene() -> SceneScript:
	var out: SceneScript=(load(ORIGINAL) as SceneScript).duplicate(true)
	out.display_name="雁门关 · 石木峡关"
	out.background_path="";out.camera_zoom=1.0
	out.player_spawn=SOUTH_ARRIVAL/SIZE;out.map_layout=layout();out.npcs=npc_rows()
	# Keep is_settlement=false, encounter groups/weights/chance/step and drift data.
	return out

static func layout() -> WalkableMapLayout:
	var original: SceneScript=load(ORIGINAL) as SceneScript
	var out: WalkableMapLayout=original.map_layout.duplicate(true)
	out.schema_version=VERSION;out.design_size=Vector2i(SIZE);out.display_at_native_size=true
	out.walkable_mask_path="";out.walkable_regions.clear()
	out.walkable_regions.append(Common.normalized_polygon(land_polygon(),SIZE))
	out.visual_objects=[];out.occluders=[];out.actor_fade_zones=[];out.blockers=[]
	for row: Dictionary in out.interactions:
		if String(row.get("id",""))=="snow_medicine_parcel":
			row.pos=MEDICINE_FOOT/SIZE;row.size=Vector2(110,100)/SIZE
	for row: Dictionary in out.portals:
		if String(row.get("id",""))=="return_world":
			row.pos=SOUTH_EXIT/SIZE;row.size=Vector2(160,100)/SIZE;row.marker_rotation_degrees=180.0
		elif String(row.get("id",""))=="snow_hidden_cave":
			row.pos=CAVE_FOOT/SIZE;row.size=Vector2(140,110)/SIZE
	out.walkable_probes=[{"id":"south_arrival","pos":SOUTH_ARRIVAL/SIZE},{"id":"gate_passage","pos":Vector2(2304,2650)/SIZE},{"id":"camp_cross","pos":Vector2(2304,2230)/SIZE},{"id":"cave_return","pos":CAVE_RETURN/SIZE},{"id":"medicine_approach","pos":MEDICINE_FOOT/SIZE}]
	out.blocked_probes=[{"id":"outside_canyon","pos":Vector2(80,1800)/SIZE},{"id":"west_barrack_body","pos":Vector2(1450,2020)/SIZE}]
	return out

static func safe_foot(uv: Vector2, include_npcs: bool = true) -> bool:
	if not uv.is_finite():return false
	var foot: Vector2=uv*SIZE
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	var polygon: PackedVector2Array=Common.rect_polygon(body)
	for corner: Vector2 in polygon:
		if not Geometry2D.is_point_in_polygon(corner,land_polygon()):return false
	var shapes: Array[Dictionary]=building_specs();shapes.append_array(prop_specs())
	for row: Dictionary in shapes:
		if row.has("body") and body.intersects(row.body,true):return false
	for solid: PackedVector2Array in solid_polygons():
		if not Geometry2D.intersect_polygons(polygon,solid).is_empty():return false
	if include_npcs and not npc_rows().is_empty():return false
	return true

static func migration(uv: Vector2, version: int) -> Variant:
	if not uv.is_finite() or uv.x<0 or uv.x>1 or uv.y<0 or uv.y>1:return null
	if version==VERSION:return uv if safe_foot(uv) else null
	if version!=1 and version!=3:return null
	# Exact old cave return and author portal anchors, never nearest-wall projection.
	if uv==Vector2(.79,.31) or uv==Vector2(.79,.26):return CAVE_RETURN/SIZE
	if uv==Vector2(.25,.78) or uv==Vector2(.25,.90) or uv==Vector2(.25,.93):return SOUTH_ARRIVAL/SIZE
	var old_scene: SceneScript=load(ORIGINAL) as SceneScript
	var old_size: Vector2=Vector2(old_scene.map_layout.design_size)
	var permitted:=true
	for offset: Vector2 in [Vector2.ZERO,Vector2(-17,-12),Vector2(17,-12),Vector2(17,12),Vector2(-17,12)]:
		var admitted:=false
		for region: PackedVector2Array in old_scene.map_layout.walkable_regions:
			if Geometry2D.is_point_in_polygon(uv+offset/old_size,region):admitted=true;break
		if not admitted:permitted=false;break
	# Explicit safeentry policy for legal pre-rebuild snow-path saves. Illegal old
	# cliffs remain rejected; no arbitrary nearest/collision-dependent fallback.
	return SOUTH_ARRIVAL/SIZE if permitted else null
