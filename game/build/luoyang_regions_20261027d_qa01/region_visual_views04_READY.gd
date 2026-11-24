extends SceneTree
## Root-only visual residual: original public entries/cameras, no movement or dialogue.
const INPUT := "res://build/luoyang_regions_20261027d_qa01/region_visual_views04_READY.json"
const INPUT_SHA := "b221cf0e0fa22d67983e46962630c823994020f71b850b6b4f046cabc338e428"
const OUTPUT_ROOT := "res://build/luoyang_regions_20261027d_qa01/region_visual_views04_READY_output/"
const AUTOLOADS := ["EventBus","GameState","WeatherManager","InvestigationState","Inventory","LoadingManager","SceneRouter","QuestManager","BountyManager","DialogPlayer","SaveManager","CursorManager","PlatformBridge","ContentPackManager","AudioManager","GMConsole"]
var spec: Dictionary = {}
var started: int = 0
var checks: int = 0
var errors: Array[String] = []
var records: Array = []
var source_first: Dictionary = {}
var save_first: Dictionary = {}
var png_count: int = 0
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
	return Time.get_ticks_msec()-started < 45000

func vec(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)

func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path): result[path]={"exists":false}; continue
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
		if file!=null: file.close()
	return result

func _run() -> void:
	started=Time.get_ticks_msec()
	if not check(FileAccess.get_sha256(INPUT)==INPUT_SHA,"FIXED_READY_FIXTURE_SHA"): finish(); return
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if not check(raw is Dictionary and raw.get("ready")==true,"ROOT_READY_ONLY"): finish(); return
	spec=raw
	if not check(spec.budgets.whole_seconds==45 and spec.budgets.entry_seconds==20 and spec.budgets.max_png==2 and spec.views.size()==2,"TWO_VIEWS_45S_BOUND"): finish(); return
	for id: String in AUTOLOADS: check(root.get_node_or_null(id)!=null,"NORMAL_AUTOLOAD:"+id)
	if not errors.is_empty(): finish(); return
	sr=root.get_node("SceneRouter"); lm=root.get_node("LoadingManager"); dp=root.get_node("DialogPlayer")
	var platform: Node=root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SAVE_SUSPENSION_TO_QUIT")
	var hero: Resource=root.get_node("GameState").get("player") as Resource
	check(hero!=null and String(hero.get("character_id"))=="protagonist" and (root.get_node("GameState").get("party") as Array).has(hero),"NORMAL_GAMESTATE_AUTOLOAD_NO_RESET_OR_LOAD")
	if not check(spec.fixed_sources.size()>0 and spec.fixed_documents.size()==3 and spec.save_paths.size()==15,"FIXED_SMALL_SOURCE_DOCS_AND_FIFTEEN_SAVE_PATHS"): finish(); return
	var fixed: Dictionary=spec.fixed_sources.duplicate(true); fixed.merge(spec.fixed_documents,true)
	source_first=facts(fixed.keys()); save_first=facts(spec.save_paths)
	for path: String in fixed: check(source_first[path].get("sha256")==fixed[path],"FIXED_PIN:"+path)
	if not errors.is_empty(): finish(); return
	var declaration: Dictionary=spec.declared_expected_sources
	if not check(spec.fixed_sources.get(declaration.path)==declaration.sha256,"INDEPENDENT_DECLARATION_PIN_NOT_OBSERVED_FILL"): finish(); return
	var declared: Variant=JSON.parse_string(FileAccess.get_file_as_string(declaration.path))
	if not check(declared is Dictionary and declared.get("status")=="FIXED_SOURCE_EXPRESSION_DECLARATIONS_NOT_OBSERVED_RECEIPTS" and declared.get("expected_sources") is Dictionary,"INDEPENDENT_EXPECTED_TABLE_SCHEMA"): finish(); return
	for row: Dictionary in spec.views:
		var expected: Variant=declared.expected_sources.get(row.source_key)
		if not check(expected is Dictionary and expected.size()==int(declaration.counts[row.source_key]) and vec(row.old_uv).is_finite(),"FIXED_VIEW_SOURCE_DECLARATION:"+row.source_key): finish(); return
		if not await enter_and_capture(row,expected): finish(); return
	check(png_count==2 and in_budget(),"EXACTLY_TWO_NATIVE_VIEWS_WITHIN_45S")
	finish()

