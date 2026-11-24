extends Node

var _checks := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_sparring_state_machine()
	_validate_city_entries()
	await _validate_reading_ui()
	print("[CitySparringReadables] checks=%d failed=%d" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)


func _validate_sparring_state_machine() -> void:
	var game_state := get_node_or_null("/root/GameState")
	_check(game_state != null, "GameState autoload is available")
	if game_state == null:
		return
	game_state.sparring_records = {}
	game_state.training_points_total = 0
	game_state.training_points_available = 0
	var first_loss: Dictionary = game_state.resolve_sparring_result(&"qa_a", false, 20, 5)
	_check(int(first_loss.reward) == 5, "first loss grants the smaller reward")
	_check(int(game_state.resolve_sparring_result(&"qa_a", false, 20, 5).reward) == 0, "repeated loss grants zero")
	var first_win: Dictionary = game_state.resolve_sparring_result(&"qa_a", true, 20, 5)
	_check(int(first_win.reward) == 20 and bool(first_win.first_victory), "victory after a loss still grants first-win reward")
	_check(int(game_state.resolve_sparring_result(&"qa_a", true, 20, 5).reward) == 0, "repeated win grants zero")
	_check(int(game_state.resolve_sparring_result(&"qa_a", false, 20, 5).reward) == 0, "loss after first victory grants zero")
	_check(int(game_state.resolve_sparring_result(&"qa_b", true, 32, 8).reward) == 32, "different spar IDs keep independent rewards")
	_check(game_state.training_points_total == 57 and game_state.training_points_available == 57, "sparring changes training points only by awarded amounts")
	_check(game_state.has_sparring_victory(&"qa_a") and game_state.has_sparring_victory(&"qa_b"), "victory ownership is persistent in sparring records")
	var json_roundtrip: Variant = JSON.parse_string(JSON.stringify(game_state.get_sparring_records_save_data()))
	game_state.sparring_records = {}
	game_state.restore_sparring_records(json_roundtrip)
	_check(game_state.has_sparring_victory(&"qa_a") and game_state.has_sparring_victory(&"qa_b"), "sparring rewards survive the same JSON round-trip used by saves")
	game_state.restore_sparring_records(null)
	_check(game_state.sparring_records.is_empty(), "older saves without sparring records load as fresh")
	var protagonist: CharacterStats = game_state.player
	var hp_before := maxi(1, protagonist.max_hp - 13)
	var mp_before := maxi(0, protagonist.max_mp - 7)
	protagonist.hp = 0
	protagonist.mp = 0
	game_state.restore_party_after_sparring([{"character_id": "protagonist", "hp": hp_before, "mp": mp_before}])
	_check(protagonist.hp == hp_before and protagonist.mp == mp_before, "sparring restores the pre-fight HP/MP snapshot")


func _validate_city_entries() -> void:
	var spar_ids: Dictionary = {}
	var spar_count := 0
	var discovery_ids: Dictionary = {}
	for scene_path in [
		"res://data/scenes/ch2_s1_zhuwei_market.tres",
		"res://data/scenes/ch3_s2_trial_ground.tres",
		"res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s3_luoyang_market.tres",
	]:
		var scene := load(scene_path) as SceneScript
		_check(scene != null, "%s loads" % scene_path)
		if scene == null:
			continue
		for npc: Dictionary in scene.npcs:
			var action := String(npc.get("interaction_action", ""))
			if not action.begins_with("spar:"):
				continue
			var parts := action.split(":", true)
			spar_count += 1
			_check(parts.size() == 6, "%s has a complete spar payload" % npc.get("npc_id", "npc"))
			if parts.size() < 6:
				continue
			_check(not spar_ids.has(parts[1]), "spar ID %s is unique" % parts[1])
			spar_ids[parts[1]] = true
			_check(ResourceLoader.exists("res://data/enemies/%s.tres" % parts[2]), "spar opponent %s exists" % parts[2])
			_check(int(parts[4]) > int(parts[5]) and int(parts[5]) > 0, "win reward exceeds one-time loss reward for %s" % parts[1])
		for hotspot: Dictionary in scene.hotspots:
			var action := String(hotspot.get("action", ""))
			if action.begins_with("discover_readable:"):
				var parts := action.split(":", true)
				discovery_ids[parts[1]] = true
	_check(spar_count >= 12, "at least twelve city NPC sparring entries exist")
	var readable_count := 0
	for filename in DirAccess.get_files_at("res://data/items"):
		if not filename.ends_with(".tres"):
			continue
		var item := load("res://data/items/%s" % filename) as Item
		if item == null or not item.readable:
			continue
		readable_count += 1
		_check(item.is_key_item() and item.is_readable(), "%s is a non-consumable readable key item" % item.item_id)
		_check(item.read_content.length() >= 60, "%s contains full reading text" % item.item_id)
	_check(readable_count >= 9, "at least nine books/pages have full readable content")
	for required_id in ["qingming_sword_record", "shadow_step_annotations", "hanjia_water_rule_rubbing", "xuantong_scale_weave_note", "zhouju_birdseal_copy", "luoyang_quench_record"]:
		_check(discovery_ids.has(required_id), "%s is acquired from a scene rather than a quest" % required_id)


func _validate_reading_ui() -> void:
	var panel := preload("res://scenes/ui/reading_panel.tscn").instantiate() as ReadingPanel
	get_tree().root.add_child(panel)
	await get_tree().process_frame
	var item := load("res://data/items/canglong_fragment_upper.tres") as Item
	_check(panel.open_item(item), "reading panel accepts a readable item")
	_check(panel.is_open(), "reading panel opens as a modal")
	_check(panel.get_node_or_null("ReadablePanelArt") is TextureRect, "reading panel uses authored formal raster UI")
	var close_button := panel.get_node_or_null("ReadablePanelArt/CloseReader") as Button
	_check(close_button != null and close_button.size.x >= 250.0 and close_button.size.y >= 64.0, "reading panel close action has a full-size touch target")
	_check(close_button != null and close_button.get_theme_font_size("font_size") >= 22, "reading panel close action remains legible")
	_check(ResourceLoader.exists("res://art/ui/inventory/reading/readable_panel_bg_v1.png"), "formal reading panel asset is imported")
	panel.close_reader()
	_check(not panel.is_open(), "reading panel closes without consuming the item")
	panel.queue_free()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failed += 1
	push_error("[CitySparringReadables] %s" % message)
