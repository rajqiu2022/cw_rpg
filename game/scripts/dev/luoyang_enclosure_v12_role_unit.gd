extends SceneTree
## Narrow role-schema positive/negative test only; not Field/visual/Physics.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("_run_unit")
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)
func _run_unit() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended", true)
	var wall := {"id":"court_wall_960_1680","world_foot_px":[960,1680],"physical_center_px":[960,1671],"collision_size_px":[0,0],"solid_polygons_px":[[[942,1520],[978,1520],[978,1680],[942,1680]]],"blocking":true,"ghost_occlusion":true,"depth_foot_y":1680}
	var deck := {"id":"dry_loading_wharf","world_foot_px":[2150,1640],"physical_center_px":[2150,1640],"collision_size_px":[0,0],"solid_polygons_px":[],"blocking":false,"ghost_occlusion":false,"role":"ground_overlay","walk_support":false,"z_index":-2,"sort_by_feet":false,"depth_foot_y":1640}
	var boat := {"id":"moored_canal_boat","world_foot_px":[2570,1430],"physical_center_px":[2570,1430],"collision_size_px":[0,0],"solid_polygons_px":[],"blocking":false,"ghost_occlusion":false,"role":"water_decoration","walk_support":false,"interaction_required":false,"sort_by_feet":true,"depth_foot_y":1430}
	for pair: Array in [[&"ch4_s1_luoyang_yamen",wall],[&"ch4_s2_canal_docks",deck],[&"ch4_s2_canal_docks",boat]]:
		_check(C._object_render_role_valid(pair[0],pair[1]),"Valid explicit role rejected")
		_check(C._render_role_matches_author(pair[1],pair[1]),"Exact role/author rejected")
	_check(C.object_solids([deck,boat]).is_empty(),"Nonblocking art created added navigation solids")
	for seed: Dictionary in [wall,deck,boat]:
		for mutation: Dictionary in [{"walk_support":true},{"walk_support":null},{"role":"unknown"}]:
			var record: Dictionary = seed.duplicate(true); record.merge(mutation,true)
			_check(not C._object_render_role_valid(&"ch4_s2_canal_docks",record),"Invalid support/type/role accepted")
	for mutation: Dictionary in [{"ghost_occlusion":false},{"sort_by_feet":false}]:
		var record: Dictionary = wall.duplicate(true); record.merge(mutation,true)
		_check(not C._object_render_role_valid(&"ch4_s1_luoyang_yamen",record),"Ordinary wall lost precise ghost/Y")
	for seed: Dictionary in [deck,boat]:
		for mutation: Dictionary in [{"blocking":true},{"ghost_occlusion":true},{"solid_polygons_px":wall.solid_polygons_px},{"collision_size_px":[2,2]}]:
			var record: Dictionary = seed.duplicate(true); record.merge(mutation,true)
			_check(not C._object_render_role_valid(&"ch4_s2_canal_docks",record),"Nonblocking role gained collision/ghost")
	for mutation: Dictionary in [{"id":"other_boat"},{"interaction_required":true},{"sort_by_feet":false},{"z_index":-2},{"depth_foot_y":1431}]:
		var record: Dictionary = boat.duplicate(true); record.merge(mutation,true)
		_check(not C._object_render_role_valid(&"ch4_s2_canal_docks",record),"Water identity/interactivity/depth bypass")
	_check(not C._object_render_role_valid(&"ch4_s1_luoyang_yamen",boat),"Water role moved to dry city")
	for mutation: Dictionary in [{"sort_by_feet":true},{"z_index":0}]:
		var record: Dictionary = deck.duplicate(true); record.merge(mutation,true)
		_check(not C._object_render_role_valid(&"ch4_s2_canal_docks",record),"Deck moved above actor")
	var changed: Dictionary = boat.duplicate(true); changed.erase("interaction_required")
	_check(not C._render_role_matches_author(changed,boat),"Removed explicit authored role key accepted")
	changed = boat.duplicate(true); changed.sort_by_feet = false
	_check(not C._render_role_matches_author(changed,boat),"Altered explicit author sort accepted")
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"Checkpoint guard lost")
	print("LUOYANG_V12_ROLE_SCHEMA_ONLY checks=" + str(checks) + " failures=" + str(failures))
	quit(0 if failures == 0 else 1)
