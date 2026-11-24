extends SceneTree
## Read-only actual Field diagnosis of ROOT412's three preserved front FAILs.
## No production predicates, image bytes, feet, solids or old evidence are edited.
const RAW = preload("res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd")
const PHYSICAL = preload("res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd")
const ORACLE = preload("res://tests/helpers/v15_geometry_oracle.gd")
const ID := "ch4_s1_luoyang_yamen"
const PATCH := "res://art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/art_patch.json"
const PATCH_SHA := "2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4"
const FAIL_IDS: Array[String] = ["v11_yamen_west_south_1520","v11_yamen_west_south_1360","v11_yamen_west_north_780"]
const ROOF_IDS: Array[String] = ["v11_yamen_west_south_1520","v11_yamen_west_south_1360","v11_yamen_west_north_780","v11_yamen_east_south_1520","v11_yamen_east_south_1360","v11_yamen_east_north_780"]
const PLAYER_PATH := "res://scripts/field/player.gd"
const PLAYER_SHA := "9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const VARIANT_ROOT := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/"
var actor_inventory: Array[Dictionary] = []
var actor_paths: Dictionary = {}
var failure := ""
var tracked: Dictionary = {}
var players_before: Dictionary = {}
var slot_before: Variant
var field: Control
var raw: RefCounted
var probe: RefCounted
var oracle: RefCounted = ORACLE.new()
var observations: Array[Dictionary] = []
var output := ""

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> void:
	if not ok and failure.is_empty(): failure=label
func _unused_capture(_label: String) -> void: pass
func _file(path: String) -> Dictionary:
	var file: FileAccess=FileAccess.open(path,FileAccess.READ)
	return {"exists":file!=null,"sha256":FileAccess.get_sha256(path) if file!=null else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if file!=null else 0,"bytes":file.get_length() if file!=null else 0}
func _track(path: String) -> bool:
	var current: Dictionary=_file(path)
	if not current.exists: _check(false,"Missing diagnostic source: "+path); return false
	if tracked.has(path) and tracked[path]!=current: _check(false,"Diagnostic source changed: "+path); return false
	tracked[path]=current
	return true
func _players() -> Dictionary:
	var result: Dictionary={}
	for index: int in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[index,suffix]
			result[path]=_file(path)
	return result
func _wait_field() -> bool:
	var deadline: int=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var loading: Node=root.get_node_or_null("LoadingManager")
		if loading!=null and loading.get("_transition_active")==true: continue
		var node: Node=current_scene
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): continue
		if node.get_script()==null or node.get_script().resource_path!="res://scripts/field/field_walkable_controller.gd": continue
		var definition: SceneScript=node.get("_current_scene") as SceneScript
		var player: Node2D=node.get("_player") as Node2D
		if definition==null or String(definition.scene_id)!=ID or not is_instance_valid(player) or node.get("_scene_rebuilding")==true: continue
		await physics_frame
		if current_scene!=node or not is_instance_valid(node) or node.is_queued_for_deletion(): continue
		field=node as Control
		return true
	return false
func _source_pixel_point(sprite: Sprite2D,source: Rect2i,x: float,y: float) -> Vector2:
	var uv:=Vector2(x/source.size.x,y/source.size.y)
	if sprite.flip_h: uv.x=1.-uv.x
	if sprite.flip_v: uv.y=1.-uv.y
	var rect: Rect2=sprite.get_rect()
	return sprite.to_global(rect.position+uv*rect.size)
