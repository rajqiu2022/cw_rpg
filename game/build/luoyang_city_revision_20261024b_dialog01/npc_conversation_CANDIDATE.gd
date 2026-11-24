extends RefCounted
## Candidate only. Called at real NPC interaction boundaries, never DP.play globally.
## No SceneTree, autoload, persistent state, rewards, media writes or voice aliases.
const HERO_PORTRAIT := "res://art/characters/protagonist_portrait.png"
const PREFIX := "npc_opening_20261024b_"
const RUMORS := {
	"ch4_s2_canal_docks|harbour_life_docks_goods_broker": "昨夜泊船又响了几声铃，有人说水里不干净。船工却说是缆绳松了，碰着船边的铃；我没上船，哪边都不敢信。",
	"ch4_s3_luoyang_market|district_life_market_tea_guest": "听说城外古寺逢雨就有怪响，有人说是显灵，也有人说水滴敲着空瓮。我只在茶桌上听来的，你若去，可别当成定论。",
	"ch4_s3_luoyang_market|luoyang_paper_artisan_20261016": "隔壁说纸要涨价，劝我多囤些；卖纸的又说货船快到了。我先把手头的纸裁好，没见着货，可不敢替谁打包票。",
	"ch4_s3_luoyang_market|district_life_market_herb_buyer": "邻家这两日晒药，总有人问是不是治疑难病的秘方。她说不过是寻常药材；我不懂药性，你可别听闲话乱试。",
	"ch4_s0_luoyang_gate|harbour_life_gate_waiting_merchant_a": "前头有人说今天验货格外慢，后头又说只查湿了封口的货。我还没轮到，只能把货单备齐，免得白跑一趟。",
	"ch4_s3_luoyang_market|district_life_market_buyer": "有人说花会一到，卖什么都好卖；邻家去年却压了不少货。今年我只按家里用量买，热闹归热闹，传言不能当银钱使。",
}
const MATCHED_FAMILY_PORTRAITS := {
	"res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png": "res://art/characters/portraits/street_expansion_v1/portrait_vegetable_seller_v1.png",
	"res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png": "res://art/characters/portraits/portrait_linxi_farmer_v1.png",
	"res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png": "res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png",
	"res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png": "res://art/characters/portraits/street_expansion_v1/portrait_street_merchant_v1.png",
}
const EMPTY_EFFECTS := ["give_items", "set_flags", "learn_skills", "add_evidence", "verify_evidence", "add_testimonies", "verify_testimonies", "faction_trust_changes", "companion_trust_changes", "bond_events", "city_outcomes", "method_flags"]

static func fallback_portrait(sprite_path: String) -> String:
	# Unknown is explicitly portrait-less; do not guess gender/age from npc_id.
	return String(MATCHED_FAMILY_PORTRAITS.get(sprite_path, ""))

static func _no_effects(node: DialogNode) -> bool:
	if node == null or node.give_gold != 0 or node.accept_quest != &"" or node.complete_quest != &"" or node.weather_id != &"": return false
	for key: String in EMPTY_EFFECTS:
		var value: Variant = node.get(key)
		if not value is Array or not value.is_empty(): return false
	return true

static func _daily_target(script: DialogScript, npc_name: String, visit: int) -> StringName:
	# Only the two exact, already authenticated AP zero-effect menu shapes.
	# Never strip a quest, trading, investigation, or author-authored choice.
	var menu: DialogNode = script.get_entry_node()
	if script.nodes.size() != 3 or menu == null or menu.node_id not in [&"menu", &"ap_daily_menu"] or menu.speaker != npc_name or menu.text != "聊聊日常" or not _no_effects(menu): return &""
	if menu.choices != [{"text": "聊聊日常", "next": "start"}, {"text": "告辞", "next": "end"}]: return &""
	var first: DialogNode = script.find_node_by_id(&"start")
	var reply: DialogNode = script.find_node_by_id(&"reply")
	if not _no_effects(first) or not _no_effects(reply) or not first.choices.is_empty() or not reply.choices.is_empty(): return &""
	if first.speaker != npc_name or reply.speaker != npc_name or first.on_end != "next:reply" or reply.on_end != "end": return &""
	return &"reply" if visit % 3 == 2 else &"start"

static func prepare(original: DialogScript, scene_id: String, npc_id: String, npc_name: String, hero_name: String, hero_portrait: String, visit: int, pure_daily: bool, preserve_instance: bool) -> Dictionary:
	if original == null or original.get_entry_node() == null or visit < 0 or npc_id.is_empty() or npc_name.is_empty(): return {"ok": false, "error": "NPC_OPENING_INPUT"}
	var seen: Dictionary = {}
	for node: DialogNode in original.nodes:
		if node == null or node.node_id == &"" or seen.has(node.node_id) or String(node.node_id).begins_with(PREFIX): return {"ok": false, "error": "NPC_OPENING_NODE_DOMAIN"}
		seen[node.node_id] = true
	var target: StringName = original.entry_node_id
	if pure_daily:
		target = _daily_target(original, npc_name, visit)
		if target == &"": return {"ok": false, "error": "NPC_DAILY_MENU_NOT_EXACT_ZERO_EFFECT"}
	var entry: DialogNode = original.get_entry_node()
	if not pure_daily and (entry.speaker == "冷孤云" or (not hero_name.is_empty() and entry.speaker == hero_name)):
		return {"ok": true, "script": original, "already_hero": true, "rumor": false}
	# Preserve the culture coordinator's exact generated script instance.
	# Ordinary cached .tres resources are deep-cloned, never mutated.
	var script: DialogScript = original if preserve_instance else original.duplicate(true) as DialogScript
	var rumor_text: String = String(RUMORS.get(scene_id + "|" + npc_id, "")) if visit % 2 == 1 else ""
	var opening := DialogNode.new()
	opening.node_id = StringName(PREFIX + "hero")
	opening.speaker = hero_name if not hero_name.is_empty() else "冷孤云"
	opening.portrait_path = hero_portrait if not hero_portrait.is_empty() else HERO_PORTRAIT
	opening.text = "劳驾，近来街坊有什么新鲜事？" if pure_daily else "打扰了，想向你请教几句。"
	opening.voice_emotion = "normal"
	opening.on_end = "next:" + String(target)
	if not rumor_text.is_empty():
		# New node IDs intentionally have no alias to old recordings. No voice
		# asset is asserted/generated for this new text; existing nodes keep IDs.
		var rumor := DialogNode.new()
		rumor.node_id = StringName(PREFIX + "rumor")
		rumor.speaker = npc_name
		rumor.text = rumor_text
		rumor.voice_emotion = "normal"
		rumor.on_end = "end" if pure_daily else "next:" + String(target)
		opening.on_end = "next:" + String(rumor.node_id)
		script.nodes.append(rumor)
	script.nodes.push_front(opening)
	script.entry_node_id = opening.node_id
	return {"ok": true, "script": script, "already_hero": false, "rumor": not rumor_text.is_empty(), "pure_daily": pure_daily, "preserve_instance": preserve_instance, "new_voice_available": false}
