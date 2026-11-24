extends SceneTree

const WORLD_LAYOUT := "res://data/maps/world_map_jianghu_layout_v11.tres"
const INTERNAL_WORLD_IDS := ["north_forest", "zhuwei_cave", "zhuwei_forest", "west_ruin", "river_camp", "canal", "temple_tunnel"]
const COMPANION_DIALOGS := [
	"linxi_companion_tang_xingzhou",
	"linxi_companion_tang_xingzhou_after_spar",
	"linxi_companion_shen_qinghe",
	"linxi_companion_shen_qinghe_offer",
]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_world_and_routes()
	_validate_investigation_objects_and_progress()
	_validate_ui_and_terms()
	await _validate_audio_and_action_timing()
	_validate_companion_voices()
	print("[PolishBatch20260822] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[PolishBatch20260822] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_world_and_routes() -> void:
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	var layout := load(WORLD_LAYOUT) as WalkableMapLayout
	_check(world != null and layout != null, "世界地图v11可加载")
	if world == null or layout == null:
		return
	_check(world.background_path.ends_with("bg_world_map_jianghu_v11_2304.png"), "运行时使用写实地标与道路视觉同源的v11江湖地图")
	_check(layout.walkable_mask_path.ends_with("world_map_jianghu_walk_v11.png"), "运行时使用v11同源道路像素蒙版")
	var image := Image.load_from_file(ProjectSettings.globalize_path(world.background_path))
	_check(image != null and image.get_size() == Vector2i(2304, 1536), "大地图使用2304×1536优化运行资源")
	var portal_ids: Dictionary = {}
	for portal: Dictionary in layout.portals:
		portal_ids[String(portal.get("id", ""))] = true
	for id: String in INTERNAL_WORLD_IDS:
		_check(not portal_ids.has(id), "内部场景不重复出现在大地图：%s" % id)

	var forest := load("res://data/maps/ch1_s3_zhuwei_forest_layout_v2.tres") as WalkableMapLayout
	var cave := load("res://data/maps/ch1_s4_zhuwei_beast_cave_layout_v3.tres") as WalkableMapLayout
	_check(_target(forest, "enter_beast_cave") == "ch1_s4_zhuwei_beast_cave", "密林进入后山洞窟")
	_check(_target(cave, "leave_beast_cave") == "ch1_s3_zhuwei_forest", "后山洞窟返回密林")
	var ruin := load("res://data/maps/ch1_s3_west_ruin_layout_v2.tres") as WalkableMapLayout
	var inner := load("res://data/maps/ch1_s3_ruin_inner_layout_v1.tres") as WalkableMapLayout
	var market := load("res://data/maps/ch2_s1_zhuwei_market_layout_v2.tres") as WalkableMapLayout
	_check(_target(ruin, "ruin_main_hall_door") == "ch1_s3_ruin_inner", "废宅外院进入内堂")
	_check(_target(inner, "ruin_return_to_outer") == "ch1_s3_west_ruin", "内堂下方入口返回外院")
	_check(_target(inner, "ruin_to_chapter2_market") == "ch2_s1_zhuwei_market", "内堂上方出口进入第二章晨市")
	_check(_target(market, "market_return_to_ruin_inner") == "ch1_s3_ruin_inner", "晨市保留返回内堂的成对入口")
	var ch2_ambush := FileAccess.get_file_as_string("res://data/scenes/ch2_s3_forest_ambush.tres")
	var ch2_cave := FileAccess.get_file_as_string("res://data/maps/ch2_s5_bandit_cave_entrance_layout_v2.tres")
	_check(ch2_ambush.contains("scene:ch2_s2_forest_edge"), "密林伏击处可返回北林旧道")
	_check(ch2_cave.contains('"target_scene":"ch2_s3_forest_ambush"'), "伪令牌洞窟返回实际进入点")
	var ch3_training := FileAccess.get_file_as_string("res://data/scenes/ch3_s3_faction_training.tres")
	var ch3_tomb := FileAccess.get_file_as_string("res://data/scenes/ch3_s4_forbidden_tomb.tres")
	_check(ch3_training.contains("scene:ch3_s1_wulin_assembly") and ch3_tomb.contains("scene:ch3_s3_faction_training"), "第三章合练返回大会、石窟返回合练场")
	var temple := FileAccess.get_file_as_string("res://data/scenes/ch4_s4_ancient_temple.tres")
	var tunnel := FileAccess.get_file_as_string("res://data/scenes/ch4_s5_temple_tunnel.tres")
	_check(temple.contains("scene:ch4_s3_luoyang_market") and temple.contains("scene:ch4_s2_canal_docks"), "古寺为街市和漕渠各保留对应回程")
	_check(tunnel.contains("scene:ch4_s4_ancient_temple"), "古寺地道返回古寺")
	var field_scene := FileAccess.get_file_as_string("res://scenes/field_walkable.tscn")
	_check(field_scene.contains("WorldBackdrop") and field_scene.contains("color = Color(0, 0, 0, 1)"), "场景底图四周统一黑色")


func _validate_investigation_objects_and_progress() -> void:
	var ruin := load("res://data/maps/ch1_s3_west_ruin_layout_v2.tres") as WalkableMapLayout
	var inner := load("res://data/maps/ch1_s3_ruin_inner_layout_v1.tres") as WalkableMapLayout
	for id: String in ["ruin_shipping_marks", "ruin_watch_roster"]:
		var entry := _entry(ruin.interactions if ruin != null else [], id)
		_check(not String(entry.get("interaction_visual_kind", "")).is_empty(), "废宅调查点拥有可见实物：%s" % id)
	var order := _entry(inner.interactions if inner != null else [], "inspect_zhao_orders")
	_check(String(order.get("interaction_visual_kind", "")) == "letter", "Boss后密令显示信件实物")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(field_source.contains("_make_trigger_visual") and field_source.contains("任务推进：") and field_source.contains("获得线索："), "探索实物、任务推进和线索Tips已接入")
	for qid: String in ["q_ch1_main_village_inquiry", "q_ch1_main_zhuwei_wilds", "q_ch1_main_west_ruin_trace", "q_ch1_main_west_ruin"]:
		var quest := load("res://data/quests/%s.tres" % qid) as QuestDef
		_check(quest != null and not quest.progress_records.is_empty(), "任务拥有线索记录：%s" % qid)


func _validate_ui_and_terms() -> void:
	for path: String in ["res://art/ui/quest/reward_gold_icon_v1.png", "res://art/ui/quest/reward_exp_icon_v1.png", "res://art/ui/skill/runtime_v2/faction_none.png"]:
		_check(ResourceLoader.exists(path), "正式UI图标存在：%s" % path.get_file())
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_check(image != null and image.get_size() == Vector2i(256, 256) and image.detect_alpha() != Image.ALPHA_NONE, "UI图标具备真实透明通道：%s" % path.get_file())
	var quest_source := FileAccess.get_file_as_string("res://scripts/ui/quest_panel.gd")
	_check(quest_source.contains("_make_value_reward_slot") and quest_source.contains("Vector2(56, 56)"), "任务奖励图标与底框使用固定对齐尺寸")
	var skill_source := FileAccess.get_file_as_string("res://scripts/ui/skill_panel.gd")
	_check(skill_source.contains("无门派") and skill_source.contains("招式源流") and skill_source.contains("_status_detail_text"), "武学界面显示无门派与完整详情")
	var skill_dir := DirAccess.open("res://data/skills")
	for file_name: String in skill_dir.get_files() if skill_dir != null else []:
		if not file_name.ends_with(".tres"):
			continue
		var skill := load("res://data/skills/%s" % file_name) as Skill
		if skill != null and skill.quality == Skill.Quality.LEGENDARY:
			_check(not skill.origin.strip_edges().is_empty(), "橙色绝学拥有起源说明：%s" % String(skill.skill_id))
	var character_source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
	_check(character_source.contains("_make_character_resource_bar") and character_source.contains("生命  %d / %d") and character_source.contains("内力  %d / %d"), "角色属性使用生命/内力进度条与数字")
	var item_dir := DirAccess.open("res://data/items")
	for file_name: String in item_dir.get_files() if item_dir != null else []:
		if not file_name.ends_with(".tres"):
			continue
		var text := FileAccess.get_file_as_string("res://data/items/%s" % file_name)
		_check(not text.contains(" MP") and not text.contains(" HP"), "道具说明不再显示HP/MP：%s" % file_name)
	var inventory_source := FileAccess.get_file_as_string("res://scripts/autoload/inventory.gd")
	_check(inventory_source.contains("add_item(&\"inner_breath_pill\", 2)"), "新游戏提供前期回内力丹药")


func _validate_audio_and_action_timing() -> void:
	var audio := get_root().get_node_or_null("AudioManager")
	_check(audio != null, "AudioManager存在")
	if audio != null:
		audio.call("set_bgm_volume", 0.4)
		audio.call("ensure_bgm_for_scene", &"world_map_jianghu")
		await create_timer(0.35).timeout
		var player := audio.get("bgm_player") as AudioStreamPlayer
		_check(player != null and player.stream != null, "大世界BGM流已装载")
		if AudioServer.get_driver_name() != "Dummy":
			_check(player.playing, "大世界BGM运行时正在播放")
		_check(String(audio.call("get_current_bgm")).ends_with("bgm_linxi_village_v6.wav"), "大世界使用玩家认可的临时武侠配器基线")
		audio.call("play_bgm", "res://art/audio/bgm/bgm_battle_mountain_v4.wav", 0.01)
		await create_timer(0.35).timeout
		_check(String(audio.call("get_current_bgm")).ends_with("bgm_battle_mountain_v4.wav"), "紧凑战斗BGM路径已切换")
		if AudioServer.get_driver_name() != "Dummy":
			_check(player.playing, "战斗BGM运行时正在播放")

	var actor_scene := load("res://scenes/battle_actor.tscn") as PackedScene
	var actor := actor_scene.instantiate() as BattleActor if actor_scene != null else null
	var target := Control.new()
	if actor != null:
		get_root().add_child(actor)
		get_root().add_child(target)
		actor.position = Vector2(100, 100)
		actor.size = Vector2(220, 320)
		target.position = Vector2(520, 100)
		target.size = Vector2(220, 320)
		await process_frame
		var image := Image.create(160, 160, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.7, 0.8, 0.9, 1.0))
		var texture := ImageTexture.create_from_image(image)
		var frames: Array[Texture2D] = [texture, texture, texture, texture]
		actor.configure(texture, false, true, frames, frames, frames, frames, frames)
		actor.set_action_time_scale(1.0)
		var start_ms := Time.get_ticks_msec()
		await actor.play_stationary_attack(target, true)
		var elapsed := Time.get_ticks_msec() - start_ms
		_check(elapsed >= 850 and elapsed <= 1600, "命名招式动作持续1秒左右（%dms）" % elapsed)
		actor.queue_free()
		target.queue_free()
	else:
		_check(false, "BattleActor可实例化")


