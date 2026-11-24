extends SceneTree
## Root-only actual candidate. No reset/new-game/save/collector or test pose writes.
## Explicit public entry is setup, not default cold-load or continuous world travel.
const INPUT := "res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_READY.json"
const INPUT_SHA := "524e3c0dff93d54423154289f847dcb8299f4fb2da6f75c7f0709c9561363c7f"
const OUTPUT_ROOT := "res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_READY_output/"
const AUTOLOADS := ["EventBus","GameState","WeatherManager","InvestigationState","Inventory","LoadingManager","SceneRouter","QuestManager","BountyManager","DialogPlayer","SaveManager","CursorManager","PlatformBridge","ContentPackManager","AudioManager","GMConsole"]
const FOOT_TOLERANCE := 10.0 # One 480px/s @60Hz tick +2px; no snapping.
var spec: Dictionary = {}
var began: int = 0
var errors: Array[String] = []
var checks: int = 0
var records: Array = []
var texts: Array = []
var displayed_choices: Array = []
var source_first: Dictionary = {}
var save_first: Dictionary = {}
var png_count: int = 0
var input_ticks: int = 0
var sr: Node
var lm: Node
var dp: Node

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> bool:
	checks += 1
	if not value: errors.append(label)
	return value

func in_budget() -> bool:
	return Time.get_ticks_msec()-began < int(spec.get("budgets",{}).get("whole_seconds",60))*1000

func v(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)

func facts(paths: Array) -> Dictionary:
	var result: Dictionary = {}
	for path: String in paths:
		if not FileAccess.file_exists(path): result[path]={"exists":false}; continue
		var f := FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":f.get_length() if f!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result

func release_input() -> void:
	for action: String in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)

