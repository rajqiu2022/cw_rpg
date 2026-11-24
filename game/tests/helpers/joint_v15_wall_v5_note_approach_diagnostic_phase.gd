extends "res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd"
## NEW LIMITED2 evidence only. Original 542 method retained mechanically;
## only before/after read-only diagnostics and exact scope guard added.
const NOTE_PARENT_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd"
const NOTE_PARENT_SHA: String="542483133d1dfd79422ac99dff5c79ee4cd3baea6a62001439f016c6055aaf72"

func _normal_action_case(id: String,kind: String,entry: Dictionary,mode: String) -> void:
	if not _check(id=="ch4_s3_luoyang_market" and kind=="interactions" and String(entry.get("id",""))=="xuantong_note" and mode in ["space","mouse"],"LIMITED2 original note identity only; no broader action credit"): return
	if not _check(FileAccess.get_sha256(NOTE_PARENT_PATH).to_lower()==NOTE_PARENT_SHA,"exact frozen 542 action/lifecycle predicates"): return
	if not _check(FileAccess.get_sha256(SCENE_CASE_ORIGIN_PATH).to_lower()==SCENE_CASE_ORIGIN_SHA,"exact unchanged ROOT198 battle lifecycle and original 52 action predicates"): return
	if not _check(FileAccess.get_sha256(AUTHORED_PARENT_PATH).to_lower()==AUTHORED_PARENT_SHA and FileAccess.get_sha256(CASE_ORIGIN_PATH).to_lower()==CASE_ORIGIN_SHA and FileAccess.get_sha256(BATTLE_ORIGIN_PATH).to_lower()==BATTLE_ORIGIN_SHA,"unchanged authored UI, original normal action predicates and bounded battle UI sources"): return
	if not _check(not transition_case_blocked,"no prior unrecognized or failed normal transition before a new public fixture"): return
	_public_fixture(entry)
	if not await _open(id): return
	var sid: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
	var slot: Dictionary=_slot(manifest.gameplay_slots[kind],sid)
	var target: Node=_npc(sid) if kind=="npcs" else null
	_check(kind!="npcs" or target!=null,"required original gated NPC really spawned: "+id+"/"+sid)
	if kind=="npcs" and target==null: return
	# Each gated original NPC appears through its NORMAL entry fixture. Aggregate
	# all these actual source families before claiming a complete boat domain.
	if kind=="npcs":
		var water_proofs: Array=await probe.call("water_proofs")
		for proof: Dictionary in water_proofs:
			proof["normal_npc_gate_fixture"]=id+"/"+sid+"/"+mode
			records.water_domains.append(proof)
			_check(_write("water_family_"+id+"_"+sid+"_"+mode+".json",proof),"full normal source-family domain evidence checked readback before absence classification")
	var station: Vector2=_npc_stand(target) if target!=null else _point(slot.get("stand_px"))
	var diagnostic_before: Dictionary=_diag_snapshot(station,true)
	var approach: Dictionary=await probe.call("move_to",station)
	var diagnostic_after: Dictionary=_diag_snapshot(station,false)
	var diagnostic: Dictionary={"scope":"LIMITED2_XUANTONG_NOTE_APPROACH_ONLY_NOT_52_OR_FULL","source_scene_id":id,"source_id":sid,"mode":mode,"original_entry":entry.duplicate(true),"actual_manifest_slot":slot.duplicate(true),"fixture_changed":false,"station_changed":false,"timeout_changed":false,"original_move_to_result":approach.duplicate(true),"before":diagnostic_before,"after":diagnostic_after,"frozen_move_to_probe_path":"res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd","frozen_move_to_parent_path":"res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd"}
	if not records.has("note_approach_diagnostics"): records["note_approach_diagnostics"]=[]
	(records.note_approach_diagnostics as Array).append(diagnostic.duplicate(true))
	if not _check(_write("note_approach_"+sid+"_"+mode+".json",diagnostic),"actual raw/physics/path/NPC approach evidence saved even before original movement failure"): return
	if not _check(bool(approach.get("ok",false)),"real normal input reaches original action: "+id+"/"+sid+" "+mode): return
	var source_foot: Vector2=(field.get("_player") as Node2D).position
	var before: Dictionary=_state()
	var event_start: int=events.size()
	var input: Dictionary={"mode":mode}
	if mode=="space": await driver.call("key",KEY_SPACE)
	elif target!=null: input=await probe.call("click_entity",target.get("sprite"))
	else:
		var sprite: Sprite2D=probe.call("prop",String(slot.get("object_id",""))) as Sprite2D
		_check(sprite!=null,"original action's actual entity exists, no invisible ground fallback")
		if sprite==null: return
		input=await probe.call("click_entity",sprite)
	await driver.call("completed_actor_stage")
	var dialogues: Array[Dictionary]=await _finish_dialogs()
	var action: String=String(entry.get("interaction_action",entry.get("action","")))
	var dialog_id: String=String(entry.get("dialog_id",""))
	if action.begins_with("dialog:"): dialog_id=action.trim_prefix("dialog:")
	var received: Array=events.slice(event_start)
	var effects: Dictionary={}
	var battle_lifecycle: Dictionary={}
	var scene_lifecycle: Dictionary={}
	var settled_id: String=id
	if action.begins_with("spar:"):
		var modal: Control=field.get("_sparring_confirm_dialog") as Control
		_check(modal!=null and modal.is_visible_in_tree(),"ordinary sparring preface opens real confirm, not direct battle")
		if modal!=null:
			var button: Button=modal.get_node_or_null("%ConfirmAction") as Button
			_check(button!=null,"normal sparring confirmation button exists")
			if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		effects=await battle.call("victory",id,source_foot,3)
		battle.call("release")
		battle=null
		var spar_id: String=action.split(":")[1]
		_check(bool(((tree.root.get_node("GameState").get("sparring_records") as Dictionary).get(spar_id,{}) as Dictionary).get("won",false)),"normal first victory records actual sparring result/reward")
		if bool(effects.get("returned",false)) and await _wait_field(id): _bind_field(id)
	elif action.begins_with("shop:"):
		effects=await _normal_shop_buy(id,source_foot)
	elif action.begins_with("bounty_board:"):
		var page: Node=tree.current_scene
		_check(page!=null and page.get_node_or_null("BountyEntries")!=null,"actual entity opens normal bounty board")
		if page!=null and page.get_node_or_null("CloseButton")!=null:
			await driver.call("pointer",(page.get_node("CloseButton") as Control).get_global_rect().get_center())
			_check(await _wait_field(id),"normal bounty close returns original city")
			if is_instance_valid(field): _bind_field(id)
	elif action.begins_with("discover_readable:"):
		var parts: PackedStringArray=action.split(":")
		_check(parts.size()>=3 and bool((tree.root.get_node("GameState").get("flags") as Dictionary).get(parts[2],false)),"normal actual discovery executes original once flag")
	else:
		_check(not dialog_id.is_empty() and not dialogues.is_empty(),"normal original NPC/hotspot starts and completes actual dialogue, no dry log")
		battle_lifecycle=_observed_battle_lifecycle(dialogues)
		if not records.has("battle_lifecycle"): records["battle_lifecycle"]=[]
		(records.battle_lifecycle as Array).append(battle_lifecycle.duplicate(true))
		if not _check(_write("battle_entry_"+id+"_"+sid+"_"+mode+".json",battle_lifecycle),"actual dialogue/loading/battle scalar evidence persisted with exact readback"): return
		var actual_battle: bool=bool(battle_lifecycle.get("actual_battle_ui",false)) or bool(battle_lifecycle.get("actual_battle_loading",false))
		if bool(battle_lifecycle.get("authored_terminal_requires_battle",false)) and not actual_battle:
			_check(false,"actual authored terminal requires battle but no real LoadingManager battle transition or normal Battle UI exists")
			transition_case_blocked=true
			return
		if not bool(battle_lifecycle.get("terminal_source_valid",false)):
			transition_case_blocked=true
			return
		if actual_battle:
			var battle: RefCounted=BATTLE.new()
			battle.call("configure",tree,driver,_check)
			effects=await battle.call("victory",id,source_foot,3)
			battle.call("release")
			if bool(effects.get("returned",false)) and await _wait_field(id):
				var return_dialogues: Array[Dictionary]=await _finish_dialogs()
				if not return_dialogues.is_empty():
					var return_terminal: Dictionary=_observed_battle_lifecycle(return_dialogues)
					if String(return_terminal.get("terminal_on_end","")).begins_with("scene:"):
						scene_lifecycle=await _observe_authored_scene_arrival(return_terminal)
						settled_id=String(scene_lifecycle.get("target_scene_id",""))
				if settled_id==id: _bind_field(id)
		elif String(battle_lifecycle.get("terminal_on_end","")).begins_with("scene:"):
			scene_lifecycle=await _observe_authored_scene_arrival(battle_lifecycle)
			settled_id=String(scene_lifecycle.get("target_scene_id",""))
	if not scene_lifecycle.is_empty(): effects["scene_transition"]=scene_lifecycle.duplicate(true)
	var settled: Dictionary=_normal_field_receipt(settled_id)
	settled["source_scene_id"]=id
	settled["source_id"]=sid
	settled["mode"]=mode
	settled["original_action"]=action
	settled["battle_entry"]=battle_lifecycle.duplicate(true)
	settled["battle_effects"]=effects.duplicate(true)
	settled["scene_arrival"]=scene_lifecycle.duplicate(true)
	if not scene_lifecycle.is_empty(): settled["complete"]=bool(settled.complete) and bool(scene_lifecycle.get("complete",false))
	if not records.has("normal_transition_receipts"): records["normal_transition_receipts"]=[]
	(records.normal_transition_receipts as Array).append(settled.duplicate(true))
	var receipt_saved: bool=_write("normal_transition_"+id+"_"+sid+"_"+mode+".json",settled)
	if not _check(receipt_saved and bool(settled.complete),"normal action has completed actual loading/live Field Player identity; unrecognized pending transition refuses"):
		transition_case_blocked=true
		return
	received=events.slice(event_start)
	if kind=="npcs":
		var exact_npc_event: bool=false
		for event: Dictionary in received:
			if event.get("kind")=="npc_talked_to" and event.get("id")==sid: exact_npc_event=true
		_check(exact_npc_event,"normal current NPC identity actually accepted this input, not a nearer NPC")
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"action":action,"dialog_id":dialog_id,"actual_input":input,"approach":approach,"pre_action_feet_px":[source_foot.x,source_foot.y],"events":received,"dialog_nodes":dialogues,"before":before,"after":_state(),"effects":effects}
	record["battle_lifecycle"]=battle_lifecycle.duplicate(true)
	record["scene_lifecycle"]=scene_lifecycle.duplicate(true)
	record["normal_transition_receipt"]=settled.duplicate(true)
	records[kind].append(record)
	_check(_write(kind+"_"+id+"_"+sid+"_"+mode+".json",record),"actual normal action and state evidence checked readback")
	await _capture(kind+"_"+sid+"_"+mode)


