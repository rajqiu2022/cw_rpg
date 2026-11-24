extends RefCounted
## Finite 11 bidirectional street relations. All coordinates are actual local feet.
const SELF := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const SCHEMA := "CITY_NAVIGATION_PAIRED_MARKERS_20261101D_V1"
const REGION_FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const MAIN_FIELD := "res://scripts/field/field_walkable_controller.gd"

static func endpoint(scene: String, logical: String, portal: String, mouth: Vector2, arrival: Vector2, outward: Vector2, retired: Array) -> Dictionary:
 return {"scene_id":scene,"logical_id":logical,"source_portal":portal,"mouth":mouth,"arrival":arrival,"outward":outward,"retired_feet":retired,"activation_size":Vector2(128,80) if outward.y != 0 else Vector2(80,128),"lane_width":80.0}

static func relations() -> Array[Dictionary]:
 var rows: Array[Dictionary] = []
 rows.append({"pair_id":"market_artisan","label":"南市—百工民坊","a":endpoint("luoyang_civic_market_region_27d","ch4_s3_luoyang_market","market_to_artisan",Vector2(1632,4470),Vector2(1632,4366),Vector2(0,1),[Vector2(1700,4560)]),"b":endpoint("luoyang_artisan_residential_20261022ap","luoyang_artisan_residential_20261022ap","artisan_to_market",Vector2(2816,180),Vector2(2816,284),Vector2(0,-1),[Vector2(2816,1740)])})
 rows.append({"pair_id":"yamen_artisan","label":"府衙—百工民坊","a":endpoint("luoyang_civic_market_region_27d","ch4_s1_luoyang_yamen","finish_i_yamen_to_artisan",Vector2(720,840),Vector2(824,840),Vector2(-1,0),[Vector2(720,970)]),"b":endpoint("luoyang_artisan_residential_20261022ap","luoyang_artisan_residential_20261022ap","finish_i_artisan_to_yamen",Vector2(2910,1300),Vector2(2806,1300),Vector2(1,0),[Vector2(128,1300)])})
 rows.append({"pair_id":"market_temple","label":"南市—城外古寺","a":endpoint("luoyang_civic_market_region_27d","ch4_s3_luoyang_market","to_ancient_temple",Vector2(3072,4470),Vector2(3072,4366),Vector2(0,1),[Vector2(3072,4510)]),"b":endpoint("luoyang_temple_region_27d","ch4_s4_ancient_temple","legacy_portal_6",Vector2(1536,200),Vector2(1536,304),Vector2(0,-1),[Vector2(680,4380)])})
 rows.append({"pair_id":"docks_temple","label":"码头—城外古寺","a":endpoint("ch4_s2_canal_docks","ch4_s2_canal_docks","canal_world_ferry",Vector2(260,180),Vector2(260,284),Vector2(0,-1),[Vector2(2140,1840)]),"b":endpoint("luoyang_temple_region_27d","ch4_s4_ancient_temple","legacy_portal_7",Vector2(2390,4380),Vector2(2390,4276),Vector2(0,1),[Vector2(2390,4380)])})
 rows.append({"pair_id":"market_estate","label":"南市—豪宅庭院","a":endpoint("luoyang_civic_market_region_27d","ch4_s3_luoyang_market","am_market_estate_alley",Vector2(5800,2350),Vector2(5800,2454),Vector2(0,-1),[Vector2(5800,4560)]),"b":endpoint("luoyang_estate_region_27d","luoyang_estate_riverside_20261021ai","estate_return_market",Vector2(1536,3890),Vector2(1536,3786),Vector2(0,1),[Vector2(1536,3890)])})
 rows.append({"pair_id":"estate_garden","label":"宅园—洛水园林","a":endpoint("luoyang_estate_region_27d","luoyang_estate_riverside_20261021ai","estate_to_garden",Vector2(2910,3700),Vector2(2806,3700),Vector2(1,0),[Vector2(2910,3700)]),"b":endpoint("luoyang_riverside_garden_20261022ap","luoyang_riverside_garden_20261022ap","garden_to_estate",Vector2(256,1680),Vector2(360,1680),Vector2(-1,0),[Vector2(256,1680)])})
 rows.append({"pair_id":"docks_garden","label":"码头—洛水园林","a":endpoint("ch4_s2_canal_docks","ch4_s2_canal_docks","docks_to_garden",Vector2(96,1216),Vector2(200,1216),Vector2(-1,0),[Vector2(512,1840)]),"b":endpoint("luoyang_riverside_garden_20261022ap","luoyang_riverside_garden_20261022ap","garden_to_docks",Vector2(2816,1740),Vector2(2712,1740),Vector2(1,0),[Vector2(2816,1740)])})
 rows.append({"pair_id":"temple_riverside","label":"古寺—岸驿曲径","a":endpoint("luoyang_temple_region_27d","ch4_s4_ancient_temple","luoyang_temple_riverside_connector",Vector2(900,200),Vector2(900,304),Vector2(0,-1),[Vector2(900,3560)]),"b":endpoint("adventure_luoyang_riverside_route","adventure_luoyang_riverside_route","luoyang_riverside_return_temple",Vector2(2048,2856),Vector2(2048,2752),Vector2(0,1),[Vector2(2048,2856.96)])})
 rows.append({"pair_id":"gate_civic","label":"南城门—府衙街","a":endpoint("ch4_s0_luoyang_gate","ch4_s0_luoyang_gate","enter_luoyang",Vector2(1536,500),Vector2(1536,604),Vector2(0,-1),[Vector2(1536,500)]),"b":endpoint("luoyang_civic_market_region_27d","ch4_s1_luoyang_yamen","to_city_gate",Vector2(1000,2110),Vector2(1000,2006),Vector2(0,1),[Vector2(720,2090),Vector2(500,3270)])})
 rows.append({"pair_id":"yamen_docks","label":"府衙—漕渠码头","a":endpoint("luoyang_civic_market_region_27d","ch4_s1_luoyang_yamen","to_canal_quay",Vector2(5500,2110),Vector2(5396,2110),Vector2(1,0),[Vector2(5500,2110)]),"b":endpoint("ch4_s2_canal_docks","ch4_s2_canal_docks","to_yamen_square",Vector2(200,850),Vector2(304,850),Vector2(-1,0),[Vector2(260,790)])})
 rows.append({"pair_id":"market_docks","label":"南市—漕渠码头","a":endpoint("luoyang_civic_market_region_27d","ch4_s3_luoyang_market","to_canal_docks",Vector2(5960,3000),Vector2(5856,3000),Vector2(1,0),[Vector2(5960,3000)]),"b":endpoint("ch4_s2_canal_docks","ch4_s2_canal_docks","to_south_market",Vector2(260,1740),Vector2(364,1740),Vector2(-1,0),[Vector2(260,1740)])})
 return rows

