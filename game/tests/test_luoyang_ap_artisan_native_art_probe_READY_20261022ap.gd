extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Root-only ONE native art probe, not Field/NAV/portal/source admission.
const FIXTURE: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/artisan_native_art_probe_READY.json"
const FIXTURE_SHA: String="6599604d571da793a9c29603d737be5a51e6f71369d1e3d72e622a0633145720"
const B_PATH: String="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const NPC_PATH: String="res://scenes/npc_node.tscn"
const SIZE: Vector2=Vector2(3072,2048)
const LIMIT_MS: int=30000
var fixed: Dictionary={}
var b: Script
var native_scene: SceneScript
var native_layout: WalkableMapLayout
var packet: Dictionary={}
var view: SubViewport
var world: Node2D
var rendered: Array[Dictionary]=[]
var actors: Array[Dictionary]=[]
var textures: Dictionary={}
var folder: String=""
var scene_before: Dictionary={}
var layout_before: Dictionary={}

func _v(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])

func _texture(path: String) -> Texture2D:
	if textures.has(path): return textures[path]
	var expected: Dictionary=fixed.publication_sources.duplicate()
	expected.merge(fixed.additional_render_source_sha256)
	if not check(expected.has(path),"Rendered source explicitly locked by48408 or exact render-only addition "+path) or not track(path,expected[path]): return null
	var side: String=path+".import"
	if FileAccess.file_exists(side):
		if not check(expected.has(side),"Actual remap in fixed render source set "+side) or not track(side,expected[side]): return null
		var cfg:=ConfigFile.new()
		if not check(cfg.load(side)==OK,"Read source-bound import "+side): return null
		var dest: Variant=cfg.get_value("deps","dest_files",null)
		if not check(dest is Array or dest is PackedStringArray,"Explicit import destination list domain "+side): return null
		if not check(dest.size()>0,"Nonempty actual compiled destinations "+side): return null
		for compiled: String in dest:
			if not check(expected.has(compiled),"Compiled source closure exact "+compiled) or not track(compiled,expected[compiled]): return null
	var texture: Texture2D=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if not check(texture!=null,"Actual Texture2D "+path): return null
	textures[path]=texture
	return texture

