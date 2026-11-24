extends SceneTree
## Root-only ordinary-resource service tests. Private memory seeds, no Field/save/Input.
const OUT := "res://build/life_skills_20261030j_qa01/gathering_results/"
const GATHER_PATH := "res://scripts/life_skills/gathering_service.gd"
const SITES_PATH := "res://scripts/life_skills/gathering_sites.json"
const KEY := "life_skills_resources_v1"
const PINS := {
	GATHER_PATH:"3d7ce595e1af2f1631ea153920b22366dd9bebd3f32b37cde21e698b3685af4f",
	SITES_PATH:"a84edca03ffc2bb0e883f53d2b3b2a07365beae57d89ef17fffe1fe6a7805614",
	"res://scripts/autoload/inventory.gd":"727a2742aff63569f2a4d91ff5b69ac28191d5e146f600084e29e1f9dd76f276",
	"res://scripts/autoload/game_state.gd":"9120f2c11c78eed304896bb6c9aa365b9db525711a7e1b17a43d13205bf94c4e"
}
const WORN := "qa_gather_original_sword#910001"
const MAX_SLOTS := 30
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
var done: bool=false
var early_suspended: bool=false
var game: Node
var inv: Node
var gather: Script
var first_sources: Dictionary={}
var original_flags: Dictionary={}
var events: Dictionary={"slots":0,"items":0,"flags":0}
var chosen: Dictionary={}
var armed: bool=false
var tried_nested: bool=false
var armed_id: String=""
var observations: Array=[]
var nested: Array=[]
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge!=null:_early(bridge)
	_run.call_deferred();_watchdog.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);early_suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _watchdog() -> void:
	await create_timer(40.0,true,false,true).timeout
	if not done:need(false,"40S_WATCHDOG_NO_RECOVERY_OR_SAVE");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("LIFE30J_GATHER_FAIL ",label)
	return ok
func source_facts() -> Dictionary:
	var result: Dictionary={};var paths: Array=PINS.keys()
	paths.append("res://scripts/life_skills/life_skills.gd");paths.append("res://scripts/life_skills/crafting_panel.gd")
	for path: String in paths:
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func item_for(site: Dictionary) -> String:return "herb_bundle" if String(site.type)=="herb" else "iron_ore"
func resource_state() -> Dictionary:return gather.call("state")
func other_flags() -> Dictionary:
	var flags: Dictionary=game.get("flags").duplicate(true);flags.erase(KEY);return flags
