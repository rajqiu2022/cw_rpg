extends "res://scripts/ui/dialog_box.gd"
## Shared dialogue presentation. DialogPlayer continues to own all story actions.

const ART := preload("res://scripts/ui/lacquer_ui.gd")
const GOLD := Color("#efd39a")
const FRAME_CAPS := Vector2(134, 137)
# Sample the three vertical bands on one quad so viewport scaling cannot
# expose a gap between them. The corner artwork keeps its aspect ratio.
const FRAME_SHADER := """
shader_type canvas_item;

uniform vec4 source_rect_px;
uniform vec2 cap_source_px;
uniform vec2 cap_screen_uv;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	float bottom_start = 1.0 - cap_screen_uv.y;
	float y;
	if (UV.y < cap_screen_uv.x) {
		y = UV.y / cap_screen_uv.x * cap_source_px.x;
	} else if (UV.y > bottom_start) {
		y = source_rect_px.w - (1.0 - UV.y) / cap_screen_uv.y * cap_source_px.y;
	} else {
		float progress = (UV.y - cap_screen_uv.x) / (bottom_start - cap_screen_uv.x);
		y = mix(cap_source_px.x, source_rect_px.w - cap_source_px.y, progress);
	}
	vec2 source_px = source_rect_px.xy + vec2(UV.x * source_rect_px.z, y);
	COLOR = texture(TEXTURE, source_px * TEXTURE_PIXEL_SIZE) * vertex_tint;
}
"""

@onready var _frame: Control = $Frame
var _frame_material: ShaderMaterial
var _frame_source_size: Vector2
const BUSTS := preload("res://scripts/ui/dialog_busts.gd")
var _speaker_left := false
var _nameplate: TextureRect
var _continue_art: TextureRect
var _scroll: ScrollContainer
var _choice_normal: StyleBoxTexture
var _choice_hover: StyleBoxTexture
var _decision_row: BoxContainer
var _decision_buttons: Array[Button] = []
var _has_portrait := false
var _speaker_given := false
var _layout_pending := false
var _layout_revision := 0


func _ready() -> void:
	_nameplate = _insert_art(ART.control_texture(ART.Shape.ACTION), speaker_label)
	_continue_art = _insert_art(ART.control_texture(ART.Shape.ACTION, 1), continue_hint)
	_choice_normal = ART.surface(ART.Shape.CARD, 0, Vector4(22, 10, 22, 10))
	_choice_hover = ART.surface(ART.Shape.CARD, 1, Vector4(22, 10, 22, 10))

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_frame.add_child(_scroll)
	choices_container.reparent(_scroll, false)
	choices_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	choices_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_container.add_theme_constant_override("separation", 6)
	$Frame/TextPlaceholder.hide()
	super._ready()
	resized.connect(_schedule_layout)


func _insert_art(texture: Texture2D, before: Control) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(rect)
	_frame.move_child(rect, before.get_index())
	return rect


func _load_frame_textures() -> void:
	var region := ART.frame_texture().region
	_frame_source_size = region.size
	var shader := Shader.new()
	shader.code = FRAME_SHADER
	_frame_material = ShaderMaterial.new()
	_frame_material.shader = shader
	_frame_material.set_shader_parameter("source_rect_px", Vector4(
		region.position.x, region.position.y, region.size.x, region.size.y))
	_frame_material.set_shader_parameter("cap_source_px", FRAME_CAPS)
	frame_art.texture = ART.FRAME
	frame_art.stretch_mode = TextureRect.STRETCH_SCALE
	frame_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame_art.material = _frame_material


func _set_narration_layout(is_narration: bool) -> void:
	_has_portrait = not is_narration
	portrait_placeholder.hide()
	speaker_label.visible = true
	if speaker_label.text.is_empty() or not _speaker_given:
		speaker_label.text = "旁白"


func _on_text_displayed(speaker: String, text: String, has_choices: bool, portrait_path: String) -> void:
	_speaker_given = not speaker.is_empty()
	_speaker_left = BUSTS.is_party_speaker(speaker)
	super._on_text_displayed(speaker, text, has_choices, "")
	portrait.texture = BUSTS.for_speaker(speaker, portrait_path, get_tree().current_scene, DialogPlayer._current_script)
	portrait.visible = portrait.texture != null
	_has_portrait = portrait.visible
	_continue_art.visible = not has_choices
	_scroll.visible = has_choices
	_scroll.scroll_vertical = 0
	_schedule_layout()


func _choice_summary(text: String) -> String:
	return text


func _apply_visual_style() -> void:
	UI_THEME.style_label(speaker_label, 26, GOLD)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speaker_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI_THEME.style_label(continue_hint, 18, ART.IVORY)
	continue_hint.text = "继续  ›"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("default_color", ART.IVORY)
	text_label.add_theme_constant_override("line_separation", 6)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.scroll_active = true
	text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_placeholder.color = Color.TRANSPARENT


