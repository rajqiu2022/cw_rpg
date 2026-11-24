extends RefCounted
## Jiang-defence town: two levels of circulation, drill court and real quay.
const Common=preload("res://build/three_settlements_20261030e_system01/common_author.gd")
const River=preload("res://build/jinling_city_20261029_system01/city_author.gd")
const ID: StringName=&"openworld_xiangzhou_city"
const SIZE:=Vector2(5632,4096)
const VERSION:=30
const SOUTH_ARRIVAL:=Vector2(2816,3960)
const SOUTH_EXIT:=Vector2(2816,4000)
const MINE_FOOT:=Vector2(2816,200)
const BASE:=Common.BASE
const EAST:=Common.EAST
const WEST:=Common.WEST
const SOIL:=River.SOIL
const STONE:=River.STONE
const GRASS:=River.GRASS
const PAVING:=River.PAVING
const LORE:=River.LORE
const RIVER_OFFSET:=Vector2(0,1100)
const GATE:="res://art/maps/bianzhou_southgate_20261028/main_gatehouse_v1_padded.png"
const HWALL:="res://art/maps/bianzhou_enclosure_20261028d/horizontal_wall_v1_padded.png"
const VWALL:="res://art/maps/bianzhou_enclosure_20261028d/west_longitudinal_wall_v2_edit_padded.png"

static func district_rows() -> Array[Dictionary]:
	return [{"id":"south_gate","name":"南门候检","rect":Rect2(1500,3650,2632,446)},{"id":"drill","name":"校场军营","rect":Rect2(1500,700,2600,1040)},{"id":"office","name":"江防府署","rect":Rect2(1500,0,2600,700)},{"id":"workshops","name":"军需工坊","rect":Rect2(80,350,1400,2040)},{"id":"homes","name":"商街民巷","rect":Rect2(4120,350,1432,2620)},{"id":"quay","name":"沿江仓码头","rect":Rect2(80,2390,5472,1420)}]

static func roads() -> Array[Dictionary]:
	return [
		{"id":"north_axis","points":PackedVector2Array([MINE_FOOT,Vector2(2816,3070)]),"width":192.0,"texture":PAVING},
		{"id":"outer_ring","points":PackedVector2Array([Vector2(1536,420),Vector2(4096,420),Vector2(4096,3070),Vector2(1536,3070),Vector2(1536,420)]),"width":176.0,"texture":STONE},
		{"id":"upper_cross","points":PackedVector2Array([Vector2(270,1050),Vector2(1450,1050),Vector2(2050,1090),Vector2(3920,1090),Vector2(4120,1050),Vector2(5410,1050)]),"width":176.0,"texture":STONE},
		{"id":"military_cross","points":PackedVector2Array([Vector2(1450,1760),Vector2(3950,1760)]),"width":176.0,"texture":STONE},
		{"id":"military_supply_spur","points":PackedVector2Array([Vector2(270,1760),Vector2(1380,1760),Vector2(1380,2180)]),"width":112.0,"texture":SOIL},
		{"id":"market_cross","points":PackedVector2Array([Vector2(270,2430),Vector2(5410,2430)]),"width":160.0,"texture":STONE},
		{"id":"north_quay","points":PackedVector2Array([Vector2(270,3070),Vector2(5410,3070)]),"width":160.0,"texture":STONE},
		{"id":"west_bridge_road","points":PackedVector2Array([Vector2(1536,3070),Vector2(1536,3800)]),"width":110.0,"texture":STONE},
		{"id":"east_bridge_road","points":PackedVector2Array([Vector2(4096,3070),Vector2(4096,3800)]),"width":104.0,"texture":STONE},
		{"id":"south_bank_ring","points":PackedVector2Array([Vector2(270,3800),Vector2(5410,3800)]),"width":144.0,"texture":STONE},
		{"id":"gate_approach","points":PackedVector2Array([Vector2(2816,3800),SOUTH_EXIT]),"width":150.0,"texture":PAVING},
		{"id":"west_service","points":PackedVector2Array([Vector2(270,650),Vector2(270,3070)]),"width":112.0,"texture":SOIL},
		{"id":"east_service","points":PackedVector2Array([Vector2(5410,650),Vector2(5410,3070)]),"width":112.0,"texture":SOIL}
	]