func _run() -> void:
	began = Time.get_ticks_msec()
	if not check(FileAccess.get_sha256(INPUT)==INPUT_SHA,"ROOT_FIXED_FIXTURE_SHA"): finish(); return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if not check(raw is Dictionary and raw.get("ready")==true,"FINAL_READY_ONLY"): finish(); return
	spec = raw
	if not check(spec.fixed_sources.size()>0 and spec.fixed_documents.size()==3 and spec.save_paths.size()==15,"FIXED_SOURCES_THREE_ROOT_DOCS_FIFTEEN_SAVES"): finish(); return
	if not check(spec.budgets.whole_seconds==75 and spec.budgets.entry_seconds==20 and spec.budgets.max_png==2,"ROOT_APPROVED_GATE_PLUS_TWO_CORE_75S_BOUND"): finish(); return
	for id: String in AUTOLOADS: check(root.get_node_or_null(id)!=null,"NORMAL_AUTOLOAD:"+id)
	sr=root.get_node_or_null("SceneRouter"); lm=root.get_node_or_null("LoadingManager"); dp=root.get_node_or_null("DialogPlayer")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(platform!=null and platform.has_method("set_checkpoint_saves_suspended"),"CHECKPOINT_API"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"SUSPENDED_TO_QUIT")
	var gs: Node=root.get_node("GameState")
	var hero: Resource=gs.get("player") as Resource
	check(hero!=null and String(hero.get("character_id"))==spec.initialization.player_id and (gs.get("party") as Array).has(hero),"NORMAL_AUTOLOAD_DEFAULT_PLAYER_AND_PARTY_NO_QA_INITIALIZATION")
	var fixed: Dictionary=spec.fixed_sources.duplicate(true)
	fixed.merge(spec.fixed_documents,true)
	source_first=facts(fixed.keys()); save_first=facts(spec.save_paths)
	for path: String in fixed: check(source_first[path].get("sha256")==fixed[path],"PIN:"+path)
	if not errors.is_empty(): finish(); return
	if not load_declared_expectations(): finish(); return
	if not check(v(spec.civic.old_uv).is_finite() and v(spec.temple.old_uv).is_finite() and v(spec.temple.stand_px).is_finite() and v(spec.temple.unlock_end_px).is_finite(),"FINAL_SOURCE_ENTRY_AND_SHORT_LEG_DECLARATIONS"): finish(); return
	if not check(not spec.civic.expected_sources.is_empty() and not spec.temple.expected_sources.is_empty() and (not spec.temple.allowed_dialog_ids.is_empty() or not spec.temple.allowed_dialog_prefixes.is_empty()) and spec.temple.npc_name is String and v(spec.temple.npc_node_position_px).is_finite(),"FINAL_INDEPENDENT_OWNER_AND_MONK_DECLARATIONS"): finish(); return
	if not check(not spec.gate.expected_sources.is_empty() and spec.temple.task_acceptance==false,"FIXED_GATE_SOURCE_SET_AND_NO_TASK_ACCEPTANCE"): finish(); return
	dp.connect("text_displayed",_on_text)
	dp.connect("choices_displayed",_on_choices)
	if not await gate_admission(): finish(); return
	var civic: Node=await enter_region(spec.civic)
	if civic==null: finish(); return
	var civic_id: Dictionary=identity(civic)
	if not check((civic.get("_player") as Node2D).position.distance_to(v(spec.civic.public_anchor_px))<=1.0,"SOURCE_PUBLIC_CIVIC_ANCHOR_NOT_DEFAULT"): finish(); return
	if not await walk(civic,v(spec.civic.approach_px),"SOURCE_APPROACH_TO_SEAM"): finish(); return
	var loading_before: Dictionary=loading_identity()
	if not await walk(civic,v(spec.civic.cross_end_px),"SINGLE_TRUE_INPUT_LOGICAL_SEAM"): finish(); return
	check(identity(civic)==civic_id,"SEAM_SAME_FIELD_PLAYER_CAMERA_SCENE_LAYOUT")
	check(loading_identity()==loading_before,"SEAM_NO_LOADING_OR_TRANSITION_GENERATION")
	check(String(sr.call("get_current_field_id"))==spec.civic.logical_after,"SEAM_NEW_LOGICAL_NAVIGATION_ID")
	check(await capture("civic_after_seam"),"CIVIC_ONE_NORMAL_CAMERA_PNG")
	if not errors.is_empty(): finish(); return
	var temple: Node=await enter_region(spec.temple)
	if temple==null: finish(); return
	if not check((temple.get("_player") as Node2D).position.distance_to(v(spec.temple.public_anchor_px))<=1.0,"SOURCE_TEMPLE_PUBLIC_ALIAS_ANCHOR"): finish(); return
	for point: Array in spec.temple.approach_points_px:
		if not await walk(temple,v(point),"SOURCE_TEMPLE_APPROACH_NO_POSE_WRITE"): finish(); return
	if not check((temple.get("_player") as Node2D).position.distance_to(v(spec.temple.stand_px))<=10.0,"SOURCE_TEMPLE_FIXED_INTERACTION_STAND"): finish(); return
	var monks: Array=[]
	for npc: Node in temple.get("_npc_nodes"):
		if is_instance_valid(npc) and String(npc.get("npc_id"))==spec.temple.npc_id: monks.append(npc)
	if not check(monks.size()==1,"EXACT_SOURCE_MONK_ID"): finish(); return
	var monk: Node2D=monks[0]
	check(monk.position.distance_to(v(spec.temple.npc_node_position_px))<=1.0 and monk.get("npc_name")==spec.temple.npc_name,"SOURCE_MONK_NODE_ORIGIN_AND_NAME_DISTINCT_FROM_FOOT")
	check((temple.get("_player") as Node2D).global_position.distance_to(monk.global_position)<=118.0,"SOURCE_APPROACH_IN_INTERACTION_RANGE")
	if not errors.is_empty(): finish(); return
	var static_before: Dictionary=static_snapshot(temple)
	if not check(static_before.floor_count>0 and static_before.body_count>0,"REAL_TEMPLE_FLOOR_AND_STATIC_BODY_SET_NONEMPTY"): finish(); return
	var temple_id: Dictionary=identity(temple)
	var quests_before: Variant=root.get_node("QuestManager").call("to_dict")
	var flags_before: Dictionary=(root.get_node("GameState").get("flags") as Dictionary).duplicate(true)
	if not check(int(root.get_node("QuestManager").call("get_status",StringName(spec.temple.offer_quest_id)))==0,"SOURCE_NORMAL_NOT_STARTED_SIDE_OFFER_PRECONDITION_NO_QA_STATE_WRITE"): finish(); return
	var economy_before: Array=[root.get_node("GameState").get("gold"),root.get_node("Inventory").call("to_dict")]
	texts.clear(); displayed_choices.clear()
	await key(KEY_SPACE)
	if not await finish_monologue(): finish(); return
	for index: int in range(2): await process_frame
	check(static_snapshot(temple)==static_before,"DIALOG_SAME_FLOORS_AND_STATIC_BODY_INSTANCES_AND_CONTENT")
	check(identity(temple)==temple_id,"DIALOG_SAME_FIELD_PLAYER_CAMERA_SCENE_LAYOUT")
	check(is_instance_valid(monk) and (temple.get("_npc_nodes") as Array).has(monk),"ORIGINAL_MONK_INSTANCE_RETAINED")
	check(root.get_node("QuestManager").call("to_dict")==quests_before and [root.get_node("GameState").get("gold"),root.get_node("Inventory").call("to_dict")]==economy_before,"NO_TASK_ACCEPTANCE_REWARD_OR_INVENTORY_CHANGE")
	check(root.get_node("GameState").get("flags")==flags_before,"SAFE_DECLINE_NO_STORY_OR_TASK_FLAG_CHANGE")
	check((temple.get("_player") as Node).get("can_move")==true,"DIALOG_INPUT_UNLOCKED")
	if not errors.is_empty(): finish(); return
	if not await walk(temple,v(spec.temple.unlock_end_px),"ONE_SOURCE_SHORT_INPUT_AFTER_DIALOG"): finish(); return
	check(await capture("temple_after_monologue"),"TEMPLE_ONE_NORMAL_CAMERA_PNG")
	check(in_budget(),"WHOLE_75S")
	finish()