func _inventory() -> bool:
	for family: String in ["sword","dao","staff","palm","hidden"]:
		for state: String in ["idle","walk"]:
			var frames: int=4 if state=="idle" else 8
			for direction: String in ["up","down","left","right"]:
				var path: String=VARIANT_ROOT+family+"/lengguyun_"+family+"_"+state+"_"+direction+"_25d_"+str(frames)+"f.png"
				if not _track(path) or not _track(path+".import"): return false
				var config:=ConfigFile.new()
				if config.load(path+".import")!=OK or not _track(String(config.get_value("remap","path",""))): return false
				var source: Image=Image.load_from_file(path)
				var texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
				var imported: Image=texture.get_image() if texture!=null else null
				if imported!=null and imported.is_compressed() and imported.decompress()!=OK: imported=null
				if source==null or imported==null or source.get_size()!=Vector2i(frames*160,160) or imported.get_size()!=source.get_size() or actor_paths.has(path): _check(false,"All40 unique native160cell source/import strip inventory required"); return false
				source.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
				var source_rgba: PackedByteArray=source.get_data(); var imported_rgba: PackedByteArray=imported.get_data()
				var alpha_equal: bool=true; var rgb_equal: bool=true
				for byte: int in source_rgba.size():
					if source_rgba[byte]==imported_rgba[byte]: continue
					if byte%4==3: alpha_equal=false
					else: rgb_equal=false
				# Existing actor imports may fix RGB edges. Record this independently;
				# proof uses the entire actual imported drawrect, not source alpha bounds.
				var edge_clone: Image=source.duplicate() as Image
				edge_clone.fix_alpha_edges()
				actor_paths[path]=frames
				var full_frames: Array[Dictionary]=[]
				for frame_index: int in frames: full_frames.append({"index":frame_index,"source_frame_rect":[frame_index*160,0,160,160],"complete_drawrect_local":[-80,-80,160,160],"alpha_cropping_used":false})
				actor_inventory.append({"family":family,"state":state,"direction":direction,"path":path,"sha256":tracked[path].sha256,"import_sha256":tracked[path+".import"].sha256,"compiled_sha256":tracked[String(config.get_value("remap","path",""))].sha256,"source_import_all_RGBA_exact":source_rgba==imported_rgba,"source_import_all_alpha_exact":alpha_equal,"source_import_all_RGB_exact":rgb_equal,"engine_alpha_edge_clone_matches_import":edge_clone.get_data()==imported_rgba,"hframes":frames,"vframes":1,"size":[source.get_width(),source.get_height()],"frames":full_frames})
	return actor_inventory.size()==40 and actor_paths.size()==40
