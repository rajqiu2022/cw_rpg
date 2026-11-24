extends "res://build/luoyang_city_revision_20261024c_qa01/finite_Field_NOTREADY/common.gd"
## Only the new source bridge: one explicit approach, one straight real crossing.
const READY25H=false
const FIXTURE25H="PENDING_SOURCE25H_GARDEN_FINAL_FIXTURE"
const FIXTURE_SHA25H="PENDING_SOURCE25H_GARDEN_FINAL_FIXTURE_SHA"
const FAMILY25H=preload("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
const GARDEN25H=&"luoyang_riverside_garden_20261022ap"
var garden_refs25h: Array=[]
func precheck() -> bool:
	if not check(READY25H and track(FIXTURE25H,FIXTURE_SHA25H),"Hardfalse until Source final native/Family expectation and Root deployment"): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE25H))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("formal_deployed")==true,"Independent final Garden fixture only"): return false
	fixture=raw
	if not check(fixture.whole_ms==60000 and fixture.entry_ms==20000 and fixture.max_pictures==0 and _v(fixture.approach_px)==Vector2(880,976) and _v(fixture.midpoint_px)==Vector2(1536,976) and _v(fixture.end_px)==Vector2(2192,976),"Root sole bridge approach and identical straight route;60/20/zero actual pictures"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	return check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty() and root.get_visible_rect().size==Vector2(1920,1080),"Original GUI only, no import or camera override")
func _natural25h() -> bool:
	var receipt: Dictionary=FAMILY25H._receipt
	var session: Dictionary=FAMILY25H._sessions.get(scene.get_instance_id(),{})
	return check(current_scene==field and scene.scene_id==GARDEN25H and receipt.get("finalized")==true and receipt.get("source_first",{})==fixture.expected_family_sources and receipt.get("source_final",{})==fixture.expected_family_sources and receipt.get("full_source_hash_passes")==2 and session.get("scene") is WeakRef and session.get("layout") is WeakRef and session.scene.get_ref()==scene and session.layout.get_ref()==scene.map_layout,"Passive natural Family FIRST/FINAL and exact live native owners; no matches/collector invoked by QA")
func _objects25h() -> bool:
	var base: Sprite2D=null;var rail: Sprite2D=null
	for node: Sprite2D in field.get("_scene_object_nodes"):
		if String(node.name)=="SceneObject_garden_stone_bridge_walkable_25h": base=node
		if String(node.name)=="SceneObject_garden_stone_bridge_front_rail_25h": rail=node
	var raw: Dictionary=scene.get_meta("ap_garden_river25h",{})
	if not check(base!=null and rail!=null and base.get_parent()==field.get("_visual_layer") and base.z_index==-17 and rail.get_parent()==field.get("_actor_layer") and base.is_visible_in_tree() and rail.is_visible_in_tree() and base.modulate.a==1.0 and rail.modulate.a==1.0,"Whole actual unchanged bridge is ground-layer; original rail is separate native foreground, not full-bridge ghost"): return false
	if not check(base.texture!=null and base.texture.resource_path==fixture.bridge_png and base.position==_v(fixture.bridge_position_px) and base.scale==_v(fixture.bridge_scale) and rail.position==_v(fixture.rail_position_px) and rail.scale==_v(fixture.rail_scale) and rail.texture is AtlasTexture,"Exact source-f32 bridge and rail native transforms"): return false
	var atlas: AtlasTexture=rail.texture as AtlasTexture
	if not check(atlas.atlas!=null and atlas.atlas.resource_path==fixture.bridge_png and atlas.region==Rect2(200,522,1374,208) and atlas.margin==Rect2() and atlas.filter_clip and raw.get("whole_bridge_below_actors")==true and raw.get("physics_is_visual_water_minus_visible_deck")==true and raw.get("physics_pieces",[]).size()==2,"Native original-UV rail rectangle and two physical water-minus-deck pieces; no new image crop/edit"): return false
	var group: Node=field.get("_collision_layer").get_node_or_null("APNativeObstacles")
	if not check(group!=null,"Actual native obstacle group installed by production"): return false
	var found: int=0
	for body: Node in group.get_children():
		var id: String=String(body.get_meta("authoring_id",""))
		if not id.begins_with("garden_river_minus_deck_"): continue
		if not check(found<2 and found<raw.physics_pieces.size(),"No extra water body beyond the two-piece source contract"): return false
		if not check(body is StaticBody2D and body.collision_layer==1 and body.get_child_count()==1 and body.get_child(0) is CollisionPolygon2D and not body.get_child(0).disabled and body.get_child(0).polygon==raw.physics_pieces[found],"Only the two actual new river bodies equal source native metadata"): return false
		found+=1
	if not check(found==2,"Exactly two water bodies, bridge deck not blocked by full old water body"): return false
	records.append({"kind":"25H_REAL_GARDEN_BRIDGE_NATIVE_LAYER_AND_ATLAS","base":_id(base),"rail":_id(rail),"base_z":base.z_index,"rail_z":rail.z_index,"deck":raw.get("deck"),"actual_water_bodies":found,"no_front_rail_alpha_overlap_credit_on_route_y976":true})
	return true
