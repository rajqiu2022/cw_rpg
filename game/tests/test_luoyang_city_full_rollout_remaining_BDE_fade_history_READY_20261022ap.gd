extends "res://tests/test_luoyang_t_yamen_hall_return_retry1_ready_20261019u.gd"
## Final stage03 source-bound groups. Reuses primitives only, never parent itinerary.
## Root alone runs these five fixed groups; no engine credit comes from this source.
const AP_READY: bool = true
const AP_GROUP_LIMITS: Dictionary={"A":180000,"B":180000,"C":180000,"D":180000,"E":90000}
const AP_CHOICE_KEYS: Array[Key]=[KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9]
var ap_group: String=""
var ap_group_spec: Dictionary={}
var ap_doors_done: Array[String]=[]
var ap_dialogues_done: Array[String]=[]
var ap_return_metrics: Array[Dictionary]=[]
const AP_CONTRACT: String = "res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_remaining_fade_history_BDE_joint_estate_READY.json"
const AP_CONTRACT_SHA: String = "0d8b2464e9909ea856cd5c213330429a8941591fc85c9973f2c44e551fd7d956"
const AP_IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s3_luoyang_market","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","luoyang_estate_riverside_20261021ai","ch4_s4_ancient_temple","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
var ap_specs: Dictionary = {}
var ap_state_before: Dictionary = {}
var ap_reached: Array[String] = []
var ap_links: Array[Dictionary] = []
var ap_full_source_checks: Dictionary = {}
var ap_initial_estate_receipt: Dictionary = {}
var ap_reuse_estate_Field: bool = false

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
	if not check(ap_group in ["B","D","E"] and plan.get("permitted_remaining_groups")==["B","D","E"] and plan.get("ready")==true and plan.get("schema")=="AP_QA_REMAINING_BDE_V6_REAL_ESTATE_JOINT_SETUP" and plan.get("arrival_ms")==60000 and (budget is int or budget is float) and is_finite(float(budget)) and float(budget)==floorf(float(budget)) and int(budget)==int(AP_GROUP_LIMITS[ap_group]),"Root remaining BDE only; original fixed shared budgets and60s arrivals"): return false
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not check(args.size()==1 and args[0]=="--ap-qa-group="+ap_group and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and root.size==Vector2i(1920,1080),"Ordinary1080P; QA selector only, no product candidate flags or whole-camera claim"): return false
	if not check(plan.scenes is Array and plan.scenes.size()==8 and plan.links is Array and plan.links.size()==3 and not plan.core_source_sha256.is_empty(),"Eight actual scenes/three new links/fixed whole source authority"): return false
	if not check(plan.get("return_performance_target_ms")==10000 and plan.get("input_endpoint_tolerance_px")==.3,"Predeclared all-return10s goal, arrival60s; original driver.3px endpoint only"): return false
	if not check(plan.return_memory_authority.Field_sha256==plan.core_source_sha256.get(plan.return_memory_authority.Field) and plan.return_memory_authority.Router_sha256==plan.core_source_sha256.get(plan.return_memory_authority.Router),"Pre-actual exact Field/Router source memory-policy authority"): return false
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
	var finite_visible: int=0
	var finite_daily: int=0
	for id: String in AP_IDS:
		finite_visible+=ap_specs[id].npc_rows.size()
		finite_daily+=ap_specs[id].get("daily_identities",[]).size()
	if not check(finite_visible==14 and finite_daily==12,"Frozen ordinary6 visual+8quarter actors/12daily only; no forced quest-hidden commander"): return false
	var pairs: Array[String]=[]
	for row: Dictionary in plan.links:
		pairs.append(String(row.source)+">"+String(row.target))
		if not check(ap_specs.has(row.source) and ap_specs.has(row.target) and row.source_approach.size()>=2 and row.target_approach.size()>=2 and row.return_max_ms==10000 and row.setup_is_not_interdistrict_travel==true and row.return_memory_policy=="AUTHORED_PORTAL_ANCHOR","Source-authored bidirectional link, frozen return budget/anchor policy "+row.id): return false
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
		var policy: String="ACTUAL_CAPTURED_FOOT" if door.source=="ch4_s3_luoyang_market" else "AUTHORED_PORTAL_ANCHOR"
		if not check(door.return_memory_policy==policy,"Pre-actual Root exact source memory contract, not observed backfill "+door.id): return false
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
		if spec.owner=="ESTATE":
			if ap_initial_estate_receipt.is_empty():
				ap_initial_estate_receipt=proof.duplicate(true)
				records.append({"kind":"AP_ESTATE_TRUE_MARKET_JOINT_INITIAL_OWNER","serial":proof.get("serial"),"key":proof.get("key"),"source_count":actual.size(),"finalized":proof.get("finalized"),"source_passes":proof.get("full_source_hash_passes")})
			else:
				if not check(C._equal_value(proof,ap_initial_estate_receipt),"Estate AP return retains exact original finalized receipt; no claimed fresh two-pass331"): return false
				records.append({"kind":"AP_ESTATE_CACHED_ORIGINAL_OWNER_REUSE","serial":proof.get("serial"),"key":proof.get("key"),"source_count":actual.size(),"fresh_source_hash_passes_this_return":0,"original_receipt_unchanged":true})
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
	if g.get("recipe")=="DOCKS_FIXED_PACKET_AND_DISTRICT_AUTHOR":
		g=_docks_geometry_ap(g,spec)
		if g.is_empty(): return false
	independent=RAW.new();mask=null
	if not check(_v(field.get("_world_size"))==_v(spec.world_size) and independent.configure(g.floor_regions_px,g.solids,_v(g.source_size_px),_v(spec.world_size),g.foot_forbidden_regions_px),"Independent native34x24/875+17 source geometry "+id): return false
	if not String(g.mask_path).is_empty():
		if not check(spec.source_sha256.get(g.mask_path)==g.mask_sha256,"Raster belongs to fixed actual source map"): return false
		mask=Image.load_from_file(g.mask_path)
		if not check(mask!=null and mask.get_size()==Vector2i(_v(spec.world_size)),"Actual full-domain mask "+id): return false
	return check(_clear(field.get("_player").position),"Native spawn Physics/full87517/continuous "+id)