func precheck() -> bool:
	if not check(DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().is_empty() and Engine.time_scale==1.0,"GUI native renderer/no args/no Field"): return false
	if not track(FIXTURE,FIXTURE_SHA): return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(value is Dictionary and value.get("status")=="AP_ARTISAN_NATIVE_ART_PROBE_ONLY_NOT_FIELD_NAV_READY" and value.get("limit_ms")==LIMIT_MS,"Frozen actual artifact art-probe scope"): return false
	fixed=value
	if not track(fixed.report_path,fixed.report_sha256): return false
	var publication: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixed.report_path))
	if not check(publication is Dictionary and publication.get("passed")==true and publication.get("source_first")==publication.get("source_final"),"Actual48408 full publication source passes reused, not repeated geometry"): return false
	for path: String in fixed.executed_pins:
		if not track(path,fixed.executed_pins[path]): return false
	for path: String in fixed.artifacts:
		if not track(path,fixed.artifacts[path]): return false
	b=load(B_PATH) as Script
	if not check(b!=null and b.can_instantiate(),"Actual fixed storage codec loads"): return false
	native_scene=ResourceLoader.load(fixed.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	native_layout=ResourceLoader.load(fixed.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var decoded: Variant=bytes_to_var(FileAccess.get_file_as_bytes(fixed.packet_path))
	if not check(native_scene!=null and native_layout!=null and decoded is Dictionary and b._plain(decoded),"Real published native resources and plain packet"): return false
	packet=decoded
	if not check(String(native_scene.scene_id)==fixed.scene_id and native_scene.actor_positions_are_feet and native_scene.map_layout.resource_path==fixed.layout_path and native_layout.visual_objects.size()==485 and native_scene.npcs.size()==4,"One native485props/4NPC scene, no invented new room/native data"): return false
	scene_before=b.storage(native_scene);layout_before=b.storage(native_layout)
	return check(b.equal(scene_before,packet.get("scene_storage")) and b.equal(layout_before,packet.get("layout_storage")) and b.equal(b.storage(native_scene.map_layout),layout_before),"All typed native Scene/layout storage equals actual published packet")

func _build_props() -> bool:
	view=SubViewport.new();view.name="APNativeArtProbe";view.size=Vector2i(3072,2048)
	view.disable_3d=true;view.world_2d=World2D.new();view.transparent_bg=false
	view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(view)
	world=Node2D.new();world.name="ActualWorldScaleOne";view.add_child(world)
	var background: Texture2D=_texture(native_scene.background_path)
	if background==null: return false
	var floor_sprite:=Sprite2D.new();floor_sprite.name="PublishedBackground";floor_sprite.texture=background;floor_sprite.centered=false;floor_sprite.scale=SIZE/Vector2(background.get_size());floor_sprite.z_index=-1000
	world.add_child(floor_sprite)
	var seen: Dictionary={}
	for data: Dictionary in native_layout.visual_objects:
		var id: String=String(data.get("id",""))
		if not check(not id.is_empty() and not seen.has(id) and data.get("pos") is Vector2 and data.get("render_size_px") is Vector2,"Exact typed authored visual identity/position/render size"): return false
		seen[id]=true
		var texture: Texture2D=_texture(String(data.texture))
		if texture==null: return false
		var sprite:=Sprite2D.new();sprite.name="SceneObject_"+id;sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered=bool(data.get("centered",true));sprite.position=data.pos*SIZE
		sprite.scale=data.render_size_px/Vector2(texture.get_size());sprite.rotation_degrees=float(data.get("rotation",0.0));sprite.z_index=int(data.get("z_index",0))
		if data.get("modulate") is Color: sprite.modulate=data.modulate
		if data.get("sort_by_feet",false):
			if not check(data.has("depth_sort_foot_y"),"Authored sort foot exists "+id): return false
			sprite.z_index=clampi(int(floor(clampf(float(data.depth_sort_foot_y),0.0,1.0)*SIZE.y/8.0)),0,255)
		world.add_child(sprite)
		rendered.append({"id":id,"position":sprite.position,"render_size_px":data.render_size_px,"scale":sprite.scale,"z_index":sprite.z_index,"texture":String(data.texture)})
	return check(rendered.size()==485,"All485 actual native visual rows rendered once")

func _build_npcs() -> bool:
	var packed: PackedScene=load(NPC_PATH) as PackedScene
	if not check(packed!=null,"Fixed original NPC PackedScene"): return false
	for row: Dictionary in native_scene.npcs:
		if not check(row.get("district_life_ground_anchored")==true and row.get("movement_mode")=="idle" and row.get("walk_sprite_path")=="" and row.get("pos") is Vector2,"Four authored static real-idle people, no walking claim"): return false
		if _texture(String(row.sprite_path))==null: return false
		var npc: NPCNode=packed.instantiate() as NPCNode
		if not check(npc!=null,"Actual NPCNode instance for initial idle only"): return false
		npc.npc_id=String(row.npc_id);npc.npc_name=String(row.npc_name);npc.sprite_path=String(row.sprite_path);npc.portrait_path=String(row.portrait_path)
		npc.dialog_id=String(row.get("dialog_id",""));npc.interaction_action=String(row.get("interaction_action",""));npc.dialog_variants.assign(row.get("dialog_variants",[]))
		npc.walk_sprite_path=String(row.walk_sprite_path);npc.movement_mode=String(row.movement_mode)
		npc.sprite_scale=float(row.get("scale",.08))*native_scene.npc_visual_scale
		npc.idle_frame_seconds=float(row.get("idle_frame_seconds",NPCNode.IDLE_FRAME_SECONDS))
		npc.walk_frame_seconds=float(row.get("walk_frame_seconds",.12))
		npc._calibrate_adult_body=true;npc.sprite_scale=1.0;npc.position=row.pos*SIZE
		world.add_child(npc)
		npc.apply_runtime_idle_texture(textures[String(row.sprite_path)])
		npc.set_ground_anchored(true);npc.set_meta("depth_band_max",255);npc.refresh_depth_sort()
		npc.set_process(false);npc.sprite.frame=0
		var body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
		var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D if body!=null and body.get_child_count()==1 else null
		if not check(shape!=null and shape.shape is RectangleShape2D and shape.shape.size==Vector2(22.4,28.8) and npc.sprite.hframes==4 and npc.sprite.frame==0 and npc.position==row.pos*SIZE,"Same native22.4x28.8/groundfoot/first real4idle frame; no Physics query credit"): return false
		actors.append({"id":npc.npc_id,"foot":npc.position,"sprite":npc.sprite_path,"frame":npc.sprite.frame,"hframes":npc.sprite.hframes,"sprite_scale":npc.sprite.scale,"sprite_offset":npc.sprite.position,"body":shape.shape.size,"z_index":npc.z_index,"animation_observed":false,"Field_or_dialogue_admission":false})
	return check(actors.size()==4,"Exactly four native initial-idle actors, not drawn portraits")

func _probe() -> bool:
	if not _build_props() or not _build_npcs(): return false
	view.render_target_update_mode=SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image: Image=view.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(3072,2048),"Actual3072x2048 GPU readback atworld1x"): return false
	var path: String=folder.path_join("artisan_native_world1x_initial_idle.png")
	if not check(not FileAccess.file_exists(path) and image.save_png(path)==OK,"One NEW native art probe PNG"): return false
	records.append({"kind":"AP_NATIVE_ART_PROBE","picture":{"path":path,"sha256":FileAccess.get_sha256(path),"size":image.get_size()},"visuals":rendered,"npcs":actors,"world_scale":Vector2.ONE,"depth":"same floor(native world foot/8), max255","Field_NAV_or_loading_admission":false,"geometry_or_import_rerun":false})
	return check(b.equal(b.storage(native_scene),scene_before) and b.equal(b.storage(native_layout),layout_before) and b.equal(b.storage(native_scene.map_layout),layout_before),"Full typed source storage unchanged by rendering")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_city_full_rollout_20261022ap_qa01/artisan_art_probe/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck(): complete=await _probe()
	if is_instance_valid(view): view.queue_free()
	await process_frame;await process_frame
	world=null;view=null;textures.clear();native_scene=null;native_layout=null;packet.clear();scene_before.clear();layout_before.clear();b=null
	finish(folder,began,complete,"AP_ARTISAN_ONE_NATIVE_ART_PROBE_NOT_FIELD_NAV_OR_FORMAL_30S")
