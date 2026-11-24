extends RefCounted
## NEW fixed wall_street candidate sibling; original predicates remain unchanged.
const SNAPSHOT_ORIGIN_PATH: String = "res://tests/helpers/joint_v15_street_detail_city_prepared_phase.gd"
const SNAPSHOT_ORIGIN_SHA: String = "1fcd434cadae68300c24fc0fab255bd4409680ce433640ec4bcb7aab21fd7f1c"
## NEW ordinary gameplay phase. No lab Field, DRY_RUN, result signal or normal
## player-save write. Current art/canonical semantic identities are re-read.
const PHYSICAL := preload("res://tests/helpers/joint_v15_wall_street_city_physical_alpha_probe.gd")
const INPUT := preload("res://tests/helpers/v15_input_driver.gd")
const BATTLE := preload("res://tests/helpers/joint_v15_existing_battle_ui_probe.gd")
const RAW := preload("res://tests/helpers/joint_v15_wall_street_ordinary_raw_oracle.gd")
const WORLD_RAW := preload("res://tests/helpers/joint_v15_v7_world_raw_oracle.gd")
const CITY_SUBJECT := preload("res://scripts/city/luoyang_layered_v3_wall_street_candidate_contract.gd")
const SPRITE_ALPHA := preload("res://tests/helpers/joint_v15_city_sprite_alpha_probe.gd")
const MIGRATION_LOAD := preload("res://tests/helpers/joint_v15_wall_street_city_migration_load_probe.gd")
const INTERACTION_NEGATIVES := preload("res://tests/helpers/joint_v15_city_interaction_negative_probe.gd")
const BGM_LOOP := preload("res://tests/helpers/joint_v15_looped_bgm_continuity.gd")
const BGM_LOOP_SHA := "28252849ab92aee8e687bf4372d24c7f369b6c13fc51180510a1b3e00d6563a3"
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const ART_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v4/"
const SIZE := Vector2(3072,2048)
const COUNTS := {"npcs":15,"interactions":11,"portals":12}
var tree: SceneTree
var candidate: bool
var checks: int=0
var failures: int=0
var output: String=""
var field: Node
var probe: RefCounted
var driver: RefCounted
var raw: RefCounted
var manifest: Dictionary={}
var records: Dictionary={"regions":[],"npcs":[],"interactions":[],"portals":[],"bounties":[],"dialog_nodes":[],"screenshots":[],"water_domains":[],"migration":{},"interaction_negatives":{}}
var water_summaries: Array[Dictionary]=[]
var before_files: Dictionary={}
var before_nav: Dictionary={}
var before_slot: Variant
var expected: Dictionary={"npcs":[],"interactions":[],"portals":[]}
var events: Array[Dictionary]=[]
var event_connections: Array[Dictionary]=[]
var runtime_started: bool=false

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		failures+=1
		push_error("[JOINT CITY FAIL] "+label)
	return ok

func _point(v: Variant) -> Vector2:
	if v is Vector2: return v
	if v is Array and v.size()==2: return Vector2(float(v[0]),float(v[1]))
	return Vector2(INF,INF)

func _write(name: String,data: Dictionary) -> bool:
	var path: String=output+name
	if FileAccess.file_exists(path): return false
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	var encoded: String=JSON.stringify(data,"\t")
	file.store_string(encoded)
	file.flush()
	var error: Error=file.get_error()
	file.close()
	return error==OK and JSON.parse_string(FileAccess.get_file_as_string(path))==JSON.parse_string(encoded)

func _normal_files() -> Dictionary:
	var result: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[slot,suffix]
			result[path]={"exists":FileAccess.file_exists(path),"sha256":FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0}
	return result

