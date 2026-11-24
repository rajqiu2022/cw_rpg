extends "res://scripts/autoload/bounty_manager.gd"
## Same save namespace and bounty ids; only approved new cases and post-battle handoff are added.

const STATUS_EVIDENCE := &"evidence"
const STATUS_DECISION := &"decision"
const OFFICE_ACTION := "warrant_office_"
const DECISION_ACTION := "warrant_decide_"
const COUNTY_BOARDS := {
	&"qinghe": {"scene":&"openworld_qinghe_town","office":&"xiangzhou","name":"清河镇缉捕榜","foot":Vector2(2210,2810),"depth":8.0},
	&"redrock": {"scene":&"openworld_redrock_town","office":&"bianzhou","name":"赤岩镇缉捕榜","foot":Vector2(2450,4350),"depth":4.0},
}
const COUNTY_BOARD_ART := preload("res://art/maps/luoyang_modular_v3/source/notice_pavilion_v2.png")
const FALSE_CASES := {
	&"bianzhou_wronged_ferryman": {
		"companion": &"warrant_ferryman_hei", "penalty": 8,
		"testimony": "我是把沉船里的两个人拖上岸，没劫粮。渡口急救的登记有两人画押；你再看这张榜，告我的正是偷卖官粮的仓吏。我的铜渡牌他们认得。若你肯让我换身衣裳离开，就拿牌去交差吧。",
	},
	&"jinling_wronged_escort": {
		"companion": &"warrant_escort_luo", "penalty": 12,
		"testimony": "我替盐船上的脚夫讨工钱，才被写成劫船人。你看这册，有船东自己的押印，也有我把那笔钱逐一发下去的收据。我这块镖局牌还在榜上。若信得过我，我换件短褂，把腰牌留给你。",
	},
}
# The equipment belongs to the fugitive, not to the clerk's reward fund.
const FIELD_LOOT := {
	&"bianzhou_black_wolf": &"iron_staff", &"bianzhou_flying_rope": &"deer_leather_boots",
	&"bianzhou_roaming_thief": &"iron_sword", &"jinling_ink_hand": &"qingming_sword",
	&"jinling_night_kite": &"wind_walker_boots", &"jinling_water_ghost": &"silver_moon_needle",
	&"luoyang_case_robber": &"iron_sword", &"luoyang_red_scar": &"deer_leather_boots",
	&"luoyang_seal_thief": &"sharp_steel_sword", &"xiangzhou_mine_jackal": &"dragon_tendon_staff",
	&"xiangzhou_mine_stamp": &"deer_leather_boots", &"xiangzhou_white_deer": &"tiger_roar_blade",
	&"qinghe_quay_thief": &"deer_leather_boots", &"qinghe_coal_robber": &"iron_staff",
	&"redrock_caravan_cutpurse": &"iron_sword", &"redrock_false_courier": &"deer_leather_boots",
}
const OFFICES := {
	&"luoyang": [&"luoyang_yamen_official_hall_20261018t",Vector2(0.56,0.8515625),"洛阳府衙正堂", "洛阳府推官"],
	&"bianzhou": [&"openworld_bianzhou_city",Vector2(3720,2020)/6144.0,"汴州北街榜亭旁的府衙验缴处","汴州府巡检"],
	&"xiangzhou": [&"openworld_xiangzhou_city",Vector2(3290,1700)/Vector2(5632,4096),"襄州校场榜亭旁的江防府验缴处","襄州江防判官"],
	&"jinling": [&"openworld_jinling_city",Vector2(4900,1990)/Vector2(5632,4096),"金陵东桥榜亭旁的府衙验缴处","金陵府推官"],
}
const OFFICER_ART := "res://art/characters/pc_hd_20261102c/paper_scholar_idle_native_20261106b02.png"

func office_city_for_board(board_id: StringName) -> StringName:
	return StringName(COUNTY_BOARDS.get(board_id,{}).get("office",board_id))

func office_label_for_board(board_id: StringName) -> String:
	var office: Array = OFFICES.get(office_city_for_board(board_id),[])
	return String(office[2]) if not office.is_empty() else ""

func _county_board_id(scene_id: StringName) -> StringName:
	for id: StringName in COUNTY_BOARDS:
		if COUNTY_BOARDS[id].scene==scene_id: return id
	return &""

