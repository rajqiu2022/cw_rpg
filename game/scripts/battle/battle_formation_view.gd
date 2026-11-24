class_name BattleFormationView
extends Control

## Presentation-only formation layer. Coordinates are normalized to the
## viewport: allies occupy the lower-left depth cluster, enemies the right-side
## depth cluster. Unmarked arenas still use five authored logical anchors.
## It does not calculate damage or decide turns.

const ACTOR_SCENE := preload("res://scenes/battle_actor.tscn")
const ACTIVE_ARROW_TEXTURE := preload("res://art/ui/battle/formal/v3/active_unit_arrow_v1.png")
const ACTIVE_ARROW_DISPLAY_SIZE := Vector2(60.0, 60.0)
const TARGET_SELECT_NORMAL := preload("res://art/ui/battle/formal/v3/target_select_v1/target_select_normal_v1.png")
const TARGET_SELECT_HOVER := preload("res://art/ui/battle/formal/v3/target_select_v1/target_select_hover_v1.png")
const TARGET_SELECT_PRESSED := preload("res://art/ui/battle/formal/v3/target_select_v1/target_select_pressed_v1.png")
const MAX_UNITS := 5
const ACTOR_VISUAL_FOOT_OFFSET_FROM_PIVOT := 180.0
const NORMALIZED_STANDING_HEIGHT := 300.0
# Shared five-point loose formation. These are ground-contact anchors, not
# sprite centres. Enemy anchors begin below the scenery horizon so a lone foe
# can never float inside bamboo, roofs or mountains as in the old 0.149-0.326
# profile. The two sides remain staggered rather than forming straight rows.
const LOOSE_ALLY_SLOTS: Array[Vector2] = [Vector2(0.145, 0.645), Vector2(0.245, 0.705), Vector2(0.105, 0.755), Vector2(0.335, 0.795), Vector2(0.215, 0.845)]
const LOOSE_ENEMY_SLOTS: Array[Vector2] = [Vector2(0.690, 0.475), Vector2(0.795, 0.525), Vector2(0.635, 0.575), Vector2(0.860, 0.620), Vector2(0.735, 0.675)]
# Village-square art owns a wider lower-left clearing and a compact upper-right
# dirt shelf. These five-point sets follow the user-authored red-box regions
# instead of reusing the generic cave/outskirts coordinates.
const VILLAGE_ALLY_SLOTS: Array[Vector2] = [Vector2(0.220, 0.710), Vector2(0.330, 0.760), Vector2(0.190, 0.820), Vector2(0.420, 0.860), Vector2(0.290, 0.910)]
const VILLAGE_ENEMY_SLOTS: Array[Vector2] = [Vector2(0.600, 0.430), Vector2(0.710, 0.470), Vector2(0.560, 0.520), Vector2(0.790, 0.550), Vector2(0.670, 0.580)]
const RIVER_ALLY_SLOTS: Array[Vector2] = [Vector2(0.10, 0.58), Vector2(0.22, 0.69), Vector2(0.06, 0.78), Vector2(0.30, 0.82), Vector2(0.15, 0.90)]
const RIVER_ENEMY_SLOTS: Array[Vector2] = [Vector2(0.76, 0.16), Vector2(0.62, 0.29), Vector2(0.82, 0.42), Vector2(0.55, 0.43), Vector2(0.70, 0.54)]
# Ground-contact anchors calibrated to the ten painted rings in
# bg_battle_mountain_gate_v2.png. `_create_side` already converts a foot point
# into the actor Control position, so these coordinates must be the actual ring
# centres rather than the old pre-offset actor centres.
const MOUNTAIN_GATE_ALLY_SLOTS: Array[Vector2] = [Vector2(0.205, 0.508), Vector2(0.259, 0.564), Vector2(0.318, 0.625), Vector2(0.379, 0.703), Vector2(0.442, 0.777)]
const MOUNTAIN_GATE_ENEMY_SLOTS: Array[Vector2] = [Vector2(0.557, 0.187), Vector2(0.609, 0.226), Vector2(0.670, 0.273), Vector2(0.722, 0.323), Vector2(0.788, 0.370)]
const STATUS_VISUALS := {
	"poison_ward": {"icon": "res://art/ui/status/icons_v1/icon_status_guard_v1.png", "name": "护毒", "color": Color("a4c987"), "desc": "青木真气护脉，毒性攻击与毒发伤害减少60%。可与丹砂佩叠加。"},
	"venom": {"icon": "res://art/ui/status/icons_v1/icon_status_poison_v1.png", "name": "烈毒", "color": Color("dbbc55"), "desc": "每个自身回合开始损失12%最大生命。与普通毒并存时只受较强的一种。丹砂佩减伤，解毒丹或回春引可解。"},
	"clear_sight": {"icon": "res://art/ui/status/icons_v1/icon_status_inner_breath_v1.png", "name": "明目", "color": Color("a8d9dc"), "desc": "服药者在剩余回合内每击必中。"},
	"poison": {"icon": "res://art/ui/status/icons_v1/icon_status_poison_v1.png", "name": "中毒", "color": Color("72d2a6"), "desc": "每回合损失5%最大生命。"},
	"bleed": {"icon": "res://art/ui/status/icons_v1/icon_status_bleed_v1.png", "name": "流血", "color": Color("e36c6c"), "desc": "每回合损失4%最大生命。"},
	"internal_injury": {"icon": "res://art/ui/status/icons_v1/icon_status_internal_injury_v1.png", "name": "内伤", "color": Color("c9a7ff"), "desc": "内功攻击会累积内伤；达到100时气脉闭塞。"},
	"internal_lock": {"icon": "res://art/ui/status/icons_v1/icon_status_internal_lock_v1.png", "name": "气脉闭塞", "color": Color("ff9e8a"), "desc": "无法施展招式，可以普通攻击、防御或使用道具。"},
	"weaken": {"icon": "res://art/ui/status/icons_v1/icon_status_weaken_v1.png", "name": "虚弱", "color": Color("d6a55d"), "desc": "造成的伤害降低，承受的伤害提高。"},
	"armor_break": {"icon": "res://art/ui/status/icons_v1/icon_status_weaken_v1.png", "name": "破甲", "color": Color("e28a58"), "desc": "防御被削弱。"},
	"burst": {"icon": "res://art/ui/status/icons_v1/icon_status_attack_up_v1.png", "name": "爆发", "color": Color("f1ca65"), "desc": "暴击率暂时提高。"},
	"damage_boost": {"icon": "res://art/ui/status/icons_v1/icon_status_attack_up_v1.png", "name": "增伤", "color": Color("f0b85b"), "desc": "攻击方增伤区提高；同类来源加算。"},
	"vulnerable": {"icon": "res://art/ui/status/icons_v1/icon_status_weaken_v1.png", "name": "易伤", "color": Color("ef8f75"), "desc": "目标承伤区提高；同类来源加算。"},
	"guard": {"icon": "res://art/ui/status/icons_v1/icon_status_guard_v1.png", "name": "防御", "color": Color("74b8d8"), "desc": "下一次受到的伤害减半。"},
	"stun": {"icon": "res://art/ui/status/icons_v1/icon_status_stun_v1.png", "name": "眩晕", "color": Color("e0ca74"), "desc": "无法行动。"},
	"freeze": {"icon": "res://art/ui/status/icons_v1/icon_status_freeze_v1.png", "name": "冰冻", "color": Color("9edaff"), "desc": "无法行动。"},
	"redirect": {"icon": "res://art/ui/status/icons_v1/icon_status_inner_breath_v1.png", "name": "回澜", "color": Color("72d2c9"), "desc": "化去部分伤害并返还给攻击者。"},
}

