extends "res://tests/helpers/luoyang_enclosure_v11_bounty_shop_equip_heal_stock20_phase_20261012.gd"
## Only the source-owned Market clone binding differs; original UI strategy,
## input, budgets, two bounty assertions and natural cleanup stay inherited.
const SHOP_BASE_PATH := "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const SHOP_BASE_SHA := "4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1"
const SHOP_SCENE_SCRIPT_PATH := "res://scripts/domain/scene_script.gd"
const SHOP_SCENE_SCRIPT_SHA := "e01a01ba69d13492441960972109d32ba0c62b1e0e881c5b805b11b73cb41bef"
const STOCK_DIALOG_ORIGIN_PATH := "res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd"
const STOCK_DIALOG_ORIGIN_SHA := "97a8d255a7148074ff5a2fbb334a675c92697b992b12565b0d14fb52d859b126"

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
	var commands: Array[Dictionary]=[]
	var shared_start: int=Time.get_ticks_msec()
	var shared_deadline: int=shared_start+180000
	supply_record["batches"]=[]
	supply_record["required_cost"]=1172
	supply_record["expected_final_healing"]=22
	supply_record["expected_final_gold"]=18828
	supply_record["shared_start_ticks_msec"]=shared_start
	supply_record["shared_deadline_ticks_msec"]=shared_deadline
	supply_record["command_limit"]=96
	for batch in 2:
		var live_npc: Node=_npc("luoyang_armorer")
		var batch_record: Dictionary={"batch":batch,"actual_NPC":_diag_node(live_npc),"command_begin":commands.size(),"shop":{}}
		if not _check(is_instance_valid(live_npc) and is_instance_valid(field) and tree.current_scene==field and not field.is_queued_for_deletion() and (field.get("_player") as Node2D).position.distance_to(source_foot)<.03 and probe.call("clear",(field.get("_player") as Node2D).position),"each stock20 entry has current live armorer, exact feet and full875+17/Physics"): return false
		_diag_emit("normal_shop_before_input",{"batch":batch,"supply":supply_record.duplicate(true),"batch_record":batch_record,"commands":commands.duplicate(true)})
		if not _check(commands.size()<96 and Time.get_ticks_msec()<shared_deadline,"shared96/180 budget before each original NPC Space"): return false
		var command_index: int=commands.size()
		commands.append({"kind":"normal_shop_NPC_space","batch":batch,"keycode":KEY_SPACE,"before_ticks_msec":Time.get_ticks_msec(),"actual_NPC":_diag_node(live_npc)})
		await driver.call("key",KEY_SPACE)
		commands[command_index]["after_ticks_msec"]=Time.get_ticks_msec()
		var entry_deadline: int=mini(shared_deadline,Time.get_ticks_msec()+30000)
		var shop: Node
		while Time.get_ticks_msec()<entry_deadline:
			await tree.process_frame
			var current: Node=tree.current_scene
			if is_instance_valid(current) and current.scene_file_path=="res://scenes/shop.tscn" and current.get_script()!=null and current.get_script().resource_path=="res://scripts/ui/shop_ui.gd":
				shop=current; break
		if not _check(is_instance_valid(shop) and Time.get_ticks_msec()<shared_deadline,"original NPC Space opens actual Shop within shared budget, not API credit"): return false
		var shopper: RefCounted=SUPPLIED_BATTLE.new()
		shopper.call("configure",tree,driver,_check)
		batch_record.shop=await shopper.call("shop_supplies",shop,batch,commands,shared_deadline)
		shopper.call("release"); shopper=null; shop=null
		batch_record.shop=(batch_record.shop as Dictionary).duplicate(true)
		_diag_emit("normal_shop_trade_immediate_return",batch_record)
		if not _check(batch_record.shop.get("ok")==true,"real shop stock20 fixed batch and cumulative96/180 input budget"): return false
		if not _check(await _wait_field_until(market,mini(shared_deadline,Time.get_ticks_msec()+30000)),"normal Accept returns actual ready Market through production loading and shared budget"): return false
		batch_record["normal_thanks_nodes"]=await _finish_shop_dialogs(commands,shared_deadline)
		if not _check(Time.get_ticks_msec()<shared_deadline and commands.size()<=96 and not bool(tree.root.get_node("DialogPlayer").call("is_playing")) and (field.get("_player") as Node2D).position.distance_to(source_foot)<.03,"normal shop_thanks drains in cumulative budget and exact pre-shop feet retained"): return false
		if not _check(_bind_field(market) and probe.call("clear",(field.get("_player") as Node2D).position),"returned Market independent fullbody/17/source/Physics rebinding"): return false
		batch_record["normal_return_foot"]=(field.get("_player") as Node2D).position
		batch_record["command_end"]=commands.size()
		batch_record["commands"]=commands.duplicate(true)
		batch_record["after"]=_state()
		(supply_record.batches as Array).append(batch_record.duplicate(true))
		_diag_emit("normal_shop_batch_return",batch_record)
	var final_shop: Dictionary=(supply_record.batches[1] as Dictionary).shop
	var final_inventory: Dictionary=final_shop.after
	if not _check((supply_record.batches as Array).size()==2 and final_inventory.healing==22 and final_inventory.gold==18828 and Time.get_ticks_msec()<shared_deadline and commands.size()<=96,"two real trades stock22/cost1172/gold18828 with one96/180 budget"): return false
	supply_record["normal_return_foot"]=(field.get("_player") as Node2D).position
	supply_record["commands"]=commands.duplicate(true)
	supply_record["shared_end_ticks_msec"]=Time.get_ticks_msec()
	supply_record["after"]=_state()
	records["normal_shop_supplies"]=supply_record.duplicate(true)
	_diag_emit("normal_shop_return",supply_record)
	return true