func _docks_geometry_ap(recipe: Dictionary,spec: Dictionary) -> Dictionary:
	# Only the frozen disk source packet/author. Never C._records, live Scene,
	# production object_solids/projected functions or observed current hashes.
	if not check(spec.id=="ch4_s2_canal_docks" and recipe.packet_sha256=="1cb6bbf9825d538c982fcdf1171c5f3e268854be54796c3684c91502da14f221" and spec.source_sha256.get(recipe.packet_path)==recipe.packet_sha256 and spec.source_sha256.get(recipe.district_author_path)==recipe.district_author_sha256,"Fixed Docks source recipe belongs to independent complete map"): return {}
	if not track(recipe.packet_path,recipe.packet_sha256) or not track(recipe.district_author_path,recipe.district_author_sha256): return {}
	var saved: Variant=bytes_to_var(FileAccess.get_file_as_bytes(recipe.packet_path))
	if not check(saved is Dictionary and saved.get("record") is Dictionary and saved.record.get("objects") is Array and saved.record.objects.size()==29,"Exactly original fixed29object disk packet, no runtime collector"): return {}
	var solids: Array[Dictionary]=[]
	var seen: Dictionary={}
	for object: Dictionary in saved.record.objects:
		if not check(object.get("id") is String and not seen.has(object.id),"Unique fixed Docks source object"): return {}
		seen[object.id]=true
		var index: int=0
		for polygon: Array in object.get("solid_polygons_px",[]):
			solids.append({"id":object.id+"_poly_"+str(index),"kind":"ORIGINAL_PACKET_WORLD_POLYGON","points_px":polygon.duplicate(true)});index+=1
		var extent: Vector2=_v(object.collision_size_px)
		if extent.x>0 and extent.y>0:
			var low: Vector2=_v(object.physical_center_px)-extent*.5
			var high: Vector2=low+extent
			solids.append({"id":object.id+"_box","kind":"ORIGINAL_PACKET_WORLD_RECTANGLE","points_px":[low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]})
	var author: Variant=JSON.parse_string(FileAccess.get_file_as_string(recipe.district_author_path))
	if not check(author is Dictionary and author.get("districts") is Dictionary and author.districts.get(spec.id) is Dictionary and author.get("assets") is Dictionary,"Exact fixed District source declarations"): return {}
	for placement: Dictionary in author.districts[spec.id].placements:
		if not check(author.assets.has(placement.asset_id),"Each District declared source asset exists"): return {}
		var asset: Dictionary=author.assets[placement.asset_id]
		var index: int=0
		for polygon: Array in asset.ground_solid_polygons_px:
			var points: Array=[]
			for point: Array in polygon: points.append(_v(placement.foot_px)+(_v(point)-_v(asset.source_ground_anchor_px))*float(placement.scale))
			solids.append({"id":"district_"+placement.id+"_"+str(index),"kind":"ORIGINAL_DISTRICT_DECLARED_POLYGON","points_px":points});index+=1
	var mask_path: String=String(saved.record.get("walk_path",""))
	if not check(not mask_path.is_empty() and spec.source_sha256.has(mask_path),"Exact source packet mask belongs to full expected map; not observed SHA admission"): return {}
	return {"source_size_px":recipe.source_size_px,"floor_regions_px":recipe.floor_regions_px,"solids":solids,"foot_forbidden_regions_px":recipe.foot_forbidden_regions_px,"mask_path":mask_path,"mask_sha256":spec.source_sha256[mask_path]}