var ally_actors: Array[BattleActor] = []
var enemy_actors: Array[BattleActor] = []
var status_widgets: Dictionary = {}
var status_texts: Dictionary = {}
var active_unit_id: StringName = &""
var selected_actor: BattleActor = null
var target_buttons: Array[Button] = []
var formation_profile: StringName = &"bamboo_platforms"
var formation_variant: int = 0
var _active_arrow: Sprite2D = null
var _active_arrow_clock: float = 0.0
var _status_tip_panel: PanelContainer = null
var _status_tip_label: RichTextLabel = null

signal target_selected(unit_id: StringName)
signal actor_created(actor: BattleActor, enemy_side: bool)


func clear_formations() -> void:
	for actor in ally_actors + enemy_actors:
		if is_instance_valid(actor):
			actor.queue_free()
	for widget in status_widgets.values():
		if is_instance_valid(widget):
			widget.queue_free()
	ally_actors.clear()
	enemy_actors.clear()
	status_widgets.clear()
	status_texts.clear()
	active_unit_id = &""
	if _active_arrow != null:
		_active_arrow.visible = false
	clear_target_selection()
	selected_actor = null


func build_formations(allies: Array[Dictionary], enemies: Array[Dictionary]) -> void:
	clear_formations()
	_create_side(allies, false, ally_actors)
	_create_side(enemies, true, enemy_actors)