func run(owner: SceneTree,before_cutover: bool) -> Dictionary:
	if not FileAccess.get_sha256(SNAPSHOT_ORIGIN_PATH).to_lower()==SNAPSHOT_ORIGIN_SHA:
		return {"scope":"JOINT_CITY_ACTUAL_NORMAL_FIELD_GAMEPLAY_NOT_JOINT_FULL","checks":1,"failures":1,"source_complete":false,"ordinary_Field_executed":false,"normal_gameplay":false,"dry_run":false,"reason":"frozen city gameplay parent bytes changed"}
	tree=owner
	candidate=before_cutover
	before_files=_normal_files()
	before_slot=tree.root.get_node("SaveManager").get("active_slot")
	output="res://build/joint_world_luoyang_20261003_qa/city_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"new city evidence directory")
	_check(candidate==("--luoyang-v3-candidate" in OS.get_cmdline_user_args()),"candidate city requires explicit candidate flag; canonical run forbids clone flag")
	driver=INPUT.new()
	driver.call("configure",tree)
	for id: String in IDS:
		var path: String=ART_ROOT+id+"/art_contract.json"
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_check(parsed is Dictionary,"current complete city manifest exists: "+id)
		if not parsed is Dictionary: continue
		var current: Dictionary=parsed as Dictionary
		var legacy: SceneScript=CITY_SUBJECT.legacy_scene(StringName(id))
		_check(legacy!=null and current.get("gameplay_slots") is Dictionary,"actual immutable original semantic identities and current city slots: "+id)
		if legacy==null or not current.get("gameplay_slots") is Dictionary: continue
		for kind: String in COUNTS:
			var originals: Array=legacy.npcs if kind=="npcs" else legacy.map_layout.get(kind)
			var slots: Array=current.gameplay_slots.get(kind,[])
			var seen: Dictionary={}
			for entry: Dictionary in originals:
				var sid: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
				expected[kind].append(id+"/"+sid)
				_check(not sid.is_empty() and not seen.has(sid) and not _slot(slots,sid).is_empty(),"current gameplay slot preserves exact original identity: "+id+"/"+sid)
				seen[sid]=true
			_check(slots.size()==originals.size(),"no additional/missing semantic identities: "+id+" "+kind)
	for kind: String in COUNTS: _check((expected[kind] as Array).size()==int(COUNTS[kind]),"all four original city "+kind+" counted independently")
	if failures>0: return await _finish()
	var sprite_alpha: RefCounted=SPRITE_ALPHA.new()
	var current_texture_cases: Dictionary=await sprite_alpha.call("run",tree,_check,output)
	_check(_write("current_sprite_atlas_region_flips.json",current_texture_cases),"synthetic current-frame/region/flip hit+render evidence persisted, separate from gameplay")
	sprite_alpha=null
	_public_fixture({})
	tree.root.get_node("SceneRouter").call("reset_for_new_game")
	before_nav=tree.root.get_node("SceneRouter").call("get_navigation_state")
	if candidate:
		var upgraded: Dictionary=before_nav.duplicate(true)
		upgraded["world_map_version"]=15
		tree.root.get_node("SceneRouter").call("restore_navigation_state",upgraded,&"",&"world_map_jianghu_v15")
		_check(String(tree.root.get_node("SceneRouter").call("get_active_world_map_scene"))=="world_map_jianghu_v15","public explicit candidate navigation selects real v15 return map")
	_connect_events()
	for id: String in IDS:
		_public_fixture({})
		if not await _open(id): continue
		await probe.call("run_routes")
		await probe.call("run_objects")
		for object: Dictionary in (probe.get("data") as Dictionary).get("objects",[]):
			if (object.get("alpha",{}) as Dictionary).get("method")=="continuous_full_drawrect_axis_separation": records.water_domains.append(object.alpha)
		records.regions.append({"id":id,"manifest_sha256":FileAccess.get_sha256(ART_ROOT+id+"/art_contract.json"),"physical_and_current_alpha":(probe.get("data") as Dictionary).duplicate(true)})
		var legacy: SceneScript=CITY_SUBJECT.legacy_scene(StringName(id))
		for entry: Dictionary in legacy.npcs:
			for mode: String in ["space","mouse"]: await _normal_action_case(id,"npcs",entry,mode)
		for entry: Dictionary in legacy.map_layout.interactions:
			for mode: String in ["space","mouse"]: await _normal_action_case(id,"interactions",entry,mode)
		for entry: Dictionary in legacy.map_layout.portals:
			for mode: String in ["space","mouse"]: await _normal_portal_case(id,entry,mode)
	# Both existing cases use the real old adjacent fields and ordinary rewards.
	await _normal_bounty_rewards()
	var negatives: RefCounted=INTERACTION_NEGATIVES.new()
	records.interaction_negatives=await negatives.call("run",self)
	negatives=null
	var migration: RefCounted=MIGRATION_LOAD.new()
	records.migration=await migration.call("run",self)
	migration=null
	return await _finish()

func _slot(slots: Array,id: String) -> Dictionary:
	for value: Dictionary in slots:
		if String(value.get("source_id",""))==id: return value
	return {}

func _public_fixture(entry: Dictionary) -> void:
	# A documented new-game process fixture. No persisted user data is restored,
	# no completion/result/reward is injected. Required flags only establish entry.
	for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState"]:
		tree.root.get_node(id).call("reset_for_new_game")
	var state: Node=tree.root.get_node("GameState")
	state.call("set_flag",&"chapter3_complete",true)
	state.call("set_flag",&"seen_ch4_yamen",true)
	state.call("set_flag",&"chapter4_started",true)
	state.set("current_chapter",4)
	state.call("add_gold",20000)
	var stats: Resource=state.get("player") as Resource
	stats.call("gain_exp",20000)
	stats.set("hp",stats.get("max_hp"))
	stats.set("mp",stats.get("max_mp"))
	for flag_key: String in ["require_flag","require_story_flag"]:
		var flag: String=String(entry.get(flag_key,""))
		if not flag.is_empty(): state.call("set_flag",StringName(flag),true)
	var quest: String=String(entry.get("require_quest_active",""))
	if not quest.is_empty(): tree.root.get_node("QuestManager").call("accept",StringName(quest))
	var hidden: String=String(entry.get("hide_flag",""))
	if not hidden.is_empty(): state.call("set_flag",StringName(hidden),false)
	# q1/q2 are real public accepted fixtures, not forced completed state.
	for qid: String in ["q_ch4_main_01_clue","q_ch4_main_02_canal"]:
		if ResourceLoader.exists("res://data/quests/"+qid+".tres"): tree.root.get_node("QuestManager").call("accept",StringName(qid))
	_check(_normal_files()==before_files and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"normal public fixture never writes player slots")

func _connect_events() -> void:
	var bus: Node=tree.root.get_node("EventBus")
	var dialog_observer: Callable=func(id: StringName): events.append({"kind":"dialog_started","id":String(id)})
	var npc_observer: Callable=func(id: StringName): events.append({"kind":"npc_talked_to","id":String(id)})
	var hotspot_observer: Callable=func(id: StringName,label: String): events.append({"kind":"hotspot_triggered","scene_id":String(id),"label":label})
	for entry: Dictionary in [{"signal":"dialog_started","callable":dialog_observer},{"signal":"npc_talked_to","callable":npc_observer},{"signal":"hotspot_triggered","callable":hotspot_observer}]:
		bus.connect(entry.signal,entry.callable)
		event_connections.append(entry)

