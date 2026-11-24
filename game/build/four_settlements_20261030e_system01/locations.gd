extends RefCounted
const IDS := [&"openworld_bailu_ferry",&"openworld_east_sea_port",&"linxi_tutorial",&"linxi_village_center",&"linxi_village_scrollmap",&"ch1_s2_qingfeng",&"ch2_s1_zhuwei_market"]
const VERSION:=3001
const FIELD:="res://build/four_settlements_20261030e_system01/field.tscn"
const LINXI_RESTORE=preload("res://build/linxi_scale_access_20261030f_system01/restore.gd")
const BUILDING_RESTORE=preload("res://build/linxi_building_scale_20261030h_system01/restore.gd")
static func town(id:StringName)->Dictionary:
	var all:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://build/four_settlements_20261030e_system01/locations.json"))
	var row:Dictionary=all.get(String(id),{}).duplicate(true)
	if row.is_empty():return row
	for k in ["size","arrival","world_foot"]:row[k]=Vector2(row[k][0],row[k][1])
	return row
static func start(router:Node,id:StringName,requested:Variant,action:String,version:int)->bool:
	var row:=town(id)
	if row.is_empty():return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok:bool)->void:
		if ok:router.go_field_smart(id,requested,action,-1,version)
	):return false
	var active_version:int=int(row.get("layout_version",VERSION))
	if version>active_version:return false
	var current:StringName=router.get("_current_field_id");var versions:Dictionary=router.get("_local_layout_versions")
	var foot:Vector2=row.arrival/row.size
	# Keep the accepted master-yard3002 restoration; only center/south add3004.
	var source_version:int=version if version>=0 else int(versions.get(String(id),0))
	if current==id and id==&"linxi_tutorial" and source_version in [3001,3002]:
		var previous:Variant=requested if requested is Vector2 else router.get("_current_field_spawn")
		if not previous is Vector2:return false
		var restored:Variant=LINXI_RESTORE.restore(previous,source_version)
		if not restored is Vector2:return false
		foot=restored
	elif current==id and id in [&"linxi_village_center",&"linxi_village_scrollmap"]:
		var previous:Variant=requested if requested is Vector2 else router.get("_current_field_spawn")
		if not previous is Vector2:return false
		var restored:Variant=BUILDING_RESTORE.restore(id,previous,source_version)
		if not restored is Vector2:return false
		foot=restored
	elif current==id and (version==active_version or (version<0 and int(versions.get(String(id),0))==active_version)):
		var previous:Variant=requested if requested is Vector2 else router.get("_current_field_spawn")
		if previous is Vector2 and previous.is_finite() and previous.x>=0 and previous.y>=0 and previous.x<=1 and previous.y<=1:foot=previous
	elif row.returns.has(String(current)):
		var a:Array=row.returns[String(current)];foot=Vector2(a[0],a[1])/row.size
	var payload:Dictionary={"scene_id":id,"player_spawn":foot,"three_town_layout_version":active_version}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload);router.set("_current_field_id",id);router.set("_current_field_spawn",foot);versions[String(id)]=active_version;router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio();router.call("_transition_to",FIELD,&"field",{"title":"进入"+String(row.label)});return true