func set_formation_profile(profile: StringName, variant: int = 0) -> void:
	formation_profile = profile
	formation_variant = posmod(variant, 3)


func _process(delta: float) -> void:
	for unit_id in status_widgets:
		var actor := get_actor(unit_id)
		var widget: VBoxContainer = status_widgets.get(unit_id) as VBoxContainer
		if actor != null and widget != null:
			_position_status_widget(actor, widget)
	if _active_arrow != null and _active_arrow.visible:
		_active_arrow_clock = fmod(_active_arrow_clock + delta, TAU)
		_position_active_arrow()


func play_team_enter() -> void:
	var entering: Array[BattleActor] = []
	entering.append_array(ally_actors)
	entering.append_array(enemy_actors)
	for actor in entering:
		if is_instance_valid(actor):
			actor.play_enter(actor in ally_actors)
	await get_tree().create_timer(0.55).timeout


func _create_side(units: Array[Dictionary], enemy_side: bool, output: Array[BattleActor]) -> void:
	var count: int = mini(units.size(), MAX_UNITS)
	var slots: Array[Vector2] = _selected_slots(_slots_for(enemy_side), count, enemy_side)
	for index in range(count):
		var actor := ACTOR_SCENE.instantiate() as BattleActor
		if actor == null:
			continue
		add_child(actor)
		var data: Dictionary = units[index]
		var ready_frames: Array[Texture2D] = _textures_from_payload(data.get("ready_frames", []))
		var move_frames: Array[Texture2D] = _textures_from_payload(data.get("move_frames", []))
		var attack_frames: Array[Texture2D] = _textures_from_payload(data.get("attack_frames", []))
		var hit_frames: Array[Texture2D] = _textures_from_payload(data.get("hit_frames", []))
		var defeat_frames: Array[Texture2D] = _textures_from_payload(data.get("defeat_frames", []))
		actor.configure(
			data.get("texture") as Texture2D,
			bool(data.get("flip_h", false)),
			bool(data.get("authored_face_right", not enemy_side)),
			ready_frames,
			move_frames,
			attack_frames,
			hit_frames,
			defeat_frames
		)
		actor.unit_id = StringName(data.get("unit_id", ""))
		actor.retain_on_defeat = enemy_side
		actor.set_idle_motion_profile(float(data.get("idle_motion_strength", 1.0)), actor.unit_id, float(data.get("idle_motion_speed", 1.0)))
		actor.pivot_offset = actor.size * 0.5
		var actor_scale := float(data.get("scale", 0.42))
		actor.position = Vector2(slots[index].x * size.x - actor.size.x * 0.5, slots[index].y * size.y - actor.size.y * 0.5)
		# Battle frames are 512x384 but live inside a 512x560 Control. With a
		# centred texture the visible feet sit below the Control pivot; treating
		# the slot as the Control centre therefore sinks boots into the platform.
		actor.position.y -= ACTOR_VISUAL_FOOT_OFFSET_FROM_PIVOT * actor_scale
		actor.scale = Vector2.ONE * actor_scale
		var depth_z := 2 + int(round(slots[index].y * 10.0))
		actor.set_meta("formation_depth_z", depth_z)
		actor.set_meta("formation_status_lift", float(data.get("status_lift", 0.0)))
		actor.z_index = depth_z
		actor.home_position = actor.position
		actor.set_process_input(false)
		output.append(actor)
		actor.set_health(int(data.get("hp", 1)), int(data.get("max_hp", 1)))
		actor.set_mana(int(data.get("mp", 0)), int(data.get("max_mp", 0)))
		actor.set_embedded_status_visible(false)
		_create_status_widget(actor, data)
		actor_created.emit(actor, enemy_side)