func _actual_delta(id: String) -> bool:
	var spec: Dictionary=ap_specs[id]
	for object_id: String in spec.visual_ids:
		var found: int=0
		for layer_name: String in ["_visual_layer","_actor_layer"]:
			var layer: Node=field.get(layer_name)
			if layer!=null and layer.get_node_or_null("SceneObject_"+object_id) is Sprite2D: found+=1
		if not check(found==1,"Exactly one affected actual Sprite "+object_id): return false
	for wanted: Dictionary in spec.get("daily_identities",[]):
		var fixed_daily: Array[Node]=[]
		for npc: Node in field.get("_npc_nodes"):
			if is_instance_valid(npc) and npc.get("npc_id")==wanted.id: fixed_daily.append(npc)
		if not check(fixed_daily.size()==1 and fixed_daily[0].get("npc_name")==wanted.name and fixed_daily[0].get_meta("ap_daily_exact_identity",false)==true and fixed_daily[0].get("interaction_action")=="culture_x_menu" and fixed_daily[0].get_meta("culture_x_primary",{})=={"dialog_id":"","interaction_action":""},"Actual ordinary12daily identity/action/unchanged empty primary "+wanted.id): return false
	for wanted: Dictionary in spec.npc_rows:
		var found: Array[Node]=[]
		for n: Node in field.get("_npc_nodes"):
			if is_instance_valid(n) and n.get("npc_id")==wanted.id: found.append(n)
		if not check(found.size()==1,"One actual source-bound role "+wanted.id): return false
		var n: Node=found[0]
		if not check(n.get("npc_name")==wanted.npc_name and n.get("sprite_path")==wanted.sprite_path and n.get("portrait_path")==wanted.portrait_path and n.get("walk_sprite_path")==wanted.walk_sprite_path and n.get("movement_mode")==wanted.movement_mode,"Actual role's admitted identity/idle-walk family "+wanted.id): return false
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
	if ap_group=="D" and ap_reuse_estate_Field and id=="luoyang_estate_riverside_20261021ai":
		return check(is_instance_valid(field) and field==current_scene and scene!=null and String(scene.scene_id)==id and not ap_initial_estate_receipt.is_empty(),"Keep original true-joint Estate Field; no direct-near rebuild or QA finalize")
	_arm(id)
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(id),null if uv==null else _v(uv),"",-1,3),"Legal public AP setup, not interdistrict travel "+id): return false
	return await _arrive(id)

