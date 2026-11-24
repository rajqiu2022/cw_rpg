extends SceneTree

## Every skill authored on an enemy must be usable at least once from its
## starting inner-power pool. Otherwise the battle silently degrades to basic
## attacks even though design data advertises a signature move.

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	var directory := DirAccess.open("res://data/enemies")
	_check(directory != null, "敌人资源目录可读取")
	if directory == null:
		_finish()
		return
	for filename: String in directory.get_files():
		if not filename.ends_with(".tres"):
			continue
		var enemy := load("res://data/enemies/%s" % filename) as EnemyDef
		if enemy == null:
			continue
		for skill_id: StringName in enemy.skill_ids:
			if skill_id == &"basic_attack" or skill_id == &"defend":
				continue
			var skill := load("res://data/skills/%s.tres" % String(skill_id)) as Skill
			_check(skill != null, "%s：技能%s可加载" % [enemy.display_name, String(skill_id)])
			if skill == null:
				continue
			_check(enemy.max_mp >= skill.mp_cost, "%s：开场内力%d足够施展%s（消耗%d）" % [enemy.display_name, enemy.max_mp, skill.display_name, skill.mp_cost])
	_finish()


func _finish() -> void:
	print("[EnemySkillBudget20260909] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[EnemySkillBudget20260909] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
