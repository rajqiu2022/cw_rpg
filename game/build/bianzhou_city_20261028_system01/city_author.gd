extends RefCounted
## Authored continuous Bianzhou. No old rejected 32-module assembly is loaded.
const ID: StringName = &"openworld_bianzhou_city"
const SIZE := Vector2(6144, 6144)
const VERSION := 30
const BASE := "res://art/maps/luoyang_modular_v3/source/"
const EAST := "res://art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png"
const WEST := "res://art/maps/luoyang_city_rebuild_20261027d/west_shop_residence_v1_padded.png"
## Fine compacted earth belongs to residential, posthouse and cargo service lanes.
## Public axes/cross streets retain stone paving; no geometry is changed here.
const SOIL := "res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
const STONE := "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const PAVING := "res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
const LORE := "res://build/bianzhou_city_20261028_lore01/ambient_dialogues.json"
const GATE_BINDING := "res://build/bianzhou_city_20261028_system04/gate_binding_BUILD.json"
const COMPLETION := "res://build/bianzhou_city_20261028_system05/completion_binding_BUILD.json"
const GRASS := "res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg"

static func district_rows() -> Array[Dictionary]:
	return [
		{"id":"08", "name":"北门驿道", "rect":Rect2(1536,0,3072,1180)},
		{"id":"07", "name":"北街榜亭", "rect":Rect2(3300,800,2644,1250)},
		{"id":"05", "name":"坊巷民居", "rect":Rect2(160,880,2740,1200)},
		{"id":"03", "name":"东驿馆", "rect":Rect2(4606,2200,1378,2100)},
		{"id":"04", "name":"西市货街", "rect":Rect2(160,2200,1280,2000)},
		{"id":"06", "name":"百工作坊", "rect":Rect2(160,4360,2740,876)},
		{"id":"01", "name":"南门候检与后勤车院", "rect":Rect2(1536,4360,4448,1784)},
		{"id":"02", "name":"中轴坊市", "rect":Rect2(1450,800,3100,3700)}
	]

static func roads() -> Array[Dictionary]:
	return [
		{"id":"axis", "points":PackedVector2Array([Vector2(3072,160),Vector2(3072,6020)]), "width":320.0, "texture":PAVING},
		{"id":"north_cross", "points":PackedVector2Array([Vector2(260,2100),Vector2(5880,2100)]), "width":224.0, "texture":STONE},
		{"id":"south_cross", "points":PackedVector2Array([Vector2(260,4456),Vector2(5880,4456)]), "width":192.0, "texture":STONE},
		{"id":"west_ring", "points":PackedVector2Array([Vector2(1450,880),Vector2(1450,4456)]), "width":192.0, "texture":STONE},
		{"id":"east_ring", "points":PackedVector2Array([Vector2(4510,880),Vector2(4510,4456)]), "width":192.0, "texture":STONE},
		{"id":"housing_lane", "points":PackedVector2Array([Vector2(260,1530),Vector2(2700,1530)]), "width":128.0, "texture":SOIL},
		{"id":"post_lane", "points":PackedVector2Array([Vector2(4510,3000),Vector2(5830,3000)]), "width":160.0, "texture":SOIL},
		{"id":"cargo_lane", "points":PackedVector2Array([Vector2(260,3290),Vector2(1450,3290)]), "width":160.0, "texture":SOIL}
	]

