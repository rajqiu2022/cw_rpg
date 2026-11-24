extends SceneTree

var failures := 0


func _initialize() -> void:
	_check_same_zone_addition()
	_check_zone_caps()
	_check_formula_order()
	_check_production_contract()
	print("[DamageModifierZones20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_same_zone_addition() -> void:
	var modifiers := DamageModifierStack.new()
	modifiers.add_outgoing_bonus("影杀", 0.20)
	modifiers.add_outgoing_bonus("武器增伤", 0.30)
	modifiers.add_outgoing_penalty("虚弱", 0.30)
	modifiers.add_incoming_vulnerability("破绽", 0.25)
	_check(is_equal_approx(modifiers.get_outgoing_multiplier(), 1.20), "outgoing bonuses and penalties add inside one source zone")
	_check(is_equal_approx(modifiers.get_incoming_multiplier(), 1.25), "incoming vulnerability owns a separate multiplier zone")
	modifiers.add_outgoing_bonus("影杀", 0.40)
	_check(is_equal_approx(modifiers.get_outgoing_multiplier(), 1.40), "same named source replaces instead of stacking twice")


func _check_zone_caps() -> void:
	var modifiers := DamageModifierStack.new()
	modifiers.add_outgoing_bonus("甲", 0.80)
	modifiers.add_outgoing_bonus("乙", 0.70)
	_check(is_equal_approx(modifiers.get_outgoing_multiplier(), 2.0), "outgoing damage zone is capped at +100%")
	modifiers.clear()
	modifiers.add_outgoing_penalty("重伤", 0.60)
	modifiers.add_outgoing_penalty("虚弱", 0.40)
	_check(is_equal_approx(modifiers.get_outgoing_multiplier(), 0.25), "outgoing penalty zone keeps a 25% damage floor")
	modifiers.add_incoming_vulnerability("破绽", 1.50)
	_check(is_equal_approx(modifiers.get_incoming_multiplier(), 2.0), "incoming vulnerability is capped at +100%")


func _check_formula_order() -> void:
	var modifiers := DamageModifierStack.new()
	modifiers.add_outgoing_bonus("影杀", 0.20)
	modifiers.add_incoming_vulnerability("破绽", 0.25)
	var detail := BattleFormula.calc_damage_breakdown(100, 0, 100, 20, 1.0, 1.0, false, false, 100, 100, 1.0, "", modifiers)
	_check(detail.damage_after_defense == 80, "defense resolves before status multiplier zones")
	_check(detail.damage_after_outgoing == 96, "outgoing zone resolves after defense")
	_check(detail.damage_after_incoming == 120 and detail.final_damage == 120, "incoming vulnerability resolves after outgoing zone")
	_check("影杀" in detail.to_gm_text() and "破绽" in detail.to_gm_text(), "GM breakdown lists named modifier sources")


func _check_production_contract() -> void:
	var controller_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(controller_source.contains("DamageModifierStack"), "battle controller builds one shared modifier stack")
	_check(not controller_source.contains("float(raw) * 1.2"), "shadow execution no longer multiplies damage outside the formula")
	_check(controller_source.contains("weapon.special_effect_duration) + 1"), "weapon damage boost survives the application action")
	_check(controller_source.contains("active_duration if active_duration > 0 else 2) + 1"), "active internal-art boost starts counting after its cast action")
	var contract := FileAccess.get_file_as_string("res://docs/combat-damage-pipeline-v1.md") if FileAccess.file_exists("res://docs/combat-damage-pipeline-v1.md") else ""
	_check(contract.is_empty() or "攻击方修正区" in contract, "damage contract documents the named modifier zones")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