func load_declared_expectations() -> bool:
	var row: Dictionary=spec.declared_expected_sources
	if not check(spec.fixed_sources.get(row.path)==row.sha256,"FIXED_SOURCE_DECLARATION_NOT_CURRENT_FILL"): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(row.path))
	if not check(raw is Dictionary and raw.get("status")=="FIXED_SOURCE_EXPRESSION_DECLARATIONS_NOT_OBSERVED_RECEIPTS" and raw.get("expected_sources") is Dictionary,"SOURCE_DECLARATION_SCHEMA"): return false
	for id: String in ["gate","civic","temple"]:
		var expected: Variant=raw.expected_sources.get(id)
		if not check(expected is Dictionary and expected.size()==int(row.counts[id]),"DECLARED_FULL_SOURCE_SET:"+id): return false
		spec[id]["expected_sources"]=expected.duplicate(true)
	if not check(v(raw.civic.old_uv)==v(spec.civic.old_uv) and v(raw.civic.public_anchor)==v(spec.civic.public_anchor_px) and int(raw.civic.seam_y)==int(spec.civic.source_domain_boundary_y),"FIXTURE_CIVIC_MATCHES_INDEPENDENT_SOURCE_CONTRACT"): return false
	if not check(v(raw.temple.old_uv)==v(spec.temple.old_uv) and v(raw.temple.public_anchor)==v(spec.temple.public_anchor_px) and v(raw.temple.stand)==v(spec.temple.stand_px) and v(raw.temple.unlock_end)==v(spec.temple.unlock_end_px) and raw.temple.npc_id==spec.temple.npc_id and raw.temple.npc_name==spec.temple.npc_name and v(raw.temple.npc_node_position)==v(spec.temple.npc_node_position_px) and raw.temple.source_primary.dialog_id==spec.temple.allowed_dialog_ids[0],"FIXTURE_TEMPLE_MATCHES_INDEPENDENT_SOURCE_CONTRACT"): return false
	records.append({"fixed_declaration":row.path,"source_counts":row.counts,"runtime_collector_calls":0,"expected_from_observation":false})
	return true