static func building_specs() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	# Different orientations, lengths and heights; no decorative three-door fronts.
	for r: Array in [
		["north_smith_store",BASE+"canal_warehouse_v3.png",Vector2(680,900),900,240,"军械物资整仓"],
		["office_w",WEST,Vector2(2180,860),570,230,"府署西厢完整楼"],
		["office_e",EAST,Vector2(3440,860),570,230,"府署东厢完整楼"],
		["north_lodging",WEST,Vector2(4900,890),640,220,"军属行旅客舍"],
		["western_barracks",BASE+"street_row_v3.png",Vector2(700,1580),940,250,"校营完整长舍"],
		["east_barracks",BASE+"street_row_v3.png",Vector2(4800,1580),920,250,"军士完整长舍"],
		["office_rear_w",WEST,Vector2(2120,630),460,170,"府署后排文书楼"],
		["office_rear_e",EAST,Vector2(3520,630),460,170,"府署后排值守楼"],
		["workshop_long",BASE+"canal_warehouse_v3.png",Vector2(700,2260),900,250,"军需作业整房"],
		["middle_supply",WEST,Vector2(2180,2260),560,230,"供给账房整楼"],
		["middle_inn",EAST,Vector2(3440,2260),560,230,"行旅商住整楼"],
		["east_homes",BASE+"shop_v1.png",Vector2(4800,2260),900,230,"东街完整民居"],
		["quay_grain",BASE+"canal_warehouse_v3.png",Vector2(700,2900),1000,230,"沿江漕粮仓"],
		["quay_wing_w",WEST,Vector2(2180,2900),560,220,"码头吏舍整楼"],
		["quay_wing_e",WEST,Vector2(3440,2890),540,210,"码头商住整楼"],
		["quay_cargo",BASE+"canal_warehouse_v3.png",Vector2(4800,2900),1000,230,"沿江军需货仓"],
		["smith_side",EAST,Vector2(1130,1240),430,170,"军需侧厢"],
		["smith_back",WEST,Vector2(550,600),430,170,"作坊后排住宅"],
		["barrack_back",EAST,Vector2(1120,1980),430,180,"军营后勤厢房"],
		["home_back_a",WEST,Vector2(4470,600),440,170,"民巷后排整宅"],
		["home_back_b",EAST,Vector2(5170,1260),440,180,"民巷东后宅"],
		["home_back_c",WEST,Vector2(4470,1980),440,180,"民巷西后宅"],
		["cargo_office",EAST,Vector2(1130,2620),430,160,"漕仓账房整楼"],
		["cargo_kitchen",WEST,Vector2(4450,2620),430,160,"仓院住屋整楼"]
	]:out.append(Common.building(r[0],r[1],r[2],r[3],r[4],r[5]))
	for p: Vector2 in [Vector2(510,1470),Vector2(5130,2110),Vector2(500,2110),Vector2(5130,2750)]:
		out.append(Common.good("kitchen_%d"%out.size(),"res://art/modules/luoyang_city_finish_20261025i/ordinary_kitchen_rear_body_v2.png",p,.42,Vector2(864,893),Rect2(327,769,1082,151),"完整灶房与生活后院"))
	return out

static func _wall(id: String, foot: Vector2, width: float) -> Dictionary:
	var row: Dictionary=Common.good(id,HWALL,foot,width/1446.0,Vector2(723,375),Rect2(0,285,1446,90),"连续真实城界")
	row.source_region_px=[946,386,1446,375]
	return row

