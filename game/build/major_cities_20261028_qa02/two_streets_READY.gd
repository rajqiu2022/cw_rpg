extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## Root-only single incremental probe + two streets' continuous real INPUT.
const NEW_FIXTURE := "res://build/major_cities_20261028_qa02/two_streets_READY.json"
const NEW_OUTPUT := "res://build/major_cities_20261028_qa02/actual/"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(NEW_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FROZEN_INCREMENTAL_ONLY"):finish();return
	spec=raw
	if not check(spec.whole_seconds==60 and spec.entry_seconds==20 and spec.max_png==1,"ONE_60S_ONE_PNG"):finish();return
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(baseline.save15.keys())
	for path: String in spec.fixed_sources:check(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	if not errors.is_empty():finish();return
	if not static_incremental_probe():finish();return
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"):finish();return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	state_before=business_state()
	if not check(sr.call("go_field_smart",StringName(spec.city_id),point(spec.public_setup_foot)/point(spec.get("size")),"",-1,29)==true,"EXPLICIT_PUBLIC_SETUP_NOT_DEFAULT_TRAVEL"):finish();return
	var field: Node=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(point(spec.public_setup_foot))<=1.0,"ORIGINAL_FIELD_EXPLICIT_VERSION29_SETUP"):finish();return
	var debug: Dictionary=field.call("get_bianzhou_debug")
	if not check(debug.layout_version==29 and (sr.get("_local_layout_versions") as Dictionary).get(spec.city_id)==29,"NATURAL_REVISION29_RUNTIME_NO_VERSION_DICT_WRITE"):finish();return
	var author: Variant=load(spec.author)
	var new_rows: Array=author.new_occupancy_rows()
	for row: Dictionary in new_rows:
		var sprites: Array=[]
		for object: Node in field.get("_scene_object_nodes"):
			if object.name=="BianzhouObject_"+String(row.id):sprites.append(object)
		if not check(sprites.size()==1,"NEW_RENDER_ROW_ONCE:"+String(row.id)):finish();return
		var target: Vector2=(row.body as Rect2).get_center()
		var query:=PhysicsPointQueryParameters2D.new();query.position=(field.get("world_container") as Node2D).to_global(target);query.collision_mask=1;query.collide_with_bodies=true;query.collide_with_areas=false
		if not check(not field.get_viewport().world_2d.direct_space_state.intersect_point(query).is_empty(),"NEW_BODY_ACTUALLY_INSTALLED:"+String(row.id)):finish();return
	var identity_before: Dictionary={"field":str(field.get_instance_id()),"player":str((field.get("_player") as Node).get_instance_id()),"camera":str((field.get("_world_camera") as Node).get_instance_id())}
	if not await walk_route(field,spec.first_street_route):finish();return
	if not await capture_new(field):finish();return
	if not await walk_route(field,spec.second_street_route):finish();return
	var identity_after: Dictionary={"field":str(field.get_instance_id()),"player":str((field.get("_player") as Node).get_instance_id()),"camera":str((field.get("_world_camera") as Node).get_instance_id())}
	check(identity_before==identity_after,"TWO_STREETS_SAME_FIELD_PLAYER_CAMERA_NO_SECOND_SETUP")
	check(business_state()==state_before,"NO_DIALOG_SHOP_QUEST_OR_ECONOMY_MUTATION")
	check(active(),"ONE_INCREMENTAL_60S_NO_EXTENSION")
	finish()

func static_incremental_probe() -> bool:
	var author: Variant=load(spec.author)
	var prior: Variant=load(spec.prior_author)
	if not check(author!=null and prior!=null and author.VERSION==29 and prior.VERSION==28,"ONLY_28_TO29_NEW_OCCUPANCY"):return false
	var rows: Array=author.new_occupancy_rows()
	if not check(rows.size()==16 and author.neighborhood_buildings().size()==2 and author.neighborhood_goods().size()==14,"EXACT_TWO_BUILDINGS_FOURTEEN_GOODS"):return false
	check(author.building_specs().slice(0,prior.building_specs().size())==prior.building_specs(),"OLD_TWENTY_ONE_BUILDINGS_TYPED_IDENTICAL")
	check(author.prop_specs().slice(0,prior.prop_specs().size())==prior.prop_specs(),"OLD_PROPS_TYPED_IDENTICAL")
	check(author.npc_rows()==prior.npc_rows() and author.roads()==prior.roads(),"ORIGINAL_NPCS_AND_ROADS_TYPED_IDENTICAL")
	var newer: Resource=author.layout();var older: Resource=prior.layout()
	check(newer.get("portals")==older.get("portals") and newer.get("interactions")==older.get("interactions"),"ORIGINAL_PORTALS_AND_BOARD_TYPED_IDENTICAL_NOT_REPLAYED")
	var ids: Dictionary={}
	var old_bodies: Array=prior.building_specs();old_bodies.append_array(prior.prop_specs())
	for row: Dictionary in rows:
		check(not ids.has(row.id),"UNIQUE_NEW_ID:"+String(row.id));ids[row.id]=true
		var body: Rect2=row.body
		check(body.size.x>0 and body.size.y>0 and author.safe_foot(row.migration_lane_foot/author.SIZE),"POSITIVE_BODY_AND_SAFE_REGISTERED_LANE:"+String(row.id))
		if row.has("source_body_px"):
			var local: Rect2=row.source_body_px
			var expected_bounds: Array=spec.source_bounds_by_file.get(String(row.texture).get_file(),[])
			check(expected_bounds.size()==4 and local==Rect2(float(expected_bounds[0]),float(expected_bounds[1]),float(expected_bounds[2]),float(expected_bounds[3])),"INDEPENDENT_ART_APPROVED_SOURCE_BOUNDS:"+String(row.id))
			var source_foot: Vector2=point(row.source_foot_px)
			var expected:=Rect2(row.foot+(local.position-source_foot)*float(row.native_scale),local.size*float(row.native_scale))
			check(body==expected,"EXACT_SOURCE_BOUND_TRANSFORM_NOT_CENTER_GUESS:"+String(row.id))
		var probes: Array[Vector2]=[body.get_center(),Vector2(body.position.x,body.get_center().y),Vector2(body.end.x,body.get_center().y),Vector2(body.get_center().x,body.position.y),Vector2(body.get_center().x,body.end.y)]
		for foot: Vector2 in probes:
			check(not author.safe_foot(foot/author.SIZE,false),"FULL_BODY_INNER_OR_EDGE_REJECT:"+String(row.id))
		var center: Vector2=body.get_center()/author.SIZE
		var expected_lane: Vector2=Vector2(INF,INF)
		var actor:=Rect2(center*author.SIZE-Vector2(17,12),Vector2(34,24))
		for entry: Dictionary in rows:
			if actor.intersects(entry.body,true):expected_lane=entry.migration_lane_foot/author.SIZE;break
		var actual: Variant=author.migration(center,28)
		check(actual is Vector2 and actual==expected_lane and author.safe_foot(actual),"PROTECTED_28_CENTER_USES_FIRST_EXPLICIT_SAFE_LANE:"+String(row.id))
		check(author.migration(center,29)==center,"NATIVE29_NOT_SILENTLY_REMAPPED:"+String(row.id))
		for old_row: Dictionary in old_bodies:
			if old_row.has("body"):check(not body.intersects(old_row.body),"NEW_BODY_NOT_OVER_OLD_BODY:"+String(row.id)+":"+String(old_row.id))
		for other: Dictionary in rows:
			if String(other.id)>String(row.id):check(not body.intersects(other.body),"NEW_BODIES_DO_NOT_OVERLAP:"+String(row.id)+":"+String(other.id))
	for raw_point: Array in spec.retained_feet:
		var foot: Vector2=point(raw_point)
		check(author.safe_foot(foot/author.SIZE) and author.migration(foot/author.SIZE,28)==foot/author.SIZE,"LIMITED_LEGAL_ENTRY_OR_SERVICE_FOOT_PRESERVED:"+str(foot))
	for npc: Dictionary in author.npc_rows():
		if npc.npc_id in spec.affected_npc_ids:check(author.safe_foot(npc.pos,false),"NEW_BODY_NOT_ON_RETAINED_NPC:"+String(npc.npc_id))
	for unknown: int in [0,27,30]:check(author.migration(Vector2(.5,.5),unknown)==null,"UNKNOWN_VERSION_REJECT:"+str(unknown))
	for legacy: Array in [[.505,.9],[.5,.18],[.3,.52]]:
		var uv: Vector2=point(legacy)
		var old_projection: Variant=prior.migration(uv,1)
		var actual: Variant=author.migration(uv,1)
		check(old_projection is Vector2 and actual==author.migration(old_projection,28),"V1_PROJECTION_THEN_SAME_INCREMENTAL_MIGRATION")
	var points: Array=[spec.public_setup_foot]
	points.append_array(spec.first_street_route);points.append_array(spec.second_street_route)
	for index: int in range(points.size()-1):
		var a: Vector2=point(points[index]);var b: Vector2=point(points[index+1])
		var count: int=maxi(1,ceili(a.distance_to(b)/32.0))
		for sample: int in range(count+1):
			if not check(author.safe_foot(a.lerp(b,float(sample)/count)/author.SIZE),"AFFECTED_SERVICE_ROUTE_FULL34X24_ONLY"):return false
	records.append({"incremental_rows":rows.size(),"retained_feet":spec.retained_feet,"migration_scope":"Only 16 new footprints; not the entire old safe set"})
	return errors.is_empty()

func capture_new(_field: Node) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=NEW_OUTPUT+str(OS.get_process_id())+"/two_streets.png"
	if not check(png_count==0 and image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL_NATIVE_1920_1080_PNG"):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not check(image.save_png(path)==OK,"NEW_NATIVE_PNG_SAVED"):return false
	png_count=1;records.append({"png":path,"sha256":FileAccess.get_sha256(path),"qa_camera_or_pose_writes":0});return true

func finish() -> void:
	release_input()
	if not source_before.is_empty():check(source_before==file_facts(source_before.keys()),"SMALL_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():check(save_before==file_facts(save_before.keys()),"REGISTERED_SAVE15_HASH_BYTES_SECONDS_SAME_ROOT_TICKS_SEPARATE")
	var path: String=NEW_OUTPUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"png_count":png_count,"records":records,"fixture_sha256":FileAccess.get_sha256(NEW_FIXTURE),"qa_actor_or_camera_writes":0,"save_writes":0,"repeated_old_travel_dialog_shop_tests":false},"\t"));file.close()
	print("[BianzhouTwoStreets] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