func _textures_from_payload(raw_frames: Variant) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if raw_frames is Array:
		for raw_frame in raw_frames:
			if raw_frame is Texture2D:
				frames.append(raw_frame)
	return frames


func _slots_for(enemy_side: bool) -> Array[Vector2]:
	match formation_profile:
		&"village_square":
			return VILLAGE_ENEMY_SLOTS if enemy_side else VILLAGE_ALLY_SLOTS
		&"river_skirmish":
			return RIVER_ENEMY_SLOTS if enemy_side else RIVER_ALLY_SLOTS
		&"courtyard_wedge":
			return MOUNTAIN_GATE_ENEMY_SLOTS if enemy_side else MOUNTAIN_GATE_ALLY_SLOTS
		_:
			return LOOSE_ENEMY_SLOTS if enemy_side else LOOSE_ALLY_SLOTS


func _selected_slots(all_slots: Array[Vector2], count: int, enemy_side: bool) -> Array[Vector2]:
	var selected: Array[Vector2] = []
	if count <= 0:
		return selected
	if formation_profile in [&"river_skirmish", &"courtyard_wedge"]:
		var fixed_indices := _balanced_slot_indices(count)
		for index in fixed_indices:
			if index >= 0 and index < all_slots.size():
				selected.append(all_slots[index])
		return selected
	var indices: Array[int] = _loose_slot_indices(count, enemy_side)
	for index in indices:
		if index >= 0 and index < all_slots.size():
			selected.append(all_slots[index])
	return selected


func _loose_slot_indices(count: int, enemy_side: bool) -> Array[int]:
	var variant := posmod(formation_variant + (1 if enemy_side else 0), 3)
	var patterns := {
		1: [[2], [0], [4]],
		2: [[0, 3], [1, 4], [0, 4]],
		3: [[0, 2, 4], [0, 1, 3], [1, 3, 4]],
		4: [[0, 1, 3, 4], [0, 1, 2, 4], [0, 2, 3, 4]],
		5: [[0, 1, 2, 3, 4], [0, 1, 2, 3, 4], [0, 1, 2, 3, 4]],
	}
	var raw: Array = patterns.get(clampi(count, 1, MAX_UNITS), patterns[5])[variant]
	var result: Array[int] = []
	for index in raw:
		result.append(int(index))
	return result


func _balanced_slot_indices(count: int) -> Array[int]:
	var indices: Array[int] = []
	match clampi(count, 1, MAX_UNITS):
		1:
			indices.append(2)
		2:
			indices.append(1)
			indices.append(3)
		3:
			indices.append(0)
			indices.append(2)
			indices.append(4)
		4:
			indices.append(0)
			indices.append(1)
			indices.append(3)
			indices.append(4)
		5:
			for index in range(MAX_UNITS):
				indices.append(index)
	return indices


