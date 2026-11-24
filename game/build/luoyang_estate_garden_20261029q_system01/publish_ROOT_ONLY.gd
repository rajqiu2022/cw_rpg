extends SceneTree
## Root-only rear-garden delta. No current bin/source/media/save writes.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const HOME:="res://build/luoyang_estate_garden_20261029q_system01/"
const MANIFEST:="res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const EXPECTED:="25d82b408f331230ad133eaaca73fda5d80494677cec65cb8f3f0bdc232425f5"
const REGION:="luoyang_estate_region_27d"
const LOGICAL:="luoyang_estate_riverside_20261021ai"
const ROOM:="estate27d_living_hall"
const ENTRY:="res://build/luoyang_regions_20261027d_source01/region_entry.gd"
const OLD_SHA:="a3a1af2a473809638fd15ed2788c0a477a1ac17c65672856003cd2c4b0540561"
var output: String
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(test: bool,label: String) -> bool:
	checks+=1
	if not test:failures.append(label);push_error(label)
	return test
func write_json(path: String,data: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data,"  ")+"\n");file.close()
func binding(path: String) -> Dictionary:
	return {"path":path,"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size()}
func polygon(raw: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in raw:result.append(Core.vec(point))
	return result
func media(path: String,pins: Dictionary) -> bool:
	if not FileAccess.file_exists(path):return false
	pins[path]=FileAccess.get_sha256(path)
	var sidecar: String=path+".import"
	if not FileAccess.file_exists(sidecar):return false
	var expression:=RegEx.new();expression.compile('path="(res://[^"\\r\\n]+\\.ctex)"')
	var found: RegExMatch=expression.search(FileAccess.get_file_as_string(sidecar))
	if found==null or not FileAccess.file_exists(found.get_string(1)):return false
	pins[sidecar]=FileAccess.get_sha256(sidecar);pins[found.get_string(1)]=FileAccess.get_sha256(found.get_string(1))
	return true
func finish() -> void:
	write_json(output+"result.json",{"passed":false,"checks":checks,"failures":failures,"production_writes":0});quit(1)
func run() -> void:
	output=HOME+"output/"+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(output)
	if not check(FileAccess.get_sha256(MANIFEST)==EXPECTED,"CURRENT29P_MANIFEST"):finish();return
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var previous_bindings: Dictionary=manifest.compiled_bindings.duplicate(true)
	var old_binding: Dictionary=manifest.compiled_bindings[REGION]
	if not check(old_binding.sha256==OLD_SHA and FileAccess.get_sha256(old_binding.path)==OLD_SHA,"ESTATE29O_SOURCE_BIN"):finish();return
	var estate: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(old_binding.path))
	var before: Dictionary=estate.duplicate(true)
	var spec_path: String=HOME+"garden_definition_READY.json"
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec_path))
	if not check(spec.get("region_id")==REGION and spec.get("schema")=="ESTATE29Q_GARDEN_DELTA_V1","EXACT_GARDEN_DEFINITION"):finish();return
	var field_script: GDScript=load(HOME+"region_field_READY.gd") as GDScript
	var entry_script: GDScript=load(HOME+"region_entry_READY.gd") as GDScript
	if not check(field_script!=null and field_script.can_instantiate() and entry_script!=null and entry_script.can_instantiate(),"NEW_FIELD_ENTRY_GARDEN_HELPERS_PARSE"):finish();return
	var pins: Dictionary={spec_path:FileAccess.get_sha256(spec_path),old_binding.path:OLD_SHA}
	var ground_rows: Array=estate.surfaces.filter(func(row: Dictionary)->bool:return row.get("id")=="private_garden")
	var cross_rows: Array=estate.surfaces.filter(func(row: Dictionary)->bool:return row.get("id")=="rear_cross")
	if not check(ground_rows.size()==1 and cross_rows.size()==1,"ORIGINAL_GARDEN_AND_CROSS_UNIQUE"):finish();return
	var green: Dictionary=spec.get("groundcover",{})
	if not check(media(String(green.get("texture","")),pins),"REUSED_GARDEN_GROUND_MEDIA"):finish();return
	for route: Dictionary in spec.garden_routes:
		if not check(media(route.texture,pins),"REUSED_GARDEN_PATH_MEDIA:"+str(route.id)):finish();return
	for area: Rect2 in [Rect2(400,1184,30,144),Rect2(2642,1184,30,144)]:
		estate.floor_rects.append(area)
		var link: Dictionary=cross_rows[0].duplicate(true)
		link.id="garden29q_side_connector_"+str(int(area.position.x));link.rect=[[area.position.x,area.position.y],[area.size.x,area.size.y]]
		estate.surfaces.append(link)
	var indices: Array=[]
	for change: Dictionary in spec.get("existing_changes",[]):
		var selected: Array=estate.render.filter(func(row: Dictionary)->bool:return row.get("id")==change.id)
		if not check(change.id=="estate_tree_nw" and selected.size()==1 and selected[0].foot_px==Core.vec(change.original_foot_px) and int(change.solid_index)==2,"EXACT_ONE_EXISTING_TREE_MOVE"):finish();return
		var delta: Vector2=Core.vec(change.new_foot_px)-selected[0].foot_px
		selected[0].foot_px+=delta;selected[0].position_px+=delta
		var moved:=PackedVector2Array()
		for point: Vector2 in estate.solids[int(change.solid_index)]:moved.append(point+delta)
		estate.solids[int(change.solid_index)]=moved;indices.append(int(change.solid_index))
	if not spec.get("existing_changes",[]).is_empty():
		var all_solids: Array=estate.solids;estate.solids=[];estate.solid_cells={}
		for shape: PackedVector2Array in all_solids:Core._append_solid(estate,shape)
	for asset: Dictionary in spec.get("assets",[]):
		var foot: Vector2=Core.vec(asset.get("foot_px"))
		var anchor: Vector2=Core.vec(asset.get("anchor_px"))
		var dimensions: Vector2=Core.vec(asset.get("texture_size_px"))
		var ratio: float=float(asset.get("scale",0))
		var id: String=String(asset.get("id",""))
		if not check(id.begins_with("garden29q_") and foot.is_finite() and anchor.is_finite() and ratio>0 and media(String(asset.get("texture","")),pins),"NEW_GARDEN_ASSET_SOURCE:"+id):finish();return
		var texture: Texture2D=load(asset.texture) as Texture2D
		if not check(texture!=null and texture.get_size()==dimensions,"NATIVE_ASSET_DIMENSIONS:"+id):finish();return
		estate.render.append({"id":id,"owner_id":id,"key":LOGICAL+"/"+id,"logical_id":LOGICAL,"texture":asset.texture,"texture_size_px":dimensions,"position_px":foot-anchor*ratio,"foot_px":foot,"scale":Vector2.ONE*ratio,"centered":false,"source_row":{"sort_by_feet":bool(asset.get("sort_by_feet",true)),"z_index":int(asset.get("z_index",-5))}})
		for raw: Array in asset.get("ground_polygons_px",[]):
			var shape:=PackedVector2Array()
			for point: Vector2 in polygon(raw):shape.append(foot+(point-anchor)*ratio)
			if not check(shape.size()>=3,"SOURCE_GARDEN_BODY_HAS_POLYGON:"+id):finish();return
			indices.append(estate.solids.size());Core._append_solid(estate,shape)
	if not check(not indices.is_empty(),"REAL_POND_OR_PLANT_BODY_REQUIRED"):finish();return
	var portal: Dictionary={"id":"estate27q_hall_rear_door","key":LOGICAL+"/estate27q_hall_rear_door","logical_id":LOGICAL,"foot":Vector2(1536,1450),"foot_px":Vector2(1536,1450),"size_px":Vector2(144,64),"legacy_source_uv":Vector2(.5,.947265625),"return_foot":Vector2(1536,1450),"data":{"id":"estate27q_hall_rear_door","pos":Vector2(1536,1450)/Vector2(3072,4096),"source_spawn_pos":Vector2(1536,1450)/Vector2(3072,4096),"size":Vector2(144,64)/Vector2(3072,4096),"target_scene":ROOM,"target_pos":Vector2(960,240)/Vector2(1920,1440),"label":"返回会客正厅","auto_trigger":false,"region27d_target":{"region_id":ROOM,"logical_id":ROOM,"foot_px":[960,240]}}}
	estate.portals.append(portal);estate.sources.merge(pins,true)
	estate["garden29q_restore"]={"spec":spec_path,"source_sha256":pins[spec_path],"target":Vector2(1536,1450),"new_solid_indices":indices}
	estate["garden29q_visual"]={"spec":spec_path,"source_sha256":pins[spec_path]}
	var rollback: Dictionary=estate.duplicate(true)
	for key: String in ["floor_rects","surfaces","render","solids","solid_cells","portals","sources"]:rollback[key]=before[key]
	rollback.erase("garden29q_restore")
	rollback.erase("garden29q_visual")
	check(var_to_bytes(rollback)==var_to_bytes(before),"OTHER_ESTATE_FIELDS_NPCS_MIGRATIONS_TYPED_IDENTICAL")
	check(Core.safe_body(estate,Vector2(1536,1450),Vector2(17,12)) and Core.npc_route_clear(estate,Vector2(1536,1450),Vector2(1536,1450),Vector2(17,12)),"REAR_PORTAL_AND_RESTORE_TARGET_SAFE")
	check(not Core.safe_body(estate,Vector2(1536,1680),Vector2(17,12)),"HOUSE_REAR_120PX_VOID_NOT_FILLED")
	check(var_to_bytes(estate.solids[before.solids.size()-1])==var_to_bytes(before.solids[-1]),"29O_SOUTH_THRESHOLD_UNCHANGED")
	for route: Dictionary in spec.get("routes",[]):
		var points: Array=route.get("points_px",[])
		if not check(points.size()>=2,"GARDEN_ROUTE_SCHEMA:"+str(route.get("id",""))):finish();return
		for i: int in range(1,points.size()):
			var a: Vector2=Core.vec(points[i-1]);var b: Vector2=Core.vec(points[i])
			if not check(Core.safe_segment(estate,a,b,Vector2(17,12)) and Core.npc_route_clear(estate,a,b,Vector2(17,12)),"GARDEN_FULL_BODY_ROUTE:"+str(route.id)+":"+str(i)):finish();return
	if not failures.is_empty():finish();return
	var path: String=output+REGION+".bin"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(var_to_bytes(estate));file.close()
	check(var_to_bytes(bytes_to_var(FileAccess.get_file_as_bytes(path)))==var_to_bytes(estate),"NEW_GARDEN_BIN_TYPED_ROUNDTRIP")
	manifest.compiled_bindings[REGION]=binding(path)
	for id: String in previous_bindings:
		if id!=REGION:check(var_to_bytes(manifest.compiled_bindings[id])==var_to_bytes(previous_bindings[id]),"OTHER_NINE_BINDINGS_IDENTICAL:"+id)
	manifest.runtime_modules[ENTRY]=FileAccess.get_sha256(HOME+"region_entry_READY.gd")
	manifest.runtime_modules[HOME+"garden_restore.gd"]=FileAccess.get_sha256(HOME+"garden_restore.gd")
	manifest.runtime_modules["res://build/luoyang_regions_20261027d_source01/region_field.gd"]=FileAccess.get_sha256(HOME+"region_field_READY.gd")
	manifest.runtime_modules[HOME+"garden_visual.gd"]=FileAccess.get_sha256(HOME+"garden_visual.gd")
	write_json(output+"region_runtime_manifest_READY.json",manifest)
	var result: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"manifest":binding(output+"region_runtime_manifest_READY.json"),"estate":manifest.compiled_bindings[REGION],"all_other_nine_bindings_29o_threshold_29p_room_inherited":true,"new_solid_count":indices.size(),"production_writes":0}
	write_json(output+"result.json",result);print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
