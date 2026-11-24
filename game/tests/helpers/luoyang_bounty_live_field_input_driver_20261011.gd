extends "res://tests/helpers/v15_input_driver.gd"
## Normal input remains identical. Loss of the CURRENT Field is an interruption,
## never an independent-clear positive and never permission to erase a live FAIL.
func live_tuple(held: Variant,player: Variant) -> Dictionary:
	var field_valid: bool=is_instance_valid(held) and held is Node
	var player_valid: bool=is_instance_valid(player) and player is Node2D
	var current: Node=tree.current_scene
	var field_inside: bool=field_valid and held.is_inside_tree()
	var player_inside: bool=player_valid and player.is_inside_tree()
	var result: Dictionary={"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"field_valid":field_valid,"player_valid":player_valid,"field_instance":held.get_instance_id() if field_valid else 0,"player_instance":player.get_instance_id() if player_valid else 0,"current_instance":current.get_instance_id() if is_instance_valid(current) else 0,"field_queued":held.is_queued_for_deletion() if field_valid else true,"player_queued":player.is_queued_for_deletion() if player_valid else true,"field_inside_tree":field_inside,"player_inside_tree":player_inside,"same_field_tree":field_inside and held.get_tree()==tree,"same_player_tree":player_inside and player.get_tree()==tree,"current_is_held":field_valid and current==held,"held_player_is_captured":field_valid and player_valid and held.get("_player")==player}
	result["live"]=field_valid and player_valid and not result.field_queued and not result.player_queued and field_inside and player_inside and result.same_field_tree and result.same_player_tree and result.current_is_held and result.held_player_is_captured
	return result

func _interruption(start: Vector2,target: Vector2,last_live: Vector2,all_feet: bool,first_bad: Vector2,lifecycle: Array[Dictionary],boundary: String) -> Dictionary:
	release_movement()
	return {"ok":false,"reason":"scene_changed_during_movement","identity_loss":true,"boundary":boundary,"reached":false,"all_recorded_feet_clear":all_feet,"start":[start.x,start.y],"target":[target.x,target.y],"actual_end":[],"last_live_foot":last_live,"last_live_foot_native_bytes":var_to_bytes(last_live).hex_encode(),"physics_samples":observed_positions.size(),"first_bad":[first_bad.x,first_bad.y] if first_bad.is_finite() else [],"lifecycle":lifecycle.duplicate(true)}

func drive(field: Node, target: Vector2, independent_clear: Callable) -> Dictionary:
	observed_positions.clear()
	if not is_instance_valid(field) or not independent_clear.is_valid(): return {"ok": false, "reason": "missing_field_or_oracle"}
	var player: Node2D = field.get("_player") as Node2D
	if not is_instance_valid(player): return {"ok": false, "reason": "missing_actual_player"}
	var start: Vector2 = player.position
	var budget: int = maxi(120, ceili(start.distance_to(target) / 2.0) + 180)
	var all_feet := true
	var first_bad := Vector2(INF, INF)
	var last_live: Vector2=start
	var lifecycle: Array[Dictionary]=[]
	var entry: Dictionary=live_tuple(field,player)
	lifecycle.append({"boundary":"entry","tuple":entry})
	if entry.live!=true: return _interruption(start,target,last_live,all_feet,first_bad,lifecycle,"entry")
	for tick in budget:
		var before: Dictionary=live_tuple(field,player)
		lifecycle.append({"boundary":"before_input","tuple":before})
		if before.live!=true: return _interruption(start,target,last_live,all_feet,first_bad,lifecycle,"before_input")
		last_live=player.position
		var delta: Vector2 = target - player.position
		if delta.length() <= .15: break
		release_movement()
		var direction: Vector2 = delta.normalized()
		var deadzone := 0.0
		for action: String in ["move_right", "move_left", "move_down", "move_up"]:
			deadzone += InputMap.action_get_deadzone(action) * .25
		# Existing production controller's maximum speed is 480px/s. The actual
		# reached point and every recorded physics step, not this estimate, decide.
		var strength: float = deadzone + (1.0 - deadzone) * minf(1.0, delta.length() / (480.0 / Engine.physics_ticks_per_second))
		Input.action_press("move_right", maxf(direction.x, 0) * strength)
		Input.action_press("move_left", maxf(-direction.x, 0) * strength)
		Input.action_press("move_down", maxf(direction.y, 0) * strength)
		Input.action_press("move_up", maxf(-direction.y, 0) * strength)
		var before_await: Dictionary=live_tuple(field,player)
		lifecycle.append({"boundary":"before_physics_await","tuple":before_await})
		if before_await.live!=true: return _interruption(start,target,last_live,all_feet,first_bad,lifecycle,"before_physics_await")
		await tree.physics_frame
		var after: Dictionary=live_tuple(field,player)
		lifecycle.append({"boundary":"after_physics_await","tuple":after})
		if after.live!=true: return _interruption(start,target,last_live,all_feet,first_bad,lifecycle,"after_physics_await")
		last_live=player.position
		observed_positions.append(player.position)
		if not bool(independent_clear.call(player.position)):
			all_feet = false
			if not first_bad.is_finite(): first_bad = player.position
	release_movement()
	await completed_actor_stage()
	var completed: Dictionary=live_tuple(field,player)
	lifecycle.append({"boundary":"completed_actor_stage","tuple":completed})
	if completed.live!=true: return _interruption(start,target,last_live,all_feet,first_bad,lifecycle,"completed_actor_stage")
	var reached: bool = is_instance_valid(player) and player.position.distance_to(target) <= .3
	return {"ok": reached and all_feet, "reached": reached, "all_recorded_feet_clear": all_feet, "start": [start.x, start.y], "target": [target.x, target.y], "actual_end": [player.position.x, player.position.y] if is_instance_valid(player) else [], "physics_samples": observed_positions.size(), "first_bad": [first_bad.x, first_bad.y] if first_bad.is_finite() else [],"last_live_foot":last_live,"last_live_foot_native_bytes":var_to_bytes(last_live).hex_encode(),"lifecycle":lifecycle.duplicate(true)}