func _wait_field(id: String,seconds: float=30) -> bool:
	var deadline: int=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		var loading: Node=tree.root.get_node_or_null("LoadingManager")
		if loading!=null and bool(loading.get("_transition_active")): continue
		var pending_field: Node=tree.current_scene
		if not is_instance_valid(pending_field) or not pending_field.is_inside_tree() or pending_field.is_queued_for_deletion(): continue
		if pending_field.scene_file_path not in ["res://scenes/field_walkable.tscn","res://scenes/field.tscn"]: continue
		var definition: SceneScript=pending_field.get("_current_scene") as SceneScript
		var player: Node2D=pending_field.get("_player") as Node2D
		if definition==null or String(definition.scene_id)!=id or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or bool(pending_field.get("_scene_rebuilding")): continue
		# Same-ID navigation can replace this Field during the awaited normal stages.
		# Never bind the pre-await node, or ask detached Physics for its space.
		await driver.call("completed_actor_stage")
		if not is_instance_valid(pending_field) or tree.current_scene!=pending_field or not pending_field.is_inside_tree() or pending_field.is_queued_for_deletion(): continue
		if loading!=null and bool(loading.get("_transition_active")): continue
		if bool(pending_field.get("_scene_rebuilding")) or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or pending_field.get("_player")!=player: continue
		var completed_definition: SceneScript=pending_field.get("_current_scene") as SceneScript
		if completed_definition==null or String(completed_definition.scene_id)!=id or not pending_field.is_ancestor_of(player): continue
		field=pending_field
		runtime_started=true
		return true
	return false

func _release_field_oracles() -> void:
	if probe!=null: probe.call("release")
	if raw!=null: raw.call("release")
	probe=null
	raw=null

func _bind_field(id: String) -> bool:
	_release_field_oracles()
	manifest=JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT+id+"/art_contract.json")) as Dictionary
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	_check(definition!=null and definition.scene_id==StringName(id) and definition.map_layout.schema_version==3,"actual normal Field uses current city3 resources")
	_check(field.get_script().resource_path=="res://scripts/field/field_walkable_controller.gd","normal production Field, no lab/dry-action subclass")
	raw=RAW.new()
	if not _check(bool(raw.call("configure_city",definition,candidate)),"independent current-city raw875/full17 source oracle"): return false
	probe=PHYSICAL.new()
	return _check(bool(probe.call("configure",tree,field,manifest,_check,_capture)),"actual physical/current-alpha probe uses frozen current manifest")

func _open(id: String,at: Variant=null) -> bool:
	var accepted: bool=tree.root.get_node("SceneRouter").call("go_field_smart",StringName(id),at,"",-1,3)
	_check(accepted,"normal public city route accepts current native source version3: "+id)
	if not accepted or not await _wait_field(id):
		_check(false,"actual ordinary Field arrives: "+id)
		return false
	await _finish_dialogs()
	return _bind_field(id)

func _state() -> Dictionary:
	var state: Node=tree.root.get_node("GameState")
	return {"flags":(state.get("flags") as Dictionary).duplicate(true),"gold":state.get("gold"),"training":state.get("training_points_total"),"reputation":state.get("reputation"),"sparring":(state.get("sparring_records") as Dictionary).duplicate(true),"inventory":tree.root.get_node("Inventory").call("to_dict"),"quests":tree.root.get_node("QuestManager").call("to_dict"),"investigation":tree.root.get_node("InvestigationState").call("to_dict"),"bounty":tree.root.get_node("BountyManager").call("to_dict"),"navigation":tree.root.get_node("SceneRouter").call("get_navigation_state")}

func _finish_dialogs() -> Array[Dictionary]:
	var visited: Array[Dictionary]=[]
	var dialog: Node=tree.root.get_node("DialogPlayer")
	var deadline: int=Time.get_ticks_msec()+45000
	var last: String=""
	while bool(dialog.call("is_playing")) and Time.get_ticks_msec()<deadline:
		await driver.call("completed_actor_stage")
		var node: DialogNode=dialog.get("_current_node") as DialogNode
		var script: DialogScript=dialog.get("_current_script") as DialogScript
		var dialog_layer: Node=dialog.get("_box") as Node
		var box: Control=dialog_layer.get_node_or_null("DialogBox") as Control if is_instance_valid(dialog_layer) and dialog_layer is CanvasLayer else null
		if node==null or script==null or box==null: continue
		if not _check(dialog_layer.get_parent()==dialog and box.get_parent()==dialog_layer and box.get_script()!=null and box.get_script().resource_path=="res://scripts/ui/dialog_box.gd","actual normal CanvasLayer root and exact live DialogBox child"): continue
		var identity: String=String(script.dialog_id)+"/"+String(node.node_id)
		if identity!=last:
			var flag_checks: Dictionary={}
			for flag: Dictionary in node.set_flags:
				var key: String=String(flag.get("key",""))
				var actual: Variant=(tree.root.get_node("GameState").get("flags") as Dictionary).get(key)
				flag_checks[key]=actual
				_check(not key.is_empty() and actual==flag.get("value",true),"authored node flag effect really executes: "+identity+" "+key)
			visited.append({"id":identity,"source_path":script.resource_path,"source_sha256":FileAccess.get_sha256(script.resource_path),"node_flags":flag_checks,"before_next_input":_state()})
			last=identity
		var choices: Array=box.get("_choice_rects") if box.get("_choice_rects") is Array else []
		if box.get("choices_container")!=null and box.get("choices_container").is_visible_in_tree() and not choices.is_empty():
			await driver.call("pointer",(choices[0] as Rect2).get_center())
		else: await driver.call("key",KEY_SPACE)
	_check(not bool(dialog.call("is_playing")),"ordinary dialogue completes through normal Space/choice UI within finite budget")
	records.dialog_nodes.append_array(visited)
	return visited

func _npc(id: String) -> Node:
	for node: Node in field.get("_npc_nodes"):
		if String(node.get("npc_id"))==id: return node
	return null

func _npc_stand(node: Node) -> Vector2:
	var root_position: Vector2=node.position
	for radius in [40,48,56,64,72]:
		for index in 16:
			var point: Vector2=root_position+Vector2.from_angle(TAU*index/16)*radius
			if bool(probe.call("clear",point)): return point
	return Vector2(INF,INF)