func _all_frame_actor_bound(player: Node2D,sprite: Sprite2D,foot_y: float) -> Dictionary:
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var normal_scale: float=.945*definition.player_visual_scale
	var family_value: Variant=player.get("_weapon_style")
	var direction_value: Variant=player.get("_direction")
	var moving_value: Variant=player.get("_is_moving")
	_check(typeof(family_value)==TYPE_STRING_NAME and typeof(direction_value)==TYPE_STRING and typeof(moving_value)==TYPE_BOOL,"Actual current Player weapon/direction/moving types exact")
	var family: String=String(family_value)
	var direction: String=String(direction_value)
	_check(family in ["sword","dao","staff","palm","hidden"] and direction in ["up","down","left","right"],"Actual current Player weapon/direction identities supported")
	if not failure.is_empty(): return {}
	var moving: bool=moving_value
	var state: String="walk" if moving else "idle"
	var frames: int=8 if moving else 4
	# Independent exact reproduction of the SHA-pinned Player._variant_texture
	# path formula. Membership alone would permit a stale valid strip when the
	# current requested strip is missing; require that exact requested resource.
	var expected_path: String=VARIANT_ROOT+family+"/lengguyun_"+family+"_"+state+"_"+direction+"_25d_"+str(frames)+"f.png"
	_check(actor_inventory.size()==40 and actor_paths.has(expected_path) and ResourceLoader.exists(expected_path) and sprite.texture.resource_path==expected_path and int(actor_paths.get(expected_path,0))==frames and sprite.hframes==frames and player.get("_applied_visual_key")==family+":"+direction+":"+state,"Actual exact current Player variant texture/hframes/key; no retained stale fallback")
	_check(definition.actor_positions_are_feet and player.get("_ground_anchored")==true and player.rotation==0. and player.scale==Vector2.ONE and sprite.centered and not sprite.region_enabled and sprite.vframes==1 and sprite.rotation==0. and sprite.scale==Vector2.ONE*normal_scale and sprite.offset==Vector2.ZERO and sprite.position==Vector2(0.,-160.*sprite.scale.y*.45) and sprite.get_rect()==Rect2(-80,-80,160,160) and player.get_parent()==field.get("_actor_layer"),"Exact ordinary160cell centered/fullrect/scale/offset/ground-anchor/parent contract")
	var transform: Transform2D=sprite.global_transform
	var parent_transform: Transform2D=(player.get_parent() as Node2D).global_transform
	_check(transform.x.is_finite() and transform.y.is_finite() and transform.origin.is_finite() and is_finite(foot_y),"Actual full actor transform/foot finite")
	var expected_foot: float=player.global_position.y+sprite.position.y+sprite.texture.get_height()*sprite.scale.y*.45
	_check(parent_transform.x==Vector2.RIGHT and parent_transform.y==Vector2.DOWN and parent_transform.origin.is_finite() and foot_y==expected_foot,"Actual ordinary axis-aligned XY translation/depth-foot domain")
	if not failure.is_empty(): return {}
	var minimum:=Vector2(INF,INF); var maximum:=Vector2(-INF,-INF)
	# Every one of the240 frames occupies this entire160cell drawrect. The bound
	# conservatively includes ALL pixels, not current-frame alpha/used_rect.
	for p: Vector2 in [Vector2(-80,-80),Vector2(80,-80),Vector2(80,80),Vector2(-80,80)]:
		var q: Vector2=sprite.to_global(p)
		minimum=minimum.min(q); maximum=maximum.max(q)
	return {"minimum_world":[minimum.x,minimum.y],"maximum_world":[maximum.x,maximum.y],"minimum_relative_to_depth_foot_y":minimum.y-foot_y,"maximum_relative_to_depth_foot_y":maximum.y-foot_y,"method":"ALL_40_STRIPS_240_FRAMES_FULL_DRAWRECT_CONSERVATIVE","strip_count":40,"frame_count":240,"actual_family":family,"actual_direction":direction,"actual_is_moving":moving,"expected_current_state":state,"expected_current_texture_path":expected_path,"expected_current_hframes":frames,"normal_scale":normal_scale,"sprite_scale":[sprite.scale.x,sprite.scale.y],"sprite_position":[sprite.position.x,sprite.position.y],"sprite_offset":[sprite.offset.x,sprite.offset.y],"centered":sprite.centered,"region_enabled":sprite.region_enabled,"actual_hframes":sprite.hframes,"actual_vframes":sprite.vframes,"actual_frame":sprite.frame,"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"filter":sprite.texture_filter,"ground_anchor":player.get("_ground_anchored"),"depth_foot_world_y":foot_y,"player_global_position":[player.global_position.x,player.global_position.y],"sprite_transform":[transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y],"parent_transform":[parent_transform.x.x,parent_transform.x.y,parent_transform.y.x,parent_transform.y.y,parent_transform.origin.x,parent_transform.origin.y]}
func _support(sprite: Sprite2D,actor: bool,depth_foot: float) -> Dictionary:
	var image: Image=oracle.call("image_for",sprite) as Image
	var source: Rect2i=oracle.call("frame",sprite,image)
	if image==null or source.size.x<=0 or source.size.y<=0: return {}
	var minimum:=Vector2(INF,INF); var maximum:=Vector2(-INF,-INF); var count:=0
	for y: int in source.size.y:
		for x: int in source.size.x:
			var alpha: float=image.get_pixelv(source.position+Vector2i(x,y)).a
			var excluded: bool=alpha*sprite.modulate.a*sprite.self_modulate.a<=.12 if actor else alpha<=0.
			if excluded: continue
			count+=1
			if actor:
				# Exact pixel centres used by the frozen strong_intersection oracle.
				var p: Vector2=_source_pixel_point(sprite,source,x+.5,y+.5)
				minimum=minimum.min(p); maximum=maximum.max(p)
			else:
				# Every positive source pixel can influence LINEAR samples up to one
				# source pixel from its centre. This conservative closed cell encloses
				# that support, including rotations/flips; it is not an alpha threshold.
				for q: Vector2 in [Vector2(x-.5,y-.5),Vector2(x+1.5,y-.5),Vector2(x+1.5,y+1.5),Vector2(x-.5,y+1.5)]:
					var p: Vector2=_source_pixel_point(sprite,source,q.x,q.y)
					minimum=minimum.min(p); maximum=maximum.max(p)
	if count==0: return {}
	_track(sprite.texture.resource_path)
	return {"pixels":count,"minimum_world":[minimum.x,minimum.y],"maximum_world":[maximum.x,maximum.y],"minimum_relative_to_depth_foot_y":minimum.y-depth_foot,"maximum_relative_to_depth_foot_y":maximum.y-depth_foot,"texture_path":sprite.texture.resource_path,"texture_sha256":FileAccess.get_sha256(sprite.texture.resource_path),"frame":sprite.frame,"frame_rect":[source.position.x,source.position.y,source.size.x,source.size.y],"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"texture_filter":sprite.texture_filter,"modulate_alpha":sprite.modulate.a,"self_modulate_alpha":sprite.self_modulate.a,"transform":[sprite.global_transform.x.x,sprite.global_transform.x.y,sprite.global_transform.y.x,sprite.global_transform.y.y,sprite.global_transform.origin.x,sprite.global_transform.origin.y],"support_method":"exact_actor_strong_centres_gt_0_12" if actor else "all_positive_prop_pixels_linear_closed_support"}
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); slot_before=root.get_node("SaveManager").get("active_slot")
	var args: PackedStringArray=OS.get_cmdline_user_args(); var tag: String=""
	for arg: String in args:
		if arg.begins_with("--roof-front-diagnostic-tag="): tag=arg.trim_prefix("--roof-front-diagnostic-tag=")
	if not "--diagnose-luoyang-v16-roof-front" in args or not "--luoyang-enclosure-v11-candidate" in args or not "--luoyang-v3-candidate" in args or tag.is_empty() or not tag.is_valid_identifier() or "--activate" in args: push_error("Explicit city-only candidate diagnostic required"); quit(1); return
	output="res://build/luoyang_enclosure_v16_roof_front/"+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))!=OK: push_error("Preserve existing diagnostic directory"); quit(1); return
	for path: String in [get_script().resource_path,"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd","res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd","res://tests/helpers/v15_geometry_oracle.gd",PLAYER_PATH,PATCH,"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/city/luoyang_layered_v3_contract.gd","res://scripts/dev/luoyang_yamen_complete_walls_v11_preview.gd"]: _track(path)
	_check(FileAccess.get_sha256(PLAYER_PATH)==PLAYER_SHA and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual player and executable SHA pinned")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.,"Actual WASAPI/ordinary time required")
	_check(_inventory(),"Complete40 strips/240 full drawrect frames decoded")
	_check(FileAccess.get_sha256(PATCH)==PATCH_SHA,"Actual ROOT393 patch unchanged")
	var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PATCH)) as Dictionary
	_track(String(patch.export_plan_path))
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(patch.export_plan_path)) as Dictionary
	for path: String in patch.source_catalog: _track(path)
	for object: Dictionary in patch.objects:
		if String(object.id) not in ROOF_IDS: continue
		var png: String=String(object.texture)
		_track(png); _track(png+".import")
		var config:=ConfigFile.new()
		_check(config.load(png+".import")==OK,"Actual PNG import config readable")
		_track(String(config.get_value("remap","path","")))
	if not failure.is_empty(): await _finish(); return
	for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
	var state: Node=root.get_node("GameState")
	for key: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: state.call("set_flag",StringName(key),true)
	state.set("current_chapter",4)
	var router: Node=root.get_node("SceneRouter")
	_check(router.call("go_field_smart",StringName(ID),null,"",-1,3)==true,"Public current-city3 route accepted")
	_check(await _wait_field(),"Actual ordinary Field arrived")
	if failure.is_empty():
		raw=RAW.new()
		_check(raw.call("configure_city",field.get("_current_scene"),true)==true,"Independent current manifest binding")
		probe=PHYSICAL.new()
		_check(probe.call("configure",self,field,raw.get("source_record"),_check,_unused_capture)==true,"Actual Physics/full875 source probe configured")
	if failure.is_empty():
		var player: Node2D=field.get("_player") as Node2D
		var container: Node2D=field.get("world_container") as Node2D
		for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			var moved: Dictionary=await probe.call("move_to",player.position+direction*2.)
			await probe.get("driver").call("completed_actor_stage")
			_check(moved.get("ok")==true,"Original normal two-pixel facing movement")
			var commanded_direction: String="up" if direction==Vector2.UP else ("down" if direction==Vector2.DOWN else ("left" if direction==Vector2.LEFT else "right"))
			_check(player.get("_direction")==commanded_direction,"Actual normal-input facing agrees with commanded direction, including completed idle")
			var sprite: Sprite2D=player.get("sprite") as Sprite2D
			var actor_foot: float=float(player.call("get_depth_sort_y"))
			var actor_support: Dictionary=_support(sprite,true,actor_foot)
			var all_actor_bound: Dictionary=_all_frame_actor_bound(player,sprite,actor_foot)
			_check(not actor_support.is_empty(),"Actual actor strong-pixel support readable")
			if not failure.is_empty(): break
			for oid: String in ROOF_IDS:
				var prop: Sprite2D=probe.call("prop",oid) as Sprite2D
				var record: Dictionary={}; var author: Dictionary={}
				for object: Dictionary in patch.objects:
					if String(object.id)==oid: record=object
				for object: Dictionary in plan.objects:
					if String(object.id)==oid: author=object
				_check(prop!=null and not record.is_empty() and not author.is_empty(),"Exact failing object exists in actual Field/patch/plan")
				if not failure.is_empty(): break
				var foot: Vector2=container.to_global(probe.call("point",record.world_foot_px))
				var decoded_source: Image=Image.load_from_file(String(record.texture))
				var actual_image: Image=oracle.call("image_for",prop) as Image
				_check(decoded_source!=null and actual_image!=null,"Independent source/import prop images decoded")
				if not failure.is_empty(): break
				decoded_source.convert(Image.FORMAT_RGBA8)
				var imported_owned: Image=actual_image.duplicate() as Image
				imported_owned.convert(Image.FORMAT_RGBA8)
				_check(decoded_source.get_size()==imported_owned.get_size() and decoded_source.get_data()==imported_owned.get_data(),"ALL actual prop source/import RGBA byteexact, not metadata used_rect")
				var declared: Dictionary={}
				for object: Dictionary in (field.get("_current_scene") as SceneScript).map_layout.visual_objects:
					if String(object.id)==oid: declared=object
				_check(not declared.is_empty() and declared.texture==record.texture and declared.sort_by_feet and float(declared.depth_sort_foot_y)*2048.==float(record.world_foot_px[1]) and prop.texture.resource_path==record.texture and prop.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"Actual object declaration texture/filter/depth-foot bound")
				var render: Vector2=probe.call("point",record.render_size_px)
				var uv: Vector2=probe.call("point",record.foot_uv)
				var authored_foot: Vector2=probe.call("point",record.world_foot_px)
				var expected_center: Vector2=(authored_foot+(Vector2(.5,.5)-uv)*render)/Vector2(3072,2048)
				_check(prop.centered and prop.offset==Vector2.ZERO and prop.rotation==0. and prop.scale==Vector2.ONE and not prop.region_enabled and prop.hframes==1 and prop.vframes==1 and prop.position==expected_center*Vector2(3072,2048) and declared.pos==expected_center and declared.render_size_px==render and prop.get_parent()==field.get("_actor_layer"),"Actual centered prop source pixels/footUV/render/pos/no region-warp/parent bound")
				var prop_support: Dictionary=_support(prop,false,foot.y)
				_check(not prop_support.is_empty(),"Actual prop positive support readable")
				if not failure.is_empty(): break
				var front_lower: float=foot.y+.01+float(all_actor_bound.minimum_relative_to_depth_foot_y)
				var gap: float=front_lower-float(prop_support.maximum_world[1])
				var separated: bool=is_finite(gap) and gap>0.
				_check(separated,"Strict finite positive all-frame front separation required: "+oid+"/"+commanded_direction)
				observations.append({"id":oid,"scope":"ORIGINAL_ROOT412_FAIL_READ_ONLY_DIAGNOSIS" if oid in FAIL_IDS else "PREDICTED_UNTESTED_DIAGNOSTIC_ONLY","direction":[direction.x,direction.y],"commanded_direction":commanded_direction,"actual_direction":all_actor_bound.actual_direction,"actual_is_moving":all_actor_bound.actual_is_moving,"normal_input":moved,"actual_player_foot_world_y":actor_foot,"actual_player_position":[player.position.x,player.position.y],"full875_raw":probe.call("raw_evidence",player.position),"actual_Physics_clear":probe.call("physical_clear",player.position),"physical_author_record":author,"patch_record":record,"current_actor_support":actor_support,"all_actor_bound":all_actor_bound,"prop_support":prop_support,"source_import_all_RGBA_exact":decoded_source.get_data()==imported_owned.get_data(),"front_domain":"ALL real XY translations with actor depth foot > prop depth foot + 0.01; legal raw/Physics/segment stations are a subset","front_domain_actor_full_drawrect_minimum_world_y":front_lower,"front_domain_prop_positive_maximum_world_y":prop_support.maximum_world[1],"continuous_front_axis_gap_world_px":gap,"all_front_translation_strong_alpha_impossible_ALL40strips240frames":separated,"zero_gap_is_NOT_PROVEN":true,"original_ROOT412_FAIL_unchanged":oid in FAIL_IDS,"collision_absence_claim":false,"production_or_QA_predicate_modified":false})
	await _finish()
