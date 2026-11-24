extends SceneTree
## Root-only ordinary-autoload in-memory transaction suite. No Field/Input/save IO.
const OUT := "res://build/life_skills_20261030j_qa01/results/"
const RECIPE_PATH := "res://scripts/life_skills/recipes.gd"
const SERVICE_PATH := "res://scripts/life_skills/crafting_service.gd"
const PINS := {
	RECIPE_PATH:"eb8fa123dfbb5a94cb5993768a4510bef57903d3b635f3590154aff49da05b22",
	SERVICE_PATH:"6de4ef5e1061ac845de835b9d8670d0454f0a5c05ed6d8ef0e98e30e0571382e",
	"res://scripts/autoload/inventory.gd":"727a2742aff63569f2a4d91ff5b69ac28191d5e146f600084e29e1f9dd76f276",
	"res://scripts/autoload/game_state.gd":"9120f2c11c78eed304896bb6c9aa365b9db525711a7e1b17a43d13205bf94c4e"
}
const IDS := ["healing_pill_minor","inner_breath_pill","antidote_pill","iron_sword","iron_helmet","iron_knuckles","iron_staff","iron_great_blade","iron_mail"]
const WORN_SWORD := "qa_original_linxi_sword#900001"
const WORN_ARMOR := "qa_original_cloth_armor#900002"
const MAX_SLOTS := 30
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
var done: bool=false
var suspended_early: bool=false
var inv: Node
var game: Node
var recipes: Script
var service: Script
var initial_sources: Dictionary={}
var event_count: int=0
var armed: bool=false
var nested_attempted: bool=false
var nested_recipe: Dictionary={}
var nested_results: Array=[]
var observations: Array=[]
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge!=null:_early(bridge)
	_run.call_deferred();_watchdog.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended_early=bool(node.call("is_checkpoint_saves_suspended"))
func _watchdog() -> void:
	await create_timer(45.0,true,false,true).timeout
	if not done:need(false,"45S_WATCHDOG_NO_SAVE_OR_RECOVERY");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("LIFE30J_QA_FAIL ",label)
	return ok
