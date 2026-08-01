extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const SKILL_DIR := "res://data/skills/"
const ATTR_ICON_ATLAS_PATH := "res://art/ui/icon/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"机敏": Rect2(290, 55, 201, 204),
	"内劲": Rect2(544, 55, 200, 204),
	"悟性": Rect2(794, 55, 195, 203),
	"防御": Rect2(38, 293, 202, 207),
}

# Runtime overlay coordinates are kept here for quick visual tuning against panel_bg_v3.
const RUNTIME_FACTION_CENTER_X := 206.0
const RUNTIME_FACTION_CREST_SIZE := 92.0
const RUNTIME_FILTER_X := 136.0
const RUNTIME_LIST_X := 148.0
const RUNTIME_LIST_WIDTH := 200.0

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

# Runtime v2 uses the generated panel/control atlas with a fixed 1280x720 safe area.
var _runtime_root: Control = null
var _runtime_list: VBoxContainer = null
var _runtime_detail: RichTextLabel = null
var _runtime_selected_id: StringName = &""
var _runtime_group: String = "move"
var _runtime_route: String = "all"
var _runtime_insight: int = 120
var _runtime_count_label: Label = null
var _runtime_resource_label: Label = null
var _runtime_name_label: Label = null
var _runtime_meta_label: Label = null
var _runtime_power_label: Label = null
var _runtime_upgrade_label: Label = null
var _runtime_cost_label: Label = null
var _runtime_upgrade_btn: Button = null
var _runtime_primary_buttons: Array[Button] = []
var _runtime_primary_text_images: Array[TextureRect] = []
var _runtime_category_buttons: Array[Button] = []


func _ready() -> void:
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_load_skills()
	_setup_runtime_v2()
	_refresh_runtime_v2()


func open() -> void:
	visible = true
	_refresh_runtime_v2()


func close() -> void:
	visible = false
	emit_signal("closed")


func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Panel/Body") as VBoxContainer
	if body == null:
		return

	var toolbar: HBoxContainer = body.get_node_or_null("SkillToolbar") as HBoxContainer
	if toolbar != null:
		body.move_child(toolbar, 1)
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
				_apply_btn_textures(_quick_btn, "btn_quick")
				_quick_btn.pressed.connect(_set_quick_skill)
		if _practice_btn == null:
			_practice_btn = actions.get_node_or_null("PracticeBtn") as Button
			if _practice_btn != null:
				_apply_btn_textures(_practice_btn, "btn_practice")
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

	_update_filter_highlights()


func _update_filter_highlights() -> void:
	var toolbar: HBoxContainer = get_node_or_null("Panel/Body/SkillToolbar") as HBoxContainer
	if toolbar == null: return
	var mode_map := {"BtnAll": "all", "BtnAttack": "attack", "BtnSupport": "support", "BtnDefense": "defense"}
	for btn_name in mode_map:
		var btn: Button = toolbar.get_node_or_null(str(btn_name)) as Button
		if btn == null: continue
		var is_sel: bool = _filter_mode == str(mode_map[btn_name])
		var tex: Texture2D = _try_load("tab_selected.png" if is_sel else "tab_normal.png")
		if tex != null:
			btn.add_theme_stylebox_override("normal", _tex_stylebox(tex))


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
	_apply_btn_textures(btn, "tab")
	btn.tooltip_text = label
	var lbl := btn.get_child(btn.get_child_count() - 1) as Label
	if lbl != null: lbl.text = label
	btn.pressed.connect(func(): _set_filter(mode))


func _set_filter(mode: String) -> void:
	_filter_mode = mode
	_update_filter_highlights()
	_refresh_list()


