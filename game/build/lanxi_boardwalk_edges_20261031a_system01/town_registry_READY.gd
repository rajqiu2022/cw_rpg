extends RefCounted
## Additive travel registry. Native layout updates are explicitly pinned; the original sixteen World doors stay unchanged.
const ROOT := "res://build/three_towns_world_20261029j_system01/"
const FIELD := ROOT + "town_field.tscn"
const WORLD := &"world_map_jianghu"
const WORLDS := [&"world_map_jianghu",&"world_map_jianghu_v15"]
const WORLD_SIZE := Vector2(12288,8192)
const VERSION := 1
const SETTLEMENTS=preload("res://build/four_settlements_20261030e_system01/locations.gd")
const ROAD=preload("res://build/linxi_mountain_road_20261030g_system01/road_entry.gd")
const ADOPTION30N=preload("res://build/sect_adoption_20261030n_system01/router_entry.gd")
const NATIVE_SOURCE_SHA := "0f39017f7f88cdc3f175e1962ee4b0a2882e67be034814df95d5d2b35d2ac8dd"
const SECT_IDS := [&"ch2_s4_lingyue_gate",&"ch7_s1_lieyun_valley_ferry",&"ch7_s2_mingwu_tea_town"]
const IDS := [&"openworld_redrock_town", &"openworld_desert_city", &"openworld_lanxi_zhai",&"ch2_s4_lingyue_gate",&"ch7_s1_lieyun_valley_ferry",&"ch7_s2_mingwu_tea_town",&"openworld_bailu_ferry",&"openworld_east_sea_port",&"linxi_tutorial",&"linxi_village_center",&"linxi_village_scrollmap",&"ch1_s2_qingfeng",&"ch2_s1_zhuwei_market",&"ch1_s1_road",&"openworld_wudang_gate",&"openworld_huashan_forecourt"]

static func town(id: StringName) -> Dictionary:
	if ADOPTION30N.IDS.has(id):return ADOPTION30N.town(id)
	if id==&"ch1_s1_road":return ROAD.town()
	if SETTLEMENTS.IDS.has(id):return SETTLEMENTS.town(id)
	match id:
		&"openworld_redrock_town":
			return {"id":id,"label":"赤岩镇","scene":"res://scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn","size":Vector2(7200,6400),"arrival":Vector2(2250,4480),"exit":Vector2(2250,4544),"world_foot":Vector2(2000,1050),"portal_id":"redrock_town_29j"}
		&"openworld_desert_city":
			return {"id":id,"label":"沙漠城","scene":"res://scenes/drafts/desert_town_20261029d/desert_town.tscn","size":Vector2(8520,5780),"arrival":Vector2(2560,4550),"exit":Vector2(2560,4614),"world_foot":Vector2(650,1050),"portal_id":"desert_city_29j"}
		&"openworld_lanxi_zhai":
			return {"id":id,"label":"岚溪寨","scene":"res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn","size":Vector2(7600,5200),"arrival":Vector2(1610,3900),"exit":Vector2(1610,3964),"world_foot":Vector2(900,6000),"portal_id":"lanxi_zhai_29j"}
		&"ch2_s4_lingyue_gate":
			return {"id":id,"label":"凌月派","scene":"res://scenes/drafts/sect_completion_20261030a/lingyue.tscn","size":Vector2(4800,3600),"arrival":Vector2(1900,3370),"inner_arrival":Vector2(3250,1120),"inner_source":&"openworld_lingyue_inner_court","sect":true,"world_foot":Vector2(0.9358724,0.55306756)*WORLD_SIZE}
		&"ch7_s1_lieyun_valley_ferry":
			return {"id":id,"label":"烈云谷","scene":"res://scenes/drafts/sect_completion_20261030a/lieyun.tscn","size":Vector2(4800,4000),"arrival":Vector2(2600,3730),"inner_arrival":Vector2(3100,1160),"inner_source":&"ch7_s3_lieyun_outpost_outer_ward","sect":true,"world_foot":Vector2(0.8300781,0.9141463)*WORLD_SIZE}
		&"ch7_s2_mingwu_tea_town":
			return {"id":id,"label":"茗雾山庄","scene":"res://scenes/drafts/sect_completion_20261030a/mingwu.tscn","size":Vector2(5600,3800),"arrival":Vector2(1700,3470),"inner_arrival":Vector2(4080,1350),"inner_source":&"ch7_s4_mingwu_manor_outer_court","sect":true,"world_foot":Vector2(0.9033203,0.9636981)*WORLD_SIZE}
	return {}

