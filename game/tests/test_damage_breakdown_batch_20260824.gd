extends SceneTree

var failures := 0


func _initialize() -> void:
	_check_soft_cap_and_stages()
	_check_status_modifiers()
	_check_miss_breakdown()
	_check_event_contract()
	print("[DamageBreakdownBatch20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_soft_cap_and_stages() -> void:
	var detail := BattleFormula.calc_damage_breakdown(100, 20, 150, 30, 1.0, 3.4, false, false, 100, 100)
	_check(detail is DamageBreakdown, "deterministic damage calculation returns DamageBreakdown")
	_check(detail.scaled_attack == 150 and detail.offense_before_variance == 170, "breakdown records attack basis and fixed damage")
	_check(is_equal_approx(detail.requested_crit_multiplier, 3.4), "breakdown records requested crit multiplier")
	_check(is_equal_approx(detail.crit_multiplier, 2.2) and detail.crit_multiplier_capped, "critical multiplier is capped at 2.2x")
	_check(detail.damage_after_crit == 374, "critical stage is calculated before defense")
	_check(detail.effective_defense == 30 and detail.damage_after_defense == 344, "defense stage is recorded once")
	_check(detail.final_damage == 344, "final damage matches stage total")
	_check("2.20" in detail.to_gm_text() and "344" in detail.to_gm_text(), "GM summary exposes cap and final damage")


func _check_status_modifiers() -> void:
	var detail := BattleFormula.calc_damage_breakdown(60, 10, 100, 20, 1.0, 1.0, true, true, 25, 100, 1.2, "剧情修正")
	_check(detail.effective_defense == 10, "target weakness halves effective defense")
	_check(is_equal_approx(detail.source_weak_multiplier, 0.7), "source weakness multiplier is explicit")
	_check(is_equal_approx(detail.low_hp_multiplier, 1.0), "low HP alone no longer reduces outgoing damage")
	_check(is_equal_approx(detail.post_multiplier, 1.2) and detail.post_modifier_label == "剧情修正", "post modifier is named and recorded")
	_check(detail.final_damage == 50, "explicit weaken and named modifier remain: round((70-10)*0.7*1.2)")


func _check_miss_breakdown() -> void:
	var result := BattleFormula.calc_damage(80, 10, 100, 12, true, 0.0, 0.0, false, false, false, 100, 100, 0.0, 0.0)
	var detail := result.get("breakdown") as DamageBreakdown
	_check(not bool(result.get("hit", true)) and int(result.get("dealt", -1)) == 0, "zero hit chance always produces a miss")
	_check(detail != null and not detail.hit and detail.final_damage == 0, "miss still returns a traceable breakdown")


func _check_event_contract() -> void:
	var event_bus := root.get_node_or_null("EventBus")
	_check(event_bus != null and event_bus.has_signal("damage_calculated"), "EventBus exposes the damage breakdown signal")
	var gm_source := FileAccess.get_file_as_string("res://scripts/autoload/gm_console.gd")
	_check(gm_source.contains("record_damage_breakdown"), "GM console records the latest damage breakdown")
	_check(gm_source.contains("伤害分析"), "GM console exposes a damage analysis section")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
