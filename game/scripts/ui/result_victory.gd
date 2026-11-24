extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const FORMAL_BACKGROUND_PATH := "res://art/ui/system/ui_result_panel_formal_v1.png"
const TITLE_ART_PATH := "res://art/ui/title/title_victory_v1.png"
const CONTINUE_BUTTON_NORMAL_PATH := "res://art/ui/button/btn_menu_frame_normal.png"
const CONTINUE_BUTTON_HOVER_PATH := "res://art/ui/button/btn_menu_frame_hover.png"
const CONTINUE_BUTTON_PRESSED_PATH := "res://art/ui/button/btn_menu_frame_pressed.png"
const REWARD_NAME_COLOR := "#c5e5ff"
const REWARD_EXP_COLOR := "#83dec1"
const REWARD_GOLD_COLOR := "#ffd47c"
const GOLD_ICON_PATH := "res://art/ui/quest/reward_gold_icon_v1.png"
const ICON_DIR := "res://art/ui/inventory/icons/"
const EQUIPMENT_ICON_FALLBACKS := {
	Equipment.Slot.WEAPON: "icon_sword.png",
	Equipment.Slot.HEAD: "icon_iron_helmet.png",
	Equipment.Slot.ARMOR: "icon_armor.png",
	Equipment.Slot.HANDS: "icon_leather_bracers.png",
	Equipment.Slot.SHOES: "icon_deer_leather_boots.png",
	Equipment.Slot.ACCESSORY: "icon_ring.png",
}

class VictoryItemDetailTip extends "res://scripts/ui/quest_reward_detail_tip.gd":
	const EQUIPMENT_STATS := preload("res://scripts/ui/equipment_stat_presentation.gd")

	func _equipment_stat_lines(equipment: Equipment) -> Array[String]:
		var lines: Array[String] = []
		var quality: String = QUALITY_COLORS.get(equipment.quality, "#c0c8d0")
		for row in EQUIPMENT_STATS.rows(equipment):
			lines.append("[color=%s]%s[/color]" % [EQUIPMENT_STATS.row_color(row, quality), row.text])
		return lines


@onready var bg: ColorRect = $Bg
@onready var title: Label = $Title
@onready var reward_label: RichTextLabel = %RewardLabel
@onready var btn_continue: Button = %BtnContinue

var _formal_background_active: bool = false
var _item_counts: Dictionary = {}
var _item_tip: ItemDetailTip


func _ready() -> void:
	var sting := AudioManager.get_node_or_null("MusicStingPlayer") as AudioStreamPlayer
	if sting == null or not sting.playing or sting.stream == null or sting.stream.resource_path != BattleActor.VICTORY_MUSIC:
		AudioManager.play_music_sting(BattleActor.VICTORY_MUSIC)
	_install_formal_background()
	_install_title_art()
	var payload: Dictionary = SceneRouter.get_result_payload()
	var gold: int = int(payload.get("gold", 0))
	var exp: int = int(payload.get("exp", 0))

	if StringName(payload.get("battle_mode", &"")) == &"sparring":
		var training := int(payload.get("training", 0))
		var opponent := String(payload.get("opponent_name", "江湖同道"))
		var opponent_text := _reward_color(_reward_literal(opponent), REWARD_NAME_COLOR)
		if training > 0:
			reward_label.text = "与 %s 切磋胜出\n首次胜利 · 获得阅历  %s 点" % [opponent_text, _reward_color(str(training), REWARD_EXP_COLOR)]
		else:
			reward_label.text = "与 %s 切磋胜出\n已领过首胜奖励 · 本次仅作试招" % opponent_text
	else:
		var bounty_result: Dictionary = payload.get("bounty_result", {})
		var reward_text := _build_party_reward_text(exp, payload.get("party_exp_results", []), true)
		reward_text += "\n\n" + _build_item_reward_text(gold, payload, bounty_result)
		if not bounty_result.is_empty():
			reward_text += "\n\n" + _reward_literal("%s\n%s" % [bounty_result.get("title", "通缉结案"), bounty_result.get("summary", "")])
		reward_label.text = reward_text
		reward_label.mouse_filter = Control.MOUSE_FILTER_PASS
		reward_label.meta_clicked.connect(_show_item_tip)
		_item_tip = VictoryItemDetailTip.new()
		_item_tip.name = "RewardItemDetailTip"
		add_child(_item_tip)
	_apply_visual_style()
	btn_continue.pressed.connect(_on_continue_pressed)


