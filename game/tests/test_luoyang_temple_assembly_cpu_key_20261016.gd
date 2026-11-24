extends SceneTree
## New temple only: source/import/storage/geometry/task data, not native Field.
const SOURCE_READY=true
const A=preload("res://scripts/city/luoyang_temple_assembly_20261016.gd")
const TASK=preload("res://scripts/city/luoyang_temple_task_adapter_20261016.gd")
const ORACLE=preload("res://tests/helpers/temple_assembly_raw_oracle_20261016.gd")
const PINS={"res://tests/helpers/temple_assembly_raw_oracle_20261016.gd":"d66cdad0a2f1cfd172f7ffc083f142e22723ae181f2b1ca0451389d801a506ae","res://scripts/city/luoyang_temple_assembly_20261016.gd":"5f72bb04544b30b05a72ee0a6684efb4de19b32433a20276967cf1301118d278","res://scripts/city/luoyang_temple_task_adapter_20261016.gd":"e8d3537f5aa8e7ec1e071586f692bc2f52f4a5cab822732f4f4195e9141fc122","res://scripts/city/luoyang_temple_fade_20261016.gd":"7c2aa06111ca88e0a048cac17450368790b682cec813e812ad9c774d81fdfb2b"}
const FINAL_BIND_SHA="2e2efab349e96d3c2da702da860a0dc54e497ab674a4130173baa9e3d4248f5f"
const PUBLISHER_PATH="res://build/luoyang_temple_assembly_publication_20261016/111788_1609/result.json"
const PUBLISHER_SHA="ea8b86c2bc79a61d46c178ea8dfa1fb73d29684a7cd46e440a2f817ee11721df"
const WORLD=Vector2(1920,1280)
var checks:=0
var failures:=0
var deadline:=0
var before: Dictionary={}
var players: Dictionary={}
var rows: Array[Dictionary]=[]
var config: Dictionary={}
var author: Dictionary={}
var child: SceneScript
var geometry: RefCounted
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok: failures+=1; printerr("TEMPLE_KEY_FAIL ",label," ",detail)
	return ok
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime":0}
	var file:=FileAccess.open(path,FileAccess.READ)
	var count:=file.get_length(); file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":count,"mtime":FileAccess.get_modified_time(path)}
func saves() -> Dictionary:
	var result: Dictionary={}
	for index: int in 5:
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path:="user://save_"+str(index)+suffix
			result[path]=fact(path)
	return result
func track(path: String,sha: String="") -> bool:
	var value:=fact(path)
	if not check(value.exists and value.sha256.length()==64 and (sha.is_empty() or value.sha256==sha.to_lower()),"Exact source "+path): return false
	if before.has(path): return check(before[path]==value,"Duplicate source remains exact "+path)
	before[path]=value; return true
