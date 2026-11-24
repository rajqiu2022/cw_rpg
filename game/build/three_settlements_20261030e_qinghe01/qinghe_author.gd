extends RefCounted
## 清河原生模块镇：两岸双桥成环，全部旧业务从原资源深复制。
const C = preload("res://build/three_settlements_20261030e_system01/common_author.gd")
const ID: StringName = &"openworld_qinghe_town"
const SIZE := Vector2(4096,3072)
const VERSION := 30
const SOUTH_ARRIVAL := Vector2(2048,2900)
const SOUTH_EXIT := Vector2(2048,2990)
const SUPPLY_FOOT := Vector2(2450,2440)
const BASE := C.BASE
const EAST := C.EAST
const WEST := C.WEST
const GRASS := "res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg"
const SOIL := "res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
const STONE := "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const PAVING := "res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
const WATER := "res://art/maps/jinling_city_20261029/river_water_v1.png"
const ROCK := "res://art/modules/luoyang_moat_v1/mossy_rock_diff_1k.jpg"
const BRIDGE := "res://art/modules/world_map_v13/bridge_stone_northsouth_v1.png"
const LORE := "res://build/bianzhou_city_20261028_lore01/ambient_dialogues.json"
const JINLING_BINDING := "res://build/jinling_city_20261029_system01/river_binding_BUILD.json"
const STONE_HOME := "res://art/modules/linxi_house_variety_20261109/stone_hip_roof_home.png"
const HERB_HOME := "res://art/modules/linxi_house_variety_20261109/herbal_drying_home.png"
const WINGED_HOME := "res://art/modules/zhuwei_rebuild_20261109/residence.png"
# Source foot, visible width and the reserved ground footprint measured in Zhuwei.
const HOUSE_ART := {
	STONE_HOME: [Vector2(794.5,829),871.0,Rect2(-188.7,-87.1,392.3,87.1),0.57],
	HERB_HOME: [Vector2(791,919),1270.0,Rect2(-194.544,-84,404.544,84),0.4032],
	WINGED_HOME: [Vector2(887,832),1742.0,Rect2(-251.5,-69.9,522.9,69.9),0.38],
}

static func home_variant(row: Array, texture: String, width: float, usage: String) -> Dictionary:
	var art: Array = HOUSE_ART[texture]
	var scale_factor: float = width / float(art[1])
	var foot: Vector2 = row[2]
	var source_foot: Vector2 = art[0]
	var source_body: Rect2 = art[2]
	var source_scale: float = art[3]
	var result := C.good(row[0],texture,foot,scale_factor,source_foot,Rect2(source_foot+source_body.position/source_scale,source_body.size/source_scale),usage)
	var original := C.building(row[0],row[1],foot,row[3],row[4],usage)
	# No new blocked foot positions across the existing layout version.
	result.body = (result.body as Rect2).intersection(original.body)
	result.visible_width = width
	return result

static func district_rows() -> Array[Dictionary]:
	return [{"id":"entry_inn","name":"镇口驿舍","rect":Rect2(900,2560,2200,450)},
		{"id":"cross_market","name":"行旅十字街","rect":Rect2(1300,1740,1500,850)},
		{"id":"homes","name":"两岸民巷","rect":Rect2(80,80,3900,1100)},
		{"id":"grain_quay","name":"河埠粮货院","rect":Rect2(80,1740,1120,1100)},
		{"id":"workshops","name":"东岸小作坊","rect":Rect2(3100,1740,900,1100)}]

static func roads() -> Array[Dictionary]:
	return [{"id":"entry","points":PackedVector2Array([Vector2(2048,2990),Vector2(2048,2380)]),"width":184.0,"texture":PAVING},
		{"id":"market_cross","points":PackedVector2Array([Vector2(180,2380),Vector2(3916,2380)]),"width":160.0,"texture":STONE},
		{"id":"south_loop","points":PackedVector2Array([Vector2(1180,1810),Vector2(1180,2820),Vector2(3000,2820),Vector2(3000,1810)]),"width":144.0,"texture":STONE},
		{"id":"south_quay","points":PackedVector2Array([Vector2(180,1810),Vector2(3916,1810)]),"width":140.0,"texture":STONE},
		{"id":"north_quay","points":PackedVector2Array([Vector2(180,1130),Vector2(3916,1130)]),"width":128.0,"texture":STONE},
		{"id":"north_homes","points":PackedVector2Array([Vector2(180,670),Vector2(3916,670)]),"width":128.0,"texture":SOIL},
		{"id":"west_bridge_lane","points":PackedVector2Array([Vector2(1180,330),Vector2(1180,1240)]),"width":136.0,"texture":STONE},
		{"id":"east_bridge_lane","points":PackedVector2Array([Vector2(3000,330),Vector2(3000,1240)]),"width":136.0,"texture":STONE},
		{"id":"quay_home_lane","points":PackedVector2Array([Vector2(180,1810),Vector2(180,2840),Vector2(1180,2840)]),"width":112.0,"texture":SOIL},
		{"id":"workshop_lane","points":PackedVector2Array([Vector2(3916,1810),Vector2(3916,2840),Vector2(3000,2840)]),"width":112.0,"texture":SOIL}]

