extends Node

var _failures: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var npc_scene: PackedScene = load("res://scenes/npc_node.tscn")
	var npc: NPCNode = npc_scene.instantiate() as NPCNode
	npc.sprite_path = "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f.png"
	npc.walk_sprite_path = "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f.png"
	npc.movement_mode = "patrol"
	npc.patrol_axis = Vector2.RIGHT
	npc.patrol_distance = 60.0
	npc.patrol_speed = 30.0
	npc.position = Vector2(300.0, 220.0)
	add_child(npc)
	await get_tree().process_frame

	npc._process(0.35)
	var moving_position: Vector2 = npc.position
	_expect(npc.sprite.texture.resource_path.ends_with("npc_street_merchant_right_walk_8f.png"), "patrol uses walk strip")

	npc.begin_conversation(npc.global_position + Vector2(-80.0, 0.0))
	var conversation_position: Vector2 = npc.position
	_expect(npc.sprite.texture.resource_path.ends_with("npc_street_merchant_right_walk_8f.png"), "conversation normalizes the authored sheet and visually faces left")
	_expect(not npc.sprite.flip_h, "authored directional strip is not mirrored")

	npc._process(0.70)
	_expect(npc.position.is_equal_approx(conversation_position), "conversation stops patrol movement")
	_expect(npc.sprite.frame == 0, "conversation freezes on a complete neutral frame")

	npc.end_conversation()
	npc.begin_conversation(npc.global_position + Vector2(80.0, 0.0))
	_expect(npc.sprite.texture.resource_path.ends_with("npc_street_merchant_left_walk_8f.png"), "conversation normalizes the authored sheet and visually faces right")
	_expect(not npc.sprite.flip_h, "right-facing authored strip is not mirrored")
	npc.end_conversation()
	npc.begin_conversation(npc.global_position + Vector2(0.0, -80.0))
	_expect(npc.sprite.texture.resource_path.ends_with("npc_street_merchant_up_walk_8f.png"), "conversation selects the up-facing strip for a player above")
	npc.end_conversation()
	npc._process(0.35)
	_expect(not npc.position.is_equal_approx(conversation_position), "patrol resumes after conversation")
	_expect(npc.sprite.texture.resource_path.ends_with("npc_street_merchant_right_walk_8f.png"), "walk strip resumes after conversation")
	_expect(not moving_position.is_equal_approx(Vector2(300.0, 220.0)), "patrol moved before conversation")

	var explicit_npc: NPCNode = npc_scene.instantiate() as NPCNode
	explicit_npc.npc_id = "linxi_granny_test"
	explicit_npc.sprite_path = "res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
	explicit_npc.conversation_sprite_paths = {
		"down": "res://art/characters/conversation_direction_v1/linxi_granny/npc_linxi_granny_down_conversation_1f.png",
		"up": "res://art/characters/conversation_direction_v1/linxi_granny/npc_linxi_granny_up_conversation_1f.png",
		"left": "res://art/characters/conversation_direction_v1/linxi_granny/npc_linxi_granny_left_conversation_1f.png",
		"right": "res://art/characters/conversation_direction_v1/linxi_granny/npc_linxi_granny_right_conversation_1f.png",
	}
	add_child(explicit_npc)
	await get_tree().process_frame
	explicit_npc.begin_conversation(explicit_npc.global_position + Vector2(0.0, -80.0))
	_expect(explicit_npc.sprite.texture.resource_path.ends_with("npc_linxi_granny_up_conversation_1f.png"), "down-only NPC uses its explicit back-facing conversation asset")
	explicit_npc.end_conversation()
	explicit_npc.begin_conversation(explicit_npc.global_position + Vector2(-80.0, 0.0))
	_expect(explicit_npc.sprite.texture.resource_path.ends_with("npc_linxi_granny_left_conversation_1f.png"), "down-only NPC uses its explicit left-facing conversation asset")
	explicit_npc.end_conversation()
	var nearby_player := npc_scene.instantiate() as NPCNode
	# A lightweight Node2D in the player group is enough to validate the
	# distance fallback without relying on an Area2D enter signal.
	nearby_player.npc_id = "interaction_probe"
	nearby_player.position = explicit_npc.position + Vector2(90.0, 0.0)
	nearby_player.add_to_group("player")
	add_child(nearby_player)
	await get_tree().process_frame
	explicit_npc.set("_in_range", false)
	var fallback_state := {"emitted": false}
	explicit_npc.npc_interacted.connect(func(_id: String, _dialog: String): fallback_state["emitted"] = true)
	explicit_npc.dialog_id = "linxi_center_granny"
	_expect(explicit_npc.try_interact(), "nearby NPC interaction survives a missed Area2D overlap signal")
	_expect(bool(fallback_state["emitted"]), "distance fallback emits the configured NPC dialog")

	var versioned_npc: NPCNode = npc_scene.instantiate() as NPCNode
	versioned_npc.npc_id = "duqingshan_versioned_test"
	versioned_npc.sprite_path = "res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png"
	add_child(versioned_npc)
	await get_tree().process_frame
	versioned_npc.begin_conversation(versioned_npc.global_position + Vector2(-80.0, 0.0))
	_expect(versioned_npc.sprite.texture.resource_path.ends_with("npc_duqingshan_v3_idle_right_25d_4f.png"), "versioned major NPC keeps the matching V3 directional family")
	versioned_npc.end_conversation()
	versioned_npc.begin_conversation(versioned_npc.global_position + Vector2(0.0, -80.0))
	_expect(versioned_npc.sprite.texture.resource_path.ends_with("npc_duqingshan_v3_idle_up_25d_4f.png"), "Du Qingshan back-facing conversation never falls back to the broken V1 strip")
	var tutorial_scene := load("res://data/scenes/linxi_tutorial.tres") as SceneScript
	if tutorial_scene != null:
		for entry: Dictionary in tutorial_scene.npcs:
			if String(entry.get("npc_id", "")) != "duqingshan":
				continue
			versioned_npc.conversation_sprite_paths = Dictionary(entry.get("conversation_sprite_paths", {})).duplicate()
			break
	versioned_npc.end_conversation()
	versioned_npc.begin_conversation(versioned_npc.global_position + Vector2(80.0, 0.0))
	_expect(versioned_npc.sprite.texture.resource_path.ends_with("npc_duqingshan_v3_idle_left_25d_4f.png"), "Du Qingshan visually faces right when the player stands to his right")
	versioned_npc.end_conversation()
	versioned_npc.begin_conversation(versioned_npc.global_position + Vector2(-80.0, 0.0))
	_expect(versioned_npc.sprite.texture.resource_path.ends_with("npc_duqingshan_v3_idle_right_25d_4f.png"), "Du Qingshan visually faces left when the player stands to his left")
	_validate_scene_direction_contract(
		"res://data/scenes/linxi_tutorial.tres",
		["duqingshan", "duqingshan_ready", "duqingshan_after_sword"]
	)
	_validate_scene_direction_contract(
		"res://data/scenes/ch1_s0_linxi_main_walkable.tres",
		["duqingshan"]
	)
	_validate_duqingshan_legacy_horizontal_mapping("res://data/scenes/linxi_tutorial.tres")
	_validate_duqingshan_legacy_horizontal_mapping("res://data/scenes/ch1_s0_linxi_main_walkable.tres")

	_validate_scene_direction_contract(
		"res://data/scenes/linxi_village_center.tres",
		[
			"linxi_herbalist",
			"linxi_granny",
			"linxi_farmer",
			"linxi_apothecary_apprentice",
			"linxi_herb_gatherer",
		]
	)
	_validate_scene_direction_contract(
		"res://data/scenes/linxi_village_scrollmap.tres",
		[
			"linxi_south_herbalist",
			"linxi_south_granny",
			"linxi_south_farmer",
			"linxi_south_apprentice",
			"linxi_south_herb_gatherer",
		]
	)

	npc.free()
	explicit_npc.free()
	nearby_player.free()
	versioned_npc.free()
	call_deferred("_finish")


