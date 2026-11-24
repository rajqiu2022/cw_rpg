extends RefCounted
## Continuous Jinling: two riverbanks, real bridges and purpose-built courts.
const ID: StringName=&"openworld_jinling_city"
const SIZE:=Vector2(5632,4096)
const VERSION:=31
const SOUTH_ARRIVAL:=Vector2(2816,3920)
const SOUTH_EXIT:=Vector2(2816,4000)
const REED_FOOT:=Vector2(440,1980)
const BASE:="res://art/maps/luoyang_modular_v3/source/"
const EAST:="res://art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png"
const WEST:="res://art/maps/luoyang_city_rebuild_20261027d/west_shop_residence_v1_padded.png"
const SOIL:="res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
const STONE:="res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const PAVING:="res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
const GRASS:="res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg"
const WATER:="res://art/maps/jinling_city_20261029/river_water_v1.png"
const BRIDGE:="res://art/modules/world_map_v13/bridge_stone_northsouth_v1.png"
## Existing approved anonymous daily dialogue only. No Jinling plot/economy rewrite.
const LORE:="res://build/bianzhou_city_20261028_lore01/ambient_dialogues.json"
const ART_BINDING:="res://build/jinling_city_20261029_system01/river_binding_BUILD.json"
const BUILDING_NATIVE:={"res://art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png":[708.5,1204,1009],"res://art/maps/luoyang_city_rebuild_20261027d/west_shop_residence_v1_padded.png":[674,1300,1058],"res://art/maps/luoyang_modular_v3/source/street_row_v3.png":[775,920,1498],"res://art/maps/luoyang_modular_v3/source/inn_v1.png":[768,974,1326],"res://art/maps/luoyang_modular_v3/source/shop_v1.png":[768,950,1498],"res://art/maps/luoyang_modular_v3/source/canal_warehouse_v3.png":[888,709,1744],"res://art/maps/luoyang_modular_v3/source/goods_stall_v2.png":[768,963,1432],"res://art/maps/luoyang_modular_v3/source/notice_pavilion_v2.png":[768.5,969,1331]}

static func district_rows() -> Array[Dictionary]:
	return [
		{"id":"western_quay","name":"西埠漕运","rect":Rect2(80,900,1270,1180)},
		{"id":"silk_quarter","name":"绸业桥市","rect":Rect2(1750,600,2050,1480)},
		{"id":"eastern_notice","name":"东桥榜亭","rect":Rect2(4300,800,1252,1280)},
		{"id":"north_lanes","name":"北岸水巷","rect":Rect2(80,80,5472,2000)},
		{"id":"west_homes","name":"西岸民巷","rect":Rect2(80,2520,1280,1456)},
		{"id":"south_market","name":"南岸市集","rect":Rect2(1700,2520,2050,1456)},
		{"id":"east_yard","name":"东岸货院","rect":Rect2(4300,2520,1252,1456)},
		{"id":"river_bridges","name":"双桥河街","rect":Rect2(80,1790,5472,910)}
	]

static func roads() -> Array[Dictionary]:
	return [
		{"id":"north_quay","points":PackedVector2Array([Vector2(260,1980),Vector2(5372,1980)]),"width":160.0,"texture":STONE},
		{"id":"north_cross","points":PackedVector2Array([Vector2(260,1260),Vector2(5372,1260)]),"width":160.0,"texture":STONE},
		{"id":"north_service","points":PackedVector2Array([Vector2(260,780),Vector2(5372,780)]),"width":128.0,"texture":SOIL},
		{"id":"north_w_lane","points":PackedVector2Array([Vector2(1536,780),Vector2(1536,1980)]),"width":160.0,"texture":STONE},
		{"id":"north_e_lane","points":PackedVector2Array([Vector2(4096,780),Vector2(4096,1980)]),"width":160.0,"texture":STONE},
		{"id":"south_quay","points":PackedVector2Array([Vector2(260,2660),Vector2(5372,2660)]),"width":160.0,"texture":STONE},
		{"id":"south_loop","points":PackedVector2Array([Vector2(1536,2660),Vector2(1536,3900),Vector2(4096,3900),Vector2(4096,2660)]),"width":160.0,"texture":STONE},
		{"id":"south_entry","points":PackedVector2Array([Vector2(2816,2660),Vector2(2816,4000)]),"width":192.0,"texture":PAVING},
		{"id":"west_court_lane","points":PackedVector2Array([Vector2(1360,2660),Vector2(1360,3900)]),"width":112.0,"texture":SOIL},
		{"id":"east_court_lane","points":PackedVector2Array([Vector2(5500,2660),Vector2(5500,3900)]),"width":112.0,"texture":SOIL}
	]