func _apply_visual_style() -> void:
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.005, 0.010, 0.016, 0.58)
	var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer
	if panel != null:
		# Keep the interactive layout inside the plain 1280x720 frame.  The
		# former full-page concept art had baked scenery outside this safe area.
		panel.offset_left = -640
		panel.offset_top = -360
		panel.offset_right = 640
		panel.offset_bottom = 360
		var panel_style: StyleBoxEmpty = StyleBoxEmpty.new()
		panel_style.content_margin_left = 72.0
		panel_style.content_margin_top = 74.0
		panel_style.content_margin_right = 72.0
		panel_style.content_margin_bottom = 54.0
		panel.add_theme_stylebox_override("panel", panel_style)
	var title: Label = get_node_or_null("Panel/Body/Header/Title") as Label
	if title != null:
		title.text = "武学"
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)

	var cn: Texture2D = _try_load("btn_close_normal.png")
	if cn != null:
		close_btn.flat = true
		close_btn.text = "关闭"
		close_btn.custom_minimum_size = Vector2(cn.get_width(), cn.get_height())
		close_btn.add_theme_font_size_override("font_size", 16)
		close_btn.add_theme_color_override("font_color", Color(0.86, 0.93, 0.95, 1.0))
		close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.62, 1.0))
		close_btn.add_theme_stylebox_override("normal", _tex_stylebox(cn))
		close_btn.add_theme_stylebox_override("hover", _tex_stylebox(_try_load("btn_close_hover.png")))
		close_btn.add_theme_stylebox_override("pressed", _tex_stylebox(_try_load("btn_close_pressed.png")))
	else:
		UI_THEME.style_button(close_btn, 16, UI_THEME.CRIMSON)

	detail.add_theme_font_size_override("normal_font_size", 18)
	detail.add_theme_color_override("default_color", Color(0.84, 0.91, 0.93, 1.0))
	detail.add_theme_stylebox_override("normal", StyleBoxEmpty.new())


