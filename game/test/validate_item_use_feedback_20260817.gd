extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	if int(inventory.call("count_of", &"linxi_jiu")) <= 0:
		inventory.call("add_item", &"linxi_jiu", 1)
	var scene := load("res://scenes/ui/character_panel.tscn") as PackedScene
	_check(scene != null, "character panel scene loads")
	if scene == null:
		_finish()
		return
	var panel := scene.instantiate()
	root.add_child(panel)
	await process_frame
	var player := game_state.get("player") as CharacterStats
	var old_max_hp := player.max_hp
	var old_max_mp := player.max_mp
	var old_count := int(inventory.call("count_of", &"linxi_jiu"))
	_check(bool(panel.call("_use_consumable_for", &"protagonist", &"linxi_jiu")), "Linxi wine use succeeds through character panel")
	_check(player.max_hp == old_max_hp + 100, "Linxi wine increases life maximum by 100")
	_check(player.max_mp == old_max_mp + 50, "Linxi wine increases inner-power maximum by 50")
	_check(int(inventory.call("count_of", &"linxi_jiu")) == old_count - 1, "Linxi wine consumes one item")
	var toast := panel.get_node_or_null("ItemEffectToast") as PanelContainer
	_check(toast != null, "successful item use creates an effect toast")
	var effect_text: RichTextLabel = null
	if toast != null:
		effect_text = toast.get_node_or_null("EffectText") as RichTextLabel
	_check(effect_text != null and "林西酒" in effect_text.text, "toast identifies the used item")
	_check(effect_text != null and "生命上限" in effect_text.text and "+100" in effect_text.text, "toast shows the life maximum gain")
	_check(effect_text != null and "内功上限" in effect_text.text and "+50" in effect_text.text, "toast shows the inner-power maximum gain")
	var source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
	_check(source.contains("_use_consumable_for(character_id, item_id)"), "confirmed precious-item path uses the same feedback helper")
	_check(source.contains("Inventory.use_item_for(character_id, item_id, false)"), "feedback helper uses canonical Inventory API")
	panel.queue_free()
	_finish()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[ItemUseFeedback20260817] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[ItemUseFeedback20260817] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
