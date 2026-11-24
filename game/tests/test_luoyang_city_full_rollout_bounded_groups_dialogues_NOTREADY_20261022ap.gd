extends "res://tests/test_luoyang_t_yamen_hall_return_retry1_ready_20261019u.gd"
## AP NEW draft. Reuses INPUT/raw-body/source/save primitives only; never parent itinerary.
## Final successor must pin contract+complete source maps and budgets before Root's only actual.
const AP_READY: bool = false
const AP_GROUP_LIMITS: Dictionary={"A":180000,"B":180000,"C":180000,"D":180000,"E":90000}
const AP_CHOICE_KEYS: Array[Key]=[KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9]
var ap_group: String=""
var ap_group_spec: Dictionary={}
var ap_doors_done: Array[String]=[]
var ap_dialogues_done: Array[String]=[]
var ap_return_metrics: Array[Dictionary]=[]
const AP_CONTRACT: String = "res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_groups_v3_dialogues_NOTREADY.json"
const AP_CONTRACT_SHA: String = "PENDING_FINAL_CONTRACT"
const AP_IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s3_luoyang_market","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","luoyang_estate_riverside_20261021ai","ch4_s4_ancient_temple","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
var ap_specs: Dictionary = {}
var ap_state_before: Dictionary = {}
var ap_reached: Array[String] = []
var ap_links: Array[Dictionary] = []
var ap_full_source_checks: Dictionary = {}

func _state_ap() -> Dictionary:
	var gs: Node = root.get_node("GameState")
	return {"flags":gs.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict").duplicate(true),"inventory":root.get_node("Inventory").call("to_dict").duplicate(true),"gold":gs.get("gold"),"reputation":gs.get("reputation"),"training_total":gs.get("training_points_total"),"training_available":gs.get("training_points_available")}

func precheck() -> bool:
	if not check(AP_READY,"NOTREADY: AP final source/native/portal/budget authority not frozen"): return false
	if not track(AP_CONTRACT,AP_CONTRACT_SHA): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AP_CONTRACT))
	if not check(parsed is Dictionary,"Exact AP contract Dictionary"): return false
	plan = parsed
	var selector_args: PackedStringArray=OS.get_cmdline_user_args()
	if not check(selector_args.size()==1 and selector_args[0].begins_with("--ap-qa-group="),"Exactly one QA-only group selector, no feature flags"): return false
	ap_group=selector_args[0].trim_prefix("--ap-qa-group=")
	if not check(AP_GROUP_LIMITS.has(ap_group) and plan.get("groups") is Dictionary and plan.groups.has(ap_group),"Fixed approved group A/B/C/D/E"): return false
	ap_group_spec=plan.groups[ap_group]
	plan["whole_ms"]=ap_group_spec.whole_ms
	var budget: Variant=plan.get("whole_ms")
	if not check(plan.get("ready")==true and plan.get("schema")=="AP_QA_BOUNDED_GROUPS_V3" and plan.get("arrival_ms")==60000 and (budget is int or budget is float) and is_finite(float(budget)) and float(budget)==floorf(float(budget)) and int(budget)==int(AP_GROUP_LIMITS[ap_group]),"Root predeclared shared whole budget and60s arrivals"): return false
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not check(args.size()==1 and args[0]=="--ap-qa-group="+ap_group and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and root.size==Vector2i(1920,1080),"Ordinary1080P; QA selector only, no product candidate flags or whole-camera claim"): return false
	if not check(plan.scenes is Array and plan.scenes.size()==8 and plan.links is Array and plan.links.size()==3 and not plan.core_source_sha256.is_empty(),"Eight actual scenes/three new links/fixed whole source authority"): return false
	if not check(plan.get("return_performance_target_ms")==10000,"Predeclared all-return10s goal, arrival remains60s"): return false
	for path: String in plan.dialogue_source_sha256:
		if not track(path,plan.dialogue_source_sha256[path]): return false
	for path: String in plan.core_source_sha256:
		if not track(path,plan.core_source_sha256[path]): return false
	for row: Dictionary in plan.scenes:
		if not check(row.get("id") in AP_IDS and not ap_specs.has(row.id) and row.get("owner") in ["CITY","ESTATE","TEMPLE","QUARTER"] and row.get("source_sha256") is Dictionary and not row.source_sha256.is_empty() and row.get("receipt_source_sha256") is Dictionary and not row.receipt_source_sha256.is_empty(),"Unique fixed per-domain complete source maps "+String(row.get("id"))): return false
		if not check(plan.core_source_sha256.has(row.owner_path) and row.source_sha256.has(row.scene_path) and row.source_sha256.has(row.layout_path) and not row.input_points.is_empty(),"Executed owner/native identity and explicit short input fixed "+row.id): return false
		ap_specs[row.id]=row
	for id: String in AP_IDS:
		if not check(ap_specs.has(id),"All eight fields required "+id): return false
	var pairs: Array[String]=[]
	for row: Dictionary in plan.links:
		pairs.append(String(row.source)+">"+String(row.target))
		if not check(ap_specs.has(row.source) and ap_specs.has(row.target) and row.source_approach.size()>=2 and row.target_approach.size()>=2 and row.return_max_ms==10000 and row.setup_is_not_interdistrict_travel==true,"Source-authored bidirectional link, frozen return budget "+row.id): return false
	pairs.sort()
	var expected_pairs: Array[String]=["ch4_s3_luoyang_market>luoyang_artisan_residential_20261022ap","luoyang_estate_riverside_20261021ai>luoyang_riverside_garden_20261022ap","luoyang_riverside_garden_20261022ap>ch4_s2_canal_docks"]
	expected_pairs.sort()
	if not check(pairs==expected_pairs,"Exactly approved three new connections, not old AO/AN doors"): return false
	if not check(plan.rooms is Array and plan.rooms.size()==5 and plan.doors is Array and plan.doors.size()==5 and plan.existing_daily_ids is Array and plan.existing_daily_ids.size()==12,"Five changed room identities/doors and twelve fixed stationary daily identities"): return false
	for room: Dictionary in plan.rooms:
		if not check(not ap_specs.has(room.id) and room.owner=="ROOM" and not room.source_sha256.is_empty() and not room.receipt_source_sha256.is_empty(),"Distinct frozen room owner "+room.id): return false
		ap_specs[room.id]=room
	for door: Dictionary in plan.doors:
		if not check(ap_specs.has(door.source) and ap_specs.has(door.target) and door.source_approach.size()>=2 and door.room_exit_approach.size()>=2 and door.return_max_ms==10000 and door.setup_is_not_interdistrict_travel==true,"Predeclared changed-door route/return budget "+door.id): return false
	return true

