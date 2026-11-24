extends SceneTree
## Root-only post-parse geometry/business smoke. No field instances or old matrix.
const OUT := "res://build/three_settlements_20261030e_qa01/geometry_ROOT_ACTUAL.json"
const ROOTS: Array[String]=[
	"res://build/three_settlements_20261030e_system01/xiangzhou_author.gd",
	"res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd",
	"res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd"]
var errors: Array[String]=[]
var records: Array=[]
var checks: int=0
var assets: Dictionary={}
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("30E_GEOMETRY_FAIL ",label)
	return ok
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	if FileAccess.file_exists(OUT):push_error("IMMUTABLE_GEOMETRY_OUTPUT_EXISTS");quit(2);return
	for path: String in ROOTS:verify_author(path)
	var file:=FileAccess.open(OUT,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"referenced_assets":assets,"field_instances":0,"engine_calls_by_qa":0,"gpu_claim":false,"save_contents_read":false,"save_writes":0,"production_writes":0},"\t"));file.close()
	print("30E_GEOMETRY_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
func verify_author(path: String) -> void:
	var author: Variant=load(path)
	if not need(author!=null and author.can_instantiate(),"LOAD:"+path):return
	var id: String=String(author.ID)
	var original: Resource=load("res://data/scenes/"+id+".tres")
	var scene: Resource=author.scene()
	var layout: Resource=scene.get("map_layout")
	if not need(original!=null and scene!=null and layout!=null,"SCENE:"+id):return
	for key: String in ["scene_id","bgm_path","ambience_path","ambience_volume_db","on_enter_dialog","on_enter_require_flag","on_enter_once_flag","hotspots","is_walkable","actor_positions_are_feet","is_settlement","exits","trigger_zones","encounter_enemy_ids","encounter_groups","encounter_allow_full_group_for_solo","encounter_step_distance","encounter_chance","encounter_require_flag"]:
		need(scene.get(key)==original.get(key),"ORIGINAL_BUSINESS:"+id+":"+key)
	var old_npcs: Array=original.get("npcs");var new_npcs: Array=scene.get("npcs")
	for old: Dictionary in old_npcs:
		var matches: Array=[]
		for npc: Dictionary in new_npcs:
			if npc.get("npc_id")==old.get("npc_id"):matches.append(npc)
		if not need(matches.size()==1,"OLD_NPC_EXACT_ID:"+id+":"+String(old.get("npc_id"))):continue
		for key: String in old:
			if key!="pos":need(matches[0].get(key)==old[key],"OLD_NPC_FIELD:"+id+":"+key)
	var old_layout: Resource=original.get("map_layout")
	for section: String in ["portals","interactions"]:
		var rows: Array=layout.get(section)
		for old: Dictionary in old_layout.get(section):
			var matches: Array=[]
			for row: Dictionary in rows:
				if row.get("id")==old.get("id"):matches.append(row)
			if not need(matches.size()==1,"OLD_ROUTE_EXACT_ID:"+id+":"+String(old.get("id"))):continue
			for key: String in old:
				if key not in ["pos","size","visual_baked"]:need(matches[0].get(key)==old[key],"OLD_ROUTE_BUSINESS:"+id+":"+String(old.get("id"))+":"+key)
	var objects: Array[Dictionary]=author.building_specs();objects.append_array(author.prop_specs())
	for row: Dictionary in objects:
		var scale_factor: float=float(row.get("native_scale",0))
		need(scale_factor>0 and scale_factor<=1.0,"NATIVE_UNIFORM_SCALE:"+id+":"+String(row.id))
		need(ResourceLoader.exists(String(row.texture)),"EXISTING_IMPORTED_ASSET:"+String(row.texture))
		remember_asset(String(row.texture))
	for row: Dictionary in author.ground_rows():remember_asset(String(row.texture))
	for row: Dictionary in author.roads():remember_asset(String(row.texture))
	if author.has_method("bridge_rows"):
		for row: Dictionary in author.bridge_rows():remember_asset(String(row.texture))
	for npc: Dictionary in new_npcs:
		need(author.safe_foot(npc.pos,false),"NPC_COMPLETE_BODY_CLEAR:"+id+":"+String(npc.npc_id))
	need(author.safe_foot(author.SOUTH_ARRIVAL/author.SIZE),"DEFAULT_ARRIVAL_SAFE:"+id)
	need(author.safe_foot(author.SOUTH_EXIT/author.SIZE),"ORIGINAL_WORLD_EXIT_SAFE:"+id)
	need(author.migration(Vector2(.01,.01),-777)==null,"UNKNOWN_COORDINATE_VERSION_REJECT:"+id)
	if id=="openworld_xiangzhou_city":
		var mapped: Variant=author.migration(Vector2(.50,.18),5)
		need(mapped is Vector2 and (mapped*author.SIZE).distance_to(author.MINE_FOOT)<=1,"ORIGINAL_MINE_RETURN_EXACT_MAPPING")
	elif id=="openworld_yanmen_pass":
		var mapped: Variant=author.migration(Vector2(.79,.31),3)
		need(mapped is Vector2 and (mapped*author.SIZE).distance_to(author.CAVE_RETURN)<=1,"ORIGINAL_HIDDEN_CAVE_RETURN_EXACT_MAPPING")
	else:
		var mapped: Variant=author.migration(Vector2(.30,.78),2)
		need(mapped is Vector2 and (mapped*author.SIZE).distance_to(author.SOUTH_ARRIVAL)<=1,"ORIGINAL_QINGHE_DEFAULT_EXACT_MAPPING")
	var lines: Array=[];var reject: Vector2
	if id=="openworld_qinghe_town":
		lines=[[Vector2(2048,2900),Vector2(2048,2820)],[Vector2(1180,1772),Vector2(1180,1132)],[Vector2(3000,1132),Vector2(3000,1772)],[Vector2(2048,2380),Vector2(3000,2380)]];reject=Vector2(2048,1400)
	elif id=="openworld_xiangzhou_city":
		lines=[[Vector2(2816,3960),Vector2(2848,3960)],[Vector2(1536,3800),Vector2(1536,3070)],[Vector2(4096,3070),Vector2(4096,3800)]];reject=Vector2(2816,3400)
	else:
		lines=[[Vector2(2304,3880),Vector2(2304,3848)],[Vector2(2304,3290),Vector2(2304,2230)]];reject=Vector2(80,1800)
	var samples: int=0
	for line: Array in lines:
		var count: int=ceili((line[1] as Vector2).distance_to(line[0])/8.0)
		for index: int in range(count+1):
			var foot: Vector2=(line[0] as Vector2).lerp(line[1],float(index)/float(maxi(1,count)));samples+=1
			if not need(author.safe_foot(foot/author.SIZE),"NEW_SHORT_ROUTE_BODY:"+id+":"+str(foot)):break
	need(not author.safe_foot(reject/author.SIZE,false),"WATER_OR_CLIFF_REJECT:"+id)
	records.append({"id":id,"author_sha256":FileAccess.get_sha256(path),"size":author.SIZE,"layout_version":author.VERSION,"buildings":author.building_specs().size(),"props":author.prop_specs().size(),"npcs":new_npcs.size(),"portals":(layout.get("portals") as Array).size(),"interactions":(layout.get("interactions") as Array).size(),"route_body_samples":samples,"not_actual_keyboard":true})
func remember_asset(path: String) -> void:
	if assets.has(path):return
	if not FileAccess.file_exists(path):need(false,"MISSING_ASSET:"+path);return
	var file:=FileAccess.open(path,FileAccess.READ)
	assets[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1}