func _normal_action_case(id: String,kind: String,entry: Dictionary,mode: String) -> void:
	_public_fixture(entry)
	if not await _open(id): return
	var sid: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
	var slot: Dictionary=_slot(manifest.gameplay_slots[kind],sid)
	var target: Node=_npc(sid) if kind=="npcs" else null
	_check(kind!="npcs" or target!=null,"required original gated NPC really spawned: "+id+"/"+sid)
	if kind=="npcs" and target==null: return
	# Each gated original NPC appears through its NORMAL entry fixture. Aggregate
	# all these actual source families before claiming a complete boat domain.
	if kind=="npcs":
		var water_proofs: Array=await probe.call("water_proofs")
		for proof: Dictionary in water_proofs:
			proof["normal_npc_gate_fixture"]=id+"/"+sid+"/"+mode
			records.water_domains.append(proof)
			_check(_write("water_family_"+id+"_"+sid+"_"+mode+".json",proof),"full normal source-family domain evidence checked readback before absence classification")
	var station: Vector2=_npc_stand(target) if target!=null else _point(slot.get("stand_px"))
	var approach: Dictionary=await probe.call("move_to",station)
	if not _check(bool(approach.get("ok",false)),"real normal input reaches original action: "+id+"/"+sid+" "+mode): return
	var source_foot: Vector2=(field.get("_player") as Node2D).position
	var before: Dictionary=_state()
	var event_start: int=events.size()
	var input: Dictionary={"mode":mode}
	if mode=="space": await driver.call("key",KEY_SPACE)
	elif target!=null: input=await probe.call("click_entity",target.get("sprite"))
	else:
		var sprite: Sprite2D=probe.call("prop",String(slot.get("object_id",""))) as Sprite2D
		_check(sprite!=null,"original action's actual entity exists, no invisible ground fallback")
		if sprite==null: return
		input=await probe.call("click_entity",sprite)
	await driver.call("completed_actor_stage")
	var dialogues: Array[Dictionary]=await _finish_dialogs()
	var action: String=String(entry.get("interaction_action",entry.get("action","")))
	var dialog_id: String=String(entry.get("dialog_id",""))
	if action.begins_with("dialog:"): dialog_id=action.trim_prefix("dialog:")
	var received: Array=events.slice(event_start)
	var effects: Dictionary={}
	if action.begins_with("spar:"):
		var modal: Control=field.get("_sparring_confirm_dialog") as Control
		_check(modal!=null and modal.is_visible_in_tree(),"ordinary sparring preface opens real confirm, not direct battle")
		if modal!=null:
			var button: Button=modal.get_node_or_null("%ConfirmAction") as Button
			_check(button!=null,"normal sparring confirmation button exists")
			if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		effects=await battle.call("victory",id,source_foot,3)
		battle.call("release")
		battle=null
		var spar_id: String=action.split(":")[1]
		_check(bool(((tree.root.get_node("GameState").get("sparring_records") as Dictionary).get(spar_id,{}) as Dictionary).get("won",false)),"normal first victory records actual sparring result/reward")
		if bool(effects.get("returned",false)) and await _wait_field(id): _bind_field(id)
	elif action.begins_with("shop:"):
		effects=await _normal_shop_buy(id,source_foot)
	elif action.begins_with("bounty_board:"):
		var page: Node=tree.current_scene
		_check(page!=null and page.get_node_or_null("BountyEntries")!=null,"actual entity opens normal bounty board")
		if page!=null and page.get_node_or_null("CloseButton")!=null:
			await driver.call("pointer",(page.get_node("CloseButton") as Control).get_global_rect().get_center())
			_check(await _wait_field(id),"normal bounty close returns original city")
			if is_instance_valid(field): _bind_field(id)
	elif action.begins_with("discover_readable:"):
		var parts: PackedStringArray=action.split(":")
		_check(parts.size()>=3 and bool((tree.root.get_node("GameState").get("flags") as Dictionary).get(parts[2],false)),"normal actual discovery executes original once flag")
	else:
		_check(not dialog_id.is_empty() and not dialogues.is_empty(),"normal original NPC/hotspot starts and completes actual dialogue, no dry log")
		if tree.current_scene!=null and tree.current_scene.get_node_or_null("%BtnAttack")!=null:
			var battle: RefCounted=BATTLE.new()
			battle.call("configure",tree,driver,_check)
			effects=await battle.call("victory",id,source_foot,3)
			battle.call("release")
			if bool(effects.get("returned",false)) and await _wait_field(id):
				await _finish_dialogs()
				_bind_field(id)
	received=events.slice(event_start)
	if kind=="npcs":
		var exact_npc_event: bool=false
		for event: Dictionary in received:
			if event.get("kind")=="npc_talked_to" and event.get("id")==sid: exact_npc_event=true
		_check(exact_npc_event,"normal current NPC identity actually accepted this input, not a nearer NPC")
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"action":action,"dialog_id":dialog_id,"actual_input":input,"approach":approach,"pre_action_feet_px":[source_foot.x,source_foot.y],"events":received,"dialog_nodes":dialogues,"before":before,"after":_state(),"effects":effects}
	records[kind].append(record)
	_check(_write(kind+"_"+id+"_"+sid+"_"+mode+".json",record),"actual normal action and state evidence checked readback")
	await _capture(kind+"_"+sid+"_"+mode)