func _create_status_widget(actor: BattleActor, data: Dictionary) -> void:
	var widget := VBoxContainer.new()
	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget.z_index = 12
	widget.size = Vector2(112, 84)
	widget.add_theme_constant_override("separation", 2)
	_position_status_widget(actor, widget)
	if data.has("enemy_level"):
		var caption := Label.new()
		caption.name = "EnemyCaption"
		var elite := bool(data.get("wild_elite", false))
		var boss_caption := String(data.get("boss_caption", ""))
		var level_text := "%d级" % int(data.enemy_level)
		caption.text = ("◆ 精英 · " if elite else "") + level_text
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.add_theme_font_size_override("font_size", 14)
		var caption_color := Color("#e5e6da")
		if elite:
			caption_color = Color("#ffd37e")
		caption.add_theme_color_override("font_color", caption_color)
		caption.add_theme_color_override("font_outline_color", Color("#160f0a"))
		caption.add_theme_constant_override("outline_size", 4)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		widget.add_child(caption)
		if not boss_caption.is_empty():
			var title := caption.duplicate() as Label
			title.name = "BossCaption"
			title.text = boss_caption
			title.add_theme_font_size_override("font_size", 19)
			title.add_theme_color_override("font_color", Color("#ff936f"))
			widget.add_child(title)
			widget.move_child(title, 0)
	var hp_text := Label.new()
	hp_text.name = "HPText"
	hp_text.text = "气 %d/%d" % [int(data.get("hp", 1)), int(data.get("max_hp", 1))]
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.add_theme_font_size_override("font_size", 13)
	hp_text.add_theme_color_override("font_color", Color(0.92, 0.94, 0.86, 1.0))
	hp_text.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.02, 0.96))
	hp_text.add_theme_constant_override("outline_size", 3)
	widget.add_child(hp_text)
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HP"
	hp_bar.max_value = max(1, int(data.get("max_hp", 1)))
	hp_bar.value = int(data.get("hp", hp_bar.max_value))
	hp_bar.custom_minimum_size = Vector2(112, 5)
	hp_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.05, 0.07, 0.08, 0.92)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.28, 0.72, 0.38, 0.96)
	hp_bar.add_theme_stylebox_override("background", bar_bg)
	hp_bar.add_theme_stylebox_override("fill", bar_fill)
	widget.add_child(hp_bar)
	var mp_text := Label.new()
	mp_text.name = "MPText"
	mp_text.text = "内 %d/%d" % [int(data.get("mp", 0)), int(data.get("max_mp", 0))]
	mp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_text.add_theme_font_size_override("font_size", 13)
	mp_text.add_theme_color_override("font_color", Color(0.54, 0.82, 1.0, 1.0))
	mp_text.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.02, 0.96))
	mp_text.add_theme_constant_override("outline_size", 3)
	mp_text.visible = int(data.get("max_mp", 0)) > 0
	widget.add_child(mp_text)
	var mp_bar := ProgressBar.new()
	mp_bar.name = "MP"
	mp_bar.max_value = max(1, int(data.get("max_mp", 0)))
	mp_bar.value = int(data.get("mp", 0))
	mp_bar.custom_minimum_size = Vector2(112, 4)
	mp_bar.show_percentage = false
	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.05, 0.07, 0.08, 0.92)
	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = Color(0.20, 0.55, 0.92, 0.96)
	mp_bar.add_theme_stylebox_override("background", mp_bg)
	mp_bar.add_theme_stylebox_override("fill", mp_fill)
	mp_bar.visible = int(data.get("max_mp", 0)) > 0
	widget.add_child(mp_bar)
	var status_anchor := Control.new()
	status_anchor.name = "StatusAnchor"
	status_anchor.custom_minimum_size = Vector2(0, 0)
	status_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget.add_child(status_anchor)
	var status_icons := HBoxContainer.new()
	status_icons.name = "StatusIcons"
	status_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	status_icons.custom_minimum_size = Vector2(72, 20)
	# Align status badges with the right side of the HP/MP group. The previous
	# -52 offset floated them above the bars and over tall enemy silhouettes.
	status_icons.position = Vector2(116, -22)
	status_icons.add_theme_constant_override("separation", 2)
	status_anchor.add_child(status_icons)
	add_child(widget)
	var unit_id: StringName = StringName(data.get("unit_id", ""))
	status_widgets[unit_id] = widget
	status_texts[unit_id] = "正常"


func _position_status_widget(actor: BattleActor, widget: VBoxContainer) -> void:
	var visual_center_x := actor.position.x + actor.size.x * 0.5
	var ground_y := actor.position.y + actor.size.y * 0.5 + ACTOR_VISUAL_FOOT_OFFSET_FROM_PIVOT * actor.scale.y
	var status_lift := float(actor.get_meta("formation_status_lift", 0.0))
	var desired := Vector2(visual_center_x - widget.size.x * 0.5, ground_y - NORMALIZED_STANDING_HEIGHT * actor.scale.y - 77.0 - status_lift)
	widget.position = Vector2(
		clampf(desired.x, 4.0, maxf(4.0, size.x - widget.size.x - 4.0)),
		# Enlarged actors can push the top rank's labels against the viewport edge.
		# Reserve room for the font ascender and its outline above the first row.
		clampf(desired.y, 28.0, maxf(28.0, size.y - widget.size.y - 4.0))
	)