static func building_specs() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for row: Array in [
		["northwest_home",WEST,Vector2(450,570),520,190,"北岸西巷完整住宅"],
		["north_mid_home",EAST,Vector2(1780,570),510,190,"北岸沿街完整侧楼"],
		["north_east_home",WEST,Vector2(2530,570),500,190,"北岸家院完整楼"],
		["north_tail_home",EAST,Vector2(3620,570),500,190,"东桥北巷完整住宅"],
		["northwest_shop",BASE+"shop_v1.png",Vector2(450,1010),740,180,"北岸日用完整铺楼"],
		["north_quay_w",WEST,Vector2(1730,1010),510,180,"桥头北岸商住楼"],
		["north_quay_e",EAST,Vector2(2490,1010),510,180,"河湾北巷完整住宅"],
		["north_craft",BASE+"street_row_v3.png",Vector2(3590,1010),730,180,"北岸连檐住家"],
		["grain_warehouse",BASE+"canal_warehouse_v3.png",Vector2(590,2260),820,210,"河埠完整粮仓与卸货院"],
		["market_w",WEST,Vector2(1710,2250),520,200,"十字街完整商住楼"],
		["market_e",EAST,Vector2(2520,2250),520,200,"补给铺所在完整商住楼（仅原货郎业务）"],
		["craft_front",BASE+"shop_v1.png",Vector2(3580,2250),730,200,"小作坊完整前楼"],
		["grain_home",WEST,Vector2(520,2720),510,190,"粮院后街完整住宅"],
		["entry_inn",BASE+"inn_v1.png",Vector2(1690,2720),650,190,"镇口完整行旅客舍外观；无虚构室内入口"],
		["southeast_home",WEST,Vector2(2520,2720),510,190,"南街东完整住宅"],
		["craft_back",EAST,Vector2(3590,2720),510,190,"作坊后院完整侧楼"],
		["grain_outbuilding",EAST,Vector2(760,1980),460,170,"河埠粮院附属完整厢楼"],
		["craft_outbuilding",WEST,Vector2(3500,1980),460,170,"河埠作坊附属完整厢楼"]]:
		match row[0]:
			"northwest_home": out.append(home_variant(row,STONE_HOME,560.0,"北岸西巷石墙住家"))
			"north_mid_home": out.append(home_variant(row,WINGED_HOME,620.0,"北岸连翼民居"))
			"north_east_home": out.append(home_variant(row,HERB_HOME,550.0,"北岸晒药民家"))
			"southeast_home": out.append(home_variant(row,STONE_HOME,550.0,"南街石墙住家"))
			"grain_outbuilding": out.append(home_variant(row,STONE_HOME,505.0,"粮院石墙管事房"))
			"craft_outbuilding": out.append(home_variant(row,HERB_HOME,500.0,"作坊晾晒厢房"))
			_: out.append(C.building(row[0],row[1],row[2],row[3],row[4],row[5]))
	for row: Array in [["west_home_kitchen",Vector2(450,390)],["east_home_kitchen",Vector2(3620,390)],["grain_kitchen",Vector2(400,2560)],["craft_kitchen",Vector2(3710,2560)]]:
		out.append(C.good(row[0],"res://art/modules/luoyang_city_finish_20261025i/ordinary_kitchen_rear_body_v2.png",row[1],.34,Vector2(864,893),Rect2(327,769,1082,151),"完整生活院后厨"))
	return out

