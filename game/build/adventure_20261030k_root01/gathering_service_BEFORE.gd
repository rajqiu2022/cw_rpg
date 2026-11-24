extends RefCounted
## Ordinary resources only; task-specific collectables are not touched.
const STATE_KEY: StringName=&"life_skills_resources_v1"
const SITES_PATH:="res://scripts/life_skills/gathering_sites.json"
static var _sites: Dictionary={}
static var _busy: bool=false

static func catalog() -> Dictionary:
	if _sites.is_empty():
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(SITES_PATH))
		if raw is Dictionary:_sites=raw
	return _sites

static func site_by_id(id: String) -> Dictionary:
	for site: Dictionary in catalog().get("sites",[]):
		if String(site.get("id"))==id:return site.duplicate(true)
	return {}

static func state() -> Dictionary:
	var value: Variant=GameState.get_flag(STATE_KEY,{})
	return value.duplicate(true) if value is Dictionary else {}

static func is_available(id: String) -> bool:
	if site_by_id(id).is_empty():return false
	var record: Dictionary=state()
	var harvested: Variant=record.get("harvested",{})
	if not harvested is Dictionary:return false
	return int(harvested.get(id,-1))<floori(float(record.get("victories",0))/3.0)

static func record_battle(victory: bool, fled: bool) -> void:
	if not victory or fled:return
	var record: Dictionary=state()
	record["victories"]=maxi(0,int(record.get("victories",0)))+1
	# This is serialized resource bookkeeping, not a story flag. Broadcasting
	# flag_set would rebuild legacy terrain for every ordinary herb gathered.
	GameState.flags[String(STATE_KEY)]=record

static func preview(id: String) -> Dictionary:
	var result: Dictionary={"ok":false,"message":"此处没有可采集的资源。"}
	if _busy:result.message="正在采集，请稍候。";return result
	var site: Dictionary=site_by_id(id)
	if site.is_empty() or String(site.get("type")) not in ["herb","ore"]:return result
	if not is_available(id):result.message="这里已采集过；每累计三场战斗胜利，资源统一恢复一轮。";return result
	var item_id: StringName=&"herb_bundle" if site.type=="herb" else &"iron_ore"
	var item: Item=Inventory.load_item_by_id(item_id)
	if item==null or not item.stackable:return result
	var amount: int=2
	var room: int=(Inventory.MAX_SLOTS-Inventory.slots.size())*item.max_stack
	for slot: Dictionary in Inventory.slots:
		var current: Item=slot.get("item") as Item
		if current!=null and current.item_id==item_id:room+=maxi(0,item.max_stack-int(slot.count))
	result={"ok":room>=amount,"message":"可以采集。" if room>=amount else "背包空间不足，请先整理背包。","item_id":String(item_id),"count":amount,"name":item.display_name}
	return result

static func collect(id: String) -> Dictionary:
	var result: Dictionary=preview(id)
	if not result.ok:return result
	_busy=true
	var item: Item=Inventory.load_item_by_id(StringName(result.item_id))
	var slots: Array[Dictionary]=[]
	for slot: Dictionary in Inventory.slots:slots.append(slot.duplicate())
	var remaining: int=int(result.count)
	for slot: Dictionary in slots:
		var current: Item=slot.get("item") as Item
		if current==null or current.item_id!=item.item_id:continue
		var put: int=mini(maxi(0,item.max_stack-int(slot.count)),remaining)
		slot["count"]=int(slot.count)+put;remaining-=put
	while remaining>0:
		var put: int=mini(item.max_stack,remaining)
		slots.append({"item":item,"count":put,"instance_id":""});remaining-=put
	var record: Dictionary=state();var harvested: Dictionary=record.get("harvested",{}).duplicate()
	harvested[id]=floori(float(record.get("victories",0))/3.0);record["harvested"]=harvested
	Inventory.slots.assign(slots)
	GameState.flags[String(STATE_KEY)]=record
	Inventory.slots_changed.emit();EventBus.item_picked_up.emit(item.item_id,int(result.count))
	result.message="采得 %s ×%d。"%[item.display_name,int(result.count)]
	_busy=false
	return result