static func building_specs() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	# Six rear bodies and paired fronts make lanes rather than detached doorways.
	for row: Array in [
		["silk_back_w",EAST,Vector2(1500,650),540,230,"绸业后巷完整楼"],
		["silk_back_e",WEST,Vector2(2300,650),540,230,"绸业院后楼"],
		["north_home_mid",EAST,Vector2(3500,650),540,230,"北巷完整住宅"],
		["north_home_e",WEST,Vector2(4300,650),540,230,"北巷完整住宅"],
		["west_guest",BASE+"inn_v1.png",Vector2(700,1180),900,260,"西埠行旅客舍"],
		["silk_workshop",BASE+"shop_v1.png",Vector2(2300,1180),950,250,"绸业作业院房"],
		["silk_storage",BASE+"street_row_v3.png",Vector2(3500,1180),900,250,"绸业账房与后院"],
		["east_street_house",BASE+"shop_v1.png",Vector2(5000,1180),900,250,"东桥街巷住宅"],
		["west_canal_warehouse",BASE+"canal_warehouse_v3.png",Vector2(650,1810),1000,250,"漕运仓与装卸院"],
		["silk_riverside_w",WEST,Vector2(2250,1810),540,230,"临水完整绸业铺面"],
		["silk_riverside_e",EAST,Vector2(3100,1810),540,230,"临水完整商住楼"],
		["east_notice_house",BASE+"street_row_v3.png",Vector2(4750,1810),850,240,"东桥榜亭后街沿"],
		["east_riverside_house",EAST,Vector2(5350,1810),500,230,"东桥临水厢楼"],
		["west_home_front",BASE+"shop_v1.png",Vector2(600,3580),950,240,"西岸民居前屋"],
		["west_home_side",EAST,Vector2(1100,3300),520,230,"西岸民居完整侧厢"],
		["south_market_w",WEST,Vector2(2300,3140),540,230,"南桥市集西铺"],
		["south_market_e",EAST,Vector2(3400,3140),540,230,"南桥市集东铺"],
		["south_goods_back",BASE+"canal_warehouse_v3.png",Vector2(3500,2880),800,190,"南岸铺后短仓"],
		["south_market_rear_w",EAST,Vector2(2300,3580),540,230,"南市后街商住楼"],
		["south_market_rear_e",WEST,Vector2(3400,3580),540,230,"南市后街商住楼"],
		["east_cargo_front",BASE+"canal_warehouse_v3.png",Vector2(5000,3580),1000,250,"东岸货行完整仓"],
		["east_home_side",WEST,Vector2(4500,3300),520,230,"东岸民居完整侧厢"],
		["south_land_house_w",WEST,Vector2(1900,3790),540,230,"南来路旁完整住宅"],
		["south_land_house_e",EAST,Vector2(3800,3790),540,230,"南来路旁完整住宅"]
	]:
		rows.append(_building(row[0],row[1],row[2],row[3],row[4],row[5]))
	for item: Array in [["north_kitchen_w",Vector2(700,650)],["north_kitchen_e",Vector2(5000,650)],["west_home_kitchen",Vector2(600,2920)],["east_home_kitchen",Vector2(5000,2920)]]:
		rows.append(_good(item[0],"res://art/modules/luoyang_city_finish_20261025i/ordinary_kitchen_rear_body_v2.png",item[1],145.0/294.0,Vector2(864,893),Rect2(327,769,1082,151),"完整民居后厨"))
	return rows

