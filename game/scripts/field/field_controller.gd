extends Control

## 探索场景（Field）控制器。
##
## 工作方式：
##   1. 从 SceneRouter 取当前 scene_id
##   2. 加载对应 SceneScript .tres
##   3. 渲染背景 + 标题 + N 个互动热点按钮（按 pos_x/pos_y 浮点比例定位）
##   4. 进场触发 on_enter_dialog（如果有）
##   5. 监听 EventBus.flag_set，flag 变化时刷新热点（require/hide 立即生效）
##
## 热点 dict 格式见 SceneScript.gd 注释。

@onready var background: TextureRect = %Background
@onready var hotspots_container: Control = %HotspotsContainer
@onready var scene_title: Label = %SceneTitle
@onready var hud_gold: Label = %GoldLabel
@onready var quest_list: RichTextLabel = %QuestList
@onready var quest_log_btn: Button = %QuestLogBtn

var _current_scene: SceneScript = null


func _ready() -> void:
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.dialog_ended.connect(_on_dialog_ended)
	QuestManager.active_quests_changed.connect(_refresh_quest_panel)
	EventBus.quest_completed.connect(_on_quest_completed)
	quest_log_btn.pressed.connect(_on_quest_log_pressed)

	var scene_id: StringName = SceneRouter.get_field_payload().get("scene_id", &"ch1_s1_road")
	_current_scene = _load_scene(scene_id)
	if _current_scene == null:
		push_warning("[Field] failed to load scene %s" % scene_id)
		return

	_render_scene(_current_scene)
	_refresh_gold()
	_refresh_quest_panel()

	# scene_entered 必须在 on_enter_dialog 之前发，
	# 这样 QuestManager 可以推进 "scene_entered:<id>" 触发的任务，
	# UI 在面板里立即看到状态变化。
	EventBus.scene_entered.emit(scene_id)

	if _current_scene.on_enter_dialog != null:
		await get_tree().process_frame
		DialogPlayer.play(_current_scene.on_enter_dialog)


func _load_scene(scene_id: StringName) -> SceneScript:
	var path := "res://data/scenes/%s.tres" % String(scene_id)
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is SceneScript:
			return res
	push_warning("[Field] scene not found: %s" % path)
	return null


func _render_scene(scene: SceneScript) -> void:
	if scene.background_path != "" and ResourceLoader.exists(scene.background_path):
		background.texture = load(scene.background_path)
	scene_title.text = scene.display_name
	_spawn_hotspots(scene.hotspots)


func _spawn_hotspots(hotspots: Array) -> void:
	for c in hotspots_container.get_children():
		c.queue_free()

	for entry in hotspots:
		var h: Dictionary = entry
		var require_flag := String(h.get("require_flag", ""))
		var hide_flag := String(h.get("hide_flag", ""))

		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var btn := Button.new()
		btn.text = String(h.get("label", "?"))
		btn.custom_minimum_size = Vector2(220, 60)
		btn.add_theme_font_size_override("font_size", 18)

		var px := float(h.get("pos_x", 0.5))
		var py := float(h.get("pos_y", 0.5))
		btn.anchor_left = px
		btn.anchor_top = py
		btn.anchor_right = px
		btn.anchor_bottom = py
		btn.offset_left = -110.0
		btn.offset_top = -30.0
		btn.offset_right = 110.0
		btn.offset_bottom = 30.0

		var action := String(h.get("action", ""))
		var captured_label := btn.text
		btn.pressed.connect(func(): _on_hotspot_pressed(captured_label, action))
		hotspots_container.add_child(btn)


func _flag_truthy(key: String) -> bool:
	var v: Variant = GameState.flags.get(key, null)
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT: return v != 0
	if typeof(v) == TYPE_STRING: return v != ""
	return true


# --- 信号回调 ---

func _on_hotspot_pressed(label: String, action: String) -> void:
	if DialogPlayer.is_playing():
		return
	EventBus.hotspot_triggered.emit(SceneRouter.get_current_field_id(), label)
	SceneRouter.resolve_action(action)


func _on_flag_set(_flag: StringName, _v: Variant) -> void:
	# Flag 变化可能让某个热点解锁/隐藏，立即刷新
	if _current_scene != null:
		_spawn_hotspots(_current_scene.hotspots)


func _on_gold_changed(_n: int) -> void:
	_refresh_gold()


func _on_dialog_ended(_id: StringName) -> void:
	# 对话结束后刷新热点（对话副作用可能改了 flag/物品）
	if _current_scene != null:
		_spawn_hotspots(_current_scene.hotspots)


func _refresh_gold() -> void:
	hud_gold.text = "金 %d" % GameState.gold


func _refresh_quest_panel() -> void:
	var actives := QuestManager.get_active_quests()
	if actives.is_empty():
		quest_list.text = "[i]暂无任务[/i]"
		return
	var lines: Array[String] = []
	for q: QuestDef in actives:
		var prefix: String = "[color=#e3a64a]●[/color] " if q.kind == QuestDef.Kind.MAIN else "[color=#88aabb]○[/color] "
		lines.append("%s[b]%s[/b]\n  %s" % [prefix, q.title, q.desc_in_progress])
	quest_list.text = "\n\n".join(lines)


func _on_quest_completed(qid: StringName) -> void:
	# 完成提示：直接借用对话框做最简版"toast"——
	# M3 范围只在控制台 print + 让面板从列表里移除，避免阻塞玩家流程。
	# 真正的弹幕/Toast UI 留给 M5+ 美术 UI 阶段。
	var def := QuestManager.load_def(qid)
	if def != null:
		print("[Field] quest completed → %s（gold +%d, exp +%d）" % [def.title, def.reward_gold, def.reward_exp])


func _on_quest_log_pressed() -> void:
	# M3 极简版：只切换面板可见性。M3+ 可以加全屏任务日志。
	var qp := get_node_or_null("QuestPanel")
	if qp != null:
		qp.visible = not qp.visible


func _unhandled_input(event: InputEvent) -> void:
	if DialogPlayer.is_playing():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			_on_quest_log_pressed()
