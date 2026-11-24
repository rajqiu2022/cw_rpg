extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Same native alpha/depth implementation, new exact assembled city whitelist.
var _ids: Array=[]
var _fade_ids: Array=[]
func configure_assembled_scene(world: Node2D,scene: SceneScript,objects: Array) -> bool:
	release()
	var runtime: Variant=load("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd")
	if not runtime.bound(scene) or not is_instance_valid(world): return false
	for entry: Dictionary in objects:
		if entry.get("sort_by_feet",false)!=true: continue
		var id:=String(entry.id)
		if id in _ids: return false
		_ids.append(id)
		if id in ["magistrate_hall","notice_pavilion","south_court_gate","inn","shop","north_market_front","southwest_market_front","southeast_market_front","market_west_ward_frontage","market_east_ward_frontage","market_northwest_rear_frontage","market_northeast_rear_frontage"] or "wall" in id or id.begins_with("assembled_") and not "tree" in id: _fade_ids.append(id)
	if _ids.is_empty(): return false
	configure(world); _fade_scene=String(scene.scene_id); _fade_opacity=.55; _fade_seconds=.18; _fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true
	return true
func add_prop(sprite: Sprite2D,id: String,foot_y: float) -> void:
	if id not in _ids: return
	super.add_prop(sprite,id,foot_y)
	if id not in _fade_ids or not is_instance_valid(sprite): return
	for row: Dictionary in _fade_records:
		if row.sprite.get_ref()==sprite: return
	for prop: Dictionary in _props:
		if prop.sprite==sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false}); return
func release() -> void:
	super.release(); _ids.clear(); _fade_ids.clear()
func get_fade_runtime_state() -> Dictionary:
	var result:=super.get_fade_runtime_state(); result.scope="EXACT_NEW_ASSEMBLED_CITY_OBJECTS"; return result
