extends RefCounted
## Finite NORMAL_SHOP_EQUIP_HEAL strategy; every operation is ordinary visible UI input.
## Handles ONLY a battle already entered by ordinary entity/dialog input.
## Never starts an encounter, emits an outcome, edits an enemy or jumps to results.
var tree: SceneTree
var driver: RefCounted
var check: Callable
const STRATEGY := "NORMAL_SHOP_EQUIP_HEAL"
var ui_receipts: Array[Dictionary]=[]

func configure(owner: SceneTree, actual_driver: RefCounted, checker: Callable) -> void:
	tree=owner
	driver=actual_driver
	check=checker

func victory(expected_source: String, expected_foot: Vector2, expected_local_version: int, expected_size: Vector2=Vector2(3072,2048)) -> Dictionary:
	ui_receipts.clear()
	var result: Dictionary={"battle_strategy_modified":true,"Attack_only":false,"strategy_scope":STRATEGY,"scope":"EXISTING_NORMAL_ACTION_BATTLE_UI","entered":false,"won":false,"returned":false,"commands":[]}
	var router: Node=tree.root.get_node("SceneRouter")
	var bus: Node=tree.root.get_node("EventBus")
	var outcomes: Array[Dictionary]=[]
	var outcome_observer: Callable=func(won: bool,fled: bool): outcomes.append({"won":won,"fled":fled})
	bus.connect("battle_ended",outcome_observer)
	var battle: Node
	var deadline: int=Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		if is_instance_valid(tree.current_scene) and tree.current_scene.get_node_or_null("%BtnAttack")!=null:
			battle=tree.current_scene
			break
	check.call(is_instance_valid(battle),"normal entity/dialog action really enters production Battle")
	if not is_instance_valid(battle):
		bus.disconnect("battle_ended",outcome_observer)
		return result
	result.entered=true
	var payload: Dictionary=router.call("get_battle_payload")
	check.call(String(payload.get("return_scene",""))==expected_source,"real action battle carries exact source scene")
	check.call(payload.get("return_spawn") is Vector2 and (payload.return_spawn as Vector2).distance_to(expected_foot/expected_size)<.00001,"real action battle preserves pre-action ordinary feet in its actual source domain")
	check.call(int(payload.get("return_local_layout_version",-1))==expected_local_version,"real city action battle carries local layout version")
	result["original_payload"]=payload.duplicate(true)
	var commands: Array[Dictionary]=[]
	deadline=Time.get_ticks_msec()+180000
	var result_scene: Node
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		if not is_instance_valid(tree.current_scene): continue
		if tree.current_scene!=battle:
			if tree.current_scene.scene_file_path.contains("victory"): result_scene=tree.current_scene
			break
		if not is_instance_valid(battle) or int(battle.get("_state"))!=1: continue
		var modal: Control=battle.get("_flee_confirm_dialog") as Control
		if modal!=null and modal.is_visible_in_tree():
			check.call(false,"unexpected Flee modal; no UI bypass")
			break
		var panel: Control=battle.get("action_panel") as Control
		var formation: Node=battle.get("formation_view") as Node
		var targets: Array=formation.get("target_buttons") if formation!=null and formation.get("target_buttons") is Array else []
		if commands.size()>=96:
			check.call(false,"96 real UI command budget exhausted, no completion credit")
			break
		if int(battle.get("_team_pending_skill_index"))>=0:
			var selected: bool=false
			for target: Variant in targets:
				if target is Button and target.is_visible_in_tree() and not target.disabled:
					var presses: Array[bool]=[]
					target.pressed.connect(func(): presses.append(true),CONNECT_ONE_SHOT)
					var pointer: Dictionary=await driver.call("pointer",target.get_global_rect().get_center())
					selected=presses.size()==1
					commands.append({"kind":"normal_target","pressed":selected,"pointer":pointer})
					break
			check.call(selected,"ordinary multi-enemy target selection receives genuine input")
			if not selected: break
			continue
		if panel==null or not panel.is_visible_in_tree() or commands.size()>=96: continue
		var decision: Dictionary=_decision()
		if decision.get("failure",false):
			check.call(false,"required medicine exhausted or actual player unavailable")
			break
		if not decision.is_empty():
			if not await _inventory_action(battle,decision,commands,deadline): break
			continue
		var button: Button=battle.get_node_or_null("%BtnAttack") as Button
		if button==null or not button.is_visible_in_tree() or button.disabled: continue
		var presses: Array[bool]=[]
		button.pressed.connect(func(): presses.append(true),CONNECT_ONE_SHOT)
		var pointer: Dictionary=await driver.call("pointer",button.get_global_rect().get_center())
		var accepted: bool=presses.size()==1 and (not is_instance_valid(battle) or int(battle.get("_state"))!=1 or int(battle.get("_team_pending_skill_index"))>=0 or not outcomes.is_empty())
		check.call(accepted,"PLAYER_TURN normal attack accepted; INTRO clicks never count")
		commands.append({"kind":"normal_attack","pressed":presses.size()==1,"accepted":accepted,"pointer":pointer})
		for tick in 6: await tree.process_frame
	var won: bool=false
	for outcome: Dictionary in outcomes:
		if bool(outcome.won) and not bool(outcome.fled): won=true
	check.call(won and is_instance_valid(result_scene),"actual gameplay reaches Victory, not fabricated payload")
	result.won=won
	result.commands=commands
	result["outcomes"]=outcomes.duplicate(true)
	result["normal_inventory_actions"]=ui_receipts.duplicate(true)
	result["real_UI_command_count"]=commands.size()
	result["command_budget"]=96
	if is_instance_valid(result_scene):
		var actual_result: Dictionary=router.call("get_result_payload")
		check.call(String(actual_result.get("return_scene",""))==expected_source and int(actual_result.get("return_local_layout_version",-1))==expected_local_version,"actual Victory preserves original city/local version")
		result["actual_result_payload"]=actual_result.duplicate(true)
		var button: Button=result_scene.get_node_or_null("%BtnContinue") as Button
		check.call(button!=null and button.is_visible_in_tree(),"normal Victory return button exists")
		if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
		deadline=Time.get_ticks_msec()+30000
		while Time.get_ticks_msec()<deadline:
			await tree.process_frame
			if not is_instance_valid(tree.current_scene) or not tree.current_scene.get("_current_scene") is SceneScript: continue
			var definition: SceneScript=tree.current_scene.get("_current_scene") as SceneScript
			if String(definition.scene_id)==expected_source:
				var player: Node2D=tree.current_scene.get("_player") as Node2D
				if player!=null:
					result.returned=player.position.distance_to(expected_foot)<.03
					result["actual_return_foot_px"]=[player.position.x,player.position.y]
				break
		check.call(bool(result.returned),"normal result button returns to exact pre-action feet")
	bus.disconnect("battle_ended",outcome_observer)
	return result