func _water_negative25h(foot: Vector2) -> bool:
	var raw: Dictionary=scene.get_meta("ap_garden_river25h",{})
	if not check(raw.get("polygon") is PackedVector2Array and raw.get("deck") is Rect2 and Geometry2D.is_point_in_polygon(foot,raw.polygon) and not raw.deck.has_point(foot),"Fixed source water negative outside visible bridge deck"): return false
	var p: CharacterBody2D=_player();var shape: CollisionShape2D=p.get_node("CollisionShape2D") as CollisionShape2D
	if not check(shape!=null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24),"Original city body34x24 for water negative"): return false
	var mask: Image=field.get("_walkable_mask_image") as Image
	var pixel: Vector2i=Vector2i((foot/Vector2(3072,2048)*Vector2(mask.get_size())).round()) if mask!=null else Vector2i(-1,-1)
	if not check(mask!=null and pixel.x>=0 and pixel.y>=0 and pixel.x<mask.get_width() and pixel.y<mask.get_height() and mask.get_pixelv(pixel).r<.5,"Actual cached mask denies fixed water negative, no PNG decode or full raster replay"): return false
	mask_samples+=1
	var q:=PhysicsShapeQueryParameters2D.new();q.shape=shape.shape;q.transform=shape.global_transform
	q.transform.origin+=(field.get("world_container") as Node2D).to_global(foot)-p.global_position;q.exclude=[p.get_rid()];q.collision_mask=p.collision_mask;q.collide_with_areas=false;physics_queries+=1
	var hits: Array=p.get_world_2d().direct_space_state.intersect_shape(q,16);var water_hit: bool=false
	for hit: Dictionary in hits:
		var collider: Object=hit.get("collider")
		if collider is StaticBody2D and String(collider.get_meta("authoring_id","")).begins_with("garden_river_minus_deck_"): water_hit=true
	records.append({"kind":"25H_SOURCE_WATER_NEGATIVE_REAL_BODY_QUERY_NO_PLAYER_WRITE","foot":foot,"pixel":pixel,"specific_water_body_hit":water_hit})
	return check(water_hit,"Real new river body also denies fixed water negative, not just mask")
func _picture25h() -> bool:
	return check(pictures==0 and int(fixture.max_pictures)==0 and not String(fixture.inherited_source_art_receipt).is_empty(),"Root approved native overview inherited by exact source pin; zero actual PNG readback or camera change")
func exercise_cpu() -> bool:
	if not check(root.get_node("SceneRouter").call("go_field_smart",GARDEN25H,_v(fixture.approach_uv)),"Explicit source bridge approach QA setup, not default travel or performance") or not await _arrive(GARDEN25H,20000,"25H_ONE_NEW_BRIDGE_EXPLICIT_APPROACH_NOT_DEFAULT"): return false
	if not check(scene.resource_path==fixture.scene_path and scene.map_layout.resource_path==fixture.layout_path and _player().position==_v(fixture.approach_position_px),"Exact source native identity/approach f32, no private Player position write") or not _natural25h() or not _objects25h(): return false
	garden_refs25h=[weakref(field),weakref(_player()),weakref(scene),weakref(scene.map_layout)]
	for foot: Vector2 in [Vector2(1536,800),Vector2(1536,1200)]:
		if not _water_negative25h(foot): return false
	if not await _walk([fixture.approach_position_px,fixture.midpoint_px],"25H_TRUE_INPUT_WEST_SHORE_TO_BRIDGE_MIDPOINT") or not await _picture25h(): return false
	if not await _walk([fixture.midpoint_px,fixture.end_px],"25H_TRUE_INPUT_BRIDGE_MIDPOINT_TO_EAST_SHORE"): return false
	return check(field==garden_refs25h[0].get_ref() and _player()==garden_refs25h[1].get_ref() and scene==garden_refs25h[2].get_ref() and scene.map_layout==garden_refs25h[3].get_ref() and _gameplay()==gameplay,"Same four native owners after complete real crossing, no task/reward/room/NPC route replay") and _natural25h()
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000;output="res://build/luoyang_city_revision_20261025h_qa01/garden02_output/%d_%d"%[OS.get_process_id(),began]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves();var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);gameplay=_gameplay();complete=await exercise_cpu()
	if driver!=null: driver.release();driver=null
	records.append({"kind":"25H_ONLY_NEW_GARDEN_BRIDGE_FINITE_QA","explicit_setups":1,"private_Player_position_writes":0,"other_five_routes_replayed":0,"NPC_or_portal_interactions":0,"full_geometry_or_RGBA_replay":0,"Physics_queries":physics_queries,"mask_samples":mask_samples,"true_INPUT_ticks":input_steps,"pictures":pictures,"default_or_loading_credit":false})
	finish(output,began,complete,"25H_GARDEN02_ZERO_PNG_HARDFALSE_FINAL_SOURCE_PENDING")