func _normal_shop_buy(id: String,foot: Vector2) -> Dictionary:
	var deadline: int=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		if tree.current_scene!=null and tree.current_scene.get_node_or_null("%BuyList")!=null: break
	var page: Node=tree.current_scene
	var result: Dictionary={"entered":page!=null and page.get_node_or_null("%BuyList")!=null,"bought":false,"returned":false}
	_check(bool(result.entered),"normal armorer input opens actual Shop UI")
	if not bool(result.entered): return result
	var shop: ShopDef=page.get("_shop") as ShopDef
	var inventory: Node=tree.root.get_node("Inventory")
	var gold: int=tree.root.get_node("GameState").get("gold")
	var initial: Dictionary=inventory.call("to_dict")
	var plus: Button
	var pending: Array[Node]=[(page.get_node("%BuyList") as Node)]
	while not pending.is_empty():
		var node: Node=pending.pop_front()
		pending.append_array(node.get_children())
		if node is Button and node.text=="+" and not node.disabled and node.is_visible_in_tree(): plus=node; break
	_check(plus!=null and shop!=null,"real stock has available plus control")
	if plus==null or shop==null: return result
	await driver.call("pointer",plus.get_global_rect().get_center())
	var selected: Dictionary=(page.get("_buy_quantities") as Dictionary).duplicate(true)
	var price: int=0
	for item_id: Variant in selected:
		var item: Item=inventory.call("load_item_by_id",StringName(item_id)) as Item
		_check(item!=null and shop.stock.has(StringName(item_id)),"selected UI item belongs to original armory stock")
		if item!=null: price+=item.buy_price*int(selected[item_id])
	var confirm: Button=page.get_node("%ConfirmTradeButton") as Button
	_check(price>0 and not confirm.disabled,"ordinary UI computes a genuine positive purchase")
	await driver.call("pointer",confirm.get_global_rect().get_center())
	var accept: Button=page.get_node("%AcceptTradeButton") as Button
	_check(accept.is_visible_in_tree(),"ordinary trade confirmation really opens")
	await driver.call("pointer",accept.get_global_rect().get_center())
	var after: Dictionary=inventory.call("to_dict")
	result.bought=int(tree.root.get_node("GameState").get("gold"))==gold-price and after!=initial
	for item_id: Variant in selected:
		var old_count: int=0
		for old: Dictionary in initial.get("slots",[]):
			if String(old.get("item_id",""))==String(item_id): old_count+=int(old.get("count",0))
		_check(int(inventory.call("count_of",StringName(item_id)))==old_count+int(selected[item_id]),"normal purchase adds exact selected stock quantity")
	_check(bool(result.bought),"actual confirmed stock transaction subtracts exact item prices and changes inventory")
	result["selected"]=selected
	result["price"]=price
	result["inventory_before"]=initial
	result["inventory_after"]=after
	if tree.current_scene==page:
		await driver.call("pointer",(page.get_node("%CloseBtn") as Control).get_global_rect().get_center())
	result.returned=await _wait_field(id)
	_check(bool(result.returned),"normal Shop action returns original city")
	if bool(result.returned):
		await _finish_dialogs()
		_check((field.get("_player") as Node2D).position.distance_to(foot)<.03,"shop public return preserves exact pre-action feet/local version")
		_bind_field(id)
	return result

func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	if not _check("--qa-gpu-approved" in OS.get_cmdline_user_args(),"explicit root GPU authorization"): return
	await driver.call("completed_actor_stage")
	await RenderingServer.frame_post_draw
	var image: Image=tree.root.get_texture().get_image()
	var path: String=output+label+"_"+str(records.screenshots.size())+".png"
	_check(image!=null and not FileAccess.file_exists(path),"new actual normal gameplay screenshot")
	if image!=null and not FileAccess.file_exists(path) and _check(image.save_png(path)==OK,"raw gameplay screenshot saved"):
		records.screenshots.append({"path":path,"sha256":FileAccess.get_sha256(path),"label":label,"visual_verdict":"NOT_REVIEWED"})