func _draw() -> void:
	if target.is_empty() or not first_draw.is_empty() or not is_instance_valid(current_scene): return
	var s: SceneScript=current_scene.get("_current_scene") as SceneScript
	var p: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if s==null or String(s.scene_id)!=target or p==null or not p.can_process() or p.get("can_move")!=true: return
	var loading: Dictionary=current_scene.call("get_field_loading_state")
	var screen: Node=root.get_node("LoadingManager").get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	if loading.get("complete")!=true or loading.get("failed",false) or (panel!=null and panel.is_visible_in_tree()): return
	var spec: Dictionary=ap_specs[target]
	if spec.owner=="CITY" and (C._resident_ready.get("scene")!=s or C._resident_ready.get("sources_finalized")!=true): return
	# First draw freezes only cheap existing state. All deep/hash verification is below.
	var now: int=Time.get_ticks_usec()
	first_draw={"target":target,"trigger_usec":triggered_usec,"first_draw_usec":now,"elapsed_usec":now-triggered_usec,"frame":Engine.get_process_frames(),"Field_id":current_scene.get_instance_id(),"Scene_id":s.get_instance_id(),"Player_id":p.get_instance_id(),"foot":p.position,"Loading_hidden":true,"can_move":true,"instrument":"AP_ORIGINAL_POSTDRAW_SCALARS_BEFORE_POSTVERIFY"}