static func prop_specs() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	out.append({"id":"south_gate","texture":GATE,"foot":Vector2(2816,3920),"native_scale":.60,"source_foot_px":[1044.5,1047],"usage":"双门墩真实洞口；非装饰门脸"})
	out.append({"id":"north_gate","texture":GATE,"foot":Vector2(2816,360),"native_scale":.60,"source_foot_px":[1044.5,1047],"usage":"矿谷外路关门"})
	for y: float in [360.0,3920.0]:
		for section: Array in [[80.0,858.0],[850.0,1630.0],[1622.0,2400.0],[3232.0,4010.0],[4002.0,4782.0],[4774.0,5552.0]]:
			out.append(_wall("horizontal_wall_%d"%out.size(),Vector2((section[0]+section[1])*.5,y),section[1]-section[0]))
	for x: float in [80.0,5552.0]:
		for i: int in range(13):
			var foot:=Vector2(x,360+(i+1)*220)
			var row: Dictionary=Common.good("side_wall_%d"%out.size(),VWALL,foot,220.0/290.0,Vector2(103.5,290),Rect2(4,0,199,290),"连续纵向城界")
			row.source_region_px=[683,1385,207,290];out.append(row)
	out.append(Common.building("notice_pavilion",BASE+"notice_pavilion_v2.png",Vector2(3170,1610),400,100,"原襄州缉捕榜实体"))
	for p: Vector2 in [Vector2(750,3010),Vector2(1000,3010),Vector2(4590,3020),Vector2(5100,3010),Vector2(700,2380),Vector2(3430,2360)]:
		out.append(Common.good("supplies_%d"%out.size(),"res://art/modules/luoyang_assembled_interiors_20261016g/grain_sack_stack_v1.png",p,.14,Vector2(768,909),Rect2(231,778,1076,133),"军需低货组"))
	for p: Vector2 in [Vector2(1180,2720),Vector2(4550,2720),Vector2(5200,2380)]:
		out.append(Common.good("handcart_%d"%out.size(),"res://art/modules/luoyang_assembled_interiors_20261016g/wood_handcart_v1.png",p,.17,Vector2(1094,817),Rect2(139,306,1259,512),"货院手车"))
	for p: Vector2 in [Vector2(1320,1140),Vector2(4300,1140),Vector2(1320,2530),Vector2(4300,2530),Vector2(2600,3710),Vector2(3030,3710)]:
		out.append(Common.good("lamp_%d"%out.size(),BASE+"street_lamp_v2.png",p,94.0/534,Vector2(422,1489),Rect2(348,1409,148,80),"街角灯柱"))
	for p: Vector2 in [Vector2(1220,710),Vector2(4350,720),Vector2(1300,2110),Vector2(4320,2110),Vector2(300,3700),Vector2(5340,3700)]:
		out.append(Common.good("tree_%d"%out.size(),"res://art/modules/luoyang_district_life_20261016f/stock_tree.png",p,.85,Vector2(76,243.68115234375),Rect2(64,225.68115234375,24,18),"院角树木"))
	var art: Dictionary=River.river_binding()
	for raw: Dictionary in art.get("objects",[]):
		var row: Dictionary=raw.duplicate(true);row.foot=Vector2(raw.foot[0],raw.foot[1])+RIVER_OFFSET;out.append(row)
	return out

static func bridge_rows() -> Array[Dictionary]:
	var out: Array[Dictionary]=River.bridge_rows()
	for row: Dictionary in out:row.foot+=RIVER_OFFSET
	return out

static func ground_rows() -> Array[Dictionary]:
	var out: Array[Dictionary]=[
		{"id":"grass","polygon":Common.rect_polygon(Rect2(Vector2.ZERO,SIZE)),"texture":GRASS,"period":Vector2(768,768),"z":-1200},
		{"id":"north_courts","polygon":Common.rect_polygon(Rect2(80,360,5472,2820)),"texture":SOIL,"period":Vector2(512,512),"z":-1100},
		{"id":"south_courts","polygon":Common.rect_polygon(Rect2(80,3620,5472,476)),"texture":SOIL,"period":Vector2(512,512),"z":-1100},
		{"id":"drill_court","polygon":Common.rect_polygon(Rect2(1680,1090,2220,510)),"texture":SOIL,"period":Vector2(512,512),"z":-1050},
		{"id":"river","polygon":Common.rect_polygon(Rect2(0,3140,5632,520)),"texture":River.WATER,"period":Vector2(420,420),"z":-1090}
	]
	for patch: Dictionary in preload("res://build/city_visual_diversity_20261031c/district_visuals.gd").rows("xiangzhou"):out.append(patch)
	for raw: Dictionary in River.river_binding().get("ground",[]):
		var row: Dictionary=raw.duplicate(true);row.polygon=_offset_polygon(raw.polygon);row.period=Vector2(raw.period[0],raw.period[1]);out.append(row)
	return out

