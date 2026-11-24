extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Root-only future successor. Sole default Quarter entry and explicit test-only
## per-segment inspection placements; never claims continuous city travel.
const ACTUAL_READY: bool=true
const PLAN="res://build/luoyang_city_full_rollout_20261022ap_qa01/artisan_A2_finite_Field_fixture_ROOT16_READY.json"
const PLAN_SHA="ca27d556af87259fcf629ccc71f03c61070aea49468b9dd273754a7a461d26bd"
const ID=&"luoyang_artisan_residential_20261022ap"
const SIZE=Vector2(3072,2048)
const LIMIT_MS=60000
const MAX_PICTURES=2
const DRIVER=preload("res://tests/helpers/v15_input_driver.gd")
const FAMILY_PATH="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
var contract: Dictionary={}
var material_spec: Dictionary={}
var field: Node
var scene: SceneScript
var player: CharacterBody2D
var driver: RefCounted
var native_mask: Image
var requested_usec: int=0
var ready_fact: Dictionary={}
var draw_fact: Dictionary={}
var last_profile: Dictionary={}
var last_preload_metrics: Dictionary={}
var pictures: Array=[]
var physics_queries: int=0
var mask_observations: int=0
var npc_instances: Dictionary={}
var output: String=""

func point(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else Vector2(raw[0],raw[1])

func clock() -> Dictionary:
	return {"usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames()}

func precheck() -> bool:
	if not check(ACTUAL_READY,"NOTREADY: final source owners/deployment not frozen"): return false
	if not track(PLAN,PLAN_SHA): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	if not check(raw is Dictionary and raw.get("ready")==true,"Fixed final A2 finite fixture"): return false
	contract=raw
	if not check(contract.whole_ms==LIMIT_MS and contract.max_pictures==MAX_PICTURES and contract.endpoint_tolerance_px==.3,"Fixed60s/two pictures/original input endpoint"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Ordinary GUI clock/no candidate args"): return false
	if not check(not contract.expected_family_receipt_source_sha256.is_empty(),"Independent complete Family source table, never collector filled"): return false
	for p: String in contract.source_sha256:
		if not track(p,contract.source_sha256[p]): return false
	var spec: Variant=JSON.parse_string(FileAccess.get_file_as_string(contract.material_contract_path))
	if not check(spec is Dictionary and spec.get("scene_id")==String(ID) and spec.get("ground",[]).size()==118 and spec.get("props",[]).size()==14,"Frozen118 ground/14 prop exact identity whitelist"): return false
	material_spec=spec
	return true

func observe() -> void:
	if requested_usec<=0 or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	if current==null or current.scene_id!=ID: return
	if current_scene.has_method("get_field_loading_profile"):
		var profile: Dictionary=current_scene.call("get_field_loading_profile")
		if profile.get("setup_identity_current")==true and profile.get("scene_instance")==current.get_instance_id() and profile.get("Field_instance")==current_scene.get_instance_id(): last_profile=profile
	var metrics: Dictionary=root.get_node("LoadingManager").call("get_field_preload_metrics")
	if metrics.get("scene_id")==String(ID): last_preload_metrics=metrics
	var state: Dictionary=current_scene.call("get_field_loading_state")
	var actor: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if ready_fact.is_empty() and state.get("complete")==true and not state.get("failed",false) and actor!=null and actor.can_process() and actor.get("can_move")==true:
		ready_fact=clock();ready_fact.merge({"elapsed_usec":int(ready_fact.usec)-requested_usec,"Field":current_scene.get_instance_id(),"Scene":current.get_instance_id(),"Player":actor.get_instance_id()})

func post_draw() -> void:
	if requested_usec<=0 or not draw_fact.is_empty() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var actor: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if current==null or current.scene_id!=ID or actor==null or not actor.can_process() or actor.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	var loading: Node=root.get_node("LoadingManager");var screen: Node=loading.get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	if state.get("complete")!=true or state.get("failed",false) or loading.get("_external_active")==true or loading.get("_transition_active")==true or (panel!=null and panel.is_visible_in_tree()): return
	# Timestamp first, before Family receipt copies, hashes or images. Quarter
	# direct entry has no four-city HANDED_OFF/nonzero C-token prerequisite.
	draw_fact=clock();draw_fact.merge({"elapsed_usec":int(draw_fact.usec)-requested_usec,"Field":current_scene.get_instance_id(),"Scene":current.get_instance_id(),"Player":actor.get_instance_id(),"foot":actor.position,"loading_hidden_inactive":true,"can_move":true})

func request_default() -> bool:
	requested_usec=Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",ID,null),"Sole public null/default Quarter request"): return false
	while Time.get_ticks_msec()<deadline:
		observe()
		if not draw_fact.is_empty():
			field=current_scene;scene=field.get("_current_scene") as SceneScript;player=field.get("_player") as CharacterBody2D
			records.append({"kind":"A2_DEFAULT_ENTRY_TIMING","ready":ready_fact,"firstdraw":draw_fact,"Field_profile":last_profile,"LM":last_preload_metrics,"first_under10s":int(draw_fact.elapsed_usec)<10000000,"timings_are_nested_wall_not_additive":true,"token0_not_source_failure_or_fresh_credit":true})
			return true
		await process_frame
	return check(false,"Fixed60s whole/arrival exhausted; no successful loading duration")

func body_query(at: Vector2) -> Array[Dictionary]:
	if not is_instance_valid(player) or not is_instance_valid(field): return [{"invalid_player":true}]
	var shape:=player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or shape.position!=Vector2.ZERO or shape.disabled or not shape.shape is RectangleShape2D or (shape.shape as RectangleShape2D).size!=Vector2(34,24): return [{"invalid_original_body":true}]
	var world: Node2D=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(at)-player.global_position;query.collision_mask=player.collision_mask;query.exclude=[player.get_rid()];query.collide_with_areas=false
	physics_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,16)

func clear_actual(at: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not is_instance_valid(field) or field!=current_scene or native_mask==null: return false
	for offset: Vector2 in [Vector2.ZERO,Vector2(-17,-12),Vector2(17,-12),Vector2(17,12),Vector2(-17,12),Vector2(-17,0),Vector2(17,0),Vector2(0,-12),Vector2(0,12),Vector2(-17,-6),Vector2(17,-6),Vector2(17,6),Vector2(-17,6),Vector2(-8,-12),Vector2(8,-12),Vector2(-8,12),Vector2(8,12)]:
		var px:=Vector2i(at.round()+offset);mask_observations+=1
		if px.x<0 or px.y<0 or px.x>=3072 or px.y>=2048 or native_mask.get_pixelv(px)!=Color.WHITE: return false
	return body_query(at).is_empty()

func source_owner_readonly() -> bool:
	var family: Variant=load(FAMILY_PATH)
	var receipt: Dictionary=family.validation_receipt()
	var sessions: Dictionary=family._sessions
	var stored: Dictionary=sessions.get(scene.get_instance_id(),{})
	if not check(receipt.get("finalized")==true and receipt.get("full_source_hash_passes")==2 and receipt.get("source_first")==contract.expected_family_receipt_source_sha256 and receipt.get("source_final")==contract.expected_family_receipt_source_sha256,"Naturally complete shared Family FIRST/FINAL"): return false
	if not check(stored.get("scene") is WeakRef and stored.get("layout") is WeakRef and stored.scene.get_ref()==scene and stored.layout.get_ref()==scene.map_layout,"Existing exact scene-instance Family session, not scene_id key"): return false
	if not check(scene.resource_path==contract.scene_path and scene.map_layout.resource_path==contract.layout_path and point(field.get("_world_size"))==SIZE,"Exact child native resource/world owner"): return false
	records.append({"kind":"A2_NATURAL_FAMILY_OWNER","serial":receipt.get("serial"),"finalized":true,"source_count":receipt.source_first.size(),"same_weak_scene_layout":true,"no_validation_matches_or_collector_called":true})
	return true

func inspect_start(at: Vector2,label: String) -> bool:
	driver.release_movement()
	var before: Vector2=player.position
	var allowed: bool=clear_actual(at)
	records.append({"kind":"EXPLICIT_TEST_ONLY_INSPECTION_BEFORE","label":label,"before":before,"fixed_start":at,"actual_mask17_and_Physics_clear":allowed,"not_connected_travel":true})
	if not check(allowed,"Fixed inspection start must already be physically clear "+label): return false
	# Sole Root-approved test placement. No Router reload, production movement
	# interface, geometry change, can_move override or implicit route credit.
	player.position=at
	await physics_frame
	await driver.completed_actor_stage()
	var after: Vector2=player.position
	records.append({"kind":"EXPLICIT_TEST_ONLY_INSPECTION_AFTER","label":label,"fixed_start":at,"actual_after_physics":after,"clock":clock(),"not_connected_travel":true})
	return check(after.distance_to(at)<=.3 and clear_actual(after),"Inspection position retained safely by real physics "+label)

func drive(at: Vector2,label: String) -> bool:
	var result: Dictionary=await driver.drive(field,at,clear_actual)
	records.append({"kind":"A2_REAL_INPUT_SHORT_SEGMENT","label":label,"result":result,"source875_not_replayed":true})
	return check(result.get("ok")==true and player.position.distance_to(at)<=.3,"Fixed short INPUT endpoint "+label,result)

func alpha_chain(node: CanvasItem) -> Array:
	var result: Array=[];var current: Node=node
	while current!=null and current!=root:
		if current is CanvasItem: result.append({"name":String(current.name),"modulate_alpha":(current as CanvasItem).modulate.a,"self_modulate_alpha":(current as CanvasItem).self_modulate.a})
		current=current.get_parent()
	return result

func visual_and_people(first: bool) -> bool:
	var objects: Array=field.get("_scene_object_nodes")
	if not check(objects.size()==132,"Actual132 Field sprites, not preview nodes"): return false
	var expected_ground: Dictionary={};var expected_props: Dictionary={};var seen: Dictionary={}
	for row: Dictionary in material_spec.ground: expected_ground["SceneObject_"+String(row.id)]=row
	for row: Dictionary in material_spec.props: expected_props["SceneObject_"+String(row.placement.id)]=row
	var ground: int=0;var opaque: int=0
	for object: Sprite2D in objects:
		var name: String=String(object.name)
		if not check(not seen.has(name),"No duplicate native Sprite identity"): return false
		seen[name]=true
		if expected_ground.has(name):
			ground+=1
			var row: Dictionary=expected_ground[name];var metadata: Dictionary=object.get_meta("ap_a2_exact_use_material",{})
			if not check(object.texture!=null and object.texture.resource_path==row.texture and object.material is ShaderMaterial and (object.material as ShaderMaterial).shader!=null and (object.material as ShaderMaterial).shader.resource_path==contract.material_shader_path and metadata.get("section")==row.section and metadata.get("profile")==row.profile and metadata.get("whole_use_union_exterior")==true,"Exact ground texture/material/profile metadata"): return false
		else:
			opaque+=1
			if not check(expected_props.has(name) and object.texture!=null and object.texture.resource_path==expected_props[name].asset.texture and object.material==null and not object.has_meta("ap_a2_exact_use_material"),"Fourteen exact source props not material-faded"): return false
			for row: Dictionary in alpha_chain(object):
				if not check(row.modulate_alpha==1.0 and row.self_modulate_alpha==1.0,"Opaque prop and ancestor alpha chain",row): return false
	if not check(ground==118 and opaque==14,"Exact118 material+14 opaque split"): return false
	var observed: Array=[]
	for row: Dictionary in contract.npcs:
		var found: Array=[]
		for actor: Node2D in field.get("_npc_nodes"):
			if actor.get("npc_id")==row.id: found.append(actor)
		if not check(found.size()==1,"One real fixed Quarter NPC "+row.id): return false
		var actor: Node2D=found[0];var sprite: Sprite2D=actor.get("sprite") as Sprite2D
		var expected_foot: Vector2=(point(row.foot)/SIZE)*SIZE
		if not check(actor.get("movement_mode")=="idle" and actor.position==expected_foot and sprite!=null and sprite.texture!=null and sprite.texture.resource_path==row.sprite_path and sprite.is_visible_in_tree(),"Real fixed NPC visible source sprite "+row.id): return false
		if first: npc_instances[row.id]=actor.get_instance_id()
		elif not check(npc_instances.get(row.id)==actor.get_instance_id(),"Same original NPC after short checks"): return false
		observed.append({"id":row.id,"instance":actor.get_instance_id(),"foot":actor.position,"texture":sprite.texture.resource_path,"visible":true})
	var world: Node2D=field.get("world_container") as Node2D
	var layer: Node=world.get_node_or_null("LuoyangAPGroundAndUseLayer")
	if not check(layer!=null,"Original ENV layer with stamps, not empty marker"): return false
	var receipt: Dictionary=layer.get_meta("ap_environment_receipt",{})
	if not check(receipt.get("ok")==true and receipt.get("source_hash_passes")==2 and receipt.get("source_first")==receipt.get("source_final") and receipt.has("a2_exact_runtime_material") and not receipt.has("artisan_union_visual_only"),"A2 material exclusive of411B with original ENV FIRST/FINAL"): return false
	var ruts:=layer.get_node_or_null("artisan_service_cart_ruts") as Sprite2D
	if not check(ruts!=null and ruts.texture!=null and ruts.texture.resource_path==contract.rut_texture and ruts.position==Vector2(610,1535) and ruts.scale==Vector2.ONE*.16 and ruts.centered and ruts.material==null,"Original complete-alpha car rut retained"): return false
	records.append({"kind":"A2_REAL132_ENV_AND4PEOPLE","initial":first,"ground":ground,"opaque_props":opaque,"NPCs":observed,"ENV_receipt":receipt,"no_dialog_or_new_animation_credit":true})
	return true

func capture(label: String) -> bool:
	if not check(pictures.size()<MAX_PICTURES and label in ["default_A2_Field_context","rack_front_opaque"],"Only two declared ordinary captures"): return false
	await RenderingServer.frame_post_draw
	var destination: String=output.path_join(label+".png")
	var image: Image=root.get_texture().get_image()
	if not check(image!=null and not FileAccess.file_exists(destination) and image.save_png(destination)==OK,"One ordinary camera image"): return false
	pictures.append({"label":label,"path":destination,"sha256":FileAccess.get_sha256(destination)})
	return true

func exercise_cpu() -> bool:
	if not await request_default(): return false
	driver=DRIVER.new();driver.configure(self)
	if not source_owner_readonly(): return false
	native_mask=field.get("_walkable_mask_image") as Image
	if not check(native_mask!=null and native_mask.get_size()==Vector2i(3072,2048),"Actual existing native Field mask"): return false
	var image: Image=native_mask.duplicate();image.convert(Image.FORMAT_RGBA8)
	var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(image.get_data())
	if not check(digest.finish().hex_encode()==contract.mask_RGBA_sha256,"Installed Field mask exact independent BA3713"): return false
	image=null
	if not check(player.position.distance_to(Vector2(2816,1740))<=.3 and clear_actual(player.position),"Real default foot without near setup"): return false
	if not visual_and_people(true) or not await capture("default_A2_Field_context"): return false
	for row: Dictionary in contract.crossings:
		if not await inspect_start(point(row.first),row.id) or not await drive(point(row.last),row.id): return false
	if not await inspect_start(Vector2(2040,1430),"rack_original_opening"): return false
	for at: Variant in contract.rack_front_route.slice(1):
		if not await drive(point(at),"rack_front"): return false
	var negative: Array[Dictionary]=body_query(Vector2(2470,1436))
	var negative_facts: Array=[]
	for hit: Dictionary in negative:
		var collider: Node=hit.get("collider") as Node
		negative_facts.append({"collider_instance":collider.get_instance_id() if collider!=null else 0,"name":String(collider.name) if collider!=null else "","authoring_id":collider.get_meta("authoring_id","") if collider!=null else "","ap_exact_native_geometry":collider.get_meta("ap_exact_native_geometry",false) if collider!=null else false})
	records.append({"kind":"A2_RACK_EXACT_NEGATIVE_ACTUAL","target":[2470,1436],"hits":negative_facts})
	if not check(not negative.is_empty(),"Rack target-only negative is blocked"): return false
	for hit: Dictionary in negative:
		var collider: Node=hit.get("collider") as Node
		if not check(collider!=null and collider.get_meta("authoring_id","")=="ap_cloth_rack_v2_hull_0" and collider.get_meta("ap_exact_native_geometry",false)==true,"Negative hits exact real rack native collider"): return false
	var before: Vector2=player.position;var observed: Array=[]
	Input.action_press("move_up")
	for tick: int in 24:
		await physics_frame
		if Time.get_ticks_msec()>=deadline or not is_instance_valid(player): break
		observed.append(player.position)
		if not clear_actual(player.position):
			driver.release_movement()
			records.append({"kind":"A2_RACK_BLOCK_PARTIAL_FAILURE","before":before,"actual_foot":player.position,"physics_positions":observed,"negative_hits":negative_facts})
			return check(false,"Stopped real body never penetrates rack",{"actual_foot":player.position,"observed_samples":observed.size()})
	driver.release_movement();await driver.completed_actor_stage()
	if not check(player.position.y<before.y-.3 and player.position.y>1436 and clear_actual(player.position),"Actual north movement stopped in front of rack"): return false
	records.append({"kind":"A2_RACK_REAL_BLOCK","before":before,"after":player.position,"physics_positions":observed,"negative_source_target":[2470,1436]})
	if not await capture("rack_front_opaque") or not visual_and_people(false) or not source_owner_readonly(): return false
	records.append({"kind":"A2_FINITE_SCOPE","ready":ready_fact,"firstdraw":draw_fact,"Field_profile":last_profile,"pictures":pictures,"Physics_queries":physics_queries,"mask17_observations":mask_observations,"no_connected_cross_region_travel_credit":true,"no_global_ghost_false_expectation":true,"no_875_geometry_replay":true})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	output="res://build/luoyang_city_full_rollout_20261022ap_qa01/artisan_A2_finite_Field_ROOT16_READY/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	RenderingServer.frame_post_draw.connect(post_draw)
	var complete: bool=false
	if precheck(): complete=await exercise_cpu()
	if driver!=null: driver.release()
	if RenderingServer.frame_post_draw.is_connected(post_draw): RenderingServer.frame_post_draw.disconnect(post_draw)
	finish(output,began,complete,"A2_ONLY_DEFAULT_QUARTER_AND_EXPLICIT_INSPECTION_START_SHORT_INPUT_NOT_CONNECTED_TRAVEL")