static func _building(id: String, texture: String, foot: Vector2, width: float, depth: float, usage: String) -> Dictionary:
	var source: Array=BUILDING_NATIVE[texture]
	return {"id":id,"texture":texture,"foot":foot,"native_scale":width/float(source[2]),"source_foot_px":[source[0],source[1]],"visible_width":width,"body":Rect2(foot-Vector2(width*.43,depth),Vector2(width*.86,depth)),"usage":usage}

static func _good(id: String, texture: String, foot: Vector2, scale_factor: float, source_foot: Vector2, bounds: Rect2, usage: String) -> Dictionary:
	return {"id":id,"texture":texture,"foot":foot,"native_scale":scale_factor,"source_foot_px":[source_foot.x,source_foot.y],"body":Rect2(foot+(bounds.position-source_foot)*scale_factor,bounds.size*scale_factor),"usage":usage}

static func prop_specs() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	for p: Vector2 in [Vector2(960,1880),Vector2(1130,1880),Vector2(3100,1920),Vector2(5100,3720),Vector2(5300,3720),Vector2(3650,3700)]:
		rows.append(_good("cargo_chest_%02d"%rows.size(),BASE+"chest_common_wood_v1.png",p,130.0/432.0,Vector2(256,468),Rect2(64,330,384,138),"低货箱"))
	for p: Vector2 in [Vector2(1280,1880),Vector2(1790,1880),Vector2(3830,1880),Vector2(4380,1880),Vector2(1280,2690),Vector2(1790,2690),Vector2(3830,2690),Vector2(4380,2690),Vector2(2730,3830),Vector2(2950,3830)]:
		rows.append(_good("quay_lamp_%02d"%rows.size(),BASE+"street_lamp_v2.png",p,94.0/534.0,Vector2(422,1489),Rect2(348,1409,148,80),"桥岸灯柱"))
	rows.append({"id":"notice_pavilion","texture":BASE+"notice_pavilion_v2.png","foot":Vector2(4780,1940),"native_scale":400.0/1331.0,"source_foot_px":[768.5,969],"body":Rect2(4620,1840,320,100),"usage":"原金陵府缉捕榜"})
	var sack: String="res://art/modules/luoyang_assembled_interiors_20261016g/grain_sack_stack_v1.png"
	var cloth: String="res://art/modules/luoyang_assembled_interiors_20261016g/cloth_roll_rack_v1.png"
	var cart: String="res://art/modules/luoyang_assembled_interiors_20261016g/wood_handcart_v1.png"
	for p: Vector2 in [Vector2(350,1880),Vector2(5280,3700),Vector2(4700,3750)]:
		rows.append(_good("grain_%02d"%rows.size(),sack,p,.14,Vector2(768,909),Rect2(231,778,1076,133),"漕粮低货组"))
	for p: Vector2 in [Vector2(2010,1890),Vector2(3330,1890),Vector2(2800,1400),Vector2(5360,2850)]:
		rows.append(_good("cloth_%02d"%rows.size(),cloth,p,.13,Vector2(768,951),Rect2(122,839,1289,114),"绸业布匹架（非新商店库存）"))
	for p: Vector2 in [Vector2(1100,1450),Vector2(3720,3300),Vector2(5300,2800)]:
		rows.append(_good("cart_%02d"%rows.size(),cart,p,.18,Vector2(1094,817),Rect2(139,306,1259,512),"装卸手车"))
	for p: Vector2 in [Vector2(820,3260),Vector2(4800,3250)]:
		rows.append(_good("home_well_%02d"%rows.size(),"res://art/modules/linxi_center_well_depth_prop_v1.png",p,.45,Vector2(768,665.6),Rect2(673.75,514.56,244.36,133.12),"住宅井庭"))
	for p: Vector2 in [Vector2(1000,3400),Vector2(4650,3400)]:
		rows.append(_good("home_laundry_%02d"%rows.size(),"res://art/modules/luoyang_assembled_interiors_20261016g/garment_rack_v1.png",p,.16,Vector2(768,942),Rect2(289,791,959,153),"民巷晾衣院"))
	for p: Vector2 in [Vector2(250,850),Vector2(1250,650),Vector2(1800,740),Vector2(3850,700),Vector2(5480,780),Vector2(300,1920),Vector2(3600,1900),Vector2(5450,1920),Vector2(250,2820),Vector2(1300,3450),Vector2(4500,3550),Vector2(5500,3700),Vector2(250,3800),Vector2(1300,3900),Vector2(4300,3900),Vector2(5500,2850)]:
		rows.append(_good("courtyard_tree_%02d"%rows.size(),"res://art/modules/luoyang_district_life_20261016f/stock_tree.png",p,.85,Vector2(76,243.68115234375),Rect2(64,225.68115234375,24,18),"院角绿树"))
	return rows