func _load_skills() -> void:
	_skills.clear()
	if GameState.player == null:
		return
	var learned_ids: Dictionary = {}
	for skill_id in GameState.player.skills:
		learned_ids[skill_id] = true
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
			var skill: Skill = res
			if learned_ids.has(skill.skill_id):
				_skills.append(skill)


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
	var row_tex: Texture2D = _try_load("skill_row_selected.png" if skill.skill_id == _selected_skill_id else "skill_row_normal.png")
	if row_tex != null:
		row_panel.add_theme_stylebox_override("panel", _tex_stylebox(row_tex))
	else:
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
	var mastery := GameState.get_skill_mastery(skill.skill_id)
	var total_power := skill.power + mastery * 2
	var atk := _player_effective_attack()
	var dmg_low := int(atk * total_power * 0.85 / 100.0)
	var dmg_high := int(atk * total_power * 1.15 / 100.0)
	btn.text = "%s  ·  %s\n⚔ %d-%d  · 消耗 %d · %d%%" % [
		skill.display_name,
		_kind_text(skill.kind),
		dmg_low, dmg_high,
		skill.mp_cost, total_power,
	]
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
	var mastery := GameState.get_skill_mastery(skill.skill_id)
	var total_power := skill.power + mastery * 2
	var atk := _player_effective_attack()
	var dmg_low := int(atk * total_power * 0.85 / 100.0)
	var dmg_high := int(atk * total_power * 1.15 / 100.0)

	if _quick_btn != null:
		_quick_btn.disabled = false
		if skill.skill_id == _quick_skill_id:
			_set_button_caption(_quick_btn, "已设为快捷")
		else:
			_set_button_caption(_quick_btn, "设为快捷招式")
	if _practice_btn != null:
		_practice_btn.disabled = mastery >= 3
		_set_button_caption(_practice_btn, "研读完成" if mastery >= 3 else "研读招式 (%d/3)" % mastery)
	detail.text = "[b]%s[/b]\n[color=#9fd3d0]%s · %s · 熟练 %d/3（威力 +%d%%）[/color]\n\n[b]战斗参数[/b]\n[color=#ffb14a]伤害：%d - %d[/color]（当前攻击力 %d × 威力 %d%%）\n目标：%s\n内力消耗：%d\n攻击段数：%d\n动画：%s\n\n[b]招式说明[/b]\n%s\n\n[b]使用建议[/b]\n%s" % [
		skill.display_name,
		_kind_text(skill.kind),
		_quick_text(skill),
		mastery,
		mastery * 2,
		dmg_low, dmg_high,
		atk, total_power,
		_target_text(skill.target),
		skill.mp_cost,
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


func _player_effective_attack() -> int:
	var p: CharacterStats = GameState.player
	if p == null: return 10
	var core: int = (p.strength * 2 + p.inner_power) + (Inventory.get_strength_bonus() * 2 + Inventory.get_inner_power_bonus())
	var legacy: int = p.attack + Inventory.get_atk_bonus()
	return max(legacy, core)


func _set_quick_skill() -> void:
	if _selected_skill_id == &"":
		return
	_quick_skill_id = _selected_skill_id
	_show_selected()


func _practice_selected() -> void:
	var skill := _find_skill(_selected_skill_id)
	if skill == null:
		return
	if GameState.practice_skill(skill.skill_id):
		_show_selected()
	else:
		detail.text += "\n\n[color=#9fd3d0]这门招式已经研读至当前上限。[/color]"


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


func _try_load(name: String) -> Texture2D:
	var path: String = "res://art/ui/skill/" + name
	if ResourceLoader.exists(path): return load(path)
	return null


func _runtime_texture(name: String) -> Texture2D:
	var path: String = name if name.begins_with("res://") else "res://art/ui/skill/runtime_v2/" + name
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _runtime_stylebox(texture: Texture2D, left: float = 0.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = left
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _runtime_rect(node: Control, position: Vector2, size: Vector2) -> void:
	node.position = position
	node.size = size


func _runtime_label(parent: Node, text_value: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_runtime_rect(label, position, size)
	parent.add_child(label)
	return label


func _runtime_image(parent: Node, path: String, position: Vector2, size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _runtime_texture(path)
	if image.texture == null and path.begins_with("res://"):
		image.texture = ResourceLoader.load(path) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_runtime_rect(image, position, size)
	parent.add_child(image)
	return image


func _runtime_button(parent: Node, text_value: String, position: Vector2, size: Vector2, normal_name: String, hover_name: String = "", pressed_name: String = "", font_size: int = 16, content_left: float = 8.0) -> Button:
	var button := Button.new()
	button.text = text_value
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.90, 0.96, 0.96, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.62, 1.0))
	button.flat = true
	_runtime_rect(button, position, size)
	var normal := _runtime_texture(normal_name)
	if normal != null:
		button.add_theme_stylebox_override("normal", _runtime_stylebox(normal, content_left))
	var hover := _runtime_texture(hover_name if hover_name != "" else normal_name)
	if hover != null:
		button.add_theme_stylebox_override("hover", _runtime_stylebox(hover, content_left))
	var pressed := _runtime_texture(pressed_name if pressed_name != "" else hover_name)
	if pressed != null:
		button.add_theme_stylebox_override("pressed", _runtime_stylebox(pressed, content_left))
	parent.add_child(button)
	return button


func _setup_runtime_v2() -> void:
	var old_panel := get_node_or_null("Panel") as Control
	if old_panel != null:
		old_panel.visible = false
	_runtime_root = Control.new()
	_runtime_root.name = "RuntimeSkillOverlay"
	_runtime_root.z_index = 3
	_runtime_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_runtime_root.anchor_left = 0.5
	_runtime_root.anchor_top = 0.5
	_runtime_root.anchor_right = 0.5
	_runtime_root.anchor_bottom = 0.5
	_runtime_root.offset_left = -640.0
	_runtime_root.offset_top = -360.0
	_runtime_root.offset_right = 640.0
	_runtime_root.offset_bottom = 360.0
	add_child(_runtime_root)

	var title := _runtime_label(_runtime_root, "", Vector2(280, 34), Vector2(720, 70), 34, UI_THEME.GOLD_LIGHT)
	_runtime_image(_runtime_root, "res://art/ui/skill/text_only_runtime_v1/title_wuxue_text.png", Vector2(591, 42), Vector2(98, 50))
	var close_runtime := _runtime_button(_runtime_root, "", Vector2(1140, 22), Vector2(58, 58), "res://art/ui/inventory/buttons/btn_x_normal.png", "res://art/ui/inventory/buttons/btn_x_hover.png", "res://art/ui/inventory/buttons/btn_x_pressed.png", 16, 0.0)
	close_runtime.flat = false
	close_runtime.pressed.connect(close)

	var faction_crest := TextureRect.new()
	faction_crest.texture = _runtime_texture("faction_huashan.png")
	faction_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	faction_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_runtime_rect(faction_crest, Vector2(RUNTIME_FACTION_CENTER_X - RUNTIME_FACTION_CREST_SIZE * 0.5, 49), Vector2(RUNTIME_FACTION_CREST_SIZE, RUNTIME_FACTION_CREST_SIZE))
	faction_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_runtime_root.add_child(faction_crest)
	var faction_name := _runtime_label(_runtime_root, "华山派", Vector2(RUNTIME_FACTION_CENTER_X - 69.0, 136), Vector2(138, 24), 18, UI_THEME.GOLD_LIGHT)
	faction_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faction_name.z_index = 5

	_runtime_resource_label = _runtime_label(_runtime_root, "总阅历 360\n可用阅历 120", Vector2(980, 42), Vector2(170, 68), 13, UI_THEME.JADE)
	_runtime_resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var primary_move := _runtime_button(_runtime_root, "", Vector2(225, 145), Vector2(400, 50), "primary_tab_normal.png", "primary_tab_selected.png", "primary_tab_selected.png", 20, 0.0)
	var primary_mind := _runtime_button(_runtime_root, "", Vector2(650, 145), Vector2(400, 50), "primary_tab_normal.png", "primary_tab_selected.png", "primary_tab_selected.png", 20, 0.0)
	var move_text_image := _runtime_image(_runtime_root, "res://art/ui/skill/text_only_runtime_v1/tab_zhaoshi_text.png", Vector2(398, 150), Vector2(84, 38))
	var mind_text_image := _runtime_image(_runtime_root, "res://art/ui/skill/text_only_runtime_v1/tab_xinfa_text.png", Vector2(823, 150), Vector2(84, 38))
	_runtime_primary_text_images = [move_text_image, mind_text_image]
	_runtime_primary_buttons = [primary_move, primary_mind]
	primary_move.pressed.connect(func(): _runtime_group = "move"; _runtime_route = "all"; _refresh_runtime_v2())
	primary_mind.pressed.connect(func(): _runtime_group = "mind"; _runtime_route = "general"; _refresh_runtime_v2())

	var category_names: Array[String] = ["全部", "剑法", "棍法", "掌法", "刀法"]
	var category_routes: Array[String] = ["all", "sword", "staff", "palm", "blade"]
	for i in range(category_names.size()):
		var x := RUNTIME_FILTER_X + float(i) * 42.0
		var category := _runtime_button(_runtime_root, category_names[i], Vector2(x, 200), Vector2(43, 32), "secondary_tab_0%d.png" % (i + 1), "secondary_tab_0%d.png" % (i + 1), "secondary_tab_0%d.png" % (i + 1), 12)
		category.flat = false
		_runtime_category_buttons.append(category)
		var route := category_routes[i]
		category.pressed.connect(func(): _runtime_route = route; _refresh_runtime_v2())

	_runtime_count_label = _runtime_label(_runtime_root, "", Vector2(RUNTIME_LIST_X + 4.0, 235), Vector2(RUNTIME_LIST_WIDTH, 24), 13, UI_THEME.MUTED)
	var scroll := ScrollContainer.new()
	_runtime_rect(scroll, Vector2(RUNTIME_LIST_X, 263), Vector2(RUNTIME_LIST_WIDTH, 370))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_runtime_list = VBoxContainer.new()
	_runtime_list.add_theme_constant_override("separation", 8)
	_runtime_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_runtime_list)
	_runtime_root.add_child(scroll)

	var stat_positions: Array[Vector2] = [Vector2(476, 292), Vector2(686, 292), Vector2(896, 292)]
	for stat_position in stat_positions:
		var stat := TextureRect.new()
		stat.texture = _runtime_texture("stat_cell.png")
		stat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_runtime_rect(stat, stat_position, Vector2(200, 62))
		_runtime_root.add_child(stat)
	_runtime_power_label = _runtime_label(_runtime_root, "", Vector2(686, 309), Vector2(200, 28), 17, Color(0.90, 0.96, 0.96, 1.0))
	_runtime_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_runtime_label(_runtime_root, "内力消耗", Vector2(476, 297), Vector2(200, 20), 11, UI_THEME.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_runtime_label(_runtime_root, "威力倍率", Vector2(686, 297), Vector2(200, 20), 11, UI_THEME.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_runtime_label(_runtime_root, "攻击段数", Vector2(896, 297), Vector2(200, 20), 11, UI_THEME.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_runtime_detail = RichTextLabel.new()
	_runtime_detail.bbcode_enabled = true
	_runtime_detail.fit_content = false
	_runtime_detail.scroll_active = false
	_runtime_detail.add_theme_font_size_override("normal_font_size", 15)
	_runtime_detail.add_theme_color_override("default_color", Color(0.84, 0.91, 0.93, 1.0))
	_runtime_rect(_runtime_detail, Vector2(476, 370), Vector2(710, 170))
	_runtime_root.add_child(_runtime_detail)
	_runtime_upgrade_label = _runtime_label(_runtime_root, "", Vector2(420, 582), Vector2(420, 32), 17, Color(0.90, 0.96, 0.96, 1.0))
	_runtime_cost_label = _runtime_label(_runtime_root, "", Vector2(420, 612), Vector2(420, 24), 13, UI_THEME.MUTED)
	_runtime_upgrade_btn = _runtime_button(_runtime_root, "提升招式", Vector2(980, 570), Vector2(220, 64), "upgrade_normal.png", "upgrade_hover.png", "upgrade_pressed.png", 15, 0.0)
	_runtime_upgrade_btn.flat = false
	_runtime_upgrade_btn.position = Vector2(900, 580)
	_runtime_upgrade_btn.size = Vector2(180, 50)
	_runtime_upgrade_btn.pressed.connect(_runtime_upgrade_selected)


func _runtime_route_for(skill: Skill) -> String:
	var value := (String(skill.skill_id) + " " + skill.display_name + " " + skill.description).to_lower()
	if value.contains("sword") or value.contains("剑"):
		return "sword"
	if value.contains("staff") or value.contains("棍"):
		return "staff"
	if value.contains("palm") or value.contains("掌") or value.contains("拳"):
		return "palm"
	if value.contains("blade") or value.contains("刀"):
		return "blade"
	return "general"


func _runtime_skill_texture(skill: Skill) -> Texture2D:
	if skill.icon_path != "" and ResourceLoader.exists(skill.icon_path):
		return load(skill.icon_path)
	if _attr_icon_atlas == null:
		return null
	var icon_key: String = "内劲"
	if _is_defense_skill(skill):
		icon_key = "防御"
	elif skill.kind == Skill.Kind.HEAL or skill.kind == Skill.Kind.BUFF:
		icon_key = "悟性"
	elif skill.kind == Skill.Kind.DEBUFF:
		icon_key = "机敏"
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0.0:
		return null
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = _attr_icon_atlas
	atlas_texture.region = region
	return atlas_texture


func _runtime_is_mind(skill: Skill) -> bool:
	return skill.kind != Skill.Kind.ATTACK or String(skill.skill_id).contains("zixia") or String(skill.skill_id).contains("xinjing")


func _runtime_visible(skill: Skill) -> bool:
	var is_mind := _runtime_is_mind(skill)
	if (_runtime_group == "mind") != is_mind:
		return false
	var route := _runtime_route_for(skill)
	if _runtime_group == "mind" and _runtime_route == "general":
		return route == "general"
	return _runtime_route == "all" or route == _runtime_route


func _refresh_runtime_v2() -> void:
	if _runtime_root == null:
		return
	for child in _runtime_list.get_children():
		child.queue_free()
	var visible_skills: Array[Skill] = []
	for skill in _skills:
		if _runtime_visible(skill):
			visible_skills.append(skill)
	_runtime_count_label.text = "已习得  %d 门武学" % visible_skills.size()
	for index in range(_runtime_primary_buttons.size()):
		var primary_active := (_runtime_group == "move" and index == 0) or (_runtime_group == "mind" and index == 1)
		_runtime_primary_buttons[index].add_theme_stylebox_override("normal", _runtime_stylebox(_runtime_texture("primary_tab_selected.png" if primary_active else "primary_tab_normal.png")))
		_runtime_primary_buttons[index].add_theme_stylebox_override("hover", _runtime_stylebox(_runtime_texture("primary_tab_selected.png" if primary_active else "primary_tab_normal.png")))
		_runtime_primary_text_images[index].modulate = Color(1.0, 1.0, 1.0, 1.0) if primary_active else Color(0.48, 0.58, 0.60, 1.0)
	for index in range(_runtime_category_buttons.size()):
		var active_route: String = "general" if _runtime_group == "mind" and index == 0 else ("all" if _runtime_group == "move" and index == 0 else ["sword", "staff", "palm", "blade"][index - 1] if index > 0 else "")
		_runtime_category_buttons[index].text = "通用" if _runtime_group == "mind" and index == 0 else ("全部" if _runtime_group == "move" and index == 0 else ["剑法", "棍法", "掌法", "刀法"][index - 1] if index > 0 else "")
		var category_active := active_route == _runtime_route
		_runtime_category_buttons[index].disabled = false
		_runtime_category_buttons[index].add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT if category_active else UI_THEME.MUTED)
		_runtime_category_buttons[index].add_theme_color_override("font_hover_color", UI_THEME.GOLD_LIGHT)
	if visible_skills.is_empty():
		_runtime_detail.text = "[b]当前分类下暂无已习得武学。[/b]"
		return
	if _runtime_selected_id == &"" or not visible_skills.any(func(skill: Skill): return skill.skill_id == _runtime_selected_id):
		_runtime_selected_id = visible_skills[0].skill_id
	for skill in visible_skills:
		_runtime_list.add_child(_runtime_make_row(skill))
	_runtime_show_selected()


func _runtime_make_row(skill: Skill) -> Button:
	var row := Button.new()
	row.text = "%s\n%s · %s" % [skill.display_name, "心法" if _runtime_is_mind(skill) else _kind_text(skill.kind), "Lv.1"]
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.custom_minimum_size = Vector2(190, 70)
	row.add_theme_font_size_override("font_size", 14)
	row.add_theme_color_override("font_color", Color(0.88, 0.95, 0.96, 1.0))
	row.add_theme_stylebox_override("normal", _runtime_stylebox(_runtime_texture("skill_row_selected.png" if skill.skill_id == _runtime_selected_id else "skill_row_normal.png"), 58.0))
	row.add_theme_stylebox_override("hover", _runtime_stylebox(_runtime_texture("skill_row_selected.png"), 58.0))
	var icon := TextureRect.new()
	icon.texture = _runtime_skill_texture(skill)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_runtime_rect(icon, Vector2(8, 9), Vector2(48, 48))
	row.add_child(icon)
	row.pressed.connect(func(): _runtime_selected_id = skill.skill_id; _refresh_runtime_v2())
	return row


func _runtime_show_selected() -> void:
	var skill: Skill = null
	for item in _skills:
		if item.skill_id == _runtime_selected_id:
			skill = item
			break
	if skill == null:
		return
	_runtime_power_label.text = "%d%%" % skill.power
	_runtime_detail.text = "[b]战斗参数[/b]\n内力消耗：%d    攻击段数：%d\n\n[b]招式说明[/b]\n%s" % [skill.mp_cost, skill.hit_count, skill.description]
	_runtime_upgrade_label.text = "招式内容 Lv.1"
	_runtime_cost_label.text = "消耗阅历 30    ·    升级后威力 +10%"
	_runtime_upgrade_btn.disabled = _runtime_insight < 30


func _runtime_upgrade_selected() -> void:
	if _runtime_insight < 30:
		return
	_runtime_insight -= 30
	_runtime_resource_label.text = "总阅历 360\n可用阅历 %d" % _runtime_insight
	_runtime_cost_label.text = "消耗阅历 30    ·    已提升，当前威力 +10%"



func _tex_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	return sb


func _apply_btn_textures(btn: Button, base_name: String) -> void:
	var t_n: Texture2D = _try_load(base_name + "_normal.png")
	if t_n == null: return
	btn.flat = true
	btn.text = ""
	btn.custom_minimum_size = Vector2(t_n.get_width(), t_n.get_height())
	btn.add_theme_stylebox_override("normal", _tex_stylebox(t_n))
	var t_h: Texture2D = _try_load(base_name + "_hover.png")
	if t_h != null: btn.add_theme_stylebox_override("hover", _tex_stylebox(t_h))
	var t_p: Texture2D = _try_load(base_name + "_pressed.png")
	if t_p != null: btn.add_theme_stylebox_override("pressed", _tex_stylebox(t_p))
	var lbl: Label = Label.new()
	lbl.text = btn.tooltip_text if btn.tooltip_text != "" else ""
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)


func _set_button_caption(btn: Button, label_text: String) -> void:
	btn.text = ""
	var caption := btn.get_node_or_null("Caption") as Label
	if caption != null:
		caption.text = label_text


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
