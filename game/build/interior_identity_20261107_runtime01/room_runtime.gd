extends RefCounted
## Exact one-room successor. No fallback admission and no file/save writes.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Alias = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")
const ROOM := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const PROFILE := "interior_identity_20261107"
const TOKEN := "YIHONG_NATIVE_ROOM_20261107_V1"
const NATIVE_SCENE := "res://build/interior_identity_20261107_runtime01/native_actor.tscn"
const NATIVE_SCRIPT := "res://build/interior_identity_20261107_runtime01/native_actor.gd"
const OLD_BIN := "res://build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/yihongyuan27n_interior.bin"
const OLD_SHA := "4871b3e428bedd5c0c4c06882d5ebe36cc1660824100adb648027f82dec31d65"
const SHELL := "res://art/modules/interior_identity_20261106/yihongyuan_luxury_shell.png"
const SHELL_SHA := "d803b06561de9a1e014a7f270d61b3db707323ec760b71a16d8b85a1dafc47ab"
const BASE := "res://art/characters/yihongyuan_identity_20261106/"
const ARRIVAL := Vector2(768,850)
const HALF := Vector2(17,12)
const OLD_IDS := ["yihongyuan27n_matron","yihongyuan27n_waiter","yihongyuan27n_merchant","yihongyuan27n_scholar","yihongyuan27n_elder_guest","yihongyuan27n_woman_guest"]
const GRID := {
	"yihongyuan27n_musician": ["musician",Vector2i(523,951),Vector2(342,889),"1f3b2ba9af09ea00d4b3a21ab40f0133f2e0e00b6a01be1f6797733ce47c1974","seated",96.0/763.0,1.8],
	"yihongyuan27n_singer": ["singer",Vector2i(509,951),Vector2(250,901),"ac7963048c966f770e98f5cdad3dd70520af6519c7b1af1f4c5bc61df1ecb923","idle",121.0/840.0,1.4],
	"yihongyuan27n_tea_attendant": ["tea_attendant",Vector2i(508,952),Vector2(262,893),"bed8ec3aeae16d735a98bfde8e4801fa8fbe51bed214d3510df09d5d0cad9559","idle",116.0/827.0,1.4],
	"yihongyuan27n_receptionist": ["receptionist",Vector2i(508,951),Vector2(254,888),"2cccdcdaf499b90a0d1ffef33c22f948e545a8d9e304a0963081d3ecc74b2d55","idle",122.0/817.0,1.4],
}

static func is_profile(room: Dictionary) -> bool:
	return room.get("id") == ROOM and room.get("size") == Vector2(1536,1024) and room.get(PROFILE) == TOKEN

static func seal_room(field: Node,owner: RefCounted,scene: SceneScript,room: Dictionary) -> bool:
	if not is_profile(room) or owner == null or scene == null or String(scene.scene_id) != ROOM or owner.call("matches",field,scene) != true:
		return false
	var first: Dictionary = owner.call("receipt").get("source_first",{})
	if first.get(SHELL) != SHELL_SHA or not first.has(SHELL+".import") or first.get(OLD_BIN) != OLD_SHA or room.get("room_enclosure",{}).get("native_complete_shell") != SHELL:
		return false
	var shell_rows: Array = room.render.filter(func(row: Dictionary) -> bool: return row.get("owner_id")=="yihongyuan_identity_native_shell")
	if shell_rows.size()!=1 or shell_rows[0].get("texture")!=SHELL or shell_rows[0].get("scale")!=Vector2.ONE or shell_rows[0].get("position_px")!=Vector2(-64,-64) or shell_rows[0].get("centered",true) or shell_rows[0].get("yihongyuan_native_layers",[]).size()!=7:
		return false
	var roster: Array[String] = []
	for row: Dictionary in room.npcs:
		var id: String = String(row.get("data",{}).get("npc_id",""))
		if id in roster or (id not in OLD_IDS and not GRID.has(id)) or row.get("logical_id")!=LOGICAL or row.get("slot_key")!=LOGICAL+"/"+id:
			return false
		roster.append(id)
	return roster.size()==10 and Core.safe_body(room,ARRIVAL,HALF) and Core.npc_route_clear(room,ARRIVAL,ARRIVAL,HALF)

