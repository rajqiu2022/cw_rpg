extends SceneTree
## Run with the PC project and an output filename after "--".

const MUSIC := preload("res://scripts/audio/music_catalog.gd")
var lengths := {}
var audio: Node
var dialogue: Node

func _initialize() -> void:
	call_deferred("collect")

func files_in(directory: String) -> Array[String]:
	var result: Array[String] = []
	for name in DirAccess.get_files_at(directory):
		if name.ends_with(".tres"):
			result.append(directory.path_join(name))
	for folder in DirAccess.get_directories_at(directory):
		result.append_array(files_in(directory.path_join(folder)))
	return result

func duration(path: String) -> float:
	if path.is_empty():
		return 0.0
	if not lengths.has(path):
		var stream := load(path) as AudioStream if ResourceLoader.exists(path, "AudioStream") else null
		lengths[path] = stream.get_length() if stream != null else 0.0
	return lengths[path]

func voice_row(script: DialogScript, node: DialogNode, speaker: String) -> Dictionary:
	var row := {"id": node.node_id, "speaker": speaker, "text": node.text, "clips": [], "status": "未找到录音"}
	if speaker.is_empty():
		row.status = "交互时确定说话人"
		return row
	var id := String(script.dialog_id)
	var safe := speaker.replace("/", "_").replace("\\", "_")
	var base := "res://art/audio/voices/%s/%s/%s_%s" % [id.left(3), id, safe, node.node_id]
	var kinds: Array = dialogue._speech_segment_kinds(node.text, speaker)
	var segments: Array[String] = []
	for i in kinds.size():
		var path: String = dialogue._segment_voice_path(id.left(3), id, safe, String(node.node_id), i, kinds[i])
		if duration(path) > 0:
			segments.append(path)
	if not segments.is_empty() and segments.size() == kinds.size():
		row.clips = segments
		row.status = "分段齐备"
		return row
	for path: String in [base + "_e" + dialogue._node_emotion(node) + ".mp3", base + ".mp3"]:
		if duration(path) > 0:
			row.clips.append(path)
			row.status = "有整句录音"
			break
	if row.clips.is_empty() and not segments.is_empty():
		row.clips = segments
		row.status = "部分分段"
	elif speaker != "旁白" and dialogue._has_inline_narration(node.text) and duration(base + "_narr.mp3") > 0:
		if row.clips.is_empty():
			row.status = "仅有旁述"
		if dialogue._narration_leads(node.text):
			row.clips.push_front(base + "_narr.mp3")
		else:
			row.clips.append(base + "_narr.mp3")
	return row

func scene_music(rows: Dictionary, id: StringName, label: String, intro: StringName = &"", override: String = "") -> void:
	var flat := "res://data/scenes/%s.tres" % id
	var base := load(flat) as SceneScript if ResourceLoader.exists(flat) else null
	var selected := override
	if selected.is_empty() and base != null:
		selected = MUSIC.scene_bgm(id, audio._normalized_audio_path(base.bgm_path))
	var fallback := selected.is_empty() or not ResourceLoader.exists(selected)
	if fallback:
		selected = audio.DEFAULT_FIELD_BGM
	rows[id] = [id, label, selected, duration(selected), fallback, intro,
			"室内沿用街区源曲" if not override.is_empty() else ""]