func _normal_portal_case(id: String,entry: Dictionary,mode: String) -> void:
	_public_fixture(entry)
	if not await _open(id): return
	var sid: String=String(entry.id)
	var slot: Dictionary=_slot(manifest.gameplay_slots.portals,sid)
	var point: Vector2=_point(slot.get("foot_px"))
	var approach: Dictionary=await probe.call("move_to",point)
	if not _check(bool(approach.get("ok",false)),"normal continuous input reaches city doorway: "+id+"/"+sid): return
	var before_foot: Vector2=(field.get("_player") as Node2D).position
	var zone: Node
	for value: Node in field.get("_exit_nodes"):
		if String(value.name)=="Exit_"+sid or String(value.get_meta("portal_id",""))==sid: zone=value
	if zone==null:
		for index in (field.get("_current_scene") as SceneScript).map_layout.portals.size():
			if String((field.get("_current_scene") as SceneScript).map_layout.portals[index].id)==sid: zone=(field.get("_exit_nodes") as Array)[index]; break
	_check(zone!=null and bool(zone.get("_in_range")),"actual enabled doorway has real player Physics2D overlap")
	if zone==null: return
	var audio: Node=tree.root.get_node("AudioManager")
	var bgm: AudioStreamPlayer=audio.get("bgm_player") as AudioStreamPlayer
	var before_bgm: Dictionary={"path":String(audio.get("_current_bgm_path")),"id":bgm.get_instance_id() if bgm!=null else 0,"position":bgm.get_playback_position() if bgm!=null else 0}
	var bgm_observer: RefCounted=BGM_LOOP.new()
	_check(FileAccess.get_sha256("res://tests/helpers/joint_v15_looped_bgm_continuity.gd")==BGM_LOOP_SHA,"current bounded loop-observer source is frozen")
	var bgm_started: Dictionary=bgm_observer.call("begin_observation",tree,id+"/"+sid+"/"+mode)
	if mode=="space": await driver.call("key",KEY_SPACE)
	else:
		var container: Node2D=field.get("world_container") as Node2D
		await driver.call("pointer",container.get_global_transform_with_canvas()*point)
	var target: String=String(entry.get("target_scene",""))
	if String(entry.get("action",""))=="world_map": target="world_map_jianghu_v15" if candidate else "world_map_jianghu"
	var entered: bool=await _wait_field(target)
	var bgm_observed: Dictionary=bgm_observer.call("finish_observation")
	bgm_observer.call("release")
	bgm_observer=null
	_check(entered,"normal city portal really arrives exact original target: "+id+"/"+sid)
	var back: Dictionary={"not_run":true}
	var paired_memory_api: Dictionary={"not_run":true}
	if entered:
		await _finish_dialogs()
		var definition: SceneScript=field.get("_current_scene") as SceneScript
		if definition.bgm_path==((CITY_SUBJECT.legacy_scene(StringName(id)) as SceneScript).bgm_path):
			_check(bool(bgm_started.get("ok",false)) and bool(bgm_observed.get("ok",false)),"same authored BGM keeps exact stream/player/path, zero change events and measured looped playhead continuity")
		if id=="ch4_s2_canal_docks" and target in ["world_map_jianghu_v15","world_map_jianghu"]:
			# Existing world UI has no direct world->docks door. The producer-approved
			# public paired-memory API is tested SEPARATELY, never input credit.
			tree.root.get_node("SceneRouter").call("return_from_world_map")
			var api_returned: bool=await _wait_field(id)
			var exact_memory: bool=api_returned and (field.get("_player") as Node2D).position.distance_to(before_foot)<.03
			_check(exact_memory,"separate PUBLIC_API_NOT_INPUT world return preserves precise docks memory")
			paired_memory_api={"scope":"PUBLIC_API_NOT_INPUT","returned":api_returned,"exact_source_feet":exact_memory}
			if not api_returned: return
			await _finish_dialogs()
			if not _bind_field(id): return
			var repeat_approach: Dictionary=await probe.call("move_to",before_foot)
			_check(bool(repeat_approach.get("ok",false)),"normal input re-reaches same docks ferry after separate API test")
			if not bool(repeat_approach.get("ok",false)): return
			await driver.call("key",KEY_SPACE)
			if not _check(await _wait_field(target),"normal ferry input re-enters world before original indirect return chain"): return
			await _finish_dialogs()
		back=await _return_from_target(id)
		_check(bool(back.get("returned",false)),"actual target public exit/input returns city, no Router shortcut")
		if bool(back.get("returned",false)):
			await _finish_dialogs()
			if String(back.get("kind",""))=="DIRECT_ORIGINAL_REVERSE_INPUT":
				_check((field.get("_player") as Node2D).position.distance_to(before_foot)<.03,"paired direct city return preserves exact ordinary pre-departure feet")
			else:
				_check(String(back.get("kind",""))=="INDIRECT_WORLD_GATE_YAMEN_DOCKS_INPUT","indirect original topology is explicitly distinguished from nonexistent direct paired-docks input")
			_bind_field(id)
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"target":target,"entered":entered,"source_foot_px":[before_foot.x,before_foot.y],"approach":approach,"return":back,"separate_paired_memory_api":paired_memory_api,"bgm_before":before_bgm,"bgm_started":bgm_started,"bgm_observation":bgm_observed}
	records.portals.append(record)
	_check(_write("portal_"+id+"_"+sid+"_"+mode+".json",record),"normal portal evidence persists")

func _return_from_target(source: String) -> Dictionary:
	var actual_definition: SceneScript=field.get("_current_scene") as SceneScript
	if source=="ch4_s2_canal_docks" and String(actual_definition.scene_id) in ["world_map_jianghu_v15","world_map_jianghu"]:
		var steps: Array[Dictionary]=[]
		for destination: String in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks"]:
			var step: Dictionary=await _input_existing_exit_to(destination)
			steps.append(step)
			if not bool(step.get("returned",false)): return {"returned":false,"kind":"INDIRECT_WORLD_GATE_YAMEN_DOCKS_INPUT","steps":steps}
			await _finish_dialogs()
		return {"returned":true,"kind":"INDIRECT_WORLD_GATE_YAMEN_DOCKS_INPUT","steps":steps,"not_a_direct_paired_return":true}
	var result: Dictionary=await _input_existing_exit_to(source)
	result["kind"]="DIRECT_ORIGINAL_REVERSE_INPUT"
	return result

func _input_existing_exit_to(source: String) -> Dictionary:
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var is_world: bool=String(definition.scene_id) in ["world_map_jianghu_v15","world_map_jianghu"]
	var actual_raw: RefCounted=WORLD_RAW.new() if is_world else RAW.new()
	var ok: bool=bool(actual_raw.call("configure_city",definition,candidate)) if IDS.has(String(definition.scene_id)) else bool(actual_raw.call("configure",definition.map_layout if is_world else definition))
	var result: Dictionary={"returned":false,"target_scene":String(definition.scene_id)}
	if not _check(ok,"target's original raw native/legacy navigation configured independently"): actual_raw.call("release"); return result
	var size: Vector2=field.get("_world_size")
	var clear: Callable=func(p: Vector2)->bool: return bool(actual_raw.call("clear",p)) and _actual_body_clear(field,p)
	var segment: Callable=func(a: Vector2,b: Vector2)->Dictionary:
		var count: int=maxi(1,ceili(a.distance_to(b)/4))
		for index in range(count+1):
			if not bool(clear.call(a.lerp(b,float(index)/count))): return {"clear":false,"index":index}
		return {"clear":true,"centers":count+1}
	var zone: Node
	# Ordinary ancient-temple doors are genuinely generated from original
	# SceneScript.hotspots. Inspect the live ExitZone rather than assuming every
	# original reverse door was authored in map_layout.portals.
	for actual_zone: Node in field.get("_exit_nodes"):
		if String(actual_zone.get("target_scene_id"))==source and not bool(actual_zone.get("is_locked")):
			zone=actual_zone
			break
	if not _check(zone!=null,"real target has original reverse route"): actual_raw.call("release"); return result
	var target: Vector2=zone.position
	result["original_reverse_zone"]={"node_path":str(zone.get_path()),"name":String(zone.name),"target_scene_id":String(zone.get("target_scene_id")),"target_spawn_pos":zone.get("target_spawn_pos"),"original_scene_sha256":FileAccess.get_sha256(definition.resource_path) if not definition.resource_path.is_empty() else "IN_MEMORY_CANDIDATE"}
	var path: PackedVector2Array=driver.call("plan",(field.get("_player") as Node2D).position,target,size,clear,segment)
	var driven: Dictionary=await driver.call("follow",field,path,clear,segment)
	_check(bool(driven.get("ok",false)) and bool(zone.get("_in_range")),"normal target input reaches enabled reverse area with complete feet/physics")
	if bool(driven.get("ok",false)):
		await driver.call("key",KEY_SPACE)
		result.returned=await _wait_field(source)
	result["drive"]=driven
	actual_raw.call("release")
	return result