static func actor_plan(source: Dictionary,data: Dictionary,first: Dictionary) -> Dictionary:
	var id: String = String(data.get("npc_id",""))
	if id in OLD_IDS:
		return {"ok":true,"native":false}
	if not GRID.has(id) or source.get("logical_id") != LOGICAL or source.get("slot_key") != LOGICAL+"/"+id or source.get("ground_anchored") != true or source.get("body_offset_px")!=Vector2.ZERO or source.get("node_origin_offset_px",Vector2.ZERO)!=Vector2.ZERO:
		return {"ok":false}
	var row: Array = GRID[id]
	var path: String = BASE + String(row[0]) + "_idle_native.png"
	var cell: Vector2i = row[1]
	var ratio: float = float(row[5])
	var expected_half := Vector2(cell)*Vector2(0.07,0.09)*ratio
	var half: Vector2 = source.get("half_body",Vector2.ZERO)
	if data.get("sprite_path")!=path or data.get("movement_mode")!=row[4] or not is_equal_approx(float(data.get("scale",0)),ratio) or not is_equal_approx(float(data.get("idle_frame_seconds",0)),float(row[6])) or half.distance_to(expected_half)>0.001:
		return {"ok":false}
	if data.get("dialog_id","")!="" or data.get("interaction_action","")!="" or not data.get("conversation_sprite_paths",{}).is_empty() or data.get("walk_sprite_path","")!="" or data.get("region27d_calibrate_adult",false) or data.get("harbour_life_ground_anchored",false) or data.get("district_life_ground_anchored",false) or first.get(path)!=row[3] or not first.has(path+".import") or not first.has(NATIVE_SCENE) or not first.has(NATIVE_SCRIPT):
		return {"ok":false}
	var texture := load(path) as Texture2D
	if texture==null or texture.resource_path!=path or Vector2i(texture.get_size())!=Vector2i(cell.x*4,cell.y):
		return {"ok":false}
	return {"ok":true,"native":true,"texture":texture,"cell":Vector2(cell),"anchor":row[2],"half_body":half}

static func recover_predecessor(room: Dictionary,id: String,uv: Vector2,version: int,extension: Dictionary,entry: Dictionary) -> Dictionary:
	if not is_profile(room) or id!=ROOM: return entry
	if entry.get("ok")==true:
		var foot: Vector2 = entry.foot
		if Core.npc_route_clear(room,foot,foot,HALF): return entry
		# Live movement cannot normally leave an exact foot inside the new
		# footprint. Refuse to migrate if not legal in the old full geometry.
	elif entry.get("error","") not in ["REGION_SAVED_FOOT_BLOCKED","SAVED_FOOT_NEEDS_AUTHORED_MIGRATION"]:
		return entry
	if room.get("sources",{}).get(OLD_BIN)!=OLD_SHA or FileAccess.get_sha256(OLD_BIN)!=OLD_SHA:
		return Core.fail("YIHONG_RESTORE_PREDECESSOR_SOURCE")
	var old: Variant = bytes_to_var(FileAccess.get_file_as_bytes(OLD_BIN))
	if not old is Dictionary or old.get("id")!=ROOM or old.get("revision")!=room.get("revision"):
		return Core.fail("YIHONG_RESTORE_PREDECESSOR_ID")
	var earlier := Alias.arrive(old,id,uv,version,extension)
	if earlier.get("ok")!=true:
		return Core.fail("YIHONG_RESTORE_NOT_PREVIOUSLY_VALID")
	var foot: Vector2 = earlier.foot
	if not Core.npc_route_clear(old,foot,foot,HALF):
		return Core.fail("YIHONG_RESTORE_OLD_ACTOR_OVERLAP")
	if Core.safe_body(room,foot,HALF) and Core.npc_route_clear(room,foot,foot,HALF):
		return entry
	if not Core.safe_body(room,ARRIVAL,HALF) or not Core.npc_route_clear(room,ARRIVAL,ARRIVAL,HALF):
		return Core.fail("YIHONG_RESTORE_NEW_ARRIVAL")
	return {"ok":true,"foot":ARRIVAL,"reason":"yihong_exact_old_legal_now_obstructed","logical_id":id}