func gate_admission() -> bool:
	var row: Dictionary=spec.gate
	var started: int=Time.get_ticks_msec()
	var previous: Node=current_scene
	var accepted: Variant=sr.call("go_field_smart",StringName(row.logical_entry))
	records.append({"public_request":row.logical_entry,"accepted":accepted,"state":sr.call("get_public_city_preparation_state")})
	if not check(accepted==true,"ONE_PUBLIC_DEFAULT_GATE_NEW_HOOK_REQUEST"): return false
	while in_budget() and Time.get_ticks_msec()-started<int(spec.budgets.entry_seconds)*1000:
		await process_frame
		var field: Node=current_scene
		if not is_instance_valid(field) or field==previous or not field.has_method("get_field_loading_state"): continue
		var state: Dictionary=field.call("get_field_loading_state")
		if state.get("failed")==true:
			records.append({"gate_failure_state":state}); return check(false,"GATE_FIELD_FAILED")
		if state.get("complete")!=true or lm.get("_transition_active")==true or lm.get("_external_active")==true: continue
		var player: Node=field.get("_player")
		if not is_instance_valid(player) or player.get("can_move")!=true or dp.call("is_playing"): continue
		await RenderingServer.frame_post_draw
		if not check(field.get_script().resource_path==row.field_script and state.get("scene_id")==row.logical_entry,"CANONICAL_GATE_NOT_REGION_SUBSTITUTE"): return false
		var c: Variant=load(row.complete_source)
		var natural: Dictionary=c._resident_ready
		var scene: Resource=field.get("_current_scene")
		if not check(natural.get("sources_finalized")==true and natural.get("scene")==scene and String(natural.get("id",""))==row.logical_entry and natural.get("sources")==row.expected_sources,"GATE_NATURAL_FINAL_FIXED_SOURCE_MAP_NO_COLLECTOR"): return false
		var layer: Node=field.get("_actor_layer")
		var parent: Sprite2D=layer.get_node_or_null(NodePath(row.parent_name)) as Sprite2D if is_instance_valid(layer) else null
		var child: Sprite2D=parent.get_node_or_null(NodePath(row.child_name)) as Sprite2D if is_instance_valid(parent) else null
		if not check(is_instance_valid(child) and child.is_visible_in_tree() and child.get_parent()==parent and child.position==v(row.child_position_px) and child.scale==Vector2.ONE and child.z_index==int(row.child_z_index) and child.z_as_relative and child.texture!=null and child.texture.resource_path==row.child_texture and child.get_meta("source_bound_parent_row_id","")==row.parent_row_id,"EXACT_NEW_GATE_SUPPLY_CHILD_SOURCE_CONTRACT"): return false
		var metadata: Dictionary=child.get_meta("source_bound_door_depth",{})
		if not check(metadata.get("scene_instance")==str(scene.get_instance_id()) and metadata.get("parent_instance")==str(parent.get_instance_id()) and metadata.get("new_body_or_portal")==false,"GATE_CHILD_SAME_LIVE_OWNER_IDENTITY"): return false
		records.append({"gate_new_hook_only":true,"setup_elapsed_ms":Time.get_ticks_msec()-started,"field":str(field.get_instance_id()),"scene":str(scene.get_instance_id()),"child":str(child.get_instance_id()),"source_count":natural.sources.size(),"Space_INPUT_PNG":0,"performance_credit":false})
		return true
	return check(false,"GATE_ENTRY_20S_NO_EXTENSION")

func enter_region(row: Dictionary) -> Node:
	var start: int=Time.get_ticks_msec()
	var previous: Node=current_scene
	var accepted: Variant=sr.call("go_field_smart",StringName(row.logical_entry),v(row.old_uv),"",-1,int(row.local_version))
	records.append({"public_request":row.logical_entry,"accepted":accepted,"state":sr.call("get_public_city_preparation_state")})
	if not check(accepted==true,"PUBLIC_REGION_REQUEST:"+row.logical_entry): return null
	while in_budget() and Time.get_ticks_msec()-start<int(spec.budgets.entry_seconds)*1000:
		await process_frame
		var field: Node=current_scene
		if not is_instance_valid(field) or field==previous or not field.has_method("get_field_loading_state"): continue
		var state: Dictionary=field.call("get_field_loading_state")
		if state.get("failed")==true:
			records.append({"entry":row.logical_entry,"failure_state":state}); check(false,"FIELD_FAILED"); return null
		if state.get("complete")!=true or lm.get("_transition_active")==true or lm.get("_external_active")==true: continue
		var player: Node=field.get("_player")
		if not is_instance_valid(player) or player.get("can_move")!=true or dp.call("is_playing"): continue
		await RenderingServer.frame_post_draw
		records.append({"explicit_public_entry":row.logical_entry,"setup_elapsed_ms":Time.get_ticks_msec()-start,"performance_credit":false})
		if not check(field.get_script().resource_path==spec.field_script and state.get("scene_id")==row.physical_id,"TRUE_NEW_PHYSICAL_REGION"): return null
		var region_state: Dictionary=field.call("get_region27d_state")
		var receipt: Dictionary=region_state.get("owner",{})
		if not check(receipt.get("owner_kind")=="REGION_27D" and receipt.get("phase")=="LIVE" and receipt.get("finalized")==true and typeof(receipt.get("token"))==TYPE_INT and receipt.token!=0 and receipt.get("field_instance")==field.get_instance_id() and receipt.get("source_first")==row.expected_sources and receipt.get("source_final")==row.expected_sources,"NATURAL_OWNER_FIXED_FULL_SOURCE_FIRST_FINAL"): return null
		records.append({"region_owner":row.physical_id,"token":str(receipt.token),"field":str(receipt.field_instance),"scene":str(receipt.scene_instance),"layout":str(receipt.layout_instance),"source_count":row.expected_sources.size()})
		var camera: Camera2D=field.get("_world_camera") as Camera2D
		if not check(is_instance_valid(camera) and field.get_viewport().get_camera_2d()==camera,"ORIGINAL_ACTIVE_REGION_CAMERA"): return null
		return field
	check(false,"ENTRY_20S_NO_EXTENSION:"+row.logical_entry); return null

