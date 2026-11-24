extends "res://tests/test_school_pointer_runtime_20260911.gd"

# This suite deliberately uses Input.parse_input_event rather than calling
# Field._unhandled_input: project touch<->mouse emulation must participate.
class NativeWitness extends Node:
	var presses: Array[String] = []
	func _input(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			presses.append("%s/device=%d" % [event.get_class(), event.device])

var witness: NativeWitness
var dialog_starts := 0
var gui_presses: Array[String] = []

func prepare_gui(field: Node) -> void:
	for node: Node in field.find_children("*", "Control", true, false) + [field]:
		if node is Control:
			node.gui_input.connect(func(event: InputEvent):
				if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
					gui_presses.append("%s/filter=%d" % [node.name,node.mouse_filter]))
	if "--transparent-field-roots" in OS.get_cmdline_user_args():
		# Diagnostic-only isolation. The default run retains production GUI.
		field.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field.get_node("Background").mouse_filter = Control.MOUSE_FILTER_IGNORE

func _run() -> void:
	root.size = Vector2i(1920,1080)
	root.get_node("GameState").reset_for_new_game()
	root.get_node("Inventory").reset_for_new_game()
	witness = NativeWitness.new()
	root.add_child(witness)
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") and ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"), "both production emulation options active")
	await native_field()
	await native_prop()
	witness.queue_free()
	await root.get_node("AudioManager").stop_bgm(0.0)
	await process_frame
	print("[NativePointerEmulation] checks=%d failed=%d" % [checks,failed])
	quit(1 if failed else 0)

func native_pair(point: Vector2, touch: bool, quick: bool) -> void:
	witness.presses.clear()
	gui_presses.clear()
	for down: bool in [true,false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = point
			event.pressed = down
			Input.parse_input_event(event)
		else:
			var event := mouse(point,down)
			event.global_position = point
			Input.parse_input_event(event)
		if not quick:
			for i in range(4): await process_frame
	for i in range(8): await process_frame
	await create_timer(0.1).timeout
	print("[NativeGUI] ",gui_presses)

func native_field() -> void:
	var field := await spawn_field(&"linxi_village_scrollmap")
	prepare_gui(field)
	field.set_process(false)
	var actor: Player = field.get("_player")
	actor.set_physics_process(false)
	var camera: Camera2D = field.get("_world_camera")
	if camera != null: camera.enabled = false
	root.canvas_transform = Transform2D.IDENTITY
	var world: Node2D = field.get("world_container")
	for zone: ExitZone in field.get("_exit_nodes"):
		detach(zone,"exit_triggered")
		detach(zone,"exit_action_triggered")
		zone.exit_triggered.connect(func(_id: String,_pos: Vector2): exit_count += 1)
		zone.exit_action_triggered.connect(func(_action: String): exit_count += 1)
	for npc: NPCNode in field.get("_npc_nodes"):
		detach(npc,"npc_interacted")
		npc.npc_interacted.connect(func(_id: String,_dialog: String): npc_count += 1)
	for pair: Array in [["linxi_south_apothecary_home","linxi_south_farmer"],["world_map_jianghu","linxi_south_veteran"]]:
		var zone: ExitZone
		var npc: NPCNode
		for item: ExitZone in field.get("_exit_nodes"):
			if item.target_scene_id == pair[0]: zone = item
		for item: NPCNode in field.get("_npc_nodes"):
			if item.npc_id == pair[1]: npc = item
		world.scale = Vector2.ONE
		world.position = Vector2(1080,530)-zone.position-zone.marker_visual.position
		actor.position = zone.position-Vector2(0,42)
		for i in range(4): await physics_frame
		check(zone.get("_in_range"), "native test uses real exit proximity")
		var visual_pos := npc.sprite.position
		npc.sprite.global_position = zone.marker_visual.global_position
		var point: Vector2 = zone.marker_visual.get_global_transform_with_canvas().origin
		for touch: bool in [false,true]:
			for quick: bool in [false,true]:
				var before_exit := exit_count
				var before_npc := npc_count
				await native_pair(point,touch,quick)
				print("[NativeSample] exit=",pair[0]," touch=",touch," quick=",quick," activations=",exit_count-before_exit," npc=",npc_count-before_npc," events=",witness.presses)
				check(exit_count-before_exit == 1 and npc_count == before_npc, "native emulation one exit activation, no NPC; touch=%s quick=%s" % [touch,quick])
		npc.sprite.position = visual_pos
		actor.position = npc.position
		for i in range(4): await physics_frame
		point = npc.sprite.get_global_transform_with_canvas()*Vector2(0,24)
		check(not field.call("_pointer_hits_sprite",zone.marker_visual,point,9.0), "native NPC point outside marker")
		for touch: bool in [false,true]:
			for quick: bool in [false,true]:
				var before := npc_count
				await native_pair(point,touch,quick)
				print("[NativeSample] npc=",pair[1]," touch=",touch," quick=",quick," requests=",npc_count-before," events=",witness.presses)
				check(npc_count-before == 1,"native emulation one NPC request")
		actor.position = Vector2(200,500)
		for i in range(4): await physics_frame
		point = zone.marker_visual.get_global_transform_with_canvas().origin
		for touch: bool in [false,true]:
			var before := count_label(field,"请靠近出口后再点击")
			await native_pair(point,touch,true)
			var delta := count_label(field,"请靠近出口后再点击")-before
			print("[NativeSample] far=",pair[0]," touch=",touch," toasts=",delta," events=",witness.presses)
			check(delta == 1,"native one far-marker toast")
	await create_timer(2.7).timeout
	field.queue_free()
	await process_frame

func native_prop() -> void:
	var bus := root.get_node("EventBus")
	bus.dialog_started.connect(func(id: StringName):
		if id == &"linxi_scholar_house_ledger": dialog_starts += 1)
	for touch: bool in [false,true]:
		for quick: bool in [false,true]:
			root.get_node("GameState").reset_for_new_game()
			root.get_node("Inventory").reset_for_new_game()
			root.get_node("QuestManager").states.clear()
			var field := await spawn_field(&"linxi_scholar_house")
			prepare_gui(field)
			var actor: Player = field.get("_player")
			actor.set_physics_process(false)
			var area: Area2D = field.get("_trigger_areas")[0]
			actor.global_position = area.global_position-Vector2(0,42)
			for i in range(4): await physics_frame
			check(area.overlaps_body(actor),"real ledger prop proximity")
			var visual: Node2D = area.get_meta("highlight_node")
			var point: Vector2 = visual.get_global_transform_with_canvas().origin
			var before := dialog_starts
			await native_pair(point,touch,quick)
			print("[NativeSample] prop=ledger touch=",touch," quick=",quick," dialogs=",dialog_starts-before," events=",witness.presses)
			check(dialog_starts-before == 1 and root.get_node("DialogPlayer").is_playing(),"native prop opens exactly one dialogue")
			root.get_node("DialogPlayer").call("_end_dialog")
			field.queue_free()
			await process_frame

func count_label(node: Node,text: String) -> int:
	var total := 1 if node is Label and node.text == text else 0
	for child in node.get_children(): total += count_label(child,text)
	return total
