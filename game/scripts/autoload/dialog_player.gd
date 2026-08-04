extends Node

## 全局对话播放器。
## 用法：
##   var script = load("res://data/dialogs/ch1_road_intro.tres")
##   DialogPlayer.play(script)
##   await DialogPlayer.dialog_ended

signal text_displayed(speaker: String, text: String, has_choices: bool, portrait_path: String)
signal choices_displayed(choices: Array)
signal dialog_ended(dialog_id: StringName)

const DIALOG_BOX_SCENE_PATH := "res://scenes/ui/dialog_box.tscn"
const SPEAKER_PORTRAITS := {
	"悦无姮": "res://art/characters/portrait_yuewuheng_rescue.png",
}

var _current_script: DialogScript = null
var _current_node: DialogNode = null
var _is_playing: bool = false
var _default_portrait: String = ""
var _default_speaker: String = ""

var _box: Node = null


func _ready() -> void:
	if ResourceLoader.exists(DIALOG_BOX_SCENE_PATH):
		var scn: PackedScene = load(DIALOG_BOX_SCENE_PATH)
		_box = scn.instantiate()
		add_child(_box)


# --- 公开 API ---

func is_playing() -> bool:
	return _is_playing


func set_default_portrait(path: String) -> void:
	_default_portrait = path


func set_default_speaker(npc_name: String) -> void:
	_default_speaker = npc_name


func play(script: DialogScript) -> void:
	if script == null:
		push_warning("[DialogPlayer] null script")
		return
	_current_script = script
	_is_playing = true
	EventBus.dialog_started.emit(script.dialog_id)
	_show_node(script.get_entry_node())
	_prewarm_voices.call_deferred()


func play_at(script: DialogScript, node_id: StringName) -> void:
	if script == null: return
	_current_script = script
	_is_playing = true
	EventBus.dialog_started.emit(script.dialog_id)
	_show_node(script.find_node_by_id(node_id))
	_prewarm_voices.call_deferred()


func advance() -> void:
	if _current_node == null: return
	if _current_node.has_choices():
		return
	AudioManager.stop_all_sfx()
	_apply_node_side_effects(_current_node)
	_resolve_action(_current_node.on_end)


func choose(idx: int) -> void:
	if _current_node == null: return
	if not _current_node.has_choices(): return
	if idx < 0 or idx >= _current_node.choices.size(): return

	var c: Dictionary = _current_node.choices[idx]
	if c.has("set_flag"):
		var flag_dict: Dictionary = c.get("set_flag", {})
		@warning_ignore("untyped_declaration")
		for key in flag_dict:
			GameState.flags[key] = flag_dict[key]
			EventBus.flag_set.emit(StringName(key), flag_dict[key])

	var next_id: String = String(c.get("next", ""))
	if next_id == "" or next_id == "end":
		_end_dialog()
	else:
		_show_node(_current_script.find_node_by_id(StringName(next_id)))


# --- 内部 ---

func _show_node(node: DialogNode) -> void:
	if node == null:
		_end_dialog()
		return
	_current_node = node
	var spk: String = node.speaker
	if spk == "" and _default_speaker != "":
		spk = _default_speaker
	var pp: String = node.portrait_path
	if pp == "" and _default_portrait != "":
		pp = _default_portrait
	if pp == "" and SPEAKER_PORTRAITS.has(spk):
		pp = String(SPEAKER_PORTRAITS[spk])

	# 播放对话语音 (如果有)
	_play_node_voice(spk, String(node.node_id))

	text_displayed.emit(
		spk,
		node.text,
		node.has_choices(),
		pp
	)
	if node.has_choices():
		choices_displayed.emit(node.choices)