func _post_owner(id: String) -> bool:
	var spec: Dictionary=ap_specs[id]
	var started: int=Time.get_ticks_usec()
	if not check(scene.resource_path==spec.scene_path and scene.map_layout.resource_path==spec.layout_path and scene.actor_positions_are_feet,"Actual intended AP native Scene/layout/feet "+id): return false
	var actual: Dictionary={}
	var proof: Dictionary={}
	var collected: Dictionary={}
	if spec.owner=="CITY":
		proof=C.resident_receipt(scene)
		if not check(proof.get("sources_finalized")==true and proof.get("proof_kind")=="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1" and proof.get("scene")==scene and int(proof.get("token",0))>0,"Actual CITY full owner token/Scene/source-final "+id): return false
		actual=proof.get("sources",{})
		collected=C._transition_sources(proof.source_scene,false)
	elif spec.owner=="ROOM":
		var room_api: Variant=load(spec.owner_path)
		proof=room_api._sessions.get(scene.get_instance_id(),{})
		if not check(proof.get("finalized",false) and proof.scene.get_ref()==scene and proof.layout.get_ref()==scene.map_layout and room_api.is_room(scene),"Actual Field-finalized room session, QA does not create it "+id): return false
		actual=room_api.catalogue().rooms[id].source_sha256
		collected=room_api.source_paths()
	elif spec.owner=="TEMPLE":
		proof=field.call("get_temple_assembly_state")
		if not check(proof.get("finalized")==true and proof.get("worker_active")==false and C._equal_value(proof.get("source_first"),proof.get("source_final")),"Temple own source-final, not borrowed C city proof"): return false
		actual=proof.get("source_first",{})
		collected=load(spec.owner_path).source_paths()
	else:
		var api: Variant=load(spec.owner_path)
		# Never call validation_begin/finish/matches from QA: they could create credit.
		proof=api.validation_receipt()
		var sessions: Dictionary=api._sessions
		var session: Dictionary=sessions.get(scene.get_instance_id(),{})
		if not check(not session.is_empty() and session.scene.get_ref()==scene and session.layout.get_ref()==scene.map_layout,"Actual Field-established live family native session "+id): return false
		if not check(proof.get("finalized")==true and C._equal_value(proof.get("source_first"),proof.get("source_final")),"Own family complete first/final receipt "+id): return false
		actual=proof.get("source_first",{})
		collected=api.source_paths()
	if not check(C._equal_value(actual,spec.receipt_source_sha256),"Exact independent owner receipt map "+id): return false
	if not check(collected.size()==spec.source_sha256.size(),"Complete collector key cardinality "+id): return false
	for path: String in collected:
		if not check(spec.source_sha256.has(path),"No unapproved collector leaf "+path): return false
	# Deduplicate test disk reads; production still owns first/final per transition.
	for path: String in spec.source_sha256:
		if source_before.has(path):
			if not check(source_before[path].sha256==spec.source_sha256[path],"Previously observed shared source stays expected "+path): return false
		elif not track(path,spec.source_sha256[path]): return false
	ap_full_source_checks[id]=true
	records.append({"kind":"AP_POSTDRAW_OWNER","id":id,"owner":spec.owner,"first_draw":first_draw.duplicate(true),"postverify_usec":Time.get_ticks_usec()-started,"sources":spec.source_sha256.duplicate(true),"receipt":proof})
	return true

func _bind_independent(id: String) -> bool:
	var spec: Dictionary=ap_specs[id]
	var g: Dictionary=spec.geometry
	independent=RAW.new();mask=null
	if not check(_v(field.get("_world_size"))==_v(spec.world_size) and independent.configure(g.floor_regions_px,g.solids,_v(g.source_size_px),_v(spec.world_size),g.foot_forbidden_regions_px),"Independent native34x24/875+17 source geometry "+id): return false
	if not String(g.mask_path).is_empty():
		if not check(spec.source_sha256.get(g.mask_path)==g.mask_sha256,"Raster belongs to fixed actual source map"): return false
		mask=Image.load_from_file(g.mask_path)
		if not check(mask!=null and mask.get_size()==Vector2i(_v(spec.world_size)),"Actual full-domain mask "+id): return false
	return check(_clear(field.get("_player").position),"Native spawn Physics/full87517/continuous "+id)