static func prop_specs() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	var pbase: String="res://art/modules/luoyang_assembled_interiors_20261016g/"
	for p: Vector2 in [Vector2(380,2390),Vector2(560,2410),Vector2(810,2390),Vector2(3270,2420)]:
		out.append(C.good("cargo_%02d"%out.size(),BASE+"chest_common_wood_v1.png",p,.28,Vector2(256,468),Rect2(64,330,384,138),"低货箱；给中街留空"))
	for p: Vector2 in [Vector2(330,2170),Vector2(840,2170),Vector2(350,2470),Vector2(860,2570)]:
		out.append(C.good("grain_%02d"%out.size(),pbase+"grain_sack_stack_v1.png",p,.13,Vector2(768,909),Rect2(231,778,1076,133),"粮货院袋堆"))
	for p: Vector2 in [Vector2(3280,2180),Vector2(3760,2440)]:
		out.append(C.good("cloth_%02d"%out.size(),pbase+"cloth_roll_rack_v1.png",p,.13,Vector2(768,951),Rect2(122,839,1289,114),"作坊布架；无新增库存"))
	for p: Vector2 in [Vector2(720,2460),Vector2(3340,2490)]:
		out.append(C.good("cart_%02d"%out.size(),pbase+"wood_handcart_v1.png",p,.15,Vector2(1094,817),Rect2(139,306,1259,512),"卸货与修车手车"))
	for p: Vector2 in [Vector2(820,780),Vector2(3370,780),Vector2(800,2790),Vector2(3330,2780)]:
		out.append(C.good("laundry_%02d"%out.size(),pbase+"garment_rack_v1.png",p,.14,Vector2(768,942),Rect2(289,791,959,153),"民巷晾衣"))
	for p: Vector2 in [Vector2(790,2520),Vector2(3320,2590),Vector2(810,710),Vector2(3340,710)]:
		out.append(C.good("well_%02d"%out.size(),"res://art/modules/linxi_center_well_depth_prop_v1.png",p,.42,Vector2(768,665.6),Rect2(673.75,514.56,244.36,133.12),"邻里生活井庭"))
	for p: Vector2 in [Vector2(240,760),Vector2(930,580),Vector2(1380,510),Vector2(2800,510),Vector2(3860,780),Vector2(240,1080),Vector2(3870,1090),Vector2(240,1870),Vector2(3870,1880),Vector2(980,2680),Vector2(3190,2700),Vector2(200,2900),Vector2(3860,2900)]:
		out.append(C.good("tree_%02d"%out.size(),"res://art/modules/luoyang_district_life_20261016f/stock_tree.png",p,.85,Vector2(76,243.68115234375),Rect2(64,225.68115234375,24,18),"院角树，不占桥口或门前"))
	return out

static func bridge_rows() -> Array[Dictionary]:
	return [{"id":"west_bridge","texture":BRIDGE,"foot":Vector2(1180,1740),"source_foot":Vector2(512,1448),"scale":.42},
		{"id":"east_bridge","texture":BRIDGE,"foot":Vector2(3000,1740),"source_foot":Vector2(512,1448),"scale":.42}]

static func bridge_deck(row: Dictionary) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for p: Array in [[371,105],[654,105],[658,370],[667,600],[678,850],[691,1080],[707,1290],[717,1448],[304,1448],[326,1290],[340,1080],[351,850],[360,600],[367,370]]:
		out.append(row.foot+(Vector2(p[0],p[1])-row.source_foot)*float(row.scale))
	return out

static func _north_edge() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0,1250),Vector2(1180,1250),Vector2(1700,1180),Vector2(2300,1180),Vector2(3000,1250),Vector2(4096,1250)])

static func _south_edge() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0,1660),Vector2(1180,1660),Vector2(1700,1590),Vector2(2300,1590),Vector2(3000,1660),Vector2(4096,1660)])

static func _strip(top: PackedVector2Array, bottom: PackedVector2Array) -> PackedVector2Array:
	var out:=top.duplicate()
	for i: int in range(bottom.size()-1,-1,-1):out.append(bottom[i])
	return out

static func land_regions() -> Array[PackedVector2Array]:
	var north:=PackedVector2Array([Vector2(80,80),Vector2(4016,80),Vector2(4016,1250),Vector2(3000,1250),Vector2(2300,1180),Vector2(1700,1180),Vector2(1180,1250),Vector2(80,1250)])
	var south:=PackedVector2Array([Vector2(80,1660),Vector2(1180,1660),Vector2(1700,1590),Vector2(2300,1590),Vector2(3000,1660),Vector2(4016,1660),Vector2(4016,3032),Vector2(80,3032)])
	var out: Array[PackedVector2Array]=[north,south]
	for bridge: Dictionary in bridge_rows():out.append(bridge_deck(bridge))
	return out

