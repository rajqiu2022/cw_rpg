extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const UI_DISPLAY_ART := preload("res://scripts/ui/ui_display_art.gd")
const SKILL_DIR := "res://data/skills/"
const DISPLAY_ART_PATH := "res://art/ui/cold_wuxia/v2/ui_display_skill_bright.png"
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"机敏": Rect2(290, 55, 201, 204),
	"内劲": Rect2(544, 55, 200, 204),
	"悟性": Rect2(794, 55, 195, 203),
	"防御": Rect2(38, 293, 202, 207),
}

@onready var skill_list: VBoxContainer = %SkillList
@onready var detail: RichTextLabel = %Detail
@onready var close_btn: Button = %CloseBtn

var _skills: Array[Skill] = []
var _attr_icon_atlas: Texture2D = null
var _filter_mode := "all"
var _school_filter: String = "all"
var _selected_skill_id: StringName = &""
var _quick_skill_id: StringName = &""
var _summary_label: Label = null
var _quick_btn: Button = null
var _practice_btn: Button = null


func _ready() -> void:
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_build_formal_layout()
	_apply_visual_style()
	UI_DISPLAY_ART.install_fullscreen_panel(self, DISPLAY_ART_PATH, close)
	close_btn.pressed.connect(close)
	_load_skills()
	_refresh_list()


func open() -> void:
	visible = true
	_refresh_list()
	close_btn.grab_focus()


func close() -> void:
	visible = false
	emit_signal("closed")


func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Panel/Body") as VBoxContainer
	if body == null:
		return

	var toolbar: HBoxContainer = body.get_node_or_null("SkillToolbar") as HBoxContainer
	if toolbar != null:
		_apply_toolbar_style(toolbar)
	else:
		_build_toolbar_in_code(body)

	var content: HBoxContainer = get_node_or_null("Panel/Body/Content") as HBoxContainer
	if content != null:
		content.add_theme_constant_override("separation", 18)
	var list_scroll: ScrollContainer = get_node_or_null("Panel/Body/Content/ListScroll") as ScrollContainer
	if list_scroll != null:
		list_scroll.custom_minimum_size = Vector2(430, 0)
	detail.custom_minimum_size = Vector2(610, 0)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var actions: HBoxContainer = body.get_node_or_null("SkillActions") as HBoxContainer
	if actions != null:
		if _quick_btn == null:
			_quick_btn = actions.get_node_or_null("QuickBtn") as Button
			if _quick_btn != null:
				UI_THEME.style_button(_quick_btn, 16, UI_THEME.JADE)
				_quick_btn.pressed.connect(_set_quick_skill)
		if _practice_btn == null:
			_practice_btn = actions.get_node_or_null("PracticeBtn") as Button
			if _practice_btn != null:
				UI_THEME.style_button(_practice_btn, 16, UI_THEME.BLUE_STEEL)
				_practice_btn.pressed.connect(_practice_selected)
	else:
		_build_actions_in_code(body)


func _apply_toolbar_style(toolbar: HBoxContainer) -> void:
	_attach_filter_button(toolbar, "BtnAll", "all", "全部")
	_attach_filter_button(toolbar, "BtnAttack", "attack", "攻击")
	_attach_filter_button(toolbar, "BtnSupport", "support", "辅助")
	_attach_filter_button(toolbar, "BtnDefense", "defense", "防御")

	var sf: OptionButton = toolbar.get_node_or_null("SchoolFilter") as OptionButton
	if sf != null:
		sf.add_item("全部流派", 0)
		sf.set_item_metadata(0, "all")
		var idx: int = 1
		for school in ["linxi", "gufeng", "huashan", "lingyue", "mingwu", "wudang", "generic"]:
			sf.add_item(school, idx)
			sf.set_item_metadata(idx, school)
			idx += 1
		sf.item_selected.connect(func(i: int):
			_school_filter = str(sf.get_item_metadata(i))
			_refresh_list()
		)

	_summary_label = toolbar.get_node_or_null("Summary") as Label
	if _summary_label != null:
		UI_THEME.style_label(_summary_label, 16, UI_THEME.MUTED, false)


func _build_toolbar_in_code(body: VBoxContainer) -> void:
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.name = "SkillToolbar"
	toolbar.add_theme_constant_override("separation", 10)
	body.add_child(toolbar)
	body.move_child(toolbar, 1)
	_add_filter_button(toolbar, "全部", "all")
	_add_filter_button(toolbar, "攻击", "attack")
	_add_filter_button(toolbar, "辅助", "support")
	_add_filter_button(toolbar, "防御", "defense")
	_summary_label = Label.new()
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI_THEME.style_label(_summary_label, 16, UI_THEME.MUTED, false)
	toolbar.add_child(_summary_label)