func _finish_shop_dialogs(commands: Array[Dictionary],shared_deadline: int) -> Array[Dictionary]:
	var visited: Array[Dictionary]=[]
	if not _check(FileAccess.get_sha256(STOCK_DIALOG_ORIGIN_PATH)==STOCK_DIALOG_ORIGIN_SHA,"mechanical original normal-dialog source for SHOP-only shared budget"): return visited
	if not _check(FileAccess.get_sha256(TWO_CHOICE_ORIGIN_PATH).to_lower()==TWO_CHOICE_ORIGIN_SHA,"two authored choices preserve exact water-only parent"): return visited
	if not _check(FileAccess.get_sha256(CHOICE_ORIGIN_PATH).to_lower()==CHOICE_ORIGIN_SHA,"authored choice sibling keeps exact unchanged lifecycle/dialog parent"): return visited
	var dialog: Node=tree.root.get_node("DialogPlayer")
	var start_ticks: int=Time.get_ticks_msec()
	var deadline: int=mini(start_ticks+45000,shared_deadline)
	var last: String=""
	var ui_seen: Dictionary={}
	var ui_records: Array[Dictionary]=[]
	var choice_records: Array[Dictionary]=[]
	while bool(dialog.call("is_playing")) and Time.get_ticks_msec()<deadline and commands.size()<96:
		await driver.call("completed_actor_stage")
		var node: DialogNode=dialog.get("_current_node") as DialogNode
		var script: DialogScript=dialog.get("_current_script") as DialogScript
		# DialogPlayer owns the actual tscn CanvasLayer root, not its Control child.
		# Resolve exactly that live child's normal UI; never call advance/choose.
		var layer: Node=dialog.get("_box") as Node
		var box: Control=null
		if is_instance_valid(layer) and layer is CanvasLayer:
			box=layer.get_node_or_null("DialogBox") as Control
		var ui_valid: bool=is_instance_valid(layer) and layer is CanvasLayer and layer.is_inside_tree() and not layer.is_queued_for_deletion() and layer.get_parent()==dialog and layer.scene_file_path=="res://scenes/ui/dialog_box.tscn" and is_instance_valid(box) and box.is_inside_tree() and not box.is_queued_for_deletion() and box.get_parent()==layer and String(box.name)=="DialogBox" and box.get_script()!=null and box.get_script().resource_path=="res://scripts/ui/dialog_box.gd"
		var ui_identity: Dictionary={"observed_ticks_msec":Time.get_ticks_msec(),"dialog_player_id":dialog.get_instance_id(),"dialog_player_path":String(dialog.get_path()),"dialog_player_script":dialog.get_script().resource_path,"root_instance_id":layer.get_instance_id() if is_instance_valid(layer) else 0,"root_class":layer.get_class() if is_instance_valid(layer) else "MISSING","root_path":String(layer.get_path()) if is_instance_valid(layer) and layer.is_inside_tree() else "","root_scene_path":layer.scene_file_path if is_instance_valid(layer) else "","root_parent_is_actual_dialog_player":is_instance_valid(layer) and layer.get_parent()==dialog,"control_instance_id":box.get_instance_id() if is_instance_valid(box) else 0,"control_class":box.get_class() if is_instance_valid(box) else "MISSING","control_path":String(box.get_path()) if is_instance_valid(box) and box.is_inside_tree() else "","control_script":box.get_script().resource_path if is_instance_valid(box) and box.get_script()!=null else "","control_parent_is_actual_root":is_instance_valid(box) and box.get_parent()==layer,"control_visible_in_tree":box.is_visible_in_tree() if is_instance_valid(box) else false,"node_present":node!=null,"script_present":script!=null,"exact_root_and_control_identity":ui_valid}
		var ui_key: String=str(ui_identity.root_instance_id)+"/"+str(ui_identity.control_instance_id)+"/"+(String(script.dialog_id)+"/"+String(node.node_id) if script!=null and node!=null else "MISSING_NODE_OR_SCRIPT")
		if not ui_seen.has(ui_key):
			ui_seen[ui_key]=true
			ui_records.append(ui_identity)
			_check(ui_valid,"ordinary dialog uses live actual CanvasLayer root and its exact normal DialogBox Control child")
		if node==null or script==null or box==null or not ui_valid: continue
		var identity: String=String(script.dialog_id)+"/"+String(node.node_id)
		if identity!=last:
			var flag_checks: Dictionary={}
			for flag: Dictionary in node.set_flags:
				var key: String=String(flag.get("key",""))
				var actual: Variant=(tree.root.get_node("GameState").get("flags") as Dictionary).get(key)
				flag_checks[key]=actual
				_check(not key.is_empty() and actual==flag.get("value",true),"authored node flag effect really executes: "+identity+" "+key)
			visited.append({"id":identity,"source_path":script.resource_path,"source_sha256":FileAccess.get_sha256(script.resource_path),"node_flags":flag_checks,"before_next_input":_state(),"actual_dialog_ui_identity":ui_identity})
			last=identity
		var choices: Array=box.get("_choice_rects") if box.get("_choice_rects") is Array else []
		if box.get("choices_container")!=null and box.get("choices_container").is_visible_in_tree() and not choices.is_empty():
			var source_sha: String=FileAccess.get_sha256(script.resource_path)
			var policy: Dictionary=two_authored_choice_policy(script.resource_path,source_sha,String(script.dialog_id),String(node.node_id),node.choices)
			var selected: int=int(policy.selected_index)
			var labels: Array=box.get("_choice_labels") if box.get("_choice_labels") is Array else []
			var label_texts: Array[String]=[]
			var displayed_exact: bool=true
			if bool(policy.exact_authored_policy):
				var expected_options: Array=NOTCH_OPTIONS if String(script.dialog_id)==NOTCH_DIALOG and String(node.node_id)==NOTCH_NODE else WATER_OPTIONS
				displayed_exact=choices.size()==3 and labels.size()==3
				for index in labels.size():
					var label: Label=labels[index] as Label
					var text: String=label.text if is_instance_valid(label) else ""
					label_texts.append(text)
					displayed_exact=displayed_exact and index<3 and is_instance_valid(label) and label.is_visible_in_tree() and text=="  %d. %s" % [index+1,expected_options[index].text]
			var selection_valid: bool=bool(policy.valid) and displayed_exact and selected>=0 and selected<choices.size() and choices[selected] is Rect2 and (choices[selected] as Rect2).has_area()
			var choice_record: Dictionary={"observed_ticks_msec":Time.get_ticks_msec(),"identity":identity,"source_path":script.resource_path,"source_sha256":source_sha,"policy":policy.duplicate(true),"authored_options":node.choices.duplicate(true),"actual_ui_label_texts":label_texts,"displayed_authored_options_exact":displayed_exact,"selection_valid":selection_valid,"selected_index":selected,"input_kind":"NORMAL_POINTER_AT_ACTUAL_VISIBLE_CHOICE_RECT_CENTER","actual_dialog_ui_identity":ui_identity}
			if selection_valid:
				var rectangle: Rect2=choices[selected]
				choice_record["pointer_px"]=[rectangle.get_center().x,rectangle.get_center().y]
			choice_records.append(choice_record)
			if not _check(selection_valid,"choice selection is original default or exact SHA-bound authored UI answer: "+identity): continue
			if not _check(commands.size()<96 and Time.get_ticks_msec()<deadline,"shared96/180 budget before original thanks choice pointer"): break
			var command_index: int=commands.size()
			commands.append({"kind":"normal_shop_thanks_choice","before_ticks_msec":Time.get_ticks_msec(),"identity":identity,"pointer":{}})
			commands[command_index]["pointer"]=await driver.call("pointer",(choices[selected] as Rect2).get_center())
			commands[command_index]["after_ticks_msec"]=Time.get_ticks_msec()
		else:
			if not _check(commands.size()<96 and Time.get_ticks_msec()<deadline,"shared96/180 budget before original thanks Space"): break
			var command_index: int=commands.size()
			commands.append({"kind":"normal_shop_thanks_space","before_ticks_msec":Time.get_ticks_msec(),"identity":identity,"keycode":KEY_SPACE})
			await driver.call("key",KEY_SPACE)
			commands[command_index]["after_ticks_msec"]=Time.get_ticks_msec()
	_check(not bool(dialog.call("is_playing")),"ordinary dialogue completes through normal Space/choice UI within finite budget")
	records.dialog_nodes.append_array(visited)
	if not records.has("dialog_ui_identity"): records["dialog_ui_identity"]=[]
	(records.dialog_ui_identity as Array).append({"scope":"ACTUAL_NORMAL_DIALOG_LAYER_AND_CONTROL_NOT_DIRECT_API","start_ticks_msec":start_ticks,"deadline_ticks_msec":deadline,"end_ticks_msec":Time.get_ticks_msec(),"wall_budget_msec":45000,"is_playing_after":bool(dialog.call("is_playing")),"ui_observations":ui_records,"visited_count":visited.size(),"input_semantics":"NORMAL_SPACE_OR_ORIGINAL_FIRST_CHOICE_EXCEPT_EXACT_SHA_WATER_OPTION_1_OR_NOTCH_OPTION_2","authored_choice_inputs":choice_records})
	return visited
