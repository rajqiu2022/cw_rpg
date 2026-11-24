extends "res://tests/test_luoyang_enclosure_native_depth_focused_gpu_20261009.gd"
## Limited pure consumers. No Field/input/visual approval. Each OS process has
## its own unmodified candidate flags; typed:int migration calls are NOT used
## to claim rejection of float/bool arguments.
const PURE_PATH := "res://tests/test_luoyang_enclosure_native_depth_and_portal_units_20261009.gd"
const DEPTH_PATH := "res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd"
const EXTRA_PINS := {
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/maps/world_map_jianghu_layout_v14.tres":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b",
	"res://data/scenes/ch4_s4_ancient_temple.tres":"1570a4d9cfcb0508a12bfa639052db8aec11ab25634a3f5c606d19cbe2223730",
	"res://data/maps/ch4_s4_ancient_temple_layout_v1.tres":"c639287b0afff4c5e2e8ad667438a5b023102a1215549610189540c8e96a26f0",
	"res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_scene.tres":"b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres":"1d5cca7d70b14032f116964533cc33b9a1b7937beb85c829a4148dfa5c79cc82",
	"res://data/maps/luoyang_v3_legacy/ch4_s1_luoyang_yamen_scene.tres":"7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"res://data/maps/luoyang_v3_legacy/ch4_s1_luoyang_yamen_layout.tres":"658d7038a28f63aa84c701f604bd04405dcff3a8df6bacc7c533557e2e73ab63",
	"res://data/maps/luoyang_v3_legacy/ch4_s2_canal_docks_scene.tres":"81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5",
	"res://data/maps/luoyang_v3_legacy/ch4_s2_canal_docks_layout.tres":"0cc4afd6ec4583b62a9979e79ea88076e2b573f4fa91fb82dd424fa8dfc8c4a3",
	"res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_scene.tres":"5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_layout.tres":"d99c58dc2ad2e8b1bfbcbc1ac69e7a9aa08e2ac7cfffc773d4b5708f6825b60c"
}
# Independent QA table, not obtained from C.FRESH_AUTHORED_ROUTES. Each source
# portal/hotspot and each target slot is also checked from separate frozen disk.
const ROUTE_CASES := [
	["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","enter_luoyang",Vector2(.5,.73),"to_city_gate",Vector2(1536,1860)],
	["ch4_s1_luoyang_yamen","ch4_s0_luoyang_gate","to_city_gate",Vector2(.5,.325),"enter_luoyang",Vector2(1536,500)],
	["ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","to_south_market",Vector2(.955,.355),"to_yamen_square",Vector2(1536,770)],
	["ch4_s1_luoyang_yamen","ch4_s2_canal_docks","to_canal_quay",Vector2(.28,.52),"to_yamen_square",Vector2(260,790)],
	["ch4_s2_canal_docks","ch4_s1_luoyang_yamen","to_yamen_square",Vector2(.85,.59),"to_canal_quay",Vector2(2790,1350)],
	["ch4_s2_canal_docks","ch4_s3_luoyang_market","to_south_market",Vector2(.955,.355),"to_canal_docks",Vector2(2840,1060)],
	["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen","to_yamen_square",Vector2(.15,.59),"to_south_market",Vector2(300,1220)],
	["ch4_s3_luoyang_market","ch4_s0_luoyang_gate","to_city_gate",Vector2(.35,.69),"enter_luoyang",Vector2(1536,500)],
	["ch4_s3_luoyang_market","ch4_s2_canal_docks","to_canal_docks",Vector2(.28,.52),"to_south_market",Vector2(260,1740)],
	["world_map_jianghu","ch4_s0_luoyang_gate","luoyang",Vector2(.5,.9),"return_world",Vector2(1536,1860)],
	["ch4_s4_ancient_temple","ch4_s3_luoyang_market","legacy_portal_6",Vector2(.12,.75),"to_ancient_temple",Vector2(1536,1860)],
	["ch4_s4_ancient_temple","ch4_s2_canal_docks","legacy_portal_7",Vector2(.12,.75),"canal_world_ferry",Vector2(340,1840)]
]
var pure_rows: Array[Dictionary]=[]

static func fixture_sources() -> Array[String]:
	var result: Array[String]=[PURE_PATH,"res://tests/test_luoyang_enclosure_native_depth_focused_gpu_20261009.gd",DEPTH_PATH]
	for path: String in EXTRA_PINS: result.append(path)
	for id: String in IDS: result.append("res://data/scenes/%s.tres"%id)
	return result

