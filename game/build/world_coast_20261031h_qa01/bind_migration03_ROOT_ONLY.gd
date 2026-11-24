extends SceneTree
## Pure new-contract calls before adoption; no Router/Field or save APIs.
const ROOT: String="res://build/world_coast_20261031h_qa01/"
const CONTRACT: String="res://build/world_coast_20261031h_system02/world_v16_contract03.gd"
const SCENE: String="res://build/world_coast_20261031h_system01/world_v16_scene03.tres"
const LAYOUT: String="res://build/world_coast_20261031h_system01/world_v16_layout02.tres"
const STREAM: String="res://build/world_coast_20261031h_system01/world_v16_stream02.tres"
const SIZE:=Vector2(12288,8192)
var suspended:=false
var errors: Array[String]=[]
var records: Array=[]
var checks:=0
var directory: String
var current: Script
var old_contract: Script
var scene: Resource
var old_scene: Resource
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _arg(name: String) -> String:
	var args: PackedStringArray=OS.get_cmdline_user_args();var i: int=args.find(name);return args[i+1] if i>=0 and i+1<args.size() else ""
func _need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("COAST_BIND03_QA_FAIL ",label)
	return ok
func _portal(data: Resource,id: String) -> Dictionary:
	for row: Dictionary in (data.get("map_layout") as Resource).get("portals"):
		if String(row.id)==id:return row
	return {}
func _destination(id: String) -> Vector2:
	var row: Dictionary=_portal(scene,id);return row.get("source_spawn_pos",row.pos)
func _choose(name: String,options: Array[Vector2]) -> Vector2:
	var tested: Array=[]
	for p: Vector2 in options:
		var uv: Vector2=p/SIZE;var was_legal: bool=old_contract.call("safe_foot",old_scene,uv);var now_legal: bool=current.call("safe_foot",scene,uv)
		tested.append({"foot":p,"old15_legal":was_legal,"new16_legal":now_legal})
		if was_legal and not now_legal:records.append({"finite_declared_fixture":name,"tried":tested,"chosen":p,"not_runtime_nearest_or_coordinate_repair":true});return uv
	records.append({"finite_declared_fixture":name,"tried":tested});_need(false,"NO_LEGITIMATE_AFFECTED_POINT_IN_FINITE_FIXTURE:"+name);return Vector2(INF,INF)
func _migrate_named(uv: Vector2,id: String,reason: String) -> bool:
	var result: Variant=current.call("migrate_spawn",uv,15,scene);var debug: Dictionary=current.call("get_last_migration_debug")
	records.append({"source15_uv":uv,"result":result,"debug":debug})
	return _need(result is Vector2 and result==_destination(id) and debug.get("portal_id")==id and debug.get("reason")==reason,"EXACT_DECLARED_NAMED_GATE:"+id+":"+reason)
