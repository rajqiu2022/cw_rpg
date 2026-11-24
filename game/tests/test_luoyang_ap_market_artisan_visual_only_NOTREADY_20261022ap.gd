extends "res://tests/test_luoyang_city_full_rollout_remaining_BDE_fade_history_READY_20261022ap.gd"
## NEW finite visual residual only. No old B/C rooms, NPC menus or route matrix.
const VISUAL_READY: bool=false
const VISUAL_FIXTURE: String="NOTREADY_AWAIT_ROOT_UNIFIED_ACTUAL_DEPLOY_AND_INDEPENDENT_OWNER_MAP"
const VISUAL_FIXTURE_SHA: String=""
var visual_mode: String=""
var visual_pose: Dictionary={}

func precheck() -> bool:
	if not check(VISUAL_READY,"NOTREADY: unified source owner and Root actual deployment missing"): return false
	if not track(VISUAL_FIXTURE,VISUAL_FIXTURE_SHA): return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(VISUAL_FIXTURE))
	if not check(parsed is Dictionary and parsed.get("schema")=="AP_FINITE_MARKET_UI_OR_ARTISAN_SAME_VIEW_VISUAL_ONLY" and parsed.get("ready")==true,"Exact finite visual source fixture"): return false
	plan=parsed
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not check(args.size()==1 and args[0] in ["--ap-qa-visual=market","--ap-qa-visual=artisan"] and DisplayServer.get_name()!="headless" and root.size==Vector2i(1920,1080) and Engine.time_scale==1.0,"Ordinary1080P one finite visual selector only"): return false
	visual_mode=args[0].trim_prefix("--ap-qa-visual=")
	if not check(plan.get("arrival_ms")==60000 and plan.get("whole_ms")==90000 and plan.get("scenes") is Array,"Predeclared90s total/60s arrival, no relaxed travel scope"): return false
	for path: String in plan.core_source_sha256:
		if not track(path,plan.core_source_sha256[path]): return false
	for path: String in plan.visual_source_sha256:
		if not track(path,plan.visual_source_sha256[path]): return false
	for spec: Dictionary in plan.scenes: ap_specs[spec.id]=spec
	visual_pose=plan.visual_poses
	return check(ap_specs.has("ch4_s3_luoyang_market") and ap_specs.has("luoyang_artisan_residential_20261022ap"),"Only intended scene owner specs available")

func _bind_independent(id: String) -> bool:
	if visual_mode=="artisan":
		var player: CharacterBody2D=field.get("_player") as CharacterBody2D
		var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D if player!=null else null
		return check(id=="luoyang_artisan_residential_20261022ap" and shape!=null and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24),"Artisan visual-only native body identity, no Physics or geometry resampling")
	return super._bind_independent(id)

func _mouse_motion(point: Vector2) -> void:
	var physical: Vector2=root.get_final_transform()*point
	var event:=InputEventMouseMotion.new()
	event.position=physical;event.global_position=physical;event.device=0
	Input.parse_input_event(event);Input.flush_buffered_events()
	await process_frame;await process_frame

func _hud_state(hud: Node) -> Dictionary:
	var panel: PanelContainer=hud.get("_quest_panel") as PanelContainer
	var style: StyleBoxFlat=hud.get("_quest_backplate") as StyleBoxFlat
	return {"hovered":hud.get("_quest_backplate_hovered"),"pinned":hud.get("_quest_backplate_pinned"),"color":style.bg_color if style!=null else Color.MAGENTA,"visible":panel.is_visible_in_tree() if panel!=null else false}

