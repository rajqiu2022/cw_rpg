extends RefCounted

const ART := preload("res://scripts/ui/lacquer_ui.gd")

static func install(dialog: FormalConfirmDialog) -> void:
	var frame := dialog._panel_art
	ART.use_frame(frame)
	dialog.get_node("Dim").color = Color(0.02, 0.045, 0.05, 0.53)
	dialog._title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialog._title.position = Vector2(42, 27)
	dialog._title.add_theme_color_override("font_color", Color("#eed8a1"))
	dialog._title.add_theme_font_size_override("font_size", 26)
	dialog._message.position = Vector2(42, 86)
	dialog._message.size = Vector2(576, 139)
	dialog._message.scroll_active = true
	for button in [dialog._confirm_button, dialog._cancel_button]:
		ART.style_button(button, ART.Shape.ACTION, button == dialog._confirm_button)
		button.focus_mode = Control.FOCUS_ALL
		button.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
		button.add_theme_font_size_override("font_size", 19)
	var rewards := HBoxContainer.new()
	rewards.position = Vector2(42, 83)
	rewards.size = Vector2(576, 71)
	rewards.add_theme_constant_override("separation", 14)
	frame.add_child(rewards)
	for caption in ["首次胜利", "首次落败"]:
		var card := Panel.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", ART.surface())
		rewards.add_child(card)
		var label := Label.new()
		label.text = caption
		label.position = Vector2(16, 9)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("#b9c7bc"))
		card.add_child(label)
		var value := Label.new()
		value.name = "Value"
		value.position = Vector2(16, 29)
		value.add_theme_font_size_override("font_size", 22)
		value.add_theme_color_override("font_color", Color("#efd39a") if caption == "首次胜利" else Color("#cfdfdb"))
		card.add_child(value)
	var field: Node = dialog.get_parent()
	while field and not field.has_method("_show_sparring_confirmation"):
		field = field.get_parent()
	var refresh := func() -> void:
		if not dialog.visible:
			return
		var spar: bool = is_instance_valid(field) and field.get("_sparring_confirm_dialog") == dialog
		rewards.visible = spar
		dialog._message.position.y = 165 if spar else 81
		dialog._message.size.y = 69 if spar else 143
		dialog._confirm_button.position = Vector2(441, 239)
		dialog._cancel_button.position = Vector2(240, 239)
		if spar:
			var parts := String(field.get("_pending_sparring_action")).split(":")
			if parts.size() < 6:
				return
			var record: Dictionary = GameState.sparring_records.get(parts[1], {})
			var won := bool(record.get("won", false))
			var lost := bool(record.get("loss_reward_claimed", false))
			rewards.get_child(0).get_node("Value").text = "已领取" if won else "%s  阅历" % parts[4]
			rewards.get_child(1).get_node("Value").text = "已领取" if lost else ("已结算" if won else "%s  阅历" % parts[5])
			var note := "复战仅供试招，无阅历、经验、金钱或掉落。" if won else "首败阅历限领一次，之后仍可领取首胜奖励。"
			dialog._message.text = "[font_size=15]%s[/font_size]\n[color=#c5d7ce]点到为止，战后恢复至切磋前的气血与内力。[/color]" % note
	dialog.visibility_changed.connect(refresh)
	refresh.call()
