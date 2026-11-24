extends "res://tests/helpers/luoyang_enclosure_v11_city_only_target_raw.gd"
## AND the original 17 visible-foot samples with the legacy ROOT constraint.
## Source regions/solids are loaded once by the original reader. Their source
## growth is retained exactly; no private Field callback, clamp or re-growth.
var _root_source_fields: PackedByteArray=PackedByteArray()
var _root_canvas: Vector2=Vector2.ZERO
var _root_screen: Vector2=Vector2.ZERO

func _source_fields(scene: SceneScript) -> PackedByteArray:
	if scene==null or scene.map_layout==null: return PackedByteArray()
	var layout: WalkableMapLayout=scene.map_layout
	return var_to_bytes([layout.design_size,layout.walkable_mask_path,layout.walkable_mask_tiles,
		layout.walkable_regions,layout.blockers,layout.visual_objects])

func configure_current(scene: SceneScript,live: Control) -> bool:
	_root_source_fields=PackedByteArray(); _root_canvas=Vector2.ZERO; _root_screen=Vector2.ZERO
	if not super.configure_current(scene,live): return false
	var screen: Variant=live.get("_screen_size")
	var canvas: Variant=live.get("_world_size")
	if typeof(screen)!=TYPE_VECTOR2 or typeof(canvas)!=TYPE_VECTOR2 or not screen.is_finite() or not canvas.is_finite() or screen.x<=0 or screen.y<=0 or screen!=canvas:
		release(); return false
	_root_source_fields=_source_fields(scene)
	_root_canvas=canvas; _root_screen=screen
	return not _root_source_fields.is_empty()

func foot_evidence(center: Vector2) -> Dictionary:
	var original: Dictionary=super.foot_evidence(center)
	if not legacy or original.get("clear")!=true: return original
	var denied: Dictionary={"clear":false,"kind":"stale_or_invalid_legacy_root_context","visible_17_evidence":original}
	if not is_instance_valid(actual) or actual.is_queued_for_deletion() or not actual.is_inside_tree() or actual.get_tree().current_scene!=actual or actual.get("_current_scene")!=definition or definition==null or definition.map_layout==null: return denied
	if actual.get("_world_size")!=_root_canvas or actual.get("_screen_size")!=_root_screen or _source_fields(definition)!=_root_source_fields or not center.is_finite() or center.x<0 or center.y<0 or center.x>=_root_screen.x or center.y>=_root_screen.y: return denied
	# Player calls production movement with ROOT coordinates, not visible foot.
	# Map the original root once; source-grown blockers already live in size.
	var source_point: Vector2=(center/_root_screen)*size
	var root: Dictionary=pixel_evidence(source_point)
	if root.get("clear")!=true:
		return {"clear":false,"kind":"legacy_root_source_region_or_pixel","root_px":center,"source_root_px":source_point,"root_evidence":root,"visible_17_evidence":original}
	for solid: Dictionary in solids:
		var blocked: bool=Geometry2D.is_point_in_polygon(source_point,solid.polygon) if solid.kind=="exact_world_polygon" else (solid.rect as Rect2).has_point(source_point)
		if blocked:
			return {"clear":false,"kind":"legacy_root_source_collision","id":solid.id,"solid_kind":solid.kind,"root_px":center,"source_root_px":source_point,"visible_17_evidence":original}
	return {"clear":true,"kind":"original_visible_17_AND_original_legacy_root","root_px":center,"source_root_px":source_point,"root_evidence":root,"visible_17_evidence":original,"source_grown_margins_changed":false,"private_production_constraint_used":false,"Physics_claimed":false}

func release() -> void:
	_root_source_fields=PackedByteArray(); _root_canvas=Vector2.ZERO; _root_screen=Vector2.ZERO
	super.release()