func _hero_body_visual() -> Dictionary:
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var sprite: Sprite2D=player.get("sprite") as Sprite2D
	var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
	var multiplier: float=maxf(.5,scene.player_visual_scale*1.12)
	var expected_scale: Vector2=Vector2.ONE*.945*multiplier
	var encoding:=Sprite2D.new()
	encoding.position=Vector2(0.0,-sprite.texture.get_height()*expected_scale.y*.45)
	var expected_position: Vector2=encoding.position
	encoding.free()
	var valid: bool=check(shape!=null and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24) and shape.position==Vector2.ZERO and not shape.disabled and player.get_script().get_script_constant_map().get("SPEED")==480.0,"Actual original34x24 body and480speed, no resize for larger sprite")
	valid=check(player.get("_visual_scale_multiplier")==multiplier and sprite.scale==expected_scale and sprite.position==expected_position and player.get("_ground_anchored")==true,"Native encoded source .945*scene visual*1.12 and unchanged foot-anchor formula") and valid
	return {"valid":valid,"body_id":shape.shape.get_instance_id(),"body_size":shape.shape.size,"player_id":player.get_instance_id(),"foot":player.position,"sprite_scale":sprite.scale,"source_old_visual_scale":Vector2.ONE*.945*scene.player_visual_scale,"factor":1.12,"sprite_position":sprite.position,"source_anchor_unchanged":true}

