extends "res://build/victory_quest_20261108/story_live.gd"

const ELITE = preload("res://scripts/battle/wilderness_elite.gd")
const SCENES = [
	"res://data/scenes/ch1_s1_road.tres",
	"res://data/scenes/ch1_s3_zhuwei_forest.tres",
	"res://data/scenes/ch1_s4_cave_mine_gallery.tres",
	"res://data/scenes/ch1_s4_cave_waterway.tres",
	"res://data/scenes/ch2_s2_forest_edge.tres",
	"res://data/scenes/ch2_s6_river_camp.tres",
	"res://data/scenes/ch4_s5_temple_tunnel.tres",
	"res://data/scenes/ch5_s1_relief_road.tres",
	"res://data/scenes/ch5_s3_snow_pass.tres",
	"res://data/scenes/ch5_s4_abandoned_mine.tres",
	"res://data/scenes/ch6_s4_baishui_convoy_route.tres",
	"res://data/scenes/ch7_s3_lieyun_outpost_outer_ward.tres",
	"res://data/scenes/openworld_bianzhou_old_post.tres",
	"res://data/scenes/openworld_jinling_reed_marsh.tres",
	"res://data/scenes/openworld_v15_bamboo_outskirts.tres",
	"res://data/scenes/openworld_v15_forest_outskirts.tres",
	"res://data/scenes/openworld_v15_marsh_outskirts.tres",
	"res://data/scenes/openworld_xiangzhou_mine_valley.tres",
	"res://data/scenes/openworld_yanmen_pass.tres",
	"res://data/scenes/ch8_s2_mistwood_blockade.tres",
	"res://data/scenes/ch8_s4_alliance_mechanism_gallery.tres",
]
const VALLEY := &"openworld_xiangzhou_mine_valley"
var inventory: Node

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	inventory = root.get_node("Inventory")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	var towns: Script = load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	expect(towns.source_valid(), "native source manifest admits every listed source")
	audit_buildings(towns)
	verify_tables()
	var town := await enter(&"openworld_qinghe_town")
	if town != null:
		await settle(town)
		var qinghe: Script = load("res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd")
		for row in qinghe.building_specs():
			if String(row.texture).contains("linxi_house_variety") or String(row.texture).contains("zhuwei_rebuild"):
				expect(ResourceLoader.exists(row.texture) and row.visible_width>=500.0 and row.body.has_area(), "Qinghe replacement "+String(row.id))
		for p in [Vector2(1180,1690),Vector2(1180,1440),Vector2(1180,1220),Vector2(3000,1440)]:
			check_clear(await position_at(town,p),"Qinghe passage")
		await position_at(town,Vector2(1950,645))
		await process_frame
		get_root().get_texture().get_image().save_png("user://qinghe-houses.png")
	var city := await enter(&"openworld_xiangzhou_city")
	if city != null:
		await settle(city)
		var author: Script = load("res://build/three_settlements_20261030e_system01/xiangzhou_author.gd")
		var changed := 0
		for row in author.building_specs():
			if row.id in ["office_rear_w","office_rear_e","home_back_a","home_back_b","home_back_c","cargo_office","cargo_kitchen"]:
				changed+=1
				expect(float(row.visible_width)>=500 and ResourceLoader.exists(row.texture),"Xiangzhou replacement "+String(row.id))
		expect(changed==7,"seven Xiangzhou buildings updated")
		check_clear(await position_at(city,Vector2(3980,1070)),"Xiangzhou residential approach")
		await position_at(city,Vector2(1230,2745))
		await create_timer(0.35).timeout
		await process_frame
		get_root().get_texture().get_image().save_png("user://xiangzhou-houses.png")
	var valley := await enter(VALLEY)
	if valley != null:
		await settle(valley)
		var origin: Vector2 = valley.get("_player").position
		var three: Array[StringName] = [&"mine_outlaw", &"mine_brute", &"mine_outlaw"]
		expect(router._adapt_authored_group_to_party(three,true).size()==3 and valley.get("_current_scene").encounter_allow_full_group_for_solo, "solo mines keep rolled triple")
		state.player.speed = 1000
		state.player.agility = 180
		state.player.skills.assign([&"basic_attack"])
		var elite_ids: Array[StringName] = [&"wild_elite_mine"]
		router.start_encounter(elite_ids, VALLEY, router.get_current_field_spawn())
		if expect(await wait_for(func():return current_scene != null and current_scene.scene_file_path.contains("battle") and current_scene.get("_state")==1),"elite battle ready"):
			await verify_battle(origin)
	finish()

func audit_buildings(towns: Script) -> void:
	for path in [
		"res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd",
		"res://build/three_settlements_20261030e_system01/xiangzhou_author.gd",
		"res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd",
		"res://build/jinling_city_20261029_system01/city_author.gd",
		"res://build/bianzhou_city_20261028_system01/city_author.gd",
	]:
		var author: Script = load(path)
		if not author.has_method("building_specs"):
			print("BUILDING_AUDIT follow source manually ",path)
			continue
		var repeated := {}
		var small := []
		for row in author.building_specs():
			var texture := String(row.get("texture","")).get_file()
			repeated[texture] = int(repeated.get(texture,0))+1
			var width := float(row.get("visible_width",0))
			if width>0 and width<480:small.append([row.id,width])
		print("BUILDING_AUDIT ",path," repeats=",repeated," width<480=",small)
	for id in [&"openworld_redrock_town", &"openworld_desert_city", &"openworld_lanxi_zhai"]:
		var place: Dictionary = towns.town(id)
		print("BUILDING_AUDIT formal source ",id," ",place.scene)

