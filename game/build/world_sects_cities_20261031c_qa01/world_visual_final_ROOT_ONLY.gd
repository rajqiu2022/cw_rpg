extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Visual-only residual. Previously passed real portal roundtrip is inherited.
func _run() -> void:
	if not await boot("world_visual_final"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(900,6000)/Vector2(12288,8192)):finish();return
	var until: int=Time.get_ticks_msec()+6000
	while Time.get_ticks_msec()<until:
		if int(field.call("get_world_v15_stream_debug").get("pending",-1))==0:break
		await process_frame
	var group: Node=world.get_node_or_null("ThreeTownWorldAdditions/openworld_lanxi_zhai")
	if not need(group!=null,"ACTUAL_LANXI_GROUP"):finish();return
	var image: Sprite2D
	for child: Node in group.get_children():
		if child is Sprite2D:image=child;break
	if not need(image!=null and image.z_index==740 and actor.z_index>image.z_index and actor.modulate.a==1.0,"FRONT_GATE_CHARACTER_NOT_HIDDEN_BY_BAKED_PATH"):finish();return
	var paths := 0
	for child: Node in group.get_parent().get_children():
		if child is Polygon2D and child.material is ShaderMaterial:
			if child.material.shader.resource_path=="res://build/world_landmarks_20261031c/path_blend.gdshader":
				paths+=1
				if not need(child.texture.resource_path=="res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png" and child.uv.size()==child.polygon.size(),"FINE_EARTH_ROAD_NOT_ENLARGED_MUD_ROCK"):finish();return
	need(paths>0,"LANXI_ONLY_FEATHERED_EARTH_PATH_PRESENT")
	records.append({"art_depth":image.z_index,"actor_depth":actor.z_index,"foot":foot(),"physics_and_original_door_unchanged":true,"inherited_world_roundtrip_pid":126972,"no_input_or_save_writes":true})
	await shot("lanxi_final_fine_earth_visible_hero")
	finish()
