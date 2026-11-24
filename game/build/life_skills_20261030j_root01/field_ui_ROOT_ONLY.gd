extends SceneTree
## Root-owned finite normal-field / real GUI input check, fresh memory only.
var failures: Array[String]=[]
var checks: int=0
var input_count: int=0
var finished: bool=false
var output: String
var records: Array=[]
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watchdog.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true)
func _watchdog() -> void:
	await create_timer(55,true,false,true).timeout
	if not finished:need(false,"WATCHDOG55");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:failures.append(label);printerr("LIFE_FIELD_UI_FAIL ",label)
	return ok
func wait_field(id: StringName,intro: bool=false) -> Node:
	var started:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<12000 and not finished:
		await process_frame
		if current_scene==null or not current_scene.has_method("get_field_loading_state"):continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("scene_id")!=String(id) or state.get("complete")!=true or state.get("failed")==true:continue
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		if bool(root.get_node("DialogPlayer").call("is_playing"))!=intro:continue
		return current_scene
	need(false,"FIELD_READY:"+String(id));return null
func delay(seconds: float=.35) -> void:await create_timer(seconds).timeout
func click(button: Control) -> void:
	var at: Vector2=button.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		Input.parse_input_event(event);input_count+=1;await process_frame
	await delay(.1)
func key(code: Key) -> void:
	for down: bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
		Input.parse_input_event(event);input_count+=1;await process_frame
	await delay(.1)
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=output+"/"+name+".png"
	need(image!=null and image.get_size()==Vector2i(1920,1080) and image.save_png(path)==OK,"NORMAL_IMAGE:"+name)
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)})
func _run() -> void:
	output="res://build/life_skills_20261030j_root01/field_ui/%d"%OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINTS_SUSPENDED"):finish();return
	var router: Node=root.get_node("SceneRouter");var game: Node=root.get_node("GameState");var inv: Node=root.get_node("Inventory");var life: Node=root.get_node("LifeSkills");var dialog: Node=root.get_node("DialogPlayer")
	inv.call("from_dict",{}) # Fresh test memory only, not a real saved slot.
	game.call("add_gold",40)
	if not need(router.call("go_field_smart",&"ch1_s1_road",null,"",-1,-1)==true,"PUBLIC_ROAD_DEFAULT"):finish();return
	var field: Node=await wait_field(&"ch1_s1_road",true)
	if field==null:finish();return
	for expected: String in ["start","meta","hint"]:
		var node: Resource=dialog.get("_current_node")
		if not need(node!=null and String(node.get("node_id"))==expected,"ORIGINAL_INTRO:"+expected):finish();return
		dialog.call("advance");await process_frame
	field=await wait_field(&"ch1_s1_road")
	if field==null:finish();return
	if not need(router.call("go_field_smart",&"ch1_s1_road",Vector2(850,2910)/Vector2(4608,3456),"",-1,3003)==true,"PUBLIC_HERB_NEAR_NOT_CONTINUOUS_WALK"):finish();return
	field=await wait_field(&"ch1_s1_road");await delay()
	if not need(field!=null and life.get("_active_sites").size()==3 and String(life.get("_nearest"))=="life_road_herb_01","REAL_ROAD_THREE_SITES_HERB_IN_RANGE"):finish();return
	await shot("ordinary_herb_site")
	await key(KEY_F)
	if not need(inv.call("count_of",&"herb_bundle")==2,"REAL_F_HARVEST_TWO_HERBS"):finish();return
	await key(KEY_F)
	need(inv.call("count_of",&"herb_bundle")==2,"REPEATED_F_NO_DUPLICATE_HARVEST")
	if not need(router.call("go_field_smart",&"ch1_s1_road",Vector2(3250,2130)/Vector2(4608,3456),"",-1,3003)==true,"PUBLIC_ORE_NEAR_NOT_CONTINUOUS_WALK"):finish();return
	field=await wait_field(&"ch1_s1_road");await delay()
	if not need(field!=null and String(life.get("_nearest"))=="life_road_ore_01","ORE_IN_RANGE"):finish();return
	await key(KEY_F)
	if not need(inv.call("count_of",&"iron_ore")==2,"REAL_F_HARVEST_TWO_ORE"):finish();return
	await click(life.get("_medicine_button") as Button)
	var panel: Control=life.get("_panel") as Control
	if not need(panel!=null and field.get("_system_panel_open")==true,"REAL_MEDICINE_BUTTON_BLOCKS_FIELD"):finish();return
	await shot("medicine_recipes")
	var line: HBoxContainer=(panel.get("rows") as VBoxContainer).get_child(0).get_child(0)
	await click(line.get_child(line.get_child_count()-1) as Button)
	var confirm: FormalConfirmDialog=panel.get("_confirm")
	if not need(confirm.is_open() and inv.call("count_of",&"herb_bundle")==2,"CONFIRM_BEFORE_ANY_DEDUCTION"):finish();return
	await click(confirm.get("_confirm_button") as Button)
	if not need(inv.call("count_of",&"healing_pill_minor")==1 and inv.call("count_of",&"herb_bundle")==0 and game.get("gold")==40,"REAL_GUI_MEDICINE_COMMITTED"):finish();return
	await key(KEY_ESCAPE)
	if not need(not is_instance_valid(life.get("_panel")) and field.get("_system_panel_open")==false,"MEDICINE_ESC_RESTORES_FIELD"):finish();return
	inv.call("add_item",&"iron_ore",1) # Clearly declared UI fixture: total3 for iron helmet.
	router.call("go_shop",&"luoyang_services_20261025h/smith");await delay(.7)
	var shop: Node=current_scene
	var button: Button=shop.get_node_or_null("Panel/LifeSmithButton") as Button
	if not need(button!=null,"ORIGINAL_SMITH_SHOP_HAS_MANUFACTURE_BUTTON"):finish();return
	await click(button);panel=life.get("_panel") as Control
	if not need(panel!=null and panel.get("station")=="blacksmith","REAL_SMITH_MANUFACTURE_PANEL"):finish();return
	await shot("smith_manufacture")
	line=(panel.get("rows") as VBoxContainer).get_child(1).get_child(0)
	await click(line.get_child(line.get_child_count()-1) as Button)
	confirm=panel.get("_confirm")
	if not need(confirm.is_open(),"SMITH_CONFIRM_VISIBLE"):finish();return
	await click(confirm.get("_confirm_button") as Button)
	need(inv.call("count_of",&"iron_helmet")==1 and inv.call("count_of",&"iron_ore")==0 and game.get("gold")==28,"REAL_GUI_HELMET_THREE_ORE_TWELVE_GOLD")
	await key(KEY_ESCAPE)
	need(current_scene==shop and not is_instance_valid(life.get("_panel")),"SMITH_ESC_RETURNS_ORIGINAL_SHOP_NOT_FIELD")
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINTS_STILL_SUSPENDED")
	finish()
func finish() -> void:
	if finished:return
	finished=true
	var file:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"errors":failures,"records":records,"input_events":input_count,"declared_memory_fixtures":{"starting_gold":40,"extra_ore_for_smith_UI":1},"save_loads":0,"save_writes":0,"continuous_world_travel_claim":false},"\t")+"\n");file.close()
	print("LIFE_FIELD_UI_RESULT ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
