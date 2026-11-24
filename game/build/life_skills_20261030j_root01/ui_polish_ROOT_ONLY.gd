extends SceneTree
## Last UI layout only; prior F/transactions are inherited, not repeated.
var checks: int=0
var failures: Array[String]=[]
var output: String
var ui: CanvasLayer
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true)
func need(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("LIFE_UI_POLISH_FAIL ",label)
func _run() -> void:
	output="res://build/life_skills_20261030j_root01/ui_polish/%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(output)
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINTS_SUSPENDED")
	var inv: Node=root.get_node("Inventory");inv.call("from_dict",{})
	inv.call("add_item",&"herb_bundle",10);inv.call("add_item",&"iron_ore",20)
	root.get_node("GameState").call("add_gold",200)
	ui=CanvasLayer.new();root.add_child(ui)
	for station: String in ["medicine","blacksmith"]:
		var panel: Control=load("res://scripts/life_skills/crafting_panel.gd").new()
		panel.set("station",station);panel.set("stock",[&"iron_staff",&"iron_great_blade"])
		panel.set("station_valid",func()->bool:return true)
		ui.add_child(panel);await process_frame;await process_frame
		var rows: VBoxContainer=panel.get("rows");var content: Control=rows.get_parent().get_parent()
		var title: Control=content.get_child(0).get_child(0)
		need(title.get_global_rect().position.y>=240,"HEADER_WITHIN_ILLUSTRATED_FRAME:"+station)
		need(title.get_global_rect().position.x>=460,"CONTENT_CLEAR_OF_LEFT_BORDER:"+station)
		need(rows.get_child_count()==(3 if station=="medicine" else 5),"EXISTING_RECIPE_ROWS:"+station)
		await RenderingServer.frame_post_draw
		var pixels: Image=root.get_viewport().get_texture().get_image()
		need(pixels.get_size()==Vector2i(1920,1080) and pixels.save_png(output+"/"+station+".png")==OK,"NORMAL_UI_IMAGE:"+station)
		panel.queue_free();await process_frame
	var file:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"errors":failures,"prior_live_F_and_crafting_transactions_inherited":true,"scope":"NEW_LAYOUT_AND_EXISTING_ATLAS_REGION_ONLY","save_loads":0,"save_writes":0,"field_instances":0,"input_events":0},"\t")+"\n");file.close()
	print("LIFE_UI_POLISH_RESULT ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
