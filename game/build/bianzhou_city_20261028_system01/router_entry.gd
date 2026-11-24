extends RefCounted
const Author = preload("res://build/bianzhou_city_20261028_system01/city_author.gd")
const FIELD := "res://build/bianzhou_city_20261028_system01/bianzhou_field.tscn"

static func start(router: Node, id: StringName, requested: Variant, action: String, version: int) -> bool:
	if id!=Author.ID or not ResourceLoader.exists(FIELD):return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok: bool) -> void:
		if ok:router.call("go_field_smart",id,requested,action,-1,version)
	):return false
	var current: StringName=router.get("_current_field_id")
	var versions: Dictionary=router.get("_local_layout_versions")
	var supplied: bool=requested is Vector2
	var same: bool=not supplied and current==id and router.get("_current_field_spawn") is Vector2
	var foot: Vector2=requested if supplied else (router.get("_current_field_spawn") if same else Vector2(3072,5910)/Author.SIZE)
	var source_version: int=version if version>=0 else (int(versions.get(String(id),1)) if supplied or same else Author.VERSION)
	# World gateways still carry legacy city UVs; always arrive outside this gate.
	# Interior and OldPost returns retain their original remembered coordinates.
	if router.call("is_world_map_scene",current):
		foot=Vector2(3072,5910)/Author.SIZE
		source_version=Author.VERSION
	var migrated: Variant=Author.migration(foot,source_version)
	if not migrated is Vector2 or not Author.safe_foot(migrated):return false
	# Content construction must be complete before changing navigation state.
	var scene: SceneScript=Author.scene()
	if scene.map_layout==null or not FileAccess.file_exists(Author.GATE_BINDING):return false
	var payload: Dictionary={"scene_id":id,"player_spawn":migrated,"bianzhou_layout_version":Author.VERSION}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload);router.set("_current_field_id",id);router.set("_current_field_spawn",migrated)
	versions[String(id)]=Author.VERSION
	router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio()
	router.call("_transition_to",FIELD,&"field",{"title":"进入汴州城"})
	return true