static func _offset_polygon(source: Variant) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for p: Variant in source:out.append((p if p is Vector2 else Vector2(p[0],p[1]))+RIVER_OFFSET)
	return out

static func foreground_rows() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for raw: Dictionary in River.river_binding().get("foreground",[]):
		var row: Dictionary=raw.duplicate(true);row.polygon=_offset_polygon(raw.polygon);row.depth_y=float(raw.depth_y)+RIVER_OFFSET.y;out.append(row)
	return out

static func solid_polygons() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array]=[]
	for polygon: PackedVector2Array in River.solid_polygons():out.append(_offset_polygon(polygon))
	for y: float in [360.0,3920.0]:
		var k: float=.60/.9824561403508771
		out.append(Common.rect_polygon(Rect2(Vector2(2816-701*k,y-210*k),Vector2(561*k,210*k))))
		out.append(Common.rect_polygon(Rect2(Vector2(2816+140*k,y-210*k),Vector2(564*k,210*k))))
	return out

static func npc_rows() -> Array[Dictionary]:
	var original:=load("res://data/scenes/openworld_xiangzhou_city.tres") as SceneScript
	var out: Array[Dictionary]=original.npcs.duplicate(true)
	out[0].pos=Vector2(2470,1660)/SIZE
	var young: String="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1_runtime160.png"
	var veteran: String="res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1_runtime160.png"
	var merchant: String="res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
	var woman: String="res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
	var carrier: String="res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png"
	var smith: String="res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png"
	for p: Array in [
		["南门值卒",Vector2(2630,3740),young,"候检守卒"],["南门老卒",Vector2(3010,3740),veteran,"候检守卒"],
		["营前军士",Vector2(2050,1210),young,"候检守卒"],["校场军士",Vector2(2400,1390),veteran,"候检守卒"],["轮值军士",Vector2(3220,1320),young,"候检守卒"],["营旁老卒",Vector2(3650,1510),veteran,"候检守卒"],
		["府前值卒",Vector2(2600,960),young,"阅榜百姓"],["文书往来人",Vector2(3400,990),merchant,"阅榜百姓"],
		["修械匠",Vector2(650,2470),smith,"修车匠人"],["补车匠",Vector2(1120,1710),smith,"修车匠人"],["军需搬运人",Vector2(700,1710),carrier,"货栈脚夫"],["军需伙计",Vector2(1200,2360),merchant,"货栈脚夫"],
		["街坊住户",Vector2(4600,2370),woman,"坊巷老住户"],["赶集买客",Vector2(5040,2480),woman,"候车旅人"],["沿街货郎",Vector2(4800,1720),merchant,"候车旅人"],["巷口住户",Vector2(5150,1700),woman,"坊巷老住户"],
		["漕仓脚夫",Vector2(500,3020),carrier,"货栈脚夫"],["货院伙计",Vector2(1100,3030),merchant,"货栈脚夫"],["码头搬运人",Vector2(4700,3040),carrier,"货栈脚夫"],["待行货商",Vector2(5200,3030),merchant,"候车旅人"],
		["阅榜军士",Vector2(3300,1680),young,"阅榜百姓"],["阅榜街坊",Vector2(3550,1710),woman,"阅榜百姓"],["桥南旅人",Vector2(1900,3750),merchant,"候车旅人"],["桥南茶贩",Vector2(3650,3750),woman,"茶食摊主"]
	]:
		var row: Dictionary={"npc_id":"xiangzhou_life_%02d"%out.size(),"npc_name":p[0],"pos":p[1]/SIZE,"sprite_path":p[2],"interaction_action":"settlement_ambient:"+p[3],"scale":.9}
		if out.size() in [3,5,15,18]:
			row.movement_mode="patrol";row.patrol_axis=Vector2.RIGHT;row.patrol_distance=28.0;row.patrol_speed=18.0
			row.walk_sprite_path="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png" if p[2]==young else "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"
			# Actual merchant strip faces LEFT despite its historical filename; guard faces RIGHT.
			row.invert_patrol_facing = p[2] != young
			if p[2]!=young and p[2]!=merchant:row.erase("movement_mode");row.erase("walk_sprite_path")
		out.append(row)
	return out