static func bridge_rows() -> Array[Dictionary]:
	return [
		{"id":"west_bridge","texture":BRIDGE,"foot":Vector2(1536,2624),"source_foot":Vector2(512,1448),"scale":.46},
		{"id":"east_bridge","texture":BRIDGE,"foot":Vector2(4096,2624),"source_foot":Vector2(512,1448),"scale":.44}
	]

static func river_binding() -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(ART_BINDING))
	return value if value is Dictionary else {}

static func bridge_deck(row: Dictionary) -> PackedVector2Array:
	# Actual native standing-surface envelope; the full player footprint and
	# separately registered original rail-contact polygons keep blocking priority.
	var source: Array=[[371,105],[654,105],[658,370],[667,600],[678,850],[691,1080],[707,1290],[717,1448],[304,1448],[326,1290],[340,1080],[351,850],[360,600],[367,370]]
	var polygon:=PackedVector2Array()
	for p: Array in source:polygon.append(row.foot+(Vector2(p[0],p[1])-row.source_foot)*float(row.scale))
	return polygon

static func land_regions() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[
		PackedVector2Array([Vector2(80,80),Vector2(5552,80),Vector2(5552,2080),Vector2(80,2080)]),
		PackedVector2Array([Vector2(80,2520),Vector2(5552,2520),Vector2(5552,4016),Vector2(80,4016)])
	]
	for row: Dictionary in bridge_rows():result.append(bridge_deck(row))
	return result

static func water_regions() -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array]=[PackedVector2Array([Vector2(0,2080),Vector2(5632,2080),Vector2(5632,2520),Vector2(0,2520)])]
	for row: Dictionary in bridge_rows():
		var next: Array[PackedVector2Array]=[]
		for polygon: PackedVector2Array in pieces:next.append_array(Geometry2D.clip_polygons(polygon,bridge_deck(row)))
		pieces=next
	return pieces

