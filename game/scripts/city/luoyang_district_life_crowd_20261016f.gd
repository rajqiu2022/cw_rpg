extends RefCounted
const MERCHANT_IDLE="res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
const MERCHANT_WALK="res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"
const GUARD_IDLE="res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png"
const GUARD_WALK="res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png"
const FARMER="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"
const WAITER="res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"
const VENDOR="res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
const IDLES={"merchant":MERCHANT_IDLE,"guard":GUARD_IDLE,"farmer":FARMER,"waiter":WAITER,"vendor":VENDOR}
static func source_paths() -> Dictionary:
	var out: Dictionary={"res://scripts/city/luoyang_district_life_crowd_20261016f.gd":true,MERCHANT_WALK:true,GUARD_WALK:true}
	for path: String in IDLES.values(): out[path]=true
	return out
static func project(rows: Array) -> Array:
	var out: Array=[]; var ids: Dictionary={}
	for row: Dictionary in rows:
		var id: String="district_life_"+String(row.get("id","")); var family: String=String(row.get("family",""))
		var distance: float=float(row.get("distance_px",0)); var foot: Variant=row.get("foot_px")
		if ids.has(id) or not IDLES.has(family) or not foot is Array or foot.size()!=2 or distance<0 or (distance>0 and family not in ["merchant","guard"]): return []
		ids[id]=true
		out.append({"npc_id":id,"npc_name":String(row.get("name","")),"pos":Vector2(foot[0],foot[1])/Vector2(3072,2048),"sprite_path":IDLES[family],"walk_sprite_path":(GUARD_WALK if family=="guard" else MERCHANT_WALK) if distance>0 else "","scale":1.0,"movement_mode":"patrol" if distance>0 else "idle","patrol_axis":Vector2.RIGHT,"patrol_distance":distance,"patrol_speed":24.0 if family=="guard" else 22.0,"invert_patrol_facing":family!="guard","idle_frame_seconds":.18,"walk_frame_seconds":.12,"dialog_id":"","interaction_action":"","district_life_ground_anchored":true})
	return out