static func building_specs() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	# Continuous paired frontage; interleaved genuine opposite oblique facades.
	for i: int in range(3):
		var y: float = 2780.0 + i * 700.0
		rows.append(_building("market_w_%d"%i, WEST if i%2==0 else BASE+"street_row_v3.png", Vector2(2500 if i%2==0 else 2240,y), 540 if i%2==0 else 890, 250, "坊市西铺街沿"))
		rows.append(_building("market_e_%d"%i, EAST if i%2==0 else BASE+"street_row_v3.png", Vector2(3630 if i%2==0 else 3910,y), 540 if i%2==0 else 890, 250, "坊市东铺街沿"))
	# Residential blocks have rear and front rows, not isolated doorway props.
	for i: int in range(2):
		rows.append(_building("home_%d"%i,BASE+("shop_v1.png" if i==0 else "street_row_v3.png"),Vector2(690+i*1280,1800),870,230,"坊巷完整住宅"))
	# Upper midtown guest lodging and supply yards close the north block.
	rows.append(_building("north_guest_w",BASE+"inn_v1.png",Vector2(2220,1180),900,260,"北街客舍"))
	rows.append(_building("north_guest_e",BASE+"inn_v1.png",Vector2(3910,1760),900,260,"北街行旅客舍"))
	rows.append(_building("north_office",BASE+"shop_v1.png",Vector2(5290,1300),1030,250,"榜亭后办事院沿"))
	rows.append(_building("north_store",BASE+"canal_warehouse_v3.png",Vector2(5280,1930),1030,250,"驿递文书短仓"))
	# Dedicated east post-house: front hall, two wings and rear luggage house.
	rows.append(_building("post_front",BASE+"inn_v1.png",Vector2(5240,2650),1120,280,"东驿馆前厅"))
	rows.append(_building("post_wing_n",WEST,Vector2(5230,3500),580,250,"东驿馆住宿厢楼"))
	rows.append(_building("post_luggage",BASE+"canal_warehouse_v3.png",Vector2(5230,4180),1050,230,"东驿馆行李后勤院"))
	# Independent cargo buildings and loading courts, safely off the axis.
	rows.append(_building("cargo_n",BASE+"canal_warehouse_v3.png",Vector2(760,2600),1100,260,"西市货栈"))
	rows.append(_building("cargo_mid",BASE+"canal_warehouse_v3.png",Vector2(760,3210),1100,260,"西市短仓"))
	rows.append(_building("cargo_s",BASE+"shop_v1.png",Vector2(760,4060),1000,230,"货行账房"))
	rows.append(_building("workshop_w",BASE+"shop_v1.png",Vector2(680,4840),970,220,"修车木作作业房"))
	rows.append(_building("workshop_e",WEST,Vector2(2040,4840),560,230,"金工作坊与后院楼"))
	rows.append(_building("market_book", "res://art/modules/luoyang_market_space_20261024b/bookshop_complete_v2.png",Vector2(690,1180),840,230,"坊巷后排完整书铺"))
	rows.append_array(neighborhood_buildings())
	rows.append(_building("east_rear_residence",EAST,Vector2(4150,4150),500,230,"东后街完整商住后楼"))
	rows.append_array(completion_specs("building"))
	return rows

static func _building(id: String, texture: String, foot: Vector2, width: float, depth: float, usage: String) -> Dictionary:
	var moved: Dictionary=relocated_buildings().get(id,{})
	if not moved.is_empty():
		foot=moved.foot;width=moved.width;depth=moved.depth
	var row: Dictionary={"id":id,"texture":texture,"foot":foot,"visible_width":width,"body":Rect2(foot-Vector2(width*.43,depth),Vector2(width*.86,depth)),"usage":usage}
	if not moved.is_empty():row.migration_lane_foot=moved.lane
	return row

static func prop_specs() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for p: Vector2 in [Vector2(340,2860),Vector2(680,2860),Vector2(1080,3520),Vector2(5000,3820),Vector2(5560,3820)]:
		rows.append({"id":"freight_%d"%rows.size(),"texture":BASE+"chest_common_wood_v1.png","foot":p,"visible_width":130.0,"body":Rect2(p-Vector2(58,48),Vector2(116,48))})
	for p: Vector2 in [Vector2(2680,2620),Vector2(3470,3270),Vector2(2670,3910)]:
		rows.append({"id":"stall_%d"%rows.size(),"texture":BASE+"goods_stall_v2.png","foot":p,"visible_width":280.0,"body":Rect2(p-Vector2(117,90),Vector2(234,90))})
	for y: int in [1030,2200,2860,3500,4160,4620]:
		for x: int in [2840,3310]:
			rows.append({"id":"lamp_%d_%d"%[x,y],"texture":BASE+"street_lamp_v2.png","foot":Vector2(x,y),"visible_width":94.0,"native_scale":94.0/534.0,"source_foot_px":[422,1489],"body":Rect2(x-13,y-14,26,14)})
	rows.append({"id":"notice_pavilion","texture":BASE+"notice_pavilion_v2.png","foot":Vector2(3600,1900),"visible_width":400.0,"body":Rect2(3440,1800,320,100)})
	rows.append_array(neighborhood_goods())
	rows.append_array(completion_specs("prop"))
	return rows