func verify_tables() -> void:
	var field_script: Script = load("res://scripts/field/field_walkable_controller.gd")
	var field: Node = field_script.new()
	seed(9112026)
	for path in SCENES:
		var scene: SceneScript = load(path)
		field.set("_current_scene",scene)
		var weights := [0.0,0.0,0.0]
		var elite_weight := 0.0
		var ordinary := {}
		for group in scene.encounter_groups:
			var ids: Array = group.enemy_ids
			weights[ids.size()-1] += group.weight
			for id in ids:
				var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
				expect(def!=null and def.level>0 and not def.is_chapter_boss, "ordinary battle definition or standalone elite "+String(id))
				if ELITE.is_elite(id):
					elite_weight += group.weight
					expect(ids.size()==1, "elite group is solo")
				else:
					ordinary[id] = def.level
		expect(weights==[70.0,22.0,8.0] and elite_weight==5.0 and ordinary.size()>=2 and scene.encounter_allow_full_group_for_solo,"encounter table "+path)
	var samples := [0,0,0,0]
	for i in range(10000):
		var group: Array[StringName] = field._pick_random_encounter_group()
		samples[group.size()-1] += 1
		if ELITE.is_elite(group[0]):samples[3]+=1
	print("RANDOM_SAMPLE ",samples)
	expect(abs(samples[0]-7000)<200 and abs(samples[1]-2200)<170 and abs(samples[2]-800)<110 and abs(samples[3]-500)<100,"weighted Godot selector observed")
	field.free()
	for id in ELITE.LOOT:
		var blue := inventory.load_item_by_id(ELITE.equipment_for_roll(id,0.20)) as Equipment
		var purple := inventory.load_item_by_id(ELITE.equipment_for_roll(id,0.19)) as Equipment
		expect(blue!=null and blue.quality==Item.Quality.RARE and purple!=null and purple.quality==Item.Quality.EPIC, "blue and purple equipment for "+String(id))

func verify_battle(origin: Vector2) -> void:
	var battle := current_scene
	var formation: Node = battle.get("formation_view")
	var label: Label = null
	for w in formation.get("status_widgets").values():
		var candidate: Label = w.get_node_or_null("EnemyCaption")
		if candidate!=null:label=candidate
	expect(label!=null and label.text.contains("精英") and label.text.ends_with("级") and label.is_visible_in_tree(),"elite caption visible")
	await process_frame
	get_root().get_texture().get_image().save_png("user://elite-battle.png")
	var enemies: Array = battle.get("_team_enemies")
	if not expect(enemies.size()==1,"one elite in battle"): return
	var enemy: BattleCombatant = enemies[0]
	enemy.stats.hp = 1
	var active: BattleCombatant = battle.get("_team_active_unit")
	var skills: Array = battle._skills_for_stats(active.stats)
	var basic := -1
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack":
			basic=i
			break
	if not expect(basic>=0,"test fighter has normal attack"):return
	for attempt in range(3):
		if not is_instance_valid(battle) or current_scene!=battle:break
		if battle.get("_state")==1:battle._team_player_action_skill_use(basic,enemy.unit_id)
		await wait_for(func():
			return current_scene!=null and (current_scene!=battle or (is_instance_valid(battle) and battle.get("_state")==1))
		,7000)
		if not enemy.alive:break
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",17000),"combat win settles elite"):
		if is_instance_valid(battle):print("BATTLE_DEBUG ",battle.get("battle_log").get_parsed_text())
		return
	expect(state.get_flag(&"defeated_wild_elite_mine",false),"elite victory sets its own defeated flag")
	var count := 0
	for slot in inventory.slots:
		var item: Item = slot.item
		if item!=null and ELITE.LOOT[&"wild_elite_mine"].has(item.item_id):count+=int(slot.count)
	expect(count==1,"one blue or purple piece in inventory")
	var result_label: Label = current_scene.get("reward_label")
	expect(result_label!=null and result_label.text.contains("精英掉落"),"victory panel shows elite gear")
	if result_label!=null:
		print("ELITE_RESULT ",result_label.text)
		current_scene._on_continue_pressed()
		if expect(await wait_for(func():
			return current_scene!=null and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false) and router.get_current_field_id()==VALLEY and not root.get_node("LoadingManager").get("_transition_active")
		),"returns to mine valley after victory"):
			var foot: Vector2 = current_scene.get("_player").position
			expect(foot.distance_to(origin)<3.0,"returns to original encounter foot")
			await settle(current_scene)
			state.player.speed=1000
			state.player.agility=180
			var three: Array[StringName] = [&"mine_outlaw", &"mine_brute", &"mine_outlaw"]
			router.start_encounter(three,VALLEY,router.get_current_field_spawn())
			if expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,18000),"three enemy battle ready"):
				expect(current_scene.get("_team_enemies").size()==3,"solo protagonist faces all three rolled enemies")
				var regular_formation: Node = current_scene.get("formation_view")
				var regular_labels := 0
				for widget in regular_formation.get("status_widgets").values():
					var label_node: Label = widget.get_node_or_null("EnemyCaption")
					if label_node!=null and label_node.text.ends_with("级") and not label_node.text.contains("精英"):
						regular_labels+=1
				expect(regular_labels==3,"all three regular enemies show levels")