func precheck() -> bool:
	if not check(SOURCE_READY,"Explicit final source readiness; draft refuses"): return false
	for path: String in PINS:
		if not track(path,PINS[path]): return false
	if not check(not A.FORMAL_ENABLED and A.FLAG in OS.get_cmdline_user_args() and A.BIND_SHA==FINAL_BIND_SHA,"Exact candidate flag and final binding") or not track(PUBLISHER_PATH,PUBLISHER_SHA): return false
	config=A.binding(); author=A.author(config)
	if not check(A.structure_valid(config,author),"Full new PNG/import/ctex structure, no old city receipt"): return false
	if not track(A.BIND_PATH,A.BIND_SHA): return false
	for path: String in config.source_sha256:
		if not track(path,config.source_sha256[path]): return false
	for path: String in A.source_paths():
		if not before.has(path) and not track(path): return false
	child=ResourceLoader.load(A.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	geometry=ORACLE.new()
	return check(child!=null and A.is_scene(child) and child.actor_positions_are_feet and geometry.configure(author,WORLD),"New exact child and independent source-feet/cover polygons") and track(get_script().resource_path)
func task_states() -> bool:
	var original:=A.original_scene()
	if not check(original!=null and original.hotspots.size()==8,"Real immutable canonical, not disguised child"): return false
	var actions: Array=A.legacy_interactions(original)
	var portals: Array=A.legacy_portals(original)
	var oldtask: Variant=load("res://scripts/city/luoyang_city_tasks_20261016.gd")
	var eq: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	var relocation: Dictionary={}
	var expected_input: Array=actions.duplicate(true)
	for mapping: Dictionary in author.get("interaction_relocations",[]):
		var id: String=String(mapping.get("id",""))
		if not check(mapping.size()==5 and mapping.get("semantic_delta")=="POSITION_ONLY_ACTION_FLAGS_QUEST_AND_REWARD_UNCHANGED" and not relocation.has(id),"Exactly one explicit old/new-only interaction relocation "+id): return false
		var found:=false
		for item: Dictionary in expected_input:
			if item.id!=id: continue
			var old:=Vector2(mapping.old_pos_uv[0],mapping.old_pos_uv[1])
			var next:=Vector2(mapping.new_pos_uv[0],mapping.new_pos_uv[1])
			if not check(item.pos==old and next.is_finite() and Vector2(mapping.new_foot_px[0],mapping.new_foot_px[1])/Vector2(1536,1024)==next,"Exact source anchor, no epsilon/nearest "+id): return false
			item.pos=next; found=true
		if not check(found,"Only existing original functional ID may relocate"): return false
		relocation[id]=mapping
	if not check(relocation.size()==6 and eq._equal_value(child.map_layout.interactions,expected_input),"All six input interactions differ only by explicit authored position"): return false
	var profiles: Array=[{"name":"not_started","flags":{},"states":{}},{"name":"accepted_no_hint","flags":{"luoyang_paper_started":true},"states":{oldtask.PAPER:1}},{"name":"hint","flags":{"luoyang_paper_started":true,"luoyang_paper_artisan_hint":true},"states":{oldtask.PAPER:1}},{"name":"materials","flags":{"luoyang_paper_started":true,"luoyang_paper_artisan_hint":true,"luoyang_paper_materials_found":true},"states":{oldtask.PAPER:1}},{"name":"completed","flags":{"luoyang_paper_started":true,"luoyang_paper_helped":true},"states":{oldtask.PAPER:2}}]
	for profile: Dictionary in profiles:
		var real: Dictionary=oldtask.project(original,profile.flags,profile.states,actions)
		var projected: Dictionary=TASK.project(child,profile.flags,profile.states,child.map_layout.interactions,child.map_layout.visual_objects)
		var expected: Array=real.interactions.duplicate(true)
		for item: Dictionary in expected:
			var map: Dictionary=relocation[item.id]
			item.pos=Vector2(map.new_pos_uv[0],map.new_pos_uv[1])
		var paper:=false
		for item: Dictionary in projected.get("interactions",[]):
			if item.id=="legacy_hotspot_3": paper=item.action=="dialog:luoyang_city_tasks_20261016/paper_materials"
		if not check(real.ok and projected.get("ok")==true and eq._equal_value(expected,projected.interactions) and eq._equal_value(child.map_layout.portals,portals) and eq._equal_value(projected.visual_objects,child.map_layout.visual_objects) and paper==(profile.name=="hint"),"Real canonical TASK five-state exact projection then only authored positions "+String(profile.name)): return false
		rows.append({"kind":"PURE_TASK_STATE","profile":profile.name,"paper_materials_visible":paper,"only_data_projection_no_dialog_or_reward_execution":true})
	return check(actions.size()==6 and portals.size()==2,"Six source action definitions and two exact exits preserved")
func texture_bytes() -> bool:
	for proof: Dictionary in config.texture_proofs:
		var raw:=Image.load_from_file(proof.texture)
		var texture:=ResourceLoader.load(proof.texture) as Texture2D
		var compiled:=CompressedTexture2D.new()
		if not check(raw!=null and texture!=null and compiled.load(proof.compiled_path)==OK,"Actual PNG/imported/nativeCTEX all exist"): return false
		var imported:=texture.get_image(); var direct:=compiled.get_image()
		for image: Image in [raw,imported,direct]:
			if image==null: return check(false,"Actual full image, not proof-only dimensions")
			if image.is_compressed() and not check(image.decompress()==OK,"Lossless image read only decompression"): return false
			image.convert(Image.FORMAT_RGBA8)
		var expected:=Vector2i(proof.size_px[0],proof.size_px[1])
		if not check(raw.get_size()==expected and imported.get_size()==expected and direct.get_size()==expected and imported.get_mipmap_count()==0 and direct.get_mipmap_count()==0 and raw.get_data()==imported.get_data() and raw.get_data()==direct.get_data(),"Actual PNG-import-CTEX fullRGBA exact, including alpha1 tails"): return false
		rows.append({"kind":"ACTUAL_SOURCE_IMPORT_CTEX_FULL_RGBA","texture":proof.texture,"size":expected,"rgba_sha256":proof.rgba_sha256,"alpha_tail_not_edited_or_thresholded":true})
	return true
func exercise_cpu() -> bool:
	if not texture_bytes(): return false
	var session:=A.new()
	if not await session.prepare(child,func() -> bool: return true): return check(false,"Actual six imported textures/full child storage",session.state())
	if not await session.finalize(child,func() -> bool: return true): return check(false,"Independent owned first/final source SHA",session.state())
	var proof:=session.state()
	if not check(proof.finalized and proof.source_first==proof.source_final and proof.scope=="TEMPLE_OWN_FIELD_NOT_C_CITY_RECEIPT","Actual temple source proof, not old C receipt"): return false
	session.release()
	for route: Dictionary in author.required_routes:
		var points: PackedVector2Array=geometry.polygon(route.points_px,WORLD/Vector2(1536,1024))
		for index: int in range(1,points.size()):
			var result: Dictionary=geometry.segment(points[index-1],points[index])
			if not check(result.clear and Time.get_ticks_msec()<deadline,"New route complete continuous34x24/round875/17/4px "+String(route.id),result): return false
	for mapping: Dictionary in author.interaction_relocations:
		if not check(geometry.clear(Vector2(mapping.new_foot_px[0],mapping.new_foot_px[1])*WORLD/Vector2(1536,1024)),"All six exact relocated interaction feet independently clear"): return false
	for pair: Array in author.preserved_portal_and_default_uv:
		if not check(geometry.clear(Vector2(pair[0],pair[1])*WORLD),"Original functional/exit/default anchor independently clear"): return false
	for point: Dictionary in author.get("negative_points",[]):
		if not check(not geometry.clear(Vector2(point.foot_px[0],point.foot_px[1])*WORLD/Vector2(1536,1024)),"Real new solid negative "+String(point.id)): return false
	return task_states()
func finish(prefix: String,began: int,complete: bool) -> void:
	var after: Dictionary={}
	for path: String in before: after[path]=fact(path)
	var player_after:=saves()
	check(before==after and players==player_after and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"Exact own source/15 saves; no restoration")
	check(complete and Time.get_ticks_msec()<deadline,"Predeclared finite whole scope")
	var folder:="res://build/"+prefix+"/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(folder)
	var file:=FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"records":rows,"source_before":before,"source_after":after,"players_before":players,"players_after":player_after},"\t")); file.close()
	else: failures+=1
	print("TEMPLE_KEY_RESULT=",folder,"/result.json")
	quit(0 if complete and failures==0 else 1)
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+15000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players=saves()
	var complete:=false
	if precheck(): complete=await exercise_cpu()
	finish("luoyang_temple_assembly_cpu_20261016",began,complete)