func _build_party_reward_text(exp: int, raw_results: Variant, styled: bool = false) -> String:
	var header := _reward_color("获得经验", REWARD_GOLD_COLOR) if styled else "获得经验"
	var lines: PackedStringArray = [header]
	var results: Array = raw_results if raw_results is Array else []
	if results.is_empty():
		var exp_text := _reward_color(str(exp), REWARD_EXP_COLOR) if styled else str(exp)
		lines.append("%s 点" % exp_text)
		return "\n".join(lines)
	for raw: Variant in results:
		if not (raw is Dictionary):
			continue
		var row: Dictionary = raw
		var name := String(row.get("display_name", row.get("character_id", "队友")))
		var gained := int(row.get("exp_gained", exp))
		var before := int(row.get("level_before", 1))
		var after := int(row.get("level_after", before))
		var gain_text := "+%d" % gained
		if styled:
			name = _reward_color(_reward_literal(name), REWARD_NAME_COLOR)
			gain_text = _reward_color(gain_text, REWARD_EXP_COLOR)
		var line := "%s  经验 %s" % [name, gain_text]
		if after > before:
			line += "　Lv.%d → Lv.%d  等级提升" % [before, after]
		lines.append(line)
	return "\n".join(lines)


func _reward_color(value: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, value]


func _build_item_reward_text(gold: int, payload: Dictionary, bounty: Dictionary) -> String:
	var lines: PackedStringArray = [_reward_color("获得道具", REWARD_GOLD_COLOR)]
	var rows: Array = payload.get("item_drops", []).duplicate()
	var legacy_elite: Variant = payload.get("elite_loot", [])
	if not payload.has("item_drops") and legacy_elite is Array:
		for elite: Dictionary in legacy_elite:
			var collected := int(elite.get("collected", false))
			rows.append({"item_id": elite.item_id, "count": collected, "uncollected": 1 - collected})
	rows.append_array(bounty.get("item_drops", []))
	var uncollected: Dictionary = {}
	for row: Variant in rows:
		var item_id := StringName(row.item_id)
		var count := int(row.get("count", 0))
		var missed := int(row.get("uncollected", 0))
		if count > 0:
			_item_counts[item_id] = int(_item_counts.get(item_id, 0)) + count
		if missed > 0:
			uncollected[item_id] = int(uncollected.get(item_id, 0)) + missed
	if gold > 0:
		lines.append("%s  %s  ×%s 两" % [_reward_icon(GOLD_ICON_PATH), _reward_color("金钱", REWARD_GOLD_COLOR), _reward_color(str(gold), REWARD_GOLD_COLOR)])
	for item_id: StringName in _item_counts:
		var item := Inventory.load_item_by_id(item_id)
		var quality: String = ItemDetailTip.QUALITY_COLORS.get(item.quality, "#c0c8d0")
		var clickable_name := "[url=%s]%s[/url]" % [item_id, _reward_color(_reward_literal(item.display_name), quality)]
		lines.append("%s  %s  ×%d" % [_reward_icon(_item_icon_path(item)), clickable_name, _item_counts[item_id]])
	if lines.size() == 1:
		lines.append("无")
	for item_id: StringName in uncollected:
		var item := Inventory.load_item_by_id(item_id)
		lines.append(_reward_color("背包已满，未拾取 %s ×%d" % [_reward_literal(item.display_name), uncollected[item_id]], "#f4c486"))
	return "\n".join(lines)


func _item_icon_path(item: Item) -> String:
	if not item.icon_path.is_empty() and ResourceLoader.exists(item.icon_path, "Texture2D"):
		return item.icon_path
	if item is Equipment:
		return ICON_DIR + EQUIPMENT_ICON_FALLBACKS.get(item.slot, "icon_scroll.png")
	match item.category:
		Item.Category.CONSUMABLE: return ICON_DIR + "icon_potion.png"
		Item.Category.MATERIAL: return ICON_DIR + "icon_ore.png"
		Item.Category.KEY_ITEM: return ICON_DIR + "icon_key.png"
	return ICON_DIR + "icon_scroll.png"


func _reward_icon(path: String) -> String:
	return "[img=32x32 center]%s[/img]" % path


