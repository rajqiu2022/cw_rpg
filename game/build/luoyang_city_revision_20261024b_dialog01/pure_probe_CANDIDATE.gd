extends SceneTree
## ROOT only, not run by implementation agent. Pure production helper calls;
## no DP playback, no task APIs or mutable gameplay singletons.
const H := preload("res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func make_daily() -> DialogScript:
	var script := DialogScript.new(); script.dialog_id = &"pure_daily_fixture"
	var menu := DialogNode.new(); menu.node_id = &"ap_daily_menu"; menu.speaker = "菜贩"; menu.text = "聊聊日常"
	menu.choices.assign([{"text": "聊聊日常", "next": "start"}, {"text": "告辞", "next": "end"}])
	var first := DialogNode.new(); first.node_id = &"start"; first.speaker = "菜贩"; first.text = "原来第一句"; first.on_end = "next:reply"
	var reply := DialogNode.new(); reply.node_id = &"reply"; reply.speaker = "菜贩"; reply.text = "原来第二句"; reply.on_end = "end"
	script.nodes.assign([menu, first, reply]); script.entry_node_id = menu.node_id
	return script

func prepare(script: DialogScript, visit: int, daily: bool = true, same: bool = false) -> Dictionary:
	return H.prepare(script, "ch4_s3_luoyang_market", "district_life_market_herb_buyer", "菜贩", "冷孤云", H.HERO_PORTRAIT, visit, daily, same)

func _initialize() -> void:
	var original := make_daily()
	var first: Dictionary = prepare(original, 0)
	check(first.get("ok") == true, "daily accepted")
	if first.get("ok") == true:
		var script: DialogScript = first.script
		check(script != original and original.nodes.size() == 3 and original.entry_node_id == &"ap_daily_menu", "cached source immutable")
		check(script.dialog_id == original.dialog_id, "same voice dialog id")
		check(script.get_entry_node().speaker == "冷孤云" and script.get_entry_node().portrait_path == H.HERO_PORTRAIT and script.get_entry_node().choices.is_empty(), "hero first no menu")
		check(script.get_entry_node().on_end == "next:start", "direct original daily")
		check(script.find_node_by_id(&"start").text == "原来第一句" and script.find_node_by_id(&"reply").text == "原来第二句", "existing node IDs and texts")
	var rumor: Dictionary = prepare(original, 1)
	check(rumor.get("ok") == true and rumor.get("rumor") == true, "attributed rumor selected")
	if rumor.get("ok") == true:
		var node: DialogNode = rumor.script.find_node_by_id(StringName(H.PREFIX + "rumor"))
		check(node != null and node.speaker == "菜贩" and node.text.contains("我不懂药性") and node.on_end == "end" and H._no_effects(node), "rumor stays uncertain and zero effects")
	var third: Dictionary = prepare(original, 2)
	check(third.get("ok") == true and third.script.get_entry_node().on_end == "next:reply", "repeat shorter original line")
	var culture := make_daily()
	var same: Dictionary = prepare(culture, 0, false, true)
	check(same.get("ok") == true and same.script == culture, "culture exact instance")
	var task := make_daily(); task.find_node_by_id(&"start").accept_quest = &"fixture_never_executed"
	check(prepare(task, 0).get("ok") == false, "daily effect refuses stripping")
	var opaque_choice := make_daily(); opaque_choice.get_entry_node().choices[0]["action"] = "shop:fixture"
	check(prepare(opaque_choice, 0).get("ok") == false, "trade action not stripped")
	var hero := make_daily(); hero.get_entry_node().speaker = "冷孤云"
	var already: Dictionary = prepare(hero, 0, false)
	check(already.get("ok") == true and already.get("already_hero") == true and already.script == hero, "existing protagonist opening unchanged")
	var duplicate := make_daily(); duplicate.nodes.append(duplicate.nodes[1])
	check(prepare(duplicate, 0).get("ok") == false, "duplicate node IDs refuse")
	check(H.fallback_portrait("res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png").ends_with("portrait_vegetable_seller_v1.png"), "matched vegetable portrait")
	check(H.fallback_portrait("res://art/characters/unknown.png") == "", "no guessed male portrait")
	check(H.RUMORS.size() == 6, "six producer approved attributed rumors")
	print(JSON.stringify({"scope":"PURE_HELPER_ONLY_NOT_FIELD_OR_DP", "checks":checks, "failures":failures, "complete":failures.is_empty()}))
	quit(0 if failures.is_empty() else 1)