func attach_county_board(world: Node2D, scene_id: StringName) -> void:
	var id := _county_board_id(scene_id)
	if id==&"" or world.get_node_or_null("CountyBountyNotice")!=null: return
	var row: Dictionary = COUNTY_BOARDS[id]
	var notice := StaticBody2D.new()
	notice.name="CountyBountyNotice"
	notice.position=row.foot
	notice.collision_layer=1
	notice.collision_mask=0
	world.add_child(notice)
	var art := Sprite2D.new()
	art.texture=COUNTY_BOARD_ART
	art.centered=false
	art.position=-Vector2(768.5,969)*0.18
	art.scale=Vector2.ONE*0.18
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	art.z_as_relative=false
	art.z_index=floori(float(row.foot.y)/float(row.depth))
	notice.add_child(art)
	var footprint := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size=Vector2(170,32)
	footprint.shape=rectangle
	footprint.position=Vector2(0,-16)
	notice.add_child(footprint)
	var title := Label.new()
	title.text="缉捕榜"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.position=Vector2(-110,-202)
	title.size=Vector2(220,36)
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("f3d59a"))
	title.add_theme_color_override("font_outline_color",Color("181209"))
	title.add_theme_constant_override("outline_size",7)
	title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title.z_as_relative=false
	title.z_index=2049
	notice.add_child(title)

func try_county_board(world: Node2D, player: Player, scene_id: StringName, map_size: Vector2) -> bool:
	var id := _county_board_id(scene_id)
	if id==&"" or SceneRouter.get_current_field_id()!=scene_id: return false
	var notice := world.get_node_or_null("CountyBountyNotice") as Node2D
	if notice==null or not is_instance_valid(player) or not player.can_move: return false
	var local_foot := notice.to_local(player.global_position)
	if absf(local_foot.x)>140.0 or local_foot.y < 0.0 or local_foot.y > 120.0: return false
	SceneRouter.set_field_return_spawn(world.to_local(player.global_position)/map_size)
	# Some native town hosts mark the key handled after this call.
	SceneRouter.go_bounty_board.call_deferred(id)
	return true

func _board_day() -> int:
	return floori(Time.get_unix_time_from_system()/86400.0)

func _board_pool(city: StringName) -> Array[BountyDef]:
	var pool: Array[BountyDef] = []
	for def: BountyDef in _definitions.values():
		if def.board_city==city and not def.locations.is_empty():
			pool.append(def)
	pool.sort_custom(func(a: BountyDef,b: BountyDef) -> bool:return String(a.bounty_id)<String(b.bounty_id))
	return pool

func get_board_entries(city_id: StringName) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var available: Array[BountyDef] = []
	var pool := _board_pool(city_id)
	if pool.is_empty():
		return entries
	var day := _board_day()
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s:%d" % [city_id,day]).hash()
	for i in range(pool.size()-1,0,-1):
		var other := rng.randi_range(0,i)
		var previous := pool[i]
		pool[i] = pool[other]
		pool[other] = previous
	for def in pool:
		var row := _state_for(def.bounty_id)
		var status := StringName(row.get("status",STATUS_AVAILABLE))
		if status in [STATUS_ACTIVE,STATUS_EVIDENCE,STATUS_DECISION]:
			entries.append(_board_entry(def,row))
		elif status!=STATUS_CAPTURED or (not FALSE_CASES.has(def.bounty_id) and int(row.get("filed_day",-1))<day):
			available.append(def)
	for i in range(mini(maxi(0,2-entries.size()),available.size())):
		entries.append(_board_entry(available[i],{"status":STATUS_AVAILABLE}))
	return entries

func _board_entry(def: BountyDef,row: Dictionary) -> Dictionary:
	var status := StringName(row.get("status",STATUS_AVAILABLE))
	var office_label := office_label_for_board(def.board_city)
	return {
		"bounty_id":def.bounty_id,"display_name":def.display_name,"title":def.title,"description":def.description,
		"level_text":"%d～%d级"%[def.recommended_min_level,def.recommended_max_level],
		"reward_text":("赏银 +%d（声望不增加）"%def.reward_gold) if _closed_quietly(row) else ("赏银 +%d　声望 +%d"%[def.reward_gold,def.reward_reputation]),
		"status":status,
		"location_label":office_label if status==STATUS_EVIDENCE else _active_location_label(def,row),
	}