func _validate_scene_direction_contract(scene_path: String, npc_ids: Array[String]) -> void:
	var scene := load(scene_path) as SceneScript
	_expect(scene != null, "conversation-direction scene loads: %s" % scene_path)
	if scene == null:
		return
	for npc_id: String in npc_ids:
		var found := false
		for entry: Dictionary in scene.npcs:
			if String(entry.get("npc_id", "")) != npc_id:
				continue
			found = true
			var paths: Dictionary = entry.get("conversation_sprite_paths", {})
			for facing: String in ["down", "up", "left", "right"]:
				var path := String(paths.get(facing, ""))
				_expect(path != "" and ResourceLoader.exists(path), "%s has an authored %s conversation facing" % [npc_id, facing])
			break
		_expect(found, "scene contains audited NPC: %s" % npc_id)


func _validate_duqingshan_legacy_horizontal_mapping(scene_path: String) -> void:
	var scene := load(scene_path) as SceneScript
	if scene == null:
		return
	for entry: Dictionary in scene.npcs:
		if not String(entry.get("npc_id", "")).begins_with("duqingshan"):
			continue
		var paths: Dictionary = entry.get("conversation_sprite_paths", {})
		_expect(
			String(paths.get("left", "")).ends_with("npc_duqingshan_v3_idle_right_25d_4f.png"),
			"%s maps world-left to the legacy sheet that visually faces left" % entry.get("npc_id", "")
		)
		_expect(
			String(paths.get("right", "")).ends_with("npc_duqingshan_v3_idle_left_25d_4f.png"),
			"%s maps world-right to the legacy sheet that visually faces right" % entry.get("npc_id", "")
		)


func _finish() -> void:
	await get_tree().process_frame
	if _failures > 0:
		push_error("[NPC Conversation State Test] %d failure(s)" % _failures)
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)
