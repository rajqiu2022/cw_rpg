class_name DamageModifierStack
extends RefCounted

## Named damage modifiers. Sources add inside their own zone; zones multiply
## only at the fixed points owned by BattleFormula.

const OUTGOING_MULTIPLIER_MIN := 0.25
const OUTGOING_MULTIPLIER_MAX := 2.0
const INCOMING_MULTIPLIER_MIN := 1.0
const INCOMING_MULTIPLIER_MAX := 2.0

var outgoing_bonuses: Dictionary = {}
var outgoing_penalties: Dictionary = {}
var incoming_vulnerabilities: Dictionary = {}


func add_outgoing_bonus(source: String, amount: float) -> void:
	if source.is_empty() or amount <= 0.0:
		return
	outgoing_bonuses[source] = amount


func add_outgoing_penalty(source: String, amount: float) -> void:
	if source.is_empty() or amount <= 0.0:
		return
	outgoing_penalties[source] = amount


func add_incoming_vulnerability(source: String, amount: float) -> void:
	if source.is_empty() or amount <= 0.0:
		return
	incoming_vulnerabilities[source] = amount


func get_outgoing_bonus_total() -> float:
	return _sum_values(outgoing_bonuses)


func get_outgoing_penalty_total() -> float:
	return _sum_values(outgoing_penalties)


func get_incoming_vulnerability_total() -> float:
	return _sum_values(incoming_vulnerabilities)


func get_outgoing_multiplier() -> float:
	return clampf(1.0 + get_outgoing_bonus_total() - get_outgoing_penalty_total(), OUTGOING_MULTIPLIER_MIN, OUTGOING_MULTIPLIER_MAX)


func get_incoming_multiplier() -> float:
	return clampf(1.0 + get_incoming_vulnerability_total(), INCOMING_MULTIPLIER_MIN, INCOMING_MULTIPLIER_MAX)


func outgoing_summary() -> String:
	var parts := PackedStringArray()
	_append_sources(parts, outgoing_bonuses, "+")
	_append_sources(parts, outgoing_penalties, "-")
	return "、".join(parts)


func incoming_summary() -> String:
	var parts := PackedStringArray()
	_append_sources(parts, incoming_vulnerabilities, "+")
	return "、".join(parts)


func copy() -> DamageModifierStack:
	var result := DamageModifierStack.new()
	result.outgoing_bonuses = outgoing_bonuses.duplicate(true)
	result.outgoing_penalties = outgoing_penalties.duplicate(true)
	result.incoming_vulnerabilities = incoming_vulnerabilities.duplicate(true)
	return result


func clear() -> void:
	outgoing_bonuses.clear()
	outgoing_penalties.clear()
	incoming_vulnerabilities.clear()


func _sum_values(values: Dictionary) -> float:
	var total := 0.0
	for value in values.values():
		total += maxf(0.0, float(value))
	return total


func _append_sources(parts: PackedStringArray, sources: Dictionary, prefix: String) -> void:
	var names := sources.keys()
	names.sort()
	for raw_name in names:
		parts.append("%s%s%d%%" % [String(raw_name), prefix, int(round(float(sources[raw_name]) * 100.0))])