func _finish() -> void:
	if probe!=null: probe.call("release"); probe=null
	if raw!=null: raw.call("release"); raw=null
	oracle.call("release")
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for tick: int in 8: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	for tick: int in 4: await process_frame
	var same: bool=true
	for path: String in tracked:
		if tracked[path]!=_file(path): same=false
	_check(same,"Exact tracked source/PNG/import bytes unchanged")
	_check(players_before==_players() and slot_before==root.get_node("SaveManager").get("active_slot"),"All15 player files/slot unchanged")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"Checkpoint remains suspended")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual audio/executable/time remain exact at finish")
	var proven_count: int=0
	for observation: Dictionary in observations:
		var gap: float=float(observation.continuous_front_axis_gap_world_px)
		if observation.get("all_front_translation_strong_alpha_impossible_ALL40strips240frames")==true and is_finite(gap) and gap>0.: proven_count+=1
	_check(observations.size()==24 and proven_count==24,"ALL24 independently recorded finite positive front gaps must be proven")
	var result: Dictionary={"scope":"ACTUAL_FIELD_SIX_ROOF_FRONT_DOMAIN_DIAGNOSIS_NOT_APPROVAL","complete":failure.is_empty() and observations.size()==24 and proven_count==24,"failure":failure,"observations":observations,"actual_normal_orientation_observations":observations.size(),"required_positive_front_gap_count":24,"proven_positive_front_gap_count":proven_count,"original_ROOT412_FAIL_IDS":FAIL_IDS,"east_three_status":"PREDICTED_UNTESTED_DIAGNOSTIC_ONLY","all_actor_strips":actor_inventory,"actor_strip_count":actor_inventory.size(),"actor_frame_count":240,"source_before":tracked,"source_unchanged":same,"players_before":players_before,"players_after":_players(),"all_animation_frames_conservatively_enclosed":actor_inventory.size()==40,"240_animation_frames_individually_driven":false,"actual_audio_driver":AudioServer.get_driver_name(),"actual_engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"actual_time_scale":Engine.time_scale,"original_ROOT412_three_FAIL_preserved":true,"production_predicate_modified":false,"QA_predicate_modified":false,"PNG_feet_solids_modified":false,"formal_approved":false,"root_precise_UTCtick_and_full_stderr_guards_required":true}
	var encoded: String=JSON.stringify(result,"\t",false)
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: push_error("Diagnostic output unreadable"); quit(1); return
	file.store_string(encoded+"\n"); file.flush(); var written: bool=file.get_error()==OK; file.close()
	written=written and JSON.parse_string(FileAccess.get_file_as_string(output+"result.json"))==JSON.parse_string(encoded)
	print("LUOYANG_ROOF_FRONT_DIAGNOSTIC "+output+"result.json observations="+str(observations.size()))
	if not failure.is_empty(): push_error(failure)
	quit(0 if result.complete and written else 1)