func _actual_delta(id: String) -> bool:
	var spec: Dictionary=ap_specs[id]
	for object_id: String in spec.visual_ids:
		var found: int=0
		for layer_name: String in ["_visual_layer","_actor_layer"]:
			var layer: Node=field.get(layer_name)
			if layer!=null and layer.get_node_or_null("SceneObject_"+object_id) is Sprite2D: found+=1
		if not check(found==1,"Exactly one affected actual Sprite "+object_id): return false
	for wanted: Dictionary in spec.npc_rows:
		var found: Array[Node]=[]
		for n: Node in field.get("_npc_nodes"):
			if is_instance_valid(n) and n.get("npc_id")==wanted.id: found.append(n)
		if not check(found.size()==1,"One actual source-bound role "+wanted.id): return false
		var n: Node=found[0]
		if not check(n.get("sprite_path")==wanted.sprite_path and n.get("portrait_path")==wanted.portrait_path and n.get("walk_sprite_path")==wanted.walk_sprite_path and n.get("movement_mode")==wanted.movement_mode,"Actual role's admitted identity/idle-walk family "+wanted.id): return false
		if not check(n.get("_ground_anchored")==wanted.ground_anchored,"Authored actor native ground-anchor "+wanted.id): return false
		var body: StaticBody2D=n.get("_body_collider") as StaticBody2D
		var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D if is_instance_valid(body) and body.get_child_count()==1 else null
		if not check(shape!=null and shape.shape is RectangleShape2D and not shape.disabled and body.collision_layer==1 and shape.shape.size==_v(wanted.body_size_px),"Original admitted native role body, never reduced for layout "+wanted.id): return false
		if wanted.get("daily_secondary",false)==true:
			if not check(n.get_meta("ap_daily_exact_identity",false)==true and n.get("interaction_action")=="culture_x_menu" and n.get_meta("culture_x_primary",{})=={"dialog_id":"","interaction_action":""},"Actual configured secondary daily identity, not ignored row fields "+wanted.id): return false

		if wanted.get("quarter_daily",false)==true:
			if not check(n.get_meta("ap_quarter_daily_exact_identity",false)==true and n.get("interaction_action")=="culture_x_menu" and n.get_meta("culture_x_primary",{})=={"dialog_id":"","interaction_action":""},"Actual quarter daily identity, not old-city metadata "+wanted.id): return false
		records.append({"kind":"AP_ACTUAL_ROLE","scene":id,"id":wanted.id,"instance_id":n.get_instance_id(),"foot":n.get("position"),"sprite_path":n.get("sprite_path")})
	return true

func _setup_ap(id: String,uv: Variant) -> bool:
	_arm(id)
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(id),null if uv==null else _v(uv),"",-1,3),"Legal public AP setup, not interdistrict travel "+id): return false
	return await _arrive(id)

func _link_ap(row: Dictionary) -> bool:
	if not await _setup_ap(row.source,row.setup_uv) or not await _walk(row.source_approach,"AP link approach "+row.id) or not await _zone(row.target,_v(row.source_portal_foot)): return false
	var origin_size: Vector2=_v(ap_specs[row.source].world_size)
	var remembered: Vector2=(field.get("_player").position/origin_size)*origin_size
	if not await _space(row.target): return false
	if not check(field.get("_player").position==_v(row.target_arrival_foot),"Actual new link arrival exact native foot "+row.id): return false
	if not await _walk(row.target_approach,"AP reverse approach "+row.id) or not await _zone(row.source,_v(row.target_portal_foot)): return false
	if not await _space(row.source): return false
	if not check(field.get("_player").position==remembered and field.get("_player").position==_v(row.expected_return_foot),"Exact actual remembered/authored return, never return-backfilled "+row.id): return false
	_return_performance(row.id,"link",first_draw)
	ap_links.append({"id":row.id,"returned":true,"elapsed_usec":first_draw.elapsed_usec,"return_max_ms":row.return_max_ms,"remembered":remembered})
	return true

func _return_performance(id: String,kind: String,measurement: Dictionary) -> void:
	var elapsed: int=int(measurement.elapsed_usec)
	var achieved: bool=elapsed<10000000
	# Functional arrival waits original60s. A slow valid return is preserved as
	# geometry/source success, but performance failure still makes whole FAIL.
	check(achieved,"Actual return firstdraw hidden+operable meets fixed10s goal "+id,{"elapsed_usec":elapsed,"target_usec":10000000,"functional_arrival":true,"arrival_limit_ms":60000})
	ap_return_metrics.append({"id":id,"kind":kind,"functional_arrival":true,"firstdraw_elapsed_usec":elapsed,"performance_target_usec":10000000,"performance_pass":achieved,"postverify_not_counted_as_loading":true})