func _f32(value: float) -> Variant:
	if not is_finite(value): return null
	var native: float=PackedFloat32Array([value]).to_byte_array().decode_float(0)
	if not is_finite(native): return null
	return 0.0 if native==0.0 else native

func _adjacent(value: float,step: int) -> float:
	var bytes: PackedByteArray=PackedFloat32Array([value]).to_byte_array()
	bytes.encode_u32(0,int(bytes.decode_u32(0))+step)
	return bytes.decode_float(0)

func _pure_depth(script: Script) -> void:
	for value: float in [0.0,-0.0,830.0,829.999999523163,_adjacent(830.,-1),_adjacent(830.,1),830.+pow(2.,-15),-8.0,1e200,NAN,INF,-INF]:
		var actual: Variant=script.call("native_depth_key",value)
		var expected: Variant=_f32(value)
		_check((actual==null) if expected==null else typeof(actual)==TYPE_FLOAT and var_to_bytes(actual)==var_to_bytes(expected),"native key independent packed codec "+PackedFloat64Array([value]).to_byte_array().hex_encode())
		pure_rows.append({"kind":"native_codec","input_float64_hex":PackedFloat64Array([value]).to_byte_array().hex_encode(),"actual_native_hex":var_to_bytes(actual).hex_encode(),"invalid_expected":expected==null})
	var values: Array=[[_adjacent(830.,-1),false,0],[830.,false,0],[830.,false,1],[829.999999523163,true,0],[830.,true,1],[_adjacent(830.,1),false,0]]
	var keys: Array[Dictionary]=[]
	for item: Array in values:
		var actual: Dictionary=script.call("canonical_depth_order_key",item[0],item[1],item[2])
		var expected: Dictionary={"foot_y":_f32(item[0]),"kind_rank":1 if item[1] else 0,"stable_ordinal":item[2]}
		_check(actual==expected,"tuple key exact independent native expectation")
		keys.append(actual)
	for a: int in keys.size():
		for b: int in keys.size():
			_check(script.call("depth_key_before",keys[a],keys[b])==(a<b),"strict tuple ordering/reflexivity/antisymmetry "+str(a)+"/"+str(b))
			for c: int in keys.size():
				if a<b and b<c: _check(script.call("depth_key_before",keys[a],keys[c])==true,"strict tuple transitivity")
	var valid: Dictionary=keys[1]
	for key: Dictionary in [{},{"foot_y":830.,"kind_rank":0,"stable_ordinal":0,"extra":true},{"foot_y":830,"kind_rank":0,"stable_ordinal":0},{"foot_y":829.999999523163,"kind_rank":0,"stable_ordinal":0},{"foot_y":830.,"kind_rank":2,"stable_ordinal":0},{"foot_y":830.,"kind_rank":true,"stable_ordinal":0},{"foot_y":830.,"kind_rank":0,"stable_ordinal":-1},{"foot_y":830.,"kind_rank":0,"stable_ordinal":0.0},{"foot_y":NAN,"kind_rank":0,"stable_ordinal":0},{"foot_y":INF,"kind_rank":0,"stable_ordinal":0}]:
		_check(script.call("depth_key_before",key,valid)==false and script.call("depth_key_before",valid,key)==false,"malformed tuple rejected "+var_to_bytes(key).hex_encode())
	for value: float in [NAN,INF,-INF,1e200]: _check((script.call("canonical_depth_order_key",value,true,0) as Dictionary).is_empty(),"invalid float tuple closed")
	_check((script.call("canonical_depth_order_key",830.,true,-1) as Dictionary).is_empty(),"negative ordinal closed")
	# Synthetic runtime snapshot fixture (not Field), actual consumer call.
	# A mismatched-parent or nonfinite member must prevent ALL reordering.
	var world:=Node2D.new(); var other:=Node2D.new()
	root.add_child(world); world.add_child(other)
	var first_node:=Node2D.new(); var second_node:=Node2D.new()
	world.add_child(first_node); other.add_child(second_node)
	first_node.z_index=11; second_node.z_index=12
	var helper: RefCounted=script.new()
	helper.set("_world",world)
	var fixture_entries: Array[Dictionary]=[{"id":"synthetic_a","node":first_node,"actor":false,"foot_local":Vector2(0,16),"ordinal":0,"band":-1,"foot_y":0.0},{"id":"synthetic_b","node":second_node,"actor":false,"foot_local":Vector2(0,8),"ordinal":1,"band":-1,"foot_y":0.0}]
	helper.set("_depth_entries",fixture_entries)
	var order_before: Array=[first_node.get_index(),second_node.get_index()]
	helper.call("_refresh_depth_order")
	_check(helper.get("_native_snapshot_valid")==false and first_node.z_index==11 and second_node.z_index==12 and order_before==[first_node.get_index(),second_node.get_index()],"synthetic mixed parents rejects entire snapshot before any Z/order write")
	other.remove_child(second_node); world.add_child(second_node)
	var entries: Array=helper.get("_depth_entries")
	entries[0].foot_local=Vector2(0,NAN)
	helper.call("_refresh_depth_order")
	_check(helper.get("_native_snapshot_valid")==false and first_node.z_index==11 and second_node.z_index==12,"synthetic nonfinite complete snapshot no partial reorder")
	helper=null; world.queue_free()

