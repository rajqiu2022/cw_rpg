extends SceneTree

const FIRST_CHAPTER_ENEMIES: Array[StringName] = [
	&"thug_lone",
	&"bandit_mountain",
	&"linxi_dojo_disciple",
	&"linxi_dojo_senior",
	&"zhuwei_bandit",
	&"boss_zhao_wuji",
	&"masked_killer_ambush",
	&"linxi_wild_beast",
]
const STATES := ["ready", "move", "attack", "hit", "defeat"]
const PLAYER_ROOT := "res://art/sprites/battle/standard_v4/lengguyun"


func _init() -> void:
	var failures: Array[String] = []
	_validate_root(PLAYER_ROOT, "lengguyun", failures)
	_validate_root("res://art/sprites/battle/companions_v2/tang_xingzhou", "tang_xingzhou", failures)
	_validate_root("res://art/sprites/battle/companions_v1/shen_qinghe", "shen_qinghe", failures)
	for enemy_id in FIRST_CHAPTER_ENEMIES:
		var path := "res://data/enemies/%s.tres" % enemy_id
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("missing EnemyDef: %s" % path)
			continue
		var source := file.get_as_text()
		for state_name in STATES:
			var property_name := "%s_frame_paths" % state_name
			var line_pattern := RegEx.new()
			line_pattern.compile("(?m)^%s = PackedStringArray\\((.*)\\)$" % property_name)
			var line_match := line_pattern.search(source)
			if line_match == null:
				failures.append("%s is missing %s" % [enemy_id, property_name])
				continue
			var path_pattern := RegEx.new()
			path_pattern.compile("\"([^\"]+)\"")
			var path_matches := path_pattern.search_all(line_match.get_string(1))
			if path_matches.size() != 4:
				failures.append("%s must own 4 %s frames, found %d" % [enemy_id, state_name, path_matches.size()])
			for path_match in path_matches:
				var frame_path := path_match.get_string(1)
				if not ResourceLoader.exists(frame_path):
					failures.append("%s missing %s frame: %s" % [enemy_id, state_name, frame_path])
	if failures.is_empty():
		print("[BattleSpriteSets] PASS: player, ally and %d chapter-one enemies" % FIRST_CHAPTER_ENEMIES.size())
		quit(0)
		return
	for failure in failures:
		push_error("[BattleSpriteSets] %s" % failure)
	quit(1)


func _validate_root(root: String, prefix: String, failures: Array[String]) -> void:
	for state_name in STATES:
		for frame_index in range(1, 5):
			var path := "%s/%s_%s_%02d.png" % [root, prefix, state_name, frame_index]
			if not ResourceLoader.exists(path):
				failures.append("missing ally frame: %s" % path)
				continue
			var texture := load(path) as Texture2D
			if texture == null or texture.get_width() != 512 or texture.get_height() != 384:
				failures.append("ally frame must be 512x384: %s" % path)
