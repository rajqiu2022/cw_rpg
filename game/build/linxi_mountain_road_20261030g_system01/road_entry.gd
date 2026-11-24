extends RefCounted
const A=preload("res://build/linxi_mountain_road_20261030g_system01/road_author.gd")
const FIELD:="res://build/linxi_mountain_road_20261030g_system01/road_field.tscn"
const VERSION:=3003
static func town() -> Dictionary:
	return {"id":A.ID,"label":"林西村外 · 山道","scene":FIELD,"size":A.SIZE,"layout_version":VERSION,"arrival":A.LINXI_ARRIVAL,"world_foot":Vector2(2600,3999.12),"returns":{"linxi_village_center":A.LINXI_ARRIVAL,"ch1_s2_qingfeng":A.ZHUWEI_ARRIVAL,"interior_bandit_cave":A.CAVE_RETURN}}
static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:
	if id!=A.ID or version>A.VERSION:return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok: bool)->void:
		if ok:router.go_field_smart(id,requested,action,-1,version)
	):return false
	var current: StringName=router.get("_current_field_id");var versions: Dictionary=router.get("_local_layout_versions")
	var foot: Vector2=A.LINXI_ARRIVAL/A.SIZE
	if current==id:
		var previous: Variant=requested if requested is Vector2 else router.get("_current_field_spawn")
		var old_version: int=version if version>=0 else int(versions.get(String(id),1))
		if previous is Vector2:
			var migrated: Variant=A.migration(previous,old_version)
			if not migrated is Vector2:return false
			foot=migrated
	elif current==&"interior_bandit_cave":foot=A.CAVE_RETURN/A.SIZE
	elif current==&"ch1_s2_qingfeng":foot=A.ZHUWEI_ARRIVAL/A.SIZE
	if not A.safe_foot(foot):return false
	var payload: Dictionary={"scene_id":id,"player_spawn":foot,"three_town_layout_version":A.VERSION}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload);router.set("_current_field_id",id);router.set("_current_field_spawn",foot)
	versions[String(id)]=A.VERSION;router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio();router.call("_transition_to",FIELD,&"field",{"title":"进入林西村外山道"});return true