func _market_visual() -> bool:
	var pose: Dictionary=visual_pose.examiner
	var id: String="ch4_s3_luoyang_market"
	if not await _setup_ap(id,_v(pose.near_setup_foot)/Vector2(3072,2048)): return false
	var hero: Dictionary=_hero_body_visual()
	if not hero.valid or not await _walk(pose.normal_input,"New exact examiner normal24px INPUT"): return false
	var hud: Node=field.get("_primary_hud")
	var panel: PanelContainer=hud.get("_quest_panel") as PanelContainer
	var text: RichTextLabel=hud.get("_quest_summary") as RichTextLabel
	if not check(panel!=null and text!=null and panel.is_visible_in_tree() and panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and text.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Actual HUD text and unmodified mouse-filter domain"): return false
	var inside: Vector2=panel.get_global_rect().get_center()
	var outside: Vector2=Vector2(inside.x,clampf(panel.get_global_rect().end.y+40.0,0.0,650.0))
	await _mouse_motion(outside)
	if not check(_hud_state(hud).color==Color(0,0,0,0) and _hud_state(hud).pinned==false,"Default outside transparent backing"): return false
	await _mouse_motion(inside)
	if not check(_hud_state(hud).color==Color(0,0,0,.62) and _hud_state(hud).hovered==true,"Real mouse hover plain black alpha.62"): return false
	if not check(panel.size.y==maxf(1.0,float(text.get_content_height()))+30.0,"Real wrapped content controls backing height without clipping"): return false
	if not await _capture("market_HUD_real_hover"): return false
	await _mouse_motion(outside)
	if not check(_hud_state(hud).color==Color(0,0,0,0),"Real pointer leave clears unpinned backing"): return false
	await driver.pointer(inside);await _mouse_motion(outside)
	if not check(_hud_state(hud).pinned==true and _hud_state(hud).color==Color(0,0,0,.62),"Real local left click pins backing after pointer leaves"): return false
	await driver.pointer(outside)
	if not check(_hud_state(hud).pinned==true,"Outside click does not toggle HUD pin"): return false
	await driver.pointer(inside);await _mouse_motion(outside)
	if not check(_hud_state(hud).pinned==false and _hud_state(hud).color==Color(0,0,0,0),"Second local left click unpins backing"): return false
	await driver.key(KEY_J);await process_frame
	if not check(field.get("_system_panel_open")==true and not panel.is_visible_in_tree(),"Original real J opens quest system panel and hides tracker"): return false
	await driver.key(KEY_ESCAPE);await process_frame
	if not check(field.get("_system_panel_open")==false and panel.is_visible_in_tree(),"Original real Esc restores HUD and movement"): return false
	var found: Array[Node]=[]
	for npc: Node in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.get("npc_id")==pose.npc_id: found.append(npc)
	if not check(found.size()==1 and found[0].get("position")==_v(pose.final_foot_world) and found[0].get("portrait_path")==plan.examiner_portrait_path,"One exact original examiner at fixed author foot with mature portrait"): return false
	var dp: Node=root.get_node("DialogPlayer")
	var before: Dictionary=_state_ap()
	await driver.key(KEY_SPACE)
	var until: int=mini(deadline,Time.get_ticks_msec()+5000)
	while not dp.call("is_playing") and Time.get_ticks_msec()<until: await process_frame
	var dialog: DialogScript=dp.get("_current_script") as DialogScript
	var node: DialogNode=dp.get("_current_node") as DialogNode
	if not check(dialog!=null and String(dialog.dialog_id)=="runtime_spar_preface_spar_luoyang_examiner" and node!=null and node.node_id==&"invite" and node.choices==[{"text":"请赐教","next":"ready"},{"text":"今日先不打扰","next":"end"}],"Real Space opened original exact examiner invitation, no direct DP play"): return false
	var layer: Node=dp.get("_box")
	var box: Control=layer.get_node_or_null("DialogBox") as Control if is_instance_valid(layer) else null
	if not check(box!=null and box.is_visible_in_tree(),"Real invitation UI box is visible"): return false
	var portrait: TextureRect=box.get_node_or_null("Frame/Portrait") as TextureRect
	var speaker: Label=box.get_node_or_null("Frame/SpeakerLabel") as Label
	if not check(speaker!=null and speaker.is_visible_in_tree() and speaker.text=="大会考校官 · 可切磋","Real invitation UI speaker belongs to exact original examiner"): return false
	if not check(portrait!=null and portrait.is_visible_in_tree() and portrait.texture!=null and portrait.texture.resource_path==plan.examiner_portrait_path and portrait.texture.get_size()==Vector2(1254,1254) and portrait.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Actual complete1254 portrait UI contain, no crop/pad or world-sprite credit"): return false
	var state: Dictionary=_hud_state(hud)
	await _mouse_motion(inside);await driver.pointer(inside);await _mouse_motion(outside)
	if not check(_hud_state(hud)==state and dp.call("is_playing"),"Dialog-playing HUD ignores actual pointer hover/click; invitation remains"): return false
	if not await _capture("market_examiner_full_canvas_portrait_real_Space"): return false
	await driver.key(KEY_2)
	until=mini(deadline,Time.get_ticks_msec()+5000)
	while dp.call("is_playing") and Time.get_ticks_msec()<until: await process_frame
	if not check(not dp.call("is_playing") and C._equal_value(before,_state_ap()),"Real dismiss only; no spar, quest, reward or inventory mutation"): return false
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
	if not check(player.get_instance_id()==hero.player_id and shape.shape.get_instance_id()==hero.body_id and shape.shape.size==hero.body_size,"Same actual hero/native body through HUD and portrait interactions"): return false
	records.append({"kind":"AP_MARKET_FINITE_HUD_EXACT_EXAMINER_HERO_VISUAL","hero":hero,"same_native_body_after":true,"real_pointer_and_keyboard_only":true,"portrait_full_source_canvas":Vector2(1254,1254),"portrait_mode":"KEEP_ASPECT_CENTERED_UI_ONLY","no_other_NPC_replacement_or_voice_credit":true})
	return true

func _artisan_visual() -> bool:
	var id: String="luoyang_artisan_residential_20261022ap"
	var pose: Dictionary=visual_pose.artisan_same_camera
	if not await _setup_ap(id,_v(pose.original_setup_spawn)/Vector2(3072,2048)): return false
	# Same original24px input for framing only. Predicate is finite position,
	# explicitly not a geometry oracle; old C/rooms/Physics get no new credit.
	var travel: Dictionary=await driver.drive(field,_v(pose.capture_player_foot),func(foot: Vector2) -> bool: return foot.is_finite())
	if not check(travel.get("reached")==true,"Same original finite visual framing INPUT endpoint"): return false
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	if not check(camera!=null and camera.zoom==Vector2.ONE and not camera.position_smoothing_enabled and [camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom]==[0,0,3072,2048],"Original ordinary camera zoom/smoothing/limits; no private reframing"): return false
	var expected:=PackedVector4Array()
	for edge: Dictionary in pose.union_exterior_segments: expected.append(Vector4(edge.from[0],edge.from[1],edge.to[0],edge.to[1]))
	if not check(expected.size()==32 and pose.source_sections.size()==9,"Fixed independent9section/32outer union oracle"): return false
	var native_tiles: Dictionary={}
	for section: Dictionary in pose.source_sections:
		var bounds: Array=section.rect
		var tile: Vector2=_v(section.tile_size)
		for yi: int in range(ceili(float(bounds[3])/tile.y)):
			for xi: int in range(ceili(float(bounds[2])/tile.x)):
				var extent: Vector2=Vector2(minf(tile.x,float(bounds[2])-xi*tile.x),minf(tile.y,float(bounds[3])-yi*tile.y))
				var center: Vector2=Vector2(bounds[0],bounds[1])+Vector2(xi*tile.x,yi*tile.y)+extent*.5
				var key: String="SceneObject_%s_%d_%d"%[section.id,xi,yi]
				native_tiles[key]={"position":(center/Vector2(3072,2048))*Vector2(3072,2048),"size":extent,"z":section.z}
	if not check(native_tiles.size()==62,"Independent fixed original9 rectangles produce exactly62 clipped native tiles"): return false
	var tiles: int=0
	var seen: Dictionary={}
	for sprite: Node in field.get("_visual_layer").get_children():
		if sprite is Sprite2D and sprite.has_meta("ap_union_exterior_transition"):
			if not check(native_tiles.has(String(sprite.name)) and not seen.has(String(sprite.name)) and sprite.texture!=null,"Unique original tile identity from independent rectangles"): return false
			seen[String(sprite.name)]=true
			var native: Dictionary=native_tiles[String(sprite.name)]
			if not check(sprite.position==native.position and sprite.texture.get_size()*sprite.scale==native.size and sprite.centered and sprite.rotation==0.0 and sprite.z_index==native.z,"Original independently authored tile position/extent/z retained exactly"): return false
			var material: ShaderMaterial=sprite.material as ShaderMaterial
			if not check(material!=null and material.shader.resource_path==plan.artisan_union_shader_path and material.get_shader_parameter("ap_union_segments")==expected and material.get_shader_parameter("ap_sprite_design_origin")==sprite.position and material.get_shader_parameter("ap_sprite_source_to_design")==sprite.scale,"Actual fixed exterior-only shader and original tile transform"): return false
			var meta: Dictionary=sprite.get_meta("ap_union_exterior_transition")
			if not check(meta=={"segment_count":32,"feather_world":32.0,"core_opacity":1.0,"native_transform_and_texture_unchanged":true,"no_tile_or_interior_section_seams":true},"Actual32world feather only at union exterior, opaque core"): return false
			tiles+=1
	if not check(tiles==62 and native_queries==0,"All62 original ground tiles; no Physics or C functional replay"): return false
	if not await _capture("artisan_same_C_camera_union_exterior_visual_only"): return false
	records.append({"kind":"AP_ARTISAN_SAME_VIEW_VISUAL_ONLY","prior_image":pose.original_image,"camera_zoom":camera.zoom,"camera_actual_position":camera.global_position,"capture_foot":field.get("_player").position,"original_native_ground_tiles":tiles,"source_sections":9,"union_exterior_segments":32,"core_opacity":1.0,"feather_world":32,"finite_only_INPUT_not_geometry_revalidation":true,"native_queries":0,"no_rooms_or_NPC_menu_or_old_C_replay":true,"Root_ART_must_compare_actual_image":true})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec()
	deadline=began+1000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	output="res://build/luoyang_city_full_rollout_20261022ap_qa01/finite_visual_only/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete: bool=false
	if precheck():
		deadline=began+90000
		driver=INPUT.new();driver.configure(self);RenderingServer.frame_post_draw.connect(_draw)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		root.get_node("GameState").set("current_chapter",4)
		ap_state_before=_state_ap()
		if visual_mode=="market": complete=await _market_visual()
		else: complete=await _artisan_visual()
	target=""
	if RenderingServer.frame_post_draw.is_connected(_draw): RenderingServer.frame_post_draw.disconnect(_draw)
	if not await _cleanup(): complete=false
	if not ap_state_before.is_empty() and not check(C._equal_value(ap_state_before,_state_ap()),"No task/flag/reward/inventory mutation during finite visual checks"): complete=false
	finish(output,began,complete,"AP_FINITE_MARKET_UI_OR_ARTISAN_SAME_C_VIEW_VISUAL_ONLY_NOT_FULL_CITY")
