extends SceneTree

const FIELD_SCENE_PATH := "res://scenes/field_walkable.tscn"
const LEGACY_FIELD_SCENE_PATH := "res://scenes/field.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle.tscn"
const DIALOG_SCENE_PATH := "res://scenes/ui/dialog_box.tscn"
const UI_LAYER_POLICY := preload("res://scripts/ui/ui_layer_policy.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_field_layers()
	await _validate_legacy_field_layers()
	await _validate_battle_layers()
	_validate_dialog_layer()
	if _failures.is_empty():
		print("[UICanvasLayerCheck] PASS: HUD/system/dialog UI stay above world actors")
		quit(0)
		return
	for failure in _failures:
		push_error("[UICanvasLayerCheck] %s" % failure)
	quit(1)


func _validate_field_layers() -> void:
	var router := root.get_node_or_null("SceneRouter")
	_expect(router != null, "SceneRouter autoload is unavailable")
	if router == null:
		return
	router.set("_field_payload", {
		"scene_id": &"linxi_village_center",
		"player_spawn": Vector2(0.5, 0.7),
	})
	var field_scene := load(FIELD_SCENE_PATH) as PackedScene
	_expect(field_scene != null, "walkable field scene failed to load")
	if field_scene == null:
		return
	var field := field_scene.instantiate()
	root.add_child(field)
	await process_frame
	await process_frame
	var hud_layer := field.get_node_or_null("HudCanvasLayer") as CanvasLayer
	var system_layer := field.get_node_or_null("SystemUICanvasLayer") as CanvasLayer
	_expect(hud_layer != null, "walkable field is missing HudCanvasLayer")
	_expect(system_layer != null, "walkable field is missing SystemUICanvasLayer")
	if hud_layer != null:
		_expect(hud_layer.layer == UI_LAYER_POLICY.HUD_LAYER, "field HUD layer value drifted")
	if system_layer != null:
		_expect(system_layer.layer == UI_LAYER_POLICY.SYSTEM_LAYER, "field system UI layer value drifted")
		_expect(system_layer.layer > UI_LAYER_POLICY.HUD_LAYER, "system UI must render above field HUD")
	for node_name in ["FieldPrimaryHud", "HUD", "QuestPanel", "HintBar"]:
		_expect(_is_under_canvas(field.find_child(node_name, true, false), hud_layer), "%s is not under field HUD canvas" % node_name)
	for node_name in ["InventoryPanel", "CharacterPanel", "SkillPanel", "QuestPanelFull", "SparringConfirmation"]:
		_expect(_is_under_canvas(field.find_child(node_name, true, false), system_layer), "%s is not under field system UI canvas" % node_name)
	var player := field.find_child("Player", true, false) as CanvasItem
	if player != null:
		player.z_index = 4096
		_expect(_canvas_ancestor(player) == null, "field actor unexpectedly entered a UI canvas")
	field.queue_free()
	await process_frame


func _validate_legacy_field_layers() -> void:
	var router := root.get_node_or_null("SceneRouter")
	if router == null:
		_expect(false, "SceneRouter autoload is unavailable for legacy field")
		return
	router.set("_field_payload", {"scene_id": &"ch1_s1_road"})
	var field_scene := load(LEGACY_FIELD_SCENE_PATH) as PackedScene
	_expect(field_scene != null, "legacy field scene failed to load")
	if field_scene == null:
		return
	var field := field_scene.instantiate()
	root.add_child(field)
	await process_frame
	var hud_layer := field.get_node_or_null("HudCanvasLayer") as CanvasLayer
	var system_layer := field.get_node_or_null("SystemUICanvasLayer") as CanvasLayer
	for node_name in ["HotspotsContainer", "HUD", "QuestPanel", "HintBar"]:
		_expect(_is_under_canvas(field.find_child(node_name, true, false), hud_layer), "%s is not under legacy field HUD canvas" % node_name)
	for node_name in ["InventoryPanel", "CharacterPanel", "SkillPanel", "QuestPanelFull"]:
		_expect(_is_under_canvas(field.find_child(node_name, true, false), system_layer), "%s is not under legacy field system UI canvas" % node_name)
	field.queue_free()
	await process_frame


func _validate_battle_layers() -> void:
	var router := root.get_node_or_null("SceneRouter")
	_expect(router != null, "SceneRouter autoload is unavailable for battle")
	if router == null:
		return
	router.set("_battle_payload", {"enemy_id": "thug_lone"})
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	_expect(battle_scene != null, "battle scene failed to load")
	if battle_scene == null:
		return
	var battle := battle_scene.instantiate()
	root.add_child(battle)
	await process_frame
	var hud_layer := battle.get_node_or_null("HudCanvasLayer") as CanvasLayer
	var system_layer := battle.get_node_or_null("SystemUICanvasLayer") as CanvasLayer
	_expect(hud_layer != null, "battle is missing HudCanvasLayer")
	_expect(system_layer != null, "battle is missing SystemUICanvasLayer")
	for node_name in ["EnemyHUD", "PlayerHUD", "LogPanel", "ActionPanel"]:
		_expect(_is_under_canvas(battle.find_child(node_name, true, false), hud_layer), "%s is not under battle HUD canvas" % node_name)
	for node_name in ["SkillSelector", "BattleFleeConfirmation"]:
		_expect(_is_under_canvas(battle.find_child(node_name, true, false), system_layer), "%s is not under battle system UI canvas" % node_name)
	# Force the inventory entry point into its legal state so the regression also
	# covers the exact panel shown in the user's screenshot.
	battle.set("_state", 1)
	battle.call("_open_battle_inventory")
	await process_frame
	_expect(
		_is_under_canvas(battle.find_child("BattleInventoryPanel", true, false), system_layer),
		"battle inventory is not under battle system UI canvas"
	)
	battle.queue_free()
	await process_frame


func _validate_dialog_layer() -> void:
	var dialog_scene := load(DIALOG_SCENE_PATH) as PackedScene
	_expect(dialog_scene != null, "dialog scene failed to load")
	if dialog_scene == null:
		return
	var dialog_layer := dialog_scene.instantiate() as CanvasLayer
	_expect(dialog_layer != null, "dialog scene root must be a CanvasLayer")
	if dialog_layer != null:
		_expect(dialog_layer.layer == UI_LAYER_POLICY.DIALOG_LAYER, "dialog canvas layer value drifted")
		_expect(dialog_layer.layer > UI_LAYER_POLICY.SYSTEM_LAYER, "dialog must render above system UI")
		dialog_layer.queue_free()


func _is_under_canvas(node: Node, expected: CanvasLayer) -> bool:
	return node != null and expected != null and _canvas_ancestor(node) == expected


func _canvas_ancestor(node: Node) -> CanvasLayer:
	var cursor := node
	while cursor != null:
		if cursor is CanvasLayer:
			return cursor as CanvasLayer
		cursor = cursor.get_parent()
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
