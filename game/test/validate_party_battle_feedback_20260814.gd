extends SceneTree

var _checked := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_dialog_layer()
	_validate_character_panel()
	_validate_companion_assets_and_recruitment()
	await _validate_formation_contract()
	_validate_battle_text_layout()
	print("[PartyBattleFeedback20260814] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _validate_dialog_layer() -> void:
	var scene := load("res://scenes/ui/dialog_box.tscn") as PackedScene
	var root := scene.instantiate() if scene != null else null
	_check(root is CanvasLayer and (root as CanvasLayer).layer >= 80, "dialog UI owns a high CanvasLayer")
	_check(root != null and root.get_node_or_null("DialogBox/Frame") != null, "dialog frame remains inside the CanvasLayer")
	if root != null:
		root.free()


func _validate_character_panel() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
	_check(source.contains('"队伍"') and not source.contains('"同行者"'), "character panel section is named 队伍")
	_check(source.contains("var button := Button.new()"), "party selector uses a plain button without an empty tooltip")


func _validate_companion_assets_and_recruitment() -> void:
	var tang := load("res://data/companions/tang_xingzhou.tres") as CharacterStats
	var qinghe := load("res://data/companions/shen_qinghe.tres") as CharacterStats
	_check(tang != null and tang.battle_sprite_root.contains("companions_v4/tang_xingzhou"), "Tang uses the locked-pose v4 battle identity root")
	_check(tang != null and tang.portrait_path.ends_with("portrait_tang_xingzhou_v2.png"), "Tang uses the distinct v2 portrait identity")
	_check(qinghe != null and qinghe.battle_sprite_root.contains("companions_v4/shen_qinghe"), "Shen uses the locked-pose v4 battle identity root")
	for entry: Dictionary in [
		{"root": tang.battle_sprite_root if tang != null else "", "prefix": "tang_xingzhou"},
		{"root": qinghe.battle_sprite_root if qinghe != null else "", "prefix": "shen_qinghe"},
	]:
		for state: String in ["ready", "move", "attack", "hit", "defeat"]:
			for frame_index: int in range(1, 5):
				var path := "%s/%s_%s_%02d.png" % [entry.root, entry.prefix, state, frame_index]
				_check(ResourceLoader.exists(path), "dedicated companion frame exists: %s" % path.get_file())
	_validate_ready_anchor_stability(tang, "tang_xingzhou")
	_validate_ready_anchor_stability(qinghe, "shen_qinghe")
	var intro := FileAccess.get_file_as_string("res://data/dialogs/linxi_companion_tang_xingzhou.tres")
	var after_spar := FileAccess.get_file_as_string("res://data/dialogs/linxi_companion_tang_xingzhou_after_spar.tres")
	_check(intro.contains("spar_then:tang_xingzhou_recruit") and not intro.contains("companion_tang_xingzhou_joined"), "Tang cannot join before sparring")
	_check(after_spar.contains("tang_xingzhou_sparred") and after_spar.contains("companion_tang_xingzhou_joined"), "Tang invitation exists only after sparring")
	var qinghe_intro := FileAccess.get_file_as_string("res://data/dialogs/linxi_companion_shen_qinghe.tres")
	var qinghe_offer := FileAccess.get_file_as_string("res://data/dialogs/linxi_companion_shen_qinghe_offer.tres")
	_check(qinghe_intro.contains("shen_qinghe_reunion_spoken") and qinghe_intro.contains("companion_shen_qinghe_joined") and qinghe_intro.contains('on_end = "next:offer"'), "Shen's first talk flows directly into the invitation")
	_check(qinghe_offer.contains("companion_shen_qinghe_joined"), "Shen's later talk remains as the declined-offer fallback")


func _validate_formation_contract() -> void:
	var formation := BattleFormationView.new()
	formation.size = Vector2(1920, 1080)
	root.add_child(formation)
	var texture := load("res://art/sprites/battle/companions_v4/tang_xingzhou/tang_xingzhou_ready_01.png") as Texture2D
	var allies: Array[Dictionary] = []
	for index: int in range(3):
		allies.append({"unit_id": StringName("ally_%d" % index), "texture": texture, "ready_frames": [texture], "scale": 0.30, "hp": 100, "max_hp": 100, "mp": 36, "max_mp": 60})
	var enemies: Array[Dictionary] = [{"unit_id": &"enemy_0", "texture": texture, "ready_frames": [texture], "scale": 0.30, "hp": 100, "max_hp": 100, "mp": 18, "max_mp": 30}]
	formation.build_formations(allies, enemies)
	await process_frame
	var first := formation.ally_actors[0]
	var mana_bar := first.get_node_or_null("ManaBar") as ProgressBar
	var mana_label := first.get_node_or_null("ManaLabel") as Label
	_check(mana_bar != null and int(mana_bar.value) == 36 and int(mana_bar.max_value) == 60, "battle actor displays current and maximum inner power")
	_check(mana_label != null and mana_label.text == "内 36/60", "inner-power label uses Chinese combat terminology")
	var status_widget := formation.status_widgets.get(&"ally_0") as VBoxContainer
	var formation_mana_label := status_widget.get_node_or_null("MPText") as Label if status_widget != null else null
	_check(status_widget != null and status_widget.scale == Vector2.ONE, "formation status values remain readable instead of inheriting actor scale")
	_check(formation_mana_label != null and formation_mana_label.text == "内 36/60", "unscaled formation HUD shows inner-power values")
	formation.update_unit_effects(&"ally_0", {"poison": 2})
	await process_frame
	var status_icons := status_widget.get_node_or_null("StatusIcons") as HBoxContainer if status_widget != null else null
	var status_icon := status_icons.get_child(0) as Button if status_icons != null and status_icons.get_child_count() > 0 else null
	_check(status_icon != null, "status effect creates a battle HUD icon without aborting formation setup")
	_check(status_icon != null and status_icon.get_theme_constant("icon_max_width") == 21, "status icon width uses a Godot 4.6 theme constant override")
	var artwork := first.get_node_or_null("Artwork") as TextureRect
	var idle_scale_before := artwork.scale if artwork != null else Vector2.ONE
	var idle_position_before := artwork.position if artwork != null else Vector2.ZERO
	await create_timer(0.25).timeout
	_check(artwork != null and artwork.scale.distance_to(idle_scale_before) > 0.0001, "Tang's locked ready frames still breathe subtly at runtime")
	_check(artwork != null and artwork.position.is_equal_approx(idle_position_before), "procedural idle never slides the feet across the platform")
	var visible_foot_y := first.position.y + first.size.y * 0.5 + BattleFormationView.ACTOR_VISUAL_FOOT_OFFSET_FROM_PIVOT * first.scale.y
	_check(absf(visible_foot_y - BattleFormationView.ALLY_SLOTS[0].y * formation.size.y) < 1.0, "ally visible feet, not the Control centre, land on the authored slot")
	formation.set_active_unit(&"ally_1")
	var arrow := formation.get_node_or_null("ActiveAllyArrow") as Sprite2D
	_check(arrow != null and arrow.visible, "active allied unit has an animated arrow")
	_check(
		arrow != null and arrow.texture != null
		and arrow.texture.resource_path == "res://art/ui/battle/formal/v3/active_unit_arrow_v1.png",
		"active unit uses the dedicated battle indicator instead of a map portal arrow"
	)
	if arrow != null and arrow.texture != null:
		var displayed_size := arrow.texture.get_size() * arrow.scale
		_check(displayed_size.distance_to(BattleFormationView.ACTIVE_ARROW_DISPLAY_SIZE) <= 0.2, "active unit indicator matches the reviewed 60 px battle size")
		var active_actor: Control = formation.ally_actors[1]
		var active_ground_y := active_actor.position.y + active_actor.size.y * 0.5 + BattleFormationView.ACTOR_VISUAL_FOOT_OFFSET_FROM_PIVOT * active_actor.scale.y
		var active_head_y := active_ground_y - BattleFormationView.NORMALIZED_STANDING_HEIGHT * active_actor.scale.y
		var active_center_x := active_actor.position.x + active_actor.size.x * 0.5
		_check(arrow.position.y <= active_head_y - 29.0, "active indicator is raised clear of the ally's head")
		_check(arrow.position.x > active_center_x, "active indicator moves slightly toward the battle centre")
	for state: String in ["normal", "hover", "pressed"]:
		_check(
			ResourceLoader.exists("res://art/ui/battle/formal/v3/target_select_v1/target_select_%s_v1.png" % state),
			"formal healing-target %s skin exists" % state
		)
	formation.set_active_unit(&"enemy_0")
	_check(arrow != null and not arrow.visible, "active arrow is reserved for player-controlled allies")
	var actor_source := FileAccess.get_file_as_string("res://scripts/battle/battle_actor.gd")
	_check(actor_source.contains("func _update_idle_motion"), "locked companion frames receive a procedural breathing idle")
	_check(actor_source.contains("0.0065") and actor_source.contains("0.0035"), "idle breathing stays subtle instead of jumping between frames")
	_check(actor_source.contains("artwork.pivot_offset = Vector2(size.x * 0.5, size.y * 0.82)"), "idle breathing pivots near the visible feet")
	formation.queue_free()


func _validate_battle_text_layout() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(not source.contains("[b]遭遇战开始[/b]"), "encounter heading does not use blurry bold BBCode")
	_check(source.contains("22.0, 72.0, 50.0"), "battle log uses a deeper left content margin")
	_check(source.contains("offset_left = 58.0") and source.contains("OVERRUN_NO_TRIMMING"), "skill card text is inset and descriptions are not ellipsized")
	_check(source.contains("_compact_skill_description(skill.description)"), "skill cards display the complete normalized description")
	_check(source.contains("formation_base_scale") and not source.contains("var ally_scale: float = 0.30"), "allies and enemies share one formation scale")
	_check(source.contains("overlay.visible = target.visible"), "legacy HUD artwork mirrors its hidden target in formation battles")
	_check(BattleFormationView.ALLY_SLOTS[0].is_equal_approx(Vector2(0.100, 0.604)), "bamboo ally foot anchors use painted platform centres")
	_check(BattleFormationView.ENEMY_SLOTS[2].is_equal_approx(Vector2(0.768, 0.238)), "bamboo enemy foot anchors use painted platform centres")
	_check(BattleFormationView.MOUNTAIN_GATE_ALLY_SLOTS[2].is_equal_approx(Vector2(0.318, 0.625)), "courtyard ally foot anchors use painted ring centres")
	_check(BattleFormationView.MOUNTAIN_GATE_ENEMY_SLOTS[2].is_equal_approx(Vector2(0.670, 0.273)), "courtyard enemy foot anchors use painted ring centres")
	var bandit := load("res://data/enemies/bandit_mountain.tres") as EnemyDef
	_check(bandit != null and bandit.battle_actor_scale <= 0.92, "mountain bandit scale no longer overwhelms the party")


func _validate_ready_anchor_stability(stats: CharacterStats, prefix: String) -> void:
	if stats == null:
		_check(false, "%s companion stats load before ready-frame audit" % prefix)
		return
	var bottoms: Array[int] = []
	var centres: Array[float] = []
	var heights: Array[int] = []
	var frame_bytes: Array[PackedByteArray] = []
	for frame_index: int in range(1, 5):
		var path := "%s/%s_ready_%02d.png" % [stats.battle_sprite_root, prefix, frame_index]
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		var rect := image.get_used_rect() if image != null and not image.is_empty() else Rect2i()
		_check(rect.size.x > 0 and rect.size.y > 0, "%s ready frame %d has visible pixels" % [prefix, frame_index])
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		bottoms.append(rect.position.y + rect.size.y)
		centres.append(float(rect.position.x) + float(rect.size.x) * 0.5)
		heights.append(rect.size.y)
		frame_bytes.append(FileAccess.get_file_as_bytes(path))
	if bottoms.size() != 4:
		return
	_check(bottoms.max() - bottoms.min() <= 1, "%s ready feet stay on one baseline" % prefix)
	_check(centres.max() - centres.min() <= 1.0, "%s ready body centre does not sway between frames" % prefix)
	_check(heights.max() - heights.min() <= 2, "%s ready breathing keeps protagonist-standard height stability" % prefix)
	# These companions currently have no approved subtle-breathing source frames.
	# Lock the ready loop to one reviewed pose rather than alternating between
	# unrelated wide and narrow stances that read as full-body teleporting.
	var locked_pose := frame_bytes.size() == 4
	if locked_pose:
		for frame_index: int in range(1, frame_bytes.size()):
			locked_pose = locked_pose and frame_bytes[frame_index] == frame_bytes[0]
	_check(locked_pose, "%s ready loop stays on one approved pose until subtle frames exist" % prefix)


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[PartyBattleFeedback20260814] %s" % message)