static func npc_rows() -> Array[Dictionary]:
	var escort: String = "res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png"
	var merchant: String = "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
	var woman: String = "res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
	var carrier: String = "res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png"
	var smith: String = "res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png"
	var young: String = "res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1_runtime160.png"
	var veteran: String = "res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1_runtime160.png"
	var waiter: String = "res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png"
	var rows: Array[Dictionary] = [
		{"npc_id":"bianzhou_postmaster","npc_name":"汴州驿丞","pos":Vector2(4780,2840)/SIZE,"sprite_path":escort,"dialog_id":"openworld_bianzhou_guide","scale":0.96},
		{"npc_id":"bianzhou_merchant","npc_name":"中原行商","pos":Vector2(2730,3080)/SIZE,"sprite_path":merchant,"interaction_action":"shop:wulin_trade_hall","scale":0.90}
	]
	var stations: Array = [
		["候检守卒",Vector2(2846,5286),young],["候检守卒",Vector2(3298,5286),veteran],
		["候车旅人",Vector2(1886,4716),merchant],["候车旅人",Vector2(1986,4796),woman],
		["茶食摊主",Vector2(2800,2860),woman],["茶食摊主",Vector2(3450,3620),waiter],
		["驿馆马夫",Vector2(4840,3140),carrier],["驿馆马夫",Vector2(5650,3710),merchant],
		["货栈脚夫",Vector2(1120,2800),carrier],["货栈脚夫",Vector2(470,3480),merchant],
		["坊巷老住户",Vector2(1160,1460),woman],["坊巷老住户",Vector2(2260,1990),merchant],
		["修车匠人",Vector2(1200,4570),smith],["修车匠人",Vector2(2500,4680),merchant],
		["阅榜百姓",Vector2(3490,2030),woman],["阅榜百姓",Vector2(3720,2020),merchant],
		["候车旅人",Vector2(2740,1470),merchant],["茶食摊主",Vector2(3450,4060),woman],
		["货栈脚夫",Vector2(1070,4260),carrier],["候车旅人",Vector2(3330,1120),merchant]
	]
	for station: Array in stations:
		rows.append({"npc_id":"bianzhou_life_%02d"%rows.size(),"npc_name":station[0],"pos":station[1]/SIZE,"sprite_path":station[2],"interaction_action":"bianzhou_ambient:%s"%station[0],"scale":0.90,"portrait_path":""})
	for row: Dictionary in rows:
		if relocated_npcs().has(row.npc_id):
			var relocation: Dictionary=relocated_npcs()[row.npc_id]
			row.pos=relocation.foot/SIZE;row.protection_body=npc_occupancy(row);row.migration_lane_foot=relocation.lane
	rows.append_array(completion_npcs())
	return rows

static func scene() -> SceneScript:
	var out := SceneScript.new()
	out.scene_id=ID; out.display_name="汴州城 · 中轴坊市";out.is_walkable=true;out.actor_positions_are_feet=true;out.is_settlement=true
	out.bgm_path="res://art/audio/bgm/bgm_city_ceremony_v4.wav";out.player_spawn=Vector2(3072,5910)/SIZE;out.camera_zoom=1.10
	out.npcs=npc_rows();out.map_layout=layout()
	return out

static func layout() -> WalkableMapLayout:
	var out := WalkableMapLayout.new();out.schema_version=VERSION;out.design_size=Vector2i(SIZE);out.display_at_native_size=true
	out.walkable_regions=[PackedVector2Array([Vector2(80,80)/SIZE,Vector2(6064,80)/SIZE,Vector2(6064,6064)/SIZE,Vector2(80,6064)/SIZE])]
	out.interactions=[{"id":"bianzhou_bounty_board","label":"查看汴州府缉捕榜","pos":Vector2(3600,2020)/SIZE,"size":Vector2(180,96)/SIZE,"activation":"interact","action":"bounty_board:bianzhou","visual_baked":false,"clickable":true}]
	out.portals=[{"id":"return_world","label":"离开汴州 · 江湖大地图","pos":Vector2(3072,6020)/SIZE,"size":Vector2(160,120)/SIZE,"action":"world_map","marker_rotation_degrees":180.0},{"id":"old_post","label":"出城历练 · 中原旧驿（2～6级）","pos":Vector2(.505,.04),"size":Vector2(160,120)/SIZE,"target_scene":"openworld_bianzhou_old_post","target_pos":Vector2(.50,.88)}]
	return out

