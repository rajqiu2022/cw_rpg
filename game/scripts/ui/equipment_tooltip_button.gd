class_name EquipmentTooltipButton
extends Button

## 角色界面的装备属性提示。固定为易读的横向长方形，属性文本由调用方逐行提供。

const TOOLTIP_MIN_WIDTH := 400.0
const DEFAULT_QUALITY_COLOR := Color("#c0c8d0")
const STAT_COLOR := Color("#72d2a6")
const HINT_COLOR := Color("#9aa8ad")
const EQUIPMENT_STATS := preload("res://scripts/ui/equipment_stat_presentation.gd")

var equipment_quality_color := DEFAULT_QUALITY_COLOR
var equipment_stat_rows: Array[Dictionary] = []


func set_stat_rows(rows: Array[Dictionary]) -> void:
	equipment_stat_rows = rows.duplicate(true)


static func compose_text(display_name: String, stat_lines: Array[String]) -> String:
	var rows := "\n".join(stat_lines) if not stat_lines.is_empty() else "无额外属性"
	return "%s\n%s\n\n%s" % [display_name, rows, "左键查看 · 右键卸下"]


func set_quality_color(color: Color) -> void:
	equipment_quality_color = color


func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.strip_edges().is_empty():
		return null
	var panel := PanelContainer.new()
	panel.name = "EquipmentTooltip"
	panel.custom_minimum_size = Vector2(TOOLTIP_MIN_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.045, 0.97)
	style.border_color = Color(0.28, 0.62, 0.64, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = Color(0, 0, 0, 0.52)
	style.shadow_size = 7
	panel.add_theme_stylebox_override("panel", style)

	var sections := for_text.split("\n\n", false, 1)
	var detail_lines := sections[0].split("\n", false)
	if detail_lines.is_empty():
		return null

	var content := VBoxContainer.new()
	content.name = "EquipmentTooltipContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)

	var name_label := Label.new()
	name_label.name = "EquipmentTooltipName"
	name_label.text = detail_lines[0]
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", equipment_quality_color)
	content.add_child(name_label)

	var regular_lines: Array[String] = []
	var special_lines: Array[String] = []
	for line in detail_lines.slice(1):
		if String(line).begins_with("◆"):
			special_lines.append(String(line))
		else:
			regular_lines.append(String(line))
	var stat_label := RichTextLabel.new()
	stat_label.name = "EquipmentTooltipStats"
	stat_label.bbcode_enabled = true
	stat_label.fit_content = true
	stat_label.scroll_active = false
	stat_label.custom_minimum_size.x = TOOLTIP_MIN_WIDTH - 40.0
	var colored_lines: Array[String] = []
	if not equipment_stat_rows.is_empty():
		special_lines.clear()
	for row in equipment_stat_rows:
		if row.get("kind", "stat") == "special":
			special_lines.append(row.text)
		else:
			colored_lines.append("[color=%s]%s[/color]" % [EQUIPMENT_STATS.row_color(row, equipment_quality_color.to_html()), row.text])
	# Legacy callers without structured values remain neutral; never infer
	# penalties from punctuation in translated prose or special effects.
	stat_label.text = "\n".join(colored_lines) if not colored_lines.is_empty() else ("\n".join(regular_lines) if not regular_lines.is_empty() else "无额外属性")
	stat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stat_label.add_theme_font_size_override("normal_font_size", 18)
	stat_label.add_theme_constant_override("line_spacing", 5)
	stat_label.add_theme_color_override("default_color", HINT_COLOR)
	content.add_child(stat_label)
	if not special_lines.is_empty():
		var special_label := Label.new()
		special_label.name = "EquipmentTooltipSpecial"
		special_label.text = "\n".join(special_lines)
		special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		special_label.add_theme_font_size_override("font_size", 17)
		special_label.add_theme_color_override("font_color", equipment_quality_color)
		special_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(special_label)

	if sections.size() > 1 and not sections[1].strip_edges().is_empty():
		var hint_label := Label.new()
		hint_label.name = "EquipmentTooltipHint"
		hint_label.text = sections[1].strip_edges()
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.add_theme_font_size_override("font_size", 16)
		hint_label.add_theme_color_override("font_color", HINT_COLOR)
		content.add_child(hint_label)
	return panel
