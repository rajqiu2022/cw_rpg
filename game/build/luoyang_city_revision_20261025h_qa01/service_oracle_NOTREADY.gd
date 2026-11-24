extends RefCounted
## Independent arithmetic oracle; never calls the service implementation.
const READY=false
const MEAL_PRICE=5
const LODGING_PRICE=20
const SERVICES=["meal","lodging"]
static func snapshot(gs: Node) -> Dictionary:
	var members: Array=[]
	for value: Variant in gs.get("party"):
		if not value is CharacterStats: return {}
		members.append({"instance":str(value.get_instance_id()),"character_id":String(value.character_id),"hp":value.hp,"mp":value.mp,"max_hp":value.max_hp,"max_mp":value.max_mp})
	return {"gold":int(gs.get("gold")),"members":members}
static func all_full(before: Dictionary) -> bool:
	if before.get("members",[]).is_empty(): return false
	for row: Dictionary in before.members:
		if row.hp!=row.max_hp or row.mp!=row.max_mp: return false
	return true
static func expected(before: Dictionary,service: String,apply: bool) -> Dictionary:
	if service not in SERVICES or before.get("members",[]).is_empty(): return {}
	var result: Dictionary=before.duplicate(true)
	if not apply: return result
	var cost: int=MEAL_PRICE if service=="meal" else LODGING_PRICE
	if before.gold<cost: return {}
	result.gold=int(before.gold)-cost
	for row: Dictionary in result.members:
		if int(row.max_hp)<1 or int(row.max_mp)<0: return {}
		if service=="lodging":
			row.hp=int(row.max_hp);row.mp=int(row.max_mp)
		else:
			row.hp=mini(int(row.max_hp),int(row.hp)+maxi(1,floori(float(row.max_hp)*.25)))
			row.mp=mini(int(row.max_mp),int(row.mp)+maxi(1,floori(float(row.max_mp)*.25)))
	return result
static func deltas(before: Dictionary,after: Dictionary) -> Dictionary:
	if before.is_empty() or after.is_empty() or before.members.size()!=after.members.size(): return {}
	var rows: Array=[]
	for i: int in range(before.members.size()):
		var a: Dictionary=before.members[i];var b: Dictionary=after.members[i]
		rows.append({"character_id":a.character_id,"same_instance":a.instance==b.instance,"hp_added":int(b.hp)-int(a.hp),"mp_added":int(b.mp)-int(a.mp),"maxima_same":a.max_hp==b.max_hp and a.max_mp==b.max_mp})
	return {"gold_spent":int(before.gold)-int(after.gold),"members":rows}