static func _legacy_street_projection(foot: Vector2, version: int) -> Variant:
	if not foot.is_finite() or foot.x<0 or foot.y<0 or foot.x>1 or foot.y>1: return null
	if version==VERSION or version==29 or version==28: return foot
	if version!=1: return null
	# Explicit old baked-map street zones to the corresponding new streets.
	# Not a nearest-safe search; every strip has one documented affine mapping.
	var p: Vector2
	if foot.y>=.9: p=Vector2(3072+(foot.x-.505)*240,lerpf(5910,6020,(foot.y-.9)/.1))
	elif foot.y>.75: p=Vector2(3072+(foot.x-.505)*240,lerpf(4456,5910,(foot.y-.75)/.15))
	elif foot.y<.25: p=Vector2(3072+(foot.x-.505)*240,lerpf(160,2100,foot.y/.25))
	elif foot.x<.385: p=Vector2(1450+(foot.x-.2)*160,lerpf(2100,4456,(foot.y-.25)/.5))
	elif foot.x>.625: p=Vector2(4510+(foot.x-.8)*160,lerpf(2100,4456,(foot.y-.25)/.5))
	else: p=Vector2(3072+(foot.x-.505)*240,lerpf(2100,4456,(foot.y-.25)/.5))
	return p/SIZE

static func safe_foot(uv: Vector2, include_npcs: bool = true) -> bool:
	if not uv.is_finite():return false
	var foot: Vector2=uv*SIZE
	var actor:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not Rect2(80,80,5984,5984).encloses(actor):return false
	var bodies: Array[Dictionary]=building_specs();bodies.append_array(prop_specs())
	for spec: Dictionary in bodies:
		if spec.has("body") and actor.intersects(spec.body,true):return false
	var binding: Variant=JSON.parse_string(FileAccess.get_file_as_string(GATE_BINDING))
	if not binding is Dictionary or not binding.get("blockers") is Array:return false
	var corners:=PackedVector2Array([actor.position,Vector2(actor.end.x,actor.position.y),actor.end,Vector2(actor.position.x,actor.end.y)])
	for row: Dictionary in binding.blockers:
		if row.has("rect"):
			var r: Array=row.rect
			if actor.intersects(Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])),true):return false
		elif row.has("polygon"):
			var poly:=PackedVector2Array()
			for point: Array in row.polygon:poly.append(Vector2(float(point[0]),float(point[1])))
			if not Geometry2D.intersect_polygons(corners,poly).is_empty():return false
	if include_npcs:
		for npc: Dictionary in npc_rows():
			if actor.intersects(npc_occupancy(npc) if npc.has("protection_body") else Rect2(npc.pos*SIZE-Vector2(17,12),Vector2(34,24)),true):return false
	return true

## Revision29 adds two whole rear buildings plus commodity groups along two
## existing streets. Old rows/roles/routes stay verbatim; no isolated wall props.
static func neighborhood_buildings() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[
		_building("backstreet_house_n",EAST,Vector2(1850,2940),540,250,"铺后东向整楼与小院"),
		_building("backstreet_house_s",WEST,Vector2(1850,4130),540,250,"铺后西向整楼与小院")
	]
	rows[0].migration_lane_foot=Vector2(1585,3100)
	rows[1].migration_lane_foot=Vector2(1585,4250)
	return rows