func accept_bounty(bounty_id: StringName) -> Dictionary:
	var def := get_definition(bounty_id)
	if def==null:return {"ok":false,"message":"榜文已经撤下。"}
	for entry in get_board_entries(def.board_city):
		if entry.bounty_id!=bounty_id or entry.status!=STATUS_AVAILABLE:continue
		var row := _state_for(bounty_id)
		# Carry historical completions forward, but start a fresh evidence cycle.
		row.status=STATUS_AVAILABLE
		row.escape_count=0
		row.erase("inventory_evidence")
		row.erase("sealed_evidence")
		row.erase("disposition")
		row.erase("gear_at_battle")
		_states[String(bounty_id)]=row
		return super.accept_bounty(bounty_id)
	return {"ok":false,"message":"此榜今日未张贴，或尚有待办。"}

func _pick_location_index(def: BountyDef,previous: int) -> int:
	var available: Array[int] = []
	var unoccupied: Array[int] = []
	for i in range(def.locations.size()):
		if i==previous: continue
		var location := def.locations[i]
		var scene := StringName(location.get("scene_id",&""))
		# Do not send early-game players into a later chapter's gated route.
		if scene==&"ch4_s0_luoyang_gate" and (def.board_city!=&"luoyang" or GameState.get_flag(&"luoyang_case_found_clue",false)!=true): continue
		if scene==&"ch7_s1_lieyun_valley_ferry" and GameState.current_chapter<7: continue
		if scene==&"interior_bandit_cave" and GameState.get_flag(&"defeated_linxi_wild_beast",false)!=true: continue
		available.append(i)
		var occupied := false
		for other_def: BountyDef in _definitions.values():
			if other_def.bounty_id==def.bounty_id: continue
			var other := _state_for(other_def.bounty_id)
			if other.status not in [STATUS_ACTIVE, STATUS_DECISION]: continue
			var hideout := _location_for(other_def,int(other.location_index))
			if hideout.get("scene_id")!=scene: continue
			var pos: Vector2 = location.pos
			if pos.distance_to(hideout.pos)<0.05:
				occupied=true
				break
		if not occupied: unoccupied.append(i)
	if not unoccupied.is_empty(): return unoccupied.pick_random()
	if not available.is_empty(): return available.pick_random()
	return previous if previous>=0 else super._pick_location_index(def,previous)

func get_scene_npcs(scene_id: StringName) -> Array[Dictionary]:
	var npcs := super.get_scene_npcs(scene_id)
	for id: StringName in FALSE_CASES:
		var row := _state_for(id)
		if row.status != STATUS_DECISION: continue
		var def := get_definition(id)
		var location := _location_for(def,int(row.get("location_index",-1)))
		if location.get("scene_id") != scene_id: continue
		npcs.append({"npc_id":"bounty_"+String(id),"npc_name":def.display_name,"pos":location.pos,
			"sprite_path":def.field_sprite_path,"scale":def.field_sprite_scale,
			"interaction_action":"bounty_battle:"+String(id)})
	for city: StringName in OFFICES:
		var office: Array = OFFICES[city]
		if office[0]!=scene_id:continue
		npcs.append({"npc_id":OFFICE_ACTION+String(city),"npc_name":office[3],"pos":office[1],
			"sprite_path":OFFICER_ART,"scale":0.91,
			"interaction_action":"bounty_battle:"+OFFICE_ACTION+String(city)})
	return npcs

func start_bounty(bounty_id: StringName) -> bool:
	var action := String(bounty_id)
	if action.begins_with(DECISION_ACTION):
		var args := action.trim_prefix(DECISION_ACTION).split("/")
		if args.size()!=2: return false
		return _settle_decision(StringName(args[0]),StringName(args[1]))
	if action.begins_with(OFFICE_ACTION):
		var city := StringName(action.trim_prefix(OFFICE_ACTION))
		if not _at_office(city) or DialogPlayer.is_playing():return false
		_show_officer_reply(city,_file_city_cases(city))
		return true
	var def := get_definition(bounty_id)
	var row := _state_for(bounty_id)
	if def==null or StringName(_location_for(def,int(row.get("location_index",-1))).get("scene_id",&""))!=SceneRouter.get_current_field_id():
		return false
	if row.status == STATUS_DECISION:
		return _show_decision(def)
	return super.start_bounty(bounty_id)