func sources() -> Dictionary:
	var result: Dictionary={}
	var paths: Array=PINS.keys();paths.append("res://scripts/ui/shop_ui.gd")
	for path: String in paths:
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func snapshot() -> Dictionary:
	# to_dict is in-memory serialization, never SaveManager.load/save/file IO.
	var packed: Dictionary=inv.call("to_dict");var resources: Array=[];var by_instance: Dictionary={};var worn_resources: Dictionary={}
	for row: Dictionary in inv.get("slots"):
		var item: Resource=row.get("item") as Resource
		resources.append(str(item.get_instance_id()) if item!=null else "NULL")
		if String(row.get("instance_id",""))!="":by_instance[String(row.instance_id)]=str(item.get_instance_id()) if item!=null else "NULL"
	for slot: int in [Equipment.Slot.WEAPON,Equipment.Slot.ARMOR]:
		var worn: Resource=inv.call("get_equipped",slot) as Resource
		worn_resources[str(slot)]=str(worn.get_instance_id()) if worn!=null else "NULL"
	var hero: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append(str(member.get_instance_id()))
	return {"inventory":packed.duplicate(true),"slot_resources":resources,"slot_reference_by_instance":by_instance,"worn_resources":worn_resources,"serial":inv.get("_next_instance_serial"),"gold":game.get("gold"),"hero_instance":str(hero.get_instance_id()),"party_instances":party,"hero_level":hero.get("level"),"hero_exp":hero.get("exp"),"hero_hp":hero.get("hp"),"hero_mp":hero.get("mp"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"event_count":event_count}.duplicate(true)
func count(item: String) -> int:return int(inv.call("count_of",StringName(item)))
func all_stock() -> Array:return [&"iron_staff",&"iron_great_blade",&"iron_mail"]
func stock(row: Dictionary) -> Array:return [StringName(row.output)] if bool(row.require_stock) else []
func seed(row: Dictionary,quantity: int,gold: int,extra_material: int=0,full: bool=false,existing_output: int=0) -> bool:
	var slots: Array=[{"item_id":"linxi_iron_sword","count":1,"instance_id":WORN_SWORD},{"item_id":"cloth_armor","count":1,"instance_id":WORN_ARMOR}]
	for id: String in row.ingredients:
		var item: Item=inv.call("load_item_by_id",StringName(id)) as Item
		if not need(item!=null and item.stackable and item.max_stack>0,"SEED_REAL_MATERIAL_RESOURCE:"+id):return false
		var amount: int=int(row.ingredients[id])*quantity+extra_material
		while amount>0:
			var put: int=mini(amount,item.max_stack);slots.append({"item_id":id,"count":put,"instance_id":""});amount-=put
	if existing_output>0:
		var item: Item=inv.call("load_item_by_id",StringName(row.output)) as Item
		if item.stackable:slots.append({"item_id":String(row.output),"count":existing_output,"instance_id":""})
		else:
			for index: int in range(existing_output):slots.append({"item_id":String(row.output),"count":1,"instance_id":"%s#%d"%[row.output,index+1]})
	if full:
		while slots.size()<MAX_SLOTS:slots.append({"item_id":"straw_sandals","count":1,"instance_id":"qa_filler#%d"%slots.size()})
	(game.get("player") as Resource).set("level",maxi(5,int(row.min_level)))
	game.set("gold",gold)
	inv.call("from_dict",{"slots":slots,"equipped_by_character":{"protagonist":{"weapon":{"item_id":"linxi_iron_sword","instance_id":WORN_SWORD},"armor":{"item_id":"cloth_armor","instance_id":WORN_ARMOR}}}})
	event_count=0
	return need(String(inv.call("get_equipped_instance_id",Equipment.Slot.WEAPON))==WORN_SWORD and String(inv.call("get_equipped_instance_id",Equipment.Slot.ARMOR))==WORN_ARMOR,"PRIVATE_SEED_ORIGINAL_WORN_INSTANCES")
func _run() -> void:
	if not need(suspended_early and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"EARLIEST_CHECKPOINT_SUSPENSION"):finish();return
	initial_sources=sources()
	for path: String in PINS:
		if not need(initial_sources[path].sha256==PINS[path],"FROZEN_SOURCE:"+path):finish();return
	inv=root.get_node("Inventory");game=root.get_node("GameState")
	recipes=load(RECIPE_PATH) as Script;service=load(SERVICE_PATH) as Script
	if not need(recipes!=null and service!=null and service.has_method("craft") and service.has_method("preview"),"REAL_STATIC_SERVICE_API"):finish();return
	inv.connect("slots_changed",_on_slots)
	game.connect("gold_changed",_on_gold)
	root.get_node("EventBus").connect("gold_changed",_on_event_gold)
	root.get_node("EventBus").connect("item_picked_up",_on_item_event)
	root.get_node("EventBus").connect("item_dropped",_on_item_event)
	if not recipe_contract():finish();return
	for id: String in IDS:
		var row: Dictionary=recipes.call("find",id)
		if not seed(row,0,100000):finish();return
		if not failure(row,1,String(row.station),stock(row),"MISSING_MATERIALS","missing:"+id):finish();return
		if int(row.gold)>0:
			if not seed(row,1,int(row.gold)-1):finish();return
			if not failure(row,1,String(row.station),stock(row),"INSUFFICIENT_GOLD","gold:"+id):finish();return
		if not seed(row,1,100000,1,true):finish();return
		if not failure(row,1,String(row.station),stock(row),"INVENTORY_FULL","full_no_release:"+id):finish();return
		if not seed(row,1,100000,0,true):finish();return
		if not success(row,1,"consume_frees_last_slot:"+id):finish();return
		if not seed(row,2,100000):finish();return
		if not success(row,2,"two_outputs:"+id):finish();return
	if not validation_cases():finish();return
	if not stacking_and_identity():finish();return
	if not reentry_case():finish();return
	if not original_inventory_trade_primitives():finish();return
	finish()
func recipe_contract() -> bool:
	if not need(int((inv.get_script() as Script).get_script_constant_map().get("MAX_SLOTS",0))==MAX_SLOTS,"ORIGINAL30_SLOT_CAPACITY_CONTRACT"):return false
	var medicine: Array=recipes.call("for_station","medicine",[])
	var basic: Array=recipes.call("for_station","blacksmith",[])
	var smith: Array=recipes.call("for_station","blacksmith",all_stock())
	if not need(medicine.size()==3 and basic.size()==3 and smith.size()==6 and (recipes.call("for_station","not_a_station",[]) as Array).is_empty(),"EXACT_MEDICINE3_BASIC3_SMITH6_STATIONS"):return false
	var seen: Dictionary={}
	for row: Dictionary in medicine+smith:
		var id: String=String(row.id)
		if not need(IDS.has(id) and not seen.has(id) and id==String(row.output) and int(row.count)==1,"UNIQUE_EXISTING_OUTPUT_RECIPE:"+id):return false
		seen[id]=true
		var output: Item=inv.call("load_item_by_id",StringName(row.output)) as Item
		if not need(output!=null and (output is Equipment if String(row.station)=="blacksmith" else output.stackable),"REAL_OUTPUT_RESOURCE_LOADS:"+id):return false
		for material: String in row.ingredients:
			var resource: Item=inv.call("load_item_by_id",StringName(material)) as Item
			if not need(resource!=null and resource.stackable and int(row.ingredients[material])>0,"REAL_INPUT_RESOURCE_LOADS:"+id+":"+material):return false
	var copy: Dictionary=recipes.call("find",String(IDS[0]));copy.ingredients["herb_bundle"]=999
	if not need(int((recipes.call("find",String(IDS[0])) as Dictionary).ingredients.herb_bundle)==2,"RECIPE_CALLERS_CANNOT_MUTATE_SHARED_DATA"):return false
	records.append({"phase":"recipes_resources_station_contract","ids":IDS,"medicine":medicine,"smith":smith})
	return true
func failure(row: Dictionary,quantity: int,station: String,provided_stock: Array,reason: String,label: String) -> bool:
	var before: Dictionary=snapshot()
	var preview: Dictionary=service.call("preview",String(row.id),quantity,station,provided_stock)
	if not need(preview.get("ok")==false and String(preview.get("reason"))==reason and snapshot()==before,"PREVIEW_FAILURE_ZERO_CHANGE:"+label):return false
	var result: Dictionary=service.call("craft",String(row.id),quantity,station,provided_stock)
	if not need(result.get("ok")==false and String(result.get("reason"))==reason and snapshot()==before and service.call("is_busy")==false,"CRAFT_FAILURE_ZERO_STATE_SERIAL_EQUIPMENT_EVENTS_CHANGE:"+label):return false
	records.append({"phase":"failure_exact_zero_change","label":label,"reason":reason,"preview":preview,"result":result})
	return true
func success(row: Dictionary,quantity: int,label: String) -> bool:
	var before: Dictionary=snapshot();var material_before: Dictionary={};var out_before: int=count(String(row.output))
	for material: String in row.ingredients:material_before[material]=count(material)
	var preview: Dictionary=service.call("preview",String(row.id),quantity,String(row.station),stock(row))
	if not need(preview.get("ok")==true and snapshot()==before,"SUCCESS_PREVIEW_PURE_NO_SERIAL_RESERVATION:"+label):return false
	var result: Dictionary=service.call("craft",String(row.id),quantity,String(row.station),stock(row))
	if not need(result.get("ok")==true and result.get("crafted")==true and String(result.get("reason"))=="OK" and service.call("is_busy")==false,"CRAFT_SUCCESS_AND_LOCK_RELEASE:"+label):return false
	for material: String in row.ingredients:
		if not need(count(material)==int(material_before[material])-int(row.ingredients[material])*quantity,"EXACT_MATERIAL_CONSUMPTION:"+label+":"+material):return false
	if not need(count(String(row.output))==out_before+int(row.count)*quantity and int(game.get("gold"))==int(before.gold)-int(row.gold)*quantity,"EXACT_OUTPUT_AND_GOLD:"+label):return false
	if not need(String(inv.call("get_equipped_instance_id",Equipment.Slot.WEAPON))==WORN_SWORD and String(inv.call("get_equipped_instance_id",Equipment.Slot.ARMOR))==WORN_ARMOR,"ORIGINAL_WORN_INSTANCES_UNCHANGED:"+label):return false
	var created: Array=result.get("created_instances",[]);var unique: Dictionary={}
	for instance: String in created:
		if not need(not instance.is_empty() and not unique.has(instance) and not (inv.call("find_slot_by_instance",instance) as Dictionary).is_empty(),"NEW_EQUIPMENT_INSTANCE_UNIQUE:"+label):return false
		unique[instance]=true
	if not need(created.size()==(int(row.count)*quantity if String(row.station)=="blacksmith" else 0) and created==preview.get("created_instances",[]),"DETERMINISTIC_PREVIEW_INSTANCE_IDS_NO_REUSE:"+label):return false
	var after: Dictionary=snapshot()
	if not need(before.worn_resources==after.worn_resources,"ORIGINAL_WORN_RESOURCE_REFERENCES_NOT_REPLACED:"+label):return false
	for instance: String in before.slot_reference_by_instance:
		if not need(after.slot_reference_by_instance.get(instance)==before.slot_reference_by_instance[instance],"EXISTING_NONSTACK_INSTANCE_AND_RESOURCE_REFERENCE_SURVIVES:"+label):return false
	if not need(before.hero_instance==after.hero_instance and before.party_instances==after.party_instances and before.hero_level==after.hero_level and before.hero_exp==after.hero_exp and before.hero_hp==after.hero_hp and before.hero_mp==after.hero_mp and before.flags==after.flags and before.quests==after.quests,"NO_REWARD_STORY_PARTY_OR_HERO_SIDE_EFFECT:"+label):return false
	records.append({"phase":"success_exact_transaction","label":label,"before_inventory":before.inventory,"after_inventory":after.inventory,"before_gold":before.gold,"after_gold":after.gold,"preview":preview,"result":result})
	return true
func validation_cases() -> bool:
	var basic: Dictionary=recipes.call("find","iron_sword");var rare: Dictionary=recipes.call("find","iron_staff")
	for quantity: int in [0,-1,11]:
		if not seed(basic,1,100000) or not failure(basic,quantity,"blacksmith",[],"INVALID_QUANTITY","quantity:"+str(quantity)):return false
	if not seed(basic,1,100000) or not failure({"id":"unknown_qa_recipe"},1,"blacksmith",[],"UNKNOWN_RECIPE","unknown"):return false
	if not seed(basic,1,100000) or not failure(basic,1,"medicine",[],"WRONG_STATION","wrong_station"):return false
	if not seed(rare,1,100000):return false
	(game.get("player") as Resource).set("level",4)
	if not failure(rare,1,"blacksmith",stock(rare),"LEVEL_REQUIRED","rare_level4"):return false
	if not seed(rare,1,100000) or not failure(rare,1,"blacksmith",[],"STOCK_REQUIRED","rare_real_stock_required"):return false
	if not failure(rare,1,"blacksmith",[{"item_id":"iron_staff"}],"STOCK_REQUIRED","dictionary_alias_not_real_stock"):return false
	if not seed(basic,1,100000):return false
	var slots: Array=inv.get("slots");slots[0]["count"]=0
	if not failure(basic,1,"blacksmith",[],"INVALID_INVENTORY","zero_slot_count"):return false
	if not seed(basic,1,100000):return false
	slots=inv.get("slots");slots[1]["instance_id"]=slots[0]["instance_id"]
	if not failure(basic,1,"blacksmith",[],"INVALID_INVENTORY","duplicate_instance_id"):return false
	if not seed(basic,10,100000) or not success(basic,10,"maximum10_equipment"):return false
	return true
func stacking_and_identity() -> bool:
	var medicine: Dictionary=recipes.call("find","healing_pill_minor")
	if not seed(medicine,1,100000,1,true,98) or not success(medicine,1,"full_bag_stack_merge_no_free_slot"):return false
	if not seed(medicine,1,100000,1,true,99) or not failure(medicine,1,"medicine",[],"INVENTORY_FULL","existing_output_stack_full"):return false
	var equipment: Dictionary=recipes.call("find","iron_sword")
	if not seed(equipment,2,100000,0,true) or not failure(equipment,2,"blacksmith",[],"INVENTORY_FULL","one_material_slot_freed_but_two_outputs_need_two"):return false
	if not seed(equipment,2,100000,0,false,1) or not success(equipment,2,"existing_serial_collision_skip"):return false
	var packed: Dictionary=inv.call("to_dict");var ids_before: Dictionary={}
	for row: Dictionary in packed.slots:
		if String(row.instance_id)!="":ids_before[String(row.instance_id)]=true
	inv.call("from_dict",packed)
	if not need(inv.call("to_dict")==packed and String(inv.call("get_equipped_instance_id",Equipment.Slot.WEAPON))==WORN_SWORD and String(inv.call("get_equipped_instance_id",Equipment.Slot.ARMOR))==WORN_ARMOR,"PURE_MEMORY_SERIALIZATION_ALL_IDS_AND_ORIGINAL_WEAR_PRESERVED_NO_SAVE_IO"):return false
	if not need(inv.call("add_item",&"iron_sword",1)==true,"ORIGINAL_ADD_AFTER_CRAFT_AND_MEMORY_ROUNDTRIP"):return false
	var all_ids: Dictionary={}
	for row: Dictionary in inv.get("slots"):
		var instance: String=String(row.get("instance_id",""))
		if instance.is_empty():continue
		if not need(not all_ids.has(instance),"ROUNDTRIP_REBUILT_SERIAL_NEVER_COLLIDES"):return false
		all_ids[instance]=true
	return true
func _on_slots() -> void:event_count+=1;_observer("slots_changed")
func _on_gold(_amount: int) -> void:event_count+=1;_observer("GameState.gold_changed")
func _on_event_gold(_amount: int) -> void:event_count+=1;_observer("EventBus.gold_changed")
func _on_item_event(_id: StringName,_amount: int) -> void:event_count+=1
func _observer(signal_name: String) -> void:
	if not armed:return
	observations.append({"signal":signal_name,"busy":service.call("is_busy"),"gold":game.get("gold"),"ore":count("iron_ore"),"output":count("iron_sword")})
	if nested_attempted:return
	nested_attempted=true
	var before: Dictionary=snapshot()
	var preview: Dictionary=service.call("preview","iron_sword",1,"blacksmith",[])
	var craft: Dictionary=service.call("craft","iron_sword",1,"blacksmith",[])
	nested_results.append({"preview":preview,"craft":craft,"state_before":before,"state_after":snapshot(),"busy_after":service.call("is_busy")})
func reentry_case() -> bool:
	var row: Dictionary=recipes.call("find","iron_sword")
	if not seed(row,2,1000):return false
	armed=true;nested_attempted=false;nested_results.clear();observations.clear()
	var result: Dictionary=service.call("craft","iron_sword",1,"blacksmith",[])
	armed=false
	if not need(result.get("ok")==true and nested_attempted and nested_results.size()==1,"REAL_SYNCHRONOUS_SIGNAL_REENTRY_EXERCISED"):return false
	var nested: Dictionary=nested_results[0]
	if not need(nested.preview.get("reason")=="BUSY" and nested.craft.get("reason")=="BUSY" and nested.state_before==nested.state_after and nested.busy_after==true,"REENTRANT_PREVIEW_CRAFT_BUSY_ZERO_CHANGE"):return false
	if not need(observations.size()==3 and count("iron_ore")==6 and count("iron_sword")==1 and int(game.get("gold"))==980,"ONLY_ONE_OUTER_COMMIT_WITH_ALL_CALLBACKS"):return false
	for observed: Dictionary in observations:
		if not need(observed.busy==true and int(observed.gold)==980 and int(observed.ore)==6 and int(observed.output)==1,"EVERY_OBSERVER_SEES_FULL_COMMIT_AND_LOCK:"+String(observed.signal)):return false
	if not need(service.call("is_busy")==false,"BUSY_RELEASED_AFTER_LAST_CALLBACK"):return false
	records.append({"phase":"real_callback_reentry","result":result,"nested":nested_results,"observations":observations})
	return true
func original_inventory_trade_primitives() -> bool:
	var row: Dictionary=recipes.call("find","iron_sword")
	if not seed(row,0,1000):return false
	var item: Item=inv.call("load_item_by_id",&"healing_pill_minor") as Item
	var before_gold: int=int(game.get("gold"))
	if not need(inv.call("add_item",item.item_id,2)==true,"ORIGINAL_NORMAL_PURCHASE_INVENTORY_ADD_COMPATIBLE"):return false
	game.call("add_gold",-item.buy_price*2)
	if not need(count("healing_pill_minor")==2 and int(game.get("gold"))==before_gold-item.buy_price*2,"NORMAL_BUY_PRIMITIVES_EXACT_COUNT_AND_PRICE"):return false
	if not need(inv.call("remove_item",item.item_id,1)==true,"ORIGINAL_NORMAL_SELL_REMOVE_COMPATIBLE"):return false
	game.call("add_gold",int(floor(item.sell_price*.5)))
	if not need(count("healing_pill_minor")==1 and int(game.get("gold"))==before_gold-item.buy_price*2+int(floor(item.sell_price*.5)) and String(inv.call("get_equipped_instance_id",Equipment.Slot.WEAPON))==WORN_SWORD,"NORMAL_SELL_PRIMITIVES_KEEP_ORIGINAL_WORN"):return false
	records.append({"phase":"original_inventory_gold_buy_sell_primitives_only","not_ShopUI_click_or_full_bag_shop_acceptance":true})
	return true
func finish() -> void:
	if done:return
	done=true;armed=false
	var final_sources: Dictionary=sources() if not initial_sources.is_empty() else {}
	if not initial_sources.is_empty():need(final_sources==initial_sources,"SOURCE_FIRST_FINAL_NO_TEST_WRITES")
	var directory: String=OUT+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	var path: String=directory+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"initial_sources":initial_sources,"final_sources":final_sources,"memory_seeds_only":true,"checkpoint_remains_suspended_until_owned_exit":true,"game_Field_instances":0,"game_input":0,"real_save_contents_read":false,"SaveManager_API_calls":0,"save_writes":0,"production_writes":0,"real171save_metadata_guard_owned_by_Root":true,"gathering_contract_not_yet_tested":true,"old_city_or11room_matrix_retested":false},"\t")+"\n");file.close()
	print("LIFE30J_CRAFT_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