func _actual_body_clear(actual: Node,p: Vector2) -> bool:
	var player: CharacterBody2D=actual.get("_player") as CharacterBody2D
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D if player!=null else null
	var world: Node2D=actual.get("world_container") as Node2D
	if shape==null or shape.disabled or shape.shape==null: return false
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape
	query.transform=shape.global_transform
	query.transform.origin+=world.to_global(p)-player.global_position
	query.exclude=[player.get_rid()]
	query.collision_mask=player.collision_mask
	query.collide_with_areas=false
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _normal_bounty_rewards() -> void:
	_public_fixture({"require_flag":"clue_luoyang_case"})
	var id: String=IDS[0]
	if not await _open(id): return
	var slot: Dictionary=_slot(manifest.gameplay_slots.interactions,"luoyang_repeatable_bounty_board")
	var approach: Dictionary=await probe.call("move_to",_point(slot.get("stand_px")))
	if not _check(bool(approach.get("ok",false)),"real bounty entity approachable"): return
	await probe.call("click_entity",probe.call("prop",String(slot.get("object_id",""))))
	for tick in 10: await tree.process_frame
	var page: Node=tree.current_scene
	if not _check(page!=null and page.get_node_or_null("BountyEntries")!=null,"ordinary entity opens actual two-case board"): return
	var entries: Array[Dictionary]=tree.root.get_node("BountyManager").call("get_board_entries",&"luoyang")
	_check(entries.size()==2,"both existing Luoyang bounty identities retained")
	for entry: Dictionary in entries:
		var button: Button=page.get_node_or_null("BountyEntries/BountyEntry_"+String(entry.bounty_id)+"/Content/AcceptButton") as Button
		_check(button!=null and not button.disabled,"ordinary available bounty accept control")
		if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
	await driver.call("pointer",(page.get_node("CloseButton") as Control).get_global_rect().get_center())
	_check(await _wait_field(id),"normal bounty board closes to exact city")
	for entry: Dictionary in entries:
		var manager: Node=tree.root.get_node("BountyManager")
		var states: Dictionary=(manager.call("to_dict") as Dictionary).states
		var state: Dictionary=states.get(String(entry.bounty_id),{})
		var definition: BountyDef=manager.call("get_definition",StringName(entry.bounty_id)) as BountyDef
		_check(String(state.get("status",""))=="active" and definition!=null,"normal actual UI accepted bounty, no injected active state")
		if definition==null or int(state.get("location_index",-1))<0: continue
		var location: Dictionary=definition.locations[int(state.location_index)]
		var target_id: String=String(location.scene_id)
		_check(not IDS.has(target_id),"existing bounty neighbor art/identity retained, not rebuilt as city")
		var accepted: bool=tree.root.get_node("SceneRouter").call("go_field_smart",StringName(target_id))
		if not _check(accepted and await _wait_field(target_id),"normal public travel enters original neighboring bounty scene"): continue
		await _finish_dialogs()
		var current: SceneScript=field.get("_current_scene") as SceneScript
		var target_raw: RefCounted=RAW.new()
		if not _check(bool(target_raw.call("configure",current)),"original neighbor raw navigation still valid"): target_raw.call("release"); continue
		var bounty_npc: Node=_npc("bounty_"+String(entry.bounty_id))
		_check(bounty_npc!=null,"actual accepted bounty spawns normal target NPC")
		if bounty_npc==null: target_raw.call("release"); continue
		var clear: Callable=func(p: Vector2)->bool: return bool(target_raw.call("clear",p)) and _actual_body_clear(field,p)
		var segment: Callable=func(a: Vector2,b: Vector2)->Dictionary:
			var count: int=maxi(1,ceili(a.distance_to(b)/4))
			for index in range(count+1):
				if not bool(clear.call(a.lerp(b,float(index)/count))): return {"clear":false}
			return {"clear":true}
		var station: Vector2=Vector2(INF,INF)
		for radius in [48,56,64,72]:
			for angle in 16:
				var point: Vector2=bounty_npc.position+Vector2.from_angle(TAU*angle/16)*radius
				if bool(clear.call(point)): station=point; break
			if station.is_finite(): break
		var path: PackedVector2Array=driver.call("plan",(field.get("_player") as Node2D).position,station,field.get("_world_size"),clear,segment)
		var driven: Dictionary=await driver.call("follow",field,path,clear,segment)
		if not _check(bool(driven.get("ok",false)),"actual normal input approaches original bounty NPC"): target_raw.call("release"); continue
		var pre: Dictionary=_state()
		var original_foot: Vector2=(field.get("_player") as Node2D).position
		var original_size: Vector2=field.get("_world_size")
		await driver.call("key",KEY_SPACE)
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		var actual: Dictionary=await battle.call("victory",target_id,original_foot,1,original_size)
		battle.call("release")
		var after: Dictionary=_state()
		var final_state: Dictionary=((manager.call("to_dict") as Dictionary).states as Dictionary).get(String(entry.bounty_id),{})
		_check(bool(actual.get("won",false)) and String(final_state.get("status",""))=="captured" and int(final_state.get("completion_count",0))==1,"real bounty victory completes original case exactly once")
		_check(int(after.reputation)==int(pre.reputation)+definition.reward_reputation and int(after.training)==int(pre.training)+definition.reward_training,"normal capture gives exact authored reputation/training, no fake result")
		records.bounties.append({"id":entry.bounty_id,"location":location,"normal_drive":driven,"battle":actual,"before":pre,"after":after,"final_state":final_state})
		target_raw.call("release")