func resolve_victory(bounty_id: StringName) -> Dictionary:
	var def := get_definition(bounty_id)
	var row := _state_for(bounty_id)
	if def==null or row.status!=STATUS_ACTIVE or not OFFICES.has(office_city_for_board(def.board_city)):return {}
	if FALSE_CASES.has(bounty_id):
		row.status=STATUS_DECISION
		_states[String(bounty_id)]=row
		return {"title":"胜负已分 · "+def.display_name,"summary":"对方收了兵刃，说榜上的事另有隐情。返回后听听他的说法。",
			"return_action":"bounty_battle:"+String(bounty_id)}
	var result := _secure_evidence(def,row)
	var loot_id := StringName(FIELD_LOOT.get(bounty_id,&""))
	if not result.is_empty() and loot_id!=&"" and Inventory.load_item_by_id(loot_id)!=null:
		row.gear_at_battle=loot_id
		_states[String(bounty_id)]=row
		var added := Inventory.slots.size()<Inventory.MAX_SLOTS and Inventory.add_item(loot_id,1)
		result.item_drops.append({"item_id":loot_id,"count":1 if added else 0,"uncollected":0 if added else 1})
	return result

func _secure_evidence(def: BountyDef,row: Dictionary) -> Dictionary:
	var bounty_id := def.bounty_id
	var item_id := _evidence_id(bounty_id)
	var evidence := Inventory.load_item_by_id(item_id)
	if evidence==null:return {}
	row.status=STATUS_EVIDENCE
	row.inventory_evidence=Inventory.slots.size()<Inventory.MAX_SLOTS and Inventory.add_item(item_id,1)
	row.sealed_evidence=not row.inventory_evidence
	_states[String(bounty_id)]=row
	var storage := "物证已入背包。" if row.inventory_evidence else "背包已满，物证暂封在随身案袋。"
	return {"title":"追捕告捷 · "+def.display_name,
		"item_drops":[{"item_id":item_id,"count":1}] if row.inventory_evidence else [],
		"summary":"取得「%s」。%s\n带到%s交验，方可领取%s。"%[evidence.display_name,storage,office_label_for_board(def.board_city),
			"赏金" if _closed_quietly(row) else "赏金与声望"]}

func _show_decision(def: BountyDef) -> bool:
	if DialogPlayer.is_playing(): return false
	var script := DialogScript.new()
	script.dialog_id = StringName("warrant_testimony_"+String(def.bounty_id))
	var line := DialogNode.new()
	line.node_id = &"start"
	line.speaker = def.display_name
	line.text = FALSE_CASES[def.bounty_id].testimony
	var prefix := "bounty_battle:"+DECISION_ACTION+String(def.bounty_id)+"/"
	var penalty := int(FALSE_CASES[def.bounty_id].penalty)
	line.choices.assign([
		{"text":"照榜交人（验缴后增加声望）","action":prefix+"custody"},
		{"text":"放他乔装离开（声望 −%d）"%penalty,"action":prefix+"spare"},
		{"text":"邀他乔装入队（声望 −%d）"%penalty,"action":prefix+"recruit"},
	])
	script.nodes.assign([line])
	DialogPlayer.play(script)
	return true

func _settle_decision(id: StringName,disposition: StringName) -> bool:
	var def := get_definition(id)
	var row := _state_for(id)
	if def==null or not FALSE_CASES.has(id) or row.status!=STATUS_DECISION: return false
	var scene: StringName = _location_for(def,int(row.get("location_index",-1))).get("scene_id",&"")
	if scene!=SceneRouter.get_current_field_id() or disposition not in [&"custody",&"spare",&"recruit"]: return false
	if Inventory.load_item_by_id(_evidence_id(id))==null: return false
	var case_data: Dictionary = FALSE_CASES[id]
	if disposition==&"recruit" and not GameState.add_companion(case_data.companion):
		EventBus.toast_requested.emit("暂时不能入队，仍可选择让他乔装离开。")
		return _show_decision(def)
	row.disposition=disposition
	var result := _secure_evidence(def,row)
	var reply := String(result.get("summary",""))
	if disposition!=&"custody":
		GameState.add_reputation(-int(case_data.penalty))
		reply = "他换了装束，把随身信物交给你。\n凭信物交差可领赏银，不增加声望。"
	else:
		reply = "你将他交给附近巡差，留下随身信物。\n"+reply
	EventBus.toast_requested.emit(reply)
	var field := get_tree().current_scene
	if field!=null and field.has_method("_on_player_interacted"):
		var npcs: Array = field.get("_npc_nodes")
		for npc: NPCNode in npcs:
			if is_instance_valid(npc) and npc.npc_id=="bounty_"+String(id):
				npcs.erase(npc)
				npc.queue_free()
				break
	return true