static func neighborhood_goods() -> Array[Dictionary]:
	var root: String="res://art/modules/luoyang_assembled_interiors_20261016g/"
	var sack: String=root+"grain_sack_stack_v1.png"
	var cloth: String=root+"cloth_roll_rack_v1.png"
	var cart: String=root+"wood_handcart_v1.png"
	var crate: String="res://art/modules/luoyang_district_life_20261016f/stock_crate.png"
	return [
		_good("backstreet_cloth",cloth,Vector2(1740,4250),.13,Vector2(768,951),Rect2(122,839,1289,114),Vector2(1585,4290)),
		_good("backstreet_sacks_n",sack,Vector2(1950,4250),.14,Vector2(768,909),Rect2(231,778,1076,133),Vector2(1585,4290)),
		_good("backstreet_crate_n",crate,Vector2(2130,2850),1.0,Vector2(58,101),Rect2(21.25,70.7600065469792,80.4299316704323,32.33996582031),Vector2(1585,3100)),
		_good("backstreet_cart",cart,Vector2(2240,4310),.18,Vector2(1094,817),Rect2(139,306,1259,512),Vector2(1585,4290)),
		_good("backstreet_crate_s",crate,Vector2(1720,4320),1.0,Vector2(58,101),Rect2(21.25,70.7600065469792,80.4299316704323,32.33996582031),Vector2(1585,4290)),
		_good("backstreet_sacks_s",sack,Vector2(1930,4330),.14,Vector2(768,909),Rect2(231,778,1076,133),Vector2(1585,4290)),
		_good("cargo_upper_sacks",sack,Vector2(850,2760),.14,Vector2(768,909),Rect2(231,778,1076,133),Vector2(1280,2780)),
		_good("cargo_upper_cloth",cloth,Vector2(1100,2870),.13,Vector2(768,951),Rect2(122,839,1289,114),Vector2(1280,2780)),
		_good("cargo_lower_cart",cart,Vector2(900,3700),.18,Vector2(1094,817),Rect2(139,306,1259,512),Vector2(1280,3750)),
		_good("cargo_lower_crate",crate,Vector2(1130,3660),1.0,Vector2(58,101),Rect2(21.25,70.7600065469792,80.4299316704323,32.33996582031),Vector2(1280,3750)),
		_good("cargo_lower_sacks",sack,Vector2(420,3710),.14,Vector2(768,909),Rect2(231,778,1076,133),Vector2(1280,3750)),
		_good("cargo_cloth_dispatch",cloth,Vector2(1110,4210),.13,Vector2(768,951),Rect2(122,839,1289,114),Vector2(1280,4200)),
		_good("cargo_dispatch_sacks",sack,Vector2(400,4200),.14,Vector2(768,909),Rect2(231,778,1076,133),Vector2(1280,4200)),
		_good("cargo_dispatch_crate",crate,Vector2(610,4210),1.0,Vector2(58,101),Rect2(21.25,70.7600065469792,80.4299316704323,32.33996582031),Vector2(1280,4200))
	]

static func _good(id: String, texture: String, foot: Vector2, scale_factor: float, source_foot: Vector2, source_body: Rect2, lane_foot: Vector2) -> Dictionary:
	return {"id":id,"texture":texture,"foot":foot,"native_scale":scale_factor,"source_foot_px":[source_foot.x,source_foot.y],"visible_width":0.0,"source_body_px":source_body,"body":Rect2(foot+(source_body.position-source_foot)*scale_factor,source_body.size*scale_factor),"migration_lane_foot":lane_foot}

static func new_occupancy_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary]=neighborhood_buildings()
	rows.append_array(neighborhood_goods())
	return rows


static func migration(foot: Vector2, version: int) -> Variant:
	var mapped: Variant=_legacy_street_projection(foot,version)
	if not mapped is Vector2:return null
	if version==VERSION:return mapped
	# Version28/v1 first pass revision29's original sixteen addition domains.
	if version!=29:
		mapped=_registered_domain_projection(mapped,new_occupancy_rows())
		if not mapped is Vector2:return null
	return _registered_domain_projection(mapped,completion_occupancy_rows())

static func _registered_domain_projection(uv: Vector2, domains: Array[Dictionary]) -> Variant:
	var actor:=Rect2(uv*SIZE-Vector2(17,12),Vector2(34,24))
	for row: Dictionary in domains:
		if actor.intersects(row.body,true):
			var registered: Vector2=row.migration_lane_foot/SIZE
			return registered if safe_foot(registered) else null
	return uv

static func relocated_buildings() -> Dictionary:
	return {
		"home_0":{"foot":Vector2(620,1930),"width":750.0,"depth":230.0,"lane":Vector2(1450,1530)},
		"home_1":{"foot":Vector2(2020,1930),"width":750.0,"depth":230.0,"lane":Vector2(2850,1530)},
		"market_book":{"foot":Vector2(3910,1760),"width":840.0,"depth":230.0,"lane":Vector2(4350,2100)},
		"north_guest_w":{"foot":Vector2(4180,2940),"width":500.0,"depth":250.0,"lane":Vector2(4510,3000)},
		"north_office":{"foot":Vector2(3920,1180),"width":850.0,"depth":250.0,"lane":Vector2(4350,2100)},
		"north_guest_e":{"foot":Vector2(5290,1400),"width":1000.0,"depth":260.0,"lane":Vector2(4510,1530)},
		"post_front":{"foot":Vector2(5240,2790),"width":1000.0,"depth":280.0,"lane":Vector2(4510,3000)},
		"post_wing_n":{"foot":Vector2(4850,3510),"width":540.0,"depth":250.0,"lane":Vector2(4510,3600)},
		"workshop_e":{"foot":Vector2(1600,4840),"width":540.0,"depth":230.0,"lane":Vector2(1450,4970)}
	}