func identity(field: Node) -> Dictionary:
	var player: Node=field.get("_player"); var scene: Resource=field.get("_current_scene"); var camera: Node=field.get("_world_camera")
	return {"field":str(field.get_instance_id()),"player":str(player.get_instance_id()),"scene":str(scene.get_instance_id()),"layout":str(scene.get("map_layout").get_instance_id()),"camera":str(camera.get_instance_id()),"zoom":camera.get("zoom")}

func loading_identity() -> Dictionary:
	return {"transition":lm.get("_transition_active"),"external":lm.get("_external_active"),"token":lm.get("_external_token"),"preparation":lm.get("_field_preparation_token")}

func walk(field: Node, target: Vector2, label: String) -> bool:
	var actor: Node2D=field.get("_player") as Node2D
	var start: Vector2=actor.position
	var delta: Vector2=target-start
	# The declared segment is axis-aligned. A preceding 230px leg is not a
	# multiple of an 8px tick, so carry its <=10px endpoint error without a pose write.
	if not check(target.is_finite() and (absf(delta.x)<=FOOT_TOLERANCE or absf(delta.y)<=FOOT_TOLERANCE),label+":SOURCE_AXIS_WITH_SAME_ONE_TICK_ENDPOINT_TOLERANCE"): return false
	var horizontal: bool=absf(delta.x)>absf(delta.y)
	var action: String=("move_right" if delta.x>0 else "move_left") if horizontal else ("move_down" if delta.y>0 else "move_up")
	var forward: float=signf(delta.x if horizontal else delta.y)
	var maximum: int=ceili(start.distance_to(target)/480.0*Engine.physics_ticks_per_second)+24
	var path: Array=[]
	Input.action_press(action)
	for index: int in range(maximum):
		await physics_frame
		if not in_budget() or not is_instance_valid(actor) or current_scene!=field: break
		path.append([actor.position.x,actor.position.y]); input_ticks+=1
		var left: float=(target.x-actor.position.x if horizontal else target.y-actor.position.y)*forward
		if left<=1.0: break
	release_input()
	await physics_frame
	var actual: Vector2=actor.position if is_instance_valid(actor) else Vector2(INF,INF)
	records.append({"true_input":label,"start":[start.x,start.y],"target":[target.x,target.y],"actual":[actual.x,actual.y],"path":path,"not_inspection_teleport":true})
	return check(in_budget() and actual.distance_to(target)<=FOOT_TOLERANCE,label+":ARRIVED_FIXED_MAX_ONE_SPEED_TICK_PLUS_2PX")

func static_snapshot(field: Node) -> Dictionary:
	var floors: Array=[]; var bodies: Array=[]
	for node: Node in field.get("_visual_layer").get_children():
		var floor_node: Polygon2D=node as Polygon2D
		if floor_node!=null: floors.append([str(floor_node.get_instance_id()),floor_node.transform,floor_node.polygon,floor_node.uv,str(floor_node.texture.get_instance_id()) if floor_node.texture!=null else "",str(floor_node.material.get_instance_id()) if floor_node.material!=null else ""])
	for node: Node in field.get("_collision_layer").get_children():
		var children: Array=[]
		for shape: Node in node.get_children():
			var polygon: CollisionPolygon2D=shape as CollisionPolygon2D
			if polygon!=null: children.append([str(polygon.get_instance_id()),polygon.transform,polygon.polygon,polygon.disabled])
		bodies.append([str(node.get_instance_id()),(node as Node2D).transform,children])
	return {"floor":var_to_bytes(floors),"bodies":var_to_bytes(bodies),"floor_count":floors.size(),"body_count":bodies.size()}

func key(code: int) -> void:
	var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=true
	Input.parse_input_event(event); await process_frame
	event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=false
	Input.parse_input_event(event); await process_frame