func _on_choices_displayed(choices: Array) -> void:
	_clear_choices()
	_scroll.show()
	choices_container.show()
	continue_hint.hide()
	_continue_art.hide()
	# Only an accept/decline pair for the same quest uses these buttons.
	# Mixed menus, investigations and story route choices keep the option list.
	if choices.size() == 2 and choices[0].has("accept_quest") and choices[0].get("accept_quest") == choices[1].get("decline_quest"):
		_show_decision_buttons(choices)
		_schedule_layout()
		return
	for i in choices.size():
		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.custom_minimum_size.y = 46
		row.add_theme_stylebox_override("panel", _choice_normal)
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "%d  ·  %s" % [i + 1, str(choices[i].get("text", ""))]
		UI_THEME.style_label(label, 20, ART.IVORY)
		row.add_child(label)
		choices_container.add_child(row)
		_choice_rows.append(row)
		_choice_labels.append(label)
	_schedule_layout()


func _show_decision_buttons(choices: Array) -> void:
	_decision_row = BoxContainer.new()
	_decision_row.name = "QuestDecisionButtons"
	_decision_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_decision_row.add_theme_constant_override("separation", 12)
	choices_container.add_child(_decision_row)
	for index in choices.size():
		var accept := index == 0
		var button := Button.new()
		button.name = "AcceptQuest" if accept else "DeclineQuest"
		button.text = "%d  ·  %s" % [index + 1, str(choices[index].get("text", ""))]
		button.custom_minimum_size = Vector2(188, 46)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color("#d6e4ce") if accept else Color("#d1d1cc"))
		button.add_theme_color_override("font_hover_color", ART.IVORY)
		button.add_theme_color_override("font_pressed_color", ART.IVORY)
		var normal := _decision_surface(0, Color("#83bf68") if accept else Color("#c5a886"))
		var hover := _decision_surface(1, Color("#9fce7b") if accept else Color("#dbc2a1"))
		var pressed := _decision_surface(2, Color("#73a65f") if accept else Color("#b19b82"))
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("hover_pressed", pressed)
		var focus := StyleBoxFlat.new()
		focus.draw_center = false
		focus.border_color = Color("#94ad81") if accept else Color("#a5a29b")
		focus.set_border_width_all(1)
		button.add_theme_stylebox_override("focus", focus)
		button.pressed.connect(DialogPlayer.choose.bind(index))
		_decision_row.add_child(button)
		_decision_buttons.append(button)


func _decision_surface(state: int, tint: Color) -> StyleBoxTexture:
	var box := ART.surface(ART.Shape.ACTION, state, Vector4(15, 6, 15, 6))
	box.modulate_color = tint
	return box