func _evidence_id(bounty_id: StringName) -> StringName:
	return StringName("warrant_evidence_"+String(bounty_id))

func _at_office(city: StringName) -> bool:
	return OFFICES.has(city) and SceneRouter.get_current_field_id()==OFFICES[city][0]

func _file_city_cases(city: StringName) -> String:
	if not _at_office(city):return "此案须回发榜的府衙验缴。"
	var replies := PackedStringArray()
	var cases := _board_pool(city)
	for board_id: StringName in COUNTY_BOARDS:
		if office_city_for_board(board_id)==city:
			cases.append_array(_board_pool(board_id))
	for def in cases:
		var row := _state_for(def.bounty_id)
		if row.status!=STATUS_EVIDENCE:continue
		var key := _evidence_id(def.bounty_id)
		var in_pack := bool(row.get("inventory_evidence",false))
		if (in_pack and Inventory.count_of(key)<1) or (not in_pack and not bool(row.get("sealed_evidence",false))):
			replies.append("「%s」缺少对应物证，暂不能结案。"%def.display_name)
			continue
		if in_pack and not Inventory.remove_item(key,1):continue
		row.status=STATUS_CAPTURED
		row.filed_day=_board_day()
		row.completion_count=int(row.get("completion_count",0))+1
		row.erase("inventory_evidence")
		row.erase("sealed_evidence")
		_states[String(def.bounty_id)]=row
		GameState.add_gold(def.reward_gold)
		var quiet := _closed_quietly(row)
		if not quiet: GameState.add_reputation(def.reward_reputation)
		GameState.add_training_points(def.reward_training)
		for member: CharacterStats in GameState.party:
			if member!=null:member.gain_exp(def.reward_exp)
		var extras := PackedStringArray()
		for reward: Dictionary in def.reward_items:
			var id := StringName(reward.get("item_id",&""))
			if id==StringName(row.get("gear_at_battle",&"")): continue
			var item := Inventory.load_item_by_id(id)
			if item==null: continue
			var count := maxi(1,int(reward.get("count",1)))
			var before := Inventory.count_of(id)
			Inventory.add_item(id,count)
			var added := Inventory.count_of(id)-before
			if added>0:
				extras.append("%s ×%d"%[item.display_name,added])
			if added<count:
				extras.append("%s ×%d（背包满，未领）"%[item.display_name,count-added])
		GameState.player_changed.emit()
		GameState.party_changed.emit()
		var status := "信物核验相符，按已查验销案。" if quiet else "物证核验相符，已销案。"
		replies.append("「%s」%s\n赏银 +%d　历练 +%d　经验 +%d%s"%[def.display_name,status,
			def.reward_gold,def.reward_training,def.reward_exp,"" if quiet else "　声望 +%d"%def.reward_reputation])
		if not extras.is_empty(): replies.append("附赏："+ "、".join(extras))
	if not replies.is_empty(): return "\n".join(replies)
	for board_id: StringName in COUNTY_BOARDS:
		if office_city_for_board(board_id)==city: continue
		for def: BountyDef in _board_pool(board_id):
			if _state_for(def.bounty_id).status==STATUS_EVIDENCE:
				return "「%s」不归本府受理，请持原物证到%s交验。"%[def.display_name,office_label_for_board(board_id)]
	return "若已揭榜，按线报找人。取得物证再来本衙验缴；只有口供，不能销案。"

func _closed_quietly(row: Dictionary) -> bool:
	return StringName(row.get("disposition",&"")) in [&"spare",&"recruit"]

func _show_officer_reply(city: StringName,reply_text: String) -> void:
	if DialogPlayer.is_playing():return
	var script := DialogScript.new()
	script.dialog_id=StringName("warrant_report_"+String(city))
	var hero := DialogNode.new()
	hero.node_id=&"start"
	hero.speaker=GameState.player.display_name if GameState.player!=null else "冷孤云"
	hero.portrait_path=GameState.player.portrait_path if GameState.player!=null else ""
	hero.text="大人，我来查验榜案。"
	hero.on_end="next:reply"
	var reply := DialogNode.new()
	reply.node_id=&"reply"
	reply.speaker=OFFICES[city][3]
	reply.portrait_path="res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"
	reply.text=reply_text
	script.nodes.assign([hero,reply])
	DialogPlayer.play(script)
