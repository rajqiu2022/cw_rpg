extends SceneTree

var _accepted: Dictionary = {}
var _completed: Dictionary = {}
var _failures: Array[String] = []


func _initialize() -> void:
	_scan_dialogs()
	_validate_quests()
	for failure in _failures:
		push_error("[Ch2SideQuestCheck] %s" % failure)
	print("[Ch2SideQuestCheck] accepted=%d completed=%d failed=%d" % [
		_accepted.size(), _completed.size(), _failures.size(),
	])
	quit(1 if not _failures.is_empty() else 0)


func _scan_dialogs() -> void:
	var dir := DirAccess.open("res://data/dialogs")
	if dir == null:
		_failures.append("cannot open dialog directory")
		return
	for file_name in dir.get_files():
		if not file_name.begins_with("ch2_") or not file_name.ends_with(".tres"):
			continue
		var dialog: Resource = ResourceLoader.load("res://data/dialogs/%s" % file_name)
		if dialog == null:
			continue
		for node in dialog.nodes:
			var accepted: String = String(node.accept_quest)
			var completed: String = String(node.complete_quest)
			if accepted.begins_with("q_ch2_side_"):
				_accepted[accepted] = true
			if completed.begins_with("q_ch2_side_"):
				_completed[completed] = true


func _validate_quests() -> void:
	var dir := DirAccess.open("res://data/quests")
	if dir == null:
		_failures.append("cannot open quest directory")
		return
	for file_name in dir.get_files():
		if not file_name.begins_with("q_ch2_side_") or not file_name.ends_with(".tres"):
			continue
		var quest: Resource = ResourceLoader.load("res://data/quests/%s" % file_name)
		if quest == null:
			_failures.append("cannot load %s" % file_name)
			continue
		var quest_id: String = String(quest.quest_id)
		if not _accepted.has(quest_id):
			_failures.append("missing acceptance source: %s" % quest_id)
		if not _completed.has(quest_id) and quest.completion_triggers.is_empty():
			_failures.append("missing completion source: %s" % quest_id)