# Only primitive state is retained; event snapshots occur INSIDE the production
# item/equipment signal, before the pointer can resume after an enemy action.
func _inventory_state() -> Dictionary:
	var inventory: Node=tree.root.get_node("Inventory")
	var player: CharacterStats=tree.root.get_node("GameState").get("player") as CharacterStats
	return {"player_id":player.get_instance_id() if player!=null else 0,"character_id":player.character_id if player!=null else "","hp":player.hp if player!=null else -1,"max_hp":player.max_hp if player!=null else -1,"gold":tree.root.get_node("GameState").get("gold"),"healing":inventory.call("count_of",&"healing_pill_minor"),"sword_count":inventory.call("count_of",&"heavy_iron_sword"),"armor_count":inventory.call("count_of",&"dark_iron_armor"),"weapon_id":String(inventory.call("get_equipped_id",0)),"weapon_instance":inventory.call("get_equipped_instance_id",0),"armor_id":String(inventory.call("get_equipped_id",2)),"armor_instance":inventory.call("get_equipped_instance_id",2)}

func _control_value(control: Variant) -> Dictionary:
	var valid: bool=is_instance_valid(control)
	return {"exists":valid,"id":control.get_instance_id() if valid else 0,"path":String(control.get_path()) if valid and control.is_inside_tree() else "","class":control.get_class() if valid else "","visible":control.is_visible_in_tree() if valid else false,"queued":control.is_queued_for_deletion() if valid else false,"disabled":control.disabled if valid and control is BaseButton else false,"script":control.get_script().resource_path if valid and control.get_script()!=null else "","rect":control.get_global_rect() if valid else Rect2()}

