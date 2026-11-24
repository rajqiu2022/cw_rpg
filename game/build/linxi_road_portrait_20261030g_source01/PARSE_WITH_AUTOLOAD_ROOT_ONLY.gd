extends SceneTree
## Root-only syntax/resource load with registered project autoloads.
## Never instantiates a PackedScene, injects input, opens a save, or starts a map.
const SELF := "res://build/linxi_road_portrait_20261030g_source01/PARSE_WITH_AUTOLOAD_ROOT_ONLY.gd"
const OUT := "res://build/linxi_mountain_road_20261030g_qa01/PARSE_WITH_AUTOLOAD_ROOT_ACTUAL.json"
const PATHS: Array[String] = [
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/build__luoyang_garden_city_minimap_20261030b_system01__city_minimap.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/build__three_settlements_20261030e_system01__city_minimap.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/build__four_settlements_20261030e_system01__minimap.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/build__four_settlements_20261030e_system01__locations.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/build__three_towns_world_20261029j_system01__town_registry.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__autoload__scene_router.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_execution_index_20261022ap.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_estate_index_20261021am.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_market_two_shops_index_20261021ao.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_precomputed_bundle_index_20261018r.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_docks_district08_index_20261019aa.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_docks_workyard_index_20261019ac.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_quarters_index_20261022ap.gd",
	"res://build/linxi_road_portrait_20261030g_source01/closure01_READY/scripts__city__luoyang_full_city_index_20261022ap.gd",
	"res://build/player_portrait_minimap_20261030f_system01/portrait_marker.gd",
	"res://build/linxi_scale_access_20261030f_system01/linxi_master.tscn",
	"res://build/linxi_scale_access_20261030f_system01/linxi_master_ground.gdshader",
	"res://build/linxi_scale_access_20261030f_system01/restore.gd",
	"res://build/linxi_mountain_road_20261030g_system01/road_author.gd",
	"res://build/linxi_mountain_road_20261030g_system01/road_entry.gd",
	"res://build/linxi_mountain_road_20261030g_system01/road_field.gd",
	"res://build/linxi_mountain_road_20261030g_system01/road_field.tscn",
	"res://build/linxi_road_portrait_20261030g_source01/road_minimap.gd",
	"res://build/linxi_road_portrait_20261030g_source01/road_minimap_base.gd",
	"res://build/luoyang_linxi_road_avatar_20261030g_snapshot01/scene_router.gd",
	"res://data/scenes/ch1_s1_road.tres",
	"res://data/maps/ch1_s1_road_layout_v5.tres",
	"res://art/characters/prop_corpse_v2.png",
	"res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png",
	"res://art/modules/huashan_map_20261029m/granite_crag.png",
	"res://art/modules/huashan_map_20261029m/granite_ground.png",
	"res://art/modules/linxi_mountain_road_20261030g/cave_mouth.png",
	"res://art/modules/miao_recompose_20261029g/woodland_floor.png",
	"res://art/modules/prop/chest_normal_closed_v1.png",
	"res://art/modules/prop/linxi_brazier_forge_v1.png",
	"res://art/modules/prop/linxi_stone_tablet_v2.png",
	"res://art/modules/veg/veg_bamboo_cluster_a.png",
	"res://art/modules/veg/veg_grass_tuft_a.png",
	"res://scenes/field_walkable.tscn",
	"res://scripts/field/field_walkable_controller.gd"
]
var checks: Array[Dictionary] = []
var errors: Array[String] = []
var resources: Array[Dictionary] = []
var started_usec := 0
var checkpoint_suspended := false

func _initialize() -> void:
	call_deferred("_run")

func need(okay: bool, label: String) -> bool:
	checks.append({"check":label,"passed":okay})
	if not okay:
		errors.append(label);printerr("PARSE30G_FAIL ",label)
	return okay

func _run() -> void:
	started_usec=Time.get_ticks_usec()
	if FileAccess.file_exists(OUT):
		printerr("IMMUTABLE_PARSE_OUTPUT_ALREADY_EXISTS");quit(2);return
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if not need(bridge!=null,"PLATFORM_BRIDGE_PRESENT"):_finish();return
	if not need(bridge.has_method("set_checkpoint_saves_suspended") and bridge.has_method("is_checkpoint_saves_suspended"),"CHECKPOINT_SUSPEND_API_PRESENT"):_finish();return
	bridge.call("set_checkpoint_saves_suspended",true)
	checkpoint_suspended=bridge.call("is_checkpoint_saves_suspended")==true
	if not need(checkpoint_suspended,"CHECKPOINT_SAVES_SUSPENDED_BEFORE_LOAD"):_finish();return
	if not need(current_scene==null and get_nodes_in_group("player").is_empty(),"NO_MAIN_SCENE_OR_PLAYER_BEFORE_LOAD"):_finish();return
	for path: String in PATHS:
		var row: Dictionary={"path":path,"sha256":FileAccess.get_sha256(path),"exists":FileAccess.file_exists(path),"resource_class":"","loaded":false,"can_instantiate":null}
		var resource: Resource=load(path)
		var okay: bool=resource!=null
		row.loaded=okay
		if resource!=null:row.resource_class=resource.get_class()
		if resource is Script:
			okay=resource.can_instantiate();row.can_instantiate=okay
		elif resource is PackedScene:
			okay=resource.can_instantiate();row.can_instantiate=okay
		resources.append(row)
		need(okay,"RESOURCE_LOAD:"+path)
		print("PARSE30G_RESOURCE ",okay," ",path," SHA256=",row.sha256)
	need(current_scene==null and get_nodes_in_group("player").is_empty(),"NO_MAIN_SCENE_OR_PLAYER_AFTER_LOAD")
	checkpoint_suspended=bridge.call("is_checkpoint_saves_suspended")==true
	need(checkpoint_suspended,"CHECKPOINT_SAVES_REMAIN_SUSPENDED")
	_finish()

func _finish() -> void:
	var hashes: Dictionary={}
	for path: String in PATHS:hashes[path]=FileAccess.get_sha256(path)
	var result: Dictionary={"status":"RUNTIME_AUTOLOAD_SYNTAX_RESOURCE_ONLY","passed":errors.is_empty(),"checks":checks,"check_count":checks.size(),"errors":errors,"resource_count_expected":40,"resource_count_attempted":resources.size(),"resources":resources,"source_sha256":hashes,"script_sha256":FileAccess.get_sha256(SELF),"checkpoint_saves_suspended":checkpoint_suspended,"current_scene_is_null":current_scene==null,"player_group_count":get_nodes_in_group("player").size(),"field_instantiations":0,"actor_instantiations":0,"input_events_injected":0,"real_save_contents_read":false,"save_calls":0,"save_writes":0,"physics_or_input_or_ART_credit":false,"raw_stderr_must_be_reviewed":true,"duration_usec":Time.get_ticks_usec()-started_usec}
	var file:=FileAccess.open(OUT,FileAccess.WRITE)
	if file==null:printerr("PARSE30G_OUTPUT_OPEN_FAILED");quit(2);return
	file.store_string(JSON.stringify(result,"\t")+"\n");file.close()
	print("PARSE30G_RESULT checks=",checks.size()," failures=",errors.size()," resources=",resources.size(),"/40 output=",OUT," SHA256=",FileAccess.get_sha256(OUT))
	# Do not re-enable checkpoint saving during headless shutdown notifications.
	quit(1 if not errors.is_empty() else 0)
