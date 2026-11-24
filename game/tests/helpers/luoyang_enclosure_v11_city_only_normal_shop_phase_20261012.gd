extends "res://tests/helpers/luoyang_enclosure_v11_bounty_shop_source_bound_stock20_phase_20261012.gd"
## Full run_city_stage/_finish_city_stage are inherited unchanged from 47006.
## Only the two-bounty segment installs D699; all other normal inputs and the
## physical probe's own driver keep their original instances and strategy.
const FULL_SHOP_PARENT_PATH := "res://tests/helpers/luoyang_enclosure_v11_bounty_shop_source_bound_stock20_phase_20261012.gd"
const FULL_SHOP_PARENT_SHA := "70ae0eaa090b25ddad440aa501480a9ced41da6f29956a29ae3fb57270e43faa"
const FULL_BOUNTY_SEGMENT_SCOPE := "BOUNTY_SEGMENT_ONLY"

func _normal_bounty_rewards() -> void:
	var original_driver: RefCounted=driver
	if not _check(tree!=null and original_driver!=null and original_driver.get_script()==INPUT and FileAccess.get_sha256(FULL_SHOP_PARENT_PATH)==FULL_SHOP_PARENT_SHA and FileAccess.get_sha256(HEALTH_INPUT_PATH)==HEALTH_INPUT_SHA,"full bounty bridge keeps original driver and exact stock20/health sources"): return
	var observer: RefCounted=HEALTH_INPUT.new()
	observer.call("configure",tree)
	driver=observer
	var installed: bool=driver.get_script()==HEALTH_INPUT and driver.get_script().resource_path==HEALTH_INPUT_PATH
	if _check(installed,"actual D699 installed only for original two-bounty segment, no lexical INPUT shadow"):
		await super._normal_bounty_rewards()
	# Every normal early return from the inherited method reaches this cleanup.
	# Do not release the original driver retained by the other whole-stage inputs.
	observer.call("release")
	var health: Dictionary=(observer.call("get_health_observation") as Dictionary).duplicate(true)
	driver=original_driver
	_check(not health.is_empty() and health.get("overflow")==false and health.get("connected")==false and health.get("released")==true and health.get("Stats_modified")==false and health.get("strategy_modified")==false and health.get("pointer_return_modified")==false,"bounty-only bounded passive health observations and symmetric release")
	_check(driver==original_driver,"original whole-stage input driver restored before all55 negatives and cleanup")
	var appendix: Dictionary={
		"scope":FULL_BOUNTY_SEGMENT_SCOPE,
		"battle_strategy_modified":true,
		"Attack_only":false,
		"strategy_scope":"NORMAL_SHOP_EQUIP_HEAL_QUARTER_HP_STOCK20",
		"passive_health_strategy_modified_false_scope":"D699_OBSERVER_ONLY",
		"health_observation_scope":"FRAME_AND_IMMEDIATE_EVENT_ONLY_NOT_PER_DAMAGE",
		"per_damage_tested":false,
		"Battle_returned_Loading_semantics_fixed":false,
		"other_city_actions_strategy_modified":false,
		"physical_probe_driver_replaced":false,
		"original_driver_script_path":original_driver.get_script().resource_path,
		"health_driver_path":HEALTH_INPUT_PATH,
		"health_driver_sha256":HEALTH_INPUT_SHA,
		"stock20_parent_path":FULL_SHOP_PARENT_PATH,
		"stock20_parent_sha256":FULL_SHOP_PARENT_SHA,
		"normal_shop_supplies":supply_record.duplicate(true),
		"health_observation":health,
		"travel_ready":travel_ready_rows.duplicate(true),
		"ordinary_encounters":(records.get("ordinary_encounters",[]) as Array).duplicate(true),
	}
	records["bounty_segment_execution"]=appendix.duplicate(true)
	_check(_write("bounty_segment_execution.json",appendix),"bounty-segment shop/health/travel/ordinary appendix persisted before original whole finish")
	observer=null

