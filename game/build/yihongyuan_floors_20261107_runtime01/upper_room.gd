extends RefCounted
## Exact second floor presentation and one scoped predecessor recovery.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Alias = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")
const LOWER := "yihongyuan27n_interior"
const UPPER := "yihongyuan27n_upper"
const SHELL := "res://art/modules/yihongyuan_floors_20261107/upper_shell.png"
const STAIR := "res://art/modules/yihongyuan_floors_20261107/up_stair.png"
const PREV := "res://build/interior_identity_20261107_runtime01/yihongyuan27n_interior.bin"
const PREV_SHA := "649075ce491953d63013f9f4ca0fe7d6eb3e6451e28980ff5865e451d9c004d9"
const HALF := Vector2(17,12)
const SAFE_LOWER := Vector2(768,850)
const LOWER_DOOR := Vector2(416,456)
const UPPER_DOOR := Vector2(768,928)
const UPPER_ARRIVAL := Vector2(768,832)
const LOWER_RETURN := Vector2(416,576)

static func seal_upper(field: Node, owner: RefCounted, scene: SceneScript, room: Dictionary) -> bool:
	if room.get("id")!=UPPER or room.get("size")!=Vector2(1536,1024) or room.get("yihong_floor_profile","")!="YIHONG_UPPER_20261107_V1" or scene==null or scene.scene_id!=StringName(UPPER) or owner==null or not owner.call("matches",field,scene):
		return false
	var pins: Dictionary = owner.call("receipt").get("source_first",{})
	if not pins.has(SHELL) or pins.get(SHELL)!=room.get("sources",{}).get(SHELL) or not pins.has(SHELL+".import") or not pins.has(STAIR) or not pins.has(STAIR+".import"):
		return false
	var shell_rows: Array = room.render.filter(func(row: Dictionary) -> bool: return row.get("owner_id")=="yihong_upper_native_shell")
	var stairs: Array = room.render.filter(func(row: Dictionary) -> bool: return row.get("owner_id")=="yihong_upper_descending_threshold")
	if shell_rows.size()!=1 or shell_rows[0].texture!=SHELL or shell_rows[0].position_px!=Vector2.ZERO or shell_rows[0].scale!=Vector2.ONE or shell_rows[0].get("yihongyuan_native_layers",[]).size()!=7 or stairs.size()!=1 or stairs[0].texture!=STAIR:
		return false
	if room.get("room_enclosure",{}).get("native_complete_shell")!=SHELL or room.portals.size()!=1 or not room.npcs.is_empty() or not room.interactions.is_empty():
		return false
	var down: Dictionary = room.portals[0]
	var target: Dictionary = down.data.get("region27d_target",{})
	return down.id=="yihong_stairs_down_20261107" and down.logical_id==UPPER and down.foot==UPPER_DOOR and target.get("region_id")==LOWER and target.get("logical_id")==LOWER and Core.vec(target.get("foot_px"))==LOWER_RETURN and Core.safe_segment(room,UPPER_ARRIVAL,UPPER_DOOR,HALF)

static func recover_lower_stair(room: Dictionary,id: String,uv: Vector2,version: int,extension: Dictionary,entry: Dictionary) -> Dictionary:
	if entry.get("ok")==true or id!=LOWER or room.get("id")!=LOWER or room.get("yihong_floor_profile","")!="YIHONG_LOWER_20261107_V1":
		return entry
	if extension.is_empty() or entry.get("error","") not in ["REGION_SAVED_FOOT_BLOCKED","YIHONG_RESTORE_NOT_PREVIOUSLY_VALID","YIHONG_RESTORE_OLD_ACTOR_OVERLAP"]:
		return entry
	var foot: Vector2 = Core.vec(extension.get("global_foot_px"))
	# Only a previous versioned exact foot inside the new stair blocker band.
	if not Rect2(336,400,160,164).has_point(foot) or Core.safe_body(room,foot,HALF) or room.sources.get(PREV)!=PREV_SHA or FileAccess.get_sha256(PREV)!=PREV_SHA:
		return entry
	var old: Variant = bytes_to_var(FileAccess.get_file_as_bytes(PREV))
	if not old is Dictionary or old.get("id")!=LOWER or old.get("revision")!=room.get("revision"):
		return entry
	var original := Alias.arrive(old,id,uv,version,extension)
	if original.get("ok")!=true or original.get("foot")!=foot or not Core.npc_route_clear(old,foot,foot,HALF) or not Core.safe_body(room,SAFE_LOWER,HALF) or not Core.npc_route_clear(room,SAFE_LOWER,SAFE_LOWER,HALF):
		return entry
	return {"ok":true,"foot":SAFE_LOWER,"reason":"yihong_recent_lower_legal_now_stair_blocked","logical_id":LOWER}