func _source_definition(id: String) -> SceneScript:
	var path: String="res://data/maps/luoyang_v3_legacy/%s_scene.tres"%id if id in IDS else "res://data/scenes/%s.tres"%id
	return ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript

func _source_layout(id: String) -> WalkableMapLayout:
	var path: String="res://data/maps/luoyang_v3_legacy/%s_layout.tres"%id if id in IDS else "res://data/maps/world_map_jianghu_layout_v14.tres" if id=="world_map_jianghu" else "res://data/maps/ch4_s4_ancient_temple_layout_v1.tres"
	return ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout

func _pure_portals(script: Script,pair: bool) -> void:
	var records: Dictionary={}
	var reader: RefCounted=(load(RAW_PATH) as Script).new()
	for id: String in IDS:
		records[id]=reader.call("independent_record",StringName(id))
		_check(not records[id].is_empty(),"independent current author record "+id)
		var canonical: SceneScript=ResourceLoader.load("res://data/scenes/%s.tres"%id,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		_check(canonical!=null and canonical.scene_id==StringName(id) and not canonical.has_meta("city_enclosure_manifest_sha"),"current uncut canonical explicitly not enclosure "+id)
		_check(script.call("_enclosure_arrival_context",StringName(id))==pair,"actual process pair/single/neither context "+id)
	for test: Array in ROUTE_CASES:
		var source: SceneScript=_source_definition(test[0])
		var layout: WalkableMapLayout=_source_layout(test[0])
		var source_matches: int=0
		if test[0]=="ch4_s4_ancient_temple":
			var index: int=6 if test[1]=="ch4_s3_luoyang_market" else 7
			_check(source!=null and layout!=null and layout.portals.is_empty() and layout.interactions.is_empty() and source.hotspots[index].get("action")=="scene:"+test[1],"original Temple exact actual6/7 source hotspot")
			source_matches=1
		elif source!=null and layout!=null:
			for portal: Dictionary in layout.portals:
				var uv: Variant=portal.get("target_pos")
				if portal.get("id")==test[2] and portal.get("target_scene")==test[1] and uv is Vector2 and uv.x==test[3].x and uv.y==test[3].y: source_matches+=1
		_check(source!=null and source.scene_id==StringName(test[0]) and source_matches==1,"original frozen source portal exact "+test[0]+"->"+test[1])
		var slots: Array=[]
		for slot_row: Dictionary in records[test[1]].gameplay_slots.portals:
			if slot_row.get("source_id")==test[4]: slots.append(slot_row)
		_check(slots.size()==1 and Vector2(slots[0].arrival_foot_px[0],slots[0].arrival_foot_px[1])==test[5],"independent target exact author slot "+test[4])
		var actual: Dictionary=script.call("migrate_spawn_report",StringName(test[1]),test[3],1,StringName(test[0]))
		var expected: Vector2=test[5]/Vector2(3072,2048)
		_check((actual.get("scene_id")==test[1] and actual.get("spawn") is Vector2 and var_to_bytes(actual.spawn)==var_to_bytes(expected) and actual.get("source_version")==1 and actual.get("target_version")==3 and actual.get("reason")=="exact_live_authored_portal") if pair else actual.is_empty(),"actual source1 mapping or context rejection "+test[0]+"->"+test[1])
		pure_rows.append({"kind":"authored_portal","source":test[0],"target":test[1],"source_portal":test[2],"target_slot":test[4],"authored_uv_hex":var_to_bytes(test[3]).hex_encode(),"independent_expected_spawn_hex":var_to_bytes(expected).hex_encode(),"actual":actual,"context_pair":pair})
		for bad: Vector2 in [Vector2(_adjacent(test[3].x,1),test[3].y),Vector2.ZERO,Vector2(INF,0),Vector2(NAN,0)]:
			_check((script.call("migrate_spawn_report",StringName(test[1]),bad,1,StringName(test[0])) as Dictionary).is_empty(),"wrong native UV/unsafe unmatched coordinate closed")
		_check((script.call("migrate_spawn_report",StringName(test[1]),test[3],1,&"") as Dictionary).is_empty(),"source1 empty source rejected")
		for version: int in [2,99]: _check((script.call("migrate_spawn_report",StringName(test[1]),test[3],version,StringName(test[0])) as Dictionary).is_empty(),"unknown integer version rejected")
		# Legal current3 memory is independently authored, unchanged in every mode.
		var current: Dictionary=script.call("migrate_spawn_report",StringName(test[1]),expected,3)
		_check(current.get("spawn") is Vector2 and var_to_bytes(current.spawn)==var_to_bytes(expected) and current.get("reason")=="same_version_local_clearance","current3 exact memory unchanged")
		var nav: Dictionary={"current_field":test[1],"current_field_spawn":[expected.x,expected.y],"local_layout_versions":{test[1]:3},"portal_return_spawns":{}}
		var prepared: Dictionary=script.call("prepare_navigation",nav,StringName(test[1]),{test[1]:3})
		_check(not prepared.is_empty() and prepared.get("current_field_spawn")==nav.current_field_spawn,"actual current3 navigation exact")
		for bad_version: Variant in [2,99,1.5,"3",true]:
			var bad_nav: Dictionary=nav.duplicate(true); bad_nav.local_layout_versions[test[1]]=bad_version
			_check((script.call("prepare_navigation",bad_nav,StringName(test[1]),{test[1]:3}) as Dictionary).is_empty(),"strict Dictionary raw version rejected "+str(typeof(bad_version)))
	_check((script.call("migrate_spawn_report",&"ch4_s1_luoyang_yamen",Vector2(.12,.75),1,&"ch4_s4_ancient_temple") as Dictionary).is_empty(),"Temple to nonwhite-listed Yamen rejected")
	_check((script.call("migrate_spawn_report",&"ch4_s0_luoyang_gate",Vector2(.5,.9),1,&"arbitrary_source") as Dictionary).is_empty(),"unknown source pair rejected")
	reader.call("release")

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null: quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"restored_before_exit":false}
	_check(default==false and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH)==BRIDGE_SHA,"checkpoint first before any await")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var permitted: Array[String]=["--luoyang-native-depth-pure","--fresh-start-only","--luoyang-v3-candidate","--luoyang-enclosure-v11-candidate"]
	_check(args.count("--luoyang-native-depth-pure")==1 and args.count("--fresh-start-only")==1,"explicit pure current scope")
	for arg: String in args: _check(arg in permitted and args.count(arg)==1,"bounded unique process mode flag")
	var pair: bool="--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual WASAPI/engine/time")
	output="res://build/joint_world_luoyang_20261003_qa/enclosure_native_depth_portal_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique pure output"): quit(1); return
	_inventory_sources()
	for path: String in fixture_sources(): _track(path)
	for path: String in EXTRA_PINS: _check(FileAccess.get_sha256(path)==EXTRA_PINS[path],"fixed independent source exact "+path)
	var depth: Script=load(DEPTH_PATH) as Script
	var c: Script=load(CONTRACT_PATH) as Script
	_check(depth!=null and depth.can_instantiate() and c!=null and c.can_instantiate(),"NEW actual consumer compile/load")
	first=_snapshot()
	_check(_write("source_before.json",first),"all unique fresh consumed input first before await")
	var navigation_before: Dictionary=(root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	if failed==0: _pure_depth(depth); _pure_portals(c,pair)
	_check(root.get_node("SceneRouter").call("get_navigation_state")==navigation_before,"pure consumer does not change actual router navigation")
	for frame: int in 4: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame: int in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last and players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"all source SHAbytesmtime/player15/slot exact end")
	_check(AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA and bridge.call("is_checkpoint_saves_suspended")==true,"actual end audio/engine/public suspension throughquit")
	var result: Dictionary={"scope":"ENCLOSURE_NATIVE_DEPTH_AND_LIVE_AUTHORED_PORTAL_PURE_NOT_FIELD_APPROVAL","complete":failed==0,"checks":checks+1,"failures":failed,"rows":pure_rows,"candidate_flag_pair":pair,"actual_args":args,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"navigation_before":navigation_before,"navigation_after":root.get_node("SceneRouter").call("get_navigation_state"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"Field_tested":false,"formal_approved":false,"typed_version_negatives_use_strict_Dictionary_API_not_coercing_int_API":true,"future_formal_enclosure_context_not_tested":true,"original_failure_changed":false,"outer_prelaunch_complete_source_and_exact_player_ticks_required":true}
	_check(_write("result.json",result),"unique pure checked result readback")
	print("NATIVE_DEPTH_PORTAL_UNITS_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)

