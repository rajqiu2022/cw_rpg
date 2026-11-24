extends "res://tests/test_luoyang_loading_baseline_ready_20261018r.gd"
## NOTREADY: exact same inherited first-draw callback/actions/160s/60s/warm2s.
## All added streaming/bundle correctness work is AFTER the draw timestamp.
const CANDIDATE_READY=false
const CANDIDATE_CORE_PATH="PENDING_FINAL_CANDIDATE_CORE_SNAPSHOT"
const CANDIDATE_CORE_SHA="PENDING_FINAL_CANDIDATE_CORE_SHA"
const BASELINE_RESULT_PATH="res://build/luoyang_loading_baseline_20261018r/111456_2847/result.json"
const BASELINE_RESULT_SHA="29ee73ffe7e21f16afefbb9e7c101ee3e0ebdb7a9d3d6d7b83692a5667075386"
const BASELINE_MAP_PATH="res://build/luoyang_loading_baseline_20261018r/111456_2847/baseline_expected_current_sources.json"
const BASELINE_MAP_SHA="aff671d2f485a8c4b61c049bcd053b59773fd5df0f3d7e2f734ab75adfeea516"
const EXPECTED_SOURCE_CHANGES={} # {path:{old:baselineSHA,new:approvedSHA}}
const EXPECTED_ADDED_SOURCES={} # All NEW helper/index/manifest/artifact leaves.
const BUNDLE_KIND="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1"
const BUNDLE_FLAG="--luoyang-precomputed-bundle-20261018r"
const STREAM_PATH="res://scripts/world/world_v15_visible_stream_20261018r.gd"
const VIEW_ORACLE=preload("res://tests/helpers/world_viewport_independent_oracle_20261018r.gd")
const VIEW_ORACLE_SHA="f0a43f79410df6a3da8a990807fed15cc41d7e60b392d40eddd5f8838e1b35bb"
var approved_sources: Dictionary={}
var world_previous_required: Dictionary={}
var world_selection_changes: int=0
var world_checks: int=0
var stream_api: Variant

func precheck() -> bool:
	if not check(CANDIDATE_READY and not EXPECTED_SOURCE_CHANGES.is_empty() and not EXPECTED_ADDED_SOURCES.is_empty(),"NOTREADY pending actual publication/current source-delta freeze"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args()==PackedStringArray([BUNDLE_FLAG]) and LEASE.LIVE_WORLD_FORMAL_ENABLED,"Real GPU/native clock; exact sole bundle candidate flag"): return false
	if not track(CANDIDATE_CORE_PATH,CANDIDATE_CORE_SHA) or not track(BASELINE_RESULT_PATH,BASELINE_RESULT_SHA) or not track(BASELINE_MAP_PATH,BASELINE_MAP_SHA): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_CORE_PATH))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track("res://tests/helpers/world_viewport_independent_oracle_20261018r.gd",VIEW_ORACLE_SHA) or not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	approved_sources=JSON.parse_string(FileAccess.get_file_as_string(BASELINE_MAP_PATH))
	for path: String in EXPECTED_SOURCE_CHANGES:
		var change: Dictionary=EXPECTED_SOURCE_CHANGES[path]
		if not check(change.size()==2 and approved_sources.get(path)==change.old and String(change.new).length()==64,"Explicit authorized baseline-old -> candidate-new SHA "+path): return false
		approved_sources[path]=change.new
	for path: String in EXPECTED_ADDED_SOURCES:
		if not check(not approved_sources.has(path) and String(EXPECTED_ADDED_SOURCES[path]).length()==64,"Exact NEW source authority/artifact leaf, not overwritten legacy "+path): return false
		approved_sources[path]=EXPECTED_ADDED_SOURCES[path]
	stream_api=load(STREAM_PATH)
	package=R.binding();author=R.author(package)
	return check(stream_api!=null and not package.is_empty() and not author.is_empty(),"Actual frozen streamer and unchanged district geometry")