func enter_and_capture(row: Dictionary, expected: Dictionary) -> bool:
	var began: int=Time.get_ticks_msec()
	var previous: Node=current_scene
	var accepted: Variant=sr.call("go_field_smart",StringName(row.logical_entry),vec(row.old_uv),"",-1,3)
	records.append({"public_entry":row.logical_entry,"accepted":accepted,"old_uv":row.old_uv,"setup_not_default_performance":true,"public_state_diagnostic_only":sr.call("get_public_city_preparation_state")})
	if not check(accepted==true,"PUBLIC_ENTRY:"+row.source_key): return false
	while in_budget() and Time.get_ticks_msec()-began<20000:
		await process_frame
		var field: Node=current_scene
		if not is_instance_valid(field) or field==previous or not field.has_method("get_field_loading_state"): continue
		var loading: Dictionary=field.call("get_field_loading_state")
		if loading.get("failed")==true:
			records.append({"field_failure":loading}); return check(false,"FIELD_FAILURE:"+row.source_key)
		if loading.get("complete")!=true or lm.get("_transition_active")==true or lm.get("_external_active")==true: continue
		var player: Node2D=field.get("_player") as Node2D
		if not is_instance_valid(player) or player.get("can_move")!=true or dp.call("is_playing"): continue
		await RenderingServer.frame_post_draw
		if not check(field.get_script().resource_path==spec.field_script and loading.get("scene_id")==row.physical_id,"EXACT_PHYSICAL_REGION:"+row.source_key): return false
		var region: Dictionary=field.call("get_region27d_state")
		var owner: Dictionary=region.get("owner",{})
		if not check(owner.get("owner_kind")=="REGION_27D" and owner.get("phase")=="LIVE" and owner.get("finalized")==true and typeof(owner.get("token"))==TYPE_INT and owner.token!=0 and owner.get("field_instance")==field.get_instance_id() and owner.get("source_first")==expected and owner.get("source_final")==expected,"NATURAL_FIXED_FIRST_FINAL_NO_COLLECTOR:"+row.source_key): return false
		var camera: Camera2D=field.get("_world_camera") as Camera2D
		if not check(is_instance_valid(camera) and field.get_viewport().get_camera_2d()==camera,"ORIGINAL_ACTIVE_CAMERA_NO_QA_CHANGE"): return false
		var hud: Array=[]
		for label: Node in field.find_children("*","Label",true,false):
			if (label as Label).is_visible_in_tree() and hud.size()<64: hud.append({"path":str(field.get_path_to(label)),"text":(label as Label).text})
		records.append({"view":row.source_key,"entry_elapsed_ms_not_performance":Time.get_ticks_msec()-began,"field":str(field.get_instance_id()),"player":str(player.get_instance_id()),"scene":str(owner.scene_instance),"layout":str(owner.layout_instance),"owner_token":str(owner.token),"source_count":expected.size(),"actual_foot":[player.position.x,player.position.y],"camera":str(camera.get_instance_id()),"zoom":[camera.zoom.x,camera.zoom.y],"visible_label_text_evidence_not_ART_or_functional_pass":hud})
		if not check(in_budget() and png_count<2,"PNG_BUDGET"): return false
		var path: String=OUTPUT_ROOT+str(OS.get_process_id())+"/"+row.source_key+".png"
		if not check(not FileAccess.file_exists(path),"NEW_PNG_ONLY"): return false
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var image: Image=root.get_viewport().get_texture().get_image()
		if not check(image!=null and not image.is_empty() and image.save_png(path)==OK,"ONE_UNALTERED_NATIVE_VIEW:"+row.source_key): return false
		png_count+=1
		records.append({"PNG":path,"sha256":FileAccess.get_sha256(path),"width":image.get_width(),"height":image.get_height(),"camera_or_player_pose_changed_by_QA":false})
		return true
	return check(false,"ENTRY_20S_NO_EXTENSION:"+row.source_key)

func finish() -> void:
	var source_final: Dictionary=facts(source_first.keys())
	var save_final: Dictionary=facts(spec.get("save_paths",[]))
	if not source_first.is_empty(): check(source_first==source_final,"FIXED_SMALL_SOURCE_FIRST_FINAL")
	if not save_first.is_empty(): check(save_first==save_final,"SAVE15_SHA_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path: String=OUTPUT_ROOT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path): printerr("PRESERVE_ORIGINAL_RESULT"); quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var output:=FileAccess.open(path,FileAccess.WRITE)
	if output==null: quit(2); return
	output.store_string(JSON.stringify({"complete":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-started,"records":records,"source_first":source_first,"source_final":source_final,"save_first":save_first,"save_final":save_final,"PNG_count":png_count,"INPUT":0,"Space":0,"QApose_camera_changes":0,"scope":"Visual residual only; no seam/dialogue/Gate/Estate/function/performance/whole-city rerun or ART blanket approval","engine_run_by_QA":false},"\t")+"\n")
	output.close(); print("REGION_VISUAL_VIEWS_RESULT ",path); quit(0 if errors.is_empty() else 1)
