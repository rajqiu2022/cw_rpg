extends SceneTree

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_companion_and_enemy_frames()
	_validate_battle_mode_and_status_ui()
	_validate_interaction_props_and_cave()
	_validate_voice_identity()
	_validate_quest_and_skill_layout()
	print("[FeedbackBatch20260822] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[FeedbackBatch20260822] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_companion_and_enemy_frames() -> void:
	var tang := load("res://data/companions/tang_xingzhou.tres") as CharacterStats
	var spar := load("res://data/enemies/companion_tang_xingzhou_spar.tres") as EnemyDef
	_check(tang != null and tang.battle_sprite_root.contains("companions_v4"), "唐行舟队友使用稳定v4战斗帧")
	_check(spar != null and spar.battle_actor_path.contains("companions_v4"), "唐行舟切磋对手不再回退大幅度v2帧")
	if spar != null:
		for path: String in spar.ready_frame_paths:
			_check(path.contains("companions_v4"), "唐行舟切磋备战帧全部来自v4")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(battle_source.contains('0.30 if id == &"companion_tang_xingzhou_spar"'), "切磋唐行舟使用低幅度呼吸配置")
	_check(battle_source.contains('member.character_id == "tang_xingzhou"'), "队友唐行舟使用同一低幅度呼吸配置")
	for enemy_id: String in ["bandit_mountain", "zhuwei_bandit"]:
		var enemy := load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
		_check(enemy != null and enemy.battle_actor_path.contains("standard_v3"), "%s使用补全脚部的v3备战图" % enemy_id)
		if enemy == null:
			continue
		for path: String in enemy.ready_frame_paths:
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			var rect := image.get_used_rect() if image != null and not image.is_empty() else Rect2i()
			_check(rect.size.y >= 320, "%s备战帧保留完整成人高度" % enemy_id)
			_check(rect.position.y + rect.size.y <= 368, "%s完整鞋底下方留有安全带" % enemy_id)


func _validate_battle_mode_and_status_ui() -> void:
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	var formation_source := FileAccess.get_file_as_string("res://scripts/battle/battle_formation_view.gd")
	_check(battle_source.contains('"切磋开始" if _is_sparring_battle() else "遭遇战开始"'), "NPC切磋使用切磋开始而非遭遇战")
	_check(battle_source.contains("style.content_margin_top = 54.0") and battle_source.contains("style.content_margin_left = 50.0"), "回合信息正文下移并避开左上装饰")
	_check(formation_source.contains("icon.mouse_entered.connect") and formation_source.contains("icon.mouse_exited.connect"), "状态图标移入即显示说明，移出关闭")
	_check(not formation_source.contains("icon.pressed.connect(_show_status_tip"), "状态说明不再要求点击")
	_check(formation_source.contains("source_pos.y + source.size.y + 8.0"), "状态说明显示在图标下方")
	_check(formation_source.contains("widget.size = Vector2(112, 84)") and formation_source.contains("custom_minimum_size = Vector2(112, 28)"), "状态图标行下移且不覆盖内力条")


func _validate_interaction_props_and_cave() -> void:
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(field_source.contains("func _interaction_visual_kind") and field_source.contains('return "ledger"') and field_source.contains('return "parcel"'), "未显式配置的信件账册包裹可按语义生成物件")
	_check(ResourceLoader.exists("res://art/props/interactive/interaction_water_stain_v1.png"), "水渍脚印交互物件存在")
	var inn := load("res://data/maps/interior_inn_hall_layout_v1.tres") as WalkableMapLayout
	var register := _find(inn.interactions if inn != null else [], "inn_guest_register")
	_check(String(register.get("interaction_visual_kind", "")) == "ledger", "客栈账册显示小型账页物件")
	var cave_scene := load("res://data/scenes/ch1_s4_zhuwei_beast_cave.tres") as SceneScript
	_check(cave_scene != null and cave_scene.display_name.contains("入口营地"), "旧单房间洞穴已升级为多场景入口营地")
	_check(cave_scene != null and cave_scene.map_layout != null and cave_scene.map_layout.portals.size() == 3, "入口营地连接密林与两条洞穴支路")
	var entrance_chest := _find(cave_scene.map_layout.interactions if cave_scene != null and cave_scene.map_layout != null else [], "cave_left_chest")
	_check(bool(entrance_chest.get("visual_baked", false)), "底图已有洞穴宝箱禁止重复叠加物件")
	for scene_id: String in ["ch1_s4_cave_mine_gallery", "ch1_s4_cave_waterway", "ch1_s4_cave_deep_den"]:
		_check(ResourceLoader.exists("res://data/scenes/%s.tres" % scene_id), "洞穴扩展场景存在：%s" % scene_id)
	var deep := load("res://data/maps/ch1_s4_cave_deep_den_layout_v1.tres") as WalkableMapLayout
	var alpha_wolf := _find(deep.interactions if deep != null else [], "cave_alpha_wolf")
	_check(String(alpha_wolf.get("visual_texture", "")).contains("wild_wolf_ready"), "头狼深窟直接显示头狼物件，不只显示感叹号")


func _validate_voice_identity() -> void:
	var voice_source := FileAccess.get_file_as_string("res://../scripts/gen_dialog_voices.py")
	_check(voice_source.contains('"卖菜大婶": "zh-CN-XiaoyiNeural"'), "卖菜大婶映射成熟女声")
	_check(voice_source.contains('"焦急妇人": "zh-CN-XiaoyiNeural"'), "焦急妇人映射独立中年女声")
	for dialog_id: String in ["ch1_s2_crying_woman", "ch1_s2_crying_woman_waiting"]:
		var dialog_source := FileAccess.get_file_as_string("res://data/dialogs/%s.tres" % dialog_id)
		_check(dialog_source.contains('speaker = "焦急妇人"') and dialog_source.contains("portrait_zhuwei_anxious_middle_aged_woman_v1.png"), "%s使用焦急妇人身份与中年立绘" % dialog_id)
	_check(ResourceLoader.exists("res://art/audio/voices/ch1/ch1_s2_crying_woman/焦急妇人_start_efear.mp3"), "焦急妇人求救女声已生成")
	_check(ResourceLoader.exists("res://art/audio/voices/ch1/ch1_s2_vegetable_vendor/卖菜大婶_start_econcerned.mp3"), "卖菜大婶成熟女声已重新生成")


func _validate_quest_and_skill_layout() -> void:
	var quest_source := FileAccess.get_file_as_string("res://scripts/ui/quest_panel.gd")
	_check(quest_source.contains("cell_default.png") and quest_source.contains("cell_selected.png"), "任务奖励改用完整方形物品格底框")
	_check(not quest_source.contains('button.texture_normal = _texture("reward_normal.png")'), "任务奖励不再缩放不完整旧底框")
	var skill_source := FileAccess.get_file_as_string("res://scripts/ui/skill_panel.gd")
	_check(skill_source.contains('normal_font_size", 16'), "招式详情正文字号降低到16")
	_check(skill_source.contains("伤害类型：[color=#%s]") and skill_source.contains("破防：[color=#%s]"), "招式核心参数按品质色突出")


func _find(entries: Array, entry_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == entry_id:
			return entry
	return {}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