func _diag_point(p: Vector2) -> Array:
	return [p.x,p.y] if p.is_finite() else []

func _diag_transform(t: Transform2D) -> Array:
	return [t.x.x,t.x.y,t.y.x,t.y.y,t.origin.x,t.origin.y]

func _diag_node(node: Node) -> Dictionary:
	if not is_instance_valid(node): return {"live":false}
	var row: Dictionary={"live":node.is_inside_tree() and not node.is_queued_for_deletion(),"name":String(node.name),"class":node.get_class(),"instance_id":node.get_instance_id(),"path":String(node.get_path()) if node.is_inside_tree() else "","script_path":node.get_script().resource_path if node.get_script()!=null else ""}
	if node is Node2D:
		row["position_px"]=_diag_point(node.position)
		row["global_transform"]=_diag_transform(node.global_transform)
		row["local_transform"]=_diag_transform(node.transform)
	if node is CollisionObject2D:
		row["rid"]=node.get_rid().get_id()
		row["collision_layer"]=node.collision_layer
		row["collision_mask"]=node.collision_mask
	if node is NPCNode:
		row["npc_id"]=String(node.npc_id)
		row["patrol_axis"]=_diag_point(node.patrol_axis)
		row["patrol_distance"]=node.patrol_distance
		row["patrol_speed"]=node.patrol_speed
		row["patrol_origin"]=_diag_point(node.get("_patrol_origin"))
		row["patrol_phase"]=node.get("_patrol_phase")
	return row

