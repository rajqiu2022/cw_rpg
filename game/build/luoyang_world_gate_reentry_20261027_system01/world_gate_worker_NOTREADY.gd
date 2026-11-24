extends "res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd"
## Only normal World -> Gate dispatch. World doorstep setup is explicit QA setup,
## not a city near-spawn, default World spawn benchmark, or saved-game restore.
const CITY=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const WORLD: StringName=&"world_map_jianghu"
const GATE: StringName=&"ch4_s0_luoyang_gate"
var exits: Array=[]

func diagnostics(label: String) -> Dictionary:
	var current: Node=tree.current_scene
	var resource: SceneScript=current.get("_current_scene") as SceneScript if is_instance_valid(current) and current.has_method("get_field_loading_state") else null
	return {"label":label,"router_field":String(router().get("_current_field_id")),"current_scene_instance":current.get_instance_id() if is_instance_valid(current) else 0,"scene_id":String(resource.scene_id) if resource!=null else "","public":router().call("get_public_city_preparation_state"),"C_state":CITY.transition_validation_state(),"C_errors":CITY.errors(),"portal_preparing":router().get("_portal_preparing"),"dialog_playing":dp().get("_is_playing"),"exit_events":exits.duplicate(true)}

func precheck() -> bool:
	if not check(spec.get("ready")==true and spec.get("formal_deployed")==true and spec.get("whole_ms")==60000 and spec.get("entry_ms")==20000,"FIXED_NORMAL_WORLD_GATE_ONLY"): return false
	first=facts(spec.dependencies.keys())
	for path: String in spec.dependencies:
		if not check(first[path].get("sha256")==spec.dependencies[path],"FIXED_FORMAL_SOURCE:"+path): return false
	return check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and tree.root.get_visible_rect().size==Vector2(1920,1080),"NORMAL_GUI_NO_CAMERA_SPEED_OR_SOURCE_WRITE")

func arrive_once(id: StringName,started_us: int) -> bool:
	var until: int=mini(deadline,int(started_us/1000)+20000)
	while Time.get_ticks_msec()<until:
		var current: Node=tree.current_scene
		if is_instance_valid(current) and current.has_method("get_field_loading_state"):
			var resource: SceneScript=current.get("_current_scene") as SceneScript
			if resource!=null and resource.scene_id==id:
				var state: Dictionary=current.call("get_field_loading_state")
				if state.get("failed")==true: return check(false,"ACTUAL_FIELD_REJECT_NO_RETRY",{"loading":state,"diagnostic":diagnostics("field_reject")})
				var p: CharacterBody2D=current.get("_player") as CharacterBody2D
				if state.get("complete")==true and p!=null and p.can_move and hidden():
					field=current;scene=resource;await RenderingServer.frame_post_draw
					var draw_us: int=Time.get_ticks_usec()
					records.append({"kind":"NORMAL_ENTRY_DRAW","scene":String(id),"elapsed_us":draw_us-started_us,"foot":p.position,"loading_profile":current.call("get_field_loading_profile"),"diagnostic":diagnostics("draw_frozen_before_getters")})
					return true
		await tree.process_frame
	return check(false,"FIXED20S_ORDINARY_ENTRY_NO_RETRY",diagnostics("timeout"))