func _clickable(control: Control) -> bool:
	if not is_instance_valid(control) or not control.is_inside_tree() or control.is_queued_for_deletion() or not control.is_visible_in_tree(): return false
	if control is BaseButton and control.disabled: return false
	var center: Vector2=control.get_global_rect().get_center()
	if not tree.root.get_visible_rect().has_point(center): return false
	var ancestor: Node=control.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer and not ancestor.get_global_rect().has_point(center): return false
		ancestor=ancestor.get_parent()
	return true

func _battle_clock() -> Dictionary:
	var current: Node=tree.current_scene
	var valid: bool=is_instance_valid(current) and current.is_inside_tree() and not current.is_queued_for_deletion() and current.scene_file_path=="res://scenes/battle.tscn" and current.get_script()!=null and current.get_script().resource_path=="res://scripts/battle/battle_controller.gd"
	var active: BattleCombatant=current.get("_team_active_unit") as BattleCombatant if valid else null
	var player: CharacterStats=current.get("_player") as CharacterStats if valid else null
	return {"valid":valid,"battle_id":current.get_instance_id() if valid else 0,"battle_path":String(current.get_path()) if valid else "","script_path":current.get_script().resource_path if valid else "","state":current.get("_state") if valid else -1,"team_mode":current.get("_team_mode") if valid else false,"active_unit_id":String(active.unit_id) if active!=null else "","active_unit_instance":active.get_instance_id() if active!=null else 0,"active_team":active.team if active!=null else -1,"active_stats_id":active.stats.get_instance_id() if active!=null and active.stats!=null else 0,"legacy_player_id":player.get_instance_id() if player!=null else 0,"game_player_id":_inventory_state().player_id,"ticks_usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames()}

func _click(control: Control,kind: String,commands: Array[Dictionary],deadline: int) -> bool:
	var receipt: Dictionary={"kind":kind,"operator_before":_control_value(control),"before":_inventory_state(),"pointer":{},"pressed":false}
	if not _clickable(control) or commands.size()>=96 or Time.get_ticks_msec()>=deadline:
		receipt["rejected"]=true; commands.append(receipt)
		check.call(false,"visible enabled current operator and shared real UI budget: "+kind)
		return false
	var presses: Array[bool]=[]
	var observer: Callable=func(): presses.append(true)
	var is_button: bool=control is BaseButton
	if is_button: control.connect("pressed",observer)
	receipt.pointer=await driver.call("pointer",control.get_global_rect().get_center())
	if is_instance_valid(control) and is_button and control.is_connected("pressed",observer): control.disconnect("pressed",observer)
	receipt.pressed=presses.size()==1 if is_button else true
	receipt["operator_after"]=_control_value(control)
	receipt["after"]=_inventory_state()
	commands.append(receipt)
	return receipt.pressed and Time.get_ticks_msec()<deadline

func _decision() -> Dictionary:
	var state: Dictionary=_inventory_state()
	if state.player_id==0 or state.hp<=0: return {"failure":true}
	if state.hp*2<=state.max_hp:
		if state.healing<=0: return {"failure":true,"reason":"required_healing_stock_exhausted"}
		return {"item_id":"healing_pill_minor","kind":"use_item","slot":-1}
	if state.armor_id!="dark_iron_armor": return {"item_id":"dark_iron_armor","kind":"equip","slot":2}
	if state.weapon_id!="heavy_iron_sword": return {"item_id":"heavy_iron_sword","kind":"equip","slot":0}
	return {}

func _inventory_action(battle: Node,decision: Dictionary,commands: Array[Dictionary],deadline: int) -> bool:
	var row: Dictionary={"decision":decision.duplicate(true),"before":_inventory_state(),"events":[],"actions":[],"ok":false}
	if not await _click(battle.get_node_or_null("%BtnItem") as Control,"normal_open_battle_inventory",commands,deadline): return false
	var panel: Control=battle.get("_battle_inventory_panel") as Control
	for tick in 4:
		if Time.get_ticks_msec()>=deadline: break
		await tree.process_frame
	var exact: bool=is_instance_valid(panel) and panel.is_inside_tree() and panel.is_visible_in_tree() and not panel.is_queued_for_deletion() and panel.get_script()!=null and panel.get_script().resource_path=="res://scripts/ui/inventory_panel.gd" and panel.scene_file_path=="res://scenes/ui/inventory_panel.tscn" and panel.get("_battle_mode")==true and panel.get("_current_filter")=="all" and tree.current_scene==battle and int(battle.get("_state"))==1
	if not exact: check.call(false,"actual normal BattleInventoryPanel identity/filter/turn"); return false
	var slots: Array=tree.root.get_node("Inventory").get("slots")
	var selected_index: int=-1
	var instance: String=""
	var selected_item: Item
	for index in slots.size():
		var item: Item=slots[index].get("item") as Item
		if item!=null and String(item.item_id)==decision.item_id:
			if selected_index!=-1: check.call(false,"one exact supplied item inventory slot"); return false
			selected_index=index; instance=String(slots[index].get("instance_id","")); selected_item=item
	var cells: Array[Control]=[]
	var grid: Node=panel.get_node_or_null("%SlotGrid")
	if grid!=null:
		for child: Node in grid.get_children():
			if child is Control and not child.is_queued_for_deletion() and child.get_meta("slot_index",-1)==selected_index: cells.append(child)
	if selected_index<0 or cells.size()!=1 or not await _click(cells[0],"normal_select_inventory_"+decision.item_id,commands,deadline):
		check.call(false,"actual filtered inventory cell receives normal input"); return false
	var selected: Item=panel.get("_selected_item") as Item
	if selected!=selected_item or String(panel.get("_selected_instance_id"))!=instance:
		check.call(false,"selected current item and unique equipment instance"); return false
	var operator: Control=panel.get_node_or_null("%BtnEquip" if decision.kind=="equip" else "%BtnUse") as Control
	row["panel"]=_control_value(panel); row["operator"]=_control_value(operator)
	row["selected_item_path"]=selected.resource_path; row["selected_item_id"]=String(selected.item_id); row["selected_instance_id"]=instance
	var bus: Node=tree.root.get_node("EventBus")
	var events: Array[Dictionary]=[]
	var actions: Array[Dictionary]=[]
	var item_observer: Callable=func(item_id: StringName): events.append({"signal":"item_used","item_id":String(item_id),"state":_inventory_state(),"clock":_battle_clock()})
	var equip_observer: Callable=func(slot: int,item_id: StringName): events.append({"signal":"equipment_changed","slot":slot,"item_id":String(item_id),"state":_inventory_state(),"clock":_battle_clock(),"actual_instance_owner":String(tree.root.get_node("Inventory").call("get_instance_equipped_character_id",instance))})
	var action_observer: Callable=func(kind: StringName): actions.append({"kind":String(kind),"state":_inventory_state(),"clock":_battle_clock()})
	bus.connect("item_used",item_observer); bus.connect("equipment_changed",equip_observer); panel.connect("action_committed",action_observer)
	var immediate_before: Dictionary=_inventory_state()
	var clock_before: Dictionary=_battle_clock()
	var clicked: bool=await _click(operator,"normal_"+decision.kind+"_"+decision.item_id,commands,deadline)
	if bus.is_connected("item_used",item_observer): bus.disconnect("item_used",item_observer)
	if bus.is_connected("equipment_changed",equip_observer): bus.disconnect("equipment_changed",equip_observer)
	if is_instance_valid(panel) and panel.is_connected("action_committed",action_observer): panel.disconnect("action_committed",action_observer)
	var ok: bool=clicked and events.size()==1 and actions.size()==1 and actions[0].kind==decision.kind and events[0].item_id==decision.item_id
	if ok:
		var instant: Dictionary=events[0].state
		var clock: Dictionary=events[0].clock
		ok=instant.player_id==immediate_before.player_id and instant.character_id==immediate_before.character_id and clock_before.valid==true and clock.valid==true and clock.state==1 and clock.battle_id==clock_before.battle_id and clock.active_unit_instance==clock_before.active_unit_instance and clock.active_stats_id==clock_before.active_stats_id and clock.legacy_player_id==instant.player_id and clock.game_player_id==instant.player_id and clock.ticks_usec>=clock_before.ticks_usec and clock.ticks_usec<=actions[0].clock.ticks_usec
		if decision.kind=="use_item":
			ok=ok and events[0].signal=="item_used" and selected.heal_hp==80 and instant.hp==mini(immediate_before.max_hp,immediate_before.hp+80) and instant.max_hp==immediate_before.max_hp and instant.healing==immediate_before.healing-1 and instant.weapon_instance==immediate_before.weapon_instance and instant.armor_instance==immediate_before.armor_instance
		else:
			ok=ok and events[0].signal=="equipment_changed" and events[0].slot==decision.slot and events[0].actual_instance_owner=="protagonist" and instant.get("armor_instance" if decision.slot==2 else "weapon_instance")==instance and instant.get("armor_id" if decision.slot==2 else "weapon_id")==decision.item_id and instant.healing==immediate_before.healing
	row["clock_before_operator"]=clock_before; row["immediate_before"]=immediate_before; row.events=events; row.actions=actions; row["after_pointer_not_heal_oracle"]=_inventory_state(); row.ok=ok
	ui_receipts.append(row)
	check.call(ok,"normal visible inventory action with synchronous actual HP/stock/equipment binding")
	return ok

func _shop_plus(shop: Node,item: Item,index: int) -> Button:
	var list: Node=shop.get_node_or_null("%BuyList")
	var live: Array[Node]=[]
	if list==null: return null
	for child: Node in list.get_children():
		if not child.is_queued_for_deletion(): live.append(child)
	var definition: ShopDef=shop.get("_shop") as ShopDef
	if definition==null or live.size()!=definition.stock.size() or index<0 or index>=live.size() or definition.stock[index]!=item.item_id: return null
	var row: Node=live[index].get_child(0) if live[index].get_child_count()>0 else null
	if row==null or row.get_child_count()!=3: return null
	var names: Node=row.get_child(0).get_child(0)
	if names.get_child_count()!=2: return null
	var name_label: Label=names.get_child(0) as Label
	var price_label: Label=names.get_child(1) as Label
	if name_label==null or price_label==null or name_label.text!=item.display_name or price_label.text!="单价 %d 金"%item.buy_price: return null
	var quantities: Node=row.get_child(2)
	if quantities.get_child_count()!=3: return null
	var plus: Button=quantities.get_child(2) as Button
	return plus if plus!=null and plus.text=="+" else null

func _wheel(scroll: ScrollContainer,down: bool,commands: Array[Dictionary],deadline: int) -> bool:
	if not _clickable(scroll) or commands.size()>=96 or Time.get_ticks_msec()>=deadline: return false
	var logical: Vector2=scroll.get_global_rect().get_center()
	var transform: Transform2D=tree.root.get_final_transform()
	var physical: Vector2=transform*logical
	var before: int=scroll.scroll_vertical
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
		event.position=physical; event.global_position=physical; event.pressed=pressed
		Input.parse_input_event(event); Input.flush_buffered_events()
		await tree.process_frame
	commands.append({"kind":"normal_shop_scroll","down":down,"logical":logical,"physical":physical,"final_transform":transform,"before":before,"after":scroll.scroll_vertical})
	return Time.get_ticks_msec()<deadline

func shop_supplies(shop: Node) -> Dictionary:
	var result: Dictionary={"scope":STRATEGY,"ok":false,"commands":[],"before":_inventory_state(),"required_cost":872}
	var commands: Array[Dictionary]=[]
	result.commands=commands
	var deadline: int=Time.get_ticks_msec()+180000
	var definition: ShopDef=shop.get("_shop") as ShopDef if is_instance_valid(shop) else null
	if definition==null or definition.shop_id!=&"luoyang_armory" or shop.get_script().resource_path!="res://scripts/ui/shop_ui.gd" or shop.scene_file_path!="res://scenes/shop.tscn": return result
	var inventory: Node=tree.root.get_node("Inventory")
	for request: Dictionary in [{"id":"healing_pill_minor","quantity":10},{"id":"dark_iron_armor","quantity":1},{"id":"heavy_iron_sword","quantity":1}]:
		var item: Item=inventory.call("load_item_by_id",StringName(request.id)) as Item
		var index: int=definition.stock.find(StringName(request.id))
		if item==null or index<0: return result
		for quantity in int(request.quantity):
			var button: Button=_shop_plus(shop,item,index)
			var scroll: ScrollContainer=shop.get_node_or_null("Panel/Content/Tabs/买入") as ScrollContainer
			var wheels: int=0
			while button!=null and not _clickable(button) and scroll!=null and wheels<40:
				if not await _wheel(scroll,button.get_global_rect().get_center().y>scroll.get_global_rect().get_center().y,commands,deadline): return result
				wheels+=1
				button=_shop_plus(shop,item,index)
			if button==null or not await _click(button,"normal_buy_plus_"+request.id,commands,deadline): return result
			await tree.process_frame
			var quantities: Dictionary=shop.get("_buy_quantities")
			if quantities.get(StringName(request.id))!=quantity+1: return result
	var selected: Dictionary=shop.get("_buy_quantities")
	if selected.size()!=3 or selected.get(&"healing_pill_minor")!=10 or selected.get(&"dark_iron_armor")!=1 or selected.get(&"heavy_iron_sword")!=1: return result
	if not await _click(shop.get_node_or_null("%ConfirmTradeButton") as Control,"normal_trade_confirm",commands,deadline): return result
	var overlay: Control=shop.get_node_or_null("%TradeConfirmOverlay") as Control
	if overlay==null or not overlay.is_visible_in_tree(): return result
	if not await _click(shop.get_node_or_null("%AcceptTradeButton") as Control,"normal_trade_accept",commands,deadline): return result
	result["commands"]=commands; result["after"]=_inventory_state()
	var before: Dictionary=result.before; var after: Dictionary=result.after
	result.ok=before.gold==20000 and before.healing==2 and after.gold==before.gold-872 and after.healing==before.healing+10 and after.sword_count==before.sword_count+1 and after.armor_count==before.armor_count+1 and after.weapon_instance==before.weapon_instance and after.armor_instance==before.armor_instance
	check.call(result.ok,"normal shop buys one sword/one armor/ten pills for exact872, no automatic equip or fixture injection")
	return result

func release() -> void:
	tree=null
	driver=null
	check=Callable()