func _run() -> void:
	await process_frame
	directory=ROOT+"bind_migration03_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	var path: String=_arg("--manifest");var sha: String=_arg("--manifest-sha").to_lower()
	if not _need(suspended and path=="res://art/maps/world_coast_20261031h/candidate02/runtime_contract03.json" and sha.length()==64 and FileAccess.get_sha256(path)==sha,"EXACT_ACTUAL03_MANIFEST_AND_CHECKPOINT_SUSPEND"):_finish();return
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	## Use the actual imported resources. Never inject a fake Texture2D provider.
	for row: Dictionary in data.navigation_tiles:
		if not _need(ResourceLoader.exists(String(row.path),"Texture2D"),"ACTUAL_NAV_TEXTURE_IMPORT_READY:"+String(row.path)):_finish();return
	current=load(CONTRACT) as Script;old_contract=load("res://scripts/world/world_map_v15_contract.gd") as Script
	scene=ResourceLoader.load(SCENE,"",ResourceLoader.CACHE_MODE_IGNORE);old_scene=old_contract.call("source_scene",15) as Resource
	if not _need(scene!=null and (scene.get("map_layout") as Resource).resource_path==LAYOUT and (scene.get("streamed_background") as Resource).resource_path==STREAM,"THIN03_REAL_EXT_RESOURCE_IDENTITIES_NOT_INLINE_SUBRESOURCES"):_finish();return
	if not _need(current.call("is_v16",scene)==true,"ACTUAL_NEW_CONTRACT03_BINDS_PINNED_MANIFEST_AND_PRIVATE_SCENE"):_finish();return
	var ports: Array=[]
	for row: Dictionary in (scene.get("map_layout") as Resource).get("portals"):ports.append({"id":String(row.id),"uv":row.pos})
	for helper_path: String in ["res://build/three_towns_world_20261029j_system01/town_registry.gd","res://build/adventure_world_20261031f_system01/world_links.gd"]:
		var helper: Script=load(helper_path) as Script
		for row: Dictionary in helper.call("portal_rows"):ports.append({"id":String(row.id),"uv":Vector2(row.world_foot)/SIZE})
	if not _need(ports.size()==22,"ACTUAL_TYPED22_SOURCE_POINTS"):_finish();return
	for row: Dictionary in ports:
		if not _need(current.call("safe_foot",scene,row.uv)==true,"NEW16_SAFE_FOOT_WITH_OBJECT_SOLIDS:"+String(row.id)):_finish();return
	var unchanged:=Vector2(6900,4700)/SIZE
	if not _need(old_contract.call("safe_foot",old_scene,unchanged)==true and current.call("safe_foot",scene,unchanged)==true,"UNCHANGED_OLD15_AND_NEW16_LEGITIMATE"):_finish();return
	if not _need(current.call("migrate_spawn",unchanged,15,scene)==unchanged and current.call("migrate_spawn",unchanged,16,scene)==unchanged,"UNCHANGED_LEGITIMATE_FOOT_EXACT_BOTH_VERSIONS"):_finish();return
	for version: int in [-1,17]:
		if not _need(current.call("migrate_spawn",unchanged,version,scene)==null,"UNKNOWN_VERSION_REJECTED:"+str(version)):_finish();return
	var mainland: Vector2=_choose("mainland_cut",[Vector2(10900,3000),Vector2(10900,3200),Vector2(11000,3400),Vector2(11050,2800)])
	if not mainland.is_finite() or not _migrate_named(mainland,"bailu_ferry","declared_historic_domain_gate"):_finish();return
	var island: Vector2=_choose("island_cut",[Vector2(11700,2400),Vector2(12050,3800),Vector2(12190,3300),Vector2(11400,3920)])
	if not island.is_finite() or not _migrate_named(island,"east_sea_port","declared_historic_domain_gate"):_finish();return
	if not _need(current.call("migrate_spawn",mainland,16,scene)==null,"NEW16_UNSAFE_SEA_REJECTS_NO_HISTORIC_WARP"):_finish();return
	var old_gate: Dictionary=_portal(old_scene,"bianzhou")
	if not _need(old_contract.call("safe_foot",old_scene,old_gate.pos)==true,"OLD_BIANZHOU_GATE_LEGITIMATE_BEFORE_MIGRATION") or not _migrate_named(old_gate.pos,"bianzhou","same_moved_portal_id"):_finish();return
	var covered: Vector2=_choose("new_bianzhou_body_old_grass",[Vector2(7380,1480),Vector2(7800,1480),Vector2(7460,1460),Vector2(7890,1450)])
	if not covered.is_finite() or not _migrate_named(covered,"bianzhou","declared_historic_domain_gate"):_finish();return
	var illegal:=Vector2(INF,INF)
	for row: Dictionary in (old_scene.get("map_layout") as Resource).get("visual_objects"):
		if String(row.get("id",""))!="compound_east_sea_port":continue
		var polygon: PackedVector2Array=row.solid_polygons_px[0];var triangles: PackedInt32Array=Geometry2D.triangulate_polygon(polygon)
		illegal=(polygon[triangles[0]]+polygon[triangles[1]]+polygon[triangles[2]])/3.0/SIZE;break
	if not _need(illegal.is_finite() and old_contract.call("safe_foot",old_scene,illegal)==false,"DECLARED_OLD_BODY_TRIANGLE_INTERIOR_NOT_LEGITIMATE15"):_finish();return
	if not _need(current.call("migrate_spawn",illegal,15,scene)==null and (current.call("get_last_migration_debug") as Dictionary).get("reason")=="source15_not_legitimate","OLD_ILLEGAL_FOOT_REJECTED_NOT_MIGRATED_TO_A_GATE"):_finish();return
	records.append({"actual_contract_path":CONTRACT,"actual_contract_sha256":FileAccess.get_sha256(CONTRACT),"scene03_sha256":FileAccess.get_sha256(SCENE),"manifest03_sha256":sha,"navigation_cache_debug":current.call("get_navigation_cache_debug")})
	_finish()
func _finish() -> void:
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"scene_instances":0,"input_events":0,"real_save_API_calls":0,"public_Router_calls":0,"production_writes":0,"scope":"private03 real external identities,actual imported NAV+object solids,22safe feet and finite version15/16 migration cases only"},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