func _find_fixed(rows: Array,id: String) -> Dictionary:
	var out: Dictionary={}
	for row: Dictionary in rows:
		if row.id==id:
			if not out.is_empty(): return {}
			out=row
	return out

func _door_ap(row: Dictionary) -> bool:
	if not await _setup_ap(row.source,row.setup_uv) or not await _walk(row.source_approach,"Changed door normal approach "+row.id) or not await _zone(row.target,_v(row.source_portal_foot)): return false
	var exterior: WeakRef=weakref(field)
	var exterior_scene: WeakRef=weakref(scene)
	var remembered: Vector2=(field.get("_player").position/_v(ap_specs[row.source].world_size))*_v(ap_specs[row.source].world_size)
	if not await _space(row.target) or not check(field.get("_player").position==_v(row.room_arrival_foot),"Changed-room exact arrival "+row.id): return false
	if not await _walk(row.room_exit_approach,"Actual room exit "+row.id) or not await _zone(row.source,_v(row.room_exit_foot)): return false
	if not await _space(row.source): return false
	if not check(field.get("_player").position==remembered and field.get("_player").position==_v(row.authored_return_foot),"Changed door exact captured/authored return "+row.id): return false
	_return_performance(row.id,"door",first_draw)
	records.append({"kind":"AP_CHANGED_DOOR_ACTUAL_TRIP","id":row.id,"returned":true,"return_firstdraw_usec":first_draw.elapsed_usec,"return_max_ms":row.return_max_ms,"remembered_before_entry":remembered,"same_Field":field==exterior.get_ref(),"same_Scene":scene==exterior_scene.get_ref(),"new_quarter_does_not_borrow_city_lease":true})
	ap_doors_done.append(row.id)
	return true

func _native_blocked(foot: Vector2) -> bool:
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
	if not check(shape!=null and shape.position==Vector2.ZERO and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24),"Unchanged native34x24 negative query"): return false
	var world: Node2D=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.exclude=[player.get_rid()];query.collision_mask=1;query.collide_with_areas=false
	native_queries+=1
	return not player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _negatives_ap(id: String) -> bool:
	for row: Dictionary in ap_specs[id].get("negative_stations",[]):
		var foot: Vector2=_v(row.foot)
		var oracle_blocked: bool=not independent.clear(foot) or not _mask_clear(foot)
		var physics_blocked: bool=_native_blocked(foot)
		if not check(oracle_blocked and physics_blocked,"Independent+actual Physics reject declared water/scenic bridge/base "+row.id): return false
		records.append({"kind":"AP_ACTUAL_DECLARED_NEGATIVE","id":row.id,"foot":foot,"independent_reject":oracle_blocked,"native_Physics_reject":physics_blocked})
	return true

func _dialogue_ap(row: Dictionary) -> bool:
	if not await _setup_ap(row.scene_id,row.setup_uv) or not await _walk(row.approach,"Actual NPC normal approach "+row.npc_id): return false
	var found: Array[Node]=[]
	for npc: Node in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.get("npc_id")==row.npc_id: found.append(npc)
	if not check(found.size()==1 and found[0].get("npc_name")==row.npc_name and found[0].get_meta(row.identity_meta,false)==true and found[0].get("interaction_action")=="culture_x_menu","One actual intended speaker before Space"): return false
	var before: Dictionary=_state_ap()
	var dp: Node=root.get_node("DialogPlayer")
	await driver.key(KEY_SPACE)
	var until: int=mini(deadline,Time.get_ticks_msec()+5000)
	while Time.get_ticks_msec()<until and not dp.call("is_playing"): await process_frame
	var script: DialogScript=dp.get("_current_script") as DialogScript
	var node: DialogNode=dp.get("_current_node") as DialogNode
	if not check(script!=null and node!=null and String(script.dialog_id)==row.expected_menu_id and String(node.node_id)==row.expected_menu_node_id and node.speaker==row.npc_name and row.exit_choice_index>=0 and row.exit_choice_index<AP_CHOICE_KEYS.size() and node.choices.size()>row.exit_choice_index,"Real Space opened exact AP menu/dialogue"): return false
	if not check(C._equal_value(node.choices,row.expected_choices) and C._equal_value(node.choices[row.exit_choice_index],row.expected_exit_choice),"Frozen no-effect dismiss choice, no guessed accept/report index"): return false
	var dialog_layer: Node=dp.get("_box")
	var box: Control=dialog_layer.get_node_or_null("DialogBox") as Control if is_instance_valid(dialog_layer) else null
	if not check(is_instance_valid(box) and box.is_visible_in_tree(),"Actual dialogue UI visible"): return false
	_arm(row.scene_id)
	await driver.key(AP_CHOICE_KEYS[row.exit_choice_index])
	if not await _arrive(row.scene_id): return false
	if not check(not dp.call("is_playing") and C._equal_value(before,_state_ap()),"Actual dismiss/rebuild leaves tasks/rewards/flags unchanged"): return false
	if not _actual_delta(row.scene_id): return false
	records.append({"kind":"AP_NPC_REAL_SPACE_NO_REWARD","npc_id":row.npc_id,"scene":row.scene_id,"dialog_id":row.expected_menu_id,"rebuild_firstdraw_usec":first_draw.elapsed_usec,"no_actual_task_chain_replay":true})
	ap_dialogues_done.append(row.id)
	return true

