extends Node

var failures: Array[String] = []


func _ready() -> void:
	GameState.reset_for_new_game()
	GameState.player.insight = 6
	_check(not GameState.learn_skill(&"canglong_three_turns"), "悟性不足时不能习得藏龙三转")
	_check(&"canglong_three_turns" in GameState.pending_skill_unlocks, "一次性剧情武学会进入待领悟列表")
	GameState.player.insight = 9
	GameState._reconcile_pending_skills()
	_check(&"canglong_three_turns" in GameState.player.skills, "达到悟性门槛后自动领悟待处理武学")
	GameState.add_training_points(100)
	var cost := GameState.get_skill_practice_cost(&"canglong_three_turns")
	_check(cost == 36, "达到门槛时首层研读费用为 36")
	_check(GameState.practice_skill(&"canglong_three_turns"), "阅历充足时可以研读招式")
	_check(GameState.training_points_available == 100 - cost, "研读只扣可用阅历")
	_check(GameState.training_points_total == 100, "总阅历不因研读而减少")

	print("[InsightLearningRuntime] checks=7 failed=%d" % failures.size())
	for failure in failures:
		push_error("[InsightLearningRuntime] %s" % failure)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