static func relocated_npcs() -> Dictionary:
	return {"bianzhou_life_04":{"foot":Vector2(1950,4950),"lane":Vector2(1450,4970)},"bianzhou_life_05":{"foot":Vector2(1900,4770),"lane":Vector2(1450,4970)},"bianzhou_life_13":{"foot":Vector2(2480,1820),"lane":Vector2(2850,1530)},"bianzhou_life_15":{"foot":Vector2(1880,4910),"lane":Vector2(1450,4970)},"bianzhou_life_19":{"foot":Vector2(3310,4020),"lane":Vector2(3270,3790)}}

static func completion_data() -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(COMPLETION))
	return raw if raw is Dictionary else {}

static func completion_specs(kind: String) -> Array[Dictionary]:
	var data: Dictionary=completion_data()
	var rows: Array[Dictionary]=[]
	for raw: Dictionary in data.get("objects",[]):
		if String(raw.kind)!=kind:continue
		var source: Dictionary=data.assets[raw.asset]
		var foot:=Vector2(float(raw.foot[0]),float(raw.foot[1]))
		var origin:=Vector2(float(source.source_foot[0]),float(source.source_foot[1]))
		var scale_factor: float=float(raw.get("native_scale",source.native_scale))
		var box: Array=source.source_bounds
		var source_body:=Rect2(float(box[0]),float(box[1]),float(box[2]),float(box[3]))
		rows.append({"id":raw.id,"texture":source.texture,"foot":foot,"source_foot_px":[origin.x,origin.y],"native_scale":scale_factor,"visible_width":0.0,"source_body_px":source_body,"body":Rect2(foot+(source_body.position-origin)*scale_factor,source_body.size*scale_factor),"migration_lane_foot":Vector2(float(raw.lane[0]),float(raw.lane[1])),"usage":raw.usage})
	return rows

static func completion_occupancy_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	for row: Dictionary in building_specs():
		if relocated_buildings().has(row.id) or row.id=="east_rear_residence":
			if not row.has("migration_lane_foot"):row.migration_lane_foot=Vector2(4510,4200)
			rows.append(row)
	rows.append_array(completion_specs("building"));rows.append_array(completion_specs("prop"))
	for npc: Dictionary in npc_rows():
		if not npc.has("completion_role") and not relocated_npcs().has(npc.npc_id):continue
		rows.append({"id":npc.npc_id,"body":npc_occupancy(npc),"migration_lane_foot":npc.migration_lane_foot})
	var gate: Variant=JSON.parse_string(FileAccess.get_file_as_string(GATE_BINDING))
	if gate is Dictionary:
		for raw: Dictionary in gate.get("blockers",[]):
			if not raw.has("migration_lane_foot"):continue
			var r: Array=raw.rect
			rows.append({"id":raw.id,"body":Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])),"migration_lane_foot":Vector2(float(raw.migration_lane_foot[0]),float(raw.migration_lane_foot[1]))})
	return rows

static func npc_occupancy(row: Dictionary) -> Rect2:
	var foot: Vector2=row.pos*SIZE
	var axis: Vector2=row.get("patrol_axis",Vector2.RIGHT)
	var sweep: Vector2=axis.abs()*float(row.get("patrol_distance",0))
	# All new 160px frames at scale.9 have a 20.16x25.92 body offset17.28
	# below feet. This conservative34x32 envelope also encloses all patrol phases.
	return Rect2(foot-Vector2(17,0)-sweep,Vector2(34,32)+sweep*2)

