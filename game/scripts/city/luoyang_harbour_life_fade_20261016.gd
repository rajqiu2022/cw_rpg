extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Same source-alpha55% fade/depth; exact new two-domain identity and objects.
var _ids: Array=[]
var _fade_ids: Array=[]
func configure_harbour_scene(world: Node2D,scene: SceneScript,objects: Array) -> bool:
	release()
	var runtime: Variant=load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd")
	if not runtime.bound(scene) or not is_instance_valid(world): return false
	for object: Dictionary in objects:
		if object.get("sort_by_feet",false)!=true: continue
		var id:=String(object.id)
		if id in _ids: return false
		_ids.append(id)
		if object.get("role")=="water_decoration": continue
		if object.get("blocking",false) and (id.begins_with("harbour_") or id in ["north_canal_warehouse","south_canal_front","notice_pavilion","north_court_boundary","west_street_front","east_street_front","gate_wall_333","gate_wall_950","gate_wall_2122","gate_wall_2739","gate_tower_140","gate_tower_2932"]): _fade_ids.append(id)
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
	var result:=super.get_fade_runtime_state(); result.scope="EXACT_HARBOUR_LIFE_TWO_DOMAIN_OBJECTS"; return result