func _clear_choices() -> void:
	if is_instance_valid(_decision_row):
		choices_container.remove_child(_decision_row)
		_decision_row.queue_free()
	_decision_row = null
	_decision_buttons.clear()
	for row in _choice_rows:
		choices_container.remove_child(row)
		row.queue_free()
	_choice_rows.clear()
	_choice_labels.clear()
	_choice_rects.clear()
	_hovered_idx = -1


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if choices_container.visible and not _decision_buttons.is_empty():
		# Native Buttons own click, touch, hover and focus. Keep the dialogue's
		# numbered shortcuts without forwarding clicks to the generic rows.
		if event is InputEventKey and event.pressed and not event.echo:
			var index: int = event.keycode - KEY_1
			if index >= 0 and index < _decision_buttons.size():
				get_viewport().set_input_as_handled()
				DialogPlayer.choose(index)
		return
	if not choices_container.visible or _choice_rows.is_empty():
		super._input(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < mini(9, _choice_rows.size()):
			get_viewport().set_input_as_handled()
			DialogPlayer.choose(idx)
			return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		# Re-read live row rectangles after scrolling or resizing; outside the
		# clipped option band can never select a scrolled-off choice.
		_refresh_choice_rects()
		if event is InputEventMouseMotion:
			_update_hover(event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in _choice_rects.size():
				if _choice_rects[i].has_point(event.position):
					get_viewport().set_input_as_handled()
					DialogPlayer.choose(i)
					return


func _refresh_choice_rects() -> void:
	_choice_rects.clear()
	var clipped_to := _scroll.get_global_rect()
	for row in _choice_rows:
		_choice_rects.append(clipped_to.intersection(row.get_global_rect()))


func _update_hover(mouse_pos: Vector2) -> void:
	var next := -1
	for i in _choice_rects.size():
		if _choice_rects[i].has_point(mouse_pos):
			next = i
			break
	if _hovered_idx == next:
		return
	if _hovered_idx >= 0 and _hovered_idx < _choice_rows.size():
		_choice_rows[_hovered_idx].add_theme_stylebox_override("panel", _choice_normal)
		_choice_labels[_hovered_idx].add_theme_color_override("font_color", ART.IVORY)
	if next >= 0:
		_choice_rows[next].add_theme_stylebox_override("panel", _choice_hover)
		_choice_labels[next].add_theme_color_override("font_color", GOLD)
	_hovered_idx = next


func _schedule_layout() -> void:
	_layout_revision += 1
	if not _layout_pending:
		_layout_pending = true
		_layout_dialog.call_deferred()


func _layout_dialog() -> void:
	_layout_pending = false
	if not visible:
		return
	var revision := _layout_revision
	var options := _scroll.visible
	var narrow := size.x < 900.0
	var width := minf(size.x - 32.0, 1320.0)
	var pad := 26.0 if narrow else 58.0
	var bust_width := minf(width * 0.27, 345.0)
	var portrait_column := bust_width + 12.0 if _has_portrait else 0.0
	var content_left := pad + (portrait_column if _speaker_left else 0.0)
	var content_width := maxf(32.0, width - 2.0 * pad - portrait_column)
	var body_top := 63.0 if narrow else 79.0
	var bottom_pad := 24.0 if narrow else 34.0
	_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_set_dialog_text_font_size(21 if narrow else 25)
	text_label.position = Vector2(content_left, body_top)
	text_label.size.x = content_width
	_scroll.position.x = content_left
	_scroll.size.x = content_width
	for label in _choice_labels:
		label.add_theme_font_size_override("font_size", 18 if narrow else 20)
	if is_instance_valid(_decision_row):
		var side_by_side := content_width >= 350.0
		_decision_row.vertical = not side_by_side
		var button_width := minf(188.0, floorf((content_width - 12.0) / 2.0)) if side_by_side else minf(content_width, 188.0)
		for button in _decision_buttons:
			button.add_theme_font_size_override("font_size", 18 if narrow else 20)
			button.custom_minimum_size.x = button_width
	await get_tree().process_frame
	if revision != _layout_revision or not visible:
		return

	var limit := minf(size.y - 24.0, maxf(235.0, size.y * (0.58 if options else 0.48)))
	var body_height := clampf(float(text_label.get_content_height()) + 4.0, 34.0, maxf(34.0, minf(145.0 if options else 246.0, limit - body_top - (95.0 if options else 64.0))))
	var options_top := body_top + body_height + 10.0
	var rows_height := clampf(choices_container.get_combined_minimum_size().y, 46.0, maxf(46.0, limit - options_top - bottom_pad))
	var art_scale := width / _frame_source_size.x
	var frame_minimum := (FRAME_CAPS.x + FRAME_CAPS.y) * art_scale + 48.0
	var content_height := options_top + rows_height + bottom_pad if options else body_top + body_height + bottom_pad + 40.0
	var height := maxf(frame_minimum, content_height)
	_frame.position = Vector2((size.x - width) * 0.5, size.y - height - (16.0 if narrow else 32.0))
	_frame.size = Vector2(width, height)
	_frame_material.set_shader_parameter("cap_screen_uv", FRAME_CAPS * art_scale / height)
	if _has_portrait:
		var aspect := portrait.texture.get_width() / float(portrait.texture.get_height())
		var bust_height := height * 1.30
		var bust_size := Vector2(minf(bust_width, bust_height * aspect), bust_height)
		var bust_x := pad if _speaker_left else width - pad - bust_size.x
		_set_art_rect(portrait, Rect2(Vector2(bust_x, -height / 3.0), bust_size))
	var plaque_width := minf(content_width, 135.0 if narrow else 170.0)
	var plaque_size := Vector2(plaque_width, plaque_width * _nameplate.texture.get_height() / _nameplate.texture.get_width())
	var ornament_clearance := 176.0 * art_scale
	var name_x := maxf(content_left, ornament_clearance)
	if _speaker_given and not _speaker_left and speaker_label.text not in ["旁白", "旧船单"]:
		name_x = minf(content_left + content_width, width - ornament_clearance) - plaque_width
	_set_art_rect(_nameplate, Rect2(Vector2(name_x, 16.0 if narrow else 22.0), plaque_size))
	speaker_label.add_theme_font_size_override("font_size", 20 if narrow else 26)
	speaker_label.position = _nameplate.position + Vector2(12, 0)
	speaker_label.size = plaque_size - Vector2(24, 0)
	text_label.size = Vector2(content_width, body_height)
	_scroll.position = Vector2(content_left, options_top)
	_scroll.size = Vector2(content_width, rows_height)
	var action_size := Vector2(118, 32) if narrow else Vector2(148, 40)
	var action_inset := maxf(pad, 112.0 * art_scale)
	_set_art_rect(_continue_art, Rect2(Vector2(minf(width - action_inset, content_left + content_width) - action_size.x, height - bottom_pad - action_size.y), action_size))
	continue_hint.position = _continue_art.position
	continue_hint.size = action_size


func _set_art_rect(control: Control, bounds: Rect2) -> void:
	control.position = bounds.position
	control.size = bounds.size