static func completion_npcs() -> Array[Dictionary]:
	var young: String="res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1_runtime160.png"
	var veteran: String="res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1_runtime160.png"
	var merchant: String="res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
	var carrier: String="res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png"
	var woman: String="res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
	var farmer: String="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"
	var scholar: String="res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png"
	var waiter: String="res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png"
	var smith: String="res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png"
	var rows: Array[Dictionary]=[]
	var stations: Array=[
		["候车旅人","候车旅人",Vector2(4300,4800),woman,"01"],
		["搬运行李的脚夫","货栈脚夫",Vector2(4380,4970),carrier,"01"],
		["行脚商","候车旅人",Vector2(2810,3200),merchant,"02"],
		["茶食伙计","茶食摊主",Vector2(3390,2900),waiter,"02"],
		["驿馆脚夫","驿馆马夫",Vector2(5740,2820),carrier,"03"],
		["驿馆养马人","驿馆马夫",Vector2(4820,3650),farmer,"03"],
		["货栈脚夫","货栈脚夫",Vector2(1260,2860),carrier,"04"],
		["往来货商","候车旅人",Vector2(1270,3610),merchant,"04"],
		["挑水住户","坊巷老住户",Vector2(1180,1510),farmer,"05"],
		["晒衣住户","坊巷老住户",Vector2(2540,1500),woman,"05"],
		["坊巷住户","坊巷老住户",Vector2(1320,1840),farmer,"05"],
		["邻里菜贩","坊巷老住户",Vector2(2600,1790),woman,"05"],
		["金工师傅","修车匠人",Vector2(1190,4750),smith,"06"],
		["木作帮工","修车匠人",Vector2(480,4560),farmer,"06"],
		["送货行商","货栈脚夫",Vector2(2400,4980),merchant,"06"],
		["抱书读榜人","阅榜百姓",Vector2(4050,1960),scholar,"07"],
		["阅榜百姓","阅榜百姓",Vector2(4140,1830),woman,"07"],
		["北街巡卒","候检守卒",Vector2(4300,2250),young,"07"],
		["北门守卒","候检守卒",Vector2(2800,1160),young,"08"],
		["北门老卒","候检守卒",Vector2(3400,1000),veteran,"08"],
		["城外行商","候车旅人",Vector2(3072,460),merchant,"08"],
		["进城乡民","候车旅人",Vector2(3290,340),farmer,"08"]
	]
	for i: int in range(stations.size()):
		var s: Array=stations[i]
		var lane: Vector2={"01":Vector2(3072,4900),"02":Vector2(3072,3200),"03":Vector2(4510,3000),"04":Vector2(1280,3750),"05":Vector2(1450,1530) if s[2].x<1536 else Vector2(2850,1530),"06":Vector2(1450,4970),"07":Vector2(4350,2100),"08":Vector2(3072,650)}[s[4]]
		var row: Dictionary={"npc_id":"bianzhou_life_%02d"%(22+i),"npc_name":s[0],"pos":s[2]/SIZE,"sprite_path":s[3],"interaction_action":"bianzhou_ambient:%s"%s[1],"scale":.9,"portrait_path":"","completion_role":s[1],"district":s[4],"migration_lane_foot":lane}
		if s[3]==farmer:row.portrait_path="res://art/characters/portraits/portrait_linxi_farmer_v1.png"
		if s[3]==scholar:row.portrait_path="res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"
		# Six genuine shipped walk strips; no sliding one-frame worker patrols.
		if i in [2,7,14,17,18,20]:
			row.movement_mode="patrol";row.patrol_axis=Vector2.RIGHT;row.patrol_distance=32.0;row.patrol_speed=18.0
			row.walk_sprite_path="res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png" if s[3]==merchant else "res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png"
		row.protection_body=npc_occupancy(row);rows.append(row)
	return rows

static func ground_patches() -> Array[Dictionary]:
	var data: Dictionary=completion_data()
	var rows: Array[Dictionary]=[]
	for raw: Dictionary in data.get("ground",[]):
		var polygon:=PackedVector2Array()
		for p: Array in raw.polygon:polygon.append(Vector2(float(p[0]),float(p[1])))
		var source_uv:=PackedVector2Array()
		for p: Array in raw.get("source_uv",[]):source_uv.append(Vector2(float(p[0]),float(p[1])))
		rows.append({"id":raw.id,"polygon":polygon,"texture":raw.texture,"period":Vector2(float(raw.period[0]),float(raw.period[1])),"z":int(raw.z),"source_uv":source_uv,"feather_px":float(raw.get("feather_px",0.0))})
	return rows