static func scene() -> SceneScript:
	var out: SceneScript=(load("res://data/scenes/openworld_xiangzhou_city.tres") as SceneScript).duplicate(true)
	out.background_path="";out.streamed_background=null;out.display_name="襄州城 · 江防校场";out.camera_zoom=1.10
	out.player_spawn=SOUTH_ARRIVAL/SIZE;out.npcs=npc_rows();out.map_layout=layout()
	return out

static func layout() -> WalkableMapLayout:
	var old: WalkableMapLayout=(load("res://data/maps/openworld_xiangzhou_city_layout_v2.tres") as WalkableMapLayout)
	var out:=WalkableMapLayout.new();out.schema_version=VERSION;out.design_size=Vector2i(SIZE);out.display_at_native_size=true
	for region: PackedVector2Array in River.land_regions():
		# Bridge deck retains the exact native bridge envelope, translated only.
		var shifted:=_offset_polygon(region)
		if region.size()==4 and region[0].y<100:shifted=Common.rect_polygon(Rect2(80,80,5472,3100))
		elif region.size()==4 and region[0].y>2500:shifted=Common.rect_polygon(Rect2(80,3620,5472,396))
		out.walkable_regions.append(Common.normalized_polygon(shifted,SIZE))
	out.interactions=old.interactions.duplicate(true);out.interactions[0].pos=Vector2(3170,1700)/SIZE;out.interactions[0].size=Vector2(180,96)/SIZE;out.interactions[0].visual_baked=false
	out.portals=old.portals.duplicate(true);out.portals[0].pos=SOUTH_EXIT/SIZE;out.portals[0].size=Vector2(140,70)/SIZE
	out.portals[1].pos=MINE_FOOT/SIZE;out.portals[1].size=Vector2(140,96)/SIZE
	return out

static func safe_foot(uv: Vector2, include_npcs: bool = true) -> bool:
	return Common.safe_foot(load("res://build/three_settlements_20261030e_system01/xiangzhou_author.gd"),uv,include_npcs)

static func migration(uv: Vector2, version: int) -> Variant:
	if not uv.is_finite() or uv.x<0 or uv.x>1 or uv.y<0 or uv.y>1:return null
	if version==VERSION:return uv if safe_foot(uv) else null
	if version!=1 and version!=5:return null
	# The immutable mine return is (.50,.18), distinct from the old city exit.
	# It is an explicit author route, even though the old city mask was mismatched.
	if uv.distance_to(Vector2(.50,.18))<.000001 or uv.distance_to(Vector2(.55,.07))<.000001:return MINE_FOOT/SIZE
	# Admit only the old authored walkable domain, excluding its original board.
	var old:=load("res://data/maps/openworld_xiangzhou_city_layout_v2.tres") as WalkableMapLayout
	var valid:=false
	for region: PackedVector2Array in old.walkable_regions:
		if Geometry2D.is_point_in_polygon(uv,region):valid=true;break
	for blocked: Dictionary in old.blockers:
		if Rect2(blocked.pos-blocked.size*.5,blocked.size).has_point(uv):valid=false
	if not valid:return null
	if uv.distance_to(Vector2(.505,.90))<.001:return SOUTH_ARRIVAL/SIZE
	var p: Vector2
	if uv.y>.70:p=Vector2(2816,lerpf(3800,4000,clampf((uv.y-.70)/.30,0,1)))
	elif uv.y<.235:p=Vector2(2816,lerpf(200,420,clampf(uv.y/.235,0,1)))
	elif uv.y<.49:p=Vector2(lerpf(300,5300,clampf((uv.x-.035)/.78,0,1)),1050)
	else:p=Vector2(lerpf(300,5300,clampf((uv.x-.035)/.78,0,1)),1760 if uv.y<.61 else 2430)
	return p/SIZE if safe_foot(p/SIZE) else null
