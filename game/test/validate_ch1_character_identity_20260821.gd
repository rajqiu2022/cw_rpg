extends SceneTree

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_master_and_blacksmith()
	_validate_companions()
	_validate_zhao_wuji()
	_validate_shenbanzhan_boundary()
	print("[Ch1CharacterIdentity20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[Ch1CharacterIdentity20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_master_and_blacksmith() -> void:
	var tutorial := load("res://data/scenes/linxi_tutorial.tres") as SceneScript
	_check(tutorial != null, "师徒院落可加载")
	if tutorial == null:
		return
	for npc: Dictionary in tutorial.npcs:
		var name := String(npc.get("npc_name", ""))
		if name == "刑樊天":
			_check(String(npc.get("portrait_path", "")).ends_with("portrait_xingfantian_master.png"), "刑樊天所有阶段使用师父立绘")
			_check(String(npc.get("sprite_path", "")).contains("npc_xingfantian"), "刑樊天所有阶段使用师父Field身份")
		elif name == "杜青衫":
			_check(String(npc.get("portrait_path", "")).ends_with("portrait_duqingshan_steady.png"), "杜青衫所有阶段使用铁匠立绘")
			_check(String(npc.get("sprite_path", "")).contains("npc_duqingshan_v3"), "杜青衫所有阶段锁定V3 Field身份")
		_validate_entry_paths(npc)


func _validate_companions() -> void:
	var center := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	var tang := _find_npc(center.npcs if center != null else [], "tang_xingzhou_recruit")
	var qinghe := _find_npc(center.npcs if center != null else [], "shen_qinghe_recruit")
	_check(not tang.is_empty() and not qinghe.is_empty(), "两名第一章伙伴拥有独立Field入口")
	_check(String(tang.get("portrait_path", "")) != String(qinghe.get("portrait_path", "")), "两名伙伴不共享立绘")
	_check(String(tang.get("sprite_path", "")) != String(qinghe.get("sprite_path", "")), "两名伙伴不共享Field精灵")
	_check(String(tang.get("sprite_path", "")).contains("tang_xingzhou"), "唐行舟使用专属练棍身份")
	_check(String(qinghe.get("sprite_path", "")).contains("shen_qinghe"), "沈青禾使用专属Field身份")
	_validate_entry_paths(tang)
	_validate_entry_paths(qinghe)
	var tang_stats := load("res://data/companions/tang_xingzhou.tres") as CharacterStats
	var qinghe_stats := load("res://data/companions/shen_qinghe.tres") as CharacterStats
	_check(tang_stats != null and tang_stats.battle_sprite_root.contains("tang_xingzhou"), "唐行舟使用专属Battle根")
	_check(qinghe_stats != null and qinghe_stats.battle_sprite_root.contains("shen_qinghe"), "沈青禾使用专属Battle根")
	_check(tang_stats != null and qinghe_stats != null and tang_stats.battle_sprite_root != qinghe_stats.battle_sprite_root, "伙伴Battle身份互不复用")


func _validate_zhao_wuji() -> void:
	var scene := load("res://data/scenes/ch1_s3_ruin_inner.tres") as SceneScript
	_check(scene != null, "赵无忌内堂可加载")
	if scene == null:
		return
	for npc: Dictionary in scene.npcs:
		_check(String(npc.get("sprite_path", "")).ends_with("npc_zhao_wuji_idle_down_25d_4f.png"), "赵无忌所有阶段使用同一Field身份")
		_check(String(npc.get("portrait_path", "")).ends_with("battle_boss_zhao_wuji_v1.png"), "赵无忌所有阶段使用同一透明对话身份")
		_validate_entry_paths(npc)
	var portrait := Image.load_from_file(ProjectSettings.globalize_path("res://art/characters/battle_boss_zhao_wuji_v1.png"))
	_check(portrait != null and portrait.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "赵无忌对话身份图拥有真实alpha")
	for dialog_id: String in ["ch1_s3_ruin_boss", "ch1_s3_ruin_after_boss"]:
		var dialog := load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
		_check(dialog != null, "%s对话可加载" % dialog_id)
		if dialog != null:
			for node: DialogNode in dialog.nodes:
				if node != null and node.speaker == "赵无忌":
					_check(node.portrait_path.ends_with("battle_boss_zhao_wuji_v1.png"), "%s赵无忌台词显式绑定专属立绘" % dialog_id)


func _validate_shenbanzhan_boundary() -> void:
	var legacy := load("res://data/scenes/ch1_s0_linxi_main_walkable.tres") as SceneScript
	var shen := _find_npc(legacy.npcs if legacy != null else [], "shenbanzhan")
	_check(not shen.is_empty(), "兼容旧场景仍保留沈半盏资源")
	_check(not String(shen.get("sprite_path", "")).contains("xingfantian"), "沈半盏不再复用刑樊天Field精灵")
	var plan := load("res://data/chapters/chapter_1_content_plan.tres") as ChapterContentPlan
	_check(plan != null and &"ch1_s0_linxi_main_walkable" not in plan.main_scene_ids, "沈半盏旧场景不冒充现行第一章主场景")
	var docs_root := ProjectSettings.globalize_path("res://").path_join("../docs").simplify_path()
	var storyline := FileAccess.get_file_as_string(docs_root.path_join("storyline-data.json"))
	_check(not storyline.contains('"name": "沈半盏"'), "沈半盏未正式重接前不出现在现行故事角色表")
	_check(not FileAccess.file_exists(ProjectSettings.globalize_path("res://art/characters/portraits/ch1/portrait_shenbanzhan_canonical_v2.png")), "RGB棋盘候选未误入运行目录")


func _find_npc(entries: Array, npc_id: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get("npc_id", "")) == npc_id:
			return raw_entry as Dictionary
	return {}


func _validate_entry_paths(npc: Dictionary) -> void:
	for key: String in ["portrait_path", "sprite_path"]:
		var path := String(npc.get(key, ""))
		if not path.is_empty():
			_check(ResourceLoader.exists(path), "%s资源存在：%s" % [key, path])


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
