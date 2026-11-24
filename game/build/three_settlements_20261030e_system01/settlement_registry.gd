extends RefCounted
const AUTHORS := {
	&"openworld_xiangzhou_city":"res://build/three_settlements_20261030e_system01/xiangzhou_author.gd",
	&"openworld_qinghe_town":"res://build/three_settlements_20261030e_qinghe01/qinghe_author.gd",
	&"openworld_yanmen_pass":"res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd"
}
const FIELD := "res://build/three_settlements_20261030e_system01/settlement_field.tscn"

static func author(id: StringName) -> Variant:
	return load(AUTHORS[id]) if AUTHORS.has(id) and ResourceLoader.exists(AUTHORS[id]) else null

static func start(router: Node, id: StringName, requested: Variant, action: String, version: int) -> bool:
	var a: Variant=author(id)
	if a==null or not ResourceLoader.exists(FIELD):return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok: bool) -> void:
		if ok:router.call("go_field_smart",id,requested,action,-1,version)
	):return false
	var current: StringName=router.get("_current_field_id")
	var versions: Dictionary=router.get("_local_layout_versions")
	var supplied: bool=requested is Vector2
	var same: bool=not supplied and current==id and router.get("_current_field_spawn") is Vector2
	var foot: Vector2=requested if supplied else (router.get("_current_field_spawn") if same else a.SOUTH_ARRIVAL/a.SIZE)
	var source_version: int=version if version>=0 else (int(versions.get(String(id),1)) if supplied or same else a.VERSION)
	if router.call("is_world_map_scene",current):
		foot=a.SOUTH_ARRIVAL/a.SIZE;source_version=a.VERSION
	elif current!=id:
		var returns: Dictionary=router.get("_portal_return_spawns")
		var key: String=router.call("_portal_route_key",current,id)
		if not returns.get(key) is Vector2:
			for portal: Dictionary in a.layout().portals:
				if StringName(portal.get("target_scene",""))==current:
					foot=portal.pos;source_version=a.VERSION;break
	var migrated: Variant=a.migration(foot,source_version)
	if not migrated is Vector2 or not a.safe_foot(migrated):return false
	var payload: Dictionary={"scene_id":id,"player_spawn":migrated,"settlement_layout_version":a.VERSION}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload);router.set("_current_field_id",id);router.set("_current_field_spawn",migrated)
	versions[String(id)]=a.VERSION;router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio()
	router.call("_transition_to",FIELD,&"field",{"title":"进入"+String(a.scene().display_name).get_slice(" · ",0)})
	return true
