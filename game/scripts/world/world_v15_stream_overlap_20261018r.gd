extends "res://scripts/world/v15_modular_overlap.gd"
const BRIDGE30M = preload("res://build/world_bridges_20261030m_system01/bridge_visual_patch.gd")
## Alpha/LINEAR sampling and1024-band behavior are inherited, not replaced.
func configure_stream(world: Node2D, source_count: int) -> void:
	configure(world)
	# All source props precede original NPC/player registrations, even when a
	# prop has not entered the visual window yet.
	_depth_ordinal=source_count

func add_stream_prop(sprite: Sprite2D, id: String, foot_y: float, source_ordinal: int) -> bool:
	var next_actor_ordinal:=_depth_ordinal
	var old_count:=_props.size()
	add_prop(sprite,id,foot_y)
	_depth_ordinal=next_actor_ordinal
	if _props.size()!=old_count+1: return false
	for entry: Dictionary in _depth_entries:
		if is_instance_valid(entry.node) and entry.node==sprite:
			entry.ordinal=source_ordinal
			break
	_signature.clear()
	return true

func remove_stream_prop(sprite: Sprite2D) -> void:
	var texture_id: int=sprite.texture.get_instance_id() if sprite.texture!=null else 0
	for i in range(_props.size()-1,-1,-1):
		if not is_instance_valid(_props[i].sprite) or _props[i].sprite==sprite: _props.remove_at(i)
	for i in range(_depth_entries.size()-1,-1,-1):
		var entry: Dictionary=_depth_entries[i]
		if is_instance_valid(entry.node) and entry.node!=sprite: continue
		if int(entry.band)>=0 and _depth_bands.has(entry.band):
			_depth_bands[entry.band].erase(entry)
			for other: Dictionary in _depth_bands[entry.band]: other.foot_y=INF
		_depth_entries.remove_at(i)
	var retained:=false
	for prop: Dictionary in _props:
		if is_instance_valid(prop.sprite) and prop.sprite.texture!=null and prop.sprite.texture.get_instance_id()==texture_id:
			retained=true; break
	if not retained: _images.erase(texture_id)
	_signature.clear()

func release_stream() -> void:
	_props.clear(); _images.clear(); _signature.clear()
	_depth_entries.clear(); _depth_bands.clear(); _actor_pixels.clear()
	_mask=null; _texture=null; _world=null
	_debug={"active":false,"pixels":0,"prop_hits":{},"candidate_count":0}

func _alpha_at(sprite: Sprite2D, image: Image, point: Vector2) -> float:
	# Same native source partition as GPU; all non-bridge alpha remains parent code.
	if not BRIDGE30M.source_pixel_visible(sprite,point):return 0.0
	return super._alpha_at(sprite,image,point)