func update_unit_health(unit_id: StringName, hp: int, max_hp: int, defeated: bool = false) -> void:
	var actor := get_actor(unit_id)
	if actor != null:
		actor.set_health(hp, max_hp, defeated)
	var widget: VBoxContainer = status_widgets.get(unit_id) as VBoxContainer
	if widget == null:
		return
	if actor != null and actor.retain_on_defeat:
		widget.visible = not defeated
	var hp_bar := widget.get_node_or_null("HP") as ProgressBar
	var hp_text := widget.get_node_or_null("HPText") as Label
	if hp_bar != null:
		hp_bar.max_value = max(1, max_hp)
		hp_bar.value = max(0, hp)
		if defeated:
			hp_bar.modulate = Color(0.45, 0.45, 0.45, 0.75)
	if hp_text != null:
		hp_text.text = "气 %d/%d" % [maxi(0, hp), maxi(1, max_hp)]
		hp_text.modulate = Color(0.55, 0.55, 0.55, 0.8) if defeated else Color.WHITE


func update_unit_mana(unit_id: StringName, mp: int, max_mp: int, defeated: bool = false) -> void:
	var actor := get_actor(unit_id)
	if actor != null:
		actor.set_mana(mp, max_mp, defeated)
	var widget: VBoxContainer = status_widgets.get(unit_id) as VBoxContainer
	if widget == null:
		return
	var mp_bar := widget.get_node_or_null("MP") as ProgressBar
	var mp_text := widget.get_node_or_null("MPText") as Label
	if mp_bar != null:
		mp_bar.visible = max_mp > 0
		mp_bar.max_value = maxi(1, max_mp)
		mp_bar.value = maxi(0, mp)
		mp_bar.modulate = Color(0.45, 0.45, 0.45, 0.75) if defeated else Color.WHITE
	if mp_text != null:
		mp_text.visible = max_mp > 0
		mp_text.text = "内 %d/%d" % [maxi(0, mp), maxi(0, max_mp)]
		mp_text.modulate = Color(0.55, 0.55, 0.55, 0.8) if defeated else Color.WHITE


func show_boss_warning(unit_id: StringName, warning: String) -> void:
	var widget := status_widgets.get(unit_id) as VBoxContainer
	if widget == null:
		return
	var anchor := widget.get_node("StatusAnchor") as Control
	var label := anchor.get_node_or_null("BossWarning") as Label
	if label == null:
		if warning.is_empty():
			return
		label = Label.new()
		label.name = "BossWarning"
		label.position = Vector2(-64, -1)
		label.size = Vector2(240, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color("#ffd49a"))
		label.add_theme_color_override("font_outline_color", Color("#28140d"))
		label.add_theme_constant_override("outline_size", 5)
		anchor.add_child(label)
	label.text = warning
	label.visible = not warning.is_empty()


func update_unit_status(unit_id: StringName, status_text: String) -> void:
	var widget: VBoxContainer = status_widgets.get(unit_id) as VBoxContainer
	if widget == null:
		return
	var label := widget.get_node_or_null("Status") as Label
	var clean_text := status_text if not status_text.is_empty() else "正常"
	status_texts[unit_id] = clean_text
	if label != null:
		label.text = ("行动中 · " + clean_text) if unit_id == active_unit_id else clean_text