func _link_ap(row: Dictionary) -> bool:
	if not await _setup_ap(row.source,row.setup_uv) or not await _walk(row.source_approach,"AP link approach "+row.id) or not await _zone(row.target,_v(row.source_portal_foot)): return false
	var origin_size: Vector2=_v(ap_specs[row.source].world_size)
	var actual_source_foot: Vector2=field.get("_player").position
	if not check(actual_source_foot.distance_to(_v(row.source_approach[-1]))<=.3,"Fixed authored INPUT endpoint only uses original driver.3px; actual body remains strict "+row.id): return false
	if not _authored_target_uv_ap(row.target,_v(row.source_portal_foot),_v(row.entry_authored_target_uv)): return false
	var remembered: Vector2=(field.get("_player").position/origin_size)*origin_size
	if not await _space(row.target): return false
	if not check(field.get("_player").position==_v(row.target_arrival_foot),"Actual new link arrival exact native foot "+row.id): return false
	if not await _walk(row.target_approach,"AP reverse approach "+row.id) or not await _zone(row.source,_v(row.target_portal_foot)): return false
	if not _authored_target_uv_ap(row.source,_v(row.target_portal_foot),_v(row.exit_authored_target_uv)): return false
	if not await _space(row.source): return false
	if not check(field.get("_player").position==_v(row.source_portal_foot),"AP link exact authored callback source anchor return; real INPUT separately bounded, never observed backfill "+row.id): return false
	_return_performance(row.id,"link",first_draw)
	ap_links.append({"id":row.id,"returned":true,"elapsed_usec":first_draw.elapsed_usec,"return_max_ms":row.return_max_ms,"actual_INPUT_foot_before_entry":actual_source_foot,"fixed_authored_return_foot":row.expected_return_foot,"authored_source_anchor":row.source_portal_foot,"return_memory_policy":row.return_memory_policy,"actual_input_not_claimed_as_stored_memory":remembered})
	return true

func _authored_target_uv_ap(id: String,portal: Vector2,expected: Vector2) -> bool:
	var matches: Array[Area2D]=[]
	for node: Node in field.get("_exit_nodes"):
		if node is Area2D and String(node.get("target_scene_id"))==id and node.position==portal: matches.append(node)
	return check(matches.size()==1 and matches[0].get("target_spawn_pos")==expected,"Authored native portal target UV independently exact; no observed return backfill "+id)

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
	var actual_source_foot: Vector2=field.get("_player").position
	if not check(actual_source_foot.distance_to(_v(row.source_approach[-1]))<=.3,"Fixed door INPUT endpoint only original.3px; no body/source tolerance "+row.id): return false
	if not _authored_target_uv_ap(row.target,_v(row.source_portal_foot),_v(row.entry_authored_target_uv)): return false
	var exterior: WeakRef=weakref(field)
	var exterior_scene: WeakRef=weakref(scene)
	var remembered: Vector2=(field.get("_player").position/_v(ap_specs[row.source].world_size))*_v(ap_specs[row.source].world_size)
	if not await _space(row.target) or not check(field.get("_player").position==_v(row.room_arrival_foot),"Changed-room exact arrival "+row.id): return false
	if not await _walk(row.room_exit_approach,"Actual room exit "+row.id) or not await _zone(row.source,_v(row.room_exit_foot)): return false
	if not _authored_target_uv_ap(row.source,_v(row.room_exit_foot),_v(row.exit_authored_target_uv)): return false
	if not await _space(row.source): return false
	var expected_return: Vector2=remembered if row.return_memory_policy=="ACTUAL_CAPTURED_FOOT" else _v(row.source_portal_foot)
	if not check(field.get("_player").position==expected_return,"Changed door exact predeclared source-memory policy, not observed return backfill "+row.id): return false
	_return_performance(row.id,"door",first_draw)
	records.append({"kind":"AP_CHANGED_DOOR_ACTUAL_TRIP","id":row.id,"returned":true,"return_firstdraw_usec":first_draw.elapsed_usec,"return_max_ms":row.return_max_ms,"actual_INPUT_foot_before_entry":actual_source_foot,"fixed_authored_room_exit_target":row.authored_return_foot,"fixed_source_portal_anchor":row.source_portal_foot,"return_memory_policy":row.return_memory_policy,"expected_return_before_entry":expected_return,"actual_input_canonical_roundtrip":remembered,"same_Field":field==exterior.get_ref(),"same_Scene":scene==exterior_scene.get_ref(),"new_quarter_does_not_borrow_city_lease":true})
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
	if ap_group=="D": return await _exercise_D_joint_ap()
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

