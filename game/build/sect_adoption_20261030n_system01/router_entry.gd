extends RefCounted
const CONTRACT=preload("res://build/sect_adoption_20261030n_system01/adoption_contract.gd")
const IDS=CONTRACT.IDS

static func town(id: StringName) -> Dictionary:return CONTRACT.town(id)

static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:
	if not IDS.has(id) or not ResourceLoader.exists(CONTRACT.FIELD):return false
	var row:=town(id)
	if row.is_empty():return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok: bool) -> void:
		if ok:router.call("go_field_smart",id,requested,action,-1,version)
	):return false
	var source: StringName=router.get("_current_field_id")
	var versions: Dictionary=router.get("_local_layout_versions")
	var report:=CONTRACT.resolve_spawn(id,requested,source,version,int(versions.get(String(id),0)),source==id,router.get("_current_field_spawn"))
	if report.is_empty():push_warning("[Sect30n] No authored safe arrival; original navigation retained");return false
	# Preserve the real foot that activated the unchanged original World gate,
	# not source-image foot_px metadata or the native outdoor's new coordinates.
	if source in [&"world_map_jianghu",&"world_map_jianghu_v15"]:
		var field: Node=router.get_tree().current_scene
		if is_instance_valid(field):
			var original_scene: SceneScript=field.get("_current_scene") as SceneScript
			var actor: Player=field.get("_player") as Player
			var world: Node2D=field.get("world_container") as Node2D
			if original_scene!=null and original_scene.scene_id==source and is_instance_valid(actor) and is_instance_valid(world):
				var source_foot: Vector2=world.to_local(actor.global_position)/CONTRACT.WORLD_SIZE
				var world_contract: Variant=router.call("layered_world_contract",original_scene)
				if world_contract!=null and world_contract.safe_foot(original_scene,source_foot):
					var returns: Dictionary=router.get("_portal_return_spawns")
					returns[String(id)+"->"+String(source)]=source_foot;router.set("_portal_return_spawns",returns)
					report["original_world_return_foot"]=source_foot
	var payload: Dictionary={"scene_id":id,"player_spawn":report.spawn,"sect_adoption_layout_version":CONTRACT.VERSION,"sect_adoption_spawn_report":report}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload);router.set("_current_field_id",id);router.set("_current_field_spawn",report.spawn)
	versions[String(id)]=CONTRACT.VERSION;router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio()
	router.call("_transition_to",CONTRACT.FIELD,&"field",{"title":"进入"+String(row.label)})
	return true