func _apply_node_side_effects(node: DialogNode) -> void:
	for entry in node.give_items:
		var iid: StringName = StringName(entry.get("id", ""))
		var cnt: int = int(entry.get("count", 1))
		if String(iid) != "":
			Inventory.add_item(iid, cnt)

	if node.give_gold > 0:
		GameState.add_gold(node.give_gold)

	for flag_entry in node.set_flags:
		var key: String = String(flag_entry.get("key", ""))
		var value: Variant = flag_entry.get("value", true)
		if key != "":
			GameState.flags[key] = value
			EventBus.flag_set.emit(StringName(key), value)

	if String(node.accept_quest) != "":
		QuestManager.accept(node.accept_quest)

	if String(node.complete_quest) != "":
		QuestManager.complete(node.complete_quest)


func _resolve_action(action: String) -> void:
	if action == "" or action == "end":
		_end_dialog()
		return

	var parts: PackedStringArray = action.split(":", true, 1)
	var cmd: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""

	if cmd == "next":
		_show_node(_current_script.find_node_by_id(StringName(arg)))
		return

	_end_dialog()
	SceneRouter.resolve_action(action)


func _play_node_voice(speaker: String, node_id: String) -> void:
	if _current_script == null: return
	var dialog_id: String = String(_current_script.dialog_id)
	if dialog_id == "": return
	var ch := dialog_id.substr(0, 3)
	var safe_spk := speaker.replace("/", "_").replace("\\", "_")
	var emotion := _detect_emotion(String(_current_node.text)) if _current_node != null else "normal"
	# 优先带情感后缀，缺失则回退普通
	var path := "res://art/audio/voices/%s/%s/%s_%s_e%s.mp3" % [ch, dialog_id, safe_spk, node_id, emotion]
	if not ResourceLoader.exists(path):
		path = "res://art/audio/voices/%s/%s/%s_%s.mp3" % [ch, dialog_id, safe_spk, node_id]
	if ResourceLoader.exists(path):
		AudioManager.play_voice(path)
		# 旁白紧随其后播放
		var narr_path := "res://art/audio/voices/%s/%s/%s_%s_narr.mp3" % [ch, dialog_id, safe_spk, node_id]
		if ResourceLoader.exists(narr_path):
			await _play_narration_after(narr_path)


func _play_narration_after(narr_path: String) -> void:
	# 等主语音完全播完（playing 变 false 后再等 3 帧确保 buffer 清空）
	while AudioManager.is_voice_playing():
		await get_tree().process_frame
	for _i in 5:
		await get_tree().process_frame
	AudioManager.play_voice(narr_path)


func _detect_emotion(text: String) -> String:
	if text.contains("别过来") or text.contains("救命") or text.contains("饶命") or text.contains("放过"):
		return "fear"
	if text.contains("哈哈") or text.contains("太好了") or text.contains("痛快"):
		return "happy"
	if text.contains("对不起") or text.contains("永别") or text.contains("舍不得"):
		return "sad"
	if text.contains("把东西留下") or text.contains("受死") or text.contains("识相"):
		return "threat"
	return "normal"


func _prewarm_voices() -> void:
	if _current_script == null: return
	var dialog_id: String = String(_current_script.dialog_id)
	if dialog_id == "": return
	var ch := dialog_id.substr(0, 3)
	for node in _current_script.nodes:
		var spk: String = node.speaker if node.speaker != "" else "旁白"
		var safe_spk := spk.replace("/", "_").replace("\\", "_")
		var emotion := _detect_emotion(node.text)
		var path := "res://art/audio/voices/%s/%s/%s_%s_e%s.mp3" % [ch, dialog_id, safe_spk, String(node.node_id), emotion]
		if AudioManager._sfx_cache.has(path): continue
		var stream := load(path) as AudioStream
		if stream == null:
			var plain := "res://art/audio/voices/%s/%s/%s_%s.mp3" % [ch, dialog_id, safe_spk, String(node.node_id)]
			stream = load(plain) as AudioStream
		if stream != null:
			AudioManager._sfx_cache[path] = stream


func _end_dialog() -> void:
	var id: StringName = _current_script.dialog_id if _current_script != null else &""

	_current_script = null
	_current_node = null
	_is_playing = false
	_default_portrait = ""
	_default_speaker = ""
	dialog_ended.emit(id)
	EventBus.dialog_ended.emit(id)