static func endpoints(scene_id: String) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for pair: Dictionary in relations():
  for side: String in ["a","b"]:
   if pair[side].scene_id != scene_id: continue
   var value: Dictionary = pair[side].duplicate(true)
   value["pair_id"] = pair.pair_id
   value["label"] = pair.label
   value["target"] = pair["b" if side == "a" else "a"].duplicate(true)
   value["kind"] = "area_exit"
   value["id"] = "citynav/" + pair.pair_id + "/" + side
   value["side"] = side
   result.append(value)
 return result

static func area_ids() -> Array[String]:
 var result: Array[String] = []
 for pair: Dictionary in relations():
  for side: String in ["a","b"]:
   for key: String in ["scene_id","logical_id"]:
    var id: String = pair[side][key]
    if not result.has(id): result.append(id)
 return result

static func room_ids() -> Array[String]:
 return ["estate27d_living_hall","estate27d_west_study","estate27d_east_bedroom","temple27d_main_hall","temple27d_monks_room","temple27d_sutra_room","yihongyuan27n_interior","luoyang_yamen_official_hall_20261018t","luoyang_market_inn_interior_20261015","luoyang_market_shop_interior_20261015","luoyang_market_north_market_front_interior_20261015","luoyang_market_market_east_ward_frontage_interior_20261015","luoyang_market_market_northeast_rear_frontage_interior_20261015","luoyang_functional_pawnshop_candidate_20261016","luoyang_market_market_west_ward_frontage_interior_20261015"]

static func source_paths() -> Array[String]:
 return [SELF]

static func destination_name(id: String) -> String:
 var names: Dictionary = {"ch4_s0_luoyang_gate":"南城门","ch4_s1_luoyang_yamen":"府衙街","ch4_s3_luoyang_market":"南市","ch4_s2_canal_docks":"漕渠码头","ch4_s4_ancient_temple":"城外古寺","luoyang_artisan_residential_20261022ap":"百工民坊","luoyang_estate_riverside_20261021ai":"宅园","luoyang_riverside_garden_20261022ap":"洛水园林","adventure_luoyang_riverside_route":"岸驿曲径"}
 return String(names.get(id,id))