func _exercise() -> bool:
	for id: String in ap_group_spec.captures:
		var spec: Dictionary=ap_specs[id]
		if not await _setup_ap(id,spec.setup_uv): return false
		if not await _walk(spec.input_points,"AP affected ordinary INPUT "+id) or not _actual_delta(id) or not _negatives_ap(id) or not await _capture(String(spec.ordinary_picture_label)): return false
		ap_reached.append(id)
	for id: String in ap_group_spec.doors:
		var row: Dictionary=_find_fixed(plan.doors,id)
		if row.is_empty() or not await _door_ap(row): return false
	for id: String in ap_group_spec.links:
		var row: Dictionary=_find_fixed(plan.links,id)
		if row.is_empty() or not await _link_ap(row): return false
	for id: String in ap_group_spec.dialogues:
		var row: Dictionary=_find_fixed(plan.dialogues,id)
		if row.is_empty() or not await _dialogue_ap(row): return false
	return check(ap_reached.size()==ap_group_spec.captures.size() and captures.size()==ap_group_spec.captures.size() and ap_doors_done.size()==ap_group_spec.doors.size() and ap_links.size()==ap_group_spec.links.size() and ap_dialogues_done.size()==ap_group_spec.dialogues.size(),"Only fixed bounded group complete; other groups get no borrowed credit")

func _run() -> void:
	var began: int=Time.get_ticks_msec()
	deadline=began+1000
	var scope_args: PackedStringArray=OS.get_cmdline_user_args()
	if scope_args.size()==1 and scope_args[0].begins_with("--ap-qa-group="): ap_group=scope_args[0].trim_prefix("--ap-qa-group=")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	output="res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_actual_%s/%d_%d"%[ap_group,OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete: bool=false
	if precheck():
		deadline=began+int(plan.whole_ms)
		driver=INPUT.new();driver.configure(self);RenderingServer.frame_post_draw.connect(_draw)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		root.get_node("GameState").set("current_chapter",4)
		ap_state_before=_state_ap()
		complete=await _exercise()
	target=""
	if RenderingServer.frame_post_draw.is_connected(_draw): RenderingServer.frame_post_draw.disconnect(_draw)
	if not await _cleanup(): complete=false
	if not ap_state_before.is_empty() and not check(C._equal_value(ap_state_before,_state_ap()),"No task/flag/reward/inventory mutation during pure travel"): complete=false
	records.append({"kind":"AP_FINITE_DELTA_SCOPE","group":ap_group,"return_performance":ap_return_metrics,"whole_limit_ms":plan.get("whole_ms",0),"doors":ap_doors_done,"dialogues":ap_dialogues_done,"reached":ap_reached,"links":ap_links,"captures":captures,"native_queries":native_queries,"formal_all_ten_art_requires_Root_ART":true,"no_AO_AN_or_ten_room_replay":true})
	finish(output,began,complete,"AP_BOUNDED_GROUPS_EIGHT_FIELD_FIVE_DOOR_THREE_LINK_ORDINARY_NOTREADY")