func update_unit_effects(unit_id: StringName, effects: Dictionary) -> void:
	var widget: VBoxContainer = status_widgets.get(unit_id) as VBoxContainer
	if widget == null:
		return
	var row := widget.get_node_or_null("StatusAnchor/StatusIcons") as HBoxContainer
	if row == null:
		return
	for child in row.get_children():
		child.queue_free()
	for raw_key in effects.keys():
		var key := String(raw_key)
		if not STATUS_VISUALS.has(key):
			continue
		var value := int(effects.get(raw_key, 0))
		if value <= 0:
			continue
		var visual: Dictionary = STATUS_VISUALS[key]
		var icon := Button.new()
		var icon_path: String = String(visual.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.icon = load(icon_path) as Texture2D
		icon.expand_icon = true
		# icon_max_width is a Button theme constant in Godot 4.6, not a
		# writable Button property. Assigning it as a property aborts battle
		# setup as soon as a status icon is created.
		icon.add_theme_constant_override("icon_max_width", 14)
		icon.text = "%d" % value
		icon.custom_minimum_size = Vector2(26, 20)
		icon.add_theme_font_size_override("font_size", 9)
		var visual_color: Color = visual.get("color", Color.WHITE) as Color
		icon.add_theme_color_override("font_color", visual_color)
		icon.add_theme_color_override("font_hover_color", Color.WHITE)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.025, 0.04, 0.05, 0.92)
		box.border_color = visual_color
		box.set_border_width_all(1)
		box.set_corner_radius_all(4)
		icon.add_theme_stylebox_override("normal", box)
		icon.add_theme_stylebox_override("hover", box.duplicate())
		var suffix := "%d/100" % value if key == "internal_injury" else "剩余%d回合" % value
		var tip_text := "%s · %s\n%s" % [String(visual.get("name", key)), suffix, String(visual.get("desc", ""))]
		if key == "armor_break":
			tip_text = "破甲 · %s\n防御降低 %d%%，锁甲加成暂时失效。" % [suffix, int(effects.get("armor_break_percent", 0))]
		icon.focus_mode = Control.FOCUS_NONE
		icon.mouse_entered.connect(_show_status_tip.bind(icon, tip_text))
		icon.mouse_exited.connect(_hide_status_tip)
		row.add_child(icon)


func _show_status_tip(source: Control, text: String) -> void:
	_ensure_status_tip()
	_status_tip_label.text = text
	_status_tip_panel.size = Vector2(300, 88)
	var source_pos := source.get_global_rect().position - global_position
	_status_tip_panel.position = Vector2(
		clampf(source_pos.x - 126.0, 8.0, maxf(8.0, size.x - 308.0)),
		clampf(source_pos.y + source.size.y + 8.0, 8.0, maxf(8.0, size.y - 96.0))
	)
	_status_tip_panel.visible = true


func _hide_status_tip() -> void:
	if _status_tip_panel != null:
		_status_tip_panel.visible = false


func _ensure_status_tip() -> void:
	if _status_tip_panel != null:
		return
	_status_tip_panel = PanelContainer.new()
	_status_tip_panel.name = "StatusEffectTip"
	_status_tip_panel.z_index = 40
	_status_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_tip_panel.custom_minimum_size = Vector2(300, 88)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.025, 0.05, 0.065, 0.96)
	box.border_color = Color(0.28, 0.72, 0.74, 0.9)
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(12)
	_status_tip_panel.add_theme_stylebox_override("panel", box)
	_status_tip_label = RichTextLabel.new()
	_status_tip_label.bbcode_enabled = false
	_status_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_tip_label.fit_content = false
	_status_tip_label.scroll_active = false
	_status_tip_label.clip_contents = true
	_status_tip_label.custom_minimum_size = Vector2(276, 64)
	_status_tip_label.size = Vector2(276, 64)
	_status_tip_label.add_theme_font_size_override("normal_font_size", 15)
	_status_tip_label.add_theme_constant_override("line_separation", 2)
	_status_tip_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.94, 1.0))
	_status_tip_panel.add_child(_status_tip_label)
	add_child(_status_tip_panel)
	_status_tip_panel.visible = false


func set_active_unit(unit_id: StringName) -> void:
	active_unit_id = unit_id
	var active_ally: BattleActor = null
	for actor in ally_actors + enemy_actors:
		if not is_instance_valid(actor):
			continue
		var is_active: bool = actor.unit_id == unit_id
		if is_active and actor in ally_actors:
			active_ally = actor
		var base_z := int(actor.get_meta("formation_depth_z", 2))
		# The active arrow already communicates turn ownership.  Keeping the
		# actor at its authored ground depth prevents an upper-row attacker from
		# being drawn over a lower-row target during its approach.
		actor.z_index = base_z
		var widget: VBoxContainer = status_widgets.get(actor.unit_id) as VBoxContainer
		var label: Label = widget.get_node_or_null("Status") as Label if widget != null else null
		if label != null:
			var base_text: String = status_texts.get(actor.unit_id, "正常")
			label.text = ("行动中 · " + base_text) if is_active else base_text
	_ensure_active_arrow()
	_active_arrow.visible = active_ally != null
	_active_arrow_clock = 0.0
	if active_ally != null:
		_position_active_arrow()


