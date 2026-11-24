extends NPCNode
## Only the four newly authored quiet ambient performers/staff use this.
## Explicit grid and native shoe anchor precede stock collision creation.
var _native_plan: Dictionary = {}
var _native_configured := false

func set_native_plan(plan: Dictionary) -> bool:
	if is_inside_tree() or not _native_plan.is_empty() or plan.get("ok")!=true or plan.get("native")!=true or not plan.get("texture") is Texture2D:
		return false
	_native_plan = plan.duplicate()
	return true

func _create_body_collision() -> void:
	if not _native_plan.is_empty() and sprite!=null and sprite.texture==_native_plan.texture and _idle_texture==_native_plan.texture and _ground_anchored and not _calibrate_adult_body:
		var cell: Vector2 = _native_plan.cell
		var anchor: Vector2 = _native_plan.anchor
		_hframes = 4
		sprite.hframes = 4
		sprite.vframes = 1
		sprite.frame = 0
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.offset = Vector2(cell.x*0.5-anchor.x,0.0)
		_native_configured = true
	super._create_body_collision()

func _visual_foot_offset() -> float:
	if _native_configured:
		var cell: Vector2 = _native_plan.cell
		var anchor: Vector2 = _native_plan.anchor
		return (anchor.y-cell.y*0.5)*sprite.scale.y
	return super._visual_foot_offset()

func native_grid_ready() -> bool:
	if not _native_configured or _body_collider == null or _body_collider.get_child_count()!=1 or sprite.hframes!=4 or sprite.vframes!=1 or _hframes!=4:
		return false
	var collider := _body_collider.get_child(0) as CollisionShape2D
	var shape := collider.shape as RectangleShape2D if collider!=null else null
	if shape==null or shape.size.distance_to(_native_plan.half_body*2.0)>0.001 or not (_body_collider.position+collider.position).is_zero_approx(): return false
	var cell: Vector2 = _native_plan.cell
	var anchor: Vector2 = _native_plan.anchor
	return (sprite.position+(anchor+sprite.offset-cell*0.5)*sprite.scale).length()<0.001
