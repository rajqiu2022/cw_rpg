extends RefCounted
## Candidate authorship only. No production route, save, autoload or old source changes.
const ART := "res://build/interior_identity_20261106_art01/"
const MODULE := "res://art/modules/luoyang_assembled_interiors_20261016g/"
const CHARS := "res://art/characters/"
const INN_AUTHOR := "res://data/maps/luoyang_assembled_interiors_20261016g/inn_hall_author.json"
const MANSION_AUTHOR := "res://data/maps/luoyang_assembled_interiors_20261016g/mansion_reception_author.json"
const YIHONG := "yihongyuan27n_interior"
const PREMIUM := "luoyang_market_inn_interior_20261015"
const COMMON := "interior_inn_hall"
const IDS := [YIHONG, PREMIUM, COMMON]
const BODY_HALF := Vector2(17, 12)
const RUG := "res://art/modules/luoyang_quality_20261101b/salon_rug_v1.png"
const HERO := CHARS + "hero_idle_down_25d_runtime_4f.png"
const FONT := "res://art/fonts/LXGWWenKaiLite-Regular.ttf"

static func _p(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

static func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func _poly(rows: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point: Array in rows:
		points.append(_p(point))
	return points

static func _donor(path: String, id: String, foot: Vector2, scale_override: float = 0.0) -> Dictionary:
	var author: Dictionary = _json(path)
	for item: Dictionary in author.furniture:
		if item.id != id:
			continue
		if FileAccess.get_sha256(item.texture) != item.source_sha256:
			return {}
		var ratio := scale_override if scale_override > 0.0 else float(item.render_scale)
		var origin := foot - _p(item.source_ground_anchor_px) * ratio
		var solids: Array[PackedVector2Array] = []
		for raw: Array in item.source_ground_solid_polygons_px:
			var poly := PackedVector2Array()
			for point: Array in raw:
				poly.append(origin + _p(point) * ratio)
			solids.append(poly)
		return {"donor_id": id, "texture": item.texture, "origin": origin, "scale": ratio, "foot": foot, "solids": solids}
	return {}

static func _inn(suffix: String, foot: Vector2, ratio: float = 0.0) -> Dictionary:
	return _donor(INN_AUTHOR, "inn_hall_" + suffix, foot, ratio)

static func _mansion(suffix: String, foot: Vector2, ratio: float = 0.0) -> Dictionary:
	return _donor(MANSION_AUTHOR, "mansion_reception_" + suffix, foot, ratio)

static func _actor(id: String, name: String, texture: String, foot: Vector2, height: float, frames: int = 4) -> Dictionary:
	return {"id": id, "name": name, "texture": texture, "foot": foot, "height": height, "frames": frames}

static func _new_actor(rows: Array, role: String, name: String, foot: Vector2, height: float) -> Dictionary:
	for row: Dictionary in rows:
		if row.role != role:
			continue
		var path := ART + "processed/" + role + "_idle_native_candidate.png"
		if FileAccess.get_sha256(path) != row.candidate_sha256:
			return {}
		var actor := _actor("yihongyuan27n_" + role, name, path, foot, height)
		actor["cell"] = _p(row.cell)
		actor["cell_foot"] = _p(row.cell_foot)
		actor["native_height"] = float(row.body_height)
		actor["movement_mode"] = "seated" if role == "musician" else "idle"
		actor["idle_frame_seconds"] = 1.8 if role == "musician" else 1.4
		return actor
	return {}

static func compose_room(id: String) -> Dictionary:
	if id not in IDS:
		return {}
	var room: Dictionary = {"id": id, "size": Vector2(1536, 1024), "shell_ratio": 1.0, "shell_origin": Vector2(-64,-64), "exit": Vector2(768, 920)}
	var furnishing: Array[Dictionary] = []
	var people: Array[Dictionary] = []
	var floor_points: Array = []
	var art_role := ""
	match id:
		YIHONG:
			art_role = "yihongyuan_luxury_shell"
			room["name"] = "怡红院 · 接待厅与雅座"
			room["entry"] = Vector2(768, 850)
			room["counter_approach"] = Vector2(1150, 586)
			room["return_id"] = "luoyang_civic_market_region_27d"
			room["return_foot"] = Vector2(5206.18, 4280)
			room["flat_rug"] = Rect2(428, 475, 288, 127)
			floor_points = [[244, 420], [1292,420], [1410,817], [889,817], [889,955], [647,955], [647,817], [126,817]]
			furnishing = [_inn("inn_counter_0",Vector2(1160,560)), _inn("dining_table_2",Vector2(310,628)), _inn("dining_table_4",Vector2(1070,740)), _mansion("wood_armchair_5",Vector2(1250,777),0.11), _mansion("writing_desk_4",Vector2(900,512),0.13)]
			var prior: Dictionary = _json("res://build/luoyang_yihongyuan_20261029n_art01/asset_and_layout_spec.json")
			var keys := ["matron","waiter","merchant","scholar","elder_guest","woman_guest"]
			for index: int in range(keys.size()):
				var old: Dictionary = prior.npcs[index]
				var foot := _p(old.foot_px)
				match index:
					0: foot = Vector2(1150,520)
					2: foot = Vector2(485,774)
					3: foot = Vector2(659,479)
					4: foot = Vector2(310,694)
				var row := _actor("yihongyuan27n_" + keys[index],old.role,old.sprite,foot,93.0 if index >= 4 else 120.0,int(old.frames))
				row["old_dialogue"] = old.dialogue
				row["old_portrait"] = old.portrait
				people.append(row)
			var women: Array = _json(ART + "women_processing_receipt.json")
			people.append(_new_actor(women,"musician","琵琶乐师",Vector2(481,558),96.0))
			people.append(_new_actor(women,"singer","清曲歌者",Vector2(592,565),121.0))
			people.append(_new_actor(women,"tea_attendant","侍茶姑娘",Vector2(602,702),116.0))
			people.append(_new_actor(women,"receptionist","迎客姑娘",Vector2(956,794),122.0))
		PREMIUM:
			art_role = "inn_premium_shell"
			room["name"] = "洛阳 · 客栈大厅"
			room["entry"] = Vector2(768, 840)
			room["counter_approach"] = Vector2(1160, 592)
			room["service_contract"] = {"meal_gold": 5, "meal_recovery": 0.25, "rest_gold": 20, "rest_recovery": 1.0}
			floor_points = [[248,467],[1292,467],[1401,818],[889,818],[889,951],[647,951],[647,818],[126,818]]
			furnishing = [_inn("inn_counter_0",Vector2(1160,560)), _inn("dining_table_2",Vector2(421,612),0.17), _mansion("wood_armchair_1",Vector2(340,687),0.12), _mansion("wood_armchair_5",Vector2(505,689),0.12), _mansion("folding_screen_6",Vector2(1271,728),0.18), _inn("dining_table_4",Vector2(1080,756),0.16), _mansion("ceremonial_desk_0",Vector2(610,518),0.12)]
			people = [_actor("innkeeper_preview","客栈掌柜",CHARS+"npc_zhuwei_innkeeper_v1_idle_down_25d_4f.png",Vector2(1150,521),121.0), _actor("waiter_preview","店小二",CHARS+"npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png",Vector2(872,613),119.0)]
		COMMON:
			art_role = "inn_common_shell"
			room["name"] = "清风镇 · 客栈大堂"
			room["entry"] = Vector2(768, 604.16)
			room["exit"] = Vector2(768, 814.08)
			room["counter_approach"] = Vector2(684, 557)
			room["return_id"] = "ch1_s2_qingfeng"
			room["return_uv"] = Vector2(0.31,0.54)
			room["ledger"] = Vector2(729.6,558.08)
			room["shell_ratio"] = 0.9
			# Preserve the exact world exit. Draw the native doorway on it
			# uniformly, rather than pulling the portal up from a closed wall.
			room["shell_origin"] = Vector2(76.8,-35) - Vector2(64,64) * 0.9
			floor_points = [[307,348],[1233,348],[1348,705],[869,705],[869,831],[667,831],[667,705],[193,705]]
			furnishing = [_inn("inn_counter_0",Vector2(529,529),0.19), _inn("dining_table_2",Vector2(468,623),0.15), _inn("dining_table_4",Vector2(1050,628),0.15), _inn("long_bench_3",Vector2(432,678),0.09), _inn("long_bench_5",Vector2(1000,682),0.09), _inn("wine_tea_shelf_1",Vector2(1080,426),0.13)]
			var common := load("res://data/scenes/interior_inn_hall.tres") as Resource
			var feet := [Vector2(478,485),Vector2(850,634),Vector2(535,671),Vector2(1135,675)]
			var old_npcs: Array = common.get("npcs")
			for index: int in range(old_npcs.size()):
				var old: Dictionary = old_npcs[index]
				var row := _actor(old.npc_id,old.npc_name,old.sprite_path,feet[index],93.0 if index >= 2 else 118.0)
				row["dialog_id"] = old.dialog_id
				row["movement_mode"] = old.get("movement_mode","idle")
				people.append(row)
	var shells: Array = _json(ART + "shell_processing_receipt.json")
	for row: Dictionary in shells:
		if row.role != art_role: continue
		var path := ART + "processed/" + art_role + "_native_padded64.png"
		if FileAccess.get_sha256(path) != row.candidate_sha256:
			return {}
		room["shell"] = path
	room["floor"] = _poly(floor_points)
	room["furniture"] = furnishing
	room["actors"] = people
	return room

static func safe(room: Dictionary, foot: Vector2, half: Vector2 = BODY_HALF) -> bool:
	var shape := PackedVector2Array([foot-half,foot+Vector2(half.x,-half.y),foot+half,foot+Vector2(-half.x,half.y)])
	for point: Vector2 in shape:
		if not Geometry2D.is_point_in_polygon(point,room.floor):
			return false
	for item: Dictionary in room.furniture:
		if item.is_empty(): return false
		for solid: PackedVector2Array in item.solids:
			if not Geometry2D.intersect_polygons(shape,solid).is_empty():
				return false
	return true

static func safe_segment(room: Dictionary, start: Vector2, finish: Vector2) -> bool:
	var steps := maxi(1,ceili(start.distance_to(finish)/4.0))
	for index: int in range(steps+1):
		if not safe(room,start.lerp(finish,float(index)/steps)):
			return false
	return true