static func ground_rows() -> Array[Dictionary]:
	var out: Array[Dictionary]=[{"id":"town_earth","polygon":C.rect_polygon(Rect2(Vector2.ZERO,SIZE)),"texture":SOIL,"period":Vector2(512,512),"z":-1010},
		{"id":"curved_river","polygon":_strip(_north_edge(),_south_edge()),"texture":WATER,"period":Vector2(512,512),"z":-990}]
	for rect: Rect2 in [Rect2(0,0,4096,150),Rect2(0,0,140,3072),Rect2(3956,0,140,3072),Rect2(0,2990,4096,82)]:
		out.append({"id":"grass_margin_%d"%out.size(),"polygon":C.rect_polygon(rect),"texture":GRASS,"period":Vector2(384,384),"z":-1005,"feather_px":48.0})
	# Both shores follow the same river polyline; not a separate misleading NAV.
	for side: int in range(2):
		var edge: PackedVector2Array=_north_edge() if side==0 else _south_edge()
		var land_edge:=PackedVector2Array();var water_edge:=PackedVector2Array()
		for point: Vector2 in edge:
			land_edge.append(point+Vector2(0,-48 if side==0 else 48))
			water_edge.append(point+Vector2(0,24 if side==0 else -16))
		out.append({"id":"shore_cap_%d"%side,"polygon":_strip(land_edge,edge),"texture":STONE,"period":Vector2(256,170.6666667),"z":-980})
		out.append({"id":"shore_face_%d"%side,"polygon":_strip(edge,water_edge),"texture":ROCK,"period":Vector2(256,256),"z":-979})
	return out

static func _binding() -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(JINLING_BINDING))
	return value if value is Dictionary else {}

static func foreground_rows() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	# Reproject the approved original rail UVs, not a cutout image or new art.
	for bridge: Dictionary in bridge_rows():
		for original: Dictionary in _binding().get("foreground",[]):
			if not String(original.id).begins_with("west_bridge_"):continue
			var poly:=PackedVector2Array();var uv:=PackedVector2Array()
			for p: Array in original.source_uv:
				var source:=Vector2(float(p[0]),float(p[1]));uv.append(source)
				poly.append(bridge.foot+(source-bridge.source_foot)*float(bridge.scale))
			out.append({"id":String(bridge.id)+String(original.id).trim_prefix("west_bridge"),"texture":BRIDGE,"polygon":poly,"source_uv":uv,"depth_y":bridge.foot.y+(float(original.depth_y)-2624.0)/.46*.42})
	return out

static func solid_polygons() -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array]=[_strip(_north_edge(),_south_edge())]
	for bridge: Dictionary in bridge_rows():
		var clipped: Array[PackedVector2Array]=[]
		for poly: PackedVector2Array in pieces:clipped.append_array(Geometry2D.clip_polygons(poly,bridge_deck(bridge)))
		pieces=clipped
		var originals: Array=_binding().get("solids",[])
		for i: int in range(2):
			var rail:=PackedVector2Array()
			for p: Array in originals[i]:rail.append(bridge.foot+(Vector2(float(p[0]),float(p[1]))-Vector2(1536,2624))/.46*.42)
			pieces.append(rail)
	return pieces

