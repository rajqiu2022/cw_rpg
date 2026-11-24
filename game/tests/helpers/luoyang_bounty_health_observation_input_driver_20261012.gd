extends "res://tests/helpers/luoyang_bounty_live_field_input_driver_20261011.gd"
## Passive frame/event health observations ONLY. No Stats, strategy or input edits.
## Original pointer return is returned unchanged; original drive is inherited.
const HEALTH_ROW_LIMIT: int=8192
const HEALTH_BATTLE_PATH := "res://scenes/battle.tscn"
const HEALTH_BATTLE_SCRIPT := "res://scripts/battle/battle_controller.gd"
var _health_rows: Array[Dictionary]=[]
var _health_comparison: PackedByteArray=PackedByteArray()
var _health_overflow: bool=false
var _health_connected: bool=false
var _health_released: bool=false

func configure(owner_tree: SceneTree) -> void:
	if _health_connected: release()
	super.configure(owner_tree)
	_health_rows.clear(); _health_comparison.clear()
	_health_overflow=false; _health_released=false
	var bus: Node=tree.root.get_node("EventBus")
	tree.process_frame.connect(_on_natural_frame)
	bus.connect("battle_started",_on_battle_started)
	bus.connect("battle_ended",_on_battle_ended)
	_health_connected=true
	_record_health("configured",{},true)

func _stats_values(value: Variant) -> Dictionary:
	if not value is CharacterStats or not is_instance_valid(value): return {"valid":false}
	var stats: CharacterStats=value
	var script: Script=stats.get_script() as Script
	return {"valid":true,"instance_id":stats.get_instance_id(),"resource_path":stats.resource_path,"script_path":script.resource_path if script!=null else "","character_id":stats.character_id,"display_name":stats.display_name,"level":stats.level,"exp":stats.exp,"hp":stats.hp,"max_hp":stats.max_hp,"mp":stats.mp,"max_mp":stats.max_mp,"dead":stats.is_dead()}

func _combatant_values(value: Variant) -> Dictionary:
	if not value is BattleCombatant or not is_instance_valid(value): return {"valid":false}
	var unit: BattleCombatant=value
	# Deliberately explicit scalar fields. No Resource, status Dictionary or node
	# from the production combatant is retained by an observation.
	return {"valid":true,"instance_id":unit.get_instance_id(),"unit_id":String(unit.unit_id),"definition_id":String(unit.definition_id),"team":unit.team,"stance":unit.stance,"alive":unit.alive,"action_points":unit.action_points,"stats":_stats_values(unit.stats)}

func _health_snapshot() -> Dictionary:
	var current: Node=tree.current_scene
	var live: bool=is_instance_valid(current)
	var script: Script=current.get_script() as Script if live else null
	var loading: Node=tree.root.get_node_or_null("LoadingManager")
	var game_state: Node=tree.root.get_node("GameState")
	var party_rows: Array[Dictionary]=[]
	for member: Variant in game_state.get("party"): party_rows.append(_stats_values(member))
	var result: Dictionary={"ticks_usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"current_valid":live,"current_instance":current.get_instance_id() if live else 0,"current_scene_path":current.scene_file_path if live else "","current_script_path":script.resource_path if script!=null else "","current_inside_tree":current.is_inside_tree() if live else false,"current_queued":current.is_queued_for_deletion() if live else false,"Loading_transition_active_readonly":loading.get("_transition_active") if loading!=null else null,"game_player":_stats_values(game_state.get("player")),"party":party_rows,"actual_Battle":false}
	if live and current.scene_file_path==HEALTH_BATTLE_PATH and script!=null and script.resource_path==HEALTH_BATTLE_SCRIPT:
		result.actual_Battle=true
		result["battle_state"]=current.get("_state")
		result["team_mode"]=current.get("_team_mode")
		result["pending_skill_index"]=current.get("_team_pending_skill_index")
		result["legacy_player"]=_stats_values(current.get("_player"))
		result["legacy_enemy"]=_stats_values(current.get("_enemy"))
		var allies: Array[Dictionary]=[]
		var enemies: Array[Dictionary]=[]
		for unit: Variant in current.get("_team_allies"): allies.append(_combatant_values(unit))
		for unit: Variant in current.get("_team_enemies"): enemies.append(_combatant_values(unit))
		result["team_allies"]=allies; result["team_enemies"]=enemies
		result["active_unit"]=_combatant_values(current.get("_team_active_unit"))
	elif live and current.scene_file_path in ["res://scenes/field_walkable.tscn","res://scenes/field.tscn"] and current.get("_current_scene") is SceneScript:
		var definition: SceneScript=current.get("_current_scene") as SceneScript
		result["field_scene_id"]=String(definition.scene_id)
		var player: Node2D=current.get("_player") as Node2D
		if is_instance_valid(player): result["field_root_native_bytes"]=var_to_bytes(player.position).hex_encode()
	return result

func _record_health(kind: String,event_values: Dictionary,force: bool=false) -> void:
	if tree==null or not _health_connected: return
	var snapshot: Dictionary=_health_snapshot()
	var comparison: Dictionary=snapshot.duplicate(true)
	for key: String in ["ticks_usec","process_frame","physics_frame","field_root_native_bytes"]: comparison.erase(key)
	var encoded: PackedByteArray=var_to_bytes(comparison)
	if not force and encoded==_health_comparison: return
	_health_comparison=encoded
	if _health_rows.size()>=HEALTH_ROW_LIMIT:
		_health_overflow=true
		return
	_health_rows.append({"kind":kind,"event":event_values.duplicate(true),"snapshot":snapshot})

func _on_natural_frame() -> void:
	_record_health("natural_process_frame",{})

func _on_battle_started(enemy_id: StringName) -> void:
	_record_health("battle_started_immediate",{"enemy_id":String(enemy_id),"argument_native_type":typeof(enemy_id)},true)

func _on_battle_ended(victory: bool,fled: bool) -> void:
	_record_health("battle_ended_immediate",{"victory":victory,"fled":fled},true)

func pointer(logical_viewport_point: Vector2) -> Dictionary:
	_record_health("before_original_pointer",{"logical":[logical_viewport_point.x,logical_viewport_point.y]},true)
	var original: Dictionary=await super.pointer(logical_viewport_point)
	_record_health("after_original_pointer",{"original_pointer":original.duplicate(true)},true)
	return original

func get_health_observation() -> Dictionary:
	return {"scope":"PASSIVE_FRAME_AND_IMMEDIATE_EVENT_HEALTH_NOT_PER_DAMAGE","row_limit":HEALTH_ROW_LIMIT,"overflow":_health_overflow,"connected":_health_connected,"released":_health_released,"rows":_health_rows.duplicate(true),"comparison_excludes":["ticks_usec","process_frame","physics_frame","field_root_native_bytes"],"Stats_modified":false,"strategy_modified":false,"pointer_return_modified":false,"per_damage_tested":false,"Battle_returned_Loading_semantics_fixed":false}

func release() -> void:
	_record_health("release_before_disconnect",{},true)
	if tree!=null and _health_connected:
		if tree.process_frame.is_connected(_on_natural_frame): tree.process_frame.disconnect(_on_natural_frame)
		var bus: Node=tree.root.get_node_or_null("EventBus")
		if bus!=null:
			if bus.is_connected("battle_started",_on_battle_started): bus.disconnect("battle_started",_on_battle_started)
			if bus.is_connected("battle_ended",_on_battle_ended): bus.disconnect("battle_ended",_on_battle_ended)
	_health_connected=false; _health_released=true
	super.release()

