extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
func canvas_layer(item: Node) -> int:
	var ancestor: Node=item
	while ancestor!=null:
		if ancestor is CanvasLayer:return ancestor.layer
		ancestor=ancestor.get_parent()
	return 0
func screen_rect(control: Control) -> Rect2:
	var transform: Transform2D=control.get_global_transform_with_canvas()
	var result:=Rect2(transform*Vector2.ZERO,Vector2.ZERO)
	for point: Vector2 in [Vector2(control.size.x,0),control.size,Vector2(0,control.size.y)]:result=result.expand(transform*point)
	return result
func _run() -> void:
	if not await boot("world"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(900,6000)/Vector2(12288,8192)) :finish();return
	var until: int=Time.get_ticks_msec()+6000
	while Time.get_ticks_msec()<until:
		var stream: Dictionary=field.call("get_world_v15_stream_debug")
		if not String(stream.get("error","")).is_empty():records.append(stream);need(false,"WORLD_STREAM_REFUSED");finish();return
		if int(stream.get("pending",-1))==0:break
		await process_frame
	var zone: ExitZone
	for item: ExitZone in field.get("_exit_nodes"):
		if item.target_scene_id=="openworld_lanxi_zhai":zone=item;break
	if not need(zone!=null and bool(zone.call("can_enter")) and foot().distance_to(Vector2(900,6000))<.1,"ORIGINAL9006000_REAL_PASSAGE_READY"):finish();return
	var label: Label=zone.get_node("Prompt") as Label
	var label_rect: Rect2=screen_rect(label)
	var hud: Control=field.get("_primary_hud") as Control
	var safe_hud := true;var hud_rects: Array=[]
	for path: String in ["PlayerInfoPanel","MapInfoPanel","QuestSummaryPanel","BtnInventory","BtnEquipment","BtnSkill","BtnQuest","BtnSystem"]:
		var widget: Control=hud.get_node_or_null(path) as Control
		if widget==null or not widget.is_visible_in_tree():continue
		var rect: Rect2=screen_rect(widget);hud_rects.append({"path":path,"rect":rect})
		if root.get_visible_rect().intersects(rect) and rect.intersects(label_rect):safe_hud=false
	var mini: Control=field.get("_world_travel_minimap") as Control
	if mini!=null and mini.is_visible_in_tree():safe_hud=safe_hud and not screen_rect(mini).intersects(label_rect)
	var hud_layer: CanvasLayer=field.get("_hud_canvas_layer") as CanvasLayer
	records.append({"World_label":label.text,"screen_rect":label_rect,"z_index":label.z_index,"z_relative":label.z_as_relative,"label_canvas":canvas_layer(label),"HUD_canvas":hud_layer.layer,"HUD_rects":hud_rects})
	if not need(label.is_visible_in_tree() and label.text.contains("岚溪寨") and label.z_index==4095 and not label.z_as_relative and canvas_layer(label)<hud_layer.layer and safe_hud,"WORLD_NAME_TOP_WITHIN_WORLD_BELOW_HUD_NO_OVERLAP"):finish();return
	var refinement: Script=load(cfg.refinement) as Script
	var texture: Texture2D=refinement.call("texture",String(cfg.landmark)) as Texture2D
	var landmarks: Array=[]
	for sprite: Sprite2D in field.find_children("*","Sprite2D",true,false):
		if sprite.texture==texture and sprite.is_visible_in_tree():landmarks.append({"path":String(sprite.get_path()),"scale":sprite.global_scale,"rect":sprite.get_rect()})
	if not need(texture!=null and not landmarks.is_empty(),"NEW_WHOLE_LANXI_LANDMARK_REAL_FIELD_TEXTURE"):finish();return
	records.append({"native_landmarks":landmarks})
	await shot("lanxi_landmark_and_name")
	var original: Vector2=foot()
	if not await enter(&"openworld_lanxi_zhai"):finish();return
	if not need(field.has_method("get_world_town_debug"),"REAL_NATIVE_LANXI_HOST"):finish();return
	if not await walk(Vector2(1610,3964),35):finish();return
	if not await enter(&"world_map_jianghu"):finish();return
	records.append({"new_landmark_original_portal_minimal_return":foot(),"expected":original})
	need(foot().distance_to(original)<.1,"ORIGINAL_WORLD_FOOT_EXACT_AFTER_MINIMAL_RETURN")
	finish()