func _post_gate(warm: bool) -> bool:
	# Super preserves the same frozen first-draw instrumentation and performs
	# full current collector/independent disk checks only AFTER that freeze.
	if not super._post_gate(warm): return false
	var ready: Dictionary=C._resident_ready
	if not check(ready.get("proof_kind")==BUNDLE_KIND and C._equal_value(baseline_sources,approved_sources),"Actual published-native proof kind and COMPLETE baseline+authorized-delta map exact; not fresh runtime geometry"): return false
	records.append({"kind":"BUNDLE_PROOF_SCOPE","warm":warm,"proof_kind":ready.get("proof_kind"),"full_geometry_rerun_at_runtime":false,"full_original_source_first_final_preserved":true,"expected_source_count":approved_sources.size(),"source_changes":EXPECTED_SOURCE_CHANGES,"added_leaves":EXPECTED_ADDED_SOURCES})
	return true

func _world_bind() -> bool:
	if not super._world_bind(): return false
	return _world_actual("BIRTH_AFTER_FIRST_DRAW")

func _world_actual(label: String) -> bool:
	var began: int=Time.get_ticks_usec()
	var world: Node2D=field.get("world_container") as Node2D
	var live: Dictionary=field.call("get_world_v15_stream_debug")
	var view: Rect2=VIEW_ORACLE.visible_world_rect(world,root.get_visible_rect())
	var expected: Dictionary=VIEW_ORACLE.selection(scene.map_layout.visual_objects,Vector2(12288,8192),view)
	if not check(expected.get("ok")==true and expected.entries.size()==2687 and live.get("index_count")==2687 and String(live.get("error","")).is_empty(),"Independent whole-source render geometry and active streamer identity"): return false
	var actual: Dictionary={};var ids: Array=[]
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		var id: String=String(sprite.name).trim_prefix("SceneObject_")
		if not check(String(sprite.name).begins_with("SceneObject_") and not actual.has(id),"Every actual streamed visual has one original unique identity",id): return false
		actual[id]=sprite;ids.append(id)
	var answer: Dictionary=VIEW_ORACLE.actual_sets(expected,ids,false)
	if not check(answer.ok,"512px required subset /1024px allowed retain; no global Sprite-count shortcut",answer): return false
	var overlap: RefCounted=field.get("_v14_modular_overlap")
	var ordinals: Dictionary={};var ordinal: int=0
	for entry: Dictionary in scene.map_layout.visual_objects:
		if bool(entry.get("sort_by_feet",false)): ordinals[String(entry.id)]=ordinal;ordinal+=1
	var depth: Dictionary={}
	for row: Dictionary in overlap.call("get_depth_order_state"):
		if row.get("actor")==false: depth[String(row.id)]=row
	var images: Dictionary={};var texture_rows: Array[Dictionary]=[]
	for id: String in actual:
		var sprite: Sprite2D=actual[id]
		var entry: Dictionary=expected.entries[id].entry
		if not check(sprite.texture!=null and sprite.texture.resource_path==String(entry.texture) and sprite.position==(entry.pos as Vector2)*Vector2(12288,8192) and sprite.scale==(entry.render_size_px as Vector2)/Vector2(sprite.texture.get_size()) and sprite.centered==bool(entry.get("centered",true)) and sprite.rotation_degrees==float(entry.get("rotation",0.0)) and sprite.visible and sprite.modulate==entry.get("modulate",Color.WHITE) and sprite.self_modulate==Color.WHITE and sprite.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"Exact original resident texture/placement/alpha/render fields "+id): return false
		if ordinals.has(id) and not check(depth.has(id) and int(depth[id].stable_ordinal)==int(ordinals[id]),"Stream attach preserves ORIGINAL all-source ordinal, not current attach order "+id): return false
		var texture_id: int=sprite.texture.get_instance_id()
		if not images.has(texture_id):
			var image: Image=sprite.texture.get_image()
			if image!=null and image.is_compressed() and image.decompress()!=OK: return check(false,"Actual streamed texture decode failed")
			if not check(image!=null and image.get_size()==Vector2i(sprite.texture.get_size()),"Actual resident native image dimensions"): return false
			images[texture_id]=image
			texture_rows.append({"texture":sprite.texture.resource_path,"texture_id":texture_id,"size":image.get_size(),"format":image.get_format(),"image_sha256":C._transition_bytes_sha(image.get_data())})
		if ordinals.has(id):
			var cached: Image=overlap.get("_images").get(texture_id)
			if not check(cached!=null and cached.get_size()==images[texture_id].get_size() and cached.get_format()==images[texture_id].get_format() and cached.get_data()==images[texture_id].get_data(),"Current resident overlap alpha image exact actual texture bytes, not stale evicted data "+id): return false
	if not _all_world_bodies_and_portals(): return false
	if not world_previous_required.is_empty() and not C._equal_value(world_previous_required,expected.required512): world_selection_changes+=1
	world_previous_required=expected.required512.duplicate()
	world_checks+=1
	records.append({"kind":"WORLD_STREAM_INDEPENDENT_POSTDRAW","label":label,"post_draw_QA_usec":Time.get_ticks_usec()-began,"view_world_rect":view,"required512":expected.required512.keys(),"allowed1024_count":expected.allowed1024.size(),"actual_ids":ids,"actual_texture_images":texture_rows,"stream_state":live,"whole_physical_objects":2322,"whole_portal_areas":16,"selection_changes_after_normal_INPUT":world_selection_changes,"image_checks_not_a_new_raw_import_publication":true})
	return true

