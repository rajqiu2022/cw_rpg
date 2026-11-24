extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Temple-only native alpha/feet: low altar stays opaque, actors ghost above.
var _temple_ids: Array=[]
var _temple_fade_ids: Array=[]
func configure_temple(world: Node2D,scene: SceneScript,data: Dictionary) -> bool:
	release()
	if not is_instance_valid(world) or not load("res://scripts/city/luoyang_temple_assembly_20261016.gd").is_scene(scene): return false
	for row: Dictionary in data.placements:
		if String(row.id) in _temple_ids: return false
		_temple_ids.append(String(row.id))
		if row.get("fade_allowed")==true: _temple_fade_ids.append(String(row.id))
	if _temple_ids.is_empty(): return false
	configure(world); _fade_scene=String(scene.scene_id); _fade_opacity=.55; _fade_seconds=.18
	_fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true; return true
func add_prop(sprite: Sprite2D,id: String,foot_y: float) -> void:
	if id not in _temple_ids: return
	super.add_prop(sprite,id,foot_y)
	if id not in _temple_fade_ids: return
	for prop: Dictionary in _props:
		if prop.sprite==sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false}); return
func release() -> void:
	super.release(); _temple_ids.clear(); _temple_fade_ids.clear()
func get_fade_runtime_state() -> Dictionary:
	var result: Dictionary=super.get_fade_runtime_state()
	result["scope"]="EXACT_TEMPLE_COMPONENTS_NOT_CITY"
	result["prop_ids"]=_temple_ids.duplicate(); result["fade_ids"]=_temple_fade_ids.duplicate(); return result