func _build_actions_in_code(body: VBoxContainer) -> void:
	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "SkillActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	_quick_btn = Button.new()
	_quick_btn.text = "设为快捷招式"
	_quick_btn.custom_minimum_size = Vector2(170, 42)
	UI_THEME.style_button(_quick_btn, 16, UI_THEME.JADE)
	_quick_btn.pressed.connect(_set_quick_skill)
	actions.add_child(_quick_btn)
	_practice_btn = Button.new()
	_practice_btn.text = "研读招式"
	_practice_btn.custom_minimum_size = Vector2(140, 42)
	UI_THEME.style_button(_practice_btn, 16, UI_THEME.BLUE_STEEL)
	_practice_btn.pressed.connect(_practice_selected)
	actions.add_child(_practice_btn)


func _add_filter_button(parent: HBoxContainer, label: String, mode: String) -> void:
	var btn: Button = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 38)
	UI_THEME.style_button(btn, 15, UI_THEME.BLUE_STEEL)
	btn.pressed.connect(func(): _set_filter(mode))
	parent.add_child(btn)


func _attach_filter_button(toolbar: HBoxContainer, node_name: String, mode: String, label: String) -> void:
	var btn: Button = toolbar.get_node_or_null(node_name) as Button
	if btn == null:
		_add_filter_button(toolbar, label, mode)
		return
	UI_THEME.style_button(btn, 15, UI_THEME.BLUE_STEEL)
	btn.pressed.connect(func(): _set_filter(mode))


func _set_filter(mode: String) -> void:
	_filter_mode = mode
	_refresh_list()


func _apply_visual_style() -> void:
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.005, 0.010, 0.016, 0.58)
	var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer
	if panel != null:
		panel.offset_left = -640
		panel.offset_top = -350
		panel.offset_right = 640
		panel.offset_bottom = 350
		panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.075, 0.98), UI_THEME.BLUE_STEEL, 18, 3))
	var title: Label = get_node_or_null("Panel/Body/Header/Title") as Label
	if title != null:
		title.text = "武学"
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_button(close_btn, 16, UI_THEME.CRIMSON)
	UI_THEME.style_rich_text(detail, 18)


func _load_skills() -> void:
	_skills.clear()
	var dir: DirAccess = DirAccess.open(SKILL_DIR)
	if dir == null:
		push_warning("[SkillPanel] skill dir missing: %s" % SKILL_DIR)
		return
	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		var res: Resource = load(SKILL_DIR + file_name)
		if res is Skill:
			_skills.append(res)


func _refresh_list() -> void:
	for child in skill_list.get_children():
		child.queue_free()
	var visible_skills: Array[Skill] = []
	for skill in _skills:
		if not _skill_visible(skill):
			continue
		visible_skills.append(skill)
		skill_list.add_child(_make_skill_row(skill))
	_update_summary()
	if visible_skills.is_empty():
		_show_empty()
		return
	if _selected_skill_id == &"" or _find_skill(_selected_skill_id) == null:
		_selected_skill_id = visible_skills[0].skill_id
	_show_selected()


func _skill_visible(skill: Skill) -> bool:
	if _school_filter != "all" and skill.school != _school_filter:
		return false
	match _filter_mode:
		"attack":
			return skill.kind == Skill.Kind.ATTACK and not _is_defense_skill(skill)
		"support":
			return skill.kind != Skill.Kind.ATTACK and not _is_defense_skill(skill)
		"defense":
			return _is_defense_skill(skill)
		_:
			return true


func _make_skill_row(skill: Skill) -> Control:
	var row_panel: PanelContainer = PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 96)
	var border := _kind_accent(skill)
	if skill.skill_id == _selected_skill_id:
		border = UI_THEME.GOLD_LIGHT
	row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.038, 0.060, 0.072, 0.90), border, 12, 1))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)
	var icon := _make_skill_icon(skill)
	if icon != null:
		row.add_child(icon)
	var btn: Button = Button.new()
	btn.text = "%s  ·  %s\n消耗 %d · 威力 %d%% · %d 段" % [skill.display_name, _kind_text(skill.kind), skill.mp_cost, skill.power, skill.hit_count]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 74)
	UI_THEME.style_button(btn, 16, _kind_accent(skill))
	var captured_id: StringName = skill.skill_id
	btn.pressed.connect(func(): _select_skill(captured_id))
	row.add_child(btn)
	return row_panel


func _select_skill(skill_id: StringName) -> void:
	_selected_skill_id = skill_id
	_refresh_list()


func _show_selected() -> void:
	var skill := _find_skill(_selected_skill_id)
	if skill == null:
		_show_empty()
		return
	_show_skill(skill)


func _show_empty() -> void:
	detail.text = "[b]武学[/b]\n\n当前分类下暂无招式。"
	if _quick_btn != null:
		_quick_btn.disabled = true
	if _practice_btn != null:
		_practice_btn.disabled = true