func _on_text(speaker: String, text: String, choices: bool, portrait: String) -> void:
	displayed_choices.clear()
	texts.append({"speaker":speaker,"text":text,"choices":choices,"portrait":portrait})

func _on_choices(choices: Array) -> void:
	# Includes DialogPlayer's source-defined SIDE-offer presentation, which is
	# not stored in DialogNode.choices. Never call advance()/choose() directly.
	displayed_choices=choices.duplicate(true)

func finish_monologue() -> bool:
	var start: int=Time.get_ticks_msec()
	var inputs: int=0
	while in_budget() and Time.get_ticks_msec()-start<int(spec.budgets.dialog_seconds)*1000 and inputs<int(spec.budgets.max_dialog_inputs):
		await process_frame
		if dp.call("is_playing")!=true: break
		var graph: Resource=dp.get("_current_script")
		var graph_allowed: bool=graph!=null and String(graph.get("dialog_id")) in spec.temple.allowed_dialog_ids
		if graph!=null:
			for prefix: String in spec.temple.allowed_dialog_prefixes:
				if prefix.length()>=16 and String(graph.get("dialog_id")).begins_with(prefix): graph_allowed=true
		if not check(graph_allowed,"SOURCE_DECLARED_DIALOG_GRAPH_OR_EXACT_GENERATOR_NAMESPACE"): return false
		var choices: Array=displayed_choices
		if not choices.is_empty():
			var labels: Array=[]
			for choice: Dictionary in choices: labels.append(String(choice.get("text","")))
			if not check(String(dp.get("_pending_side_offer_id"))==spec.temple.offer_quest_id and labels==spec.temple.offer_choice_texts,"ORIGINAL_SYNTHESIZED_SIDE_OFFER_EXACT_LABELS_AND_QUEST"): return false
			var selected: int=-1
			for index: int in range(choices.size()):
				if String(choices[index].get("text","")) in spec.temple.safe_exit_choice_texts:
					if selected!=-1: check(false,"AMBIGUOUS_SAFE_EXIT_CHOICE"); return false
					selected=index
			if not check(selected>=0 and selected<9,"DECLARED_NO_EFFECT_EXIT_ONLY_NO_GUESS"): return false
			await key(KEY_1+selected)
		else: await key(KEY_SPACE)
		inputs+=1
	var npc_text: bool=false
	for event: Dictionary in texts:
		if event.speaker==spec.temple.npc_name and not event.text.is_empty(): npc_text=true
	records.append({"temple_dialog":texts.duplicate(true),"real_key_inputs":inputs})
	return check(dp.call("is_playing")==false and npc_text,"REAL_MONK_DIALOG_NORMAL_END")

func capture(label: String) -> bool:
	if png_count>=int(spec.budgets.max_png) or not in_budget(): return false
	await RenderingServer.frame_post_draw
	var path: String=OUTPUT_ROOT+str(OS.get_process_id())+"/"+label+".png"
	if FileAccess.file_exists(path): return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var image: Image=root.get_viewport().get_texture().get_image()
	if image==null or image.is_empty() or image.save_png(path)!=OK: return false
	png_count+=1; records.append({"PNG":path,"sha256":FileAccess.get_sha256(path),"width":image.get_width(),"height":image.get_height(),"camera_changed_by_QA":false}); return true

func finish() -> void:
	release_input()
	var source_final: Dictionary=facts(source_first.keys())
	var save_final: Dictionary=facts(spec.get("save_paths",[]))
	if not source_first.is_empty(): check(source_first==source_final,"SMALL_FIXED_SOURCE_FIRST_FINAL")
	if not save_first.is_empty(): check(save_first==save_final,"FIFTEEN_SAVE_SHA_BYTES_MTIME_SECONDS_SAME_ROOT_EXACTTICKS_GUARD_SEPARATE")
	var path: String=OUTPUT_ROOT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path): printerr("PRESERVE_ORIGINAL_RESULT"); quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var output:=FileAccess.open(path,FileAccess.WRITE)
	if output==null: quit(2); return
	output.store_string(JSON.stringify({"complete":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"source_first":source_first,"source_final":source_final,"save_first":save_first,"save_final":save_final,"true_input_physics_samples":input_ticks,"PNG_count":png_count,"scope":"New Gate child admission only, Civic seam and safe Temple greeting; no old services/Estate/whole city; explicit region entry not default performance","production_or_save_calls":0},"\t")+"\n"); output.close()
	print("BOUNDED_REGION_RESULT ",path)
	quit(0 if errors.is_empty() else 1)