static func npc_rows() -> Array[Dictionary]:
	var young: String="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1_runtime160.png"
	var merchant: String="res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
	var woman: String="res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
	var carrier: String="res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png"
	var waiter: String="res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"
	var scholar: String="res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png"
	var farmer: String="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"
	var rows: Array[Dictionary]=[
		{"npc_id":"jinling_water_patrol","npc_name":"金陵水巡","pos":Vector2(4500,1900)/SIZE,"sprite_path":young,"dialog_id":"openworld_jinling_guide","scale":.9},
		{"npc_id":"jinling_merchant","npc_name":"绸缎商人","pos":Vector2(2590,1900)/SIZE,"sprite_path":merchant,"interaction_action":"shop:lingyue_pavilion","scale":.9}
	]
	var stations: Array=[
		["漕粮脚夫",Vector2(550,1880),carrier,"货栈脚夫"],["仓前伙计",Vector2(820,1880),waiter,"货栈脚夫"],
		["候船旅人",Vector2(1220,1880),woman,"候车旅人"],["行脚商",Vector2(500,1380),merchant,"候车旅人"],
		["搬运脚夫",Vector2(800,1380),carrier,"货栈脚夫"],["投宿乡民",Vector2(1100,840),farmer,"候车旅人"],
		["绸铺伙计",Vector2(2100,1380),waiter,"货栈脚夫"],["绸业送货人",Vector2(2500,1380),carrier,"货栈脚夫"],
		["采买街坊",Vector2(2920,1380),woman,"候车旅人"],["桥市茶贩",Vector2(3300,1380),waiter,"茶食摊主"],
		["北巷住户",Vector2(3650,840),woman,"坊巷老住户"],["往来货商",Vector2(2700,1880),merchant,"候车旅人"],
		["东桥巡卒",Vector2(4500,1380),young,"阅榜百姓"],["阅榜街坊",Vector2(5100,1380),scholar,"阅榜百姓"],
		["赶集住户",Vector2(5250,1880),woman,"候车旅人"],["桥头茶食伙计",Vector2(4650,840),waiter,"茶食摊主"],
		["西巷老住户",Vector2(480,3680),woman,"坊巷老住户"],["挑水住户",Vector2(800,3690),farmer,"候车旅人"],
		["晒衣住户",Vector2(1120,3420),woman,"坊巷老住户"],["巷口行商",Vector2(300,3650),merchant,"候车旅人"],
		["邻家住户",Vector2(1000,3650),woman,"坊巷老住户"],["候行乡民",Vector2(1180,2820),farmer,"候车旅人"],
		["南桥买客",Vector2(2100,3270),woman,"候车旅人"],["市集茶贩",Vector2(2490,3270),waiter,"茶食摊主"],
		["卸货伙计",Vector2(3100,3270),carrier,"货栈脚夫"],["南街买客",Vector2(3900,3270),woman,"候车旅人"],
		["穿街行商",Vector2(2450,3660),merchant,"候车旅人"],["送货行商",Vector2(3500,3660),merchant,"货栈脚夫"],
		["东巷老住户",Vector2(4850,3840),woman,"坊巷老住户"],["东货院脚夫",Vector2(5150,3860),carrier,"货栈脚夫"],
		["仓旁伙计",Vector2(5440,3820),waiter,"货栈脚夫"],["东巷买菜人",Vector2(4650,3660),woman,"候车旅人"],
		["装卸货商",Vector2(5100,3660),merchant,"货栈脚夫"],["赶船旅人",Vector2(4500,2820),farmer,"候车旅人"],
		["南来住户",Vector2(2000,3970),woman,"候车旅人"],["等候旅人",Vector2(2500,3790),merchant,"候车旅人"],
		["携书旅人",Vector2(3300,3790),scholar,"阅榜百姓"],["南街乡民",Vector2(3900,3970),farmer,"候车旅人"]
	]
	for i: int in range(stations.size()):
		var p: Array=stations[i]
		var row: Dictionary={"npc_id":"jinling_life_%02d"%i,"npc_name":p[0],"pos":p[1]/SIZE,"sprite_path":p[2],"interaction_action":"jinling_ambient:"+p[3],"scale":.9}
		if i in [3,12,27,32]:
			row.movement_mode="patrol";row.patrol_axis=Vector2.RIGHT;row.patrol_distance=32.0;row.patrol_speed=18.0
			row.walk_sprite_path="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png" if p[2]==young else "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"
		rows.append(row)
	return rows

static func scene() -> SceneScript:
	var out:=SceneScript.new();out.scene_id=ID;out.display_name="金陵城 · 水巷桥市"
	out.is_walkable=true;out.actor_positions_are_feet=true;out.is_settlement=true
	out.bgm_path="res://art/audio/bgm/bgm_jianghu_journey_v4.wav";out.camera_zoom=1.10
	out.player_spawn=SOUTH_ARRIVAL/SIZE;out.npcs=npc_rows();out.map_layout=layout()
	return out