func _validate_companion_voices() -> void:
	var generator_path := ProjectSettings.globalize_path("res://").path_join("../scripts/gen_dialog_voices.py")
	var generator_source := FileAccess.get_file_as_string(generator_path)
	_check(generator_source.contains('"沈青禾": "zh-CN-XiaoxiaoNeural"') and generator_source.contains('"唐行舟": "zh-CN-YunxiNeural"'), "两名可入队角色使用正确性别声线")
	for dialog_id: String in COMPANION_DIALOGS:
		var dialog := load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
		_check(dialog != null, "队友对白存在：%s" % dialog_id)
		if dialog == null:
			continue
		var chapter_dir := dialog_id.substr(0, 3)
		for node: DialogNode in dialog.nodes:
			if node.speaker not in ["唐行舟", "沈青禾"]:
				continue
			var voice := "res://art/audio/voices/%s/%s/%s_%s_seg01_dialog.mp3" % [chapter_dir, dialog_id, node.speaker, String(node.node_id)]
			_check(ResourceLoader.exists(voice), "队友节点语音已生成：%s/%s" % [dialog_id, String(node.node_id)])
	var female_names := ["凌霜", "沈青禾", "沈晚棠", "楚泠", "赵思颖", "大会乐师", "晒药婆婆", "采药村妇"]
	for name: String in female_names:
		_check(generator_source.contains('"%s": "zh-CN-Xiao' % name), "女性角色映射女性声线：%s" % name)


func _target(layout: WalkableMapLayout, id: String) -> String:
	if layout == null:
		return ""
	return String(_entry(layout.portals, id).get("target_scene", ""))


func _entry(entries: Array[Dictionary], id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == id:
			return entry
	return {}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
