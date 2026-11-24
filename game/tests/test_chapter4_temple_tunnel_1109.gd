extends "res://tests/test_chapter3_modular_maps_1109.gd"

const TEMPLE := &"ch4_s4_ancient_temple"
const TUNNEL := &"ch4_s5_temple_tunnel"
const REGION_FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"

func _done() -> void:
	print("CH4_TEMPLE_TUNNEL_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _run() -> void:
	if not _expect(_paused_checkpoints, "private profile; checkpoint saves suspended"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var flags: Dictionary = root.get_node("GameState").get("flags")
	flags["chapter3_complete"] = true
	flags["defeated_temple_ambusher"] = true
	var full_route := OS.get_cmdline_user_args().has("--full-temple-route")
	var approach := Vector2.ZERO
	if full_route:
		if not _expect(bool(_router.call("go_field_smart",TEMPLE,null,"",-1,3)), "official ancient temple route"):
			_done()
			return
		var temple: Node = await _ready_field(TEMPLE)
		if temple == null: _done(); return
		_expect(temple.get_script().resource_path == REGION_FIELD, "current native temple host")
		var intro := _area_for_action(temple,"dialog:ch4_tunnel_intro")
		if not _expect(is_instance_valid(intro), "old tunnel investigation remains available"):
			_done()
			return
		var world := temple.get("world_container") as Node2D
		approach = world.to_local(intro.global_position)
		print("CH4_TUNNEL_SOURCE_FOOT ", approach)
		if not await _talk(temple,&"ch4_tunnel_intro",approach/Vector2(temple.get("_world_size"))):
			_done()
			return
	else:
		print("CH4_TUNNEL_SCOPE local scene and interactions; no native temple travel")
		if not _expect(bool(_router.call("go_field_smart",TUNNEL)), "direct tunnel load by official ID"):
			_done()
			return
	var field: Node = await _ready_field(TUNNEL)
	if field == null: _done(); return
	_contract(field,TUNNEL)
	var scene := field.get("_current_scene") as SceneScript
	_expect(bool(field.call("_spawn_has_foot_clearance",scene,_feet(field)/SIZE)), "arrival foot clearance")
	_expect(scene.encounter_groups.size()==2 and is_equal_approx(scene.encounter_chance,0.14) and is_equal_approx(scene.encounter_step_distance,650.0), "original encounter setup")
	_expect(_area_for_action(field,"dialog:ch4_tunnel_boss") != null and _area_for_action(field,"dialog:ch4_tunnel_result") == null, "old boss/evidence gates")
	_expect(_area_for_action(field,"dialog:ch4_hanjia_blade_recover") == null and _area_for_action(field,"dialog:ch4_canglong_assemble") == null,"both optional spots hidden before prerequisites")
	await _place(field,Vector2(.50,.65))
	await _capture(field,"ch4_temple_tunnel")
	flags["hanjia_blade_search_started"] = true
	root.get_node("GameState").call("set_flag",&"canglong_pages_complete",true)
	field = await _ready_field(TUNNEL)
	if field == null: _done(); return
	if not await _talk(field,&"ch4_hanjia_blade_recover",Vector2(.30,.56)): _done(); return
	_expect(bool(flags.get("hanjia_blade_recovered",false)),"original old blade action")
	field = await _ready_field(TUNNEL)
	if field == null: _done(); return
	if not await _talk(field,&"ch4_canglong_assemble",Vector2(.72,.54)): _done(); return
	_expect(bool(flags.get("canglong_manual_assembled",false)),"original scroll action")
	field = await _ready_field(TUNNEL)
	if field == null: _done(); return
	if full_route:
		field=await _door(field,TEMPLE,Vector2(.5,.86))
		if field == null: _done(); return
		_expect(field.get_script().resource_path==REGION_FIELD,"return to the native temple")
		print("CH4_TUNNEL_RETURN_FOOT ", _feet(field), " from ", approach)
	else:
		await _place(field,Vector2(.5,.86))
		var zone := _portal(field,TEMPLE)
		_expect(is_instance_valid(zone) and not zone.is_locked and bool(zone.get("_in_range")),"original return portal reachable locally")
	_done()