static func layout() -> WalkableMapLayout:
	var out:=WalkableMapLayout.new();out.schema_version=VERSION;out.design_size=Vector2i(SIZE);out.display_at_native_size=true
	for polygon: PackedVector2Array in land_regions():
		var normalized:=PackedVector2Array()
		for point: Vector2 in polygon:normalized.append(point/SIZE)
		out.walkable_regions.append(normalized)
	out.interactions=[{"id":"jinling_bounty_board","label":"查看金陵府缉捕榜","pos":Vector2(4780,1990)/SIZE,"size":Vector2(180,96)/SIZE,"activation":"interact","action":"bounty_board:jinling","visual_baked":false,"clickable":true}]
	out.portals=[{"id":"return_world","label":"离开金陵 · 江湖大地图","pos":SOUTH_EXIT/SIZE,"size":Vector2(160,96)/SIZE,"action":"world_map","marker_rotation_degrees":180.0},{"id":"reed_marsh","label":"乘舟前往江南芦荡（9～13级）","pos":REED_FOOT/SIZE,"size":Vector2(150,100)/SIZE,"target_scene":"openworld_jinling_reed_marsh","target_pos":Vector2(.5,.88)}]
	return out

static func solid_polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=water_regions()
	var art: Dictionary=river_binding()
	for raw: Array in art.get("solids",[]):
		var polygon:=PackedVector2Array()
		for p: Array in raw:polygon.append(Vector2(float(p[0]),float(p[1])))
		result.append(polygon)
	return result

static func safe_foot(uv: Vector2, include_npcs: bool = true) -> bool:
	if not uv.is_finite():return false
	var foot: Vector2=uv*SIZE
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not Rect2(80,80,5472,3936).encloses(body):return false
	for corner: Vector2 in [body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)]:
		var on_land:=false
		for polygon: PackedVector2Array in land_regions():
			if Geometry2D.is_point_in_polygon(corner,polygon):on_land=true;break
		if not on_land:return false
	var shapes: Array[Dictionary]=building_specs();shapes.append_array(prop_specs())
	for row: Dictionary in shapes:
		if body.intersects(row.body,true):return false
	var corners:=PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
	for polygon: PackedVector2Array in solid_polygons():
		if not Geometry2D.intersect_polygons(corners,polygon).is_empty():return false
	if include_npcs:
		for npc: Dictionary in npc_rows():
			var p: Vector2=npc.pos*SIZE;var reach: float=float(npc.get("patrol_distance",0))
			if body.intersects(Rect2(p-Vector2(17+reach,0),Vector2(34+reach*2,32)),true):return false
	return true

static func migration(uv: Vector2, version: int) -> Variant:
	if not uv.is_finite() or uv.x<0 or uv.y<0 or uv.x>1 or uv.y>1:return null
	if version==VERSION:return uv if safe_foot(uv) else null
	if version!=1 and version!=5:return null
	var p: Vector2
	if uv.distance_to(Vector2(.105,.105))<.000001 or uv.distance_to(Vector2(.15,.5))<.000001:p=REED_FOOT
	elif uv.y>=.585 and uv.x>=.325 and uv.x<=.675:
		p=Vector2(2816+(uv.x-.5)*200,lerpf(2660,4000,clampf((uv.y-.585)/.415,0,1)))
	elif uv.x<.25 and uv.y<.4:p=Vector2(lerpf(300,1200,clampf(uv.x/.25,0,1)),1980)
	elif uv.x>=.115 and uv.x<=.87 and uv.y>=.165 and uv.y<=.72:
		p=Vector2(lerpf(300,5332,(uv.x-.115)/.755),1260 if uv.y<.30 else (1980 if uv.y<.585 else 2660))
	else:return null
	return p/SIZE if safe_foot(p/SIZE) else null