func _show_skill(skill: Skill) -> void:
	if _quick_btn != null:
		_quick_btn.disabled = false
		if skill.skill_id == _quick_skill_id:
			_quick_btn.text = "已设为快捷"
		else:
			_quick_btn.text = "设为快捷招式"
	if _practice_btn != null:
		_practice_btn.disabled = false
	detail.text = "[b]%s[/b]\n[color=#9fd3d0]%s · %s[/color]\n\n[b]战斗参数[/b]\n目标：%s\n内力消耗：%d\n威力倍率：%d%%\n攻击段数：%d\n动画：%s\n\n[b]招式说明[/b]\n%s\n\n[b]使用建议[/b]\n%s" % [
		skill.display_name,
		_kind_text(skill.kind),
		_quick_text(skill),
		_target_text(skill.target),
		skill.mp_cost,
		skill.power,
		skill.hit_count,
		String(skill.animation_id),
		skill.description,
		_advice_text(skill),
	]


func _find_skill(skill_id: StringName) -> Skill:
	for skill in _skills:
		if skill.skill_id == skill_id:
			return skill
	return null


func _set_quick_skill() -> void:
	if _selected_skill_id == &"":
		return
	_quick_skill_id = _selected_skill_id
	_show_selected()


func _practice_selected() -> void:
	var skill := _find_skill(_selected_skill_id)
	if skill == null:
		return
	detail.text += "\n\n[color=#9fd3d0]已研读：%s。当前版本暂不消耗资源，后续可接入熟练度。[/color]" % skill.display_name


func _update_summary() -> void:
	if _summary_label == null:
		return
	var attack_count := 0
	var support_count := 0
	var defense_count := 0
	for skill in _skills:
		if _is_defense_skill(skill):
			defense_count += 1
		elif skill.kind == Skill.Kind.ATTACK:
			attack_count += 1
		else:
			support_count += 1
	_summary_label.text = "招式 %d · 攻击 %d · 辅助 %d · 防御 %d" % [_skills.size(), attack_count, support_count, defense_count]


func _is_defense_skill(skill: Skill) -> bool:
	var id_text := String(skill.skill_id).to_lower()
	var name_text := skill.display_name.to_lower()
	var desc_text := skill.description.to_lower()
	return id_text.contains("defend") or name_text.contains("防") or desc_text.contains("防") or desc_text.contains("守")


func _kind_accent(skill: Skill) -> Color:
	if _is_defense_skill(skill):
		return UI_THEME.BLUE_STEEL
	match skill.kind:
		Skill.Kind.ATTACK:
			return UI_THEME.JADE
		Skill.Kind.HEAL:
			return UI_THEME.GOLD
		Skill.Kind.BUFF:
			return UI_THEME.BLUE_STEEL
		Skill.Kind.DEBUFF:
			return UI_THEME.CRIMSON
		_:
			return UI_THEME.GOLD


func _quick_text(skill: Skill) -> String:
	return "快捷招式" if skill.skill_id == _quick_skill_id else "已掌握"


func _advice_text(skill: Skill) -> String:
	if _is_defense_skill(skill):
		return "适合在强敌蓄势或气血较低时使用，稳住战线。"
	if skill.kind == Skill.Kind.ATTACK and skill.mp_cost > 0:
		return "适合在内力充足时打出爆发，优先用于关键敌人。"
	if skill.kind == Skill.Kind.ATTACK:
		return "消耗低，可作为常规试探招式。"
	if skill.kind == Skill.Kind.HEAL:
		return "适合在气血告急时保命。"
	if skill.kind == Skill.Kind.DEBUFF:
		return "适合先手削弱敌人，为后续爆发创造机会。"
	return "适合根据战局灵活使用。"


func _kind_text(kind: int) -> String:
	match kind:
		Skill.Kind.ATTACK:
			return "攻击"
		Skill.Kind.HEAL:
			return "疗伤"
		Skill.Kind.BUFF:
			return "增益"
		Skill.Kind.DEBUFF:
			return "削弱"
		_:
			return "未知"


func _target_text(target: int) -> String:
	match target:
		Skill.Target.ENEMY_SINGLE:
			return "敌方单体"
		Skill.Target.ENEMY_ALL:
			return "敌方全体"
		Skill.Target.ALLY_SINGLE:
			return "己方单体"
		Skill.Target.ALLY_ALL:
			return "己方全体"
		Skill.Target.SELF:
			return "自身"
		_:
			return "未知"


func _make_skill_icon(skill: Skill) -> TextureRect:
	var tex: Texture2D = null
	if skill.icon_path != "" and ResourceLoader.exists(skill.icon_path):
		tex = load(skill.icon_path)
	elif _attr_icon_atlas != null:
		var icon_key := "内劲"
		if _is_defense_skill(skill):
			icon_key = "防御"
		elif skill.kind == Skill.Kind.HEAL or skill.kind == Skill.Kind.BUFF:
			icon_key = "悟性"
		elif skill.kind == Skill.Kind.DEBUFF:
			icon_key = "机敏"
		var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
		if region.size.x > 0 and region.size.y > 0:
			var atlas_tex: AtlasTexture = AtlasTexture.new()
			atlas_tex.atlas = _attr_icon_atlas
			atlas_tex.region = region
			tex = atlas_tex
	if tex == null:
		return null
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	return icon


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