func clear_active_unit() -> void:
	active_unit_id = &""
	if _active_arrow != null:
		_active_arrow.visible = false
	for actor in ally_actors + enemy_actors:
		if not is_instance_valid(actor):
			continue
		actor.z_index = int(actor.get_meta("formation_depth_z", 2))
		var widget: VBoxContainer = status_widgets.get(actor.unit_id) as VBoxContainer
		var label := widget.get_node_or_null("Status") as Label if widget != null else null
		if label != null:
			label.text = status_texts.get(actor.unit_id, "正常")


func _ensure_active_arrow() -> void:
	if _active_arrow != null:
		return
	_active_arrow = Sprite2D.new()
	_active_arrow.name = "ActiveAllyArrow"
	_active_arrow.texture = ACTIVE_ARROW_TEXTURE
	_active_arrow.centered = true
	var source_size := ACTIVE_ARROW_TEXTURE.get_size()
	if source_size.x > 0.0 and source_size.y > 0.0:
		_active_arrow.scale = Vector2(
			ACTIVE_ARROW_DISPLAY_SIZE.x / source_size.x,
			ACTIVE_ARROW_DISPLAY_SIZE.y / source_size.y
		)
	_active_arrow.z_index = 24
	_active_arrow.visible = false
	add_child(_active_arrow)


func _position_active_arrow() -> void:
	if _active_arrow == null or active_unit_id == &"":
		return
	var actor := get_actor(active_unit_id)
	if actor == null or actor not in ally_actors:
		_active_arrow.visible = false
		return
	var widget: VBoxContainer = status_widgets.get(active_unit_id) as VBoxContainer
	if widget == null:
		_active_arrow.visible = false
		return
	var bob := sin(_active_arrow_clock * 3.6) * 3.0
	# 箭头属于当前行动 HUD，固定在生命条组正上方中央，不再跟随人物头部偏移。
	_active_arrow.position = Vector2(
		widget.position.x + widget.size.x * 0.5,
		widget.position.y - ACTIVE_ARROW_DISPLAY_SIZE.y * 0.38 + bob
	)
	var pulse := 0.94 + 0.06 * sin(_active_arrow_clock * 3.6)
	_active_arrow.modulate = Color(1.0, 1.0, 1.0, pulse)


func show_target_selection(unit_ids: Array[StringName]) -> void:
	clear_target_selection()
	for unit_id in unit_ids:
		var actor := get_actor(unit_id)
		if actor == null:
			continue
		var target_button := Button.new()
		target_button.text = "选择"
		target_button.custom_minimum_size = Vector2(128, 44)
		target_button.size = Vector2(128, 44)
		target_button.z_index = 20
		var visual_center_x := actor.position.x + actor.size.x * 0.5
		var ground_y := actor.position.y + actor.size.y * 0.5 + ACTOR_VISUAL_FOOT_OFFSET_FROM_PIVOT * actor.scale.y
		target_button.position = Vector2(
			visual_center_x - target_button.size.x * 0.5,
			ground_y - NORMALIZED_STANDING_HEIGHT * actor.scale.y - 54.0 - float(actor.get_meta("formation_status_lift", 0.0))
		)
		_style_target_button(target_button)
		var target_id := unit_id
		target_button.pressed.connect(func() -> void: target_selected.emit(target_id))
		add_child(target_button)
		target_buttons.append(target_button)


func _style_target_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.96, 0.86, 0.44, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.95, 0.92, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.95))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _target_style(TARGET_SELECT_NORMAL))
	button.add_theme_stylebox_override("hover", _target_style(TARGET_SELECT_HOVER))
	button.add_theme_stylebox_override("pressed", _target_style(TARGET_SELECT_PRESSED))
	button.add_theme_stylebox_override("focus", _target_style(TARGET_SELECT_HOVER))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _target_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 28.0
	style.texture_margin_right = 28.0
	style.texture_margin_top = 18.0
	style.texture_margin_bottom = 18.0
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func clear_target_selection() -> void:
	for target_button in target_buttons:
		if is_instance_valid(target_button):
			target_button.queue_free()
	target_buttons.clear()


func get_actor(unit_id: StringName) -> BattleActor:
	for actor in ally_actors + enemy_actors:
		if actor.unit_id == unit_id:
			return actor
	return null