func collect() -> void:
	audio = root.get_node("AudioManager")
	dialogue = root.get_node("DialogPlayer")
	var result := {"dialogs": [], "scenes": [], "cues": [], "battle": [], "hooks": [], "effects": []}
	var actors := {}
	for path in files_in("res://data/scenes"):
		var scene := load(path) as SceneScript
		if scene == null or root.get_node("SceneRouter").field_scene_resource_path(scene.scene_id) != path:
			continue
		for npc in scene.npcs:
			var name := str(npc.get("npc_name", ""))
			if name.is_empty():
				continue
			var variants: Array = npc.get("dialog_variants", []).duplicate()
			variants.append(npc)
			for variant: Dictionary in variants:
				var id := str(variant.get("dialog_id", ""))
				if not id.is_empty():
					if not actors.has(id):
						actors[id] = []
					if not actors[id].has(name):
						actors[id].append(name)
	for path in files_in("res://data/dialogs"):
		var script := load(path) as DialogScript
		if script == null:
			continue # Includes external DialogNode resources.
		var rows := []
		for node in script.nodes:
			if node == null or node.text.strip_edges().is_empty():
				continue
			var row := voice_row(script, node, node.speaker)
			if node.speaker.is_empty():
				row["candidates"] = []
				row["narration"] = voice_row(script, node, "旁白")
				for name: String in actors.get(String(script.dialog_id), []):
					row.candidates.append(voice_row(script, node, name))
			rows.append(row)
			var actions := [node.on_end]
			for choice in node.choices:
				actions.append(choice.get("action", ""))
			for action: String in actions:
				if action.begins_with("field_cutscene:"):
					result.hooks.append([script.dialog_id, node.node_id, action.trim_prefix("field_cutscene:")])
		result.dialogs.append({"id": script.dialog_id, "source": path, "rows": rows})
	# Scene music is resolved from the top-level ID by AudioManager, even for
	# registered nested rooms. Avoid counting alternate candidate copies as rooms.
	var scene_rows := {}
	var router := root.get_node("SceneRouter")
	for path in files_in("res://data/scenes"):
		var scene := load(path) as SceneScript
		if scene == null or scene_rows.has(scene.scene_id):
			continue
		var source: String = router.field_scene_resource_path(scene.scene_id)
		if not ResourceLoader.exists(source):
			continue
		var registered := load(source) as SceneScript
		if registered == null or registered.scene_id != scene.scene_id:
			continue
		scene_music(scene_rows, scene.scene_id, registered.display_name,
				registered.on_enter_dialog.dialog_id if registered.on_enter_dialog != null else &"")
	var towns := load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	for id in towns.IDS:
		if not scene_rows.has(id):
			scene_music(scene_rows, id, towns.town(id).get("label", id))
	for id in [router.WORLD_MAP_V16_SCENE, router.ESTATE_AM.ID] + Array(router.AP_QUARTERS.IDS):
		if not scene_rows.has(id):
			var mapped_path: String = router.field_scene_resource_path(id)
			if not mapped_path.is_empty() and ResourceLoader.exists(mapped_path):
				var mapped := load(mapped_path) as SceneScript
				scene_music(scene_rows, id, mapped.display_name)
	# A native room first emits scene_entered, then explicitly plays the BGM
	# of its source district. Read the same compiled room and source bindings.
	var entry: Script = router.REGION27D.Entry
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(entry.MANIFEST_PATH))
	var author: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest.author.path))
	for id in entry.ALIASES:
		var region: String = entry.ALIASES[id]
		var compiled: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(manifest.compiled_bindings[region].path))
		if compiled.get("navigation_kind") == "AUTHORED_INTERIOR":
			var logical: String = compiled.room_source_logical_id
			var terminal: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(author.terminal_bindings[logical].path))
			var source := load(terminal.source_scene_path) as SceneScript
			var room := load(entry.SCENE_RESOURCES[region]) as SceneScript
			scene_music(scene_rows, id, room.display_name, &"", source.bgm_path)
		elif not scene_rows.has(id) and author.terminal_bindings.has(id):
			var terminal: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(author.terminal_bindings[id].path))
			var source := load(terminal.source_scene_path) as SceneScript
			scene_music(scene_rows, id, source.display_name, source.on_enter_dialog.dialog_id if source.on_enter_dialog else &"")
	result.scenes = scene_rows.values()
	for table: Dictionary in [MUSIC.DIALOG_TRACKS, MUSIC.DIALOG_NODE_TRACKS]:
		for key in table:
			var path := MUSIC.track_path(table[key])
			result.cues.append([key, path, duration(path)])
	var battle := load("res://scripts/battle/battle_controller.gd").get_script_constant_map() as Dictionary
	for arena in battle.BATTLE_ARENA_BGM:
		var path: String = battle.BATTLE_ARENA_BGM[arena]
		result.battle.append([arena, path, duration(path)])
	for key in audio.get_script().get_script_constant_map():
		if String(key).ends_with("_SFX"):
			var path: String = audio.get(key)
			result.battle.append([key, path, duration(path)])
	var battle_cues := {"ENEMY_VANISH_SFX": battle.ENEMY_VANISH_SFX, "BATTLE_BOSS_BGM": battle.BATTLE_BOSS_BGM}
	for key: String in battle_cues:
		var path: String = battle_cues[key]
		result.battle.append([key, path, duration(path)])
	var victory: String = load("res://scripts/battle/battle_actor.gd").VICTORY_MUSIC
	result.battle.append(["VICTORY_MUSIC", victory, duration(victory)])
	for directory: String in ["skills", "enemies"]:
		var fields := ["cast_sfx_path", "impact_sfx_path"] if directory == "skills" else ["ready_sfx_path", "attack_sfx_path", "hit_sfx_path", "defeat_sfx_path"]
		for path in files_in("res://data/" + directory):
			var definition := load(path)
			if not (definition is Skill or definition is EnemyDef):
				continue
			var cues := {}
			for field: String in fields:
				var cue: String = definition.get(field)
				cues[field] = [cue, duration(cue)]
			result.effects.append([directory, path.get_file().get_basename(), cues])
	# Exercise the production dialogue signals and inspect the playing streams.
	result["samples"] = []
	for pair in [["ch1_s1_road", "ch1_road_corpse"], ["ch8_s5_alliance_ceremonial_platform", "ch8_false_order_prebattle"], ["ch8_s5_alliance_ceremonial_platform", "ch8_false_order_prebattle", "declare"], ["ch8_s7_mingwu_rear_sanctum", "ch8_su_final_prelude_dead"], ["ch1_s1_road", "ch1_side_caravan_victory", "thanks"]]:
		audio.ensure_bgm_for_scene(pair[0])
		var base: String = audio.get_current_bgm()
		var script := load("res://data/dialogs/%s.tres" % pair[1]) as DialogScript
		var label: String = pair[1]
		if pair.size() > 2:
			dialogue.play_at(script, StringName(pair[2]))
			label += ":" + String(pair[2])
		else:
			dialogue.play(script)
		await create_timer(0.12).timeout
		var player: AudioStreamPlayer = audio._voice_player
		var clip := player.stream.resource_path if player.playing and player.stream != null else ""
		result.samples.append([label, base, audio.get_current_bgm(), audio.bgm_player.playing, clip])
		dialogue._end_dialog()
		await process_frame
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	if file == null:
		quit(2)
		return
	file.store_string(JSON.stringify(result))
	file.close()
	print("CATALOG_MEDIA dialogs=", result.dialogs.size(), " scenes=", result.scenes.size(), " effects=", result.effects.size())
	quit()