func _all_world_bodies_and_portals() -> bool:
	var size:=Vector2(12288,8192)
	var actual: Dictionary={}
	for body: StaticBody2D in field.get("_collision_bodies"):
		if String(body.name).begins_with("ObjectCollision_"):
			var id: String=String(body.name).trim_prefix("ObjectCollision_")
			if not check(not actual.has(id),"Unique whole-world physical body "+id): return false
			actual[id]=body
	var count: int=0
	for entry: Dictionary in scene.map_layout.visual_objects:
		if not entry.has("solid_polygons_px") and not entry.has("collision_size"): continue
		var id: String=String(entry.id);count+=1
		if not check(actual.has(id),"Full authoritative world body exists even OUTSIDE visual window "+id): return false
		var body: StaticBody2D=actual[id]
		var position: Vector2=entry.pos*size
		if not check(body.position==position and body.collision_layer==1 and body.collision_mask==0 and PhysicsServer2D.body_get_space(body.get_rid()).is_valid(),"Original whole physical foot/layer/active space "+id): return false
		if entry.has("solid_polygons_px"):
			if not check(body.get_child_count()==entry.solid_polygons_px.size(),"Every original polygon child retained "+id): return false
			for index: int in entry.solid_polygons_px.size():
				var expected:=PackedVector2Array()
				for point: Vector2 in entry.solid_polygons_px[index]: expected.append(point-position)
				var polygon:=body.get_child(index) as CollisionPolygon2D
				if not check(polygon!=null and not polygon.disabled and polygon.position==Vector2.ZERO and polygon.polygon==expected,"Full native physical polygon exact "+id): return false
		else:
			var shape:=body.get_child(0) as CollisionShape2D
			if not check(body.get_child_count()==1 and shape!=null and shape.shape is RectangleShape2D and not shape.disabled and shape.position==entry.get("collision_offset",Vector2.ZERO)*size and (shape.shape as RectangleShape2D).size==(entry.collision_size as Vector2)*size,"Full native rectangle/offset exact "+id): return false
	if not check(count==2322 and actual.size()==2322 and scene.map_layout.portals.size()==16 and field.get("_exit_nodes").size()==16,"All2322 physical objects and16Areas unchanged independently of streamed residency"): return false
	for entry: Dictionary in scene.map_layout.portals:
		var matches: Array=[];var foot: Vector2=entry.pos*size
		for zone: Node2D in field.get("_exit_nodes"):
			if zone.position==foot: matches.append(zone)
		if not check(matches.size()==1,"Each original portal has exact native position "+String(entry.id)): return false
		var zone: Area2D=matches[0]
		var polygon:=zone.get_node_or_null("DoorwayPolygon") as CollisionPolygon2D
		var expected:=PackedVector2Array()
		for point: Vector2 in entry.passage_polygon_px: expected.append(point-foot)
		if not check(zone.get_script().resource_path=="res://scripts/field/world_v15_exit_zone.gd" and polygon!=null and polygon.polygon==expected and zone.get("_doorway_polygon")==expected and zone.get("target_spawn_pos")==entry.get("target_pos",Vector2(.5,.5)) and (zone.get("is_locked")==true or (String(zone.get("target_scene_id"))==String(entry.get("target_scene","")) and String(zone.get("action"))==String(entry.get("action","")))),"Exact original portal polygon/target; streaming cannot remove/reshape an offscreen entrance "+String(entry.id)): return false
	return true