func _capture_D_ap(id: String) -> bool:
	var spec: Dictionary=ap_specs[id]
	if not _actual_delta(id) or not _negatives_ap(id) or not await _capture(String(spec.ordinary_picture_label)): return false
	ap_reached.append(id)
	return true

func _exercise_D_joint_ap() -> bool:
	var initial: Dictionary=plan.D_initial_joint_setup
	if not await _setup_ap(initial.source,initial.setup_uv) or not await _walk(initial.source_approach,"Necessary original Market-Estate setup approach") or not await _zone(initial.target,_v(initial.source_portal_foot)): return false
	if not _authored_target_uv_ap(initial.target,_v(initial.source_portal_foot),_v(initial.entry_authored_target_uv)) or not await _space(initial.target): return false
	if not check(field.get("_player").position==_v(initial.arrival_foot) and not ap_initial_estate_receipt.is_empty(),"True joint arrival established original complete Estate owner"): return false
	var first_estate_Field: WeakRef=weakref(field)
	if not await _walk(initial.same_Field_south_loop,"Same Estate Field south-loop to new Garden gate") or not check(first_estate_Field.get_ref()==field,"South-loop uses original true-joint Estate Field") or not await _capture_D_ap(initial.target): return false
	ap_reuse_estate_Field=true
	if not await _link_ap(_find_fixed(plan.links,"estate_garden")): return false
	ap_reuse_estate_Field=false
	var garden: String="luoyang_riverside_garden_20261022ap"
	if not await _setup_ap(garden,ap_specs[garden].setup_uv) or not await _walk(ap_specs[garden].input_points,"Original finite Garden pavilion approach") or not await _capture_D_ap(garden): return false
	if not await _link_ap(_find_fixed(plan.links,"garden_docks")): return false
	var docks: String="ch4_s2_canal_docks"
	if not await _setup_ap(docks,ap_specs[docks].setup_uv) or not await _walk(ap_specs[docks].input_points,"Original Docks finite ordinary approach") or not await _capture_D_ap(docks): return false
	return check(ap_reached.size()==3 and captures.size()==3 and ap_links.size()==2 and ap_doors_done.is_empty() and ap_dialogues_done.is_empty(),"D remaining3pictures2links only; necessary old joint setup not old AN/main hall replay")

func _run() -> void:
	var began: int=Time.get_ticks_msec()
	deadline=began+1000
	var scope_args: PackedStringArray=OS.get_cmdline_user_args()
	if scope_args.size()==1 and scope_args[0].begins_with("--ap-qa-group="): ap_group=scope_args[0].trim_prefix("--ap-qa-group=")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	output="res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_remaining_fade_history_%s/%d_%d"%[ap_group,OS.get_process_id(),began]
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
	finish(output,began,complete,"AP_BOUNDED_GROUPS_EIGHT_FIELD_FIVE_DOOR_THREE_LINK_ORDINARY_FIXED_SOURCE_MEMORY_POLICIES")
