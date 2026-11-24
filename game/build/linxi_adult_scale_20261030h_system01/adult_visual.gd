extends RefCounted
## Visual-only post-catalog calibration. Existing bodies/areas/business stay owned
## by the original MainField/NPCNode; no new identity or metadata exemption.
const SCENES := [&"linxi_tutorial",&"linxi_village_center",&"linxi_village_scrollmap"]
const ADULT_REFERENCE := 140.0

static func target_height(npc_id: String) -> float:
	if "granny" in npc_id:return 120.0
	if "herbalist" in npc_id:return 122.0
	if npc_id.begins_with("xingfantian"):return 144.0
	if npc_id == "linxi_south_veteran":return 152.0 # Spear tip sits above the head; body alone measures about 137 px.
	if "teacher" in npc_id:return 124.0
	if "apprentice" in npc_id or "herb_gatherer" in npc_id or "shen_qinghe" in npc_id:return 128.0
	if "guard" in npc_id or "porter" in npc_id or "coach" in npc_id or "tang_xingzhou" in npc_id:return 132.0
	return 130.0

static func _shape_state(node: Node) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for child: Node in node.get_children():
		if not child is CollisionShape2D:continue
		var collider:=child as CollisionShape2D
		var shape: Shape2D=collider.shape
		var row: Dictionary={"node":collider.get_instance_id(),"transform":collider.transform,"disabled":collider.disabled,"shape":shape.get_instance_id() if shape!=null else 0,"size":Vector2.ZERO,"radius":0.0,"height":0.0}
		if shape is RectangleShape2D:row.size=shape.size
		elif shape is CircleShape2D:row.radius=shape.radius
		elif shape is CapsuleShape2D:row.radius=shape.radius;row.height=shape.height
		result.append(row)
	return result

static func physical_business_state(npc: NPCNode) -> Dictionary:
	var body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
	var area: Area2D=npc.interact_area
	return {"npc_position":npc.position,"npc_transform":npc.transform,"ground_anchored":npc.get("_ground_anchored"),"patrol_origin":npc.get("_patrol_origin"),"patrol_phase":npc.get("_patrol_phase"),"patrol_axis":npc.patrol_axis,"patrol_distance":npc.patrol_distance,"patrol_speed":npc.patrol_speed,"movement_mode":npc.movement_mode,"invert_patrol_facing":npc.invert_patrol_facing,"dialog_id":npc.dialog_id,"interaction_action":npc.interaction_action,"dialog_variants":npc.dialog_variants.duplicate(true),"portrait_path":npc.portrait_path,"sprite_path":npc.sprite_path,"walk_sprite_path":npc.walk_sprite_path,"conversation_sprite_paths":npc.conversation_sprite_paths.duplicate(true),"body_node":body.get_instance_id() if body!=null else 0,"body_transform":body.transform if body!=null else Transform2D.IDENTITY,"body_layer":body.collision_layer if body!=null else 0,"body_mask":body.collision_mask if body!=null else 0,"body_shapes":_shape_state(body) if body!=null else [],"area_node":area.get_instance_id() if area!=null else 0,"area_transform":area.transform if area!=null else Transform2D.IDENTITY,"area_layer":area.collision_layer if area!=null else 0,"area_mask":area.collision_mask if area!=null else 0,"area_pickable":area.input_pickable if area!=null else false,"area_monitoring":area.monitoring if area!=null else false,"area_monitorable":area.monitorable if area!=null else false,"area_shapes":_shape_state(area) if area!=null else []}

static func apply(npc: NPCNode) -> Dictionary:
	if not is_instance_valid(npc) or not is_instance_valid(npc.sprite) or npc.sprite.texture==null:return {"ok":false,"reason":"VISIBLE_NPC_TEXTURE_REQUIRED"}
	if npc.get("_ground_anchored")!=true:return {"ok":false,"reason":"ORIGINAL_GROUND_ANCHOR_REQUIRED","npc_id":npc.npc_id}
	var before: Dictionary=physical_business_state(npc)
	var ground_before: float=npc.get_depth_sort_y()
	var bounds: Rect2i=npc._visible_bounds(npc.sprite.texture)
	var old_height: float=float(bounds.size.y)*npc.sprite.scale.y
	var target: float=target_height(npc.npc_id)
	npc._calibrate_adult_body=true
	npc.sprite_scale=target/ADULT_REFERENCE
	npc._apply_sprite_scale()
	npc.set_ground_anchored(true)
	var after: Dictionary=physical_business_state(npc)
	var same_physics: bool=var_to_bytes(before)==var_to_bytes(after)
	var same_ground: bool=is_equal_approx(ground_before,npc.get_depth_sort_y())
	var new_height: float=float(bounds.size.y)*npc.sprite.scale.y
	var sized: bool=absf(new_height-target)<.01
	return {"ok":same_physics and same_ground and sized,"npc_id":npc.npc_id,"target_visible_height_px":target,"old_visible_height_px":old_height,"new_visible_height_px":new_height,"ground_before":ground_before,"ground_after":npc.get_depth_sort_y(),"same_physical_and_business":same_physics,"same_ground":same_ground,"bounds_px":bounds,"runtime_scale":npc.sprite.scale,"visual_scale_parameter":npc.sprite_scale,"before":before,"after":after}