func _walk(points: PackedVector2Array) -> bool:
	if not await super._walk(points): return false
	if scene==null or String(scene.scene_id)!=WORLD_ID: return true
	# Movement may have shifted the prefetch window. Wait for that pending
	# correctness set only AFTER timing freeze, within the original whole budget.
	var settled: bool=false
	var last: Dictionary={}
	while Time.get_ticks_msec()<deadline:
		await RenderingServer.frame_post_draw # Actual Camera canvas has updated.
		var state: Dictionary=field.call("get_world_v15_stream_debug")
		if not String(state.get("error","")).is_empty(): return check(false,"World streamer error during original96px route",state)
		var world: Node2D=field.get("world_container") as Node2D
		var view: Rect2=VIEW_ORACLE.visible_world_rect(world,root.get_visible_rect())
		var expected: Dictionary=VIEW_ORACLE.selection(scene.map_layout.visual_objects,Vector2(12288,8192),view)
		if not check(expected.get("ok")==true,"Independent postdraw selection remains well-formed"): return false
		var actual_ids: Array=[]
		for sprite: Sprite2D in field.get("_scene_object_nodes"): actual_ids.append(String(sprite.name).trim_prefix("SceneObject_"))
		var sets: Dictionary=VIEW_ORACLE.actual_sets(expected,actual_ids,false)
		last={"sets":sets,"stream":state,"frame":Engine.get_process_frames(),"view":view}
		if sets.ok and int(state.get("pending",0))==0 and int(state.get("broker_outstanding",0))==0:
			settled=true;break
	if not check(settled,"Original whole budget: independent512 coverage+1024 allowed set AND loader drain; pending0 alone never proves complete",last): return false
	return _world_actual("AFTER_ORIGINAL_NORMAL_INPUT_WINDOW_SHIFT")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+160000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_loading_candidate_20261018r/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		RenderingServer.frame_post_draw.connect(_r_draw)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
	draw_target=""
	if RenderingServer.frame_post_draw.is_connected(_r_draw): RenderingServer.frame_post_draw.disconnect(_r_draw)
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	while stream_api!=null and stream_api.drain_count()>0 and Time.get_ticks_msec()<deadline: await process_frame
	if stream_api!=null and not check(stream_api.drain_count()==0,"Owned exit consumes abandoned world requests; drain0 within original160s"): complete=false
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;retained=null;retained_scene=null;retained_oracle=null;retained_static.clear();retained_nav.clear();retained_crowd.clear();frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":160000,"arrival_ms":60000,"strict_warm_usec":2000000,"captures":captures,"native_queries":native_queries,"world_postdraw_checks":world_checks,"selection_changes_after_original96px":world_selection_changes,"same_inherited_R_firstdraw_instrument":true,"added_world_correctness_after_freeze_not_Loading":true,"runtime_bundle_not_fresh_geometry":true,"one_Gate_cold_real_world_warm_no_Market_performance_credit":true})
	finish(folder,began,complete,"R_BUNDLE_CANDIDATE_SAME_TIMING_WITH_WORLD_VIEW_AND_FULL_PHYSICS")
