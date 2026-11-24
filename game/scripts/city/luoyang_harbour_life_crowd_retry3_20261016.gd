extends RefCounted
## Real native NPCNode horizontal patrol, not idle-texture translation. Each
## finite swept lane is checked against the newly composed static navigation.
const A=preload("res://scripts/city/luoyang_harbour_life_author_retry3_20261016.gd")
const MERCHANT_IDLE="res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
const MERCHANT_WALK="res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"
const GUARD_IDLE="res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png"
const GUARD_WALK="res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png"
const FARMER="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"
const WAITER="res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"
static func source_paths() -> Dictionary:
	return {"res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd":true,MERCHANT_IDLE:true,MERCHANT_WALK:true,GUARD_IDLE:true,GUARD_WALK:true,FARMER:true,WAITER:true}
static func spec(id: StringName) -> Array:
	if id==A.IDS[0]: return [
		["gate_waiting_merchant_a","候检商人",[750,1600],70,true,false],
		["gate_pack_carrier_a","挑夫",[1120,1720],70,true,false],
		["gate_patrol_west","巡城军士",[2010,1700],70,true,true],
		["gate_waiting_merchant_b","行脚商",[2440,1640],60,true,false],
		["gate_patrol_east","巡城军士",[2370,1870],110,true,true],
		["gate_pack_carrier_b","脚夫",[680,1880],120,true,false],
		["gate_waiting_traveller_a","候检旅人",[1020,1480],0,false,false],
		["gate_waiting_traveller_b","候检旅人",[1940,1450],0,false,false],
		["gate_supply_attendant","货担主人",[2400,1450],0,false,false],
		["gate_check_assistant","验货军士",[1840,1600],0,false,true]]
	if id==A.IDS[1]: return [
		["docks_rope_carrier","搬运脚夫",[1400,880],60,true,false],
		["docks_goods_broker","货行商人",[1670,900],70,true,false],
		["docks_quay_patrol","巡河军士",[1570,1430],60,true,true],
		["docks_southern_carrier","搬运脚夫",[1570,1740],70,true,false],
		["docks_west_carrier","脚夫",[590,1240],100,true,false],
		["docks_departing_merchant","行脚商",[900,1930],140,true,false],
		["docks_store_attendant","货栈伙计",[1050,970],0,false,false],
		["docks_loading_attendant","装卸伙计",[2000,1430],0,false,false],
		["docks_rope_seller","索具商",[1050,1410],0,false,false],
		["docks_booking_attendant","记货伙计",[2010,1900],0,false,false]]
	return []
static func project(id: StringName) -> Array:
	var result: Array=[]; var stationary:=0
	for row: Array in spec(id):
		var guard:=bool(row[5]); var moving:=bool(row[4]); var idle:=GUARD_IDLE if guard else MERCHANT_IDLE
		if not moving and not guard:
			idle=FARMER if stationary%2==0 else WAITER; stationary+=1
		result.append({"npc_id":"harbour_life_"+String(row[0]),"npc_name":row[1],"pos":A.v(row[2])/Vector2(3072,2048),"sprite_path":idle,"walk_sprite_path":(GUARD_WALK if guard else MERCHANT_WALK) if moving else "","scale":1.0,"movement_mode":"patrol" if moving else "idle","patrol_axis":Vector2.RIGHT,"patrol_distance":float(row[3]),"patrol_speed":26.0 if guard else 22.0,"invert_patrol_facing":not guard,"walk_frame_seconds":0.12,"dialog_id":"","interaction_action":"","harbour_life_ground_anchored":true})
	return result
static func lanes(id: StringName) -> Array:
	var result: Array=[]
	for row: Array in spec(id):
		var foot:=A.v(row[2]); var distance:=float(row[3])
		result.append({"id":"crowd_"+String(row[0]),"points_px":[A.xy(foot-Vector2(distance,0)),A.xy(foot+Vector2(distance,0))],"moving":row[4],"native_body_min_px":[34.0,24.0]})
	return result
