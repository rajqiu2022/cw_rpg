extends "res://tests/helpers/luoyang_enclosure_v11_bounty_shop_equip_heal_phase_20261012.gd"
## Only the source-owned Market clone binding differs; original UI strategy,
## input, budgets, two bounty assertions and natural cleanup stay inherited.
const SHOP_BASE_PATH := "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const SHOP_BASE_SHA := "4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1"
const SHOP_SCENE_SCRIPT_PATH := "res://scripts/domain/scene_script.gd"
const SHOP_SCENE_SCRIPT_SHA := "e01a01ba69d13492441960972109d32ba0c62b1e0e881c5b805b11b73cb41bef"

func _normal_shop_supplies() -> bool:
	if not _check(FileAccess.get_sha256(SUPPLIED_BATTLE_PATH)==SUPPLIED_BATTLE_SHA and FileAccess.get_sha256(SUPPLIED_FIELD_PATH)==SUPPLIED_FIELD_SHA,"exact NEW UI strategy and current production Field source"): return false
	var market: String=IDS[3]
	if not await _open(market): return false
	var original: SceneScript=ENCLOSURE.legacy_scene(StringName(market))
	var fixed_scene: String="res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_scene.tres"
	var fixed_layout: String="res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_layout.tres"
	var old_present: bool=original!=null
	var old_path: String=original.resource_path if old_present else ""
	var old_path_equal: bool=old_present and old_path==fixed_scene
	var old_sha_equal: bool=old_path_equal and FileAccess.get_sha256(old_path)==MARKET_RETURN_SOURCE_PINS[old_path]
	var source_files_bound: bool=FileAccess.get_sha256(fixed_scene)==MARKET_RETURN_SOURCE_PINS[fixed_scene] and FileAccess.get_sha256(fixed_layout)==MARKET_RETURN_SOURCE_PINS[fixed_layout]
	var contract_bound: bool=FileAccess.get_sha256(SHOP_BASE_PATH)==SHOP_BASE_SHA and FileAccess.get_sha256(SHOP_SCENE_SCRIPT_PATH)==SHOP_SCENE_SCRIPT_SHA
	_diag_emit("normal_shop_original_source_gate",{"original_present":old_present,"actual_copy_resource_path":old_path,"original_path_equal":old_path_equal,"original_sha_equal":old_sha_equal,"original_L30_predicate":old_present and old_path_equal and old_sha_equal,"old_failed_gate_is_not_new_gate":true,"fixed_scene_path":fixed_scene,"fixed_scene_sha256":FileAccess.get_sha256(fixed_scene),"fixed_layout_path":fixed_layout,"fixed_layout_sha256":FileAccess.get_sha256(fixed_layout),"source_files_bound":source_files_bound,"BASE_pinned_contract":contract_bound})
	if not _check(source_files_bound and contract_bound,"exact frozen Market scene/layout and BASE/SceneScript contract bytes"): return false
	var loaded: SceneScript=ResourceLoader.load(fixed_scene,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var loaded_layout: WalkableMapLayout=ResourceLoader.load(fixed_layout,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var loaded_script: Script=loaded.get_script() as Script if loaded!=null else null
	var clone_script: Script=original.get_script() as Script if original!=null else null
	var script_bound: bool=loaded_script!=null and clone_script!=null and loaded_script.resource_path==SHOP_SCENE_SCRIPT_PATH and clone_script.resource_path==SHOP_SCENE_SCRIPT_PATH and loaded_script.get_source_code()==FileAccess.get_file_as_string(SHOP_SCENE_SCRIPT_PATH) and clone_script.get_source_code()==loaded_script.get_source_code()
	var scene_bound: bool=loaded!=null and loaded.scene_id==StringName(market) and original!=null and original.scene_id==loaded.scene_id and script_bound
	var npcs_bound: bool=scene_bound and var_to_bytes(original.npcs)==var_to_bytes(loaded.npcs)
	var layout_bound: bool=loaded_layout!=null and original!=null and original.map_layout!=null and original.map_layout.get_script()==loaded_layout.get_script()
	if layout_bound:
		for property: Dictionary in loaded_layout.get_property_list():
			var property_name: String=String(property.name)
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or property_name in ["script","resource_path","resource_name","resource_local_to_scene"]: continue
			if var_to_bytes(original.map_layout.get(property_name))!=var_to_bytes(loaded_layout.get(property_name)): layout_bound=false
	var loaded_authors: Array[Dictionary]=[]
	if loaded!=null:
		for entry: Dictionary in loaded.npcs:
			if entry.get("npc_id")=="luoyang_armorer": loaded_authors.append(entry.duplicate(true))
	var action_bound: bool=loaded_authors.size()==1 and typeof(loaded_authors[0].get("interaction_action"))==TYPE_STRING and loaded_authors[0].interaction_action=="shop:luoyang_armory"
	_diag_emit("normal_shop_source_bound_clone",{"source_scene_id":String(loaded.scene_id) if loaded!=null else "","loaded_scene_resource_path":loaded.resource_path if loaded!=null else "","loaded_layout_resource_path":loaded_layout.resource_path if loaded_layout!=null else "","clone_scene_id":String(original.scene_id) if original!=null else "","source_script_path":loaded_script.resource_path if loaded_script!=null else "","clone_script_path":clone_script.resource_path if clone_script!=null else "","script_bound":script_bound,"scene_bound":scene_bound,"entire_npcs_native_equal":npcs_bound,"source_npcs_native_hex":var_to_bytes(loaded.npcs).hex_encode() if loaded!=null else "","clone_npcs_native_hex":var_to_bytes(original.npcs).hex_encode() if original!=null else "","frozen_layout_path":fixed_layout,"clone_layout_resource_path":original.map_layout.resource_path if original!=null and original.map_layout!=null else "","clone_layout_storage_bound":layout_bound,"one_source_author_action":action_bound})
	if not _check(scene_bound and npcs_bound and layout_bound and action_bound,"exact source-loaded Market identity, whole clone NPC bytes and frozen backup layout storage"): return false
	var authors: Array[Dictionary]=[]
	for entry: Dictionary in original.npcs:
		if entry.get("npc_id")=="luoyang_armorer": authors.append(entry.duplicate(true))
	if not _check(authors.size()==1 and authors[0].get("interaction_action")=="shop:luoyang_armory","one exact original armory NPC/action, no hidden shop open"): return false
	var npc: Node=_npc("luoyang_armorer")
	if not _check(is_instance_valid(npc),"original live armorer exists"): return false
	var station: Vector2=_npc_stand(npc)
	var approach: Dictionary=await probe.call("move_to",station)
	if not _check(approach.get("ok")==true,"normal full875+17/Physics input reaches real armorer"): return false
	var source_foot: Vector2=(field.get("_player") as Node2D).position
	supply_record={"scope":SUPPLIED_SCOPE,"original_author":authors[0],"legacy_scene_path":fixed_scene,"legacy_scene_sha256":FileAccess.get_sha256(fixed_scene),"legacy_layout_path":fixed_layout,"legacy_layout_sha256":FileAccess.get_sha256(fixed_layout),"clone_resource_path":original.resource_path,"source_foot":source_foot,"normal_approach":approach,"actual_NPC":_diag_node(npc),"shop":{}}
	_diag_emit("normal_shop_before_input",supply_record)
	await driver.call("key",KEY_SPACE)
	var deadline: int=Time.get_ticks_msec()+30000
	var shop: Node
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		var current: Node=tree.current_scene
		if is_instance_valid(current) and current.scene_file_path=="res://scenes/shop.tscn" and current.get_script()!=null and current.get_script().resource_path=="res://scripts/ui/shop_ui.gd":
			shop=current; break
	if not _check(is_instance_valid(shop),"original NPC Space opens actual Shop, not public API credit"): return false
	var shopper: RefCounted=SUPPLIED_BATTLE.new()
	shopper.call("configure",tree,driver,_check)
	supply_record.shop=await shopper.call("shop_supplies",shop)
	shopper.call("release"); shopper=null; shop=null
	_diag_emit("normal_shop_trade_immediate_return",supply_record)
	if not _check(supply_record.shop.get("ok")==true,"real shop exact one sword/one armor/ten pills, cost872"): return false
	if not _check(await _wait_field(market),"normal Accept returns actual Market through production loading"): return false
	await _finish_dialogs()
	if not _check(not bool(tree.root.get_node("DialogPlayer").call("is_playing")) and (field.get("_player") as Node2D).position.distance_to(source_foot)<.03,"normal shop_thanks drains and exact pre-shop source feet retained"): return false
	if not _check(_bind_field(market) and probe.call("clear",(field.get("_player") as Node2D).position),"returned Market independent fullbody/17/source/Physics rebinding"): return false
	supply_record["normal_return_foot"]=(field.get("_player") as Node2D).position
	supply_record["after"]=_state()
	records["normal_shop_supplies"]=supply_record.duplicate(true)
	_diag_emit("normal_shop_return",supply_record)
	return true
