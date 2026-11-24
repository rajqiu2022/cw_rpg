extends "res://tests/helpers/v15_field_raw_oracle.gd"
## Only the NEW city-only reverse/bounty consumer uses this explicit live context.
## The source reader, 17-shoe ellipse and original source-grown solids stay intact.
## Actual canvas/root/visible-foot domain is never guessed from scene ID alone.
var actual: Control
var definition: SceneScript
var legacy: bool=false

func configure_current(scene: SceneScript,live: Control) -> bool:
	actual=null; definition=null; legacy=false
	if scene==null or scene.map_layout==null or not is_instance_valid(live) or not live.is_inside_tree() or live.is_queued_for_deletion() or live.get_tree().current_scene!=live or live.get("_current_scene")!=scene: return false
	var canvas: Variant=live.get("_world_size")
	if typeof(canvas)!=TYPE_VECTOR2 or not canvas.is_finite() or canvas.x<=0 or canvas.y<=0: return false
	if not super.configure(scene.map_layout,"normalized_image_round",-1.0): return false
	actual=live; definition=scene
	legacy=not bool(live.get_tree().root.get_node("SceneRouter").call("is_world_map_scene",scene.scene_id))
	return true

func foot_evidence(center: Vector2) -> Dictionary:
	if not legacy: return super.foot_evidence(center)
	var denied: Dictionary={"clear":false,"kind":"invalid_actual_legacy_context"}
	if not valid or not is_instance_valid(actual) or not actual.is_inside_tree() or actual.is_queued_for_deletion() or actual.get_tree().current_scene!=actual or actual.get("_current_scene")!=definition or definition==null or definition.map_layout==null or Vector2(definition.map_layout.design_size)!=size: return denied
	var canvas: Variant=actual.get("_world_size")
	var player: Node2D=actual.get("_player") as Node2D
	var container: Node2D=actual.get("world_container") as Node2D
	if typeof(canvas)!=TYPE_VECTOR2 or not canvas.is_finite() or canvas.x<=0 or canvas.y<=0 or not is_instance_valid(player) or container==null or not center.is_finite(): return denied
	var offset: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
	var shoes: PackedVector2Array=samples(center+offset)
	if not offset.is_finite() or shoes.size()!=17: return denied
	var records: Array=[]
	for index in shoes.size():
		var point: Vector2=shoes[index]
		if not point.is_finite() or point.x<0 or point.y<0 or point.x>=canvas.x or point.y>=canvas.y: return {"clear":false,"kind":"outside_actual_canvas","shoe_index":index}
		# EACH actual 10x6 shoe maps once. No clamp, rescaled center or re-grown
		# source blocker margin. Actual Player shape is checked by the caller.
		var source_point: Vector2=(point/canvas)*size
		var pixel: Dictionary=pixel_evidence(source_point)
		if pixel.get("clear")!=true: return {"clear":false,"kind":"source_pixel","shoe_index":index,"actual_point_px":[point.x,point.y],"source_point_px":[source_point.x,source_point.y],"pixel":pixel}
		for solid: Dictionary in solids:
			var blocked: bool=Geometry2D.is_point_in_polygon(source_point,solid.polygon) if solid.kind=="exact_world_polygon" else (solid.rect as Rect2).has_point(source_point)
			if blocked: return {"clear":false,"kind":"source_collision","id":solid.id,"shoe_index":index,"actual_point_px":[point.x,point.y],"source_point_px":[source_point.x,source_point.y]}
		records.append({"shoe_index":index,"actual_point_px":[point.x,point.y],"source_point_px":[source_point.x,source_point.y],"pixel":pixel})
	return {"clear":true,"kind":"actual17_mapped_to_unchanged_legacy_source","samples":records,"visible_offset_px":[offset.x,offset.y],"source_size_px":[size.x,size.y],"actual_size_px":[canvas.x,canvas.y],"source_grown_margins_changed":false,"Physics_claimed":false}

func clear(center: Vector2) -> bool:
	return foot_evidence(center).get("clear")==true

func release() -> void:
	actual=null; definition=null; legacy=false
	super.release()