static func portal_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	for id: StringName in IDS.slice(0,3):
		var row:=town(id)
		rows.append({"id":row.portal_id,"label":row.label,"target_scene":String(id),"target_pos":row.arrival/row.size,"pos":row.world_foot/WORLD_SIZE,"source_spawn_pos":row.world_foot/WORLD_SIZE,"world_foot":row.world_foot,"source_scene":row.scene})
	return rows

static func source_valid() -> bool:
	if FileAccess.get_sha256(ROOT+"native_sources.json")!=NATIVE_SOURCE_SHA:return false
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"native_sources.json"))
	if not manifest is Dictionary or manifest.get("sources",{}).is_empty():return false
	for path: String in manifest.sources:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=manifest.sources[path]:
			push_error("[Three towns] Native source changed: "+path)
			return false
	return true

static func ensure_watcher(router: Node) -> void:
	if router.has_node("ThreeTownWorldWatcher"):return
	var watcher: Node=load(ROOT+"world_watcher.gd").new()
	watcher.name="ThreeTownWorldWatcher"
	router.add_child(watcher)

static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:
	if ADOPTION30N.IDS.has(id):return ADOPTION30N.start(router,id,requested,action,version) if source_valid() else false
	if id==&"ch1_s1_road":return ROAD.start(router,id,requested,action,version) if source_valid() else false
	if SETTLEMENTS.IDS.has(id):return SETTLEMENTS.start(router,id,requested,action,version) if source_valid() else false
	var row:=town(id)
	if row.is_empty() or not source_valid() or not ResourceLoader.exists(FIELD):return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok: bool) -> void:
		if ok:router.call("go_field_smart",id,requested,action,-1,version)
	):return false
	var current: StringName=router.get("_current_field_id")
	var same: bool=current==id and router.get("_current_field_spawn") is Vector2
	var foot: Vector2=requested if requested is Vector2 else (router.get("_current_field_spawn") if same else row.arrival/row.size)
	if row.get("sect",false):
		var known:Dictionary=router.get("_local_layout_versions")
		if not same or (version<1 and int(known.get(String(id),0))<1):foot=row.arrival/row.size
		if current==row.inner_source:foot=row.inner_arrival/row.size
	if router.call("is_world_map_scene",current):foot=row.arrival/row.size
	if not foot.is_finite() or foot.x<0.0 or foot.y<0.0 or foot.x>1.0 or foot.y>1.0:return false
	if version>VERSION:return false
	var payload: Dictionary={"scene_id":id,"player_spawn":foot,"three_town_layout_version":VERSION}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload)
	router.set("_current_field_id",id)
	router.set("_current_field_spawn",foot)
	var versions: Dictionary=router.get("_local_layout_versions")
	versions[String(id)]=VERSION
	router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio()
	router.call("_transition_to","res://build/sect_completion_20261030a_system01/sect_field.tscn" if row.get("sect",false) else FIELD,&"field",{"title":"进入"+String(row.label)})
	return true

static func enter_from_world(field: Node,row: Dictionary) -> void:
	if not is_instance_valid(field) or not is_v15_world(field):return
	var source_id:=get_world_id(field)
	var source: Vector2=field.get("world_container").to_local(field.get("_player").global_position)/WORLD_SIZE
	var returns: Dictionary=SceneRouter.get("_portal_return_spawns")
	returns[String(row.target_scene)+"->"+String(source_id)]=source
	SceneRouter.set("_portal_return_spawns",returns)
	SceneRouter.go_field_smart(StringName(row.target_scene),row.target_pos,"",15,VERSION)

static func leave_town(id: StringName) -> void:
	var row:=town(id)
	if row.is_empty():return
	var world_id: StringName=SceneRouter.get_active_world_map_scene()
	if not WORLDS.has(world_id):return
	var returns: Dictionary=SceneRouter.get("_portal_return_spawns")
	var foot: Vector2=returns.get(String(id)+"->"+String(world_id),row.world_foot/WORLD_SIZE)
	SceneRouter.go_field_smart(world_id,foot,"",15,-1)

static func is_v15_world(field: Node) -> bool:
	var id:=get_world_id(field)
	return WORLDS.has(id) and SceneRouter.world_version_for_scene(id)==15

static func actor_shape_clear(actor: Player) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree():return false
	var shape: CollisionShape2D=actor.get_node_or_null("CollisionShape2D")
	if shape==null or shape.shape==null or shape.disabled:return false
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape
	query.transform=shape.global_transform
	query.collision_mask=actor.collision_mask
	query.exclude=[actor.get_rid()]
	query.collide_with_areas=false
	query.collide_with_bodies=true
	query.margin=0.0
	return actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

static func get_world_id(field: Node) -> StringName:
	for property: Dictionary in field.get_property_list():
		if property.name=="_current_scene":
			var current: Variant=field.get("_current_scene")
			return current.scene_id if current!=null else &""
	return &""