func _finish() -> Dictionary:
	var bus: Node=tree.root.get_node("EventBus")
	for entry: Dictionary in event_connections:
		if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
	event_connections.clear()
	_release_field_oracles()
	var field_ref: WeakRef=weakref(field) if is_instance_valid(field) else null
	if is_instance_valid(tree.current_scene):
		var owned: Node=tree.current_scene
		tree.current_scene=null
		owned.queue_free()
	field=null
	for tick in 8: await tree.process_frame
	_check(field_ref==null or field_ref.get_ref()==null,"owned city Field/reference callbacks naturally released")
	_check(_normal_files()==before_files and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"normal player files and active slot unchanged through all normal city gameplay")
	# Actual action/result evidence above is retained before process-only cleanup.
	# Do not restore flags/inventory/quests wholesale and hide gameplay side effects.
	if not before_nav.is_empty():
		tree.root.get_node("SceneRouter").call("reset_for_new_game")
		_check(tree.root.get_node("SceneRouter").call("get_navigation_state")==before_nav,"public empty-navigation cleanup returns exact process fixture baseline")
	var covered: Dictionary={}
	for kind: String in COUNTS:
		var actual: Dictionary={}
		for row: Dictionary in records[kind]: actual[String(row.source_scene_id)+"/"+String(row.source_id)]=true
		var complete: bool=actual.size()==(expected[kind] as Array).size()
		for id: String in expected[kind]: complete=complete and actual.has(id)
		_check(complete,"actual normal input covers every original "+kind+" identity")
		covered[kind]=actual.keys()
	_finalize_water_proofs()
	var incomplete: Array[String]=[]
	if not bool((records.interaction_negatives as Dictionary).get("complete",false)): incomplete.append("ALL11_INTERACTION_WRONG_SIDE_AND_PHYSICAL_BOUNDARY_INPUT_NEGATIVES")
	if not bool((records.migration as Dictionary).get("complete",false)): incomplete.append("ACTUAL_LOCAL1_AND_LOCAL3_ISOLATED_MIGRATION_LOAD")
	var report: Dictionary={"schema":1,"scope":"JOINT_CITY_ACTUAL_NORMAL_FIELD_GAMEPLAY_NOT_JOINT_FULL","checks":checks,"failures":failures,"dry_run":false,"source_complete":incomplete.is_empty() and failures==0 and runtime_started,"ordinary_Field_executed":runtime_started,"incomplete_phases":incomplete,"normal_gameplay":failures==0 and runtime_started,"region_ids":IDS,"npcs_ids":covered.npcs,"interactions_ids":covered.interactions,"portals_ids":covered.portals,"water_decoration_absence_proofs":water_summaries.duplicate(true),"records":records.duplicate(true),"player_saves_unchanged":before_files==_normal_files(),"output":output,"engine_pid":OS.get_process_id(),"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"visual_verdict":"NOT_REVIEWED"}
	_check(_write("result.json",report),"complete actual city phase JSON persisted with checked readback")
	report.checks=checks
	report.failures=failures
	driver.call("release")
	driver=null
	manifest.clear()
	tree=null
	return report

func _finalize_water_proofs() -> void:
	var groups: Dictionary={}
	for proof: Dictionary in records.water_domains:
		var key: String=String(proof.region_id)+"/"+String(proof.object_id)
		if not groups.has(key): groups[key]=[]
		(groups[key] as Array).append(proof)
	for key: String in groups:
		var rows: Array=groups[key]
		var first: Dictionary=rows[0]
		var seen_npcs: Dictionary={}
		var complete: bool=true
		var gap: float=INF
		var frame_count: int=0
		for proof: Dictionary in rows:
			complete=complete and bool(proof.get("complete",false)) and proof.get("manifest_sha256")==first.manifest_sha256 and proof.get("source_sha256")==first.source_sha256 and proof.get("nav_sha256")==first.nav_sha256
			gap=minf(gap,float(proof.get("minimum_gap_px",-INF)))
			frame_count+=int(proof.get("source_frame_count",0))
			for actor_domain: Dictionary in proof.get("actor_domains",[]):
				if String(actor_domain.get("actor","")).begins_with("normal_player_"): continue
				seen_npcs[String(actor_domain.get("actor",""))]=true
		for expected_npc: String in expected.npcs:
			if expected_npc.begins_with(String(first.region_id)+"/"): complete=complete and seen_npcs.has(expected_npc.get_slice("/",1))
		var evidence_path: String=output+"water_complete_"+String(first.object_id)+".json"
		var saved: bool=_write("water_complete_"+String(first.object_id)+".json",{"scope":"CONTINUOUS_ALL_NORMAL_PLAYER_WEAPONS_AND_ALL_GATED_NPC_FAMILIES","complete":complete,"normal_npc_ids":seen_npcs.keys(),"families":rows})
		_check(complete and saved,"all original gated NPC source families and every Player weapon/state/direction belong to persisted complete water separation evidence: "+key)
		water_summaries.append({"region_id":first.region_id,"object_id":first.object_id,"method":"continuous_full_drawrect_axis_separation","complete":complete and saved,"manifest_sha256":first.manifest_sha256,"nav_sha256":first.nav_sha256,"source_sha256":first.source_sha256,"source_frame_count":frame_count,"source_alpha_pixels":first.source_alpha_pixels,"legal_nav_cells":first.legal_nav_cells,"intersection_count":0 if complete else -1,"minimum_gap_px":gap,"evidence":{"path":evidence_path,"sha256":FileAccess.get_sha256(evidence_path) if saved else ""}})

