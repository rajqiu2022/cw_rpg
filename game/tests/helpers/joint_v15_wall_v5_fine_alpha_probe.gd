extends "res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd"
## NEW ROOT168 coarse-miss refinement. No old execution source is changed.
## Actual current-frame-only witnesses; no all-frame or absence-proof credit.
const FINE_ALPHA_ORIGIN_PATH: String="res://tests/helpers/joint_v15_wall_street_city_physical_alpha_probe.gd"
const FINE_ALPHA_ORIGIN_SHA: String="ca5f919320364b2e8346f057044a62a0dd0bfe99b49f2d029b7362d129bbd5f2"

func _alpha_trial(object: Dictionary) -> Dictionary:
	var origin_exact: bool=FileAccess.get_sha256(FINE_ALPHA_ORIGIN_PATH).to_lower()==FINE_ALPHA_ORIGIN_SHA
	_check(origin_exact,"fine-alpha sibling preserves exact frozen original physical probe")
	if not origin_exact: return {"records":[],"missing_relation_is_fail":true,"origin_exact":false,"discovery_is_not_absence_proof":true}
	var player: Node2D = field.get("_player") as Node2D
	var sprite: Sprite2D = player.get("sprite") as Sprite2D
	var container: Node2D = field.get("world_container") as Node2D
	var target_prop: Sprite2D = prop(String(object.id))
	var bounds: Rect2 = alpha.bounds_in(target_prop, container)
	var stations: Dictionary = {}
	var trials: Array = []
	var considered := 0
	# Bounded station discovery only. Failure does NOT prove alpha absence.
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var orientation: Dictionary = await move_to(player.position + direction * 2)
		await driver.completed_actor_stage()
		if not bool(orientation.get("ok", false)): continue
		var xs: Array[float] = [bounds.position.x - 20, bounds.position.x + 20, bounds.get_center().x, bounds.end.x - 20, bounds.end.x + 20]
		var ys: Array[float] = []
		for d: float in [-256.0, -128.0, -64.0, -32.0, -16.0, -8.0, -2.0, 2.0, 8.0, 16.0, 32.0, 64.0]: ys.append(float(object.depth_foot_y) + d)
		for y in range(maxi(16, floori(bounds.position.y)), mini(2032, ceili(bounds.end.y) + 116), 16): ys.append(float(y))
		for y: float in ys:
			for x: float in xs:
				considered += 1
				var p := Vector2(x, y)
				if not clear(p) or not bool(segment(p - direction * 2, p).get("clear", false)): continue
				var actor_foot: float = float(player.call("get_depth_sort_y")) + container.to_global(p).y - player.global_position.y
				var prop_foot: float = container.to_global(point(object.world_foot_px)).y
				if absf(actor_foot - prop_foot) <= .01: continue
				var relation: String = "front" if actor_foot > prop_foot else "behind"
				if stations.has(relation): continue
				var hits: Dictionary = alpha.strong_intersection(sprite, target_prop, container.to_global(p) - player.global_position)
				if int(hits.get("hits", 0)) > 0: stations[relation] = {"point": p, "direction": direction, "current_search_frame": hits}
			if stations.size() == 2: break
		if stations.size() == 2: break
	var coarse_evidence: Dictionary={"considered":considered,"stations":_scalar_evidence(stations),"xs":_scalar_evidence([bounds.position.x-20,bounds.position.x+20,bounds.get_center().x,bounds.end.x-20,bounds.end.x+20]),"method":"ORIGINAL_FIVE_X_SAME_Y_RULE_AND_ACTUAL_FACING"}
	var fine_evidence: Array[Dictionary]=[]
	var fine_considered: int=0
	# A coarse miss is NOT an absence proof. Only add finite 1px logical-world
	# X candidates, with the very same Y rule and naturally obtained facings.
	# No legal predicate, live Physics query, alpha threshold, or final assertion
	# is replaced by the offline ROOT168 candidate calculations.
	if stations.size()<2:
		for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			var orientation: Dictionary=await move_to(player.position+direction*2)
			await driver.completed_actor_stage()
			var stage: Dictionary={"direction":[direction.x,direction.y],"orientation":_scalar_evidence(orientation),"considered":0,"accepted":[],"current_frame":sprite.frame,"texture_path":sprite.texture.resource_path,"texture_sha256":FileAccess.get_sha256(sprite.texture.resource_path),"method":"FINITE_ONE_LOGICAL_PX_X_SAME_ORIGINAL_YS","absence_proven":false}
			fine_evidence.append(stage)
			if not bool(orientation.get("ok",false)): continue
			var minimum_x: int=floori(bounds.position.x)-20
			var maximum_x: int=ceili(bounds.end.x)+20
			stage["x_min_inclusive"]=minimum_x
			stage["x_max_inclusive"]=maximum_x
			stage["x_step_px"]=1
			var ys: Array[float]=[]
			for d: float in [-256.0,-128.0,-64.0,-32.0,-16.0,-8.0,-2.0,2.0,8.0,16.0,32.0,64.0]: ys.append(float(object.depth_foot_y)+d)
			for y in range(maxi(16,floori(bounds.position.y)),mini(2032,ceili(bounds.end.y)+116),16): ys.append(float(y))
			stage["same_original_ys"]=ys.duplicate()
			for y: float in ys:
				for x in range(minimum_x,maximum_x+1):
					considered+=1
					fine_considered+=1
					stage["considered"]=int(stage["considered"])+1
					var p:=Vector2(float(x),y)
					if not clear(p) or not bool(segment(p-direction*2,p).get("clear",false)): continue
					var actor_foot: float=float(player.call("get_depth_sort_y"))+container.to_global(p).y-player.global_position.y
					var prop_foot: float=container.to_global(point(object.world_foot_px)).y
					if absf(actor_foot-prop_foot)<=.01: continue
					var relation: String="front" if actor_foot>prop_foot else "behind"
					if stations.has(relation): continue
					var hits: Dictionary=alpha.strong_intersection(sprite,target_prop,container.to_global(p)-player.global_position)
					if int(hits.get("hits",0))>0:
						stations[relation]={"point":p,"direction":direction,"current_search_frame":hits}
						(stage["accepted"] as Array).append({"relation":relation,"point":[p.x,p.y],"current_search_frame":hits})
					if stations.size()==2: break
				if stations.size()==2: break
			if stations.size()==2: break
	for relation: String in ["behind", "front"]:
		_check(stations.has(relation), "finite actual-facing legal strong-alpha station discovered (empty = NOT_PROVEN, never waived): " + String(object.id) + " " + relation)
		if not stations.has(relation): continue
		var station: Dictionary = stations[relation]
		var target: Vector2 = station.point
		var direction: Vector2 = station.direction
		var approach: Dictionary = await move_to(target - direction * 2)
		var leg: Dictionary = await driver.drive(field, target, clear) if bool(approach.get("ok", false)) else {"ok": false}
		await driver.completed_actor_stage()
		var hits: Dictionary = alpha.strong_intersection(sprite, target_prop)
		var actor_front: bool = alpha.actual_in_front(player, target_prop)
		var feet_relation: bool = float(player.call("get_depth_sort_y")) > container.to_global(point(object.world_foot_px)).y
		var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
		# Preserve the exact first-assertion cache/actor observation. Later natural
		# stages may diagnose timing but MUST NOT replace or green this assertion.
		var assertion_snapshot: Dictionary=_alpha_observation(target_prop)
		_check(bool(approach.get("ok", false)) and bool(leg.get("ok", false)), "normal input and actual-facing final leg reach alpha witness: " + String(object.id) + " " + relation)
		_check(raw_clear(player.position) and physical_clear(player.position) and int(hits.get("hits", 0)) > 0, "real current-frame strong alpha with full17/34x24 and Physics2D clearance: " + String(object.id) + " " + relation)
		_check(feet_relation == (relation == "front") and actor_front == feet_relation, "completed normal node stage actual feet/order incl same-band siblings: " + String(object.id) + " " + relation)
		var hit_count: int = int((debug.get("prop_hits", {}) as Dictionary).get(String(object.id), 0))
		_check(hit_count > 0 if relation == "behind" else hit_count == 0, "only genuinely covered pixels ghost; player in front is not faded: " + String(object.id) + " " + relation)
		_check(exact_union(debug), "independent current-frame LINEAR union byteexact, not rectangular whole-person fade: " + String(object.id) + " " + relation)
		var trial: Dictionary={"relation": relation, "actual_point": [player.position.x, player.position.y], "actual_alpha": hits, "raw": raw_evidence(player.position), "physical_clear": physical_clear(player.position), "actor_front": actor_front, "actor_band": player.z_index, "prop_band": target_prop.z_index, "actor_index": player.get_index(), "prop_index": target_prop.get_index(), "approach": approach, "final_leg": leg, "ghost_target_pixels": hit_count, "union_pixels": debug.get("pixels", 0),"first_assertion_snapshot":assertion_snapshot}
		await driver.completed_actor_stage()
		trial["second_natural_stage_snapshot"]=_alpha_observation(target_prop)
		trial["second_natural_stage_alpha"]=alpha.strong_intersection(sprite,target_prop)
		trial["second_natural_stage_raw"]=raw_evidence(player.position)
		trial["second_natural_stage_physical_clear"]=physical_clear(player.position)
		trial["second_stage_is_diagnostic_not_assertion_replacement"]=true
		trials.append(trial)
		await capture.call(String(object.id) + "_" + relation)
	return {"discovery_is_not_absence_proof": true, "considered": considered, "records": trials, "scope": "actual_current_idle_frame_only", "missing_relation_is_fail": trials.size() != 2, "coarse_discovery": coarse_evidence, "fine_discovery": fine_evidence, "fine_considered": fine_considered, "discovered_stations": _scalar_evidence(stations), "fine_search_is_not_absence_proof": true}