func exercise() -> bool:
	# Fixed native V15 author, not an observed runtime location. Read the original
	# portal's normalized pos; its authored target remains (.5,.9), version 1.
	var original: SceneScript=load(spec.world_scene.path) as SceneScript
	if not check(original!=null and original.scene_id==WORLD and original.map_layout!=null,"FIXED_ORIGINAL_WORLD_RESOURCE"): return false
	var declared: Array=[]
	for row: Dictionary in original.map_layout.portals:
		if row.get("id")=="luoyang": declared.append(row)
	if not check(declared.size()==1,"UNIQUE_SOURCE_WORLD_LUOYANG_PORTAL"): return false
	var source: Dictionary=declared[0]
	if not check(source.get("target_scene")==String(GATE) and source.get("target_pos")==Vector2(.5,.9) and source.get("auto_trigger")==false,"ORIGINAL_WORLD_TARGET_UV_UNCHANGED"): return false
	var started_us: int=Time.get_ticks_usec()
	if not check(router().call("go_field_smart",WORLD,source.pos,"",15),"PUBLIC_WORLD_DOORSTEP_SETUP_NOT_CITY_NEAR"): return false
	if not await arrive_once(WORLD,started_us): return false
	if not check(field.get("_world_size")==Vector2(12288,8192) and player().position.distance_to(source.pos*Vector2(12288,8192))<=.3,"EXPLICIT_WORLD_SOURCE_FOOT_NO_INSPECTION_WRITE"): return false
	for stage: int in range(2): await tree.physics_frame;await tree.process_frame
	var targets: Array=[]
	for zone: Node in field.get("_exit_nodes"):
		var can: Variant=zone.call("can_enter") if zone.has_method("can_enter") else zone.get("_in_range")
		records.append({"kind":"WORLD_EXIT_BEFORE_INPUT","node":String(zone.name),"position":zone.get("position"),"target":zone.get("target_scene_id"),"target_spawn":zone.get("target_spawn_pos"),"locked":zone.get("is_locked"),"can_enter":can})
		if zone.get("target_scene_id")==String(GATE): targets.append(zone)
	if not check(targets.size()==1,"UNIQUE_REAL_WORLD_GATE_EXIT"): return false
	var target: Area2D=targets[0] as Area2D
	if not check(target!=null and target.get_script().resource_path=="res://scripts/field/world_v15_exit_zone.gd" and target.call("can_enter")==true and target.get("target_spawn_pos")==Vector2(.5,.9) and target.get("is_locked")==false and target.get("auto_trigger")==false,"ORIGINAL_PUBLIC_WORLD_CAN_ENTER"): return false
	target.connect("exit_triggered",func(destination: String,uv: Vector2) -> void: exits.append({"target":destination,"uv":uv}))
	records.append(diagnostics("before_only_space"))
	started_us=Time.get_ticks_usec();await driver.key(KEY_SPACE);space_calls+=1
	if not await arrive_once(GATE,started_us): return false
	var proof: Dictionary=CITY._resident_ready
	var lease: Dictionary=field.call("get_finish25i_state")
	if not check(exits.size()==1 and exits[0].target==String(GATE) and exits[0].uv==Vector2(.5,.9),"ONE_REAL_WORLD_SPACE_NO_ROUTER_SHORTCUT"): return false
	if not check(proof.get("scene")==scene and proof.get("id")==GATE and proof.get("sources_finalized")==true and proof.get("sources")==spec.expected_gate_sources,"NATURAL_GATE_ORIGINAL_FIRST_FINAL_FIXED_SOURCE_MAP"): return false
	if not check(lease.get("finalized")==true and lease.get("scene_instance")==scene.get_instance_id() and player().position.distance_to(Vector2(1536,1860))<=.3,"DEFAULT_AUTHORED_GATE_FOOT_AND_REAL_FINISH_LEASE"): return false
	var moved: Dictionary=await driver.drive(field,Vector2(1536,1828),func(foot: Vector2) -> bool: return budget() and foot.is_finite() and tree.current_scene==field and player().can_move)
	records.append({"kind":"GATE32PX_REAL_INPUT","movement":moved})
	if not check(moved.get("ok")==true and hidden(),"ORDINARY_ENTRY_OPERABLE"): return false
	await RenderingServer.frame_post_draw
	var image: Image=tree.root.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(1920,1080),"UNMODIFIED_CURRENT_CAMERA"): return false
	var image_path: String=output+"normal_world_to_gate.png"
	if not check(image.save_png(image_path)==OK,"ONE_GATE_IMAGE"): return false
	pictures+=1;records.append({"kind":"NORMAL_GATE_CURRENT_CAMERA","path":image_path,"sha256":FileAccess.get_sha256(image_path)})
	return true

func run(owner_tree: SceneTree,fixture: Dictionary) -> void:
	tree=owner_tree;spec=fixture;began=Time.get_ticks_msec();deadline=began+60000
	output=String(spec.output_root)+str(OS.get_process_id())+"/"
	if DirAccess.dir_exists_absolute(output): tree.quit(2);return
	DirAccess.make_dir_recursive_absolute(output);saves_first=saves();gameplay_first=gameplay()
	var complete: bool=false
	if precheck() and check(FileAccess.get_sha256(DRIVER_PATH)==DRIVER_SHA,"MATURE_REAL_INPUT_DRIVER"):
		var input_script: GDScript=load(DRIVER_PATH) as GDScript
		if check(input_script!=null and input_script.can_instantiate(),"INPUT_DRIVER_LOAD"):
			driver=input_script.new();driver.configure(tree);complete=await exercise()
	if driver!=null: driver.release()
	var last: Dictionary=facts(spec.get("dependencies",{}).keys());var last_saves: Dictionary=saves()
	check(first==last,"FORMAL_SOURCE_HEAD_UNCHANGED");check(saves_first==last_saves,"15_SAVE_FACTS_UNCHANGED_ROOT_EXTERNAL_EXACTTICKS");check(gameplay_first==gameplay(),"NO_GAMEPLAY_OR_QUEST_CHANGES")
	check(complete and budget() and space_calls==1 and pictures<=1,"FIXED60S_ONE_WORLD_SPACE_NO_RETRY")
	var report: Dictionary={"complete":complete and errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"pictures":pictures,"Space_calls":space_calls,"source_first":first,"source_final":last,"save_first":saves_first,"save_final":last_saves,"collector_calls":0,"position_writes":0,"camera_writes":0,"claim":"Only normal World luoyang Space -> default Gate arrival and basic operability; World doorstep is explicit QA setup. No other city, saved-game restore, loading target, or whole-city claim."}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: tree.quit(2);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close();print("NORMAL_WORLD_GATE ",output+"result.json");tree.quit(0 if report.complete else 1)
