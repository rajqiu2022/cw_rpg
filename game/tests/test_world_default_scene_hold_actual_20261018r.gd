extends "res://tests/test_world_visible_stream_default_diagnostic_20261018r.gd"
## One ordinary default/null world birth. Original first-draw instrument and
##90s/60s,16px normal INPUT, full streamed/physical oracle,1PNG and drain0.
const HOLD_READY=true
const HOLD_CORE="res://tests/fixtures/world_default_hold_final_core_20261018r.json"
const HOLD_CORE_SHA="496f5038ab05e2ce5765c1d0ca6c86b8e1f5db4519ec3803aecbea53c697f438"
const HOLD_PARENT="res://tests/test_world_visible_stream_default_diagnostic_20261018r.gd"
const HOLD_PARENT_SHA="befea0e9fd161909298bcd2286541d9442083592fbd0c4d52e3ac61c83b52dc5"
const HOLD_CONTRACT="res://scripts/world/world_map_v15_contract.gd"
const HOLD_CONTRACT_SHA="b01bcf23c45c37cca5d59072c1baa56efd4c6244b290887e51b4f85ac0d0f5b7"
const HOLD_BEFORE="res://build/luoyang_loading_10s_20261018r_root01/deployment_before/world_contract_C10E.source"
const HOLD_BEFORE_SHA="c10efd8bfeca980325ac0d8d4dcd99a03f5d01aba636efabc524a1cb9f43def8"
const HOLD_DEFINITION="res://data/scenes/world_map_jianghu.tres"
const HOLD_DEFINITION_SHA="685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046"
const HOLD_LAYOUT="res://data/maps/world_map_jianghu_layout_v15.tres"
const HOLD_LAYOUT_SHA="aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072"

func precheck() -> bool:
	if not check(HOLD_READY and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary default world single-Scene hold, no candidate flags"): return false
	for pair: Array in [[HOLD_CORE,HOLD_CORE_SHA],[HOLD_PARENT,HOLD_PARENT_SHA],[DIAGNOSTIC_PARENT,DIAGNOSTIC_PARENT_SHA],[DEFAULT_WORLD_BASE,DEFAULT_WORLD_BASE_SHA],[WORLD_TOOL_PATH,WORLD_TOOL_SHA],[DIAGNOSTIC_PATCH,DIAGNOSTIC_PATCH_SHA],[DIAGNOSTIC_CORE,DIAGNOSTIC_CORE_SHA],[HOLD_BEFORE,HOLD_BEFORE_SHA]]:
		if not track(pair[0],pair[1]): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(HOLD_CORE))
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIAGNOSTIC_CORE))
	if not check(core.source_sha256.size()==prior.source_sha256.size()+1 and not prior.source_sha256.has(HOLD_CONTRACT) and core.source_sha256.get(HOLD_CONTRACT)==HOLD_CONTRACT_SHA,"Exactly one new explicit WorldContract authority leaf; prior65 untouched"): return false
	for path: String in prior.source_sha256:
		if not check(core.source_sha256.get(path)==prior.source_sha256[path],"Original ordinary core value unchanged "+path): return false
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	stream_api=load(STREAM_PATH)
	diagnostic_patch_api=load(DIAGNOSTIC_PATCH)
	# No Scene/layout load or formal_version() before arm: preserve true default
	# first-request parsing boundary, unlike the old near-Gate portal lookup.
	return check(stream_api!=null and diagnostic_patch_api!=null,"Exact B01B plus unchanged LM17D/Field/Router/B468/r3 source closure")

func _world_actual(label: String) -> bool:
	if not super._world_actual(label): return false
	var world_api: Variant=load(HOLD_CONTRACT)
	var held: SceneScript=world_api._formal_scene
	if not check(not first_draw.is_empty() and held!=null and world_api.is_v15(held) and held==scene and held.map_layout==scene.map_layout and held.resource_path==HOLD_DEFINITION and held.map_layout.resource_path==HOLD_LAYOUT,"After first draw: retained formal Scene and its actual Field map are the same original native resources"): return false
	var held_id: int=held.get_instance_id()
	var held_layout_id: int=held.map_layout.get_instance_id()
	if not check(world_api.formal_version()==15 and world_api._formal_scene==held and ResourceLoader.load(HOLD_DEFINITION)==held,"Existing REUSE canonical resource and formal-version hold keep exact Scene identity, no alias"): return false
	# Source-definition SHA checks only AFTER immutable first operable DRAW.
	if not track(HOLD_DEFINITION,HOLD_DEFINITION_SHA) or not track(HOLD_LAYOUT,HOLD_LAYOUT_SHA): return false
	records.append({"kind":"WORLD_DEFAULT_FORMAL_SCENE_STRONG_HOLD","label":label,"Scene_instance_id":held_id,"layout_instance_id":held_layout_id,"same_actual_Field_Scene":held==scene,"same_actual_map_layout":held.map_layout==scene.map_layout,"source_definition_unchanged":true,"definition_sha256":HOLD_DEFINITION_SHA,"layout_sha256":HOLD_LAYOUT_SHA,"first_draw_frozen":first_draw.duplicate(true),"checks_after_first_draw":true,"no_hot_disk_reload_or_repeat_unit_speed_claim":true,"near_Gate_old_setup_preloaded_layout_not_true_default_first_request":true})
	return true