func count(id: String) -> int:return int(inv.call("count_of",StringName(id)))
func snapshot() -> Dictionary:
	var resources: Array=[]
	for row: Dictionary in inv.get("slots"):
		var item: Resource=row.get("item") as Resource
		resources.append(str(item.get_instance_id()) if item!=null else "NULL")
	var hero: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append(str(member.get_instance_id()))
	return {"inventory":(inv.call("to_dict") as Dictionary).duplicate(true),"slot_resource_refs":resources,"serial":inv.get("_next_instance_serial"),"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"hero_instance":str(hero.get_instance_id()),"party_instances":party,"hero_level":hero.get("level"),"hero_exp":hero.get("exp"),"hero_hp":hero.get("hp"),"hero_mp":hero.get("mp"),"events":events.duplicate(true)}.duplicate(true)
func seed_gather_case(site: Dictionary,amount: int=0,full: bool=false,victories: int=0,harvested: Dictionary={}) -> bool:
	var slots: Array=[{"item_id":"linxi_iron_sword","count":1,"instance_id":WORN}]
	if amount>0:slots.append({"item_id":item_for(site),"count":amount,"instance_id":""})
	if full:
		while slots.size()<MAX_SLOTS:slots.append({"item_id":"straw_sandals","count":1,"instance_id":"qa_gather_filler#%d"%slots.size()})
	inv.call("from_dict",{"slots":slots,"equipped_by_character":{"protagonist":{"weapon":{"item_id":"linxi_iron_sword","instance_id":WORN}}}})
	var flags: Dictionary=original_flags.duplicate(true)
	# Explicit QA-only nested sentinel, not a fabricated completed story flag.
	flags["qa_life_skills_untouched_sentinel"]={"keep":true,"nested":[17,"unchanged"]}
	flags[KEY]={"victories":victories,"harvested":harvested.duplicate(true)}
	game.set("flags",flags);game.set("gold",417)
	events={"slots":0,"items":0,"flags":0}
	return need(String(inv.call("get_equipped_instance_id",Equipment.Slot.WEAPON))==WORN,"PRIVATE_GATHER_MEMORY_SEED_WORN_INSTANCE")
func _run() -> void:
	if not need(early_suspended and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"EARLIEST_CHECKPOINT_SUSPEND"):finish();return
	first_sources=source_facts()
	for path: String in PINS:
		if not need(first_sources[path].sha256==PINS[path],"EXACT_LATEST_RESOURCE_BOOKKEEPING_SOURCE:"+path):finish();return
	game=root.get_node("GameState");inv=root.get_node("Inventory");gather=load(GATHER_PATH) as Script
	if not need(gather!=null and gather.has_method("collect") and gather.has_method("record_battle"),"REAL_GATHER_STATIC_SERVICE"):finish();return
	original_flags=game.get("flags").duplicate(true)
	inv.connect("slots_changed",_on_slots)
	root.get_node("EventBus").connect("item_picked_up",_on_item)
	root.get_node("EventBus").connect("flag_set",_on_flag)
	if not catalog_contract():finish();return
	for type: String in ["herb","ore"]:
		var site: Dictionary=chosen[type]
		if not seed_gather_case(site):finish();return
		if not collect_success(site,"first_"+type):finish();return
		if not unchanged_failure(String(site.id),"duplicate_"+type):finish();return
		var saved: Dictionary=game.get("flags").duplicate(true)
		game.set("flags",saved.duplicate(true))
		if not need(game.get("flags")==saved and not gather.call("is_available",String(site.id)),"MEMORY_FLAGS_RELOAD_REMAINS_HARVESTED:"+type):finish();return
		if not unchanged_failure(String(site.id),"memory_reload_duplicate_"+type):finish();return
		if not seed_gather_case(site,97,true) or not collect_success(site,"full30_merge97_to99_"+type):finish();return
		if not seed_gather_case(site,98,true):finish();return
		if not unchanged_failure(String(site.id),"full30_only_one_stack_space_"+type):finish();return
		if not need(gather.call("is_available",String(site.id))==true and resource_state().harvested.is_empty(),"FAILED_CAPACITY_DOES_NOT_CONSUME_SITE:"+type):finish();return
		var filler: String=String((inv.get("slots") as Array)[-1].instance_id)
		if not need(inv.call("remove_instance",filler)==true and (inv.get("slots") as Array).size()==29,"PUBLIC_INVENTORY_REMOVAL_FREES_ONE_SLOT:"+type):finish();return
		if not collect_success(site,"free_slot_split98_to99_plus1_"+type):finish();return
		if not need(count(item_for(site))==100 and (inv.get("slots") as Array).size()==30,"TWO_ITEMS_SPLIT_WITH_NO_DISCARD_OR_OVERFLOW:"+type):finish();return
		if not seed_gather_case(site,99,true) or not unchanged_failure(String(site.id),"full30_stack99_"+type):finish();return
	if not battle_refresh():finish();return
	if not signal_reentry():finish();return
	if not unchanged_failure("unknown_qa_resource_site","unknown_site"):finish();return
	finish()
func catalog_contract() -> bool:
	var catalog: Dictionary=gather.call("catalog")
	if not need(int(catalog.get("schema_version",0))==1 and catalog.get("sites",[]).size()==12 and catalog.get("coordinate_basis",{}).size()==4,"FROZEN12_SITES_FOUR_SCENE_DATA_CONTRACT_NOT_ROUTE_TEST"):return false
	var seen: Dictionary={};var types: Dictionary={"herb":0,"ore":0}
	for site: Dictionary in catalog.sites:
		var id: String=String(site.get("id",""));var type: String=String(site.get("type",""));var scene: String=String(site.get("scene_id",""))
		if not need(not id.is_empty() and not seen.has(id) and types.has(type) and catalog.coordinate_basis.has(scene),"UNIQUE_ORDINARY_SITE_AND_EXPLICIT_BASIS:"+id):return false
		seen[id]=true;types[type]=int(types[type])+1
		var basis: Array=catalog.coordinate_basis[scene];var p: Array=site.foot
		if not need(basis.size()==2 and p.size()==2 and float(p[0])>0 and float(p[1])>0 and float(p[0])<float(basis[0]) and float(p[1])<float(basis[1]) and float(site.scale)>0 and float(site.scale)<=1 and ResourceLoader.exists(String(site.texture)),"SOURCE_FOOT_WITHIN_DESIGN_BASIS_AND_EXISTING_SHRUNK_ART:"+id):return false
		if not need(gather.call("site_by_id",id)==site,"REAL_SITE_LOOKUP_EXACT:"+id):return false
		if not chosen.has(type):chosen[type]=site.duplicate(true)
	if not need(int(types.herb)==8 and int(types.ore)==4 and (gather.call("site_by_id","unknown_qa_resource_site") as Dictionary).is_empty() and gather.call("is_available","unknown_qa_resource_site")==false,"HERB8_ORE4_ONLY_UNKNOWN_REJECTED"):return false
	for type: String in types:
		var item: Item=inv.call("load_item_by_id",StringName(item_for(chosen[type]))) as Item
		if not need(item!=null and item.stackable and item.max_stack==99,"ONLY_REAL_ORDINARY_HERB_OR_ORE_ITEMS:"+type):return false
	records.append({"phase":"data_contract_only_no_map_instance","types":types,"representatives":chosen,"catalog":catalog,"forest_basis_requires_runtime_projection_not_assumed_runtime_px":true})
	return true
func unchanged_failure(id: String,label: String) -> bool:
	var before: Dictionary=snapshot()
	var preview: Dictionary=gather.call("preview",id)
	if not need(preview.get("ok")==false and snapshot()==before,"PREVIEW_FAILURE_EXACT_ZERO_CHANGE:"+label):return false
	var result: Dictionary=gather.call("collect",id)
	if not need(result.get("ok")==false and snapshot()==before,"COLLECT_FAILURE_NO_ITEM_FLAG_CYCLE_SERIAL_GOLD_OR_EVENT_CHANGE:"+label):return false
	records.append({"phase":"failure_zero_change","label":label,"preview":preview,"result":result,"resource_state":resource_state()})
	return true
func collect_success(site: Dictionary,label: String) -> bool:
	var before: Dictionary=snapshot();var item_id: String=item_for(site);var owned: int=count(item_id)
	var flags: Dictionary=other_flags();var preview: Dictionary=gather.call("preview",String(site.id))
	if not need(preview.get("ok")==true and String(preview.get("item_id"))==item_id and int(preview.get("count",0))==2 and snapshot()==before,"PREVIEW_TWO_ORDINARY_RESOURCES_PURE:"+label):return false
	var result: Dictionary=gather.call("collect",String(site.id));var after: Dictionary=snapshot()
	if not need(result.get("ok")==true and count(item_id)==owned+2 and after.gold==before.gold and after.serial==before.serial and (inv.get("slots") as Array).size()<=MAX_SLOTS,"COLLECT_EXACT_TWO_NO_GOLD_SERIAL_OR_OVERFLOW:"+label):return false
	var state: Dictionary=resource_state();var cycle: int=floori(float(state.victories)/3.0)
	if not need(int(state.harvested.get(String(site.id),-1))==cycle and gather.call("is_available",String(site.id))==false,"SITE_MARKED_CURRENT_VICTORY_CYCLE_ONLY_AFTER_SUCCESS:"+label):return false
	if not need(other_flags()==flags and after.quests==before.quests and after.hero_instance==before.hero_instance and after.party_instances==before.party_instances and after.hero_level==before.hero_level and after.hero_exp==before.hero_exp and after.hero_hp==before.hero_hp and after.hero_mp==before.hero_mp and String(inv.call("get_equipped_instance_id",Equipment.Slot.WEAPON))==WORN,"ORIGINAL_QUEST_FLAGS_PARTY_HERO_WORN_UNCHANGED:"+label):return false
	if not need(int(events.slots)==int(before.events.slots)+1 and int(events.items)==int(before.events.items)+1 and int(events.flags)==int(before.events.flags),"ONE_COMMITTED_INVENTORY_EVENT_NO_STORY_FLAG_BROADCAST:"+label):return false
	records.append({"phase":"ordinary_resource_success","label":label,"before_inventory":before.inventory,"after_inventory":after.inventory,"resource_state":state,"result":result,"original_task_flags_unchanged":true})
	return true
func battle_refresh() -> bool:
	var site: Dictionary=chosen.herb
	if not seed_gather_case(site) or not collect_success(site,"refresh_cycle0_harvest"):return false
	for pair: Array in [[false,false],[false,true],[true,true]]:
		var before: Dictionary=snapshot();gather.call("record_battle",bool(pair[0]),bool(pair[1]))
		if not need(snapshot()==before,"LOSS_OR_FLIGHT_NEVER_COUNTS_WIN:"+str(pair)):return false
	var flags: Dictionary=other_flags();var inventory: Dictionary=(inv.call("to_dict") as Dictionary).duplicate(true)
	for wins: int in range(1,7):
		gather.call("record_battle",true,false)
		if not need(int(resource_state().victories)==wins and other_flags()==flags and inv.call("to_dict")==inventory and int(events.flags)==0,"TRUE_NONFLED_WIN_COUNTS_ONCE_WITH_NO_STORY_BROADCAST:"+str(wins)):return false
		var expected: bool=wins==3 or wins==6
		if not need(bool(gather.call("is_available",String(site.id)))==expected,"EXACT_THREE_VICTORY_GLOBAL_CYCLE_BOUNDARY:"+str(wins)):return false
		if wins==3:
			if not collect_success(site,"refresh_cycle1_harvest"):return false
			inventory=(inv.call("to_dict") as Dictionary).duplicate(true)
			var saved: Dictionary=game.get("flags").duplicate(true);game.set("flags",saved.duplicate(true))
			if not need(not gather.call("is_available",String(site.id)) and int(resource_state().harvested[String(site.id)])==1,"MEMORY_RELOAD_PRESERVES_CYCLE1_HARVEST_NO_SAVE_FILE"):return false
	if not need(gather.call("is_available",String(chosen.ore.id))==true,"PER_SITE_HARVEST_STATE_DOES_NOT_EXHAUST_OTHER_SITE"):return false
	records.append({"phase":"direct_record_battle_unit_not_combat_tour","wins":resource_state().victories,"state":resource_state(),"loss_and_flight_ignored":true,"three_wins_per_global_cycle":true})
	return true
func _on_slots() -> void:events.slots=int(events.slots)+1;_observer("slots_changed")
func _on_item(_id: StringName,_amount: int) -> void:events.items=int(events.items)+1;_observer("item_picked_up")
func _on_flag(_key: StringName,_value: Variant) -> void:events.flags=int(events.flags)+1
func _observer(signal_name: String) -> void:
	if not armed:return
	var busy_preview: Dictionary=gather.call("preview",armed_id)
	observations.append({"signal":signal_name,"busy_message":busy_preview.get("message"),"busy_ok":busy_preview.get("ok"),"count":count("herb_bundle"),"state":resource_state()})
	if tried_nested:return
	tried_nested=true
	var before: Dictionary=snapshot();var result: Dictionary=gather.call("collect",armed_id)
	nested.append({"result":result,"before":before,"after":snapshot()})
func signal_reentry() -> bool:
	var site: Dictionary=chosen.herb
	if not seed_gather_case(site):return false
	armed=true;armed_id=String(site.id);tried_nested=false;observations.clear();nested.clear()
	var result: Dictionary=gather.call("collect",armed_id)
	armed=false
	if not need(result.get("ok")==true and tried_nested and nested.size()==1 and observations.size()==2,"REAL_GATHER_SIGNAL_REENTRY_AT_BOTH_COMMIT_OBSERVERS"):return false
	var attempt: Dictionary=nested[0]
	if not need(attempt.result.get("ok")==false and String(attempt.result.get("message")).begins_with("正在采集") and attempt.before==attempt.after,"NESTED_COLLECT_BUSY_ZERO_CHANGE"):return false
	for seen: Dictionary in observations:
		if not need(seen.busy_ok==false and String(seen.busy_message).begins_with("正在采集") and int(seen.count)==2 and int(seen.state.harvested[armed_id])==0,"EACH_OBSERVER_SEES_ATOMIC_ITEMS_HARVEST_AND_BUSY:"+String(seen.signal)):return false
	if not need(count("herb_bundle")==2 and int(events.slots)==1 and int(events.items)==1 and int(events.flags)==0 and gather.call("is_available",armed_id)==false,"ONE_GATHER_ONLY_NO_STORY_FLAG_OR_EXTRA_ITEMS"):return false
	if not need((gather.call("preview",String(chosen.ore.id)) as Dictionary).get("ok")==true,"BUSY_RELEASED_FOR_OTHER_AVAILABLE_SITE_AFTER_CALLBACKS"):return false
	records.append({"phase":"gather_synchronous_reentry","outer":result,"nested":nested,"observations":observations})
	return true
func finish() -> void:
	if done:return
	done=true;armed=false
	var last: Dictionary=source_facts() if not first_sources.is_empty() else {}
	if not first_sources.is_empty():need(last==first_sources,"SOURCE_FIRST_FINAL_NO_TEST_OR_PRODUCTION_WRITES")
	var directory: String=OUT+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	var path: String=directory+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"first_sources":first_sources,"final_sources":last,"private_memory_seed_only":true,"checkpoint_remains_suspended_until_owned_exit":true,"real_save_contents_read":false,"SaveManager_API_calls":0,"save_writes":0,"production_writes":0,"Field_instances":0,"game_input":0,"service_units_not_physics_or_F_input_acceptance":true,"crafting754_success_inherited_not_retested":true,"old_city11room_matrix_retested":false,"real171save_metadata_protected_by_Root":true},"\t")+"\n");file.close()
	print("LIFE30J_GATHER_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
