extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Read-only render facts and normal images. Root alone runs the engine.
func effective_z(item: CanvasItem) -> int:
	var value := 0;var current: Node=item
	while current is CanvasItem:
		value+=(current as CanvasItem).z_index
		if not (current as CanvasItem).z_as_relative:break
		current=current.get_parent()
	return value
func screen_bounds(item: Sprite2D) -> Rect2:
	var r:=item.get_rect();var t:=item.get_global_transform_with_canvas()
	var out:=Rect2(t*r.position,Vector2.ZERO)
	for p: Vector2 in [r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)]:out=out.expand(t*p)
	return out
func item_facts(item: CanvasItem) -> Dictionary:
	return {"path":String(item.get_path()),"visible":item.visible,"visible_in_tree":item.is_visible_in_tree(),"modulate":item.modulate,"self_modulate":item.self_modulate,"z":item.z_index,"z_relative":item.z_as_relative,"effective_z":effective_z(item),"visibility_layer":item.visibility_layer,"material":str(item.material),"use_parent_material":item.use_parent_material,"canvas_transform":item.get_global_transform_with_canvas()}
func observe(label: String) -> void:
	var player:=actor as Player;var sprite: Sprite2D=player.sprite
	var chain: Array=[];var node: Node=sprite
	while node!=null:
		if node is CanvasItem:chain.append(item_facts(node))
		node=node.get_parent()
	var frame:=Rect2i(Vector2i.ZERO,sprite.texture.get_size())
	if sprite.region_enabled:frame=Rect2i(sprite.region_rect)
	var cell:=Vector2i(frame.size.x/sprite.hframes,frame.size.y/sprite.vframes)
	frame=Rect2i(frame.position+sprite.frame_coords*cell,cell)
	var im:=sprite.texture.get_image();if im.is_compressed():im.decompress()
	var solid := 0;var box:=Rect2i()
	for y: int in range(frame.size.y):
		for x: int in range(frame.size.x):
			if im.get_pixelv(frame.position+Vector2i(x,y)).a>.1:
				solid+=1
				box=Rect2i(Vector2i(x,y),Vector2i.ONE) if solid==1 else box.expand(Vector2i(x,y))
	var overlaps: Array=[];var bounds:=screen_bounds(sprite)
	for candidate: Node in field.find_children("*","Sprite2D",true,false):
		var other:=candidate as Sprite2D
		if other==sprite or not other.is_visible_in_tree() or other.texture==null:continue
		if effective_z(other)<effective_z(sprite) or not screen_bounds(other).intersects(bounds):continue
		overlaps.append({"facts":item_facts(other),"texture":other.texture.resource_path,"screen_bounds":screen_bounds(other)})
	var overlap_state: Dictionary=field.call("get_v14_modular_overlap_debug")
	overlap_state.erase("mask_image");overlap_state.erase("mask_texture")
	records.append({"label":label,"foot":foot(),"viewport_size":root.get_visible_rect(),"canvas_cull_mask":root.get_viewport().canvas_cull_mask,"actor_chain":chain,"actor_source":sprite.texture.resource_path,"frame":sprite.frame,"hframes":sprite.hframes,"vframes":sprite.vframes,"source_frame_rect":frame,"source_alpha_count":solid,"source_alpha_bounds":box,"sprite_scale":sprite.scale,"sprite_rect":sprite.get_rect(),"sprite_screen_bounds":bounds,"higher_overlap_sprites":overlaps,"world_overlap_debug":overlap_state})
	await shot(label)
func _run() -> void:
	if not await boot("world_visual_final"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(900,6000)/Vector2(12288,8192)):finish();return
	var until: int=Time.get_ticks_msec()+6000
	while Time.get_ticks_msec()<until:
		if int(field.call("get_world_v15_stream_debug").get("pending",-1))==0:break
		await process_frame
	await observe("lanxi_original_door_readonly_draw_facts")
	finish()