func _show_item_tip(meta: Variant) -> void:
	var item_id := StringName(meta)
	if not _item_counts.has(item_id):
		return
	var item := Inventory.load_item_by_id(item_id)
	_item_tip.show_item(item, _item_counts[item_id])
	var details := reward_label.get_global_rect()
	var tip_size := _item_tip.size
	var viewport_rect := get_global_rect().grow(-12)
	var tip_position := Vector2(details.end.x + 16, details.get_center().y - tip_size.y * 0.5)
	if tip_position.x + tip_size.x > viewport_rect.end.x:
		tip_position.x = details.position.x - tip_size.x - 16
	_item_tip.global_position = tip_position.clamp(viewport_rect.position, viewport_rect.end - tip_size)


func _reward_literal(value: String) -> String:
	return value.replace("[", "[lb]")


func _install_formal_background() -> void:
	if not ResourceLoader.exists(FORMAL_BACKGROUND_PATH):
		return
	var texture: Texture2D = load(FORMAL_BACKGROUND_PATH) as Texture2D
	if texture == null:
		return
	var formal_background: TextureRect = TextureRect.new()
	formal_background.name = "FormalBackground"
	formal_background.texture = texture
	formal_background.modulate = Color.WHITE
	formal_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	formal_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	formal_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	formal_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(formal_background)
	move_child(formal_background, 0)
	_formal_background_active = true


func _install_title_art() -> void:
	if not ResourceLoader.exists(TITLE_ART_PATH) or title == null:
		return
	var title_art := TextureRect.new()
	title_art.name = "TitleArt"
	title_art.texture = load(TITLE_ART_PATH) as Texture2D
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_art.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_art.position = Vector2(-320, 120)
	title_art.size = Vector2(640, 220)
	title_art.pivot_offset = title_art.size * 0.5
	title_art.modulate = Color(1, 1, 1, 0.98)
	add_child(title_art)
	title.visible = false


func _apply_visual_style() -> void:
	if bg != null:
		bg.visible = not _formal_background_active
		bg.color = Color(0.028, 0.038, 0.052, 1.0)
	UI_THEME.style_label(title, 96, UI_THEME.GOLD_LIGHT)
	reward_label.add_theme_font_size_override("normal_font_size", 25)
	reward_label.add_theme_color_override("default_color", UI_THEME.TEXT)
	reward_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	reward_label.add_theme_constant_override("shadow_offset_x", 2)
	reward_label.add_theme_constant_override("shadow_offset_y", 2)
	if not _install_continue_button_art():
		UI_THEME.style_button(btn_continue, 24, UI_THEME.GOLD)
	btn_continue.icon = null
	btn_continue.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _install_continue_button_art() -> bool:
	var paths: Array[String] = [
		CONTINUE_BUTTON_NORMAL_PATH,
		CONTINUE_BUTTON_HOVER_PATH,
		CONTINUE_BUTTON_PRESSED_PATH,
	]
	for path: String in paths:
		if not ResourceLoader.exists(path):
			return false
	btn_continue.add_theme_stylebox_override("normal", _button_style(CONTINUE_BUTTON_NORMAL_PATH))
	btn_continue.add_theme_stylebox_override("hover", _button_style(CONTINUE_BUTTON_HOVER_PATH))
	btn_continue.add_theme_stylebox_override("pressed", _button_style(CONTINUE_BUTTON_PRESSED_PATH))
	btn_continue.add_theme_stylebox_override("focus", _button_style(CONTINUE_BUTTON_HOVER_PATH))
	btn_continue.add_theme_font_size_override("font_size", 24)
	btn_continue.add_theme_color_override("font_color", UI_THEME.TEXT)
	btn_continue.add_theme_color_override("font_hover_color", Color.WHITE)
	btn_continue.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	return true


func _button_style(path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	style.texture_margin_left = 24.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 20.0
	style.content_margin_top = 8.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 8.0
	return style


func _on_continue_pressed() -> void:
	var payload: Dictionary = SceneRouter.get_result_payload()

	var return_scene: StringName = payload.get("return_scene", &"")
	var bounty_result: Dictionary = payload.get("bounty_result", {})
	var victory_action: String = String(bounty_result.get("return_action",payload.get("victory_action","")))
	if String(return_scene) != "":
		SceneRouter.return_from_battle_payload(payload, victory_action)
	else:
		SceneRouter.go_field_smart(SceneRouter.START_FIELD_SCENE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_instance_valid(_item_tip) and _item_tip.visible:
			_item_tip.hide_tip()
			return
		_on_continue_pressed()