func _diag_shapes(node: Node) -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	for child: Node in node.get_children():
		if child is CollisionShape2D:
			var shape_row: Dictionary=_diag_node(child)
			shape_row["disabled"]=child.disabled
			shape_row["one_way_collision"]=child.one_way_collision
			var shape: Shape2D=child.shape
			shape_row["shape_class"]=shape.get_class() if shape!=null else ""
			if shape is RectangleShape2D: shape_row["size_px"]=_diag_point(shape.size)
			elif shape is CircleShape2D: shape_row["radius_px"]=shape.radius
			elif shape is CapsuleShape2D: shape_row["radius_px"]=shape.radius; shape_row["height_px"]=shape.height
			shape_row["parent"]=_diag_node(child.get_parent())
			rows.append(shape_row)
		elif child is CollisionPolygon2D:
			var polygon_row: Dictionary=_diag_node(child)
			polygon_row["disabled"]=child.disabled
			polygon_row["build_mode"]=child.build_mode
			polygon_row["polygon_local_px"]=[]
			for p: Vector2 in child.polygon: (polygon_row.polygon_local_px as Array).append(_diag_point(p))
			polygon_row["parent"]=_diag_node(child.get_parent())
			rows.append(polygon_row)
		rows.append_array(_diag_shapes(child))
	return rows