static func npc_rows() -> Array[Dictionary]:
	var original:=load("res://data/scenes/openworld_qinghe_town.tres") as SceneScript
	var rows: Array[Dictionary]=original.npcs.duplicate(true)
	for row: Dictionary in rows:
		if String(row.npc_id)=="qinghe_supply":row.pos=SUPPLY_FOOT/SIZE
	var merchant: String="res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
	var woman: String="res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
	var farmer: String="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"
	var carrier: String="res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png"
	var waiter: String="res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"
	var scholar: String="res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png"
	var stations: Array=[
		["投宿旅人",Vector2(1810,2890),merchant,"候车旅人"],["候车乡民",Vector2(2260,2890),farmer,"候车旅人"],
		["客舍伙计",Vector2(1320,2880),waiter,"茶食摊主"],["行脚书生",Vector2(2800,2880),scholar,"候车旅人"],
		["街头买客",Vector2(1650,2440),woman,"候车旅人"],["过桥行商",Vector2(2820,2440),merchant,"候车旅人"],
		["茶食伙计",Vector2(2250,2440),waiter,"茶食摊主"],["粮院脚夫",Vector2(430,2320),carrier,"货栈脚夫"],
		["仓前乡民",Vector2(920,2300),farmer,"候车旅人"],["河埠搬运人",Vector2(1030,2110),carrier,"货栈脚夫"],
		["码货伙计",Vector2(1030,2210),waiter,"货栈脚夫"],["修车匠人",Vector2(3210,2510),farmer,"修车匠人"],
		["作坊送货人",Vector2(3710,2370),carrier,"货栈脚夫"],["布架住户",Vector2(3380,2390),woman,"坊巷老住户"],
		["西巷住户",Vector2(700,2790),woman,"坊巷老住户"],["挑水乡民",Vector2(360,2800),farmer,"候车旅人"],
		["东巷住户",Vector2(3630,2800),woman,"坊巷老住户"],["北岸采买人",Vector2(740,1060),woman,"候车旅人"],
		["北埠行商",Vector2(1520,1060),merchant,"候车旅人"],["北巷住户",Vector2(1970,670),woman,"坊巷老住户"],
		["街边乡民",Vector2(2720,700),farmer,"候车旅人"],["桥北读书人",Vector2(3310,1060),scholar,"阅榜百姓"],
		["东桥旅人",Vector2(3710,1060),merchant,"候车旅人"],["西桥茶贩",Vector2(910,1060),waiter,"茶食摊主"]]
	for i: int in range(stations.size()):
		var row: Array=stations[i]
		rows.append({"npc_id":"qinghe_life_%02d"%i,"npc_name":row[0],"pos":row[1]/SIZE,"sprite_path":row[2],"interaction_action":"settlement_ambient:"+row[3],"scale":.9})
	return rows

static func layout() -> WalkableMapLayout:
	var original:=load("res://data/maps/openworld_qinghe_town_layout.tres") as WalkableMapLayout
	var out:=original.duplicate(true) as WalkableMapLayout
	out.schema_version=VERSION;out.design_size=Vector2i(SIZE);out.display_at_native_size=true
	out.walkable_regions.clear();out.blockers.clear();out.occluders.clear();out.blocked_probes.clear();out.walkable_probes.clear()
	for poly: PackedVector2Array in land_regions():out.walkable_regions.append(C.normalized_polygon(poly,SIZE))
	# All original keys / action / flags / target survive, only their geometry moves.
	for portal: Dictionary in out.portals:
		if String(portal.id)=="return_world":
			portal.pos=SOUTH_EXIT/SIZE;portal.size=Vector2(160,80)/SIZE;portal.marker_rotation_degrees=180.0
	return out

static func scene() -> SceneScript:
	var original:=load("res://data/scenes/openworld_qinghe_town.tres") as SceneScript
	var out:=original.duplicate(true) as SceneScript
	out.background_path="";out.streamed_background=null;out.player_spawn=SOUTH_ARRIVAL/SIZE
	out.npcs=npc_rows();out.map_layout=layout();out.camera_zoom=1.1
	return out

static func safe_foot(uv: Vector2, include_npcs: bool = true) -> bool:
	return C.safe_foot(load("res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd"),uv,include_npcs)

static func migration(uv: Vector2, version: int) -> Variant:
	if not uv.is_finite() or uv.x<0.0 or uv.x>1.0 or uv.y<0.0 or uv.y>1.0:return null
	if version==VERSION:return uv if safe_foot(uv) else null
	if version!=1 and version!=2:return null
	# Only the immutable old walk polygon authorizes legacy feet. No nearest fallback.
	var old:=load("res://data/maps/openworld_qinghe_town_layout.tres") as WalkableMapLayout
	var old_body:=Rect2(uv-Vector2(17.0/1536.0,12.0/1024.0),Vector2(34.0/1536.0,24.0/1024.0))
	for corner: Vector2 in C.rect_polygon(old_body):
		var admitted:=false
		for poly: PackedVector2Array in old.walkable_regions:
			if Geometry2D.is_point_in_polygon(corner,poly):admitted=true;break
		if not admitted:return null
	for blocker: Dictionary in old.blockers:
		var block_size: Vector2=blocker.size
		if old_body.intersects(Rect2(blocker.pos-block_size*.5,block_size),true):return null
	var mapped:=SOUTH_ARRIVAL
	if uv.distance_to(Vector2(.30,.92))<.055:mapped=SOUTH_EXIT
	elif uv.y<.57:mapped=Vector2(3000,lerpf(680,1130,clampf((uv.y-.13)/.44,0,1)))
	elif uv.y<.74:mapped=Vector2(2048,2380)
	return mapped/SIZE if safe_foot(mapped/SIZE) else null