func _diag_physics(p: Vector2) -> Dictionary:
	var result: Dictionary={"scope":"SAME_ORDINARY_PLAYER_SHAPE_TRANSFORM_MASK_EXCLUDE_AS_FROZEN_PROBE","point_px":_diag_point(p),"valid":false,"hit_limit":128,"hits":[]}
	if not is_instance_valid(field) or tree.current_scene!=field or not field.is_inside_tree() or field.is_queued_for_deletion() or bool(field.get("_scene_rebuilding")): return result
	var player: Node2D=field.get("_player") as Node2D
	var container: Node2D=field.get("world_container") as Node2D
	if not is_instance_valid(player) or not player.is_inside_tree() or not is_instance_valid(container) or not container.is_inside_tree() or not p.is_finite(): return result
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or not shape.shape is RectangleShape2D: return result
	var query: PhysicsShapeQueryParameters2D=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape
	query.transform=shape.global_transform
	query.transform.origin+=container.to_global(p)-player.global_position
	query.collision_mask=player.collision_mask
	query.exclude=[player.get_rid()]
	query.collide_with_areas=false
	var space: World2D=player.get_world_2d()
	if space==null or space.direct_space_state==null: return result
	var hits: Array[Dictionary]=space.direct_space_state.intersect_shape(query,128)
	result["valid"]=true
	result["query_transform"]=_diag_transform(query.transform)
	result["query_shape_size_px"]=_diag_point((shape.shape as RectangleShape2D).size)
	result["collision_mask"]=query.collision_mask
	result["excluded_player_rid"]=player.get_rid().get_id()
	result["collide_with_areas"]=false
	result["hit_count"]=hits.size()
	result["truncated_possible"]=hits.size()==128
	for hit: Dictionary in hits:
		var collider: Node=hit.get("collider") as Node
		var hit_rid: RID=hit.get("rid")
		var row: Dictionary={"shape_index":hit.get("shape",-1),"rid":hit_rid.get_id(),"collider":_diag_node(collider)}
		if is_instance_valid(collider):
			row["collider_shapes"]=_diag_shapes(collider)
			var ancestor: Node=collider
			while ancestor!=null and ancestor!=field and not ancestor is NPCNode: ancestor=ancestor.get_parent()
			row["npc_ancestor"]=_diag_node(ancestor) if ancestor is NPCNode else {}
		(result.hits as Array).append(row)
	return result

func _diag_snapshot(target: Vector2,include_path: bool) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D if is_instance_valid(field) else null
	var row: Dictionary={"ticks_usec":Time.get_ticks_usec(),"process_frames":Engine.get_process_frames(),"physics_frames":Engine.get_physics_frames(),"field":_diag_node(field),"player":_diag_node(player),"target_px":_diag_point(target),"npc_nodes":[],"all_field_shapes":[]}
	if not is_instance_valid(player) or not target.is_finite() or not is_instance_valid(field) or tree.current_scene!=field:
		row["valid"]=false
		return row
	var start: Vector2=player.position
	row["valid"]=true
	row["start_px"]=_diag_point(start)
	row["start_raw"]=probe.call("raw_evidence",start)
	row["target_raw"]=probe.call("raw_evidence",target)
	row["start_physics"]=_diag_physics(start)
	row["target_physics"]=_diag_physics(target)
	for npc: Node in field.get("_npc_nodes"):
		if is_instance_valid(npc):
			var npc_row: Dictionary=_diag_node(npc)
			npc_row["shapes"]=_diag_shapes(npc)
			(row.npc_nodes as Array).append(npc_row)
	row["all_field_shapes"]=_diag_shapes(field)
	if include_path:
		row["direct_segment"]=probe.call("segment",start,target)
		var direct: Dictionary=row.direct_segment
		if direct.has("point"):
			var denied_point: Vector2=_point(direct.point)
			row["direct_first_denial_physics"]=_diag_physics(denied_point)
		var path: PackedVector2Array=probe.get("driver").call("plan",start,target,Vector2(3072,2048),Callable(probe,"clear"),Callable(probe,"segment"))
		row["planner_scope"]="READ_ONLY_ORIGINAL_32PX_MAX20000_FULL17_4PX_PLANNER; NOT A DRIVEN PATH OR NEW ROUTE"
		row["planned_points_px"]=[]
		row["planned_edges"]=[]
		for p: Vector2 in path: (row.planned_points_px as Array).append(_diag_point(p))
		for i in range(1,path.size()):
			(row.planned_edges as Array).append({"from":_diag_point(path[i-1]),"to":_diag_point(path[i]),"evidence":probe.call("segment",path[i-1],path[i])})
	return row

